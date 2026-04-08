//Abhinav Dutt Exp Design STATA 3 22nd March, 2026
//Worked with Warren Burroughs

clear


//Your working directory below:
global wd "C:\Users\abhin\Downloads"
cd $wd


//Part 1
//1.1, 1.2:

set seed 344 //for consistency 
set obs 10000 //as asked in question 

//Developing a data generating process
gen x = rnormal(100,1) //Mean of 100 and SD of 1. Mean of 100 arbitrarily chosen for nice, round numbers.
gen error = rnormal(0,1) //Error term is a normal distribution with mean of 1 and SD of 1
gen y = 1 + 2*x + error //our regression equation. We chose our equation to have beta0 of 1 and beta2 of 2 but these values are arbitrary. 

save part1.dta //saving generated data set to local directory 


//1.3:
//A program that: loads data, randomly samples, regresses y on x, Returns N, beta, SEM, p-value, and confidence intervals

capture program drop q1
program define q1, rclass //including rclass as we are returning scalars
	syntax, sample_size(integer) //sample size is the input for this program 
	
	clear
	use part1.dta //using dataset we generated earlier
	
	gen random_num = runiform() 
	sort random //using random_num to sort the dataset randomly 
	keep if _n<=`sample_size' //keeping only as many entries as needed for our sample size 
	
	reg y x //regression 
	
	return scalar N = e(N) //returns sample size 
	
	matrix results = r(table) //Stores a matrix called results that is the regression output
	return scalar beta = results[1,1] //beta is in array index [1,1] of our matrix table 
	return scalar SEM = results[2,1] //SEM is in array index [1,1] of our matrix table 
	return scalar pvalue = results[4,1] //pval is in array index [1,1] of our matrix table 
	return scalar ll = results[5,1] //LL of CI is in array index [1,1] of our matrix table 
	return scalar ul = results[6,1] //UL of CI in array index [1,1] of our matrix table 
	
end

simulate N = r(N) beta = r(beta) SEM = r(SEM) pvalue = r(pvalue) ll = r(ll) ul = r(ul), reps(100): q1, sample_size(10) //simulate command with 100 repetitions 


//1.4
//Run a loop that: Has different sample sizes: 10, 100, 1,000, 10,000 and appends each loop into one dataset

clear
tempfile part1_4 //creating a tempfile
save `part1_4', emptyok //saving tempfile 
foreach n of numlist 10000 1000 100 10 { //loop for values of 10,100,1000,10000
	//The loop is in descending order so that the final dataset has observations in ascending order of sample size
	
	clear
	set seed 1000 //for consistency
	
	simulate N = r(N) beta = r(beta) SEM = r(SEM) pvalue = r(pvalue) ll = r(ll) ul = r(ul), reps(500): q1, sample_size(`n') //similiar simulate command as above, with repetitions now at 500 and sample size replaced with local n 
	
	
	append using `part1_4' //appending our dataset with values for every iteration of the loop 
	save `"`part1_4'"', replace
}
//For a sample size of 10,000, all observations are the same because we set our population to 10,000

save part1_4.dta //saving our results 

//1.5 
//Creating a figure and a table 

dtable beta SEM pvalue ll ul, by(N, nototals) nosample export(table1.md) //putting our results into a table so that we can see how our estimates vary by N 

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

//We know that the correct population values is shown in sample size equals 10,000 as that is the entire population. We see that as sample size increases, SEM and p-value descreases because our test gets more precise. Further, the confidence intervals (UL & LL) tighten around the true value as sample size increases. 

*/

//output histograms for our figures - run each line one by one to see each one! Frequency of our four estimates. Each line of code produces 4 histograms - one for each sample size! 
histogram beta, freq by(N)
histogram SEM, freq by(N)
histogram ll, freq by(N)
histogram ul, freq by(N)


******README UPLOADED******


//Part 2
//2.1 Program that has a data generating process, regresses y on x, and returns scalars
capture program drop p2
program define p2, rclass //rclass as we are returning scalars 
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
	
	//using matrix table just as before 
	matrix results = r(table)
	return scalar beta = results[1,1]
	return scalar SEM = results[2,1]
	return scalar pvalue = results[4,1]
	return scalar ll = results[5,1]
	return scalar ul = results[6,1]
	
	//same program idea as part 1 
end

//2.2
clear
tempfile part2_2
save `part2_2', emptyok
//Creating a while loop that executes until we reach a sample size of the 20th power of 2

local i = 2
while `i' <= 1048576{
	clear
	set seed 1000 //for consistency
	
	simulate N = r(N) beta = r(beta) SEM = r(SEM) pvalue = r(pvalue) ll = r(ll) ul = r(ul), reps(500): p2, sample_size(`i') //similar simulate command but the sample size is now local loop variable i 
	
	
	append using `part2_2' //appending as before 
	save `"`part2_2'"', replace
	
	local i = `i' * 2 //i multiplied by 2 for the next iteration 
}
//Running program now for first 4 powers of 10
foreach n of numlist 10000 1000 100 10 { //using for loop for 4 specified values 
	
	clear
	set seed 1000 //for consistency
	
	simulate N = r(N) beta = r(beta) SEM = r(SEM) pvalue = r(pvalue) ll = r(ll) ul = r(ul), reps(500): p2, sample_size(`n') ////similar simulate command but the sample size is now local loop variable n 
	
	append using `part2_2' //appending to same tempfile as above 
	save `"`part2_2'"', replace
}
sort N //sorting by sample size 

save part2_2.dta //saving required dataset with 13,000 observations 

tabstat beta SEM pvalue ll ul, by(N) stat(mean) format(%9.4f) //outputting required table 

gen lnN = log(N) //generating new variable for log sample size so that we can generate graphs that are visually more coherent and aesthetically more pleasing without obfuscating or altering interpretation 

//output histograms for our figures - run each line one by one to see each one! 

scatter beta lnN
scatter SEM lnN
scatter ll lnN
scatter ul lnN


******README UPLOADED******



//Part 3
//3.1 
clear
set seed 4267 //for consistency of results 
set obs 100000 
gen y_pre = rnormal(0,1) //y-values pre-treatment generated to be a normal distribution 

//3.2
gen treatment_effect = 0.2 * runiform() //Average treatment effect is 0.1, uniformly distributed between 0.0 and 0.2. Using runiform*0.2 to achieve this! 

//3.3 Half of population in control, half are in treatment
gen rand = runiform(0,1)
gen treatment_indicator = 0
sort rand //sorting our dataset by random variable so that we can randomly assign to treatment and control groups 
replace treatment_indicator = 1 if _n <= _N/2 //first half of dataset assigned to treatment after randomly sorting 


gen y_post = y_pre //Both control and treatment group get the same y_post value initally i.e. y_pre. For control group, this remains unchanged as control group requires y_post = y_pre! 
replace y_post = y_pre + treatment_effect if treatment_indicator == 1 //ONLY treatment group gets treatment effect added to y_pre for total y_post value 

//What's the mean and sd of the non-treated group?
sum y_post if treatment_indicator == 0 //using summary command to access values through r
scalar m1 = r(mean)
scalar sd1 = r(sd)
//What's the mean and sd of the treated group?
sum y_post if treatment_indicator == 1
scalar m2 = r(mean)
scalar sd2 = r(sd)

//Power calculation to detect 0.1 sd treatement effect at 80% power
power twomeans `=scalar(m1)' `=scalar(m2)', sd1(`=scalar(sd1)') sd2(`=scalar(sd2)') power(0.8) 

//ANSWER: N=2936 for our set seed 

//3.4
clear
set seed 4267 //for consistency of results 
set obs 100000
gen y_pre = rnormal(0,1) //data generating process 

gen treatment_effect = 0.2 * runiform() // Average treatment effect is 0.1, uniformly distributed between 0.0 and 0.2

//Half of population in control, half are in treatment
gen rand = runiform(0,1)
gen treatment_indicator = 0
sort rand
replace treatment_indicator = 1 if _n <= _N/2

//15% attrition rate. THIS is the part that is different from above! 
gen rand2 = runiform(0,1)
gen attrite = 0
replace attrite = 1 if rand2 <= 0.15 //dataset is assigned values from uniform distribution randomly; after this, all rand values <=0.15 are no longer in experiment to mimic attrition process and 15% attrition rate! IMPORTANT: attrition happens at a rate of 15% overall and the people attriting can be from either control or treatment group! 

//NOTE: We are defining attrtion as people leaving the experiment after we randomize into control and treatment groups. We will continue know if they were in the control or treatment group before leaving, but we won't know how the treatment affected them as they left the study!

// Effect of being treated v. not treated
gen y_post = y_pre //not treated (no difference between y_pre and y_post)
replace y_post = y_pre + treatment_effect if treatment_indicator == 1 & attrite != 1 //only those who treated and didn't attrite get the treatment effect 

//What's the mean and sd of the non-treated group?
sum y_post if treatment_indicator == 0 & attrite != 1 //using summary command to store results using r
scalar m1 = r(mean)
scalar sd1 = r(sd)
//What's the mean and sd of the treated group?
sum y_post if treatment_indicator == 1 & attrite != 1
scalar m2 = r(mean)
scalar sd2 = r(sd)

//Power calculation to detect 0.1 sd treatement effect at 80% power with attrition
power twomeans `=scalar(m1)' `=scalar(m2)', sd1(`=scalar(sd1)') sd2(`=scalar(sd2)') power(0.8) 

//ANSWER: 2964 for our set seed! NOTE how required N is higher now because of attrition! Gap is even bigger for other seed values based on testing done by me! 

//3.5 Can only afford 30%
clear
set seed 4267 //for consistency of results 
set obs 100000
gen y_pre = rnormal(0,1)

gen treatment_effect = 0.2 * runiform() 

gen rand = runiform(0,1)
gen treatment_indicator = 0
sort rand
replace treatment_indicator = 1 if _n <= _N * .3 //Everything else is same as above but now, due to financial constraints, we can only afford a treatment group size of 30% instead of 50%

gen rand2 = runiform(0,1)
gen attrite = 0
replace attrite = 1 if rand2 <= 0.15 //same as before! 

gen y_post = y_pre
replace y_post = y_pre + treatment_effect if treatment_indicator == 1 & attrite != 1 //same as before 

sum y_post if treatment_indicator == 0 & attrite != 1 //same as before 
scalar m1 = r(mean)
scalar sd1 = r(sd)
sum y_post if treatment_indicator == 1 & attrite != 1
scalar m2 = r(mean)
scalar sd2 = r(sd)
power twomeans `=scalar(m1)' `=scalar(m2)', sd1(`=scalar(sd1)') sd2(`=scalar(sd2)') power(0.8) 

//ANSWER: Required N is 3700 for our set seed! When treatment group is smaller, required N is even higher! 

//4.1, 4.2, 4.3, 4.4
capture program drop math_test
program define math_test, rclass //rclass as we are returning scalars
	syntax, school_num(integer) student_num(integer) //school_num is number of schools i.e. number of clusters and student_num is number of students per school i.e. cluster size. These are the two inputs for the program! 
	
	clear
	set obs `school_num' //setting observations from local variable for number of clusters 
	set seed 573 //for consistency of results 
	gen y = rnormal(75, 7) //randomly choosing 75 as mean and 7 as sd for test scores based on what we think could be realistic numbers 

	gen school_id = _n //assigning school id to schools based on index number
	gen students_per_school = `student_num' //assigning clutser size from local 
	expand students_per_school // Make it so each student has their own observation. Expanding our data set so that number of total obs is cluster size * number of clusters! 
	by school_id, sort: gen student_id = _n //assigning student id to students based on index number 

	local rho = 0.3 // rho is defined in question as 0.3. Rho is intra class coefficient. 
	local sd_u = sqrt(`rho') // Since u is given as a variance, and we care about sd, we are square rooting! 
	local sd_e = sqrt(1-`rho') //0.3 here can be interpreted as student's unique charcateristics having a greater effect on test scores than characteristics of school! Opposite would be true for ICC(also knows as rho)>0.5! 

	by school_id (student_id), sort: gen u = rnormal(0, `sd_u') if _n == 1 // School effect
	by school_id (student_id): replace u = u[1] //school effect is copied for all students from the first index. School effect is of course identical for all students within a specific school! 
	gen e = rnormal(0,`sd_e') //Student effect which is unique for every student!
	gen total_effect = u + e //total effect = school effect + student effect 

	
	gen treatment_indicator = 0
	bysort school_id: replace treatment_indicator = 1 if mod(school_id, 2) == 1 // Odd numbered schools are treated to ensure randomization! Mod gives remainder and remainder is 1 when you divide by 2 for odd numbers. 

	gen treatment_effect = ((0.25 - 0.15) * runiform() + 0.15) * 7 //Treatment effect is 0.2 sd and is uniformly distributed between 0.15 sd and 0.25 sd. Multiplied by 7 because originally standard deviation was chosen as 7 by us at the top! 
	
	gen y_pre = y + total_effect // Test scores are normally distributed (our original y) and then impacted by school and student effects
	
	gen y_post = y_pre // y_post = y_pre if not treated
	replace y_post = y_pre + treatment_effect if treatment_indicator == 1 // If treated, they receive treatment effect

	//What's the mean and sd of the non-treated group?
	sum y_post if treatment_indicator == 0 //using summary command once again to store values using r 
	return scalar mean1 = r(mean)
	return scalar std1 = r(sd)
	//What's the mean and sd of the treated group?
	sum y_post if treatment_indicator == 1 
	return scalar mean2 = r(mean)
	return scalar std2 = r(sd)
	
end

simulate mean1 = r(mean1) mean2 = r(mean2) std1 = r(std1) std2 = r(std2), reps(1): math_test, school_num(200) student_num(1024) //simulate command done with 200 clusters and 2^10 cluster size to store scalars 

scalar define m1_s = mean1
scalar define m2_s = mean2
scalar define sd1_s = std1 
scalar define sd2_s = std2


power twomeans `=scalar(m1_s)' `=scalar(m2_s)', cluster sd1(`=scalar(sd1_s)') sd2(`=scalar(sd2_s)') n(1024) rho(0.3) //doing power calc with cluster option


//4.5
clear
tempfile part4_5
save `part4_5', emptyok
//Creating a while loop that continues until we reach a sample size of the 10th power of 2
local i = 2 //local loop variable 
while `i' <= 1024{
	clear
	
	set seed 573 //for consistency of results 
	
	simulate mean1 = r(mean1) mean2 = r(mean2) std1 = r(std1) std2 = r(std2), reps(1): math_test, school_num(200) student_num(`i') //cluster number is 200 as before but now cluster_size is local loop variable i 
	
	scalar define m1_s = mean1
	scalar define m2_s = mean2
	scalar define sd1_s = std1 
	scalar define sd2_s = std2


	capture power twomeans `=scalar(m1_s)' `=scalar(m2_s)', sd1(`=scalar(sd1_s)') sd2(`=scalar(sd2_s)') n(`i') //same as before but n is now loop var i
	gen power = r(power)
	gen cluster_size = `i' //storing cluster_size as current loop var value i
	
	append using `part4_5' //appending to store data results 
	save `"`part4_5'"', replace
	
	local i = `i' * 2 //multiplying loop variable by 2 for next iteration 
}

//Answer: Based on our data, we would recommend a higher cluster size as power increases meaningfully as cluster size increases.


//4.6
simulate mean1 = r(mean1) mean2 = r(mean2) std1 = r(std1) std2 = r(std2), reps(1): math_test, school_num(200) student_num(15) //cluster size is now fixed at 15

scalar define m1_s = mean1
scalar define m2_s = mean2
scalar define sd1_s = std1 
scalar define sd2_s = std2

power twomeans `=scalar(m1_s)' `=scalar(m2_s)', cluster sd1(`=scalar(sd1_s)') sd2(`=scalar(sd2_s)') m1(15) //m1 is option in power command for cluster size 

// We need 219 schools in our RCT to get 80% power 


//4.7
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

	by school_id (student_id), sort: gen u = rnormal(0, `sd_u') if _n == 1
	by school_id (student_id): replace u = u[1]
	gen e = rnormal(0,`sd_e') //Everything is same as above SO FAR! 
	gen total_effect = u + e

	
	gen treatment_indicator = 0
	bysort school_id: replace treatment_indicator = 1 if mod(school_id, 2) == 1 // Odd numbered schools are treated
	bysort school_id: replace treatment_indicator = 0 if treatment_indicator == 1 & _n <= .3*_N //ONLY 70% ADOPT TREATMENT. 30% DO NOT GET THE TREATMENT EFFECT! 

	gen treatment_effect = ((0.25 - 0.15) * runiform() + 0.15) * 7 //Treatment effect is 0.2 sd and is uniformly distributed between 0.15 sd and 0.25 sd. Multiplied by 7 because originally standard deviation was 7! Same as before! 
	
	gen y_pre = y + total_effect // Test scores are normally distributed then impacted by school and student effects! Same as before! 
	
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

simulate mean1 = r(mean1) mean2 = r(mean2) std1 = r(std1) std2 = r(std2), reps(1): math_test_2, school_num(200) student_num(15) //same as before 

scalar define m1_s = mean1
scalar define m2_s = mean2
scalar define sd1_s = std1 
scalar define sd2_s = std2

power twomeans `=scalar(m1_s)' `=scalar(m2_s)', cluster sd1(`=scalar(sd1_s)') sd2(`=scalar(sd2_s)') m1(15) //Same as before 

//We need 227 schools if only 70% of the schools actually adopt the treatment. Required number of schools has gone up as expected! Number of students goes up as well of course! 










	










