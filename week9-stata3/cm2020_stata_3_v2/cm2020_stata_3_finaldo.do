/*==============================================================================
*Name: Catherine Morris
*Class: Gui2de Spring 2026
*Assignment: Stata 3 
*Date: March 19, 2026
*Edited: March 20, 2026
*Edited: March 21, 2026
*Edited: March 22, 2026

==============================================================================*/
/*==============================================================================
PART 1 

STEPS 1 & 2: Develop Data Generating Process and Create Fixed Population

Data Generating Process:
  X ~ Normal(mean=20, sd=5)
  Y = 3*X + 10 + epsilon
      where epsilon ~ Normal(0, sd=15)

  True beta on X = 3
  True intercept = 10
  Noise SD       = 15
==============================================================================*/

clear all

*Establishing file path 
if c(username) == "cam_cew" {
	global path "/Users/cam_cew/Desktop/Experimental_design/Stata_3_assignment"
} 
display "${path}"

*Set seed so population is always identical 
set seed 20240319

*Create 10,000-observation population 
clear
set obs 10000

*Generate X
gen x = rnormal(20, 5)

*Generate Y using the true relationship + random noise
*    True model: Y = 3*X + 10 + epsilon
gen epsilon = rnormal(0, 15)
gen y = 3 * x + 10 + epsilon

*Drop helper variable 
drop epsilon

*Review
summarize y x
reg y x          

*shows beta ≈ 3 (2.998909), intercept ≈ 10 (10.15261)

*Save as tempfile
tempfile population
global popfile `population'

save `population', replace


/*------------------------------------------------------------------------------
  STEP 3 – Define the sampling-and-regression program
------------------------------------------------------------------------------*/

capture program drop sample_and_reg
program define sample_and_reg, rclass
   

    args sample_size

    *Using the tempfile
    quietly use "${popfile}", clear

    *Creating a random sample of size `sample_size' 
    quietly sample `sample_size', count

    *Regressing y on x 
    quietly reg y x

    *Extract results from r(table) matrix 
    matrix results = r(table)

    *Return result into r() so simulate command can collect them subsequently
    return scalar N      = e(N)
    return scalar beta   = results[1, 1]   // i.e., coefficient on X
    return scalar sem    = results[2, 1]   // i.e., std error
    return scalar pval   = results[4, 1]   // i.e., p-value
    return scalar ci_lo  = results[5, 1]   // i.e., lower 95% CI
    return scalar ci_hi  = results[6, 1]   // i.e., upper 95% CI

end


/*------------------------------------------------------------------------------
  STEP 4 – Run simulation 500 times at each sample size
------------------------------------------------------------------------------*/

local reps 500
local sizes "10 100 1000 10000"

*Creating new tempfile but clearing first so prior results don't get pulled into new tempfile
clear 
tempfile allresults
save `allresults', emptyok

foreach n of local sizes {

    display as text _newline "Running simulate: N = `n', reps = `reps' ..."

	*Run sample_and_reg 500 times and collect results into dataset
    simulate                             ///
        sim_N    = r(N)                  ///
        sim_beta = r(beta)               ///
        sim_sem  = r(sem)                ///
        sim_pval = r(pval)               ///
        sim_cilo = r(ci_lo)              ///
        sim_cihi = r(ci_hi),             ///
        reps(`reps') seed(20240319):     ///
        sample_and_reg `n'

    *Tagging with the nominal sample size 
    gen nominal_N = `n'

    *Generating derived variable: CI width 
    gen ci_width = sim_cihi - sim_cilo

    *Appending to master results file 
    append using `allresults'
    save `allresults', replace

}

use `allresults', clear

*Creating label for N groups 
label define Nlbl 10 "N=10" 100 "N=100" 1000 "N=1,000" 10000 "N=10,000"
label values nominal_N Nlbl


*creating new folder to store output I don't get horribly mixed up
global out "/Users/cam_cew/Desktop/Experimental_design/Stata_3_assignment/part_1_output"

save "${out}/cm2020_simulation_results_q1.dta", replace
display as text "Simulation results saved to: ${out}/cm2020_simulation_results_q1.dta"


/*------------------------------------------------------------------------------
  STEP 5a – FIGURE: Distribution of beta estimates by sample size
  (violin / kdensity overlay, one panel per N)
------------------------------------------------------------------------------*/


set scheme s2color

twoway                                                           ///
    (kdensity sim_beta if nominal_N == 10,    lcolor(cranberry)  lwidth(medthick)) ///
    (kdensity sim_beta if nominal_N == 100,   lcolor(navy)       lwidth(medthick)) ///
    (kdensity sim_beta if nominal_N == 1000,  lcolor(forest_green) lwidth(medthick)) ///
    (kdensity sim_beta if nominal_N == 10000, lcolor(dkorange)   lwidth(medthick)) ///
    ,                                                            ///
    xline(3, lcolor(black) lpattern(dash) lwidth(thin))          ///
    legend(order(1 "N=10" 2 "N=100" 3 "N=1,000" 4 "N=10,000")  ///
           position(1) ring(0) cols(1))                          ///
    xtitle("Estimated Beta (OLS coefficient on X)")              ///
    ytitle("Density")                                            ///
    title("Distribution of Beta Estimates by Sample Size")       ///
    subtitle("500 simulations per N | True beta = 3 | Dashed line = true value") ///
    note("Population: 10,000 obs | DGP: Y = 3X + 10 + {&epsilon}, {&epsilon}~N(0,15)")

graph export "${out}/fig1_beta_distribution.png", replace width(1200)
display as text "Figure saved: ${out}/fig1_beta_distribution.png"


/*------------------------------------------------------------------------------
  STEP 5b – TABLE: Summary statistics of estimates by sample size
------------------------------------------------------------------------------*/

*Compute summary stats by N 
collapse                                    ///
    (mean)   mean_beta  = sim_beta          ///
    (sd)     sd_beta    = sim_beta          ///
    (mean)   mean_sem   = sim_sem           ///
    (mean)   mean_ciw   = ci_width          ///
    (p3)     p025_beta  = sim_beta          ///
    (p97)    p975_beta  = sim_beta          ///
    ,                                       ///
    by(nominal_N)

*Derived: empirical 95% coverage width from percentiles 
gen emp_ci_width = p975_beta - p025_beta

*Format and list 
format mean_beta sd_beta mean_sem mean_ciw emp_ci_width %6.4f

list nominal_N mean_beta sd_beta mean_sem mean_ciw emp_ci_width, ///
     separator(0)                                                  ///
     noobs

drop if nominal_N == .


*Export 
export delimited "${out}/cm2020_table1_simulation_summary.csv", replace
display as text "Table saved: ${out}/cm2020_table1_simulation_summary.csv"

/*
  Defining table columns: 
    nominal_N    – target sample size used in each simulation
    mean_beta    – average beta estimate across 500 reps 
    sd_beta      – standard deviation of beta estimates across reps
    mean_sem     – average standard error reported by OLS
    mean_ciw     – average width of the 95% CI from regression output
    emp_ci_width – empirical 2.5th–97.5th pctile spread of beta estimates
*/

/*checking some things for data ID card purposes*/

codebook nominal_N

clear all
cd "/Users/cam_cew/Desktop/Experimental_design/Stata_3_assignment/part_1_output"

use "cm2020_simulation_results_q1.dta", clear
*there isn't a specific unit of observation so i will generate one

gen sim_id = _n
codebook sim_id

save "${out}/cm2020_simulation_results_q1.dta", replace



/*==============================================================================
*Name: Catherine Morris
*Class: Gui2de Spring 2026
*Assignment: Stata 3 
*Date: March 19, 2026
*Edited: March 20, 2026
*Edited: March 21, 2026

==============================================================================*/
/*==============================================================================
Part 2: Sampling Noise in an Infinite Superpopulation


Sample sizes:
  - First 20 powers of 2: 4, 8, 16, ..., 2,097,152
  - Plus: 10, 100, 1,000, 10,000, 100,000, 1,000,000
  - Total: 26 sample sizes x 500 reps = 13,000 results

==============================================================================*/

*File path ---
if c(username) == "cam_cew" {
    global path "/Users/cam_cew/Desktop/Experimental_design/Stata_3_assignment"
}
display "${path}"


/*------------------------------------------------------------------------------
  STEP 1 – Define the program
------------------------------------------------------------------------------*/

capture program drop gen_and_reg
program define gen_and_reg, rclass
   

    args sample_size

    *Generate new data set
    quietly {
        clear
        set obs `sample_size'
        gen x       = rnormal(20, 5)
        gen epsilon = rnormal(0, 15)
        gen y       = 3 * x + 10 + epsilon
        drop epsilon
    }

    *Regression of y on x 
    quietly reg y x

    *Return N, SEM, p-values, and confidence intervals in r()
    matrix results = r(table)

    return scalar N     = e(N)
    return scalar beta  = results[1, 1]
    return scalar sem   = results[2, 1]
    return scalar pval  = results[4, 1]
    return scalar ci_lo = results[5, 1]
    return scalar ci_hi = results[6, 1]

end


/*------------------------------------------------------------------------------
  STEP 2 – Run simulate at all sample sizes
------------------------------------------------------------------------------*/

local reps 500

*Building a list of the first 20 powers of 2, which we will use as sample sizes
local pow2sizes ""
forvalues k = 2/21 {
    local n = 2^`k'
    local pow2sizes "`pow2sizes' `n'"
}

*Creating additional sample sizes 
local extra "10 100 1000 10000 100000 1000000"

*Combine all sizes 
local allsizes "`pow2sizes' `extra'"

display as text "Sample sizes to simulate:"
display as text "`allsizes'"

*Creating a temp file to store results 
tempfile allresults
save `allresults', emptyok

foreach n of local sizes {
}

*Loop through every sampe of the size in the list, this block runs 26 times, one for each sample size

foreach n of local allsizes {

    display as text _newline "Running simulate: N = `n', reps = `reps' ..."

/*calling gen_and_reg 500 times at the sample size `n' and grab esult for the simulated N, beta, SEM, p-value, and confidence interval bounds*/

    simulate                            ///
        sim_N    = r(N)                 ///
        sim_beta = r(beta)              ///
        sim_sem  = r(sem)               ///
        sim_pval = r(pval)              ///
        sim_cilo = r(ci_lo)             ///
        sim_cihi = r(ci_hi),            ///
        reps(`reps') seed(20240319):    ///
        gen_and_reg `n'

/*These are then packed into a dataset of 500 rows; the loop runs 26 times, resulting in 13,000 obs*/

    gen nominal_N = `n'
    gen ci_width  = sim_cihi - sim_cilo
    gen log2_N    = log(`n') / log(2)   

    append using `allresults'
    save `allresults', replace

}

use `allresults', clear
drop if missing(nominal_N)

save "${path}/cm2020_part2_simulation_results.dta", replace
display as text "Results saved to: ${path}/cm2020_part2_simulation_results.dta"


/*Cleaning file because there are 13,004 observations when there should be 13,000*/

use "${path}/cm2020_part2_simulation_results.dta", clear
gen sim_id = _n
drop if missing(sim_beta)
count   // now there are 13,000 obs

drop mean_beta sd_beta mean_sem mean_ciw p025_beta p975_beta emp_ci_width // dropping stray variables

save "${path}/cm2020_part2_simulation_results.dta", replace


/*------------------------------------------------------------------------------
  STEP 3a – FIGURE: SD of beta estimates vs log2(N)
  Shows the 1/sqrt(N) convergence rate clearly on a log scale
------------------------------------------------------------------------------*/

/*Collapse to one row per N for the line plot*/
preserve

    collapse                            ///
        (sd)   sd_beta  = sim_beta      ///
        (mean) mean_sem = sim_sem       ///
        (mean) mean_ciw = ci_width      ///
        (mean) log2_N   = log2_N        ///
        , by(nominal_N)

    drop if missing(nominal_N)

    /*Generate theoretical 1/sqrt(N) line (scaled to match at N=4) */
    quietly summarize sd_beta if nominal_N == 4
    local scale = r(mean) * sqrt(4)
    gen theoretical = `scale' / sqrt(nominal_N)

    sort nominal_N

    twoway                                                          ///
        (line sd_beta   nominal_N, lcolor(navy)    lwidth(medthick)) ///
        (line mean_sem  nominal_N, lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
        (line theoretical nominal_N, lcolor(black) lwidth(thin) lpattern(dot)) ///
        ,                                                           ///
        xscale(log) xlabel(4 10 100 1000 10000 100000 1000000,      ///
               angle(45) labsize(small))                            ///
        legend(order(1 "Empirical SD of beta"                       ///
                     2 "Mean OLS SEM"                               ///
                     3 "Theoretical 1/√N")                          ///
               position(1) ring(0) cols(1))                         ///
        xtitle("Sample Size N (log scale)")                         ///
        ytitle("Standard Deviation / SEM")                          ///
        title("Precision of Beta Estimates vs Sample Size")         ///
        subtitle("500 simulations per N | True beta = 3")           ///
        note("DGP: Y = 3X + 10 + {&epsilon}, {&epsilon}~N(0,15)")

    graph export "${path}/cm2020_part2_fig1_precision.png",         ///
        replace width(1200)
    display as text "Figure 1 saved."

restore


/*------------------------------------------------------------------------------
  STEP 3b – FIGURE 2: Distribution of beta at selected N values
------------------------------------------------------------------------------*/

twoway                                                              ///
    (kdensity sim_beta if nominal_N == 10,      lcolor(cranberry)   lwidth(medthick)) ///
    (kdensity sim_beta if nominal_N == 100,     lcolor(navy)        lwidth(medthick)) ///
    (kdensity sim_beta if nominal_N == 1000,    lcolor(forest_green) lwidth(medthick)) ///
    (kdensity sim_beta if nominal_N == 10000,   lcolor(dkorange)    lwidth(medthick)) ///
    (kdensity sim_beta if nominal_N == 1000000, lcolor(purple)      lwidth(medthick)) ///
    ,                                                               ///
    xline(3, lcolor(black) lpattern(dash) lwidth(thin))             ///
    legend(order(1 "N=10" 2 "N=100" 3 "N=1,000"                    ///
                 4 "N=10,000" 5 "N=1,000,000")                      ///
           position(1) ring(0) cols(1))                             ///
    xtitle("Estimated Beta (OLS coefficient on X)")                 ///
    ytitle("Density")                                               ///
    title("Distribution of Beta Estimates by Sample Size")          ///
    subtitle("500 simulations per N | True beta = 3 | Infinite superpopulation") ///
    note("DGP: Y = 3X + 10 + {&epsilon}, {&epsilon}~N(0,15)")

graph export "${path}/cm2020_part2_fig2_distribution.png",          ///
    replace width(1200)
display as text "Figure 2 saved."


/*------------------------------------------------------------------------------
  STEP 3c – TABLE: Summary statistics by sample size
------------------------------------------------------------------------------*/

preserve

    collapse                                ///
        (mean) mean_beta = sim_beta         ///
        (sd)   sd_beta   = sim_beta         ///
        (mean) mean_sem  = sim_sem          ///
        (mean) mean_ciw  = ci_width         ///
        (p3)   p3_beta   = sim_beta         ///
        (p97)  p97_beta  = sim_beta         ///
        , by(nominal_N)

    drop if missing(nominal_N)

    gen emp_ci_width = p97_beta - p3_beta

    format mean_beta sd_beta mean_sem mean_ciw emp_ci_width %6.4f

    sort nominal_N

    list nominal_N mean_beta sd_beta mean_sem mean_ciw emp_ci_width, ///
         separator(0) noobs

    export delimited "${path}/cm2020_part2_table1_summary.csv", replace
    display as text "Table saved."

restore


/*==============================================================================
*Name: Catherine Morris
*Class: Gui2de Spring 2026
*Assignment: Stata 3 
*Date: March 21, 2026
==============================================================================*/
/*==============================================================================
Part 3: Power calculations for individual-level randomization

DGP requirements:
  Y ~ N(0, 1) for control group (standardized outcome)
  Treatment effect = 0.1 SD on average
  Individual effects ~ Uniform(0.0, 0.2) so average effect = 0.1 SD
  Treatment proportion = 0.5 (50% treated, 50% control)

Additional steps:
  Q3: The proportion of individuals receiving treatment should be 0.5 (i.e. half in control, and half in treatment) Calculate the number of individuals required to reach 80% power when you are trying to detect 0.1 sd treatment effect.
  Q4: Now assume, 15% of the sample will attrite (assume similar attrition rates in control and treatment arms.) How does this change your sample size calculations from the previous part?
  Q5: Now assume the intervention is very expensive and we can only afford to provide this specific treatment to 30% of the sample. How would this change the sample size needed for 80% power.
  
  
 !!!!!!!  NOTE: SEE README FILE FOR SUPPORTING FIGURES/TABLES !!!!!!!!!!!!!
==============================================================================*/

clear all

*Filepath and output folder
if c(username) == "cam_cew" {
    global path "/Users/cam_cew/Desktop/Experimental_design/Stata_3_assignment"
}
global out "${path}/part_3_output"
display "${path}"

help power twomeans
/*------------------------------------------------------------------------------
  Q3: Basic power calculation
------------------------------------------------------------------------------*/

power twomeans 0 0.1, sd(1) power(0.8) 

/*Note: the command above produces the following result

Estimated sample sizes for a two-sample means test
t test assuming sd1 = sd2 = sd
H0: m2 = m1  versus  Ha: m2 != m1

Study parameters:

        alpha =    0.0500
        power =    0.8000
        delta =    0.1000
           m1 =    0.0000
           m2 =    0.1000
           sd =    1.0000

Estimated sample sizes:

            N =     3,142
  N per group =     1,571

  Validating this, half are in treatment, half in control
  */

*Storing the required N
local N_basic = r(N)
display as text "N required: " `N_basic'


capture program drop power_sim
program define power_sim, rclass
    args sample_size treat_prop

    quietly {
        clear
        set obs `sample_size'

        *Assign treatment (treat_prop share gets treatment) 
        gen rand = runiform()
        gen treatment = rand <= `treat_prop'

        *Generate individual treatment effects ~ Uniform(0, 0.2) 
        gen indiv_effect = runiform(0, 0.2)

        *Generate outcome Y 
        *   Control: Y ~ N(0, 1)
        *   Treatment: Y ~ N(0 + indiv_effect, 1)
        gen y = rnormal(0, 1) + treatment * indiv_effect

        *Regress y on treatment 
        reg y treatment

        *Store results 
        matrix results = r(table)
        return scalar N     = e(N)
        return scalar beta  = results[1, 1]
        return scalar pval  = results[4, 1]
        return scalar sig   = (results[4, 1] < 0.05)  // 1 if significant
    }
end


*Run 1000 simulations at the analytical N, 50/50 split 
display as text _newline "Simulating power at N = " `N_basic' " ..."

simulate                            ///
    sim_N    = r(N)                 ///
    sim_beta = r(beta)              ///
    sim_pval = r(pval)              ///
    sim_sig  = r(sig),              ///
    reps(1000) seed(20240319):      ///
    power_sim `N_basic' 0.5

*Empirical power = proportion of simulations where p < 0.05 
summarize sim_sig

/*    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
     sim_sig |      1,000        .799    .4009486          0          1

Note: The mean of .799 puts us very close to 80%
	 */
local emp_power_basic = r(mean)
display as text "Empirical power at N = " `N_basic' ": " %4.3f `emp_power_basic'

save "${out}/part3_q3_simresults.dta", replace


/*------------------------------------------------------------------------------
  Q4: Adjust for 15% attrition
  If 15% drop out, we need to recruit more upfront to end up with N_basic
------------------------------------------------------------------------------*/

*Analytical adjustment 
*   If 15% attrite, we retain 85% of recruited sample
*   So: N_recruit = N_basic / 0.85

local N_attrition = ceil(`N_basic' / 0.85)
display as text _newline "N required with 15% attrition: " `N_attrition'
display as text "(Recruited " `N_attrition' " to end up with ~" `N_basic' " after 15% dropout)"

*Verify with simulation 
*Simulate attrition by randomly dropping 15% of sample
capture program drop power_sim_attrition
program define power_sim_attrition, rclass
    args sample_size treat_prop attrition_rate

    quietly {
        clear
        set obs `sample_size'

        *Assign treatment --
        gen rand = runiform()
        gen treatment = rand <= `treat_prop'

        *Simulate attrition: randomly drop attrition_rate share 
        gen attrite = runiform() <= `attrition_rate'
        drop if attrite == 1

        *Generate individual treatment effects ~ Uniform(0, 0.2) 
        gen indiv_effect = runiform(0, 0.2)

        *Generate outcome 
        gen y = rnormal(0, 1) + treatment * indiv_effect

        *Regress 
        reg y treatment

        matrix results = r(table)
        return scalar N    = e(N)
        return scalar beta = results[1, 1]
        return scalar pval = results[4, 1]
        return scalar sig  = (results[4, 1] < 0.05)
    }
end

display as text _newline "Simulating power with attrition at N = " `N_attrition' " ..."

simulate                                    ///
    sim_N    = r(N)                         ///
    sim_beta = r(beta)                      ///
    sim_pval = r(pval)                      ///
    sim_sig  = r(sig),                      ///
    reps(1000) seed(20240319):              ///
    power_sim_attrition `N_attrition' 0.5 0.15

summarize sim_sig
local emp_power_attrition = r(mean)
display as text "Empirical power with attrition at N = " `N_attrition' ": " %4.3f `emp_power_attrition'

save "${out}/part3_q4_simresults.dta", replace



/*------------------------------------------------------------------------------
  Q5: Unequal treatment proportion (30% treated, 70% control)
  Unequal splits reduce power, so we need a larger sample
------------------------------------------------------------------------------*/

*Analytical power calculation with 30/70 split 
*ratio = N_control / N_treatment = 0.70/0.30 = 2.333
local ratio = 0.70 / 0.30

power twomeans 0 0.1, sd(1) power(0.8) nratio(`ratio')

local N_unequal = r(N)
display as text _newline "N required with 30% treatment proportion: " `N_unequal'

*Verify with simulation 
display as text _newline "Simulating power with 30% treatment at N = " `N_unequal' " ..."

simulate                            ///
    sim_N    = r(N)                 ///
    sim_beta = r(beta)              ///
    sim_pval = r(pval)              ///
    sim_sig  = r(sig),              ///
    reps(1000) seed(20240319):      ///
    power_sim `N_unequal' 0.3

summarize sim_sig
local emp_power_unequal = r(mean)
display as text "Empirical power with 30% treatment at N = " `N_unequal' ": " %4.3f `emp_power_unequal'

save "${out}/cm2020_part3_q5_simresults.dta", replace


/*------------------------------------------------------------------------------
  Summary table
------------------------------------------------------------------------------*/

clear
set obs 3

gen scenario     = ""
gen N_required   = .
gen treat_prop   = .
gen attrition    = .
gen emp_power    = .

replace scenario   = "Q3: Basic (50/50, no attrition)"  in 1
replace scenario   = "Q4: 15% attrition (50/50)"        in 2
replace scenario   = "Q5: 30% treatment proportion"      in 3

replace N_required = `N_basic'      in 1
replace N_required = `N_attrition'  in 2
replace N_required = `N_unequal'    in 3

replace treat_prop = 0.50 in 1
replace treat_prop = 0.50 in 2
replace treat_prop = 0.30 in 3

replace attrition  = 0.00 in 1
replace attrition  = 0.15 in 2
replace attrition  = 0.00 in 3

replace emp_power  = `emp_power_basic'      in 1
replace emp_power  = `emp_power_attrition'  in 2
replace emp_power  = `emp_power_unequal'    in 3

list scenario N_required treat_prop attrition emp_power, noobs separator(0)

/*  +-----------------------------------------------------------------------------+
  |                        scenario   N_requ~d   treat_~p   attrit~n   emp_po~r |
  |-----------------------------------------------------------------------------|
  | Q3: Basic (50/50, no attrition)       3142         .5          0       .799 |
  |       Q4: 15% attrition (50/50)       3697         .5        .15       .805 |
  |    Q5: 30% treatment proportion       3740         .3          0       .814 |
  +-----------------------------------------------------------------------------+
 
 Takeaways:
 
*Attrition increases required sample size by about 18% (3,142 → 3,697)
*Unequal treatment proportion increases required sample size by about 19% (3,142 → 3,740)
*Both adjustments push us 80% power in the simulations
*/

export delimited "${out}/cm2020_part3_summary_table.csv", replace
display as text "Summary table saved."



/*==============================================================================
*Name: Catherine Morris
*Class: Gui2de Spring 2026
*Assignment: Stata 3 
*Date: March 21, 2026
==============================================================================*/
/*==============================================================================
Part 4: Power Calculations for Cluster Randomization

DGP:
  Y = math score for each individual student
  Treatment assigned at school level (cluster randomization)
  ICC (rho) ~ 0.3 — students within same school are correlated
  Treatment effect = 0.2 SD on average
  Individual effects ~ Uniform(0.15, 0.25) so average effect = 0.2 SD
  Treatment proportion = 0.5 (half schools treated, half control)

Questions:
  Q5: Holding the number of clusters fixed at 200, what happens to the power when you increase the cluster size (use first 10 powers of 2) What cluster size would you recommend and why?
  
  A: 64 students per school is the optimal cluster size. After this, power peaks, meaning that adding more students does not offer any gains but will increase the cost of the study. 
  
  
  Q6: Now hold the cluster size fixed (15 students/school). How many schools do you need in your RCT to get 80% to detect 0.2 sd treatment effect.
  
  A: Power crosses the 80% threshold between 250 and 300 schools, as shown in the figure. To attempt to isolate the true answer, I ran a narrower simulation.

| Schools (Clusters) | Empirical Power |
|---|---|
| 250 | 76.2% |
| 260 | 81.2% |
| 270 | 79.8% |
| 280 | 78.8% |
| 290 | 84.0% |
| 300 | 84.8% |

As you can see, the resulting empirical power values vary quite a bit likely due to simulation noise. This make is dificult to pinpoint where the 80% threshold is exactly, but it is likely somewhere within 260-280 schools. Conservatively, we can say that it would be at 280 schools.   
  
  
  Q7: Now assume that only 70% of the schools actually adopt your treatment. How many schools do you need now to get 80% power?
  
  A: Power crosses the 80% threshold somewhere between 550 and 600 schools
  
!!!!!!!  NOTE: SEE README FILE FOR SUPPORTING FIGURES/TABLES !!!!!!!!!!!!!
==============================================================================*/
clear all

*--- File path ---
if c(username) == "cam_cew" {
    global path "/Users/cam_cew/Desktop/Experimental_design/Stata_3_assignment"
}
global out "${path}/part_4_output"
display "${path}"


/*------------------------------------------------------------------------------
  STEP 1 — Define the cluster randomization program

  How ICC = 0.3 is achieved:
  Total variance = between-school variance + within-school variance
  ICC = between / (between + within)
  
  We set:
    - within-school SD  = sqrt(0.7) so within variance = 0.7
    - between-school SD = sqrt(0.3) so between variance = 0.3
    - Total variance = 1.0, ICC = 0.3/1.0 = 0.3
------------------------------------------------------------------------------*/

capture program drop cluster_sim
program define cluster_sim, rclass
    /*
    Arguments:
      `1' — number of clusters (schools)
      `2' — cluster size (students per school)
    */

    args n_clusters cluster_size

    quietly {

        *-- Total observations --
        local N = `n_clusters' * `cluster_size'
        local half_clusters = `n_clusters' / 2

        clear
        set obs `n_clusters'

        *-- Assign treatment at school level (50/50 split) --
        gen school_id = _n
        gen rand = runiform()
        egen rank = rank(rand)
        gen treatment = rank <= `half_clusters'

        *-- Generate school-level random effect (between-school variation) --
        *   Between-school SD = sqrt(0.3) to achieve ICC = 0.3
        gen school_effect = rnormal(0, sqrt(0.3))

        *-- Generate school-level treatment effect ~ Uniform(0.15, 0.25) --
        gen treat_effect = runiform(0.15, 0.25)

        *-- Expand to student level --
        expand `cluster_size'

        *-- Generate student-level outcome --
        *   Within-school SD = sqrt(0.7) to achieve ICC = 0.3
        *   Y = school_effect + treatment_effect (if treated) + student_noise
        gen y = school_effect                           ///
              + treatment * treat_effect                ///
              + rnormal(0, sqrt(0.7))

        *-- Cluster-robust regression --
        reg y treatment, vce(cluster school_id)

        *-- Extract results --
        matrix results = r(table)
        return scalar N        = e(N)
        return scalar beta     = results[1, 1]
        return scalar sem      = results[2, 1]
        return scalar pval     = results[4, 1]
        return scalar ci_lo    = results[5, 1]
        return scalar ci_hi    = results[6, 1]
        return scalar sig      = (results[4, 1] < 0.05)

    }
end


/*------------------------------------------------------------------------------
  Q5: Hold clusters = 200, vary cluster size (first 10 powers of 2)
  Powers of 2: 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024
------------------------------------------------------------------------------*/

display as text _newline "=== Q5: Varying cluster size, clusters fixed at 200 ==="

local n_clusters_q5 = 200
local reps = 500

*-- Build list of first 10 powers of 2 --
local pow2sizes ""
forvalues k = 1/10 {
    local n = 2^`k'
    local pow2sizes "`pow2sizes' `n'"
}
display as text "Cluster sizes to simulate: `pow2sizes'"

*-- Accumulate results --
tempfile q5results
clear
save `q5results', emptyok

foreach cs of local pow2sizes {

    display as text _newline "Simulating: 200 clusters, cluster size = `cs' ..."

    simulate                                ///
        sim_N    = r(N)                     ///
        sim_beta = r(beta)                  ///
        sim_sem  = r(sem)                   ///
        sim_pval = r(pval)                  ///
        sim_sig  = r(sig),                  ///
        reps(`reps') seed(20240319):        ///
        cluster_sim `n_clusters_q5' `cs'

    gen n_clusters   = `n_clusters_q5'
    gen cluster_size = `cs'
    gen total_N      = `n_clusters_q5' * `cs'

    append using `q5results'
    save `q5results', replace

}

use `q5results', clear
drop if missing(sim_beta)

save "${out}/part4_q5_simresults.dta", replace

*-- Collapse to get power by cluster size --
preserve

    collapse (mean) power = sim_sig, by(cluster_size total_N n_clusters)
    drop if missing(cluster_size)
    sort cluster_size

    list cluster_size total_N power, noobs separator(0)
    export delimited "${out}/part4_q5_power_table.csv", replace
    display as text "Q5 table saved."

    *-- Figure: Power vs cluster size --
    twoway                                                          ///
        (line power cluster_size,                                   ///
            lcolor(navy) lwidth(medthick))                          ///
        ,                                                           ///
        yline(0.8, lcolor(red) lpattern(dash))                     ///
        xlabel(2 4 8 16 32 64 128 256 512 1024, angle(45))         ///
        xtitle("Cluster Size (Students per School)")                ///
        ytitle("Empirical Power")                                   ///
        title("Power vs Cluster Size")                             ///
        subtitle("200 schools | 500 simulations | True effect = 0.2 SD") ///
        note("Dashed line = 80% power threshold" ///
             "DGP: ICC = 0.3, Y = school effect + treatment effect + noise")

    graph export "${out}/part4_q5_power_figure.png", replace width(1200)
    display as text "Q5 figure saved."

restore


/*------------------------------------------------------------------------------
  Q6: Hold cluster size = 15, find number of schools for 80% power
  Try a range of school counts and find where power crosses 80%
------------------------------------------------------------------------------*/

display as text _newline "=== Q6: Varying number of schools, cluster size fixed at 15 ==="

local cluster_size_q6 = 15

*-- Try a range of school counts (must be even for 50/50 split) --
local school_counts "20 40 60 80 100 120 140 160 180 200 250 300"

tempfile q6results
clear
save `q6results', emptyok

foreach nc of local school_counts {

    display as text _newline "Simulating: `nc' schools, cluster size = 15 ..."

    simulate                                ///
        sim_N    = r(N)                     ///
        sim_beta = r(beta)                  ///
        sim_sem  = r(sem)                   ///
        sim_pval = r(pval)                  ///
        sim_sig  = r(sig),                  ///
        reps(`reps') seed(20240319):        ///
        cluster_sim `nc' `cluster_size_q6'

    gen n_clusters   = `nc'
    gen cluster_size = `cluster_size_q6'
    gen total_N      = `nc' * `cluster_size_q6'

    append using `q6results'
    save `q6results', replace

}

use `q6results', clear
drop if missing(sim_beta)

save "${out}/part4_q6_simresults.dta", replace

*-- Collapse to get power by number of schools --
preserve

    collapse (mean) power = sim_sig, by(n_clusters total_N cluster_size)
    drop if missing(n_clusters)
    sort n_clusters

    list n_clusters total_N power, noobs separator(0)
    export delimited "${out}/part4_q6_power_table.csv", replace
    display as text "Q6 table saved."

    *-- Figure: Power vs number of schools --
    twoway                                                          ///
        (line power n_clusters,                                     ///
            lcolor(navy) lwidth(medthick))                          ///
        ,                                                           ///
        yline(0.8, lcolor(red) lpattern(dash))                     ///
        xtitle("Number of Schools (Clusters)")                      ///
        ytitle("Empirical Power")                                   ///
        title("Power vs Number of Schools")                        ///
        subtitle("15 students/school | 500 simulations | True effect = 0.2 SD") ///
        note("Dashed line = 80% power threshold" ///
             "DGP: ICC = 0.3, Y = school effect + treatment effect + noise")

    graph export "${out}/part4_q6_power_figure.png", replace width(1200)
    display as text "Q6 figure saved."

restore


/*------------------------------------------------------------------------------
  Q7: Only 70% of treated schools actually adopt treatment
  Non-adopting schools receive treatment assignment but no actual treatment
  This is "non-compliance" — it dilutes the treatment effect
  Need more schools to maintain 80% power
------------------------------------------------------------------------------*/

display as text _newline "=== Q7: 70% compliance among treated schools ==="

capture program drop cluster_sim_compliance
program define cluster_sim_compliance, rclass
    /*
    Arguments:
      `1' — number of clusters (schools)
      `2' — cluster size (students per school)
      `3' — compliance rate (proportion of treated schools that adopt)
    */

    args n_clusters cluster_size compliance_rate

    quietly {

        local half_clusters = `n_clusters' / 2

        clear
        set obs `n_clusters'

        gen school_id = _n
        gen rand = runiform()
        egen rank = rank(rand)
        gen treatment_assigned = rank <= `half_clusters'

        *-- Only compliance_rate share of treated schools actually adopt --
        gen actually_treated = treatment_assigned * (runiform() <= `compliance_rate')

        *-- School-level random effect --
        gen school_effect = rnormal(0, sqrt(0.3))

        *-- Treatment effect only for schools that actually adopt --
        gen treat_effect = runiform(0.15, 0.25)

        *-- Expand to student level --
        expand `cluster_size'

        *-- Generate outcome --
        gen y = school_effect                               ///
              + actually_treated * treat_effect             ///
              + rnormal(0, sqrt(0.7))

        *-- Regression uses ASSIGNED treatment (intent-to-treat) --
        reg y treatment_assigned, vce(cluster school_id)

        matrix results = r(table)
        return scalar N     = e(N)
        return scalar beta  = results[1, 1]
        return scalar pval  = results[4, 1]
        return scalar sig   = (results[4, 1] < 0.05)

    }
end

*-- Try a range of school counts with 70% compliance --
local school_counts_q7 "60 80 100 120 140 160 180 200 250 300 350 400"

tempfile q7results
clear
save `q7results', emptyok

foreach nc of local school_counts_q7 {

    display as text _newline "Simulating: `nc' schools, 70% compliance ..."

    simulate                                        ///
        sim_N    = r(N)                             ///
        sim_beta = r(beta)                          ///
        sim_pval = r(pval)                          ///
        sim_sig  = r(sig),                          ///
        reps(`reps') seed(20240319):                ///
        cluster_sim_compliance `nc' 15 0.70

    gen n_clusters   = `nc'
    gen cluster_size = 15
    gen compliance   = 0.70

    append using `q7results'
    save `q7results', replace

}

use `q7results', clear
drop if missing(sim_beta)

save "${out}/part4_q7_simresults.dta", replace

*-- Collapse to get power by number of schools --
preserve

    collapse (mean) power = sim_sig, by(n_clusters cluster_size compliance)
    drop if missing(n_clusters)
    sort n_clusters

    list n_clusters power, noobs separator(0)
    export delimited "${out}/part4_q7_power_table.csv", replace
    display as text "Q7 table saved."

    *-- Figure: Power vs number of schools at 70% compliance --
	twoway                                                          ///
    (line power n_clusters,                                     ///
        lcolor(cranberry) lwidth(medthick))                     ///
    ,                                                           ///
    yline(0.8, lcolor(red) lpattern(dash))                     ///
    xtitle("Number of Schools (Clusters)")                      ///
    ytitle("Empirical Power")                                   ///
    title("Power vs Number of Schools (70% Compliance)")       ///
    subtitle("15 students/school | 500 simulations | True effect = 0.2 SD") ///
    note("Dashed line = 80% power threshold" ///
         "DGP: ICC = 0.3, 70% of treated schools adopt treatment")

	graph export "${out}/part4_q7_power_figure.png", replace width(1200)

restore

**Figure for q5 came out a little wonky, fixing

use "${out}/part4_q5_simresults.dta", clear
collapse (mean) power = sim_sig, by(cluster_size total_N n_clusters)
drop if missing(cluster_size)
sort cluster_size

twoway                                                          ///
    (line power cluster_size,                                   ///
        lcolor(navy) lwidth(medthick))                          ///
    ,                                                           ///
    yline(0.8, lcolor(red) lpattern(dash))                     ///
    xscale(log)                                                 ///
    xlabel(2 4 8 16 32 64 128 256 512 1024, angle(45) labsize(small)) ///
    xtitle("Cluster Size (Students per School, log scale)")     ///
    ytitle("Empirical Power")                                   ///
    title("Power vs Cluster Size")                             ///
    subtitle("200 schools | 500 simulations | True effect = 0.2 SD") ///
    note("Dashed line = 80% power threshold" ///
         "DGP: ICC = 0.3, Y = school effect + treatment effect + noise")

graph export "${out}/part4_q5_power_figure.png", replace width(1200)


**identifying the school range for q6

*--- Narrow search: 250-300 schools, cluster size = 15 ---
local cluster_size_q6 = 15
local reps = 500

capture program drop cluster_sim
program define cluster_sim, rclass
    args n_clusters cluster_size
    quietly {
        local half_clusters = `n_clusters' / 2
        clear
        set obs `n_clusters'
        gen school_id = _n
        gen rand = runiform()
        egen rank = rank(rand)
        gen treatment = rank <= `half_clusters'
        gen school_effect = rnormal(0, sqrt(0.3))
        gen treat_effect = runiform(0.15, 0.25)
        expand `cluster_size'
        gen y = school_effect + treatment * treat_effect + rnormal(0, sqrt(0.7))
        reg y treatment, vce(cluster school_id)
        matrix results = r(table)
        return scalar N    = e(N)
        return scalar beta = results[1, 1]
        return scalar pval = results[4, 1]
        return scalar sig  = (results[4, 1] < 0.05)
    }
end

tempfile narrowresults
clear
save `narrowresults', emptyok

foreach nc in 250 260 270 280 290 300 {
    display as text "Simulating: `nc' schools ..."
    simulate sim_sig = r(sig), reps(`reps') seed(20240319): ///
        cluster_sim `nc' `cluster_size_q6'
    gen n_clusters = `nc'
    append using `narrowresults'
    save `narrowresults', replace
}

use `narrowresults', clear
collapse (mean) power = sim_sig, by(n_clusters)
sort n_clusters
list n_clusters power, noobs separator(0)

***completing q7 with narrowe school range 
local cluster_size_q7 = 15
local reps = 500

tempfile q7extended
clear
save `q7extended', emptyok

foreach nc in 400 450 500 550 600 650 700 750 800 {
    display as text "Simulating: `nc' schools, 70% compliance ..."
    simulate sim_sig = r(sig), reps(`reps') seed(20240319): ///
        cluster_sim_compliance `nc' `cluster_size_q7' 0.70
    gen n_clusters = `nc'
    append using `q7extended'
    save `q7extended', replace
}

use `q7extended', clear
collapse (mean) power = sim_sig, by(n_clusters)
sort n_clusters
list n_clusters power, noobs separator(0)

***checking for data ID card purposes, will not add identifying var_name for the unit of observation, but if you want you can use similar code as above

use "/Users/cam_cew/Desktop/Experimental_design/Stata_3_assignment/part_4_output/part4_q5_simresults.dta"

 use "/Users/cam_cew/Desktop/Experimental_design/Stata_3_assignment/part_4_output/part4_q6_simresults.dta"
 
 use "/Users/cam_cew/Desktop/Experimental_design/Stata_3_assignment/part_4_output/part4_q7_simresults.dta"
