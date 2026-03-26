* Part 2: Sampling noise in an infinite superpopulation

// kenshi: added wd global to run on my local 
if c(username) == "kkawade" {
    global boxd "/Users/kkawade/Library/CloudStorage/Box-Box/ppol6818/perev"
}

// Replace username and path below
if c(username) == "qy112" { 
    global boxd  "replace here with your boxfile path"  
}

* local directory
if c(username) == "kkawade" {
    global wd "/Users/kkawade/gu_class/ppol6818/perev"
}

// Replace username and path below
if c(username) == "yqy" { 
    global wd  "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-stata3"  
}

cd "$boxd"

****************************************************
*** 1 ***
****************************************************
clear all
set more off

capture program drop sim_superpop
program define sim_superpop, rclass
    syntax , N(integer)

    clear
    set obs `n'

    * DGP
    gen x = rnormal(0,1)
    gen u = rnormal(0,2)
    gen y = 1 + 2*x + u

    regress y x

    return scalar N    = e(N)
    return scalar beta = _b[x]
    return scalar sem  = _se[x]
    return scalar pval = 2 * ttail(e(df_r), abs(_b[x] / _se[x]))
    return scalar lb   = _b[x] - invttail(e(df_r), 0.025) * _se[x]
    return scalar ub   = _b[x] + invttail(e(df_r), 0.025) * _se[x]
end

****************************************************
*** 2 ***
****************************************************
local pow2_list 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152
local pow10_list 10 100 1000 10000 100000 1000000

tempfile powers
clear
save `powers', emptyok

local seed_counter = 1000

foreach n of local pow2_list {
    di "Running power-of-two simulations for N = `n'"
    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
        reps(500) seed(`seed_counter') nodots: sim_superpop, n(`n')
    gen sample_group = "power_of_two"
    gen designN = `n'
    append using `powers'
    save `powers', replace
    local seed_counter = `seed_counter' + 1
}

foreach n of local pow10_list {
    di "Running power-of-ten simulations for N = `n'"
    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
        reps(500) seed(`seed_counter') nodots: sim_superpop, n(`n')
    gen sample_group = "power_of_ten"
    gen designN = `n'
    append using `powers'
    save `powers', replace
    local seed_counter = `seed_counter' + 1
}

use `powers', clear
order designN sample_group N beta sem pval lb ub
sort designN
gen ci_width = ub - lb

save "Part2_Q2.dta", replace

count
tab designN

****************************************************
*** 3 ***
****************************************************
* Figure
preserve
collapse ///
    (mean) mean_beta=beta ///
    (sd)   sd_beta=beta ///
    (p5)   p5_beta=beta ///
    (p95)  p95_beta=beta, by(designN)

twoway ///
    (rarea p5_beta p95_beta designN, sort) ///
    (line mean_beta designN, sort) ///
    , xscale(log) ///
      yline(2, lpattern(dash)) ///
      ytitle("Estimated beta") ///
      title("Sampling variation in beta estimates by sample size") ///
      legend(order(1 "5th-95th percentile range" 2 "Mean beta"))

graph export "Part2_Q3.png", replace
restore

* Table
preserve
collapse ///
    (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
    (sd)   sd_beta=beta ///
    (p5)   p5_beta=beta ///
    (p95)  p95_beta=beta, by(designN)

format mean_beta mean_sem mean_ci_width sd_beta p5_beta p95_beta %9.4f
list, sepby(designN)

save "Part2_Q3.dta", replace
export excel using "Part2_Q3.xlsx", firstrow(variables) replace
restore

****************************************************
*** 4 ***
****************************************************
* See README

****************************************************
*** 5 ***
****************************************************
* Part 1 summary
use "Part1_Q4.dta", clear
gen ci_width = ub - lb

collapse ///
    (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
    (sd)   sd_beta=beta, by(sample_size)

rename sample_size designN
gen source = "Part 1 fixed population"

tempfile p1sum
save `p1sum', replace

* Part 2 summary
use "Part2_Q2.dta", clear
keep if inlist(designN, 10, 100, 1000, 10000)

collapse ///
    (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
    (sd)   sd_beta=beta, by(designN)

gen source = "Part 2 superpopulation"

tempfile p2sum
save `p2sum', replace

* Append together
use `p1sum', clear
append using `p2sum'
sort designN source

save "Part2_Q5_comparison.dta", replace

list source designN mean_beta sd_beta mean_sem mean_ci_width, sepby(designN)

export excel using "Part2_Q5_comparison.xlsx", firstrow(variables) replace

* Figure 1: Compare mean SEM
twoway ///
    (connected mean_sem designN if source=="Part 1 fixed population", sort) ///
    (connected mean_sem designN if source=="Part 2 superpopulation", sort) ///
    , xscale(log) ///
      ytitle("Mean SEM") ///
      xtitle("Sample size (log scale)") ///
      title("Mean SEM: Part 1 vs Part 2") ///
      legend(order(1 "Part 1 fixed population" 2 "Part 2 superpopulation"))

graph export "Part2_Q5_meanSEM.png", replace

* Figure 2: Compare mean confidence interval width
twoway ///
    (connected mean_ci_width designN if source=="Part 1 fixed population", sort) ///
    (connected mean_ci_width designN if source=="Part 2 superpopulation", sort) ///
    , xscale(log) ///
      ytitle("Mean confidence interval width") ///
      xtitle("Sample size (log scale)") ///
      title("Mean CI width: Part 1 vs Part 2") ///
      legend(order(1 "Part 1 fixed population" 2 "Part 2 superpopulation"))

graph export "Part2_Q5_meanCI.png", replace
