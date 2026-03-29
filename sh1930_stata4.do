********************************************************************************
* Sunduss Hamdan (sh1930) - Assignment 8
********************************************************************************

clear all
set more off

* Install required packages
ssc install spmap, replace
ssc install shp2dta, replace


********************************************************************************
* PART 1: FUZZY MATCHING - TANZANIA WARDS
********************************************************************************

use "/Users/sunduss/Downloads/Tz_GIS_2015_2010_intersection.dta", clear
describe

* Keep only meaningful overlaps (>=50% area overlap)
keep if percentage >= 50

* Count how many 2015 wards map to each 2010 ward
bysort ward_gis_2012 region_gis_2012: gen num_children = _N

* Q1: Wards in both 2010 and 2015 (not divided)
preserve
	bysort ward_gis_2012 region_gis_2012: keep if _n == 1
	count if num_children == 1
	di "Q1: Wards in both 2010 and 2015 (not divided) = " r(N)
restore

* Q4: Wards divided into exactly 2
preserve
	bysort ward_gis_2012 region_gis_2012: keep if _n == 1
	count if num_children == 2
	di "Q4: Wards divided into 2 = " r(N)
restore

* Q5: Wards divided into 3 or more
preserve
	bysort ward_gis_2012 region_gis_2012: keep if _n == 1
	count if num_children >= 3
	di "Q5: Wards divided into 3 or more = " r(N)
restore

* Q2: Parentless wards - in 2015 but not in GIS
use "/Users/sunduss/Downloads/Tz_GIS_2015_2010_intersection.dta", clear
keep if percentage >= 50
keep ward_gis_2017 region_gis_2017
duplicates drop
rename (ward_gis_2017 region_gis_2017) (ward_15 region_15)
gen in_gis = 1
tempfile gis_2017
save `gis_2017'

use "/Users/sunduss/Downloads/Tz_elec_15_clean.dta", clear
merge m:1 ward_15 region_15 using `gis_2017', keep(master) nogenerate
count
di "Q2: Parentless wards (in 2015, no 2010 parent) = " r(N)

* Q3: Orphan wards - in 2010 but not in GIS
use "/Users/sunduss/Downloads/Tz_GIS_2015_2010_intersection.dta", clear
keep if percentage >= 50
keep ward_gis_2012 region_gis_2012
duplicates drop
rename (ward_gis_2012 region_gis_2012) (ward_10 region_10)
tempfile gis_2012
save `gis_2012'

use "/Users/sunduss/Downloads/Tz_elec_10_clean.dta", clear
merge m:1 ward_10 region_10 using `gis_2012', keep(master) nogenerate
count
di "Q3: Orphan wards (in 2010, no 2015 child) = " r(N)

* Q6: Rate of ward division by region
use "/Users/sunduss/Downloads/Tz_GIS_2015_2010_intersection.dta", clear
keep if percentage >= 50

bysort ward_gis_2012 region_gis_2012: gen num_children = _N
bysort ward_gis_2012 region_gis_2012: keep if _n == 1

gen divided = (num_children > 1)

bysort region_gis_2012: egen total_wards = count(ward_gis_2012)
bysort region_gis_2012: egen divided_wards = sum(divided)
gen division_rate = divided_wards / total_wards

bysort region_gis_2012: keep if _n == 1
gsort -division_rate

list region_gis_2012 total_wards divided_wards division_rate, clean noobs


********************************************************************************
* PART 2: DE-BIASING A PARAMETER ESTIMATE USING CONTROLS
********************************************************************************

clear all
set seed 12345

capture program drop sim_bias
program define sim_bias, rclass
    args n

    clear
    set obs `n'

    * Confounder: affects both treatment AND Y
    gen confounder = runiform()

    * Treatment: binary, influenced by confounder
    gen treatment = (confounder + runiform() > 1)

    * Y outcome: true treatment effect = 0.3 sd
    gen y = 0.3 * treatment + 0.5 * confounder + runiform()

    * Mediator: caused by treatment, affects Y (controlling blocks the causal path)
    gen mediator = 0.5 * treatment + 0.3 * runiform()

    * Collider: caused by both treatment AND Y (controlling opens a backdoor)
    gen collider = 0.4 * treatment + 0.4 * y + runiform()

    * Model 1: Naive - biased (confounder omitted)
    reg y treatment
    return scalar b1 = _b[treatment]

    * Model 2: Confounder only - unbiased, should recover ~0.3
    reg y treatment confounder
    return scalar b2 = _b[treatment]

    * Model 3: Confounder + Mediator - over-controls, attenuates estimate
    reg y treatment confounder mediator
    return scalar b3 = _b[treatment]

    * Model 4: Collider only - biased (opens spurious backdoor)
    reg y treatment collider
    return scalar b4 = _b[treatment]

    * Model 5: All variables - still biased
    reg y treatment confounder mediator collider
    return scalar b5 = _b[treatment]

end

local sizes "50 100 250 500 1000 2500"
local reps 200

tempfile results
postfile mypost n b1 b2 b3 b4 b5 using `results', replace

foreach n of local sizes {
    forval r = 1/`reps' {
        quietly sim_bias `n'
        post mypost (`n') (r(b1)) (r(b2)) (r(b3)) (r(b4)) (r(b5))
    }
}

postclose mypost
use `results', clear

foreach m in 1 2 3 4 5 {
    bysort n: egen mean_b`m' = mean(b`m')
    bysort n: egen sd_b`m' = sd(b`m')
}

bysort n: keep if _n == 1
sort n

twoway ///
    (line mean_b1 n, lcolor(red) lpattern(dash)) ///
    (line mean_b2 n, lcolor(blue)) ///
    (line mean_b3 n, lcolor(green)) ///
    (line mean_b4 n, lcolor(orange)) ///
    (line mean_b5 n, lcolor(purple) lpattern(dot)) ///
    , yline(0.3, lcolor(black) lwidth(medium)) ///
    legend(order(1 "Model 1: Naive" 2 "Model 2: Confounder" ///
                 3 "Model 3: Confounder+Mediator" 4 "Model 4: Collider" ///
                 5 "Model 5: All vars") rows(3) size(small)) ///
    xtitle("Sample Size (N)") ytitle("Mean Beta Estimate") ///
    title("Mean Beta Estimates by Model and Sample Size") ///
    subtitle("Black line = true treatment effect (0.3)")
graph export "bias_mean_beta.png", replace

di "Summary at N = 2500:"
list n mean_b1 sd_b1 mean_b2 sd_b2 mean_b3 sd_b3 mean_b4 sd_b4 mean_b5 sd_b5 ///
    if n == 2500, clean noobs


********************************************************************************
* PART 3: CHOROPLETH MAP - US State Unemployment Rate 2022
********************************************************************************

clear
input str30 state_name float unemp_rate
"Alabama" 2.7
"Alaska" 4.4
"Arizona" 3.5
"Arkansas" 3.2
"California" 4.1
"Colorado" 3.2
"Connecticut" 4.1
"Delaware" 4.4
"Florida" 2.9
"Georgia" 3.0
"Hawaii" 3.3
"Idaho" 2.8
"Illinois" 4.5
"Indiana" 2.9
"Iowa" 2.6
"Kansas" 2.8
"Kentucky" 3.9
"Louisiana" 3.7
"Maine" 2.7
"Maryland" 3.3
"Massachusetts" 3.6
"Michigan" 4.0
"Minnesota" 2.8
"Mississippi" 4.2
"Missouri" 3.2
"Montana" 2.7
"Nebraska" 2.1
"Nevada" 5.4
"New Hampshire" 2.4
"New Jersey" 3.9
"New Mexico" 4.4
"New York" 4.3
"North Carolina" 3.5
"North Dakota" 2.2
"Ohio" 4.0
"Oklahoma" 3.1
"Oregon" 4.1
"Pennsylvania" 4.3
"Rhode Island" 3.6
"South Carolina" 3.1
"South Dakota" 2.0
"Tennessee" 3.4
"Texas" 3.8
"Utah" 2.4
"Vermont" 2.3
"Virginia" 3.0
"Washington" 4.4
"West Virginia" 4.1
"Wisconsin" 2.9
"Wyoming" 3.6
end

save "unemp_2022.dta", replace

shp2dta using "/Users/sunduss/Downloads/cb_2018_us_state_20m", ///
    data("us_states_data") coor("us_states_coord") genid(id) replace

use "us_states_data.dta", clear
rename NAME state_name
merge 1:1 state_name using "unemp_2022.dta", nogenerate

spmap unemp_rate using "us_states_coord.dta", id(id) ///
    fcolor(Blues) ocolor(white ..) osize(thin ..) ///
    title("US State Unemployment Rate, 2022 (Annual Average)") ///
    subtitle("Source: Bureau of Labor Statistics") ///
    legend(title("Unemployment %", size(small)))
graph export "choropleth_unemp.png", replace
