********************************************************************
* Stata4 Assignment - Part 1
* Qingya Yang

********************************************************************
* Part 1: Fuzzy Matching 
cd "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-stata4"

********************************************************************
*** Q1 ***
********************************************************************
* 2010 election data
use "Tz_elec_10_clean.dta", clear
gen district_clean = strtrim(district_10)
gen key_merge = district_clean + "||" + ward_10

preserve
keep ward_id_10 region_10 district_clean ward_10 key_merge
tempfile Tz_ward10
save `Tz_ward10'
restore

* 2015 election data
use "Tz_elec_15_clean.dta", clear

gen district_clean = strtrim(district_15)
gen key_merge          = district_clean + "||" + ward_15

* Merge 2015 onto 2010 lookup
merge m:1 key_merge using `Tz_ward10', keep(1 2 3) gen(match_result)
* match_result == 3  →  exists in both years (exact name match)
* match_result == 1  →  in 2015 only  (parentless, at this stage)

* Q1
count if match_result == 3
di "Q1 - Wards existing in both 2010 and 2015: " r(N)

********************************************************************* *** Q2 ***
*********************************************************************
count if match_result == 1
di "Q2 - Parentless wards (in 2015, not in 2010): " r(N)

********************************************************************* *** Q3 ***
*********************************************************************
* Create a lookup for 2015 data
use "Tz_elec_15_clean.dta", clear
gen district_clean = strtrim(district_15)
gen key_merge = district_clean +"||" + ward_15
keep key_merge
tempfile Tz_ward15
save `Tz_ward15'

* Merge onto 2010 data
use "Tz_elec_10_clean.dta", clear
gen district_clean = strtrim(district_10)
gen key_merge = district_clean + "||" + ward_10

merge m:1 key_merge using `Tz_ward15', keep(1 2 3) gen(in_2015)
* in_2015 == 1 means the 2010 ward has no match in 2015 → orphan

count if in_2015 == 1
di "Q3 - Orphan wards (in 2010, not in 2015): " r(N)
********************************************************************* *** Q4 & Q5 ***
********************************************************************
use "Tz_GIS_2015_2010_intersection.dta", clear

* For each 2010 ward, count how many 2015 wards are mapped to it
bysort fid_gis_2012: gen n_children = _N

* Q4: Wards divided into exactly 2
* Q5: Wards divided into 3 or more

preserve
    bysort fid_gis_2012: keep if _n == 1

    count if n_children == 2
    di "Q4 - Wards divided into exactly 2: " r(N)

    count if n_children >= 3
    di "Q5 - Wards divided into 3 or more: " r(N)
restore

********************************************************************
*** Q6 ***
********************************************************************

use "Tz_GIS_2015_2010_intersection.dta", clear

bysort fid_gis_2012: gen n_children = _N
bysort fid_gis_2012: keep if _n == 1

gen divided = (n_children >= 2)

* Collapse to region level
collapse (count) total_wards = fid_gis_2012 ///
         (sum) n_divided   = divided, ///
         by(region_gis_2012)

* Compute division rate
gen division_rate = round(100 * n_divided / total_wards, 0.01)

label var total_wards    "Total wards in 2010"
label var n_divided      "Wards divided into 2+ by 2015"
label var division_rate  "Division rate (%)"

* Display sorted by division rate (highest first)
gsort -division_rate
list region_gis_2012 total_wards n_divided division_rate, ///
     sep(0) noobs abbrev(20)

