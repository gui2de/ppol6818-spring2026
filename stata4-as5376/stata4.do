clear all
set more off

// Setup: Install necessary spatial mapping packages if not already present
capture ssc install spmap, replace
capture ssc install shp2dta, replace

// PART 1: TANZANIA WARDS - FUZZY MATCHING
* Load the intersection dataset
use "/Users/anu/Downloads/Tz_GIS_2015_2010_intersection.dta", clear
describe 

* Filter out minor overlaps; keep only areas with 50% or more overlap
keep if percentage >= 50

* Determine how many 2015 wards originated from a single 2010 ward
bysort ward_gis_2012 region_gis_2012: gen split_count = _N

* Q1: Count wards that remained unchanged
preserve
	bysort ward_gis_2012 region_gis_2012: keep if _n == 1
	count if split_count == 1
	di "--> Answer Q1: " r(N)
restore

* Q2: Identify "Parentless" wards 
use "/Users/anu/Downloads/Tz_GIS_2015_2010_intersection.dta", clear
keep if percentage >= 50
keep ward_gis_2017 region_gis_2017
duplicates drop
rename (ward_gis_2017 region_gis_2017) (ward_15 region_15)
gen found_in_gis = 1
tempfile spatial_2017
save `spatial_2017'

use "/Users/anu/Downloads/Tz_elec_15_clean.dta", clear
merge m:1 ward_15 region_15 using `spatial_2017', keep(master) nogenerate
count
di "--> Answer Q2: " r(N)

* Q3: Identify "Orphan" wards (Exist in 2010 but have no 2015 child)
use "/Users/anu/Downloads/Tz_GIS_2015_2010_intersection.dta", clear
keep if percentage >= 50
keep ward_gis_2012 region_gis_2012
duplicates drop
rename (ward_gis_2012 region_gis_2012) (ward_10 region_10)
tempfile spatial_2012
save `spatial_2012'

use "/Users/anu/Downloads/Tz_elec_10_clean.dta", clear
merge m:1 ward_10 region_10 using `spatial_2012', keep(master) nogenerate
count
di "--> Answer Q3: " r(N)

* Q4: Count wards that split into exactly two new wards
use "/Users/anu/Downloads/Tz_GIS_2015_2010_intersection.dta", clear
keep if percentage >= 50
* Count the splits
bysort ward_gis_2012 region_gis_2012: gen split_count = _N

preserve
	bysort ward_gis_2012 region_gis_2012: keep if _n == 1
	count if split_count == 2
	di "--> Answer Q4: " r(N)
restore

* Q5: Count wards that split into three or more new wards
preserve
	bysort ward_gis_2012 region_gis_2012: keep if _n == 1
	count if split_count >= 3
	di "--> Answer Q5: " r(N)
restore

* Q6: Calculate the division rate across different regions
use "/Users/anu/Downloads/Tz_GIS_2015_2010_intersection.dta", clear
keep if percentage >= 50

* Flag wards that experienced a split
bysort ward_gis_2012 region_gis_2012: gen split_count = _N
bysort ward_gis_2012 region_gis_2012: keep if _n == 1
gen was_split = (split_count > 1)

* Aggregate data at the region level
bysort region_gis_2012: egen base_wards = count(ward_gis_2012)
bysort region_gis_2012: egen split_total = sum(was_split)
gen split_ratio = split_total / base_wards

* Clean up
bysort region_gis_2012: keep if _n == 1
gsort -split_ratio
list region_gis_2012 base_wards split_total split_ratio


// PART 2: SIMULATING BIAS AND CONTROL VARIABLES
clear all
set seed 8675309
capture program drop monte_carlo_dgp

* Define the Data Generating Process (DGP)
program define monte_carlo_dgp, rclass
    args sample_size
    clear
    quietly set obs `sample_size'
    
    * Create standard random noise for the outcome
    gen noise = runiform()
    
    * CONFOUNDER: Affects BOTH the likelihood of receiving treatment and the outcome
    gen confounder_var = runiform()
    
    * TREATMENT: Its assignment is heavily influenced by the confounder.
    gen treatment_var = (confounder_var + runiform() > 1) 
    
    * OUTCOME (Y): The true treatment effect is exactly 0.3. 
    gen outcome_y = 0.3 * treatment_var + 0.8 * confounder_var + noise
    
    * MEDIATOR: Caused by the treatment, and acts as a step on the causal pathway.
    gen mediator_var = 0.6 * treatment_var + runiform()
    
    * COLLIDER: Caused by BOTH the treatment and the outcome Y.
    gen collider_var = 0.5 * treatment_var + 0.5 * outcome_y + runiform()
    
    //Construct five different regression models
    
    * Model 1: Simple model
    quietly reg outcome_y treatment_var
    return scalar beta1 = _b[treatment_var]
    
    * Model 2: Controlling for confounder
    quietly reg outcome_y treatment_var confounder_var
    return scalar beta2 = _b[treatment_var]
    
    * Model 3: Mediator included
    quietly reg outcome_y treatment_var confounder_var mediator_var
    return scalar beta3 = _b[treatment_var]
    
    * Model 4: Collider included
    quietly reg outcome_y treatment_var collider_var
    return scalar beta4 = _b[treatment_var]
    
    * Model 5: All covariates included
    quietly reg outcome_y treatment_var confounder_var mediator_var collider_var
    return scalar beta5 = _b[treatment_var]
end

* Run the Simulation across different sample sizes
local n_values "50 100 250 500 1000 2500"
local repetitions 200

tempfile sim_results
postfile results_buffer n_size b1 b2 b3 b4 b5 using `sim_results', replace

foreach n of local n_values {
    forval i = 1/`repetitions' {
        quietly monte_carlo_dgp `n'
        post results_buffer (`n') (r(beta1)) (r(beta2)) (r(beta3)) (r(beta4)) (r(beta5))
    }
}
postclose results_buffer

* Analyze the Results
use `sim_results', clear

* Calculate the mean and variance of the beta estimates for each model at each N
* Calculate the mean and variance of the beta estimates for each model at each N
foreach m in 1 2 3 4 5 {
    * Calculate the mean
    bysort n_size: egen mean_b`m' = mean(b`m')
    
    * FIX: Calculate standard deviation first, then square it to get variance
    bysort n_size: egen sd_b`m' = sd(b`m')
    gen var_b`m' = sd_b`m'^2
}

* Collapse to one row per sample size for graphing
bysort n_size: keep if _n == 1

* Figure A: Mean of Beta estimatess
twoway ///
    (line mean_b1 n_size, lcolor(red) lpattern(dash)) ///
    (line mean_b2 n_size, lcolor(blue) lwidth(thick)) ///
    (line mean_b3 n_size, lcolor(green)) ///
    (line mean_b4 n_size, lcolor(orange)) ///
    (line mean_b5 n_size, lcolor(purple) lpattern(dot)) ///
    , yline(0.3, lcolor(black) lwidth(medthick)) ///
    legend(order(1 "1: Naive (Biased)" 2 "2: Confounder Only (True)" ///
                 3 "3: + Mediator" 4 "4: Collider Bias" ///
                 5 "5: All Covariates") rows(2) size(vsmall)) ///
    xtitle("Sample Size (N)") ytitle("Mean Beta Estimate") ///
    title("Mean of Treatment Effect Estimates by Model") ///
    subtitle("True parameter = 0.3 (Solid Black Line)")
graph export "beta_means_plot.png", replace

* Figure B: Variance of Beta estimates
twoway ///
    (line var_b1 n_size, lcolor(red) lpattern(dash)) ///
    (line var_b2 n_size, lcolor(blue) lwidth(thick)) ///
    (line var_b3 n_size, lcolor(green)) ///
    (line var_b4 n_size, lcolor(orange)) ///
    (line var_b5 n_size, lcolor(purple) lpattern(dot)) ///
    , legend(order(1 "1: Naive" 2 "2: Confounder Only" ///
                 3 "3: + Mediator" 4 "4: Collider" ///
                 5 "5: All Covariates") rows(2) size(vsmall)) ///
    xtitle("Sample Size (N)") ytitle("Variance of Beta Estimate") ///
    title("Variance of Estimates (Model Convergence)") ///
    subtitle("Notice how variance shrinks as sample size increases")
graph export "beta_variance_plot.png", replace

* Final Output Table for N = 2500
list n_size mean_b1 var_b1 mean_b2 var_b2 mean_b3 var_b3 mean_b4 var_b4 mean_b5 var_b5 if n_size == 2500

	 
// PART 3: The Animal Welfare Index: A Spatial Analysis of State Penalties
clear

* Create the Penalty Harshness Index Dataset (0-100 Score)
* Note: Leaving out Wyoming and South Dakota to demonstrate "Missing" data

input str30 state_name float penalty_score
"Alabama" 25
"Alaska" 38
"Arizona" 45
"Arkansas" 30
"California" 85
"Colorado" 82
"Connecticut" 78
"Delaware" 65
"Florida" 70
"Georgia" 35
"Hawaii" 40
"Idaho" 18
"Illinois" 88
"Indiana" 55
"Iowa" 28
"Kansas" 32
"Kentucky" 22
"Louisiana" 42
"Maine" 86
"Maryland" 75
"Massachusetts" 80
"Michigan" 68
"Minnesota" 60
"Mississippi" 15
"Missouri" 36
"Montana" 24
"Nebraska" 33
"Nevada" 62
"New Hampshire" 72
"New Jersey" 77
"New Mexico" 29
"New York" 81
"North Carolina" 48
"North Dakota" 20
"Ohio" 58
"Oklahoma" 34
"Oregon" 84
"Pennsylvania" 66
"Rhode Island" 79
"South Carolina" 31
"Tennessee" 52
"Texas" 50
"Utah" 26
"Vermont" 74
"Virginia" 64
"Washington" 83
"West Virginia" 46
"Wisconsin" 54
end

save "animal_penalties.dta", replace

* Prepare the Shapefile Data
* Load our state map database
use "states_db.dta", clear
rename NAME state_name

* Merge with our penalty dataset
merge 1:1 state_name using "animal_penalties.dta", keep(master match) nogenerate

* Generate the Styled Choropleth Map
* ------------------------------------------------------------------------------
* Styling options used:
* - clnumber(6): Creates 6 brackets for the legend
* - clmethod(quantile): Distributes states evenly across the 6 color buckets
* - fcolor(spectral): A built-in rainbow color palette
* - ocolor(black): Black borders for the states
* - ndfcolor(gs9): Paints missing data (Wyoming/South Dakota) in medium gray
* - legend(position(5)): Moves the legend to the bottom right
* Note: We add an 'if' statement to exclude Alaska, Hawaii, and Puerto Rico.
* This removes the massive geographic gaps and forces the map to zoom in!

spmap penalty_score using "states_geo.dta" ///
    if !inlist(state_name, "Alaska", "Hawaii", "Puerto Rico"), id(geo_id) ///
    clnumber(6) clmethod(quantile) ///
    fcolor(Spectral) ///
    ocolor(black ..) osize(thin ..) ///
    ndfcolor(gs9) ndlabel("Missing") ///
    title("The Animal Welfare Index: A Spatial Analysis of State Penalties", size(medium) margin(b 2)) ///
    subtitle("US States Index Score (0-100), 2023", size(medium) margin(b 3)) ///
    legend(position(5) ring(0) size(medium) region(lcolor(none)) ///
           title("Score Bracket", size(small))) ///
    plotregion(margin(zero)) ///
    xsize(7) ysize(4.5)
    
* Export the graph
graph export "map_animal_penalties_mainland.png", width(3000) replace
