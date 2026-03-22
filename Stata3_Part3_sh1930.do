*** ============================================================
*** Part 3: Power Calculations for Individual-Level Randomization
*** ============================================================

*------------------------------------------------------------
* STEP 1:
*------------------------------------------------------------

capture program drop indiv_power
program define indiv_power, rclass

    args N

    clear
    set obs `N'

    gen rand = runiform()
    gen treatment = (rand <= 0.5)

    gen ind_te  = runiform(0.0, 0.2)
    gen Y = rnormal(0, 1) + treatment * ind_te

    quietly reg Y treatment

    mat res = r(table)
    scalar pval = res[4,1]

    return scalar reject = (pval < 0.05)
    return scalar beta   = res[1,1]
    return scalar pval   = pval

end


*------------------------------------------------------------
* STEP 2:
*------------------------------------------------------------

power twomeans 0 0.1, sd(1) power(0.80) alpha(0.05)

local N_analytical = 3142

tempfile power_results
clear
save `power_results', emptyok

local test_sizes "500 1000 1500 2000 2500 3000 3500 4000 5000"

foreach n of local test_sizes {

    simulate reject=r(reject) beta=r(beta) pval=r(pval), reps(1000) nodots: indiv_power `n'

    gen target_n = `n'
    collapse (mean) power=reject (mean) mean_beta=beta, by(target_n)

    append using `power_results'
    save `power_results', replace
}

use `power_results', clear
save "stata3_part3a_power.dta", replace

list target_n power, noobs sep(0)

sort target_n
gen crosses80 = (power >= 0.80)
list target_n power if crosses80==1, noobs

twoway (line power target_n, lcolor(navy) lwidth(medium)) (yline 0.80, lcolor(red) lpattern(dash)), xtitle("Sample Size") ytitle("Estimated Power") title("Figure 7: Power Curve — Individual Randomization" "ATE=0.1 sd, 50/50 split, 1000 simulations", size(medsmall)) legend(order(1 "Simulated Power" 2 "80% power threshold")) note("True ATE ~ Uniform(0.0, 0.2). Y ~ N(0,1).") scheme(s2color)
graph export "stata3_part3a_power_curve.png", replace width(1200)

*------------------------------------------------------------
* STEP 3
*------------------------------------------------------------

power twomeans 0 0.1, sd(1) power(0.80) alpha(0.05)

local attrition = 0.15
local retention = 1 - `attrition'

quietly power twomeans 0 0.1, sd(1) power(0.80) alpha(0.05)
local N_base = r(N)

local N_attrition = ceil(`N_base' / `retention')

local N_effective = floor(`N_attrition' * `retention')
power twomeans 0 0.1, sd(1) n(`N_effective') alpha(0.05)

*------------------------------------------------------------
* STEP 4
*------------------------------------------------------------

local treat_frac = 0.30
local ctrl_frac  = 0.70
local nratio = `treat_frac' / `ctrl_frac'   

power twomeans 0 0.1, sd(1) power(0.80) alpha(0.05) nratio(`nratio')

quietly power twomeans 0 0.1, sd(1) power(0.80) alpha(0.05) nratio(`nratio')
local N_unequal = r(N)
local N_balanced = `N_base'

*------------------------------------------------------------
* STEP 5: Summary table
*------------------------------------------------------------

display as text ""
display as text "=============================================="
display as text " Summary Table — Part 3: Sample Size Requirements"
display as text "=============================================="
display as text " Scenario                          | Required N"
display as text " ----------------------------------|----------"
display as text " Baseline (50/50, no attrition)| `N_base'"
display as text " 15% attrition                 | `N_attrition'"
display as text " 30% treated                   | `N_unequal'"
display as text "=============================================="
