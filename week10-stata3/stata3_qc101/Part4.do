// Stata3_Qingyue Chen
// Part 4: Power calculations for cluster randomization

clear all
set more off

global BOXPATH "C:\Users\86186\Box\stata3"

capture program drop sim_cluster
program define sim_cluster, rclass
    syntax, CLUSTERS(integer) CSIZE(integer) [ADOPT(real 1)]

    clear

    set obs `clusters'
    gen school_id = _n

    gen treat_assign = (school_id <= `clusters'/2)

    gen adopt_draw = runiform()
    gen treat_actual = treat_assign
    replace treat_actual = 0 if treat_assign==1 & adopt_draw > `adopt'

    gen u_school = rnormal(0, sqrt(0.3))
    gen tau = runiform(0.15, 0.25)

    expand `csize'
    bysort school_id: gen student_id = _n

    gen u_student = rnormal(0, sqrt(0.7))
    gen math_score = u_school + u_student + treat_actual*tau

    regress math_score treat_actual, vce(cluster school_id)

    scalar ci_low  = _b[treat_actual] - invttail(e(df_r), 0.025) * _se[treat_actual]
    scalar ci_high = _b[treat_actual] + invttail(e(df_r), 0.025) * _se[treat_actual]

    return scalar beta  = _b[treat_actual]
    return scalar sem   = _se[treat_actual]
    return scalar pval  = 2 * ttail(e(df_r), abs(_b[treat_actual]/_se[treat_actual]))
    return scalar ci_lo = ci_low
    return scalar ci_hi = ci_high
    return scalar sig   = (return(pval) < 0.05)
    return scalar N     = e(N)
    return scalar G     = `clusters'
    return scalar M     = `csize'
    return scalar adopt = `adopt'
end


* cluster size variation (fixed 200 schools)
tempfile power_m
clear
save `power_m', emptyok replace

local msizes 2 4 8 16 32 64 128 256 512 1024

foreach m of local msizes {
    simulate beta=r(beta) sem=r(sem) pval=r(pval) ///
             ci_lo=r(ci_lo) ci_hi=r(ci_hi) sig=r(sig), ///
             reps(500) seed(`=2000+`m''): ///
             sim_cluster, clusters(200) csize(`m') adopt(1)

    gen cluster_size = `m'
    gen ci_width = ci_hi - ci_lo

    collapse (mean) power=sig mean_beta=beta mean_sem=sem ///
             mean_ci_width=ci_width, by(cluster_size)

    order cluster_size power mean_beta mean_sem mean_ci_width

    tempfile one`m'
    save `one`m'', replace

    use `power_m', clear
    append using `one`m'', force
    save `power_m', replace
}

use `power_m', clear
sort cluster_size
save "$BOXPATH\part4_power_by_cluster_size.dta", replace


* schools variation (cluster size = 15)
tempfile power_g
clear
save `power_g', emptyok replace

local school_list 20 30 40 50 60 70 80 90 100 120 140 160 180 200 220 240 260 280 300 350 400 450 500

foreach g of local school_list {
    simulate beta=r(beta) sem=r(sem) pval=r(pval) ///
             ci_lo=r(ci_lo) ci_hi=r(ci_hi) sig=r(sig), ///
             reps(500) seed(`=3000+`g''): ///
             sim_cluster, clusters(`g') csize(15) adopt(1)

    gen schools = `g'
    gen ci_width = ci_hi - ci_lo

    collapse (mean) power=sig mean_beta=beta mean_sem=sem ///
             mean_ci_width=ci_width, by(schools)

    order schools power mean_beta mean_sem mean_ci_width

    tempfile g`g'
    save `g`g'', replace

    use `power_g', clear
    append using `g`g'', force
    save `power_g', replace
}

use `power_g', clear
sort schools
save "$BOXPATH\part4_power_by_schools_fullcompliance.dta", replace


* 70% adoption
tempfile power_g70
clear
save `power_g70', emptyok replace

foreach g of local school_list {
    simulate beta=r(beta) sem=r(sem) pval=r(pval) ///
             ci_lo=r(ci_lo) ci_hi=r(ci_hi) sig=r(sig), ///
             reps(500) seed(`=4000+`g''): ///
             sim_cluster, clusters(`g') csize(15) adopt(0.7)

    gen schools = `g'
    gen ci_width = ci_hi - ci_lo

    collapse (mean) power=sig mean_beta=beta mean_sem=sem ///
             mean_ci_width=ci_width, by(schools)

    order schools power mean_beta mean_sem mean_ci_width

    tempfile h`g'
    save `h`g'', replace

    use `power_g70', clear
    append using `h`g'', force
    save `power_g70', replace
}

use `power_g70', clear
sort schools
save "$BOXPATH\part4_power_by_schools_70adoption.dta", replace


* comparison
use "$BOXPATH\part4_power_by_schools_fullcompliance.dta", clear
rename power power_full
tempfile full
save `full'

use "$BOXPATH\part4_power_by_schools_70adoption.dta", clear
rename power power_70adopt
merge 1:1 schools using `full', nogen

save "$BOXPATH\part4_power_comparison_table.dta", replace
export excel using "$BOXPATH\part4_power_comparison_table.xlsx", firstrow(variables) replace