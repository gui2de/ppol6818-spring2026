

***************************************
*QUESTION 1*
clear all
cd "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\Assignment 3\assignment_ Stata 1\q1_data"

rename primary_teacher teacher
merge m:1 teacher using teacher.dta
save stdtea_merge.dta, replace
drop _merge

merge m:1 school using school.dta
drop _merge
save stdteaschool_merge.dta, replace

merge m:1 subject using subject.dta
br
drop _merge
save finalmerged.dta, replace

***Question 1(a)***
describe
tab loc 
summarize attendance if loc=="South"

/*
 su attendance if loc=="South"

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180

Thus, the average student attendance this year in the Southern schools is 177.48 days
*/


***Question 1(b)***
tab tested if level=="High" 

/*
. tab tested if level=="High" 

     tested |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        769       55.77       55.77
          1 |        610       44.23      100.00
------------+-----------------------------------
      Total |      1,379      100.00

Thus, 44.23% of the High schools have a primary teacher who teaches a tested subject
*/


***Question 1(c)***
summarize gpa
/*

. summarize gpa

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334
	 
Answer: the average GPA of all students in the district is 3.601		 
*/


***Question 1(d)***
 tabstat attendance if level=="Middle", by(school) statistics(mean)
/*
 Summary for variables: attendance
Group variable: school 

          school |      Mean
-----------------+----------
Joseph Darby Mid |  177.4408
Mahatma Ghandi M |  177.3344
Malala Yousafzai |  177.5478
-----------------+----------
           Total |  177.4514
----------------------------
Answer: the average attendance by school is as follows
*/
******************************************



******************************************
*QUESTION 2*
clear all
cd "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\Assignment 3\assignment_ Stata 1"
use q2_village_pixel.dta

*Question 2(a)
*method 1:
	
bysort pixel: egen min_payout=min(payout)
bysort pixel: egen max_payout=max(payout)
gen pixel_consistent= 1 if min_payout==max_payout
label define payout 0 "Varied Payout" 1 "Same Payout"
label values pixel_c payout
tab pixel_c
	
	
/*Method 2: shortcut
bysort pixel payout: gen payout_consistent = (payout[1] == payout[_N])
list pixel payout if payout_consistent == 0
**here its saying that if max payout is equal to min payout, then 1
*/


*Question 2(b)
bysort village pixel: gen tag = _n == 1
*puts 1 on the first row of each village–pixel group
bysort village: egen n_pixels = total(tag)
*for each village, this counts how many unique pixels
gen pixel_village = 0
replace pixel_vil = 1 if n_pixels > 1
label define pixel 0 "Single Pixel" 1 "Multiple Pixel"
label values pixel_village pixel
tab pixel_vi

 
 
 *Question 2(c)
gen villagetype=.
replace villagetype=1 if pixel_v==0
replace villaget=2 if pixel_v==1 & payout_c==1
replace villaget=3 if pixel_v==1 & payout_c==0
tab villaget

list hhid village pixel if villagetype == 2


*****************************************


*****************************************
*Question 3
clear all
cd "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\Assignment 3\assignment_ Stata 1"
use q3_proposal_review.dta

rename Rewiewer1 Reviewer1
rename Review1Score ReviewerScore1
rename Reviewer2Score ReviewerScore2
rename Reviewer3Score ReviewerScore3
*this corrected the non-consistent vars

reshape long Reviewer ReviewerScore, i(proposal_id) j(rnum)
sort proposal_id rnum

*Question 3(a)
bysort Reviewer: egen meanscore = mean(ReviewerScore)
bysort Reviewer: egen sdscore = sd(ReviewerScore)

*creating standardized score per reviewer
gen standardscore = (ReviewerScore - meanscore) / sdscore

keep proposal_id PIName Department rnum standardscore Reviewer
reshape wide standardscore Reviewer, i(proposal_id) j(rnum)
rename standardscore1 stand_r1_score
rename standardscore2 stand_r2_score
rename standardscore3 stand_r3_score


*Question 3(b)
gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score) / 3


*Question 3(c)
egen rank = rank(-average_stand_score)
sort rank
order rank

