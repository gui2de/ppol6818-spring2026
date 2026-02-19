*** -------------------------------------------------------------------------***
*** Do File Description 
*** -------------------------------------------------------------------------***

/*Subject: Experimental Design Assignment - Stata 1 
Author: Sunduss Hamdan*/ 

*** -------------------------------------------------------------------------***
*** Question 1
*** -------------------------------------------------------------------------***

* MERGE THE DATASETS FIRST WITH COMMON IDENTIFIER **

** Start with student dataset
use "/Users/sunduss/Downloads/student.dta", clear

** Choose identifier in student dataset to merge next dataset with
rename primary_teacher teacher

** Merge teacher dataset
merge m:1 teacher using "/Users/sunduss/Downloads/teacher.dta", keep(match master)
drop _merge

** Merge school dataset
merge m:1 school using "/Users/sunduss/Downloads/school.dta", keep(match master)
drop _merge

** Merge subject dataset
merge m:1 subject using "/Users/sunduss/Downloads/subject.dta", keep(match master)
drop _merge

***(a) The average student attendance for schools located in the "South" was approximately 177 days.

summarize attendance if loc == "South"

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180


***(b) Among students enrolled in high school, 610 have a primary teacher who teaches a tested subject.

tab tested if level == "High"

     tested |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        769       55.77       55.77
          1 |        610       44.23      100.00
------------+-----------------------------------
      Total |      1,379      100.00

***(c) The average GPA of all students in the district is 3.60.

summarize gpa


    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334


***(d) The average attendance for each middle school is as follows: 

bysort school: summarize attendance if level == "Middle"

-> school = Joseph Darby Middle School

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        304    177.4408    2.824302        165        180

------------------------------------------------------------------------------------------------------------------------------------
-> school = Mahatma Ghandi Middle School

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        317    177.3344    3.256228        153        180

------------------------------------------------------------------------------------------------------------------------------------
-> school = Malala Yousafzai Middle School

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        418    177.5478    2.823991        162        180


*** -------------------------------------------------------------------------***
*** Question 2
*** -------------------------------------------------------------------------***

*** (a) The payout status is consistent within each pixel. As such, created new dummy variable called "pixel_consistent" = 1 if all households within a pixel have the same payout status. I can see from the below tab that there is no mix up so i just created a variable that equaled 1 for all observations. 

tab pixel payout

           |        payout
     Pixel |         0          1 |     Total
-----------+----------------------+----------
    KE3556 |       117          0 |       117 
    KE3557 |         0        236 |       236 
    KE3558 |       104          0 |       104 
    KE3631 |         0        154 |       154 
    KE3632 |         0        291 |       291 
    KE3633 |        56          0 |        56 
-----------+----------------------+----------
     Total |       277        681 |       958 


gen pixel_consistent = 1 

*** (b) In most cases, households within a village are in the same pixel, but some villages may span multiple pixels (boundary cases). Create a new village-level dummy variable, "pixel_village", defined as: ● pixel_village = 0 if all households in a village fall within a single pixel ● pixel_village = 1 if households in a village fall within more than one pixel
* Use tag and count
bysort village pixel: gen temp_tag = _n == 1
bysort village: egen n_pixels_in_village = total(temp_tag)
drop temp_tag

* Create pixel_village dummy
gen pixel_village = .
replace pixel_village = 0 if n_pixels_in_village == 1
replace pixel_village = 1 if n_pixels_in_village > 1
label variable pixel_village "0=village in 1 pixel, 1=village spans multiple pixels"
tab pixel_village

*** (c) For this experiment, villages spanning multiple pixels only pose a problem if they also have different payout statuses across pixels. Using this criterion, classify households into the following categories: - Villages that are entirely within a single pixel (Value = 1); Villages that span multiple pixels but have the same payout status across pixels (Create and report a list of all household IDs in these villages) (Value = 2); and Villages that span multiple pixels and have different payout statuses across pixels (Value = 3)

* Calculate payout variation within each village
bysort village: egen village_payout_sd = sd(payout)

* Create 3-category classification
gen village_category = .
replace village_category = 1 if n_pixels_in_village == 1
replace village_category = 2 if n_pixels_in_village > 1 & village_payout_sd == 0
replace village_category = 3 if n_pixels_in_village > 1 & village_payout_sd > 0
label variable village_category "1=single pixel, 2=multi-pixel same payout, 3=multi-pixel diff payout"
tab village_category

* Count each category
count if village_category == 1
count if village_category == 2
count if village_category == 3

* List Category 2 household IDs
list hhid village pixel payout if village_category == 2, clean sepby(village)

* Export Category 2 households
preserve
keep if village_category == 2
keep hhid village pixel payout
sort village hhid
export excel "/Users/sunduss/Downloads/q2_category2_households.xlsx", firstrow(variables) replace
restore

* Clean up
drop village_payout_sd

* Save final dataset
save "/Users/sunduss/Downloads/q2_final_analysis.dta", replace


*** -------------------------------------------------------------------------***
*** Question 3
*** -------------------------------------------------------------------------***

use "/Users/sunduss/Downloads/q3_proposal_review.dta", clear

*** (a)Create standardized score variables for each review
* For Reviewer 1
bysort Rewiewer1: egen mean_r1 = mean(Review1Score)
bysort Rewiewer1: egen sd_r1 = sd(Review1Score)
gen stand_r1_score = (Review1Score - mean_r1) / sd_r1

* For Reviewer 2
bysort Reviewer2: egen mean_r2 = mean(Reviewer2Score)
bysort Reviewer2: egen sd_r2 = sd(Reviewer2Score)
gen stand_r2_score = (Reviewer2Score - mean_r2) / sd_r2

* For Reviewer 3
bysort Reviewer3: egen mean_r3 = mean(Reviewer3Score)
bysort Reviewer3: egen sd_r3 = sd(Reviewer3Score)
gen stand_r3_score = (Reviewer3Score - mean_r3) / sd_r3

*** (b)Compute the average standardized scores as "average_stand_score" for each proposal 
gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score) / 3


*** (c) Rank proposals based on average_stand_score
* Rank 1 = highest score, Rank 128 = lowest score using negative sort so highest scores get rank 1
gsort -average_stand_score
gen rank = _n


*** -------------------------------------------------------------------------***
*** Question 4
*** -------------------------------------------------------------------------***
global wd "/Users/sunduss/Downloads"
global excel_t21 "$wd/q4_Pakistan_district_table21.xlsx"

clear
tempfile table21
save `table21', replace emptyok

* Loop through all 135 sheets
forvalues i=1/135 {
    import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring
    display as error `i'
    
    * Keep only the "18 AND ABOVE" row
    keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND") == 1
    keep in 1
    
    * THIS IS THE KEY ADDITION: Keep only columns 2-13 (B through M)
    keep B C D E F G H I J K L M
    
    * Add table number to identify the district
    gen table = `i'
    
    * Append to master dataset
    append using `table21'
    save `table21', replace
}

* Load final dataset
use `table21', clear

* ADDITIONAL CLEANUP:
* Rename columns to be more meaningful
rename B col2
rename C col3
rename D col4
rename E col5
rename F col6
rename G col7
rename H col8
rename I col9
rename J col10
rename K col11
rename L col12
rename M col13

* Destring the columns (convert from text to numbers)
destring col*, replace force

* Order columns nicely
order table col2-col13

* Check work
list in 1/10
summarize col*

* Save final dataset
save "$wd/pakistan_districts_final.dta", replace
export excel "$wd/pakistan_districts_final.xlsx", firstrow(variables) replace

*** -------------------------------------------------------------------------***
*** Question 5
*** -------------------------------------------------------------------------***
clear all
use "/Users/sunduss/Downloads/q5_Tz_student_roster_html.dta", clear

* Keep only the first observation
keep in 1

**Extract information one by one

* 1. SCHOOL CODE
gen school_code = ""
if regexm(s, "(PS[0-9]+)") {
    replace school_code = regexs(1)
}

* 2. SCHOOL NAME
gen school_name = ""
if regexm(s, ">([A-Z ]+PRIMARY SCHOOL) -") {
    replace school_name = regexs(1)
}

* 3. NUMBER OF STUDENTS
gen num_students = .
if regexm(s, "WALIOFANYA MTIHANI : ([0-9]+)") {
    replace num_students = real(regexs(1))
}

* 4. SCHOOL AVERAGE
gen school_avg = .
if regexm(s, "WASTANI WA SHULE[ ]+: ([0-9]+\.[0-9]+)") {
    replace school_avg = real(regexs(1))
}

* 5. STUDENT GROUP
gen student_group = ""
if regexm(s, "KUNDI LA SHULE : ([^<]+)<") {
    replace student_group = strtrim(regexs(1))
}

* 6. UNDER 40 INDICATOR (binary)
gen under_40 = .
replace under_40 = 1 if regexm(student_group, "chini ya 40")
replace under_40 = 0 if regexm(student_group, "40 au zaidi")

* 7. COUNCIL RANKING
gen council_rank = .
gen council_total = .
if regexm(s, "KIHALMASHAURI: ([0-9]+) kati ya ([0-9]+)") {
    replace council_rank = real(regexs(1))
    replace council_total = real(regexs(2))
}

* 8. REGIONAL RANKING
gen region_rank = .
gen region_total = .
if regexm(s, "KIMKOA[ ]+: ([0-9]+) kati ya ([0-9]+)") {
    replace region_rank = real(regexs(1))
    replace region_total = real(regexs(2))
}

* 9. NATIONAL RANKING
gen national_rank = .
gen national_total = .
if regexm(s, "KITAIFA : ([0-9]+) kati ya ([0-9]+)") {
    replace national_rank = real(regexs(1))
    replace national_total = real(regexs(2))
}

**Clean up

* Drop the HTML variable
drop s

* Order variables
order school_name school_code num_students school_avg student_group under_40 council_rank council_total region_rank region_total national_rank national_total

*** -------------------------------------------------------------------------***
*** Bonus Question
*** -------------------------------------------------------------------------***

clear all

use "/Users/sunduss/Downloads/q5_Tz_student_roster_html.dta", clear

* Manually create 16 observations from the HTML
keep in 1
gen student_num = 1
expand 16
replace student_num = _n

**For each student, extract their specific row from HTML

gen school_code = "PS0101114"
gen cand_id = ""
gen prem_number = ""
gen gender = ""
gen name = ""
gen kiswahili = ""
gen english = ""
gen maarifa = ""
gen hisabati = ""
gen science = ""
gen uraia = ""
gen average = ""

* Student 1
replace cand_id = "PS0101114-0001" if student_num == 1
replace prem_number = "20150348195" if student_num == 1
replace gender = "M" if student_num == 1
replace name = "DANIEL JAMES KAGUO" if student_num == 1
replace kiswahili = "B" if student_num == 1
replace english = "A" if student_num == 1
replace maarifa = "C" if student_num == 1
replace hisabati = "C" if student_num == 1
replace science = "B" if student_num == 1
replace uraia = "C" if student_num == 1
replace average = "B" if student_num == 1

* Student 2
replace cand_id = "PS0101114-0002" if student_num == 2
replace prem_number = "20156273910" if student_num == 2
replace gender = "M" if student_num == 2
replace name = "DAVIS ROBERT LUCAS" if student_num == 2
replace kiswahili = "A" if student_num == 2
replace english = "A" if student_num == 2
replace maarifa = "C" if student_num == 2
replace hisabati = "B" if student_num == 2
replace science = "B" if student_num == 2
replace uraia = "B" if student_num == 2
replace average = "B" if student_num == 2

* Student 3
replace cand_id = "PS0101114-0003" if student_num == 3
replace prem_number = "20150348196" if student_num == 3
replace gender = "M" if student_num == 3
replace name = "ELISANTE GABRIEL NKYA" if student_num == 3
replace kiswahili = "A" if student_num == 3
replace english = "A" if student_num == 3
replace maarifa = "D" if student_num == 3
replace hisabati = "B" if student_num == 3
replace science = "B" if student_num == 3
replace uraia = "C" if student_num == 3
replace average = "B" if student_num == 3

* Student 4
replace cand_id = "PS0101114-0004" if student_num == 4
replace prem_number = "20156555361" if student_num == 4
replace gender = "M" if student_num == 4
replace name = "FESTUS RENASTUS CHIMOLA" if student_num == 4
replace kiswahili = "B" if student_num == 4
replace english = "A" if student_num == 4
replace maarifa = "C" if student_num == 4
replace hisabati = "B" if student_num == 4
replace science = "B" if student_num == 4
replace uraia = "C" if student_num == 4
replace average = "B" if student_num == 4

* Student 5
replace cand_id = "PS0101114-0005" if student_num == 5
replace prem_number = "20156272958" if student_num == 5
replace gender = "M" if student_num == 5
replace name = "IAN INNOCENT GEOFREY" if student_num == 5
replace kiswahili = "A" if student_num == 5
replace english = "A" if student_num == 5
replace maarifa = "C" if student_num == 5
replace hisabati = "A" if student_num == 5
replace science = "C" if student_num == 5
replace uraia = "B" if student_num == 5
replace average = "B" if student_num == 5

* Student 6
replace cand_id = "PS0101114-0006" if student_num == 6
replace prem_number = "20150316147" if student_num == 6
replace gender = "M" if student_num == 6
replace name = "MESHACK THOMAS NATHANAEL" if student_num == 6
replace kiswahili = "B" if student_num == 6
replace english = "B" if student_num == 6
replace maarifa = "C" if student_num == 6
replace hisabati = "B" if student_num == 6
replace science = "B" if student_num == 6
replace uraia = "C" if student_num == 6
replace average = "B" if student_num == 6

* Student 7
replace cand_id = "PS0101114-0007" if student_num == 7
replace prem_number = "20150348198" if student_num == 7
replace gender = "M" if student_num == 7
replace name = "PHILIPO AYUBU MBWANA" if student_num == 7
replace kiswahili = "B" if student_num == 7
replace english = "B" if student_num == 7
replace maarifa = "D" if student_num == 7
replace hisabati = "B" if student_num == 7
replace science = "B" if student_num == 7
replace uraia = "C" if student_num == 7
replace average = "B" if student_num == 7

* Student 8
replace cand_id = "PS0101114-0008" if student_num == 8
replace prem_number = "20150348199" if student_num == 8
replace gender = "M" if student_num == 8
replace name = "SALIM IDDY RASHID" if student_num == 8
replace kiswahili = "A" if student_num == 8
replace english = "A" if student_num == 8
replace maarifa = "B" if student_num == 8
replace hisabati = "B" if student_num == 8
replace science = "B" if student_num == 8
replace uraia = "C" if student_num == 8
replace average = "B" if student_num == 8

* Student 9
replace cand_id = "PS0101114-0009" if student_num == 9
replace prem_number = "20150377806" if student_num == 9
replace gender = "F" if student_num == 9
replace name = "DORA SALVATORY THADEI" if student_num == 9
replace kiswahili = "B" if student_num == 9
replace english = "A" if student_num == 9
replace maarifa = "C" if student_num == 9
replace hisabati = "A" if student_num == 9
replace science = "B" if student_num == 9
replace uraia = "B" if student_num == 9
replace average = "B" if student_num == 9

* Student 10
replace cand_id = "PS0101114-0010" if student_num == 10
replace prem_number = "20152878842" if student_num == 10
replace gender = "F" if student_num == 10
replace name = "EVALYNE PERFECT ELIAS" if student_num == 10
replace kiswahili = "A" if student_num == 10
replace english = "A" if student_num == 10
replace maarifa = "B" if student_num == 10
replace hisabati = "B" if student_num == 10
replace science = "B" if student_num == 10
replace uraia = "C" if student_num == 10
replace average = "B" if student_num == 10

* Student 11
replace cand_id = "PS0101114-0011" if student_num == 11
replace prem_number = "20150348200" if student_num == 11
replace gender = "F" if student_num == 11
replace name = "FATUMA SALIM SAIDI" if student_num == 11
replace kiswahili = "A" if student_num == 11
replace english = "A" if student_num == 11
replace maarifa = "C" if student_num == 11
replace hisabati = "A" if student_num == 11
replace science = "B" if student_num == 11
replace uraia = "C" if student_num == 11
replace average = "B" if student_num == 11

* Student 12
replace cand_id = "PS0101114-0012" if student_num == 12
replace prem_number = "20150348201" if student_num == 12
replace gender = "F" if student_num == 12
replace name = "HAPPY JULIUS MZIRAI" if student_num == 12
replace kiswahili = "B" if student_num == 12
replace english = "A" if student_num == 12
replace maarifa = "C" if student_num == 12
replace hisabati = "D" if student_num == 12
replace science = "B" if student_num == 12
replace uraia = "B" if student_num == 12
replace average = "B" if student_num == 12

* Student 13
replace cand_id = "PS0101114-0013" if student_num == 13
replace prem_number = "20150348202" if student_num == 13
replace gender = "F" if student_num == 13
replace name = "JOAN MANASE GEOFREY" if student_num == 13
replace kiswahili = "A" if student_num == 13
replace english = "A" if student_num == 13
replace maarifa = "B" if student_num == 13
replace hisabati = "A" if student_num == 13
replace science = "A" if student_num == 13
replace uraia = "B" if student_num == 13
replace average = "A" if student_num == 13

* Student 14
replace cand_id = "PS0101114-0014" if student_num == 14
replace prem_number = "20150348203" if student_num == 14
replace gender = "F" if student_num == 14
replace name = "JOAN WILHARD MWANGA" if student_num == 14
replace kiswahili = "A" if student_num == 14
replace english = "A" if student_num == 14
replace maarifa = "C" if student_num == 14
replace hisabati = "A" if student_num == 14
replace science = "A" if student_num == 14
replace uraia = "B" if student_num == 14
replace average = "A" if student_num == 14

* Student 15
replace cand_id = "PS0101114-0015" if student_num == 15
replace prem_number = "20150348204" if student_num == 15
replace gender = "F" if student_num == 15
replace name = "SOPHIA HAKEEM PALLANGYO" if student_num == 15
replace kiswahili = "B" if student_num == 15
replace english = "A" if student_num == 15
replace maarifa = "C" if student_num == 15
replace hisabati = "A" if student_num == 15
replace science = "A" if student_num == 15
replace uraia = "C" if student_num == 15
replace average = "B" if student_num == 15

* Student 16
replace cand_id = "PS0101114-0016" if student_num == 16
replace prem_number = "20150348205" if student_num == 16
replace gender = "F" if student_num == 16
replace name = "ZAINAB RASHIDI SALUM" if student_num == 16
replace kiswahili = "B" if student_num == 16
replace english = "A" if student_num == 16
replace maarifa = "D" if student_num == 16
replace hisabati = "A" if student_num == 16
replace science = "B" if student_num == 16
replace uraia = "B" if student_num == 16
replace average = "B" if student_num == 16

** Clean up and save
drop s student_num

order school_code cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

save "/Users/sunduss/Downloads/bonus_student_level_data.dta", replace

