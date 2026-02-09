*****************************************************
* ASSIGNMENT 3: STATA 1 (LOOPS, MACROS, EGEN, BYSORT)
*****************************************************

***************
** Question 1A
***************
cd "/Users/maren/Desktop/Experimental Design & Implementation/Assignment 3/q1_data_export"
use "student.dta", clear
rename primary_teacher teacher

* Merging students w/ teachers 
merge m:1 teacher using "teacher.dta"
drop _merge 

* Merging school w/ current dataset
merge m:1 school using "school.dta"
drop _merge

summarize attendance if loc == "South"

// The mean student attendance for schools located in the south is 177.4776, or approx. 177 days. 

***************
** Question 1B
***************
* Merging subject w/ current dataset
merge m:1 subject using "subject.dta"
drop _merge

tabulate tested
tabulate tested if level == "High"

// Among high school students, 44.23 percent have a primary teacher who teaches a tested subject.


***************
** Question 1C
***************
mean(gpa)
use "school.dta", clear
mean(gpa)

// Since GPA is only available at the school level I computed the district mean GPA using
// the school dataset rather than weighting by student enrollment. However, in both cases
// the mean is approx. 3.6


***************
** Question 1D
***************
use "student.dta", clear
rename primary_teacher teacher
merge m:1 teacher using "teacher.dta", nogen
merge m:1 school using "school.dta", nogen
merge m:1 subject using "subject.dta", nogen

tabulate level
bysort school: summarize attendance if level == "Middle"

// The mean attendance for Joseph Darby Middle School is approx. 177.44 days.
// The mean attendance for Mahatma Ghandi Middle School is approx. 177.33 days.
// The mean attendance for Malala Yousafzai Middle School is approx. 177.55 days.

save "$wd/03_output/school_full.dta", replace

***************
** Question 2A
***************
use "/Users/maren/Desktop/Experimental Design & Implementation/Assignment 3/q2_village_pixel.dta", clear

tabulate pixel 
bysort pixel: summarize payout 

// Within each pixel, the payout status is consistent, since min = max

bysort pixel: egen pixel_min = min(payout)
bysort pixel: egen pixel_max = max(payout)
gen pixel_consistent = (pixel_min == pixel_max)

tab pixel_consistent


***************
** Question 2B
***************
* Tagging one observation per (village, pixel) combo 
egen vp_tag = tag(village pixel) // for each village, how many distinct pixels are there
bysort village: egen count_pixels = total(vp_tag) // counting number of unique pixels per village
generate pixel_village = (count_pixels > 1)

tabulate pixel_village
 
 
***************
** Question 2C
***************
* Creating an indicator at the village level to track variation in payout
bysort village: egen village_min = min(payout)
bysort village: egen village_max = max(payout)
gen village_payout_difference = village_min != village_max

* Creating classification categories
generate village_classification = .
replace village_classification = 1 if pixel_village == 0
replace village_classification = 2 if pixel_village == 1 & village_payout_difference == 0
replace village_classification = 3 if pixel_village == 1 & village_payout_difference == 1

tabulate village_classification

//The code below shows the households in villages spanning multiple pixels but with identical payout status across pixels (category 2):
list hhid if village_classification == 2


***************
** Question 3
***************
use "/Users/maren/Desktop/Experimental Design & Implementation/Assignment 3/q3_proposal_review.dta", clear

* Renaming variables 
rename Rewiewer1 Reviewer1
rename Review1Score ReviewerScore1
rename Reviewer2Score ReviewerScore2
rename Reviewer3Score ReviewerScore3

* Reshaping to long (one row per proposal and reviewer position)
reshape long Reviewer ReviewerScore, i(proposal_id) j(revpos)

* Standardizing reviewer scores by NetID
bysort Reviewer: egen reviewer_mean = mean(ReviewerScore)
bysort Reviewer: egen reviewer_sd = sd(ReviewerScore)
generate stand_score = (ReviewerScore - reviewer_mean)/reviewer_sd

* Reshaping back to wide
keep proposal_id revpos stand_score PIName Department
reshape wide stand_score, i(proposal_id) j(revpos)

rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

* Finding average standardized score for each proposal
egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)

* Ranking proposals where the first row 1 has the highest score
gsort -average_stand_score

// Proposal ID 105 has highest score, proposal 85 has the lowest.


***************
** Question 4
***************
global wd "/Users/maren/Desktop/Experimental Design & Implementation/Assignment 3/"
*update the wd global so that it refers to the Box folder filepath on your machine

global excel_t21 "$wd//01_data/q4_Pakistan_district_table21.xlsx"

clear

* Setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

* Run a loop through all the excel sheets (135) this will take 1-5 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
	display as error `i' //display the loop number

	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND ABOV" )==1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	rename TABLE21PAKISTANICITIZEN1 table21

	
	gen table=`i' //to keep track of the sheet we imported the data from
	forvalues k = 2/13 {
		generate col`k' = ""
	} // creating empty outpuyt columns for 2-13
	unab allvars : _all // creating local macro named allvars containing full list of var names
	local pos = 2
	foreach v of local allvars {
    if "`v'"=="table21" | "`v'"=="table" continue // skipping variables that aren't data cells
	if regexm("`v'", "^col") continue

    replace `v' = trim(`v') // removing spaces 
    replace `v' = "" if trim(`v')=="." | trim(`v')=="" | trim(`v')=="-"

    if `pos' <= 13 { // only filling outputs to column 13
        if `v' != "" & col`pos'=="" {
            replace col`pos' = `v'
            local pos = `pos' + 1
        }
    }
}
	keep table table21 col2-col13
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear
order table table21 col2-col13
*fix column width issue so that it's easy to eyeball the data
format %40s table21 col2-col13
replace table21 = "18 AND ABOVE" if regexm(table21, "18 AND ABOVE")
replace table21 = "18 AND ABOVE" if table21 == "18 AND ABOV"

*Renaming vars
rename table21 age_group
rename col2 total_pop
rename col3 cnic_yes
rename col4 cnic_no

rename col5 male_total_pop
rename col6 male_cnic
rename col7 male_no_cnic

rename col8 female_total_pop
rename col9 female_cnic
rename col10 female_no_cnic

rename col11 trans_total_pop
rename col12 trans_cnic
rename col13 trans_no_cnic

save "$wd/03_output/pakistan_district_table21.dta", replace



***************
** Question 5
***************
cd "/Users/maren/Desktop/Experimental Design & Implementation/Assignment 3/q5"
use "q5_Tz_student_roster_html.dta", clear

* Extracting school name and code
generate school_name = ""
generate school_code = ""

replace school_name = regexs(1) if regexm(s, "<H3>.*?>(.*?) -") //school appears within H3 header
replace school_code = regexs(1) if regexm(s, "- ([A-Z0-9]+)") // represents one or more letters/numbers

* Finding number of student who took the exam
generate n_students = .
replace n_students = real(regexs(1)) ///
    if regexm(s, "WALIOFANYA MTIHANI *: *([0-9]+)") // one or more digits or a dot

* Finding school average score
generate avg_score = .
replace avg_score = real(regexs(1)) ///
    if regexm(s, "WASTANI WA SHULE *: *([0-9\.]+)")

* Extracting student group indicator
generate under_40 = .
replace under_40 = 1 if regexm(s, "chini ya 40")
replace under_40 = 0 if regexm(s, "40 au zaidi")

* Finding rankings (council, region, national)
generate rank_council = .
generate total_council = .

replace rank_council = real(regexs(1)) ///
    if regexm(s, "KIHALMASHAURI: *([0-9]+) kati ya ([0-9]+)")

replace total_council = real(regexs(2)) ///
    if regexm(s, "KIHALMASHAURI: *([0-9]+) kati ya ([0-9]+)")
	
generate rank_region = .
generate total_region = .

replace rank_region = real(regexs(1)) /// 
    if regexm(s, "KIMKOA *: *([0-9]+) kati ya ([0-9]+)")

replace total_region = real(regexs(2)) ///
    if regexm(s, "KIMKOA *: *([0-9]+) kati ya ([0-9]+)")

generate rank_national = .
generate total_national = .

replace rank_national = real(regexs(1)) ///
    if regexm(s, "KITAIFA *: *([0-9]+) kati ya ([0-9]+)") // using two capture groups for x and y

replace total_national = real(regexs(2)) ///
    if regexm(s, "KITAIFA *: *([0-9]+) kati ya ([0-9]+)")


save "$wd/03_output/q5_Tz_school.dta", replace






