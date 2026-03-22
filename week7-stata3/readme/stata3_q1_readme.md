# Part 1: Sampling noise in a fixed population

## 1. Data Generating Process (DGP)
In this activity, the outcome of interest is monthly household consumption expenditure USD, $cons_i$. The true DGP is:

$$
cons_i = \beta_0 + \beta_1 mmacc_i + \beta_2 prim_i + \beta_3 high_i + \beta_4 col_i + \beta_5 inc_i + \epsilon_i
$$

where the true parameter values are 
$\beta_0$ = 100, $\beta_1$ = 20, $\beta_2$ = 7, $\beta_3$ = 10, $\beta_4$ = 5, $\beta_5$ = 0.15, and $\varepsilon_i \sim \mathcal{N}(0, 1)$.

The regressors are drawn as follows:

- $mmacc_i$ :                   **Mobile money access** indicator, equal to 1 if household $i$ holds an active mobile money account
- $prim_i$, $high_i$, $col_i$ : **Education** dummies to indicate the highest education level of household $i$, constructed from a `runiform(0 1)`, yielding approximately 30% shares each, with the remaiing 10% having zero year of education. 
- $inc_i$ :                     **Monthly income** variable (USD), calculated by `runiform(0 1)*1000`.
- $\varepsilon_i \sim \mathcal{N}(0, 1)$ :                **Error term** 

I generated a **fixed population** of $10,000$ households with a fixed seed for reproducibility. 

**Codes:**
```stata
clear

set seed 68183 //set seed for reproducibility 

local totaln = 10000 //set individual obs
set obs `totaln'

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

* consumption
gen cons = 100 + 20*mmacc + 7*prim + 10*high + 5*college + .15*income + e
label variable cons "Monthly HH consumption (USD)"

* save box folder
save "$boxd/output/stata3_q1_pop.dta", replace
```

## 2. Define a program & Simulation
A program below is designed to capture **Estimated $\beta$**, **Standard Error**, **P-value**, and **Lower/higher boundary of Confidence Interval(95% level)** for arbitrary sample size. 

**Codes:**
```stata

capture program drop q1_reg 
program define q1_reg, rclass

	syntax, sample(integer) // set a syntax of the program

	use "$boxd/output/stata3_q1_pop.dta", clear
	
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
```
In this simulation, I simulated **500** times for each cases where N is **10, 100, 1000, and 10000** out of 10000 households. 

**Codes:**
```stata
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

save "$boxd/output/stata3_q1_simulated.dta", replace
```

## 3. Outputs & Interpretation
### *FIGURE. 1* Boxplot for estimated $\beta$'s for each sample size, N
The boxplot below shows the distrubition of estimated $\beta$'s for each variables with different N. 

**Interpretation:**
- The distribution is the widest with N of 10, which makes sense as there would be more noises.
- As N becomes larger, the noise gets smaller, and eventually the estimated $\beta$ becomes equal to the true $\beta$ with N of 10,000, which also makes sense as the independent value, *consumption*, was calculated using the same 10,000 households variables.

![stata3_q1_boxplot.png](https://github.com/gui2de/ppol6818-spring2026/blob/kk1534_stata3/week7-stata3/output/stata3_q1_boxplot.png?raw=true)

**Codes:**
```stata
use "$boxd/output/stata3_q1_simulated.dta", clear

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

graph export "$boxd/output/stata3_q1_boxplot.png", replace
```
### *FIGURE. 2* Each Standard Errors for different sample size, N
The graphs below depict how standard errors of each coefficient changes, based on N.

**Interpretation:**
- Each standard errors is also larger with smaller N, which aligns with what I found in OLS estimates distribution.
- As N gets larger, the standard errors gets smaller because there would be less noises.

![stata3q1_line.png](https://github.com/gui2de/ppol6818-spring2026/blob/kk1534_stata3/week7-stata3/output/stata3_q1_line.png?raw=true)

**Codes:**
```stata
local ses se_mmacc se_prim se_high se_col se_inc

foreach v in `ses' {
	twoway (line `v' N), ///
	ytitle("`v'") xtitle("Sample size") ///
	name(`v', replace) title("`v'")
} 

graph combine se_mmacc se_prim se_high se_col se_inc, title("S.E. for Different Samples by Each Vars")subtitle("Fixed 10k Population, 500 Simulation")

graph export  "$boxd/output/stata3_q1_line.png", replace
```

### *FIGURE. 3* Each P-values for different sample size, N
The graphs below depict how p-values of each coefficient changes, based on N.

**Interpretation:**
- As N gets larger, the p-values get smaller for the same reasons above.

![pvline.png](https://github.com/gui2de/ppol6818-spring2026/blob/kk1534_stata3/week7-stata3/output/stata3_q1_pvline.png?raw=true)

**Codes:**
```stata
local pvs pv_mmacc pv_prim pv_high pv_col pv_inc

foreach v in `pvs' {
	twoway line `v' N if N <=1000, ///
	ytitle("`v'") xtitle("Sample size") ///
	name(`v', replace) title("`v'")
} 

graph combine pv_mmacc pv_prim pv_high pv_col pv_inc, title("P-value for Different Samples by Each Vars")subtitle("Fixed 10k Population, 500 Simulation")

graph export  "$boxd/output/stata3_q1_pvline.png", replace
```

### *TABLE. 1*
The table below consists each **Estimated $\beta$**, **Standard Error**, and **CI width**.

**Interpretation:**
- Estimated $\beta$'s become closer to the true $\beta$s, as N becomes bigger.
- Standard errors and CI widths get smaller, as N becomes bigger.
- Both observations make sense because by having larger  N, we can remove the noises. 

<img width="2000" height="2588" alt="image" src="https://github.com/user-attachments/assets/48f419d6-cdcf-44d3-bbb4-3925ab95717f" />

**Codes:**
```stata
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
```

