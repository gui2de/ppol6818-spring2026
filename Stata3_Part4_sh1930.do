*** ============================================================
*** OLD CODE FOR Part 4: Power Calculations for Cluster Randomization
*** ============================================================

*------------------------------------------------------------
* STEP 1
*------------------------------------------------------------

capture program drop cluster_power
program define cluster_power, rclass

    args n_clusters cluster_size

    local total_students = `n_clusters' * `cluster_size'

    local sigma_b = sqrt(0.3)
    local sigma_w = sqrt(0.7)

    clear
    set obs `n_clusters'

    gen school_id = _n

    gen treated = (school_id <= `n_clusters'/2)

    gen school_effect = rnormal(0, `sigma_b')

    gen te = runiform(0.15, 0.25)
    replace te = 0 if treated == 0

    expand `cluster_size'

    gen epsilon = rnormal(0, `sigma_w')

    gen math_score = school_effect + epsilon + treated * te

    quietly reg math_score treated, vce(cluster school_id)

    mat res = r(table)
    scalar pval = res[4,1]

    quietly loneway math_score school_id
    scalar observed_icc = r(rho)

    return scalar reject = (pval < 0.05)
    return scalar beta   = res[1,1]
    return scalar pval   = pval
    return scalar icc    = observed_icc

end


*------------------------------------------------------------
* STEP 2
*------------------------------------------------------------

set seed 99999
cluster_power 50 30

*------------------------------------------------------------
* STEP 3
*------------------------------------------------------------

tempfile part4a_results
clear
save `part4a_results', emptyok

local n_clusters = 200

forvalues k = 1/10 {
    local cluster_size = 2^`k'

    simulate reject=r(reject) beta=r(beta) pval=r(pval) icc=r(icc), reps(500) nodots: cluster_power `n_clusters' `cluster_size'

    gen n_clusters  = `n_clusters'
    gen cluster_sz  = `cluster_size'
    gen total_n     = `n_clusters' * `cluster_size'
    collapse (mean) power=reject (mean) mean_beta=beta (mean) mean_icc=icc, by(n_clusters cluster_sz total_n)

    append using `part4a_results'
    save `part4a_results', replace
}

use `part4a_results', clear
sort cluster_sz
save "stata3_part4a_results.dta", replace

list cluster_sz total_n power mean_icc, noobs sep(0)

twoway (line power cluster_sz, lcolor(navy) lwidth(medium) sort) (yline 0.80, lcolor(red) lpattern(dash)), xscale(log base(2)) xlabel(2 4 8 16 32 64 128 256 512 1024, angle(45)) xtitle("Cluster Size (students per school, log2 scale)") ytitle("Estimated Power") title("Figure 8: Power vs Cluster Size" "200 Schools Fixed, ATE=0.2 sd, ICC≈0.3", size(medsmall)) legend(order(1 "Simulated Power" 2 "80% threshold")) note("500 replications per cluster size. ATE~Uniform(0.15,0.25).") scheme(s2color)
graph export "stata3_part4a_power_clustersize.png", replace width(1200)

list cluster_sz power, noobs sep(0)

gsort cluster_sz
gen above80 = (power >= 0.80)
quietly summarize cluster_sz if above80==1

*------------------------------------------------------------
* STEP 4
*------------------------------------------------------------

tempfile part4b_results
clear
save `part4b_results', emptyok

local cluster_size = 15
local cluster_range "20 40 60 80 100 120 140 160 180 200 250 300"

foreach n_clust of local cluster_range {
    display as text "Simulating: `n_clust' clusters, size=15..."

    simulate reject=r(reject) beta=r(beta) pval=r(pval) icc=r(icc), reps(500) nodots: cluster_power `n_clust' `cluster_size'

    gen n_clusters = `n_clust'
    gen cluster_sz = `cluster_size'
    gen total_n    = `n_clust' * `cluster_size'
    collapse (mean) power=reject (mean) mean_beta=beta (mean) mean_icc=icc, by(n_clusters cluster_sz total_n)

    append using `part4b_results'
    save `part4b_results', replace
}

use `part4b_results', clear
sort n_clusters
save "stata3_part4b_results.dta", replace

display as text ""
display as text " Table 4b: Power by Number of Schools (cluster size=15 fixed)"
list n_clusters total_n power mean_icc, noobs sep(0)

twoway (line power n_clusters, lcolor(maroon) lwidth(medium) sort) (yline 0.80, lcolor(red) lpattern(dash)), xtitle("Number of Schools") ytitle("Estimated Power") title("Figure 9: Power vs Number of Schools" "Cluster Size=15 Fixed, ATE=0.2 sd, ICC≈0.3", size(medsmall)) legend(order(1 "Simulated Power" 2 "80% threshold")) note("500 replications per N. ATE~Uniform(0.15,0.25).") scheme(s2color)
graph export "stata3_part4b_power_nschools.png", replace width(1200)

gen above80b = (power >= 0.80)
quietly summarize n_clusters if above80b==1

*------------------------------------------------------------
* STEP 5
*------------------------------------------------------------

capture program drop cluster_power_comply
program define cluster_power_comply, rclass
    args n_clusters cluster_size comply_rate

    local total_students = `n_clusters' * `cluster_size'
    local sigma_b = sqrt(0.3)
    local sigma_w = sqrt(0.7)

    clear
    set obs `n_clusters'
    gen school_id = _n
    gen assigned_treat = (school_id <= `n_clusters'/2)

    gen rand_comply = runiform()
    gen actually_treated = (assigned_treat==1 & rand_comply <= `comply_rate')

    gen school_effect = rnormal(0, `sigma_b')

    gen te = runiform(0.15, 0.25)
    replace te = 0 if actually_treated == 0

    expand `cluster_size'
    gen epsilon = rnormal(0, `sigma_w')
    gen math_score = school_effect + epsilon + actually_treated * te

    quietly reg math_score assigned_treat, vce(cluster school_id)

    mat res = r(table)
    scalar pval = res[4,1]
    quietly loneway math_score school_id
    scalar observed_icc = r(rho)

    return scalar reject = (pval < 0.05)
    return scalar beta   = res[1,1]
    return scalar pval   = pval
    return scalar icc    = observed_icc
end


tempfile part4c_results
clear
save `part4c_results', emptyok

local cluster_size   = 15
local comply_rate    = 0.70
local cluster_range2 "60 80 100 120 140 160 180 200 250 300 350 400 500"

foreach n_clust of local cluster_range2 {
    display as text "Simulating (comply=70%): `n_clust' clusters, size=15..."

    simulate reject=r(reject) beta=r(beta) pval=r(pval) icc=r(icc), reps(500) nodots: cluster_power_comply `n_clust' `cluster_size' `comply_rate'

    gen n_clusters = `n_clust'
    gen cluster_sz = `cluster_size'
    gen total_n    = `n_clust' * `cluster_size'
    collapse (mean) power=reject (mean) mean_beta=beta (mean) mean_icc=icc, ///
             by(n_clusters cluster_sz total_n)

    append using `part4c_results'
    save `part4c_results', replace
}

use `part4c_results', clear
sort n_clusters
save "stata3_part4c_results.dta", replace

list n_clusters total_n power mean_icc, noobs sep(0)

gen above80c = (power >= 0.80)
quietly summarize n_clusters if above80c==1
display as text "Minimum schools needed (70% compliance): " r(min)


use "stata3_part4b_results.dta", clear
gen compliance = "100% (Full)"
save "stata3_part4b_tagged.dta", replace

use "stata3_part4c_results.dta", clear
gen compliance = "70%"
append using "stata3_part4b_tagged.dta"

twoway (line power n_clusters if compliance=="100% (Full)", lcolor(navy) lwidth(medium) sort) (line power n_clusters if compliance=="70%", lcolor(orange) lwidth(medium) sort) (yline 0.80, lcolor(red) lpattern(dash)), xtitle("Number of Schools") ytitle("Estimated Power") title("Figure 10: Power vs Schools — Full vs 70% Compliance" "Cluster size=15, ATE=0.2 sd, ICC≈0.3", size(medsmall)) legend(order(1 "100% compliance" 2 "70% compliance" 3 "80% threshold")) note("500 replications per N. ITT analysis used for 70% compliance.") scheme(s2color)
graph export "stata3_part4c_compliance_comparison.png", replace width(1200)
