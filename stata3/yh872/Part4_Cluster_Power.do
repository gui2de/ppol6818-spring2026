* Part 4: Power calculations for cluster randomization

cd "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 3"

* 1. Define the Program for Clustered Data Generating Process
capture program drop part4_sim
program define part4_sim, rclass
    args num_clusters cluster_size
    
    clear
    * Create schools (clusters)
    set obs `num_clusters'
    gen school_id = _n
    
    * Divide schools evenly between treatment and control arms (50/50 split)
    gen rand_school = rnormal()
    egen rank_school = rank(rand_school)
    gen treatment = (rank_school <= `num_clusters'/2)
    
    * Generate cluster-level random effect (u) for ICC = 0.3
    * Based on hint: Variance of u = 0.3. SD is the square root.
    local sd_u = sqrt(0.3)
    gen u = rnormal(0, `sd_u')
    
    * Expand dataset so each school has `cluster_size` number of students
    expand `cluster_size'
    
    * Generate individual-level student error (e)
    * Based on hint: Variance of e = 1 - 0.3 = 0.7. SD is the square root.
    local sd_e = sqrt(0.7)
    gen e = rnormal(0, `sd_e')
    
    * Generate Treatment Effect
    * Uniformly distributed between 0.15 and 0.25 (mean is 0.2 sd)
    gen te = runiform(0.15, 0.25)
    
    * Generate final Math Score (Y)
    * Base score is u + e
    gen y = u + e
    * Apply treatment effect only to treatment schools
    replace y = y + te if treatment == 1
    
    * Perform regression of Y on treatment. 
    reg y treatment, vce(cluster school_id)
    mat a = r(table)
    
    * Return the p-value
    return scalar pval = a[4,1]
end

* 2. Q5: Simulation - Holding clusters fixed at 200, increasing cluster size
clear
tempfile results_p4
save `results_p4', emptyok

* Loop through the first 10 powers of 2 (2, 4, 8, 16, 32, 64, 128, 256, 512, 1024)
forvalues i = 1/10 {
    local c_size = 2^`i'
    
    * Run simulation 500 times for each cluster size
    quietly simulate pval=r(pval), reps(500) seed(2026): part4_sim 200 `c_size'
    
    * Record the cluster size and whether the result was significant
    gen cluster_size = `c_size'
    gen significant = (pval < 0.05)
    
    append using `results_p4'
    save `results_p4', replace
}

* Load results to create table and figure
use `results_p4', clear
save "Part4_Simulation_Results.dta", replace

* Calculate empirical power (mean of the 'significant' indicator)
collapse (mean) power=significant, by(cluster_size)
format power %9.4f

* Export the table
export excel using "Part4_Table_Power_by_ClusterSize.xlsx", firstrow(variables) replace

* Create a line graph showing how power changes as cluster size increases
graph twoway (connected power cluster_size), 
    yline(0.8, lpattern(dash) lcolor(red)) 
    title("Part 4: Power by Cluster Size (Fixed at 200 Schools)") 
    ytitle("Empirical Power") 
    xtitle("Cluster Size (Students per School)") 
    note("ICC = 0.3, Treatment Effect = 0.2 SD")
    
graph export "Part4_Figure_Power.png", replace

* 3. Q6: How many schools for 80% power (Fixed cluster size = 15)
* Note: We use m1() and m2() to specify the cluster size for both arms.
power twomeans 0 0.2, m1(15) m2(15) rho(0.3) power(0.8)

* 4. Q7: Adjusting for 70% Adoption (Imperfect Compliance)
* The effect shrinks to 0.14 SD. 
power twomeans 0 0.14, m1(15) m2(15) rho(0.3) power(0.8)
