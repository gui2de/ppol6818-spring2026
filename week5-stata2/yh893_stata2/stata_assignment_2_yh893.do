********************************************************************************
* Assisgnment: STATA 2
* Author: Yubing Han
* Date: Feb 23, 2026
********************************************************************************

clear all
set more off
cap log close
global class "/Users/serovia/Desktop/assignment: Stata 2"
log using "$class/output/stata2.log", replace text

********************************************************************************
* Q1
********************************************************************************

use "$class/01_data/q1_psle_student_raw.dta",clear
rename schoolcode schoolfile
rename s html
** Create school id for reshape
gen sid = _n

* Clean HTML
replace html = ustrregexra(html, "^\ufeff", "")
replace html = ustrregexra(html, "ï»¿", "")
replace html = ustrregexra(html, "[\r\n\t]+", " ")
replace html = ustrregexra(html, "\s+", " ")
replace html = ustrtrim(html)

* Split HTML into <TR> rows
gen strL tr = html
replace tr = ustrregexra(tr, "</TR>", "<<<ROW>>>")
replace tr = ustrregexra(tr, "</tr>", "<<<ROW>>>")

split tr, parse("<<<ROW>>>") gen(r)
drop tr html

* Reshape long: one observation per HTML row
reshape long r, i(sid schoolfile) j(k)
drop if missing(r)
replace r = ustrtrim(r)

* Keep only rows containing candidate IDs
keep if ustrregexm(r, "PS[0-9]+-[0-9]+")
rename r rowhtml

* Extract student identifiers & student information
gen cand_id = ustrregexs(1) if ustrregexm(rowhtml, "(PS[0-9]+-[0-9]{3,5})")
gen schoolcode = ustrregexs(1) if ustrregexm(cand_id, "^(PS[0-9]+)")
gen prem_number = ustrregexs(1) if ustrregexm(rowhtml,"PS[0-9]+-[0-9]{3,5}.*?<P[^>]*>\s*([0-9]{6,})\s*</")
gen gender = ustrregexs(1) if ustrregexm(rowhtml, ">\s*([MF])\s*</")
gen name = ustrregexs(1) if ustrregexm(rowhtml, "([A-Z][A-Z '.-]{3,})\s*</")
replace name = ustrtrim(name)

* Extract subject grades
gen kiswahili = ustrregexs(1) if ustrregexm(rowhtml, "Kiswahili\s*-\s*([A-Z])")

gen english = ustrregexs(1) if ustrregexm(rowhtml, "English\s*-\s*([A-Z])")

gen maarifa = ustrregexs(1) if ustrregexm(rowhtml, "Maarifa\s*-\s*([A-Z])")

gen hisabati = ustrregexs(1) if ustrregexm(rowhtml, "Hisabati\s*-\s*([A-Z])")

gen science = ustrregexs(1) if ustrregexm(rowhtml, "Science\s*-\s*([A-Z])")

gen uraia = ustrregexs(1) if ustrregexm(rowhtml, "Uraia\s*-\s*([A-Z])")

gen average = ustrregexs(1) if ustrregexm(rowhtml, "Average Grade\s*-\s*([A-Z])")
	
* Final student-level dataset
keep schoolfile schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

order schoolfile schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

compress

count
list schoolfile cand_id prem_number gender name in 1/10, noobs

* Save dataset
save "$class/output/q1_output.dta", replace
export delimited using "$class/output/q1_output.csv", replace

********************************************************************************
* Q2
********************************************************************************

use "$class/01_data/q2_CIV_Section_0.dta", clear

decode b06_departemen, gen(dept_str)
gen dept_key = lower(trim(dept_str))
replace dept_key = itrim(dept_key)     
replace dept_key = "arrah" if dept_key=="arrha"
replace dept_key = ustrregexra(dept_key, "[^a-z ]", "")
replace dept_key = itrim(trim(dept_key))

tempfile hh
save `hh', replace    

* keep only DEPARTEMENT rows
import excel "$class/01_data/q2_CIV_populationdensity.xlsx", firstrow clear

gen circ = lower(trim(NOMCIRCONSCRIPTION))
replace circ = itrim(circ)

keep if regexm(circ, "^departement")

gen dept_key = circ
replace dept_key = regexr(dept_key, "^departement\s+(d'|de|du|des)\s*", "")
replace dept_key = regexr(dept_key, "^departement\s+", "")
replace dept_key = itrim(trim(dept_key))

replace dept_key = ustrregexra(dept_key, "[^a-z ]", "")
replace dept_key = itrim(trim(dept_key))

rename DENSITEAUKM pop_density
destring pop_density, replace force
tab dept_key if inlist(dept_key,"adzope","issia","oume","akoupe","alepe")

keep dept_key pop_density
duplicates drop dept_key, force

isid dept_key

tempfile dens
save `dens', replace

* merge back to household
use `hh', clear
merge m:1 dept_key using `dens'

tab _merge
count if missing(pop_density)

keep if _merge!=2
drop _merge

save "$class/output/q2_CIV_Section_0_with_density.dta", replace



********************************************************************************
* Q3
********************************************************************************
use "$class/01_data/q3_GPS Data.dta",clear


* 1) parameters (generalize)
local K = 19
local N = _N
local base = floor(`N'/`K')
local rem  = `N' - `K'*`base'

* 2) standardize GPS
egen zlat = std(latitude)
egen zlon = std(longitude)

* 3) PCA to get main spatial direction
pca zlat zlon
predict pc1 pc2

* 4) sort households so neighbors are geographically close-ish
sort pc1 pc2

* 5) assign enumerators with exact capacities (base/base+1)
gen int enum_id = .
local start = 1
forvalues e = 1/`K' {
    local size = `base'
    if `e' <= `rem' local size = `base' + 1
    
    local end = `start' + `size' - 1
    replace enum_id = `e' in `start'/`end'
    local start = `end' + 1
}

* 6) QA checks
assert !missing(enum_id)
assert inrange(enum_id,1,`K')

bys enum_id: gen enum_n = _N
tab enum_n   // should be `base' or `base'+1


drop zlat zlon pc1 pc2 enum_n
save "$class/output/q3_GPS_with_enum_id.dta", replace


********************************************************************************
* Q4 
********************************************************************************
clear all
set more off

import excel "$class/01_data/q4_Tz_election_2010_raw.xls", sheet("Sheet1") cellrange(A5) firstrow clear allstring

* Fill in missing geographic information
foreach v of varlist REGION DISTRICT COSTITUENCY WARD {
    replace `v' = `v'[_n-1] if missing(`v')
}

* Remove rows with missing political party (e.g., M/F header rows or blank footer rows)
drop if missing(POLITICALPARTY)
drop if POLITICALPARTY == ""

* Convert "UN OPPOSED" to 0 and ensure the variable is numeric
replace TTLVOTES = "0" if TTLVOTES == "UN OPPOSED"
destring TTLVOTES, replace ignore(",") force

* Remove spaces and special characters
replace POLITICALPARTY = trim(itrim(POLITICALPARTY))
replace POLITICALPARTY = subinstr(POLITICALPARTY, " ", "_", .)
replace POLITICALPARTY = subinstr(POLITICALPARTY, "-", "_", .)
replace POLITICALPARTY = subinstr(POLITICALPARTY, ".", "", .)

* Calculate total votes and number of candidates per ward before reshaping
bysort REGION DISTRICT COSTITUENCY WARD: egen ward_total_votes_10 = sum(TTLVOTES)
bysort REGION DISTRICT COSTITUENCY WARD: gen total_candidates_10 = _N

* Collapse and Reshape (Long to Wide)
collapse (sum) TTLVOTES (first) ward_total_votes_10 total_candidates_10, by(REGION DISTRICT COSTITUENCY WARD POLITICALPARTY)

reshape wide TTLVOTES, i(REGION DISTRICT COSTITUENCY WARD) j(POLITICALPARTY) string

rename TTLVOTES* votes_*
foreach v of varlist votes_* {
    rename `v' `v'_10
}

* Standardize geographic variable names and add suffix to match template
rename REGION region_10
rename DISTRICT district_10
rename COSTITUENCY constituency_10
rename WARD ward_10

* Replace missing party votes with 0
foreach v of varlist votes_* {
    replace `v' = 0 if missing(`v')
}


list in 1/10
save "$class/output/q4_Tz_election_2010_clean.dta", replace


********************************************************************************
* Q5
********************************************************************************

use "$class/01_data/q5_school_location.dta", clear

rename NECTACentreNo school_code
replace school_code = upper(trim(school_code))

keep school_code Ward
duplicates drop school_code, force

tempfile location_temp
save `location_temp'

use "$class/01_data/q5_psle_2020_data.dta", clear

gen cleaned_address = trim(school_code_address)
gen school_code = upper(substr(cleaned_address, 5, 9))

merge m:1 school_code using `location_temp'

keep if _merge == 1 | _merge == 3

tab _merge
count if !missing(Ward)
drop _merge

save "$class/output/q5_psle_with_wards_final.dta", replace
