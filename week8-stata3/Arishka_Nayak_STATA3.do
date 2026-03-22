clear all

if c(username) == "arish" {
    global project_directory "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\STATA 3"
}
*FOR REVIEWER*: 
*Add your username and path below
if c(username) == "username" { 
    global wd  "C:/Users/username/Documents/username"  
}
cd "$project_directory"


********************************************************************************
*PART 1: Sampling Noise in a Fixed Population
********************************************************************************
*Part 1(1) and 1(2)
clear
set seed 2026
set obs 10000
gen sqft=runiform()
gen error=runiform()
gen price=80+65*sqft+error
save "housing_data.dta", replace 


*Question 1(3)
capture program drop dataset
program define dataset, rclass 
syntax, n(integer)
use "$project_directory\housing_data.dta", clear
///sample `n', count
///can use bsample
bsample `n'
regress price sqft


    local obs      = e(N)
    local beta     = _b[sqft]
    local se       = _se[sqft]
    local tstat    = `beta' / `se'
    local pval     = 2 * ttail(e(df_r), abs(`tstat'))
    local ci_lo    = `beta' - invttail(e(df_r), 0.025) * `se'
    local ci_hi    = `beta' + invttail(e(df_r), 0.025) * `se'

    * Return results into r()
    return scalar N      = `obs'
    return scalar beta   = `beta'
    return scalar se     = `se'
    return scalar pval   = `pval'
    return scalar ci_lo  = `ci_lo'
    return scalar ci_hi  = `ci_hi'
end	



********************************************************************************
*Part 1(4)
********************************************************************************
clear
tempfile results
save `results', emptyok replace

foreach size in 10 100 1000 10000 {
	display "Simulating N = `size'"
    quietly simulate n=r(N) b=r(beta) se=r(se) p=r(pval) ci_low=r(ci_lo) ci_hi=r(ci_hi), reps(500) nodots: dataset, n(`size')

    append using `results'
    save `results', replace
}


********************************************************************************
*Part 1(5): creating tables and figures
********************************************************************************
tabstat b se ci_low ci_hi, by(n) statistics(mean sd min max) columns(statistics)

dtable b, by(n) title(Variation in Beta Estimates as N Increases) nosample export(part1_table, as(xlsx))
graph box b, over(n) yline(65) title("Variation in Beta Estimates")
hist b, by(n) freq
graph box se, over(n) yline(65) title("Variation in Standard Error Estimates")


********************************************************************************
*PART 2: Sampling Noise in an Infinite Superpopulation
********************************************************************************
********************************************************************************
*Part 2(1)
********************************************************************************
clear 

capture program drop housing_random
program define housing_random, rclass 
syntax, n(integer)
drop _all
set obs `n'
gen sqft=runiform()
gen error=runiform()
gen price=80+65*sqft+error
regress price sqft

    local obs      = e(N)
    local beta     = _b[sqft]
    local se       = _se[sqft]
    local tstat    = `beta' / `se'
    local pval     = 2 * ttail(e(df_r), abs(`tstat'))
    local ci_lo    = `beta' - invttail(e(df_r), 0.025) * `se'
    local ci_hi    = `beta' + invttail(e(df_r), 0.025) * `se'

    * Return results into r()
    return scalar N      = `obs'
    return scalar beta   = `beta'
    return scalar se     = `se'
    return scalar pval   = `pval'
    return scalar ci_lo  = `ci_lo'
    return scalar ci_hi  = `ci_hi'
end



********************************************************************************
*Part 2(2)*
********************************************************************************


clear
tempfile results
save `results', emptyok replace

local ns ""
forval i = 1/20 {
    local val = 2^`i'
    local ns "`ns' `val'"
}
local ns "`ns' 10 100 1000 10000 100000 1000000"

foreach size in `ns' {
    display "Simulating N = `size'"
    quietly simulate n=r(N) b=r(beta) se=r(se) p=r(pval) ci_lo=r(ci_lo) ci_hi=r(ci_hi), reps(500) nodots: housing_random, n(`size') 
    append using `results'
    save `results', replace
}

use `results', clear
count


********************************************************************************
*Part 2(3)
********************************************************************************
tabstat b se ci_lo ci_hi, by(n) statistics(mean sd min max) columns(statistics)
dtable b, by(n) title(Variation in Beta Estimates as N Increases) nosample export(part1_table, as(xlsx))
graph box b, over(n) yline(65) title("Variation in Beta Estimates")
hist b, by(n) freq
graph box se, over(n) yline(65) title("Variation in Standard Error Estimates")


********************************************************************************
*PART 3: Power calculations for individual-level randomization
********************************************************************************
*Part 3(1)-(3)*
clear
capture program drop powercalc
program define powercalc, rclass
syntax, n(integer) prop_treat(real)
*here prop_treat: proportion of treated
drop _all
set obs `n'

*To assign treatment randomly
generate treat=(runiform() < `prop_treat')
*generates a random number between 0 and 1 for each observation
*turn into 1 if <0.5
*50% of time random num>0.5, treat =1



*Uniformly distributing treatment effect b/w 0.0 and 0.2
*this is the average treatment effect 
*ATE is the 
generate avg_te=runiform(0, 0.2)

*DGP: generating outcome
*control gets N(0,1) treatment gets N(0,1)_effect
generate y=rnormal(0,1)+(treat*avg_te)
regress y treat
return scalar pval = (2*ttail(e(df_r), abs(_b[treat]/_se[treat])))
*here: if p-value is less than 0.05, it is marked as detected effect
end



*To test where we have an 80% chance of detecting the effect of 0.1 SD: 
power twomeans 0 0.1, sd(1) power(0.8)
*Min Sample size to detect a difference of 0.1 SD, with 80% power 
*with equal treatment and control sizes (nratio(1))

*this gives power 3142. running simulation to verify: 

simulate p=r(pval), reps(1000) nodots: powercalc, n(3142) prop_treat(0.5)
gen sig = (p < 0.05)
summarize sig
*this doesn't Always give 0.8, so we can round up to 3143




********************************************************************************
*Part3(4): Case 1: 15% attrition in treatment and control 
********************************************************************************
power twomeans 0 0.1, power(0.8) nratio(1)
scalar new_N = r(N) / (1 - 0.15)
display new_N


*TESTING*
simulate p=r(pval), reps(1000) nodots: powercalc, n(3696) prop_treat(0.5)
gen sig = (p < 0.05)
summarize sig

*MATH:
*we get a sample size of 3,142 people for 80% effect 
*we need to find where: 3142=0.85*sample size
*3142/0.85=3696.47 ~ 3696 (new sample size to account for attrition)





********************************************************************************
*Part3(5): Case 2: 30-70 treatment:control 
********************************************************************************

*with 50-50, we had 1 control for 1 treatment 
*with 30-70 we have 2.33 control for every 1 treatment 
*Here, the control group is 2.33 times larger than the treatment group 

*Therefore for 80% power: 
power twomeans 0 0.1, power(0.8) nratio(2.33333)
*this predicts required N= 3740 

*TESTING*
*with 3140-3142, we don't always get 0.8, so we can round up to 3143
simulate p=r(pval), reps(1000) nodots: powercalc, n(3742) prop_treat(0.3)
gen sig = (p < 0.05)
summarize sig

********************************************************************************/





********************************************************************************
*PART 4: Power calculations for cluster randomization
********************************************************************************
clear
capture program drop cluster_random
program define cluster_random, rclass
syntax, schools(integer) school_size(integer) rho(real)
*Intraclass Correlation (ICC): how similar people are in the group to one another*

clear
set obs `schools'
gen school_id=_n

gen error_school = rnormal(0, sqrt(`rho'))
*to make sure the students in the same school have same error term 

gen treat = (runiform() < 0.5)
gen treat_effect = runiform(0.15, 0.25)

expand `school_size'
*Expand replaces each observation in the dataset with n copies of the observation

gen error_student = rnormal(0, sqrt(1 - `rho'))
*student level randomness: we want total variation to be 1: SD=1, so student randomness is 1-school level randomness

gen mathscore = error_school + error_student + (treat * treat_effect)

reg mathscore treat, vce(cluster school_id)
return scalar pval = (2*ttail(e(df_r), abs(_b[treat]/_se[treat])))

*stata normall assumes every obs is completely independent/unique characteristics
*But here with school level data, some students share similarities, so if some treatment effects are attributable to group as a whole. 
*VCE here calculates SE based #schools
*this is to inflate standard errors and increase p-values so its harder to reject null (reduce type 1 error)


end



********************************************************************************
*Part 4(5): Checking for ideal cluster size
********************************************************************************
forvalues i=1/10{
	local n=2^`i'
	
	display "Simulating Ideal Cluster Size for Size =`n'"
	
	quietly simulate p=r(pval), reps(1000) nodots: cluster_random, schools(200) school_size(`n') rho(0.3)
	gen sig=(p<0.05)
	summarize sig
	
}

*The power increases at a decreasing rate with each cluster size (it has an inverted U-shape)
*Increasing the number of students per school beyond 32 provides negligible power gains. 
*therefore, I would recommend cluster size of 32
*To achieve 80% power, I would recommend increasing the number of schools rather than the cluster size.




********************************************************************************
*Part 4(6): Checking for ideal clusters
********************************************************************************


foreach size in 200 300 400 500{
	display "Simulating Ideal Clusters for Clusters = `size'"
	
	quietly simulate p=r(pval), reps(1000) nodots: cluster_random, schools(`size') school_size(15) rho(0.3)
	gen sig=(p<0.05)
	summarize sig

}


*We get power of 0.8 at a clusters = 300
*Therefore, we would need 300 schools in the RCT to get 80% to detect 0.2 SD effect





********************************************************************************
*Part 4(7): Checking for ideal clusters with attrition
********************************************************************************
*From last loop we know currently 500 clusters give 0.971 as effect size, if 30% schools drop out 
*this will reduce the power, so we can start here to see

clear
capture program drop cluster_random
program define cluster_random, rclass
syntax, schools(integer) school_size(integer) rho(real)

clear
set obs `schools'
gen school_id=_n

gen error_school = rnormal(0, sqrt(`rho'))
gen treat = (_n <= `schools'/2)
gen adopter = (runiform() < 0.70) if treat == 1
replace adopter = 0 if treat == 0


expand `school_size'
gen error_student = rnormal(0, sqrt(1 - `rho'))


gen treat_effect = runiform(0.15, 0.25)
    gen mathscore= error_school + error_student + (treat * adopter * treat_effect)

reg mathscore treat, vce(cluster school_id)
return scalar pval = (2*ttail(e(df_r), abs(_b[treat]/_se[treat])))

end




********************************************************************************
foreach size in 500 550 600 650 {
    display "Testing `s' schools with 70% Adoption for clusters = `size'"
    
    quietly simulate p=r(pval), reps(500) nodots: cluster_random, schools(`size') school_size(15) rho(0.3) 
        
    gen sig=(p<0.05)
    summarize sig
}


*This predicts numbers of schools to be 650, Therefore accounting for attrition, 
*The number of schools is 650













