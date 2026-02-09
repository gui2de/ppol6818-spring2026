*Maimoona Mohsin* 
*Experimental Design_ PS1* 
*Please see word for answers 


*Question 1 
cd "C:\Users\maimo\OneDrive\Desktop\Semester 2\Experimental Design & Implement\Stata 1 assignment"
use "teacher.dta" 
rename teacher primary_teacher
save teacher.dta, replace 
use student.dta, clear
merge m:1 primary_teacher using teacher.dta
tab _merge 
drop _merge

merge m:1 school using school.dta
tab _merge
drop _merge

merge m:1 subject using subject.dta
drop _merge

describe attendance level loc tested subject
/* Merging is done 

Part a */ 

sum attendance if loc=="South" 

/* Part b */ 

br tested 
des tested 
summarize tested if level == "High"

/*Part c */ 
sum gpa 

/*Part d */ 

 tabstat attendance if level== "Middle", by (school)
 
 /* Question 2 */
 
 * Part a 
 
 use q2_village_pixel, clear 
 describe village pixel
list pixel payout in 1/20
bysort pixel: egen payout_min = min(payout)
bysort pixel: egen payout_max = max(payout)
list pixel payout payout_min payout_max in 1/30
gen pixel_consistent = 1
replace pixel_consistent = 0 if payout_min != payout_max
tab pixel_consistent


*Part b 

bysort village pixel: gen one = 1
bysort village pixel: gen tag = _n == 1
bysort village: egen n_pixels = total(tag)


gen pixel_village = 0
replace pixel_village = 1 if n_pixels > 1
tab pixel_village

*Part c 

bysort village: egen village_payout_min = min(payout)
bysort village: egen village_payout_max = max(payout)
gen village_payout_consistent = 1
replace village_payout_consistent = 0 if village_payout_min != village_payout_max

gen village_type = .
replace village_type = 1 if pixel_village == 0

replace village_type = 2 if pixel_village == 1 & village_payout_consistent == 1
replace village_type = 3 if pixel_village == 1 & village_payout_consistent == 0
tab village_type

*Question 3 

use q3_proposal_review, clear  
*Part 1 
*Reviewer 1 steps 
bysort Rewiewer1: egen r1_mean = mean(Review1Score)
bysort Rewiewer1: egen r1_sd = sd(Review1Score)
gen stand_r1_score = (Review1Score - r1_mean) / r1_sd

summarize stand_r1_score
* Reviewer 2 
bysort Reviewer2: egen r2_mean = mean(Reviewer2Score)
bysort Reviewer2: egen r2_sd   = sd(Reviewer2Score)
gen stand_r2_score = (Reviewer2Score - r2_mean) / r2_sd

summarize stand_r2_score

*Now for Reviewer 3 
bysort Reviewer3: egen r3_mean = mean(Reviewer3Score)
bysort Reviewer3: egen r3_sd   = sd(Reviewer3Score)

gen stand_r3_score = (Reviewer3Score - r3_mean) / r3_sd

summarize stand_r3_score

*Part 2 
gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score) / 3
summarize average_stand_score

*Part 3 
* here i will use the -ve sign in front because the question says 128 is the lowest value 

egen rank = rank(-average_stand_score)
sort rank
list average_stand_score rank in 1/10
sum rank
/* 


    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
        rank |        126        63.5    36.51712          1        126
this tells the command worked */ 






















































 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


