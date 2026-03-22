************************************************************
* Stata Assignment 3
* Part 1: Sampling Noise in a Fixed Population
* Part 2: Sampling Noise in an Infinite Superpopulation
* Author: Maimoona Subhani 
************************************************************

clear all
set more off

************************************************************
* Set global folder path
************************************************************

global folder "C:/Users/maimo/OneDrive/Desktop/Semester 2/Experimental Design & Implement/Stata 3 assignment"

************************************************************
* PART 1: Sampling Noise in a Fixed Population
************************************************************

************************************************************
* 1. Create fixed population of 10,000 observations
************************************************************

set seed 12345
set obs 10000

gen id = _n
gen x = rnormal(0,1)
gen u = rnormal(0,2)

* True data generating process
gen y = 2 + 1.5*x + u

save "$folder/population_data.dta", replace

************************************************************
* 2. Define simulation program for Part 1
************************************************************

capture program drop regsim
program define regsim, rclass
    syntax , N(integer)

    * Load fixed population
    use "$folder/population_data.dta", clear

    * Randomly sample N observations
    sample `n', count

    * Run regression
    regress y x

    * Return requested statistics
    return scalar N    = e(N)
    return scalar beta = _b[x]
    return scalar sem  = _se[x]
    return scalar pval = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar lb   = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar ub   = _b[x] + invttail(e(df_r), 0.025)*_se[x]
end

************************************************************
* 3. Run simulations for Part 1
************************************************************

* N = 10
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
    reps(500) seed(101): regsim, n(10)
gen sample_size = 10
save "$folder/sim_n10.dta", replace

* N = 100
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
    reps(500) seed(102): regsim, n(100)
gen sample_size = 100
save "$folder/sim_n100.dta", replace

* N = 1000
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
    reps(500) seed(103): regsim, n(1000)
gen sample_size = 1000
save "$folder/sim_n1000.dta", replace

* N = 10000
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
    reps(500) seed(104): regsim, n(10000)
gen sample_size = 10000
save "$folder/sim_n10000.dta", replace

************************************************************
* 4. Combine Part 1 simulation results
************************************************************

use "$folder/sim_n10.dta", clear
append using "$folder/sim_n100.dta"
append using "$folder/sim_n1000.dta"
append using "$folder/sim_n10000.dta"

gen part = 1
gen ci_width = ub - lb

save "$folder/all_sim_results.dta", replace

************************************************************
* 5. Figure for Part 1
************************************************************

graph box beta, over(sample_size) ///
    yline(1.5) ///
    title("Part 1: Distribution of Beta Estimates by Sample Size") ///
    ytitle("Estimated beta on x") ///
    note("True beta = 1.5")

graph export "$folder/beta_boxplot_part1.png", replace

************************************************************
* 6. Summary table for Part 1
************************************************************

preserve
collapse ///
    (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
    (sd) sd_beta=beta ///
    (p50) median_beta=beta, by(sample_size)

sort sample_size
list, clean

export delimited using "$folder/simulation_summary_table_part1.csv", replace
restore

************************************************************
* PART 2: Sampling Noise in an Infinite Superpopulation
************************************************************

************************************************************
* 7. Define simulation program for Part 2
************************************************************

capture program drop regsim_super
program define regsim_super, rclass
    syntax , N(integer)

    clear
    set obs `n'

    * Generate fresh data from same DGP as Part 1
    gen x = rnormal(0,1)
    gen u = rnormal(0,2)
    gen y = 2 + 1.5*x + u

    * Run regression
    regress y x

    * Return requested statistics
    return scalar N    = e(N)
    return scalar beta = _b[x]
    return scalar sem  = _se[x]
    return scalar pval = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar lb   = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar ub   = _b[x] + invttail(e(df_r), 0.025)*_se[x]
end

************************************************************
* 8. Run simulations for Part 2
************************************************************

local sizes 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 10 100 1000 10000 100000 1000000

local first = 1

foreach n of local sizes {

    di "Running simulations for N = `n'"

    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
        reps(500) seed(`=1000+`n''): regsim_super, n(`n')

    gen sample_size = `n'
    gen part = 2
    gen ci_width = ub - lb

    save "$folder/part2_n`n'.dta", replace

    if `first' == 1 {
        save "$folder/part2_all_sim_results.dta", replace
        local first = 0
    }
    else {
        append using "$folder/part2_all_sim_results.dta"
        save "$folder/part2_all_sim_results.dta", replace
    }
}

************************************************************
* 9. Clean and save Part 2 combined results
************************************************************

use "$folder/part2_all_sim_results.dta", clear
sort sample_size
save "$folder/part2_all_sim_results.dta", replace

************************************************************
* 10. Figure for Part 2
************************************************************

preserve
collapse ///
    (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
    (sd) sd_beta=beta, by(sample_size)

gen log10N = log10(sample_size)

twoway ///
    (line mean_sem log10N, sort) ///
    (line mean_ci_width log10N, sort), ///
    title("Part 2: Mean SEM and CI Width by Sample Size") ///
    xtitle("log10(Sample Size)") ///
    ytitle("Mean SEM / Mean CI Width") ///
    legend(order(1 "Mean SEM" 2 "Mean CI Width"))

graph export "$folder/part2_precision_plot.png", replace
restore

************************************************************
* 11. Summary table for Part 2
************************************************************

preserve
collapse ///
    (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
    (sd) sd_beta=beta ///
    (p50) median_beta=beta, by(sample_size)

sort sample_size
list, clean

export delimited using "$folder/part2_summary_table.csv", replace
restore

************************************************************
* 12. Comparison table: Part 1 vs Part 2
************************************************************

use "$folder/all_sim_results.dta", clear
collapse ///
    (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
    (sd) sd_beta=beta, by(part sample_size)
save "$folder/part1_summary_compare.dta", replace

use "$folder/part2_all_sim_results.dta", clear
collapse ///
    (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
    (sd) sd_beta=beta, by(part sample_size)
save "$folder/part2_summary_compare.dta", replace

use "$folder/part1_summary_compare.dta", clear
append using "$folder/part2_summary_compare.dta"

sort sample_size part
save "$folder/part1_part2_comparison.dta", replace
export delimited using "$folder/part1_part2_comparison_table.csv", replace

************************************************************
* 13. Comparison figure: Part 1 vs Part 2
************************************************************

gen log10N = log10(sample_size)

twoway ///
    (line mean_sem log10N if part==1, sort) ///
    (line mean_sem log10N if part==2, sort), ///
    title("Comparison of Mean SEM: Part 1 vs Part 2") ///
    xtitle("log10(Sample Size)") ///
    ytitle("Mean SEM") ///
    legend(order(1 "Part 1: Fixed population" 2 "Part 2: Superpopulation"))

graph export "$folder/part1_part2_sem_comparison.png", replace

************************************************************
* PART 3: Power Calculations for Individual-Level Randomization
************************************************************

************************************************************
* 14. Set up data generating process assumptions
************************************************************

* Outcome Y is centered at 0 with standard deviation 1
* Treatment effects for treated units are uniformly distributed
* between 0 and 0.2, so the average treatment effect is 0.1

scalar mu_y    = 0
scalar sd_y    = 1
scalar ate     = 0.1
scalar alpha   = 0.05
scalar power80 = 0.80

************************************************************
* 15. Required sample size for 80% power with 50% treatment
************************************************************

* Equal assignment: 50% treatment, 50% control
* Detecting a mean difference of 0.1 SD

power twomeans 0 0.1, sd(1) power(0.8)

* Store returned sample sizes
scalar n1_equal = r(N1)
scalar n2_equal = r(N2)
scalar ntotal_equal = r(N)

display "Part 3, Scenario 1: Equal assignment (50/50)"
display "Required control group size = " n1_equal
display "Required treatment group size = " n2_equal
display "Required total sample size = " ntotal_equal

************************************************************
* 16. Adjust for 15% attrition
************************************************************

* If 15% of the sample attrits equally across both groups,
* inflate required sample size by dividing by 0.85

scalar ntotal_attrition = ceil(ntotal_equal / 0.85)
scalar n1_attrition = ceil(n1_equal / 0.85)
scalar n2_attrition = ceil(n2_equal / 0.85)

display "Part 3, Scenario 2: Equal assignment with 15% attrition"
display "Required control group size before attrition = " n1_equal
display "Required treatment group size before attrition = " n2_equal
display "Required total sample size before attrition = " ntotal_equal
display "Adjusted control group size = " n1_attrition
display "Adjusted treatment group size = " n2_attrition
display "Adjusted total sample size = " ntotal_attrition


************************************************************
* 17. Sample size if only 30% can receive treatment
************************************************************

* 30% treatment, 70% control
* nratio = control / treatment = 0.70 / 0.30

scalar ratio_30_70 = 0.70/0.30

power twomeans 0 0.1, sd(1) power(0.8) nratio(`=ratio_30_70')

scalar n1_30 = r(N1)   // treatment group
scalar n2_30 = r(N2)   // control group
scalar ntotal_30 = r(N)

display "Part 3, Scenario 3: 30% treatment, 70% control"
display "Required treatment group size = " n1_30
display "Required control group size = " n2_30
display "Required total sample size = " ntotal_30

************************************************************
* 18. Create a small summary table for Part 3
************************************************************

clear
set obs 3

gen str45 scenario = ""
gen treatment_share = .
gen control_share = .
gen treatment_n = .
gen control_n = .
gen total_n = .

replace scenario = "50/50 assignment" in 1
replace treatment_share = 0.50 in 1
replace control_share   = 0.50 in 1
replace treatment_n     = n2_equal in 1
replace control_n       = n1_equal in 1
replace total_n         = ntotal_equal in 1

replace scenario = "50/50 assignment with 15% attrition" in 2
replace treatment_share = 0.50 in 2
replace control_share   = 0.50 in 2
replace treatment_n     = n2_attrition in 2
replace control_n       = n1_attrition in 2
replace total_n         = ntotal_attrition in 2

replace scenario = "30/70 assignment" in 3
replace treatment_share = 0.30 in 3
replace control_share   = 0.70 in 3
replace treatment_n     = n1_30 in 3
replace control_n       = n2_30 in 3
replace total_n         = ntotal_30 in 3

list, clean

save "$folder/part3_power_summary_table.dta", replace
export delimited using "$folder/part3_power_summary_table.csv", replace


************************************************************
* 19. Optional DGP illustration for Part 3
************************************************************

* Create one example dataset just to illustrate the DGP
clear
set seed 54321
set obs 1000

gen id = _n
gen treat = (_n <= 500)
replace treat = treat[_n] if _n <= _N

* Shuffle treatment assignment randomly
gen shuffle = runiform()
sort shuffle
replace treat = (_n <= 500)

* Baseline outcome: mean 0, SD 1
gen y0 = rnormal(0,1)

* Individual treatment effect: Uniform(0, 0.2) for treated
gen te = runiform(0,0.2)

* Observed outcome
gen y = y0 + treat*te

drop shuffle
save "$folder/part3_dgp_example.dta", replace

* End of Part 3

************************************************************
* PART 4: Power Calculations for Cluster Randomization
************************************************************

************************************************************
* 20. Define clustered data generating process
************************************************************

* We want ICC (rho) ≈ 0.3
* ICC = var_between / (var_between + var_within)
* Choose:
*   school random effect variance = 0.3
*   student-level error variance   = 0.7
* Then ICC = 0.3 / (0.3 + 0.7) = 0.3

capture program drop cluster_power
program define cluster_power, rclass
    syntax , CLUSTERS(integer) CSIZE(integer) [ADOPT(real 1)]

    clear
    set obs `clusters'

    * School ID
    gen school_id = _n

    * Evenly divide schools into treatment and control
    gen treat = (_n <= `clusters'/2)

    * School-level treatment effect: Uniform(0.15, 0.25)
    gen te_school = runiform(0.15, 0.25)

    * School-level adoption among treated schools
    * adopt = 1 means full compliance
    * adopt = 0.7 means 70% of treated schools adopt
    gen adopt_school = 1
    if `adopt' < 1 {
        replace adopt_school = (runiform() < `adopt') if treat == 1
        replace adopt_school = 0 if treat == 0
    }
    else {
        replace adopt_school = treat
    }

    * School-level random effect
    gen u_school = rnormal(0, sqrt(0.3))

    * Expand to student level
    expand `csize'
    bysort school_id: gen student_id = _n

    * Student-level error
    gen e_student = rnormal(0, sqrt(0.7))

    * Baseline outcome
    gen y0 = u_school + e_student

    * Observed outcome
    gen y = y0 + adopt_school*te_school

    * Regression with clustered SEs
    regress y treat, vce(cluster school_id)

    * Return useful values
    return scalar beta = _b[treat]
    return scalar sem  = _se[treat]
    return scalar pval = 2*ttail(e(df_r), abs(_b[treat]/_se[treat]))
    return scalar sig  = (return(pval) < 0.05)
    return scalar N_clusters = `clusters'
    return scalar cluster_size = `csize'
end

************************************************************
* 21. Check ICC in one example dataset (optional sanity check)
************************************************************

clear
set obs 200
gen school_id = _n
gen u_school = rnormal(0, sqrt(0.3))
expand 15
bysort school_id: gen student_id = _n
gen e_student = rnormal(0, sqrt(0.7))
gen y_check = u_school + e_student

loneway y_check school_id

************************************************************
* 22. Power when number of schools is fixed at 200
*     and cluster size increases through first 10 powers of 2
************************************************************

local csizes 2 4 8 16 32 64 128 256 512 1024
local first = 1

foreach m of local csizes {

    di "Running cluster-size power simulation for cluster size = `m'"

    simulate beta=r(beta) sem=r(sem) pval=r(pval) sig=r(sig) ///
        N_clusters=r(N_clusters) cluster_size=r(cluster_size), ///
        reps(500) seed(`=2000+`m''): cluster_power, clusters(200) csize(`m') adopt(1)

    gen part = 4
    gen scenario = 1

    save "$folder/part4_clustersize_`m'.dta", replace

    if `first' == 1 {
        save "$folder/part4_power_clustersize_all.dta", replace
        local first = 0
    }
    else {
        append using "$folder/part4_power_clustersize_all.dta"
        save "$folder/part4_power_clustersize_all.dta", replace
    }
}

* Summarize power by cluster size
use "$folder/part4_power_clustersize_all.dta", clear
collapse (mean) power=sig mean_beta=beta mean_sem=sem, by(cluster_size)
sort cluster_size
list, clean

save "$folder/part4_power_by_clustersize.dta", replace
export delimited using "$folder/part4_power_by_clustersize.csv", replace

* Figure: power vs cluster size
gen log2_cluster_size = log(cluster_size)/log(2)

twoway line power cluster_size, sort ///
    title("Part 4: Power by Cluster Size (200 Schools Fixed)") ///
    xtitle("Cluster size (students per school)") ///
    ytitle("Estimated power") ///
    yline(0.8)

graph export "$folder/part4_power_by_clustersize.png", replace

************************************************************
* 23. Find number of schools needed for 80% power
*     holding cluster size fixed at 15 students/school
************************************************************

local school_counts 20 30 40 50 60 70 80 90 100 120 140 160 180 200 220 240 260 280 300 350 400
local first = 1

foreach c of local school_counts {

    * Need even number of schools for equal treatment/control assignment
    if mod(`c',2)==0 {

        di "Running school-count power simulation for clusters = `c'"

        simulate beta=r(beta) sem=r(sem) pval=r(pval) sig=r(sig) ///
            N_clusters=r(N_clusters) cluster_size=r(cluster_size), ///
            reps(500) seed(`=3000+`c''): cluster_power, clusters(`c') csize(15) adopt(1)

        gen part = 4
        gen scenario = 2

        save "$folder/part4_schools_`c'.dta", replace

        if `first' == 1 {
            save "$folder/part4_power_schools_all.dta", replace
            local first = 0
        }
        else {
            append using "$folder/part4_power_schools_all.dta"
            save "$folder/part4_power_schools_all.dta", replace
        }
    }
}

use "$folder/part4_power_schools_all.dta", clear
collapse (mean) power=sig mean_beta=beta mean_sem=sem, by(N_clusters)
sort N_clusters
list, clean

save "$folder/part4_power_by_schools.dta", replace
export delimited using "$folder/part4_power_by_schools.csv", replace

* Figure: power vs number of schools
twoway line power N_clusters, sort ///
    title("Part 4: Power by Number of Schools (15 Students/School)") ///
    xtitle("Number of schools") ///
    ytitle("Estimated power") ///
    yline(0.8)

graph export "$folder/part4_power_by_schools.png", replace

************************************************************
* 24. Find number of schools needed if only 70% adopt treatment
*     holding cluster size fixed at 15 students/school
************************************************************

local school_counts 20 30 40 50 60 70 80 90 100 120 140 160 180 200 220 240 260 280 300 350 400
local first = 1

foreach c of local school_counts {

    if mod(`c',2)==0 {

        di "Running partial-adoption power simulation for clusters = `c'"

        simulate beta=r(beta) sem=r(sem) pval=r(pval) sig=r(sig) ///
            N_clusters=r(N_clusters) cluster_size=r(cluster_size), ///
            reps(500) seed(`=4000+`c''): cluster_power, clusters(`c') csize(15) adopt(0.7)

        gen part = 4
        gen scenario = 3

        save "$folder/part4_schools_adopt70_`c'.dta", replace

        if `first' == 1 {
            save "$folder/part4_power_schools_adopt70_all.dta", replace
            local first = 0
        }
        else {
            append using "$folder/part4_power_schools_adopt70_all.dta"
            save "$folder/part4_power_schools_adopt70_all.dta", replace
        }
    }
}

use "$folder/part4_power_schools_adopt70_all.dta", clear
collapse (mean) power=sig mean_beta=beta mean_sem=sem, by(N_clusters)
sort N_clusters
list, clean

save "$folder/part4_power_by_schools_adopt70.dta", replace
export delimited using "$folder/part4_power_by_schools_adopt70.csv", replace

* Figure: power vs number of schools under 70% adoption
twoway line power N_clusters, sort ///
    title("Part 4: Power by Number of Schools with 70% Adoption") ///
    xtitle("Number of schools") ///
    ytitle("Estimated power") ///
    yline(0.8)

graph export "$folder/part4_power_by_schools_adopt70.png", replace

************************************************************
* 25. Comparison table for school counts with and without adoption loss
************************************************************

use "$folder/part4_power_by_schools.dta", clear
gen adoption = "100% adoption"
save "$folder/part4_compare_100.dta", replace

use "$folder/part4_power_by_schools_adopt70.dta", clear
gen adoption = "70% adoption"
save "$folder/part4_compare_70.dta", replace

use "$folder/part4_compare_100.dta", clear
append using "$folder/part4_compare_70.dta"

sort adoption N_clusters
list, clean

save "$folder/part4_school_power_comparison.dta", replace
export delimited using "$folder/part4_school_power_comparison.csv", replace

* Comparison figure
twoway ///
    (line power N_clusters if adoption=="100% adoption", sort) ///
    (line power N_clusters if adoption=="70% adoption", sort), ///
    title("Part 4: Schools Needed for 80% Power") ///
    xtitle("Number of schools") ///
    ytitle("Estimated power") ///
    yline(0.8) ///
    legend(order(1 "100% adoption" 2 "70% adoption"))

graph export "$folder/part4_school_power_comparison.png", replace


