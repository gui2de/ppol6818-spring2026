*12345678901234567890123456789012345678901234567890123456789012345678901234567890
// capture log close
clear all
set more off

*	************************************************************************
* 	File-Name: 	ps1_dofile_q1-5_bonus_pd757.do
*	Log-file:	na
*	Date:  		02/04/2026
*	Author: 	Puran Dou
*	Data Used:  various
*	Output		various
*	Purpose:   	.do file for PPOL-6818 assignment: stata 1
*	************************************************************************


*	************************************************************************
*	Set directory
*	************************************************************************

global root "/Users/oldfarmerdou/Dropbox/ExperimentalDesign/assignment_stata1"
cap mkdir "$output"
global output "$root/output"

*	************************************************************************
*	Q1
*	************************************************************************

global q1 "$root/q1_data"

* merge dataset
use "$q1/student.dta", clear

** merge on teacher
rename primary_teacher teacher
merge m:1 teacher using "$q1/teacher.dta"
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             4,490  (_merge==3)
    -----------------------------------------
*/

** merge school
drop _merge
merge m:1 school using "$q1/school.dta"
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             4,490  (_merge==3)
    -----------------------------------------
*/

** merge subject
drop _merge
merge m:1 subject using "$q1/subject.dta"
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             4,490  (_merge==3)
    -----------------------------------------
*/

** sanity check
describe
sum, detail
drop _merge

save "$output/q1_student_teacher_school_subject_merged.dta", replace


* (a) What is the mean student attendance for schools located in the "South"? 
sum attendance if loc == "South"
/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180

*/


* (b) Among students enrolled in high school, what proportion have a primary teacher who teaches a tested subject, i.e. "tested" = 1?
tab tested if level == "High"
/*
     tested |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        769       55.77       55.77
          1 |        610       44.23      100.00
------------+-----------------------------------
      Total |      1,379      100.00
*/
* Among high school students, 44.23% have a primary teacher who teaches a tested subject (tested=1).

* (c) What is the mean gpa of all students in the district? 
sum gpa
/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334
*/
* The mean gpa of all students in the district is 3.60144.

* (d) What is the mean attendance for each middle school?
preserve
	keep if level=="Middle"
	tabstat attendance, by(school)
restore
/*
          school |      Mean
-----------------+----------
Joseph Darby Mid |  177.4408
Mahatma Ghandi M |  177.3344
Malala Yousafzai |  177.5478
-----------------+----------
           Total |  177.4514
----------------------------
*/
* The mean attendance for Joseph Darby Middle School is 177.4408 days, for Mahatma Ghandi Middle School is 177.3344 days, and for Malala Yousafzai Middle School is 177.5478 days.



*	************************************************************************
*	Q2
*	************************************************************************

use "$root/q2_village_pixel.dta", clear

* a) The payout status should be consistent within each pixel. Verify whether this condition holds.

bysort pixel: egen payout_min = min(payout)
bysort pixel: egen payout_max = max(payout)

replace pixel_consistent = 1 if payout_min == payout_max
replace pixel_consistent = 0 if payout_min != payout_max

tab pixel_consistent
/*

pixel_consi |
      stent |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        958      100.00      100.00
------------+-----------------------------------
      Total |        958      100.00
*/
* The payout status is consistent within each pixel.


* b) In most cases, households within a village are in the same pixel, but some villages may span multiple pixels (boundary cases).
bysort village: egen n_pixels = nvals(pixel)
gen pixel_village = (n_pixels > 1)
tab pixel_village
/*
pixel_villa |
         ge |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        834       87.06       87.06
          1 |        124       12.94      100.00
------------+-----------------------------------
      Total |        958      100.00

*/
* 12.94% households are within a village are in the same pixel.


* c) For this experiment, villages spanning multiple pixels only pose a problem if they also have different payout statuses across pixels.
gen category = .
bysort village: egen n_payouts = nvals(payout)

replace category = 1 if pixel_village == 0
replace category = 2 if pixel_village == 1 & n_payouts == 1
replace category = 3 if pixel_village == 1 & n_payouts > 1

list hhid if category == 2

preserve
    keep if category == 2
    keep hhid
    export delimited using "$output/q2_hhid_category2.csv", replace
restore


*	************************************************************************
*	Q3
*	************************************************************************

use "$root/q3_proposal_review.dta", clear

* 1. Create standardized score variables for each review: a. stand_r1_score b. stand_r2_score c. stand_r3_score 

** rename
rename Rewiewer1   reviewer_1
rename Reviewer2   reviewer_2
rename Reviewer3   reviewer_3
rename Review1Score    reviewscore_1
rename Reviewer2Score  reviewscore_2
rename Reviewer3Score  reviewscore_3
** reshape
reshape long reviewer_ reviewscore_, i(proposal_id) j(r)

** gen score
bysort reviewer_: egen mean_r = mean(reviewscore_)
bysort reviewer_: egen sd_r   = sd(reviewscore_)

gen stand_score = (reviewscore_ - mean_r) / sd_r


*2. Compute the average standardized score as "average_stand_score" for each proposal 
keep proposal_id r stand_score
reshape wide stand_score, i(proposal_id) j(r)

rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)


*3. Rank proposals based on average_stand_score, where: a. Rank = 1 corresponds to the highest score b. Rank = 128 corresponds to the lowest score
egen rank = rank(-average_stand_score), unique
sort rank


*	************************************************************************
*	Q4
*	************************************************************************

global excel_t21 "$root/q4_Pakistan_district_table21.xlsx"
clear

* set up empty tempfile to append
tempfile master
save `master', replace emptyok

forvalues i = 1/135 {

    * 1. import table
    import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring
    di as error "Processing sheet `i'"

    * 2. change all numeric to string
	ds, has(type numeric)
    if "`r(varlist)'" != "" tostring `r(varlist)', replace force

    capture confirm string variable TABLE21PAKISTANICITIZEN1
    if _rc tostring TABLE21PAKISTANICITIZEN1, replace force

    * 3. find 18 and above + keep first one
    keep if regexm(upper(TABLE21PAKISTANICITIZEN1), "18") & ///
            (regexm(upper(TABLE21PAKISTANICITIZEN1), "ABOVE") | regexm(upper(TABLE21PAKISTANICITIZEN1), "AND"))
    keep in 1

    rename TABLE21PAKISTANICITIZEN1 age_group

    * 4. keep row & build col2-col13
    keep age_group *
    ds age_group, not
    local cols `r(varlist)'

    forvalues k = 2/13 {
        gen str40 col`k' = ""
    }

    foreach v of local cols {

        tempvar vv
        gen str244 `vv' = ""

        capture confirm string variable `v'
        if _rc==0 replace `vv' = `v'
        else      replace `vv' = string(`v')

        replace `vv' = subinstr(`vv', ",", "", .)
        replace `vv' = subinstr(`vv', char(9), "", .)
        replace `vv' = subinstr(`vv', " ", "", .)
        replace `vv' = subinstr(`vv', `"""', "", .)

        replace col2  = `vv' if col2==""  & `vv'!="" & `vv'!="."
        replace col3  = `vv' if col3==""  & `vv'!="" & `vv'!="." & col2!=""
        replace col4  = `vv' if col4==""  & `vv'!="" & `vv'!="." & col3!=""
        replace col5  = `vv' if col5==""  & `vv'!="" & `vv'!="." & col4!=""
        replace col6  = `vv' if col6==""  & `vv'!="" & `vv'!="." & col5!=""
        replace col7  = `vv' if col7==""  & `vv'!="" & `vv'!="." & col6!=""
        replace col8  = `vv' if col8==""  & `vv'!="" & `vv'!="." & col7!=""
        replace col9  = `vv' if col9==""  & `vv'!="" & `vv'!="." & col8!=""
        replace col10 = `vv' if col10=="" & `vv'!="" & `vv'!="." & col9!=""
        replace col11 = `vv' if col11=="" & `vv'!="" & `vv'!="." & col10!=""
        replace col12 = `vv' if col12=="" & `vv'!="" & `vv'!="." & col11!=""
        replace col13 = `vv' if col13=="" & `vv'!="" & `vv'!="." & col12!=""
    }

    gen byte ok12 = (col2!="" & col3!="" & col4!="" & col5!="" & col6!="" & col7!="" & ///
                     col8!="" & col9!="" & col10!="" & col11!="" & col12!="" & col13!="")

    gen int sheet_id = `i'
	
    keep sheet_id age_group col2-col13 ok12

    * append
    append using `master'
    save `master', replace
}

use `master', clear

* destring
destring col2-col13, replace force

count
tab ok12
list sheet_id age_group col2-col13 if ok12==0, clean noobs

drop ok12 age_group
order sheet_id, first
sort sheet_id

save "$output/q4_18plus_cols2_13_all_districts.dta", replace
export delimited using "$output/q4_18plus_cols2_13_all_districts.csv", replace


*	************************************************************************
*	Q5
*	************************************************************************

use "$root/q5/q5_Tz_student_roster_html.dta", clear

* replicate long string
gen strL txt = s

* 1. <br> / </p> / </tr> to newline
replace txt = ustrregexra(txt, "(?i)<br\s*/?>", char(10))
replace txt = ustrregexra(txt, "(?i)</p>|</h\d>|</tr>|</table>|</div>", char(10))

* 2. get rid off <xxx>
replace txt = ustrregexra(txt, "(?s)<[^>]+>", " ")

* 3. get rid off extra spaces
replace txt = ustrregexra(txt, "\s+", " ")
replace txt = ustrtrim(txt)

* take a look
display substr(txt[1],1,400)

* 4. gen col names
gen school_name = ""
gen school_code = ""
gen n_test = .
gen school_avg = .
gen under40 = .
gen council_rank = .
gen council_total = .
gen region_rank = .
gen region_total = .
gen national_rank = .
gen national_total = .


* a. school name and school code
if ustrregexm(txt[1], "(?i).*\b([A-Z][A-Z0-9 ']+PRIMARY\s+SCHOOL)\s*-\s*(PS[0-9]{7,})\b") {
    replace school_name = ustrtrim(ustrregexs(1))
    replace school_code = ustrtrim(ustrregexs(2))
}

* b. Number of students who took the test
if ustrregexm(txt[1], "(?i)WALIOFANYA\s+MTIHANI\s*:\s*([0-9]+)") {
    replace n_test = real(ustrregexs(1))
}

* c. School average score
if ustrregexm(txt[1], "(?i)WASTANI\s+WA\s+SHULE\s*:\s*([0-9]+(\.[0-9]+)?)") {
    replace school_avg = real(ustrregexs(1))
}

* d. Student group 0/1
if ustrregexm(txt[1], "(?i)KUNDI\s+LA\s+SHULE\s*:\s*Wanafunzi\s+chini\s+ya\s+40") {
    replace under40 = 1
}
else if ustrregexm(txt[1], "(?i)KUNDI\s+LA\s+SHULE\s*:\s*.*(40\s+au\s+zaidi|40\s+na\s+zaidi|>=\s*40|40\+)") {
    replace under40 = 0
}

* School ranking
if ustrregexm(txt[1], "(?i)KIHALMASHAURI\s*:\s*([0-9]+)\s*kati\s+ya\s*([0-9]+)") {
    replace council_rank  = real(ustrregexs(1))
	replace council_total = real(ustrregexs(2))
}

if ustrregexm(txt[1], "(?i)KIMKOA\s*:\s*([0-9]+)\s*kati\s+ya\s*([0-9]+)") {
    replace region_rank  = real(ustrregexs(1))
	replace region_total = real(ustrregexs(2))
}

if ustrregexm(txt[1], "(?i)KITAIFA\s*:\s*([0-9]+)\s*kati\s+ya\s*([0-9]+)") {
    replace national_rank  = real(ustrregexs(1))
	replace national_total = real(ustrregexs(2))
}

drop s txt
br
	 
save "$output/q5_school_level.dta", replace
export delimited using "$output/q5_school_level.csv", replace


*	************************************************************************
*	BONUS
*	************************************************************************

use "$root/q5/q5_Tz_student_roster_html.dta", clear

gen strL txt = s

* school_code
gen school_code = ""
if ustrregexm(txt[1], "(?i).*\b([A-Z][A-Z0-9 ']+PRIMARY\s+SCHOOL)\s*-\s*(PS[0-9]{7,})\b") {
    replace school_code = ustrtrim(ustrregexs(2))
}

* find </TR> add separate
gen strL chunk = ustrregexra(txt, "(?is)</TR>", "separate")

* chunk to row
split chunk, parse("separate") gen(row)

* reshape to long
gen id = 1
reshape long row, i(id) j(j)
drop if missing(row)

* keep with cand_id PSxxx
keep if ustrregexm(row, "PS[0-9]+-[0-9]{4}")

* col var
gen cand_id = ""
gen prem_number = ""
gen gender = ""
gen name = ""
gen subject = ""

* cand_id
replace cand_id = ustrregexs(1) if ustrregexm(row, "(?is)>(PS[0-9]+-[0-9]{4})<")

* prem_number
replace prem_number = ustrregexs(1) if ustrregexm(row, "(?is)</TD>\s*<TD[^>]*>.*?>\s*([0-9]{6,})<")

* gender m/f
replace gender = ustrregexs(1) if ustrregexm(row, "(?is)</TD>\s*<TD[^>]*>.*?>\s*([MF])<")

* name
replace name = ustrregexs(1) if ustrregexm(row, "(?is)<P>\s*([A-Z ]+)\s*</FONT>")

* subjects
replace subject = ustrregexs(1) if ustrregexm(row, "(?is)SUBJECTS.*?</TD></TR>|<TD[^>]*>\s*<FONT[^>]*>.*?<P[^>]*>\s*([^<]+Average Grade[^<]+)</FONT>")

replace subject = ustrregexs(1) if ustrregexm(row, "(?is)(Kiswahili\s*-\s*[A-E].*?Average\s+Grade\s*-\s*[A-E])")

* grade
gen kiswahili = ustrregexs(1) if ustrregexm(subject, "(?i)Kiswahili\s*-\s*([A-E])")
gen english = ustrregexs(1) if ustrregexm(subject, "(?i)English\s*-\s*([A-E])")
gen maarifa = ustrregexs(1) if ustrregexm(subject, "(?i)Maarifa\s*-\s*([A-E])")
gen hisabati = ustrregexs(1) if ustrregexm(subject, "(?i)Hisabati\s*-\s*([A-E])")
gen science = ustrregexs(1) if ustrregexm(subject, "(?i)Science\s*-\s*([A-E])")
gen uraia = ustrregexs(1) if ustrregexm(subject, "(?i)Uraia\s*-\s*([A-E])")
gen average = ustrregexs(1) if ustrregexm(subject, "(?i)Average\s+Grade\s*-\s*([A-E])")

keep school_code cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average
order school_code cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

br

save "$output/q5_students_bonus.dta", replace
export delimited using "$output/q5_students_bonus.csv", replace



*	************************************************************************
*							END of do file
*	************************************************************************


