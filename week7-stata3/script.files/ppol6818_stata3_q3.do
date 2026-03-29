/*==========================================================

	Author: Kenshi Kawade
	Title: stata3 assignement 
	Part: 3 out of 4

============================================================*/

if c(username) == "kkawade" {
    global boxd "/Users/kkawade/Library/CloudStorage/Box-Box/ppol6818"
}

// Replace username and path below
if c(username) == "username" { 
    global boxd  "C:/Users/username/Documents/username"  
}

* local directory
if c(username) == "kkawade" {
    global wd "/Users/kkawade/gu_class/ppol6818ex/week_8"
}

// Replace username and path below
if c(username) == "username" { 
    global wd  "C:/Users/username/Documents/username"  
}


cd "$boxd"

clear all
set more off
set seed 681803 // for reproducibility

/*==========================================================
1&2. DGP


unit: hhid
X: treatment; mobile money access(mmacc)
Y: consumption ~ Normal(0, 1)
ATE: 0.1
effect: Uniform(0, 0.2)
error:Normal(0,1)

True: cons = effect*mmacc + e

==========================================================*/

/*==========================================================
3. Baseline
==========================================================*/
* define a program 
capture program drop powerbase
program define powerbase, rclass
    syntax, n(integer) treat(real) //proportion of treatment can be different
	
    clear
    set obs `n'
    gen mmacc = (runiform(0, 1) <= `treat')
    gen effect = runiform(0, 0.2)
    gen cons0 = rnormal(0, 1)
	gen cons1 = cons0 + effect*mmacc 
	
	qui reg cons1 mmacc
    return scalar reject_yn = (r(table)["pvalue","mmacc"] < 0.05) //whether to reject the null(beta1 = 0) at 5% level
end

* simulate!!
* before simulate, predict answer by command
power twomeans 0 0.1, sd(1)  power(0.8) alpha(0.05) nratio(1)
/*
Estimated sample sizes:

            N =     3,142
  N per group =     1,571

so my simulation would have something close
*/

* prepare an empty file to load all the simulation outcomes below
tempname baseline
postfile `baseline' N power using "$boxd/output/stata3_q3_pw.dta", replace 

** simulation1 (sorting the N)
forvalues N = 2500(100)4000 {
    qui simulate reject_yn = r(reject_yn), reps(500): powerbase, n(`N') treat(0.5) //proportion of treatement is 0.5 in this case
    quietly sum reject_yn
    local pw = r(mean)
    post `baseline' (`N') (`pw')
	display as error "`N' : Power = `pw'"
}
postclose `baseline'
/*
3100 : Power = .782
3200 : Power = .8159999999999999

so somewhere between N = 3100 and 3200
*/

** simulation2 (further sorting the N)
tempname baseline
postfile `baseline' N power using "$boxd/output/stata3_q3_pw.dta", replace 

forvalues N = 3100(1)3200 {
    qui simulate reject_yn = r(reject_yn), reps(500): powerbase, n(`N') treat(0.5) //proportion of treatement is 0.5 in this case
    quietly sum reject_yn
    local pw = r(mean)
    post `baseline' (`N') (`pw')
	display as error "`N' : Power = `pw'"
}
postclose `baseline'
/*
can't really tell it's very noisy 

ex)
3109 : Power = .786
3110 : Power = .804
3111 : Power = .782
3112 : Power = .84

but, the minimum N that could have a power of higher than 80% is 3101. 
3100 : Power = .78
3101 : Power = .8179999999999999

3,101 (by simulation) and 3,142 (power calc) are not contradicting each other. The power twomeans answer is the precise theoretical value without randomness. The simulation answer is a noisy estimate of that same value, and with 500 reps the noise is large enough to shift the answer by ~40 households. 
*/

/*==========================================================
4. Attritioin
==========================================================*/
clear all
set more off
set seed 681803

* edit the program to consider about attrition rate
capture program drop powerattr
program define powerattr, rclass
    syntax , n(integer) treat(real) attr(real)
	
    clear
    set obs `n'
	
	gen mmacc = (runiform(0, 1) <= `treat')
    gen effect = runiform(0, 0.2)
    gen cons0 = rnormal(0, 1)
	gen cons1 = cons0 + effect*mmacc 
	
	*drop attriting obs
	gen attr = (runiform(0,1) <= `attr')
	drop if attr == 1
	
	qui reg cons1 mmacc
    return scalar reject_yn = (r(table)["pvalue","mmacc"] < 0.05)
end

* simulate!!
** before simulate, predict answer 
display ceil(3142 / 0.85) // power twomean answer devided people who would stay
* 3697 so it should be somewhere around there

* simulation
tempname attrition
postfile `attrition' N power using "$boxd/output/stata3_q3_pw.dta", replace 

forvalues N = 3100(100)4000{
    qui simulate reject_yn = r(reject_yn), reps(500): powerattr, n(`N') treat(0.5) attr(0.15)
    quietly sum reject_yn
    local pw = r(mean)
    post `attrition' (`N') (`pw')
	display as error "`N' : Power = `pw'"
}
postclose `attrition'

/*
3800 : Power = .79
3900 : Power = .8179999999999999
The power gets higher than 80% between 3800 and 3900. This is not contradicting the power twomean answer of 3697 because there is more noise with this simulation.
*/

/*==========================================================
5. Fewer treatments
==========================================================*/
* simulate
** before simulate, predict answer 
local ratio = .3/.7
power twomeans 0 0.1, sd(1)  power(0.8) alpha(0.05) nratio(`ratio')

display ceil(3740 / 0.85)
*4400

* simulation
tempname attrition
postfile `attrition' N power using "$boxd/output/stata3_q3_pw.dta", replace 

forvalues N = 4000(100)5000{
    qui simulate reject_yn = r(reject_yn), reps(500): powerattr, n(`N') treat(0.3) attr(0.15)
    quietly sum reject_yn
    local pw = r(mean)
    post `attrition' (`N') (`pw')
	display as error "`N' : Power = `pw'"
}
postclose `attrition'

/*
4400 : Power = .786
4500 : Power = .82
*/














