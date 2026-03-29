/*==========================================================

	Author: Kenshi Kawade
	Title: stata3 assignement 
	Part: 1 out of 4

============================================================*/

if c(username) == "kkawade" {
    global wd "/Users/kkawade/Library/CloudStorage/Box-Box/ppol6818"
}

// Replace username and path below
if c(username) == "username" { 
    global wd  "C:/Users/username/Documents/username"  
}

cd "$wd"

/*==========================================================
1. DEVELOP SOME DATA

unit: hhid
X: mobile money access, education, income 
Y: log consumption

============================================================*/

clear

set seed 68183 //set seed for reproducibility 

local totaln = 10000 //set individual obs
set obs `totaln'

/*==========================================================
2. GENERATE VARS
============================================================*/

* hh ID
gen hhid = _n
label variable hhid "Household ID"

* mobile money access 
gen mmpc = runiform()
gen mmacc = (mmpc < 0.5)
label variable mmacc "HH has active mobile money account (1 = yes)"
label define mmlab 0 "No mobile money" 1 "Has mobile money"
label values mmacc mmlab

* education
gen educlev = runiform()
gen prim = (educlev > .1 & educlev <= .4) 
gen high = (educlev > .4 & educlev <= .7)
gen college = (educlev > .7 & educlev <= 1)
label variable prim "HH head's highest education level is primary school"
label variable high "HH head's highest education level is highschool" 
label variable college "HH head's highest education level is college or above"

* income
gen income = runiform()*1000
label variable income "HH monthly income (USD)" 

* error term
gen e = rnormal(0, 1)

* log consumption
gen cons = 100 + 20*mmacc + 7*prim + 10*high + 5*college + .15*income + e
label variable cons "Monthly HH consumption (USD)"

* save box folder
save "$wd/output/stata3_q1_pop.dta", replace

/*==========================================================
3. DEFINE A PROGRAM
============================================================*/

capture program drop q1_reg 
program define q1_reg, rclass

	syntax, sample(integer) // set a syntax of the program

	use "$wd/output/stata3_q1_pop.dta", clear
	
	sample `sample', count 
	
	qui reg cons mmacc prim high college income
	
	* return stats
    return scalar num_hh = e(N)

    return scalar b1 = _b[mmacc]
	return scalar b2 = _b[prim]
	return scalar b3 = _b[high]
	return scalar b4 = _b[college]
	return scalar b5 = _b[income]

    return scalar se_mmacc  = _se[mmacc]
	return scalar se_prim = _se[prim]
	return scalar se_high = _se[high]
	return scalar se_col = _se[college]
	return scalar se_inc = _se[income]
	
	matrix output = r(table) // make an output table matrix

    * pvalue
    return scalar pv_mmacc = output[4, colnumb(output, "mmacc")]
    return scalar pv_prim  = output[4, colnumb(output, "prim")]
    return scalar pv_high  = output[4, colnumb(output, "high")]
    return scalar pv_col   = output[4, colnumb(output, "col")]
    return scalar pv_inc   = output[4, colnumb(output, "income")]

    * Lower CI
    return scalar lb_mmacc = output[5, colnumb(output, "mmacc")]
    return scalar lb_prim  = output[5, colnumb(output, "prim")]
    return scalar lb_high  = output[5, colnumb(output, "high")]
    return scalar lb_col   = output[5, colnumb(output, "col")]
    return scalar lb_inc   = output[5, colnumb(output, "income")]

    * Upper CI 
    return scalar ub_mmacc = output[6, colnumb(output, "mmacc")]
    return scalar ub_prim  = output[6, colnumb(output, "prim")]
    return scalar ub_high  = output[6, colnumb(output, "high")]
    return scalar ub_col   = output[6, colnumb(output, "col")]
    return scalar ub_inc   = output[6, colnumb(output, "income")]

end

/*==========================================================
4. SIMULATION
============================================================*/

tempfile simulated

foreach n in 10 100 1000 10000 {

    simulate ///
        N  = r(num_hh)  ///
        beta1  = r(b1) beta2 = r(b2) beta3 = r(b3) beta4 = r(b4) beta5 = r(b5)          ///
        se_mmacc   = r(se_mmacc) se_prim = r(se_prim) se_high = r(se_high) se_col = r(se_col) se_inc = r(se_inc) ///
		pv_mmacc   = r(pv_mmacc) pv_prim = r(pv_prim) pv_high = r(pv_high) pv_col = r(pv_col) pv_inc = r(pv_inc) ///        
        lb_mmacc   = r(lb_mmacc) lb_prim = r(lb_prim) lb_high = r(lb_high) lb_col = r(lb_col) lb_inc = r(lb_inc) ///
        ub_mmacc   = r(ub_mmacc) ub_prim = r(ub_prim) ub_high = r(ub_high) ub_col = r(ub_col) ub_inc = r(ub_inc), ///
		reps(500) : q1_reg, sample(`n')

    if `n' == 10 {
        save `simulated', replace  
    }
    else {
        append using `simulated'  
        save `simulated', replace 
    }
}

save "$wd/output/stata3_q1_simulated.dta", replace

/*==========================================================
5. DATA VIS
============================================================*/

use "$wd/output/stata3_q1_simulated.dta", clear

gen samp_group = .
replace samp_group = 1 if N == 10
replace samp_group = 2 if N == 100
replace samp_group = 3 if N == 1000
replace samp_group = 4 if N == 10000
label define samplab 1 "N = 10" 2 "N = 100" 3 "N = 1,000" 4 "N = 10,000"
label values samp_group samplab

local vars "mmacc prim high col inc"
foreach v of local vars {
	gen ciw_`v' = ub_`v' - lb_`v'
}

* Boxplot
graph box beta*, ///
    over(samp_group) ///
    title("Sampling Distributions of {&beta} Estimates by Sample Size", size(medlarge) color(black)) ///
	subtitle("Fixed 10k Population, 500 Simulation") ///
    ytitle("OLS Estimate of {&beta}{subscript:k}") ///
	yline(20, lcolor(stblue) lpattern(dash) lwidth(thin)) ///
	yline(7, lcolor(stred) lpattern(dash) lwidth(thin)) ///
	yline(10, lcolor(stgreen) lpattern(dash) lwidth(thin)) ///
	yline(5,lcolor(styellow) lpattern(dash) lwidth(thin)) ///
	yline(.15, lcolor(purple) lpattern(dash) lwidth(thin)) ///
	legend(label(1 "{&beta}{subscript:mmacc} : True {&beta} = 20") label(2 "{&beta}{subscript:prim} : True {&beta} = 7") ///
		label(3 "{&beta}{subscript:high} : True {&beta} = 10") label(4 "{&beta}{subscript:college} : True {&beta} = 5") ///
		label(5 "{&beta}{subscript:inc} : True {&beta} = .15"))

graph export "$wd/output/stata3_q1_boxplot.png", replace 

* s.e. for each vars
local ses se_mmacc se_prim se_high se_col se_inc

foreach v in `ses' {
	twoway (line `v' N), ///
	ytitle("`v'") xtitle("Sample size") ///
	name(`v', replace) title("`v'")
} 

graph combine se_mmacc se_prim se_high se_col se_inc, title("S.E. for Different Samples by Each Vars")subtitle("Fixed 10k Population, 500 Simulation")

graph export  "$wd/output/stata3_q1_line.png", replace

* pvalue for each vars
local pvs pv_mmacc pv_prim pv_high pv_col pv_inc

foreach v in `pvs' {
	twoway line `v' N if N <=1000, ///
	ytitle("`v'") xtitle("Sample size") ///
	name(`v', replace) title("`v'")
} 

graph combine pv_mmacc pv_prim pv_high pv_col pv_inc, title("P-value for Different Samples by Each Vars")subtitle("Fixed 10k Population, 500 Simulation")

graph export  "$wd/output/stata3_q1_pvline.png", replace

* Table  
preserve //presearve what I have before collapsing 

collapse (mean) betabar1 = beta1 (mean) betabar2 = beta2 (mean) betabar3 = beta3 ///
		 (mean) betabar4 = beta4 (mean) betabar5 = beta5 ///
		 (mean) mse1 = se_mmacc (mean) mse2 = se_prim (mean) mse3 = se_high ///
		 (mean) mse4 = se_col (mean) mse5 = se_inc ///
		 (mean) cibar1 = ciw_mmacc (mean) cibar2 = ciw_prim (mean) cibar3 = ciw_high ///
		 (mean) cibar4 = ciw_col (mean) cibar5 = ciw_inc ///
		 , by(samp_group)

collect clear

table (var) (samp_group), stat(mean betabar* mse* cibar*) nformat(%9.3f)

collect title "Estimated Betas, MSEs, and CIs for Each Vars (Fixed 10k Population, 500 Simulation)"

collect export stata3_q1_table.pdf, as(pdf) replace

restore //restore what I preserved 

*** prep for step 2
keep N beta1 se_mmacc pv_mmacc ciw_mmacc samp
collapse (mean) beta_10k =beta1 (mean)  se_10k= se_mm (mean)  ciw_10k =ciw , by(N)

save "$wd/output/stata3_p1_forcomp.dta", replace


