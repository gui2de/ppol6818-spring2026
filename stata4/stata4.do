/*==============================================================================
  Part 1: Fuzzy Matching
  Tanzania Ward Matching 2010-2015
==============================================================================*/

clear all
set more off

global path "/Users/serovia/Desktop/stata4"
cd "$path"

/*------------------------------------------------------------------------------
  Step 1: Q1-Q3 Direct merge of the two election tables (same naming system)
------------------------------------------------------------------------------*/

// Standardize 2010 variable names
use "data/Tz_elec_10_clean.dta", clear
rename (region_10 district_10 ward_10) (region district ward)
save "data/temp_10.dta", replace

// Merge 2015 table with 2010 table
use "data/Tz_elec_15_clean.dta", clear
rename (region_15 district_15 ward_15) (region district ward)

merge 1:1 region district ward using "data/temp_10.dta"

tab _merge

// Q1: Wards that exist in both 2010 and 2015 (exact name match)
di "========== Q1: Wards existing in both 2010 and 2015 =========="
count if _merge == 3
* 21

// Q2: Parentless wards (exist in 2015 but not in 2010)
di "========== Q2: Parentless wards (2015 only) =========="
count if _merge == 1
* 0

// Q3: Orphan wards (exist in 2010 but not in 2015)
di "========== Q3: Orphan wards (2010 only) =========="
count if _merge == 2
* 0

/*------------------------------------------------------------------------------
  Step 2: Use GIS intersection table to identify ward splits
------------------------------------------------------------------------------*/

use "data/Tz_GIS_2015_2010_intersection.dta", clear

// For each 2015 ward, keep only the 2010 ward with the largest overlap (= parent)
bysort region_gis_2017 district_gis_2017 ward_gis_2017 (percentage): keep if _n == _N

// Count from the 2010 side: how many 2015 wards does each 2010 ward map to
bysort region_gis_2012 district_gis_2012 ward_gis_2012: gen n_children = _N

// Keep one row per 2010 ward
bysort region_gis_2012 district_gis_2012 ward_gis_2012: keep if _n == 1

// Q4: Wards split into exactly two
di "========== Q4: Wards split into two =========="
count if n_children == 2
* 466

// Q5: Wards split into three or more
di "========== Q5: Wards split into three or more =========="
count if n_children >= 3
* 37

// Distribution of splits
di "========== Split distribution =========="
tab n_children
/*
 n_children |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      2,773       84.65       84.65
          2 |        466       14.22       98.87
          3 |         30        0.92       99.79
          4 |          3        0.09       99.88
          5 |          2        0.06       99.94
          8 |          1        0.03       99.97
          9 |          1        0.03      100.00
------------+-----------------------------------
      Total |      3,276      100.00
*/


/*------------------------------------------------------------------------------
  Step 3: Q6 Ward split rate by region
------------------------------------------------------------------------------*/

// Flag whether each 2010 ward was split
gen was_split = (n_children >= 2)

// GIS side: count splits per region
collapse (sum) n_split = was_split (count) n_gis_total = was_split, by(region_gis_2012)
rename region_gis_2012 region

// Trim whitespace and lowercase (just in case)
replace region = strtrim(strlower(region))

save "data/temp_gis_region.dta", replace

// Election side: count total 2010 wards per region
use "data/Tz_elec_10_clean.dta", clear
gen one = 1
collapse (sum) n_total_10 = one, by(region_10)
rename region_10 region
replace region = strtrim(strlower(region))
save "data/temp_elec_region.dta", replace

// GIS side: remap 4 post-2012 regions back to their 2010 parent regions
use "data/temp_gis_region.dta", clear
replace region = "mwanza"    if region == "geita"
replace region = "rukwa"     if region == "katavi"
replace region = "iringa"    if region == "njombe"
replace region = "shinyanga" if region == "simiyu"

// Re-collapse since remapped regions now share rows
collapse (sum) n_split, by(region)
save "data/temp_gis_region2.dta", replace

// Merge election totals with GIS split counts
use "data/temp_elec_region.dta", clear
merge 1:1 region using "data/temp_gis_region2.dta"
tab _merge
replace n_split = 0 if n_split == .
gen split_rate = n_split / n_total_10

di "========== Q6: Ward split rate by region =========="
gsort -split_rate
list region n_total_10 n_split split_rate, sep(0)


/*
     +-----------------------------------------------+
     |        region   n_tot~10   n_split   split_~e |
     |-----------------------------------------------|
  1. |         rukwa        106        37   .3490566 |
  2. |      morogoro        181        50   .2762431 |
  3. |        mtwara        149        39    .261745 |
  4. |        mwanza        214        54   .2523364 |
  5. |        arusha        122        30   .2459016 |
  6. |        kigoma        110        22         .2 |
  7. |        tabora        163        30   .1840491 |
  8. |          mara        154        23   .1493506 |
  9. |       manyara        123        18   .1463415 |
 10. | dar es salaam         90        13   .1444445 |
 11. |        ruvuma        140        20   .1428571 |
 12. |         tanga        206        26   .1262136 |
 13. |     shinyanga        245        28   .1142857 |
 14. |         pwani        112        12   .1071429 |
 15. |        dodoma        190        20   .1052632 |
 16. |         mbeya        218        21   .0963303 |
 17. |        iringa        189        17   .0899471 |
 18. |         lindi        141        12   .0851064 |
 19. |   kilimanjaro        153        13   .0849673 |
 20. |       singida        124         9   .0725806 |
 21. |        kagera        203         9    .044335 |
     +-----------------------------------------------+
	 
*/




/*==============================================================================
 Part 2: De-biasing a Parameter Estimate
 Scenario: Does a job training program reduce domestic violence?
 True total effect = -0.3 SD
==============================================================================*/

clear all
set more off

global path "/Users/serovia/Desktop/stata4"
cd "$path"

/*------------------------------------------------------------------------------
  Step 1: Define the simulation program
  
  Causal structure:
  - C (alcohol use): confounder, affects both treatment and outcome
  - T (job training): treatment, binary
  - M (income): mediator, T -> M -> Y
  - Y (DV severity): outcome
  - Col (police report): collider, T -> Col and Y -> Col
  
  True total effect of T on Y:
    direct = -0.2, indirect via M = (-0.25)*0.4 = -0.1, total = -0.3
------------------------------------------------------------------------------*/

capture program drop dgp_sim
program define dgp_sim, rclass
    syntax, n(integer)
    
    clear
    set obs `n'
    
    // Confounder: alcohol use (0 to 1)
    // heavy drinkers are less likely to join training AND more violent
    gen alcohol = runiform()
    
    // Treatment: job training (binary)
    // higher alcohol -> less likely to enroll
    gen training = (runiform() > 0.3 + 0.4 * alcohol)
    
    // Mediator: income
    // training increases income
    gen income = 0.4 * training + runiform()
    
    // Outcome: DV severity
    // direct effect of training = -0.2
    // indirect effect through income = -0.25 * 0.4 = -0.1
    // total effect = -0.3
    gen dv_score = -0.2 * training + 0.5 * alcohol - 0.25 * income + rnormal()
    
    // Collider: police report
    // training -> more monitoring -> more reports
    // more severe DV -> more reports
    gen police = 0.3 * training + 0.4 * dv_score + rnormal()
    
    // Model 1: no controls (omitted variable bias)
    quietly reg dv_score training
    return scalar beta_nocontrol = _b[training]
    
    // Model 2: control for confounder only (correct specification)
    quietly reg dv_score training alcohol
    return scalar beta_correct = _b[training]
    
    // Model 3: control for confounder + mediator (over-control)
    quietly reg dv_score training alcohol income
    return scalar beta_mediator = _b[training]
    
    // Model 4: control for confounder + collider (collider bias)
    quietly reg dv_score training alcohol police
    return scalar beta_collider = _b[training]
    
    // Model 5: control for everything (mediator + collider problems)
    quietly reg dv_score training alcohol income police
    return scalar beta_all = _b[training]
    
end


/*------------------------------------------------------------------------------
  Step 2: Run simulations across different sample sizes
------------------------------------------------------------------------------*/

local reps 500
local sizes 100 500 1000 5000 10000

local first = 1
foreach n of local sizes {
    di "===== Simulating N = `n' ====="
    
    simulate beta_nocontrol=r(beta_nocontrol) beta_correct=r(beta_correct) ///
        beta_mediator=r(beta_mediator) beta_collider=r(beta_collider) ///
        beta_all=r(beta_all), reps(`reps') seed(12345): dgp_sim, n(`n')
    
    gen N = `n'
    
    if `first' == 1 {
        save "data/sim_all.dta", replace
        local first = 0
    }
    else {
        append using "data/sim_all.dta"
        save "data/sim_all.dta", replace
    }
}


/*------------------------------------------------------------------------------
  Step 3: Summary table
------------------------------------------------------------------------------*/

use "data/sim_all.dta", clear

collapse (mean) beta_nocontrol beta_correct beta_mediator beta_collider beta_all ///
         (sd) sd_nocontrol=beta_nocontrol sd_correct=beta_correct ///
              sd_mediator=beta_mediator sd_collider=beta_collider ///
              sd_all=beta_all, by(N)

di "========== Mean of estimated beta =========="
list N beta_nocontrol beta_correct beta_mediator beta_collider beta_all, noobs

di "========== SD of estimated beta =========="
list N sd_nocontrol sd_correct sd_mediator sd_collider sd_all, noobs

save "data/sim_summary.dta", replace


/*------------------------------------------------------------------------------
  Step 4: Figures
------------------------------------------------------------------------------*/

// Figure 1: Mean of beta across sample sizes (bias comparison)
twoway (connected beta_nocontrol N) ///
       (connected beta_correct N) ///
       (connected beta_mediator N) ///
       (connected beta_collider N) ///
       (connected beta_all N), ///
       yline(-0.3, lpattern(dash) lcolor(black)) ///
       ytitle("Mean estimated coefficient on training") ///
       xtitle("Sample size") ///
       legend(order(1 "No controls" 2 "Alcohol only (correct)" ///
                    3 "Alcohol + income" 4 "Alcohol + police" ///
                    5 "All controls"))

graph export "output/fig1_bias.png", replace


// Figure 2: SD of beta across sample sizes (convergence)
twoway (connected sd_nocontrol N) ///
       (connected sd_correct N) ///
       (connected sd_mediator N) ///
       (connected sd_collider N) ///
       (connected sd_all N), ///
       ytitle("SD of estimated coefficient") ///
       xtitle("Sample size") ///
       legend(order(1 "No controls" 2 "Alcohol only (correct)" ///
                    3 "Alcohol + income" 4 "Alcohol + police" ///
                    5 "All controls"))

graph export "output/fig2_convergence.png", replace


// Figure 3: Distribution at N = 10000
use "data/sim_all.dta", clear
keep if N == 10000

twoway (kdensity beta_nocontrol) ///
       (kdensity beta_correct) ///
       (kdensity beta_mediator) ///
       (kdensity beta_collider) ///
       (kdensity beta_all), ///
       xline(-0.3, lpattern(dash) lcolor(black)) ///
       xtitle("Estimated coefficient on training") ///
       ytitle("Density") ///
       legend(order(1 "No controls" 2 "Alcohol only (correct)" ///
                    3 "Alcohol + income" 4 "Alcohol + police" ///
                    5 "All controls"))

graph export "output/fig3_density.png", replace




/*==============================================================================
  Part 3: Spatial Analysis
  Choropleth map of US state-level poverty rates
  Data source: US Census Bureau, American Community Survey
==============================================================================*/

clear all
set more off

global path "/Users/serovia/Desktop/stata4"
cd "$path"


/*------------------------------------------------------------------------------
  Step 1: Convert shapefile to Stata format
  
  shp2dta creates two files:
  - usdb.dta: the attribute table (state names, IDs, etc.)
  - uscoord.dta: the coordinates for drawing boundaries
------------------------------------------------------------------------------*/

shp2dta using "data/cb_2022_us_state_20m", ///
    database("data/usdb") coordinates("data/uscoord") ///
    genid(id) replace


/*------------------------------------------------------------------------------
  Step 2: Load and clean the shapefile database
------------------------------------------------------------------------------*/

use "data/usdb.dta", clear

// Check what variables are available
describe
list NAME in 1/10

// Drop territories (keep only 50 states + DC)
drop if NAME == "Puerto Rico"
drop if NAME == "United States Virgin Islands"
drop if NAME == "Guam"
drop if NAME == "American Samoa"
drop if NAME == "Commonwealth of the Northern Mariana Islands"

// Rename for merging
rename NAME state

save "data/usdb_clean.dta", replace


/*------------------------------------------------------------------------------
  Step 3: Load poverty data and merge with shapefile
------------------------------------------------------------------------------*/

import delimited "data/us_poverty.csv", clear
duplicates drop
drop if state == ""
save "data/poverty.dta", replace

// Merge
use "data/usdb_clean.dta", clear
merge 1:1 state using "data/poverty.dta"

tab _merge
// Check if anything didn't match
list state if _merge != 3

drop _merge
save "data/us_map_data.dta", replace


/*------------------------------------------------------------------------------
  Step 4: Generate choropleth map
------------------------------------------------------------------------------*/

// Basic choropleth
spmap poverty_rate using "data/uscoord" if state != "Alaska" & state != "Hawaii", ///
    id(id) fcolor(Reds) ///
    clmethod(quantile) clnumber(5) ///
    title("Poverty Rate by State (Continental US)") ///
    subtitle("Source: US Census Bureau, ACS 2023") ///
    legend(title("Poverty Rate (%)") position(5) size(medium))
graph export "output/fig_choropleth.png", replace width(1200) height(900)





	 
