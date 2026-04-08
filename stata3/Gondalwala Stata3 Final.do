/*************************************************************
	
	Author: Gavin Gondalwala
	Date: 17 March 2026
	Assignment: Stata 3
		
*************************************************************/

*************************************************************

// Housekeeping:
if c(username) == "gavinaligondalwala" {
    global wd "/Users/gavinaligondalwala/Documents/Georgetown/Spring2026/ExperimentalDesign/Stata3"
}

// Replace username and path below
if c(username) == "username" { 
    global wd  "C:/Users/username/Documents/username"  
}

cd $wd

*************************************************************

*************************************************************
***** Part 1 *****
*************************************************************

*** Questions 1 & 2

clear
set seed 103

set obs 10000
gen x = runiform(1,500) // Generates random x values between 1 and 500

gen rand_u = runiform(3,24) // Generates random error values between 3 and 24

gen y = (3*x) + 24 + rand_u

order y, after(x)

save $wd/part1.dta, replace

*************************************************************

*** Question 3
clear

capture program drop experiment1
program define experiment1, rclass
	syntax, sample(integer)
	use $wd/part1.dta, clear
	bsample `sample'
	regress y x
	local df = e(df_r)
	
	return scalar N = e(N)
	return scalar beta = _b[x]
	return scalar sem = _se[x]
	return scalar p_val = 2*ttail(`df', abs(_b[x]/_se[x]))
	return scalar ci_low = _b[x] - invttail(`df', 0.025)*_se[x]
	return scalar ci_high = _b[x] + invttail(`df', 0.025)*_se[x]
	
end

*************************************************************

*** Question 4

// Original simulate code
* simulate n_val=r(N) b=r(beta) se=r(sem) ll=r(ci_low) hl=r(ci_high), reps(500) nodots: experiment1, sample(10)

// Loop

tempfile results
save `results', emptyok

foreach n in 10 100 1000 10000 {
	use $wd/part1.dta, clear
	display "SIMULATION N = `n'"
	
	simulate n_val=r(N) b=r(beta) se=r(sem) ll=r(ci_low) hl=r(ci_high), reps(500) nodots:experiment1, sample(`n')
	
	append using `results'
	save `results', replace
	
}

capture save $wd/part1_results.dta

*************************************************************

*** Question 5

graph box b, over(n_val) yline(3) ytitle("Beta Estimate") title("Variation in Beta Estimates as N Increases") // Choosing 3 as yline because my original data generating used 3 as the slope for the x-y relationship
	capture graph export $wd/q1_beta_distribution.jpg
	
graph hbox b, over(n_val) yline(3) ytitle("Beta Estimate") title("Variation in Beta Estimates as N Increases") // Choosing 3 as yline because my original data generating used 3 as the slope for the x-y relationship
	capture graph export $wd/q1_beta_distribution_hbox.jpg
	
capture dtable b, by(n_val) title(Variation in Beta Estimates as N Increases) nosample export(part1_table, as(xlsx))

// Describing SEM and Confidence Intervals
gen ci_width = hl - ll

bysort n: sum se
/* 
For n=10, se mean is .0147227
For n=100, se mean is .0042305
For n=1000, se mean is .0013222
For n=10,000, se mean is .0004179

As n increases, se gets smaller.
*/

bysort n: sum ci_width
/*
For n=10, the mean width of the confidence interval is .0679012
For n=100, the mean width of the confidence interval is .0167907
For n=1000, the mean width of the confidence interval is .0051891
For n=10,000, the mean width of the confidence interval is .0016383

Aa n increases, the width of the confidence intervals becomes narrower.

The se and confidence interval width decreasing means that the estimates are becoming more precise as n gets larger.
*/

*************************************************************


*************************************************************
***** Part 2 *****
*************************************************************


*** Question 1

clear

capture program drop experiment2
program define experiment2, rclass
	syntax, n(integer)
	clear
	set obs `n'
	gen x = runiform(1,500)
	gen rand_u = runiform(3,24)
	gen y = (3*x) + 24 + rand_u
	
	regress y x
	local df = e(df_r)
	
	return scalar N = e(N)
	return scalar beta = _b[x]
	return scalar sem = _se[x]
	return scalar p_val = 2*ttail(`df', abs(_b[x]/_se[x]))
	return scalar ci_low = _b[x] - invttail(`df', 0.025)*_se[x]
	return scalar ci_high = _b[x] + invttail(`df', 0.025)*_se[x]
	
end

*************************************************************

*** Question 2

tempfile results2
save `results2', emptyok

local powers ""
forvalues i=2/21 {
	local val = 2^`i'
	local powers `powers' `val' // Appends the current value of 2^i onto the existing list of powers
}

local sample `powers' 10 100 1000 10000 100000 1000000

foreach sample in `sample' {
	display "SIMULATION N = `sample'"
	
	simulate n_val=r(N) b=r(beta) se=r(sem) ll=r(ci_low) hl=r(ci_high), reps(500) nodots:experiment2, n(`sample')
	
	append using `results2'
	save `results2', replace
	
}

capture save $wd/part2_results.dta

*************************************************************

*** Question 3

graph hbox b, over(n_val) yline(3) ytitle("Beta Estimate") title("Variation in Beta Estimates as N Increases") aspect(.5)
	capture graph export $wd/q2_beta_distribution.jpg

capture dtable b, by(n_val) title(Variation in Beta Estimates as N Increases) nosample export(part2_table, as(xlsx))

*************************************************************


*************************************************************
***** Part 3 *****
*************************************************************


*** Question 1-3.

clear
power twomeans 0 0.1, sd1(1) sd2(1) // 0 and 0.1 reflects that the control mean is 0 and the treatment mean is 0.1, since the treatment effect is 0.1 -> 0+0.1=0.1
	// N = 3,142
	// N per group = 1,571

			*************************************************************

clear
set seed 103

// Parameters
	local samplesize = 3142
	local m1 = 0
	local m2 = 0.1
	local sd1 = 1
	local sd2 = 1
	local treat_num = `samplesize'/2

set obs `samplesize'	

gen y = rnormal(0,1) // Generating a random baseline population
gen rand = runiform()
egen rank = rank(rand)

gen treatment = 0
replace treatment = 1 if rank <= `treat_num' // Generates 50/50 split control and treatment groups, with the treatment group assigned a value of 1. 

gen effect_treatment = runiform(0,0.2) // Creates a random uniformly distributed treatment effect with a mean of 0.1.

gen outcome_treatment = 0
replace outcome_treatment = (y + effect_treatment) if treatment == 1 // Treatment group's outcome is their baseline plus their individual effect.
replace outcome_treatment = y if treatment == 0 // Control group's outcome is their baseline.

*************************************************************

*** Question 4.

gen attrition_rand = runiform()
gen stayed = 1
replace stayed = 0 if attrition_rand <= 0.15

/* In order for power to remain at 80% with 15% attrition, the sample would need to be larger. Since the final sample I need to achieve 80% power is 3,142, I would divide it by (1-.15). 3142/.85 = 3,696.47. So I would make my initial sample 3,697 to ensure there were 3,142 people remaining in the sample after attrition. */

*************************************************************

*** Question 5.

/* Only being able to afford to treat 30% of the sample means that now instead of an even 50/50 split between the control and treatment groups, the control group would have 70% of the sample and the treatment group would have 30%. */

power twomeans 0 0.1, sd1(1) sd2(1) nratio(0.428) // nratio is the ratio of treatment group to control group (30/70)=.428

/* The sample has increased to 3,745. There are 2,622 people in the control group and 1,123 in the treatment group. */

*************************************************************


*************************************************************
***** Part 4 *****
*************************************************************


*** Question 1.
clear
set seed 103

capture program drop math_data
program define math_data, rclass
	syntax, school_n(integer) student_n(integer)
	
	// Parameters
	local samplesize = `school_n'
	local m1 = 0
	local m2 = 0.2
	local sd1 = 1
	local sd2 = 1
	local treat_num = `samplesize'*0.5
	local rho = 0.3
	
	
	clear
	set obs `school_n' // Allows us to look at data for any number of schools (clusters)
	gen school_id = _n 
	gen school_effect = rnormal(0,sqrt(0.3)) // Generates an impact at the school level with a variance of 0.3
	
		// Building treatment group & treatment effect
		gen rand = runiform()
		egen rank = rank(rand)
		
		gen treatment = 0
		replace treatment = 1 if rank <= `treat_num'
		
		gen effect_treatment = runiform(0.15,0.25) if treatment == 1 // Creates an average treatment effect of 0.2 centered between 0.15 and 0.25
		replace effect_treatment = 0 if treatment == 0 // Ensures the control group receives no benefit from treatment
	
	expand `student_n' // Creating individual observations for each student. Each school will be copied student_n number of times, reflecting that each student w/i a school is affected by the same factors.
	bysort school_id: gen student_id = string(school_id) + "." + string(_n) // Generating student IDs which reference the school they come from.
		
	gen student_effect = rnormal(0,sqrt(0.7))
	
	gen test_score_z = school_effect + student_effect
	
	label var test_score_z "Math Score (Standardized) (ICC ~ 0.3)"
	
	// Adding outcome of treatment/control groups
	gen outcome_treatment = 0
	replace outcome_treatment = test_score_z if treatment == 0
	replace outcome_treatment = test_score_z + effect_treatment if treatment == 1
	
end

// Setting up locals to calculate changing powers.
		local powers ""
		forvalues i=2/11 {
			local val = 2^`i'
			local powers `powers' `val'
			
		}

		local samplesize = 200
			local m1 = 0
			local m2 = 0.2
			local sd1 = 1
			local sd2 = 1
			local treat_num = `samplesize'*0.5
			local rho = 0.3

		power twomeans `m1' `m2', cluster sd1(`sd1') sd2(`sd2') k1(`treat_num') k2(`treat_num') m1(`powers') rho(`rho')

/*
Estimated power for a two-sample means test
Cluster randomized design, z test
H0: m2 = m1  versus  Ha: m2 != m1

  +-------------------------------------------------------------------------------------------------+
  |   alpha   power      K1      K2      M1      M2   delta      m1      m2     sd1     sd2     rho |
  |-------------------------------------------------------------------------------------------------|
  |     .05   .5367     100     100       4       4      .2       0      .2       1       1      .3 |
  |     .05   .6224     100     100       8       8      .2       0      .2       1       1      .3 |
  |     .05   .6744     100     100      16      16      .2       0      .2       1       1      .3 |
  |     .05   .7029     100     100      32      32      .2       0      .2       1       1      .3 |
  |     .05   .7178     100     100      64      64      .2       0      .2       1       1      .3 |
  |     .05   .7254     100     100     128     128      .2       0      .2       1       1      .3 |
  |     .05   .7292     100     100     256     256      .2       0      .2       1       1      .3 |
  |     .05   .7311     100     100     512     512      .2       0      .2       1       1      .3 |
  |     .05   .7321     100     100   1,024   1,024      .2       0      .2       1       1      .3 |
  |     .05   .7326     100     100   2,048   2,048      .2       0      .2       1       1      .3 |
  +-------------------------------------------------------------------------------------------------+
Power increases when you increase the cluster size. I recommend a cluster size of 2,048 to get the highest power.
*/


*************************************************************

*** Question 6.

local powers ""
forvalues i=2/11 {
	local val = 2^`i'
	local powers `powers' `val'
	
}

local samplesize = 200
	local m1 = 0
	local m2 = 0.2
	local sd1 = 1
	local sd2 = 1
	local treat_num = `samplesize'*0.5
	local rho = 0.3

power twomeans `m1' `m2', cluster sd1(`sd1') sd2(`sd2') m1(15) rho(`rho')

/*
Study parameters:

        alpha =    0.0500
        power =    0.8000
        delta =    0.2000
           m1 =    0.0000
           m2 =    0.2000
          sd1 =    1.0000
          sd2 =    1.0000

Cluster design:

           M1 =        15
           M2 =        15
          rho =    0.3000

Estimated numbers of clusters and sample sizes:

           K1 =       137
           K2 =       137
           N1 =     2,055
           N2 =     2,055
*/

// I need 274 schools total to achieve 80% power if there are 15 students per school. */

*************************************************************

*** Question 7.

/* This would mean that the treatment effect I want of 0.2 is being multiplied by a rate of .70 to produce a .14 sd treatment effect. */

// This means current power for an individual study is:
power twomeans 0 0.14, sd(1) // 1,604 students in an individual study.

// To account for the "design effect" of a cluster study:
	/* 	DE = 1 + (clustersize - 1)*rho
		   = 1 + (15 - 1)*0.3			= 5.2
		   
	So, there needs to be 5.2 times more students in a cluster study.
	*/

// For the cluster study:
power twomeans 0 0.14, cluster sd1(1) sd2(1) m1(15) rho(0.3)

/* There would need to be 8,340 students split between 556 clusters to ahieve 80% power, assuming a cluster size of 15. */




	
	
	









