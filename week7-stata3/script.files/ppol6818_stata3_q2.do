/*==========================================================

	Author: Kenshi Kawade
	Title: stata3 assignement 
	Part: 2 out of 4

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


do "$wd/01_script/ppol6818_stata3_q1.do" // do the part1


cd "$boxd"


clear
set seed 681803

/*==========================================================
1. DEFINE THE PROGRAM
==========================================================*/

capture program drop q2_reg
program define q2_reg, rclass

    syntax, n(integer)   

    * randomly generate a fresh dataset of size N following the same DGP as Part 1
    clear
    set obs `n'

    * mobile money access 
    gen mmpc  = runiform()
    gen mmacc = (mmpc < 0.5)

    * education dummies 
    gen educlev = runiform()
    gen prim    = (educlev >  .1 & educlev <= .4)
    gen high    = (educlev >  .4 & educlev <= .7)
    gen college = (educlev >  .7 & educlev <= 1 )

    * income 
    gen income = runiform() * 1000

    * Error ~ N(0,1)
    gen e = rnormal(0, 1)

    * consumption
    gen cons = 100 + 20*mmacc + 7*prim + 10*high + 5*college + .15*income + e

    * regress on one X, mobile money access
    qui reg cons mmacc

    * return the stats
    matrix output = r(table)

    return scalar num_hh   = e(N)
    return scalar b_mmacc  = _b[mmacc]
    return scalar se_mmacc = _se[mmacc]
    return scalar pv_mmacc = output[4, colnumb(output, "mmacc")]
    return scalar lb_mmacc = output[5, colnumb(output, "mmacc")]
    return scalar ub_mmacc = output[6, colnumb(output, "mmacc")]

end

/*==========================================================
2. Simulation
==========================================================*/

local samp  "2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 10 100 1000 10000 100000 1000000"

tempfile simulated
local first = 1

foreach v of local samp {
	simulate N        = r(num_hh) ///
        beta     = r(b_mmacc)   ///
        se       = r(se_mmacc) ///
        pval     = r(pv_mmacc) ///
        ci_lo    = r(lb_mmacc)  ///
        ci_hi    = r(ub_mmacc), ///
        reps(500) : q2_reg, n(`v')
		
		if `first'{
			save `simulated', replace  
			local first = 0
		}
		else {
			append using `simulated'  
			save `simulated', replace 
		}
}

save "$boxd/output/stata3_q2_simulated.dta", replace

/*==========================================================
3. Data viz
==========================================================*/
use "$boxd/output/stata3_q2_simulated.dta", clear

*boxplot
graph box beta, over(N,  label(angle(45))) ///
	title("Sampling Distributions of {&beta} Estimate by Sample Size (True {&beta} = 20)") /// 
	subtitle("Superpopulation, 500 Simulation") ///
	ytitle("OLS Estimate of {&beta}{subscript:1}") ///
	yline(20, lcolor(stred) lpattern(dash) lwidth(thin)) ///
	text(20 0 "20", placement(left))


graph export  "$boxd/output/stata3_q2_boxplot.png", replace
	
*table
preserve //presearve what I have before collapsing 

collapse (mean) betabar = beta (mean) sebar = se (mean) ci_*, by(N)
gen ciw = ci_hi - ci_lo

table N, stat(mean betabar) stat(mean sebar) stat(mean ciw) export(stata3_q2_table, as(pdf) replace) title("Betas, MSEs, CIs (Superpopulation, 500 Simulation)") // estimated betas for each sample size 

restore //restore what I preserved 

/*==========================================================
5. Comparison
==========================================================*/
collapse (mean)  beta (mean)  se (mean) ci_*		 , by(N)
gen ciw = ci_hi - ci_lo

merge m:1 N using "$boxd/output/stata3_p1_forcomp.dta", force //merge part1 to part2

* Overall
twoway  (line beta N, lpattern(dot))(line beta_10k N if _merge == 3), legend(order(1 "Superpop" 2 "Fixed Pop")) xtitle("Sample size") ytitle("Estimated {&beta}") name(beta, replace) title("{&beta} Comparison") xlabel(, angle(45))

twoway  (line se N, lpattern(dot))(line se_10k N if _merge == 3), legend(order(1 "Superpop"2 "Fixed Pop")) xtitle("Sample size") ytitle("Standard Error") name(se, replace) title("SEM Comparison") xlabel(, angle(45))

twoway  (line ciw N, lpattern(dot))(line ciw_10k N if _merge == 3), legend(order(1 "Superpop"2 "Fixed Pop")) xtitle("Sample size") ytitle("CI width") name(ciw, replace) title("CI Comparison") xlabel(, angle(45))

graph combine beta se ciw, title("Comparisons for {&beta}, SEM, and CI" "between Superpopulation and Fixed Population" )

graph export "$boxd/output/stata3_q2_linecomp.png", replace

* N = 10 100 1000 10000
keep if _merge == 3 // to compare N = 10 100 1000 10000
drop ci_*

order N beta_10k beta se_10k se ciw_10k ciw

twoway  (line beta N, lcolor(blue))(scatter beta N, mcolor(blue))(line beta_10k N if _merge == 3, lcolor(red))(scatter beta_ N, mcolor(red)), legend(order(1 "Superpop"3 "Fixed Pop")) xtitle("Sample size") ytitle("Estimated {&beta}") name(beta, replace) title("{&beta} Comparison") xlabel(, angle(45)) xline(10 100 1000 10000, lcolor(grey) lpattern(dot))

twoway  (line se N, lcolor(blue))(scatter se N, mcolor(blue))(line se_10k N if _merge == 3, lcolor(red))(scatter se_ N, mcolor(red)), legend(order(1 "Superpop"2 "Fixed Pop")) xtitle("Sample size") ytitle("Standard Error") name(se, replace) title("S.E. Comparison") xlabel(, angle(45))xline(10 100 1000 10000, lcolor(grey) lpattern(dot))

twoway  (line ciw N, lcolor(blue))(scatter ciw N, mcolor(blue))(line ciw_10k N if _merge == 3, lcolor(red))(scatter ciw_ N, mcolor(red)), legend(order(1 "Superpop"2 "Fixed Pop")) xtitle("Sample size") ytitle("CI width") name(ciw, replace) title("CI Comparison") xlabel(, angle(45))xline(10 100 1000 10000, lcolor(grey) lpattern(dot))

graph combine beta se ciw, title("Comparisons for {&beta}, SEM, and CI" "between Superpopulation and Fixed Population""N = 10 100 1000 10000" )

graph export "$boxd/output/stata3_q2_linecomp1010000.png", replace

** table

label var    beta_  "beta Fixed Pop" 
label var     beta   "beta Superpop" 
label var     se_    "SE Fixed Pop"      
label var     se     "SE Superpop"      
label var     ciw_   "CI Fixed Pop"      
label var     ciw    "CI Superpop"
label var N "N"

table N, stat(mean beta_) stat(mean beta) stat(mean se_)   stat(mean se) stat(mean ciw_)  stat(mean ciw) export(q2_table.pdf, as(pdf) replace)

** Distribution of beta for each N
use "$boxd/output/stata3_q1_simulated.dta", clear

keep N beta1
rename beta1 beta_10k

merge m:m N using "$boxd/output/stata3_q2_simulated.dta", force


preserve
keep if _merge == 3

twoway ///
    (kdensity beta if N==10, lcolor(red))  ///
	(kdensity beta_ if N==10, lcolor(blue)),  ///
	legend(order(1 "Superpop" 2 "Fixed Pop")) ///
	title("N = 10") ///
	xtitle("Estimated {&beta}") ytitle("Density") ///
	xline(20, lcolor(black) lpattern(dot)) ///
	xlabel(20, add) ///
	name(N_10, replace)
	
twoway ///
    (kdensity beta if N==100, lcolor(red))  ///
	(kdensity beta_10k if N==100, lcolor(blue)),  ///
	legend(order(1 "Superpop" 2 "Fixed Pop")) ///
	title("N = 100") ///
	xtitle("Estimated {&beta}") ytitle("Density") ///
	xline(20, lcolor(black) lpattern(dot)) ///
	xlabel(20, add) ///
	name(N_100, replace)
	
twoway ///
    (kdensity beta if N==1000, lcolor(red))  ///
	(kdensity beta_10k if N==1000, lcolor(blue)),  ///
	legend(order(1 "Superpop" 2 "Fixed Pop")) ///
	title("N = 1000") ///
	xtitle("Estimated {&beta}") ytitle("Density") ///
	xline(20, lcolor(black) lpattern(dot)) ///
	xlabel(20, add) ///
	name(N_1000, replace)

tab beta_10k if N == 10000 // there is only one unique value for estimated beta when N = 10,000, which is 20.00955.

twoway ///
    (kdensity beta if N==10000, lcolor(red)),  ///
	legend(order(1 "Superpop" 2 "Fixed Pop")) ///
	title("N = 10000") ///
	xtitle("Estimated {&beta}") ytitle("Density") ///
	xline(20, lcolor(black) lpattern(dot)) ///
	xline(20.00955, lcolor(blue) lpattern(solid)) ///
	xlabel(20, add) ///
	name(N_10000, replace)

graph combine N_10 N_100 N_1000 N_10000, ///
	 title("Comparisons of {&beta} distribution between Superpopulation and Fixed Population""N = 10 100 1000 10000")

graph export "$boxd/output/stata3_q2_betadis.png", replace

restore

* beta with CIs
twoway lpolyci beta N , title("Superpopulation") xscale(log) ///
	xtitle("Sample size") ytitle("Estimated {&beta}") xlabel(, angle(90))  legend(label(2 "estimated beta")) ///
	name(super, replace)
	
twoway lpolyci beta_ N, title("Fixed population") xscale(log) ///
	xtitle("Sample size") ytitle("Estimated {&beta}") xlabel(, angle(90)) legend(label(2 "estimated beta")) ///
	name(fixed, replace)
	
graph combine super fixed, title("Estimated {&beta} with 95% CI")
graph export "$boxd/output/stata3_q2_betaci.png", replace
	
 