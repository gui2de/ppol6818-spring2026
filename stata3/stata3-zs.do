* ==========================================
* PART 1: Fixed Population Simulation
* ==========================================
clear all
set seed 12345

* 1. Create the fixed population
set obs 10000
gen x = rnormal()
* True relationship: Beta = 3, error term = rnormal() 
gen y = 2 + 3*x + rnormal() 

save "fixed_population.dta", replace

* 2. Define the program to sample and regress 
capture program drop sim_fixed
program sim_fixed, rclass
    syntax, n(integer)
    preserve
    * Load the fixed population data 
    use "fixed_population.dta", clear
    * Randomly sample 'n' observations 
    sample `n', count
    * Perform regression 
    reg y x
    
    * Return values into r() 
    return scalar N = e(N)
    return scalar beta = _b[x]
    return scalar sem = _se[x]
    return scalar pval = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar lb = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar ub = _b[x] + invttail(e(df_r), 0.025)*_se[x]
    restore
end

* 3. Run the simulation 500 times for specific sample sizes 
tempfile part1_results
save `part1_results', emptyok

foreach n in 10 100 1000 10000 {
    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
        reps(500) seed(123): sim_fixed, n(`n')
    append using `part1_results'
    save `part1_results', replace
}

* 4. Load resulting data and create a figure/table 
use `part1_results', clear
save "C:\Users\24547\Desktop\stata3\part1_results.dta", replace

* Table summarizing Beta and SEM by sample size 
tabstat beta sem, by(N) statistics(mean sd)

* Figure: Scatter plot or box plot of beta estimates 
graph box beta, over(N) title("Variation in Beta Estimates (Fixed Pop)") ///
    ytitle("Beta Estimate")
	
graph export "C:\Users\24547\Desktop\stata3\Graph1.png", replace
	

* ==========================================
* PART 2: Infinite Superpopulation Simulation
* ==========================================

* 1. Define the new program 
capture program drop sim_inf
program sim_inf, rclass
    syntax, n(integer)
    clear
    set obs `n'
    gen x = rnormal()
    gen y = 2 + 3*x + rnormal() 
    
    * Perform regression 
    reg y x
    
    return scalar N = e(N)
    return scalar beta = _b[x]
    return scalar sem = _se[x]
    return scalar pval = 2*ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar lb = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar ub = _b[x] + invttail(e(df_r), 0.025)*_se[x]
end

tempfile part2_results
save `part2_results', emptyok

* 2. Run at powers of 2 
forvalues i = 2/20 {
    local n = 2^`i'
    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
        reps(500): sim_inf, n(`n')
    append using `part2_results'
    save `part2_results', replace
}

* 3. Run at powers of 10 [cite: 16]
foreach n in 10 100 1000 10000 100000 1000000 {
    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
        reps(500): sim_inf, n(`n')
    append using `part2_results'
    save `part2_results', replace
}

* Load resulting data [cite: 17]
use `part2_results', clear
gen pop_type = "Infinite"

save "C:\Users\24547\Desktop\stata3\part2_results.dta", replace

* Figure/Table generation [cite: 18]
tabstat beta sem, by(N) statistics(mean sd)


* ==========================================
* Create Comparison Visualization (Part 1 vs Part 2)
* ==========================================
clear

use "C:\Users\24547\AppData\Local\Temp\ST_933c_000001.tmp", clear 
gen pop_type = "Infinite"

append using "part1_results.dta" 
replace pop_type = "Fixed" if pop_type == ""

keep if inlist(N, 10, 100, 1000, 10000, 100000)

collapse (sd) sd_beta=beta, by(N pop_type)


twoway (connected sd_beta N if pop_type=="Fixed", lcolor(blue) mcolor(blue)) ///
       (connected sd_beta N if pop_type=="Infinite", lcolor(red) mcolor(red)), ///
       xscale(log) xlabel(10 100 1000 10000 100000) ///
       xtitle("Sample Size (N) - Log Scale") ///
       ytitle("Standard Deviation of Beta Estimates") ///
       title("Variation in Beta: Fixed vs. Infinite Population") ///
       legend(order(1 "Fixed Population (Part 1)" 2 "Infinite Superpopulation (Part 2)"))

graph export "C:\Users\24547\Desktop\stata3\Graph_Comparison.png", replace
* ==========================================
* PART 3: Individual Randomization Power
* ==========================================

* 1. The Data Generating Process (Example) 
clear
set obs 1000
gen treat = rbinomial(1, 0.5) // 50% treatment proportion
gen effect = runiform(0.0, 0.2) // Uniformly distributed, average 0.1 sd
gen y = rnormal(0, 1) + treat * effect // Y normally distributed around 0

* 2. Base Power Calculation 
power twomeans 0 0.1, sd(1) power(0.8) 

* 3. With 15% Attrition 
display 3142 / (1 - 0.15) 

* 4. With 30% Treatment / 70% Control Allocation 
* Ratio of Control to Treatment = 70 / 30 = 2.333
power twomeans 0 0.1, sd(1) power(0.8) k1(2.3333)


* ==========================================
* PART 4: Cluster Randomization Power
* ==========================================

* 1. Program to generate the cluster DGP 
capture program drop cluster_dgp
program cluster_dgp
    syntax, num_schools(integer) cluster_size(integer)
    clear
    set obs `num_schools'
    gen school_id = _n
    
    * School-level error (Variance = 0.3) 
    gen school_effect = rnormal(0, sqrt(0.3)) 
    
    * Treatment assigned at school level (50/50 split) 
    gen treat = mod(_n, 2) 
    
    * Expand to create students within schools 
    expand `cluster_size'
    
    * Student-level error (Variance = 0.7). Total variance = 0.3+0.7=1.0. ICC = 0.3/1.0 = 0.3. 
    gen student_effect = rnormal(0, sqrt(0.7))
    
    * Treatment effect uniformly distributed between 0.15 and 0.25 
    gen effect = runiform(0.15, 0.25)
    
    gen y_math = school_effect + student_effect + treat*effect [cite: 29]
end

* 2. Fix clusters at 200, increase size using powers of 2 
forvalues i = 1/10 {
    local m = 2^`i'
    quietly power twomeans 0 0.2, k(200) m(`m') rho(0.3)
    display "Cluster size: `m', Power: " r(power)
}
* 3. Hold cluster size fixed at 15. How many schools for 80% power? [cite: 35]
power twomeans 0 0.2, m(15) rho(0.3) power(0.8)

	
	
	