********************************************************************
* Assignment Stata 4 - Part 2
* Qingya Yang
********************************************************************

cd "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-stata4"
clear all
set more off
set seed 42

********************************************************************
*** Q1: Set up the DGP parameters
********************************************************************
local true_beta = 0.3
local reps = 100
local Nlist "50 100 200 500 1000 2000"


********************************************************************
*** Q2: Define the DGP program
********************************************************************
capture program drop dgp
program define dgp
    args n true_beta
    drop _all
    set obs `n'

    * Confounder: omitting it causes upward omitted-variable bias
    gen confounder = runiform(-1, 1)

    * Treatment: binary; higher confounder => higher P(treated)
    gen prob_treat = 0.4 + 0.3 * confounder
    replace prob_treat = min(max(prob_treat, 0.01), 0.99)
    gen X_treat = (runiform() < prob_treat)

    * Mediator: controlling it blocks the indirect effect X->mediator->Y
    gen mediator = 0.5 * X_treat + 0.5 * runiform()

    * Outcome Y
    gen noise = rnormal(0, 1)
    gen Y = `true_beta' * noise ///
          + 0.5 * X_treat       ///
          + 0.6 * confounder    ///
          + 0.4 * mediator      ///
          + noise

    * Collider: controlling it opens a backdoor path, introducing bias
    gen collider = 0.5 * X_treat + 0.5 * Y + 0.3 * rnormal()
end


********************************************************************
*** Q3: Define the simulation program
********************************************************************
capture program drop run_sim
program define run_sim
    args n true_beta

    * Generate data using the DGP program defined in Q2
    dgp `n' `true_beta'

    * Model 1: No controls - upward bias
    quietly reg Y X_treat
    post handle ("M1: No controls") (`n') (_b[X_treat])

    * Model 2: Confounder only - correct specification
    quietly reg Y X_treat confounder
    post handle ("M2: Confounder only") (`n') (_b[X_treat])

    * Model 3: Confounder + Mediator - downward bias
    quietly reg Y X_treat confounder mediator
    post handle ("M3: Confounder+Mediator") (`n') (_b[X_treat])

    * Model 4: Collider only - collider bias
    quietly reg Y X_treat collider
    post handle ("M4: Collider only") (`n') (_b[X_treat])

    * Model 5: All variables - collider still contaminates
    quietly reg Y X_treat confounder mediator collider
    post handle ("M5: All variables") (`n') (_b[X_treat])
end
 ********************************************************************
* Run the simulation and collect results
* Storage: saves every beta estimate from every run

tempfile simresults
postfile handle str25 model int N double beta_hat using `simresults', replace

* Loop over sample sizes and repetitions, calling run_sim each time
foreach n of numlist `Nlist' {
    forvalues r = 1/`reps' {
        quietly run_sim `n' `true_beta'
    }
}

postclose handle


********************************************************************
* Summarize results, produce figures and tables
********************************************************************
use `simresults', clear

* Compute mean and SD of beta_hat for each model at each sample size
collapse (mean) mean_beta = beta_hat ///
         (sd)   sd_beta   = beta_hat, ///
         by(model N)

* Benchmark: M2 (correct spec) at N=2000 as empirical "true" value
quietly sum mean_beta if model == "M2: Confounder only" & N == 2000
local truth = r(mean)

gen bias = mean_beta - `truth'

save "simulation_summary.dta", replace

* Results table
list model N mean_beta sd_beta bias, sepby(model) noobs abbreviate(30)

********************************************************************
* Figure 1: Mean beta vs N
********************************************************************
twoway ///
    (connected mean_beta N if model=="M1: No controls")         ///
    (connected mean_beta N if model=="M2: Confounder only")     ///
    (connected mean_beta N if model=="M3: Confounder+Mediator") ///
    (connected mean_beta N if model=="M4: Collider only")       ///
    (connected mean_beta N if model=="M5: All variables"),      ///
    yline(`truth')                                              ///
    title("Figure 1: Mean Beta-hat by Model and Sample Size")   ///
    xtitle("Sample Size N") ytitle("Mean estimated beta")       ///
    legend(order(1 "M1: No controls"                            ///
                 2 "M2: Confounder only (correct)"              ///
                 3 "M3: Confounder+Mediator"                    ///
                 4 "M4: Collider only"                          ///
                 5 "M5: All variables"                          ///
                 6 "True value"))
graph export "fig1_mean_beta.png", replace


********************************************************************
* Figure 2: SD of beta vs N
********************************************************************
twoway ///
    (connected sd_beta N if model=="M1: No controls")         ///
    (connected sd_beta N if model=="M2: Confounder only")     ///
    (connected sd_beta N if model=="M3: Confounder+Mediator") ///
    (connected sd_beta N if model=="M4: Collider only")       ///
    (connected sd_beta N if model=="M5: All variables"),      ///
    title("Figure 2: SD of Beta-hat by Model and Sample Size") ///
    xtitle("Sample Size N") ytitle("SD of estimated beta")     ///
    legend(order(1 "M1: No controls"                           ///
                 2 "M2: Confounder only"                       ///
                 3 "M3: Confounder+Mediator"                   ///
                 4 "M4: Collider only"                         ///
                 5 "M5: All variables"))
graph export "fig2_sd_beta.png", replace
