****************************************************
* Part 3: Power calculations for individual-level randomization
****************************************************

// kenshi: added wd global to run on my local 
if c(username) == "kkawade" {
    global boxd "/Users/kkawade/Library/CloudStorage/Box-Box/ppol6818/perev"
}

// Replace username and path below
if c(username) == "qy112" { 
    global boxd  "replace here with your boxfile path"  
}

* local directory
if c(username) == "kkawade" {
    global wd "/Users/kkawade/gu_class/ppol6818/perev"
}

// Replace username and path below
if c(username) == "yqy" { 
    global wd  "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-stata3"  
}

cd "$boxd"

*** 1-3 ***
****************************************************
clear all
set more off
set seed 410
capture program drop power50
program define power50, rclass
    syntax , N(integer)
    clear
    set obs `n'
    gen treat = (runiform() < 0.5)
    gen u = rnormal(0,1)
    gen tau = runiform(0,0.2)
    gen y = u + treat*tau
    regress y treat
    return scalar sig = (2*ttail(e(df_r), abs(_b[treat]/_se[treat])) < 0.05)
end

tempname results1
postfile `results1' N power using "Part3_Q3.dta", replace
forvalues N = 2500(50)4500 {
    quietly simulate sig = r(sig), reps(1000) nodots: power50, n(`N')
    quietly summarize sig
    local pw = r(mean)
    post `results1' (`N') (`pw')
    di "Q3: N = `N', power = " %6.3f `pw'
}
postclose `results1'

use "Part3_Q3.dta", clear
sort N
list N power if power >= 0.8
egen min_N = min(N) if power >= 0.8
summarize min_N
di "Minimum sample size required for 80% power: " r(min)

****************************************************
*** 4 ***
****************************************************
clear all
set more off
set seed 410
capture program drop power50_attr
program define power50_attr, rclass
    syntax , N(integer)
    clear
    set obs `n'
    gen treat = (runiform() < 0.5)
    gen u = rnormal(0,1)
    gen tau = runiform(0,0.2)
    gen y = u + treat*tau
    gen keep = (runiform() > 0.15)
    keep if keep == 1
    regress y treat
    return scalar sig = (2*ttail(e(df_r), abs(_b[treat]/_se[treat])) < 0.05)
end

tempname results2
postfile `results2' N power using "Part3_Q4.dta", replace
forvalues N = 3000(50)4500 {
    quietly simulate sig = r(sig), reps(1000) nodots: power50_attr, n(`N')
    quietly summarize sig
    local pw = r(mean)
    post `results2' (`N') (`pw')
    di "Q4: N = `N', power = " %6.3f `pw'
}
postclose `results2'

use "Part3_Q4.dta", clear
sort N
list, clean
list N power if power >= 0.8
egen min_N = min(N) if power >= 0.8
summarize min_N
di "Minimum sample size required for 80% power with 15% attrition: " r(min)

****************************************************
*** 5 ***
****************************************************
clear all
set more off
set seed 410
capture program drop power30
program define power30, rclass
    syntax , N(integer)
    clear
    set obs `n'
    gen treat = (runiform() < 0.3)
    gen u = rnormal(0,1)
    gen tau = runiform(0,0.2)
    gen y = u + treat*tau
    regress y treat
    return scalar sig = (2*ttail(e(df_r), abs(_b[treat]/_se[treat])) < 0.05)
end

tempname results3
postfile `results3' N power using "Part3_Q5.dta", replace
forvalues N = 3000(50)5500 {
    quietly simulate sig = r(sig), reps(1000) nodots: power30, n(`N')
    quietly summarize sig
    local pw = r(mean)
    post `results3' (`N') (`pw')
    di "Q5: N = `N', power = " %6.3f `pw'
}
postclose `results3'

use "Part3_Q5.dta", clear
sort N
list, clean
list N power if power >= 0.8
egen min_N = min(N) if power >= 0.8
summarize min_N
di "Minimum sample size required for 80% power with 30% treatment: " r(min)
