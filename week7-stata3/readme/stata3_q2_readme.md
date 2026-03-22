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

### *TABLE. 1*
The table below consists each **Estimated $\beta$**, **Standard Error**, and **CI width** for 25 sample sizes.

**Interpretation:**
- Estimated $\beta$ becomes closer to the true $\beta$s, as N becomes bigger.
- Standard errors and CI widths get smaller, as N becomes bigger.
- Both observations make sense because by having larger  N, we can remove the noises. 

<img width="2000" height="2588" alt="image" src="https://github.com/user-attachments/assets/413b35dc-9865-46f3-a0a5-32ad548b3a87" />

## Part1 vs Part2
### *FIGURE. 1* 

**Interpretation:**

![linecomp.png](https://github.com/gui2de/ppol6818-spring2026/blob/kk1534_stata3/week7-stata3/output/stata3_q2_linecomp.png?raw=true)

### *FIGURE. 2* 

**Interpretation:**

![linecomp2.png](https://github.com/gui2de/ppol6818-spring2026/blob/kk1534_stata3/week7-stata3/output/stata3_q2_linecomp1010000.png?raw=true)


