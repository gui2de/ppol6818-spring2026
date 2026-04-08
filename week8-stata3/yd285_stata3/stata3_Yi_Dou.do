****************************************************
* Part 1: Sampling noise in a fixed population
****************************************************
cd "C:\Users\ASUS\Desktop\research_design\assignments\stata3\part1"

clear all
set more off

****************************************************
* Step 1. Create a fixed population of 10,000
* - generate random X
* - generate Y from a true relationship + error
* - save the population dataset
****************************************************

set seed 6818
set obs 10000

gen id = _n
gen x  = rnormal(0,1)
gen u  = rnormal(0,1)
gen y  = 1 + 0.5*x + u

save "part1_population.dta", replace


****************************************************
* Step 2. Define a program that:
* (a) loads the data
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
* for N = 10, 100, 1000, 10000
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
* Step 4. Load the 2,000 regression results into Stata
****************************************************

use "part1_results_10.dta", clear
append using "part1_results_100.dta"
append using "part1_results_1000.dta"
append using "part1_results_10000.dta"

save "part1_all_results.dta", replace

****************************************************
* Step 5a. Create at least one figure showing
* variation in beta estimates by sample size
****************************************************

graph box beta, over(sample_size) ///
    title("Distribution of beta estimates by sample size") ///
    ytitle("Estimated beta on x")  
	
graph export "part1_beta_figure.png", replace


****************************************************
* Step 5b. Create at least one table showing
* beta variation, SEM, and confidence interval width
* by sample size
****************************************************

gen ci_width = ub - lb

collapse (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
         (sd)   sd_beta=beta sd_sem=sem sd_ci_width=ci_width, ///
         by(sample_size)

list sample_size mean_beta sd_beta mean_sem mean_ci_width, noobs sep(0)

save "part1_table_results.dta", replace


****************************************************
* Part 2: Sampling noise in an infinite superpopulation
****************************************************

clear all
set more off
cd "C:\Users\ASUS\Desktop\research_design\assignments\stata3\part2"

****************************************************
* Step 1a. Define a program that randomly creates
* a dataset of size n following the DGP from Part 1
* including a true relationship and an error source
****************************************************
set seed 6818
capture program drop part2_reg
program define part2_reg, rclass
    syntax, n(integer)

    clear
    set obs `n'

    gen x = rnormal(0,1)
    gen u = rnormal(0,1)
    gen y = 1 + 0.5*x + u


****************************************************
* Step 1(b). Perform a regression of Y on one X
****************************************************

    regress y x


****************************************************
* Step 1(c). Return N, beta, SEM, p-value, and
* confidence intervals into r()
****************************************************

    return scalar N      = e(N)
    return scalar beta   = _b[x]
    return scalar sem    = _se[x]
    return scalar pvalue = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar lb     = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar ub     = _b[x] + invttail(e(df_r), 0.025)*_se[x]
end


****************************************************
* Step 2. Using simulate, run the program 500
* times each at the first twenty powers of two
* (4, 8, 16, ...) and at N = 10, 100, 1000,
* 10000, 100000, 1000000
****************************************************

tempfile allresults
save `allresults', emptyok replace

local ns 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 ///
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
* Step 3a. Create at least one figure showing
* variation in beta estimates depending on sample size
****************************************************

graph box beta, over(sample_size) ///
    title("Distribution of beta estimates by sample size") ///
    ytitle("Estimated beta on x") 

graph export "part2_beta_figure.png", replace


****************************************************
* Step 3b. Create at least one table showing
* variation in beta estimates, SEM, and confidence
* intervals as N gets larger
****************************************************

gen ci_width = ub - lb

collapse (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
         (sd)   sd_beta=beta sd_sem=sem sd_ci_width=ci_width, ///
         by(sample_size)

list sample_size mean_beta sd_beta mean_sem mean_ci_width, noobs sep(0)

save "part2_table_results.dta", replace

****************************************************
* Part 3: Power calculations for individual-level randomization
****************************************************

clear all
set more off
cd "C:\Users\ASUS\Desktop\research_design\assignments\stata3\part3"



****************************************************
* Step 1&2. Develop a data generating process for Y
* - Y is normally disturbed around 0 with sd = 1
* - individual treatment effects are uniformly
*   distributed between 0.0 and 0.2 sd
****************************************************
set seed 6818
capture program drop part3_power
program define part3_power, rclass
    syntax, n(integer) ptreat(real) [attrit(real 0)]

    clear
    set obs `n'

    * Baseline outcome
    gen y0 = rnormal(0,1)

    * Individual treatment effect: Uniform(0, 0.2)
    gen tau = runiform(0,0.2)

    * Treatment assignment
    gen treat = (runiform() < `ptreat')

    * Outcome
    gen y = y0 + tau*treat

    * Attrition (same rate in treatment and control)
    if `attrit' > 0 {
        gen keep = (runiform() > `attrit')
        keep if keep == 1
    }

    regress y treat

    return scalar pvalue = 2*ttail(e(df_r), abs(_b[treat]/_se[treat]))
    return scalar reject = (return(pvalue) < 0.05)
    return scalar N      = e(N)
end


****************************************************
* Step 3. The proportion treated is 0.5
* Calculate the number of individuals required to
* reach 80% power to detect a 0.1 sd treatment effect
****************************************************

tempname results1
postfile `results1' N power using "part3_power_50pct.dta", replace

forvalues n = 50(50)5000 {
    quietly simulate reject=r(reject), reps(500): ///
        part3_power, n(`n') ptreat(0.5)

    quietly summarize reject
    local power = r(mean)

    post `results1' (`n') (`power')
}

postclose `results1'

use "part3_power_50pct.dta", clear
list, noobs sep(0)

gen meets80 = (power >= 0.80)
list N power if meets80 == 1, noobs sep(0)

summarize N if meets80 == 1, meanonly
display "Required N for 80% power with 50% treated = " r(min)


****************************************************
* Step 4. Now assume 15% of the sample will attrite
* How does this change the sample size calculation?
****************************************************

tempname results2
postfile `results2' N power using "part3_power_50pct_attrition.dta", replace

forvalues n = 50(50)6000 {
    quietly simulate reject=r(reject), reps(500): ///
        part3_power, n(`n') ptreat(0.5) attrit(0.15)

    quietly summarize reject
    local power = r(mean)

    post `results2' (`n') (`power')
}

postclose `results2'

use "part3_power_50pct_attrition.dta", clear
list, noobs sep(0)

gen meets80 = (power >= 0.80)
list N power if meets80 == 1, noobs sep(0)

summarize N if meets80 == 1, meanonly
display "Required N for 80% power with 15% attrition = " r(min)


****************************************************
* Step 5. Now assume only 30% of the sample can
* receive treatment. How does this change the sample
* size needed for 80% power?
****************************************************

tempname results3
postfile `results3' N power using "part3_power_30pct_treated.dta", replace

forvalues n = 50(50)7000 {
    quietly simulate reject=r(reject), reps(500): ///
        part3_power, n(`n') ptreat(0.3)

    quietly summarize reject
    local power = r(mean)

    post `results3' (`n') (`power')
}

postclose `results3'

use "part3_power_30pct_treated.dta", clear
list, noobs sep(0)

gen meets80 = (power >= 0.80)
list N power if meets80 == 1, noobs sep(0)

summarize N if meets80 == 1, meanonly
display "Required N for 80% power with 30% treated = " r(min)

****************************************************
* Part 4: Power calculations for cluster randomization
****************************************************

clear all
set more off
cd "C:\Users\ASUS\Desktop\research_design\assignments\stata3\part4"


****************************************************
* Step 1-4. Develop a data generating process for Y
* (math score) in a school with school-level treatment
* assignment. The function allows the number of
* clusters and cluster size to vary, and generates
* data with ICC approximately 0.3
****************************************************
set seed 6818
capture program drop part4_power
program define part4_power, rclass
    syntax, clusters(integer) csize(integer) [adopt(real 1)]

    clear
    set obs `clusters'
    gen school_id = _n

    * School-level random effect and treatment assignment
    gen school_shock = rnormal(0, sqrt(0.3))
    gen treat_school = (_n <= `clusters'/2)

    * Expand to students within schools
    expand `csize'
    bysort school_id: gen student_id = _n

    * Individual-level random effect
    gen student_shock = rnormal(0, sqrt(0.7))

    * Individual treatment effect: Uniform(0.15, 0.25)
    gen tau = runiform(0.15, 0.25)

    * School adoption of treatment
	gen adopts = 1
	replace adopts = (runiform() < `adopt') if treat_school == 1

	* Outcome: treatment effect only appears if a treated school adopts
	gen y = school_shock + student_shock + tau*treat_school*adopts

	* Estimate ITT effect using assigned treatment
	regress y treat_school, vce(cluster school_id)

	return scalar pvalue = 2*ttail(e(df_r), abs(_b[treat_school]/_se[treat_school]))
	return scalar reject = (return(pvalue) < 0.05)
    return scalar N_clusters = `clusters'
    return scalar cluster_size = `csize'
end


****************************************************
* Step 5. Holding the number of clusters fixed at
* 200, examine what happens to power when cluster
* size increases (first 10 powers of 2)
****************************************************

tempname results1
postfile `results1' cluster_size power using "part4_power_by_cluster_size.dta", replace

local csizes 2 4 8 16 32 64 128 256 512 1024

foreach m of local csizes {
    quietly simulate reject=r(reject), reps(500): ///
        part4_power, clusters(200) csize(`m')

    quietly summarize reject
    local power = r(mean)

    post `results1' (`m') (`power')
}

postclose `results1'

use "part4_power_by_cluster_size.dta", clear
list, noobs sep(0)


****************************************************
* Step 6. Holding cluster size fixed at 15,
* calculate how many schools are needed to reach
* 80% power to detect a 0.2 sd treatment effect
****************************************************

tempname results2
postfile `results2' clusters power using "part4_power_by_clusters.dta", replace

forvalues g = 20(10)500 {
    quietly simulate reject=r(reject), reps(500): ///
        part4_power, clusters(`g') csize(15)

    quietly summarize reject
    local power = r(mean)

    post `results2' (`g') (`power')
}

postclose `results2'

use "part4_power_by_clusters.dta", clear
list, noobs sep(0)

gen meets80 = (power >= 0.80)
list clusters power if meets80 == 1, noobs sep(0)

summarize clusters if meets80 == 1, meanonly
display "Required number of schools for 80% power = " r(min)


****************************************************
* Step 7. Now assume only 70% of the schools
* actually adopt the treatment. Calculate how many
* schools are needed now to get 80% power
****************************************************

tempname results3
postfile `results3' clusters power using "part4_power_by_clusters_70adopt.dta", replace

forvalues g = 20(10)800 {
    quietly simulate reject=r(reject), reps(500): ///
        part4_power, clusters(`g') csize(15) adopt(0.7)

    quietly summarize reject
    local power = r(mean)

    post `results3' (`g') (`power')
}

postclose `results3'

use "part4_power_by_clusters_70adopt.dta", clear
list, noobs sep(0)

gen meets80 = (power >= 0.80)
list clusters power if meets80 == 1, noobs sep(0)

summarize clusters if meets80 == 1, meanonly
display "Required number of schools for 80% power with 70% adoption = " r(min)