/*
PPOL 6818 - Experimental Design
Aqsa Zaidi
Stata Assignment 3
22 March 2026

Purpose:
    Part 1 -- Creates a fixed population of 10,000 observations from a known
              DGP and saves it as population.dta. Simulates OLS regressions
              on subsamples (N = 10, 100, 1,000, 10,000) to show sampling noise.
    Part 2 -- Simulates OLS from an infinite superpopulation (fresh data each
              rep) across 26 sample sizes up to N = 1,000,000. Compares
              fixed-population vs superpopulation sampling variation.
    Part 3 -- Power calculations for individual-level randomization.
              Analytical N for 80% power (ATE = 0.1 SD) under three scenarios:
              base case, 15% attrition, and 30% treatment proportion.
              Validates with a simulation-based power curve.
    Part 4 -- Power calculations for cluster (school-level) randomization.
              DGP with ICC = 0.3. Varies cluster size (holding N_clusters=200),
              number of clusters (holding cluster_size=15), and compliance
              rate (70%). Uses simulate with cluster-robust standard errors.

DGP (Parts 1 & 2):
    X ~ N(0, 1)
    Y = 2 + 3*X + e,   e ~ N(0, 2)
    True beta = 3, true intercept = 2

DGP (Parts 3 & 4):
    Part 3: Control Y ~ N(0,1); treatment Y = tau_i + N(0,1), tau_i ~ U(0.0,0.2)
            Average treatment effect = 0.1 SD
    Part 4: Y_ij = u_j + tau_j*T_j + N(0,1);  u_j ~ N(0, sqrt(0.3/0.7))
            ICC = 0.3; average treatment effect = 0.2 SD; tau_j ~ U(0.15,0.25)
*/


* ============================================================
* PART 1: CREATE FIXED POPULATION AND GENERATE SIMULATIONS
* ============================================================

* -----------------------------------------------
* 1) Create the fixed population
* -----------------------------------------------
clear all

* Set seed -- ensures the same population is generated every run
set seed 42

* Create 10,000 observations
set obs 10000

* Generate predictor X from standard normal distribution
gen X = rnormal(0, 1)
label variable X "Independent variable (X ~ N(0,1))"

* Generate outcome Y using the true DGP: Y = 2 + 3X + error
gen Y = 2 + 3*X + rnormal(0, 2)
label variable Y "Outcome variable (Y = 2 + 3X + e, e ~ N(0,2))"

label data "Fixed population (N=10,000) | True beta=3, intercept=2 | Seed=42"

* Verify DGP -- OLS on full population should recover true parameters closely
display as text _newline "--- Verification: OLS on full population ---"
regress Y X

* Save the fixed population
save "population.dta", replace

display as text _newline "population.dta saved with `= _N' observations."


* -----------------------------------------------
*2) Define and run the program
* -----------------------------------------------

/*
    reg_sample is an rclass program that takes one argument (n_size).
    It loads the fixed population, draws a random subsample of size n_size,
    runs OLS, and returns 6 scalars into r():
        r(N)      -- sample size used in regression
        r(beta)   -- OLS coefficient on X
        r(sem)    -- standard error of beta
        r(pval)   -- two-sided p-value for X
        r(ci_lo)  -- lower bound of 95% CI
        r(ci_hi)  -- upper bound of 95% CI

    NOTE: seed() is placed on the simulate line, not inside the program.
    Placing set seed inside the program would cause every repetition to use
    the same random draw, producing 500 identical results per batch.
*/

capture program drop reg_sample
program define reg_sample, rclass
    args n_size

    * (a) Load the fixed population
    use "population.dta", clear

    * (b) Randomly sample n_size observations without replacement
    sample `n_size', count

    * (c) Regress Y on X
    quietly regress Y X

    * Capture r(table) immediately -- cleared by subsequent commands
    * Row index: 1=coef, 2=se, 3=t, 4=p, 5=ci_lower, 6=ci_upper
    * Column 1 = X (first regressor)
    mat a = r(table)

    * (d) Return results into r()
    return scalar N     = e(N)
    return scalar beta  = _b[X]
    return scalar sem   = _se[X]
    return scalar pval  = a[4, 1]
    return scalar ci_lo = a[5, 1]
    return scalar ci_hi = a[6, 1]

end


* --- N = 10 ---
display as text _newline "Running simulate: N = 10 (500 reps)..."
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
    reps(500) seed(1001) nodots: reg_sample 10
gen sample_size = 10
tempfile s10
save `s10'

* --- N = 100 ---
display as text _newline "Running simulate: N = 100 (500 reps)..."
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
    reps(500) seed(1002) nodots: reg_sample 100
gen sample_size = 100
tempfile s100
save `s100'

* --- N = 1,000 ---
display as text _newline "Running simulate: N = 1,000 (500 reps)..."
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
    reps(500) seed(1003) nodots: reg_sample 1000
gen sample_size = 1000
tempfile s1000
save `s1000'

* --- N = 10,000 (full population) ---
display as text _newline "Running simulate: N = 10,000 (500 reps)..."
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
    reps(500) seed(1004) nodots: reg_sample 10000
gen sample_size = 10000

* Append all four batches into one dataset
append using `s1000'
append using `s100'
append using `s10'

sort sample_size

* Label variables
label variable sample_size "Sample size drawn from fixed population"
label variable N           "Observations used in regression"
label variable beta        "OLS estimate of beta (coefficient on X)"
label variable sem         "Standard error of beta estimate"
label variable pval        "Two-sided p-value for H0: beta = 0"
label variable ci_lo       "Lower bound of 95% CI for beta"
label variable ci_hi       "Upper bound of 95% CI for beta"

label data "Simulation results: 500 reps x 4 sample sizes = 2,000 rows"

save "simulation_results.dta", replace

display as text _newline "simulation_results.dta saved with `= _N' observations."

* ------------------------------------------
*3) Figure and Table
* ------------------------------------------

use "simulation_results.dta", clear

* --- Figure: Overlaid kernel density of beta estimates by N ---
twoway ///
    (kdensity beta if sample_size == 10,    lcolor(red)    lwidth(medthick) lpattern(solid)) ///
    (kdensity beta if sample_size == 100,   lcolor(orange) lwidth(medthick) lpattern(solid)) ///
    (kdensity beta if sample_size == 1000,  lcolor(blue)   lwidth(medthick) lpattern(solid)) ///
    (kdensity beta if sample_size == 10000, lcolor(green)  lwidth(medthick) lpattern(solid)), ///
    xline(3, lcolor(black) lpattern(dash) lwidth(medium))  ///
    legend(order(1 "N = 10" 2 "N = 100" 3 "N = 1,000" 4 "N = 10,000") ///
           position(1) ring(0) cols(1) size(small))        ///
    xtitle("Estimated Beta (OLS Coefficient on X)", size(medsmall))  ///
    ytitle("Density", size(medsmall))                       ///
    title("Sampling Distribution of OLS Beta Estimates", size(medium))  ///
    subtitle("500 simulations per N | Fixed population of 10,000 | True beta = 3", size(small)) ///
    note("DGP: Y = 2 + 3X + {&epsilon}, X~N(0,1), {&epsilon}~N(0,2)", size(vsmall)) ///
    scheme(s2color)

graph export "fig1_beta_density.png", replace width(1200)

display as text _newline "fig1_beta_density.png exported."


* --- Table: Summary statistics by sample size ---

gen ci_width = ci_hi - ci_lo
gen rejected = (pval < 0.05)

preserve
collapse ///
    (mean)   mean_beta   = beta      ///
    (sd)     sd_beta     = beta      ///
    (mean)   mean_sem    = sem       ///
    (mean)   mean_ciw    = ci_width  ///
    (mean)   power       = rejected  ///
    , by(sample_size)

format mean_beta sd_beta mean_sem mean_ciw %7.4f
format power %5.3f

display as text _newline "======================================================="
display as text "Table 1: Simulation Results by Sample Size (True beta = 3)"
display as text "======================================================="
display as text "N       | Mean Beta | SD Beta | Mean SEM | Mean CI Width | Power"
display as text "--------|-----------|---------|----------|---------------|------"

forvalues i = 1/`= _N' {
    local n   = sample_size[`i']
    local mb  = string(mean_beta[`i'],  "%7.4f")
    local sdb = string(sd_beta[`i'],    "%7.4f")
    local ms  = string(mean_sem[`i'],   "%7.4f")
    local mcw = string(mean_ciw[`i'],   "%7.4f")
    local pw  = string(power[`i'],      "%5.3f")
    display as text "`n'" _col(9) "| `mb'" _col(20) "| `sdb'" _col(29) "| `ms'" _col(39) "| `mcw'" _col(54) "| `pw'"
}

display as text "======================================================="
display as text "Notes: Power = proportion of reps with p < 0.05"
display as text "       Mean SEM ≈ SD Beta validates the OLS SE formula"

restore

display as text _newline "Part 1 done. All Part 1 outputs saved."


* ============================================================
* PART 2: SAMPLING NOISE IN AN INFINITE SUPERPOPULATION
* ============================================================
/*
    KEY DIFFERENCE FROM PART 1:

    In Part 1, we sampled WITHOUT REPLACEMENT from a FIXED population of
    10,000 people. That population never changes -- it is the same 10,000
    rows saved in population.dta. The maximum sample you can ever draw is
    10,000 (the whole population), and once you do, the estimate has zero
    sampling variance because there is nothing left to chance.

    In Part 2, we draw from an imagined INFINITE SUPERPOPULATION by
    generating BRAND-NEW data from the DGP at each repetition. There is no
    stored population to exhaust, so N can be as large as we like -- we run
    simulations up to N = 1,000,000 below.

    This is the conceptual difference between:
        Part 1 -- finite-population / design-based inference (like a survey)
        Part 2 -- model-based / superpopulation inference (like an experiment
                  you could in principle repeat infinitely many times)

    Why might the SEM differ at common N values between Part 1 and Part 2?
    Sampling without replacement from a finite population introduces a
    FINITE POPULATION CORRECTION (FPC): Var(beta) is multiplied by (1 - n/N).
    At n=10 out of N=10,000 the FPC is 0.999 -- negligible.
    At n=1,000 the FPC is 0.9 -- SEMs in Part 1 are sqrt(0.9)≈5% smaller.
    At n=10,000 (=N) the FPC is 0 -- variance vanishes entirely.
    In Part 2 there is no FPC, so SEMs follow the pure 1/sqrt(N) formula.
*/


* --- Program definition ---
/*
    gen_superpop generates a fresh dataset of n_size observations from
    the same DGP used in Part 1 (X~N(0,1), Y=2+3X+e, e~N(0,2)), runs
    OLS, and returns the same six scalars as reg_sample in Part 1.
    The only difference: it creates data rather than loading population.dta.
*/
capture program drop gen_superpop
program define gen_superpop, rclass
    args n_size

    * (a) Generate a fresh dataset of n_size observations
    clear
    set obs `n_size'
    gen X = rnormal(0, 1)
    gen Y = 2 + 3*X + rnormal(0, 2)

    * (b) Regress Y on X
    quietly regress Y X

    * Capture r(table) immediately before anything else clears it
    * Rows: 1=coef 2=se 3=t 4=p 5=ci_lo 6=ci_hi | Col 1 = X
    mat a = r(table)

    * (c) Return results into r()
    return scalar N     = e(N)
    return scalar beta  = _b[X]
    return scalar sem   = _se[X]
    return scalar pval  = a[4, 1]
    return scalar ci_lo = a[5, 1]
    return scalar ci_hi = a[6, 1]

end


* --- Define all 26 sample sizes ---
* First 20 powers of 2: 2^1 = 2 through 2^20 = 1,048,576
local pow2  "2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576"
* Six powers of 10: 10 through 1,000,000
local pow10 "10 100 1000 10000 100000 1000000"
* Combined list -- 26 total; 26 × 500 = 13,000 regression results
local all_sizes "`pow2' `pow10'"


* --- Simulate across all 26 sample sizes ---
* Following the tempfile + append pattern from week_08_simulations.do:
* start with an empty file, then grow it one batch at a time.
clear
tempfile p2_results
save `p2_results', emptyok

* Seeds run from 2001 to 2026 (one per sample size, placed on simulate
* line -- NOT inside the program, which would make all 500 reps identical)
local seed_p2 = 2001

foreach n of local all_sizes {

    display as text _newline "Running simulate: N = `n' (500 reps)..."

    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ///
             ci_lo=r(ci_lo) ci_hi=r(ci_hi),               ///
        reps(500) seed(`seed_p2') nodots: gen_superpop `n'

    gen sample_size = `n'

    append using `p2_results'
    save `p2_results', replace

    local seed_p2 = `seed_p2' + 1
}

use `p2_results', clear
sort sample_size

label variable sample_size "Sample size (fresh draw from superpopulation)"
label variable N           "Observations used in regression"
label variable beta        "OLS estimate of beta (coefficient on X)"
label variable sem         "Standard error of beta estimate"
label variable pval        "Two-sided p-value for H0: beta = 0"
label variable ci_lo       "Lower bound of 95% CI for beta"
label variable ci_hi       "Upper bound of 95% CI for beta"

label data "Part 2: Superpopulation simulation | 500 reps x 26 N values = 13,000 rows"

save "simulation_results_p2.dta", replace

display as text _newline "simulation_results_p2.dta saved with `= _N' observations."


* ------------------------------------------------
*2) Figures
* -------------------------------------------------

use "simulation_results_p2.dta", clear

* Derived variables used in both figures and table
gen ci_width = ci_hi - ci_lo
gen rejected = (pval < 0.05)


* --- Figure 2: kdensity overlay for 6 representative N values ---
* Six N values chosen to span the full range of the simulation:
* N=4 (tiny), N=64, N=1024, N=16384, N=262144, N=1000000 (huge)
twoway ///
    (kdensity beta if sample_size == 4,       lcolor(red)     lwidth(medium) lpattern(solid)) ///
    (kdensity beta if sample_size == 64,      lcolor(orange)  lwidth(medium) lpattern(solid)) ///
    (kdensity beta if sample_size == 1024,    lcolor(dkgreen) lwidth(medium) lpattern(solid)) ///
    (kdensity beta if sample_size == 16384,   lcolor(blue)    lwidth(medium) lpattern(solid)) ///
    (kdensity beta if sample_size == 262144,  lcolor(purple)  lwidth(medium) lpattern(solid)) ///
    (kdensity beta if sample_size == 1000000, lcolor(black)   lwidth(medium) lpattern(solid)), ///
    xline(3, lcolor(black) lpattern(dash) lwidth(medium))                                      ///
    legend(order(1 "N = 4" 2 "N = 64" 3 "N = 1,024"                                           ///
                 4 "N = 16,384" 5 "N = 262,144" 6 "N = 1,000,000")                            ///
           position(1) ring(0) cols(1) size(small))                                            ///
    xtitle("Estimated Beta (OLS Coefficient on X)", size(medsmall))                            ///
    ytitle("Density", size(medsmall))                                                          ///
    title("Sampling Distribution of OLS Beta: Superpopulation", size(medium))                 ///
    subtitle("500 simulations per N | Infinite superpopulation | True beta = 3", size(small)) ///
    note("DGP: Y = 2 + 3X + {&epsilon}, X~N(0,1), {&epsilon}~N(0,2)", size(vsmall))          ///
    scheme(s2color)

graph export "fig2_beta_density_p2.png", replace width(1200)
display as text _newline "fig2_beta_density_p2.png exported."


* --- Figure 3: SD(beta) and mean SEM vs N on log-log scale ---
* Collapsing to one row per N for the scatter; overlay the theoretical
* SE formula: sigma_epsilon / (sigma_X * sqrt(N)) = 2 / (1 * sqrt(N))
* On a log-log plot this becomes a straight line with slope -1/2.
preserve

collapse ///
    (mean)   mean_beta  = beta      ///
    (sd)     sd_beta    = beta      ///
    (mean)   mean_sem   = sem       ///
    (mean)   mean_ciw   = ci_width  ///
    (mean)   power      = rejected  ///
    , by(sample_size)

twoway ///
    (scatter sd_beta  sample_size if sample_size >= 4, mcolor(navy)   msymbol(circle)  msize(small))  ///
    (scatter mean_sem sample_size if sample_size >= 4, mcolor(orange) msymbol(diamond) msize(small))  ///
    (function y = 2/sqrt(x), range(4 1048576) lpattern(dash) lcolor(red) lwidth(medium)),             ///
    xscale(log) yscale(log range(.0008 3))                                                   ///
    xlabel(10 100 1000 10000 100000 1000000, labsize(small))                                 ///
    ylabel(0.001 0.01 0.1 1, labsize(small))                                                 ///
    legend(order(1 "Empirical SD of beta" 2 "Mean analytical SEM"                           ///
                 3 "Theoretical: 2/sqrt(N)")                                                 ///
           position(1) ring(0) cols(1) size(small))                                          ///
    xtitle("Sample Size N (log scale)", size(medsmall))                                      ///
    ytitle("SE of Beta (log scale)", size(medsmall))                                         ///
    title("Precision of OLS Beta Estimates vs Sample Size", size(medium))                    ///
    subtitle("Part 2: Superpopulation | Slope = -1/2 on log-log axes confirms 1/sqrt(N) law", ///
             size(small))                                                                    ///
    note("Theoretical SE = 2/sqrt(N). N=2 excluded: 0 residual df produces extreme (Cauchy-like) beta estimates.", ///
         size(vsmall))                                                                       ///
    scheme(s2color)

graph export "fig3_sd_vs_n_p2.png", replace width(1200)
display as text _newline "fig3_sd_vs_n_p2.png exported."

restore


* --- Figure 4: Comparison -- Part 1 (fixed pop) vs Part 2 (superpopulation) ---
* This figure highlights the key conceptual difference between the two parts:
*   Part 1 (red): SD falls toward zero as n approaches the population size N=10,000
*   Part 2 (blue): SD continues decreasing as 1/sqrt(N) with no lower bound
* The N=10,000 point from Part 1 is excluded because SD=0 cannot be shown
* on a log scale (all 500 reps returned the same result -- the full-population OLS).

* Collapse Part 1 simulation results
use "simulation_results.dta", clear
collapse (sd) sd_p1 = beta, by(sample_size)
* Drop the N=10,000 full-population point (SD=0, undefined on log scale)
drop if sample_size == 10000
tempfile p1_coll
save `p1_coll'

* Collapse Part 2 simulation results
use "simulation_results_p2.dta", clear
collapse (sd) sd_p2 = beta, by(sample_size)
tempfile p2_coll
save `p2_coll'

* Merge on sample_size; rows only in Part 2 will have missing sd_p1 (correct)
use `p1_coll', clear
merge 1:1 sample_size using `p2_coll', nogenerate
sort sample_size

twoway ///
    (connected sd_p1 sample_size if !missing(sd_p1), sort                       ///
        lcolor(red)  mcolor(red)  msymbol(circle)  lwidth(medium) lpattern(solid)) ///
    (connected sd_p2 sample_size if sample_size >= 4, sort                      ///
        lcolor(blue) mcolor(blue) msymbol(diamond) lwidth(medium) lpattern(solid)) ///
    (function y = 2/sqrt(x), range(4 1048576) lpattern(dash) lcolor(black) lwidth(medium)), ///
    xscale(log) yscale(log range(.0008 3))                                       ///
    xlabel(10 100 1000 10000 100000 1000000, labsize(small))                     ///
    ylabel(0.001 0.01 0.1 1, labsize(small))                                     ///
    legend(order(1 "Part 1: Fixed population (max N = 10,000)"                  ///
                 2 "Part 2: Superpopulation (no upper bound)"                   ///
                 3 "Theoretical: 2/sqrt(N)")                                    ///
           position(1) ring(0) cols(1) size(small))                             ///
    xtitle("Sample Size N (log scale)", size(medsmall))                         ///
    ytitle("SD of Beta Estimates (log scale)", size(medsmall))                  ///
    title("Sampling Variation: Fixed Population vs Superpopulation", size(medium)) ///
    subtitle("Part 1 converges to zero at N=10,000; Part 2 follows 1/sqrt(N) indefinitely", ///
             size(small))                                                        ///
    note("N=2 excluded: 0 residual df produces extreme beta estimates. Part 1 N=10,000 excluded: SD=0 (log undefined).", ///
         size(vsmall))                                                           ///
    scheme(s2color)

graph export "fig4_comparison.png", replace width(1200)
display as text _newline "fig4_comparison.png exported."

* ------------------------------------------------
*3) Tables
* ------------------------------------------------

* --- Table 2: Part 2 summary statistics for all 26 sample sizes ---
use "simulation_results_p2.dta", clear
gen ci_width = ci_hi - ci_lo
gen rejected = (pval < 0.05)

preserve
collapse ///
    (mean)   mean_beta  = beta      ///
    (sd)     sd_beta    = beta      ///
    (mean)   mean_sem   = sem       ///
    (mean)   mean_ciw   = ci_width  ///
    (mean)   power      = rejected  ///
    , by(sample_size)

format mean_beta sd_beta mean_sem mean_ciw %8.5f
format power %5.3f

display as text _newline "============================================================"
display as text "Table 2: Part 2 Simulation Results (True beta = 3, Superpopulation)"
display as text "============================================================"
display as text "N           | Mean Beta | SD Beta  | Mean SEM | Mean CI Width | Power"
display as text "------------|-----------|----------|----------|---------------|------"

forvalues i = 1/`= _N' {
    local n   = sample_size[`i']
    local mb  = string(mean_beta[`i'], "%8.5f")
    local sdb = string(sd_beta[`i'],   "%8.5f")
    local ms  = string(mean_sem[`i'],  "%8.5f")
    local mcw = string(mean_ciw[`i'],  "%8.5f")
    local pw  = string(power[`i'],     "%5.3f")
    display as text "`n'" _col(13) "| `mb'" _col(24) "| `sdb'" _col(34) "| `ms'" _col(44) "| `mcw'" _col(59) "| `pw'"
}

display as text "============================================================"
display as text "Note: Theoretical SD = 2/sqrt(N). Power = prop. with p<0.05."
restore


* --- Comparison Table: Part 1 vs Part 2 at the four common sample sizes ---
* N = 10, 100, 1,000, 10,000 appear in both simulations.
* At N=10,000 in Part 1, SD=0 because every rep uses the full population.
* At N=10,000 in Part 2, SD>0 because each rep draws fresh data.
* The FPC shrinks Part 1 SDs slightly below Part 2 for N=100 and N=1,000.

* Collapse Part 1
use "simulation_results.dta", clear
gen ci_width = ci_hi - ci_lo
collapse (mean) mb_p1=beta (sd) sd_p1=beta (mean) sem_p1=sem (mean) ciw_p1=ci_width, ///
    by(sample_size)
tempfile p1_comp
save `p1_comp'

* Collapse Part 2 (keep only the four common N values)
use "simulation_results_p2.dta", clear
gen ci_width = ci_hi - ci_lo
keep if inlist(sample_size, 10, 100, 1000, 10000)
collapse (mean) mb_p2=beta (sd) sd_p2=beta (mean) sem_p2=sem (mean) ciw_p2=ci_width, ///
    by(sample_size)

* Merge Part 1 and Part 2 on sample_size
merge 1:1 sample_size using `p1_comp', nogenerate
sort sample_size

format mb_p1 sd_p1 sem_p1 ciw_p1 mb_p2 sd_p2 sem_p2 ciw_p2 %8.5f

display as text _newline "=========================================================================="
display as text "Comparison Table: Part 1 (Fixed Pop) vs Part 2 (Superpop) | True beta = 3"
display as text "=========================================================================="
display as text "N      |    --- Part 1: Fixed Pop ---         |    --- Part 2: Superpop ---"
display as text "       | Mean Beta | SD Beta  | Mean SEM      | Mean Beta | SD Beta  | Mean SEM"
display as text "-------|-----------|----------|---------------|-----------|----------|----------"

forvalues i = 1/`= _N' {
    local n    = sample_size[`i']
    local mb1  = string(mb_p1[`i'],  "%8.5f")
    local sd1  = string(sd_p1[`i'],  "%8.5f")
    local se1  = string(sem_p1[`i'], "%8.5f")
    local mb2  = string(mb_p2[`i'],  "%8.5f")
    local sd2  = string(sd_p2[`i'],  "%8.5f")
    local se2  = string(sem_p2[`i'], "%8.5f")
    display as text "`n'" _col(8) "| `mb1'" _col(19) "| `sd1'" _col(29) "| `se1'" _col(44) "| `mb2'" _col(55) "| `sd2'" _col(65) "| `se2'"
}

display as text "=========================================================================="
display as text "Note: Part 1 SD at N=10,000 = 0.000 (all reps use the full population)."
display as text "      Part 1 SDs slightly smaller than Part 2 at large N due to the"
display as text "      finite population correction factor: FPC = sqrt(1 - n/N)."

display as text _newline "All Part 2 outputs saved."


* ============================================================
* PART 3: POWER CALCULATIONS — INDIVIDUAL-LEVEL RANDOMIZATION
* ============================================================
/*
    DGP:
        Control:   Y_i ~ N(0, 1)
        Treatment: Y_i = tau_i + epsilon_i,  tau_i ~ U(0.0, 0.2),  epsilon_i ~ N(0,1)
        Average treatment effect = E[tau_i] = 0.1 SD

    Sub-questions:
        3a.  50/50 split, no attrition       → baseline N for 80% power
        3b.  50/50 split, 15% attrition      → inflate enrolled N by 1/(1-0.15)
        3c.  30% treatment, 70% control      → unequal allocation (less efficient)

    Analytical answers use Stata's built-in power twomeans command
    (same command shown in week_08_simulations.do).
    A simulation-based power curve cross-validates the analytical answer.
*/

* ------------------------------------------------------------------
* 3a: Analytical power — base case (50/50 split, no attrition)
* ------------------------------------------------------------------
display as text _newline "=== Part 3a: Base case — 50/50 split, ATE = 0.1 SD, power = 0.80 ==="
power twomeans 0 0.1, sd(1) power(0.8)
local N_base    = r(N)           // total N returned by power twomeans
local N_per_grp = `N_base' / 2
display as text "Required total N: `N_base'  (`N_per_grp' per group)"

* ------------------------------------------------------------------
* 3b: Adjust for 15% attrition (equal rate in both arms)
* ------------------------------------------------------------------
/*
    Enroll N_enroll = N_needed / (1 - attrition_rate) individuals.
    Those who remain after attrition form the analytical sample of N_needed.
    Attrition is symmetric: equal in treatment and control, so the
    50/50 split is preserved and power calculation is unchanged.
*/
display as text _newline "=== Part 3b: 15% attrition — enroll more to compensate ==="
local attrition_rate = 0.15
local N_enroll       = ceil(`N_base' / (1 - `attrition_rate'))
local pct_inc_b      = (`N_enroll' / `N_base' - 1) * 100
display as text "Enrollment required: `N_enroll'"
display as text "Increase over base:  +" %4.1f `pct_inc_b' "%"

* ------------------------------------------------------------------
* 3c: Adjust for 30% treatment proportion (unequal allocation)
* ------------------------------------------------------------------
/*
    With p = 30% treatment, efficiency = 4*p*(1-p) = 4*0.3*0.7 = 0.84.
    A 50/50 split is optimal; any deviation raises required N.
    In power twomeans: nratio = n2/n1 where sample 1 = control (m1=0),
    sample 2 = treatment (m2=0.1).  nratio = n_treat/n_control = 0.3/0.7.
*/
display as text _newline "=== Part 3c: 30% treatment proportion (unequal allocation) ==="
local nratio = 0.3 / 0.7
power twomeans 0 0.1, sd(1) power(0.8) nratio(`nratio')
local N_unequal      = r(N)
local N_treat_uneq   = round(`N_unequal' * 0.3)
local N_ctrl_uneq    = `N_unequal' - `N_treat_uneq'
local pct_inc_c      = (`N_unequal' / `N_base' - 1) * 100
display as text "Treatment group:    `N_treat_uneq'"
display as text "Control group:      `N_ctrl_uneq'"
display as text "Total N:            `N_unequal'"
display as text "Increase over base: +" %4.1f `pct_inc_c' "%"

* ------------------------------------------------------------------
* Table 3: Analytical summary
* ------------------------------------------------------------------
local N_enroll_treat = ceil(`N_enroll' / 2)
local N_enroll_ctrl  = `N_enroll' - `N_enroll_treat'

display as text _newline "========================================================================"
display as text "Table 3: Individual-Level RCT — Required N (80% power, ATE = 0.1 SD, alpha=0.05)"
display as text "========================================================================"
display as text "Scenario                           | N Treatment | N Control | Total N | +% vs Base"
display as text "-----------------------------------|-------------|-----------|---------|------------"
display as text "3a. Base (50/50, no attrition)     | " %7.0f `N_per_grp'    " | " %7.0f `N_per_grp'    " | " %7.0f `N_base'    " | ---"
display as text "3b. 15% attrition (enroll)         | " %7.0f `N_enroll_treat' " | " %7.0f `N_enroll_ctrl' " | " %7.0f `N_enroll'  " | +" %4.1f `pct_inc_b' "%"
display as text "3c. 30% treatment proportion       | " %7.0f `N_treat_uneq'   " | " %7.0f `N_ctrl_uneq'   " | " %7.0f `N_unequal' " | +" %4.1f `pct_inc_c' "%"
display as text "========================================================================"
display as text "Notes: 3b enrolls N/(1-0.15) so that the completed sample = base N."
display as text "       3c is less efficient: 4*0.3*0.7 = 0.84 of the 50/50 efficiency."

* ------------------------------------------------------------------
* Simulation: power curve to cross-validate the analytical answer
* ------------------------------------------------------------------
/*
    Following the simulate pattern from week_08_simulations.do:
    define a program, run it 500 times at each N, accumulate results
    into a tempfile, then collapse to a power-vs-N plot.
*/
capture program drop indiv_power
program define indiv_power, rclass
    args n_size treat_prop

    local n_treat   = round(`n_size' * `treat_prop')

    clear
    set obs `n_size'
    gen treatment = (_n <= `n_treat')
    * Individual treatment effects drawn from U(0.0, 0.2) → mean ATE = 0.1 SD
    gen tau_i = runiform(0.0, 0.2) * treatment
    gen Y     = rnormal(0, 1) + tau_i

    quietly regress Y treatment
    mat a = r(table)

    return scalar N      = e(N)
    return scalar beta   = _b[treatment]
    return scalar pval   = a[4, 1]
    return scalar reject = (a[4, 1] < 0.05)
end

* N values span from well below to well above the analytical answer (~N_base)
local p3_sizes "500 1000 1500 2000 2500 3000 3500 4000"
clear
tempfile p3_power
save `p3_power', emptyok

local seed_p3 = 3001
foreach n of local p3_sizes {
    display as text _newline "Part 3 power sim: N = `n' (500 reps)..."
    simulate N=r(N) beta=r(beta) pval=r(pval) reject=r(reject), ///
        reps(500) seed(`seed_p3') nodots: indiv_power `n' 0.5
    gen sample_size = `n'
    append using `p3_power'
    save `p3_power', replace
    local seed_p3 = `seed_p3' + 1
}

use `p3_power', clear
sort sample_size
save "sim_results_p3.dta", replace

* Collapse to one power estimate per N and display
preserve
collapse (mean) power = reject (mean) mean_beta = beta, by(sample_size)

display as text _newline "Power curve (50/50, treatment effect ~ U[0,0.2], mean ATE = 0.1 SD):"
display as text "N       | Sim. Power"
display as text "--------|----------"
forvalues i = 1/`=_N' {
    local n  = sample_size[`i']
    local pw = string(power[`i'], "%5.3f")
    display as text "`n'" _col(9) "| `pw'"
}

* Figure 5: Power curve with 80% threshold and analytical-N reference lines
twoway                                                                          ///
    (connected power sample_size,                                               ///
        lcolor(navy) mcolor(navy) msymbol(circle) lwidth(medium) msize(medium)) ///
    ,                                                                           ///
    yline(0.8,      lcolor(red)    lpattern(dash) lwidth(medium))               ///
    xline(`N_base', lcolor(orange) lpattern(dash) lwidth(medium))               ///
    ytitle("Estimated Power", size(medsmall))                                   ///
    xtitle("Total Sample Size (N)", size(medsmall))                             ///
    title("Power Curve: Individual-Level RCT", size(medium))                    ///
    subtitle("50/50 split | Treatment effect ~ U(0.0, 0.2) SD | 500 reps per N", size(small)) ///
    note("Red dash = 80% power. Orange dash = analytical N = `N_base' (power twomeans).", ///
         size(vsmall))                                                          ///
    ylabel(0(0.1)1, labsize(small))                                             ///
    xlabel(500 1000 1500 2000 2500 3000 3500 4000, labsize(small))              ///
    scheme(s2color)

graph export "fig5_power_curve_p3.png", replace width(1200)
display as text _newline "fig5_power_curve_p3.png exported."
restore

display as text _newline "Part 3 complete."


* ============================================================
* PART 4: POWER CALCULATIONS — CLUSTER RANDOMIZATION
* ============================================================
/*
    DGP for school-level cluster RCT:
        Y_ij = u_j  +  tau_j * T_j  +  epsilon_ij

        u_j         ~ N(0, sigma_b)    school-level random effect
        epsilon_ij  ~ N(0, 1)          individual-level noise
        tau_j       ~ U(0.15, 0.25)   school-level treatment effect (mean=0.2 SD)
        T_j = 1 if school j is assigned treatment

    ICC = 0.30:
        sigma_b  = sqrt(rho / (1-rho)) = sqrt(0.3/0.7) ≈ 0.6547
        ICC = sigma_b^2 / (sigma_b^2 + 1) = (3/7) / (3/7 + 1) = 0.30  ✓

    Design efficiency factor (DEFF):
        DEFF = 1 + (m - 1) * ICC = 1 + (m-1)*0.3
        where m = cluster size. Larger clusters raise DEFF → more variance.

    Compliance (sub-question 4c):
        Only 70% of assigned-treatment schools actually adopt.
        Regression uses assigned_treat → ITT analysis.
        Effective ITT effect = 0.70 × 0.20 = 0.14 SD.

    Three sub-questions:
        4a. N_clusters = 200 fixed; vary cluster size (2^1 through 2^10)
        4b. Cluster size = 15 fixed; vary N_clusters (full compliance)
        4c. As 4b but compliance = 0.70
*/

* ------------------------------------------------------------------
* Verify ICC of DGP before running simulations
* ------------------------------------------------------------------
display as text _newline "=== Part 4: Verifying ICC = 0.3 in the DGP ==="
local sigma_b = sqrt(0.3 / 0.7)
clear
set obs 200               // 200 schools
gen cluster_id = _n
gen u_j        = rnormal(0, `sigma_b')
expand 30                 // 30 students per school
bysort cluster_id: gen student_id = _n
gen eps     = rnormal(0, 1)
gen Y_check = u_j + eps
loneway Y_check cluster_id
display as text "ICC from loneway should be ≈ 0.30 (see output above)"

* ------------------------------------------------------------------
* Define cluster_power program
* ------------------------------------------------------------------
capture program drop cluster_power
program define cluster_power, rclass
    args n_clusters cluster_size compliance
    /*
        n_clusters   = total number of schools
        cluster_size = students per school
        compliance   = share of assigned-treatment schools that adopt (0 to 1)
                       1.0 → full adoption   0.7 → 70% adoption (ITT analysis)
    */
    local n_treat_clust = floor(`n_clusters' / 2)   // even split
    local sigma_b       = sqrt(3/7)                 // ICC = 0.3

    * --- Generate school-level data first, then expand to students ---
    * This avoids a slow forvalues loop inside simulate.
    clear
    set obs `n_clusters'
    gen cluster_id     = _n
    gen assigned_treat = (cluster_id <= `n_treat_clust')

    * School random effect (drives ICC)
    gen u_j = rnormal(0, `sigma_b')

    * School treatment effect: U[0.15, 0.25] only for compliant treatment schools
    gen adopts = (assigned_treat == 1) & (runiform() <= `compliance')
    gen tau_j  = runiform(0.15, 0.25) * adopts   // = 0 for control + non-compliers

    * Expand each school row to cluster_size student rows
    expand `cluster_size'
    bysort cluster_id: gen student_id = _n

    * Individual noise and outcome
    gen eps = rnormal(0, 1)
    gen Y   = u_j + eps + tau_j

    * ITT regression with cluster-robust SEs
    quietly regress Y assigned_treat, vce(cluster cluster_id)
    mat a = r(table)

    return scalar N       = e(N)
    return scalar N_clust = `n_clusters'
    return scalar beta    = _b[assigned_treat]
    return scalar pval    = a[4, 1]
    return scalar reject  = (a[4, 1] < 0.05)
end

* ------------------------------------------------------------------
* 4a: Vary cluster size — hold N_clusters=200, full compliance
* ------------------------------------------------------------------
display as text _newline "=== Part 4a: Varying cluster size (N_clusters=200, compliance=1) ==="
local clust_sizes "2 4 8 16 32 64 128 256 512 1024"
clear
tempfile p4a_results
save `p4a_results', emptyok

local seed_p4 = 4001
foreach m of local clust_sizes {
    display as text _newline "Part 4a: 200 schools x `m' students/school (500 reps)..."
    simulate N=r(N) N_clust=r(N_clust) beta=r(beta) pval=r(pval) reject=r(reject), ///
        reps(500) seed(`seed_p4') nodots: cluster_power 200 `m' 1
    gen cluster_size = `m'
    append using `p4a_results'
    save `p4a_results', replace
    local seed_p4 = `seed_p4' + 1
}

use `p4a_results', clear
sort cluster_size
label variable cluster_size "Students per school"
label variable reject       "1 if H0 rejected at 5% level (ITT)"
save "sim_results_p4a.dta", replace

preserve
collapse (mean) power = reject (mean) mean_beta = beta, by(cluster_size)

display as text _newline "============================================================="
display as text "Table 4a: Power by Cluster Size (N_clusters=200, ATE=0.2 SD, ICC=0.3)"
display as text "============================================================="
display as text "Students/School | DEFF = 1+(m-1)*0.3 | Power"
display as text "----------------|-------------------|------"
forvalues i = 1/`=_N' {
    local m    = cluster_size[`i']
    local deff = string(1 + (`m' - 1) * 0.3, "%6.2f")
    local pw   = string(power[`i'], "%5.3f")
    display as text "`m'" _col(17) "| " `deff' _col(36) "| `pw'"
}
display as text "============================================================="
display as text "Note: DEFF rises with cluster size; power gains diminish as DEFF grows."

* Figure 6: Power vs cluster size (log-x scale)
twoway                                                                              ///
    (connected power cluster_size,                                                  ///
        lcolor(navy) mcolor(navy) msymbol(circle) lwidth(medium) msize(medium))    ///
    ,                                                                               ///
    yline(0.8, lcolor(red) lpattern(dash) lwidth(medium))                          ///
    xscale(log)                                                                     ///
    xlabel(2 4 8 16 32 64 128 256 512 1024, labsize(small))                        ///
    ytitle("Estimated Power", size(medsmall))                                       ///
    xtitle("Students per School (log scale)", size(medsmall))                      ///
    title("Power vs. Cluster Size — 200 Schools", size(medium))                    ///
    subtitle("ATE = 0.2 SD | ICC = 0.3 | Full compliance | 500 reps per cluster size", ///
             size(small))                                                           ///
    note("Red dash = 80% power. DEFF = 1+(m-1)*0.3 grows with cluster size.", size(vsmall)) ///
    ylabel(0(0.1)1, labsize(small))                                                 ///
    scheme(s2color)

graph export "fig6_power_cluster_size.png", replace width(1200)
display as text _newline "fig6_power_cluster_size.png exported."
restore

* ------------------------------------------------------------------
* 4b: Vary N_clusters — hold cluster_size=15, full compliance
* ------------------------------------------------------------------
display as text _newline "=== Part 4b: Varying N_clusters (cluster_size=15, compliance=1) ==="
local n_clust_list "50 100 150 200 250 300 350 400"
clear
tempfile p4b_results
save `p4b_results', emptyok

foreach k of local n_clust_list {
    display as text _newline "Part 4b: `k' schools x 15 students/school (500 reps)..."
    simulate N=r(N) N_clust=r(N_clust) beta=r(beta) pval=r(pval) reject=r(reject), ///
        reps(500) seed(`seed_p4') nodots: cluster_power `k' 15 1
    gen n_clusters = `k'
    append using `p4b_results'
    save `p4b_results', replace
    local seed_p4 = `seed_p4' + 1
}

use `p4b_results', clear
sort n_clusters
label variable n_clusters "Number of schools"
save "sim_results_p4b.dta", replace

preserve
collapse (mean) power = reject (mean) mean_beta = beta, by(n_clusters)

display as text _newline "=============================================================="
display as text "Table 4b: Power by N_clusters (cluster_size=15, full compliance, ATE=0.2 SD)"
display as text "=============================================================="
display as text "N Schools | Power"
display as text "----------|------"
forvalues i = 1/`=_N' {
    local k  = n_clusters[`i']
    local pw = string(power[`i'], "%5.3f")
    display as text "`k'" _col(11) "| `pw'"
}
display as text "=============================================================="
display as text "Note: 80% power is reached when the power column first exceeds 0.800."

* Figure 7: Power vs N_clusters (full compliance)
twoway                                                                              ///
    (connected power n_clusters,                                                    ///
        lcolor(navy) mcolor(navy) msymbol(circle) lwidth(medium) msize(medium))    ///
    ,                                                                               ///
    yline(0.8, lcolor(red) lpattern(dash) lwidth(medium))                          ///
    ytitle("Estimated Power", size(medsmall))                                       ///
    xtitle("Number of Schools", size(medsmall))                                     ///
    title("Power vs. Number of Schools — Cluster Size = 15", size(medium))         ///
    subtitle("ATE = 0.2 SD | ICC = 0.3 | Full compliance | 500 reps per N", size(small)) ///
    note("Red dashed line = 80% power target.", size(vsmall))                      ///
    ylabel(0(0.1)1, labsize(small))                                                 ///
    xlabel(50(50)400, labsize(small))                                               ///
    scheme(s2color)

graph export "fig7_power_nclusters.png", replace width(1200)
display as text _newline "fig7_power_nclusters.png exported."
restore

* ------------------------------------------------------------------
* 4c: Vary N_clusters — cluster_size=15, 70% compliance (ITT)
* ------------------------------------------------------------------
/*
    Only 70% of assigned-treatment schools actually adopt the intervention.
    The regression uses assigned_treat (ITT estimand).
    Effective ITT treatment effect = 0.70 × E[tau_j] = 0.70 × 0.20 = 0.14 SD.
    Because the detectable effect is smaller, we need more clusters.
*/
display as text _newline "=== Part 4c: Varying N_clusters (cluster_size=15, compliance=0.70) ==="
clear
tempfile p4c_results
save `p4c_results', emptyok

foreach k of local n_clust_list {
    display as text _newline "Part 4c: `k' schools x 15 students/school, 70% compliance (500 reps)..."
    simulate N=r(N) N_clust=r(N_clust) beta=r(beta) pval=r(pval) reject=r(reject), ///
        reps(500) seed(`seed_p4') nodots: cluster_power `k' 15 0.7
    gen n_clusters = `k'
    append using `p4c_results'
    save `p4c_results', replace
    local seed_p4 = `seed_p4' + 1
}

use `p4c_results', clear
sort n_clusters
save "sim_results_p4c.dta", replace

preserve
collapse (mean) power = reject (mean) mean_beta = beta, by(n_clusters)

display as text _newline "================================================================"
display as text "Table 4c: Power by N_clusters (cluster_size=15, 70% compliance, ITT)"
display as text "================================================================"
display as text "N Schools | Power  (ITT effect ≈ 0.14 SD)"
display as text "----------|-------"
forvalues i = 1/`=_N' {
    local k  = n_clusters[`i']
    local pw = string(power[`i'], "%5.3f")
    display as text "`k'" _col(11) "| `pw'"
}
display as text "================================================================"
display as text "Note: ITT effect = compliance_rate x ATE = 0.70 x 0.20 = 0.14 SD."
display as text "      More schools needed than in 4b to detect the smaller ITT effect."
restore

* Figure 8: Compare full compliance vs 70% compliance on same axes
use "sim_results_p4b.dta", clear
gen compliance = 1
tempfile p4b_comp
save `p4b_comp'

use "sim_results_p4c.dta", clear
gen compliance = 0.7
append using `p4b_comp'
collapse (mean) power = reject, by(n_clusters compliance)

twoway                                                                              ///
    (connected power n_clusters if compliance == 1,   sort                         ///
        lcolor(navy)   mcolor(navy)   msymbol(circle)  lwidth(medium) lpattern(solid)) ///
    (connected power n_clusters if compliance == 0.7, sort                         ///
        lcolor(orange) mcolor(orange) msymbol(diamond) lwidth(medium) lpattern(dash))  ///
    ,                                                                               ///
    yline(0.8, lcolor(red) lpattern(dash) lwidth(medium))                          ///
    legend(order(1 "100% compliance  (ATE = 0.20 SD)"                              ///
                 2 "70% compliance   (ITT = 0.14 SD)")                             ///
           position(4) ring(0) cols(1) size(small))                                ///
    ytitle("Estimated Power", size(medsmall))                                       ///
    xtitle("Number of Schools", size(medsmall))                                     ///
    title("Power vs. Schools: Full vs. Partial Compliance", size(medium))           ///
    subtitle("Cluster size = 15 | ICC = 0.3 | ATE = 0.2 SD | 500 reps per N", size(small)) ///
    note("Red dash = 80% power. Non-compliance shrinks the ITT effect to 0.14 SD.", ///
         size(vsmall))                                                              ///
    ylabel(0(0.1)1, labsize(small))                                                 ///
    xlabel(50(50)400, labsize(small))                                               ///
    scheme(s2color)

graph export "fig8_compliance_comparison.png", replace width(1200)
display as text _newline "fig8_compliance_comparison.png exported."

display as text _newline "All Parts 1-4 complete."
