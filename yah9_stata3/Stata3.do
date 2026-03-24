// Housekeeping:
if "`c(username)'" == "yousrahussain" {
    global wd "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Stata Assignment"
}

// Replace 'YourName' with your computer's actual username and the path below
else if "`c(username)'" == "YourName" { 
    global wd "C:/Users/YourName/Documents/StataProject"  
}

// Safety check
else {
    display as error "User '`c(username)'' not recognized. Please update the filepath logic."
    exit
}

cd "$wd"

********
**Question 1
********

* Data Generating Process:
* X ~ N(0,1)
* e ~ N(0,1)
* Y = 2*X + e
* True beta = 2

clear 
set seed 12069
set obs 10000

//Generate variables 

gen x = rnormal(0,1)
gen e = rnormal(0,1) 
gen y = 2*x + e 

//Verification
reg y x 

save "question1_stata3.dta", replace

/*
Defining a program that: (a) loads this data; (b) randomly samples a subset whose sample size is an argument to the program; (c) performs a regression of Y on X; and (e) returns the N, beta, SEM, p-value, and confidence intervals into r().
*/

capture program drop first_exp
program define first_exp, rclass  //'rclass' allows the program to return values to r()
	args n                           
	use "question1_stata3.dta", clear        
	
	sample `n', count                   
	regress y x              
	
	matrix results = r(table)                
	
	return scalar obs     = e(N)             
	return scalar beta    = _b[x]       
	return scalar sem     = _se[x]    
	
	return scalar pval    = results[4, 1]     
	return scalar ci_low  = results[5, 1] 
	return scalar ci_high = results[6, 1] 
	
	end


//Setting temp file
tempfile master_results

//Loop through sample sizes 
foreach n in 10 100 1000 10000 {
    
    display "--- Starting Simulation for N = `n' ---"
    
    //Simulation
    simulate b=r(beta) se=r(sem) p=r(pval) ll=r(ci_low) ul=r(ci_high), ///
             reps(500) nodots: first_exp `n'
             
    gen sample_size = `n'
    
	//Logic check
    if `n' == 10 {
        save "`master_results'", replace
    }
    else {
        append using "`master_results'"
        save "`master_results'", replace
    }
}


use "`master_results'", clear

save "part1_results.dta", replace

tab sample_size
summarize

/* 5.	Create at least one figure and at least one table showing the variation in your beta estimates depending on the sample size, and characterize the size of the SEM and confidence intervals as N gets larger. */ 

**Figure 

histogram b, ///
    by(sample_size, title("{bf:Sampling Distribution of Beta}") ///
    subtitle("As N increases, the distribution narrows around the True Beta (2)")) ///
    bin(30) ///                              
    fcolor(stone%80) lcolor(black) ///        
    xline(2, lcolor(cranberry) lwidth(vthin)) /// //Red line at true beta
    xtitle("Estimated Beta Value") ///
    xlabel(0(1)4) ///                         
    scheme(s2color)

graph export "beta_histogram.png", replace


**Table 

//Labels 
label variable b "Estimated Beta"
label variable se "Standard Error (SEM)"
label variable ll "Lower 95% CI"
label variable ul "Upper 95% CI"

// 1. Label variables for a clean header
label variable b "Mean Beta"
label variable se "Mean SEM"
label variable ll "Lower CI"
label variable ul "Upper CI"

 capture dtable b se ll ul, by(sample_size) title(Variation in Beta Estimates as N Increases) nosample export(part1_table, as(pdf) replace)


*******
**Question 2
*******

/*
1.	Write a do-file defining a program that: (a) randomly creates a data set whose sample size is an argument to the program following your DGP from Part 1 including a true relationship and an error source; (b) performs a regression of Y on one X; and (c) returns the N, beta, SEM, p-value, and confidence intervals into r().
*/

clear

capture program drop second_exp
program define second_exp, rclass            
	
	args n                             

	clear                                    
	set obs `n'                      
	
	gen x = rnormal(0,1)                   
	gen e = rnormal(0,1)                     
	gen y = 2*x + e           
	
	regress y x                 

	matrix res = r(table)                    
	
	return scalar obs      = e(N)
	return scalar beta     = _b[x]     
	return scalar sem      = _se[x]   
	
	return scalar pval     = res[4, 1]
	return scalar ci_low   = res[5, 1] 
	return scalar ci_high  = res[6, 1] 

end

/*
2.	Using the simulate command, run your program 500 times each at sample sizes corresponding to the first twenty powers of two (ie, 4, 8, 16 ...); as well as at N = 10, 100, 1,000, 10,000, 100,000, and 1,000,000. Load the resulting data set of 13,000 regression results into Stata.
*/

local my_n_list ""

// 1. Add the first twenty powers of two (starting at 4, 8, 16...)
forvalues i = 2/21 {
    local p2 = 2^`i'
    local my_n_list `my_n_list' `p2'
}

// 2. Add the specific powers of ten requested
foreach p10 of numlist 10 100 1000 10000 100000 1000000 {
    local my_n_list `my_n_list' `p10'
}


// 3. Run the loop through the combined list
tempfile simulation_results
save `simulation_results', emptyok replace

foreach n in `my_n_list' {    
    
    display "--- Starting Simulation for N = `n' ---"
    
    // Run 500 simulations for the current size
    simulate b=r(beta) se=r(sem) p=r(pval) ll=r(ci_low) ul=r(ci_high), ///
             reps(500): second_exp `n'
             
    gen sample_size = `n'
    
    // Append and save to the tempfile
    append using "`simulation_results'"
    save "`simulation_results'", replace
}

// Load the final dataset of 13,000 observations (26 sizes * 500 reps)
use "`simulation_results'", clear
save "part2_results.dta", replace

summ 

**Figure 


//Pick 4 sizes to show the trend: 4, 1024, 16384, and 1000000
histogram b if inlist(sample_size, 4, 1024, 16384, 1000000), ///
    by(sample_size, title("{bf:The Consistency of OLS}") ///
    subtitle("Distribution of Beta estimates as N increases") ///
    note("Red line indicates True Beta = 2.0")) ///
    bins(60) ///                                  // More bins for smoother 'mountains'
    fcolor(teal%60) lcolor(black) lwidth(vthin) ///
    xline(2, lcolor(red) lwidth(medium)) ///      // The target
    xlabel(0(1)4) ///                             
    scheme(s2color)

graph export "beta_histogram_2.png", replace


**Table 

//Labels 
label variable b "Estimated Beta"
label variable se "Standard Error (SEM)"
label variable ll "Lower 95% CI"
label variable ul "Upper 95% CI"

// 1. Label variables for a clean header
label variable b "Mean Beta"
label variable se "Mean SEM"
label variable ll "Lower CI"
label variable ul "Upper CI"

 capture dtable b se, by(sample_size, nototals) title(Variation in Beta Estimates as N Increases) nosample export("part2_table.xlsx", replace)

//Question 2.5 

use "part2_results.dta", clear
gen source = "Part 2: Generated (Infinite)"

// 2. Add Part 1 (The "Finite" Population results)
append using "part1_results.dta"
replace source = "Part 1: Population (Finite)" if source == ""

// 3. Keep only the overlapping sample sizes to make a clean comparison
keep if inlist(sample_size, 10, 100, 1000, 10000)

// 4. Create a Comparison Table
table (sample_size) (source), stat(mean b se) nformat(%9.4f)
    
 
**********
**Question 3
**********

clear all
set seed 12345

power twomeans 0 0.1, sd(1) power(0.8) alpha(0.05)

//Parameters for 80% power
local samplesize = 3140                 
local treat_num  = 1570              

tempfile results
save `results', emptyok replace

//Loop
forvalues i = 1/1000 {
    
    clear
    set obs `samplesize'
    
    //Assign treatment to exactly 50% of the sample
        gen u = runiform()              
        sort u                         
        gen treatment = (_n <= `treat_num') 
    
    **DGP
    //Requirement 1: Baseline noise around 0 with SD of 1
    gen y0 = rnormal(0, 1) 
    
    //Requirement 2: Treatment effects between 0.0 and 0.2 SD
    gen tau = runiform(0.0, 0.2)   
    
    gen y = y0 + (tau * treatment)  
    
    reg y treatment
    
    mat a = r(table)
    
    clear
    set obs 1
    gen iteration = `i'
    gen reg_coef  = a[1,1]                   
    gen reg_pval  = a[4,1]                  
    
    append using `results'
    save `results', replace
}

//Results
use `results', clear

count if reg_pval < 0.05
local sig_count = r(N)
local power = `sig_count' / 1000

display "Calculated Empirical Power: " `power'

/*
Now assume, 15% of the sample will attrite (assume similar attrition rates in control and treatment arms.) How does this change your sample size calculations from the previous part? 
*/ 

display 3140/(1-0.15) 
display 3696/2

clear all
set seed 12345

//Parameters
local samplesize = 3696  //The recruitment target is now 3140 / 0.85               
local treat_num  = 1848  //This is half of the recruitment target


tempfile results
quietly {
    clear
    set obs 0
    gen iteration = .
    gen reg_coef  = .
    gen reg_pval  = .
    gen final_n   = .
    save `results', replace
}

//Loop
forvalues i = 1/1000 {
    
    quietly {
        clear
        set obs `samplesize'
        
        //Treatment Assignment
        gen u_rand = runiform()
        sort u_rand
        gen treatment = (_n <= `treat_num')
        
        //Attrition (15%)
        gen lost_to_followup = (runiform() < 0.15) 
        drop if lost_to_followup == 1
        
        //DGP
        gen y0 = rnormal(0, 1)
        gen tau = runiform(0, 0.2)
        gen y = y0 + (tau * treatment)
        
        //Estimation
        reg y treatment
    
        local current_n = e(N)          
        mat a = r(table) 
        local current_beta = a[1,1]
        local current_pval = a[4,1]
        
        //Result to append
        clear
        set obs 1
        gen iteration = `i'
        gen reg_coef  = `current_beta'          
        gen reg_pval  = `current_pval' 
        gen final_n   = `current_n'
        
        append using `results'
        save `results', replace
    }
    
    //Progress counter
    if mod(`i', 100) == 0 {
        display "Iteration `i' complete..."
    }
}

//Results
use `results', clear
drop if iteration == .  

//Power
count if reg_pval < 0.05
local sig_count = r(N)
local power = `sig_count' / 1000

//Output
summarize reg_coef reg_pval final_n
display "Empirical Power: " `power'


**Question 3.5***********

clear all
set seed 12345

// To maintain 80% power with a 30/70 split, the total number of people who finish the study must increase from 3,140 to 3,738. Recruited: 3738 / 0.85 = 4,398. 
local samplesize = 4398                 
local treat_num  = 1320                 // Exactly 30% of 4,400 (rounded)

tempfile results
quietly {
    clear
    set obs 0
    gen iteration = .
    gen reg_coef  = .
    gen reg_pval  = .
    gen final_n   = .
    save `results', replace
}

//Loop
forvalues i = 1/1000 {
    
    quietly {
        clear
        set obs `samplesize'
        
        //30% Treatment/70% Control
        gen u_shuffle = runiform()
        sort u_shuffle
        gen treatment = (_n <= `treat_num')
        
        //15% Drop-out
        gen attrite = (runiform() < 0.15)
        drop if attrite == 1
        
        **DGP
        gen y0 = rnormal(0, 1)          
        gen tau = runiform(0, 0.2)      
        gen y = y0 + (tau * treatment)
        
        //Estimation
        reg y treatment
        
        //Results
        local current_n = e(N)          
        mat a = r(table) 
        local current_beta = a[1,1]
        local current_pval = a[4,1]
        
        clear
        set obs 1
        gen iteration = `i'
        gen reg_coef  = `current_beta'          
        gen reg_pval  = `current_pval' 
        gen final_n   = `current_n'
        
        append using `results'
        save `results', replace
    }
    
    if mod(`i', 100) == 0 {
        display "Iteration `i' complete..."
    }
}


use `results', clear
drop if iteration == .

//Power
count if reg_pval < 0.05
local sig_count = r(N)
local power = `sig_count' / 1000

//Output
display "Initial Recruitment: 4,398"
summarize final_n
display "Empirical Power: " `power'


***
**Question 4

clear all

capture program drop school_sim
program define school_sim, rclass
    args n_schools n_students
    
    clear
    set obs `n_schools'
    gen school_id = _n
    
    //Dividing schools evenly 
    gen u_shuffle = runiform()
    sort u_shuffle
    gen treated = (_n <= `n_schools' / 2)
    
    //School-Level Error
    gen u_j = rnormal(0, sqrt(0.3))
    
    expand `n_students'
    
    //Student-Level Error
    gen e_ij = rnormal(0, sqrt(0.7))
    
    //Heterogeneous Treatment Effect: Uniform(0.15, 0.25)
    gen tau = runiform(0.15, 0.25)
    
    //Math Score 
    gen math_score = 70 + (tau * treated) + u_j + e_ij
	
	//Verify the ICC (rho). How much variance comes from the 'school_id' level
    gen baseline_score = 70 + u_j + e_ij
    loneway baseline_score school_id
    
    //Estimation (Cluster standard errors by school_id)
    reg math_score treated, vce(cluster school_id)
    
    //P-value 
    mat a = r(table)
    return scalar pval = a[4,1]
end

//2. Master Loop: Testing Cluster Sizes (Powers of 2)

tempfile power_results
save `power_results', emptyok replace

forvalues p = 1/10 {
    local c_size = 2^`p'  //Generates 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024
    
    
    //500 simulations for each size to calculate power
    simulate p=r(pval), reps(500) nodots: school_sim 200 `c_size'
    
    //Power
    gen sig = (p < 0.05)
    summarize sig
    local power_val = r(mean)
    
    //Store result 
    clear
    set obs 1
    gen cluster_size = `c_size'
    gen power = `power_val'
    append using `power_results'
    save `power_results', replace
}


use `power_results', clear
line power cluster_size, xscale(log) xlabel(2 4 8 16 32 64 128 256 512 1024) ///
     title("Power vs Cluster Size (Fixed J=200, ICC=0.3)")
	 
**Would recommend a cluster size of 256 as it generates the highest power. 

*******
****Question 4.6 and 4.7
********

capture program drop school_sim
program define school_sim, rclass
    args n_schools n_students compliance
    
    clear
    set obs `n_schools'
    gen school_id = _n
    
    gen u_shuffle = runiform()
    sort u_shuffle
    gen assigned_treat = (_n <= `n_schools' / 2)
    
    //Only % of treated schools actually adopt
    gen adopted = 0
    replace adopted = (runiform() < `compliance') if assigned_treat == 1
    
    // 3. School-Level Error (u_j) -> Variance = 0.3
    gen u_j = rnormal(0, sqrt(0.3))
    
    // 4. Expand to Students
    expand `n_students'
    
    // 5. Student-Level Error (e_ij) -> Variance = 0.7
    gen e_ij = rnormal(0, sqrt(0.7))
    
    // 6. Heterogeneous Treatment Effect (Uniform 0.15 - 0.25 SD)
    gen tau = runiform(0.15, 0.25)
    
    // 7. Final Math Score
    // Note: Only 'adopted' schools get the 'tau' boost
    gen math_score = 70 + (tau * adopted) + u_j + e_ij
    
    // 8. Intent-to-Treat (ITT) Estimation
    // We regress on the original assignment, NOT adoption
    reg math_score assigned_treat, vce(cluster school_id)
    
    // Extract P-Value
    mat a = r(table)
    return scalar pval = a[4,1]
end


set seed 12345

//100% Adoption, Fixed n=15
simulate p=r(pval), reps(500) nodots: school_sim 274 15 1.0
count if p < 0.05
local power6 = r(N)/500
display "Empirical Power (Scenario 6): " `power6'

//So we need 274 schools (137 in treatment, 137 in control).


//70% Adoption, Fixed n=15
simulate p=r(pval), reps(500) nodots: school_sim 560 15 0.7
count if p < 0.05
local power7 = r(N)/500
display "Empirical Power (Scenario 7): " `power7'

//So we need 560 schools (280 in treatment, 280 in control).






