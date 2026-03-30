//Part 1: Sampling noise in a fixed population
//question 1 and question 2
clear all
set seed 12345
set obs 10000
gen x = rnormal(5,2)
gen z = rnormal(0.5)
gen y = 1.5 * x + z
save "population_data.dta", replace

//question 3
capture program drop sim_reg
program sim_reg, rclass
    syntax, n(integer)
	quietly use "population_data.dta", clear
	bsample `n'
	regress y x
	matrix table = r(table)
	return scalar N = `n'
    return scalar beta = _b[x]
    return scalar sem = _se[x]
    return scalar pval = table[4, 1] 
    return scalar ci_lower = table[5, 1]
    return scalar ci_upper = table[6, 1]
end

//question 4
tempfile sim10 sim100 sim1000 sim10000
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lower=r(ci_lower) ci_upper=r(ci_upper), reps(500) seed(8675309): sim_reg, n(10)
save `sim10'
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lower=r(ci_lower) ci_upper=r(ci_upper), reps(500) seed(8675309): sim_reg, n(100)
save `sim100'
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lower=r(ci_lower) ci_upper=r(ci_upper), reps(500) seed(8675309): sim_reg, n(1000)
save `sim1000'
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lower=r(ci_lower) ci_upper=r(ci_upper), reps(500) seed(8675309): sim_reg, n(10000)
save `sim10000'
clear
append using `sim10' `sim100' `sim1000' `sim10000'
save "simulation_results.dta", replace

//question 5
tabstat beta sem ci_lower ci_upper, by(N) statistics(mean sd) format(%9.4f)
graph box beta, over(N)
graph export "beta_variation_plot.png", replace

//part 2: Sampling noise in an infinite superpopulation.
//question 1 
clear all
set more off
capture program drop sim_dgp
program define sim_dgp, rclass
    syntax, n(integer)
	clear
    quietly set obs `n'
	quietly gen x = rnormal(0, 1)
    quietly gen error = rnormal(0, 5)
    quietly gen y = 2 + 3*x + error
	quietly reg y x
	matrix results = r(table)
    
    return scalar N_obs = `n'
    return scalar beta  = _b[x]
    return scalar sem   = _se[x]
	return scalar pval  = 2 * ttail(e(df_r), abs(_b[x]/_se[x]))
	return scalar ci_lower = results[5, 1]
    return scalar ci_upper = results[6, 1]
end

tempfile sim_results
save `sim_results', emptyok
//question 2
forvalues i = 1/20 {
    local N = 2^`i'
    display "Simulating for N = `N' (Power of 2: 2^`i')"
    
    quietly simulate N_obs=r(N_obs) beta=r(beta) sem=r(sem) pval=r(pval) ci_lower=r(ci_lower) ci_upper=r(ci_upper), reps(500) seed(12345):sim_dgp, n(`N')
        
    quietly append using `sim_results'
    quietly save `sim_results', replace
}
foreach N in 10 100 1000 10000 100000 1000000 {
    display "Simulating for N = `N' (Power of 10)"
    
    quietly simulate N_obs=r(N_obs) beta=r(beta) sem=r(sem) pval=r(pval) ci_lower=r(ci_lower) ci_upper=r(ci_upper), reps(500) seed(12345):sim_dgp, n(`N')
        
    quietly append using `sim_results'
    save `sim_results', replace
}
//question 3
use `sim_results', clear
gen log10_N = log10(N_obs)
//Generate a log(10) scale of N for graphing (otherwise visual scales get crushed)
save `sim_results', replace
twoway (scatter beta log10_N, msize(tiny) mcolor(navy%15)), yline(3, lcolor(red) lpattern(dash))
graph export "beta_variation.png", replace
gen ci_width = ci_upper - ci_lower
twoway (scatter ci_width log10_N, msize(tiny) mcolor(forest_green%15))
graph export "ci_width_variation.png", replace
preserve
collapse (mean) mean_beta=beta mean_sem=sem mean_ci_l=ci_lower mean_ci_u=ci_upper (sd) sd_beta=beta, by(N_obs)
format mean_beta sd_beta mean_sem mean_ci_l mean_ci_u %9.4f
format N_obs %12.0fc
list N_obs mean_beta sd_beta mean_sem mean_ci_l mean_ci_u, sep(0)
restore
//question 5
use "simulation_results.dta", clear
rename N N_obs
gen part = 1
gen true_beta = 1.5
gen ci_width = ci_upper - ci_lower
save "combined_sims.dta", replace
use `sim_results', clear
gen part = 2
gen true_beta = 3
gen ci_width = ci_upper - ci_lower
append using "combined_sims.dta"
keep if inlist(N_obs, 10, 100, 1000, 10000)
preserve
collapse (mean) mean_sem=sem mean_ci_width=ci_width, by(part N_obs)
format mean_sem mean_ci_width %9.4f
format N_obs %12.0fc
reshape wide mean_sem mean_ci_width, i(N_obs) j(part)
list, sep(0) abbrev(20)
restore
gen log10_N = log10(N_obs)
twoway (scatter ci_width log10_N if part == 1, msize(tiny) mcolor(navy%20)) (scatter ci_width log10_N if part == 2, msize(tiny) mcolor(maroon%20))
graph export "comparison_ci_width.png", replace

//part 3 Power calculations for individual-level randomization
set seed 12345
set obs 10000
gen treatment = rbinomial(1,0.5)
gen y_base = rnormal(0, 1)
gen tau = runiform(0.0, 0.2)
gen Y_observed = y_base + (treatment * tau)
regress Y_observed treatment
power twomeans 0 0.1, sd(1) power(0.8) alpha(0.05)
local n_base = r(N)
display "Required sample size for a 50/50 split: " `n_base'
local n_attrition = ceil(`n_base' / (1 - 0.15))
display "To achieve an effective sample size of " `n_base' " after 15% attrition,"
display "you must recruit an initial sample size of: " `n_attrition'
power twomeans 0 0.1, sd(1) power(0.8) alpha(0.05) nratio(0.42857143)
local n_unbalanced = r(N)
display "Required sample size for a 30/70 split: " `n_unbalanced'

//part 4 Power calculations for cluster randomization
clear all
set more off
set seed 12345
capture program drop simulate_schools
program simulate_schools
    syntax, num_schools(integer) cluster_size(integer)
    clear
	set obs `num_schools'
    gen school_id = _n
	gen rand = runiform()
    sort rand
    gen treatment = (_n <= `num_schools' / 2)
	gen school_effect = rnormal(0, sqrt(0.3))
	expand `cluster_size'
    gen student_id = _n
	gen student_error = rnormal(0, sqrt(0.7))
	gen tau = runiform(0.15, 0.25)
	gen math_score = school_effect + student_error + (treatment * tau)
end
simulate_schools, num_schools(100) cluster_size(20)
display "Testing the DGP for ICC ~ 0.3:"
mixed math_score || school_id:
estat icc
display "Testing the DGP for ATE ~ 0.2:"
regress math_score treatment, vce(cluster school_id)
forvalues i = 0/9 {
    local m = 2^`i'
    quietly power twomeans 0 0.2, k1(100) k2(100) m1(`m') m2(`m') rho(0.3)
    display "Cluster Size: " `m' " | Power: " %4.3f r(power)
}
power twomeans 0 0.2, m1(15) m2(15) rho(0.3) power(0.8)

local k1 = r(K1)
local total_schools = `k1' * 2
display "Schools required for 80% power (15 students/school): " `total_schools'
power twomeans 0 0.14, m1(15) m2(15) rho(0.3) power(0.8)

local k1_adj = r(K1)
local total_schools_adj = `k1_adj' * 2
display "Schools required assuming 70% compliance: " `total_schools_adj'