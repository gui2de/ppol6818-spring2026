************************
* Class: Guide Class
* Topic: Assignment 1
* Author: Kate Morris
* Date: January 31, 2026
***************

cd "/Users/cam_cew/Desktop/Experimental_design/Feb_8_assignment/q1_data"

pwd


*** Question 1a: What is the mean student attendance for school located in the South?

*** I tried using temp files for this first but that didn't work, so I began creating files saved to my desktop

clear all

use "student.dta", clear
save "students_temp.dta", replace


use "teacher.dta", clear
save "teacher_temp.dta", replace
rename teacher primary_teacher



merge 1:m primary_teacher using "students_temp.dta"

*** I noticed that this generated a _merge variable

/* tab _merge

Matching result from |
                  merge |      Freq.     Percent        Cum.
------------------------+-----------------------------------
            Matched (3) |      4,490      100.00      100.00
------------------------+-----------------------------------
                  Total |      4,490      100.00


				  */

*** I didn't want to keep the _merge variable so I dropped it
				  
drop _merge


save "students_teachers.dta", replace


use "school.dta", clear

merge 1:m school using "students_teachers.dta"


tab _merge

/*  Matching result from |
                  merge |      Freq.     Percent        Cum.
------------------------+-----------------------------------
            Matched (3) |      4,490      100.00      100.00
------------------------+-----------------------------------
                  Total |      4,490      100.00
*/

drop _merge

save "students_teachers_location.dta", replace


summarize attendance if loc == "South"

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180

  
 
*******************************************************************************
*** Question 1b: Among students enrolled in high school, what proportion have a primary teacher who teaches a tested subject, i.e. "tested" = 1?


clear all

use "students_teachers_location.dta", clear
save "students_teachers_location_temp.dta", replace

merge m:1 subject using "subject_temp.dta"

tab _merge
drop _merge

 tab tested if level == "High"

 
  tested |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        769       55.77       55.77
          1 |        610       44.23      100.00
------------+-----------------------------------
      Total |      1,379      100.00

	  
*** 44% of high school students have a primary teacher who teaches a tested subject



*******************************************************************************	  
*** Question 1c: What is the mean gpa of all students in the district


clear all

use "students_teachers_location.dta", clear
save "students_teachers_location_temp.dta", replace

merge m:1 subject using "subject_temp.dta"

tab _merge

drop _merge

sum gpa

 Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334
		 

*** The mean GPA for all students in the district is 3.6



*******************************************************************************
*** Question 1d: what is the mean attendance for each middle school?

*** checking out the names of the different schools, to see how many individual middle schools there are

tab school level


           |              level
               school | Element..       High     Middle |     Total
----------------------+---------------------------------+----------
Abraham Lincoln Ele.. |       316          0          0 |       316 
Amartya Sen High Sc.. |         0        610          0 |       610 
Benjamin Franklin E.. |       436          0          0 |       436 
Horace Mann Element.. |       327          0          0 |       327 
John Dewey Elementary |       234          0          0 |       234 
Joseph Darby Middle.. |         0          0        304 |       304 
Mahatma Ghandi Midd.. |         0          0        317 |       317 
Malala Yousafzai Mi.. |         0          0        418 |       418 
Martin Luther King .. |       243          0          0 |       243 
Norman Borlaug High.. |         0        769          0 |       769 
Rachel Carson Eleme.. |       261          0          0 |       261 
Robert Smalls Eleme.. |       255          0          0 |       255 
----------------------+---------------------------------+----------
                Total |     2,072      1,379      1,039 |     4,490 

save "middle_school_students.dta", replace
keep if level == "Middle"

tabstat attendance, by(school) stat(mean)

          school |      Mean
-----------------+----------
Joseph Darby Mid |  177.4408
Mahatma Ghandi M |  177.3344
Malala Yousafzai |  177.5479
-----------------+----------
           Total |   177.441



		   
*******************************************************************************
*** Question 2a. The payout status should be consistent within each pixel. Verify whether this condition holds. Create a new dummy variable, "pixel_consistent," with 1: if all households within a pixel have the same payout and 0 = if there is any variation in payout status within a pixel

clear all

*** Picking up work again after a break and closing out Stata

cd "/Users/cam_cew/Desktop/Experimental_design/Feb_8_assignment"

use "q2_village_pixel.dta", clear
save "q2_village_pixel_temp.dta", replace


tab pixel payout,row

*** The payout looks consistent

gen pixel_consistent = .

bysort pixel: egen min_payout = min(payout)
bysort pixel: egen max_payout = max(payout)

replace pixel_consistent = 0 if min_payout != max_payout
replace pixel_consistent = 1 if min_payout == max_payout

tab pixel_consistent

drop min_payout max_payout

**** all pixels have a consistent payout


/* Question 2b: In most cases, households within a village are in the same pixel, but some villages
may span multiple pixels (boundary cases).
Create a new village-level dummy variable, "pixel_village", defined as:
● pixel_village = 0 if all households in a village fall within a single pixel
● pixel_village = 1 if households in a village fall within more than one pixel */

use "q2_village_pixel_temp.dta", clear

sort village

bysort village (pixel): gen unique_pixels = pixel != pixel[_n-1]
bysort village: replace unique_pixels = sum(unique_pixels)
bysort village: replace unique_pixels = unique_pixels[_N]

gen pixel_village = .

replace pixel_village = 0 if unique_pixels == 1
replace pixel_village = 1 if unique_pixels == 2

label define pixel_label 0 "Single pixel" 1 "Multiple pixels"
label values pixel_village pixel_label

drop unique_pixels

tab pixel_village

  pixel_village |      Freq.     Percent        Cum.
----------------+-----------------------------------
   Single pixel |        834       87.06       87.06
Multiple pixels |        124       12.94      100.00
----------------+-----------------------------------
          Total |        958      100.00


/* Questions 2c: For this experiment, villages spanning multiple pixels only pose a problem if they also have different payout statuses across pixels. Using this criterion, classify households into the following categories:
● Villages that are entirely within a single pixel (Value = 1)
● Villages that span multiple pixels but have the same payout status across
pixels (Create and report a list of all household IDs in these villages) (Value = 2)
● Villages that span multiple pixels and have different payout statuses across
pixels (Value = 3) */

clear all

use "q2_village_pixel_temp.dta", clear

bysort village: egen p_min = min(payout)
bysort village: egen p_max = max(payout)
gen p_differs = (p_min != p_max)

tab pixel_village, m

gen village_category = .

replace village_category = 0 if pixel_village == 0
replace village_category = 1 if pixel_village == 1 & p_differs == 0
replace village_category = 2 if pixel_village == 1 & p_differs == 1

tab village_category, m

village_cat |
      egory |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        834       87.06       87.06
          1 |         50        5.22       92.28
          2 |         74        7.72      100.00
------------+-----------------------------------
      Total |        958      100.00

	  
drop p_min p_max p_differs



/* Question 3: Faculty members submitted 128 proposals for funding, but resources are available to fund only 50 grants. Each proposal was randomly assigned to three reviewers, and each reviewer assigned a score between 1 (lowest) and 5 (highest). Each reviewer evaluated 24 proposals and assigned a score.
Since reviewers may differ in how strictly they score, you are asked to standardize scores at the reviewer level before computing final rankings. We think it will be better if we normalize the score wrt each reviewer (using unique ids) before calculating the average score. The formula is as follows:
Standardized Score = (score – mean)/sd, where
● mean = mean score of that particular reviewer (based on the NetID)
● sd = standard deviation of scores of that particular reviewer (based on that NetID)
Using the reviewer NetID (not reviewer position 1, 2, or 3), complete the following tasks:
1. Create standardized score variables for each review:
a. stand_r1_score b. stand_r2_score c. stand_r3_score
2. Compute the average standardized score as "average_stand_score" for each proposal
3. Rank proposals based on average_stand_score, where:
a. Rank = 1 corresponds to the highest score
b. Rank = 128 corresponds to the lowest score */


clear all

use "q3_proposal_review.dta", clear
save "q3_proposal_review_temp.dta", replace

*** Made a series of mistakes so cleared all and started over with the work file

use "q3_proposal_review_temp.dta", clear

*** revising labels and putting all variables in lowercase to make coding easier

rename Rewiewer1 reviewer1
rename Review1Score reviewerscore1
rename Reviewer2Score reviewerscore2
rename Reviewer3Score reviewerscore3
rename *, lower


reshape long reviewer reviewerscore, i(proposal_id) j(pos)

bysort reviewer: egen m = mean(reviewerscore)
bysort reviewer: egen s = sd(reviewerscore)

gen stand_score = .
replace stand_score = (reviewerscore - m) / s if s > 0 & s != .

drop m s

reshape wide reviewer reviewerscore stand_score, i(proposal_id) j(pos)

rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)

egen rank = rank(average_stand_score), field

sort rank
list proposal_id average_stand_score rank in 1/50

/*     | propos~d   a~_score   rank |
     |----------------------------|
  1. |      105   1.095271      1 |
  2. |      114   1.072452      2 |
  3. |       65   1.044625      3 |
  4. |       77   1.008047      4 |
  5. |       75   .9732648      5 |
     |----------------------------|
  6. |       84   .9473619      6 |
  7. |       78   .8316699      7 |
  8. |       86   .7812539      8 |
  9. |       33   .7636148      9 |
 10. |       46   .7450528     10 |
     |----------------------------|
 11. |      100   .7416676     11 |
 12. |       71   .7415178     12 |
 13. |       52   .7378891     13 |
 14. |       18   .7267417     14 |
 15. |       58   .7149979     15 |
     |----------------------------|
 16. |      111   .7030721     16 |
 17. |       45   .6455194     17 |
 18. |       26   .6384386     18 |
 19. |       57   .6203605     19 |
 20. |       91   .6177917     20 |
     |----------------------------|
 21. |       59   .5999078     21 |
 22. |       51     .58099     22 |
 23. |       68   .5744227     23 |
 24. |      112   .5701222     24 |
 25. |      108   .5421028     25 |
     |----------------------------|
 26. |       44    .537549     26 |
 27. |        9   .4922419     27 |
 28. |       92   .4815972     28 |
 29. |       88   .4754057     29 |
 30. |       13   .4664439     30 |
     |----------------------------|
 31. |        8   .4652879     31 |
 32. |       27   .4590366     32 |
 33. |      119   .4119876     33 |
 34. |      118   .4004899     34 |
 35. |       72   .3999041     35 |
     |----------------------------|
 36. |       80   .3998114     36 |
 37. |       98   .3851046     37 |
 38. |      127   .3832116     38 |
 39. |       61   .3781382     39 |
 40. |       23   .3775783     40 |
     |----------------------------|
 41. |       87   .3715229     41 |
 42. |      101   .3645006     42 |
 43. |       81    .340217     43 |
 44. |       34    .331895     44 |
 45. |        1   .3252122     45 |
     |----------------------------|
 46. |      102   .3138168     46 |
 47. |       21   .3068023     47 |
 48. |       89   .2978317     48 |
 49. |       20   .2847954     49 |
 50. |       60   .2836112     50 |
*/

/* Question 4: You are given information on adults who possess a computerized national ID card in the file "Pakistan_district_table21.pdf". This PDF contains 135 tables, one for each district. The tables were extracted using OCR software, but the resulting data contain formatting inaccuracies.
  
Your task is to extract columns 2 through 13 from the first data row ("18 and above") in each district table and construct a dataset in which each row corresponds to one district.
A hint do-file has been provided that includes code to loop through each table. You will need to modify or extend this code to ensure that the columns are correctly aligned across districts.
Hint: While the table structure is mostly consistent, there are a small number of minor formatting anomalies. Be sure to inspect your output carefully and adjust your code as needed.*/

clear all

cd "/Users/cam_cew/Desktop/Experimental_design/Feb_8_assignment"

import excel "q4_pakistan_district_table21.xlsx", describe

*** It looks like some of the "B" columns got switched to "E" or are just missing. Some of the columns also extend to Z, others to AA

*** the table import is very messy as shown by running the code below

import excel "q4_pakistan_district_table21.xlsx", sheet("Table 1") allstring clear
list A B C in 1/20


**********************************************

*** Code, using the hint file


global wd "/Users/cam_cew/Desktop/Experimental_design/Feb_8_assignment"

global excel_t21 "$wd//q4_Pakistan_district_table21.xlsx"




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
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %40s table21 B C D E F G H I J K L M N O P Q R S T U V W X Y  Z AA AB AC




*** the data looks very messy with tons of missings, but I'm going to save it so as to not lose it

save "pakistan_districts_temp.dta", replace


*** I think we can drop the first column 
    drop table21 
    
**** The columns are all given alphabetical labels, but I'm not sure how to correct that without messing things up. So I'm going to stop here, because I think I missed something in class.





/* Question 5: This task focuses on string cleaning and data wrangling. Data for a school were scraped from a Tanzanian government website, but the resulting formatting is highly unstructured. Your task is to extract the following school-level variables:
1. Number of students who took the test
2. School average score
3. Student group (binary indicator: under 40 vs 40 or above)
4. School ranking within the council (for example, 22 out of 46)
5. School ranking within the region (for example, 74 out of 290)
6. School ranking at the national level (for example, 545 out of 5,664)
In addition to these variables, also capture the school name and school code in two different columns.
Note: This is a school level dataset, and should only contain one row with all the variables. All the school level information is given in the html file provided with the assignment files, which you can open using any browser. The page is in Swahili but it should be fairly straightforward to find the relevant information. You can use google translate if you have trouble finding the relevant parts of the webpage. */

clear all

cd "/Users/cam_cew/Desktop/Experimental_design/Feb_8_assignment/q5"
pwd


use "shl_ps0101114.html", clear
*** there doesn't seem to be anything in this file, so I'm going to attempt to use the html file... but I am not sure how to import an html file or how to direct Stata to use that instead. 


use "q5_Tz_student_roster_html.dta", clear

*** This pulls up the same thing.

*** I suspect there's a way to pull in the data using some kind of generate command? But I am not sure. I have spent hours trying to figure this out, and am feeling pretty lost. I am instead going to generate the variables using the translated information from the website. 

gen school_name = "ALBEHIJE PRIMARY SCHOOL"
gen school_code = "PS0101114"

*** There is a random s variable in there, probably from when I tried to import the file.

drop s


gen student_number = 16

gen avg_score = 217.3750

gen student_group = "Less than 40"

gen council_rank = 22

gen regional_rank = 74


*** This creates a one-row data set with all the relevant variables. Obviously, a true Stata professional would use a different system/code, but this is the best I could do.

gen national_rank = 545

