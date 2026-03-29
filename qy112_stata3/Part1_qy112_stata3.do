* Stata Assignment 3 
* Author: Qingya Yang
* box directory


// kenshi: added wd global to run on my local 
if c(username) == "kkawade" {
    global boxd "/Users/kkawade/Library/CloudStorage/Box-Box/ppol6818/perev"
}

// Replace username and path below
if c(username) == "qy112" { 
    global boxd  "replace here with your boxfile path"  
}

* local directory
if c(username) == "kkawade" {
    global wd "/Users/kkawade/gu_class/ppol6818/perev"
}

// Replace username and path below
if c(username) == "yqy" { 
    global wd  "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-stata3"  
}

cd "$boxd"



****************************************************
* Part 1: Sampling noise in a fixed population
****************************************************
*** 1 ***
****************************************************
* Data generating process (DGP):
*   X ~ N(0,1)
*   u ~ N(0,2)
*   Y = 1 + 2X + u
*
* True population coefficient on X = 2

****************************************************
*** 2 ***
****************************************************
clear all
set more off

* Set seed so the population is always the same
set seed 410

* Create fixed population
set obs 10000 //kenshi: our fixed population is 10,000 not 100,000

* Unique ID
gen id = _n

* Generate X and error term u
gen x = rnormal(0,1)
gen u = rnormal(0,2)

* Generate outcome Y using the DGP from Question 1
gen y = 1 + 2*x + u

* Save fixed population
* cd "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-stata3" //kenshi: I set cd in boxfile
save "Part1_Q2.dta", replace

****************************************************
*** 3 ***
****************************************************
clear all
set more off

capture program drop sample_reg
program define sample_reg, rclass
	syntax, n(integer)

	* Load fixed population
	use "Part1_Q2.dta", clear

	* Draw a random sample of size n
	sample `n', count

	* Run regression
	reg y x

	* Extract regression results using classroom script style
	mat a = r(table)

	* Return results into r()
	return scalar N    = e(N)
	return scalar beta = a[1,1]
	return scalar sem  = a[2,1]
	return scalar pval = a[4,1]
	return scalar lb   = a[5,1]
	return scalar ub   = a[6,1]
end

****************************************************
*** 4 ***
****************************************************
tempfile sim10 sim100 sim1000 sim10000

* Simulations for N = 10
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
	reps(500) seed(1010) saving(`sim10', replace): ///
	sample_reg, n(10)

use `sim10', clear
gen sample_size = 10
save `sim10', replace


* Simulations for N = 100
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
	reps(500) seed(1100) saving(`sim100', replace): ///
	sample_reg, n(100)

use `sim100', clear
gen sample_size = 100
save `sim100', replace


* Simulations for N = 1000
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
	reps(500) seed(2000) saving(`sim1000', replace): ///
	sample_reg, n(1000)

use `sim1000', clear
gen sample_size = 1000
save `sim1000', replace


* Simulations for N = 10000
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) lb=r(lb) ub=r(ub), ///
	reps(500) seed(3000) saving(`sim10000', replace): ///
	sample_reg, n(10000)

use `sim10000', clear
gen sample_size = 10000
save `sim10000', replace


* Append all results together
use `sim10', clear
append using `sim100'
append using `sim1000'
append using `sim10000'

save "Part1_Q4.dta", replace

/*kenshi: I like that you did all the simulations individually! I did it with loop commands like this FYI;

```
tempfile simulation

foreach n in 10 100 1000 10000 {
	simulate N=r(`n'),,,,,:sample_reg, n(`n')
	
	if `n' == 10{
		save `simulation', replace
	}
	else {
		append using `simulation'
		save `simulation', replace
	}
}
```
*/

****************************************************
*** 5 ***
****************************************************
use "Part1_Q4.dta", clear

* Create confidence interval width
gen ci_width = ub - lb

* Figure1: Distribution of beta estimates by sample size
graph box beta, over(sample_size) ///
	yline(2, lpattern(dash)) ///
	title("Distribution of beta estimates by sample size") ///
	ytitle("Estimated coefficient on x") ///

graph export "Part1_Q5_estimates.png", replace

* Table: Summary statistics by sample size
preserve

collapse ///
	(mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width mean_pval=pval ///
	(sd)   sd_beta=beta sd_sem=sem sd_ci_width=ci_width ///
	(min)  min_beta=beta ///
	(max)  max_beta=beta, by(sample_size)

list, clean noobs

save "Part1_Q5.dta", replace
export excel using "Part1_Q5.xlsx", firstrow(variables) replace

* Figure2: Mean SEM by sample size（放在collapse之后，此时mean_sem已存在）
graph bar mean_sem, over(sample_size) ///
    title("Mean SEM by sample size") ///
    ytitle("Mean Standard Error")
graph export "Part1_Q5_SEM.png", replace

restore

****************************************************
*** 6 ***
****************************************************
* See README
