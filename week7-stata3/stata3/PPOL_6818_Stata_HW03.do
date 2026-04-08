*================================================================================
* PPOL 6818 - Stata Assignment 03
* Sampling Noise, Superpopulation, and Power Calculations
*================================================================================
*==============================================================================
* PART 1: Sampling Noise in a Fixed Population
*==============================================================================
*------------------------------------------------------------------------------
* Step 1-2: Create and save the fixed population of 10,000 observations
*------------------------------------------------------------------------------

clear
set seed 20240101   // Ensures reproducibility

set obs 10000

* Generate X and Y
gen X = rnormal(50, 10)
gen epsilon = rnormal(0, 5)
gen Y = 2 + 0.5 * X + epsilon

label var X "Predictor variable (test score, mean=50, sd=10)"
label var Y "Outcome variable (Y = 2 + 0.5*X + error)"

* Save population dataset to your Box folder
* *** Update this path to your own Box folder ***
local box_path "/Users/serovia/Desktop/stata3"
capture mkdir "`/Users/serovia/Desktop/stata3'"
save "`box_path'/population_10000.dta", replace

*------------------------------------------------------------------------------
* Step 3: Define the sampling program (r-class)
*------------------------------------------------------------------------------

capture program drop sample_and_reg
program define sample_and_reg, rclass
    syntax, n(integer)

    * (a) Load fixed population
    local box_path "/Users/serovia/Desktop/stata3"
    use "`box_path'/population_10000.dta", clear

    * (b) Randomly sample N observations
    sample `n', count

    * (c) Regression of Y on X
    reg Y X

    * (e) Return results: N, beta, SEM, p-value, CI
    mat b = r(table)

    return scalar N     = e(N)
    return scalar beta  = b[1,1]   // coefficient on X
    return scalar se    = b[2,1]   // standard error
    return scalar pval  = b[4,1]   // p-value
    return scalar ci_lo = b[5,1]   // lower 95% CI
    return scalar ci_hi = b[6,1]   // upper 95% CI
end

*------------------------------------------------------------------------------
* Step 4: Run simulate 500 times at N = 10, 100, 1000, 10000
*------------------------------------------------------------------------------

tempfile part1_results
local sample_sizes "10 100 1000 10000"

local first = 1
foreach n of local sample_sizes {

    di "Running simulations for N = `n' ..."
    set seed 42

    simulate               ///
        N     = r(N)       ///
        beta  = r(beta)    ///
        se    = r(se)      ///
        pval  = r(pval)    ///
        ci_lo = r(ci_lo)   ///
        ci_hi = r(ci_hi),  ///
        reps(500) nodots:  ///
        sample_and_reg, n(`n')

    gen true_n = `n'

    if `first' == 1 {
        save `part1_results', replace
        local first = 0
    }
    else {
        append using `part1_results'
        save `part1_results', replace
    }
}

use `part1_results', clear
label var beta  "OLS estimate of beta"
label var se    "Standard error of beta"
label var pval  "p-value"
label var ci_lo "Lower 95% CI"
label var ci_hi "Upper 95% CI"
label var true_n "Sample size used"

save "`box_path'/part1_simulation_results.dta", replace

*------------------------------------------------------------------------------
* Step 5: Figures and table for Part 1
*------------------------------------------------------------------------------

use `part1_results', clear

* --- Figure 1: Distribution of beta estimates by sample size ---
graph box beta, over(true_n)                              ///
    yline(0.5, lcolor(red) lpattern(dash))               ///
    title("Distribution of Beta Estimates by Sample Size" ///
          "(Fixed Population, 500 Simulations)")          ///
    ytitle("Estimated Beta")                              ///
    note("Red dashed line = true beta (0.5)")
graph export "`box_path'/part1_fig1_beta_distribution.png", replace

* --- Figure 2: Mean SEM and CI width by sample size ---
preserve
collapse (mean) mean_se=se mean_beta=beta                ///
         (sd)   sd_beta=beta, by(true_n)
gen ci_width = 2 * 1.96 * mean_se

twoway (connected mean_se true_n, mcolor(navy) lcolor(navy))       ///
       (connected ci_width true_n, mcolor(maroon) lcolor(maroon)), ///
    xscale(log) xlabel(10 100 1000 10000, format(%9.0g))           ///
    title("Mean SEM and CI Width vs. Sample Size"                  ///
          "(Fixed Population)")                                     ///
    xtitle("Sample Size (log scale)")                              ///
    ytitle("Magnitude")                                            ///
    legend(label(1 "Mean SEM") label(2 "Mean CI Width (95%)"))
graph export "`box_path'/part1_fig2_sem_ci.png", replace
restore

* --- Table 1: Summary statistics by sample size ---
preserve

* Calculate percentiles BEFORE collapsing (while beta still exists)
gen ci_lo_sim = .
gen ci_hi_sim = .

levelsof true_n, local(ns)
foreach n of local ns {
    _pctile beta if true_n == `n', percentiles(2.5 97.5)
    replace ci_lo_sim = r(r1) if true_n == `n'
    replace ci_hi_sim = r(r2) if true_n == `n'
}

collapse (mean) mean_beta=beta mean_se=se ///
         (sd)   sd_beta=beta              ///
         (mean) ci_lo_sim ci_hi_sim,      ///
         by(true_n)

gen ci_width = 2 * 1.96 * mean_se

list true_n mean_beta sd_beta mean_se ci_width ci_lo_sim ci_hi_sim, ///
    noobs sep(0)
restore


*==============================================================================
* PART 2: Sampling Noise in an Infinite Superpopulation
*==============================================================================
*------------------------------------------------------------------------------
* Step 1: Define superpopulation program (r-class)
*------------------------------------------------------------------------------
local box_path "/Users/serovia/Desktop/stata3"

capture program drop superpop_reg
program define superpop_reg, rclass
    syntax, n(integer)

    * (a) Generate fresh data from the DGP
    clear
    set obs `n'
    gen X = rnormal(50, 10)
    gen Y = 2 + 0.5 * X + rnormal(0, 5)

    * (b) Regression of Y on X
    reg Y X

    * (c) Return results
    mat b = r(table)

    return scalar N     = e(N)
    return scalar beta  = b[1,1]
    return scalar se    = b[2,1]
    return scalar pval  = b[4,1]
    return scalar ci_lo = b[5,1]
    return scalar ci_hi = b[6,1]
end

*------------------------------------------------------------------------------
* Step 2: Run simulate 500 times at first 20 powers of 2 + 6 powers of 10
*------------------------------------------------------------------------------

* Powers of 2: 2^2=4 through 2^21=2097152 (first 20 powers starting at 2^2)
local pow2_sizes ""
forvalues k = 2/21 {
    local sz = 2^`k'
    local pow2_sizes "`pow2_sizes' `sz'"
}

* Powers of 10
local pow10_sizes "10 100 1000 10000 100000 1000000"

* Combine into one list (dedup not needed since no overlap except 1000/100000
* which do overlap but that's fine – we keep both for the comparison)
local all_sizes "`pow2_sizes' `pow10_sizes'"

tempfile part2_results
local first = 1

foreach n of local all_sizes {

    di "Superpopulation simulations: N = `n' ..."
    set seed 42

    * Skip very large Ns that take too long (optional guard)
    * If you have time, remove the cap below
    if `n' > 1000000 {
        di "  Skipping N=`n' (too large for routine run)"
        continue
    }

    simulate               ///
        N     = r(N)       ///
        beta  = r(beta)    ///
        se    = r(se)      ///
        pval  = r(pval)    ///
        ci_lo = r(ci_lo)   ///
        ci_hi = r(ci_hi),  ///
        reps(500) nodots:  ///
        superpop_reg, n(`n')

    gen true_n   = `n'
    gen is_pow2  = (mod(round(log(`n')/log(2)), 1) == 0)  // flag powers of 2
    gen is_pow10 = inlist(`n', 10, 100, 1000, 10000, 100000, 1000000)

    if `first' == 1 {
        save `part2_results', replace
        local first = 0
    }
    else {
        append using `part2_results'
        save `part2_results', replace
    }
}
local box_path "/Users/serovia/Desktop/stata3"
use `part2_results', clear
save "`box_path'/part2_simulation_results.dta", replace

*------------------------------------------------------------------------------
* Step 3: Figures and table for Part 2
*------------------------------------------------------------------------------
local box_path "/Users/serovia/Desktop/stata3"
use `part2_results', clear

* --- Figure 3: Beta distribution for superpopulation ---
graph box beta, over(true_n)                              ///
    yline(0.5, lcolor(red) lpattern(dash))               ///
    title("Distribution of Beta Estimates"               ///
          "(Superpopulation, 500 Simulations)")           ///
    ytitle("Estimated Beta")                             ///
    note("Red dashed line = true beta (0.5)")
graph export "`box_path'/part2_fig3_beta.png", replace

* --- Figure 4: SEM vs log(N) for Part 2 ---
preserve
collapse (mean) mean_se=se mean_beta=beta, by(true_n is_pow2 is_pow10)
gen log_n = log10(true_n)
gen ci_width = 2 * 1.96 * mean_se

twoway (scatter mean_se log_n if is_pow2==1,  mcolor(navy)   msymbol(O))  ///
       (scatter mean_se log_n if is_pow10==1, mcolor(maroon) msymbol(D)), ///
    title("Mean SEM vs. log(N) – Superpopulation")                       ///
    xtitle("log10(Sample Size)")                                          ///
    ytitle("Mean SEM of Beta")                                            ///
    legend(label(1 "Powers of 2") label(2 "Powers of 10"))
graph export "`box_path'/part2_fig4_sem_logn.png", replace
restore

* --- Table 2: Summary for Part 2 (powers of 10 only for brevity) ---
preserve
keep if is_pow10 == 1
collapse (mean)  mean_beta=beta mean_se=se  ///
         (sd)    sd_beta=beta, by(true_n)
gen ci_width = 2 * 1.96 * mean_se

list true_n mean_beta sd_beta mean_se ci_width, noobs sep(0)
restore

* --- Step 5 comparison: Part 1 vs Part 2 at shared sample sizes ---
local box_path "/Users/serovia/Desktop/stata3"

use "`box_path'/part1_simulation_results.dta", clear
gen source = "Fixed Population"
tempfile tagged1
save `tagged1'

use "`box_path'/part2_simulation_results.dta", clear
gen source = "Superpopulation"
keep if inlist(true_n, 10, 100, 1000, 10000)
append using `tagged1'

preserve
collapse (mean) mean_se=se (sd) sd_beta=beta, by(true_n source)
gen ci_width = 2 * 1.96 * mean_se

twoway (connected mean_se true_n if source=="Fixed Population",   ///
            mcolor(navy) lcolor(navy) msymbol(O))                 ///
       (connected mean_se true_n if source=="Superpopulation",    ///
            mcolor(maroon) lcolor(maroon) msymbol(D)),            ///
    xscale(log) xlabel(10 100 1000 10000, format(%9.0g))          ///
    title("Mean SEM: Fixed Population vs Superpopulation")        ///
    xtitle("Sample Size (log scale)")                             ///
    ytitle("Mean SEM")                                            ///
    legend(label(1 "Fixed Population") label(2 "Superpopulation"))
graph export "`box_path'/comparison_fig5_sem.png", replace
restore


*==============================================================================
* PART 3: Power Calculations – Individual-Level Randomization
*==============================================================================
*------------------------------------------------------------------------------
* Step 3a: Analytical power calculation (Stata built-in)
*------------------------------------------------------------------------------

* Detect 0.1 sd effect, Y ~ N(0,1), 50/50 split, 80% power

power twomeans 0 0.1, sd(1) power(0.8) nratio(1)

* Save required N
local n_base = r(N)
di "Required N (no attrition): `n_base'"

*------------------------------------------------------------------------------
* Step 3b: Simulation-based power (to verify and for figures)
*------------------------------------------------------------------------------

capture program drop indiv_power_sim
program define indiv_power_sim, rclass
    syntax, n(integer) [ate(real 0.1)]

    clear
    set obs `n'

    * Treatment assignment: 50/50
    gen rand      = runiform()
    sort rand
    gen treatment = (_n <= `n'/2)

    * Heterogeneous treatment effects ~ Uniform(0, 0.2)
    gen te = runiform(0, 0.2)

    * Outcome
    gen Y = rnormal(0, 1) + treatment * te

    reg Y treatment

    mat b    = r(table)
    return scalar beta  = b[1,1]
    return scalar pval  = b[4,1]
    return scalar N     = e(N)
end

* Find power at the analytically-required N
set seed 12345
simulate beta=r(beta) pval=r(pval), reps(1000) nodots: ///
    indiv_power_sim, n(`n_base')

gen rejected = (pval < 0.05)
sum rejected
local power_base = r(mean)
di "Simulated power at N=`n_base' (no attrition): " %4.1f (`power_base'*100) "%"

*------------------------------------------------------------------------------
* Step 3c: Attrition – 15% of sample attrits
*------------------------------------------------------------------------------

local n_attrition = ceil(`n_base' / (1 - 0.15))

di "Adjusted N for 15% attrition: `n_attrition'"

power twomeans 0 0.1, sd(1) power(0.8) nratio(1)
* Manual adjustment:
di "With 15% attrition, inflate N by 1/(1-0.15) = " 1/0.85
di "Adjusted N = ceil(" `n_base' " / 0.85) = `n_attrition'"

*------------------------------------------------------------------------------
* Step 3d: Partial take-up – only 30% receive treatment
*------------------------------------------------------------------------------
* Intent-to-treat (ITT) effect is diluted: ATE_ITT = compliance_rate * ATE_TOT
* compliance = 0.30, so detectable ITT = 0.30 * 0.1 = 0.03 sd

local compliance = 0.30
local ate_itt    = `compliance' * 0.1

di "ITT effect (diluted) = `ate_itt' sd"
power twomeans 0 `ate_itt', sd(1) power(0.8) nratio(1)
local n_partial = r(N)
di "Required N with 30% take-up: `n_partial'"







*==============================================================================
* PART 4: Power Calculations – Cluster Randomization
*==============================================================================

local box_path "/Users/serovia/Desktop/stata3"

*------------------------------------------------------------------------------
* Step 1-4: Define the cluster power program
*------------------------------------------------------------------------------

capture program drop cluster_power_sim
program define cluster_power_sim, rclass
    syntax, nclusters(integer) clustersize(integer) [takeupratio(real 1.0)]

    local rho     = 0.3
    local sigma_b = sqrt(`rho')
    local sigma_w = sqrt(1 - `rho')

    clear
    set obs `nclusters'

    * School-level identifiers and treatment
    gen school_id = _n
    gen rand = runiform()
    sort rand
    gen treatment_school = (_n <= `nclusters' / 2)

    * Partial take-up: some treated schools don't comply
    gen actually_treated = treatment_school
    if `takeupratio' < 1.0 {
        replace actually_treated = (treatment_school == 1 & runiform() <= `takeupratio')
    }

    * School-level random effect and heterogeneous treatment effect
    gen u_j       = rnormal(0, `sigma_b')
    gen school_te = runiform(0.15, 0.25)

    * Expand to student level
    expand `clustersize'

    * Student-level error and outcome
    gen e_ij = rnormal(0, `sigma_w')
    gen Y    = u_j + e_ij + actually_treated * school_te

    * Cluster-robust regression
    reg Y treatment_school, vce(cluster school_id)

    mat b = r(table)
    return scalar beta = b[1,1]
    return scalar pval = b[4,1]
    return scalar N    = e(N)
    return scalar ncl  = `nclusters'
    return scalar csz  = `clustersize'
end

*------------------------------------------------------------------------------
* Step 5: Hold clusters = 200, vary cluster size (first 10 powers of 2)
*------------------------------------------------------------------------------

local first = 1

forvalues k = 1/10 {
    local csz = 2^`k'
    di "  Cluster size = `csz' ..."
    set seed 99999

    simulate beta=r(beta) pval=r(pval), reps(500) nodots: ///
        cluster_power_sim, nclusters(200) clustersize(`csz')

    gen cluster_size = `csz'
    gen n_clusters   = 200

    if `first' == 1 {
        save "`box_path'/part4_clustersize_raw.dta", replace
        local first = 0
    }
    else {
        append using "`box_path'/part4_clustersize_raw.dta"
        save "`box_path'/part4_clustersize_raw.dta", replace
    }
}

use "`box_path'/part4_clustersize_raw.dta", clear
gen rejected = (pval < 0.05)
collapse (mean) power=rejected (mean) mean_beta=beta, by(cluster_size n_clusters)

di "Power by cluster size (n_clusters = 200):"
list cluster_size power, noobs sep(0)

twoway connected power cluster_size,                                        ///
    xscale(log) xlabel(2 4 8 16 32 64 128 256 512 1024, format(%9.0g))     ///
    yline(0.8, lcolor(red) lpattern(dash))                                  ///
    title("Statistical Power vs. Cluster Size"                              ///
          "(200 Schools, 500 Simulations)")                                 ///
    xtitle("Students per School (log scale)")                               ///
    ytitle("Power (proportion rejecting H0)")                               ///
    note("Red dashed line = 80% power threshold")
graph export "`box_path'/part4_fig6_power_clustersize.png", replace

gen meets_80 = (power >= 0.8)
sum cluster_size if meets_80 == 1
local rec_csz = r(min)
di "Recommended minimum cluster size: `rec_csz' students/school"

save "`box_path'/part4_clustersize_summary.dta", replace

*------------------------------------------------------------------------------
* Step 6: Hold cluster size = 15, find N_clusters for 80% power
*------------------------------------------------------------------------------

local first = 1

foreach nc in 20 40 60 80 100 120 140 160 180 200 250 300 400 500 {
    di "  N clusters = `nc' ..."
    set seed 55555

    simulate beta=r(beta) pval=r(pval), reps(500) nodots: ///
        cluster_power_sim, nclusters(`nc') clustersize(15)

    gen cluster_size = 15
    gen n_clusters   = `nc'

    if `first' == 1 {
        save "`box_path'/part4_nclusters_raw.dta", replace
        local first = 0
    }
    else {
        append using "`box_path'/part4_nclusters_raw.dta"
        save "`box_path'/part4_nclusters_raw.dta", replace
    }
}

use "`box_path'/part4_nclusters_raw.dta", clear
gen rejected = (pval < 0.05)
collapse (mean) power=rejected (mean) mean_beta=beta, by(n_clusters cluster_size)

di "Power by number of clusters (cluster_size = 15):"
list n_clusters power, noobs sep(0)

twoway connected power n_clusters,                             ///
    yline(0.8, lcolor(red) lpattern(dash))                    ///
    title("Statistical Power vs. Number of Schools"           ///
          "(15 Students/School, 500 Simulations)")            ///
    xtitle("Number of Schools")                               ///
    ytitle("Power (proportion rejecting H0)")                 ///
    note("Red dashed line = 80% power threshold")
graph export "`box_path'/part4_fig7_power_nclusters.png", replace

gen meets_80 = (power >= 0.8)
sum n_clusters if meets_80 == 1
local rec_nc = r(min)
di "Minimum number of schools for 80% power: `rec_nc'"

save "`box_path'/part4_nclusters_summary.dta", replace

*------------------------------------------------------------------------------
* Step 7: 70% school take-up (partial compliance)
*------------------------------------------------------------------------------

local first = 1

foreach nc in 40 60 80 100 120 140 160 180 200 250 300 400 500 {
    di "  N clusters (70% take-up) = `nc' ..."
    set seed 77777

    simulate beta=r(beta) pval=r(pval), reps(500) nodots: ///
        cluster_power_sim, nclusters(`nc') clustersize(15) takeupratio(0.70)

    gen cluster_size = 15
    gen n_clusters   = `nc'

    if `first' == 1 {
        save "`box_path'/part4_takeup_raw.dta", replace
        local first = 0
    }
    else {
        append using "`box_path'/part4_takeup_raw.dta"
        save "`box_path'/part4_takeup_raw.dta", replace
    }
}

use "`box_path'/part4_takeup_raw.dta", clear
gen rejected = (pval < 0.05)
collapse (mean) power=rejected (mean) mean_beta=beta, by(n_clusters cluster_size)

di "Power by number of clusters (70% take-up, cluster_size = 15):"
list n_clusters power, noobs sep(0)

gen meets_80 = (power >= 0.8)
sum n_clusters if meets_80 == 1
local rec_nc_takeup = r(min)
di "Minimum number of schools for 80% power (70% take-up): `rec_nc_takeup'"

save "`box_path'/part4_takeup_summary.dta", replace

*------------------------------------------------------------------------------
* Step 7b: Comparison figure – Full compliance vs 70% take-up
*------------------------------------------------------------------------------

use "`box_path'/part4_nclusters_summary.dta", clear
gen scenario = "Full Compliance"
tempfile full
save `full'

use "`box_path'/part4_takeup_summary.dta", clear
gen scenario = "70% Take-up"
append using `full'

twoway (connected power n_clusters if scenario == "Full Compliance", ///
            mcolor(navy) lcolor(navy) msymbol(O))                    ///
       (connected power n_clusters if scenario == "70% Take-up",     ///
            mcolor(maroon) lcolor(maroon) msymbol(D)),               ///
    yline(0.8, lcolor(red) lpattern(dash))                           ///
    title("Power vs. Number of Schools: Full vs. Partial Compliance") ///
    xtitle("Number of Schools")                                      ///
    ytitle("Power (proportion rejecting H0)")                        ///
    legend(label(1 "Full Compliance") label(2 "70% Take-up"))        ///
    note("Red dashed line = 80% power threshold")
graph export "`box_path'/part4_fig8_comparison.png", replace








