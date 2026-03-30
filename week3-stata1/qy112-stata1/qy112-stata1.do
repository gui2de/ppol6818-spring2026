* Stata Assignment 
cd "D:\yqy\硕士-mpp\第四学期\experimental design\assignment1-stata"

* Q1
use "Q1\student.dta", clear
rename primary_teacher teacher
merge m:1 teacher using "Q1\teacher.dta"
drop _merge

merge m:1 school using "Q1\school.dta"
drop _merge

merge m:1 subject using "Q1\subject.dta"
drop _merge

* (a)
sum attendance if loc=="South"

* (b)
gen teach_tested = (tested==1) if !missing(tested)
sum teach_tested if level=="High"

* (c)
sum gpa

* (d)
preserve
keep if level=="Middle"
bysort school: egen mean_attendance = mean(attendance)
bysort school: keep if _n==1
sort school
list school mean_attendance
restore

* Q2
use "Q2\q2_village_pixel.dta", clear

* (a)
bysort pixel: egen p_min = min(payout)
bysort pixel: egen p_max = max(payout)

gen pixel_consistent = (p_min == p_max) if payout!=.
tab pixel_consistent

* (b)
bysort village pixel: gen pix_tag = (_n==1)
bysort village: egen n_pixel_in_village = total(pix_tag)

gen pixel_village = (n_pixel_in_village > 1) 
tab pixel_village

* (c)
bysort pixel: egen pixel_payout = mean(payout)
bysort village pixel: gen vp_tag = (_n==1)
bysort village: egen vp_payout_min = min(pixel_payout) 
bysort village: egen vp_payout_max = max(pixel_payout) 

gen village_category = .
replace village_category = 1 if n_pixel_in_village==1
replace village_category = 2 if n_pixel_in_village>1 & vp_payout_min==vp_payout_max
replace village_category = 3 if n_pixel_in_village>1 & vp_payout_min!=vp_payout_max

tab village_category
list hhid village pixel payout if village_category==2

* Q3
use "Q3\q3_proposal_review.dta", clear
rename Review1Score ReviewerScore1
rename Reviewer2Score ReviewerScore2
rename Reviewer3Score ReviewerScore3

reshape long Reviewer ReviewerScore, i(proposal_id) j(reviewer_id)
bysort Reviewer: egen reviewer_mean = mean(ReviewerScore)
bysort Reviewer: egen reviewer_sd   = sd(ReviewerScore)

* (a)
gen stand_score = .
replace stand_score = (ReviewerScore - reviewer_mean) / reviewer_sd ///
    if reviewer_sd > 0 & ReviewerScore < .
replace stand_score = 0 if reviewer_sd == 0 & ReviewerScore < .

keep proposal_id reviewer_id stand_score
reshape wide stand_score, i(proposal_id) j(reviewer_id)

rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

* (b)
gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score)/3

* (c) 
egen rank = rank(-average_stand_score), unique

sum average_stand_score
sum rank
list proposal_id average_stand_score rank ///
     stand_r1_score stand_r2_score stand_r3_score

* Q4
global wd "D:\yqy\硕士-mpp\第四学期\experimental design\assignment1-stata"
global excel_t21 "$wd\Q4\q4_Pakistan_district_table21.xlsx"
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
	rename TABLE21PAKISTANICITIZEN1 table21
	
	gen table=`i' //to keep track of the sheet we imported the data from
	
gen x1  = ""
gen x2  = ""
gen x3  = ""
gen x4  = ""
gen x5  = ""
gen x6  = ""
gen x7  = ""
gen x8  = ""
gen x9  = ""
gen x10 = ""
gen x11 = ""
gen x12 = ""

	local k = 1
foreach col in B C D E F G H I J K L M N O P Q R S T U V W X Y  Z AA AB AC{
* The following step of "capture confirm "was added with the help of an AI tool to handle cases. I encountered Stata errors such as "variable R not found" when looping over columns.
	capture confirm variable `col'
    if _rc != 0 continue 
	
    if `k' <= 12 {
        replace x`k' = `col' if x`k'=="" & regexm(`col', "[0-9]")
        count if x`k' != ""
        if r(N) == 1 local k = `k' + 1
    }
}

keep table table21 x1-x12
	
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %40s table21

use `table21', clear
br

* Q5

**********************************************************************************
**********Qingfeng's Comment******************************************************
**********************************************************************************
**It seems that you manually coded rather than extracting the messy HTML string. Since the prompt explicitly frames Q5 as string cleaning/data wrangling and ask to "extract" school-level variables from the provided HTML, this approach is not generalizable (won't work for another school) and doesn't demonstrate the intended parsing steps.
**Therefore, I'd recommend reading the HTML/source text and programmatically parsing out the counts/avg score/under40 indicator and the council/region/national rank (including denominators) before saving the one-row dataset.

use "Q5\q5_Tz_student_roster_html.dta", clear
set obs 1

gen school_name = "ALBEHIJE PRIMARY SCHOOL"
gen school_code = "PS0101114"
gen num_test = 16
gen avg_score = 217.3750
gen under40 = 1   // 1=under 40, 0=40 or above

gen rank_council = 22
gen total_council = 46

gen rank_region = 74
gen total_region = 290

gen rank_national = 545
gen total_national = 5664

list
save "Q5\q5_schoollevel.dta", replace

	