*Stata 2 Assignment
*Author: Zimu Zhai (Arlo)
*NetID: zz592
*Date: 03/01/2026
**********************************************
clear all
global data_dir "C:\ExpDesign\StataAssignment2"
cd "$data_dir"
***************************** Question 1 ***************************************
* 1. Load raw HTML dataset (one row per school)
use "$data_dir/q1_psle_student_raw.dta", clear
rename schoolcode schoolfile
rename s html
** Create school id for reshape
gen sid = _n

* 2. Clean HTML text
replace html = ustrregexra(html, "^\ufeff", "")
replace html = ustrregexra(html, "ï»¿", "")
replace html = ustrregexra(html, "[\r\n\t]+", " ")
replace html = ustrregexra(html, "\s+", " ")
replace html = ustrtrim(html)

* 3. Split HTML into <TR> rows
gen strL tr = html
replace tr = ustrregexra(tr, "</TR>", "<<<ROW>>>")
replace tr = ustrregexra(tr, "</tr>", "<<<ROW>>>")

split tr, parse("<<<ROW>>>") gen(r)
drop tr html

* 4. Reshape long: one observation per HTML row
reshape long r, i(sid schoolfile) j(k)
drop if missing(r)
replace r = ustrtrim(r)

* 5. Keep only rows containing candidate IDs
keep if ustrregexm(r, "PS[0-9]+-[0-9]+")
rename r rowhtml

* 6. Extract student identifiers & student information
gen cand_id = ustrregexs(1) ///
    if ustrregexm(rowhtml, "(PS[0-9]+-[0-9]{3,5})")

gen schoolcode = ustrregexs(1) ///
    if ustrregexm(cand_id, "^(PS[0-9]+)")
	
gen prem_number = ustrregexs(1) ///
    if ustrregexm(rowhtml, ///
    "PS[0-9]+-[0-9]{3,5}.*?<P[^>]*>\s*([0-9]{6,})\s*</")

gen gender = ustrregexs(1) ///
    if ustrregexm(rowhtml, ">\s*([MF])\s*</")

gen name = ustrregexs(1) ///
    if ustrregexm(rowhtml, "([A-Z][A-Z '.-]{3,})\s*</")

replace name = ustrtrim(name)

* 7. Extract subject grades
gen kiswahili = ustrregexs(1) ///
    if ustrregexm(rowhtml, "Kiswahili\s*-\s*([A-Z])")

gen english = ustrregexs(1) ///
    if ustrregexm(rowhtml, "English\s*-\s*([A-Z])")

gen maarifa = ustrregexs(1) ///
    if ustrregexm(rowhtml, "Maarifa\s*-\s*([A-Z])")

gen hisabati = ustrregexs(1) ///
    if ustrregexm(rowhtml, "Hisabati\s*-\s*([A-Z])")

gen science = ustrregexs(1) ///
    if ustrregexm(rowhtml, "Science\s*-\s*([A-Z])")

gen uraia = ustrregexs(1) ///
    if ustrregexm(rowhtml, "Uraia\s*-\s*([A-Z])")

gen average = ustrregexs(1) ///
    if ustrregexm(rowhtml, "Average Grade\s*-\s*([A-Z])")
	
* 8. Final student-level dataset
keep schoolfile schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

order schoolfile schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

compress

count
list schoolfile cand_id prem_number gender name in 1/10, noobs

* 9. Save dataset
save "$data_dir/Q1_student_level.dta"
export delimited using "$data_dir/Q1_student_level.csv", replace

***************************** Question 2 ***************************************
clear all
set more off

* 1. Import population density Excel file

import excel "$data_dir/q2_CIV_populationdensity.xlsx", firstrow clear

save "$data_dir/q2_CIV_populationdensity.dta", replace

* 2. Load household data (master)
use "$data_dir/q2_CIV_Section_0.dta", clear

decode b06_departemen, gen(dept_name_hh)
replace dept_name_hh = strtrim(upper(dept_name_hh))

use "$data_dir/q2_CIV_populationdensity.dta", clear

rename NOMCIRCONSCRI~N dept_name
replace dept_name = strtrim(upper(dept_name))
isid dept_name

collapse (mean) DENSITEAUKM (sum) POPULATION (sum) SUPERFICIEKM2, by(dept_name)
isid dept_name
save "$data_dir/density_clean.dta", replace

* 3. Merge
use "$data_dir/q2_CIV_Section_0.dta", clear

decode b06_departemen, gen(dept_name)
replace dept_name = strtrim(upper(dept_name))

merge m:1 dept_name using "$data_dir/density_clean.dta"

tab _merge

drop if _merge==2
drop _merge

***************************** Question 3 ***************************************
clear all
set more off

* Parameters (changable among villages) ---
local n_enum 19      // number of enumerators
local per_day 6      // target households per enumerator

* Load GPS data 
use "$data_dir/q3_GPS Data.dta", clear

* 1. Identify latitude/longitude variables 
local latvar latitude
local lonvar longitude

* 2. Order households by main spatial axis (PCA) and assign 6 per enumerator
pca latitude longitude
predict pc1
sort pc1
gen enumerator_id = ceil(_n / 6)

* 3. Quick checks 
tab enumerator_id

* 4. Save results
save "$data_dir/q3_GPS_assigned.dta", replace

***************************** Question 4 ***************************************
clear all
set more off

* Import starting from the row that contains the true column headers
import excel "$data_dir/q4_Tz_election_2010_raw.xls", ///
    cellrange(A5:J7927) firstrow clear

* Standardiza variable names
rename *, lower
rename costituency constituency

* Keep only what we need
keep region district constituency ward candidatename politicalparty ttlvotes

* Basic cleaning
replace region       = strtrim(upper(region))
replace district     = strtrim(upper(district))
replace constituency = strtrim(upper(constituency))
replace ward         = strtrim(upper(ward))
replace politicalparty = strtrim(upper(politicalparty))
replace candidatename  = strtrim(upper(candidatename))
foreach v in region district constituency ward {
    replace `v' = `v'[_n-1] if missing(`v') & _n>1
}
drop if missing(ward) & missing(politicalparty)

* Count number of candidates per ward
bysort region district constituency ward: gen n_candidates = _N

* Collapse to ward-party vote totals (in case of duplicates)
replace ttlvotes = "0" if upper(strtrim(ttlvotes))=="UN OPPOSSED"
replace ttlvotes = strtrim(ttlvotes)
destring ttlvotes, replace ignore(",")
rename ttlvotes votes

collapse (sum) votes (max) n_candidates, ///
    by(region district constituency ward politicalparty)


* Make party names safe for variable names
replace politicalparty = upper(strtrim(politicalparty))
replace politicalparty = subinstr(politicalparty,"-","_",.)
replace politicalparty = subinstr(politicalparty," ","_",.)
drop if missing(politicalparty)

* Reshape wide: one row per ward, party votes in separate columns
reshape wide votes, ///
    i(region district constituency ward n_candidates) ///
    j(politicalparty) string

* Save cleaned dataset
save "$data_dir/q4_Tz_election_2010_clean_wide.dta", replace


***************************** Question 5 ***************************************
clear all

** A) Create a ward lookup table with a unique key
use "q5_school_location.dta", clear

* Keep only the variables needed for the merge
keep NECTACentreNo Ward

* Clean the key variables 
replace NECTACentreNo = upper(trim(NECTACentreNo))
replace Ward          = strtrim(Ward)

* Check for duplicate NECTACentreNo values
duplicates report NECTACentreNo
drop if NECTACentreNo=="N/A"

* If a NECTA code appears multiple times, keep only the first occurrence
bysort NECTACentreNo: keep if _n==1

save "ward_lookup.dta", replace


** B) Return to the PSLE dataset (master), extract NECTA code, and merge

use "q5_psle_2020_data.dta", clear

* Extract the NECTA Centre number (e.g., PS0101001) from school_code_address
gen str9 NECTACentreNo = ""
replace NECTACentreNo = upper(regexs(0)) if regexm(lower(school_code_address), "ps[0-9]{7}")

* Merge ward information into the PSLE dataset (PSLE is the master dataset)
merge m:1 NECTACentreNo using "ward_lookup.dta"

tab _merge

* Keep only observations from the PSLE dataset (N = 17,329)
drop if _merge==2
drop _merge

count

* Save results
save "q5_psle_2020_with_ward.dta", replace


*************************** Bonus Question *************************************

clear all
set more off

* 0) Build 2010 lookup table
use ""
* Clean keys for 2010 election data
gen region_key   = lower(strtrim(region_10))
gen district_key = lower(strtrim(district_10))
gen ward_key     = lower(strtrim(ward_10))

* Keep only what we need for lookup
keep ward_id_10 ward_10 region_10 district_10 region_key district_key ward_key

save "ward10_lookup_rw.dta", replace


* 1) Start from 2015 election data (defines final rows)
use "Tz_elec_15_clean.dta", clear

* Clean keys for 2015 election data
gen region_key   = lower(strtrim(region_15))
gen district_key = lower(strtrim(district_15))
gen ward_key     = lower(strtrim(ward_15))


* 2) Direct match (wards NOT split): exact name match across years

* Build 2010 keys table for direct match (region+district+ward)
preserve
    use "Tz_elec_10_clean.dta", clear
    gen region_key   = lower(strtrim(region_10))
    gen district_key = lower(strtrim(district_10))
    gen ward_key     = lower(strtrim(ward_10))

    keep ward_id_10 ward_10 region_10 district_10 region_key district_key ward_key
    duplicates drop region_key district_key ward_key, force
    save "ward10_keys_rdw.dta", replace
restore

merge m:1 region_key district_key ward_key using "ward10_lookup_rw.dta", ///
    keepusing(ward_id_10 ward_10 region_10 district_10) gen(_m_direct)

* Save direct parent 
gen ward_id_10_direct = ward_id_10 if _m_direct==3

* Clean up direct merge artifacts: keep full 2015 dataset 
drop ward_id_10 ward_10 region_10 district_10

save "ward15_merged.dta", replace


* 3) Build GIS "best parent" table: for each 2015 ward, choose max-overlap 2010 ward

use "Tz_GIS_2015_2010_intersection.dta"

* 2015-side keys from GIS (2017 shapefile)
gen region_key = lower(strtrim(region_gis_2017))
gen ward_key   = lower(strtrim(ward_gis_2017))

* 2010-side keys from GIS (2012 shapefile) -> parent keys
gen p_region_key   = lower(strtrim(region_gis_2012))
gen p_ward_key     = lower(strtrim(ward_gis_2012))
gen p_district_key = lower(strtrim(district_gis_2012))   // keep for reference

* Pick max overlap parent within each 2015 ward
gsort region_key ward_key -percentage
by region_key ward_key: keep if _n==1

keep region_key ward_key p_region_key p_ward_key p_district_key percentage
save "gis_best_parent_rw.dta", replace


* 4) Merge GIS best parent back into 2015 election data
use "ward10_lookup_rw.dta", clear
rename region_key p_region_key
rename ward_key p_ward_key
rename district_key p_district_key
save ward10_lookup_rw, replace
foreach v in p_region_key p_district_key p_ward_key {
    replace `v' = subinstr(`v', "wilaya ya ", "", .)
    replace `v' = subinstr(`v', "jiji la ", "", .)
    replace `v' = subinstr(`v', "manispaa ya ", "", .)
    replace `v' = subinstr(`v', "mji wa ", "", .)
    replace `v' = subinstr(`v', "mkoa wa ", "", .)
    replace `v' = subinstr(`v', "  ", " ", .)
    replace `v' = subinstr(`v', "  ", " ", .)
    replace `v' = strtrim(`v')
}

use "ward15_merged.dta", clear
foreach v in region_key district_key ward_key {
    replace `v' = subinstr(`v', "wilaya ya ", "", .)
    replace `v' = subinstr(`v', "jiji la ", "", .)
    replace `v' = subinstr(`v', "manispaa ya ", "", .)
    replace `v' = subinstr(`v', "mji wa ", "", .)
    replace `v' = subinstr(`v', "mkoa wa ", "", .)
    replace `v' = subinstr(`v', "  ", " ", .)
    replace `v' = subinstr(`v', "  ", " ", .)
    replace `v' = strtrim(`v')
}


* Now merge GIS parent (region+ward only)
merge m:1 region_key ward_key using "gis_best_parent_rw.dta", gen(_m_gis)

save "ward15_merged", replace


use "ward15_merged.dta", clear

* Sort recording to wards of 2015
gsort ward_id_15 -percentage

* Keep only ward_id_15 overlaped the most
by ward_id_15: keep if _n==1

isid ward_id_15  
count             
drop if ward_id_15 == .
keep ward_id_15 region_15 district_15 ward_15 percentage p_region_key p_ward_key p_district_key

rename p_region_key region_10
rename p_district_key district_10
rename p_ward_key ward_10


save "ward15_final_onerow.dta", replace


