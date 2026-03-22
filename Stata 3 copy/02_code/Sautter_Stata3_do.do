***********
* STATA 3
***********
global wd "/Users/maren/Desktop/Experimental Design & Implementation/Stata 3"


***********************************************
** Part 1: Sampling noise in a fixed population
***********************************************

* STEP 1 & 2: CREATE & SAVE FIXED POPULATION, N = 10,000

* Setting seed for reproducibility
set seed 202603

* Creating  population
set obs 10000

* Data Generating Process 
* Creating Independent variable
gen X = rnormal(50, 10)

* Outcome variable (true beta = 0.5)
gen Y = 2 + 0.5 * X + rnormal(0, 5)

* Labeling variables

label var X "Predictor (mean=50, sd=10)"
label var Y "Outcome (Y = 2 + 0.5X + error)"

* Saving dataset
save "${wd}/01_data/new_data.dta", replace


* STEP 3: DEFINING THE PROGRAM

capture program drop sample_reg

program define sample_reg, rclass
syntax, sample(integer)

use "${wd}/01_data/new_data.dta", clear

gen rand = runiform()
sort rand
keep if _n <= `sample'

regress Y X

mat a = r(table)

* Returning results
return scalar N = e(N)
return scalar beta = a[1,1]
return scalar se = a[2,1]
return scalar p = a[4,1]
return scalar ci_low = a[5,1]
return scalar ci_high = a[6,1]

end


* STEP 4: RUNNING PROGRAM
tempfile results
local first = 1

foreach n in 10 100 1000 10000 {

    di "Running simulations for N = `n'..."

    simulate ///
        N=r(N) beta=r(beta) se=r(se) p=r(p) ci_low=r(ci_low) ci_high=r(ci_high), ///
        reps(500) nodots: sample_reg, sample(`n')

    gen sample_size = `n'

    if `first' == 1 {
        save `results', replace
        local first = 0
    }
    else {
        append using `results'
        save `results', replace
    }
}

use `results', clear
save "${wd}/03_output/part1_all.dta", replace


* STEP 5: DATA VISUALIZATION

* Figure 1
graph box beta, over(sample_size) ///
    yline(0.5, lcolor(orange) lpattern(dash)) ///
    title("Distribution of beta estimates by sample size") ///
    subtitle("Fixed population, 500 Simulations per sample size") ///
    ytitle("Estimated Beta") ///
	note("X-axis: Sample Size   |   Orange dashed line = true β = 0.5")

	graph export "${wd}/03_output/part1_beta_distr.png", replace 


gen ci_width = ci_high - ci_low
preserve

use "${wd}/03_output/part1_all.dta", clear

* Table 1
gen ci_width = ci_high - ci_low

preserve

collapse ///
    (mean) mean_beta=beta mean_se=se mean_ci_width=ci_width mean_p=p ///
    (sd)   sd_beta=beta sd_se=se sd_ci_width=ci_width sd_p=p, ///
    by(sample_size)

format mean_beta mean_se mean_ci_width sd_beta sd_se sd_ci_width %9.4f

list sample_size mean_beta mean_se mean_ci_width sd_beta sd_se sd_ci_width, noobs clean

save "${wd}/03_output/part1_table.dta", replace
export excel using "${wd}/03_output/part1_table.xlsx", firstrow(variables) replace

restore


********************************************************
** Part 2: Sampling noise in an infinite superpopulation
********************************************************

clear all
set more off

* STEP 1: DEFINING PROGRAM

capture program drop superpop_reg

program define superpop_reg, rclass
syntax, n(integer)

clear
set obs `n'

gen X = rnormal(0,1)
gen u = rnormal(0,1)
gen Y = 2 + 0.5*X + u   // true beta = 0.5

regress Y X

matrix a = r(table)

return scalar N       = e(N)
return scalar beta    = a[1,1]
return scalar sem     = a[2,1]
return scalar p       = a[4,1]
return scalar ci_low  = a[5,1]
return scalar ci_high = a[6,1]

end

* STEP 2: RUNNING PROGRAM


tempfile results2
save `results2', emptyok

* Powers of 2, 20 times
forvalues i = 2/21 {
    
    local n = 2^`i'
    
    simulate N=r(N) beta=r(beta) sem=r(sem) p=r(p) ///
             ci_low=r(ci_low) ci_high=r(ci_high), reps(500) nodots: ///
             superpop_reg, n(`n')

    gen sample_size = `n'

    append using `results2'
    save `results2', replace
}

* Additional sample sizes
foreach n in 10 100 1000 10000 100000 1000000 {

    simulate N=r(N) beta=r(beta) sem=r(sem) p=r(p) ///
             ci_low=r(ci_low) ci_high=r(ci_high), reps(500) nodots: ///
             superpop_reg, n(`n')

    gen sample_size = `n'

    append using `results2'
    save `results2', replace
}

use `results2', clear
save "${wd}/03_output/part2_superpop.dta", replace


* STEP 3: DATA VISUALIZATION

* Table 2
gen ci_width = ci_high - ci_low

preserve

collapse ///
    (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width mean_p=p ///
    (sd)   sd_beta=beta sd_sem=sem sd_ci_width=ci_width sd_p=p, ///
    by(sample_size)

format mean_beta mean_sem mean_ci_width sd_beta sd_sem sd_ci_width %9.4f

list sample_size mean_beta mean_sem mean_ci_width sd_beta sd_sem sd_ci_width, noobs clean

save "${wd}/03_output/part2_table.dta", replace
export excel using "${wd}/03_output/part2_table.xlsx", firstrow(variables) replace

restore


* Figure 2

preserve
collapse (mean) beta, by(sample_size)
gen log_n = log(sample_size)
twoway (line beta log_n, sort) ///
       (scatter beta log_n), ///
	   legend(off) ///
    yline(0.5, lcolor(orange) lpattern(dash)) ///
    title("Convergence of Beta Estimates") ///
    xtitle("Log Sample Size") ///
    ytitle("Mean Estimated Beta") ///
	note("Orange dashed line = true β = 0.5")
restore

graph export "${wd}/03_output/part2_beta_distr.png", replace


* STEP 5: COMPARISONS

* Table 2.1
use "${wd}/03_output/part1_table.dta", clear
rename mean_beta part1_mean_beta
rename mean_se   part1_mean_se
rename mean_ci_width part1_mean_ci_width
keep sample_size part1_mean_beta part1_mean_se part1_mean_ci_width
save "${wd}/03_output/part1_comp.dta", replace

use "${wd}/03_output/part2_table.dta", clear
rename mean_beta part2_mean_beta
rename mean_sem  part2_mean_sem
rename mean_ci_width part2_mean_ci_width
keep sample_size part2_mean_beta part2_mean_sem part2_mean_ci_width

merge 1:1 sample_size using "${wd}/03_output/part1_comp.dta"
list, clean noobs

keep if _merge == 3
drop _merge

list sample_size ///
     part1_mean_beta part2_mean_beta ///
     part1_mean_se part2_mean_sem ///
     part1_mean_ci_width part2_mean_ci_width, clean noobs

	 export excel using "${wd}/03_output/part2_tablecomparison.xlsx", firstrow(variables) replace

* Figure 2.1
gen log_n = log(sample_size)

twoway ///
    (line part1_mean_se log_n, sort lcolor(navy) lwidth(medthick)) ///
    (line part2_mean_sem log_n, sort lcolor(maroon) lwidth(medthick)), ///
    title("Mean SEM: Finite vs Superpopulation") ///
    xtitle("Log Sample Size") ///
    ytitle("Mean SEM") ///
    legend(label(1 "Part 1: Finite Population") ///
           label(2 "Part 2: Superpopulation")) ///
    yscale(range(0 0.4))
	
	graph export "${wd}/03_output/part2_comparison.png", replace
	
	

*****************************************************************
** Part 3: Power calculations for individual-level randomizations
*****************************************************************
clear all
set more off


* PART 1-3
* 50/50 assignment, detect 0.1 sd effect
power twomeans 0 0.1, sd(1) power(0.8) nratio(1)
local n_base = r(N)
display "Required N (50/50): `n_base'"

* Simulation 
capture program drop power_indiv

program define power_indiv, rclass
    syntax, n(integer)

    clear
    set obs `n'

    * 50/50 treatment assignment
    gen rand = runiform()
    sort rand
    gen treatment = (_n <= `n'/2)

    * Heterogeneous treatment effects
    gen te = runiform(0, 0.2)

    * Outcome
    gen Y = rnormal(0,1) + treatment * te

    reg Y treatment

    matrix a = r(table)

    return scalar beta = a[1,1]
    return scalar pval = a[4,1]
end

* Simulated power
simulate beta=r(beta) pval=r(pval), reps(1000): ///
    power_indiv, n(`n_base')

gen reject = (pval < 0.05)
sum reject



* PART 4
* 15% attrition
local n_attr = ceil(`n_base' / 0.85)

di "Required N with 15% attrition: `n_attr'"

* PART 5
* 30% Treated
power twomeans 0 0.1, sd(1) power(0.8) nratio(0.3/0.7)

local n_30 = r(N)
di "Required N with 30% treated: `n_30'"



********************************************************
** Part 4: Power calculations for cluster randomization
********************************************************

* PART 1-4
clear all
set more off
set seed 202622

capture program drop cluster_power

program define cluster_power, rclass
    syntax, g(integer) m(integer) [rho(real 0.3) adopt(real 1)]

    quietly {
        drop _all
        set obs `g'

        gen school = _n

        * Randomly assign half the schools to treatment
        gen rand = runiform()
        sort rand
        gen treat = (_n <= `g'/2)
        sort school
        drop rand

        * Cluster-level effect for ICC
        gen u = rnormal(0, sqrt(`rho'))

        * Expand to student level
        expand `m'
        sort school
        by school: gen student = _n

        * Individual-level noise
        gen e = rnormal(0, sqrt(1-`rho'))

        * Baseline outcome
        gen y0 = u + e

        * Treatment effect, average about 0.2 SD
        by school: gen tau = runiform(0.15, 0.25) if _n == 1
        by school: replace tau = tau[1]

        * Partial adoption
        by school: gen adopt_school = 1 if _n == 1
        by school: replace adopt_school = (runiform() < `adopt') if treat == 1 & _n == 1
        by school: replace adopt_school = 1 if treat == 0 & _n == 1
        by school: replace adopt_school = adopt_school[1]

        * Outcome
        gen y = y0 + treat * adopt_school * tau

        * Regression with clustered SEs
        regress y treat, vce(cluster school)

        scalar p = 2 * ttail(e(df_r), abs(_b[treat] / _se[treat]))

        return scalar beta = _b[treat]
        return scalar pval = p
        return scalar sig  = (p < 0.05)

        * Realized ICC from baseline outcome
        loneway y0 school
        return scalar rho_hat = r(rho)
    }
end

* Part 5: HOLDING CLUSTERS FIXED AT 200, VARYING CLUSTER SIZE 

tempfile q5_results
postfile q5file cluster_size mean_power mean_beta mean_rho using `q5_results', replace

forvalues i = 0/9 {
    local m = 2^`i'

    simulate sig=r(sig) beta=r(beta) pval=r(pval) rho=r(rho_hat), reps(500) nodots: ///
        cluster_power, g(200) m(`m')

    summarize sig
    local power = r(mean)

    summarize beta
    local beta_mean = r(mean)

    summarize rho
    local rho_mean = r(mean)

    post q5file (`m') (`power') (`beta_mean') (`rho_mean')

    di "Cluster size = `m', power = " %6.3f `power'
}

postclose q5file

use `q5_results', clear
sort cluster_size

list cluster_size mean_power mean_beta mean_rho, clean noobs

twoway line mean_power cluster_size, sort ///
    xscale(log) ///
    xlabel(1 2 4 8 16 32 64 128 256 512, format(%9.0g)) ///
    title("Power vs. Cluster Size, Holding Number of Schools Fixed at 200") ///
    xtitle("Students per School (log scale)") ///
    ytitle("Power")
	
	graph export "${wd}/03_output/part4_q5.png", replace


* PART 6: FIXING CLUSTER SIZE AT 15 STUDENTS/SCHOOL

tempfile q6_results
postfile q6file num_schools mean_power mean_beta mean_rho using `q6_results', replace

forvalues g = 50(10)500 {
    
    simulate sig=r(sig) beta=r(beta) pval=r(pval) rho=r(rho_hat), reps(500) nodots: ///
        cluster_power, g(`g') m(15)

    summarize sig
    local power = r(mean)

    summarize beta
    local beta_mean = r(mean)

    summarize rho
    local rho_mean = r(mean)

    post q6file (`g') (`power') (`beta_mean') (`rho_mean')

    di "Schools = `g', power = " %6.3f `power'
}

postclose q6file

use `q6_results', clear
sort num_schools

list num_schools mean_power mean_beta mean_rho, clean noobs


* PART 7: SET ADOPTION TO 0.7, FIND 80% POWER

tempfile q7_results
postfile q7file num_schools mean_power mean_beta mean_rho using `q7_results', replace

forvalues g = 100(10)800 {

    simulate sig=r(sig) beta=r(beta) pval=r(pval) rho=r(rho_hat), reps(500) nodots: ///
        cluster_power, g(`g') m(15) adopt(0.7)

    summarize sig
    local power = r(mean)

    summarize beta
    local beta_mean = r(mean)

    summarize rho
    local rho_mean = r(mean)

    post q7file (`g') (`power') (`beta_mean') (`rho_mean')

    di "Schools = `g', power = " %6.3f `power'
}

postclose q7file

use `q7_results', clear
sort num_schools

list num_schools mean_power mean_beta mean_rho, clean noobs

list num_schools mean_power if mean_power >= 0.8, clean noobs

summarize num_schools if mean_power >= 0.8
display r(min)


