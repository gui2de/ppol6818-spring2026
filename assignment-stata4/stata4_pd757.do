* ------------------------------------------------------------
* PS: Stata4
* Author: Puran Dou (pd757)
* ------------------------------------------------------------

clear all
set more off
version 17

if c(username) == "oldfarmerdou" {
    global ROOT "/Users/oldfarmerdou/Dropbox/ExperimentalDesign/assignment_stata4/data"
}

capture mkdir output
capture mkdir temp

* ------------------------------------------------------------
* Part 1: Fuzzy Matching
* ------------------------------------------------------------

clear all
set more off

cd "$ROOT"
tempfile q1

* 1-3: unchanged / parentless / orphan
use "$ROOT/Tz_elec_10_clean.dta", clear
rename (region_10 district_10 ward_10) (region district ward)
save `q1'

use "$ROOT/Tz_elec_15_clean.dta", clear
rename (region_15 district_15 ward_15) (region district ward)
merge 1:1 region district ward using `q1'

count if _merge==3
// wards in both 2010 and 2015 = 2,379
count if _merge==1
// parentless wards (2015 only) = 1,565
count if _merge==2
// orphan wards (2010 only) = 954


* 4-6: ward division from GIS
use "$ROOT/Tz_GIS_2015_2010_intersection.dta", clear

bys region_gis_2012 district_gis_2012 ward_gis_2012: gen nchild = _N
egen tag = tag(region_gis_2012 district_gis_2012 ward_gis_2012) // avoid double counting

count if tag & nchild==2
// wards divided into two = 466
count if tag & nchild>=3
// wards divided into three or more = 37

gen divided = tag & nchild>1
collapse (sum) divided tag, by(region_gis_2012)
rename tag total_2010_wards

gen division_rate = divided/total_2010_wards
gsort -division_rate

// region-level ward division rate: 
list region_gis_2012 divided total_2010_wards division_rate, noobs clean
/*
    region_g~2012   divided   total_~s   divisi~e  
            rukwa        25         63   .3968254  
         morogoro        50        152   .3289474  
           katavi        12         42   .2857143  
           mtwara        39        148   .2635135  
           arusha        30        122   .2459016  
           mwanza        34        153   .2222222  
            geita        20         97   .2061856  
           kigoma        22        109   .2018349  
           tabora        30        166   .1807229  
           simiyu        19        111   .1711712  
             mara        23        152   .1513158  
          manyara        18        122    .147541  
    dar es salaam        13         89   .1460674  
           ruvuma        20        139   .1438849  
            tanga        26        209   .1244019  
            pwani        12        106   .1132075  
           dodoma        20        188    .106383  
            mbeya        21        215   .0976744  
           njombe         9         96     .09375  
            lindi        12        133   .0902256  
           iringa         8         91   .0879121  
      kilimanjaro        13        152   .0855263  
        shinyanga         9        118   .0762712  
          singida         9        123   .0731707  
           kagera         9        180        .05  
*/

/* Answer for part 1:
1) Wards existing in both 2010 and 2015: 2,379
2) Parentless wards (exist in 2015 but not in 2010): 1,565
3) Orphan wards (exist in 2010 but not in 2015): 954
4) Wards divided into exactly two wards: 466
5) Wards divided into three or more wards: 37
6) Ward division rates vary by region, refer to the table above.
*/ 


* ------------------------------------------------------------
* Part 2: De-biasing a parameter estimate using controls
* ------------------------------------------------------------

clear all
cd "$ROOT"
capture mkdir output
capture mkdir temp

set seed 7256
* sample size and repetitions
local Ns 100 250 500 1000 5000
local reps 500

* true total treatment effect in the DGP is 0.3
* direct effect of treatment on Y = 0.1
* indirect effect through mediator = 0.5 * 0.4 = 0.2
* total effect = 0.1 + 0.2 = 0.3
local true_beta = 0.3

capture program drop sim_betas
program define sim_betas, rclass
    syntax, N(integer)

    quietly {
        clear
        set obs `n'

        * confounder: affects both treatment assignment and the outcome Y
        gen confounder = rnormal()

        * omitted shock: affects Y and helps create the collider
        gen u = rnormal()

        * treatment: partly determined by the confounder
        gen treat_latent = 0.8*confounder + rnormal()
        gen treat = (treat_latent > 0)

        * mediator: treatment changes mediator, which then changes Y
        gen mediator = 0.5*treat + rnormal()

        * collider: from treatment and by omitted shock u
        gen collider = 0.7*treat + 0.7*u + rnormal()

        * outcome Y:
        * - direct treatment effect = 0.1
        * - confounder affects Y
        * - mediator affects Y, creating indirect effect of 0.2
        * - omitted shock u affects Y
        * - total treatment effect = 0.3
        gen y = 0.1*treat + 0.4*mediator + 0.6*confounder + 0.6*u + rnormal(0,0.4)

        * model 1: omits everything
        reg y treat
        return scalar m1 = _b[treat]

        * model 2: controls for confounding only
        reg y treat confounder
        return scalar m2 = _b[treat]

        * model 3: controls for mediator only
        reg y treat mediator
        return scalar m3 = _b[treat]

        * model 4: controls for collider only
        reg y treat collider
        return scalar m4 = _b[treat]

        * model 5: confounder + mediator
        reg y treat confounder mediator
        return scalar m5 = _b[treat]

        * model 6: confounder + collider
        reg y treat confounder collider
        return scalar m6 = _b[treat]
    }
end

tempfile all_results
save `all_results', emptyok

foreach N of local Ns {
    simulate m1=r(m1) m2=r(m2) m3=r(m3) m4=r(m4) m5=r(m5) m6=r(m6), ///
        reps(`reps') nodots: sim_betas, n(`N')

    gen N = `N'
    append using `all_results'
    save `all_results', replace
}

* Save raw simulation draws
use `all_results', clear
order N m1 m2 m3 m4 m5 m6
export delimited using "output/part2_raw_simulation_draws.csv", replace

* Reshape long and summarize mean / variance / bias
gen sim_id = _n
reshape long m, i(sim_id N) j(model)
rename m beta_hat

label define model_lbl ///
    1 "Naive: treat only" ///
    2 "Correct: + confounder" ///
    3 "Bad: + mediator" ///
    4 "Bad: + collider" ///
    5 "Confounder + mediator" ///
    6 "Confounder + collider"
label values model model_lbl

gen true_beta = `true_beta'

tempfile long_results
save `long_results', replace

collapse (mean) mean_beta=beta_hat (sd) sd_beta=beta_hat (count) reps=beta_hat, by(N model true_beta)
gen var_beta = sd_beta^2
gen bias = mean_beta - true_beta
format mean_beta sd_beta var_beta bias %9.4f

export delimited using "output/part2_summary_table.csv", replace
save "output/part2_summary_table.dta", replace


* fig1: mean beta by N, compared to true value
twoway ///
    (connected mean_beta N if model==1, sort) ///
    (connected mean_beta N if model==2, sort) ///
    (connected mean_beta N if model==3, sort) ///
    (connected mean_beta N if model==4, sort) ///
    (connected mean_beta N if model==5, sort) ///
    (connected mean_beta N if model==6, sort) ///
    , yline(0.3, lpattern(dash)) ///
	legend(order(1 "naive" 2 "confounder" 3 "mediator" 4 "collider" 5 "conf+med" 6 "conf+coll") rows(2)) ///
	xtitle("sample size (N)") ///
	ytitle("mean treatment effect") ///
	title("mean beta")
	
graph export "output/part2_mean_beta.png", replace width(2200)

* fig2: variance of beta by N
twoway ///
    (connected var_beta N if model==1, sort) ///
    (connected var_beta N if model==2, sort) ///
    (connected var_beta N if model==3, sort) ///
    (connected var_beta N if model==4, sort) ///
    (connected var_beta N if model==5, sort) ///
    (connected var_beta N if model==6, sort) ///
    , legend(order(1 "Naive" 2 "Confounder" 3 "Mediator" 4 "Collider" 5 "Conf+Med" 6 "Conf+Coll") rows(2)) ///
    xtitle("sample size (N)") ///
    ytitle("variance of beta")
graph export "output/part2_variance_beta.png", replace width(2200)



* ------------------------------------------------------------
* Part 3: Spatial Analysis
* >>> U.S. state-level choropleth map of 2025 population
* ------------------------------------------------------------

clear all
cd "$ROOT"

* download shapefile and convert it to Stata format
copy "https://www2.census.gov/geo/tiger/TIGER2023/STATE/tl_2023_us_state.zip" ///
    "tl_2023_us_state.zip", replace
unzipfile "tl_2023_us_state.zip", replace
spshape2dta "tl_2023_us_state.shp", saving("us_states") replace

* Download state-level data: population
copy "https://www2.census.gov/programs-surveys/popest/datasets/2020-2025/state/totals/NST-EST2025-ALLDATA.csv" ///
    "NST-EST2025-ALLDATA.csv", replace

import delimited "NST-EST2025-ALLDATA.csv", clear varnames(1)

* keep state-level rows only
capture confirm variable SUMLEV
if !_rc {
    keep if sumlev == 40
}
else {
    keep if state != 0
}

keep state name popestimate2025
rename state statefp
rename name statename
rename popestimate2025 pop2025

* make merge key consistent with shapefile file
tostring statefp, replace format(%02.0f)
save "state_pop2025.dta", replace

* merge
use "us_states.dta", clear

capture confirm numeric variable STATEFP
if !_rc {
    tostring STATEFP, replace format(%02.0f)
}

rename STATEFP statefp

drop if inlist(STUSPS, "AK", "HI", "PR", "AS", "GU", "MP", "VI")

merge 1:1 statefp using "state_pop2025.dta", keep(match) nogen

save "us_states_with_pop.dta", replace

* draw choropleth map
grmap pop2025 using "us_states_shp.dta", id(_ID) ///
    clmethod(quantile) clnumber(6) ///
    fcolor(Blues) ///
    ocolor(white ..) ///
    osize(vthin ..) ///
    title("U.S. State Population, 2025") ///
    note("Source: U.S. Census Bureau") ///
    legend(size(small))

graph export "$ROOT/output/part3_us_state_population_2025.png", replace width(2200)
