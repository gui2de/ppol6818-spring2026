
//STEP 1- Define the Data Generating Process
capture program drop sim_indiv_rct
program define sim_indiv_rct, rclass
    * Accept the sample size as an argument
    args samp_size

    drop _all
    set obs `samp_size'

    * 1. Random Assignment
    gen u_val = runiform()
    gen is_treated = (u_val <= 0.5)

    * 2. Generate Heterogeneous Treatment Effect
    gen indiv_effect = runiform(0.0, 0.2)
    
    * 3. Generate Outcome
    gen outcome = rnormal(0, 1) + (is_treated * indiv_effect)

    * 4. Estimate the Treatment Effect
    quietly regress outcome is_treated

    * 5. Extract results
    matrix reg_matrix = r(table)
    scalar p_value = reg_matrix[4,1]

    * 6. Return results (1 if significant at 5% level, 0 otherwise)
    return scalar is_sig   = (p_value < 0.05)
    return scalar est_beta = reg_matrix[1,1]
    return scalar p_val    = p_value
end


//STEP 2- Simulate Power Across Different Sample Sizes
power twomeans 0 0.1, sd(1) power(0.80) alpha(0.05)
local analytic_n = r(N)

* Prepare a temporary file to store our simulation loop results
tempfile sim_data
save `sim_data', emptyok

* Define the grid of sample sizes we want to test
local n_grid "500 1000 1500 2000 2500 3000 3500 4000 5000"

foreach current_n of local n_grid {
    display "Simulating power for N = `current_n'..."
    
    * Run the simulation 1000 times for the current sample size
    simulate is_sig=r(is_sig) est_beta=r(est_beta) p_val=r(p_val), ///
             reps(1000) nodots: sim_indiv_rct `current_n'

    * Tag the sample size and calculate the mean of 'is_sig' (which is our Power)
    gen n_obs = `current_n'
    collapse (mean) stat_power=is_sig (mean) avg_beta=est_beta, by(n_obs)

    * Add to our growing dataset
    append using `sim_data'
    save `sim_data', replace
}

use `sim_data', clear
save "Stata3_q3_results.dta", replace

* Display the exact point where we cross the 80% power threshold
sort n_obs
gen achieve_80_power = (stat_power >= 0.80)
display "Sample sizes achieving >= 80% power:"
list n_obs stat_power if achieve_80_power == 1, noobs

* Create and export the Power Curve Graph
twoway (line stat_power n_obs, lcolor(ebblue) lwidth(medthick)), ///
       yline(0.80, lcolor(cranberry) lpattern(dash)) ///
       xtitle("Total Sample Size (N)") ytitle("Simulated Statistical Power") ///
       title("Power Curve for Individual Randomization") ///
       subtitle("ATE = 0.1 SD, 50/50 Split, 1000 Repetitions") ///
       legend(order(1 "Simulated Power") ring(0) pos(4)) ///
       note("DGP: True ATE ~ U(0.0, 0.2), Y ~ N(0,1)") ///
       scheme(s2color) name(power_curve, replace)
       
//STEP 3- Adjusting Sample Size for 15% Attrition
local drop_rate = 0.15
local keep_rate = 1 - `drop_rate'

* Get the pure baseline requirement first
quietly power twomeans 0 0.1, sd(1) power(0.80) alpha(0.05)
local base_n = r(N)

* Inflate the baseline to account for the subjects who will drop out
local inflated_n = ceil(`base_n' / `keep_rate')

* Verify: If we recruit 'inflated_n' and lose 15%, do we still have enough?
local final_n = floor(`inflated_n' * `keep_rate')
quietly power twomeans 0 0.1, sd(1) n(`final_n') alpha(0.05)

//STEP 4- Adjusting Sample Size for Unequal Treatment Allocation
local tx_prop = 0.30
local c_prop  = 0.70

* Stata requires the ratio of control to treatment (n2 / n1)
local alloc_ratio = `c_prop' / `tx_prop'  

* Calculate the new total sample size needed with this inefficient split
quietly power twomeans 0 0.1, sd(1) power(0.80) alpha(0.05) nratio(`alloc_ratio')
local unbal_n = r(N)


//STEP 5- Final Simulated Output
table n_obs, stat(mean stat_power) stat(mean avg_beta) ///
      nformat(%9.3f) ///
      title("Simulated Power Analysis")
