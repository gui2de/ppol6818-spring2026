* Part 2: Sampling noise in an infinite superpopulation

* Set working directory
cd "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 3"

* 1. Define the program with DGP inside (Infinite Superpopulation)
capture program drop part2_sim
program define part2_sim, rclass
    * Make sample size an argument to the program 
    args sample_size
    
    * (a) Randomly create a data set of size `sample_size` 
    clear
    set obs `sample_size'
    
    * Generate X following the DGP from Part 1 
    gen x = rnormal(50, 10)
    
    * Generate Y with a true relationship and an error source 
    * True Beta = 2, Constant = 5
    gen error = rnormal(0, 5)
    gen y = 5 + (2 * x) + error
    
    * (b) Perform regression of Y on one X
    reg y x
    
    * Extract results using the matrix method
    mat a = r(table)
    
    * (c) Return the N, beta, SEM, p-value, and confidence intervals into r()
    return scalar N = e(N)
    return scalar beta = a[1,1]        
    return scalar sem = a[2,1]         
    return scalar pval = a[4,1]        
    return scalar ci_lower = a[5,1]    
    return scalar ci_upper = a[6,1]    
end 

* 2. Run the simulations
clear
tempfile results_p2
save `results_p2', emptyok

* Generate a list containing the first twenty powers of two (4, 8, 16... up to 2^21) 
* We use a simple loop to build a local macro with these numbers
local n_list ""
forvalues i = 2/21 {
    local val = 2^`i'
    local n_list "`n_list' `val'"
}

* Add the base-10 sample sizes to our list 
local n_list "`n_list' 10 100 1000 10000 100000 1000000"

* Run the program 500 times for each sample size in our list 
* This will yield exactly 13,000 regression results (26 sample sizes * 500) 
foreach n of local n_list {
    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) 
             ci_lower=r(ci_lower) ci_upper=r(ci_upper), 
             reps(500) seed(2026): part2_sim `n'
             
    append using `results_p2'
    save `results_p2', replace
}

* Load the resulting data set into Stata 
use `results_p2', clear

* Calculate confidence interval width
gen ci_width = ci_upper - ci_lower

* Save the final Part 2 dataset
save "Part2_Simulation_Results.dta", replace

* 3. Create Part 2 Outputs (Tables and Figures) 
* Figure 1: Distribution of beta estimates by sample size
* Note: A boxplot with 26 categories can be crowded, but it shows the full trend
graph box beta, over(N) 
    yline(2, lpattern(dash) lcolor(red)) 
    title("Part 2: Beta Estimates (Infinite Superpopulation)") 
    ytitle("Estimated Beta (True Beta = 2)")
    
graph export "Part2_Figure_BetaVariation.png", replace

* Table 1: Summary statistics by sample size
preserve
collapse (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width mean_pval=pval 
         (sd) sd_beta=beta sd_sem=sem sd_ci_width=ci_width, by(N)

* Force Stata to keep 4 decimal places
format mean_beta mean_sem mean_ci_width mean_pval sd_beta sd_sem sd_ci_width %9.4f

export excel using "Part2_Table_Results.xlsx", firstrow(variables) replace
restore

* 4. Comparison: Part 1 vs Part 2 
* The prompt asks to visualize Part 1 and Part 2 together meaningfully 

* Add a source identifier to Part 2 data
use "Part2_Simulation_Results.dta", clear
gen source = "Infinite"

* Append Part 1 data
append using "Part1_Simulation_Results.dta"
replace source = "Fixed" if source == ""

* Ensure ci_width exists for all rows (in case it wasn't saved in Part 1's raw file)
replace ci_width = ci_upper - ci_lower if missing(ci_width)

* Keep only the sample sizes that overlap to make a meaningful comparison 
keep if N == 10 | N == 100 | N == 1000 | N == 10000

* Comparison Table 
preserve
collapse (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width 
         (sd) sd_beta=beta, by(N source)
         
format mean_beta mean_sem mean_ci_width sd_beta %9.4f
sort N source

export excel using "Comparison_Table_Fixed_vs_Infinite.xlsx", firstrow(variables) replace
restore

* Comparison Figure 
* This will put the Fixed and Infinite box plots side-by-side for each N
graph box beta, over(source) over(N) 
    yline(2, lpattern(dash) lcolor(red)) 
    title("Comparison: Fixed vs. Infinite Population") 
    ytitle("Estimated Beta") 
    note("Comparing N=10, 100, 1000, 10000")
    
graph export "Comparison_Figure_Fixed_vs_Infinite.png", replace
