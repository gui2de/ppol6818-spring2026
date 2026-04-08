*** ============================================================
*** Part 1: Sampling Noise in a Fixed Population
*** ==============================================================

*------------------------------------------------------------
* STEP 1
*------------------------------------------------------------
clear
set seed 12345

set obs 10000

gen X = rnormal(50, 10)

gen e = rnormal(0, 20)
gen Y = 3 + 2*X + e

save "stata3_population.dta", replace


*------------------------------------------------------------
* STEP 2: Define the sampling program
*------------------------------------------------------------

capture program drop sample_regress
program define sample_regress, rclass

    args samplesize

    use "stata3_population.dta", clear

    sample `samplesize', count

    quietly reg Y X

    mat results = r(table)

    return scalar N     = e(N)
    return scalar beta  = results[1,1]  
    return scalar sem   = results[2,1]   
    return scalar pval  = results[4,1]   
    return scalar ci_lo = results[5,1]   
    return scalar ci_hi = results[6,1]   

end

*------------------------------------------------------------
* STEP 3: Run simulate 500 times at each sample size
*------------------------------------------------------------

local sample_sizes "10 100 1000 10000"

tempfile all_results
clear
save `all_results', emptyok

foreach n of local sample_sizes {

    simulate  N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lo=r(ci_lo) ci_hi=r(ci_hi), reps(500) nodots: sample_regress `n'

    gen target_n = `n'

    append using `all_results'
    save `all_results', replace
}

use `all_results', clear
save "stata3_part1_results.dta", replace

*------------------------------------------------------------
* STEP 4: Table of Summary statistics of beta by sample size
*------------------------------------------------------------

gen beta_bias = beta - 2

gen ci_width = ci_hi - ci_lo

table target_n, stat(mean beta) stat(sd beta) stat(mean sem) stat(mean ci_width) nformat(%9.4f) name(beta_table)

estpost tabstat beta sem ci_width, by(target_n) stat(mean sd p50) columns(stats)
esttab using "stata3_part1_table.csv", replace cells("mean(fmt(4)) sd(fmt(4)) p50(fmt(4))") title("Table 1: OLS Beta Estimates by Sample Size (Part 1: Fixed Population)") noobs label
	
tabstat beta sem ci_width, by(target_n) stat(mean sd p50 min max) columns(statistics) format(%9.4f) longstub


*------------------------------------------------------------
* STEP 5: Figures
*------------------------------------------------------------

* --- Figure 1: Distribution of beta estimates by sample size ---
graph box beta, over(target_n, label(angle(0))) yline(2, lcolor(red) lpattern(dash) lwidth(medium)) title("Figure 1: Distribution of Beta Estimates by Sample Size" "(Fixed Population, 500 Replications)", size(medsmall)) ytitle("Estimated Beta") xtitle("Sample Size") note("Red dashed line = true beta (2). DGP: Y = 3 + 2X + error.") scheme(s2color)
graph export "stata3_part1_fig1_boxplot.png", replace width(1200)

* --- Figure 2: Mean beta and 95% CI band by sample size ---
preserve
collapse (mean) mean_beta=beta (sd) sd_beta=beta (mean) mean_sem=sem (mean) mean_ci_width=ci_width, by(target_n)
gen emp_lo = mean_beta - 1.96*sd_beta
gen emp_hi = mean_beta + 1.96*sd_beta

twoway (rarea emp_lo emp_hi target_n, color(gs12) sort) (line mean_beta target_n, lcolor(navy) lwidth(medium)) (yline 2, lcolor(red) lpattern(dash)), xscale(log) xlabel(10 100 1000 10000) title("Figure 2: Mean Beta Estimate ± 1.96 SD by Sample Size" "(Fixed Population)", size(medsmall)) ytitle("Beta Estimate") xtitle("Sample Size (log scale)") legend(order(2 "Mean beta" 1 "±1.96 SD band" 3 "True beta = 2")) note("Shaded band = empirical ±1.96 SD across 500 replications.") scheme(s2color)
graph export "stata3_part1_fig2_mean_ci.png", replace width(1200)
restore

* --- Figure 3: Mean SEM by sample size ---
preserve
collapse (mean) mean_sem=sem, by(target_n)
twoway line mean_sem target_n, xscale(log) xlabel(10 100 1000 10000) lcolor(maroon) lwidth(medium) title("Figure 3: Mean Standard Error of Beta by Sample Size" "(Fixed Population)", size(medsmall)) ytitle("Mean SEM") xtitle("Sample Size (log scale)") note("SEM shrinks as N increases (sampling noise falls).") scheme(s2color)
graph export "stata3_part1_fig3_sem.png", replace width(1200)
restore

