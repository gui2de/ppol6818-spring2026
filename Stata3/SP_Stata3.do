*************************
******Problem Set 3******
*****Stephanie Petrov****
*************************

cd /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata3

*****************************************************************
*********PART 1: SAMPLING NOISE IN A FIXED POPULATION************
*****************************************************************

*1. Develop some data generating process for data X's and for outcome Y. 
* X = GPA
* Y = passing a class
clear
set obs 100
gen gpa = runiform(3,4)
gen pass = 0
replace pass=1 if gpa>3.3
tab pass


*2. Write a do-file that creates a fixed population of 10,000 individual observations and generate random X's for them (use set seed to make sure it will always create the same data set). Create the Ys from the Xs with a true relationship and an error source. Save this data set in your Box folder.

clear
set seed 031826
set obs 10000
gen gpa = runiform(3, 4)
gen pass = (gpa>3.3) + rnormal(0, 0.1)
replace pass = 1 if pass >= 0.5
replace pass = 0 if pass < 0.5
save gpa_pass.dta, replace
br

*3. Write a do-file defining a program that (a) loads this data; (b) randomly samples a subset whose sample size is an argument to the program; (c) performs a regression of Y on X; and (e) returns the N, beta, SEM, p-value, and confidence intervals into r().

clear
set seed 031826
capture program drop grades
program define grades, rclass
	syntax, n(integer)
	use gpa_pass.dta, clear
	sample `n' , count
	reg pass gpa
	matrix table = r(table)
	return scalar num_gpa = e(N)
	return scalar sem_gpa = _se[gpa]
	return scalar beta_gpa = _b[gpa]
	return scalar pval_gpa = table[4, 1]
	return scalar ci_lower = table[5, 1]
	return scalar ci_higher = table[6, 1]

end

grades, n(200)
display r(num_gpa)
display r(sem_gpa)
display r(beta_gpa)
display r(pval_gpa)
display r(ci_lower)
display r(ci_higher)

*4.Using the simulate command, run your program 500 times each at sample sizes N = 10, 100, 1,000, and 10,000. Load the resulting data set of 2,000 regression results into Stata.

clear
set seed 031826

capture program drop grades
program define grades, rclass
	syntax, n(integer)
	use gpa_pass.dta, clear
	sample `n', count
	reg pass gpa
	matrix table = r(table)
	return scalar num_gpa = e(N)
	return scalar sem_gpa = _se[gpa]
	return scalar beta_gpa = _b[gpa]
	return scalar pval_gpa = table[4, 1]
	return scalar ci_lower = table[5, 1]
	return scalar ci_higher = table[6, 1]

end

foreach n in 10 100 1000 10000 {

simulate num_gpa=r(num_gpa) sem_gpa=r(sem_gpa) beta_gpa=r(beta_gpa) pval_gpa=r(pval_gpa) ci_lower=r(ci_lower) ci_higher=r(ci_higher), reps(500) seed(031826): grades, n(`n')
save part1_n`n'.dta, replace

}

//appending all the datasets to load the data into stata for all 2000 obsercations across the different sample sizes

use part1_n10000.dta, clear
append using part1_n1000
append using part1_n100
append using part1_n10
save part1_all.dta, replace
br

count //2000 results

*5. Create at least one figure and at least one table showing the variation in your beta estimates depending on the sample size, and characterize the size of the SEM and confidence intervals as N gets larger.

use part1_all.dta, clear
bysort num_gpa: tabstat beta_gpa sem_gpa ci_lower ci_higher, ///
	stat (mean sd min max) ///
	format(%9.4f)
	
//Table showing the differences in beta, confidence intervals, descriptive tatistics, and standard error with different sample sizes.

graph box sem_gpa, over(num_gpa) ///
    title("SEM by Sample Size") ///
    ytitle("Standard Error")

//Box plot showing how the standard error gets smaller as the sample size increases. 

gen ci_width = ci_higher - ci_lower
graph box ci_width, over(num_gpa) ///
    title("Confidence Interval Width by Sample Size") ///
    ytitle("CI Width")
	
//Box plots showing how the confidence interval gets smaller as the sample size increases. 

	
*As N (the sample size) increases from 10 to 10000, the beta decreases. It does not change much between the sample sizes of 100 and 10000. The standard error decreases as the sample size increases, indicating that the sample mean gets closer to the true population mean. The confidence interviews also get smaller,and closer to the true population mean, as the sample size increases.
	

*****************************************************************
*****PART 2: SAMPLING NOISE IN AN INFINITE SUPERPOPULATION******
*****************************************************************

*1.Write a do-file defining a program that: (a) randomly creates a data set whose sample size is an argument to the program following your DGP from Part 1 including a true relationship and an error source; (b) performs a regression of Y on one X; and (c) returns the N, beta, SEM, p-value, and confidence intervals into r().

clear

set seed 031826

capture program drop grades2
program define grades2, rclass
	syntax, n(integer)
	clear
	set obs `n'
	gen gpa = runiform(3,4)
	gen pass = (gpa > 3.3) + rnormal(0 ,0.1)
	replace pass = 1 if pass >= 0.5
	replace pass = 0 if pass < 0.5
	
	reg pass gpa
	matrix table = r(table)
	return scalar num_gpa = e(N)
	return scalar sem_gpa = _se[gpa]
	return scalar beta_gpa = _b[gpa]
	return scalar pval_gpa = table[4, 1]
	return scalar ci_lower = table[5, 1]
	return scalar ci_higher = table[6, 1]
	
end

grades2, n(200)
display r(num_gpa)
display r(sem_gpa)
display r(beta_gpa)
display r(pval_gpa)
display r(ci_lower)
display r(ci_higher)


*2.Using the simulate command, run your program 500 times each at sample sizes corresponding to the first twenty powers of two (ie, 4, 8, 16 ...); as well as at N = 10, 100, 1,000, 10,000, 100,000, and 1,000,000. Load the resulting data set of 13,000 regression results into Stata.

*powers of 2 = 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576

//WARNING: RUNNING THE BELOW CODE TAKES A VERY LONG TIME TO LOAD!!!

//first starting with the power of 2s

clear

capture program drop grades2
program define grades2, rclass
	syntax, n(integer)
	clear
	set obs `n'
	gen gpa = runiform(3,4)
	gen pass = (gpa > 3.3) + rnormal(0 , 0.1)
	replace pass = 1 if pass >= 0.5
	replace pass = 0 if pass < 0.5
	reg pass gpa
	matrix table = r(table)
	return scalar num_gpa = e(N)
	return scalar sem_gpa = _se[gpa]
	return scalar beta_gpa = _b[gpa]
	return scalar pval_gpa = table[4, 1]
	return scalar ci_lower = table[5, 1]
	return scalar ci_higher = table[6, 1]
	
end

grades2, n(200)
display r(num_gpa)
display r(sem_gpa)
display r(beta_gpa)
display r(pval_gpa)
display r(ci_lower)
display r(ci_higher)

forvalues i = 1/20 {
	local n= 2^`i'
	
	simulate num_gpa=r(num_gpa) sem_gpa=r(sem_gpa) beta_gpa=r(beta_gpa) /// 
	pval_gpa=r(pval_gpa) ci_lower=r(ci_lower) ci_higher=r(ci_higher), ///
	reps(500) seed(031826): grades2, n(`n')
	
	save "part2_n`n'.dta", replace
	
}


//Now for the other N's

foreach n in 10 100 1000 10000 100000 1000000 {
	
	simulate num_gpa=r(num_gpa) sem_gpa=r(sem_gpa) beta_gpa=r(beta_gpa) ///
	pval_gpa=r(pval_gpa) ci_lower=r(ci_lower) ci_higher=r(ci_higher), ///
	reps(500) seed(031826): grades2, n(`n')

	save "part2_n`n'.dta", replace
	
}


use "part2_n2", clear

forvalues i = 2/20 {
	
	local n = 2^`i'
	append using "part2_n`n'.dta"
	
}

foreach n in 10 100 1000 10000 100000 1000000 {
    append using "part2_n`n'.dta"
}

save "part2_all.dta", replace
count


*3.Create at least one figure and at least one table showing the variation in your beta estimates depending on the sample size, and characterize the size of the SEM and confidence intervals as N gets larger.

use part2_all.dta, clear

bysort num_gpa: tabstat beta_gpa sem_gpa ci_lower ci_higher, ///
	stat (mean sd min max) ///
	format(%9.4f)

bysort num_gpa: egen mean_sem    = mean(sem_gpa)
gen ci_width = ci_higher - ci_lower
bysort num_gpa: egen mean_ciwidth = mean(ci_width)

tostring num_gpa, gen(n_label)
graph box sem_gpa, over(n_label, sort(num_gpa)) ///
    title("SEM by Sample Size") ///
    ytitle("Standard Error") ///

	
graph box ci_width, over(n_label, sort(num_gpa)) ///
    title("CI Width by Sample Size") ///
    ytitle("CI Width") ///
 
	
*4. Fully describe your results in your README file, including figures and tables as appropriate.


//Similarly to part 1, as the sample size grows, the confidence interval gets narrower and clusters around the true mean. The standard error also decreases as we can visualize the true mean now with more certainty. Beta estimates will also shift as the sample size increases from 2 to 1,000,000+. We are able to draw a larger sample size than in Part 1 because in Part 1 we were working with a fixed population of 10,000 and in Part 2 we are working with an "infinite superpopulation" which is characterized by the randomly generated dataset in Question 1. 


*****************************************************************
**PART 3: POWER CALCULATIONS FOR INDIVIDUAL LEVEL RANDOMIZATION**
*****************************************************************


*1.Develop a data generating process for some Y that is normally disturbed around 0 with standard deviation of 1.

clear
set seed 031826
set obs 100000
gen outcome = rnormal(0, 1)

histogram outcome
br


*2.The average treatment effect should be 0.1 sd (with the effects being uniformly distributed between 0.0 – 0.2 sd)


clear
set obs 100000

gen treatment =runiform() > 0.5
gen outcome = rnormal(0,1) + treatment * runiform(0, 0.2)
reg outcome treatment

*3.The proportion of individuals receiving treatment should be 0.5 (i.e. half in control, and half in treatment) Calculate the number of individuals required to reach 80% power when you are trying to detect 0.1 sd treatment effect.

power twomeans 0 0.1, sd1(1) sd2(1) power(0.8) nratio(1)

//The number of individuals required to reach 80% power is 3,142.


*4.	Now assume, 15% of the sample will attrite (assume similar attrition rates in control and treatment arms.) How does this change your sample size calculations from the previous part?


display 3142/0.85 // 3696.4706
display 3697 - 3142 // 555

// You would need to increase the sample size by 555 from 3142 to 3697. 


*5.	Now assume the intervention is very expensive and we can only afford to provide this specific treatment to 30% of the sample. How would this change the sample size needed for 80% power.

power twomeans 0 0.1, sd1(1) sd2(1) power(0.8) nratio(0.3/0.7)

//The sample size needed to 80% power increases to 4428 individuals. 


*****************************************************************
******PART 4: POWER CALCULATIONS FOR CLUSTER RANDOMIZATION*******
*****************************************************************

*1. Develop data generating process for data for Y (assume math score of each individual student) in a school. We can only assign treatment at the school-level.

clear
set seed 031826

set obs 10
gen school_id = _n
gen treatment = runiform() > 0.5
gen school_effect = rnormal(0, sqrt(0.50))
expand 10
gen math_score = school_effect + rnormal(0,sqrt(0.50)) + treatment * runiform(0, 0.2)
br


*2. Your function should be able to change the number of clusters (i.e. schools) and the cluster size (i.e. number of students in each school)

//use locals to change the number of clusters (schools) and cluster size (students in each school)

clear
set seed 031826

local schools = 10 // 10 schools
local students = 100 // 100 students
local icc = 0.5 // icc of 0.5

set obs `schools'
gen school_id = _n
gen treatment = runiform() > 0.5
gen school_effect = rnormal(0, sqrt(`icc'))
expand `students'
gen math_score = school_effect + rnormal(0,sqrt(1-`icc')) + treatment * runiform(0, 0.2)
br

//to change the number of clusters and cluster size, adjust the values in the macros

*3.	Make sure the rho/icc is ~ 0.3 when generating these clusters. 

clear
set seed 031826

local schools = 10 // 10 schools
local students = 100 // 100 students
local icc = 0.3 // icc of 0.3

set obs `schools'
gen school_id = _n
gen treatment = runiform() > 0.5
gen school_effect = rnormal(0, sqrt(`icc'))
expand `students'
gen math_score = school_effect + rnormal(0,sqrt(1-`icc')) + treatment * runiform(0, 0.2)
br


*4. Divide the schools evenly between treatment and control arms. And generate a treatment effect of 0.2 sd (with the effects being uniformly distributed between 0.15 – 0.25 sd)

clear
set seed 031826

local schools = 10 // 10 schools
local students = 100 // 100 students
local icc = 0.3 // icc of 0.3

set obs `schools'
gen school_id = _n
gen treatment = (_n > `schools'/2)
gen school_effect = rnormal(0, sqrt(`icc'))
expand `students'
gen math_score = school_effect + rnormal(0,sqrt(1-`icc')) + treatment * runiform(0.15, 0.25)
br


*5.	Holding the number of clusters fixed at 200, what happens to the power when you increase the cluster size (use first 10 powers of 2) What cluster size would you recommend and why?

*First 10 powers of two = 4, 8, 16, 32, 64, 128, 256, 512, 1024, 4096

clear
set seed 031826

postfile handle cluster_size power using results, replace

forvalues i = 2/11 {
	local n= 2^`i'

local schools = 200 // 10 schools
local students = `n' // n students - sample size to the power of 2
local icc = 0.3 // icc of 0.3
local sims = 500
local reject_null = 0

forvalues s = 1/500 {

clear
set obs `schools'
gen school_id = _n
gen treatment = (_n > `schools'/2)
gen school_effect = rnormal(0, sqrt(`icc'))
expand `students'
gen math_score = school_effect + rnormal(0,sqrt(1-`icc')) + treatment * runiform(0.15, 0.25)
reg math_score treatment, cluster(school_id)

local pval = r(table)[4, 1]
if `pval' < 0.05 local reject_null = `reject_null' + 1

}

local power = `reject_null' / `sims'
post handle (`n') (`power')

///Remember power is the probability of correcting rejecting the null hypothesis

}

postclose handle 
use results, clear
list


///When you increase the cluster size to 200, power increases until it starts to plateau after 512. I recommend cluster size 512, which gives me a power of 0.778 - this is the closest to 0.80. These results are with 500 simulations. Increasing the sample size to more than 200 schools per cluster may help reach 0.80 power. 


*6. Now hold the cluster size fixed (15 students/school). How many schools do you need in your RCT to get 80% to detect 0.2 sd treatment effect.

clear
set seed 031826

postfile handle n_schools power using results2, replace

forvalues i = 1/30{
	
local schools = `i' * 10
local students = 15 
local icc = 0.3 // icc of 0.3
local sims = 500
local reject_null = 0

forvalues s = 1/`sims' {

clear
set obs `schools'
gen school_id = _n
gen treatment = (_n > floor(`schools'/2))
gen school_effect = rnormal(0, sqrt(`icc'))
expand `students'
gen math_score = school_effect + rnormal(0,sqrt(1-`icc')) + treatment * runiform(0.15, 0.25)
reg math_score treatment, cluster(school_id)

local pval = r(table)[4, 1]
if `pval' < 0.05 local reject_null = `reject_null' + 1

}

local power = `reject_null' / `sims'
post handle (`schools') (`power')

}

postclose handle 
use results2, clear
list

///You would need approximately 260 schools to get 80% power. At 260 schools, power = 0.802.

*7.	Now assume that only 70% of the schools actually adopt your treatment. How many schools do you need now to get 80% power?

//attrition


clear
set seed 031826

postfile handle n_schools power using results3, replace

forvalues i = 1/60{
	
local schools = `i' * 10
local students = 15 
local icc = 0.3 // icc of 0.3
local sims = 500
local attrition = 0.7
local reject_null = 0

forvalues s = 1/`sims' {

clear
set obs `schools'
gen school_id = _n
gen treatment = (_n > floor(`schools'/2))
gen adopt_treatment = treatment * (runiform() < `attrition')
gen school_effect = rnormal(0, sqrt(`icc'))
expand `students'
gen math_score = school_effect + rnormal(0,sqrt(1-`icc')) + adopt_treatment * runiform(0.15, 0.25)
reg math_score treatment, cluster(school_id)

local pval = r(table)[4, 1]
if `pval' < 0.05 local reject_null = `reject_null' + 1

}

local power = `reject_null' / `sims'
post handle (`schools') (`power')

}

postclose handle 
use results3, clear
list

///You would need about 560 schools to reach above 0.80 power. At 560 schools, power is 0.832. You would need approximately between 550 and 600 schools. At 550. power is 0.796.

