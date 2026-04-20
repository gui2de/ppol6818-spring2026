*==========================================================================
************************* Outlier Checks ********************************
*==========================================================================

clear all
set seed 12345
set obs 500

**DGP 

gen child_id = _n
gen enumerator_id = ceil(runiform()*5)

* Children ages
gen age_months = floor(runiform()*25)

* Total Vaccine Doses 
gen vaccine_count = floor(runiform()*6)

**Errors 

* Age Errors
replace age_months = 99 in 1            
replace age_months = -5 in 2            
replace age_months = 28 in 10/12        

* Vaccine Count Errors
replace vaccine_count = 15 in 3       
replace vaccine_count = -1 in 4         

**HFC: Outlier Checks*****

* Flags for outliers 
gen age_flag = (age_months > 24 | age_months < 0)
gen dose_flag = (vaccine_count > 5 | vaccine_count < 0)

gen is_outlier = (age_flag == 1 | dose_flag == 1)

* Labels for extreme outliers
gen extreme_label = ""
replace extreme_label = string(child_id) if (age_months > 90 | vaccine_count > 10 | age_months < 0 | vaccine_count < 0)

**Scatterplot 


twoway (scatter vaccine_count age_months if is_outlier==0, mcolor(blue%30) msize(small)) ///
       (scatter vaccine_count age_months if is_outlier==1, mcolor(red) msize(medium) mlabel(extreme_label)), ///
       title("HFC Data Quality Monitor: Outlier Check", size(medium)) ///
       subtitle("Nigeria Immunization RCT - Baseline Pilot", size(vsmall)) ///
       xtitle("Child Age (Months)") ytitle("Total Vaccine Doses Recorded") ///
       xlabel(-10(10)30 99) ylabel(-5(5)15) ///
       xline(0 24, lcolor(gs12) lpattern(dash)) ///
       yline(0 5, lcolor(orange) lpattern(dash)) ///
       legend(order(1 "Valid Records" 2 "Flagged Outliers") position(6) ring(1) size(vsmall)) ///
       note("Note: Red points fall outside the valid biological/eligibility range (0-24m, 0-5 doses).")

*Tabular Output

list child_id age_months vaccine_count if is_outlier == 1, table divider





*==========================================================================
************************* Unique ID Checks ********************************
*==========================================================================
global wd "/Users/maren/Desktop/Experimental Design & Implementation/Survey 3"

//ssc install mdesc

clear all
set seed 12345
set obs 500

** DGP
gen child_id = _n
gen enumerator_id = ceil(runiform()*5)
gen village_id = ceil(runiform()*20)
gen surveystatus = 1
gen date = td(13apr2026) + floor(runiform()*5)
format date %td

* Children ages
gen age_months = floor(runiform()*25)

* Total Vaccine Doses
gen vaccine_count = floor(runiform()*6)

** Errors for outlier check
replace age_months = 99 in 1
replace age_months = -5 in 2
replace age_months = 28 in 10/12

replace vaccine_count = 15 in 3
replace vaccine_count = -1 in 4

** Errors for unique ID check
replace child_id = 25 in 50
replace child_id = 25 in 120
replace child_id = 100 in 200
replace child_id = 100 in 350
replace child_id = . in 400



local unique child_id
local enum enumerator_id

***********************************
** Checking for missing child IDs
*********************************** 

count if missing(`unique')
di "`unique' has " r(N) " missing values"

list `unique' `enum' date if missing(`unique')

************************* 
** Duplicates in child ID
*************************

sort `unique', stable
qui by `unique': gen dup = cond(_N==1,0,_n)

count if dup > 0
di "Surveys with duplicate child IDs:"

list `unique' `enum' date village_id surveystatus age_months vaccine_count dup ///
    if dup > 0 & !missing(`unique'), sepby(`unique') abbr(16)

preserve
    keep if dup > 0 & !missing(`unique')
    export excel using "$wd/03_output/duplicate_child_id.xlsx", replace firstrow(variables)
restore











