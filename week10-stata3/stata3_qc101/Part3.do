// Stata3_Qingyue Chen
// Part 3: Power calculations for individual-level randomization

clear all
set more off

global BOXPATH "C:\Users\86186\Box\stata3"

* 1. Illustrative data generating process
set seed 12345
set obs 10000

gen id = _n
gen treat = (_n <= 5000)

* baseline outcome under control
gen y0 = rnormal(0,1)

* individual treatment effect: Uniform(0, 0.2)
gen tau = runiform(0,0.2)

* observed outcome
gen y = y0 + treat*tau

save "$BOXPATH\part3_dgp_example.dta", replace

* 2. Power calculation: 50% treated / 50% control
power twomeans 0 0.1, ///
    sd(1) ///
    alpha(0.05) ///
    power(0.80) ///
    nratio(1)

* r(N) is per-group sample size, so total N = 2*r(N)
scalar N_5050  = 2*r(N)
scalar Nt_5050 = r(N)
scalar Nc_5050 = r(N)

display "--------------------------------------------"
display "50/50 allocation"
display "Required total N = " N_5050
display "Treated N = " Nt_5050
display "Control N = " Nc_5050


* 3. Adjust for 15% attrition
scalar N_5050_attrit  = N_5050 / 0.85
scalar Nt_5050_attrit = N_5050_attrit * 0.5
scalar Nc_5050_attrit = N_5050_attrit * 0.5

display "--------------------------------------------"
display "50/50 allocation with 15% attrition"
display "Required total N = " N_5050_attrit
display "Rounded total N = " ceil(N_5050_attrit)
display "Rounded treated N = " ceil(Nt_5050_attrit)
display "Rounded control N = " ceil(Nc_5050_attrit)

* 4. Power calculation: only 30% treated
* treatment share = 0.3, control share = 0.7
* nratio = control/treatment = 0.7/0.3
power twomeans 0 0.1, ///
    sd(1) ///
    alpha(0.05) ///
    power(0.80) ///
    nratio(0.7/0.3)

* r(N) is treated group size (group 1)
scalar Nt_3070 = r(N)
scalar Nc_3070 = r(N) * (0.7/0.3)
scalar N_3070  = Nt_3070 + Nc_3070

display "--------------------------------------------"
display "30/70 allocation"
display "Required total N = " N_3070
display "Treated N = " Nt_3070
display "Control N = " Nc_3070


* 5. 30% treated + 15% attrition
scalar N_3070_attrit  = N_3070 / 0.85
scalar Nt_3070_attrit = N_3070_attrit * 0.3
scalar Nc_3070_attrit = N_3070_attrit * 0.7

display "--------------------------------------------"
display "30/70 allocation with 15% attrition"
display "Required total N = " N_3070_attrit
display "Rounded total N = " ceil(N_3070_attrit)
display "Rounded treated N = " ceil(Nt_3070_attrit)
display "Rounded control N = " ceil(Nc_3070_attrit)


* 6. Create summary table dataset
clear
set obs 4

gen str30 scenario = ""
gen total_N = .
gen treated_N = .
gen control_N = .

replace scenario = "50/50 allocation" in 1
replace total_N = ceil(N_5050) in 1
replace treated_N = ceil(Nt_5050) in 1
replace control_N = ceil(Nc_5050) in 1

replace scenario = "50/50 + 15% attrition" in 2
replace total_N = ceil(N_5050_attrit) in 2
replace treated_N = ceil(Nt_5050_attrit) in 2
replace control_N = ceil(Nc_5050_attrit) in 2

replace scenario = "30/70 allocation" in 3
replace total_N = ceil(N_3070) in 3
replace treated_N = ceil(Nt_3070) in 3
replace control_N = ceil(Nc_3070) in 3

replace scenario = "30/70 + 15% attrition" in 4
replace total_N = ceil(N_3070_attrit) in 4
replace treated_N = ceil(Nt_3070_attrit) in 4
replace control_N = ceil(Nc_3070_attrit) in 4

list, clean noobs

save "$BOXPATH\part3_power_results.dta", replace
export excel using "$BOXPATH\part3_power_results.xlsx", firstrow(variables) replace