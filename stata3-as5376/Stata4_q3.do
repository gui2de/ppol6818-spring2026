//Step 1- Program
capture program drop cluster_sim
program define cluster_sim, rclass
    syntax , n_schools(integer) students_per_school(integer) treat_effect(real)
    
    clear
    set obs `n_schools'
    gen school_id = _n
    
    * School-level: Randomize treatment and school-level error
    gen treat = (_n <= `n_schools' / 2)
    gen school_error = rnormal(0, sqrt(0.3)) // Variance = 0.3
    
    * Student-level: Expand observations
    expand `students_per_school'
    gen student_error = rnormal(0, sqrt(0.7)) // Variance = 0.7
    
    * Generate Outcome Y (Math Score)
    * Effect is uniform(0.15, 0.25), average 0.2
    gen effect = runiform(0.15, 0.25)
    gen y = (effect * treat) + school_error + student_error
    
    * Regression with Cluster-Robust Standard Errors
    reg y treat, vce(cluster school_id)
    return scalar sig = (r(table)[4,1] < 0.05)
end

//Step 2- Increasing Cluster Size
tempfile size_results
save `size_results', emptyok

forvalues i = 1/10 {
    local c_size = 2^`i'
    simulate sig=r(sig), reps(200) nodots: ///
             cluster_sim, n_schools(200) students_per_school(`c_size') treat_effect(0.2)
             
    gen cluster_size = `c_size'
    append using `size_results'
    save `size_results', replace
}

//Step 3- Increasing Cluster Size
* k1 and k2 are number of clusters (schools)
* m1 and m2 are cluster sizes (15)
power twomeans 0 0.2, sd(1) m1(15) m2(15) rho(0.3) power(0.8)

//Step 4- Hold the Cluster Size Fixed
power twomeans 0 0.14, sd(1) m1(15) m2(15) rho(0.3) power(0.8)

//Step 5-  Checking Cluster Power via Simulation
capture program drop sim_cluster_rct
program define sim_cluster_rct, rclass
    args total_schools students_per_school

    drop _all
    
    * 1. Create the Schools (Clusters)
    set obs `total_schools'
    gen school_id = _n
    
    * Half the schools get treatment, half get control
    gen is_treated = (_n <= `total_schools' / 2)
    
    * Create school-level noise (Variance = 0.3 to match our ICC of 0.3)
    gen school_noise = rnormal(0, sqrt(0.3))
    
    * 2. Expand to Create Students within Schools
    expand `students_per_school'
    
    * Create student-level noise (Variance = 0.7 so total variance = 1.0)
    gen student_noise = rnormal(0, sqrt(0.7))
    
    * 3. Generate the Heterogeneous Treatment Effect (Uniform 0.15 to 0.25)
    gen school_effect = runiform(0.15, 0.25)
    
    * 4. Calculate Final Math Score (Outcome Y)
    gen math_score = (is_treated * school_effect) + school_noise + student_noise
    
    * 5. Run Regression WITH Cluster-Robust Standard Errors!
    quietly regress math_score is_treated, vce(cluster school_id)
    
    * 6. Extract and Return Results
    matrix reg_matrix = r(table)
    scalar p_value = reg_matrix[4,1]
    
    return scalar is_sig   = (p_value < 0.05)
    return scalar est_beta = reg_matrix[1,1]
end

//Step 5- Run the Simulation to "Check" the Math (Using K=274 schools, M=15 students)
simulate stat_power=r(is_sig) avg_beta=r(est_beta), reps(1000) nodots: sim_cluster_rct 274 15

* Print the final simulated power check
sum stat_power avg_beta
