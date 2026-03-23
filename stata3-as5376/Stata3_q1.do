//Step 1- Generate dataset
clear all
set seed 12345 // Ensures reproducibility

* 1. Create 10,000 observations
set obs 10000

* 2. Generate X (Independent Variable)
gen x = rnormal(50, 10) 

* 3. Generate Y (Outcome) with a true Beta of 1.5 and an error term
gen error = rnormal(0, 25)
gen y = 10 + 1.5*x + error

* 4. Save the population data
save "fixed_population.dta", replace

//Step 2- Program
capture program drop run_regression
program define run_regression, rclass
    syntax , n(integer)
    
    * Load the population
    use "fixed_population.dta", clear
    
    * Randomly sample n observations
    sample `n', count
    
    * Perform regression
    regress y x
    
    * Return results to r()
    return scalar N = e(N)
    return scalar beta = _b[x]
    return scalar sem = _se[x]
    return scalar pval = (2 * ttail(e(df_r), abs(_b[x]/_se[x])))
    return scalar ci_low = _b[x] - invt(e(df_r), 0.975)*_se[x]
    return scalar ci_high = _b[x] + invt(e(df_r), 0.975)*_se[x]
end

//Step 3- Regression
tempfile combined_results
save `combined_results', emptyok

foreach size in 10 100 1000 10000 {
    display "Simulating N = `size'..."
    simulate b=r(beta) se=r(sem) p=r(pval) ll=r(ci_low) ul=r(ci_high), reps(500) nodots: run_regression, n(`size')
             
    gen sample_size = `size'
    append using `combined_results'
    save `combined_results', replace
}

use `combined_results', clear
save "stata3_q1_results.dta", replace

//Step 4- Generate tables and graph

graph box b, over(sample_size) ///
    title("Variation in Beta Estimates by Sample Size") ///
    ytitle("Estimated Beta (True Beta = 1.5)") ///
    note("Note: Variation narrows significantly as N increases.")
	
tabstat b se ll ul, by(sample_size) statistics(mean sd min max) columns(statistics) 

table sample_size, stat(mean b) stat(sd b) stat(mean se) stat(mean ll-ul) nformat(%9.4f) name(beta_table)
