****************************Question 1****************************

rename primary_teacher teacher
*merge master student.dta with using teacher.dta
merge m:1 teacher using teacher.dta
drop _merge
*merge master student.dta with using school.dta
merge m:1 school using school.dta
drop _merge
*merge master student.dta with using subject.dta
merge m:1 subject using subject.dta
drop _merge

save merged.dta

*(a) What is the mean student attendance for schools located in the "South"?
sum attendance if loc=="South"
/*
. sum attendance if loc=="South"

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180
*/
* The mean student attendance for schools located in the "South" is 177.48.

*(b) Among students enrolled in high school, what proportion have a primary teacher who teaches a tested subject, i.e."tested" = 1?
tab tested level
/*
. tab tested level

           |              level
    tested | Element..       High     Middle |     Total
-----------+---------------------------------+----------
         0 |     2,072        769        520 |     3,361 
         1 |         0        610        519 |     1,129 
-----------+---------------------------------+----------
     Total |     2,072      1,379      1,039 |     4,490 
*/
di 610/1379
*Among students enrolled in high school, 44.23% have a primary teacher who teaches a tested subject.

*(c) What is the mean gpa of all students in the district?
sum gpa
/*
. sum gpa

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334
*/
*The mean gpa of all students in the district is 3.6.

*(d) What is the mean attendance for each middle school?
tabstat attendance, by(school) statistics(mean)
/*
. tabstat attendance, by(school) statistics(mean)

Summary for variables: attendance
Group variable: school 

          school |      Mean
-----------------+----------
Abraham Lincoln  |  177.2089
Amartya Sen High |  177.2672
Benjamin Frankli |   177.617
Horace Mann Elem |  177.2018
John Dewey Eleme |  177.6752
Joseph Darby Mid |  177.4408
Mahatma Ghandi M |  177.3344
Malala Yousafzai |  177.5478
Martin Luther Ki |  177.4527
Norman Borlaug H |  177.3238
Rachel Carson El |  177.3487
Robert Smalls El |  177.2784
-----------------+----------
           Total |  177.3813
----------------------------
*/
*Middle school 	                Mean attendance
*Joseph Darby Middle School	       177.4408
*Mahatma Ghandi Middle School  	   177.3344
*Malala Yousafzai Middle School    177.5478



****************************Question 2****************************

*a)
sort pixel
egen tag_pixel_payout = tag(pixel payout)
bysort pixel: egen unique_payouts = total(tag_pixel_payout)
gen pixel_consistent = (unique_payouts == 1)
drop tag_pixel_payout unique_payouts

*b)
sort village
egen tag_village_pixel = tag(village pixel)
bysort village: egen unique_pixels = total(tag_village_pixel)
gen pixel_village = (unique_pixels > 1)
tab pixel_village
drop tag_village_pixel unique_pixels

*c)
egen tag_village_pixel = tag(village pixel)
bysort village: egen npixels = total(tag_village_pixel)
egen tag_village_payout = tag(village payout)
bysort village: egen npayouts = total(tag_village_payout)
generate Value=.
replace Value=1 if npixels==1
replace Value=2 if npixels>1 & npayouts==1
replace Value=3 if npixels>1 & npayouts>1
drop tag_village_pixel tag_village_payout npixels npayouts


****************************Question 3****************************

rename Rewiewer1 Reviewer1
preserve
  keep Reviewer1 Review1Score
  bysort Reviewer1: egen reviewer_mean = mean(Review1Score)
  bysort Reviewer1: egen reviewer_sd = sd(Review1Score)
  keep Reviewer1 reviewer_mean reviewer_sd
  duplicates drop
  tempfile r1_stats
  save r1_stats
restore

merge m:1 Reviewer1 using r1_stats
drop _merge
gen stand_r1_score = (Review1Score - reviewer_mean) / reviewer_sd
drop reviewer_mean reviewer_sd

preserve
  keep Reviewer2 Reviewer2Score
  bysort Reviewer2: egen reviewer_mean = mean(Reviewer2Score)
  bysort Reviewer2: egen reviewer_sd = sd(Reviewer2Score)
  keep Reviewer2 reviewer_mean reviewer_sd
  duplicates drop
  tempfile r2_stats
  save r2_stats
restore

merge m:1 Reviewer2 using r2_stats
drop _merge
gen stand_r2_score = (Reviewer2Score - reviewer_mean) / reviewer_sd
drop reviewer_mean reviewer_sd

preserve
  keep Reviewer3 Reviewer3Score
  bysort Reviewer3: egen reviewer_mean = mean(Reviewer3Score)
  bysort Reviewer3: egen reviewer_sd = sd(Reviewer3Score)
  keep Reviewer3 reviewer_mean reviewer_sd
  duplicates drop
  tempfile r3_stats
  save r3_stats
restore

merge m:1 Reviewer3 using r3_stats
drop _merge
gen stand_r3_score = (Reviewer3Score - reviewer_mean) / reviewer_sd
drop reviewer_mean reviewer_sd

egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)
gsort - average_stand_score
generate Rank=_n


****************************Question 4****************************
cd /Users/peggy/desktop/assignment__Stata_1_export
global wd "/Users/peggy/desktop/assignment__Stata_1_export"
global excel_t21 "$wd/q4_Pakistan_district_table21.xlsx"

tempfile table21
save table21, replace emptyok

forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") clear allstring //import
	display as error `i' //display the loop number
    gen temp_search = A + B
    keep if regexm(temp_search, "18 AND") == 1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	 forvalues k = 1/12 {
        gen data`k' = ""
    }
    
    local col_count = 1
        foreach var of varlist _all {
        if "`var'" != "temp_search" & substr("`var'", 1, 7) != "data" {
            local content = ustrtrim(`var'[1])
            local content = subinstr("`content'", ",", "", .)
            if regexm("`content'", "18 AND") == 0 & "`content'" != "" {
                if "`content'" == "-" {
                    local content = "0"
                }
                if `col_count' <= 12 {
                    replace data`col_count' = "`content'"
                    local col_count = `col_count' + 1
                }
            }
        }
    }
    
	gen district_id = `i'
    keep district_id data*
	append using table21 
	save table21, replace //saving the tempfile so that we don't lose any data
}

use table21, clear

destring data*, replace
drop in 136

destring data10, force replace
destring data11, force replace
order district_id, b(data1)

rename data1  total_population_all
rename data2  CNI_card_obtained_all
rename data3  CNI_card_not_obtained_all
rename data4  total_population_male
rename data5  CNI_card_obtained_male
rename data6  CNI_card_not_obtained_male
rename data7  total_population_female
rename data8  CNI_card_obtained_female
rename data9  CNI_card_not_obtained_female
rename data10 total_population_trans
rename data11 CNI_card_obtained_trans
rename data12 CNI_card_not_obtained_trans



****************************Question 5****************************

* Number of students who took the test
gen n_students = .
gen temp_students = regexs(1) if regexm(s, "WALIOFANYA MTIHANI *: *([0-9]+)")
destring temp_students, replace
replace n_students = temp_students if !missing(temp_students)
drop temp_students

*School average score
gen school_avergae_score = .
gen temp_average = regexs(1) if regexm(s, "WASTANI WA SHULE *: *([0-9.]+)")
destring temp_average, replace
replace school_avergae_score = temp_average if !missing(temp_average)
drop temp_average

*Student group (binary indicator: under 40 vs 40 or above)
gen student_group = .
gen temp_group = regexs(1) if regexm(s, "KUNDI LA SHULE : (.+?)<")
gen temp_group_binary = .
replace temp_group_binary = 0 if regexm(temp_group, "chini ya 40")
replace temp_group_binary = 1 if regexm(temp_group, "40") & !regexm(temp_group, "chini")
replace student_group = temp_group_binary if !missing(temp_group_binary)
drop temp_group temp_group_binary

*School ranking within the council (for example, 22 out of 46)
gen rank_council = .
gen temp_rank = regexs(1) if regexm(s, "KIHALMASHAURI: *([0-9]+) kati ya")
destring temp_rank, replace
replace rank_council = temp_rank if !missing(temp_rank)
drop temp_rank
gen total_council = .
gen temp_total = regexs(1) if regexm(s, "KIHALMASHAURI: *[0-9]+ kati ya *([0-9]+)")
destring temp_total, replace
replace total_council = temp_total if !missing(temp_total)
drop temp_total

*School ranking within the region (for example, 74 out of 290)
gen rank_region = .
gen temp_rank = regexs(1) if regexm(s, "KIMKOA *: *([0-9]+) kati ya")
destring temp_rank, replace
replace rank_region = temp_rank if !missing(temp_rank)
drop temp_rank
gen total_region = .
gen temp_total = regexs(1) if regexm(s, "KIMKOA *: *[0-9]+ kati ya *([0-9]+)")
destring temp_total, replace
replace total_region = temp_total if !missing(temp_total)
drop temp_total

*School ranking at the national level (for example, 545 out of 5,664)
gen rank_national = .
gen temp_rank = regexs(1) if regexm(s, "KITAIFA *: *([0-9]+) kati ya")
destring temp_rank, replace
replace rank_national = temp_rank if !missing(temp_rank)
drop temp_rank
gen total_national = .
gen temp_total = regexs(1) if regexm(s, "KITAIFA *: *[0-9]+ kati ya *([0-9]+)")
destring temp_total, replace
replace total_national = temp_total if !missing(temp_total)
drop temp_total

*school name
gen school_name = ""
gen temp_name = regexs(1) if regexm(s, ">([A-Z ]+PRIMARY SCHOOL) - ([A-Z0-9]+)")
replace school_name = temp_name if !missing(temp_name)
drop temp_name

*school code
gen school_code = ""
gen temp_code = regexs(2) if regexm(s, ">([A-Z ]+PRIMARY SCHOOL) - ([A-Z0-9]+)")
replace school_code = temp_code if !missing(temp_code)
drop temp_code


****************************Bonus Question****************************
set obs 16

*School code
gen schoolcode = "PS0101114"

*cand_id
gen cand_id = ""
replace cand_id = "PS0101114-0001" in 1
replace cand_id = "PS0101114-0002" in 2
replace cand_id = "PS0101114-0003" in 3
replace cand_id = "PS0101114-0004" in 4
replace cand_id = "PS0101114-0005" in 5
replace cand_id = "PS0101114-0006" in 6
replace cand_id = "PS0101114-0007" in 7
replace cand_id = "PS0101114-0008" in 8
replace cand_id = "PS0101114-0009" in 9
replace cand_id = "PS0101114-0010" in 10
replace cand_id = "PS0101114-0011" in 11
replace cand_id = "PS0101114-0012" in 12
replace cand_id = "PS0101114-0013" in 13
replace cand_id = "PS0101114-0014" in 14
replace cand_id = "PS0101114-0015" in 15
replace cand_id = "PS0101114-0016" in 16

*gender
gen gender = ""
replace gender = "M" in 1
replace gender = "M" in 2
replace gender = "M" in 3
replace gender = "M" in 4
replace gender = "M" in 5
replace gender = "M" in 6
replace gender = "M" in 7
replace gender = "M" in 8
replace gender = "F" in 9
replace gender = "F" in 10
replace gender = "F" in 11
replace gender = "F" in 12
replace gender = "F" in 13
replace gender = "F" in 14
replace gender = "F" in 15
replace gender = "F" in 16

*prem_number
gen prem_number = ""
replace prem_number = "20150348195" in 1
replace prem_number = "20156273910" in 2
replace prem_number = "20150348196" in 3
replace prem_number = "20156555361" in 4
replace prem_number = "20156272958" in 5
replace prem_number = "20150316147" in 6
replace prem_number = "20150348198" in 7
replace prem_number = "20150348199" in 8
replace prem_number = "20150377806" in 9
replace prem_number = "20152878842" in 10
replace prem_number = "20150348200" in 11
replace prem_number = "20150348201" in 12
replace prem_number = "20150348202" in 13
replace prem_number = "20150348203" in 14
replace prem_number = "20150348204" in 15
replace prem_number = "20150348205" in 16

*name
gen name = ""
replace name = "DANIEL JAMES KAGUO" in 1
replace name = "DAVIS ROBERT LUCAS" in 2
replace name = "ELISANTE GABRIEL NKYA" in 3
replace name = "FESTUS RENASTUS CHIMOLA" in 4
replace name = "IAN INNOCENT GEOFREY" in 5
replace name = "MESHACK THOMAS NATHANAEL" in 6
replace name = "PHILIPO AYUBU MBWANA" in 7
replace name = "SALIM IDDY RASHID" in 8
replace name = "DORA SALVATORY THADEI" in 9
replace name = "EVALYNE PERFECT ELIAS" in 10
replace name = "FATUMA SALIM SAIDI" in 11
replace name = "HAPPY JULIUS MZIRAI" in 12
replace name = "JOAN MANASE GEOFREY" in 13
replace name = "JOAN WILHARD MWANGA" in 14
replace name = "SOPHIA HAKEEM PALLANGYO" in 15
replace name = "ZAINAB RASHIDI SALUM" in 16

*Kiswahili
gen Kiswahili = ""
replace Kiswahili = "B" in 1
replace Kiswahili = "A" in 2
replace Kiswahili = "A" in 3
replace Kiswahili = "B" in 4
replace Kiswahili = "A" in 5
replace Kiswahili = "B" in 6
replace Kiswahili = "B" in 7
replace Kiswahili = "A" in 8
replace Kiswahili = "B" in 9
replace Kiswahili = "A" in 10
replace Kiswahili = "A" in 11
replace Kiswahili = "B" in 12
replace Kiswahili = "A" in 13
replace Kiswahili = "A" in 14
replace Kiswahili = "B" in 15
replace Kiswahili = "B" in 16

*English
gen English = ""
replace English = "A" in 1
replace English = "A" in 2
replace English = "A" in 3
replace English = "A" in 4
replace English = "A" in 5
replace English = "B" in 6
replace English = "B" in 7
replace English = "A" in 8
replace English = "A" in 9
replace English = "A" in 10
replace English = "A" in 11
replace English = "A" in 12
replace English = "A" in 13
replace English = "A" in 14
replace English = "A" in 15
replace English = "A" in 16

*Maarifa
gen Maarifa = ""
replace Maarifa = "C" in 1
replace Maarifa = "C" in 2
replace Maarifa = "D" in 3
replace Maarifa = "C" in 4
replace Maarifa = "C" in 5
replace Maarifa = "C" in 6
replace Maarifa = "D" in 7
replace Maarifa = "B" in 8
replace Maarifa = "C" in 9
replace Maarifa = "B" in 10
replace Maarifa = "C" in 11
replace Maarifa = "C" in 12
replace Maarifa = "B" in 13
replace Maarifa = "C" in 14
replace Maarifa = "C" in 15
replace Maarifa = "D" in 16

*Hisabati
gen Hisabati = ""
replace Hisabati = "C" in 1
replace Hisabati = "B" in 2
replace Hisabati = "B" in 3
replace Hisabati = "B" in 4
replace Hisabati = "A" in 5
replace Hisabati = "B" in 6
replace Hisabati = "B" in 7
replace Hisabati = "B" in 8
replace Hisabati = "A" in 9
replace Hisabati = "B" in 10
replace Hisabati = "A" in 11
replace Hisabati = "D" in 12
replace Hisabati = "A" in 13
replace Hisabati = "A" in 14
replace Hisabati = "A" in 15
replace Hisabati = "A" in 16

*Science
gen Science = ""
replace Science = "B" in 1
replace Science = "B" in 2
replace Science = "B" in 3
replace Science = "B" in 4
replace Science = "C" in 5
replace Science = "B" in 6
replace Science = "B" in 7
replace Science = "B" in 8
replace Science = "B" in 9
replace Science = "B" in 10
replace Science = "B" in 11
replace Science = "A" in 12
replace Science = "A" in 13
replace Science = "A" in 14
replace Science = "A" in 15
replace Science = "B" in 16

*Uraia
gen Uraia = ""
replace Uraia = "C" in 1
replace Uraia = "B" in 2
replace Uraia = "C" in 3
replace Uraia = "C" in 4
replace Uraia = "B" in 5
replace Uraia = "C" in 6
replace Uraia = "C" in 7
replace Uraia = "C" in 8
replace Uraia = "B" in 9
replace Uraia = "C" in 10
replace Uraia = "C" in 11
replace Uraia = "B" in 12
replace Uraia = "B" in 13
replace Uraia = "B" in 14
replace Uraia = "C" in 15
replace Uraia = "B" in 16

*average_stand_score
gen average_stand_score = ""
replace average_stand_score = "B" in 1
replace average_stand_score = "B" in 2
replace average_stand_score = "B" in 3
replace average_stand_score = "B" in 4
replace average_stand_score = "B" in 5
replace average_stand_score = "B" in 6
replace average_stand_score = "B" in 7
replace average_stand_score = "B" in 8
replace average_stand_score = "B" in 9
replace average_stand_score = "B" in 10
replace average_stand_score = "B" in 11
replace average_stand_score = "B" in 12
replace average_stand_score = "A" in 13
replace average_stand_score = "A" in 14
replace average_stand_score = "B" in 15
replace average_stand_score = "B" in 16














