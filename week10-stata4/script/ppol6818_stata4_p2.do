/*===========================
	
	Author: Kenshi Kawade
	Date: March 25, 2026
	Title: ppol6818 stata4
	Part: 2 of 3
	
=============================*/
if c(username) == "kkawade" {
    global wd "/Users/kkawade/GU_Class/ppol6818ex"
}

if c(username) == "username" {
    global wd "yourpathway"
}

cd "$wd/week_10/02_data"

/*

Y: Monthly consumption 

X: Mobile money access

Confounder: MM agent nearby access

Mediator: Frequency of checking balance / receiving remittence 

Collider: Mobile credit usage

*/

clear all
set seed 681804

capture program drop simreg
program define simreg, rclass

syntax, n(integer)

clear
set obs `n'

***** Confounder variable *****

*create confounder var agent access
gen agentacc = runiform()


*create a random variable that will determine treatment status
*it should also include confounder
gen random_t = rnormal() + 0.8*agent 

****** X variable (treatment) *****

*create treatment binary variable
gen mmacc = 0
*use median point of random_t to divide treatment vs control 
summ random_t, d
replace mmacc = 1 if random_t>`r(p50)'

*verify treatment => 500 and Control =>500
tab mmacc

***** Mediator *****

gen balancech = 0.5* mmacc + 0.3*runiform()

***** Y variable *****

*create outcome variable (Note: also add some treatment effect)

gen cons = rnormal() + 1.5*agent + 0.3*mmacc 
*IMPORTANT: Treatment effect size is 0.5. The distribution of betas should be centered around 0.5 when we run the CORRECT model.


***** Collider *****

gen credit_use = 0.4*mmacc + 0.3*cons + 0.3*rnormal()

***** Models *****

*Run Model 1 (no confounder) , and save results as scalars
reg cons mmacc 
matrix reg_1 = r(table) //save results as a matrix
matrix list reg_1 //list the matrix to make sure there are no issues

*save Beta + Pvalue as scalar
return scalar model1_beta = reg_1[1,1] //first row, first columns

*Run Models to test if it is confounder not IV 
reg cons agent
matrix reg_con = r(table)
return scalar modelcon_p = reg_con[4,1]

reg mmacc agentacc
matrix reg_con1 = r(table)
return scalar modelcon1_p = reg_con1[4,1]
// these pvalue should be low enough for my confounder to be significant on both cons and mmacc.

*run model 2 (controlling for confounder)
reg cons mmacc agentacc
matrix reg_2 = r(table) //save results as a matrix
matrix list reg_2 //list the matrix to make sure there are no issues

*save Beta + Pvalue as scalar
return scalar model2_beta = reg_2[1,1] //first row, first columns

* run model 3 (controlling for mediator)
reg cons mmacc agentacc balancech
matrix reg_3 = r(table)
return scalar model3_beta = reg_3[1,1]

* run model 4 (controlling for collidor)
reg cons mmacc agentacc credit
matrix reg_4 = r(table)
return scalar model4_beta = reg_4[1,1]

* run model 3 (controlling for both collidor and mediator)
reg cons mmacc agentacc balancech credit
matrix reg_5 = r(table)
return scalar model5_beta = reg_5[1,1]


end

***** Simulation with 1000 samples *****

*simulate with sample size of 1000
simulate model1_beta=r(model1_beta) model2_beta=r(model2_beta) modelcon_p = r(modelcon_p) modelcon1_p =r(modelcon1_p) model3_beta=r(model3_beta) model4_beta=r(model4_beta) model5_beta=r(model5_beta)  , reps(500): simreg, n(1000)

* Draw and save each histogram as a named graph (not a file yet)
twoway histogram model1_beta, xline(0.3, lcolor(red) lpattern(dot)) ///
    title("M1 Restricted") ///
    xtitle("Beta") ///
    name(h1, replace)

twoway histogram model2_beta, xline(0.3, lcolor(red) lpattern(dot)) ///
    title("M2 Confounder controlled") ///
    xtitle("Beta") ///
    name(h2, replace)

twoway histogram model3_beta, xline(0.3, lcolor(red) lpattern(dot)) ///
    title("M3 Mediator controlled") ///
    xtitle("Beta") ///
    name(h3, replace)

twoway histogram model4_beta, xline(0.3, lcolor(red) lpattern(dot)) ///
    title("M4 Collider controlled") ///
    xtitle("Beta") ///
    name(h4, replace)

twoway histogram model5_beta, xline(0.3, lcolor(red) lpattern(dot)) ///
    title("M5 Everything") ///
    xtitle("Beta") ///
    name(h5, replace)

* Combine into one figure and save
graph combine h1 h2 h3 h4 h5, ///
    cols(3) ///
    title("Distribution of beta across model specifications")

graph export "$wd/week_10/03_output/stata4_p2_histograms.png", replace 

sum modelcon_ modelcon1
/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  modelcon_p |        500    1.36e-30    3.04e-29          0   6.79e-28
 modelcon1_p |        500    .0000497    .0004433   9.32e-18    .006816
*/


***** Simulation with different sample size *****

tempfile simulated
local first = 1

local sample_sizes 100 200 500 1000 1500 2000 3000

foreach v of local sample_sizes {
	simulate model1_beta=r(model1_beta) model2_beta=r(model2_beta)  ///
	modelcon_p = r(modelcon_p) modelcon1_p =r(modelcon1_p)  ///
	model3_beta=r(model3_beta) model4_beta=r(model4_beta) model5_beta=r(model5_beta), ///
	reps(500): simreg, n(`v')
	
	gen n = `v'
		
	if `first'{
			save `simulated', replace  
			local first = 0
	}
	else {
			append using `simulated'  
			save `simulated', replace 
	}
}

use `simulated', clear

save "$wd/week_10/03_output/stata4_p2_simulation.dta", replace

use "$wd/week_10/03_output/stata4_p2_simulation.dta", clear


** boxplot
graph box model1 model2 model3 model4 model5, over(n, label(angle(45))) ///
	title("Sampling Distributions of {&beta} Estimate by Sample Size (True {&beta} = .3)") /// 
	ytitle("OLS Estimate of {&beta}{subscript:1}") ///
	yline(0.3, lcolor(stred) lpattern(dash) lwidth(thin)) ///
	legend(order(                                      ///
        1 "M1 Restricted"                                   ///
        2 "M2 Confounder controlled"       ///
        3 "M3 Mediator controlled"                     ///
        4 "M4 Collider controlled"                     ///
        5 "M5 Everything "))  ///
	text(0.5 0 "0.5", placement(left))
	


graph export  "$wd/week_10/03_output/stata4_p2_boxplot.png", replace

** beta changes
preserve 

collapse ///
    (mean) mean1=model1_beta mean2=model2_beta ///
           mean3=model3_beta mean4=model4_beta ///
           mean5=model5_beta                   ///
    (sd)   sd1=model1_beta   sd2=model2_beta   ///
           sd3=model3_beta   sd4=model4_beta   ///
           sd5=model5_beta                     ///
    , by(n)
	

twoway ///
    (line mean1 n, lcolor(red)    lpattern(solid))    ///
    (line mean2 n, lcolor(blue)   lpattern(solid))    ///
    (line mean3 n, lcolor(green)  lpattern(dash))     ///
    (line mean4 n, lcolor(orange) lpattern(dash))     ///
    (line mean5 n, lcolor(purple) lpattern(shortdash)), ///
    legend(order(                                      ///
        1 "M1 Restricted"                                   ///
        2 "M2 Confounder controlled"       ///
        3 "M3 Mediator controlled"                     ///
        4 "M4 Collider controlled"                     ///
        5 "M5 Everything "))                        ///
    title("Mean beta by model across different Sample Size")             ///
    ytitle("Mean coefficient on mm_access")            ///
    xtitle("Sample size")                          ///
    yline(0.3, lcolor(black) lpattern(dash))   ///
	ylabel( 0.3)
	
graph export "$wd/week_10/03_output/stata4_p2_betacomp.png", replace

** sd changes
twoway ///
    (line sd1 n, lcolor(red)    lpattern(solid))     ///
    (line sd2 n, lcolor(blue)   lpattern(solid))     ///
    (line sd3 n, lcolor(green)  lpattern(dash))      ///
    (line sd4 n, lcolor(orange) lpattern(dash))      ///
    (line sd5 n, lcolor(purple) lpattern(shortdash)) ///
    , legend(order(                                  ///
        1 "M1 Restricted"                                 ///
        2 "M2 Confounder controlled"                 ///
        3 "M3 Mediator controlled"                   ///
        4 "M4 Collider controlled"                   ///
        5 "M5 Everything"))                        ///
    title("SD of beta by model across Sample Size")          ///
    ytitle("Standard deviation of beta")             ///
    xtitle("Sample size")                        ///
    ylabel(, grid)
	
graph export "$wd/week_10/03_output/stata4_p2_sdcomp.png", replace


restore 
