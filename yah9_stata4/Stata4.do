// Housekeeping:
if "`c(username)'" == "yousrahussain" {
    global wd "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Stata Assignment"
}

// Replace 'YourName' with your computer's actual username and the path below
else if "`c(username)'" == "YourName" { 
    global wd "C:/Users/YourName/Documents/StataProject"  
}

// Safety check
else {
    display as error "User '`c(username)'' not recognized. Please update the filepath logic."
    exit
}

cd "$wd"

ssc install distinct
ssc install unique
/*

Between 2010 and 2015, the number of wards in Tanzania went from 3,333 to 3,944. This happened by dividing existing ward into 2 (or in some cases three or more) new wards. You have to create a dataset where each row is a 2015 ward matched with the corresponding parent ward from 2010. It's a trivial task to match wards that weren't divided, but it's impossible to match wards that were divided without additional information. Thankfully, we had access to shapefiles from 2012 and 2017. We used ArcGIS to create a new dataset that tells us the percentage area of 2015 ward that overlaps a 2010 ward. You can use information from this dataset to match wards that were divided. Can you generate the following insights:
1)	How many wards exist both in 2010 and 2015?
2)	How many are "parentless" wards (i.e. exist in 2015 but not in 2010)
3)	How many are "orphan" wards? (i.e. exist in 2010 but not in 2015)
4)	How many wards were divided into two wards between 2010 and 2015?
5)	How many wards were divided into three or more wards between 2010 and 2015?
6)	List regions along with the rate of ward division

*/

* GIS Mapping File 

use "Tz_GIS_2015_2010_intersection.dta", clear

gsort ward_gis_2017 -percentage
by ward_gis_2017: keep if _n == 1


*Rename 
rename ward_gis_2017 ward_15
rename district_gis_2017 district_15
rename ward_gis_2012 ward_10
rename district_gis_2012 district_10

*Standardize geography names 
foreach var of varlist district_10 ward_10 district_15 ward_15 {
    replace `var' = lower(`var')
    replace `var' = trim(itrim(`var'))
}

replace district_10 = subinstr(district_10, "wilaya ya ", "", .)
replace district_10 = subinstr(district_10, " township authority", "", .)
replace district_10 = subinstr(district_10, " district", "", .)
replace district_10 = subinstr(district_10, " municipal", "", .)
replace district_10 = subinstr(district_10, " city", "", .)
replace district_10 = subinstr(district_10, " council", "", .)
replace district_10 = trim(itrim(district_10)) // Final trim just in case spaces were left behind

replace district_15 = subinstr(district_15, "wilaya ya ", "", .)
replace district_15 = subinstr(district_15, " township authority", "", .)
replace district_15 = subinstr(district_15, " district", "", .)
replace district_15 = subinstr(district_15, " municipal", "", .)
replace district_15 = subinstr(district_15, " city", "", .)
replace district_15 = subinstr(district_15, " council", "", .)
replace district_15 = trim(itrim(district_15)) // Final trim just in case

preserve
    keep district_15 ward_15 district_10 ward_10
    save "GIS_2015_Crosswalk.dta", replace
restore

*Count how many 2015 wards belong to each 2010 parent

bysort district_10 ward_10: gen split_count = _N
bysort district_10 ward_10: keep if _n == 1

keep district_10 ward_10 split_count
save "GIS_2010_Level_Cleaned.dta", replace

//2010 data

*Load the master 2010 election dataset
use "Tz_elec_10_clean.dta", clear

*Same cleaning
foreach var of varlist district_10 ward_10 {
    replace `var' = lower(`var')
    replace `var' = trim(itrim(`var'))
}
replace district_10 = subinstr(district_10, "wilaya ya ", "", .)
replace district_10 = subinstr(district_10, " township authority", "", .)
replace district_10 = subinstr(district_10, " district", "", .)
replace district_10 = subinstr(district_10, " municipal", "", .)
replace district_10 = subinstr(district_10, " city", "", .)
replace district_10 = subinstr(district_10, " council", "", .)
replace district_10 = trim(itrim(district_10))


* Merge the election data with the cleaned GIS data
merge 1:1 district_10 ward_10 using "GIS_2010_Level_Cleaned.dta"


// Fuzzy Matching 

*Successful exact matches 
preserve
    keep if _merge == 3 // Keep only perfect matches
    drop _merge         
    save "Perfect_Matches.dta", replace
restore

*Did not match
preserve
    keep if _merge == 2 
    drop _merge
    gen id_gis = _n     
    save "Unmatched_GIS.dta", replace
restore

keep if _merge == 1 //Keep only unmatched master (Election) data
drop _merge
gen id_elec = _n    // Create a unique temporary ID number

**Fuzzy Match
reclink district_10 ward_10 using "Unmatched_GIS.dta", idmaster(id_elec) idusing(id_gis) gen(match_score) minscore(0.75)

*Matches we trust
gen is_fuzzy_match = (match_score >= 0.85 & !missing(match_score))

*Drop the temporary variables 
drop Udistrict_10 Uward_10 match_score id_elec id_gis

append using "Perfect_Matches.dta"

save "Final_2010_Election_Matched.dta", replace


***Answering questions******

* Q1: How many wards exist both in 2010 and 2015? (Undivided)
* Rows where the split count is exactly 1
count if split_count == 1

// 1559 wards exist in both 2010 and 2015 

* Q3: How many are "orphan" wards? (Exist in 2010 but not in 2015)
* Rows where the GIS split count never matched)
count if missing(split_count)

// 1,506 wards are orphan wards

* Q4: How many wards were divided into exactly two wards?
* Rows where the split count is exactly 2
count if split_count == 2

// 252 wards were divided into two wards. 

* Q5: How many wards were divided into three or more wards?
* Count rows where the split count is 3 or greater
count if split_count >= 3

// 1,523 wards were divided into three or more wards. 

* Q6: List regions along with the rate of ward division

gen is_divided = (split_count > 1) if !missing(split_count) //Binary variable (1 or 0) indicating if a ward was divided. 

collapse (mean) division_rate=is_divided (sum) total_divided=is_divided (count) total_wards=is_divided, by(region_10)

* Decimal to percentage 
replace division_rate = division_rate * 100
format division_rate %9.1f // Format to 1 decimal place

* Final table 
list region_10 division_rate total_divided total_wards

/*

+------------------------------------------------+
     |     region_10   divisi~e   total_~d   total_~s |
     |------------------------------------------------|
  1. |        arusha       23.2         19         82 |
  2. | dar es salaam          .          0          0 |
  3. |        dodoma        5.7          5         88 |
  4. |        iringa        5.1          5         99 |
  5. |        kagera        3.9          5        128 |
     |------------------------------------------------|
  6. |        kigoma       18.2          6         33 |
  7. |   kilimanjaro       11.8          9         76 |
  8. |         lindi       13.7         10         73 |
  9. |       manyara       17.6         16         91 |
 10. |          mara       12.8         12         94 |
     |------------------------------------------------|
 11. |         mbeya       10.1         12        119 |
 12. |      morogoro       34.8         31         89 |
 13. |        mtwara       23.2         22         95 |
 14. |        mwanza       20.3         30        148 |
 15. |         pwani        9.2          8         87 |
     |------------------------------------------------|
 16. |         rukwa       33.3          8         24 |
 17. |        ruvuma       13.6         11         81 |
 18. |     shinyanga       17.0         25        147 |
 19. |       singida        7.1          3         42 |
 20. |        tabora       19.8         16         81 |
     |------------------------------------------------|
 21. |         tanga       10.6         16        151 |
     +------------------------------------------------+



*/

**** Q2: How many are "parentless" wards (i.e. exist in 2015 but not in 2010)?

use "Tz_elec_15_clean.dta", clear

*Same cleaning
foreach var of varlist district_15 ward_15 {
    replace `var' = lower(`var')
    replace `var' = trim(itrim(`var'))
}

replace district_15 = subinstr(district_15, "wilaya ya ", "", .)
replace district_15 = subinstr(district_15, " township authority", "", .)
replace district_15 = subinstr(district_15, " district", "", .)
replace district_15 = subinstr(district_15, " municipal", "", .)
replace district_15 = subinstr(district_15, " city", "", .)
replace district_15 = subinstr(district_15, " council", "", .)
replace district_15 = trim(itrim(district_15)) // Final trim just in case

* Merge the election data with the cleaned GIS data
merge 1:1 district_15 ward_15 using "GIS_2015_Crosswalk.dta"

* 2015 records from the master dataset that couldn't find a 2010 GIS match
count if _merge == 1

// 1,591 are parentless wards. 


********
**Question 2
********

/*

1.	Develop some data generating process for data X's and for outcome Y, with a treatment variable and treatment effect (0.3 sd) 
2.	This DGP should include: 
1.	In addition to creating Y & treatment variables, also create confounder, mediator and a collider var (wrt Ys & treatment)
2.	Each of these covariates should be clearly labelled (i.e. put a comment in the code next to where you generate each covariate explaining how it affects the generation of Y).
3.	This process need not be complex, you could do everything with basic operations and uniformly distributed random values plus some dataset manipulation.

*/

/*
// A confounder is a variable that influences both Treatment and Outcome
// Mediator is the mechanism through which the treatment works. Treatment -> Mediator ->  Outcome.
// A collider is the exact opposite of a confounder. It is a variable that is caused by both the Treatment and the Outcome.

*/




capture program drop sim_dgp

program sim_dgp, rclass
    syntax, n(integer)
    
    clear
    set obs `n'

    //Generate Variables
	
	//Connfounder 
    gen xcon = rnormal(0, 1)
	
	//Covariates
    gen x1 = rnormal(0, 1)      
    gen x2 = runiform(0, 1)     
    
	
   //Treatment Assignment (influenced by confounder)
   // Subjects with a higher 'xcon' score are more likely to be treated
    gen prob_treat = normal(xcon) 
    gen treatment = (runiform() < prob_treat)

    //Mediator 
    // xmed is driven by its own baseline noise (x3) AND the treatment
	gen x3 = rnormal(0, 1) 
    gen xmed = (0.8 * treatment) + x3 

    gen error = rnormal(0, 1)
    gen tau = 0.3
    
    // DGP
    gen y = (0.6 * xcon) + (0.4 * x1) + (0.4 * x2) + (0.5 * xmed) + (tau * treatment) + error

	// Collider 
    // The collider is caused by BOTH the treatment and the final outcome Y
    gen x4 = rnormal(0, 1) 
    gen xcoll = x4 + (0.7 * treatment) + (0.7 * y) 

    //Models 
    reg y treatment
    return scalar beta1 = _b[treatment]

    reg y treatment x1 x2 xcon 
    return scalar beta2 = _b[treatment]

    reg y treatment x1 xcon xmed 
    return scalar beta3 = _b[treatment]

    reg y treatment x1 x2 xcon xmed 
    return scalar beta4 = _b[treatment]

    reg y treatment x1 xcon if xcoll > 0
    return scalar beta5 = _b[treatment]
end




tempfile all_results
save `all_results', emptyok replace

foreach n in 50 100 500 1000 5000 {
    display "Running simulation for N = `n'..."
    
    
    clear
    
    //Simulation
    simulate b1=r(beta1) b2=r(beta2) b3=r(beta3) b4=r(beta4) b5=r(beta5), ///
        reps(200) seed(12345): sim_dgp, n(`n')
        
    gen N = `n'
    append using `all_results'
    save `all_results', replace
}

//Graphing results 

use `all_results'

// Mean and SD for each sample size 
collapse (mean) mean_b1=b1 mean_b2=b2 mean_b3=b3 mean_b4=b4 mean_b5=b5 ///
         (sd)   sd_b1=b1   sd_b2=b2   sd_b3=b3   sd_b4=b4   sd_b5=b5, by(N)

// Generating Variance
gen var_b1 = sd_b1^2
gen var_b2 = sd_b2^2
gen var_b3 = sd_b3^2
gen var_b4 = sd_b4^2
gen var_b5 = sd_b5^2

//Mean convergence 
list N mean_b1 mean_b2 mean_b3 mean_b4 mean_b5, sep(0)
//Variance shrinking
list N var_b3 var_b4, sep(0)

//Mean Beta (Biasedness & Convergence) 
twoway (connected mean_b1 N, msymbol(O) lcolor(red) mcolor(red)) ///
       (connected mean_b2 N, msymbol(S) lcolor(blue) mcolor(blue)) ///
       (connected mean_b3 N, msymbol(D) lcolor(green) mcolor(green)) ///
       (connected mean_b4 N, msymbol(T) lcolor(emerald) mcolor(emerald)) ///
       (connected mean_b5 N, msymbol(X) lcolor(purple) mcolor(purple)), ///
       yline(0.3, lpattern(dash) lcolor(black)) text(0.32 4000 "True Direct Effect (0.3)") ///
       yline(0.7, lpattern(dash) lcolor(gs8)) text(0.72 4000 "True Total Effect (0.7)") ///
       title("Convergence of Treatment Effect Estimates") ///
       subtitle("Mean Beta across 200 Iterations by Sample Size") ///
       xtitle("Sample Size (N)") ytitle("Estimated Beta (Mean)") ///
       legend(order(1 "1. Naive" 2 "2. Total (Controls Confounder)" ///
                    3 "3. Direct (Controls Med)" 4 "4. Direct (+ X2)" 5 "5. Collider Bias") cols(2) size(small)) ///
       name(mean_plot, replace)

//Variance of Beta (Efficiency)

twoway (connected var_b3 N, msymbol(D) lcolor(green) mcolor(green)) ///
       (connected var_b4 N, msymbol(T) lcolor(emerald) mcolor(emerald)), ///
       title("Variance of Direct Effect Estimates as N Grows") ///
       subtitle("Comparing models with and without the extra covariate X2") ///
       xtitle("Sample Size (N)") ytitle("Variance of Estimated Beta") ///
       legend(order(1 "Model 3 (Without X2)" 2 "Model 4 (With X2)") ring(0) pos(1)) ///
       name(var_plot, replace)



*********
**Question 3
**********


ssc install spmap, replace
ssc install shp2dta, replace
ssc install mif2dta, replace

clear 

spshape2dta "Wards_from_2022.shp", replace

import delimited "ACS_5-Year_Demographic_Characteristics_DC_Ward.csv", clear

rename namelsad _ID

replace _ID = subinstr(_ID, "Ward ", "", .)
destring _ID, replace

save "ACS_Clean.dta", replace

//Merge 
use "Wards_from_2022.dta", clear
merge 1:1 _ID using "ACS_Clean.dta"

drop _merge

rename dp05_0018e median_age

save "merged_data", replace

use "merged_data.dta", clear
spmap median_age using "Wards_from_2022_shp.dta", id(_ID) clnumber(5) clmethod(quantile) fcolor(BuRd) ndfcolor(gs8) ndlab("Missing") legend(size(*1.4)) title ("Median Age By Ward") subtitle("Washington D.C. (2000)" " ")







