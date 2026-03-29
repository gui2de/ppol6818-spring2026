* PART 1: FUZZY MATCHING - Tanzania Ward Analysis
cd "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 4/data"

* Q1–Q3: Exact name matching between the two clean datasets

* --- Standardize 2015 ward names ---
use "Tz_elec_15_clean.dta", clear
gen ward_name     = lower(trim(ward_15))
gen district_name = lower(trim(district_15))
gen region_name   = lower(trim(region_15))
save "temp_15.dta", replace

* --- Standardize 2010 ward names ---
use "Tz_elec_10_clean.dta", clear
gen ward_name     = lower(trim(ward_10))
gen district_name = lower(trim(district_10))
gen region_name   = lower(trim(region_10))
save "temp_10.dta", replace

* --- Merge on name ---
use "temp_15.dta", clear
merge 1:1 region_name district_name ward_name using "temp_10.dta"
*  _merge == 3 → in both years
*  _merge == 1 → only in 2015 (parentless)
*  _merge == 2 → only in 2010 (orphan)

* Q1: wards in BOTH 2010 and 2015
count if _merge == 3
di "Q1 – Wards existing in both years: " r(N)

* Q2: "parentless" wards (in 2015, not found in 2010)
count if _merge == 1
di "Q2 – Parentless wards (2015 only): " r(N)

* Q3: "orphan" wards (in 2010, not found in 2015)
count if _merge == 2
di "Q3 – Orphan wards (2010 only): " r(N)


* Q4–Q6: Use GIS intersection data to study ward divisions

use "Tz_GIS_2015_2010_intersection.dta", clear

* STEP 1: For each 2015 ward, keep only the row with the HIGHEST overlap
* _n == _N means the LAST row = highest percentage = parent ward
bysort fid_gis_2017 (percentage): keep if _n == _N

* STEP 2: Count how many 2015 children each 2010 ward has
bysort fid_gis_2012: gen n_children = _N

* STEP 3: Collapse to one row per 2010 ward
bysort fid_gis_2012: keep if _n == 1

* Q4: 2010 wards divided into EXACTLY 2 wards
count if n_children == 2
di "Q4 – Wards divided into exactly 2: " r(N)

* Q5: 2010 wards divided into 3 OR MORE wards
count if n_children >= 3
di "Q5 – Wards divided into 3 or more: " r(N)

* Q6: Division rate by region
gen was_divided = 0
replace was_divided = 1 if n_children > 1

bysort region_gis_2012: gen total_wards_2010 = _N
bysort region_gis_2012: egen n_divided = total(was_divided)
gen division_rate = n_divided / total_wards_2010

bysort region_gis_2012: keep if _n == 1
gsort -division_rate
list region_gis_2012 total_wards_2010 n_divided division_rate, sep(0)
