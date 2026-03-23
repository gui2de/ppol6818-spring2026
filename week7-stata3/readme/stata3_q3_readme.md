# Part 3: Power calculations for individual-level randomization
## 1. DGP
I set my DGP as followed:

- unit: hhid <br>
- X (treatment) :   mobile money access(mmacc)<br>
- Y (output of interest) :    consumption ~ Normal(0, 1) <br>
- ATE: 0.1<br>
- Individual effect: Treatment effect at hh level are different ~ Uniform(0, 0.2)<br>

In this exercise, the baseline consumption is normally distributed, and the treatment outcome is calculated by:

$$
cons1_i = cons0_i + effect_i * mmacc_i 
$$

Where:

- $cons1_i$ : Consumption of treated group
- $cons0_i$ : Baseline consumption ~ Normal(0, 1)
- $effect_i$ : Individual treatment effect ~ Uniform(0, 0.2)
- $mmacc_i$ : Treatement dummy, equal to 1 if the hh is treated and given a mobile money access

## 2. Baseline 
### Program
The program is designed as below. I am using 95% confidence level to reject the null ($\beta_{effect}$ = 0).
```stata
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
```

### Power calculation 
The power calucation is done as below. The minimum sample size to have at least 80% power is **3142**.
```stata
power twomeans 0 0.1, sd(1)  power(0.8) alpha(0.05) nratio(1)
/*
Estimated sample sizes:

            N =     3,142
  N per group =     1,571
*/
```

### Simulation with the defined program
Simulation using the defined program above is done as below. The reps is 500 times. The expected minimum sample size to have a power of higher than 80% is calculated to be **3101**.

```stata
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
*/
```

### Notes
- 3,101 (by simulation) and 3,142 (power calc) are not contradicting each other. The power twomeans answer is the precise theoretical value without randomness. The simulation answer is a noisy estimate of that same value, and with 500 reps the noise is large enough to shift the answer by ~40 households.


## Case of attrition 
In this section, we think about the case where the attrition rate is 15% instead of 0%. 
### Program
The program is designed as below. I am using 95% confidence level to reject the null ($\beta_{effect}$ = 0).
```stata
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
```

### Power calculation
The power calucation is done as below. The minimum sample size to have at least 80% power with attrition rate of 15% is **3697**.
```stata
display ceil(3142 / 0.85)
```

### Simulation with the defined program
Simulation using the defined program above is done below. The reps is 500 times. The expected minimum sample size to have a power of higher than 80% with attrition rate of 15% is calculated to be between **3800 and 3900**.

```stata
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
*/
```

### Notes
- The power (simulated) gets higher than 80% between 3800 and 3900. This is not contradicting the power twomean answer of 3697 because there is more noise with this simulation.

## Case of fewer treatement
In this section, we think about the case where the attrition rate is 15% instead of 0%, as well as the proportion of treatment group is 30% out of total sample size. 
### Power calculation
The power calucation is done below. The minimum sample size to have at least 80% power with attrition rate of 15% and treatement rate of 30% is **4400**.
```stata
local ratio = .3/.7
power twomeans 0 0.1, sd(1)  power(0.8) alpha(0.05) nratio(`ratio')

display ceil(3740 / 0.85)
*4400
```

### Simulation 
Simulation using the defined program above is done below. The reps is 500 times. The expected minimum sample size to have a power of higher than 80% with attrition rate of 15% and treatement rate of 30% is calculated to be between **4400 and 4500**.
```stata
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
```

## Conclusion
Below is a table for the minimum sample sizes to have at least a power of 80% in each case. As it mentioned above, the `power twomeans` answers seem to be more precise as they don't have randomness which the other method has.  

| Method | Case 1 (Baseline) | Case 2 (Attrition = 15%) | Case 3 (Attrition = 15% & Treatment = 30%) |
| :--- | :---: | :---: | :---: |
| `power twomeans` | 3142 | 3697 | 4400 |
| `simulate powerfunction, reps(500)` | 3101 | 3800–3900 | 4400–4500 |


