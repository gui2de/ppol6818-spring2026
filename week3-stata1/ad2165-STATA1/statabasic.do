**** Exp Design ***
*** Assigment Basic Stata ***
*** Kenshi Kawade ***

cd "C:\Github Local\ppol6818-spring2026\week3-stata1\ad2165-STATA1" //Abhinav - changing cd to my local github folder 

//Abhinav - had to use my pre downloaded versions of the assignment data files that were unchanged from my own work for the assignment! Luckily I had them saved on my system or I would have to redownload every file from Canvas again! Would be nice to upload all pre-edited data files that are needed to run the code next time :)

** Q.1 **--------------------------------------------------------
de using student.dta

de using teacher.dta

de using school.dta

de using subject.dta

use school.dta

merge 1:m school using "teacher.dta"
drop _merge

rename teacher primary_teacher

merge 1:m primary_teacher using "student.dta"
drop _merge

* a
sum atten if loc == "South"

/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180
  
The mean student attendance for schools located in the "South" is 177.4776.
*/

* b
merge m:1 subject using "subject.dta"
drop _merge

tab tested if level == "High"

/*
     tested |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        769       55.77       55.77
          1 |        610       44.23      100.00
------------+-----------------------------------
      Total |      1,379      100.00

. sum stdnt if level == "High"

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
   stdnt_num |      1,379      2226.1    1314.547          2       4490

Among students enrolled in high school, 44.23% have a primary teacher who
teaches a tested subject
*/

* c
sum gpa

/*

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334

The mean gpa of all students in the district is 3.60144.
*/

* d. 
tabstat attend if level == "Middle", by(school)

/*
          school |      Mean
-----------------+----------
Joseph Darby Mid |  177.4408
Mahatma Ghandi M |  177.3344
Malala Yousafzai |  177.5478
-----------------+----------
           Total |  177.4514
----------------------------

The mean attendance for Joseph Darby is 177.4408.
The mean attendance for Mahatma Ghandi is 177.3344.
The mean attendance for Malala Yousafzai is 177.5478.
*/

save "q1_merged.dta", replace

//Abhinav - everything for Q1 looks great and it ran smoothly on my system with no issues. Awesome job! 

** Q.2 **--------------------------------------------------------
use q2_village_pixel.dta

* a.
bysort pixel: tab payout
gen pixel_consistant = 1

* b. 
ssc install egenmore //Abhinav - had to install this package before running rest of code! Thanks for including this in your comments!

bysort village: egen n_pixel = nvals(pixel)

gen pixel_village = 0
replace pixel_village = 1 if n_pixel > 1

* c.
gen value = 1

bysort village: egen n_payout = nvals(payout)

replace value = 2 if pixel_village == 1 & n_payout == 1
replace value = 3 if n_payout > 1

save "q2_categorized.dta", replace

//Abhinav - everything looks good to me! It all ran smoothly! For next time, I recommend including some comments in your key coding steps that explain your thought process and explaining how you intend your code to work! Had to spend some time understanding everything slowly and carefully as I didn't have your comments to guide me. For example, letting the reviewer know what nvals does with a small comment would be very nice! Great job though - code is very simple and efficient! 


** Q.3 **--------------------------------------------------------

*** Data cleaning 
use q3_proposal_review.dta, clear

rename Rewiewer1 Reviewer1
rename Review1Score Reviewer1Score

save "q3_proposal_review_clean.dta", replace

* 1. 

*** Make reviewers list from Reviewer1
gen reviewers = Reviewer1
duplicates drop reviewers, force
keep reviewers

save "q3_reviewers.dta", replace

*** Make 3 different datasets with 2 vars (reviewers and each score) for each reviewer position
foreach v in 1 2 3 {
	use q3_proposal_review_clean.dta, clear
	keep Reviewer`v' Reviewer`v'Score
	rename Reviewer`v' reviewers
	rename Reviewer`v' score
	tempfile eachr`v'score
	save `eachr`v'score'
	use q3_reviewers.dta, clear
	merge m:m reviewers using `eachr`v'score'
	drop _merge
	save "q3_reviewers`v'.dta", replace
} 

*** Make a long form dataset with 2 vars (reviewers and each score, 16x24 = 384rows)
use q3_reviewers1.dta, clear
append using q3_reviewers2.dta
append using q3_reviewers3.dta 
drop if missing(score)

*** Calculate each reviewer's mean and sd score using the long form dataset with 2 vars
bysort reviewers: egen rmean = mean(score)
bysort reviewers: egen rsd = sd(score)
drop score
duplicates drop reviewers, force
save "q3_reviewers.dta", replace

*** Calculate standarized score
use q3_proposal_review_clean.dta, clear
foreach v in 1 2 3 {
	rename Reviewer`v' reviewers
	merge m:1 reviewers using "q3_reviewers.dta"
	drop _merge
	rename rmean rmean`v'
	rename rsd rsd`v'
	gen stand_r`v'_score = (Reviewer`v'Score - rmean`v')/rsd`v'
	rename reviewers Reviewer`v'
}


* 2.
gen average_stand_score = (stand_r1 + stand_r2 + stand_r3) / 3
drop if average == .

* 3. 
gsort -average_stand_score
gen rank = _n

*** playing ***
order average_stand_score, a(Average)
gsort -Average
gen rank_biased = _n

save "q3_proposal_review_ranked.dta", replace
//Abhinav - great job! Everything ran smoothly! Comments were VERY helpful for this one! Very clean!

** Q.4 **--------------------------------------------------------

//Abhinav - removing this as I don't need it! global wd "~/GU_Class/ExpDes/data"

global excel_t21 "q4_Pakistan_district_table21.xlsx" //Abhinav - removed the $wd here for my sake so that I can run it!

clear

*** setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

ssc install missings //Abhinav - had to install this! Thanks! 

forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow allstring clear //import
	display as error `i' //display the loop number
	rename TABLE21PAKISTANICITIZEN table21
	keep if regexm(table21, "18 AND" ) == 1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	gen table=`i' //to keep track of the sheet we imported the data from
	
	
	missings dropvars, force // ssc install missings //drop empty vars
	
	describe
	gen var_num = r(k)
	
	*rename each vars for appending
	forvalues c=2/13 {
		if var_num == 14 {
			ds
			local v`c': word `c' of `r(varlist)'
			rename `v`c'' col`c'
		}
		else if var_num == 13 {
			tempvar var13
			gen `var13' = "", b(table)
			ds
			local v`c': word `c' of `r(varlist)'
			rename `v`c'' col`c'
		}
		else {
			tempvar var12
			gen `var12' = "", b(table)
			tempvar var13
			gen `var13' = "", b(table)
			ds
			local v`c': word `c' of `r(varlist)'
			rename `v`c'' col`c'
		}
	}
	*after running loops above, there are some table having var_num = 13, missing the var for the last column in the table

	append using `table21'
	drop var_num
	save `table21',replace 	//saving the tempfile so that we don't lose any data
	
}

*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %20s table21 col2-col13

save "q4_Pakistan_district_table21_imported.dta", replace

//Abhinav - everything ran smoothly! Great job! Output looked good! It took a while to finish running of course but it was all functioning! There were some red numbers in the middle of the displayed output, at periodic intervals, such as 128 and then later on 132 and then later on 135, and I don't know why that happened. The code ran to completion though and everything looked good! Great job, Kenshi! Please see me in person and explain the code to me so I can understand this better myself! :)

** Q.5 **--------------------------------------------------------


tempfile psle21
save `psle21', replace emptyok

//Abhinav - not sure whether I should run the following loop or not because it is in comments and you mention misunderstanding the instructions! Unsure how to proceed!

/* this loop takes 10 mins, even though I misunderstood the instruction that we needed to extract test results data from all school.

forvalues y = 1/7 {
	forvalues x = `y'000/`y'200  {
		display as error `x' //display the loop number
	* see if the website exists
		capture import delimited		"https://maktaba.tetea.org/exam-results/PSLE2021/shl_ps010`x'.htm", clear
	
	* if it exists, run this loop
		if _rc == 0 {
		
			drop v2
			keep if _n == 17 | inrange(_n, 20, 30)
			sxpose2, clear // ssc install sxpose2

			foreach v of varlist _all{
			
				if regexm(`v', "br") == 1 {
					drop `v'
				}
			
			}
		
			
			append using `psle21'
			save `psle21', replace
		
		}
		else {
			continue
		}
	}


}
*/

save "q5_imported.dta", replace

use q5_imported, clear //Abhinav - I ended up not running the following code as I was unsure which parts of your loop above were correct/intended and which weren't.

rename _var2 students
label variable students "Number of students who took the test"
destring students, replace ignore("WALIOFANYA MTIHANI:")

rename _var4 avgscore
label variable avgscore "School average score"
destring avg, replace ignore("WASTANI WA SHULE: ")

rename _var6 gr
gen byte group = 0 if gr != "KUNDI LA SHULE : Wanafunzi chini ya 40", a(avg)
replace group = 1 if group == .
drop gr
label variable group "Student group (binary indicator: under 40 (0) vs 40 or above (1))"

rename _var8 counrank
label variable counrank "School ranking within the council (for example, 22 out of 46)"
replace counrank = subinstr(counrank, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI: ", "", .)
replace counrank = subinstr(counrank, "kati ya", "out of", .)

rename _var10 regrank
label variable regrank "School ranking within the region (for example, 74 out of 290)"
replace regrank = subinstr(regrank, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA  : ", "", .)
replace regrank = subinstr(regrank, "kati ya", "out of", .)

rename _var12 natrank
label variable natrank "School ranking at the national level (for example, 545 out of 5,664)"
replace natrank = subinstr(natrank, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA : ", "", .)
replace natrank = subinstr(natrank, "kati ya", "out of", .)

format %20s counrank regrank natrank 

rename _var1 school
replace school = subinstr(school, "<H3><P ALIGN=", "", .)
replace school = subinstr(school, `""LEFT"  >"', "", .)

split school, parse("-") gen(part)
rename part1 school_name
rename part2 school_id
order school_name school_id, b(student)
drop school
drop part3

save "q5_imported.dta", replace

keep if regexm(school_name, "ALBEHIJE") == 1 // <- This gives what i need for question 5

//Abhinav - as mentioned above, I didn't run the code for this question but I looked through your formatting code carefully and it all looked clean and appropriate to me! 

** Bonus **--------------------------------------------------------
/* Couldn't figure out

//Abhinav - I have no idea how to do this either haha! Wish I could be of more help! Great job on this assignment overall! I needed to make ZERO unintended changes to run your code for questions 1-4 and that should make you feel VERY proud of your work! 

capture import delimited		"https://maktaba.tetea.org/exam-results/PSLE2021/shl_ps0101114.htm", clear

drop v2
keep in 116/l
sxpose2, clear

drop _var161


forvalues i = 1/10{
		rename _var`i' row1_`i'
}

forvalues i = 1/10 {
forvalues v = 11/159{
	{
		forvalues x = 2/15{
			rename _var`v' row`x'_`i'
		}
	}
}

		ds
		local v`c': word `c' of `r(varlist)'
		rename `v`c'' col`c'_0
} 
				
				
				
forvalues i = 1/16 {
	
}
*/
