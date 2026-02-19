//Abhinav Dutt Experimental Design STATA assignment 1 February 8

cd"/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Github/ppol6818-spring2026/week3-stata1/ad2165-STATA1"

//Question 1

use school.dta //starting with dataset that has variables school, level, gpa, and loc as the master data set (school.dta)

merge 1:m school using teacher.dta 

drop _merge //dropping merge variable after checking that all 195 entries had merge value 3

rename teacher primary_teacher //doing this so it can merge with the next file 

merge 1:m primary_teacher using student.dta 

drop _merge //dropping merge variable after checking that all 4490 entries had merge value 3

merge m:1 subject using subject.dta 

//all 4 data sets have been successfully merged into school.dta 
//the unique variable in the daat set with no repeating values is stdnt_num

tabstat attendance if loc=="South" //a. The answer is 177.4776

//By examining subject.dta, we see that the three tested subjects are Math, Science, and Reading/Writing 

tabstat tested if level=="High", by (subject) //b. The answer is 0.4423495. We can see that the values for tested are zero for all subjects that aren't the three tested subjects.  

tabstat gpa //c. The answer is 3.60144. We only have GPA mean values for our schools. But, by taking every student's GPA value to be the overall mean GPA of their school, we can still find the average GPA for all students in the district. 

tabstat attendance, by(school) //d. Answers: Joseph Darby Middle School = 177.4408, Mahatma Ghandi Middle School = 177.3344, Malala Yousafzai Middle School = 177.5478

//Question 2

clear 
use q2_village_pixel.dta 

generate pixel_consistent=. 
sort pixel

egen mean_payout = mean(payout), by(pixel) //each entry gets the mean payout value for its pixel group

replace pixel_consistent=1 if mean_payout==1 | mean_payout==0 //mean will be 0 OR 1 for all consistent pixel groups
replace pixel_consistent=0 if mean_payout!=1 & mean_payout!=0 //mean will not be 0 AND will not be 1 only if there is variation in payout within pixel group. No such pixels. 
//All values of pixel_consistent are 1 because all payout schemes are consistent within a specifc pixel. All mean payout values are 0 or 1 which verifies this! 

//part a done above

generate pixel_village=. 
sort village 

destring pixel, generate(pixel_num) ignore("KE"[,ignoreopts]) //converting pixel to an integer 

replace pixel_village=0

egen mode_pixel = mode(pixel_num), by(village) //assigning each hhid the mode pixel value of all the households in its village 

generate outlier=0
replace outlier = 1 if mode_pixel==. //these are missing mode values as there are multiple modes
replace outlier = 1 if mode_pixel!=pixel_num //these are households outside the main village pixel 

egen mean_outlier = mean(outlier), by(village) //this helps identify all households in villages that are spread across more than one pixel 

replace pixel_village = 1 if mean_outlier!=0 //identifies all households that are in a village that spans more than one pizel 

//part b done above

generate category=. 

egen mean_villagepayout = mean(payout), by(village) //mean payout now done by village instead of pixel. All villages with intra-consistent payout schemes will have values of zero or one. 

replace category = 1 if mean_outlier==0 //all households in village are in same pixel 
replace category = 2 if mean_outlier!=0 & (mean_villagepayout==0 | mean_villagepayout==1) //households that are in villages that span more than one pixel but have intra-consistent payout within village
replace category = 3 if mean_outlier!=0 & mean_villagepayout!=0 & mean_villagepayout!=1 // codebook category shows us that our category variable is mutually exclusive and exhaustive! 

list hhid if category==2 //displaying all category 2 household IDs

//part c done above 

// Question 3

clear
use q3_proposal_review.dta 

rename Rewiewer1 Reviewer1 //fixing typo
rename Review1Score Reviewer1Score //fixing typo

foreach x in ahs103 am3944 ass95 ato12 bp557 fg443 ft227 glp38 mp1792 nbs56 nd549 oo140 sa1600 scb136 yc577 ynd3 {
	gen `x'_score = Reviewer1Score if Reviewer1 =="`x'"
	replace `x'_score = Reviewer2Score if Reviewer2 =="`x'"
	replace `x'_score = Reviewer3Score if Reviewer3 =="`x'"
	egen mean_`x' = mean(`x'_score)
	egen sd_`x' = sd(`x'_score)
}
 //Above loop generates a separate variable for each reviewer's mean and standard deviation

gen stand_r1_score=., af(Reviewer1Score)
gen stand_r2_score=., af(Reviewer2Score)
gen stand_r3_score=., af(Reviewer3Score)
// Now generating standardized score AFTER non-standardized score by using it in calculations and applying giving formula


foreach x in ahs103 am3944 ass95 ato12 bp557 fg443 ft227 glp38 mp1792 nbs56 nd549 oo140 sa1600 scb136 yc577 ynd3 {
	replace stand_r1_score = (Reviewer1Score - mean_`x')/sd_`x' if Reviewer1=="`x'"
	replace stand_r2_score = (Reviewer2Score - mean_`x')/sd_`x' if Reviewer2=="`x'"
	replace stand_r3_score = (Reviewer3Score - mean_`x')/sd_`x' if Reviewer3=="`x'"
}
//part 1 done above 

gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score)/3, af(AverageScore)
// storing the average for each review score after individual scores are calculated 

//part 2 done above 


gsort -average_stand_score //sorting in DESCENDING order 
gen rank=_n, af(average_stand_score) //ranking the proposals using the descending order sort 

//part 3 done above 


// Question 4 

clear
global excel_t21 "q4_Pakistan_district_table21.xlsx"

tempfile table21 // creating empty tempfile 
save `table21', replace emptyok //to make sure empty strings don't give errors 

//we will be importing the data by running a loop that imports all 135 excel sheets one by one. Couldn't think of anything more efficient! 
forvalues i=1/135 { 
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //importing and making sure we clear the first row since we are importing from excel 
	display as error `i' //this displays the loop number 
	keep if regexm(TABLE21PAKISTANICITIZEN, "18 AND") == 1 //this keeps only the rows that have "18 AND". regexm is allowing us to keep only the rows we want by hunting for a particular text. 

	keep in 1 //we want the first out of three as second/third are urban/rural
	
	foreach var of varlist * {
		//we are now looping through every variable in the data set within the initial loop 
		quietly count if !missing(`var') //Counts missing rows without printing
		
		if r(N) == 1 {
			//this if condition is only entered if variable is empty
			di "Dropping variable `var' as it is empty" //print message
			//drop `var' //drops the variable
		}
	}
	
	capture rename * var#, addnumber //this line of code allows us to rename every variable WITH a number, in order, so that we can append smoothly 
	rename var1 table21 
	
	replace table21 = "18 AND ABOVE" if regexm(table21, "18 AND") | regexm(table21, "OVERALL") //we are correcting for any naming differences 
	
	gen table = `i' //this allows us to not lose track of our import sheet 
	append using `table21'
	save `table21', replace //saving tempfile as it was only temporarily saved before this 
} //end of initial loop

use `table21', clear //loading the data 

capture format var %40s //fixing to ideal column width 

rename var2 all_totalpop
rename var3 all_CNI
rename var4 all_noCNI
rename var5 m_totalpop
rename var6 m_CNI
rename var7 m_noCNI
rename var8 f_totalpop
rename var9 f_CNI
rename var10 f_noCNI
rename var11 trans_totalpop
rename var12 trans_CNI
rename var13 trans_noCNI

//renaming our variables with names again since we had converted it to numbers 

save pakistan_ID_bydistrict.dta //SAVED! 


// Question 5 

clear 

import delimited "shl_ps0101114.html", delimiter("|") //importing the file. Adding a SPECIFIC character, that's nowhere else, as a delimiter so that each line of code can be separated into an independent observation 

drop if !strpos(v1, "ALBEHIJE PRIMARY SCHOOL - PS0101114") & !strpos(v1, "WASTANI WA SHULE") & !strpos(v1, "KUNDI LA SHULE : Wanafunzi chini ya 40") & !strpos(v1, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI: 22 kati ya 46") & !strpos(v1, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA  : 74 kati ya 290") & !strpos(v1, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA : 545 kati ya 5664") & !strpos(v1, "WALIOFANYA MTIHANI : 16") //identifying the rows with data 

sxpose2, clear //turning observations in v1 to VARIABLES. Very important step! 

rename _var1 school
split school, parse("-") gen(part) //splitting the observation using the hyphen
rename part1 school_n
rename part2 school_id
order school_n school_id, before(school)
replace school_n = "ALBEHIJE PRIMARY SCHOOL"
drop school
//we now have school name and school ID SEPARATELY 

rename _var2 test_takers
label variable test_takers "Number of Test Takers"
destring test_takers, replace ignore("WALIOFANYA MTIHANI : ") //we are destringing test takers by ignoring the part of the string we don't need 

rename _var3 average_grade
label variable average_grade "Average Grade"
destring average_grade, replace ignore("WASTANI WA SHULE  :") //same as above 

rename _var4 group
label variable group "1 = Under 40 | 2 = Above 40"
destring group, replace ignore("KUNDI LA SHULE : Wanafunzi chini ya ") //same as above once again 
recode group (40=1) //changing value 

rename _var5 council
label variable council "Council Rank (out of 46)"
destring council, replace ignore("NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI: " " kati ya 46") 

rename _var6 regional 
label variable regional "Regional Rank (out of 290)"
destring regional, replace ignore("NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA  : " "kati ya 290")

rename _var7 national
label variable national "National Rank (out of 5664)"
destring national, replace ignore("NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA : " "kati ya 5664")
recode national (.=545) //changing value 

//END OF ASSIGNMENT. Bonus question not done as I unfortunately ran out of time!



