// Qingyue Chen - Stata1 Assignment

capture log close
log using "$outroot/pd757_review_run.log", replace text

*	************************************************************************
*	Reviewer: Puran Dou (pd757)
*	************************************************************************

global dataroot "/Users/oldfarmerdou/Dropbox/ExperimentalDesign/assignment_stata1"
global q1 "$dataroot/q1_data"
global q5 "$dataroot/q5"

global outroot "/Users/oldfarmerdou/Dropbox/ExperimentalDesign/pd757-stata1-review"
capture mkdir "$outroot"

cd "$dataroot"

*	************************************************************************

clear all
set more off
// cd "C:/Users/86186/Desktop/Stata1_assignment"
cd "$dataroot"


// Q1-data prep
// use subject.dta, clear
use "$q1/subject.dta", clear
sort subject
// save "temp_subject.dta", replace
save "$outroot/temp_subject.dta", replace

// use school.dta, clear
use "$q1/school.dta", clear
sort school
// save "temp_school.dta", replace
save "$outroot/temp_school.dta", replace


// use teacher.dta, clear
use "$q1/teacher.dta", clear
rename teacher primary_teacher

* Merge School info onto Teacher
sort school
// merge m:1 school using "temp_school.dta"
merge m:1 school using "$outroot/temp_school.dta"

drop if _merge == 2 
drop _merge

* Merge Subject info onto Teacher
sort subject
// merge m:1 subject using "temp_subject.dta"
merge m:1 subject using "$outroot/temp_subject.dta"
drop if _merge == 2
drop _merge

sort primary_teacher
// save "temp_teacher_full.dta", replace
save "$outroot/temp_teacher_full.dta", replace

* Create Master Student Dataset
// use student.dta, clear
use "$q1/student.dta", clear


* Merge the enriched Teacher/School/Subject data onto the Student data
sort primary_teacher
// merge m:1 primary_teacher using "temp_teacher_full.dta"
merge m:1 primary_teacher using "$outroot/temp_teacher_full.dta"

* Keep only matched observations (students with valid teachers)
keep if _merge == 3
drop _merge

// Q1-a What is the mean student attendance for schools located in the "South"?
summarize attendance if loc == "South"
display "Mean student attendance for schools in the South: 177.4776"

// Answer: The mean student attendence for schools located in the "South" is 177.4776

// Q1-b Among students enrolled in high school, what proportion have a primary teacher who teaches a tested subject?
summarize tested if level == "High"
display "Proportion of HS students with teacher in tested subject: 44.24%"

// Answer:The proportion is approximately 44.24%

// Q1-c What is the mean gpa of all students in the district?
summarize gpa
display "Mean GPA of all students (using School GPA assigned to students): 3.60144"

// Answer: The mean GPA of all the students in the district is 3.60144

// Q1-d What is the mean attendance for each middle school?
tabulate school if level == "Middle", summarize(attendance)
display "Mean attendance for each Middle School:  Joseph Darby Middle School (177.44079), Mahatma Ghandi Middle School (177.33438),  Malala Yousafzai Middle School (177.54785)"

// Answer: The mean attendance for Joseph Darby Middle School is 177.44079, for Mahatma Ghandi Middle School is 177.33438,  for Malala Yousafzai Middle School is 177.54785"


// Q2
clear all
set more off
// cd "C:\Users\86186\Desktop\Stata1_assignment"
cd "$dataroot"
// use "q2_village_pixel.dta", clear
use "$dataroot/q2_village_pixel.dta", clear
describe

// Q2-a Create "pixel_consistent"
* Calculate the minimum and maximum payout status for each pixel
bysort pixel: egen min_pay = min(payout)
bysort pixel: egen max_pay = max(payout)

* Generate the dummy variable
* 1 if min equal max (no variation), 0 otherwise
gen pixel_consistent = (min_pay == max_pay)

* Verify if the condition holds (display the frequency)
tab pixel_consistent

* Clean up temporary variables
drop min_pay max_pay

/* Output: 
pixel_consi |
      stent |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        958      100.00      100.00
------------+-----------------------------------
      Total |        958      100.00
*/

// Answer: Yes, the condition holds. tab pixel_consistent) shows that 100% of the observations (958 out of 958) have a value of 1. Since pixel_consistent = 1 means there is no variation in payout status within a pixel, and there are no zeros in your output, the data confirms that every pixel has a consistent payout status for all households within it.

// Q2-b Create "pixel_village"
* Tag unique pixels within each village to handle duplicates
bysort village pixel: gen pixel_tag = (_n == 1)

* Count how many unique pixels exist per village
bysort village: egen village_pixel_count = total(pixel_tag)

* Create the dummy variable
gen pixel_village = (village_pixel_count > 1)

* Clean up temporary variables
drop pixel_tag village_pixel_count

// Q2-c Classify Households
* First, check if payout is consistent across the WHOLE village
bysort village: egen min_vill_pay = min(payout)
bysort village: egen max_vill_pay = max(payout)

* 1 = same payout across whole village, 0 = different payouts found in village
gen village_payout_consistent = (min_vill_pay == max_vill_pay)

* Initialize the category variable
gen classification_cat = .

* Category 1: Villages entirely within a single pixel
replace classification_cat = 1 if pixel_village == 0

* Category 2: Villages spanning multiple pixels but SAME payout status
replace classification_cat = 2 if pixel_village == 1 & village_payout_consistent == 1

* Category 3: Villages spanning multiple pixels and DIFFERENT payout statuses
replace classification_cat = 3 if pixel_village == 1 & village_payout_consistent == 0

* Verify the categories (mutually exclusive and exhaustive)
tab classification_cat, m

* REPORT: List household IDs (hhid) for Category 2
list hhid if classification_cat == 2

* Clean up
drop min_vill_pay max_vill_pay village_payout_consistent

// Output: 
/* tab classification_cat, m

classificat |
    ion_cat |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        834       87.06       87.06
          2 |         50        5.22       92.28
          3 |         74        7.72      100.00
------------+-----------------------------------
      Total |        958      100.00
*/

/* Answer: The households were classified into the three mutually exclusive categories as follows:
1. Villages entirely within a single pixel, Frequency:834, Percentage:87.06%
2. Villages spanning multiple pixels (same payout), Frequency:50, Percentage:5.22%
3. Villages spanning multiple pixels (different payout),  Frequency:74, Percentage:7.72%

List of Household IDs for Category 2: 

120507103
120507101
120507102
120507111
120507104
120508209
120508203
120508202
120508206
120508204
120508208
120610602
120610604
120610605
120610609
120611102
120611108
120611101
120813801
120813811
120813804
120813803
120813807
120814901
120814911
120814907
120814903
131120506
131120509
131120510
131221901
131221904
131221909
131221905
131221912
131424206
131424211
131424204
131424205
131424609
131424610
131424604
131424602
141728101
141728103
141728102
141728108
131336109
131336107
131336101

*/

// Q3
clear all
set more off
// cd "C:\Users\86186\Desktop\Stata1_assignment"
cd "$dataroot"
// use "q3_proposal_review.dta", clear
use "$dataroot/q3_proposal_review.dta", clear
describe

rename Rewiewer1 netid1
rename Reviewer2 netid2
rename Reviewer3 netid3
rename Review1Score score1
rename Reviewer2Score score2
rename Reviewer3Score score3

* Reshape to Long format
reshape long score netid, i(proposal_id) j(reviewer_num)
bysort netid: egen reviewer_mean = mean(score)
bysort netid: egen reviewer_sd = sd(score)
gen stand_score = (score - reviewer_mean) / reviewer_sd
drop reviewer_mean reviewer_sd

* Reshape back
reshape wide score netid stand_score, i(proposal_id) j(reviewer_num)
rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score
egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)
egen rank = rank(-average_stand_score), unique
sort rank
list proposal_id Department average_stand_score rank stand_r1_score stand_r2_score stand_r3_score, noobs

// Q4
clear all
set more off
// cd "C:\Users\86186\Desktop\Stata1_assignment"
cd "$dataroot"

* Define the global for the excel file name (assuming it's in the cd)
// global excel_t21 "q4_Pakistan_district_table21.xlsx"
global excel_t21 "$dataroot/q4_Pakistan_district_table21.xlsx"

clear

* Setting up an empty tempfile to store results
tempfile table21
save `table21', replace emptyok

* Loop through all 135 sheets
forvalues i=1/135 {
    
    * Import the specific sheet
    * allstring is used to ensure different column types across sheets don't break the append
    import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring 
    
    display as error "Processing Sheet: `i'" 

    * Keep only rows containing the string "18 AND"
    * Using regexm to handle potential leading/trailing spaces in the Excel cells
    keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND") == 1 
    
    * Keep only the first occurrence (usually the total for the category)
    keep in 1 
    
    * Create a sheet identifier
    gen sheet_id = `i'
    
    * Rename the identifier column for consistency
    rename TABLE21PAKISTANICITIZEN1 age_group
    
    * Append the current sheet's result to the master tempfile
    append using `table21'
    save `table21', replace 
}


use `table21', clear
format %40s age_group B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC

// Q5
clear all
set more off
// cd "C:\Users\86186\Desktop\Stata1_assignment"
cd "$dataroot"
// use "q5_Tz_student_roster_html.dta", clear
use "$q5/q5_Tz_student_roster_html.dta", clear
rename s html_line
replace html_line = ustrtrim(html_line)
gen strL html = ""
quietly {
    forvalues i = 1/`=_N' {
        replace html = html + " " + html_line[`i'] in 1
    }
}
keep in 1

* Clean
replace html = ustrregexra(html, "[\r\n\t]+", " ")
replace html = ustrregexra(html, "\s+", " ")
replace html = upper(html)

* Gen variables
gen str80 school_name = ""
gen str20 school_code = ""
gen took_test = .
gen avg_score = .
gen byte group_under40 = .   
gen council_rank = .
gen council_total = .
gen region_rank = .
gen region_total = .
gen national_rank = .
gen national_total = .

* Scratch school name and code
replace school_code = ustrregexs(1) if ustrregexm(html, "(PS[0-9]{7,})")
replace school_name = strtrim(ustrregexs(1)) if ustrregexm(html, "([A-Z0-9 \.\-']+?)\s*-\s*PS[0-9]{7,}")
replace school_name = strtrim(ustrregexs(1)) if ustrregexm(html, "([A-Z0-9 \.\-']+?PRIMARY SCHOOL)\s*-\s*(PS[0-9]{7,})")
replace school_name = proper(school_name)

* Number of students who took the test & avg scores
replace took_test = real(ustrregexs(1)) if ustrregexm(html, "WALIOFANYA MTIHANI\s*:\s*([0-9]{1,5})")
replace avg_score = real(ustrregexs(1)) if ustrregexm(html, "WASTANI WA SHULE\s*:\s*([0-9]+(\.[0-9]+)?)")

* Student group（under40 vs 40+）
replace group_under40 = 1 if ustrregexm(html, "KUNDI LA SHULE\s*:\s*WANAfunzi CHINI YA 40") | ///
                            ustrregexm(html, "KUNDI LA SHULE\s*:\s*WANAfunzi\s*CHINI\s*YA\s*40")

replace group_under40 = 0 if ustrregexm(html, "KUNDI LA SHULE\s*:\s*WANAfunzi\s*40\s*AU\s*ZAIDI")

* Rank: x kati ya y
* council: KIH...MASHAURI
* region : KIMKOA
* national: KITAIFA
replace council_rank  = real(ustrregexs(1)) if ustrregexm(html, "KIHALMASHAURI\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")
replace council_total = real(ustrregexs(2)) if ustrregexm(html, "KIHALMASHAURI\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")

replace region_rank  = real(ustrregexs(1)) if ustrregexm(html, "KIMKOA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")
replace region_total = real(ustrregexs(2)) if ustrregexm(html, "KIMKOA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")

replace national_rank  = real(ustrregexs(1)) if ustrregexm(html, "KITAIFA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")
replace national_total = real(ustrregexs(2)) if ustrregexm(html, "KITAIFA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")

keep school_name school_code took_test avg_score group_under40 ///
     council_rank council_total region_rank region_total national_rank national_total
list, noobs
// save "q5_school_level_summary.dta", replace
save "$outroot/q5_school_level_summary.dta", replace

// Bonus question
clear all
set more off
// cd "C:\Users\86186\Desktop\Stata1_assignment"
cd "$dataroot"

// use "q5_Tz_student_roster_html.dta", clear
use "$q5/q5_Tz_student_roster_html.dta", clear
rename s html_line
replace html_line = ustrtrim(html_line)

gen strL html = ""
quietly {
    forvalues i = 1/`=_N' {
        replace html = html + " " + html_line[`i'] in 1
    }
}
keep in 1

replace html = ustrregexra(html, "[\r\n\t]+", " ")
replace html = ustrregexra(html, "\s+", " ")
replace html = upper(html)

local schoolcode ""
if ustrregexm(html, "(PS[0-9]{7,})") local schoolcode = ustrregexs(1)

gen strL blob = html
local anchor = "`schoolcode'-"
replace blob = subinstr(blob, "`anchor'", "|||`anchor'", .)

split blob, parse("|||") gen(part)
drop blob part1

gen long one = 1
reshape long part, i(one) j(j)
drop if missing(part)
rename part rowtxt
drop one

keep if substr(rowtxt, 1, length("`anchor'")) == "`anchor'"

gen str20 schoolcode = "`schoolcode'"

gen str20 cand_id = ""
replace cand_id = ustrregexs(1) if ustrregexm(rowtxt, "^(PS[0-9]{7,}-[0-9]{4})")

gen strL clean = rowtxt
replace clean = ustrregexra(clean, "<[^>]+>", " ")
replace clean = ustrregexra(clean, "&NBSP;", " ")
replace clean = ustrregexra(clean, "\s+", " ")
replace clean = strtrim(clean)
replace clean = upper(clean)

gen str20 prem_number = ""
replace prem_number = ustrregexs(1) if ustrregexm(clean, "\s(20[0-9]{8,})\s")

gen str1 gender = ""
replace gender = ustrregexs(1) if ustrregexm(clean, "(?:20[0-9]{8,})\s*([MF])\s")
replace gender = strtrim(gender)

gen str80 name = ""
replace name = strtrim(ustrregexs(1)) if ///
    ustrregexm(clean, "\s[MF]\s+([A-Z \.'-]+?)\s+KISWAHILI\s*-\s*[A-E]")

gen str1 kiswahili = ""
gen str1 english = ""
gen str1 maarifa = ""
gen str1 hisabati = ""
gen str1 science = ""
gen str1 uraia = ""
gen str1 average = ""

replace kiswahili = ustrregexs(1) if ustrregexm(clean, "KISWAHILI\s*-\s*([A-E])")
replace english   = ustrregexs(1) if ustrregexm(clean, "ENGLISH\s*-\s*([A-E])")
replace maarifa   = ustrregexs(1) if ustrregexm(clean, "MAARIFA\s*-\s*([A-E])")
replace hisabati  = ustrregexs(1) if ustrregexm(clean, "HISABATI\s*-\s*([A-E])")
replace science   = ustrregexs(1) if ustrregexm(clean, "SCIENCE\s*-\s*([A-E])")
replace uraia     = ustrregexs(1) if ustrregexm(clean, "URAIA\s*-\s*([A-E])")
replace average   = ustrregexs(1) if ustrregexm(clean, "AVERAGE\s*GRADE\s*-\s*([A-E])")

keep schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average
order schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

count
list, noobs

// save "bonus_q5_student_level.dta", replace
save "$outroot/bonus_q5_student_level.dta", replace


log close
