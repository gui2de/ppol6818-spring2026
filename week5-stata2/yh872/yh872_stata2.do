**************
* Question 1 *
**************
clear all
set more off
use "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q1_psle_student_raw.dta", clear

* schoolcode
replace schoolcode = substr(schoolcode, 5, 9)
replace schoolcode = upper(schoolcode)

* clean html
gen txt = s
replace txt = subinstr(txt, "&nbsp;", " ", .)
replace txt = subinstr(txt, "&#160;", " ", .)
replace txt = ustrregexra(txt, "<[^>]*>", " ") 
replace txt = itrim(txt)
replace txt = strtrim(txt)

* split into student chunks and reshape
replace txt = ustrregexra(txt, "(PS[0-9]{7}-[0-9]{4})", "|||$1")
split txt, parse("|||") gen(student_)
drop s txt student_1 
keep schoolcode student_*
reshape long student_, i(schoolcode) j(id)
drop if student_ == ""

* extract student identifiers and demographics
gen cand_id = ""
replace cand_id = regexs(1) if regexm(student_, "(PS[0-9]{7}-[0-9]{4})")

gen prem_number = ""
replace prem_number = regexs(1) if regexm(student_, "PS[0-9]{7}-[0-9]{4} *([0-9]+)")

gen gender = ""
replace gender = regexs(1) if regexm(student_, " ([MF]) ")

gen name = ""
replace name = regexs(1) if regexm(student_, " [MF] (.+) Kiswahili")
replace name = strtrim(name) 

*  subject grades
foreach subj in Kiswahili English Maarifa Hisabati Science Uraia {
    local lower_subj = strlower("`subj'")
    gen `lower_subj' = ustrregexs(1) if ustrregexm(seg, "`subj' *- *([A-E])")
}
gen average = ustrregexs(1) if ustrregexm(seg, "Average Grade *- *([A-E])")

* save results
drop if cand_id == ""

keep schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average
order schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

save "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q1_psle_student_raw.dta", replace

list in 1/20


**************
* Question 2 *
**************
clear all
set more off

import excel "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q2_CIV_populationdensity.xlsx", firstrow clear

rename NOMCIRCONSCRIPTION dept_str
rename DENSITE* density

* drops the duplicate city/sub-prefecture rows
keep if strpos(upper(dept_str), "DEPARTEMENT") > 0

* make lowercase and remove the prefixes
replace dept_str = strlower(dept_str)
replace dept_str = subinstr(dept_str, "departement d' ", "", .)
replace dept_str = subinstr(dept_str, "departement de ", "", .)
replace dept_str = subinstr(dept_str, "departement d'", "", .)
replace dept_str = subinstr(dept_str, "departement du ", "", .)
replace dept_str = strtrim(dept_str)

keep dept_str density
drop if missing(dept_str)
duplicates drop dept_str, force

save "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/CIV_density_temp.dta", replace

use "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q2_CIV_Section_0.dta", clear

* decode the numeric department variable into a string
decode b06_departemen, gen(dept_str)

* clean the new string variable so it matches the density data perfectly
replace dept_str = strlower(dept_str)
replace dept_str = strtrim(dept_str)

* merge 
merge m:1 dept_str using "CIV_density_temp.dta"
tab _merge
drop _merge
erase "CIV_density_temp.dta"

* save output
save "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q2_CIV_Section_0_merged.dta", replace


**************
* Question 3 *
**************
clear all
set more off
use "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q3_GPS Data.dta", clear

* sort the households geographically (North to South, then West to East)
sort latitude longitude

* each block consists of 6 observations
egen enumerator_id = seq(), block(6)

tab enumerator_id


**************
* Question 4 *
**************
clear all
set more off

* load raw dataset without the firstrow
import excel "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q4_Tz_election_2010_raw.xls", clear

rename A region_10
rename B district_10
rename C constituency_10
rename D ward_10
rename E candidate_name
rename H party_10
rename I votes_ 

* drop  messy header rows
drop if missing(candidate_name) | candidate_name == "CANDIDATE NAME"

* fill  missing geographic identifiers caused by merged Excel
replace region_10 = region_10[_n-1] if missing(region_10)
replace district_10 = district_10[_n-1] if missing(district_10)
replace constituency_10 = constituency_10[_n-1] if missing(constituency_10)
replace ward_10 = ward_10[_n-1] if missing(ward_10)

* clean trailing/leading spaces from string variables
replace region_10 = strtrim(region_10)
replace district_10 = strtrim(district_10)
replace constituency_10 = strtrim(constituency_10)
replace ward_10 = strtrim(ward_10)

* convert votes from string format to numbers
destring votes_, replace force

* generate total candidates, total votes per ward before reshape
bysort region_10 district_10 constituency_10 ward_10: gen total_candidates_10 = _N
bysort region_10 district_10 constituency_10 ward_10: egen ward_total_votes_10 = sum(votes_)

* clean party names for variable suffixes
replace party_10 = strtrim(party_10)
replace party_10 = subinstr(party_10, " - ", "_", .)
replace party_10 = subinstr(party_10, "-", "_", .)
replace party_10 = subinstr(party_10, " ", "_", .)

replace party_10 = party_10 + "_10"

* collapse to 1 row per party per ward 
collapse (sum) votes_ (firstnm) total_candidates_10 ward_total_votes_10, by(region_10 district_10 constituency_10 ward_10 party_10)

* wide format
reshape wide votes_, i(region_10 district_10 constituency_10 ward_10) j(party_10) string

* create a variable based on geographic group
egen ward_id_10 = group(region_10 district_10 ward_10)

capture gen votes_other_10 = .

order region_10 district_10 constituency_10 ward_10 total_candidates_10 ward_total_votes_10 ward_id_10 votes_AFP_10 votes_APPT_MAENDELEO_10 votes_CCM_10 votes_CHADEMA_10 votes_CHAUSTA_10 votes_CUF_10 votes_DP_10 votes_JAHAZI_ASILIA_10 votes_MAKIN_10 votes_NCCR_MAGEUZI_10 votes_NLD_10 votes_NRA_10 votes_SAU_10 votes_TADEA_10 votes_TLP_10 votes_UDP_10 votes_UMD_10 votes_UPDP_10 votes_other_10

save "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q4_Tz_election_template.dta", replace

de

**************
* Question 5 *
**************
clear all
set more off

use "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q5_school_location.dta", clear

* clean school ID
gen scode = upper(strtrim(NECTACentreNo))
drop if scode == "N/A" | missing(scode)

* clean school name
gen region_n = upper(strtrim(Region))
gen name_c = upper(strtrim(School))
replace name_c = ustrregexra(name_c, "\bPRIMARY\b|\bSCHOOL\b", "")
replace name_c = ustrregexra(name_c, "[^A-Z0-9 ]", "")
replace name_c = strtrim(itrim(name_c))

* match based on school id
preserve
    bysort scode: keep if _n == 1
    keep scode Ward
    tempfile lookup_id
    save `lookup_id'
restore

* match maced on school name and ward
preserve
    bysort region_n name_c: keep if _n == 1
    keep region_n name_c Ward
    rename Ward ward_m2
    tempfile lookup_name
    save `lookup_name'
restore

use "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q5_psle_2020_data.dta", clear

* extract the 7-digit school code
gen scode = upper(ustrregexs(1)) if ustrregexm(school_code_address, "(ps[0-9]{7})")

* clean up region and school names
gen region_n = upper(strtrim(region_name))
gen name_c = upper(strtrim(schoolname))
replace name_c = ustrregexra(name_c, " - PS[0-9].*", "")
replace name_c = ustrregexra(name_c, "\\\\r\\\\n.*", "")
replace name_c = ustrregexra(name_c, "\bPRIMARY\b|\bSCHOOL\b", "")
replace name_c = ustrregexra(name_c, "[^A-Z0-9 ]", "")
replace name_c = strtrim(itrim(name_c))

gen ward = ""

* merge by id
merge m:1 scode using `lookup_id', keep(master match) nogen
replace ward = Ward if missing(ward) & !missing(Ward)
drop Ward

* merge by name and region
merge m:1 region_n name_c using `lookup_name', keep(master match) nogen
replace ward = ward_m2 if missing(ward) & !missing(ward_m2)
drop ward_m2

* manually merge
replace ward = "Kitunda"        if scode == "PS0201019" & missing(ward)
replace ward = "Gararagua"      if scode == "PS0702207" & missing(ward)
replace ward = "Kifula"         if scode == "PS0702234" & missing(ward)
replace ward = "Rabour"         if scode == "PS0903051" & missing(ward)
replace ward = "Msolwa Station" if scode == "PS1101059" & missing(ward)
replace ward = "Sanje"          if scode == "PS1101060" & missing(ward)
replace ward = "Hembeti"        if scode == "PS1101142" & missing(ward)
replace ward = "Kisawasawa"     if scode == "PS1101159" & missing(ward)
replace ward = "Kibaoni"        if scode == "PS1101180" & missing(ward)
replace ward = "Mwendakulima"   if scode == "PS1701106" & missing(ward)
replace ward = "Majiri"         if scode == "PS1807014" & missing(ward)
replace ward = "Masiwani"       if scode == "PS2006047" & missing(ward)

drop scode region_n name_c

assert _N == 17329

save "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q5_psle_with_ward.dta", replace

*********
* Bonus *
*********
clear all
set more off

use "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/Tz_elec_10_clean.dta", clear

* search for target
gen target_reg = upper(strtrim(region_10))
gen target_dist = upper(strtrim(district_10))
gen target_ward = upper(strtrim(ward_10))
foreach v of varlist target_* {
    replace `v' = ustrregexra(`v', "[^A-Z0-9 ]", "")
    replace `v' = strtrim(itrim(`v'))
}

bysort target_reg target_dist target_ward: keep if _n == 1
save "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q6_elec10_temp.dta", replace

use "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/Tz_GIS_2015_2010_intersection.dta", clear

* 2015 (fid_gis_2017)
gsort fid_gis_2017 -percentage
bysort fid_gis_2017: keep if _n == 1

* clean 2015 
gen reg_15 = upper(strtrim(region_gis_2017))
gen dist_15 = upper(strtrim(district_gis_2017))
gen ward_15 = upper(strtrim(ward_gis_2017))

* clean 2010 - GIS
gen target_reg_gis = upper(strtrim(region_gis_2012))
gen target_dist_gis = upper(strtrim(district_gis_2012))
gen target_ward_gis = upper(strtrim(ward_gis_2012))

foreach v of varlist reg_15 dist_15 ward_15 target_*_gis {
    replace `v' = ustrregexra(`v', "[^A-Z0-9 ]", "")
    replace `v' = strtrim(itrim(`v'))
}

keep reg_15 dist_15 ward_15 target_reg_gis target_dist_gis target_ward_gis
bysort reg_15 dist_15 ward_15: keep if _n == 1
save "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q6_gis_temp.dta", replace

use "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/Tz_elec_15_clean.dta", clear

* reg_15, dist_15, ward_15
rename region_15 reg_15
rename district_15 dist_15

replace reg_15 = upper(strtrim(reg_15))
replace dist_15 = upper(strtrim(dist_15))
replace ward_15 = upper(strtrim(ward_15))

foreach v of varlist reg_15 dist_15 ward_15 {
    replace `v' = ustrregexra(`v', "[^A-Z0-9 ]", "")
    replace `v' = strtrim(itrim(`v'))
}

* merge - GIS
merge m:1 reg_15 dist_15 ward_15 using "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q6_gis_temp.dta", keep(master match) gen(_merge_gis)

* merge - target
gen target_reg = target_reg_gis
gen target_dist = target_dist_gis
gen target_ward = target_ward_gis

* 2015 -> 2010
replace target_reg = reg_15 if missing(target_reg)
replace target_dist = dist_15 if missing(target_dist)
replace target_ward = ward_15 if missing(target_ward)

* final target extract -> 2010
merge m:1 target_reg target_dist target_ward using "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q6_elec10_temp.dta", keep(master match) gen(_merge_elec10)

*test
count
assert r(N) == 3944
tab _merge_elec10

* wrap up
drop reg_15 dist_15 ward_15 target_* _merge_gis
erase "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q6_elec10_temp.dta"
erase "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/q6_gis_temp.dta"

save "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 2/01_data/Tz_elec_15_10_matched.dta", replace
