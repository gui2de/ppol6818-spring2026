***Stata 3_Qingfeng_qy111***


****************************************************
* Part 1: Sampling noise in a fixed population
****************************************************
cd "C:\Users\余青锋\OneDrive\Experimental Design\Peer Review 2\ppol6818-spring2026\stata3\part1"

clear all
set more off


****************************************************
* Step 1. Create a fixed population of 10,000
* - set seed for reproducibility
* - generate random X ~ N(0,1)
* - generate Y = 1 + 0.5*X + u, u ~ N(0,1)
* - save the population dataset
****************************************************

set seed 2024
set obs 10000

gen id = _n
gen x  = rnormal(0, 2)        // X ~ N(0, 4): mean 0, sd 2
gen u  = rnormal(0, 1.5)      // error term: sd = 1.5
gen y  = 3 + 0.8*x + u        // true intercept = 3, true beta = 0.8

save "part1_population.dta", replace


****************************************************
* Step 2. Define a program that:
* (a) loads the fixed population
* (b) draws a random sample of size n
* (c) regresses y on x
* (d) returns N, beta, SEM, p-value, and CI in r()
****************************************************

capture program drop part1_reg
program define part1_reg, rclass
    syntax, n(integer)

    use "part1_population.dta", clear
    sample `n', count

    regress y x

    return scalar N      = e(N)
    return scalar beta   = _b[x]
    return scalar sem    = _se[x]
    return scalar pvalue = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar lb     = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar ub     = _b[x] + invttail(e(df_r), 0.025)*_se[x]
end


****************************************************
* Step 3. Use simulate to run the program 500 times
* at each sample size: N = 10, 100, 1000, 10000
* Save each set of results separately
****************************************************

simulate N=r(N) beta=r(beta) sem=r(sem) pvalue=r(pvalue) lb=r(lb) ub=r(ub), ///
    reps(500): part1_reg, n(10)
gen sample_size = 10
save "part1_results_10.dta", replace

simulate N=r(N) beta=r(beta) sem=r(sem) pvalue=r(pvalue) lb=r(lb) ub=r(ub), ///
    reps(500): part1_reg, n(100)
gen sample_size = 100
save "part1_results_100.dta", replace

simulate N=r(N) beta=r(beta) sem=r(sem) pvalue=r(pvalue) lb=r(lb) ub=r(ub), ///
    reps(500): part1_reg, n(1000)
gen sample_size = 1000
save "part1_results_1000.dta", replace

simulate N=r(N) beta=r(beta) sem=r(sem) pvalue=r(pvalue) lb=r(lb) ub=r(ub), ///
    reps(500): part1_reg, n(10000)
gen sample_size = 10000
save "part1_results_10000.dta", replace


****************************************************
* Step 4. Append all results into one dataset of
* 2,000 regression results and save
****************************************************

use "part1_results_10.dta", clear
append using "part1_results_100.dta"
append using "part1_results_1000.dta"
append using "part1_results_10000.dta"

save "part1_all_results.dta", replace


****************************************************
* Step 5a. Figure: distribution of beta estimates
* by sample size using a box plot
* True beta = 0.5 shown as a reference line
****************************************************

graph box beta, over(sample_size) ///
    yline(0.8, lcolor(red) lpattern(dash)) ///
    title("Distribution of Beta Estimates by Sample Size") ///
    ytitle("Estimated beta on x") ///
    note("Red dashed line = true beta (0.8)")

graph export "part1_beta_figure.png", replace


****************************************************
* Step 5b. Table: mean beta, SD of beta, mean SEM,
* and mean CI width by sample size
****************************************************

gen ci_width = ub - lb

collapse (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
         (sd)   sd_beta=beta, ///
         by(sample_size)

list sample_size mean_beta sd_beta mean_sem mean_ci_width, noobs sep(0)

save "part1_table_results.dta", replace


****************************************************
* Part 2: Sampling noise in an infinite superpopulation
****************************************************
cd "C:\Users\余青锋\OneDrive\Experimental Design\Peer Review 2\ppol6818-spring2026\stata3\part2"

clear all
set more off


****************************************************
* Step 1. Define a program that:
* (a) randomly creates a fresh dataset of size n
*     following the same DGP as Part 1:
*     X ~ N(0,4), u ~ N(0,2.25), Y = 3 + 0.8*X + u
* (b) regresses Y on X
* (c) returns N, beta, SEM, p-value, and CI in r()
****************************************************

set seed 2025
capture program drop part2_reg
program define part2_reg, rclass
    syntax, n(integer)

    clear
    set obs `n'

    gen x = rnormal(0, 2)       // X ~ N(0, 4): sd = 2
    gen u = rnormal(0, 1.5)     // error term: sd = 1.5
    gen y = 3 + 0.8*x + u      // true intercept = 3, true beta = 0.8

    regress y x

    return scalar N      = e(N)
    return scalar beta   = _b[x]
    return scalar sem    = _se[x]
    return scalar pvalue = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar lb     = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar ub     = _b[x] + invttail(e(df_r), 0.025)*_se[x]
end


****************************************************
* Step 2. Using simulate, run the program 500 times
* at the first twenty powers of two (4, 8, 16 ...)
* and at N = 10, 100, 1000, 10000, 100000, 1000000
* Append results incrementally into one tempfile
****************************************************

tempfile allresults
save `allresults', emptyok replace

local ns 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 ///
         65536 131072 262144 524288 1048576 2097152 ///
         10 100 1000 10000 100000 1000000

foreach n of local ns {
    simulate N=r(N) beta=r(beta) sem=r(sem) pvalue=r(pvalue) lb=r(lb) ub=r(ub), ///
        reps(500): part2_reg, n(`n')

    gen sample_size = `n'

    append using `allresults'
    save `allresults', replace
}

use `allresults', clear
save "part2_all_results.dta", replace


****************************************************
* Step 3a. Figure: distribution of beta estimates
* by sample size using a box plot
* Only plot powers-of-two samples for readability;
* true beta = 0.8 shown as a red reference line
****************************************************

graph box beta if inlist(sample_size, 4, 16, 64, 256, 1024, 4096, 16384, 65536, 262144, 1048576), ///
    over(sample_size) ///
    yline(0.8, lcolor(red) lpattern(dash)) ///
    title("Distribution of Beta Estimates by Sample Size") ///
    ytitle("Estimated beta on x") ///
    note("Red dashed line = true beta (0.8). Powers-of-two samples shown.")

graph export "part2_beta_figure.png", replace


****************************************************
* Step 3b. Table: mean beta, SD of beta, mean SEM,
* and mean CI width by sample size
****************************************************

gen ci_width = ub - lb

collapse (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
         (sd)   sd_beta=beta, ///
         by(sample_size)

gsort sample_size
list sample_size mean_beta sd_beta mean_sem mean_ci_width, noobs sep(0)

save "part2_table_results.dta", replace


****************************************************
* Part 3: Power calculations for individual-level
*         randomization
****************************************************
cd "C:\Users\余青锋\OneDrive\Experimental Design\Peer Review 2\ppol6818-spring2026\stata3\part3"

clear all
set more off


****************************************************
* Step 1 & 2. Define a program implementing the DGP:
* - Y0 ~ N(0,1): baseline outcome
* - tau ~ Uniform(0.0, 0.2): heterogeneous treatment
*   effects (average treatment effect = 0.1 sd)
* - treat: Bernoulli with probability ptreat
* - attrit: optional uniform attrition rate
* - Outcome: Y = Y0 + tau * treat (post-attrition)
****************************************************

set seed 2024
capture program drop part3_sim
program define part3_sim, rclass
    syntax, n(integer) ptreat(real) [attrit(real 0)]

    clear
    set obs `n'

    * Baseline outcome: N(0,1)
    gen y0 = rnormal(0, 1)

    * Heterogeneous treatment effect: Uniform(0, 0.2)
    gen tau = runiform(0, 0.2)

    * Treatment assignment
    gen treat = (runiform() < `ptreat')

    * Observed outcome
    gen y = y0 + tau * treat

    * Apply attrition if specified (equal across arms)
    if `attrit' > 0 {
        gen retained = (runiform() > `attrit')
        keep if retained == 1
    }

    regress y treat

    * Store pvalue in a local first to avoid r() being overwritten
    local pval = 2*ttail(e(df_r), abs(_b[treat]/_se[treat]))

    return scalar N      = e(N)
    return scalar pvalue = `pval'
    return scalar reject = (`pval' < 0.05)
end


****************************************************
* Step 3. Scenario A: 50% treated, no attrition
* Step size 250, reps 200 for speed
* (~20 iterations total for this scenario)
****************************************************

tempname res_a
postfile `res_a' N power using "part3_scenario_a.dta", replace

forvalues n = 250(250)5000 {
    quietly simulate reject=r(reject), reps(200): ///
        part3_sim, n(`n') ptreat(0.5)
    quietly summarize reject
    post `res_a' (`n') (r(mean))
}

postclose `res_a'

use "part3_scenario_a.dta", clear
list N power, noobs sep(0)
gen meets80 = (power >= 0.80)
summarize N if meets80 == 1, meanonly
display "Scenario A — min N for 80% power (50% treated): " r(min)


****************************************************
* Step 4. Scenario B: 50% treated, 15% attrition
****************************************************

tempname res_b
postfile `res_b' N power using "part3_scenario_b.dta", replace

forvalues n = 250(250)6000 {
    quietly simulate reject=r(reject), reps(200): ///
        part3_sim, n(`n') ptreat(0.5) attrit(0.15)
    quietly summarize reject
    post `res_b' (`n') (r(mean))
}

postclose `res_b'

use "part3_scenario_b.dta", clear
list N power, noobs sep(0)
gen meets80 = (power >= 0.80)
summarize N if meets80 == 1, meanonly
display "Scenario B — min N for 80% power (50% treated + 15% attrition): " r(min)


****************************************************
* Step 5. Scenario C: 30% treated, no attrition
****************************************************

tempname res_c
postfile `res_c' N power using "part3_scenario_c.dta", replace

forvalues n = 250(250)7000 {
    quietly simulate reject=r(reject), reps(200): ///
        part3_sim, n(`n') ptreat(0.3)
    quietly summarize reject
    post `res_c' (`n') (r(mean))
}

postclose `res_c'

use "part3_scenario_c.dta", clear
list N power, noobs sep(0)
gen meets80 = (power >= 0.80)
summarize N if meets80 == 1, meanonly
display "Scenario C — min N for 80% power (30% treated): " r(min)


****************************************************
* Part 4: Power calculations for cluster randomization
****************************************************
cd "C:\Users\余青锋\OneDrive\Experimental Design\Peer Review 2\ppol6818-spring2026\stata3\part4"

clear all
set more off


****************************************************
* Step 1-4. Define a program implementing the DGP:
* - Y = math score for each student
* - School-level random effect generates ICC ~ 0.3:
*   var_school = 0.6, var_student = 1.4 → ICC = 0.6/2.0
* - Treatment assigned at school level (50/50 split)
* - tau ~ Uniform(0.15, 0.25): ATE = 0.2 sd
* - Optional: adopt controls share of treated schools
*   that actually implement the treatment
****************************************************

set seed 2024
capture program drop part4_sim
program define part4_sim, rclass
    syntax, clusters(integer) csize(integer) [adopt(real 1)]

    clear
    set obs `clusters'
    gen school_id = _n

    * School-level random effect (var = 0.6)
    gen u_school = rnormal(0, sqrt(0.6))

    * Treatment assigned to first half of schools
    gen treat_school = (_n <= `clusters' / 2)

    * Expand to student level
    expand `csize'
    bysort school_id: gen student_id = _n

    * Student-level random effect (var = 1.4)
    * ICC = 0.6 / (0.6 + 1.4) = 0.3 ✓
    gen u_student = rnormal(0, sqrt(1.4))

    * Heterogeneous treatment effect: Uniform(0.15, 0.25)
    gen tau = runiform(0.15, 0.25)

    * School adoption of treatment
    gen adopts = 1
    replace adopts = (runiform() < `adopt') if treat_school == 1

    * Outcome: treatment effect only if school adopts
    gen y = u_school + u_student + tau * treat_school * adopts

    * ITT regression with cluster-robust SE
    regress y treat_school, vce(cluster school_id)

    local pval = 2*ttail(e(df_r), abs(_b[treat_school]/_se[treat_school]))

    return scalar pvalue     = `pval'
    return scalar reject     = (`pval' < 0.05)
    return scalar N_clusters = `clusters'
    return scalar csize      = `csize'
end


****************************************************
* Step 5. Fix clusters = 200, vary cluster size
* using first 10 powers of 2 (2, 4, 8, ..., 1024)
* Examine how power changes with cluster size
****************************************************

tempname res1
postfile `res1' csize power using "part4_power_by_csize.dta", replace

local csizes 2 4 8 16 32 64 128 256 512 1024

foreach m of local csizes {
    quietly simulate reject=r(reject), reps(500): ///
        part4_sim, clusters(200) csize(`m')
    quietly summarize reject
    post `res1' (`m') (r(mean))
}

postclose `res1'

use "part4_power_by_csize.dta", clear
list csize power, noobs sep(0)


****************************************************
* Step 6. Fix cluster size = 15 students/school
* Search over number of schools to find minimum
* required for 80% power (step size = 20)
****************************************************

tempname res2
postfile `res2' clusters power using "part4_power_by_clusters.dta", replace

forvalues g = 20(20)600 {
    quietly simulate reject=r(reject), reps(500): ///
        part4_sim, clusters(`g') csize(15)
    quietly summarize reject
    post `res2' (`g') (r(mean))
}

postclose `res2'

use "part4_power_by_clusters.dta", clear
list clusters power, noobs sep(0)

gen meets80 = (power >= 0.80)
summarize clusters if meets80 == 1, meanonly
display "Required schools for 80% power (full adoption): " r(min)


****************************************************
* Step 7. Only 70% of treated schools adopt
* Extend search range to 800 schools to allow for
* the power loss from partial adoption
****************************************************

tempname res3
postfile `res3' clusters power using "part4_power_70adopt.dta", replace

forvalues g = 20(20)800 {
    quietly simulate reject=r(reject), reps(500): ///
        part4_sim, clusters(`g') csize(15) adopt(0.7)
    quietly summarize reject
    post `res3' (`g') (r(mean))
}

postclose `res3'

use "part4_power_70adopt.dta", clear
list clusters power, noobs sep(0)

gen meets80 = (power >= 0.80)
summarize clusters if meets80 == 1, meanonly
display "Required schools for 80% power (70% adoption): " r(min)