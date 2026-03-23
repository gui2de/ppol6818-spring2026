*** PART ONE ***
clear
cd "C:\ExpDesign\StataAssignment3"

**q1 and q2**

set seed 47001
set obs 10000

gen x = runiform(0,100)
gen e = rnormal(-100,100)
gen y = 27 + 93*x + e 

save part1q2, replace

**q3**
capture program drop q3regression
program define q3regression, rclass
	syntax, sample(integer)
	
	*load data
	use part1q2.dta, clear
	*random subset sample
	gen samplen = runiform()
	sort samplen
	keep if _n <= `sample'
	*perform regression
	reg y x
	*return required materials
	return scalar N = e(N)
	return scalar beta = _b[x]
	return scalar sem = _se[x]
	return scalar pval = (2 * ttail(e(df_r), abs(_b[x]/_se[x])))
    return scalar ci_low = _b[x] - invt(e(df_r), 0.975)*_se[x]
    return scalar ci_high = _b[x] + invt(e(df_r), 0.975)*_se[x]
end

**q4**
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_low=r(ci_low) ci_high=r(ci_high), reps(500) saving(sim10, replace): q3regression, sample(10)

simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_low=r(ci_low) ci_high=r(ci_high), reps(500) saving(sim100, replace): q3regression, sample(100)

simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_low=r(ci_low) ci_high=r(ci_high), reps(500) saving(sim1000, replace): q3regression, sample(1000)

simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_low=r(ci_low) ci_high=r(ci_high), reps(500) saving(sim10000, replace): q3regression, sample(10000)

use sim10, clear
append using sim100
append using sim1000
append using sim10000

save total_simulations, replace

**q5**
graph box beta, over(N) ytitle("Beta") title("Variation in Beta as Sample Size Increases")

table N, statistic(mean sem) statistic(mean ci_low) statistic(mean ci_high)



*** PART TWO ***
clear

**q1**
capture program drop part2program
program define part2program, rclass
	syntax, sample(integer)
	
	clear
	set obs `sample'
	
	gen x = runiform(0,100)
	gen e = rnormal(-100,100)
	gen y = 27 + 93*x + e 

	reg y x

	return scalar N = e(N)
	return scalar beta = _b[x]
	return scalar sem = _se[x]
	return scalar pval = (2 * ttail(e(df_r), abs(_b[x]/_se[x])))
    return scalar ci_low = _b[x] - invt(e(df_r), 0.975)*_se[x]
    return scalar ci_high = _b[x] + invt(e(df_r), 0.975)*_se[x]
end

**q2**
local pow2
forvalues i = 2/21 {
    local pow2 `pow2' `=2^`i''
}


foreach n of local pow2 {

    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_low=r(ci_low) ci_high=r(ci_high), reps(500) saving(sim2_`n', replace): part2program, sample(`n')
}


local tens 10 100 1000 10000 100000 1000000

foreach n of local tens {

    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_low=r(ci_low) ci_high=r(ci_high), reps(500) saving(sim10_`n', replace): part2program, sample(`n')
}


clear
local first = 1

foreach n of local pow2 {
    if `first' {
        use sim2_`n', clear
        local first = 0
    }
    else {
        append using sim2_`n'
    }
}

foreach n of local tens {
    append using sim10_`n'
}

save total_simulations_part2, replace

**q3**
graph box beta, over(N) ytitle("Beta") title("Variation in Beta as Sample Size Increases Part 2")

table N, statistic(mean sem) statistic(mean ci_low) statistic(mean ci_high)



*** PART THREE ***
clear

**q1**
set obs 15000

gen y = rnormal(0,1)

**q2**
gen treatment_effect = runiform(0, 0.2)
sum treatment_effect

**q3**
gen treat_assign = 0
replace treat_assign = 1 if _n <= _N/2

gen y_treated = y + treatment_effect*treat_assign


*calculate sample size required for 80% power

power twomeans 0 0.1, sd(1) power(0.8)
return list
*gives r(N) equal to 3142

*check using simulation
capture program drop power80
program define power80, rclass
	syntax, sample(integer)
	
	clear
	set obs `sample'
	
	gen y = rnormal(0,1)
	gen treatment_effect = runiform(0, 0.2)
	gen treat_assign = 0
	replace treat_assign = 1 if _n <= _N/2
	gen y_treated = y + treatment_effect*treat_assign
	
	reg y_treated treat_assign
	
	return scalar sig = (abs(_b[treat_assign]/_se[treat_assign]) > invnormal(0.975))
end

simulate sig= r(sig), reps(500): power80, sample(3142)
sum sig
*mean sig is just over .8

**q4**

display 3142/0.85
* ~= 3697

capture program drop power80
program define power80, rclass
	syntax, sample(integer)
	
	clear
	set obs `sample'
	
	gen y = rnormal(0,1)
	gen treatment_effect = runiform(0, 0.2)
	gen treat_assign = 0
	replace treat_assign = 1 if _n <= _N/2
	gen y_treated = y + treatment_effect*treat_assign
	
	gen keep = (runiform() > 0.15)
	keep if keep == 1
	
	reg y_treated treat_assign
	
	return scalar sig = (abs(_b[treat_assign]/_se[treat_assign]) > invnormal(0.975))
end

simulate sig= r(sig), reps(500): power80, sample(3697)
sum sig

*the sample size has to increase to accomodate those who will attrite from the study in order for 80% power to remain. In this case, there is an increase from 3142 to 3697

**q5**
power twomeans 0 0.1, sd(1) power(0.8) nratio(0.3/0.7)
return list
display r(N1) + r(N2)
*4424

capture program drop power80
program define power80, rclass
	syntax, sample(integer)
	
	clear
	set obs `sample'
	
	gen y = rnormal(0,1)
	gen treatment_effect = runiform(0, 0.2)
	gen treat_assign = 0
	replace treat_assign = (runiform() < 0.3)
	gen y_treated = y + treatment_effect*treat_assign
	
	gen keep = (runiform() > 0.15)
	keep if keep == 1
	
	reg y_treated treat_assign
	
	return scalar sig = (abs(_b[treat_assign]/_se[treat_assign]) > invnormal(0.975))
end

simulate sig= r(sig), reps(500): power80, sample(4424)
sum sig



*** PART FOUR ***
clear

**q1-q4
capture program drop cluster_sim
program define cluster_sim, rclass
    syntax , clusters(integer) size(integer) compliance(real)

    clear
    set obs `=`clusters'*`size''

    gen school = ceil(_n / `size')

    gen u = .
    bysort school: replace u = rnormal(0, sqrt(0.3)) if _n==1
    bysort school: replace u = u[1]

    gen e = rnormal(0, sqrt(0.7))
    gen y = u + e

    gen treat_assign = 0
    replace treat_assign = 1 if school <= `clusters'/2

    gen treatment_effect = .
    bysort school: replace treatment_effect = runiform(0.15,0.25) if _n==1
    bysort school: replace treatment_effect = treatment_effect[1]

    * compliance (for q7)
    gen adopt = (runiform() < `compliance')

    gen y_treated = y + treat_assign*adopt*treatment_effect

    reg y_treated treat_assign, cluster(school)

    return scalar sig = (2 * ttail(e(df_r), abs(_b[treat_assign]/_se[treat_assign])) < 0.05)
    return scalar beta = _b[treat_assign]
end

simulate sig=r(sig) beta=r(beta), reps(500): cluster_sim, clusters(200) size(20) compliance(1)

**q5**

local sizes
forvalues i = 1/10 {
    local sizes `sizes' `=2^`i''
}


foreach s of local sizes {

    simulate sig=r(sig), reps(500): cluster_sim, clusters(200) size(`s') compliance(1)

    gen size = `s'
    save sim_size_`s', replace
}

local first = 1

foreach s of local sizes {
    if `first' {
        use sim_size_`s', clear
        local first = 0
    }
    else {
        append using sim_size_`s'
    }
}

save power_size, replace

bysort size: tab sig
*generally speaking, the power goes up as size increases. In my simulation, power maxed out at a size of 64, and then fluctuates a little above 70% as it increases, so I would recommend a size of 64.

**q6**


forvalues c = 50(25)350 {

    simulate sig=r(sig), reps(500): cluster_sim, clusters(`c') size(15) compliance(1)

    summarize sig
    display "Clusters = `c'  Power = " r(mean)
}
*We need 275 clusters to get a power of 80%

**q7**
forvalues c = 50(25)700 {

    simulate sig=r(sig), reps(500): cluster_sim, clusters(`c') size(15) compliance(0.7)

    summarize sig
    display "Clusters = `c'  Power = " r(mean)
}
*We need 550 clusters to get a power of 80% in this case
