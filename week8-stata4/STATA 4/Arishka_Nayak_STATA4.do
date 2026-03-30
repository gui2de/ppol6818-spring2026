********************************************************************************
clear all

if c(username) == "arish" {
    global project_directory "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\STATA 4"
}
*FOR REVIEWER*: 
*Add your username and path below
if c(username) == "username" { 
    global wd  "C:/Users/username/Documents/username"  
}
cd "$project_directory"
********************************************************************************
*Part 1: Fuzzy Matching
********************************************************************************
* Clean 2010 election file 
use "Tz_elec_10_clean.dta", clear
rename (region_10 ward_10 district_10 ward_id_10 ward_total_votes_10) (region ward district w_id_10 total_votes_10)
save "elec10_clean.dta", replace
 
 

***Clean 2015 election file***
use "Tz_elec_15_clean.dta", clear
rename (region_15 ward_15 district_15 ward_total_votes_15 ward_id_15) (region ward district total_votes_15 w_id_15)
save "elec15_clean.dta", replace



* Clean GIS file *
use "Tz_GIS_2015_2010_intersection.dta", clear
gen parent_ward_2010 = ward_gis_2012
rename (region_gis_2017 district_gis_2017 ward_gis_2017) (region district ward)
gsort region district ward -percentage
duplicates drop region district ward, force
save "gis_clean.dta", replace

*******************************************************************************
use "elec15_clean.dta", clear
capture drop _merge
capture drop master_id
gen master_id = _n
isid master_id

reclink2 ward district region using "elec10_clean.dta", idmaster(master_id) idusing(w_id_10) gen(match_score) required(region district) manytoone

duplicates tag w_id_10 if !missing(w_id_10), gen(wards_split)
**wards_split == 0: This 2010 ward has a 1:1 relationship. It maps to exactly one 2015 ward.
**wards_split == 1: This 2010 ward has "split" into two 2015 wards.
**wards_split > 1: This 2010 ward has split into three or more 2015 wards.

*Counting wards in 2010 and 2015
tab wards_split

*Counting wards in 2015 but not 2010 (Parentless wards)
count if missing(w_id_10)

*Counting wards in 2010 but not 2015 (Childless wards)
preserve
	drop _merge
    tempfile matched_data
    save `matched_data'
    use "elec10_clean.dta", clear
    merge 1:m w_id_10 using `matched_data'
    count if _merge == 1
restore


*Generating table of ward divisions
gen divided = (wards_split > 0) if !missing(wards_split)

gen division_rate = divided * 100
label variable division_rate "Ward Division Rate (%)"
tabulate region, summarize(division_rate)
tabulate region, su(divided)


********************************************************************************
*PART 2:De-biasing a parameter estimate using controls
********************************************************************************
clear all
cd "$project_directory"

capture program drop bias
program define bias, rclass
syntax, n(integer) 
clear
set obs `n'

generate confound=rnormal(0,1)
*Affects both treatment and outcome; therefore should appear in both treat and outcome 

generate treat=(0.5*confound)+rnormal(0,1)
*treatment effect as a function of the confounder + some randomness

generate mediate=(0.4*treat)+ rnormal(0,1)
*treatment affects outcome only through this var 

generate y=(0.3*treat)+(0.5*confound)-(0.8*mediate)

generate collide=(0.6*treat)+(0.2*y)+rnormal(0,1)
*both treatment and outcome variable affect this

********************************************************************************
*Model 1:  SIMPLE REGRESSION MODEL (OMITTED VAR BIAS)
regress y treat 
return scalar b1=_b[treat]

*MODEL 2: CONTROL FOR CONFOUNDER BIAS 
regress y treat confound
return scalar b2=_b[treat]

*MODEL 3: CONTROL FOR MEDIATOR
regress y treat mediate
return scalar b3=_b[treat]

*MODEL 4: OMMITED VAR + COLLIDER BIAS
regress y treat collide
return scalar b4=_b[treat]

*MODEL 5: COLLIDER BIAS 
regress y treat confound collide
return scalar b5=_b[treat]
end
	
tempfile master
save `master', emptyok replace

foreach size in 200 300 400 500 {
	display "Now simulating for sample size `size'"
    simulate b1=r(b1) b2=r(b2) b3=r(b3) b4=r(b4) b5=r(b5), reps(1000) nodots: bias, n(`size')
    gen n_size = `size'
    append using `master'
    save `master', replace
}

use `master', clear
tabstat b1 b2 b3 b4 b5, by(n_size) stat(mean)

collapse (mean) m1=b1 m2=b2 m3=b3 m4=b4 m5=b5 (sd) sd1=b1 sd2=b2 sd3=b3 sd4=b4, by(n_size)

format m* sd* %9.3f
list n_size m1 sd1 m2 sd2, clean


foreach i in 1 2 4 {
    gen u`i' = m`i' + sd`i'
    gen l`i' = m`i' - sd`i'
}

twoway (rcap u2 l2 n_size, lcolor(blue)) (scatter m2 n_size, mcolor(blue) msymbol(D) connect(l)) (rcap u1 l1 n_size, lcolor(red)) (scatter m1 n_size, mcolor(red) msymbol(O) connect(l)), yline(0.3, lpattern(dash) lcolor(black)) ytitle("Coefficient Estimate") xtitle("Sample Size (N)") title("Convergence and Bias by Model") legend(order(2 "Model 2 (Controlled)" 4 "Model 1 (OVB)" 5 "True Beta (0.3)"))




********************************************************************************
*Part 3: Spatial Analysis
********************************************************************************
**WASHINGTON DC
clear
spshape2dta "Wards_from_2022.shp", saving(dc_shape) replace
import delimited "$project_directory\ACS_5-Year_Demographic_Characteristics_DC_Ward.csv"

rename dp05_0001e total_pop
rename dp05_0018e median_age
rename dp05_0038e black_pop
rename sldust ward_id
keep ward_id total_pop median_age black_pop
save "census_data_clean.dta", replace



use "dc_shape.dta", clear
rename WARD ward_id
merge 1:1 ward_id using "census_data_clean.dta"
spmap total_pop using "dc_shape_shp", id(_ID) fcolor(Greens) title("Total Population by Ward, District of Columbia") legstyle(2) clmethod(quantile)


*BONUS WORK
**MAHARASHTRA STATE**
clear
spshape2dta "india_2011_district.shp", saving(india_shape) replace

import delimited "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\STATA 4\india_schooldata.csv", stringcols(2) numericcols(1) 

rename v3 govt_schools
label variable govt_schools "Number of Government Schools"
rename v4 enrollment
label variable enrollment "Enrollment in Government Schools"
keep slno stateut govt_schools enrollment
rename stateut st_nm
rename slno st_cen_cd
replace st_nm="Jammu & Kashmir" if st_nm=="Jammu and Kashmir"
replace st_nm="Dadara & Nagar Havelli" if st_nm=="Dadra and Nagar Haveli and Daman and Diu"
replace st_nm="NCT of Delhi" if st_nm=="Delhi"
replace st_nm="Arunanchal Pradesh" if st_nm=="Arunachal Pradesh"
replace st_nm="Andaman & Nicobar Island" if st_nm=="Andaman and Nicobar Islands"

drop if st_nm=="India"
drop if st_nm=="Telangana"
drop if st_nm=="Ladakh"

save "india_schools_clean.dta", replace

use "india_shape.dta", clear
drop if st_nm=="Daman & Diu"


merge m:1 st_cen_cd using "india_schools_clean.dta"
spmap govt_schools using "india_shape_shp", id(_ID) fcolor(Reds) title("Number of Government Schools by State") legend(pos(6) title("Schools", size(small)))
