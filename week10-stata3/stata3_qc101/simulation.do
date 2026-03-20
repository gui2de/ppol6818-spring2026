// Stata3_QingyueChen
// program define
clear all
set more off

global BOXPATH "C:\Users\86186\Box\stata3"

capture program drop sim_reg
program define sim_reg, rclass
    syntax, N(integer)

    use "$BOXPATH\fixed_population.dta", clear
    sample `n', count

    regress y x

    return scalar N      = e(N)
    return scalar beta   = _b[x]
    return scalar sem    = _se[x]
    return scalar pval   = 2 * ttail(e(df_r), abs(_b[x] / _se[x]))
    return scalar ci_lo  = _b[x] - invttail(e(df_r), 0.025) * _se[x]
    return scalar ci_hi  = _b[x] + invttail(e(df_r), 0.025) * _se[x]
    return scalar width  = return(ci_hi) - return(ci_lo)
end

// simulation
tempfile sim10 sim100 sim1000 sim10000

simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi) width=r(width), ///
         reps(500) seed(1001): sim_reg, n(10)
gen sample_size = 10
save `sim10'

simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi) width=r(width), ///
         reps(500) seed(1002): sim_reg, n(100)
gen sample_size = 100
save `sim100'

simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi) width=r(width), ///
         reps(500) seed(1003): sim_reg, n(1000)
gen sample_size = 1000
save `sim1000'

simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ///
         ci_lo=r(ci_lo) ci_hi=r(ci_hi) width=r(width), ///
         reps(500) seed(1004): sim_reg, n(10000)
gen sample_size = 10000
save `sim10000'

use `sim10', clear
append using `sim100'
append using `sim1000'
append using `sim10000'

save "$BOXPATH\simulation_results.dta", replace

// graph
use "$BOXPATH\simulation_results.dta", clear

graph box beta, over(sample_size) ///
    yline(2.5, lcolor(red)) ///
    title("Beta estimates by sample size")

graph export "$BOXPATH\beta_boxplot.png", replace

// table
table sample_size, ///
    statistic(mean beta) ///
    statistic(sd beta) ///
    statistic(mean sem) ///
    statistic(mean width)