cd /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata1/assignment__Stata_1_export/q1_data

********************************************************************************
* Experimental Design and Implementation: Stata1 Assignment
* Stephanie Petrov
* February 8, 2026
********************************************************************************

***********************
***   Question 1    ***
***********************


*(a) What is the mean student attendance for schools located in the "South"?

use /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata1/assignment__Stata_1_export/q1_data/student.dta, clear

*Step 1: Merge teacher.dta and student.dta
*Step 1: rename primary_teacher 
*Then merge on subject.d2a

rename primary_teacher teacher
merge m:1 teacher using "teacher.dta", gen(merge1)
merge m:1 school using "school.dta", gen(merge2)
merge m:1 subject using "subject.dta",gen (merge3)

order merge1, after(subject_gpa)
order merge2, after(merge1)
order merge3, after(merge2)

summ attendance if loc=="South"

*The mean student attendance for schools located in the "South" is 177.4776 days.

*(b) Among students enrolled in high school, what proportion have a primary teacher who teaches a tested subject, i.e. "tested" = 1?

tab tested if level=="High"
*44.23 percent of students enrolled in high school have a primary teacher who teaches a tested subject. 

*(c) What is the mean gpa of all students in the district?

summ gpa

*The mean gpa af all students in the district is 3.601.

* (d) What is the mean attendance for each middle school?

tab attendance if level=="Middle"

tab attendance school if level=="Middle"
summ attendance school if level=="Middle"
tab school if level=="Middle"

summ attendance if school== "Joseph Darby Middle School"
*The mean attendance for Joseph Darby Middle School is 177.4408 days.
summarize attendance if school=="Mahatma Ghandi Middle School"
*The mean attendance for Mahatma Ghandi Middle School is 177.3344 days. 
summarize attendance if school=="Malala Yousafzai Middle School"
*The mean attendance for Malala Yousafszai Middle School is 177.5478 days. 


***********************
***   Question 2    ***
***********************


use /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata1/assignment__Stata_1_export/q2_village_pixel.dta, clear

sort pixel
bysort pixel: count
tab pixel

*117 in pixel KE3556
*236 in pixel KE3557
*154 in pixel KE3631
*291 in pixel KE3632
*56 in pixel KE3633

tab pixel payout

gen pixel_consistent=.
replace pixel_consistent=1 //all pixels are consistent based on the tabulation so every observation gets the value 

bysort village pixel: gen first_village_pixel_combo = (_n == 1) //identifies unique combos of pixels/villages
bysort village: gen pixel_village = sum(first_village_pixel_combo) //generate the dummy variable
bysort village: replace pixel_village = (pixel_village[_N] > 1)

gen hhid_class=.
replace hhid_class=1 if pixel_village==0
replace hhid_class=2 if pixel_village==1 & pixel_consistent==1
replace hhid_class=3 if pixel_village==1 & pixel_consistent==0 // should have 0 in this category because all pixels have the same payout status.
tab hhid_class //yes, I have 834 in category 1 and 124 in category 2 and 0 in category 3


***********************
***   Question 3    ***
***********************

use /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata1/assignment__Stata_1_export/q3_proposal_review.dta, clear

**renaming variables**

rename Rewiewer1 Reviewer1
rename Reviewer2Score Review2Score
rename Reviewer3Score Review3Score

rename Review1Score ReviewScore_1
rename Review2Score ReviewScore_2
rename Review3Score ReviewScore_3

**need to reshape the data**

reshape long Reviewer ReviewScore_, i(proposal_id) j(review_num)

bysort Reviewer: egen reviewer_mean = mean(ReviewScore_)
bysort Reviewer: egen reviewer_sd = sd(ReviewScore_)
sort proposal_id

**generating the standardized scores**

gen stand_r1_score = (ReviewScore_ - reviewer_mean)/reviewer_sd if review_num==1
gen stand_r2_score = (ReviewScore_ - reviewer_mean)/reviewer_sd if review_num==2
gen stand_r3_score = (ReviewScore_ - reviewer_mean)/reviewer_sd if review_num==3

reshape wide Reviewer ReviewScore_ reviewer_mean reviewer_sd stand_r1_score stand_r2_score stand_r3_score, i(proposal_id) j(review_num)

drop stand_r2_score1 stand_r3_score1 stand_r1_score2 stand_r3_score2 stand_r1_score3 stand_r2_score3

egen average_stand_score = rmean(stand_r1_score1 stand_r2_score2 stand_r3_score3)

gsort -average_stand_score, gen(rank)
br

***********************
***   Question 4    ***
***********************

global wd /users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata1/assignment__Stata_1_export
global excel_t21 "$wd/q4_Pakistan_district_table21.xlsx"

clear

tempfile table21
save `table21', replace emptyok

forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring 
	display as error `i' 
	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1
	keep in 1 
	rename TABLE21PAKISTANICITIZEN1 table21
	gen table=`i' 
	append using `table21' 
	save `table21', replace
}

use `table21', clear
format %10s table21 B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC
order table, after(table21)
sort table

rename table21 ages

***********************
***   Question 5    ***
***********************


use /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata1/assignment__Stata_1_export/q5/q5_Tz_student_roster_html.dta, clear

*generating new variables and filling them in based on data provided in the shl_ps0101114.html* (which I just opened in a different window, translated to English, and used the data available to replace the values in the necessary variables)

gen num_students_test=.
gen school_avg_score=.
gen under40=.
gen school_rank_council=.
gen school_rank_region=.
gen school_rank_national=.
gen school_name=.
tostring school_name, replace //turning into string variable
gen school_code=.
tostring school_code, replace //turning into string variable

replace num_students_test= 16 
replace school_avg_score = 217.3750
replace under40=1
replace school_rank_council=22
replace school_rank_region=74
replace school_rank_national=545
replace school_name="Albehije Primary School"
replace school_code="PS0101114"

