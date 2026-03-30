Stata 4
//Part 1
//question 1
use "Tz_elec_15_clean.dta",clear
gen lowerregion = lower(strtrim(region_15))
gen lowerward = lower(strtrim(ward_15))
gen combine = lowerregion + lowerward
save "year15"
use "Tz_elec_10_clean.dta",clear
gen lowerregion = lower(strtrim(region_10))
gen lowerward = lower(strtrim(ward_10))
gen combine = lowerregion + lowerward
save "year10"
use "year15"
merge m:m combine using "year10"
tab _merge 
count if _merge==3
//there are 2944 wards in both 2010 and 2015
//question 2
count if _merge==1
//there are 1005 wards that only exist in 2015, but not exist in 2010
//question 3
count if _merge==2
//there are 411 wards exists only in 2010, but not in the 2015.
//question 4
use "Tz_GIS_2015_2010_intersection.dta", clear
gen combine_2012 = region_gis_2012 + district_gis_2012 + ward_gis_2012
gen combine_2017 = region_gis_2017 + district_gis_2017 + ward_gis_2017
bysort combine_2012 combine_2017: keep if _n==1
bysort combine_2012: gen number = _N
count if number==2
// there are 932 wards divided into two wards between 2010 and 2015
//question 5
count if number>=3
// there are 129 wards divided into three and more wards between 2010 and 2015
//question 6
collapse (first) number region_gis_2012, by(ward_gis_2012)
gen divided = (number>=2) if !missing(number)
gen ward_counter=1 
collapse (mean)division_rate = divided (sum)divided_wards = divided (sum)total_2012_wards = ward_counter, by(region_gis_2012)
format division_rate %9.2f
list region_gis_2012 total_2012_wards divided_wards division_rate, clean

//part 2
clear all
set seed 12345
capture program drop sim_dgp
program sim_dgp, rclass
	syntax, n(integer)
	drop _all
	set obs `n'
	gen C = rnormal()
	gen T = 0.5 * C + rnormal()
	gen M = 0.6 * T + rnormal()
	gen Y = 0.5 * M + 0.8 * C + rnormal()
	gen Z = 0.4 * T + 0.4 * Y + rnormal()
	reg Y T
    return scalar b_naive = _b[T]
	reg Y T C
    return scalar b_correct = _b[T]
	reg Y T C M
    return scalar b_mediator = _b[T]
	reg Y T C Z
    return scalar b_collider = _b[T]
	reg Y T C M Z
    return scalar b_all = _b[T]
end
tempfile sim_results
save `sim_results', emptyok
foreach n in 50 100 500 1000 5000 {
    display "Running simulation for N = `n'..."
    simulate b_naive=r(b_naive) b_correct=r(b_correct) b_mediator=r(b_mediator) b_collider=r(b_collider) b_all=r(b_all), reps(200) seed(123): sim_dgp, n(`n')
			
	gen N = `n'
    append using `sim_results'
    save `sim_results', replace
}

collapse (mean) mean_naive=b_naive mean_correct=b_correct mean_mediator=b_mediator mean_collider=b_collider mean_all=b_all (sd) sd_naive=b_naive sd_correct=b_correct sd_mediator=b_mediator sd_collider=b_collider sd_all=b_all, by(N)
foreach var in naive correct mediator collider all {
    gen var_`var' = sd_`var'^2
}
twoway (line mean_naive N, lcolor(red) lpattern(dash)) (line mean_correct N, lcolor(green) lwidth(medthick)) (line mean_mediator N, lcolor(blue) lpattern(dot)) (line mean_collider N, lcolor(orange) lpattern(dash_dot)) (line mean_all N, lcolor(purple) lpattern(shortdash)), yline(0.3, lcolor(black) lwidth(thick) lpattern(solid)) title("Mean of Treatment Effect (\beta) by Sample Size") ytitle("Estimated \beta") xtitle("Sample Size (N)") legend(order(1 "Naive" 2 "Correct" 3 "Mediator" 4 "Collider" 5 "Kitchen Sink" 6 "True Effect (0.3)")) name(mean_plot, replace)
twoway (line var_naive N, lcolor(red)) (line var_correct N, lcolor(green)) (line var_mediator N, lcolor(blue)) (line var_collider N, lcolor(orange)) (line var_all N, lcolor(purple)), title("Variance of \beta Estimates by Sample Size") ytitle("Variance") xtitle("Sample Size (N)") legend(order(1 "Naive" 2 "Correct" 3 "Mediator" 4 "Collider" 5 "Kitchen Sink")) name(var_plot, replace)

//part 3
ssc install spmap
ssc install shp2dta
ssc install mif2dta
grmap activated
// install everything required
cd "C:\Users\13106\Desktop\us_state_500k"
spshape2dta "cb_2020_us_state_500k.shp", replace
import delimited "NST-EST2024-ALLDATA.csv", clear
rename name NAME
save "my_map_data.dta", replace
use "cb_2020_us_state_500k.dta", clear
merge 1:1 NAME using "my_map_data.dta"
keep if _merge ==3
drop _merge
spset
 grmap popestimate2020, title("US Population by State") subtitle("Using Census Bureau Data") fcolor(Blues) clmethod(quantile) clnumber(5) legstyle(2) legend(position(8)) ndfcolor(gs12) //you can change the variable to anything in the dataset
