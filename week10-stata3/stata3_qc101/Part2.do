// Stata3_Qingyue Chen
// Part2

* Sampling noise in an infinite superpopulation
clear all
set more off

global BOXPATH "C:\Users\86186\Box\stata3"

* 1. Define program for superpopulation simulation
capture program drop sim_super
program define sim_super, rclass
    syntax, N(integer)

    clear
    set obs `n'

    * Data generating process
    gen x = rnormal(0,1)
    gen u = rnormal(0,2)
    gen y = 1 + 2.5*x + u

    * Regression
    regress y x

    * Return results
    return scalar N     = e(N)
    return scalar beta  = _b[x]
    return scalar sem   = _se[x]
    return scalar pval  = 2 * ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar ci_lo = _b[x] - invttail(e(df_r), 0.025) * _se[x]
    return scalar ci_hi = _b[x] + invttail(e(df_r), 0.025) * _se[x]
    return scalar width = return(ci_hi) - return(ci_lo)
end

* 2. Run simulation for powers of two + powers of ten

tempfile allresults
save `allresults', emptyok replace

local sizes ///
4 8 10 16 32 64 100 128 256 512 1000 1024 2048 4096 8192 ///
10000 16384 32768 65536 100000 131072 262144 524288 1000000 1048576 2097152

foreach n of local sizes {
    di "Running simulation for N = `n'"

    tempfile sim`n'

    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ///
        ci_lo=r(ci_lo) ci_hi=r(ci_hi) width=r(width), ///
        reps(500) seed(`=1000+`n''): sim_super, n(`n')

    gen sample_size = `n'
    save `sim`n'', replace

    use `allresults', clear
    append using `sim`n''
    save `allresults', replace
}

use `allresults', clear
order sample_size N beta sem pval ci_lo ci_hi width

save "$BOXPATH\part2_simulation_results.dta", replace

* 3. Graph and table
* graph1
use "$BOXPATH\part2_simulation_results.dta", clear

egen group = group(sample_size)
label define gs ///
1 "4" 2 "8" 3 "10" 4 "16" 5 "32" 6 "64" 7 "100" 8 "128" 9 "256" 10 "512" ///
11 "1000" 12 "1024" 13 "2048" 14 "4096" 15 "8192" 16 "10000" 17 "16384" ///
18 "32768" 19 "65536" 20 "100000" 21 "131072" 22 "262144" 23 "524288" ///
24 "1000000" 25 "1048576" 26 "2097152"
label values group gs

graph box beta, over(group, label(angle(60) labsize(small))) ///
    yline(2.5, lpattern(dash) lcolor(red)) ///
    title("Distribution of beta estimates by sample size") ///
    ytitle("Estimated beta")

graph export "$BOXPATH\part2_beta_boxplot.png", replace

* table1
use "$BOXPATH\part2_simulation_results.dta", clear

table sample_size, ///
    statistic(mean beta) ///
    statistic(sd beta) ///
    statistic(mean sem) ///
    statistic(mean width) ///
    nformat(%9.4f)

* 4. Comparison tables
* Part 1 summary
use "$BOXPATH\simulation_results.dta", clear
collapse (mean) mean_beta=beta mean_sem=sem mean_width=width ///
         (sd) sd_beta=beta, by(sample_size)
gen part = "Part 1: Fixed population"
tempfile p1
save `p1'

* Part 2 summary, keep comparable N only
use "$BOXPATH\part2_simulation_results.dta", clear
keep if inlist(sample_size, 10, 100, 1000, 10000)
collapse (mean) mean_beta=beta mean_sem=sem mean_width=width ///
         (sd) sd_beta=beta, by(sample_size)
gen part = "Part 2: Superpopulation"
tempfile p2
save `p2'

* Append and display
use `p1', clear
append using `p2'
sort sample_size part
list part sample_size mean_beta sd_beta mean_sem mean_width, clean noobs

save "$BOXPATH\comparison_table_part1_part2.dta", replace

* graph1: mean SEM
use "$BOXPATH\simulation_results.dta", clear
collapse (mean) mean_sem=sem mean_width=width mean_beta=beta, by(sample_size)
gen part = 1
tempfile p1
save `p1'

use "$BOXPATH\part2_simulation_results.dta", clear
keep if inlist(sample_size, 10, 100, 1000, 10000)
collapse (mean) mean_sem=sem mean_width=width mean_beta=beta, by(sample_size)
gen part = 2
tempfile p2
save `p2'

use `p1', clear
append using `p2'

label define partlbl 1 "Part 1: Fixed population" 2 "Part 2: Superpopulation"
label values part partlbl

twoway ///
    (line mean_sem sample_size if part==1, sort) ///
    (line mean_sem sample_size if part==2, sort), ///
    xscale(log) ///
    xtitle("Sample size (log scale)") ///
    ytitle("Mean standard error") ///
    title("Comparison of mean standard errors: Part 1 vs Part 2") ///
    legend(order(1 "Part 1" 2 "Part 2"))

graph export "$BOXPATH\compare_sem_part1_part2.png", replace

* graph2: mean CI width
twoway ///
    (line mean_width sample_size if part==1, sort) ///
    (line mean_width sample_size if part==2, sort), ///
    xscale(log) ///
    xtitle("Sample size (log scale)") ///
    ytitle("Mean confidence interval width") ///
    title("Comparison of mean CI widths: Part 1 vs Part 2") ///
    legend(order(1 "Part 1" 2 "Part 2"))

graph export "$BOXPATH\compare_ciwidth_part1_part2.png", replace
