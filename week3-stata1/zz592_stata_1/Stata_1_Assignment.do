*Stata 1 Assignment
*Author: Zimu Zhai (Arlo)
*NetID: zz592
*Date: 02/08/2026
**********************************************
clear all
******* Question 1 ***********************

* Set the data folder
global data_dir "/Users/zhongguochimingdijianjian/Desktop/Experiment Design/week_3__STATA_1_export/q1_data_export"

* Build student-level analysis file by merging datasets

use "${data_dir}/teacher.dta", clear
rename teacher primary_teacher
save "${data_dir}/teacher_merge.dta", replace

use "${data_dir}/student.dta", clear
merge m:1 primary_teacher using "${data_dir}/teacher_merge.dta"
tab _merge
drop _merge

merge m:1 school using "${data_dir}/school.dta"
tab _merge
drop _merge

merge m:1 subject using "${data_dir}/subject.dta"
tab _merge
drop _merge

save "${data_dir}/q1_analysis_studentlevel.dta", replace

* (a) 
summarize attendance if loc == "South"
** Mean attendance (South) = 177.4776 days.

* (b) 
summarize tested if level == "High"
** Among high school students, approximately 44.23% have a primary teacher who teaches a tested subject.

* (c) 
summarize gpa
** Mean GPA of all students is 3.60144.

* (d) 
bysort school:summarize attendance if level == "Middle"
** Joseph Darby Middle School: 177.4408.
** Mahatma Ghandi Middle School: 177.3344.
** Malala Yousafzai Middle School: 177.5478.

******* Question 2 ***********************

clear
use "${data_dir}/q2_village_pixel.dta", clear
describe

* (a)
bysort pixel: egen payout_min = min(payout)
bysort pixel: egen payout_max = max(payout)

gen pixel_consistent = (payout_min == payout_max)
label define pc 0 "not consistent" 1 "consistent"
label values pixel_consistent pc

tab pixel_consistent
**The payout status is perfectly consistent within each pixel.

* (b)
bysort village pixel: gen tag_pixel = (_n == 1)
bysort village: egen n_pixel_in_village = total(tag_pixel)
gen pixel_village = (n_pixel_in_village > 1)
label define pv 0 "single pixel" 1 "multiple pixels"
label values pixel_village pv

tab pixel_village
** 12.94% of villages span multiple pixels.

* (c)
bysort village payout: gen tag_payout = (_n == 1)
bysort village: egen n_payout_in_village = total(tag_payout)

gen village_case = .
replace village_case = 1 if n_pixel_in_village == 1
replace village_case = 2 if n_pixel_in_village > 1 & n_payout_in_village == 1
replace village_case = 3 if n_pixel_in_village > 1 & n_payout_in_village > 1

label define vc 1 "single pixel" ///
               2 "multi pixel, same payout" ///
               3 "multi pixel, different payout"
label values village_case vc

tab village_case

preserve
keep if village_case == 2
sort village hhid
list village hhid pixel payout, noobs
restore
**First, 87.06% of households (834 out of 958) belong to villages that are entirely contained within a single pixel. Second, 5.22% of households (50 households) are in villages that span multiple pixels but have the same payout status across pixels. A list of household IDs in these villages is reported as required. Finally, 7.72% of households (74 households) belong to villages that span multiple pixels and have different payout statuses across pixels. These villages represent the cases that pose a potential problem for the experiment.
**The list of household IDs that span multiple pixels but have the same payout status across pixels is generated in the do-file and exported for reference.


******* Question 3 ***********************

use "${data_dir}/q3_proposal_review.dta", clear
describe

* (a) Generate standardized score variables
rename Rewiewer1 Reviewer1
bysort Reviewer1: egen r1_mean = mean(Review1Score)
bysort Reviewer1: egen r1_sd   = sd(Review1Score)
gen stand_r1_score = (Review1Score - r1_mean) / r1_sd

bysort Reviewer2: egen r2_mean = mean(Reviewer2Score)
bysort Reviewer2: egen r2_sd   = sd(Reviewer2Score)
gen stand_r2_score = (Reviewer2Score - r2_mean) / r2_sd

bysort Reviewer3: egen r3_mean = mean(Reviewer3Score)
bysort Reviewer3: egen r3_sd   = sd(Reviewer3Score)
gen stand_r3_score = (Reviewer3Score - r3_mean) / r3_sd

summarize stand_r1_score stand_r2_score stand_r3_score

* (b)
egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)

* (c)
gsort -average_stand_score
gen rank = _n


******* Question 4 ***********************

global excel_t21 "$data_dir/q4_Pakistan_district_table21.xlsx"
clear

*setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135)
forvalues i = 1/135 {

    import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring
    display as error "`i'"

    keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND") == 1
    keep in 1

    rename TABLE21PAKISTANICITIZEN1 table21
    gen table = `i'
*Identify all variables in the current sheet
    ds
    local allvars `r(varlist)'
*Exclude non-numeric candidates (text label and sheet id)	
    local candvars : list allvars - table21
    local candvars : list candvars - table
*Clean and convert candidate columns to numeric
    foreach x of local candvars {
        capture confirm variable `x'
        if _rc continue
        capture replace `x' = subinstr(`x', ",", "", .)
        capture destring `x', replace force
    }
*Collect columns with valid numeric values and compress into v2–v13
    local j = 2
    foreach x of local candvars {
        capture confirm variable `x'
        if _rc continue
        quietly summarize `x'
        if r(N) > 0 & r(min) < . {
            gen v`j' = `x'
            local ++j
            if `j' > 13 continue, break
        }
    }
*Fill remaining columns with missing values if fewer than 12 numeric columns
    forvalues k = `j'/13 {
        gen v`k' = .
    }
*Keep only the standardized output variables
    keep table table21 v2-v13
   
    append using `table21'
    save `table21', replace
}

*Load the tempfile
use `table21', clear


** I loop through all 135 district tables and extract the "18 AND ABOVE" row from each sheet. I then retain columns 2–13 to construct a district-level dataset, with one row per district.


******* Question 5 ***********************

use "${data_dir}/q5_Tz_student_roster_html.dta", clear

* Keep a working copy of the raw HTML
gen html = s


* School name + school code (in the same line)
gen school_name = regexs(1) if regexm(html, "([A-Z][A-Z ]+) - (PS[0-9]+)")
gen school_code = regexs(2) if regexm(html, "([A-Z][A-Z ]+) - (PS[0-9]+)")


* Number of students who took the test

gen n_students = real(regexs(1)) if regexm(html, "WALIOFANYA MTIHANI *: *([0-9]+)")

* School average score

gen avg_score = real(regexs(1)) if regexm(html, "WASTANI WA SHULE *: *([0-9.]+)")

* Student group (binary: under 40 vs 40+)
* First grab the group label, then map to binary.

gen school_group = regexs(1) if regexm(html, "KUNDI LA SHULE *: *([A-Za-z]+)")

gen group_under40 = .
replace group_under40 = 1 if regexm(html, "Under 40") | school_group=="Wanafunzi"
replace group_under40 = 0 if regexm(html, "40 or above") | (school_group!="" & school_group!="Wanafunzi")


* Rankings: council / region / national
gen rank_council   = .
gen total_council  = .
gen rank_region    = .
gen total_region   = .
gen rank_national  = .
gen total_national = .

* Use uppercase copy to avoid case issues (kati ya vs KATI YA)
gen html_up = upper(html)

* Council ranking (KIHALMASHAURI: X KATI YA Y)
replace rank_council  = real(ustrregexs(1)) if ustrregexm(html_up, "KIHALMASHAURI\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")
replace total_council = real(ustrregexs(2)) if ustrregexm(html_up, "KIHALMASHAURI\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")

* Region ranking (KIMKOA: X KATI YA Y)
replace rank_region  = real(ustrregexs(1)) if ustrregexm(html_up, "KIMKOA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")
replace total_region = real(ustrregexs(2)) if ustrregexm(html_up, "KIMKOA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")

* National ranking (KITAIFA: X KATI YA Y)
replace rank_national  = real(ustrregexs(1)) if ustrregexm(html_up, "KITAIFA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")
replace total_national = real(ustrregexs(2)) if ustrregexm(html_up, "KITAIFA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")

* Final dataset
keep school_name school_code n_students avg_score group_under40 rank_council rank_region rank_national

list


******* Bonus Question ***********************

clear all
set more off
local fpath "$data_dir/shl_ps0101114.html"

* Read HTML into one long string

clear
set obs 1
gen strL html = " "

file open fh using `"`fpath'"', read text
file read fh line
while r(eof)==0 {
    replace html = html + " " + `"`line'"' in 1
    file read fh line
}
file close fh

* clean whitespace
replace html = ustrregexra(html, "[\r\n\t]+", " ")
replace html = ustrregexra(html, "\s+", " ")
replace html = ustrtrim(html)

* Split into <TR> rows using </TR> as separator

gen strL tr = html
replace tr = ustrregexra(tr, "</TR>", "<<<ROW>>>")
replace tr = ustrregexra(tr, "</tr>", "<<<ROW>>>")

split tr, parse("<<<ROW>>>") gen(r)
drop tr html

gen id = 1
reshape long r, i(id) j(k)
drop if missing(r)

replace r = ustrtrim(r)

* keep only rows that contain a candidate id
keep if ustrregexm(r, "PS[0-9]+-[0-9]+")
rename r rowhtml
drop id k

* Extract cand_id + schoolcode

gen cand_id = ustrregexs(1) if ustrregexm(rowhtml, "(PS[0-9]+-[0-9]{3,5})")
gen schoolcode = ustrregexs(1) if ustrregexm(cand_id, "^(PS[0-9]+)")

* Extract prem_number, gender, name

gen prem_number = ustrregexs(1) if ustrregexm(rowhtml, "PS[0-9]+-[0-9]{3,5}.*?<P[^>]*>\s*([0-9]{6,})\s*</")

gen gender = ustrregexs(1) if ustrregexm(rowhtml, ">\s*([MF])\s*</")

gen name = ustrregexs(1) if ustrregexm(rowhtml, "([A-Z][A-Z '.-]{3,})\s*</")
replace name = ustrtrim(name)

* Extract subject grades

gen kiswahili = ustrregexs(1) if ustrregexm(rowhtml, "Kiswahili\s*-\s*([A-Z])")
gen english   = ustrregexs(1) if ustrregexm(rowhtml, "English\s*-\s*([A-Z])")
gen maarifa   = ustrregexs(1) if ustrregexm(rowhtml, "Maarifa\s*-\s*([A-Z])")
gen hisabati  = ustrregexs(1) if ustrregexm(rowhtml, "Hisabati\s*-\s*([A-Z])")
gen science   = ustrregexs(1) if ustrregexm(rowhtml, "Science\s*-\s*([A-Z])")
gen uraia     = ustrregexs(1) if ustrregexm(rowhtml, "Uraia\s*-\s*([A-Z])")
gen average   = ustrregexs(1) if ustrregexm(rowhtml, "Average Grade\s*-\s*([A-Z])")

* Final dataset

keep schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

order schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

compress

count
list cand_id prem_number gender name in 1/5, noobs

save "BQ_student_level.dta", replace
export delimited using "BQ_student_level.csv", replace
