/*Experimental Design, Stata 1, Emilia Antunez



QUESTION 1*/

cd "/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Stata1HW/q1_data_export"

/* DATASETS

use student.dta

use teacher.dta

use school.dta

use subject.dta
*/

/* Order the key identifier in the using dataset, and change its name so it's the same as in the master dataset*/

use student.dta

rename primary_teacher teacher

gsort teacher

save v1_student.dta, replace


/*Merging teacher.dta (master) and v1_student.dta (using)*/

use teacher.dta, clear

merge 1:m teacher using "v1_student.dta"

gsort teacher

drop _merge

save teacher_student_m.dta, replace

clear

/*Merging school.dta (master) and teacher_student_m.dta (using)*/

use school.dta

merge 1:m school using "teacher_student_m.dta"

gsort school

drop _merge

save school_teacher_student_m.dta, replace

clear

/*Merging subject.dta (master) and school_teacher_student_m.dta (using)*/

use subject.dta

merge 1:m subject using "school_teacher_student_m.dta"

order stdnt_num teacher school loc, before (subject)

gsort stdnt_num

drop _merge

save subject_school_teacher_student_m.dta, replace

/*

A) What is the mean student attendance for schools located in the "South"?*/

use subject_school_teacher_student_m.dta

summarize attendance if loc=="South"

/*The mean student attendance in schools in the South is 177.4776 days per year.



B) Among students enrolled in high school, what proportion has a primary teacher who teaches a tested subject, i.e. "tested" = 1?*/

count if level=="High"
count if level=="High" & tested==1
display 610/1379

/*The proportion of students enrrolled in high school who have a teacher with a tested subject is .44234953.



C) What is the mean gpa of all students in the district?*/
summarize gpa

/*The mean GPA in the district is 3.60144.



D) What is the mean attendance for each middle school?*/
gen school_tag = tag(school)
bysort level: list school if school_tag == 1
tabstat atten if level=="Middle", by(school)

/*The mean attendance per school is:
          school |      Mean
-----------------+----------
Joseph Darby Mid |  177.4408
Mahatma Ghandi M |  177.3344
Malala Yousafzai |  177.5478
-----------------+----------
           Total |  177.4514
----------------------------
*/







/*QUESTION 2*/
 
cd "/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Stata1HW"

use q2_village_pixel.dta, clear

/*You are working on a crop insurance project in Kenya. For each household, the dataset includes village name, pixel identifier, and payout status.




A) The payout status should be consistent within each pixel. Verify whether this condition holds.

Create a new dummy variable, "pixel_consistent", defined as –

● pixel_consistent = 1 if all households within a pixel have the same payout
status

● pixel_consistent = 0 if there is any variation in payout status within a pixel*/
tab pixel payout

gen pixel_consistent=. 

bysort pixel: replace pixel_consistent=1 if payout==1 | payout==0
bysort pixel: replace pixel_consistent=0 if payout==1 & payout==0

/*The condition holds for every pixel.






B) In most cases, households within a village are in the same pixel, but some villages may span multiple pixels (boundary cases).
Create a new village-level dummy variable, "pixel_village", defined as:
● pixel_village = 0 if all households in a village fall within a single pixel
● pixel_village = 1 if households in a village fall within more than one pixel
*/

tab village pixel

bysort village (pixel): gen pixel_village = pixel[1] == pixel[_N] //This is telling stata to compare the first element in pixel, per village, with the last element in pixel, per village. This way we can know if values are different.

replace pixel_village = 1 - pixel_village //Because the gen command automatically generates a value of 1 if all pixel units are the same, we have to change it so that 1 means that pixel units are different within one village. We do this because that is what the HW asks.

tab village pixel 
tab village pixel_village // These two lines are made to check that the villages with more than one pixel are in fact categorized. MUDHIERO is a town that has more than one pixel, you find that information in the tab village pixel and then check again in tab village pixel_village to see that the village has a value of 1.







/* 3) For this experiment, villages spanning multiple pixels only pose a problem if they also have different payout statuses across pixels.

Using this criterion, classify households into the following categories:
● Villages that are entirely within a single pixel (Value = 1)
● Villages that span multiple pixels but have the same payout status across
pixels
(Create and report a list of all household IDs in these villages) (Value = 2)
● Villages that span multiple pixels and have different payout statuses across
pixels (Value = 3)*/

gen payout_pixel_village =.
replace payout_pixel_village=1 if pixel_village==0
replace payout_pixel_village=2 if pixel_village==1 & pixel_consistent==1
replace payout_pixel_village=3 if pixel_village==1 & pixel_consistent==0

list hhid village // HOW CAN I MAKE A BETTER LIST?









/* QUESTION 3 

Faculty members submitted 128 proposals for funding, but resources are available to fund only 50 grants. Each proposal was randomly assigned to three reviewers, and each reviewer assigned a score between 1 (lowest) and 5 (highest). Each reviewer evaluated 24 proposals and assigned a score.

Since reviewers may differ in how strictly they score, you are asked to standardize scores at the reviewer level before computing final rankings. We think it will be better if we normalize the score wrt each reviewer (using unique ids) before calculating the average score. 

The formula is as follows:
Standardized Score = (score – mean)/sd, where

● mean = mean score of that particular reviewer (based on the NetID)
● sd = standard deviation of scores of that particular reviewer (based on that NetID)

Using the reviewer NetID (not reviewer position 1, 2, or 3), complete the following tasks:

1. Create standardized score variables for each review:
	a. stand_r1_score 
	b. stand_r2_score 
	c. stand_r3_score*/


* 0. Understand data	

use q3_proposal_review.dta, clear

rename Rewiewer1 R1_reviewer
rename Reviewer2 R2_reviewer
rename Reviewer3 R3_reviewer
rename Review1Score R1_score
rename Reviewer2Score R2_score
rename Reviewer3Score R3_score

ssc install egenmore

describe
/*

Variable      Storage   Display    Value
    name         type    format    label      Variable label
-----------------------------------------------------------------------------------------------------
proposal_id     float   %9.0g                 
PIName          str24   %24s                  PI Name
Department      str53   %53s                  Department
R1_reviewer     str6    %9s                   Rewiewer 1
R2_reviewer     str6    %9s                   Reviewer 2
R3_reviewer     str6    %9s                   Reviewer 3
R1_score        double  %14.2fc               Review 1 Score
R2_score        double  %14.2fc               Reviewer 2 Score
R3_score        double  %14.2fc               Reviewer 3 Score
AverageScore    double  %10.0g                Average Score
StandardDevia~n double  %14.2fc               Standard Deviation

*/

list proposal_id R1_r R2_r R3_r R1_score R2_score R3_score  


* 2. Loop with foreach

forvalues i = 1/3 {

    bysort R`i'_reviewer: egen mean_r`i' = mean(R`i'_score)
	
    bysort R`i'_reviewer: egen sd_r`i'   = sd(R`i'_score)

    gen stand_r`i'_score = (R`i'_score - mean_r`i') / sd_r`i'
}








/*QUESTION 4

You are given information on adults who possess a computerized national ID card in the file "Pakistan_district_table21.pdf". This PDF contains 135 tables, one for each district. The tables were extracted using OCR software, but the resulting data contain formatting inaccuracies.
  
Your task is to extract columns 2 through 13 from the first data row ("18 and above") in each district table and construct a dataset in which each row corresponds to one district.

A hint do-file has been provided that includes code to loop through each table. You will need to modify or extend this code to ensure that the columns are correctly aligned across districts.

Hint: While the table structure is mostly consistent, there are a small number of minor formatting anomalies. Be sure to inspect your output carefully and adjust your code as needed.*/


global wd "/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Stata1HW"

global excel_t21 "/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Stata1HW/q4_Pakistan_district_table21.xlsx"


*setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135) this will take 1-5 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
	display as error `i' //display the loop number

 
keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND". Regexm is a command that helps you keep rows that contain only that string element.

*I'm using regex because the following code won't work if there are any trailing/leading blanks

*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
keep in 1 //there are 3 of them, but we want the first one

rename TABLE21PAKISTANICITIZEN1 table21

*Eliminate extra columns
foreach v of varlist _all {
    quietly capture confirm string variable `v'
    if !_rc {
        if ustrtrim(`v'[1]) == "" drop `v'
    }
    else {
        if missing(`v'[1]) drop `v'
    }
}

gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}


*Rename variables
rename B all_total_pop
rename C all_cni_obtained
rename D all_cni_not_obtained
rename E male_total_pop
rename F male_cni_obtained
rename G male_cni_not_obtained
rename H female_total_pop
rename I female_cni_obtained
rename J female_cni_not_obtained
rename K trans_total_pop
rename L trans_cni_obtained
rename M trans_cni_not_obtained








/*QUESTION 5

This task focuses on string cleaning and data wrangling. Data for a school were scraped from a Tanzanian government website, but the resulting formatting is highly unstructured. 

Your task is to extract the following school-level variables:
1. Number of students who took the test
2. School average score
3. Student group (binary indicator: under 40 vs 40 or above)
4. School ranking within the council (for example, 22 out of 46)
5. School ranking within the region (for example, 74 out of 290)
6. School ranking at the national level (for example, 545 out of 5,664)

In addition to these variables, also capture the school name and school code in two different columns.

Note: This is a school level dataset, and should only contain one row with all the variables. All the school level information is given in the html file provided with the assignment files, which you can open using any browser. The page is in Swahili but it should be fairly straightforward to find the relevant information. You can use google translate if you have trouble finding the relevant parts of the webpage.*/

cd "/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Stata1HW"

use q5_Tz_student_roster_html.dta

net install readhtml, from(https://ssc.wisc.edu/sscc/stata/)

net install htmltab2stata.pkg

htmltab2stata , url(shl_ps0101114.html)

* School name and code from:
* "ALBEHIJE PRIMARY SCHOOL - PS0101114"
gen strL school_name = ""
gen str20 school_code = ""

