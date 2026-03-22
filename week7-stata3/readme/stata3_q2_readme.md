# Part 2: Sampling noise in an infinite superpopulation

## DGP & Program
Same setup as [Part.1](week7-stata3/readme/stata3_q1_readme.md), where the true DGP is:

$$
cons_i = \beta_0 + \beta_1 mmacc_i + \beta_2 prim_i + \beta_3 high_i + \beta_4 col_i + \beta_5 inc_i + \epsilon_i
$$

However, in this simulation, I assumed an **Infinite Superpopulation**, instead of fixed 10,000 households. For the simplicity, the program below is only designed to capture the statistics of $mmacc_i$.

**Codes:**
```stata
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
```
## Simulation
The simulation here reflects the cases where the sample size is power of 2 or power of 10; there are 26 cases. I repeat each simulation for 500 times. 

```stata
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
```

## Outputs & Interpretation
### *FIGURE. 1* Boxplot for estimated $\beta$ for each sample size, N
The boxplot below shows the distrubition of estimated $\beta_1$ with different N. 

**Interpretation:**
- 

**Codes:**
```stata
graph box beta, over(N,  label(angle(45))) ///
	title("Sampling Distributions of {&beta} Estimate by Sample Size (True {&beta} = 20)") /// 
	subtitle("Superpopulation, 500 Simulation") ///
	ytitle("OLS Estimate of {&beta}{subscript:1}") ///
	yline(20, lcolor(stred) lpattern(dash) lwidth(thin)) ///
	text(20 0 "20", placement(left))


graph export  "$boxd/output/stata3_q2_boxplot.png", replace
```

### *TABLE. 1* $\beta$, Standard Error, and CI width for each sample size from superpopulation
The table below consists each **Estimated $\beta$**, **Standard Error**, and **CI width** for 26 sample sizes.

**Interpretation:**
- Estimated $\beta$ becomes closer to the true $\beta$s, as N becomes bigger.
- Standard errors and CI widths get smaller, as N becomes bigger.
- Both observations make sense because by having larger  N, we can remove the noises. 

<img width="2000" height="2588" alt="image" src="https://github.com/user-attachments/assets/413b35dc-9865-46f3-a0a5-32ad548b3a87" />

**Codes:**
```stata
collapse (mean) betabar = beta (mean) sebar = se (mean) ci_*, by(N)
gen ciw = ci_hi - ci_lo

table N, stat(mean betabar) stat(mean sebar) stat(mean ciw) export(stata3_q2_table, as(pdf) replace) title("Betas, MSEs, CIs (Superpopulation, 500 Simulation)") // estimated betas for each sample size 
```



## Part1 vs Part2
### *FIGURE. 2* Comparison of Estimated $\beta$, Standard Error, and CI width between Part1 and Part2
The graphs below show Estimated $\beta$, Standard Error, and CI width for both Part1 and Part2. 

**Interpretation:**
- Since Part1 only has 4 sample sizes, the line only goes the range of the samples.
- It looks like Part2 has more noises in all the statistics because Part2 has an infinite superpopulation, but the overall trends are the same as Part1; the bigger the sample size is, the less noises there are. 

![linecomp.png](https://github.com/gui2de/ppol6818-spring2026/blob/kk1534_stata3/week7-stata3/output/stata3_q2_linecomp.png?raw=true)

**Codes:**
```stata
collapse (mean)  beta (mean)  se (mean) ci_*		 , by(N)
gen ciw = ci_hi - ci_lo

merge m:1 N using "$boxd/output/stata3_p1_forcomp.dta", force //merge part1 to part2

* Overall
twoway  (line beta N, lpattern(dot))(line beta_10k N if _merge == 3), legend(order(1 "Superpop" 2 "Fixed Pop")) xtitle("Sample size") ytitle("Estimated {&beta}") name(beta, replace) title("{&beta} Comparison") xlabel(, angle(45))

twoway  (line se N, lpattern(dot))(line se_10k N if _merge == 3), legend(order(1 "Superpop"2 "Fixed Pop")) xtitle("Sample size") ytitle("Standard Error") name(se, replace) title("SEM Comparison") xlabel(, angle(45))

twoway  (line ciw N, lpattern(dot))(line ciw_10k N if _merge == 3), legend(order(1 "Superpop"2 "Fixed Pop")) xtitle("Sample size") ytitle("CI width") name(ciw, replace) title("CI Comparison") xlabel(, angle(45))

graph combine beta se ciw, title("Comparisons for {&beta}, SEM, and CI" "between Superpopulation and Fixed Population" )

graph export "$boxd/output/stata3_q2_linecomp.png", replace
```


### *FIGURE. 3* Comparison of Estimated $\beta$, Standard Error, and CI width between Part1 and Part2 only for sample size of 10, 100, 1000, and 10000
The graphs below consists of the same contents as *FIGURE. 2*, including Estimated $\beta$, Standard Error, and CI width for both Part1 and Part2. But, the sample sizes are limited to 4 samples that both Part1 and Part2 have. (N = 10, 100, 1000, 10000) 

**Interpretation:**
- As observed in *FIGURE. 2*, the standard error and CI width vary more in Part2. This is because the Part2 samples are obtained from infinite population, which give them much more noises. Both statistics get closer to zero as the sample size gets bigger.
- Estimated $\beta$ also converges toward the true $\beta$ of 20, as the sample size gets bigger, while Part2 $\beta$ is showing a volatility up to the sample size of 1000. 

![linecomp2.png](https://github.com/gui2de/ppol6818-spring2026/blob/kk1534_stata3/week7-stata3/output/stata3_q2_linecomp1010000.png?raw=true)

**Codes:**
```stata
keep if _merge == 3 // to compare N = 10 100 1000 10000
drop ci_*

order N beta_10k beta se_10k se ciw_10k ciw

twoway  (line beta N, lcolor(blue))(scatter beta N, mcolor(blue))(line beta_10k N if _merge == 3, lcolor(red))(scatter beta_ N, mcolor(red)), legend(order(1 "Superpop"3 "Fixed Pop")) xtitle("Sample size") ytitle("Estimated {&beta}") name(beta, replace) title("{&beta} Comparison") xlabel(, angle(45)) xline(10 100 1000 10000, lcolor(grey) lpattern(dot))

twoway  (line se N, lcolor(blue))(scatter se N, mcolor(blue))(line se_10k N if _merge == 3, lcolor(red))(scatter se_ N, mcolor(red)), legend(order(1 "Superpop"2 "Fixed Pop")) xtitle("Sample size") ytitle("Standard Error") name(se, replace) title("S.E. Comparison") xlabel(, angle(45))xline(10 100 1000 10000, lcolor(grey) lpattern(dot))

twoway  (line ciw N, lcolor(blue))(scatter ciw N, mcolor(blue))(line ciw_10k N if _merge == 3, lcolor(red))(scatter ciw_ N, mcolor(red)), legend(order(1 "Superpop"2 "Fixed Pop")) xtitle("Sample size") ytitle("CI width") name(ciw, replace) title("CI Comparison") xlabel(, angle(45))xline(10 100 1000 10000, lcolor(grey) lpattern(dot))

graph combine beta se ciw, title("Comparisons for {&beta}, SEM, and CI" "between Superpopulation and Fixed Population""N = 10 100 1000 10000" )

graph export "$boxd/output/stata3_q2_linecomp1010000.png", replace
```
### *TABLE. 2* $\beta$, Standard Error, and CI width for sample size of 10, 100, 1000, 10000 from both fixed population and superpopulation



<img width="2000" height="2588" alt="image" src="https://github.com/user-attachments/assets/5b6b4f7e-df2c-4559-bc8b-6836eca84662" />

**Codes:**
```stata
label var    beta_  "beta Fixed Pop" 
label var     beta   "beta Superpop" 
label var     se_    "SE Fixed Pop"      
label var     se     "SE Superpop"      
label var     ciw_   "CI Fixed Pop"      
label var     ciw    "CI Superpop"
label var N "N"

table N, stat(mean beta_) stat(mean beta) stat(mean se_)   stat(mean se) stat(mean ciw_)  stat(mean ciw) export(q2_table.pdf, as(pdf) replace)
```
