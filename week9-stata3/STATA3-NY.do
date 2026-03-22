clear all
set more off

global box "C:\Users\yzqri\Downloads"
cd "$box"

**************************************************
**# Bookmark #1
* Part A: Create fixed population
**************************************************
set seed 123456
set obs 10000

gen id = _n
gen x = rnormal(0,1)
gen u = rnormal(0,2)
gen y = 2 + 1.5*x + u

save "fixed_population.dta", replace

**************************************************
* Part B: Define sampling/regression program
**************************************************
capture program drop sample_reg
program define sample_reg, rclass
    version 17.0
    syntax , N(integer)

    use "fixed_population.dta", clear
    sample `n', count
    regress y x

    return scalar N       = e(N)
    return scalar beta    = _b[x]
    return scalar se      = _se[x]
    return scalar pvalue  = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar cilow   = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar cihigh  = _b[x] + invttail(e(df_r), 0.025)*_se[x]
    return scalar ciwidth = ///
        ( _b[x] + invttail(e(df_r), 0.025)*_se[x] ) - ///
        ( _b[x] - invttail(e(df_r), 0.025)*_se[x] )
end

**************************************************
* Part C: Simulations
**************************************************
simulate N=r(N) beta=r(beta) se=r(se) pvalue=r(pvalue) ///
         cilow=r(cilow) cihigh=r(cihigh) ciwidth=r(ciwidth), ///
         reps(500) seed(101): sample_reg, n(10)
gen sample_size = 10
save "sim_n10.dta", replace

simulate N=r(N) beta=r(beta) se=r(se) pvalue=r(pvalue) ///
         cilow=r(cilow) cihigh=r(cihigh) ciwidth=r(ciwidth), ///
         reps(500) seed(102): sample_reg, n(100)
gen sample_size = 100
save "sim_n100.dta", replace

simulate N=r(N) beta=r(beta) se=r(se) pvalue=r(pvalue) ///
         cilow=r(cilow) cihigh=r(cihigh) ciwidth=r(ciwidth), ///
         reps(500) seed(103): sample_reg, n(1000)
gen sample_size = 1000
save "sim_n1000.dta", replace

simulate N=r(N) beta=r(beta) se=r(se) pvalue=r(pvalue) ///
         cilow=r(cilow) cihigh=r(cihigh) ciwidth=r(ciwidth), ///
         reps(500) seed(104): sample_reg, n(10000)
gen sample_size = 10000
save "sim_n10000.dta", replace

use "sim_n10.dta", clear
append using "sim_n100.dta"
append using "sim_n1000.dta"
append using "sim_n10000.dta"
save "all_sim_results.dta", replace

**************************************************
* Part D: Table
**************************************************
table sample_size, ///
    statistic(mean beta) ///
    statistic(sd beta) ///
    statistic(mean se) ///
    statistic(mean ciwidth) ///
    statistic(mean pvalue) ///
    nformat(%9.4f)

**************************************************
* Part E: Figure
**************************************************
graph box beta, over(sample_size) ///
    yline(1.5, lpattern(dash)) ///
    title("Distribution of Beta Estimates by Sample Size") ///
    ytitle("Estimated beta") ///
    b1title("Sample size")
	
	
********Part2****************

clear all
set more off

global box "C:\Users\yzqri\Downloads"
cd "$box"

**************************************************
* Define superpopulation program
**************************************************
capture program drop superpop_reg
program define superpop_reg, rclass
    version 17.0
    syntax , N(integer)

    clear
    set obs `n'

    gen x = rnormal(0,1)
    gen u = rnormal(0,2)
    gen y = 2 + 1.5*x + u

    regress y x

    return scalar N       = e(N)
    return scalar beta    = _b[x]
    return scalar se      = _se[x]
    return scalar pvalue  = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar cilow   = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar cihigh  = _b[x] + invttail(e(df_r), 0.025)*_se[x]
    return scalar ciwidth = ///
        (_b[x] + invttail(e(df_r), 0.025)*_se[x]) - ///
        (_b[x] - invttail(e(df_r), 0.025)*_se[x])
end

**************************************************
* Test the program first
**************************************************
superpop_reg, n(10)
return list

**************************************************
* Then run simulations
**************************************************
local pow2list 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152

foreach n of local pow2list {
    di "Running simulations for N = `n'"

    simulate N=r(N) beta=r(beta) se=r(se) pvalue=r(pvalue) cilow=r(cilow) cihigh=r(cihigh) ciwidth=r(ciwidth), reps(500): superpop_reg, n(`n')
    gen sample_size = `n'
    gen group = "power_of_two"
    save "superpop_n`n'.dta", replace
}


use "superpop_n4.dta", clear

local allsizes 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 10 100 1000 10000 100000 1000000

foreach n of local allsizes {
    append using "superpop_n`n'.dta"
}

order sample_size group N beta se pvalue cilow cihigh ciwidth
save "superpop_all_results.dta", replace

********Setting benchmarklist*************
local benchmarklist 10 100 1000 10000 100000 1000000

foreach n of local benchmarklist {
    di "Running simulations for N = `n'"

    simulate N=r(N) beta=r(beta) se=r(se) pvalue=r(pvalue) cilow=r(cilow) cihigh=r(cihigh) ciwidth=r(ciwidth), reps(500): superpop_reg, n(`n')

    gen sample_size = `n'
    gen group = "benchmark"
    save "superpop_n`n'.dta", replace
}

use "superpop_n4.dta", clear

local allsizes 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 10 100 1000 10000 100000 1000000

foreach n of local allsizes {
    append using "superpop_n`n'.dta"
}

order sample_size group N beta se pvalue cilow cihigh ciwidth
save "superpop_all_results.dta", replace


use "superpop_all_results.dta", clear
count
tab group
tab sample_size

**********Table*************
table sample_size if inlist(sample_size,10,100,1000,10000,100000,1000000), statistic(mean beta) statistic(sd beta) statistic(mean se) statistic(mean ciwidth) statistic(mean pvalue) nformat(%12.6f)


graph box beta if inlist(sample_size,10,100,1000,10000,100000,1000000), ///
    over(sample_size) ///
    yline(1.5, lpattern(dash)) ///
    title("Superpopulation: Beta Estimates by Sample Size") ///
    ytitle("Estimated beta") ///
    b1title("Sample size")

graph export "superpop_beta_boxplot.png", replace

*************Comparison table****************

use "all_sim_results.dta", clear
keep if inlist(sample_size,10,100,1000,10000)
gen design = "fixed_population"
save "part1_benchmark.dta", replace

use "superpop_all_results.dta", clear
keep if inlist(sample_size,10,100,1000,10000)
gen design = "superpopulation"
save "part2_benchmark.dta", replace

use "part1_benchmark.dta", clear
append using "part2_benchmark.dta"
save "part1_part2_compare.dta", replace

table design sample_size, ///
    statistic(mean beta) ///
    statistic(sd beta) ///
    statistic(mean se) ///
    statistic(mean ciwidth) ///
    nformat(%10.4f)

*************Comparison figure************

use "part1_part2_compare.dta", clear

graph box beta, over(sample_size) over(design) ///
    yline(1.5, lpattern(dash)) ///
    title("Part 1 vs Part 2: Beta Estimates by Sample Size") ///
    ytitle("Estimated beta") ///
    b1title("Design and sample size")


clear all
set more off
set seed 12345

**************************************************
* Part 3: DGP demonstration
**************************************************
set obs 2000

gen treat = runiform() < 0.5
gen y0 = rnormal(0,1)
gen tau = runiform(0,0.2)
gen y = y0 + treat*tau

summarize y0 tau y
reg y treat

**************************************************
* Power calculation: 50% treated, 50% control
**************************************************
power twomeans 0 0.1, sd(1) power(0.8) alpha(0.05) nratio(1)

* From standard formula / expected output:
scalar N_equal = 1568
display "Required total sample, 50/50 assignment = " N_equal

**************************************************
* Adjust for 15% attrition
**************************************************
scalar N_equal_attrition = ceil(N_equal/0.85)
display "Required sample with 15% attrition = " N_equal_attrition

**************************************************
* Power calculation: 30% treated, 70% control
**************************************************
power twomeans 0 0.1, sd(1) power(0.8) alpha(0.05) nratio(2.3333)

* From standard formula / expected output:
scalar N_30 = 3734
display "Required total sample, 30% treated = " N_30

**************************************************
* 30% treated + 15% attrition
**************************************************
scalar N_30_attrition = ceil(N_30/0.85)
display "Required sample, 30% treated + 15% attrition = " N_30_attrition



***********Part 4*****************

clear all
set more off
set seed 12345

**************************************************
* Program 1: generate clustered student-level data
**************************************************
capture program drop make_cluster_data
program define make_cluster_data
    version 17.0
    syntax, CLusters(integer) M(integer)

    clear
    set obs `clusters'
    gen school_id = _n
    gen treat = mod(_n,2)
    gen u_school = rnormal(0, sqrt(0.3))
    gen tau = runiform(0.15, 0.25)
    expand `m'
    bysort school_id: gen student_id = _n
    gen e_student = rnormal(0, sqrt(0.7))
    gen y = u_school + e_student + treat*tau
end

**************************************************
* Check ICC
**************************************************
make_cluster_data, clusters(200) m(15)
mixed y || school_id:
estat icc

**************************************************
* Program 2: run one clustered RCT and return p-value
**************************************************
capture program drop cluster_power
program define cluster_power, rclass
    version 17.0
    syntax, CLusters(integer) M(integer) [ADOPT(real 1)]

    quietly make_cluster_data, clusters(`clusters') m(`m')

    if `adopt' < 1 {
        bysort school_id: gen adopted_school = .
        by school_id: replace adopted_school = (runiform() < `adopt') if _n==1 & treat==1
        by school_id: replace adopted_school = 0 if _n==1 & treat==0
        by school_id: replace adopted_school = adopted_school[1]
        replace y = u_school + e_student + (treat*adopted_school)*tau
    }

    quietly reg y treat, cluster(school_id)

    return scalar pvalue = 2*ttail(e(df_r), abs(_b[treat]/_se[treat]))
    return scalar beta   = _b[treat]
    return scalar se     = _se[treat]
    return scalar N      = e(N)
end

******************

local mlist 1 2 4 8 16 32 64 128 256 512

foreach m of local mlist {
    di "Running power simulation for cluster size = `m'"
    simulate pvalue=r(pvalue) beta=r(beta) se=r(se), reps(500): cluster_power, clusters(200) m(`m')
    gen cluster_size = `m'
    gen reject = (pvalue < 0.05)
    save "cluster_power_m`m'.dta", replace
}

use "cluster_power_m1.dta", clear
append using "cluster_power_m2.dta"
append using "cluster_power_m4.dta"
append using "cluster_power_m8.dta"
append using "cluster_power_m16.dta"
append using "cluster_power_m32.dta"
append using "cluster_power_m64.dta"
append using "cluster_power_m128.dta"
append using "cluster_power_m256.dta"
append using "cluster_power_m512.dta"
save "cluster_size_power_results.dta", replace


use "cluster_size_power_results.dta", clear

collapse (mean) power=reject mean_beta=beta mean_se=se, by(cluster_size)
list, clean


*********************

local clist 20 40 60 80 100 120 140 160 180 200 240 280 320

foreach c of local clist {
    di "Running power simulation for clusters = `c'"
    simulate pvalue=r(pvalue) beta=r(beta) se=r(se), reps(500): cluster_power, clusters(`c') m(15)
    gen clusters = `c'
    gen reject = (pvalue < 0.05)
    save "cluster_count_`c'.dta", replace
}


use "cluster_count_20.dta", clear
append using "cluster_count_40.dta"
append using "cluster_count_60.dta"
append using "cluster_count_80.dta"
append using "cluster_count_100.dta"
append using "cluster_count_120.dta"
append using "cluster_count_140.dta"
append using "cluster_count_160.dta"
append using "cluster_count_180.dta"
append using "cluster_count_200.dta"
append using "cluster_count_240.dta"
append using "cluster_count_280.dta"
append using "cluster_count_320.dta"
save "cluster_count_power_results.dta", replace

use "cluster_count_power_results.dta", clear
collapse (mean) power=reject mean_beta=beta mean_se=se, by(clusters)
list, clean

******************************************

local clist2 20 40 60 80 100 120 140 160 180 200 240 280 320 360 400

foreach c of local clist2 {
    di "Running power simulation with 70% adoption for clusters = `c'"
    simulate pvalue=r(pvalue) beta=r(beta) se=r(se), reps(500): cluster_power, clusters(`c') m(15) adopt(0.7)
    gen clusters = `c'
    gen reject = (pvalue < 0.05)
    save "cluster_count_adopt70_`c'.dta", replace
}

use "cluster_count_adopt70_20.dta", clear
append using "cluster_count_adopt70_40.dta"
append using "cluster_count_adopt70_60.dta"
append using "cluster_count_adopt70_80.dta"
append using "cluster_count_adopt70_100.dta"
append using "cluster_count_adopt70_120.dta"
append using "cluster_count_adopt70_140.dta"
append using "cluster_count_adopt70_160.dta"
append using "cluster_count_adopt70_180.dta"
append using "cluster_count_adopt70_200.dta"
append using "cluster_count_adopt70_240.dta"
append using "cluster_count_adopt70_280.dta"
append using "cluster_count_adopt70_320.dta"
append using "cluster_count_adopt70_360.dta"
append using "cluster_count_adopt70_400.dta"
save "cluster_count_adopt70_results.dta", replace


use "cluster_count_adopt70_results.dta", clear
collapse (mean) power=reject mean_beta=beta mean_se=se, by(clusters)
list, clean



