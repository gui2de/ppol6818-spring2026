*Stata 3 Assignment
*Author: Zimu Zhai (Arlo)
*NetID: zz592
*Date: 03/22/2026
**********************************************

******************************** Part 1 ****************************************
global wd "/Users/zhongguochimingdijianjian/Desktop/Experiment Design/Stata_3"
cd "$wd"

** 1. Create Fixed Population
clear all
set more off

set seed 12345

set obs 10000

* Generate individual ID
gen id = _n

gen X = rnormal(0, 1)

gen epsilon = rnormal(0, 1)

* Generate Y with true relationship
gen Y = 1 + 2 * X + epsilon

label variable id      "Individual ID"
label variable X       "Covariate X ~ N(0,1)"
label variable epsilon "Error term ~ N(0,1)"
label variable Y       "Outcome Y = 1 + 2X + epsilon"

summarize X Y epsilon

* Save dataset
save "population_data.dta", replace


** 2. Define Sampling & Regression Program

clear all
set more off

capture program drop sample_regression
program define sample_regression, rclass

    * Argument: sample size
    args n

    * Load the fixed population data
    use "$wd/population_data.dta", clear

    * Randomly sample n observations (without replacement)
    sample `n', count

    * Run OLS regression
    regress Y X

    * Return results into r()
    return scalar N     = e(N)
    return scalar beta  = _b[X]
    return scalar se    = _se[X]
    return scalar tstat = _b[X] / _se[X]

    * Compute p-value and confidence intervals
    local df = e(df_r)

    return scalar pvalue = 2 * ttail(`df', abs(_b[X] / _se[X]))
    return scalar ci_lo  = _b[X] - invttail(`df', 0.025) * _se[X]
    return scalar ci_hi  = _b[X] + invttail(`df', 0.025) * _se[X]

end

** 3. Run Simulation + Analysis

clear all
set more off

* Load the program definition first
do "$wd/sampling_program.do"

* Run simulate 500 reps x 4 sample sizes

* N = 10 
simulate N=r(N) beta=r(beta) se=r(se) pvalue=r(pvalue) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
         reps(500) seed(111) nodots: sample_regression 10

gen sample_size = 10
save "$wd/sim_n10.dta", replace

* N = 100 
simulate N=r(N) beta=r(beta) se=r(se) pvalue=r(pvalue) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
         reps(500) seed(222) nodots: sample_regression 100

gen sample_size = 100
save "$wd/sim_n100.dta", replace

* N = 1,000
simulate N=r(N) beta=r(beta) se=r(se) pvalue=r(pvalue) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
         reps(500) seed(333) nodots: sample_regression 1000

gen sample_size = 1000
save "$wd/sim_n1000.dta", replace

* N = 10,000
simulate N=r(N) beta=r(beta) se=r(se) pvalue=r(pvalue) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
         reps(500) seed(444) nodots: sample_regression 10000

gen sample_size = 10000
save "$wd/sim_n10000.dta", replace

* Combine all 2,000 results

use "$wd/sim_n10.dta", clear
append using "$wd/sim_n100.dta"
append using "$wd/sim_n1000.dta"
append using "$wd/sim_n10000.dta"

* Label
label variable beta        "Beta estimate (OLS)"
label variable se          "Standard Error of beta"
label variable pvalue      "P-value (two-tailed)"
label variable ci_lo       "95% CI Lower Bound"
label variable ci_hi       "95% CI Upper Bound"
label variable sample_size "Sample Size (N)"

save "$wd/simulation_results.dta", replace


** TABLE: Summary statistics by sample size
* Compute CI width
gen ci_width = ci_hi - ci_lo

table sample_size, ///
    stat(mean beta) stat(sd beta) ///
    stat(mean se) stat(mean ci_width) ///
    nformat(%9.4f)

preserve
    collapse (mean) mean_beta=beta (sd) sd_beta=beta ///
             (mean) mean_se=se (mean) mean_ciwidth=ci_width ///
             (mean) mean_pval=pvalue, by(sample_size)

    * Add true beta for reference
    gen true_beta = 2

    format mean_beta sd_beta mean_se mean_ciwidth mean_pval %9.4f
    list sample_size true_beta mean_beta sd_beta mean_se mean_ciwidth mean_pval, ///
         separator(0) noobs

    export delimited "$wd/simulation_table.csv", replace
restore


* FIGURE 1:  Distribution of beta by sample size

twoway ///
    (kdensity beta if sample_size == 10,     lcolor(red)    lwidth(medium)) ///
    (kdensity beta if sample_size == 100,    lcolor(orange) lwidth(medium)) ///
    (kdensity beta if sample_size == 1000,   lcolor(green)  lwidth(medium)) ///
    (kdensity beta if sample_size == 10000,  lcolor(blue)   lwidth(medium)) ///
    , xline(2, lcolor(black) lpattern(dash)) ///
    legend(order(1 "N=10" 2 "N=100" 3 "N=1,000" 4 "N=10,000") ///
           position(1) ring(0)) ///
    title("Distribution of Beta Estimates by Sample Size") ///
    subtitle("Dashed line = True beta (2)") ///
    xtitle("Beta Estimate") ytitle("Density") ///
    scheme(s2color)

graph export "$wd/figure1_beta_distribution.png", replace width(1200)


* FIGURE 2: SE and CI width vs. sample size

preserve
    collapse (mean) mean_se=se (mean) mean_ciwidth=ci_width, by(sample_size)

    twoway ///
        (connected mean_se sample_size, lcolor(navy) mcolor(navy) msymbol(circle)) ///
        (connected mean_ciwidth sample_size, lcolor(maroon) mcolor(maroon) msymbol(square)) ///
        , legend(order(1 "Mean SE" 2 "Mean CI Width") position(1) ring(0)) ///
        title("SE and CI Width as N Increases") ///
        xtitle("Sample Size (N)") ytitle("Value") ///
        xlabel(10 100 1000 10000) xscale(log) ///
        scheme(s2color)

    graph export "$wd/figure2_se_ci_by_n.png", replace width(1200)
restore


* FIGURE 3: Box plots of beta by sample size

graph box beta, over(sample_size) ///
    yline(2, lcolor(red) lpattern(dash)) ///
    title("Beta Estimates by Sample Size") ///
    subtitle("Red dashed line = True beta (2)") ///
    ytitle("Beta Estimate") ///
    scheme(s2color)

graph export "$wd/figure3_boxplot_beta.png", replace width(1200)


******************************** Part 2 ****************************************
global wd "/Users/zhongguochimingdijianjian/Desktop/Experiment Design/Stata_3"
cd "$wd"

clear all
set more off

** 1. Define the program

capture program drop sim_superpop
program define sim_superpop, rclass
    args n
    
    * Drop existing data and create n new observations
    drop _all
    set obs `n'
    
    * New draw each time
    gen X = rnormal(0, 1)
    
    gen epsilon = rnormal(0, 1)
    
    gen Y = 1 + 2 * X + epsilon
    
    regress Y X
    
    local df = e(df_r)
    return scalar N      = e(N)
    return scalar beta   = _b[X]
    return scalar se     = _se[X]
    return scalar pvalue = 2 * ttail(`df', abs(_b[X] / _se[X]))
    return scalar ci_lo  = _b[X] - invttail(`df', 0.025) * _se[X]
    return scalar ci_hi  = _b[X] + invttail(`df', 0.025) * _se[X]

end

** 2. Define all sample sizes

* Loop over all sizes and append results
local sizes "4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 10 100 1000 10000 100000 1000000"

* Temp file to accumulate results
tempfile combined
local first = 1

local seed_val = 100

foreach n of local sizes {
    
    di "Running N = `n'..."
    
    simulate N=r(N) beta=r(beta) se=r(se) pvalue=r(pvalue) ///
             ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
             reps(500) seed(`seed_val') nodots: sim_superpop `n'
    
    gen sample_size = `n'
    
    if `first' == 1 {
        save "`combined'", replace
        local first = 0
    }
    else {
        append using "`combined'"
        save "`combined'", replace
    }
    
    local seed_val = `seed_val' + 1
}

* Load final combined dataset (13,000 obs)
use "`combined'", clear

* Label variables
label variable beta        "Beta estimate (OLS)"
label variable se          "Standard Error of beta"
label variable pvalue      "P-value (two-tailed)"
label variable ci_lo       "95% CI Lower Bound"
label variable ci_hi       "95% CI Upper Bound"
label variable sample_size "Sample Size (N)"

* Compute CI width
gen ci_width = ci_hi - ci_lo
label variable ci_width "95% CI Width"

save "$wd/part2_simulation_results.dta", replace


** 3. TABLE: Summary by sample size

preserve
    collapse (mean) mean_beta=beta (sd) sd_beta=beta ///
             (mean) mean_se=se (mean) mean_ciwidth=ci_width ///
             (mean) mean_pval=pvalue, by(sample_size)

    gen true_beta = 2
    gen bias = mean_beta - true_beta
    sort sample_size

    format mean_beta sd_beta mean_se mean_ciwidth mean_pval bias %9.4f

    list sample_size true_beta mean_beta bias sd_beta mean_se mean_ciwidth mean_pval, ///
         separator(0) noobs

    export delimited "$wd/part2_table.csv", replace
restore

** 4 FIGURE 1: Beta distribution
* A few representative sizes picked

twoway ///
    (kdensity beta if sample_size == 4,       lcolor(red)       lwidth(medium)) ///
    (kdensity beta if sample_size == 64,      lcolor(orange)    lwidth(medium)) ///
    (kdensity beta if sample_size == 1024,    lcolor(green)     lwidth(medium)) ///
    (kdensity beta if sample_size == 16384,   lcolor(blue)      lwidth(medium)) ///
    (kdensity beta if sample_size == 1000000, lcolor(purple)    lwidth(medium)) ///
    , xline(2, lcolor(black) lpattern(dash)) ///
    legend(order(1 "N=4" 2 "N=64" 3 "N=1,024" 4 "N=16,384" 5 "N=1,000,000") ///
           position(1) ring(0)) ///
    title("Part 2: Distribution of Beta Estimates by Sample Size") ///
    subtitle("Infinite superpopulation | Dashed = True beta (2)") ///
    xtitle("Beta Estimate") ytitle("Density") ///
    scheme(s2color)

graph export "$wd/part2_figure1_beta_distribution.png", replace width(1400)

** 5. FIGURE 2: SE and CI width vs. log(N)

preserve
    collapse (mean) mean_se=se (mean) mean_ciwidth=ci_width, by(sample_size)
    sort sample_size

    gen log_n = log10(sample_size)

    twoway ///
        (connected mean_se sample_size, lcolor(navy) mcolor(navy) msymbol(circle)) ///
        (connected mean_ciwidth sample_size, lcolor(maroon) mcolor(maroon) msymbol(square)) ///
        , legend(order(1 "Mean SEM" 2 "Mean CI Width") position(1) ring(0)) ///
        title("Part 2: SEM and CI Width vs. Sample Size") ///
        subtitle("Infinite superpopulation — note log scale on x-axis") ///
        xtitle("Sample Size (N, log scale)") ytitle("Value") ///
        xscale(log) ///
        scheme(s2color)

    graph export "$wd/part2_figure2_se_ci.png", replace width(1400)
restore

** 6. COMPARISON: Part 1 vs Part 2

* Load Part 1 results
use "$wd/simulation_results.dta", clear
gen part = 1
save "$wd/part1_tagged.dta", replace

* Load Part 2 results, keep only overlapping N
use "$wd/part2_simulation_results.dta", clear
keep if inlist(sample_size, 10, 100, 1000, 10000)
gen part = 2

append using "$wd/part1_tagged.dta"

* Comparison table
preserve
    collapse (mean) mean_beta=beta (sd) sd_beta=beta ///
             (mean) mean_se=se (mean) mean_ciwidth=ci_width, ///
             by(sample_size part)

    sort sample_size part
    format mean_beta sd_beta mean_se mean_ciwidth %9.4f

    list sample_size part mean_beta sd_beta mean_se mean_ciwidth, ///
         separator(2) noobs

    export delimited "$wd/comparison_table.csv", replace
restore

* Comparison figure: SE by N
preserve
    collapse (mean) mean_se=se, by(sample_size part)
    sort part sample_size

    twoway ///
        (connected mean_se sample_size if part==1, lcolor(navy)   msymbol(circle) lpattern(solid)) ///
        (connected mean_se sample_size if part==2, lcolor(maroon) msymbol(square) lpattern(dash))  ///
        , legend(order(1 "Part 1 (Finite pop)" 2 "Part 2 (Infinite superpop)") ///
                 position(1) ring(0)) ///
        title("SEM Comparison: Part 1 vs Part 2") ///
        xtitle("Sample Size (N, log scale)") ytitle("Mean SEM") ///
        xscale(log) xlabel(10 100 1000 10000) ///
        scheme(s2color)

    graph export "$wd/comparison_figure_se.png", replace width(1400)
restore


******************************** Part 3 ****************************************

global wd "/Users/zhongguochimingdijianjian/Desktop/Experiment Design/Stata_3"
cd "$wd"

clear all
set more off

** Program 1: Base case (p=0.5, no attrition)


capture program drop sim_power_base
program define sim_power_base, rclass
    args n

    drop _all
    set obs `n'

    * Individual treatment effect ~ Uniform(0, 0.2), mean = 0.1
    gen tau_i = runiform(0, 0.2)

    * Treatment assignment: 50/50
    gen D = (runiform() < 0.5)

    * Y(0) ~ N(0,1), observed Y
    gen Y = rnormal(0, 1) + D * tau_i

    regress Y D

    local df = e(df_r)
    return scalar reject = (2 * ttail(`df', abs(_b[D]/_se[D])) < 0.05)
    return scalar beta   = _b[D]
    return scalar se     = _se[D]

end

** Program 2: With 15% attrition (p=0.5)

capture program drop sim_power_attrit
program define sim_power_attrit, rclass
    args n

    drop _all
    set obs `n'

    gen tau_i = runiform(0, 0.2)
    gen D = (runiform() < 0.5)
    gen Y = rnormal(0, 1) + D * tau_i

    * 15% attrition equally in both arms — drop those obs
    gen attrit = (runiform() < 0.15)
    drop if attrit == 1

    regress Y D

    local df = e(df_r)
    return scalar reject = (2 * ttail(`df', abs(_b[D]/_se[D])) < 0.05)
    return scalar beta   = _b[D]
    return scalar se     = _se[D]

end

** Program 3: Treatment share p=0.30

capture program drop sim_power_p30
program define sim_power_p30, rclass
    args n

    drop _all
    set obs `n'

    gen tau_i = runiform(0, 0.2)

    * Only 30% get treatment
    gen D = (runiform() < 0.3)

    gen Y = rnormal(0, 1) + D * tau_i

    regress Y D

    local df = e(df_r)
    return scalar reject = (2 * ttail(`df', abs(_b[D]/_se[D])) < 0.05)
    return scalar beta   = _b[D]
    return scalar se     = _se[D]

end

** Simulation loop

local test_sizes "500 1000 1500 2000 2500 3000 3250 3500 3750 4000 4500 5000 6000"

* Scenario 1: Base 

tempfile s1
local first = 1
local seed = 1000

foreach n of local test_sizes {

    simulate reject=r(reject) beta=r(beta) se=r(se), ///
        reps(500) seed(`seed') nodots: sim_power_base `n'

    collapse (mean) power=reject (mean) mean_beta=beta (mean) mean_se=se
    gen sample_size = `n'
    gen scenario = 1

    if `first' == 1 {
        save "`s1'", replace
        local first = 0
    }
    else {
        append using "`s1'"
        save "`s1'", replace
    }

    local seed = `=`seed' + 1'
}

* Scenario 2: 15% Attrition
tempfile s2
local first = 1

foreach n of local test_sizes {
    simulate reject=r(reject) beta=r(beta) se=r(se), ///
             reps(500) seed(`seed') nodots: sim_power_attrit `n'
    collapse (mean) power=reject (mean) mean_beta=beta (mean) mean_se=se
    gen sample_size = `n'
    gen scenario = 2
    if `first'==1 { 
		save "`s2'", replace
		local first=0 
		}
    else { 
		append using "`s2'"
		save "`s2'", replace 
	}
		
    local seed = `=`seed' + 1'
}

* Scenario 3: p=0.30 
tempfile s3
local first = 1

foreach n of local test_sizes {
    simulate reject=r(reject) beta=r(beta) se=r(se), ///
             reps(500) seed(`seed') nodots: sim_power_p30 `n'
    collapse (mean) power=reject (mean) mean_beta=beta (mean) mean_se=se
    gen sample_size = `n'
    gen scenario = 3
    if `first'==1 { 
		save "`s3'", replace
		local first=0 
		}
    else { 
		append using "`s3'"
		save "`s3'", replace
	}
	
    local seed = `=`seed' + 1'
}

** Combine all scenarios
use "`s1'", clear
append using "`s2'"
append using "`s3'"

label define sc 1 "Base (p=0.5)" 2 "15% Attrition" 3 "p=0.30"
label values scenario sc

sort scenario sample_size
format power mean_beta mean_se %9.4f

save "$wd/part3_sim_power.dta", replace

** Show results
use "$wd/part3_sim_power.dta", clear
sort scenario sample_size
list scenario sample_size power if power >= 0.8, sepby(scenario)


******************************** Part 4 ****************************************

global wd "/Users/zhongguochimingdijianjian/Desktop/Experiment Design/Stata_3"
cd "$wd"

clear all
set more off

** Program: cluster RCT simulation

capture program drop sim_cluster
program define sim_cluster, rclass
    args n_clusters cluster_size compliance

    drop _all

    * Total observations
    local n_total = `n_clusters' * `cluster_size'
    set obs `n_total'

    * School ID
    gen school_id = ceil(_n / `cluster_size')

    * School-level random effect ~ N(0, sqrt(0.3))
    * ICC = 0.3/(0.3+0.7) = 0.3
    gen school_effect = .
    forvalues j = 1/`n_clusters' {
        local u = rnormal(0, sqrt(0.3))
        replace school_effect = `u' if school_id == `j'
    }

    * Individual error ~ N(0, sqrt(0.7))
    gen epsilon = rnormal(0, sqrt(0.7))

    * School-level treatment assignment (50/50, at school level)
    gen D_school = .
    local half = `n_clusters' / 2
    forvalues j = 1/`n_clusters' {
        if `j' <= `half' {
            replace D_school = 1 if school_id == `j'
        }
        else {
            replace D_school = 0 if school_id == `j'
        }
    }

    * Partial compliance: only (compliance)% of treated schools actually treat
    * Effective treatment = D_school * (runiform() < compliance)
    gen D = .
    forvalues j = 1/`n_clusters' {
        * get D_school for this school
        qui sum D_school if school_id == `j'
        local ds = r(mean)
        if `ds' == 1 {
            * treated school: comply with probability = compliance
            local comply = (runiform() < `compliance')
            replace D = `comply' if school_id == `j'
        }
        else {
            replace D = 0 if school_id == `j'
        }
    }

    * School-level treatment effect ~ Uniform(0.15, 0.25)
    gen tau_school = .
    forvalues j = 1/`n_clusters' {
        local tau = 0.15 + runiform() * 0.10
        replace tau_school = `tau' if school_id == `j'
    }

    * Observed outcome
    gen Y = school_effect + epsilon + D * tau_school

    * Cluster-robust regression (regress with vce cluster)
    regress Y D, vce(cluster school_id)

    local df = e(df_r)
    return scalar reject = (2 * ttail(`df', abs(_b[D]/_se[D])) < 0.05)
    return scalar beta   = _b[D]
    return scalar se     = _se[D]
    return scalar N_clus = `n_clusters'
    return scalar clus_size = `cluster_size'

end

** 5. Fix n_clusters=200, vary cluster size

local clus_sizes "2 4 8 16 32 64 128 256 512"

tempfile q5_results
local first = 1
local seed = 2000

foreach cs of local clus_sizes {
    di "  cluster_size = `cs'..."
    simulate reject=r(reject) beta=r(beta) se=r(se), ///
             reps(500) seed(`seed') nodots: sim_cluster 200 `cs' 1

    collapse (mean) power=reject (mean) mean_beta=beta (mean) mean_se=se
    gen n_clusters  = 200
    gen cluster_size = `cs'
    gen scenario = "Q5: vary cluster size"

    if `first'==1 { 
		save "`q5_results'", replace
		local first=0 
		}
    else { 
		append using "`q5_results'"
		save "`q5_results'", replace
	}

    local seed = `=`seed' + 1'
}

use "`q5_results'", clear
sort cluster_size
format power mean_beta mean_se %9.4f
di "N_clusters=200 | cluster_size | power"
list n_clusters cluster_size power mean_beta mean_se, noobs sep(0)
save "$wd/part4_q5.dta", replace

** 6. Fix cluster_size=15, vary n_clusters

local n_clus_list "20 40 60 80 100 120 140 160 180 200 250 300"

tempfile q6_results
local first = 1

foreach nc of local n_clus_list {
    di "  n_clusters = `nc'..."
    simulate reject=r(reject) beta=r(beta) se=r(se), ///
             reps(500) seed(`seed') nodots: sim_cluster `nc' 15 1

    collapse (mean) power=reject (mean) mean_beta=beta (mean) mean_se=se
    gen n_clusters   = `nc'
    gen cluster_size = 15
    gen scenario = "Q6: vary n_clusters"

    if `first'==1 { 
		save "`q6_results'", replace
		local first=0 
	}
    else { 
		append using "`q6_results'"
		save "`q6_results'", replace 
	}

    local seed = `=`seed' + 1'
}

use "`q6_results'", clear
sort n_clusters
format power mean_beta mean_se %9.4f
list n_clusters cluster_size power mean_beta mean_se, noobs sep(0)

di ""
di "First n_clusters with power >= 0.80:"
qui levelsof n_clusters if power >= 0.80, local(passing)
local min_nc : word 1 of `passing'
di "  → `min_nc' schools needed (cluster_size=15)"

save "$wd/part4_q6.dta", replace

** 7. 70% compliance, cluster_size=15, vary n_clusters
local n_clus_list "20 60 100 140 180 200 250 300 310 320"
local first7 = 1
local seed = 4000

foreach nc of local n_clus_list {
    di "n_clusters = `nc'"
    simulate reject=r(reject) beta=r(beta) se=r(se), reps(500) seed(`seed') nodots: sim_cluster `nc' 15 0.7
    collapse (mean) power=reject (mean) mean_beta=beta (mean) mean_se=se
    gen n_clusters   = `nc'
    gen cluster_size = 15
    gen scenario     = "Q7: 70% compliance"
    if `first7' == 1 {
        save "$wd/q7_results.dta", replace
        local first7 = 0
    }
    else {
        append using "$wd/q7_results.dta"
        save "$wd/q7_results.dta", replace
    }
    local seed = `seed' + 1
}

use "$wd/q7_results.dta", clear
sort n_clusters
format power mean_beta mean_se %9.4f
list n_clusters cluster_size power mean_beta mean_se, noobs sep(0)

di "First n_clusters with power >= 0.80 (70% compliance):"
qui levelsof n_clusters if power >= 0.80, local(passing2)
local min_nc2 : word 1 of `passing2'
di "  → `min_nc2' schools needed"

save "$wd/part4_q7.dta", replace

