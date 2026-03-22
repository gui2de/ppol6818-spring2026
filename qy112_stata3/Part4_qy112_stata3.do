****************************************************
* Part 4: Power calculations for cluster randomization
****************************************************
*** 1-4 ***
****************************************************
clear all
set more off
set seed 410

capture program drop cr_power
program define cr_power, rclass
    syntax, g(integer) m(integer) [rho(real 0.3) adopt(real 1)]

    quietly {
        drop _all
        set obs `g'
        gen school = _n

        * Randomly assign half of schools to treatment
        gen rand = runiform()
        sort rand
        gen treat = (_n <= `g'/2)
        sort school
        drop rand

        * School-level random effect
        gen u = rnormal(0, sqrt(`rho'))

        * Treatment effect
        gen tau = runiform(0.15, 0.25) * treat

        * Partial adoption
        gen adopt_school = 1
        replace adopt_school = (runiform() < `adopt') if treat == 1
        replace tau = tau * adopt_school

        * Expand to student level
        expand `m'
        bysort school: gen student = _n

        * Individual-level error
        gen e = rnormal(0, sqrt(1 - `rho'))

        * Baseline outcome
        gen y0 = 50 + u + e

        * Outcome with treatment effect
        gen y = y0 + tau

        * ITT regression with cluster-robust SEs
        regress y treat, vce(cluster school)

        scalar pval = 2 * ttail(e(df_r), abs(_b[treat] / _se[treat]))

        return scalar p   = pval
        return scalar sig = (pval < 0.05)
        return scalar b   = _b[treat]

        * Realized ICC from baseline outcome
        loneway y0 school
        return scalar rho_hat = r(rho)
    }
end

****************************************************
*** 5 ***
****************************************************

tempname student1
postfile `student1' m power using "Part4_Q5.dta", replace

forvalues k = 0/9 {
    local m = 2^`k'

    quietly simulate sig = r(sig), reps(1000) nodots: ///
        cr_power, g(200) m(`m') rho(0.3)

    quietly summarize sig
    local pw = r(mean)

    post `student1' (`m') (`pw')
    di "Q5: cluster size = `m', power = " %6.3f `pw'
}

postclose `student1'

use "Part4_Q5.dta", clear
sort m
list, clean

twoway line power m, ///
    title("Power by cluster size, fixed 200 schools") ///
    xtitle("Students per school") ///
    ytitle("Power") ///
    note("ICC = 0.3, treatment effect ~ U(0.15, 0.25), 1000 simulations")

graph export "Part4_Q5.png", replace

****************************************************
*** 6 ***
****************************************************

tempname student2
postfile `student2' g power using "Part4_Q6.dta", replace

forvalues g = 100(20)500 {

    quietly simulate sig = r(sig), reps(1000) nodots: ///
        cr_power, g(`g') m(15) rho(0.3)

    quietly summarize sig
    local pw = r(mean)

    post `student2' (`g') (`pw')
    di "Q6: schools = `g', power = " %6.3f `pw'
}

postclose `student2'

use "Part4_Q6.dta", clear
sort g
list, clean

* Report schools achieving >= 80% power
list g power if power >= 0.8

* Minimum schools for 80% power
summarize g if power >= 0.8
di "Minimum number of schools for 80% power: " r(min)

twoway line power g, ///
    yline(0.8, lpattern(dash)) ///
    title("Power by number of schools, 15 students per school") ///
    xtitle("Number of schools") ///
    ytitle("Power") ///
    note("ICC = 0.3, treatment effect ~ U(0.15, 0.25), 1000 simulations")

graph export "Part4_Q6.png", replace

****************************************************
*** 7 ***
****************************************************

tempname student3
postfile `student3' g power using "Part4_Q7.dta", replace

forvalues g = 200(20)800 {

    quietly simulate sig = r(sig), reps(1000) nodots: ///
        cr_power, g(`g') m(15) rho(0.3) adopt(0.7)

    quietly summarize sig
    local pw = r(mean)

    post `student3' (`g') (`pw')
    di "Q7: schools = `g', power = " %6.3f `pw'
}

postclose `student3'

use "Part4_Q7.dta", clear
sort g
list, clean

* Report schools achieving >= 80% power
list g power if power >= 0.8

summarize g if power >= 0.8
di "Minimum number of schools for 80% power with 70% adoption: " r(min)

twoway line power g, ///
    yline(0.8, lpattern(dash)) ///
    title("Power by number of schools, 70% adoption") ///
    xtitle("Number of schools") ///
    ytitle("Power") ///
    note("ICC = 0.3, treatment effect ~ U(0.15, 0.25), adopt = 0.70, 1000 simulations")

graph export "Part4_Q7.png", replace
