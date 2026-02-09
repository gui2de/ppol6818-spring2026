clear all
cd "C:\Users\ASUS\Desktop\research_design\assignments\assignment1"

*Q1
*(a)
use "inputs\q1_data\student.dta"
rename primary_teacher teacher
merge m:1 teacher using "inputs\q1_data\teacher.dta"
drop _merge
merge m:1 school using "inputs\q1_data\school.dta"
sum attendance if loc == "South"
*The mean student attendance for schools located in the "South" is 177.4776 days.

*(b)
drop _merge
merge m:1 subject using "inputs\q1_data\subject.dta"
sum tested if level == "High"
/*Among students enrolled in high school, 44.23495% have a primary teacher who
teaches a tested subject.*/  

*(c)
sum gpa
*The mean gpa of all students in the district is 3.60144.

*(d)
tabstat attendance if level == "Middle", by(school) stat(mean)
/*
school	            Mean
	
Joseph Darby Mid	177.4408
Mahatma Ghandi M	177.3344
Malala Yousafzai	177.5478
	
Total	177.4514
*/

*Q2
*(a)
clear all
use "inputs\q2_village_pixel.dta"
egen mean_payout = mean(payout), by(pixel)	
gen pixel_consistent = (payout == mean_payout)
drop mean_payout
tab pixel_consistent
*The payout status is consistent within each pixel. 

*(b)
encode pixel, gen(pixel_id)
egen mean_pixel = mean(pixel_id), by(village)
gen pixel_village = !(pixel_id == mean_pixel)
drop mean_pixel pixel_id
/* This method has a potential problem: if a village have 3 households, and each
of them is in pixel 1, 2 and 3, then household 2's pixel_village will be mislabeled
as 0. I have manually checked the data and ensured this problem did not happen in
this dataset. */

*(c)
gen village_category = 1 if pixel_village == 0
egen mean_village_payout = mean(payout), by(village)
replace village_category = 2 if pixel_village == 1 & payout == mean_village_payout
replace village_category = 3 if pixel_village == 1 & payout != mean_village_payout
tab village_category, missing
drop mean_village_payout
decode village, gen(village_name)
levelsof village_name if village_category == 2
drop village_name
/* Here is the list of villages that span multiple pixels but have the same payout
status across pixels:
"HAWONO", "KISENYE", "LINGANYIRO 'B'", "LUNGA", "MALOMBA", "OGUDA 'A'", 
"ONYANGO 'A'", "ORAWO", "SIND", "SKALA", "UKAKA 'A'", "UKANDA 'B'". */

*Q3
*(a)
clear all
use "inputs\q3_proposal_review.dta"
rename Rewiewer1 Reviewer1
rename Review1Score ReviewerScore1
rename Reviewer2Score ReviewerScore2
rename Reviewer3Score ReviewerScore3
reshape long Reviewer ReviewerScore, i(proposal_id) j(reviewer_position)
egen reviewer_mean = mean(ReviewerScore), by(Reviewer)
egen reviewer_sd   = sd(ReviewerScore), by(Reviewer)
gen stand_score = (ReviewerScore - reviewer_mean) / reviewer_sd
keep proposal_id reviewer_position stand_score
reshape wide stand_score, i(proposal_id) j(reviewer_position)
rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

*(b)
gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score) / 3

*(c)
egen rank = rank(-average_stand_score)

*Q4
*(a)
global wd "C:\Users\ASUS\Desktop\research_design\assignments\assignment1"
global excel_t21 "$wd\inputs\q4_Pakistan_district_table21.xlsx"
clear

tempfile table21
save `table21', replace emptyok

forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
	display as error `i' //display the loop number
	
	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	keep in 1 //there are 3 of them, but we want the first one
	rename TABLE21PAKISTANICITIZEN1 table21

	/* This is one modification I made based on the hint. The target is to fill in 
	the values which are not spaces correctly. */ 
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
	
	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}
use `table21', clear
format %40s V1-V13
/* This is one modification I made based on the hint. The target is to transform the
"-" in the excel file into missing value, and change the data format into numeric. */
destring V2-V13, replace force
sort table
*I manually checked the first and last 5 rows and they are all correct.

*Q5
clear all
use "inputs\q5\q5_Tz_student_roster_html.dta"
rename s html

*school and code
gen school_name = regexs(1) if regexm(html, "([A-Z ]+) - PS")
replace school_name = strtrim(school_name)
gen school_code = regexs(1) if regexm(html, "- (PS[0-9]+)")

*number of students
gen n_students = real(regexs(1)) if regexm(html, "WALIOFANYA MTIHANI *: *([0-9]+)")

*school average score
gen avg_score = real(regexs(1)) if regexm(html, "WASTANI WA SHULE *: *([0-9.]+)")

*student group
gen group_under40 = .
replace group_under40 = 1 if strpos(html, "chini ya 40") > 0
replace group_under40 = 0 if strpos(html, "chini ya 40") == 0
label define g40 1 "under 40" 0 "40 or above"
label values group_under40 g40

*ranking within the council
gen rank_council = real(regexs(1)) if regexm(html, "KIHALMASHAURI *: *([0-9]+) kati ya ([0-9]+)")
gen council_total = real(regexs(2)) if regexm(html, "KIHALMASHAURI *: *([0-9]+) kati ya ([0-9]+)")

*ranking within the region
gen rank_region = real(regexs(1)) if regexm(html, "KIMKOA *: *([0-9]+) kati ya ([0-9]+)")
gen region_total = real(regexs(2)) if regexm(html, "KIMKOA *: *([0-9]+) kati ya ([0-9]+)")

*ranking at the national level
gen rank_national = real(regexs(1)) if regexm(html, "KITAIFA *: *([0-9]+) kati ya ([0-9]+)")
gen national_total = real(regexs(2)) if regexm(html, "KITAIFA *: *([0-9]+) kati ya ([0-9]+)")

keep school_name school_code n_students avg_score group_under40 rank_council council_total rank_region region_total rank_national national_total




