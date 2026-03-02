**PPOL 6818: Experimental Design and Implementation
**Assignment: Stata 2
**Submitted by Aqsa Zaidi
**Date: 1st March '26

global wd "C:\Users\aqsaz\Documents\Georgetown\Spring 2026\Experimental Design\Stata\Assignment-Stata-2\01_data"

********************************************************************************
********************************QUESTION 1**************************************

clear all
use "q1_psle_student_raw.dta", clear

*------------------------------------------------------------
* 1) Clean HTML and prep for splitting in one pass
*------------------------------------------------------------
replace s = ustrregexra(s, "[\r\n\s]+", " ")
replace s = subinstr(s, "&nbsp;", " ", .)
replace s = ustrregexra(s, "(?i)</tr>", "</TR>||END||")

*------------------------------------------------------------
* 2) Split and Reshape Long
*------------------------------------------------------------
gen long school_id = _n
split s, parse("||END||") gen(part)
reshape long part, i(school_id) j(j)

* Drop non-student rows immediately to speed up regex below
keep if ustrregexm(part, "PS[0-9]{7}-[0-9]{4}") 

*------------------------------------------------------------
* 3) Extract Demographics
*------------------------------------------------------------
gen cand_id        = ustrregexs(1) if ustrregexm(part, "(PS[0-9]{7}-[0-9]{4})")
gen schoolcode_nec = substr(cand_id, 1, strpos(cand_id,"-")-1)
gen prem_number    = ustrregexs(1) if ustrregexm(part, "([0-9]{10,})")
gen gender         = ustrregexs(1) if ustrregexm(part, ">([MF])<")

* Use ([^<]+) to catch ANY character between the tags
gen name           = ustrregexs(1) if ustrregexm(part, "<P>([^<]+)</FONT>")

*------------------------------------------------------------
* 4) Extract Grades directly from the HTML chunk
*------------------------------------------------------------
* Added (?i) to make grade extraction case-insensitive just in case
gen Kiswahili = ustrregexs(1) if ustrregexm(part, "(?i)Kiswahili - ([A-Z])")
gen English   = ustrregexs(1) if ustrregexm(part, "(?i)English - ([A-Z])")
gen maarifa   = ustrregexs(1) if ustrregexm(part, "(?i)Maarifa - ([A-Z])")
gen hisabati  = ustrregexs(1) if ustrregexm(part, "(?i)Hisabati - ([A-Z])")
gen science   = ustrregexs(1) if ustrregexm(part, "(?i)Science - ([A-Z])")
gen uraia     = ustrregexs(1) if ustrregexm(part, "(?i)Uraia - ([A-Z])")
gen average   = ustrregexs(1) if ustrregexm(part, "(?i)Average Grade - ([A-Z])")

*------------------------------------------------------------
* 5) Final Cleanup
*------------------------------------------------------------
keep schoolcode_nec cand_id gender prem_number name Kiswahili English maarifa hisabati science uraia average

* With the permissive name regex, no valid student should be dropped here
drop if missing(cand_id) | missing(name)

save "q1_finaldataset.dta", replace

********************************************************************************
********************************QUESTION 2**************************************

clear all
set more off

*------------------------------------------------------------
* 1) Clean density Excel 
*------------------------------------------------------------
import excel "q2_CIV_populationdensity.xlsx", firstrow clear
keep if strpos(lower(NOMCIRCONSCRIPTION), "departement")

* Clean prefixes in a loop to reduce repetitive lines
gen departement_name = lower(trim(NOMCIRCONSCRIPTION))
foreach p in "departement d' " "departement d'" "departement de " "departement du " {
    replace departement_name = subinstr(departement_name, "`p'", "", 1)
}

rename DENSITEAUKM pop_density
keep departement_name pop_density
duplicates drop departement_name, force

* Use a tempfile so we don't clutter the directory with intermediate files
tempfile density
save `density'

*------------------------------------------------------------
* 2) Load household data, format, and merge
*------------------------------------------------------------
use "q2_CIV_Section_0.dta", clear

decode b06_departemen, gen(departement_name)
replace departement_name = lower(trim(departement_name))
replace departement_name = "arrah" if departement_name == "arrha"

* Merge directly using the tempfile and native filtering options
merge m:1 departement_name using `density', keep(1 3) nogen

*------------------------------------------------------------
* 3) Save final dataset
*------------------------------------------------------------
save "q2_finaldataset.dta", replace

summ pop_density

********************************************************************************
********************************QUESTION 3**************************************
clear all
set more off

* Load the dataset
use "q3_GPS Data.dta", clear

* ==========================================
* USER INPUTS: Set your parameters here
* ==========================================
local X_enums = 19     // (X) Total number of enumerators
local Z_days  = 1      // (Z) Total days allocated for this village
* ==========================================

* Calculate total discrete geographic chunks needed (Enumerators * Days)
local total_groups = `X_enums' * `Z_days'

* 1. Create geographic bands using the dataset's latitude 
local bands = max(1, ceil(sqrt(`total_groups')))
egen lat_band = cut(latitude), group(`bands')

* 2. Create the "snake" walking pattern using the dataset's longitude 
gen lon_snake = cond(mod(lat_band, 2) == 0, longitude, -longitude)
sort lat_band lon_snake

* 3. Assign households proportionally to ensure exactly Y groups
* This perfectly balances the remainder across any total number of units (_N)
gen master_group = ceil(_n * `total_groups' / _N)

* 4. Translate the master group into a specific Enumerator ID and Day ID
gen day_id = ceil(master_group / `X_enums')
gen enum_id = mod(master_group - 1, `X_enums') + 1

* Clean up temporary routing variables and sort for clean viewing
drop lat_band lon_snake master_group
sort day_id enum_id

* ==========================================
* SUMMARY & EXPORT
* ==========================================
* Display the breakdown of assignments
tabulate enum_id day_id

* Save as a new Stata dataset to protect the original file
save "q3_finaldataset.dta", replace

********************************************************************************
********************************QUESTION 4**************************************

clear all
set more off

local xls "q4_Tz_election_2010_raw.xls"
tempfile base
save `base', emptyok replace

* Loop through sheets (adjust sheet names if they differ in your file)
foreach s in Sheet1 {
    import excel using "`xls'", sheet("`s'") clear
    
    * 1. Rename by position immediately
    rename (A B C D H I) (region_10 district_10 constituency_10 ward_10 party votes)
    
    * 2. FILL DOWN FIRST - This is the most important fix
    foreach v in region_10 district_10 constituency_10 ward_10 {
        replace `v' = `v'[_n-1] if trim(`v') == "" | `v' == "."
    }
    
    * 3. Now it is safe to drop headers and empty rows
    drop if mi(party) | party == "POLITICAL PARTY" | party == "SEX"
    
    * 4. Clean votes (Handle strings like "UN OPPOSSED" and commas)
    capture confirm string variable votes
    if !_rc {
        replace votes = subinstr(votes, ",", "", .)
        replace votes = "0" if votes == "UN OPPOSSED"
        destring votes, replace force
    }
    replace votes = 0 if mi(votes)

    * 5. Clean Party names for valid variable naming
    gen partycode = ustrregexra(party, "[^a-zA-Z0-9]", "")
    
    append using `base'
    save `base', replace
}

* Final processing
use `base', clear

* Ensure every ward is unique by summing any duplicate party entries
collapse (sum) votes, by(region_10 district_10 constituency_10 ward_10 partycode)

* Reshape to Wide

reshape wide votes, i(region_10 district_10 constituency_10 ward_10) j(partycode) string

* Rename to match template format
foreach v of varlist votes* {
    rename `v' `v'_10
}

* Calculate totals as required by the template
egen ward_total_votes_10 = rowtotal(votes*)
egen total_candidates_10 = rownonmiss(votes*)

save "q4_finaldataset.dta", replace


********************************************************************************
********************************QUESTION 5**************************************

clear all
version 15

*-----------------------------------------------------------------
* 1) Prep Location Dataset for both matching passes
*----------------------------------------------------------------
use "q5_school_location.dta", clear

* Clean keys for matching
gen necta = upper(trim(NECTACentreNo))
gen reg_norm = upper(trim(Region))
gen dist_norm = upper(trim(regexr(Council, "\([^)]*\)", "")))

* Use modern ustrregexra for global replacement (much faster and cleaner)
gen sch_norm = upper(ustrregexra(School, "\r|\n|PRIMARY SCHOOL", " "))
replace sch_norm = itrim(trim(ustrregexra(sch_norm, "[^A-Z0-9 ]", " ")))
rename Ward ward

* Save dataset for second-pass (name) matching
preserve
duplicates drop reg_norm dist_norm sch_norm, force
tempfile loc_name
save "`loc_name'"
restore

* Save dataset for first-pass (NECTA) matching
keep if necta != "" & necta != "N/A"
duplicates drop necta, force
tempfile loc_necta
save "`loc_necta'"

*----------------------------------------------------------------
* 2) Process PSLE Dataset & Merge
*----------------------------------------------------------------
use "q5_psle_2020_data.dta", clear

* Extract NECTA code safely (checking lowercased text captures both cases)
gen necta = upper(regexs(0)) if regexm(lower(school_code_address), "(ps[0-9]+)")
replace necta = upper(regexs(0)) if missing(necta) & regexm(lower(schoolname), "(ps[0-9]+)")

* FIRST PASS: Merge on NECTA code
* keep(1 3) ensures we keep master-only (1) and matches (3), ignoring extra rows from location
merge m:1 necta using "`loc_necta'", keepusing(ward) keep(1 3) nogen

* Prepare names for second-pass match 
gen reg_norm = upper(trim(region_name))
gen dist_norm = upper(trim(regexr(district_name, "\([^)]*\)", "")))
gen sch_norm = upper(regexr(schoolname, "\s*-\s*PS[0-9]+.*$", ""))
replace sch_norm = ustrregexra(sch_norm, "\r|\n|PRIMARY SCHOOL", " ")
replace sch_norm = itrim(trim(ustrregexra(sch_norm, "[^A-Z0-9 ]", " ")))

* SECOND PASS: Merge on Names (Updates missing wards only)
* The 'update' option automatically fills missing 'ward' values
* keep(1 3 4 5) strictly protects your row count, rejecting unmatched using rows (2)
merge m:1 reg_norm dist_norm sch_norm using "`loc_name'", update keepusing(ward) keep(1 3 4 5) nogen

*----------------------------------------------------------------
* 3) Cleanup and Save
*----------------------------------------------------------------
drop necta reg_norm dist_norm sch_norm
count

compress
save "q5_finaldataset.dta", replace



