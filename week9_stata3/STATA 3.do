*************************
*STATA 3				|
*Warren Burroughs   	|
*Experimental Design    |
*	and Implementation  |
*************************
clear


*Your working directory here:
global wd "C:\Users\warre\OneDrive\Desktop\Georgetown\SecondSemester\Experimental_Design\Assignments\assignments_stata_3"
cd $wd



**Part 1)
*1.1, 1.2:
//Set seed and observations
set seed 344
set obs 10000

//Develop a data generating process
gen x = rnormal(100,1) // First value: mean ; Second value: st dev
gen error = rnormal(0,1) // Our error term
gen y = 1 + 2*x + error // Our outcome

save part1.dta


**1.3:
//A program that:
*a) loads data
*b) randomly samples
*c) regresses y on x
*d) Returns N, beta, SEM, p-value, and confidence intervals
capture program drop q1
program define q1, rclass
	syntax, sample_size(integer)
	
	//a)
	clear
	use part1.dta
	
	//b)
	gen random_num = runiform()
	sort random
	keep if _n<=`sample_size'
	
	//c)
	reg y x
	
	//d)
	return scalar N = e(N)
	
	matrix results = r(table) // Store a matrix called results that is the regression output
	return scalar beta = results[1,1]
	return scalar SEM = results[2,1]
	return scalar pvalue = results[4,1]
	return scalar ll = results[5,1]
	return scalar ul = results[6,1]
	
end

simulate N = r(N) beta = r(beta) SEM = r(SEM) pvalue = r(pvalue) ll = r(ll) ul = r(ul), reps(100): q1, sample_size(10)


**1.4
*Run a loop that:
//Has different sample sizes: 10, 100, 1,000, 10,000
//Appends each loop into one dataset
clear
tempfile part1_4
save `part1_4', emptyok
foreach n of numlist 10000 1000 100 10 {
	//Loop is in descencding order so the final datafile's observations are in ascending order according to sample size
	
	clear
	set seed 1000
	
	simulate N = r(N) beta = r(beta) SEM = r(SEM) pvalue = r(pvalue) ll = r(ll) ul = r(ul), reps(500): q1, sample_size(`n')
	
	
	append using `part1_4'
	save `"`part1_4'"', replace
}
//For a sample size of 10,000, all observations are the same because we set our population to 10,000

save part1_4.dta

*1.5 
*Create a figure and a table 

dtable beta SEM pvalue ll ul, by(N, nototals) nosample export(table1.md)
/*
-----------------------------------------------------------------
                                    r(N)                         
                10           100           1000         10000    
-----------------------------------------------------------------
r(beta)   1.998 (0.370) 2.004 (0.102) 2.009 (0.030) 2.008 (0.000)
r(SEM)    0.343 (0.143) 0.099 (0.010) 0.031 (0.001) 0.010 (0.000)
r(pvalue) 0.004 (0.018) 0.000 (0.000) 0.000 (0.000) 0.000 (0.000)
r(ll)     1.206 (0.482) 1.808 (0.105) 1.948 (0.030) 1.989 (0.000)
r(ul)     2.790 (0.508) 2.201 (0.102) 2.070 (0.030) 2.028 (0.000)
-----------------------------------------------------------------

*/


histogram beta, freq by(N)
histogram SEM, freq by(N)
histogram ll, freq by(N)
histogram ul, freq by(N)
******README*****************


*Part 2:
*2.1
*Program that does a data generating process, regresses y on x, and returns scalars
capture program drop p2
program define p2, rclass
	syntax, sample_size(integer)
	
	//Randomly generates a dataset
	clear
	set obs `sample_size'
	gen x = rnormal(100,1)
	gen error = rnormal(0,1)
	gen y = 1 + 2*x + error
	
	//Regression
	reg y x
	
	//Return scalars
	return scalar N = e(N)
	
	matrix results = r(table)
	return scalar beta = results[1,1]
	return scalar SEM = results[2,1]
	return scalar pvalue = results[4,1]
	return scalar ll = results[5,1]
	return scalar ul = results[6,1]
	
end

*2.2
clear
tempfile part2_2
save `part2_2', emptyok
//Create a while loop that continues until we reach a sample size of the 20th power of 2
local i = 2
while `i' <= 1048576{
	clear
	set seed 1000
	
	simulate N = r(N) beta = r(beta) SEM = r(SEM) pvalue = r(pvalue) ll = r(ll) ul = r(ul), reps(500): p2, sample_size(`i')
	
	
	append using `part2_2'
	save `"`part2_2'"', replace
	
	local i = `i' * 2
}
//Find sample sizes of multiples of 10
foreach n of numlist 10000 1000 100 10 {
	
	clear
	set seed 1000
	
	simulate N = r(N) beta = r(beta) SEM = r(SEM) pvalue = r(pvalue) ll = r(ll) ul = r(ul), reps(500): p2, sample_size(`n')
	
	
	append using `part2_2'
	save `"`part2_2'"', replace
}
sort N

save part2_2.dta

tabstat beta SEM pvalue ll ul, by(N) stat(mean) format(%9.4f) 

gen lnN = log(N)

scatter beta lnN
scatter SEM lnN
scatter ll lnN
scatter ul lnN
****************README*****************



*Part 3
*3.1 
clear
set obs 100000
gen y_pre = rnormal(0,1) // DGP

*3.2
gen treatment_effect = 0.2 * runiform() // Average treatment effect is 0.1, uniformly distributed between 0.0 and 0.2. 

*3.3
//Half of population in control, half are in treatment
gen rand = runiform(0,1)
gen treatment_indicator = 0
sort rand
replace treatment_indicator = 1 if _n <= _N/2

// Effect of being treated v. not treated
gen y_post = y_pre // not treated (no difference between y_pre and y_post)
replace y_post = y_pre + treatment_effect if treatment_indicator == 1 // treated

//What's the mean and sd of the non-treated group?
sum y_post if treatment_indicator == 0
scalar m1 = r(mean)
scalar sd1 = r(sd)
//What's the mean and sd of the treated group?
sum y_post if treatment_indicator == 1
scalar m2 = r(mean)
scalar sd2 = r(sd)

//Power calculation to detect 0.1 sd treatement effect at 80% power
power twomeans `=scalar(m1)' `=scalar(m2)', sd1(`=scalar(sd1)') sd2(`=scalar(sd2)') power(.8) 

**ANSWER: 3854 people needed to get a power of 80%

*3.4
clear
set obs 100000
gen y_pre = rnormal(0,1) // DGP

gen treatment_effect = 0.2 * runiform() // Average treatment effect is 0.1, uniformly distributed between 0.0 and 0.2

//Half of population in control, half are in treatment
gen rand = runiform(0,1)
gen treatment_indicator = 0
sort rand
replace treatment_indicator = 1 if _n <= _N/2

//15% attrition rate
gen rand2 = runiform(0,1)
sort rand2
gen attrite = 0
replace attrite = 1 if _n <= _N * .15

**NOTE: We are defining attrtion as people leaving the experiment after we randomized the treatment. We know if they are in the control or treatment group, but we don't know how the treatment affected them.

// Effect of being treated v. not treated
gen y_post = y_pre // not treated (no difference between y_pre and y_post)
replace y_post = y_pre + treatment_effect if treatment_indicator == 1 & attrite != 1 // treated and didn't attrite

//What's the mean and sd of the non-treated group?
sum y_post if treatment_indicator == 0 & attrite != 1
scalar m1 = r(mean)
scalar sd1 = r(sd)
//What's the mean and sd of the treated group?
sum y_post if treatment_indicator == 1 & attrite != 1
scalar m2 = r(mean)
scalar sd2 = r(sd)

//Power calculation to detect 0.1 sd treatement effect at 80% power with attrition
power twomeans `=scalar(m1)' `=scalar(m2)', sd1(`=scalar(sd1)') sd2(`=scalar(sd2)') power(.8) 

**ANSWER: 3,104 people are needed to get a power of 80%. The number of people at the end of the experiment (after attrition) is smaller than if there was no attrition since there are fewer people total in the sample after attrition.

*3.5 Can only afford 30%
clear
set seed 500023
set obs 100000
gen y_pre = rnormal(0,1)

gen treatment_effect = 0.2 * runiform() 

gen rand = runiform(0,1)
gen treatment_indicator = 0
sort rand
replace treatment_indicator = 1 if _n <= _N * .3 // Can only afford 30%

gen rand2 = runiform(0,1)
gen attrite = 0
replace attrite = 1 if _n <= _N * .15

gen y_post = y_pre
replace y_post = y_pre + treatment_effect if treatment_indicator == 1 & attrite != 1

sum y_post if treatment_indicator == 0 & attrite != 1
scalar m1 = r(mean)
scalar sd1 = r(sd)
sum y_post if treatment_indicator == 1 & attrite != 1
scalar m2 = r(mean)
scalar sd2 = r(sd)
power twomeans `=scalar(m1)' `=scalar(m2)', sd1(`=scalar(sd1)') sd2(`=scalar(sd2)') power(.8) 

**ANSWER: We need 3,592 people after attrition is factored in to reach a power of 80% if 30% of the sample receives the treatment. This is larger than the answer to the previous question. 

*4.1, 4.2, 4.3, 4.4
capture program drop math_test
program define math_test, rclass
	syntax, school_num(integer) student_num(integer)
	
	clear
	set obs `school_num' 
	set seed 573
	gen y = rnormal(75, 7) //randomly choosing 75 as mean and 7 as sd for score 

	gen school_id = _n
	gen students_per_school = `student_num'
	expand students_per_school // Make it so each student has their own observation
	by school_id, sort: gen student_id = _n

	local rho = 0.3 // rho is defined in question as 0.3
	local sd_u = sqrt(`rho') // Since u is given as a variance, and we care about sd
	local sd_e = sqrt(1-`rho')

	by school_id (student_id), sort: gen u = rnormal(0, `sd_u') if _n == 1 // School effect
	by school_id (student_id): replace u = u[1]
	gen e = rnormal(0,`sd_e') // Student effect
	gen total_effect = u + e

	//mixed total_effect || school_id:
	//estat icc
	
	gen treatment_indicator = 0
	bysort school_id: replace treatment_indicator = 1 if mod(school_id, 2) == 1 // Odd numbered schools are treated

	gen treatment_effect = ((0.25 - 0.15) * runiform() + 0.15) * 7 //Treatment effect is 0.2 sd and is uniformly distributed between 0.15 sd and 0.25 sd. Multiplied by 7 because originally standard deviation was 7
	
	gen y_pre = y + total_effect // Test scores are normally distributed then impacted by school and student effects
	
	gen y_post = y_pre // y_post = y_pre if not treated
	replace y_post = y_pre + treatment_effect if treatment_indicator == 1 // If treated, receive treatment effect

	//What's the mean and sd of the non-treated group?
	sum y_post if treatment_indicator == 0
	return scalar mean1 = r(mean)
	return scalar std1 = r(sd)
	//What's the mean and sd of the treated group?
	sum y_post if treatment_indicator == 1 
	return scalar mean2 = r(mean)
	return scalar std2 = r(sd)
	
end


*4.5
clear
tempfile part4_5
save `part4_5', emptyok
//Create a while loop that continues until we reach a sample size of the 10th power of 2
local i = 2
while `i' <= 1024{
	clear
	
	set seed 573
	
	simulate mean1 = r(mean1) mean2 = r(mean2) std1 = r(std1) std2 = r(std2), reps(1): math_test, school_num(200) student_num(`i')
	
	scalar define m1_s = mean1
	scalar define m2_s = mean2
	scalar define sd1_s = std1 
	scalar define sd2_s = std2


	capture power twomeans `=scalar(m1_s)' `=scalar(m2_s)', sd1(`=scalar(sd1_s)') sd2(`=scalar(sd2_s)') n(`i')

	gen power = r(power)
	gen cluster_size = `i'
	
	append using `part4_5'
	save `"`part4_5'"', replace
	
	local i = `i' * 2
}

*We would recommend a higher cluster size as power increases meaningfully as cluster size increases. A sample size of 1024 results in a power of 0.871.


*4.6
simulate mean1 = r(mean1) mean2 = r(mean2) std1 = r(std1) std2 = r(std2), reps(1): math_test, school_num(200) student_num(15)

scalar define m1_s = mean1
scalar define m2_s = mean2
scalar define sd1_s = std1 
scalar define sd2_s = std2

power twomeans `=scalar(m1_s)' `=scalar(m2_s)', cluster sd1(`=scalar(sd1_s)') sd2(`=scalar(sd2_s)') m1(15)

// We need 219 schools in our RCT to get 80% power.
// Note for reader: I am using scalar's here, however I am not sure if locals are more optimal. For the sake of practicing the material given in class, I decided to opt for scalars.


*4.7
capture program drop math_test_2
program define math_test_2, rclass
	syntax, school_num(integer) student_num(integer)
	
	clear
	set obs `school_num' 
	set seed 573
	gen y = rnormal(75, 7) //randomly choosing 75 as mean and 7 as sd for score 

	gen school_id = _n
	gen students_per_school = `student_num'
	expand students_per_school // Make it so each student has their own observation
	by school_id, sort: gen student_id = _n

	local rho = 0.3 // rho is defined in question as 0.3
	local sd_u = sqrt(`rho') // Since u is given as a variance, and we care about sd
	local sd_e = sqrt(1-`rho')

	by school_id (student_id), sort: gen u = rnormal(0, `sd_u') if _n == 1 // School effect
	by school_id (student_id): replace u = u[1]
	gen e = rnormal(0,`sd_e') // Student effect
	gen total_effect = u + e

	//mixed total_effect || school_id:
	//estat icc
	
	gen treatment_indicator = 0
	bysort school_id: replace treatment_indicator = 1 if mod(school_id, 2) == 1 // Odd numbered schools are treated
	bysort school_id: replace treatment_indicator = 0 if treatment_indicator == 1 & _n <= .3*_N //ONLY 70% ADOPT TREATMENT

	gen treatment_effect = ((0.25 - 0.15) * runiform() + 0.15) * 7 //Treatment effect is 0.2 sd and is uniformly distributed between 0.15 sd and 0.25 sd. Multiplied by 7 because originally standard deviation was 7
	
	gen y_pre = y + total_effect // Test scores are normally distributed then impacted by school and student effects
	
	gen y_post = y_pre // y_post = y_pre if not treated
	replace y_post = y_pre + treatment_effect if treatment_indicator == 1 // If treated, receive treatment effect

	//What's the mean and sd of the non-treated group?
	sum y_post if treatment_indicator == 0
	return scalar mean11 = r(mean)
	return scalar std11 = r(sd)
	//What's the mean and sd of the treated group?
	sum y_post if treatment_indicator == 1 
	return scalar mean22 = r(mean)
	return scalar std22 = r(sd)
	
end

simulate mean1 = r(mean11) mean2 = r(mean22) std1 = r(std11) std2 = r(std22), reps(1): math_test_2, school_num(200) student_num(15)

scalar define m1_s = mean1
scalar define m2_s = mean2
scalar define sd1_s = std1 
scalar define sd2_s = std2

power twomeans `=scalar(m1_s)' `=scalar(m2_s)', cluster sd1(`=scalar(sd1_s)') sd2(`=scalar(sd2_s)') m1(15)

// We need 227 schools if only 70% of the schools actually adopt the treatment. 










	










