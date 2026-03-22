*******STATA Assignment 3-Peggy Wang***********

******Part 1: Sampling noise in a fixed population
****Generate population
cd /Users/peggy/Desktop/pw553_STATA3

clear all
set more off

set seed 42
set obs 10000
* Generate X: continuous variable ~ Normal(mean=50, sd=10)
gen X = rnormal(50, 10)
* Generate error term: e ~ Normal(0, sd=15)
gen e = rnormal(0, 15)
* Generate Y using true relationship: Y = 10 + 5*X + e
gen Y = 10 + 5 * X + e

summarize X Y e
correlate X Y

save "population_10000.dta", replace

****Simulate
clear all
set more off

capture program drop sample_regression
program define sample_regression, rclass
    args n
    use "population_10000.dta", clear
    
    sample `n', count

    regress Y X
    
    return scalar N      = e(N)
    return scalar beta   = _b[X]
    return scalar sem    = _se[X]
    return scalar pvalue = 2 * ttail(e(df_r), abs(_b[X] / _se[X]))
    return scalar ci_lo  = _b[X] - invttail(e(df_r), 0.025) * _se[X]
    return scalar ci_hi  = _b[X] + invttail(e(df_r), 0.025) * _se[X]

end
*test
sample_regression 100

****500 reps at each of 4 sample sizes
* N = 10
simulate N=r(N) beta=r(beta) sem=r(sem) pvalue=r(pvalue) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
         reps(500) seed(101): sample_regression 10
gen sample_size = 10
save "sim_n10.dta", replace

* N = 100
simulate N=r(N) beta=r(beta) sem=r(sem) pvalue=r(pvalue) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
         reps(500) seed(202): sample_regression 100
gen sample_size = 100
save "sim_n100.dta", replace

* N = 1,000
simulate N=r(N) beta=r(beta) sem=r(sem) pvalue=r(pvalue) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
         reps(500) seed(303): sample_regression 1000
gen sample_size = 1000
save "sim_n1000.dta", replace

* N = 10,000
simulate N=r(N) beta=r(beta) sem=r(sem) pvalue=r(pvalue) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
         reps(500) seed(404): sample_regression 10000
gen sample_size = 10000
save "sim_n10000.dta", replace

****Merge the dataset
use "sim_n10.dta", clear
append using "sim_n100.dta"
append using "sim_n1000.dta"
append using "sim_n10000.dta"

gen ci_width = ci_hi - ci_lo

save "all_simulation_results.dta", replace

clear all
set more off

****Figures and Tables
* Figure 1:Box plots of beta estimates by sample size
use "all_simulation_results.dta", clear

summarize
tab sample_size

graph box beta, over(sample_size, label(angle(0))) ///
    yline(5, lcolor(red)) ///
    title("Distribution of {&beta} Estimates by Sample Size") ///
    subtitle("True {&beta} = 5 shown as dashed red line") ///
    ytitle("OLS Estimate of {&beta}")

graph export "figure1_beta_distribution.png",replace

* Table 1:Summary statistics of beta, SEM, CI width, and rejection rate
gen reject_H0 = (ci_lo > 0 | ci_hi < 0)

gen covers_true = (ci_lo <= 5 & ci_hi >= 5)

preserve
    collapse ///
        (mean)  mean_beta    = beta        ///
        (sd)    sd_beta      = beta        ///
        (mean)  mean_sem     = sem         ///
        (mean)  mean_ciwidth = ci_width    ///
        (mean)  reject_rate  = reject_H0   ///
        (mean)  coverage     = covers_true ///
        , by(sample_size)

    format mean_beta sd_beta mean_sem mean_ciwidth
    format reject_rate coverage

    list, sep(0) noobs abbreviate(30)

    display ""
    display "TABLE 1: Simulation Results Summary (500 reps per sample size)"
    display "True DGP: Y = 10+5*X+e, X~N(50,10), e~N(0,15)"
    display "---------------------------------------------------------------"
    display "N        MeanBeta  SDbeta  MeanSEM  CI_Width  RejectH0  Coverage"

    export delimited "table1_simulation_summary.csv", replace
restore


************************************************************************************





******Part 2: Sampling noise in an infinite superpopulation
cd /Users/peggy/Desktop/pw553_STATA3
clear all
set more off

capture program drop super_regression
program define super_regression, rclass
    args n
    
    clear
    set obs `n'
    gen X = rnormal(50, 10)
    gen e = rnormal(0, 15)
    gen Y = 10 + 5 * X + e
    
    regress Y X
    
    return scalar N      = e(N)
    return scalar beta   = _b[X]
    return scalar sem    = _se[X]
    return scalar pvalue = 2 * ttail(e(df_r), abs(_b[X] / _se[X]))
    return scalar ci_lo  = _b[X] - invttail(e(df_r), 0.025) * _se[X]
    return scalar ci_hi  = _b[X] + invttail(e(df_r), 0.025) * _se[X]

end

*test
super_regression 100


****Simulate
* Powers of 2: 2^2 through 2^21
local pow2list 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 ///
65536 131072 262144 524288 1048576 2097152

* Powers of 10
local pow10list 10 100 1000 10000 100000 1000000

* Combine all sample sizes
local allsizes `pow2list' `pow10list'

local filenum = 1
foreach n of local allsizes {
    simulate N=r(N) beta=r(beta) sem=r(sem) pvalue=r(pvalue) ///
             ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
             reps(500) seed(`filenum'00): super_regression `n'
    gen sample_size = `n'
    save "sim2_n`n'.dta", replace
    local filenum = `filenum' + 1
}

* Merge all of the dataset
use "sim2_n4.dta", clear

foreach n in 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 ///
131072 262144 524288 1048576 2097152 10 100 1000 10000 100000 1000000 {
    append using "sim2_n`n'.dta"
}

gen ci_width   = ci_hi - ci_lo
gen reject_H0  = (ci_lo > 0 | ci_hi < 0)
gen covers_true = (ci_lo <= 5 & ci_hi >= 5)
gen log2_n     = log(sample_size) / log(2)
gen ln_n       = ln(sample_size)

save "all_simulation_results_part2.dta", replace

*Figures and tables
use "all_simulation_results_part2.dta", clear

preserve
    collapse ///
        (mean)  mean_beta    = beta        ///
        (sd)    sd_beta      = beta        ///
        (mean)  mean_sem     = sem         ///
        (mean)  mean_ciwidth = ci_width    ///
        (mean)  reject_rate  = reject_H0   ///
        (mean)  coverage     = covers_true ///
        , by(sample_size)

    format mean_beta sd_beta mean_sem mean_ciwidth 
    format reject_rate coverage

    sort sample_size
    list, sep(0) noobs abbreviate(30)
    export delimited "table2_part2_summary.csv", replace
restore

*Figure
preserve
    collapse (sd) sd_beta = beta (mean) mean_sem = sem, by(sample_size)
    gen log_n = log10(sample_size)

    twoway (scatter sd_beta log_n, mcolor(navy) msymbol(circle) msize(small)) ///
           (scatter mean_sem log_n, mcolor(maroon) msymbol(triangle) msize(small)), ///
        title("Variation in {&beta} Estimates vs. Sample Size") ///
        subtitle("Part 2: Infinite Superpopulation") ///
        xtitle("log{subscript:10}(Sample Size)") ///
        ytitle("SD of {&beta} / Mean SEM") ///
        legend(label(1 "SD of {&beta} across 500 reps") label(2 "Mean SEM")) ///
        xline(1 2 3 4 5 6, lcolor(gs12) lpattern(dot)) ///
		legend(off)
    graph export "figure2a_sd_sem_by_n.png", replace
restore



************************************************************************************

******Part 3: Power calculations for individual-level randomization
cd /Users/peggy/Desktop/pw553_STATA3
clear all
set more off

scalar mu_c     = 0 
scalar sigma    = 1
scalar ate      = 0.1
scalar te_lo    = 0.0 
scalar te_hi    = 0.2 
scalar p_treat  = 0.5 
scalar alpha    = 0.05
scalar power    = 0.80

scalar z_alpha2 = invnormal(1 - alpha/2) 
scalar z_beta   = invnormal(power) 

scalar var_te = (te_hi - te_lo)^2 / 12

scalar var_yc = sigma^2 
scalar var_yt = sigma^2 + var_te  

scalar N_total_33  = (z_alpha2 + z_beta)^2 * (var_yc/0.5 + var_yt/0.5) / ate^2
scalar N_total_33c = ceil(N_total_33)
scalar N_arm_33    = ceil(N_total_33c / 2)

scalar attrition   = 0.15
scalar inflate     = 1 / (1 - attrition)
scalar N_total_34  = N_total_33 * inflate
scalar N_total_34c = ceil(N_total_34)
scalar N_extra_34  = N_total_34c - N_total_33c

scalar p_t_35      = 0.30
scalar p_c_35      = 0.70
scalar N_total_35  = (z_alpha2 + z_beta)^2 * (var_yc/p_c_35 + var_yt/p_t_35) / ate^2
scalar N_total_35c = ceil(N_total_35)
scalar N_treat_35  = ceil(N_total_35c * p_t_35)
scalar N_ctrl_35   = N_total_35c - N_treat_35
scalar N_extra_35  = N_total_35c - N_total_33c

display ""
display "============================================================"
display " SUMMARY: SAMPLE SIZE REQUIREMENTS"
display "============================================================"
display "Scenario                                   N (total)"
display "------------------------------------------------------------"
display "3.3 Baseline (p=0.5, no attrition)        " N_total_33c
display "3.4 With 15% attrition (enroll)           " N_total_34c
display "3.5 30% treated, 70% control              " N_total_35c
display "------------------------------------------------------------"

capture program drop power_sim
program define power_sim, rclass
    args n p_treat ate_lo ate_hi

    clear
    set obs `n'

    gen treated = (runiform() < `p_treat')
    gen te_i    = `ate_lo' + (`ate_hi' - `ate_lo') * runiform()
    gen Y       = rnormal(0, 1) + treated * te_i

    regress Y treated

    return scalar beta   = _b[treated]
    return scalar pvalue = 2 * ttail(e(df_r), abs(_b[treated] / _se[treated]))
    return scalar reject = (return(pvalue) < 0.05)
end

*Verify baseline:
simulate reject=r(reject) beta=r(beta), ///
    reps(1000) seed(123): power_sim `=N_total_33c' 0.5 0.0 0.2
summarize reject


*Verify unequal allocation:
simulate reject=r(reject) beta=r(beta), ///
    reps(1000) seed(789): power_sim `=N_total_35c' 0.30 0.0 0.2
summarize reject


*Program for attrition
capture program drop power_sim_attrit
program define power_sim_attrit, rclass
    args n_enroll attrition p_treat ate_lo ate_hi

    clear
    set obs `n_enroll'

    gen treated = (runiform() < `p_treat')
    gen te_i    = `ate_lo' + (`ate_hi' - `ate_lo') * runiform()
    gen Y       = rnormal(0, 1) + treated * te_i

    gen attrite = (runiform() < `attrition')
    drop if attrite == 1

    regress Y treated

    return scalar n_final = e(N)
    return scalar beta    = _b[treated]
    return scalar pvalue  = 2 * ttail(e(df_r), abs(_b[treated] / _se[treated]))
    return scalar reject  = (return(pvalue) < 0.05)
end

*Verify attrition
simulate reject=r(reject) n_final=r(n_final), ///
    reps(1000) seed(456): power_sim_attrit `=N_total_34c' 0.15 0.5 0.0 0.2
summarize reject n_final

*comparison
use "all_simulation_results_part2.dta", clear
keep if inlist(sample_size, 10, 100, 1000, 10000)
gen source = "2"

append using "all_simulation_results.dta"
replace source = "1" if source == ""

*Figure
encode source, gen(source_num)

graph box beta, over(source_num) ///
    over(sample_size) ///
    yline(5, lcolor(red) lpattern(dash)) ///
    ytitle("OLS Estimate of {&beta}") 
graph export "figure3_comparison.png",replace

*Table
collapse ///
    (mean)  mean_beta    = beta        ///
    (sd)    sd_beta      = beta        ///
    (mean)  mean_sem     = sem         ///
    (mean)  mean_ciwidth = ci_width    ///
    (mean)  coverage     = covers_true ///
    , by(sample_size source)

sort sample_size source
list, sep(2) noobs abbreviate(30)
export delimited "table3_comparison.csv", replace




************************************************************************************

******Part 4: Power calculations for cluster randomization
cd /Users/peggy/Desktop/pw553_STATA3
clear all
set more off

local rho      = 0.3
local sigma_b  = sqrt(`rho')
local sigma_w  = sqrt(1 - `rho') 
local ate      = 0.2
local te_lo    = 0.15
local te_hi    = 0.25

capture program drop cluster_regression
program define cluster_regression, rclass
    args n_clusters cluster_size compliance

    if "`compliance'" == "" local compliance = 1

    local rho      = 0.3
    local sigma_b  = sqrt(`rho')
    local sigma_w  = sqrt(1 - `rho')
    local te_lo    = 0.15
    local te_hi    = 0.25
    local n_treat  = `n_clusters' / 2   

    clear
    set obs `n_clusters'
    gen school_id = _n

    gen u_j = rnormal(0, `sigma_b')

    gen treated_school = (_n <= `n_treat')

    gen actually_treated = treated_school * (runiform() < `compliance')

    expand `cluster_size'
    bysort school_id: gen student_id = _n

    gen e_ij = rnormal(0, `sigma_w')

    gen te_i = `te_lo' + (`te_hi' - `te_lo') * runiform()

    gen Y = u_j + e_ij + actually_treated * te_i

    regress Y treated_school, vce(cluster school_id)

    return scalar N          = e(N)
    return scalar n_clusters = `n_clusters'
    return scalar cluster_sz = `cluster_size'
    return scalar beta       = _b[treated_school]
    return scalar sem        = _se[treated_school]
    return scalar pvalue     = 2 * ttail(e(df_r), abs(_b[treated_school] / _se[treated_school]))
    return scalar reject     = (return(pvalue) < 0.05)
    return scalar ci_lo      = _b[treated_school] - invttail(e(df_r), 0.025) * _se[treated_school]
    return scalar ci_hi      = _b[treated_school] + invttail(e(df_r), 0.025) * _se[treated_school]
end

*Test
cluster_regression 200 15


local sizes "2 4 8 16 32 64 128 256 512 1024"
local filenum = 1

foreach m of local sizes {
    simulate n_clusters=r(n_clusters) cluster_sz=r(cluster_sz) ///
             beta=r(beta) sem=r(sem) pvalue=r(pvalue) reject=r(reject), ///
             reps(500) seed(`filenum'11): cluster_regression 200 `m'
    gen sample_size = 200 * `m'
    save "clus45_m`m'.dta", replace
    local filenum = `filenum' + 1
}


use "clus45_m2.dta", clear
foreach m in 4 8 16 32 64 128 256 512 1024 {
    append using "clus45_m`m'.dta"
}
save "part4_5_results.dta", replace


collapse (mean) power=reject (mean) mean_beta=beta (mean) mean_sem=sem, ///
    by(cluster_sz)
list, sep(0) noobs
export delimited "table4_power_by_clustersize.csv", replace


use "part4_5_results.dta", clear
collapse (mean) power=reject (mean) mean_sem=sem, by(cluster_sz)

twoway (connected power cluster_sz, lcolor(navy) mcolor(navy) msymbol(circle)), ///
    xscale(log) xlabel(2 4 8 16 32 64 128 256 512 1024, angle(45)) ///
    yline(0.8, lcolor(red) lpattern(dash)) ///
    title("Power vs. Cluster Size (G = 200 Schools)") ///
    xtitle("Cluster Size (students per school, log scale)") ///
    ytitle("Simulated Power")
graph export "figure4_power_clustersize.png"



local G_list "50 100 150 200 250 274 300 350"
local filenum = 1

foreach G of local G_list {
    simulate n_clusters=r(n_clusters) cluster_sz=r(cluster_sz) ///
             beta=r(beta) sem=r(sem) pvalue=r(pvalue) reject=r(reject), ///
             reps(500) seed(`filenum'22): cluster_regression `G' 15
    save "clus46_G`G'.dta", replace
    local filenum = `filenum' + 1
}

use "clus46_G50.dta", clear
foreach G in 100 150 200 250 274 300 350 {
    append using "clus46_G`G'.dta"
}
save "part4_results.dta", replace

collapse (mean) power=reject (mean) mean_beta=beta (mean) mean_sem=sem, ///
    by(n_clusters)
list, sep(0) noobs
export delimited "table4_power_by_nclusters.csv", replace


use "part4_results.dta", clear
collapse (mean) power=reject, by(n_clusters)

twoway (connected power n_clusters, lcolor(black) mcolor(black) msymbol(circle)), ///
    yline(0.8, lcolor(red) lpattern(dash)) ///
    title("Power vs. Number of Schools (m = 15 Students/School)") ///
    xtitle("Number of Schools (clusters)") ///
    ytitle("Simulated Power") ///
    xline(274, lcolor(green) lpattern(dot))
graph export "figure4_power_nclusters.png"


local G_list2 "274 350 400 450 500 556 600"
local filenum = 1

foreach G of local G_list2 {
    simulate n_clusters=r(n_clusters) cluster_sz=r(cluster_sz) ///
             beta=r(beta) sem=r(sem) pvalue=r(pvalue) reject=r(reject), ///
             reps(500) seed(`filenum'33): cluster_regression `G' 15 0.70
    save "clus47_G`G'.dta", replace
    local filenum = `filenum' + 1
}


use "clus47_G274.dta", clear
foreach G in 350 400 450 500 556 600 {
    append using "clus47_G`G'.dta"
}
save "part47_results.dta", replace

collapse (mean) power=reject (mean) mean_beta=beta, by(n_clusters)
list, sep(0) noobs
export delimited "table4_partial_compliance.csv", replace


use "part47_results.dta", clear
collapse (mean) power=reject, by(n_clusters)

twoway (connected power n_clusters, lcolor(black) mcolor(black) msymbol(circle)), ///
    yline(0.8, lcolor(red) lpattern(dash)) ///
    title("Power vs. Schools: Partial Compliance (70%)") ///
    xtitle("Number of Schools (clusters)") ///
    ytitle("Simulated Power") ///
    xline(556, lcolor(green) lpattern(dot))
graph export "figure4_partial_compliance.png"

























