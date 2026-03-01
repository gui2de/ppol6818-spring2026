********************************************************************************
***********************Qingfeng's Stata 2 Assignment****************************
*****************************Date: Feb 28, 2026*********************************
********************************************************************************

global wd"E:\stata2\01_data"

****************Q1****************
use "$wd/q1_psle_student_raw.dta", clear
rename schoolcode schoolfile
rename s html

*Generate school id. Prepare for reshape later
generate sid = _n

*Clean HTML
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
 
* Change data format into long
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

* Student-level dataset
keep schoolfile schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average
order schoolfile schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average
count
browse

****************Q2****************
import excel "$wd/q2_CIV_populationdensity.xlsx", firstrow clear

* Keep relevant variables
keep NOMCIRCONSCRIPTION DENSITEAUKM

* Rename variables to match household dataset
rename NOMCIRCONSCRIPTION b06_departemen
rename DENSITEAUKM pop_density

* Clean department names
replace b06_departemen = lower(strtrim(b06_departemen))

* If duplicates exist, take mean density by department
collapse (mean) pop_density, by(b06_departemen)

* Ensure department uniquely identifies observations
isid b06_departemen

* Save cleaned density dataset
save "$wd/density_temp.dta", replace

* Open household dataset
use "$wd/q2_CIV_Section_0.dta", clear

* If department variable is numeric with value label, convert to string
capture confirm string variable b06_departemen
if _rc {
    decode b06_departemen, gen(dept_name)
    drop b06_departemen
    rename dept_name b06_departemen
}

* Clean department names to match density data
replace b06_departemen = lower(strtrim(b06_departemen))


* Merge (many households to one department)
merge m:1 b06_departemen using "$wd/density_temp.dta"

* Check merge result
tab _merge

* Keep only matched observations
keep if _merge == 3
drop _merge

* Verify merge worked
summ pop_density
list b06_departemen pop_density in 1/10

****************Q3****************
use "$wd/q3_GPS Data.dta", clear

* Step 1: Create longitude strips (East-West bands) ───────────────────────
* Divide the village into strips along longitude (approx. sqrt(19) ≈ 4 strips)
xtile lon_strip = longitude, nq(4)

* Step 2: Snake pattern sorting ───────────────────────────────────────────
* Odd strips: sort latitude low to high; Even strips: sort latitude high to low
* This ensures no large spatial jumps at strip boundaries"
gen lat_order = latitude
replace lat_order = -latitude if mod(lon_strip, 2) == 0

* Step 3: Generate global spatial rank ─────────────────────────────────────
sort lon_strip lat_order
gen spatial_rank = _n

* Step 4: Assign enumerator IDs sequentially (~6 households each) ─────────
* 111 households / 19 enumerators = 5.84, so some get 6 households, some get 5
gen enumerator_id = ceil(spatial_rank * 19 / _N)

* Step 5: Verify number of households assigned to each enumerator ──────────
tab enumerator_id

****************Q4****************
clear all
set more off

* Step 1: Import raw Excel data (data starts at row 5, first row = header) ──
import excel "$wd/q4_Tz_election_2010_raw.xls", sheet("Sheet1") cellrange(A5) firstrow clear allstring

* Step 2: Forward-fill missing geographic identifiers ──────────────────────
* Raw data leaves region/district/constituency blank for repeated rows
local geo_vars REGION DISTRICT COSTITUENCY WARD
foreach v of local geo_vars {
    replace `v' = `v'[_n-1] if `v' == ""
}

* Step 3: Remove non-party rows (blank or missing POLITICALPARTY) ──────────
drop if POLITICALPARTY == "" | POLITICALPARTY == "."

* Step 4: Handle uncontested wards and convert votes to numeric ─────────────
replace TTLVOTES = "0" if regexm(upper(TTLVOTES), "UN.?OPPOSED")
* Remove commas from numbers (e.g. "1,234") before converting
replace TTLVOTES = subinstr(TTLVOTES, ",", "", .)
destring TTLVOTES, replace force

* Step 5: Standardize party name strings ────────────────────────────────────
* Trim whitespace, then replace separators with underscores
replace POLITICALPARTY = strtrim(POLITICALPARTY)
replace POLITICALPARTY = subinstr(POLITICALPARTY, " ", "_", .)
replace POLITICALPARTY = subinstr(POLITICALPARTY, "-", "_", .)
replace POLITICALPARTY = subinstr(POLITICALPARTY, ".", "", .)

* Step 6: Collapse to ward-party level ─────────────────────────────────────
* This sums votes if a party fielded multiple candidates in the same ward,
* and computes ward-level totals — all before reshaping
collapse (sum) TTLVOTES (count) total_candidates_10 = TTLVOTES, ///
    by(REGION DISTRICT COSTITUENCY WARD POLITICALPARTY)

bysort REGION DISTRICT COSTITUENCY WARD: ///
    egen ward_total_votes_10 = total(TTLVOTES)

* Step 7: Reshape long to wide (now uniquely identified) ───────────────────
reshape wide TTLVOTES, ///
    i(REGION DISTRICT COSTITUENCY WARD ward_total_votes_10 total_candidates_10) ///
    j(POLITICALPARTY) string

* Step 8: Rename vote columns to match template naming convention ───────────
rename TTLVOTES* votes_*
foreach v of varlist votes_* {
    rename `v' `v'_10
}

* Step 9: Rename geographic columns ────────────────────────────────────────
rename (REGION DISTRICT COSTITUENCY WARD) ///
       (region_10 district_10 constituency_10 ward_10)

* Step 10: Replace missing party votes with 0 (party did not contest ward) ──
foreach v of varlist votes_*_10 {
    replace `v' = 0 if missing(`v')
}

* Step 11: Generate unique ward ID ─────────────────────────────────────────
gen ward_id_10 = _n

list in 1/10
save "$wd/q4_Tz_election_2010_clean.dta", replace


****************Q5****************
use "$wd/q5_school_location.dta", clear

* Step 1: Prepare the school location lookup table
rename NECTACentreNo school_code
replace school_code = upper(strtrim(school_code))

rename School school_name_loc
replace school_name_loc = upper(strtrim(school_name_loc))

keep school_code Ward school_name_loc

duplicates drop school_code, force

* Save as a real file instead of tempfile to avoid macro scope issues
save "$wd/loc_lookup.dta", replace

* Step 2: Prepare PSLE dataset and attempt code-based merge
use "$wd/q5_psle_2020_data.dta", clear

gen addr_clean  = upper(strtrim(school_code_address))
gen school_code = strtrim(substr(addr_clean, 5, 9))

merge m:1 school_code using "$wd/loc_lookup.dta", ///
    keepusing(Ward) keep(1 3) nogen

* Step 3: Fallback — name-based merge for unmatched schools
gen school_name_psle = upper(strtrim(schoolname))

preserve
    use "$wd/loc_lookup.dta", clear
    duplicates drop school_name_loc, force
    rename school_name_loc school_name_psle
    rename Ward Ward_name
    save "$wd/name_lookup.dta", replace
restore

merge m:1 school_name_psle using "$wd/name_lookup.dta", ///
    keepusing(Ward_name) keep(1 3) nogen

replace Ward = Ward_name if missing(Ward) & !missing(Ward_name)
drop Ward_name

* Step 4: Report and save

count if !missing(Ward)
count if  missing(Ward)
count

drop addr_clean school_code school_name_psle

save "$wd/q5_psle_with_wards_final.dta", replace






