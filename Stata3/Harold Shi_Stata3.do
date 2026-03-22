//Harold Shi
//Stata3
clear
cd "D:\stata3"

*********************************************
**                Question1                **
*********************************************
//Step 1
set obs 10000 //set a dataset
gen id=_n //set a identification for each observation
gen x=runiform() //set data for X
gen u=rnormal(0,1) //set data for error term
gen y=1+2*x+u //set process for outcome y
save "Q1.dta", replace

//Step 2 Set the program
capture program drop Q1
program define Q1, rclass
    syntax , n(integer)
    use "Q1.dta", clear
    sample `n', count
    reg y x
    return scalar N    = e(N)
    return scalar beta = _b[x]
    return scalar se   = _se[x]
    return scalar p    = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar lb   = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar ub   = _b[x] + invttail(e(df_r), 0.025)*_se[x]
end

//Step 3 Test the program
Q1, n(100)
return list

// Step 4 simulate
simulate N=r(N) beta=r(beta) se=r(se) p=r(p) lb=r(lb) ub=r(ub), reps(500) seed(101): Q1, n(10)
gen sample_size = 10
save "results_10.dta", replace

simulate N=r(N) beta=r(beta) se=r(se) p=r(p) lb=r(lb) ub=r(ub), reps(500) seed(102): Q1, n(100)
gen sample_size = 100
save "results_100.dta", replace

simulate N=r(N) beta=r(beta) se=r(se) p=r(p) lb=r(lb) ub=r(ub), reps(500) seed(103): Q1, n(1000)
gen sample_size = 1000
save "results_1000.dta", replace

simulate N=r(N) beta=r(beta) se=r(se) p=r(p) lb=r(lb) ub=r(ub), reps(500) seed(104): Q1, n(10000)
gen sample_size = 10000
save "results_10000.dta", replace

//Step 5
use "results_10.dta", clear
append using "results_100.dta"
append using "results_1000.dta"
append using "results_10000.dta"

save "all_results.dta", replace

//Step 6 to 8
use "all_results.dta", clear

gen ci_width = ub - lb
gen sig = (p < 0.05)

tabstat beta se ci_width sig, by(sample_size) stat(mean sd min max n)

graph box beta, over(sample_size) yline(1.5)
graph export "beta_box.png", replace

graph box se, over(sample_size)
graph export "se_box.png", replace

*********************************************
**                Question2                **
*********************************************
clear
//step 1
capture program drop Q2
program define Q2, rclass
    syntax , n(integer)

    clear
    set obs `n'

    gen x = rnormal(0,1)
    gen u = rnormal(0,1)
    gen y = 2 + 1.5*x + u

    reg y x

    return scalar N    = e(N)
    return scalar beta = _b[x]
    return scalar se   = _se[x]
    return scalar p    = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar lb   = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar ub   = _b[x] + invttail(e(df_r), 0.025)*_se[x]
end

//step 2
Q2, n(100)
return list

//step 3
simulate N=r(N) beta=r(beta) se=r(se) p=r(p) lb=r(lb) ub=r(ub), reps(10) seed(2001): Q2, n(100)
list in 1/5

//step 4
local seed = 3000

forvalues i = 2/21 {
    
    local N = 2^`i'
    
    simulate N=r(N) beta=r(beta) se=r(se) p=r(p) lb=r(lb) ub=r(ub), ///
        reps(500) seed(`=`seed'+`i''): Q2, n(`N')
    
    gen sample_size = `N'
    
    save "p2_`N'.dta", replace
}

forvalues k = 1/6 {
    
    local N = 10^`k'
    
    simulate N=r(N) beta=r(beta) se=r(se) p=r(p) lb=r(lb) ub=r(ub), ///
        reps(500) seed(`=4000+`k''): Q2, n(`N')
    
    gen sample_size = `N'
    
    save "p2_`N'.dta", replace
}

clear

local first = 1

* powers of 2
forvalues i = 2/21 {
    local N = 2^`i'
    
    if `first' == 1 {
        use "p2_`N'.dta", clear
        local first = 0
    }
    else {
        append using "p2_`N'.dta"
    }
}

* powers of 10
forvalues k = 1/6 {
    local N = 10^`k'
    append using "p2_`N'.dta"
}

save "part2_all_results.dta", replace

use "part2_all_results.dta", clear
gen ci_width = ub - lb
gen sig = (p < 0.05)

graph box beta, over(sample_size) yline(2)
graph export "p2_beta_box.png", replace

graph box se, over(sample_size)
graph export "p2_se_box.png", replace

*********************************************
**                Question3                **
*********************************************
clear
//Step 1
set more off

//Step2
set obs 1000
gen y0=rnormal(0,1)
gen tau=runiform(0,0.2)
gen y1=y0+tau

//Step3
power twomeans 0 0.1, power(0.8) alpha(0.05) sd(1) nratio(1)

//Step4
return list
display r(N)
display r(N)/0.85
display ceil(r(N)/0.85)

//Step 5
power twomeans 0 0.1, power(0.8) alpha(0.05) sd(1) nratio(0.3/0.7)

*********************************************
**                Question4                **
*********************************************
clear
capture program drop Q4

//Step1 Program define
program define Q4, rclass
    syntax , CLUSTERS(integer) SIZE(integer)

    clear
    set obs `clusters'
    gen school_id = _n
    gen u_school = rnormal(0, sqrt(0.3))
    gen treat_school = (_n <= `clusters'/2)

    expand `size'
    bysort school_id: gen student_id = _n

    gen e_student = rnormal(0, sqrt(0.7))
    gen y0 = u_school + e_student
    gen tau = runiform(0.15, 0.25)
    gen y = y0 + treat_school*tau

    reg y treat_school, cluster(school_id)

    return scalar beta = _b[treat_school]
    return scalar se   = _se[treat_school]
    return scalar p    = 2*ttail(e(df_r), abs(_b[treat_school]/_se[treat_school]))
    return scalar hit  = (2*ttail(e(df_r), abs(_b[treat_school]/_se[treat_school])) < 0.05)
end

//Step2 ICC Check
set obs 200
gen school_id = _n
gen u_school = rnormal(0, sqrt(0.3))
expand 15
bysort school_id: gen student_id = _n
gen e_student = rnormal(0, sqrt(0.7))
gen y0 = u_school + e_student

loneway y0 school_id

//Step3

tempfile allpow
save `allpow', emptyok replace

forvalues k = 1/10 {
    local m = 2^`k'
    simulate beta=r(beta) se=r(se) p=r(p) hit=r(hit), ///
        reps(500) seed(`=5000+`k''): Q4, clusters(200) size(`m')
    gen cluster_size = `m'
    append using `allpow'
    save `allpow', replace
}

use `allpow', clear
collapse (mean) power=hit, by(cluster_size)
twoway line power cluster_size, xscale(log)
graph export "part4_power_by_cluster_size.png", replace

//Step4

tempfile powerclusters
save `powerclusters', emptyok replace

forvalues c = 20(10)400 {
    simulate beta=r(beta) se=r(se) p=r(p) hit=r(hit), ///
        reps(500) seed(`=7000+`c''): Q4, clusters(`c') size(15)
    gen clusters = `c'
    append using `powerclusters'
    save `powerclusters', replace
}

use `powerclusters', clear
collapse (mean) power=hit, by(clusters)
list if power>=0.8, clean

//Step5
capture program drop Q4a

program define Q4a, rclass
    syntax , CLUSTERS(integer) SIZE(integer)

    clear
    set obs `clusters'
    gen school_id = _n
    gen u_school = rnormal(0, sqrt(0.3))
    gen assign_school = (_n <= `clusters'/2)

    gen adopt_school = 0
    replace adopt_school = (runiform() < 0.7) if assign_school==1

    expand `size'
    bysort school_id: gen student_id = _n

    gen e_student = rnormal(0, sqrt(0.7))
    gen y0 = u_school + e_student
    gen tau = runiform(0.15, 0.25)
    gen y = y0 + adopt_school*tau

    reg y assign_school, cluster(school_id)

    return scalar beta = _b[assign_school]
    return scalar se   = _se[assign_school]
    return scalar p    = 2*ttail(e(df_r), abs(_b[assign_school]/_se[assign_school]))
    return scalar hit  = (2*ttail(e(df_r), abs(_b[assign_school]/_se[assign_school])) < 0.05)
end

//Step6

tempfile poweradopt
save `poweradopt', emptyok replace

forvalues c = 20(10)600 {
    simulate beta=r(beta) se=r(se) p=r(p) hit=r(hit), ///
        reps(500) seed(`=9000+`c''): Q4a, clusters(`c') size(15)
    gen clusters = `c'
    append using `poweradopt'
    save `poweradopt', replace
}

use `poweradopt', clear
collapse (mean) power=hit, by(clusters)
list if power>=0.8, clean