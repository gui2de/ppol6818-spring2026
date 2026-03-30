/*************************************************************
	
	Author: Gavin Gondalwala
	Date: 25 March 2026
	Assignment: Experimental Design Stata 4
		
*************************************************************/

*************************************************************
***** Housekeeping *****
*************************************************************

// For current directory:
	if c(username) == "gavinaligondalwala" {
		global wd "/Users/gavinaligondalwala/Documents/Georgetown/Spring2026/ExperimentalDesign/Stata4"
	}

	// Replace username and path below
	if c(username) == "username" { 
		global wd  "C:/Users/username/Documents/username"  
	}

cd $wd

// Globals for datasets
global tz_15 "$wd/Tz_elec_15_clean.dta" // Will be used as the master datasets
global og_tz_10 "$wd/Tz_elec_10_clean.dta"
global tz_gis "$wd/Tz_GIS_2015_2010_intersection.dta"
global tz_10 "$wd/tz_10.dta"

// Plugins
ssc install reclink

*************************************************************

use $wd/Tanzania_election_2015_raw.dta, clear

codebook ward // Dataset has 3,643 unique wards 
count if ward=="" // No missing wards

*************************************************************

use $og_tz_10, clear

codebook // Dataset has 3,109 unique wards in 2010
count if ward_10=="" // No missing wards

*************************************************************

use $tz_15, clear

codebook // Dataset has 3,640 unique wards in 2010

cf ward* using $tz_10 // Master has 3944 obs, using 3333

*************************************************************


*************************************************************
***** Part 1 *****
*************************************************************

use $og_tz_10, clear

// Ensuring variables are clean for fuzzy matching. Will be used to generate clean IDs for merge since variable ward_id* is inconsistent across datasets.
rename ward_10 ward
replace ward = trim(ward)
replace ward = stritrim(ward)
replace ward = strlower(ward)

rename district_10 district
replace district = trim(district)
replace district = stritrim(district)
replace district = strlower(district)

rename region_10 region
replace region = trim(region)
replace region = stritrim(region)
replace region = strlower(region)

// Creating new identifier for fuzzy matching
gen new_ward_id = ward + "_" + district + "_" + region
order new ward

capture save $wd/tz_10.dta

************************
tempfile fuzzyprep
save `fuzzyprep', emptyok

use $tz_15, clear

// Ensuring variables are clean for fuzzy matching. Will be used to generate clean IDs for merge since variable ward_id* is inconsistent across datasets.
rename ward_15 ward
replace ward = trim(ward)
replace ward = stritrim(ward)
replace ward = strlower(ward)

rename district_15 district
replace district = trim(district)
replace district = stritrim(district)
replace district = strlower(district)

rename region_15 region
replace region = trim(region)
replace region = stritrim(region)
replace region = strlower(region)

// Creating new identifier for fuzzy matching
gen new_ward_id = ward + "_" + district + "_" + region
order new ward

// Merging
merge 1:1 new_ward_id using $tz_10

sort _merge

// Example of using only: buhingu_wilaya ya kigoma_kigoma (ward dist region)

save `fuzzyprep', replace

************************

use $tz_gis, clear

sum percentage, detail

	gsort fid_gis_2017 -percentage
	bysort fid_gis_2017: keep if _n == 1
	bysort region_gis_2012 district_gis_2012 ward_gis_2012: gen child_count = _N
		gen is_divided = (child_count > 1)
	bysort region_gis_2012 district_gis_2012 ward_gis_2012: gen parent_tag = (_n == 1)

	count if child_count == 2 & parent_tag == 1 // 466 wards divided into 2
	count if child_count >= 3 & parent_tag == 1 // 37 wards divided into 3+

preserve
    keep if parent_tag == 1
    collapse (mean) div_rate = is_divided (count) total_2010_wards = is_divided, by(region_gis_2012)
    
    replace div_rate = div_rate * 100
    list region_gis_2012 total_2010_wards div_rate
restore


// Fuzzy Matching Prep.
gsort fid_gis_2017 -percentage
bysort fid_gis_2017: keep if _n == 1
rename fid_gis_2017 ward_id_15
rename fid_gis_2012 parent_id_2010
keep ward_id_15 parent_id_2010 percentage
save $wd/spatial_parent_lookup.dta, replace // Generating a "lookup table"

// Fuzzy Merge
use `fuzzyprep', clear

capture drop _merge
merge m:1 ward_id_15 using $wd/spatial_parent_lookup.dta
replace ward_id_10 = parent_id_2010 if missing(ward_id_10) & _merge == 3
gen match_type = "Exact" if !missing(ward_id_10) & _merge != 3
replace match_type = "Spatial/Fuzzy" if _merge == 3 & match_type == ""
*************************************************************


*************************************************************
***** Part 2 *****
*************************************************************
clear
set seed 103

capture program drop experimental_outcomes
program define experimental_outcomes, rclass
	
	syntax, sample(integer)
	clear
	set obs `sample'
	gen control_x = runiform() // Generates random x values as control


	// Confounder
	gen confounder = runiform() // Creating a random confounder variable which effects X and Y
	label var confounder "Omitted Variable (Confounder)"


	// Treatment Assignment
	gen rand_treatment = rnormal() + (0.8 * confounder)

	gen treatment = 0
	sum rand_treatment, detail
	replace treatment = 1 if rand_treatment > `r(p50)'
	label var treatment "Treatment (0/1)"

	tab treatment


	// Generating Mediator
	gen mediator = (0.7 * treatment) + rnormal()
	label var mediator "Mediator (Affected by Treatment)"


	// Creating a "base" world to find the standard deviation of base outcomes in order to produce a 0.3sd treatment effect
	gen base_outcome = rnormal() + (1.5 * confounder) + (0.8 * mediator)
	sum base_outcome
	local sd_base = r(sd)


	// Generating experimental outcomes with the 0.3sd treatment effect
	gen exp_outcome = base_outcome + (0.3 * `sd_base')*treatment
	label var exp_outcome "Experimental Outcome Y"


	// Generating Collider, caused by treatment and outcomes
	gen collider = (0.6 * treatment) + (0.6 * exp_outcome) + rnormal()
	label var collider "Collider (Result of T and Y)"
	
	
	// Run Model 1 (no confounder)
	quietly regress exp_outcome treatment
	matrix reg_1 = r(table) // Save results as a matrix
	matrix list reg_1
	return scalar model1_beta = reg_1[1,1]
	return scalar model1_pval = reg_1[4,1]
	
	
	// Run Model 2
	quietly regress exp_outcome treatment confounder
	matrix reg_2 = r(table) // Save results as a matrix
	matrix list reg_2
	return scalar model2_beta = reg_2[1,1]
	return scalar model2_pval = reg_2[4,1]
	
	
	// Run Model 3
	quietly regress exp_outcome treatment confounder mediator
	matrix reg_3 = r(table) // Save results as a matrix
	matrix list reg_3
	return scalar model3_beta = reg_3[1,1]
	return scalar model3_pval = reg_3[4,1]
	
	// Regress Model 4
	quietly regress exp_outcome treatment confounder mediator collider
	matrix reg_4 = r(table) // Save results as a matrix
	matrix list reg_4
	return scalar model4_beta = reg_4[1,1]
	return scalar model4_pval = reg_4[4,1]
	
	// Run Model 5
	quietly regress exp_outcome treatment confounder mediator collider c.confounder##c.collider
	matrix reg_5 = r(table) // Save results as a matrix
	matrix list reg_5
	return scalar model5_beta = reg_5[1,1]
	return scalar model5_pval = reg_5[4,1]
	
end


// Simulations
tempfile results
save `results', emptyok

foreach n in 10 100 1000 5000 {
	display "SIMULATION N = `n'"
	
	simulate m1_b=r(model1_beta) m2_b=r(model2_beta) m3_b=r(model3_beta) m4_b=r(model4_beta) m5_b=r(model5_beta), reps(500) nodots: experimental_outcomes, sample(`n')
	
	gen n_val = `n'
	
	append using `results'
	save `results', replace
}

save "$wd/gondalwala_p2_simulation_analysis.dta", replace

// Generating Summary Statistics
* use $wd/gondalwala_p2_simulation_analysis.dta, clear
preserve
	collapse (mean) m1_mean=m1_b m2_mean=m2_b m3_mean=m3_b m4_mean=m4_b m5_mean=m5_b (sd) m1_sd=m1_b m3_sd=m3_b, by(n_val)
	label var n_val "Sample Size"
	label var m1_mean "Model 1 (Naive)"
	label var m3_mean "Model 3 (Gold)"
	label var m4_mean "Model 4 (Collider)"

	list n_val m1_mean m2_mean m3_mean m4_mean m5_mean, divider sepby(n_val)
	
	// Illustrating Converging Betas 
	local true_target = 0.4176751 // Mean of 5000 reps of Model 3, which controls for confounders and mediators

	twoway (connected m1_mean n_val, lcolor(gs12) lp(dash)) ///
		   (connected m2_mean n_val, lcolor(orange) lp(shortdash)) ///
		   (connected m3_mean n_val, lcolor(blue) lwidth(thick)) ///
		   (connected m4_mean n_val, lcolor(red) lp(dot)) ///
		   (connected m5_mean n_val, lcolor(purple) lp(longdash)), ///
		   yline(`true_target', lcolor(black) lp(solid)) ///
		   title("Consistency of Beta Estimates Across Models") ///
		   subtitle("Only Model 3 (Blue) Converges to Truth") ///
		   xtitle("Sample Size (N)") ytitle("Mean Beta Estimate") ///
		   legend(order(1 "M1: Naive" 2 "M2: Total Effect" 3 "M3: Gold Standard" 4 "M4: Collider Trap" 5 "M5: Interaction")) ///
		   xlabel(10 100 1000 5000)
	graph export $wd/gondalwala_p2_betas.jpg, as(jpg) width(2000) replace
restore

// Illustrating distributions
graph box m1_b m2_b m3_b m4_b m5_b, over(n_val) ///
    yline(0.66, lcolor(red) lpattern(dash)) ///
    title("Efficiency and Bias: All 5 Models") ///
    subtitle("Boxes shrink (Efficiency) but only" "M3 centers on Truth (Consistency)", size(small)) ///
    legend(label(1 "M1") label(2 "M2") label(3 "M3") label(4 "M4") label(5 "M5") rows(1)) ///
    note("The red line represents the True Treatment Effect (~0.3 SD).")	   
graph export $wd/gondalwala_p2_distributions.jpg, as(jpg) width(2000) replace

*************************************************************


*************************************************************
***** Part 3 *****
*************************************************************

clear

// Confirming plug-in installation
ssc install spmap
ssc install shp2dta


// Converting shape file
spshape2dta $wd/cb_2018_us_county_500k.shp, saving(LA_temp) replace

use LA_temp.dta, clear

keep if STATEFP == "22" // Retains observations for Louisiana only

spset, modify shpfile(LA_temp_shp)
save $wd/LA_map_final.dta, replace
destring GEOID, replace
save $wd/LA_map_final.dta, replace

// Converting & cleaning attributes file to map educational attainment in Louisiana Parishes (counties)
import delimited "$wd/ACSST5Y2024.S1501-Data.csv", varnames(1) clear

foreach v of varlist _all {
    * 1. Grab the long description from Row 1
    local raw_text = `v'[1]
    
    * 2. Find the position of the LAST "!!"
    local last_pos = strrpos("`raw_text'", "!!")
    
    * 3. If "!!" exists, extract the text after it
    if `last_pos' > 0 {
        local clean_label = substr("`raw_text'", `last_pos' + 2, .)
        
        * 4. Remove the "(includes equivalency)" part for High School
        local clean_label = subinstr("`clean_label'", " (includes equivalency)", "", .)
        
        * 5. Apply the clean version as a variable label
        label variable `v' "`clean_label'"
    }
} // Author's Note: code for this loop was refined with the aid of Google Gemini.

drop in 1

rename geo_id raw_geo_id

gen GEOID = substr(raw_geo_id, strpos(raw_geo_id, "US") + 2, .)
order GEOID
destring GEOID, replace

foreach v of varlist s* {
    capture destring `v', replace ignore(",")
}

save $wd/LA_edu_attainment.dta, replace


// Merge
use $wd/LA_map_final.dta, clear

merge 1:1 GEOID using $wd/LA_edu_attainment.dta

tab _merge // All parishes successfully matched
drop _merge


// Mapping
grmap, activate

grmap s1501_c01_001e, title("Estimated Bachelor's Degree Attainment" "in Louisiana Parishes", size(medium)) clmethod(quantile) clnumber(5) fcolor(Greens) legstyle(2) legend(ring(1) pos(7))

graph export $wd/LA_Bachelor_Attainment_Map.jpg, as(jpg) width(2000) replace
*************************************************************
















