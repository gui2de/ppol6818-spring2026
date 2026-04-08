*** ============================================================
*** Part 2: Sampling Noise in an Infinite Superpopulation
*** ============================================================

*------------------------------------------------------------
* STEP 1: Define the superpopulation simulation program
*------------------------------------------------------------

capture program drop superpop_regress
program define superpop_regress, rclass

    args samplesize

    clear
    set obs `samplesize'

    gen X = rnormal(50, 10)
    gen e = rnormal(0, 20)
    gen Y = 3 + 2*X + e

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
* STEP 2
*------------------------------------------------------------

local pow2_sizes ""
forvalues k = 2/21 {
    local n = 2^`k'
    local pow2_sizes "`pow2_sizes' `n'"
}
display "Powers of 2: `pow2_sizes'"

local pow10_sizes "10 100 1000 10000 100000 1000000"

local all_sizes "`pow2_sizes' `pow10_sizes'"

*------------------------------------------------------------
* STEP 3: Run simulate 500 times at each sample size
*------------------------------------------------------------

tempfile all_results
clear
save `all_results', emptyok

foreach n of local all_sizes {

    display as text "Running 500 simulations for N = `n'..."

    simulate  N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lo=r(ci_lo) ci_hi=r(ci_hi), reps(500) nodots: superpop_regress `n'

    gen target_n = `n'

    append using `all_results'
    save `all_results', replace
}

use `all_results', clear
save "stata3_part2_results.dta", replace

*------------------------------------------------------------
* STEP 4: Table — Summary statistics of beta by sample size
*------------------------------------------------------------

gen beta_bias  = beta - 2
gen ci_width   = ci_hi - ci_lo

tabstat beta sem ci_width, by(target_n) stat(mean sd p50) columns(statistics) format(%9.4f) longstub


*------------------------------------------------------------
* STEP 5: Figures
*------------------------------------------------------------

* --- Figure 1: SD of beta (empirical SEM) by sample size ---
preserve
collapse (mean) mean_beta=beta (sd) sd_beta=beta (mean) mean_sem=sem   (mean) mean_ci_width=ci_width, by(target_n)

gen is_pow10 = 0
foreach n in 10 100 1000 10000 100000 1000000 {
    replace is_pow10 = 1 if target_n == `n'
}

twoway (scatter sd_beta target_n if is_pow10==0, mcolor(navy) msize(small) msymbol(circle)) (scatter sd_beta target_n if is_pow10==1, mcolor(orange) msize(medium) msymbol(diamond)), xscale(log) xtitle("Sample Size (log scale)") ytitle("SD of Beta Estimates (= empirical SEM)") title("Figure 4: Empirical SEM by Sample Size" "(Superpopulation, 500 Replications)", size(medsmall)) legend(order(1 "Powers of 2" 2 "Powers of 10")) note("SD of beta estimates across 500 replications. Shrinks as N grows.") scheme(s2color)
graph export "stata3_part2_fig1_sem_by_n.png", replace width(1200)

* --- Figure 2: Mean CI width by sample size ---
twoway (line mean_ci_width target_n, sort lcolor(maroon) lwidth(medium)), xscale(log) xtitle("Sample Size (log scale)") ytitle("Mean Width of 95% CI") title("Figure 5: Mean CI Width by Sample Size" "(Superpopulation)", size(medsmall)) note("CI width shrinks at rate 1/sqrt(N).") scheme(s2color)
graph export "stata3_part2_fig2_ciwidth.png", replace width(1200)
restore


*------------------------------------------------------------
* STEP 6: Comparison of Part 1 (fixed pop) and Part 2 (superpop)
*------------------------------------------------------------

use "stata3_part1_results.dta", clear
gen source = "Fixed Population"
save "stata3_part1_tagged.dta", replace

use "stata3_part2_results.dta", clear
gen source = "Superpopulation"

keep if inlist(target_n, 10, 100, 1000, 10000)
append using "stata3_part1_tagged.dta"

gen ci_width = ci_hi - ci_lo

table target_n source, stat(mean sem) stat(mean ci_width) nformat(%9.4f)

preserve
collapse (sd) sd_beta=beta (mean) mean_sem=sem, by(target_n source)

twoway (line sd_beta target_n if source=="Fixed Population", lcolor(navy) lwidth(medium) lpattern(solid)) (line sd_beta target_n if source=="Superpopulation", lcolor(orange) lwidth(medium) lpattern(dash)), xscale(log) xlabel(10 100 1000 10000) xtitle("Sample Size (log scale)") ytitle("SD of Beta (empirical SEM)") title("Figure 6: Comparison of Empirical SEM" "Fixed Population vs Superpopulation", size(medsmall)) legend(order(1 "Fixed Population" 2 "Superpopulation")) note("Fixed population: sampling from 10,000 obs." "Superpopulation: new draws each replication.") scheme(s2color)
graph export "stata3_part2_fig3_comparison.png", replace width(1200)
restore
