* Part 1, Do-File 2: Program, Simulation, and Outputs

* Set working directory
cd "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 3"

* 1. Define the sampling and regression program
capture program drop part1_sim
program define part1_sim, rclass
    * Make sample size an argument to the program 
    args sample_size
    
    * (a) Load the fixed population data 
    use "Part1_Fixed_Population.dta", clear
    
    * (b) Randomly sample a subset based on the argument provided
    sample `sample_size', count
    
    * (c) Perform regression of Y on X 
    reg y x
    
    * Extract results using the matrix method shown in class notes
    mat a = r(table)
    
    * (e) Return the N, beta, SEM, p-value, and confidence intervals into r() 
    return scalar N = e(N)
    return scalar beta = a[1,1]        
    return scalar sem = a[2,1]         
    return scalar pval = a[4,1]        
    return scalar ci_lower = a[5,1]    
    return scalar ci_upper = a[6,1]    
end 

* 2. Run the simulations using the simulate command
clear
tempfile results
save `results', emptyok

* Run program 500 times each at sample sizes N = 10, 100, 1,000, and 10,000 
foreach n in 10 100 1000 10000 {
    
    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) 
             ci_lower=r(ci_lower) ci_upper=r(ci_upper),
             reps(500) seed(2026): part1_sim `n'
             
    append using `results'
    save `results', replace
}

* Load the resulting data set of 2,000 regression results into Stata 
use `results', clear
save "Part1_Simulation_Results.dta", replace

* 3. Create outputs (Table and Figure) 

* Create a table showing variation in beta estimates depending on sample size
preserve
collapse (mean) mean_beta=beta mean_sem=sem mean_ci_lower=ci_lower mean_ci_upper=ci_upper 
         (sd) sd_beta=beta, by(N)

* Force Stata to keep 4 decimal places 
format mean_beta mean_sem mean_ci_lower mean_ci_upper sd_beta %9.4f
         
* Export the summary table to Excel 
export excel using "Part1_Table_Results.xlsx", firstrow(variables) replace
restore

* Create at least one figure showing the variation in beta estimates 
graph box beta, over(N) 
    title("Part 1: Variation in Beta Estimates by Sample Size") 
    ytitle("Estimated Beta (True Beta = 2)") 
    note("Fixed Population N=10,000. 500 Repetitions per Sample Size.")
    
* Export the figure to your folder
graph export "Part1_Figure_BetaVariation.png", replace
