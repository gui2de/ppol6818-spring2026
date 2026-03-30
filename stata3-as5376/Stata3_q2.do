//Step 1-Create a program
capture program drop run_superpop
program define run_superpop, rclass
    syntax , n(integer)
    
    drop _all
    set obs `n'
    
    * Generate fresh data from the DGP
    gen x = rnormal(50, 10)
    gen error = rnormal(0, 25)
    gen y = 10 + 1.5*x + error
    
    * Perform regression
    quietly regress y x
	
	matrix results = r(table)
    
    * Return results
    return scalar N = e(N)
    return scalar beta  = results[1,1]
    return scalar sem   = results[2,1]
    return scalar pval  = results[4,1]
    return scalar ci_lo = results[5,1]
    return scalar ci_hi = results[6,1]
end

//Step 2- Simulate
tempfile superpop_results
save `superpop_results', emptyok

* Define the list of sample sizes
local sizes ""
forvalues i = 2/21 {
    local val = 2^`i'
    local sizes "`sizes' `val'"
}
local sizes "`sizes' 10 100 1000 10000 100000 1000000"

foreach s in `sizes' {
    display "Simulating Superpopulation N = `s'..."
    simulate b=r(beta) se=r(sem) p=r(pval) ll=r(ci_low) ul=r(ci_high), reps(500) nodots: run_superpop, n(`s')
             
    gen sample_size = `s'
    gen source = "Superpopulation"
    append using `superpop_results'
    save `superpop_results', replace
}

save "stata3_q2_results.dta", replace

//Step 3- Generate graphs and table comparing Part1 and Part2
use "stata3_q2_results.dta", clear
gen type = 2
* Append the Fixed Population data
append using "stata3_q1_results.dta"
replace source = "Fixed Population" if source == ""

tabstat b se ll-ul, by(sample_size) stat(mean sd p50) columns(statistics) format(%9.4f) longstub

// Graph 1 - The Boxplot Comparison
* We use 'preserve' and 'restore' to temporarily filter the data just for the sample sizes that both parts share.
preserve
keep if inlist(sample_size, 10, 100, 1000, 10000)

graph box b, over(source) over(sample_size) asyvars ///
    title("Variation in Beta: Fixed vs. Superpopulation") ///
    ytitle("Estimated Beta (True = 1.5)") ///
    legend(title("Data Source") order(1 "Fixed Population" 2 "Superpopulation")) ///
    note("Note: At N=10,000, the Fixed Population has zero variance because the whole population is sampled.") ///
    name(box_comparison, replace)
restore

// Graph 2 - The Standard Error Decay Curve
* We collapse the data to get the average SE for each sample size
preserve
collapse (mean) se, by(sample_size source)

* We plot this on a log-log scale so the massive differences are visible
twoway (connected se sample_size if source == "Superpopulation", msymbol(O) mcolor(blue)) ///
       (connected se sample_size if source == "Fixed Population", msymbol(D) mcolor(red)), ///
       xscale(log) yscale(log) ///
       xlabel(10 100 1000 10000 100000 1000000, labsize(small)) ///
       title("Standard Error Decay as Sample Size Increases") ///
       xtitle("Sample Size (Log Scale)") ytitle("Mean Standard Error (Log Scale)") ///
       legend(order(1 "Superpopulation" 2 "Fixed Population (Max N=10,000)")) ///
       note("The Superpopulation SE continues to shrink steadily. The Fixed Population SE drops to zero.") ///
       name(se_decay, replace)
restore
