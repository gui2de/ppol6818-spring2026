*********Part1***************

cd "C:\Users\yzqri\Downloads"

use "Tz_GIS_2015_2010_intersection.dta", clear

* Sort so the largest overlap comes first within each 2015 ward
gsort +ward_gis_2017 -percentage

* Keep the best parent match for each 2015 ward
by ward_gis_2017: keep if _n == 1

* Rename variables
rename ward_gis_2017 ward_15
rename ward_gis_2012 ward_10
rename region_gis_2017 region_15
rename district_gis_2017 district_15
rename region_gis_2012 region_10
rename district_gis_2012 district_10

* Standardize names
foreach var of varlist region_15 district_15 ward_15 region_10 district_10 ward_10 {
    replace `var' = lower(trim(itrim(`var')))
}

keep region_15 district_15 ward_15 region_10 district_10 ward_10 percentage
save "tz_ward_crosswalk_2015_2010.dta", replace

*******Q1***********
use "tz_ward_crosswalk_2015_2010.dta", clear

* Count how many 2015 wards each 2010 ward maps to
bysort region_10 district_10 ward_10: gen n_children = _N

* Same-name direct continuation
gen same_name = (ward_15 == ward_10)

* Exists in both years without division
gen common_ward = (same_name == 1 & n_children == 1)

count if common_ward == 1 //// The result is 2494.

***********Q2&Q3***********

use "Tz_elec_15_clean.dta", clear
rename region_15 region
rename district_15 district
rename ward_15 ward

foreach var of varlist region district ward {
    replace `var' = lower(trim(itrim(`var')))
}

keep region district ward
duplicates drop

tempfile wards15
save `wards15'

use "Tz_elec_10_clean.dta", clear
rename region_10 region
rename district_10 district
rename ward_10 ward

foreach var of varlist region district ward {
    replace `var' = lower(trim(itrim(`var')))
}

keep region district ward
duplicates drop

tempfile wards10
save `wards10'


**************************************************
* Load and clean the existing crosswalk
**************************************************
use "tz_ward_crosswalk_2015_2010.dta", clear

foreach var of varlist region_15 district_15 ward_15 region_10 district_10 ward_10 {
    replace `var' = lower(trim(itrim(`var')))
}

tempfile crosswalk
save `crosswalk'

use `wards15', clear
merge 1:1 region district ward using `wards10'
tab _merge

use `wards10', clear
merge 1:1 region district ward using `wards15'
tab _merge

**************************************************
* Q2. Parentless wards
**************************************************

* Step 1: exact roster match (still use full exact match here)
use `wards15', clear
merge 1:1 region district ward using `wards10'
gen exact_match = (_merge == 3)
drop _merge

tempfile exact15
save `exact15'

* Step 2: GIS parent info from crosswalk, matched by ward name only
use "tz_ward_crosswalk_2015_2010.dta", clear

foreach var of varlist ward_15 ward_10 {
    replace `var' = lower(trim(itrim(`var')))
}

keep ward_15
duplicates drop
rename ward_15 ward

gen has_gis_parent = 1
tempfile gisparent15
save `gisparent15'

* Step 3: combine
use `exact15', clear
merge m:1 ward using `gisparent15'
replace has_gis_parent = 0 if missing(has_gis_parent)
drop _merge

gen parentless = (exact_match == 0 & has_gis_parent == 0)

count if parentless == 1
display "Q2. Parentless wards = " r(N)


**************************************************
* Q3. Orphan wards
**************************************************

* Step 1: exact roster match
use `wards10', clear
merge 1:1 region district ward using `wards15'
gen exact_match = (_merge == 3)
drop _merge

tempfile exact10
save `exact10'

* Step 2: GIS child info from crosswalk, matched by ward name only
use "tz_ward_crosswalk_2015_2010.dta", clear

foreach var of varlist ward_15 ward_10 {
    replace `var' = lower(trim(itrim(`var')))
}

keep ward_10
duplicates drop
rename ward_10 ward

gen has_gis_child = 1
tempfile gischild10
save `gischild10'

* Step 3: combine
use `exact10', clear
merge m:1 ward using `gischild10'
replace has_gis_child = 0 if missing(has_gis_child)
drop _merge

gen orphan = (exact_match == 0 & has_gis_child == 0)

count if orphan == 1
display "Q3. Orphan wards = " r(N)


*********Q4************

use "tz_ward_crosswalk_2015_2010.dta", clear

foreach var of varlist region_10 district_10 ward_10 region_15 district_15 ward_15 {
    replace `var' = lower(trim(itrim(`var')))
}

* count number of 2015 children for each 2010 ward
bysort region_10 district_10 ward_10: gen n_children = _N

* keep one row per 2010 ward
bysort region_10 district_10 ward_10: keep if _n == 1

count if n_children == 2


***********Q5*********

count if n_children >= 3



***********Q6*************

use "tz_ward_crosswalk_2015_2010.dta", clear

foreach var of varlist region_10 district_10 ward_10 region_15 district_15 ward_15 {
    replace `var' = lower(trim(itrim(`var')))
}

bysort region_10 district_10 ward_10: gen n_children = _N
bysort region_10 district_10 ward_10: keep if _n == 1

gen divided = (n_children >= 2)
gen one = 1

collapse (sum) total_wards_2010 = one ///
         (sum) divided_wards = divided, by(region_10)

gen division_rate = divided_wards / total_wards_2010

gsort -division_rate
list region_10 total_wards_2010 divided_wards division_rate


* Part 2: De-biasing a parameter estimate using controls
* Full simulation do-file

clear all
set more off
set seed 12345
* True treatment effect
local true_beta = 0.3

* Sample sizes to evaluate
local Ns 100 250 500 1000 2500 5000

* Number of repetitions per sample size
local reps = 500


* 1. Define simulation program

capture program drop sim_bias
program define sim_bias, rclass
    syntax, N(integer)

    clear
    set obs `n'

    * --------------------------------------------
    * Generate random shocks
    * --------------------------------------------
    gen u_c   = rnormal()
    gen u_t   = rnormal()
    gen u_m   = rnormal()
    gen u_y   = rnormal()
    gen u_col = rnormal()

    * --------------------------------------------
    * Generate confounder
    * Confounder affects BOTH treatment and Y
    * Omitting it causes omitted variable bias
    * --------------------------------------------
    gen confounder = u_c

    * --------------------------------------------
    * Generate treatment
    * Treatment is partly determined by confounder
    * --------------------------------------------
    gen treatment = 0.8*confounder + u_t

    * Standardize treatment
    quietly summarize treatment
    replace treatment = (treatment - r(mean)) / r(sd)

    * --------------------------------------------
    * Generate mediator
    * Mediator is CAUSED BY treatment and also affects Y
    * Controlling for it blocks part of treatment effect
    * --------------------------------------------
    gen mediator = 0.7*treatment + 0.3*confounder + u_m

    * --------------------------------------------
    * Generate outcome Y
    * True treatment effect = 0.3
    * Y also depends on confounder and mediator
    * --------------------------------------------
    gen y = 0.3*treatment + 0.6*confounder + 0.5*mediator + u_y

    * --------------------------------------------
    * Generate collider
    * Collider is CAUSED BY treatment and Y
    * Controlling for it induces collider bias
    * --------------------------------------------
    gen collider = 0.6*treatment + 0.6*y + u_col

    * --------------------------------------------
    * Run regression models
    * --------------------------------------------

    * Model 1: Naive (no controls)
    regress y treatment
    return scalar b1 = _b[treatment]

    * Model 2: Good control only (confounder)
    regress y treatment confounder
    return scalar b2 = _b[treatment]

    * Model 3: Mediator only
    regress y treatment mediator
    return scalar b3 = _b[treatment]

    * Model 4: Collider only
    regress y treatment collider
    return scalar b4 = _b[treatment]

    * Model 5: Confounder + mediator
    regress y treatment confounder mediator
    return scalar b5 = _b[treatment]

    * Model 6: Confounder + collider
    regress y treatment confounder collider
    return scalar b6 = _b[treatment]

    * Model 7: All controls
    regress y treatment confounder mediator collider
    return scalar b7 = _b[treatment]
end


* 2. Run simulation and store results

tempname memhold
tempfile results

postfile `memhold' ///
    int N int rep ///
    double b1 b2 b3 b4 b5 b6 b7 ///
    using `results', replace

foreach n of local Ns {
    di "Running simulations for N = `n'"

    forvalues r = 1/`reps' {
        quietly sim_bias, n(`n')

        post `memhold' ///
            (`n') (`r') ///
            (r(b1)) (r(b2)) (r(b3)) (r(b4)) (r(b5)) (r(b6)) (r(b7))
    }
}

postclose `memhold'

use `results', clear
save "simulation_results.dta", replace


* 3. Reshape results to long format

reshape long b, i(N rep) j(model)

label define model_lbl ///
    1 "Naive" ///
    2 "Confounder only" ///
    3 "Mediator only" ///
    4 "Collider only" ///
    5 "Confounder + Mediator" ///
    6 "Confounder + Collider" ///
    7 "All controls"

label values model model_lbl


* 4. Construct summary measures

gen true_beta = `true_beta'
gen bias = b - true_beta
gen sq_error = (b - true_beta)^2

collapse ///
    (mean) mean_beta=b mean_bias=bias mse=sq_error ///
    (sd) sd_beta=b, ///
    by(N model)

gen var_beta = sd_beta^2

save "simulation_summary.dta", replace


* 5. View summary table

sort model N
list, sepby(model)


* 6. Export summary table

export delimited using "simulation_summary.csv", replace


* 7. Figure 1: Mean beta by sample size

twoway ///
    (line mean_beta N if model==1, sort) ///
    (line mean_beta N if model==2, sort) ///
    (line mean_beta N if model==3, sort) ///
    (line mean_beta N if model==4, sort) ///
    (line mean_beta N if model==5, sort) ///
    (line mean_beta N if model==6, sort) ///
    (line mean_beta N if model==7, sort), ///
    yline(`true_beta', lpattern(dash)) ///
    legend(order(1 "Naive" ///
                 2 "Confounder only" ///
                 3 "Mediator only" ///
                 4 "Collider only" ///
                 5 "Confounder + Mediator" ///
                 6 "Confounder + Collider" ///
                 7 "All controls") rows(3)) ///
    xtitle("Sample size (N)") ///
    ytitle("Mean estimated beta") ///
    title("Mean beta across sample sizes")

graph export "mean_beta_by_N.png", replace


* 8. Figure 2: Variance of beta by sample size

twoway ///
    (line var_beta N if model==1, sort) ///
    (line var_beta N if model==2, sort) ///
    (line var_beta N if model==3, sort) ///
    (line var_beta N if model==4, sort) ///
    (line var_beta N if model==5, sort) ///
    (line var_beta N if model==6, sort) ///
    (line var_beta N if model==7, sort), ///
    legend(order(1 "Naive" ///
                 2 "Confounder only" ///
                 3 "Mediator only" ///
                 4 "Collider only" ///
                 5 "Confounder + Mediator" ///
                 6 "Confounder + Collider" ///
                 7 "All controls") rows(3)) ///
    xtitle("Sample size (N)") ///
    ytitle("Variance of estimated beta") ///
    title("Variance of beta across sample sizes")

graph export "var_beta_by_N.png", replace

* 9. Figure 3: Bias by sample size

twoway ///
    (line mean_bias N if model==1, sort) ///
    (line mean_bias N if model==2, sort) ///
    (line mean_bias N if model==3, sort) ///
    (line mean_bias N if model==4, sort) ///
    (line mean_bias N if model==5, sort) ///
    (line mean_bias N if model==6, sort) ///
    (line mean_bias N if model==7, sort), ///
    yline(0, lpattern(dash)) ///
    legend(order(1 "Naive" ///
                 2 "Confounder only" ///
                 3 "Mediator only" ///
                 4 "Collider only" ///
                 5 "Confounder + Mediator" ///
                 6 "Confounder + Collider" ///
                 7 "All controls") rows(3)) ///
    xtitle("Sample size (N)") ///
    ytitle("Mean bias") ///
    title("Bias across sample sizes")

graph export "bias_by_N.png", replace

* End of do-file

di "Done! Files saved:"
di "- simulation_results.dta"
di "- simulation_summary.dta"
di "- simulation_summary.csv"
di "- mean_beta_by_N.png"
di "- var_beta_by_N.png"
di "- bias_by_N.png"
di "- summary_table_N5000.csv"


clear all
set more off

* Set working directory
cd "C:\Users\yzqri\Downloads"


* 1. Import crime data

import delimited "crimeRatesByState2005.csv", clear

* Keep only states / DC level observations
drop if state == "United States"

* Clean state names
replace state = lower(trim(state))

save "crime_clean.dta", replace


* 2. Convert shapefile to Stata map files
* Replace us_states.shp with your actual shapefile name

shp2dta using "cb_2018_us_state_500k.shp", ///
    database(usdb) ///
    coordinates(uscoord) ///
    genid(id) replace


* 3. Open shapefile attribute data and inspect state variable

use usdb.dta, clear
describe

* Suppose the state-name variable in shapefile is called name
replace NAME = lower(trim(NAME))
rename NAME state

save "usdb_clean.dta", replace

* 4. Merge crime data with shapefile data

use "usdb_clean.dta", clear
merge 1:1 state using "crime_clean.dta"

tab _merge

* Keep matched observations only
keep if _merge == 3
drop _merge

save "crime_map_data.dta", replace


* 5. Draw choropleth map
* Example 1: robbery rate

* Open merged map data
use "crime_map_data.dta", clear

* Keep contiguous U.S. only
drop if state == "alaska"
drop if state == "hawaii"

* Draw choropleth map
spmap robbery using uscoord.dta, id(id) ///
    fcolor(Blues) ///
    ocolor(white ..) ///
    osize(vthin ..) ///
    clmethod(quantile) ///
    clnumber(5) ///
	clbreaks(0 100 200 300 400 500 600 700) ///
    legend(label(2 "0–100") ///
           label(3 "101–200") ///
           label(4 "201–300") ///
           label(5 "301–400") ///
           label(6 "401–500") ///
		   label(7 "501–600") ///
           label(8 "601–700")) ///
    legend(pos(7) size(small)) ///
	legtitle("Robbery rate (%)") ///
    title("Robbery Rate by State, 2005", size(medsmall))

graph export "robbery_map_contiguous.png", replace