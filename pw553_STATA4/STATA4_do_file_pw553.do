*************STATA 4-Peggy Wang***********************

***Part 1:
*1. Using the name, district, and region matching, there are 2379 wards are 
*found in both the 2010 and 2015 datasets. 

*2. There are 1565 wards appear in the 2015 dataset with no direct name-match 
*to a 2010 dataset. These are the new wards that created by division.

*3. There are 954 wards from 2010 dataset have no exact name in 2015. These are 
*the wards that were divided and renamed. 

*4. There are 466 wards from 2010 dataset were split into exactly two wards in 
*2015 dataset.

*5. There are 37 wards from 2010 dataset were split into three or more wards in 
*2015 dataset.

*6. 
/*
Region          Division Rate
Rukwa           0.40
Morogoro        0.33       
Katavi          0.29
Mtwara          0.26
Arusha          0.25
Mwanza          0.22
Geita           0.21
Kigoma          0.20
Tabora          0.18
Simiyu          0.17
Mara            0.15
Manyara         0.15
Dar es Salaam   0.15
Ruvuma          0.14
Tanga           0.12
Pwani           0.11
Dodoma          0.11
Mbeya           0.10
Njombe          0.09
Lindi           0.09
Iringa          0.09
Shinyanga       0.08
Singida         0.07
Kagera          0.05
*/



***Part 2:
clear all
cd /Users/peggy/Desktop/pw553_STATA4
set more off
version 17  

local true_total  = 0.5129
local true_direct = 0.2850

local nsims  = 400
local sizes  "50 100 200 500 1000 2000 5000"
local nmod   = 6

tempfile simresults
postfile handle  int(sim_id model_id) long(n_obs) float(beta_hat) ///
    using `simresults', replace
	
program define run_one_sim
    syntax, n(integer) simid(integer)

    quietly {
        clear
        set obs `n'
        gen confounder = runiform(0, 1)
        gen double p_treat = 0.3 + 0.4 * confounder
        gen treat = (runiform(0,1) < p_treat)
        gen mediator = 0.6 * treat + 0.3 * rnormal(0,1)
        gen double y_raw = 0.3*treat + 0.5*confounder + 0.4*mediator + rnormal(0,1)
        quietly sum y_raw
        gen y = (y_raw - r(mean)) / r(sd)
        gen collider = 0.5*treat + 0.5*y + 0.3*rnormal(0,1)
        gen region = runiformint(0, 4)
		
        reg y treat
        local b1 = _b[treat]

        reg y treat confounder
        local b2 = _b[treat]

        reg y treat confounder mediator
        local b3 = _b[treat]

        reg y treat confounder collider
        local b4 = _b[treat]

        reg y treat confounder i.region
        local b5 = _b[treat]

        reg y treat collider
        local b6 = _b[treat]
		
    }
	    forvalues m = 1/6 {
        post handle (`simid') (`m') (`n') (`b`m'')
    }
end

local total_cells = 7 * `nsims'
local done = 0

foreach n of local sizes {
    forvalues s = 1/`nsims' {

        local seed = `s' * 7 + `n' * 3
        set seed `seed'

        run_one_sim, n(`n') simid(`s')

        local ++done
        if mod(`done', 500) == 0 {
            di "  `done' / `total_cells' cells done ..."
        }
    }
    di "  N = `n'  complete"
}

postclose handle


use `simresults', clear
gen bias_total  = beta_hat - `true_total'
gen bias_direct = beta_hat - `true_direct'
gen se2         = (beta_hat - `true_total')^2 

collapse (mean) mean_beta=beta_hat  mean_bias=bias_total ///
         (sd)   sd_beta=beta_hat ///
         (mean) rmse_sq=se2 ///                          
         , by(model_id n_obs)

gen rmse = sqrt(rmse_sq)
gen variance = sd_beta^2
drop rmse_sq

label values model_id modlbl
sort model_id n_obs

local c1 "214 39 40"
local c2 "44 160 44"
local c3 "255 127 14"
local c4 "148 103 189"
local c5 "31 119 180"
local c6 "140 86 75"

local lp1 "lcolor("`c1'") mcolor("`c1'")"
local lp2 "lcolor("`c2'") mcolor("`c2'")"
local lp3 "lcolor("`c3'") mcolor("`c3'")"
local lp4 "lcolor("`c4'") mcolor("`c4'")"
local lp5 "lcolor("`c5'") mcolor("`c5'")"
local lp6 "lcolor("`c6'") mcolor("`c6'")"

local xopts "xscale(log) xlabel(50 100 200 500 1000 2000 5000, angle(45))"



*Figure 1: Mean beta ± 1 SD vs N
gen upper = mean_beta + sd_beta
gen lower = mean_beta - sd_beta


twoway ///
    (line mean_beta n_obs if model_id==1, lp(solid) lw(medthick) `lp1') ///
    (line mean_beta n_obs if model_id==2, lp(solid) lw(medthick) `lp2') ///
    (line mean_beta n_obs if model_id==3, lp(solid) lw(medthick) `lp3') ///
    (line mean_beta n_obs if model_id==4, lp(solid) lw(medthick) `lp4') ///
    (line mean_beta n_obs if model_id==5, lp(dash)  lw(medthick) `lp5') ///
    (line mean_beta n_obs if model_id==6, lp(shortdash) lw(medthick) `lp6') ///
    (rarea upper lower n_obs if model_id==1, color("`c1'%15") lw(none)) ///
    (rarea upper lower n_obs if model_id==2, color("`c2'%15") lw(none)) ///
    (rarea upper lower n_obs if model_id==3, color("`c3'%15") lw(none)) ///
    (rarea upper lower n_obs if model_id==4, color("`c4'%15") lw(none)) ///
    (rarea upper lower n_obs if model_id==5, color("`c5'%15") lw(none)) ///
    (rarea upper lower n_obs if model_id==6, color("`c6'%15") lw(none)) ///
    , yline(`true_total',  lcolor(black)   lp(dash)  lw(medthick)) ///
      yline(`true_direct', lcolor(gs8)     lp(dot)   lw(medthick)) ///
      `xopts' ///
      ytitle("Estimated {&beta} on treatment") ///
      xtitle("Sample size (log scale)") ///
      title("Mean {&plusmn} 1 SD of {&beta}{hat} by model and sample size" ///
            "(400 simulations per cell)", size(medsmall)) ///
      legend(order(1 "M1: Treat only" 2 "M2: +Confounder (correct)" ///
                   3 "M3: +Mediator" 4 "M4: +Collider" ///
                   5 "M5: +RegionFE" 6 "M6: Treat+Collider") ///
             cols(2) size(small))

graph export "figure1_mean_sd.png", replace

* Figure 2: Bias
twoway ///
    (line mean_bias n_obs if model_id==1, lp(solid)     lw(medthick) `lp1') ///
    (line mean_bias n_obs if model_id==2, lp(solid)     lw(medthick) `lp2') ///
    (line mean_bias n_obs if model_id==3, lp(solid)     lw(medthick) `lp3') ///
    (line mean_bias n_obs if model_id==4, lp(solid)     lw(medthick) `lp4') ///
    (line mean_bias n_obs if model_id==5, lp(dash)      lw(medthick) `lp5') ///
    (line mean_bias n_obs if model_id==6, lp(shortdash) lw(medthick) `lp6') ///
    , yline(0, lcolor(black) lp(dash) lw(medium)) ///
      `xopts' ///
      ytitle("Bias  ({&beta}{hat} {&minus} true total ATE)") ///
      xtitle("Sample size (log scale)") ///
      title("Asymptotic bias by model" ///
            "(does not vanish with N)", size(medsmall)) ///
      legend(order(1 "M1" 2 "M2 (correct)" 3 "M3" 4 "M4" 5 "M5" 6 "M6") ///
             cols(3) size(small))

graph export "figure2_bias.png", replace


* Figure 3: RMSE
twoway ///
    (line rmse n_obs if model_id==1, lp(solid)     lw(medthick) `lp1') ///
    (line rmse n_obs if model_id==2, lp(solid)     lw(medthick) `lp2') ///
    (line rmse n_obs if model_id==3, lp(solid)     lw(medthick) `lp3') ///
    (line rmse n_obs if model_id==4, lp(solid)     lw(medthick) `lp4') ///
    (line rmse n_obs if model_id==5, lp(dash)      lw(medthick) `lp5') ///
    (line rmse n_obs if model_id==6, lp(shortdash) lw(medthick) `lp6') ///
    , `xopts' ///
      ytitle("RMSE (vs true total ATE)") ///
      xtitle("Sample size (log scale)") ///
      title("Root Mean Squared Error of {&beta}{hat} by model and sample size", ///
            size(medsmall)) ///
      legend(order(1 "M1" 2 "M2 (correct)" 3 "M3" 4 "M4" 5 "M5" 6 "M6") ///
             cols(3) size(small))

graph export "figure3_rmse.png", replace

* Figure 4: Variance
twoway ///
    (line variance n_obs if model_id==1, lp(solid)     lw(medthick) `lp1') ///
    (line variance n_obs if model_id==2, lp(solid)     lw(medthick) `lp2') ///
    (line variance n_obs if model_id==3, lp(solid)     lw(medthick) `lp3') ///
    (line variance n_obs if model_id==4, lp(solid)     lw(medthick) `lp4') ///
    (line variance n_obs if model_id==5, lp(dash)      lw(medthick) `lp5') ///
    (line variance n_obs if model_id==6, lp(shortdash) lw(medthick) `lp6') ///
    , `xopts' ///
      ytitle("Variance of {&beta}{hat}") ///
      xtitle("Sample size (log scale)") ///
      title("Sampling variance of {&beta}{hat} by model and sample size", ///
            size(medsmall)) ///
      legend(order(1 "M1" 2 "M2 (correct)" 3 "M3" 4 "M4" 5 "M5" 6 "M6") ///
             cols(3) size(small))

graph export "figure4_variance.png", replace 

* Figure 5: Distribution of beta-hat at N=500
use `simresults', clear
label values model_id modlbl
gen bias_total = beta_hat - `true_total'

local glist ""
forvalues m = 1/6 {
    quietly sum beta_hat if model_id==`m' & n_obs==500
    local meanbeta = r(mean)
    local meanbeta_fmt : display %5.3f `meanbeta'

    histogram beta_hat if model_id==`m' & n_obs==500, ///
        bin(35) color("`c`m''%70") lcolor(white) lwidth(vthin) ///
        xline(`true_total',  lcolor(black) lp(dash)  lw(medthick)) ///
        xline(`true_direct', lcolor(gs8)   lp(dot)   lw(medium))   ///
        xline(`meanbeta',    lcolor("`c`m''") lp(solid) lw(medthick)) ///
        xtitle("{&beta}{hat}", size(small)) ytitle("Density", size(small)) ///
        title(`:label modlbl `m''": mean=`meanbeta_fmt'", size(small)) ///
        legend(off)
    graph save "hist`m'.gph", replace
    local glist `"`glist' "hist`m'.gph""'
}

graph combine `glist', cols(3) ///
    title("Distribution of {&beta}{hat} at N=500  (400 simulations)", size(medsmall)) ///
    note("Black dashed = true total ATE (0.513)  |  Grey dotted = true direct ATE (0.285)", ///
         size(vsmall)) ///
	graphregion(color(white))

graph export "figure5_distributions.png", replace


* Figure 6: Bias-Variance bubble chart at N=500
use `simresults', clear
label values model_id modlbl
gen bias_total = beta_hat - `true_total'

preserve
keep if n_obs == 500
collapse (mean) mean_beta=beta_hat (sd) sd_beta=beta_hat ///
         (mean) mean_bias=bias_total, by(model_id)
gen abs_bias = abs(mean_bias)
gen variance = sd_beta^2
gen rmse     = sqrt(mean_bias^2 + variance)

local bubble_scale = 25

twoway ///
    (scatter variance abs_bias if model_id==1, msymbol(circle) mcolor("`c1'%70") msize(vlarge) mlcolor(white) mlwidth(thin)) ///
    (scatter variance abs_bias if model_id==2, msymbol(circle) mcolor("`c2'%70") msize(medium) mlcolor(white) mlwidth(thin)) ///
    (scatter variance abs_bias if model_id==3, msymbol(circle) mcolor("`c3'%70") msize(large)  mlcolor(white) mlwidth(thin)) ///
    (scatter variance abs_bias if model_id==4, msymbol(circle) mcolor("`c4'%70") msize(huge)   mlcolor(white) mlwidth(thin)) ///
    (scatter variance abs_bias if model_id==5, msymbol(circle) mcolor("`c5'%70") msize(medium) mlcolor(white) mlwidth(thin)) ///
    (scatter variance abs_bias if model_id==6, msymbol(circle) mcolor("`c6'%70") msize(huge)   mlcolor(white) mlwidth(thin)) ///
    , xtitle("|Bias|  (vs true total ATE)") ///
      ytitle("Variance of {&beta}{hat}") ///
      title("Bias{&ndash}Variance trade-off at N=500", size(medsmall)) ///
      note("Bubble size proportional to RMSE. Ideal: bottom-left corner.", size(small)) ///
      legend(order(1 "M1: Treat only" 2 "M2: +Confounder (correct)" ///
                   3 "M3: +Mediator"  4 "M4: +Collider" ///
                   5 "M5: +RegionFE"  6 "M6: Treat+Collider") ///
             cols(2) size(small))
restore

graph export "figure6_bias_variance.png", replace


use `simresults', clear
gen bias_total = beta_hat - `true_total'
gen bias_dir   = beta_hat - `true_direct'
gen bias_sq    = bias_total^2  

collapse (mean) mean_beta=beta_hat mean_bias=bias_total ///
         (sd)   sd_beta=beta_hat ///
         (mean) rmse_sq=bias_sq ///
         , by(model_id n_obs)

gen rmse = sqrt(rmse_sq)
drop rmse_sq
label values model_id modlbl
sort model_id n_obs

export delimited using "simulation_results.csv", replace




***Part 3:

clear all
cd /Users/peggy/Desktop/pw553_STATA4
set more off
version 14

capture ssc install spmap,   replace
capture ssc install shp2dta, replace

local shp_url "https://www2.census.gov/geo/tiger/GENZ2022/shp/cb_2022_us_state_500k.zip"
local shp_zip "cb_2022_us_state_500k.zip"

copy "`shp_url'" "`shp_zip'", replace
unzipfile "`shp_zip'", replace

shp2dta using cb_2022_us_state_500k,      ///
    database(us_state_data)                ///
    coordinates(us_state_coord)            ///
    genid(id)                              ///
    replace


use us_state_data, clear
describe
list STATEFP NAME id in 1/10

destring STATEFP, gen(fips)
keep id fips NAME
save us_state_attr, replace

clear
input int fips  str30 state_name  float rate
  1   "Alabama"              28.2
  2   "Alaska"               22.3
  4   "Arizona"              31.2
  5   "Arkansas"             22.3
  6   "California"           24.1
  8   "Colorado"             27.6
  9   "Connecticut"          40.8
 10   "Delaware"             43.6
 11   "District of Columbia" 44.5
 12   "Florida"              35.9
 13   "Georgia"              22.5
 15   "Hawaii"               14.7
 16   "Idaho"                14.5
 17   "Illinois"             31.5
 18   "Indiana"              36.2
 19   "Iowa"                 13.5
 20   "Kansas"               16.0
 21   "Kentucky"             49.0
 22   "Louisiana"            30.4
 23   "Maine"                27.9
 24   "Maryland"             40.0
 25   "Massachusetts"        35.1
 26   "Michigan"             31.4
 27   "Minnesota"            17.9
 28   "Mississippi"          19.8
 29   "Missouri"             36.7
 30   "Montana"              19.5
 31   "Nebraska"             12.1
 32   "Nevada"               32.3
 33   "New Hampshire"        36.6
 34   "New Jersey"           32.3
 35   "New Mexico"           42.7
 36   "New York"             32.5
 37   "North Carolina"       33.8
 38   "North Dakota"         11.0
 39   "Ohio"                 47.2
 40   "Oklahoma"             28.8
 41   "Oregon"               28.9
 42   "Pennsylvania"         41.8
 44   "Rhode Island"         39.0
 45   "South Carolina"       30.5
 46   "South Dakota"          9.9
 47   "Tennessee"            40.1
 48   "Texas"                16.0
 49   "Utah"                 22.1
 50   "Vermont"              30.4
 51   "Virginia"             28.1
 53   "Washington"           28.9
 54   "West Virginia"        80.9
 55   "Wisconsin"            29.9
 56   "Wyoming"              18.5
end

label variable rate "Age-adjusted drug overdose death rate per 100,000 (2022)"
label variable fips "State FIPS code"
label variable state_name "State name"

save overdose_data, replace

use us_state_attr, clear

merge 1:1 fips using overdose_data

list NAME fips rate _merge if _merge==2
drop _merge

gen contiguous = (fips != 2 & fips != 15 & fips <= 56)
save us_map_merged, replace
use us_map_merged, clear

spmap rate using us_state_coord                                  ///
    if contiguous == 1                                           ///
    , id(id)                                                     ///
    fcolor(YlOrRd)                                               ///
    clmethod(quantile)                                           ///
    clnumber(5)                                                  ///
    ocolor(white ..)                                             ///
    osize(0.3 ..)                                                ///
    ndfcolor(gs12)                                               ///
    ndocolor(white)                                              ///
    ndsize(0.3)                                                  ///
    legend(pos(5) size(*1.3) title("Rate per 100,000", size(*1.1))) ///
    legstyle(2)                                                  ///
    title("Drug Overdose Death Rates by State, 2022",            ///
          size(large) margin(b=3))                               ///
    subtitle("Age-adjusted rate per 100,000 population"          ///
             " | Source: CDC / NCHS",                            ///
             size(medsmall) color(gs6))                          ///
    note("Contiguous US only. Classification: quintiles."        ///
         " West Virginia (80.9) is the highest-rate state.",     ///
         size(vsmall) color(gs8))                          

graph export "choropleth_overdose_2022.png", replace





