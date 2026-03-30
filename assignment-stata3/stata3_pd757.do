*12345678901234567890123456789012345678901234567890123456789012345678901234567890

*	************************************************************************
* 	File-Name: 	stata3_pd757.do
*	Log-file:	na
*	Date:  		03/22/2026
*	Author: 	Puran Dou
*	Data Used:  various
*	Output		various
*	************************************************************************

clear all
set more off

// log using stata3log, replace

*===============================================================================
* 0. SET PATHS
*===============================================================================

global out "/Users/oldfarmerdou/Dropbox/ExperimentalDesign/assignment_stata3_pd757"

cap mkdir "$out"
cap mkdir "$out/graphs"
cap mkdir "$out/tables"

*===============================================================================
* 1. PART 1
*===============================================================================

* Step 1. gen 10,000 person

clear
set seed 12345
set obs 10000

gen id = _n
gen x = rnormal(0,1)
gen u = rnormal(0,1)
gen y = 1 + 0.8*x + u

save "$out/fixed_pop.dta", replace

* Step 2. write program

capture program drop sim_fixed
program define sim_fixed, rclass
    syntax, N(integer)

    preserve
    use "$out/fixed_pop.dta", clear

    sample `n', count

    quietly reg y x

    return scalar N    = e(N)
    return scalar beta = _b[x]
    return scalar sem  = _se[x]
    return scalar pval = 2*ttail(e(df_r),abs(_b[x]/_se[x]))
    return scalar cil  = _b[x] - invttail(e(df_r),0.025)*_se[x]
    return scalar ciu  = _b[x] + invttail(e(df_r),0.025)*_se[x]

    restore
end

* Step 3. simulate 500x4

tempfile allresults
clear
save `allresults', emptyok replace

foreach s in 10 100 1000 10000 {
    simulate N=r(N) beta=r(beta) sem=r(sem) ///
             pval=r(pval) cil=r(cil) ciu=r(ciu), ///
             reps(500) seed(`=100+`s'') nodots: ///
             sim_fixed, n(`s')

    gen sample_n = `s'
    append using `allresults'
    save `allresults', replace
}

use `allresults', clear
sort sample_n
save "$out/part1_results.dta", replace

* Step 4. table

preserve
collapse (mean) mean_beta=beta mean_sem=sem ///
         (sd) sd_beta=beta, by(sample_n)

list, clean
export delimited using "$out/part1_table.csv", replace
restore

* Step 5. graph

use "$out/part1_results.dta", clear
graph box beta, over(sample_n)
graph export "$out/part1_beta_box.png", replace

* Step 6. SEM and CI

gen ci_width = ciu - cil
bysort sample_n: egen mean_sem = mean(sem)
bysort sample_n: egen mean_ciw = mean(ci_width)

sort sample_n
list sample_n mean_sem mean_ciw if _n==1 | sample_n!=sample_n[_n-1], clean

preserve
collapse (mean) mean_sem=sem mean_ciw=ci_width, by(sample_n)
export delimited using "$out/part1_sem_ciw_table.csv", replace
restore


*===============================================================================
* 2. PART 2
*===============================================================================

* Step 1. write program

capture program drop sim_superpop
program define sim_superpop, rclass
    syntax, N(integer)

    clear
    set obs `n'

    gen x = rnormal(0,1)
    gen u = rnormal(0,1)
    gen y = 1 + 0.8*x + u

    quietly reg y x

    return scalar N    = e(N)
    return scalar beta = _b[x]
    return scalar sem  = _se[x]
    return scalar pval = 2*ttail(e(df_r),abs(_b[x]/_se[x]))
    return scalar cil  = _b[x] - invttail(e(df_r),0.025)*_se[x]
    return scalar ciu  = _b[x] + invttail(e(df_r),0.025)*_se[x]
end

* Step 2. gen list

local pow2_list
forvalues k = 2/21 {
    local thisn = 2^`k'
    local pow2_list `pow2_list' `thisn'
}

local extra_list 10 100 1000 10000 100000 1000000 // powers of ten

* Step 2. simulate

tempfile allresults
clear
save `allresults', emptyok replace

foreach s of local pow2_list {
    simulate N=r(N) beta=r(beta) sem=r(sem) ///
             pval=r(pval) cil=r(cil) ciu=r(ciu), ///
             reps(500) seed(`=200+`s'') nodots: ///
             sim_superpop, n(`s')

    gen sample_n = `s'
    gen n_type = "power_of_two"
    append using `allresults'
    save `allresults', replace
}

foreach s of local extra_list {
    simulate N=r(N) beta=r(beta) sem=r(sem) ///
             pval=r(pval) cil=r(cil) ciu=r(ciu), ///
             reps(500) seed(`=500+`s'') nodots: ///
             sim_superpop, n(`s')

    gen sample_n = `s'
    gen n_type = "power_of_ten"
    append using `allresults'
    save `allresults', replace
}

use `allresults', clear
sort sample_n
save "$out/part2_results.dta", replace

* Step 4. table

gen ci_width = ciu - cil

preserve
collapse (mean) mean_beta=beta mean_sem=sem mean_ciw=ci_width ///
         (sd) sd_beta=beta, by(sample_n n_type)

sort sample_n
list, clean
export delimited using "$out/part2_table.csv", replace
restore

* Step 4. graph

graph box beta, over(sample_n, label(angle(45)))
graph export "$out/part2_beta_box.png", replace

preserve
collapse (mean) mean_sem=sem mean_ciw=ci_width, by(sample_n)

twoway ///
    (line mean_sem sample_n, sort) ///
    (line mean_ciw sample_n, sort yaxis(2)), ///
    xscale(log) ///
    xtitle("Sample size (log scale)") ///
    ytitle("Mean SEM", axis(1)) ///
    ytitle("Mean CI width", axis(2)) ///
    title("Part 2: Precision improves as N grows") ///
    legend(order(1 "Mean SEM" 2 "Mean CI width"))

graph export "$out/part2_precision.png", replace
restore


* Step 5. compare Part 1 and Part 2

use "$out/part1_results.dta", clear
gen source = "Part 1"

append using "$out/part2_results.dta"
replace source = "Part 2" if missing(source)

gen ci_width = ciu - cil

preserve
collapse (mean) mean_beta=beta mean_sem=sem mean_ciw=ci_width, by(source sample_n)
export delimited using "$out/part1_part2_comparison.csv", replace
restore

graph box beta, over(sample_n) by(source, note(""))
graph export "$out/part1_part2_beta_compare.png", replace

use "$out/part1_results.dta", clear
gen source = "Part 1"

append using "$out/part2_results.dta"
replace source = "Part 2" if missing(source)

keep if inlist(sample_n,10,100,1000,10000)

graph box beta, over(sample_n) by(source, note(""))
graph export "$out/part1_part2_beta_compare_clean.png", replace

*===============================================================================
* 3. PART 3
*===============================================================================

* Step 1. define one experiment

capture program drop one_rct
program define one_rct, rclass
    syntax, N(integer) PTR(real)

    clear
    set obs `n'

    gen y0 = rnormal(0,1)
    gen te = runiform(0,0.2)

    gen u = runiform()
	egen rank = rank(u)
	gen treat = rank <= round(`ptr' * `n')

    gen y = y0 + treat*te

    quietly reg y treat

    local p = 2*ttail(e(df_r), abs(_b[treat]/_se[treat]))

    return scalar reject = (`p' < 0.05)
    return scalar beta   = _b[treat]
    return scalar pval   = `p'
end

* Step 2. define power

capture program drop get_power
program define get_power, rclass
    syntax, N(integer) PTR(real) [REPS(integer 500)]

    quietly simulate reject=r(reject), reps(`reps') nodots: ///
        one_rct, n(`n') ptr(`ptr')

    quietly summarize reject

    return scalar power = r(mean)
    return scalar N     = `n'
    return scalar ptr   = `ptr'
end


* Step 3. case 1: 50% treated

tempfile results50
clear
save `results50', emptyok replace

foreach n of numlist 200(100)4000 {
    quietly get_power, n(`n') ptr(0.5) reps(500)

    clear
    set obs 1
    gen N = `n'
    gen treatshare = 0.5
    gen power = r(power)

    append using `results50'
    save `results50', replace
}

use `results50', clear
sort N
gen meets80 = power >= 0.8

list N power if meets80==1 & meets80[_n-1]!=1, noobs

save "$out/part3_50_50_results.dta", replace

* Step 4. case 2: required initial sample size with 15% attrition

gen N_with_attrition = ceil(N/0.85) if meets80==1
list N power N_with_attrition if meets80==1 & meets80[_n-1]!=1, noobs

preserve
keep if meets80==1 & (meets80[_n-1]!=1 | _n==1)
keep N power N_with_attrition
export delimited using "$out/part3_attrition_table.csv", replace
restore

* Step 5. case 3: 30% treated

tempfile results30
clear
save `results30', emptyok replace

foreach n of numlist 200(100)5000 {
    quietly get_power, n(`n') ptr(0.3) reps(500)

    clear
    set obs 1
    gen N = `n'
    gen treatshare = 0.3
    gen power = r(power)

    append using `results30'
    save `results30', replace
}

use `results30', clear
sort N
gen meets80 = power >= 0.8

list N power if meets80==1 & meets80[_n-1]!=1, noobs

save "$out/part3_30_70_results.dta", replace


* Step 6. graph

use "$out/part3_50_50_results.dta", clear
append using "$out/part3_30_70_results.dta"

twoway ///
    (line power N if inrange(treatshare,0.499999,0.500001), sort) ///
    (line power N if inrange(treatshare,0.299999,0.300001), sort), ///
    yline(0.8, lpattern(dash)) ///
    xtitle("Total sample size") ///
    ytitle("Empirical power") ///
    title("Part 3: Power under different treatment shares") ///
    legend(order(1 "50% treated" 2 "30% treated"))
graph export "$out/part3_power_curves.png", replace

*===============================================================================
* 4. PART 4
*===============================================================================

* Step 1. define one cluster RCT experiment

capture program drop one_cluster_rct
program define one_cluster_rct, rclass
    syntax, K(integer) M(integer) [ADOPT(real 1)]

    clear
    set obs `k'

    gen school = _n

    * School-level random assignment
    gen u = runiform()
    egen rank = rank(u)
    gen assign = rank <= (`k'/2)

    * School-level adoption
    gen adopt_school = (assign==1 & runiform()<=`adopt')

    * Construct ICC about 0.3
    gen school_fe = rnormal(0, sqrt(0.3))
    gen te_school = runiform(0.15, 0.25)

    * Expand from schools to students
    expand `m'
    bysort school: gen student = _n

    * Student-level error
    gen e = rnormal(0, sqrt(0.7))

    * Generate outcome
    gen y0 = school_fe + e
    gen y  = y0 + adopt_school*te_school

    * Estimate ITT effect
    quietly reg y assign, vce(cluster school)

    local p = 2*ttail(e(df_r), abs(_b[assign]/_se[assign]))

    return scalar reject = (`p' < 0.05)
    return scalar beta   = _b[assign]
    return scalar pval   = `p'
end

* Step 2. define power

capture program drop get_cluster_power
program define get_cluster_power, rclass
    syntax, K(integer) M(integer) [ADOPT(real 1) REPS(integer 500)]

    quietly simulate reject=r(reject), reps(`reps') nodots: ///
        one_cluster_rct, k(`k') m(`m') adopt(`adopt')

    quietly summarize reject

    return scalar power = r(mean)
    return scalar K     = `k'
    return scalar M     = `m'
    return scalar adopt = `adopt'
end


* Step 3. check whether ICC is about 0.3

clear
set obs 200
gen school = _n
gen school_fe = rnormal(0, sqrt(0.3))
expand 15
gen e = rnormal(0, sqrt(0.7))
gen y0 = school_fe + e
loneway y0 school


* Step 4. q1: fix 200 schools and vary cluster size

tempfile results_size
clear
save `results_size', emptyok replace

local mlist 1 2 4 8 16 32 64 128 256 512

foreach m of local mlist {
    quietly get_cluster_power, k(200) m(`m') adopt(1) reps(500)

    clear
    set obs 1
    gen total_schools = 200
    gen cluster_size  = `m'
    gen adopt_rate    = 1
    gen power         = r(power)

    append using `results_size'
    save `results_size', replace
}

use `results_size', clear
sort cluster_size
list, clean

export delimited using "$out/part4_power_by_cluster_size.csv", replace
save "$out/part4_power_by_cluster_size.dta", replace

twoway ///
    (line power cluster_size, sort), ///
    xscale(log) ///
    yline(0.8, lpattern(dash)) ///
    xtitle("Students per school (log scale)") ///
    ytitle("Empirical power") ///
    title("Power as cluster size increases (200 schools fixed)")
graph export "$out/part4_power_by_cluster_size.png", replace


* Step 5. q2: fix 15 students per school and find required schools

tempfile results_k
clear
save `results_k', emptyok replace

foreach k of numlist 40(20)600 {
    quietly get_cluster_power, k(`k') m(15) adopt(1) reps(500)

    clear
    set obs 1
    gen total_schools = `k'
    gen cluster_size  = 15
    gen adopt_rate    = 1
    gen power         = r(power)

    append using `results_k'
    save `results_k', replace
}

use `results_k', clear
sort total_schools
gen meets80 = power >= 0.8
list total_schools power if meets80==1 & meets80[_n-1]!=1, noobs

export delimited using "$out/part4_power_by_numschools.csv", replace
save "$out/part4_power_by_numschools.dta", replace

* Step 6. q3: if only 70% of schools adopt

tempfile results_k70
clear
save `results_k70', emptyok replace

foreach k of numlist 40(20)800 {
    quietly get_cluster_power, k(`k') m(15) adopt(0.7) reps(500)

    clear
    set obs 1
    gen total_schools = `k'
    gen cluster_size  = 15
    gen adopt_rate    = 0.7
    gen power         = r(power)

    append using `results_k70'
    save `results_k70', replace
}

use `results_k70', clear
sort total_schools
gen meets80 = power >= 0.8
list total_schools power if meets80==1 & meets80[_n-1]!=1, noobs

export delimited using "$out/part4_power_by_numschools_adopt70.csv", replace
save "$out/part4_power_by_numschools_adopt70.dta", replace


* Step 7. graph

use `results_k', clear
append using `results_k70'

twoway ///
    (line power total_schools if inrange(adopt_rate,0.999999,1.000001), sort) ///
    (line power total_schools if inrange(adopt_rate,0.699999,0.700001), sort), ///
    yline(0.8, lpattern(dash)) ///
    xtitle("Total number of schools") ///
    ytitle("Empirical power") ///
    title("Power with full adoption vs 70% adoption") ///
    legend(order(1 "100% adoption" 2 "70% adoption"))
graph export "$out/part4_power_adoption_compare.png", replace


*============================= END OF DO FILE =================================*

// log close


