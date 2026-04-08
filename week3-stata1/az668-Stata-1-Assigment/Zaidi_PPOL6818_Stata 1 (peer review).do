**PPOL 6818: Experimental Design and Implementation
**Assignment: Stata Basic
**Submitted by Aqsa Zaidi
**Date: 7th Feb '26

*global wd "C:\Users\aqsaz\Documents\Georgetown\Spring 2026\Experimental Design\Stata\Assignment-Basic\assignment_ Stata 1"
global data_dir "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 1"

********************************************************************************
******************************QUESTION 1****************************************

**viewing and understanding datasets
use "$data_dir/student.dta"
clear
use "$data_dir/teacher.dta"
clear
use "$data_dir/school.dta"
clear
use "$data_dir/subject.dta"
clear

use "$data_dir/student.dta"
rename primary_teacher teacher
save student_new.dta, replace

**merging datasets
merge m:1 teacher using "$data_dir/teacher.dta"
drop _merge
merge m:1 school using "$data_dir/school.dta"
drop _merge
merge m:1 subject using "$data_dir/subject.dta"
drop _merge

save q1_finaldataset.dta, replace // final dataset with all variables is saved

**analysing as per the questions

**a) What is the mean student attendance for schools located in the "South"? 
summ attendance if loc == "South"
/*  Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180 */

**(b) Among students enrolled in high school, what proportion have a primary teacher who teaches a tested subject, i.e. "tested" = 1? 
summ tested if level == "High"
/*  Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
      tested |      1,379    .4423495    .4968455          0          1 */

**(c) What is the mean gpa of all students in the district? 
summ gpa
/*  Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334 */ 

**(d) What is the mean attendance for each middle school?
tabstat attendance if level == "Middle", by(school)
/*
Summary for variables: attendance
Group variable: school 
          school |      Mean
-----------------+----------
Joseph Darby Mid |  177.4408
Mahatma Ghandi M |  177.3344
Malala Yousafzai |  177.5478
-----------------+----------
           Total |  177.4514
----------------------------  */

clear

********************************************************************************
******************************QUESTION 2****************************************

use "$data_dir/q2_village_pixel.dta"
order hhid

**Part (a)
tab pixel payout // verifying for myself if the payout status is consistent within each pixel
/*1. bysort: perform check within each pixel group
2. payout[1]: the "anchor" (first household's status) (can be any row, I am taking the first row based on conventions)
3. == : returns 1 (match) or 0 (no match)
4. min: if any 0s exist in the group, the whole pixel is marked 0
*/
bysort pixel: egen pixel_consistent = min(payout == payout[1]) 

**Part (b)
*same logic as the previous one, except that instead of 1 it will need to be reported as 0, so I've recoded the values
bysort village: egen pixel_village = min(pixel == pixel[1]) 
recode pixel_village (1=0) (0=1) 
tab pixel_village

**Part (c)
bysort pixel: egen pixel_payout = max(payout)
bysort village: egen village_pixel_payout_var = max(pixel_payout != pixel_payout[1])
gen Value = 1 if pixel_village==0 
replace Value = 2 if pixel_village==1 & village_pixel_payout_var==0 
replace Value = 3 if pixel_village==1 & village_pixel_payout_var==1 
list hhid if Value == 2

/*
     +-----------+
     |      hhid |
     |-----------|
170. | 120507104 |
171. | 120507103 |
172. | 120507102 |
173. | 120507101 |
174. | 120507111 |
     |-----------|
201. | 120508206 |
202. | 120508208 |
203. | 120508209 |
204. | 120508202 |
205. | 120508203 |
     |-----------|
206. | 120508204 |
266. | 120610602 |
267. | 120610604 |
268. | 120610605 |
269. | 120610609 |
     |-----------|
278. | 120611101 |
279. | 120611102 |
280. | 120611108 |
342. | 120813801 |
343. | 120813811 |
     |-----------|
344. | 120813803 |
345. | 120813807 |
346. | 120813804 |
385. | 120814903 |
386. | 120814907 |
     |-----------|
387. | 120814911 |
388. | 120814901 |
534. | 131120506 |
535. | 131120509 |
536. | 131120510 |
     |-----------|
571. | 131221909 |
572. | 131221912 |
573. | 131221901 |
574. | 131221905 |
575. | 131221904 |
     |-----------|
615. | 131424205 |
616. | 131424206 |
617. | 131424211 |
618. | 131424204 |
635. | 131424604 |
     |-----------|
636. | 131424610 |
637. | 131424609 |
638. | 131424602 |
739. | 141728103 |
740. | 141728102 |
     |-----------|
741. | 141728108 |
742. | 141728101 |
950. | 131336107 |
951. | 131336109 |
952. | 131336101 |
     +-----------+
*/

**# Bookmark #1
drop pixel_payout village_pixel_payout_var

save q2_finaldataset.dta, replace

clear

********************************************************************************
******************************QUESTION 3****************************************

use "$data_dir/q3_proposal_review.dta"

**renaming variables so that the reshaping command can be performed smoothly
rename Review1Score Score1
rename Reviewer2Score Score2
rename Reviewer3Score Score3
rename Rewiewer1 Reviewer1

**reshaping data so that each reviewer has one row, instead of each proposal having one row and then generating their standardised scores
reshape long Reviewer Score, i(proposal_id) j(ReviewerNo)

**generating mean and sd for each reviewer
bysort Reviewer: egen mean = mean(Score)
bysort Reviewer: egen sd = sd(Score)
gen Standard_Score = (Score - mean) / sd

drop mean sd

*reshaping back
reshape wide Reviewer Score Standard_Score, i(proposal_id) j(ReviewerNo)

**generating standardised score for each proposal and ranking them
gen average_stand_score = (Standard_Score1 + Standard_Score2 + Standard_Score3)/3

gsort -average_stand_score

gen Rank = _n

save q3_finaldataset.dta, replace

clear

********************************************************************************
******************************QUESTION 4****************************************

global excel_t21 "$data_dir/q4_Pakistan_district_table21.xlsx"

clear

*setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135) this will take 1-5 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
	display as error `i' //display the loop number

	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	
	foreach v of varlist _all {
        capture count if !missing(`v')
        if r(N) == 0 {
            drop `v'
        }
    }
	rename * col#, addnumber
	rename col1 table21
	
	replace table21 = subinstr(table21, char(160), " ", .)
    replace table21 = trim(itrim(table21))
    replace table21 = "18 AND ABOVE" if regexm(table21, "18 AND") | regexm(table21, "OVERALL")

	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}

*load the tempfile

use `table21', clear

*fix column width issue so that it's easy to eyeball the data
format %40s table21 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13 

rename col2 Total_Pop
rename col3 CNICard_Obtained
rename col4 CNICard_Not
rename col5 Male_Total_Pop
rename col6 Male_CNICard_Obtained
rename col7 Male_CNICard_Not
rename col8 Female_Total_Pop
rename col9 Female_CNICard_Obtained
rename col10 Female_CNICard_Not
rename col11 Trans_Total_Pop
rename col12 Trans_CNICard_Obtained
rename col13 Trans_CNICard_Not
rename table District_No

save q4_finaldataset.dta, replace

clear all

********************************************************************************
******************************QUESTION 5****************************************

* Create exactly 1 observation
set obs 1
gen strL html = ""

* Read file into a local macro and append to html
file open fh using "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 1/q5/shl_ps0101114.html", read text

local line ""
file read fh line
while r(eof)==0 {
    replace html = html + `"`line'"' + " "
    file read fh line
}

file close fh


* Extract variables
gen str80 school_name = ""
gen str20 school_code = ""

gen int    n_tested    = .
gen double school_avg  = .

gen str60 group_text   = ""
gen byte   under40     = .

gen str20 council_rnk  = ""
gen str20 region_rnk   = ""
gen str20 national_rnk = ""

* School name + code (not asked by the question but adding extra)
if regexm(html, "([A-Z][A-Z ]+PRIMARY SCHOOL)\s*-\s*(PS[0-9]+)") {
    replace school_name = strtrim(regexs(1))
    replace school_code = regexs(2)
}

* Number tested
if regexm(html, "WALIOFANYA MTIHANI\s*:\s*([0-9]+)") {
    replace n_tested = real(regexs(1))
}

* School average
if regexm(html, "WASTANI WA SHULE\s*:\s*([0-9]+(\.[0-9]+)?)") {
    replace school_avg = real(regexs(1))
}

* Group text
if regexm(html, "KUNDI LA SHULE\s*:\s*([^<]+)<") {
    replace group_text = strtrim(regexs(1))
}

* Binary group
replace under40 = 1 if regexm(lower(group_text), "chini ya 40")
replace under40 = 0 if missing(under40)

* Council rank
if regexm(html, "KIHALMASHAURI:\s*([0-9]+)\s*kati ya\s*([0-9]+)") {
    replace council_rnk = regexs(1) + "/" + regexs(2)
}

* Region rank
if regexm(html, "KIMKOA\s*:\s*([0-9]+)\s*kati ya\s*([0-9]+)") {
    replace region_rnk = regexs(1) + "/" + regexs(2)
}

* National rank
if regexm(html, "KITAIFA\s*:\s*([0-9]+)\s*kati ya\s*([0-9]+)") {
    replace national_rnk = regexs(1) + "/" + regexs(2)
}

* Keep exactly the requested outputs
keep school_name school_code n_tested school_avg under40 council_rnk region_rnk national_rnk

save q5_finaldataset.dta, replace

********************************************************************************

