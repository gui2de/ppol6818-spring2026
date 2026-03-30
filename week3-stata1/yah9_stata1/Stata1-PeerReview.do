cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\assignment__Stata_1_export\q1_data"
use school.dta

use student.dta

use teacher.dta 

use subject.dta

// Merging Datasets 

use teacher.dta, clear
merge m:1 school using "school.dta"
save "teacher_school_merged.dta", replace

use teacher_school_merged.dta, clear 
drop _merge
merge m:1 subject using "subject.dta" 
save "teacher_school_subject_merged.dta", replace

use teacher_school_subject_merged.dta, clear
use student.dta, clear
save student.dta, replace

use "teacher_school_subject_merged.dta", clear
drop _merge
save "teacher_final_clean.dta", replace

use "student.dta", clear
merge m:1 teacher using "teacher_final_clean.dta"

br 

// What is the mean student attendance for schools located in the "South"?

summarize attendance if loc == "South" 

/*

 Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180
  
The mean attendance is 178 days. 


*/

// Among students enrolled in high school, what proportion have a primary teacher who teaches a tested subject, i.e. "tested" = 1?

tab tested if level == "High"

/*
 tested |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        769       55.77       55.77
          1 |        610       44.23      100.00
------------+-----------------------------------
      Total |      1,379      100.00

	  
The proportion of high school students whose primary teacher teaches a tested subject is approximately 0.442 (or 44.2%).

*/ 

// What is the mean gpa of all students in the district?

summarize gpa

/* 

 Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334


The mean gpa of all students in the district is 3.601

*/


//  What is the mean attendance for each middle school?

tab school if level == "Middle", summarize(attendance)

/*


                                 |        Summary of attendance
                          school |        Mean   Std. dev.       Freq.
---------------------------------+------------------------------------
      Joseph Darby Middle School |   177.44079   2.8243018         304
    Mahatma Ghandi Middle School |   177.33438   3.2562283         317
  Malala Yousafzai Middle School |   177.54785   2.8239907         418
---------------------------------+------------------------------------
                           Total |    177.4514    2.961099       1,039


The mean attendance for each middle school: 

Joseph Darby Middle School: 177 days
Mahatma Gandhi Middle School: 177 days
Malala Yousafzai Middle School: 178 days 

*/ 

save "teacher_final_clean.dta", replace

************
*Question 2
**************

/* The payout status should be consistent within each pixel. Verify whether this condition
holds.
Create a new dummy variable, "pixel_consistent", defined as –
● pixel_consistent = 1 if all households within a pixel have the same payout
status
● pixel_consistent = 0 if there is any variation in payout status within a pixel

*/


cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\assignment__Stata_1_export"

use q2_village_pixel.dta

bysort pixel: tab payout

//Verified its consistent, through dummy variable method: 

bysort pixel: egen min_payout = min(payout)

bysort pixel: egen max_payout = max(payout)

gen pixel_consistent = (min_payout == max_payout)

br pixel payout pixel_consistent 

// It is consistent 

/*

b) In most cases, households within a village are in the same pixel, but some villages
may span multiple pixels (boundary cases).
Create a new village-level dummy variable, "pixel_village", defined as:
● pixel_village = 0 if all households in a village fall within a single pixel
● pixel_village = 1 if households in a village fall within more than one pixel

*/

tab village pixel

sort village pixel

bysort village: gen first_pixel = pixel[1]

bysort village: gen last_pixel = pixel[_N]

gen pixel_village = . 

replace pixel_village = 1 if first_pixel != last_pixel 

replace pixel_village = 0 if first_pixel == last_pixel 

br village pixel pixel_village 

/*

For this experiment, villages spanning multiple pixels only pose a problem if they also
have different payout statuses across pixels.
Using this criterion, classify households into the following categories:
● Villages that are entirely within a single pixel (Value = 1)
● Villages that span multiple pixels but have the same payout status across
pixels
(Create and report a list of all household IDs in these villages) (Value = 2)
● Villages that span multiple pixels and have different payout statuses across
pixels (Value = 3)

*/ 

tab payout, missing //checking for missing variables 

gen pixel_payout_status = . 

replace pixel_payout_status = 1 if pixel_village == 0 
replace pixel_payout_status = 2 if pixel_village == 1 & pixel_consistent == 1
list hhid if pixel_payout_status == 2 
replace pixel_payout_status = 3 if pixel_village == 1 & pixel_consistent == 0 

/*

List: 

 +-----------+
     |      hhid |
     |-----------|
 48. | 110202207 |
 49. | 110202203 |
 50. | 110202201 |
 51. | 110202210 |
 52. | 110202212 |
     |-----------|
 55. | 110202506 |
 56. | 110202505 |
 57. | 110202509 |
 58. | 110202501 |
 59. | 110202510 |
     |-----------|
 82. | 110203505 |
 83. | 110203509 |
 84. | 110203507 |
170. | 120507101 |
171. | 120507102 |
     |-----------|
172. | 120507103 |
173. | 120507111 |
174. | 120507104 |
201. | 120508209 |
202. | 120508208 |
     |-----------|
203. | 120508206 |
204. | 120508202 |
205. | 120508203 |
206. | 120508204 |
255. | 120610109 |
     |-----------|
256. | 120610102 |
257. | 120610103 |
258. | 120610107 |
266. | 120610605 |
267. | 120610604 |
     |-----------|
268. | 120610602 |
269. | 120610609 |
278. | 120611102 |
279. | 120611108 |
280. | 120611101 |
     |-----------|
281. | 120611205 |
282. | 120611206 |
283. | 120611209 |
284. | 120611210 |
285. | 120611201 |
     |-----------|
312. | 120712305 |
313. | 120712310 |
321. | 120712803 |
322. | 120712801 |
342. | 120813801 |
     |-----------|
343. | 120813803 |
344. | 120813807 |
345. | 120813804 |
346. | 120813811 |
375. | 120814703 |
     |-----------|
376. | 120814705 |
377. | 120814711 |
378. | 120814710 |
379. | 120814702 |
380. | 120814704 |
     |-----------|
385. | 120814901 |
386. | 120814907 |
387. | 120814911 |
388. | 120814903 |
492. | 121019203 |
     |-----------|
493. | 121019204 |
494. | 121019208 |
495. | 121019209 |
496. | 121019210 |
497. | 121019201 |
     |-----------|
498. | 121019309 |
499. | 121019308 |
500. | 121019306 |
534. | 131120509 |
535. | 131120506 |
     |-----------|
536. | 131120510 |
571. | 131221901 |
572. | 131221909 |
573. | 131221904 |
574. | 131221912 |
     |-----------|
575. | 131221905 |
615. | 131424206 |
616. | 131424211 |
617. | 131424205 |
618. | 131424204 |
     |-----------|
635. | 131424609 |
636. | 131424610 |
637. | 131424604 |
638. | 131424602 |
651. | 141525312 |
     |-----------|
652. | 141525310 |
653. | 141525302 |
654. | 141525309 |
718. | 141627412 |
719. | 141627401 |
     |-----------|
720. | 141627408 |
721. | 141627407 |
722. | 141627405 |
728. | 141727712 |
729. | 141727709 |
     |-----------|
730. | 141727707 |
731. | 141727701 |
739. | 141728101 |
740. | 141728103 |
741. | 141728108 |
     |-----------|
742. | 141728102 |
755. | 141728601 |
756. | 141728607 |
757. | 141728606 |
758. | 141728603 |
     |-----------|
759. | 141728608 |
828. | 152431707 |
829. | 152431703 |
830. | 152431702 |
831. | 152431708 |
     |-----------|
832. | 152431706 |
865. | 162533008 |
866. | 162533002 |
872. | 162533401 |
873. | 162533408 |
     |-----------|
890. | 162633905 |
891. | 162633902 |
892. | 162633907 |
893. | 162633912 |
894. | 162633906 |
     |-----------|
895. | 162633908 |
950. | 131336107 |
951. | 131336109 |
952. | 131336101 |
     +-----------+

*/ 

***********
*Question 3
***********
clear
use "C:\Users\fabih\Downloads\q3_proposal_review.dta"
/*
Faculty members submitted 128 proposals for funding, but resources are available
to fund only 50 grants. Each proposal was randomly assigned to three reviewers, and each
reviewer assigned a score between 1 (lowest) and 5 (highest). Each reviewer evaluated 24
proposals and assigned a score.
Since reviewers may differ in how strictly they score, you are asked to standardize scores at the
reviewer level before computing final rankings. We think it will be better if we normalize the
score wrt each reviewer (using unique ids) before calculating the average score. The formula is
as follows:
Standardized Score = (score – mean)/sd, where
● mean = mean score of that particular reviewer (based on the NetID)
● sd = standard deviation of scores of that particular reviewer (based on that NetID)
Using the reviewer NetID (not reviewer position 1, 2, or 3), complete the following tasks:
1. Create standardized score variables for each review:
a. stand_r1_score
b. stand_r2_score
c. stand_r3_score
2. Compute the average standardized score as "average_stand_score" for each proposal
3. Rank proposals based on average_stand_score, where:
a. Rank = 1 corresponds to the highest score
b. Rank = 128 corresponds to the lowest score

*/ 

rename Rewiewer1 reviewer1    
rename Reviewer2 reviewer2    
rename Reviewer3 reviewer3

rename Review1Score Reviewer1Score

rename Reviewer1Score score1

rename Reviewer2Score score2

rename Reviewer3Score score3


reshape long reviewer score, i(proposal_id) j(reviewer_position)

bysort reviewer: egen reviewer_mean = mean(score)

bysort reviewer: egen reviewer_sd = sd(score)

gen stand_score = (score - reviewer_mean) / reviewer_sd

keep proposal_id reviewer_position stand_score
reshape wide stand_score, i(proposal_id) j(reviewer_position)

rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)


gsort -average_stand_score
gen rank = _n

//Highest rank is 105 proposal_id


********
*Question 4
********


/*

You are given information on adults who possess a computerized national ID card
in the file "Pakistan_district_table21.pdf". This PDF contains 135 tables, one for each district.
The tables were extracted using OCR software, but the resulting data contain formatting
inaccuracies.
Your task is to extract columns 2 through 13 from the first data row ("18 and above") in each
district table and construct a dataset in which each row corresponds to one district.
A hint do-file has been provided that includes code to loop through each table. You will need to
modify or extend this code to ensure that the columns are correctly aligned across districts.
Hint: While the table structure is mostly consistent, there are a small number of minor formatting
anomalies. Be sure to inspect your output carefully and adjust your code as needed.

*/

clear 
cls


**Problems I noticed: data is misaligned in the columns and 18 & Above isn't consistent 


clear

global wd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design"
global excel_t21 "$wd\q4_Pakistan_district_table21.xlsx"


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
	
***Dropping empty cells 
foreach v of varlist _all {
        capture count if !missing(`v')
        if r(N) == 0 {
            drop `v'
        }
    }

*** Standardizing column numbers 
rename * col#, addnumber
rename col1 table21

**to remove the empty spaces
replace table21 = "18 AND ABOVE" if regexm(table21, "18 AND") | regexm(table21, "OVERALL")

**what columns to keep 
capture keep table21 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13 table_number
	
	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %40s table21 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13


br

******
**Question 5
******

/*
This task focuses on string cleaning and data wrangling. Data for a school were
scraped from a Tanzanian government website, but the resulting formatting is highly
unstructured. Your task is to extract the following school-level variables:
1. Number of students who took the test ****
2. School average score ****
3. Student group (binary indicator: under 40 vs 40 or above)
4. School ranking within the council (for example, 22 out of 46)
5. School ranking within the region (for example, 74 out of 290)
6. School ranking at the national level (for example, 545 out of 5,664)
In addition to these variables, also capture the school name and school code in two different
columns.
*/


clear 
cls
clear
	
cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\assignment__Stata_1_export\q5"

use "$wd//Assignment/q5_Tz_student_roster_html.dta", clear 

//Students Who Took Test

gen students_took_test = regexs(1) if regexm(s, "WALIOFANYA MTIHANI : ([0-9]+)")
destring students_took_test, replace

// School Name 
gen school_name = regexs(1) if regexm(s, ">([A-Z ]+) - PS")

//School Code 

gen school_code = regexs(1) if regexm(s, "(PS[0-9]+)")

//School Average Score 

gen school_avg_score = regexs(1) if regexm(s, "WASTANI WA SHULE *: ([0-9.]+)")
destring school_avg_score, replace

// Student group (binary indicator: under 40 vs 40 or above)

gen sg_under_40 = regexm(s, "KUNDI LA SHULE : .*chini ya 40")

//School Ranking Within The Council (for example, 22 out of 46) 

gen rank_council = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI *: ([0-9]+)")
destring rank_council, replace

//School ranking within the region (for example, 74 out of 290)

gen rank_region = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA *: ([0-9]+)")
destring rank_region, replace

//School ranking at national level 

gen rank_national = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA *: ([0-9]+)")
destring rank_national, replace



*******
**Bonus Question 
*******

/*

This task involves string cleaning and data wrangling. We scrapped student
data for a school from a Tanzanian government website. Unfortunately, the formatting of the
data is a mess. Your task is to create a student level dataset with the following variables:
schoolcode, cand_id, gender, prem_number, name, grade variables for: Kiswahili, English,
maarifa, hisabati, science, uraia, average.
Note: This is a student level dataset, and should have 16 rows (same as the number of
students in that school).

*/

clear

cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\assignment__Stata_1_export\q5"
*update the wd global so that it refers to the Box folder filepath on your machine

use "$wd//Assignment/q5_Tz_student_roster_html.dta", clear 

split s, parse("</TR>") gen(row)

gen id = 1
reshape long row, i(id) j(n)

keep if ustrregexm(row, "PS[0-9]+-[0-9]+")

// School Code 

gen school_code = regexs(1) if regexm(s, "(PS[0-9]+)")

//Cand Id 

gen can_id = regexs(1) if regexm(s, "(PS0101114-[0-9]+)")

//Gender- 1 if it's M 

gen sex_m = regexm(s, "M")

//Prem_Number 

gen p_num = regexs(1) if regexm(s, "(2015[0-9]+)") //idk how to fix this 

//Name 

gen name = regexs(1) if regexm(s, "<P>([A-Z ]+)</FONT>")

// Subject and Grades- looping to extract

local subjects "Kiswahili English Maarifa Hisabati Science Uraia"

foreach sub of local subjects {
    
    local varname = lower("`sub'")
    
    * Match subject name 
    gen `varname' = regexs(1) if regexm(s, "`sub' - ([A-F])")
}

* Extract Average Grade
gen average = regexs(1) if regexm(s, "Average Grade - ([A-F])")




