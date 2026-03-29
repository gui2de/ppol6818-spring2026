// Stata3_QingyueChen

// 01_create_population.do
clear all
set more off
set seed 123456

global BOXPATH "C:\Users\86186\Box\stata3"

set obs 10000
gen id = _n
gen x = rnormal(0,1)
gen u = rnormal(0,2)
gen y = 1 + 2.5*x + u

save "$BOXPATH\fixed_population.dta", replace