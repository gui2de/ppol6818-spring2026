/***************************
Experimental Design 
Stata 04
Fabiha Moin 
26th March 2026
****************************/ 

/**************************
Part 01
**************************/ 

cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata 04"

use "Tz_GIS_2015_2010_intersection.dta", clear

*Calculating Overlapping Area Percentages
bysort ward_gis_2017: egen total_2015_area = sum(area)
gen overlap_pct = (area / total_2015_area) * 100
keep if overlap_pct > 10 // keeping only overlaps greater than 10% to eliminate tiny GIS slivers
bysort ward_gis_2017 (overlap_pct): gen is_primary_parent = (_n == _N)
bysort ward_gis_2012: gen num_children = _N if is_primary_parent == 1
by ward_gis_2012: egen max_children = max(num_children)


**Answering Questions

*Question 1: Wards that didn't divide (1-to-1 match)
count if max_children == 1
display "Wards that exist in both years: " r(N)
***********Answer: 2,458

*Question 2
*Creating the unique list of matched 2015 wards from GIS
use "Tz_GIS_2015_2010_intersection.dta", clear

bysort ward_gis_2017: egen total_2015_area = sum(area)
gen overlap_pct = (area / total_2015_area) * 100
keep if overlap_pct > 10
bysort ward_gis_2017 (overlap_pct): keep if _n == _N

keep ward_gis_2017
duplicates drop
gen matched_to_2010 = 1
rename ward_gis_2017 ward_15

save "matched_2015_list.dta", replace

*Merging using m:1 with the 2015 election data
use "Tz_elec_15_clean.dta", clear
merge m:1 ward_15 using "matched_2015_list.dta"
quietly count if _merge == 1
display "Total rows without parents: " r(N)
preserve
    keep if _merge == 1
    duplicates drop ward_15, force
    count
    display "Number of UNIQUE parentless wards: " r(N)
restore

*****************Answer: 318

*Question 3
*Creating the unique list of 2010 parent wards from GIS
use "Tz_GIS_2015_2010_intersection.dta", clear

bysort ward_gis_2017: egen total_2015_area = sum(area)
gen overlap_pct = (area / total_2015_area) * 100
keep if overlap_pct > 10
bysort ward_gis_2017 (overlap_pct): keep if _n == _N

keep ward_gis_2012
duplicates drop
gen has_children = 1
rename ward_gis_2012 ward_10

save "parent_2010_list.dta", replace

*Merging
use "Tz_elec_10_clean.dta", clear
merge m:1 ward_10 using "parent_2010_list.dta"

*Counting only unique wards
preserve
    keep if _merge == 1
    duplicates drop ward_10, force
    count
    display "Number of UNIQUE orphan wards: " r(N)
restore

*******************Answer: 304

*Question 4: Divided into exactly 2 wards
count if max_children == 2
display "Wards divided into two: " r(N)
*****************Answer: 982


*Question 5: Divided into 3 or more wards
count if max_children >= 3 & max_children != .
display "Wards divided into three or more: " r(N)
********Answer: 262


**Question 6: Generating the Regional Table

preserve

*Keeping only the divided wards
gen is_divided = (max_children >= 2) if !missing(max_children)
collapse (sum) num_divided = is_divided (count) total_2010_wards = max_children, by(region_gis_2012)
gen division_rate = (num_divided / total_2010_wards) * 100
list region_gis_2012 division_rate total_2010_wards, table
restore


/**********************
Part 02
************************/


clear all
set seed 12345 // For reproducibility

**Defining Program

capture program drop sim_dgp
program define sim_dgp, rclass
    syntax , n(integer)
    
    clear
    set obs `n'
    
    *Independent baseline error terms
    gen u_y = rnormal(0, 1)
    gen u_t = rnormal(0, 1)
    
    **Confounder
    gen confounder = rnormal(0, 1) 
    
    **Treatment Variable
    gen treat = 0.5 * confounder + u_t
    
    **Mediator
    gen mediator = 0.6 * treat + rnormal(0, 1) 
    
    **The Outcome (Y)
    gen y = 0.1 * treat + 0.4 * confounder + 0.5 * mediator + u_y // setting the true direct effect of treatment to 0.3 standard deviations.
    
    **Collider
    gen collider = 0.7 * treat + 0.7 * y + rnormal(0, 1)
    
    
    **Regression 1: Simple (Biased by Confounder)
    regress y treat
    return scalar b1 = _b[treat]
    
    **Regression 2: Ideal (Controls for Confounder, yields true 0.3)
    regress y treat confounder
    return scalar b2 = _b[treat]
    
    **Regression 3: Over-controlling (Blocks path via Mediator)
    regress y treat confounder mediator
    return scalar b3 = _b[treat]
    
    **Regression 4: Collider Bias (Controls for Collider)
    regress y treat confounder collider
    return scalar b4 = _b[treat]
    
    **Regression 5: Kitchen Sink (Everything included)
    regress y treat confounder mediator collider
    return scalar b5 = _b[treat]

end

**Simulation Across Ns

tempfile results_all
save `results_all', emptyok
foreach size in 50 500 5000 {
    
    dis "Running simulation for N = `size'..."
    
    simulate beta1=r(b1) beta2=r(b2) beta3=r(b3) beta4=r(b4) beta5=r(b5), ///
        reps(200) nodots: sim_dgp, n(`size')
        
    gen N = `size'
    
    append using `results_all'
    save `results_all', replace
}

**Visuals 

use `results_all', clear

**Prepping Data for Graphs 
gen sim_id = _n

reshape long beta, i(sim_id) j(model)

label define modellbl 1 "1. Raw (No Controls)" 2 "2. Controlled (Confounder)" 3 "3. Overcontrolled (Mediator)" 4 "4. Collider Bias" 5 "5. Kitchen Sink"
label values model modellbl

**Collapsing to find the Mean and Standard Deviation (Variance) of beta for each N
collapse (mean) mean_beta=beta (sd) sd_beta=beta, by(N model)

***Generating Confidence Intervals
gen upper = mean_beta + 1.96 * sd_beta
gen lower = mean_beta - 1.96 * sd_beta

***Graphing the Convergence towards the True Parameter (0.3)
twoway ///
    (line mean_beta N if model==1, lcolor(red) lpattern(dash)) ///
    (line mean_beta N if model==2, lcolor(green) lpattern(solid) lwidth(thick)) ///
    (line mean_beta N if model==3, lcolor(blue) lpattern(shortdash)) ///
    (line mean_beta N if model==4, lcolor(orange) lpattern(longdash)) ///
    (line mean_beta N if model==5, lcolor(purple) lpattern(dash_dot)) ///
    , ///
    yline(0.3, lcolor(black) lwidth(thin)) ///
    xlabel(50 500 5000) ///
    ylabel(-0.5(0.2)1.2) ///
    title("Beta Convergence by Model as N Grows") ///
    subtitle("Black horizontal line indicates true parameter (0.3)") ///
    legend(order(1 "1. Raw" 2 "2. Controlled (Ideal)" 3 "3. Mediator Blocked" 4 "4. Collider Bias" 5 "5. All Variables") rows(2)) ///
    xtitle("Sample Size (N)") ytitle("Mean Estimated Beta")


**Graphing Variance and Mean simultaneously
twoway ///
    (rcap upper lower N if model==1, lcolor(red%50)) ///
    (rcap upper lower N if model==2, lcolor(green%50)) ///
    (line mean_beta N if model==1, lcolor(red)) ///
    (line mean_beta N if model==2, lcolor(green)) ///
    , ///
    yline(0.3, lcolor(black)) ///
    xlabel(50 500 5000) ///
    title("Mean and Variance of Beta (Models 1 & 2)") ///
    subtitle("Shaded caps represent Variance. Green centers on the truth.") ///
    xtitle("Sample Size (N)") ytitle("Beta Estimate") ///
    legend(order(3 "Model 1 Estimate" 4 "Model 2 Estimate"))



/************************* 
Part 03
*************************/ 
cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata 04"

ssc install spmap
ssc install shp2dta

shp2dta using "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata 04\Wards_from_2022.shp", database(ward_db) coordinates(ward_coord) genid(id)


use dc_crashes.dta, clear
gen total_crashes = 1
collapse (sum) total_crashes speeding_involved, by(ward)
gen speed_pct = (speeding_involved / total_crashes) * 100
gen ward_1=.
replace ward_1=1 if ward=="Ward 1"
replace ward_1=2 if ward=="Ward 2"
replace ward_1=3 if ward=="Ward 3"
replace ward_1=4 if ward=="Ward 4"
replace ward_1=5 if ward=="Ward 5"
replace ward_1=6 if ward=="Ward 6"
replace ward_1=7 if ward=="Ward 7"
replace ward_1=8 if ward=="Ward 8"

drop ward
rename ward_1 ward
drop if ward==.
save crash_by_ward.dta, replace

use ward_db.dta
rename WARD ward

merge 1:1 ward using crash_by_ward.dta
spmap speed_pct using ward_coord, id(id) fcolor(Reds) title("Percentage of Crashes Involving Speeding")

graph export "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Sta
> ta 04\Choropleth Map _ Stata 04.png", as(png) name("Graph")
file C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata
    04\Choropleth Map _ Stata 04.png saved as PNG format
