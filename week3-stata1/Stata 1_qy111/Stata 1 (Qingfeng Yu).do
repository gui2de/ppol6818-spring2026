***Stata 1, Qingfeng Yu***

***Question 1***
**Prepare data
cd "H:\Experimental_Design\stata1"

rename primary_teacher teacher
merge m:1 teacher using "teacher.dta"
drop _merge

merge m:1 school using "school.dta"
drop _merge

merge m:1 subject using "subject.dta"
drop _merge

**a. For students in South school, their mean attendance is 177.47 days per year.
sum attendance if loc=="South"

**b. Among students enrolled in high school, 44.23% of them have a primary teacher who teaches a tested subject.
tab tested if level=="High"

**c.  3.60144
summarize gpa

**d. Joseph Darby Middle School- 177.44; Mahatma Ghandi Middle School-177.33; Malala Yousafzai Middle School-177.55
keep if level == "Middle"
bysort school: summarize attendance

***Question 2***
**a. Yes, this condition holds.
bysort pixel: egen payout_sd = sd(payout)
generate pixel_consistent = (payout_sd == 0)
sum pixel_consistent

**b. 
bysort village: egen num_pixels = nvals(pixel)
generate pixel_village = (num_pixels > 1)
tab pixel_village

**c.
*Category 1
generate village_category = .
replace village_category = 1 if pixel_village == 0

bysort village: egen village_payout_min = min(payout)
bysort village: egen village_payout_max = max(payout)
*Category 2
replace village_category = 2 if pixel_village == 1 & village_payout_min == village_payout_max
*Category 3
replace village_category = 3 if pixel_village == 1 & village_payout_min != village_payout_max

count
tab village_category

***Question 3***
**1
rename Rewiewer1 reviewer1
rename Reviewer2 reviewer2
rename Reviewer3 reviewer3
rename Review1Score score1
rename Reviewer2Score score2
rename Reviewer3Score score3

*reshape to long format
reshape long reviewer score, i(proposal_id) j(rpos)

*Compute each reviewer's mean
bysort reviewer: egen r_mean = mean(score)
bysort reviewer: egen r_sd   = sd(score)

*Standardize each score
gen stand_score = (score - r_mean) / r_sd
sum stand_score
tab stand_score

*Reshape back to wide format
drop r_mean r_sd
reshape wide reviewer score stand_score, i(proposal_id) j(rpos)
rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

**2
generate average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score)/3

**3
egen rank = rank(average_stand_score), field
sort rank
list proposal_id average_stand_score rank in 1/50


***Question 4***
*Set the environment
global wd "H:\Experimental_Design\stata1"
global excel_t21 "$wd\q4_Pakistan_district_table21.xlsx"
clear

tempfile table21
save `table21', replace emptyok

forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring
	*display the loop number
	display as error `i' 
	
	*keep only those rows that have "18 AND"
	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1
	*there are 3 of them, but we want the first one
	keep in 1 
	rename TABLE21PAKISTANICITIZEN1 table21

	* Fill in the values which are not spaces correctly.
	   ds
    local vars `r(varlist)'
    forvalues j = 1/13 {
        gen V`j' = ""
    }
    gen __k = 0
    foreach v of local vars {
        replace __k = __k + 1 if `v' != ""
        forvalues j = 1/13 {
            replace V`j' = `v' if __k == `j' & `v' != ""
        }
    }
    drop __k
    keep V1-V13
	
	*Keep track of the sheet we imported the data from
	gen table=`i' 
	append using `table21' 
	save `table21', replace
}
use `table21', clear
format %40s V1-V13
* Change the"-" into missing value, and change the data format into numeric.
destring V2-V13, replace force
br



***Question 4***
clear all
set more off

* 1) Edit your HTML path
local f "C:\Users\LENOVO\OneDrive\Experimental Design\Stata 1\shl_ps0101114.html"

* 2) Safety check
capture confirm file "`f'"
if _rc {
    di as err "File not found: `f'"
    exit 601
}

* 3) Read full HTML into one long string
set obs 1
gen strL html = fileread("`f'")

* 4) School name & code (format: "... - PS0101114")
gen str80 school_name = ""
gen str20 school_code = ""
replace school_name = ustrtrim(ustrregexs(1)) if ustrregexm(html, "([A-Z0-9 \.\&\-\(\)']+)\s*-\s*(PS[0-9]+)")
replace school_code = ustrtrim(ustrregexs(2)) if ustrregexm(html, "([A-Z0-9 \.\&\-\(\)']+)\s*-\s*(PS[0-9]+)")

* 5) Required variables
gen n_test = .
replace n_test = real(ustrregexs(1)) if ustrregexm(html, "WALIOFANYA MTIHANI\s*:\s*([0-9]+)")

gen avg_score = .
replace avg_score = real(ustrregexs(1)) if ustrregexm(html, "WASTANI WA SHULE\s*:\s*([0-9]+(?:\.[0-9]+)?)")

gen byte under40 = .
replace under40 = 1 if ustrregexm(html, "KUNDI LA SHULE\s*:\s*Wanafunzi\s+chini\s+ya\s+40")
replace under40 = 0 if under40==. & ustrregexm(html, "KUNDI LA SHULE\s*:")

gen council_rank=.  
gen council_total=.
replace council_rank  = real(ustrregexs(1)) if ustrregexm(html, "KIHALMASHAURI\s*:\s*([0-9]+)\s+kati\s+ya\s+([0-9]+)")
replace council_total = real(ustrregexs(2)) if ustrregexm(html, "KIHALMASHAURI\s*:\s*([0-9]+)\s+kati\s+ya\s+([0-9]+)")

gen region_rank=.   
gen region_total=.
replace region_rank  = real(ustrregexs(1)) if ustrregexm(html, "KIMKOA\s*:\s*([0-9]+)\s+kati\s+ya\s+([0-9]+)")
replace region_total = real(ustrregexs(2)) if ustrregexm(html, "KIMKOA\s*:\s*([0-9]+)\s+kati\s+ya\s+([0-9]+)")

gen national_rank=. 
gen national_total=.
replace national_rank  = real(ustrregexs(1)) if ustrregexm(html, "KITAIFA\s*:\s*([0-9]+)\s+kati\s+ya\s+([0-9]+)")
replace national_total = real(ustrregexs(2)) if ustrregexm(html, "KITAIFA\s*:\s*([0-9]+)\s+kati\s+ya\s+([0-9]+)")

* 6) Keep only the final 1-row school-level dataset
keep school_name school_code n_test avg_score under40 ///
     council_rank council_total region_rank region_total ///
     national_rank national_total

order school_name school_code n_test avg_score under40 ///
      council_rank council_total region_rank region_total ///
      national_rank national_total

br
****************************************************



