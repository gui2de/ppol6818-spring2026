*12345678901234567890123456789012345678901234567890123456789012345678901234567890

*	************************************************************************
* 	File-Name: 	ps2_dofile_q1-6_pd757.do
*	Log-file:	na
*	Date:  		02/27/2026
*	Author: 	Puran Dou
*	Data Used:  various
*	Output		various
*	Purpose:   	.do file for PPOL-6818 assignment: stata 2
*	************************************************************************

clear all
set more off

// capture log close
// log using "$LOG/stata_assignment2.log", replace text

*	************************************************************************
*	Set directory
*	************************************************************************


global ROOT "/Users/oldfarmerdou/Dropbox/ExperimentalDesign/assignment_stata2"
global RAW  "$ROOT/01_data"

* output
global OUT  "$ROOT/02_output"
global TEMP "$ROOT/03_temp"
global LOG  "$ROOT/04_log"

capture mkdir "$OUT"
capture mkdir "$TEMP"
capture mkdir "$LOG"


*	************************************************************************
*	Q1 [!!! DO NOT RUN: reshape long row, i(source_id) j(row_no)]
*	************************************************************************

use "$RAW/q1_psle_student_raw.dta", clear

keep schoolcode s
gen strL txt = s

* clean html
replace txt = ustrregexra(txt, "^b'", "")
replace txt = ustrregexra(txt, "'$", "")

replace txt = ustrregexra(txt, "\\\\r\\\\n|\\\\n|\\\\r", " ")

replace txt = ustrregexra(txt, "\s+", " ")
replace txt = ustrtrim(txt)

* school code
gen school_code = ""
replace school_code = upper(regexs(1)) if regexm(upper(schoolcode), "(PS[0-9]+)")

* split into rows
gen strL chunk = ustrregexra(txt, "(?is)</TR>", "<<<SEP>>>")
split chunk, parse("<<<SEP>>>") gen(row)
gen source_id = _n


* !!! DO NOT RUN THIS, takes ~30min
reshape long row, i(source_id) j(row_no)
/*
Data                               Wide   ->   Long
-----------------------------------------------------------------------------
Number of observations              138   ->   34,224      
Number of variables                 254   ->   8           
j variable (248 values)                   ->   row_no
xij variables:
                   row1 row2 ... row248   ->   row
-----------------------------------------------------------------------------
*/


drop if missing(row)

keep if ustrregexm(row, "PS[0-9]+-[0-9]{4}")

* student var
gen cand_id = ""
gen prem_number = ""
gen gender = ""
gen student_name = ""
gen subject = ""

* candidate id
replace cand_id = ustrregexs(1) if ustrregexm(row, "(?is)(PS[0-9]+-[0-9]{4})")

* prem number
replace prem_number = ustrregexs(1) if ustrregexm(row, "(?is)PS[0-9]+-[0-9]{4}</FONT></TD>\s*<TD[^>]*>\s*<FONT[^>]*>\s*<P[^>]*>\s*([0-9]{6,})<")

* gender
replace gender = ustrregexs(1) if ustrregexm(row, "(?is)[0-9]{6,}</FONT></TD>\s*<TD[^>]*>\s*<FONT[^>]*>\s*<P[^>]*>\s*([MF])<")

* student name: 
replace student_name = ustrregexs(1) if ustrregexm(row, "(?is)[MF]</FONT></TD>\s*<TD[^>]*>\s*<FONT[^>]*>\s*<P[^>]*>\s*([^<]+)<")

* subjects block
replace subject = ustrregexs(1) if ustrregexm(row, "(?is)(Kiswahili\s*-\s*[A-EX].*?Average\s+Grade\s*-\s*[A-EX])")

* grades
gen kiswahili = ustrregexs(1) if ustrregexm(subject, "(?i)Kiswahili\s*-\s*([A-EX])")
gen english = ustrregexs(1) if ustrregexm(subject, "(?i)English\s*-\s*([A-EX])")
gen maarifa = ustrregexs(1) if ustrregexm(subject, "(?i)Maarifa\s*-\s*([A-EX])")
gen hisabati = ustrregexs(1) if ustrregexm(subject, "(?i)Hisabati\s*-\s*([A-EX])")
gen science = ustrregexs(1) if ustrregexm(subject, "(?i)Science\s*-\s*([A-EX])")
gen uraia = ustrregexs(1) if ustrregexm(subject, "(?i)Uraia\s*-\s*([A-EX])")
gen average = ustrregexs(1) if ustrregexm(subject, "(?i)Average\s+Grade\s*-\s*([A-EX])")

keep schoolcode school_code cand_id prem_number gender student_name ///
     kiswahili english maarifa hisabati science uraia average

order schoolcode school_code cand_id prem_number gender student_name ///
      kiswahili english maarifa hisabati science uraia average

sort school_code cand_id

* check
count //8,791

count if missing(gender) // 0
count if missing(student_name) // 0
count if missing(prem_number) // 0
count if missing(average) // 2

tab average, missing
/*

    average |      Freq.     Percent        Cum.
------------+-----------------------------------
            |          2        0.02        0.02
          A |        791        9.00        9.02
          B |      2,736       31.12       40.14
          C |      4,246       48.30       88.44
          D |        831        9.45       97.90
          E |         20        0.23       98.12
          X |        165        1.88      100.00
------------+-----------------------------------
      Total |      8,791      100.00

*/

save "$OUT/q1_psle_students_clean.dta", replace
export delimited using "$OUT/q1_psle_students_clean.csv", replace




*	************************************************************************
*	Q2
*	************************************************************************

** clean the excel
import excel "$RAW/q2_CIV_populationdensity.xlsx", sheet("Population density") firstrow clear

* keep  department name and density only
keep NOMCIRCONSCRIPTION DENSITEAUKM
rename NOMCIRCONSCRIPTION dept_raw
rename DENSITEAUKM pop_density

gen dept_std = lower(trim(dept_raw))
replace dept_std = subinstr(dept_std, "district autonome d'", "", .)
replace dept_std = subinstr(dept_std, "departement d'", "", .)
replace dept_std = subinstr(dept_std, "departement de ", "", .)
replace dept_std = subinstr(dept_std, "departement ", "", .)
replace dept_std = trim(dept_std)

bysort dept_std: keep if _n == 1
save "$TEMP/q2_density_clean.dta", replace

** clean household data
use "$RAW/q2_CIV_Section_0.dta", clear

decode b06_departemen, gen(dept_raw)
gen dept_std = lower(trim(dept_raw))

* fix spelling
replace dept_std = "arrah" if dept_std == "arrha"

merge m:1 dept_std using "$TEMP/q2_density_clean.dta"
keep if _merge == 3
tab _merge
/*
   Matching result from |
                  merge |      Freq.     Percent        Cum.
------------------------+-----------------------------------
            Matched (3) |     12,899      100.00      100.00
------------------------+-----------------------------------
                  Total |     12,899      100.00
*/

drop _merge

save "$OUT/q2_CIV_Section_0_with_density.dta", replace
export delimited using "$OUT/q2_CIV_Section_0_with_density.csv", replace




*	************************************************************************
*	Q3
*	************************************************************************

use "$RAW/q3_GPS Data.dta", clear

* keep valid gps
drop if missing(latitude) | missing(longitude)

* unique household id
gen long hh_id = _n

* number of enumerators
local K = 19

count
local N = r(N)

* balanced group sizes
local base = floor(`N'/`K')
local rem  = mod(`N',`K')


* spatial assignment
sort latitude longitude
gen int enumerator_id = .

local start = 1
forvalues g = 1/`K' {
    
    local target = `base' + (`g' <= `rem')
    local end = `start' + `target' - 1
    
    replace enumerator_id = `g' in `start'/`end'
    
    local start = `end' + 1
}

* checks
count if missing(enumerator_id)

bysort enumerator_id: gen cluster_size = _N
tab enumerator_id
tab cluster_size
/*
cluster_siz |
          e |      Freq.     Percent        Cum.
------------+-----------------------------------
          5 |         15       13.51       13.51
          6 |         96       86.49      100.00
------------+-----------------------------------
      Total |        111      100.00
*/

sort enumerator_id latitude longitude

* save
save "$OUT/q3_GPS_with_enumerator_id.dta", replace
export delimited using "$OUT/q3_GPS_with_enumerator_id.csv", replace




*	************************************************************************
*	Q4
*	************************************************************************

import excel "$RAW/q4_Tz_election_2010_raw.xls", cellrange(A5:J7927) clear allstring

rename A region
rename B district
rename C constituency
rename D ward
rename E candidate_name
rename F sex_m
rename G sex_f
rename H party
rename I votes
rename J elected

* drop first two extra rows
drop in 1/2

* fill down location variables
replace region = region[_n-1] if trim(region)==""
replace district = district[_n-1] if trim(district)==""
replace constituency = constituency[_n-1] if trim(constituency)==""
replace ward = ward[_n-1] if trim(ward)==""

* clean key variables
replace party = upper(trim(party))
replace party = subinstr(party, "-", "_", .)
replace party = subinstr(party, " ", "_", .)
replace party = ustrregexra(party, "_+", "_")

replace party = "JAHAZIASILIA" if party == "JAHAZI_ASILIA"

replace votes = trim(votes)
destring votes, replace force
replace votes = 0 if missing(votes)

* ward id
egen ward_id_10 = group(region district constituency ward)

* keep only needed vars
keep ward_id_10 region district constituency ward party votes

* collapse to ward-party level
collapse (sum) votes, by(ward_id_10 region district constituency ward party)

* reshape wide
reshape wide votes, i(ward_id_10 region district constituency ward) j(party) string

* rename location vars
rename region region_10
rename district district_10
rename constituency constituency_10
rename ward ward_10

* rename vote vars to match template style
rename votes* votes_*_10

* replace missing vote counts with 0
foreach v of varlist votes_*_10 {
    replace `v' = 0 if missing(`v')
}

sort ward_id_10

save "$OUT/q4_Tz_election_2010_clean_wide.dta", replace
export delimited using "$OUT/q4_Tz_election_2010_clean_wide.csv", replace




*	************************************************************************
*	Q5
*	************************************************************************

tempfile psle_base loc_code

* clean plse
use "$RAW/q5_psle_2020_data.dta", clear

gen obs_id = _n

* extract school code
gen school_code = ""
replace school_code = upper(regexs(1)) if regexm(upper(school_code_address), "(PS[0-9]+)")

save `psle_base', replace


* clean school location
use "$RAW/q5_school_location.dta", clear

gen school_code = upper(trim(NECTACentreNo))
gen ward = Ward

keep school_code ward

bysort school_code: keep if _n == 1

save `loc_code', replace

* merge
use `psle_base', clear
merge m:1 school_code using `loc_code'
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                         1,192
        from master                       292  (_merge==1)
        from using                        900  (_merge==2)

    Matched                            17,037  (_merge==3)
    -----------------------------------------
*/

tab _merge

* keep PSLE observations only
drop if _merge == 2

count // 17,329
count if !missing(ward) // 17,037
drop _merge

sort obs_id
save "$OUT/q5_psle_2020_with_ward.dta", replace
export delimited using "$OUT/q5_psle_2020_with_ward.csv", replace



*	************************************************************************
*	Q6
*	************************************************************************

tempfile gismax e15keys gis15keys distmap15 elec15_parent ///
		 e10keys gis10keys distmap10 lookup10


* gis crosswalk
use "$RAW/Tz_GIS_2015_2010_intersection.dta", clear

bysort region_gis_2017 district_gis_2017 ward_gis_2017 (percentage): keep if _n == _N

gen reg15_n = lower(trim(region_gis_2017))
gen dist15g_n = lower(trim(district_gis_2017))
gen ward15_n = lower(trim(ward_gis_2017))

gen reg10p_n = lower(trim(region_gis_2012))
gen dist10p_g_n = lower(trim(district_gis_2012))
gen ward10p_n = lower(trim(ward_gis_2012))

foreach v in reg15_n dist15g_n ward15_n reg10p_n dist10p_g_n ward10p_n {
    replace `v' = subinstr(`v', "-", " ", .)
    replace `v' = subinstr(`v', ".", " ", .)
    replace `v' = itrim(trim(`v'))
}

keep reg15_n dist15g_n ward15_n reg10p_n dist10p_g_n ward10p_n percentage
save `gismax', replace


* 2015 district crosswalk election district -> gis district
use "$RAW/Tz_elec_15_clean.dta", clear

gen reg15_n = lower(trim(region_15))
gen dist15e_n = lower(trim(district_15))
gen ward15_n = lower(trim(ward_15))

foreach v in reg15_n dist15e_n ward15_n {
    replace `v' = subinstr(`v', "-", " ", .)
    replace `v' = subinstr(`v', ".", " ", .)
    replace `v' = itrim(trim(`v'))
}

keep reg15_n dist15e_n ward15_n
duplicates drop
save `e15keys', replace

use `gismax', clear
keep reg15_n dist15g_n ward15_n
duplicates drop
save `gis15keys', replace

use `e15keys', clear
joinby reg15_n ward15_n using `gis15keys'

gen one = 1
collapse (sum) overlap = one, by(reg15_n dist15e_n dist15g_n)

gsort reg15_n dist15e_n -overlap dist15g_n
by reg15_n dist15e_n: keep if _n == 1

save `distmap15', replace


* attach parent ward names to 2015 wards
use "$RAW/Tz_elec_15_clean.dta", clear

gen reg15_n = lower(trim(region_15))
gen dist15e_n = lower(trim(district_15))
gen ward15_n = lower(trim(ward_15))

foreach v in reg15_n dist15e_n ward15_n {
    replace `v' = subinstr(`v', "-", " ", .)
    replace `v' = subinstr(`v', ".", " ", .)
    replace `v' = itrim(trim(`v'))
}

merge m:1 reg15_n dist15e_n using `distmap15', keep(master match) nogen
merge 1:1 reg15_n dist15g_n ward15_n using `gismax', keep(master match) nogen

save `elec15_parent', replace


* 2010 district crosswalk election district -> gis 2012 district
use "$RAW/Tz_elec_10_clean.dta", clear

gen reg10_n = lower(trim(region_10))
gen dist10e_n = lower(trim(district_10))
gen ward10_n = lower(trim(ward_10))

foreach v in reg10_n dist10e_n ward10_n {
    replace `v' = subinstr(`v', "-", " ", .)
    replace `v' = subinstr(`v', ".", " ", .)
    replace `v' = itrim(trim(`v'))
}

keep reg10_n dist10e_n ward10_n
duplicates drop
save `e10keys', replace

use `gismax', clear
keep reg10p_n dist10p_g_n ward10p_n
rename reg10p_n reg10_n
rename dist10p_g_n dist10g_n
rename ward10p_n ward10_n
duplicates drop
save `gis10keys', replace

use `e10keys', clear
joinby reg10_n ward10_n using `gis10keys'

gen one = 1
collapse (sum) overlap = one, by(reg10_n dist10e_n dist10g_n)

gsort reg10_n dist10e_n -overlap dist10g_n
by reg10_n dist10e_n: keep if _n == 1

save `distmap10', replace


* 2010 lookup in gis naming system
use "$RAW/Tz_elec_10_clean.dta", clear

gen reg10_n = lower(trim(region_10))
gen dist10e_n = lower(trim(district_10))
gen ward10_n = lower(trim(ward_10))

foreach v in reg10_n dist10e_n ward10_n {
    replace `v' = subinstr(`v', "-", " ", .)
    replace `v' = subinstr(`v', ".", " ", .)
    replace `v' = itrim(trim(`v'))
}

merge m:1 reg10_n dist10e_n using `distmap10', keep(master match) nogen
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                           276
        from master                       276  
        from using                          0  

    Matched                             3,057  
    -----------------------------------------
*/


keep ward_id_10 total_candidates_10 ward_total_votes_10 ///
     reg10_n dist10g_n ward10_n

duplicates drop reg10_n dist10g_n ward10_n, force

rename reg10_n   reg10p_n
rename dist10g_n dist10p_g_n
rename ward10_n  ward10p_n

save `lookup10', replace


* attach 2010 ward_id to 2015 wards
use `elec15_parent', clear

merge m:1 reg10p_n dist10p_g_n ward10p_n using `lookup10', keep(master match) nogen
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                         1,304
        from master                     1,304  
        from using                          0  

    Matched                             2,640  
    -----------------------------------------
*/

gen parent_name_found = !missing(reg10p_n)
gen ward2010_found    = !missing(ward_id_10)

count // 3,944
count if parent_name_found // 3,472
count if ward2010_found // 2,640

sort ward_id_15

save "$OUT/q6_2015_to_2010_parent_ward_match.dta", replace
export delimited using "$OUT/q6_2015_to_2010_parent_ward_match.csv", replace



*	************************************************************************
*							END of do file
*	************************************************************************
