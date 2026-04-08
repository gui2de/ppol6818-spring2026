* Part 3: Power calculations for individual-level randomization

* Set working directory
cd "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 3"

* 1. Calculate sample size for 80% power (Base case: 50% treatment)
* We are trying to detect a 0.1 SD treatment effect with 80% power.
* Base Y is normally distributed around 0 with SD = 1.
* Control mean = 0, Treatment mean = 0.1, Standard Deviation = 1.
power twomeans 0 0.1, sd(1) power(0.8)

* NOTE: The output from the command above will show N = 3142 (1571 per arm).
* We will use this N (3142) in our simulation below.


* 2. Simulation of the Data Generating Process (DGP)
clear
tempfile results_p3
save `results_p3', emptyok

set seed 2026

* Input parameters based on the power calculation above
local samplesize = 3142
local treat_num = `samplesize' / 2

forvalues i = 1/1000 {
    clear
    set obs `samplesize'

    * Generate dummy variable for treatment (50% control, 50% treatment)
    * Using the exact rank logic from the class notes
    gen rand = rnormal()
    egen rank = rank(rand)
    gen treatment = rank <= `treat_num'

    * Data Generating Process (DGP)
    * 1. Y is normally disturbed around 0 with standard deviation of 1
    gen y = rnormal(0, 1)

    * 2. Treatment effect is uniformly distributed between 0.0 and 0.2 sd 
    * (This means the average treatment effect is 0.1)
    gen te = runiform(0, 0.2)

    * 3. Apply the individual treatment effect to the treatment group
    replace y = y + te if treatment == 1

    * Perform regression of Y on treatment
    reg y treatment

    * Extract results using the matrix method from notes
    mat a = r(table)

    clear
    set obs 1
    gen iteration = `i'
    gen reg_coef = a[1,1]
    gen reg_pval = a[4,1]
    
    * Generate an indicator: 1 if the result is statistically significant (p < 0.05), 0 otherwise
    gen significant = (reg_pval < 0.05)

    append using `results_p3'
    save `results_p3', replace
}

* Analyze simulation results
use `results_p3', clear
save "Part3_Simulation_Results.dta", replace

* Calculate empirical power
* The mean of the "significant" variable is our empirical power. 
* It should be approximately 0.80 (80%), verifying our theoretical calculation.
sum significant


* 3. Adjusting Sample Size for 15% Attrition
* If 15% of the sample attrites (drops out), we only retain 85% of our starting sample.
* We still need the final effective sample size to be 3142.
* Starting Sample * (1 - 0.15) = 3142
* Starting Sample = 3142 / 0.85

display "Required sample size with 15% attrition (rounded up):"
display ceil(3142 / 0.85)

* 4. Adjusting Sample Size for 30% Treatment Allocation
* We use the "nratio" option in the power command to handle unequal allocation.
power twomeans 0 0.1, sd(1) power(0.8) nratio(0.42857)
