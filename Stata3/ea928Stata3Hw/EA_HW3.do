********************************************************************************
** 	TITLE	: Assignment_03_EA.do
**	PURPOSE	: Work for assignment two 
**  PROJECT	: gui2de research and fieldwork analysis course 
**	AUTHOR	: Emilia Antunez
**	DATE	: March 22 2026
********************************************************************************
























*------------------------------------------------------------------------------*
**# WORKING DIRECTORY  
*------------------------------------------------------------------------------*

if c(username) == "PJ" { 
	global wd "/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Stata3HW"
}
else if c(username) == ""{ //People are going to put their name and their filepath here so that it runs in their machine
	global wd ""
}
else {
	display as error //"Define user specific file path"
}


// Set working directory dynamically
cd "$wd"












*------------------------------------------------------------------------------*
**# QUESTION 1 HW3
*------------------------------------------------------------------------------*

/*Part 1: Sampling noise in a fixed population
1.	Develop some data generating process for data X's and for outcome Y.
2.	Write a do-file that creates a fixed population of 10,000 individual observations and generate random X's for them (use set seed to make sure it will always create the same data set). Create the Ys from the Xs with a true relationship and an error source. Save this data set in your Box folder.
3.	Write a do-file defining a program that: (a) loads this data; (b) randomly samples a subset whose sample size is an argument to the program; (c) performs a regression of Y on X; and (e) returns the N, beta, SEM, p-value, and confidence intervals into r().
4.	Using the simulate command, run your program 500 times each at sample sizes N = 10, 100, 1,000, and 10,000. Load the resulting data set of 2,000 regression results into Stata.
5.	Create at least one figure and at least one table showing the variation in your beta estimates depending on the sample size, and characterize the size of the SEM and confidence intervals as N gets larger.
6.	Fully describe your results in your README file, including figures and tables as appropriate.
*/





clear all
set seed 123456







* STEP 1-2: CREATE THE FIXED POPULATION
* We create a population of 10,000 individuals with a true relationship
* between X and Y. Y = 5 + 2*X + error
* The seed ensures this population is always the same


set obs 10000

* Generate X as a random normal variable
gen x = rnormal(0, 1)

* Generate Y with a true relationship: intercept=5, slope=2, plus random noise
* rnormal(0,3) is the error source - random noise with SD=3
gen y = 5 + 2*x + rnormal(0, 3)

* Label variables
label var x "Independent Variable"
label var y "Outcome Variable (Y = 5 + 2X + error)"

* Save the fixed population - this file never changes
save "population.dta", replace





* STEP 3: DEFINE THE PROGRAM
* This program:
* a) loads the fixed population
* b) takes a random sample of size n
* c) runs a regression of Y on X
* d) returns N, beta, SEM, p-value, and confidence intervals into r()


capture program drop sample_reg
program define sample_reg, rclass
    args n                              // n is the sample size argument

    * (a) Load the fixed population every time
    use "population.dta", clear

    * (b) Randomly sample n observations from the population
    * "count" means n is a number of observations, not a percentage
    sample `n', count

    * (c) Run regression of Y on X
    regress y x

    * (d) Return results into r()
    * N: number of observations in this sample
    return scalar N     = e(N)
    * beta: estimated coefficient on X (should be close to true value of 2)
    return scalar beta  = _b[x]
    * sem: standard error of the beta estimate
    return scalar sem   = _se[x]
    * pval: two-tailed p-value for the coefficient on X
    return scalar pval  = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    * confidence intervals: beta +/- 1.96*SEM
    return scalar ci_lo = _b[x] - 1.96*_se[x]
    return scalar ci_hi = _b[x] + 1.96*_se[x]

end







* STEP 4: RUN SIMULATE 500 TIMES AT EACH SAMPLE SIZE
* We run the program 500 times at N = 10, 100, 1000, 10000
* Each run takes a different random sample from the fixed population
* This gives us 2,000 regression results total (500 x 4 sample sizes)

* We will store all results here
tempfile results_all

* Loop over each sample size
foreach n in 10 100 1000 10000 {

    * Run the program 500 times and collect results
    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ///
             ci_lo=r(ci_lo) ci_hi=r(ci_hi),              ///
             reps(500) nodots: sample_reg `n'

    * Tag which sample size these results came from
    gen sample_size = `n'

    * Save or append results
    if `n' == 10 {
        * First batch - just save
        save `results_all', replace
    }
    else {
        * Subsequent batches - append to existing results
        append using `results_all'
        save `results_all', replace
    }
}

* Load the final combined dataset of 2,000 results
use `results_all', clear






* STEP 5A: FIGURE - Distribution of beta estimates by sample size
* This shows how the spread of beta estimates shrinks as N grows
* The red line marks the TRUE beta value of 2


graph box beta, over(sample_size)                    ///
    yline(2, lcolor(red) lpattern(dash))             ///
    title("Distribution of Beta Estimates by Sample Size") ///
    ytitle("Estimated Beta")                         ///
    note("Red line = true beta value of 2")


	
	
	

* STEP 5B: FIGURE - Average SEM by sample size
* This shows how precision improves as N grows


* Calculate mean SEM and CI width for each sample size
gen ci_width = ci_hi - ci_lo

* Collapse to one row per sample size for plotting
preserve
    collapse (mean) beta sem ci_width, by(sample_size)

    * Plot average SEM by sample size
    twoway line sem sample_size,                         ///
        title("Average SEM by Sample Size")             ///
        xtitle("Sample Size")                           ///
        ytitle("Average Standard Error")                ///
        xlabel(10 100 1000 10000)

restore









* STEP 5C: TABLE - Summary statistics by sample size
* Shows mean beta, SEM, and CI width at each sample size

* Generate ci_width if not already generated
capture gen ci_width = ci_hi - ci_lo

* Table of results
table sample_size,                  ///
    statistic(mean beta)            ///
    statistic(sd beta)              ///
    statistic(mean sem)             ///
    statistic(mean ci_width)        ///
    nformat(%9.4f)

	
	
	
	
*STEP 6 – Describe results

/*---------------------------------------------------------------
            |              Mean              Standard deviation
            |  r(beta)   r(sem)   ci_width              r(beta)
------------+--------------------------------------------------
sample_size |                                                  
  10        |   2.0488   1.0800     4.2338               1.0718
  100       |   1.9910   0.3028     1.1868               0.3029
  1000      |   1.9727   0.0947     0.3711               0.0926
  10000     |   1.9739   0.0299     0.1172               0.0000
  Total     |   1.9966   0.3768     1.4772               0.5593
---------------------------------------------------------------


As we can observe in the table, as the sample size becomes bigger, the SE becomes smaller.This means that results with larger smaple sizes will be more accurate, as a bigger n reduces the spread (variation) of a sampling distribution.  When we use the enitre population as sample, we can observe SE is basically 0, which makes sense because you are using your true population as the sample. Regarding the beta, it's also evident that the effect is reduced, as well as the width of the CI. This also makes sense based on the reduction of the SE.




*SEM meaning: if I took many samples of this size, how much would my beta estimate jump around?"*/



























*------------------------------------------------------------------------------*
**# QUESTION 2 HW3
*------------------------------------------------------------------------------*

/*Part 2: Sampling noise in an infinite superpopulation.
1.	Write a do-file defining a program that: (a) randomly creates a data set whose sample size is an argument to the program following your DGP from Part 1 including a true relationship and an error source; (b) performs a regression of Y on one X; and (c) returns the N, beta, SEM, p-value, and confidence intervals into r().
2.	Using the simulate command, run your program 500 times each at sample sizes corresponding to the first twenty powers of two (ie, 4, 8, 16 ...); as well as at N = 10, 100, 1,000, 10,000, 100,000, and 1,000,000. Load the resulting data set of 13,000 regression results into Stata.
3.	Create at least one figure and at least one table showing the variation in your beta estimates depending on the sample size, and characterize the size of the SEM and confidence intervals as N gets larger.
4.	Fully describe your results in your README file, including figures and tables as appropriate.
5.	In particular, take care to discuss the reasons why you are able to draw a larger sample size than in Part 1, and why the sizes of the SEM and confidence intervals might be different at the powers of ten than in Part 1. Can you visualize Part 1 and Part 2 together meaningfully, and create a comparison table?*/




clear all
set seed 123456


* STEP 1: DEFINE THE PROGRAM
* Key difference from Part 1: instead of loading a saved dataset,
* we generate BRAND NEW data every time the program runs.
* This is the "infinite superpopulation" - there is no fixed dataset,
* just a data generating process we can sample from unlimited times.


capture program drop superpop_reg
program define superpop_reg, rclass
    args n                              // n is the sample size argument

    * (a) Generate a brand new dataset of size n every single time
    * Unlike Part 1, we are NOT loading a saved file
    * We are drawing fresh observations from an infinite population
    clear
    set obs `n'

    * Same DGP as Part 1: Y = 5 + 2*X + error
    * X is a random normal variable
    gen x = rnormal(0, 1)
    * Y has a true relationship with X: intercept=5, slope=2, plus noise
    gen y = 5 + 2*x + rnormal(0, 3)

    * (b) Run regression of Y on X
    regress y x

    * (c) Return results into r()
    * N: number of observations in this sample
    return scalar N     = e(N)
    * beta: estimated coefficient on X (true value is 2)
    return scalar beta  = _b[x]
    * sem: standard error of the beta estimate
    return scalar sem   = _se[x]
    * pval: two-tailed p-value for the coefficient on X
    return scalar pval  = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    * confidence intervals: beta +/- 1.96*SEM
    return scalar ci_lo = _b[x] - 1.96*_se[x]
    return scalar ci_hi = _b[x] + 1.96*_se[x]

end






* STEP 2A: RUN SIMULATE AT FIRST 20 POWERS OF 2
* Powers of 2: 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048,
*              4096, 8192, 16384, 32768, 65536, 131072, 262144,
*              524288, 1048576, 2097152
* 500 reps x 20 sample sizes = 10,000 regression results


tempfile results_all

forvalues k = 2/21 {                    // k=2 gives 2^2=4, k=21 gives 2^21
    local n = 2^`k'

    display "Running sample size `n'..."

    * Run program 500 times and collect results
    * nodots suppresses the progress dots
    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ///
             ci_lo=r(ci_lo) ci_hi=r(ci_hi),              ///
             reps(500) nodots: superpop_reg `n'

    * Tag which sample size and source these results came from
    gen sample_size = `n'
    gen source = "power_of_2"

    * Save first batch, append all subsequent batches
    if `k' == 2 {
        save `results_all', replace
    }
    else {
        append using `results_all'
        save `results_all', replace
    }
}








* STEP 2B: RUN SIMULATE AT POWERS OF 10
* N = 10, 100, 1000, 10000, 100000, 1000000
* 500 reps x 6 sample sizes = 3,000 regression results
* Note: N=1,000,000 will take a while to run

foreach n in 10 100 1000 10000 100000 1000000 {

    display "Running sample size `n'..."

    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ///
             ci_lo=r(ci_lo) ci_hi=r(ci_hi),              ///
             reps(500) nodots: superpop_reg `n'

    gen sample_size = `n'
    gen source = "power_of_10"

    append using `results_all'
    save `results_all', replace
}

* Load the final combined dataset of 13,000 results
use `results_all', clear







* STEP 3A: FIGURE - Distribution of beta estimates by sample size
* Shows how beta estimates cluster tighter around true value of 2
* as sample size grows


* Because sample sizes span a huge range, use log scale
gen log_sample = log10(sample_size)

graph box beta, over(sample_size)                        ///
    yline(2, lcolor(red) lpattern(dash))                 ///
    title("Distribution of Beta Estimates by Sample Size") ///
    ytitle("Estimated Beta")                             ///
    note("Red line = true beta value of 2")


	
	
	
	
* STEP 3B: FIGURE - Average SEM by sample size
* Shows how precision improves as N grows
* We use log scale because sample sizes span from 4 to 1,000,000


gen ci_width = ci_hi - ci_lo

preserve
    * Collapse to one row per sample size
    collapse (mean) beta sem ci_width (sd) sd_beta=beta, by(sample_size)

    * Plot SEM on log scale
    twoway line sem sample_size,                         ///
        title("Average SEM by Sample Size")             ///
        xtitle("Sample Size (log scale)")               ///
        ytitle("Average Standard Error")                ///
        xscale(log)                                     ///
        xlabel(4 16 64 256 1024 10000 100000 1000000, angle(45))

restore







* STEP 3C: TABLE - Summary statistics by sample size
* Shows mean beta, SD of beta, mean SEM, and mean CI width
* at each sample size - should show all shrinking as N grows


capture gen ci_width = ci_hi - ci_lo

table sample_size,                                       ///
    statistic(mean beta)                                 ///
    statistic(sd beta)                                   ///
    statistic(mean sem)                                  ///
    statistic(mean ci_width)                             ///
    nformat(%9.4f)


	
	
	
	
* STEP 5: COMPARE PART 1 AND PART 2
* Load Part 1 results and tag them
* (assuming you saved Part 1 results as "results_part1.dta")
use "results_part1.dta", clear
gen part = "1: Fixed Population"
append using `results_all'
replace part = "2: Infinite Superpopulation" if part == ""

* Collapse for comparison plot
preserve
    collapse (mean) sem, by(sample_size part)

    * Plot both SEM curves together
    twoway (line sem sample_size if part == "1: Fixed Population")       ///
           (line sem sample_size if part == "2: Infinite Superpopulation"), ///
           legend(label(1 "Fixed Population")                            ///
                  label(2 "Infinite Superpopulation"))                   ///
           title("SEM Comparison: Fixed vs Infinite Population")         ///
           xscale(log)                                                   ///
           xtitle("Sample Size (log scale)")                             ///
           ytitle("Average SEM")

restore

* Comparison table
table sample_size part,                                  ///
    statistic(mean sem)                                  ///
    statistic(mean ci_width)                             ///
    nformat(%9.4f)



	
/*--------------------------------------------------------------
            |              Mean              Standard deviation
            |  r(beta)   r(sem)   ci_width              r(beta)
------------+--------------------------------------------------
sample_size |                                                  
  4         |   1.8332   2.0327     7.9683               2.7790
  8         |   1.9186   1.2180     4.7747               1.4097
  10        |   2.0625   1.0798     4.2327               1.1746
  16        |   2.0075   0.7951     3.1169               0.8302
  32        |   1.9693   0.5429     2.1281               0.5420
  64        |   2.0076   0.3821     1.4980               0.3789
  100       |   1.9727   0.3037     1.1907               0.2921
  128       |   1.9843   0.2661     1.0430               0.2652
  256       |   1.9995   0.1884     0.7384               0.1877
  512       |   2.0091   0.1326     0.5199               0.1214
  1000      |   1.9979   0.0947     0.3714               0.0957
  1024      |   1.9988   0.0940     0.3683               0.0907
  2048      |   1.9987   0.0664     0.2604               0.0666
  4096      |   1.9988   0.0469     0.1840               0.0470
  8192      |   2.0028   0.0331     0.1299               0.0325
  10000     |   2.0024   0.0300     0.1176               0.0289
  16384     |   2.0013   0.0234     0.0919               0.0234
  32768     |   2.0001   0.0166     0.0649               0.0164
  65536     |   2.0008   0.0117     0.0459               0.0119
  100000    |   2.0008   0.0095     0.0372               0.0090
  131072    |   2.0002   0.0083     0.0325               0.0081
  262144    |   1.9997   0.0059     0.0230               0.0058
  524288    |   2.0002   0.0041     0.0162               0.0042
  1000000   |   2.0000   0.0030     0.0118               0.0030
  1048576   |   1.9999   0.0029     0.0115               0.0030
  2097152   |   2.0000   0.0021     0.0081               0.0022
  Total     |   1.9910   0.2844     1.1148               0.6924
---------------------------------------------------------------



The reason why we can draw a larger sample size is that the previous questions was capped at n=10,000. Here, the n can extend to infinite, so it can grow as much as the researcher decides. Here, the CI and the SEM might be different because the population is infinite, so even if we sample a very big number, there's likely going to be variation reflected in the CI and SE. In the previous question, when n=10,000, SE was almost zero because we were basically sampling the whole population. Not much room for error. Thus, at large N, Part 1 SEMs will be smaller than Part 2 SEMs due to this finite population correction*/

	
/*The p-value answers this question: "if the true effect were zero, how likely am I to see a beta this large just by chance?"*/	
	
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
*------------------------------------------------------------------------------*
**# QUESTION 3 HW3
*------------------------------------------------------------------------------*	
/*Part 3: Power calculations for individual-level randomization
1.	Develop a data generating process for some Y that is normally disturbed around 0 with standard deviation of 1.
2.	The average treatment effect should be 0.1 sd (with the effects being uniformly distributed between 0.0 – 0.2 sd)
3.	The proportion of individuals receiving treatment should be 0.5 (i.e. half in control, and half in treatment) Calculate the number of individuals required to reach 80% power when you are trying to detect 0.1 sd treatment effect.
4.	Now assume, 15% of the sample will attrite (assume similar attrition rates in control and treatment arms.) How does this change your sample size calculations from the previous part?
5.	Now assume the intervention is very expensive and we can only afford to provide this specific treatment to 30% of the sample. How would this change the sample size needed for 80% power.*/

clear all
set seed 123456


* STEP 1-2: TEST THE DGP FIRST 
* Y is normally distributed around 0 with SD=1
* Treatment effect is 0.1 SD on average, uniform between 0.0 and 0.2
* This is individual-level randomization - no clustering


clear
set obs 1000                         // test with 1000 people first

* 50/50 treatment assignment
* _n goes from 1 to 1000, so _n > 500 gives exactly 500 treated
gen treat = (_n > 500)

* Treatment effect: uniform between 0.0 and 0.2 SD
* Since Y has SD=1, effect in SD units = effect in raw units
* No need to multiply by anything unlike Part 4
gen te = runiform(0.0, 0.2)

* Outcome: normal around 0 with SD=1, plus treatment effect if treated
gen y = rnormal(0, 1) + te*treat

* Check it looks right
summarize y treat te
* Mean of y should be close to 0
* Mean of treat should be close to 0.5
* Mean of te should be close to 0.1







* STEP 3: PROGRAM FOR BASIC POWER CALCULATION (50/50, no attrition)
* This is the baseline - optimal design with equal treatment/control

capture program drop sim_indiv
program define sim_indiv, rclass
    args n                           // only argument is sample size

    clear
    set obs `n'

    * 50/50 treatment assignment
    gen treat = (_n > `n'/2)

    * Treatment effect uniform between 0.0 and 0.2 SD
    gen te = runiform(0.0, 0.2)

    * Outcome: SD=1, centered at 0, plus treatment effect
    gen y = rnormal(0, 1) + te*treat

    * Run regression
    regress y treat

    * Return results
    return scalar beta = _b[treat]
    return scalar pval = 2*ttail(e(df_r), abs(_b[treat]/_se[treat]))
    return scalar N    = e(N)

end

* Test it once before running simulate
sim_indiv 1000
display "Beta: " r(beta)
display "P-value: " r(pval)








* STEP 3B: FIND N FOR 80% POWER (50/50 split)
* We try different sample sizes and see where power crosses 0.8
* Effect size is small (0.1 SD) so we expect to need a large sample


tempfile results3
postfile buffer3 n power using `results3', replace

* Try a range of sample sizes
* We start with a guess - for a 0.1 SD effect we expect to need
* somewhere between 1000 and 5000 people
foreach n in 100 500 1000 2000 3000 4000 5000 {

    display "Running N=`n'..."

    * Run program 500 times and collect p-values
    simulate pval=r(pval), reps(500) nodots: sim_indiv `n'

    * Power = proportion of times we rejected the null (pval < 0.05)
    gen reject = (pval < 0.05)
    summarize reject
    local power = r(mean)

    * Save this sample size and its power
    post buffer3 (`n') (`power')
    drop pval reject
}

postclose buffer3

* Load and plot results
use `results3', clear

twoway line power n,                                     ///
    yline(0.8, lcolor(red) lpattern(dash))               ///
    title("Power vs Sample Size (50/50, No Attrition)")  ///
    xtitle("Sample Size")                                ///
    ytitle("Power")                                      ///
    ylabel(0 0.2 0.4 0.6 0.8 1)                         ///
    note("Red line = 80% power threshold")

* Save results for comparison later
gen scenario = "Q3: Baseline"
save "results_q3.dta", replace









* STEP 4: PROGRAM WITH 15% ATTRITION
* Attrition means 15% of people drop out and we lose their data
* We randomly remove 15% of observations AFTER generating the data
* Since attrition is equal in both arms, we just need a bigger sample
* to end up with enough observations after dropout


capture program drop sim_attrit
program define sim_attrit, rclass
    args n attrition_rate            // two arguments: sample size and attrition rate

    clear
    set obs `n'

    * 50/50 treatment assignment
    gen treat = (_n > `n'/2)

    * Treatment effect
    gen te = runiform(0.0, 0.2)

    * Outcome
    gen y = rnormal(0, 1) + te*treat

    * Attrition: randomly remove attrition_rate % of the sample
    * runiform() draws a number between 0 and 1 for each person
    * if that number is less than attrition_rate, they drop out
    gen attrit = (runiform() < `attrition_rate')
    drop if attrit == 1
    * After this, roughly 85% of original sample remains

    * Run regression on remaining sample
    regress y treat

    return scalar beta = _b[treat]
    return scalar pval = 2*ttail(e(df_r), abs(_b[treat]/_se[treat]))
    return scalar N    = e(N)        // this will be ~85% of original n

end

* Test it once - check that N is roughly 85% of what you passed in
sim_attrit 1000 0.15
display "N after attrition: " r(N)   // should be around 850









* STEP 4B: FIND N FOR 80% POWER WITH 15% ATTRITION
* We expect to need MORE people than Q3 because we lose 15% of our sample
* Rule of thumb: divide Q3 sample size by 0.85 to get starting point

tempfile results4
postfile buffer4 n power using `results4', replace

* Extend range since we need more people than Q3
foreach n in 100 500 1000 2000 3000 4000 5000 6000 7000 {

    display "Running N=`n' with attrition..."

    simulate pval=r(pval), reps(500) nodots: sim_attrit `n' 0.15

    gen reject = (pval < 0.05)
    summarize reject
    local power = r(mean)

    post buffer4 (`n') (`power')
    drop pval reject
}

postclose buffer4

use `results4', clear

twoway line power n,                                         ///
    yline(0.8, lcolor(red) lpattern(dash))                   ///
    title("Power vs Sample Size (50/50, 15% Attrition)")     ///
    xtitle("Sample Size")                                    ///
    ytitle("Power")                                          ///
    ylabel(0 0.2 0.4 0.6 0.8 1)                             ///
    note("Red line = 80% power threshold")

gen scenario = "Q4: 15% Attrition"
save "results_q4.dta", replace









* STEP 5: PROGRAM WITH UNEQUAL TREATMENT SHARE (30% treated)
* When treatment is expensive, we can only treat 30% of the sample
* This is LESS efficient than 50/50 - the optimal split is always equal
* So we need an even larger sample to reach 80% power


capture program drop sim_unequal
program define sim_unequal, rclass
    args n treatment_share           // two arguments: sample size and treatment share

    clear
    set obs `n'

    * Assign treatment to only treatment_share % of sample
    * runiform() < 0.3 is true for roughly 30% of observations
    gen treat = (runiform() < `treatment_share')

    * Treatment effect
    gen te = runiform(0.0, 0.2)

    * Outcome
    gen y = rnormal(0, 1) + te*treat

    * Run regression
    regress y treat

    return scalar beta = _b[treat]
    return scalar pval = 2*ttail(e(df_r), abs(_b[treat]/_se[treat]))
    return scalar N    = e(N)

end

* Test it once - check treatment share is roughly 30%
sim_unequal 1000 0.3
display "Beta: " r(beta)












* STEP 5B: FIND N FOR 80% POWER WITH 30% TREATMENT SHARE
* We expect to need MORE people than Q3 because the unequal split
* means we have less statistical power per observation


tempfile results5
postfile buffer5 n power using `results5', replace

* Extend range even further since unequal split needs more people
foreach n in 100 500 1000 2000 3000 4000 5000 6000 7000 8000 {

    display "Running N=`n' with 30% treatment..."

    simulate pval=r(pval), reps(500) nodots: sim_unequal `n' 0.3

    gen reject = (pval < 0.05)
    summarize reject
    local power = r(mean)

    post buffer5 (`n') (`power')
    drop pval reject
}

postclose buffer5

use `results5', clear

twoway line power n,                                             ///
    yline(0.8, lcolor(red) lpattern(dash))                       ///
    title("Power vs Sample Size (30% Treatment, No Attrition)")  ///
    xtitle("Sample Size")                                        ///
    ytitle("Power")                                              ///
    ylabel(0 0.2 0.4 0.6 0.8 1)                                 ///
    note("Red line = 80% power threshold")

gen scenario = "Q5: 30% Treatment"
save "results_q5.dta", replace


* STEP 6: COMBINE ALL THREE SCENARIOS FOR COMPARISON
* This puts all three power curves on one graph so you can clearly
* see how attrition and unequal splits increase the N you need


use "results_q3.dta", clear
append using "results_q4.dta"
append using "results_q5.dta"

* Plot all three curves together
twoway (line power n if scenario == "Q3: Baseline")              ///
       (line power n if scenario == "Q4: 15% Attrition")         ///
       (line power n if scenario == "Q5: 30% Treatment"),        ///
       yline(0.8, lcolor(red) lpattern(dash))                    ///
       legend(label(1 "Q3: Baseline (50/50)")                    ///
              label(2 "Q4: 15% Attrition")                       ///
              label(3 "Q5: 30% Treatment"))                      ///
       title("Power Comparison Across Scenarios")                ///
       xtitle("Sample Size") ytitle("Power")                     ///
       ylabel(0 0.2 0.4 0.6 0.8 1)                              ///
       note("Red line = 80% power threshold")

	   
	   

	   
	   
/*As we can observe in the graph, reaching 80% power with a smaller N is easiest in the first 50/50 design. When we add 15% attrition and 30% treatment rate, the required N to reach 80% grows. The reason is that these factors effectively reduce the sample size, which means the results will be less accurate. To compensate that, we will need to increase the population size in order to get that 80% power*/


















	
	
	


*------------------------------------------------------------------------------*
**# QUESTION 4 HW3
*------------------------------------------------------------------------------*

/* Part 4: Power calculations for cluster randomization
1.	Develop data generating process for data for Y (assume math score of each individual student) in a school. We can only assign treatment at the school-level.
2.	Your function should be able to change the number of clusters (i.e. schools) and the cluster size (i.e. number of students in each school)
3.	Make sure the rho/icc is ~ 0.3 when generating these clusters. Hint.
4.	Divide the schools evenly between treatment and control arms. And generate a treatment effect of 0.2 sd (with the effects being uniformly distributed between 0.15 – 0.25 sd)
5.	Holding the number of clusters fixed at 200, what happens to the power when you increase the cluster size (use first 10 powers of 2) What cluster size would you recommend and why?
6.	Now hold the cluster size fixed (15 students/school). How many schools do you need in your RCT to get 80% to detect 0.2 sd treatment effect.
7.	Now assume that only 70% of the schools actually adopt your treatment. How many schools do you need now to get 80% power?*/


clear all
set seed 123456


* STEP 1-4: PROGRAM DEFINITION


capture program drop sim_cluster
program define sim_cluster, rclass
    args num_schools cluster_size

    * Clear and create school-level data. We create locals to be able to change the numbers.
    clear
    set obs `num_schools' 
    gen school_id = _n

    * School-level random effect (calibrated for ICC = 0.3)
    * ICC = var_between / (var_between + var_within)
    * 0.3 = 3 / (3 + 7) -> SD_between = sqrt(3) = 1.73, SD_within = sqrt(7) = 2.65
    gen school_effect = rnormal(0, 1.73)

    * Treatment assignment (50/50 split at school level)
    gen treat = (_n > `num_schools'/2)

    * School-level treatment effect (0.2 SD, uniform between 0.15-0.25)
    * Total SD = sqrt(3 + 7) = sqrt(10) = 3.16
    gen te_sd = runiform(0.15, 0.25)
    gen true_effect = te_sd * 3.16

    * Expand to students
    expand `cluster_size'
    bysort school_id: gen student_id = _n

    * Generate outcome. We use rnormal(0,2.65) 
    gen math_score = 60 + true_effect*treat + school_effect + rnormal(0, 2.65)

    * Run regression
    regress math_score treat, vce(cluster school_id)

    * Return results
    return scalar beta = _b[treat]
    return scalar pval = 2*ttail(e(df_r), abs(_b[treat]/_se[treat]))

end





* STEP 5: Power vs Cluster Size (200 schools, vary cluster size)


tempfile results5
postfile buffer5 cluster_size power using `results5', replace

forvalues k = 1/10 {
    local csize = 2^`k'

    simulate pval=r(pval), reps(500) nodots: sim_cluster 200 `csize'

    gen reject = (pval < 0.05)
    summarize reject
    local power = r(mean)

    post buffer5 (`csize') (`power')
    drop pval reject
}

postclose buffer5
use `results5', clear

* Plot power curve
twoway line power cluster_size, ///
    xlabel(2 4 8 16 32 64 128 256 512 1024) ///
    ylabel(0 0.2 0.4 0.6 0.8 1) ///
    yline(0.8, lcolor(red) lpattern(dash)) ///
    xtitle("Cluster Size (Students per School)") ///
    ytitle("Power") ///
    title("Power vs Cluster Size (200 Schools Fixed)")


/* As we can admire in the graph, power stagnates around cluster size 8-16 and never reaches 80% regardless of how many students per school we add. This is because with ICC=0.3, the binding constraint is the number of schools (200), not the number of students. Adding more students per school yields diminishing returns quickly. We recommend a cluster size of around 8-16 students per school since power stops improving beyond that point, making larger cluster sizes costly without benefit*/	
	
	
	
* STEP 6: How many schools for 80% power (15 students/school)


tempfile results6
postfile buffer6 num_schools power using `results6', replace //postfile helps you keep the results of each iteration in the following loop. We use replace to overwrite whatever file that has the same name. 

foreach n in 250 260 270 280 290 300 310 320 {
    simulate pval=r(pval), reps(500) nodots: sim_cluster `n' 15

    gen reject = (pval < 0.05)
    summarize reject
    local power = r(mean)

    post buffer6 (`n') (`power')
    drop pval reject
}

postclose buffer6
use `results6', clear

* Plot power curve
twoway line power num_schools, ///
    ylabel(0 0.2 0.4 0.6 0.8 1) ///
    yline(0.8, lcolor(red) lpattern(dash)) ///
    xtitle("Number of Schools") ///
    ytitle("Power") ///
    title("Power vs Number of Schools (15 Students/School Fixed)")

/*As we can observe in the graph and in the dataset, the amount of schools needed to obtain a power of 80% ranges between 280 and 300. Thus, if the student number is set at 15, we would recommend to a number of schools higher than 280*/
	
	
	
* STEP 7: 70% compliance - how many schools for 80% power


capture program drop sim_cluster_comply
program define sim_cluster_comply, rclass
    args num_schools cluster_size compliance

    clear
    set obs `num_schools'
    gen school_id = _n
    gen school_effect = rnormal(0, 1.73)

    * Treatment assignment
    gen assigned_treat = (_n > `num_schools'/2)

    * Actual treatment (only compliance% of treated schools adopt)
    gen actual_treat = assigned_treat * (runiform() < `compliance')

    * School-level treatment effect
    gen te_sd = runiform(0.15, 0.25)
    gen true_effect = te_sd * 3.16

    * Expand to students
    expand `cluster_size'
    bysort school_id: gen student_id = _n

    * Generate outcome using actual treatment
    gen math_score = 60 + true_effect*actual_treat + school_effect + rnormal(0, 2.65)

    * Regress on assigned treatment (intent-to-treat analysis)
    regress math_score assigned_treat, vce(cluster school_id)

    return scalar beta = _b[assigned_treat]
    return scalar pval = 2*ttail(e(df_r), abs(_b[assigned_treat]/_se[assigned_treat]))

end

tempfile results7
postfile buffer7 num_schools power using `results7', replace

foreach n in 550 575 600 625 650 675 700 {
    simulate pval=r(pval), reps(500) nodots: sim_cluster_comply `n' 15 0.7

    gen reject = (pval < 0.05)
    summarize reject
    local power = r(mean)

    post buffer7 (`n') (`power')
    drop pval reject
}

postclose buffer7
use `results7', clear

* Plot power curve
twoway line power num_schools, ///
    ylabel(0 0.2 0.4 0.6 0.8 1) ///
    yline(0.8, lcolor(red) lpattern(dash)) ///
    xtitle("Number of Schools") ///
    ytitle("Power") ///
    title("Power vs Number of Schools (70% Compliance, 15 Students/School)")

	
	
	
/*As we can observe in the graph and the dataset, with a 70% compliance rate and 15 students, we need at least 575 schools to obtain a power higher than 80%*/


