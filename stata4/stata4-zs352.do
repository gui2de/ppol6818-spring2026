
use "C:\Users\24547\Desktop\stata4\Tz_GIS_2015_2010_intersection.dta", clear
gsort fid_gis_2017 -percentage 
bysort fid_gis_2017: keep if _n == 1 
save "C:\Users\24547\Desktop\stata4\ward_crosswalk.dta", replace

* ==============================================================================
* Part 1: Fuzzy Matching and Ward Counts
* ==============================================================================

* 1. Count stable, divided-into-two, and divided-into-three+ wards
use "C:\Users\24547\Desktop\stata4\ward_crosswalk.dta", clear
bysort fid_gis_2012: gen child_count = _N
preserve
bysort fid_gis_2012: keep if _n == 1

count if child_count == 1
display "====> Stable wards (exist in both years): " r(N)

count if child_count == 2
display "====> Wards divided into two: " r(N)

count if child_count >= 3
display "====> Wards divided into three or more: " r(N)
restore

* 2. Find Parentless wards (Exist in 2015, not in 2010)
use "C:\Users\24547\Desktop\stata4\ward_crosswalk.dta", clear
gen match_name = strlower(trim(ward_gis_2017)) 
duplicates drop match_name, force 
save "C:\Users\24547\Desktop\stata4\temp_crosswalk.dta", replace

use "C:\Users\24547\Desktop\stata4\Tz_elec_15_clean.dta", clear
gen match_name = strlower(trim(ward_15)) 
merge m:1 match_name using "C:\Users\24547\Desktop\stata4\temp_crosswalk.dta"

count if _merge == 1 
display "====> Parentless wards count: " r(N)

* 3. Find Orphan wards (Exist in 2010, not in 2015)
use "C:\Users\24547\Desktop\stata4\ward_crosswalk.dta", clear
gen match_name = strlower(trim(ward_gis_2012)) 
duplicates drop match_name, force 
save "C:\Users\24547\Desktop\stata4\temp_parents.dta", replace

use "C:\Users\24547\Desktop\stata4\Tz_elec_10_clean.dta", clear
gen match_name = strlower(trim(ward_10)) 
merge m:1 match_name using "C:\Users\24547\Desktop\stata4\temp_parents.dta"

count if _merge == 1
display "====> Orphan wards count: " r(N)

* 4. Calculate Regional Division Rate
use "C:\Users\24547\Desktop\stata4\ward_crosswalk.dta", clear
bysort fid_gis_2012: gen child_count = _N
bysort fid_gis_2012: keep if _n == 1
gen is_divided = (child_count > 1)
collapse (count) total_wards = is_divided (sum) divided_wards = is_divided, by(region_gis_2012)
gen division_rate = (divided_wards / total_wards) * 100
format division_rate %9.2f
gsort -division_rate
display "====> Top 5 regions by division rate:"
list region_gis_2012 total_wards divided_wards division_rate in 1/5, clean

* ------------------------------------------------------------------------------
* Part2
* ------------------------------------------------------------------------------
capture program drop sim_dgp
program sim_dgp, rclass
    syntax, obs(integer)
    clear
    quietly set obs `obs' // 
    
    gen C = rnormal() 
    
    gen T = 0.5 * C + rnormal() 
    
    gen M = 0.5 * T + rnormal() 
    
    gen Y = 0.3 * T + 0.5 * C + 0.5 * M + rnormal() 
    
    gen W = 0.5 * T + 0.5 * Y + rnormal() 
    
    quietly reg Y T
    return scalar b1 = _b[T]
    
    quietly reg Y T C
    return scalar b2 = _b[T]
    
    quietly reg Y T C M
    return scalar b3 = _b[T]
    
    quietly reg Y T C W
    return scalar b4 = _b[T]
    
    quietly reg Y T C M W
    return scalar b5 = _b[T]
end


tempfile results_all
save `results_all', emptyok

local n_list 50 100 250 500 1000 2000

foreach n in `n_list' {
    display 
    
    quietly simulate b1=r(b1) b2=r(b2) b3=r(b3) b4=r(b4) b5=r(b5), ///
        reps(200) seed(12345): sim_dgp, obs(`n')
        
    gen N = `n'
    
    capture append using `results_all'
    save `results_all', replace
}

* ------------------------------------------------------------------------------
* 2 graphs
* ------------------------------------------------------------------------------
use `results_all', clear

collapse (mean) mean_b1=b1 mean_b2=b2 mean_b3=b3 mean_b4=b4 mean_b5=b5 ///
         (sd)   sd_b1=b1   sd_b2=b2   sd_b3=b3   sd_b4=b4   sd_b5=b5, by(N)

gen var_b1 = sd_b1^2
gen var_b2 = sd_b2^2
gen var_b3 = sd_b3^2
gen var_b4 = sd_b4^2
gen var_b5 = sd_b5^2

twoway (line mean_b1 N, lpattern(dash) lcolor(red)) ///
       (line mean_b2 N, lwidth(thick) lcolor(green)) ///
       (line mean_b3 N, lpattern(shortdash) lcolor(blue)) ///
       (line mean_b4 N, lpattern(dot) lcolor(orange)) ///
       (line mean_b5 N, lpattern(longdash) lcolor(purple)), ///  
       yline(0.3, lcolor(black) lwidth(medthick) lpattern(solid)) /// 
       title("Mean of Estimated Beta vs. Sample Size (N)") ///
       xtitle("Sample Size (N)") ytitle("Estimated Beta (True = 0.3)") ///
       legend(order(1 "Model 1 (Omitted C)" 2 "Model 2 (Correct)" 3 "Model 3 (+C, M)" 4 "Model 4 (+C, W)" 5 "Model 5 (All)"))

graph export "beta_mean_convergence.png", replace


twoway (line var_b1 N, lcolor(red)) ///
       (line var_b2 N, lcolor(green)) ///
       (line var_b3 N, lcolor(blue)) ///
       (line var_b4 N, lcolor(orange)) ///
       (line var_b5 N, lcolor(purple)), ///
       title("Variance of Estimated Beta vs. Sample Size (N)") ///
       xtitle("Sample Size (N)") ytitle("Variance of Beta") ///
       legend(order(1 "Model 1" 2 "Model 2" 3 "Model 3" 4 "Model 4" 5 "Model 5"))

graph export "beta_variance_convergence.png", replace


* ==============================================================================
* Part 3: Spatial Analysis 
* ==============================================================================
clear all
cd "C:\Users\24547\Desktop\stata4\"  

capture ssc install spmap
capture ssc install shp2dta
capture ssc install palettes 
capture ssc install colrspace 

spshape2dta "TZA_adm1.shp", replace


use "TZA_adm1.dta", clear
keep _ID NAME_1 

set seed 888
gen avg_income = runiform(500, 2500) 
label var avg_income "Average Income (USD)"

save "mock_public_data.dta", replace

use "TZA_adm1.dta", clear

merge 1:1 _ID using "mock_public_data.dta"
drop _merge

spmap avg_income using "TZA_adm1_shp.dta", ///
    id(_ID) ///
    clnumber(5) fcolor(Blues) ///
    ocolor(white ..) osize(thin ..) /// 
    title("Choropleth Map of Tanzania", size(medlarge)) ///
    subtitle("Simulated Average Income by Region", size(medium)) ///
    legend(title("Avg Income (USD)", size(small)) position(8)) ///
    ndfcolor(gray) // 

graph export "Tanzania_Income_Map.png", replace