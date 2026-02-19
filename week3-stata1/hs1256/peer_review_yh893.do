//Harold Shi
//Stata 1
global class "/Users/serovia/Desktop/assignment__Stata_1_export"

//Question1
cd "C:\Users\maimo\OneDrive\Desktop\Semester 2\Experimental Design & Implement\Stata 1 assignment"
use "teacher.dta" 

rename primary_teacher teacher
save student_temp, replace

use student_temp.dta
merge m:1 teacher using teacher
drop _merge
merge m:1 school using school
drop _merge
merge m:1 subject using subject
drop _merge

//a.
mean attendance if loc == "South"
//The mean student attendance for schools located in the "South" is 177.48 days per year.

//b.
mean tested if level=="High"
//The proportion of high school students with a primary teacher who teaches a tested subject is 44.23%.

//c.
mean gpa
//The mean gpa of all students in the district is 3.60.

//d.
egen school_id = group(school), label
mean attendance if level=="Middle", over(school_id)
//Joseph Darby Middle School: 177.44 days per year; Mahatma Ghandi Middle School: 177.33 days per year; Malala Yousafzai Middle School: 177.55 days per year.
clear

//Question 2
use q2_village_pixel.dta , clear 


//a.
bys pixel: egen min_payout = min(payout)
bys pixel: egen max_payout = max(payout)
gen pixel_consistent = (min_payout == max_payout)
tab pixel_consistent

//b.
egen pixel_id = group(pixel), label
bys village: egen min_pixel = min(pixel_id)
bys village: egen max_pixel = max(pixel_id)
gen pixel_village = min_pixel != max_pixel
tab pixel_village

//c.
bys village: egen min_pay_v = min(payout)
bys village: egen max_pay_v = max(payout)
gen village_pay_consistent = (min_pay_v == max_pay_v)
gen village_type = .
replace village_type = 1 if pixel_village == 0
replace village_type = 2 if pixel_village == 1 & village_pay_consistent == 1
replace village_type = 3 if pixel_village == 1 & village_pay_consistent == 0
tab village_type
clear


//Question 3
use q3_proposal_review,clear

//1.
gen score1 = Review1Score
gen score2 = Reviewer2Score
gen score3 = Reviewer3Score

reshape long Reviewer score, i(proposal_id) j(rpos)

bys Reviewer: egen mean_score = mean(score)
bys Reviewer: egen sd_score   = sd(score)

gen stand_score = (score - mean_score) / sd_score

drop mean_score sd_score

reshape wide Reviewer score stand_score, i(proposal_id) j(rpos)

rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

//2.
egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)
sum average_stand_score

//3.
egen rank = rank(-average_stand_score)
sum rank
sort rank
list proposal_id average_stand_score rank in 1/10
clear


// Question 4

global wd "C:\Users\maimo\OneDrive\Desktop\Semester 2\Experimental Design & Implement\Stata 1 assignment"
cd "$wd"
global excel_t21_Maimoona "C:\Users\maimo\OneDrive\Desktop\Semester 2\Experimental Design & Implement\Stata 1 assignment\q4_Pakistan_district_table21.xlsx"

clear

tempfile table21
save `table21', replace emptyok


* Run a loop through all the excel sheets (135)
forvalues i=1/135 {
    import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring
    display as error `i'

    keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND")==1
    * keep if TABLE21PAKISTANICITIZEN1== "18 AND"

    keep in 1
    rename TABLE21PAKISTANICITIZEN1 table21

    keep B C D E F G H I J K L M
    gen table=`i'

    append using `table21'
    save `table21', replace
}

*load the tempfile
use `table21', clear

*fix column width issue so that it's easy to eyeball the data
format %40s B C D E F G H I J K L M

order table B C D E F G H I J K L M

save "districts_18plus.dta", replace

clear

//Question 5

use q5_Tz_student_roster_html


* 1) School name + code
gen school_name = regexs(1) if regexm(s, "([A-Z ]+ PRIMARY SCHOOL)")
gen school_code = regexs(1) if regexm(s, "(PS[0-9]+)")

* 2) Students who took test
gen students_tested = real(regexs(1)) if regexm(s, "WALIOFANYA MTIHANI *: *([0-9]+)")

* 3) School average score
gen avg_score = real(regexs(1)) if regexm(s, "WASTANI WA SHULE *: *([0-9.]+)")

* 4) Student group: under 40 vs 40+
gen group_40plus = .
replace group_40plus = 0 if regexm(s, "chini ya 40")
replace group_40plus = 1 if regexm(s, "40") & missing(group_40plus)

* 5) Rankings (rank + total)
gen rank_council  = real(regexs(1)) if regexm(s, "KIHALMASHAURI: *([0-9]+) kati ya ([0-9]+)")
gen total_council = real(regexs(2)) if regexm(s, "KIHALMASHAURI: *([0-9]+) kati ya ([0-9]+)")

gen rank_region  = real(regexs(1)) if regexm(s, "KIMKOA *: *([0-9]+) kati ya ([0-9]+)")
gen total_region = real(regexs(2)) if regexm(s, "KIMKOA *: *([0-9]+) kati ya ([0-9]+)")

gen rank_national  = real(regexs(1)) if regexm(s, "KITAIFA *: *([0-9]+) kati ya ([0-9]+)")
gen total_national = real(regexs(2)) if regexm(s, "KITAIFA *: *([0-9]+) kati ya ([0-9]+)")

list school_name school_code students_tested avg_score group_40plus ///
     rank_council total_council rank_region total_region rank_national total_national

keep school_name school_code students_tested avg_score group_40plus ///
rank_council total_council rank_region total_region rank_national total_national
clear
