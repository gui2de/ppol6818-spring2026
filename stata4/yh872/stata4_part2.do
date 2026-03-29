* PART 2: De-biasing a Parameter Estimate Using Controls

* STEP 1: Define the DGP program (takes sample size as arg)
capture program drop dgp_reg
program define dgp_reg, rclass
    args n_obs
    clear
    set obs `n_obs'

    /*  DAG structure:
                    CONFOUNDER
                    ↙         ↘
           TREATMENT  →  MEDIATOR  →  OUTCOME
                    ↘                ↗
                         (direct)
                    ↘         ↗
                    COLLIDER (← also ← OUTCOME)
    */

    * CONFOUNDER: raises both P(treatment=1) and outcome
    *             → omitting it biases treatment beta UPWARD
    gen confounder = runiform()

    * Treatment assignment (binary), confounded by confounder
    gen random_t = rnormal() + 0.8*confounder
    gen treatment = 0
    summ random_t, d
    replace treatment = 1 if random_t > `r(p50)'

    * MEDIATOR: caused by treatment, and also raises outcome sits on the causal path T → M → Y controlling for it BLOCKS the indirect path → underestimates total treatment effect
    gen mediator = 0.5*treatment + rnormal()*0.3

    * OUTCOME:
    *   direct effect of treatment on Y     =  0.2
    *   indirect via mediator: 0.2 * 0.5    =  0.1
    *   ─────────────────────────────────────────────
    *   TRUE TOTAL treatment effect         =  0.3
    gen outcome = rnormal() + 0.8*confounder + 0.2*treatment + 0.2*mediator

    * COLLIDER: caused by BOTH treatment AND outcome
    *           conditioning on it opens a non-causal path
    *           → introduces collider bias
    gen collider = 0.5*treatment + 0.5*outcome + rnormal()*0.3

    *--- Model 1: No controls → upward bias (confounder omitted)
    reg outcome treatment
    matrix b = r(table)
    return scalar m1 = b[1,1]

    *--- Model 2: Control confounder only → UNBIASED for total effect (0.3)
    reg outcome treatment confounder
    matrix b = r(table)
    return scalar m2 = b[1,1]

    *--- Model 3: Confounder + mediator → blocks indirect path, converges to direct effect (0.2)
    reg outcome treatment confounder mediator
    matrix b = r(table)
    return scalar m3 = b[1,1]

    *--- Model 4: Confounder + collider → opens non-causal path via collider
    reg outcome treatment confounder collider
    matrix b = r(table)
    return scalar m4 = b[1,1]

    *--- Model 5: All vars → mediator blocks indirect AND collider biases
    reg outcome treatment confounder mediator collider
    matrix b = r(table)
    return scalar m5 = b[1,1]

end


* STEP 2: Initialize empty summary results dataset
clear
set obs 0
gen n_obs     = .
gen model     = .
gen beta_mean = .
gen beta_sd   = .
save "results_summary.dta", replace

* STEP 3: Loop over sample sizes → simulate → collect stats
local sample_sizes "50 100 200 500 1000 2000 5000"
local reps 500

foreach n of local sample_sizes {

    di "========== Running N = `n' =========="

    * Run 500 simulations at this sample size
    simulate m1=r(m1) m2=r(m2) m3=r(m3) m4=r(m4) m5=r(m5), ///
        reps(`reps'): dgp_reg `n'

    * Save full simulation results for this N (used for histograms)
    save "sim_n`n'.dta", replace

    * Extract mean and SD for each model → save as scalars
    * (must save BEFORE clearing, since summ results live in r())
    forvalues m = 1/5 {
        summ m`m'
        scalar smean_`m' = r(mean)
        scalar ssd_`m'   = r(sd)
    }

    * Build a 5-row dataset (one per model) and append to summary
    clear
    set obs 5
    gen n_obs     = `n'
    gen model     = _n          // _n goes 1,2,3,4,5
    gen beta_mean = .
    gen beta_sd   = .
    forvalues m = 1/5 {
        replace beta_mean = smean_`m' if model == `m'
        replace beta_sd   = ssd_`m'   if model == `m'
    }

    append using "results_summary.dta"
    save "results_summary.dta", replace
}

* STEP 4: FIGURE 1 – Histograms at N=1,000
use "sim_n1000.dta", clear

hist m1, xline(0.3) xtitle("Beta") ///
    title("M1: No controls (biased up)") name(h1, replace)

hist m2, xline(0.3) xtitle("Beta") ///
    title("M2: +Confounder (unbiased)") name(h2, replace)

hist m3, xline(0.3) xtitle("Beta") ///
    title("M3: +Confounder+Mediator (blocks indirect path)") name(h3, replace)

hist m4, xline(0.3) xtitle("Beta") ///
    title("M4: +Confounder+Collider (collider bias)") name(h4, replace)

hist m5, xline(0.3) xtitle("Beta") ///
    title("M5: All vars (mediator+collider bias)") name(h5, replace)

graph combine h1 h2 h3 h4 h5, ///
    title("Distribution of Beta Estimates at N = 1,000") ///
    subtitle("Vertical line = true treatment effect (0.3)") ///
    rows(2)
graph export "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 4/data/part2_fig1_histograms_N1000.png", replace

* STEP 5: FIGURE 2 – Mean beta as a function of N
use "results_summary.dta", clear

gen upper = beta_mean + beta_sd
gen lower = beta_mean - beta_sd

twoway ///
    (line beta_mean n_obs if model==1, lcolor(red)    lpattern(solid)) ///
    (line beta_mean n_obs if model==2, lcolor(blue)   lpattern(solid)) ///
    (line beta_mean n_obs if model==3, lcolor(green)  lpattern(solid)) ///
    (line beta_mean n_obs if model==4, lcolor(orange) lpattern(solid)) ///
    (line beta_mean n_obs if model==5, lcolor(purple) lpattern(solid)) ///
    (rarea upper lower n_obs if model==2, color(blue%15) lwidth(none)) ///
    , ///
    yline(0.3, lcolor(black) lpattern(dash) lwidth(medthick)) ///
    xscale(log) ///
    xlabel(50 100 200 500 1000 2000 5000, angle(45)) ///
    ytitle("Mean Beta Estimate") xtitle("Sample Size (N, log scale)") ///
    title("Mean Beta by Model and Sample Size") ///
    subtitle("Dashed line = true total treatment effect (0.3)") ///
    legend(order(1 "M1: No controls" ///
                 2 "M2: +Confounder (correct)" ///
                 3 "M3: +Mediator (blocks indirect)" ///
                 4 "M4: +Collider (collider bias)" ///
                 5 "M5: All vars") ///
           size(small) rows(3))
graph export "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 4/data/part2_fig2_mean_beta_by_N.png", replace

* STEP 6: FIGURE 3 – SD of beta as a function of N
use "results_summary.dta", clear

twoway ///
    (line beta_sd n_obs if model==1, lcolor(red)) ///
    (line beta_sd n_obs if model==2, lcolor(blue)) ///
    (line beta_sd n_obs if model==3, lcolor(green)) ///
    (line beta_sd n_obs if model==4, lcolor(orange)) ///
    (line beta_sd n_obs if model==5, lcolor(purple)) ///
    , ///
    xscale(log) ///
    xlabel(50 100 200 500 1000 2000 5000, angle(45)) ///
    ytitle("SD of Beta Estimate") xtitle("Sample Size (N, log scale)") ///
    title("Variance of Beta by Model and Sample Size") ///
    subtitle("All models converge as N grows; bias persists") ///
    legend(order(1 "M1: No controls" ///
                 2 "M2: +Confounder (correct)" ///
                 3 "M3: +Mediator" ///
                 4 "M4: +Collider" ///
                 5 "M5: All vars") ///
           size(small) rows(3))
graph export "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 4/data/part2_fig3_sd_beta_by_N.png", replace
