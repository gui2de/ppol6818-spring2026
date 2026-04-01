****************************************************
* PPOL 6818 – Stata Assignment 2
* Luke Keller
*
* Folder structure:
* lsk70/
* ├── do/        (do-files)
* ├── data/      (raw inputs: .dta, .xlsx, .pdf)
* └── outputs/   (log files, generated outputs)
****************************************************
* reviewer: Puran Dou

clear all					
set more off 

// *Working directory set-up
// if c(username) == "lukekeller" {
// 	global wd "/Users/lukekeller/Desktop/ppol6818-spring2026/week5-stata2/lsk70"
// } 

* Working directory set-up
global wd "/Users/oldfarmerdou/Documents/GitHub/ppol6818-spring2026/week5-stata2/lsk70"


*Subfolder set-up
global do    "$wd/do"
global data  "$wd/data"    
global out   "$wd/outputs"

cd "$wd"

*Create outputs folder if it doesn't alreadt exist
capture mkdir "$out"

*Start log
capture log close
log using "$out/stata2.log", text replace

****************************************************

***************
* Question 1  *
***************

*Load the 138-school dataset (1 row per school HTML page)
use "$data/q1_psle_student_raw.dta", clear

*Create an empty file to append student rows into
tempfile allstudents
save `allstudents', emptyok replace

*Loop over each school (row)
forvalues i = 1/`=_N' {
    preserve
        keep in `i'

        *Keep the filename school code for traceability
        local schoolfile = schoolcode[1]

        *Put raw HTML into a 1-row dataset variable
        gen strL page_raw = s

        *Clean HTML into plain text
        gen strL page = page_raw

        *Remove tags
        replace page = ustrregexra(page, "<[^>]+>", " ")

        *Replace HTML spacing entities
        replace page = subinstr(page, "&nbsp;", " ", .)

        *Normalize whitespace
        replace page = ustrregexra(page, "[\r\n\t]+", " ")
        replace page = ustrregexra(page, "\s+", " ")
        replace page = strtrim(page)

        *Split cleaned page into student blocks
        replace page = ustrregexra(page, "(PS[0-9]{7}-[0-9]{4})", "|||$1")

        *Split into separate variables
        split page, parse("|||") gen(block)

        *Block1 is everything before the first student
        drop block1

        *Reshape blocks wide -> long (want student rows)
        gen id = 1
        reshape long block, i(id) j(student_index)
        drop id student_index

        *Create student-level variables
        gen str20 cand_id = ""
        gen str20 prem_number = ""
        gen str1  gender = ""
        gen str60 name = ""
        gen strL  grades = ""

        *Parse each block into components
        local pat "^\s*(PS[0-9]{7}-[0-9]{4})\s+([0-9]{8,})\s+([MF])\s+(.+?)\s+(Kiswahili.*)$"

        replace cand_id      = ustrregexs(1) if ustrregexm(block, "`pat'")
        replace prem_number  = ustrregexs(2) if ustrregexm(block, "`pat'")
        replace gender       = ustrregexs(3) if ustrregexm(block, "`pat'")
        replace name         = strtrim(ustrregexs(4)) if ustrregexm(block, "`pat'")
        replace grades       = ustrregexs(5) if ustrregexm(block, "`pat'")

        *Parse school code from cand_id (PS0101114)
        gen str12 schoolcode_ps = substr(cand_id, 1, 9)

        *Keep filename-based schoolcode
        gen str20 schoolfile = "`schoolfile'"

        *Extract subject grades (same as yours)
        gen str1 kiswahili = "" 
        gen str1 english   = ""
        gen str1 maarifa   = ""
        gen str1 hisabati  = ""
        gen str1 science   = ""
        gen str1 uraia     = ""
        gen str1 average   = ""

        replace kiswahili = ustrregexs(1) if ustrregexm(grades, "Kiswahili\s*-\s*([A-E])")
        replace english   = ustrregexs(1) if ustrregexm(grades, "English\s*-\s*([A-E])")
        replace maarifa   = ustrregexs(1) if ustrregexm(grades, "Maarifa\s*-\s*([A-E])")
        replace hisabati  = ustrregexs(1) if ustrregexm(grades, "Hisabati\s*-\s*([A-E])")
        replace science   = ustrregexs(1) if ustrregexm(grades, "Science\s*-\s*([A-E])")
        replace uraia     = ustrregexs(1) if ustrregexm(grades, "Uraia\s*-\s*([A-E])")
        replace average   = ustrregexs(1) if ustrregexm(grades, "Average\s+Grade\s*-\s*([A-E])")

        *Finalize: keep vars and append to master
        keep schoolfile schoolcode_ps cand_id gender prem_number name ///
             kiswahili english maarifa hisabati science uraia average

        append using `allstudents'
        save `allstudents', replace
    restore
}

*Load final combined dataset
use `allstudents', clear

*Clean ordering
order schoolcode_ps schoolfile cand_id gender prem_number name ///
      kiswahili english maarifa hisabati science uraia average

*Minor cleaning
drop s
drop schoolcode

*Save outputs
save "$out/q1_psle_student_clean.dta", replace
export delimited using "$out/q1_psle_student_clean.csv", replace

****************************************************

***************
* Question 2  *
***************

use "$data/q2_CIV_Section_0.dta", clear

*Prep hh data
decode b06_departemen, gen(depname_raw)
gen depname = upper(strtrim(depname_raw))

tempfile hh
save `hh', replace

*Prep density
import excel "$data/q2_CIV_populationdensity.xlsx", firstrow clear

*Standardize department name field
gen depname = upper(strtrim(NOMCIRCONSCRIPTION))
replace depname = subinstr(depname, "'", "'", .)

*Keep only department-level rows (drop higher-level ones)
drop if regexm(depname, "^DISTRICT")
drop if regexm(depname, "^DEPARTEMENT")

*Keep only the merge key + density
keep depname DENSITEAUKM
rename DENSITEAUKM pop_density

*Ensure uniqueness of using key
duplicates report depname
duplicates drop depname, force

tempfile dens
save `dens', replace

*Merge m:1 into households
use `hh', clear
merge m:1 depname using `dens'

*Inspect match quality + clean
tab _merge
list depname if _merge==1 in 1/20, noobs

drop depname depname_raw _merge

*Save merged dataset
save "$out/q2_CIV_Section_0_with_density.dta", replace
export delimited using "$out/q2_CIV_Section_0_with_density.csv", replace

****************************************************

***************
* Question 3  *
***************

use "$data/q3_GPS Data.dta", clear

*Parameters
local K = 19
local N = _N
local target = ceil(`N'/`K')   // approx 6

*Sort geographically
sort latitude longitude

*Assign enumerator IDs in blocks
gen enumerator_id = ceil(_n / `target')

tab enumerator_id

*Export
save "$out/q3_GPS_assigned_simple.dta", replace
export delimited using "$out/q3_GPS_assigned_simple.csv", replace

****************************************************

***************
* Question 4  *
***************

import excel "$data/q4_Tz_election_2010_raw.xls", clear

*Drop title/header rows
drop in 1/6

*Rename columns based on what we saw in row 5/template
rename B region_10
rename C district_10
rename D constituency_10
rename E ward_10
rename H party_raw
rename I votes_raw

*Keep only needed columns (candidate/sex/elected not needed to build ward-party vote totals)
keep region_10 district_10 constituency_10 ward_10 party_raw votes_raw

*Carry forward geography fields (blank for subsequent party rows)
foreach v in region_10 district_10 constituency_10 ward_10 {
    replace `v' = `v'[_n-1] if missing(`v')
}

*Clean strings
foreach v in region_10 district_10 constituency_10 ward_10 party_raw {
    replace `v' = lower(strtrim(`v'))
}

*Clean votes to numeric
destring votes_raw, gen(votes) ignore(",") force

*Drop rows that aren't party-vote rows
drop if missing(party_raw) | missing(votes)

*Standardize party names to match template column naming
gen party = upper(party_raw)
replace party = subinstr(party, "-", "_", .)
replace party = subinstr(party, " ", "_", .)

*Keep only parties that appear in template, send all others to "other"
*Build a list from template
gen party_std = party

*Define allowed parties
local allowed "AFP APPT_MAENDELEO CCM CHADEMA CHAUSTA CUF DP JAHAZI_ASILIA MAKINI NCCR_MAGEUZI NLD NRA SAU TADEA TLP UDP UMD UPDP"

replace party_std = "OTHER"

foreach p of local allowed {
    replace party_std = "`p'" if party == "`p'"
}

*Collapse in case multiple candidates/lines per ward-party (sum votes)
collapse (sum) votes, by(region_10 district_10 constituency_10 ward_10 party_std)

*Create ward id like template
egen ward_id_10 = group(region_10 district_10 ward_10)

*Reshape wide: one row per ward, vote columns per party
reshape wide votes, i(region_10 district_10 constituency_10 ward_10 ward_id_10) j(party_std) string

*Rename reshaped vote vars to template style
ds votes*
foreach v of varlist `r(varlist)' {
    local p = subinstr("`v'","votes","",1)
    if "`p'"=="OTHER" {
        rename `v' votes_other_10
    }
    else {
        rename `v' votes_`p'_10
    }
}

*Total candidates in ward = number of parties with nonmissing votes
egen total_candidates_10 = rownonmiss(votes_*_10)

*Total votes in ward
egen ward_total_votes_10 = rowtotal(votes_*_10)

*Match template variable names/order
order region_10 district_10 constituency_10 ward_10 total_candidates_10 ward_total_votes_10 ward_id_10, first

save "$out/q4_Tz_election_2010_clean.dta", replace
export delimited using "$out/q4_Tz_election_2010_clean.csv", replace

****************************************************

***************
* Question 5  *
***************

use "$data/q5_school_location.dta", clear

gen ps_code = upper(strtrim(NECTACentreNo))
keep ps_code Ward

*Drop garbage keys (these caused many duplicates)
drop if missing(ps_code) | inlist(ps_code, "N/A", "NA", ".", "")

*Ensure one row per PS code
bys ps_code (Ward): keep if _n==1
isid ps_code

tempfile loc
save `loc'

*Merge prep
use "$data/q5_psle_2020_data.dta", clear

*PS code extraction
gen ps_code = ustrregexs(1) if ustrregexm(schoolname, "(PS[0-9]{7})")
replace ps_code = upper(strtrim(ps_code))

merge m:1 ps_code using `loc'

tab _merge
count if missing(Ward)

drop if _merge==2
drop _merge
rename Ward ward

count   // should be 17329

*Outputs
save "$out/q5_psle_2020_with_ward.dta", replace
export delimited using "$out/q5_psle_2020_with_ward.csv", replace

****************************************************

***************
* Bonus		  *
***************

use "$data/Tz_GIS_2015_2010_intersection.dta", clear

*Clean
foreach v in region_gis_2017 district_gis_2017 ward_gis_2017 ///
            region_gis_2012 district_gis_2012 ward_gis_2012 {
    replace `v' = lower(strtrim(`v'))
}

*Build path from GIS intersection (2017~2015, 2012~2010)
bys region_gis_2017 district_gis_2017 ward_gis_2017: egen maxpct = max(percentage)
keep if percentage == maxpct
gsort region_gis_2017 district_gis_2017 ward_gis_2017 -percentage ///
      region_gis_2012 district_gis_2012 ward_gis_2012
bys region_gis_2017 district_gis_2017 ward_gis_2017: keep if _n==1

keep region_gis_2017 district_gis_2017 ward_gis_2017 ///
     region_gis_2012 district_gis_2012 ward_gis_2012 percentage
rename (region_gis_2017 district_gis_2017 ward_gis_2017) (region_15 district_15 ward_15)
rename (region_gis_2012 district_gis_2012 ward_gis_2012) (region_10 district_10 ward_10)
rename percentage parent_overlap_pct

tempfile xwalk
save `xwalk'

*Attach parent ward to 2015 election wards (keep N=3944)
use "$data/Tz_elec_15_clean.dta", clear
foreach v in region_15 district_15 ward_15 { 
	replace `v' = lower(strtrim(`v')) 
	}

merge 1:1 region_15 district_15 ward_15 using `xwalk'
drop if _merge==2
drop _merge

*Bring in parent ward_id_10 (+ 2010 totals) from 2010 clean file
tempfile elec15
save `elec15'

use "$data/Tz_elec_10_clean.dta", clear
foreach v in region_10 district_10 ward_10 { 
	replace `v' = lower(strtrim(`v')) 
	}
tempfile elec10
save `elec10'

use `elec15', clear
merge m:1 region_10 district_10 ward_10 using `elec10'
drop if _merge==2
drop _merge

*Final output (one row per 2015 ward)
keep ward_id_15 region_15 district_15 ward_15 ///
     ward_id_10 region_10 district_10 ward_10 parent_overlap_pct
count   // should be 3944

save "$out/q6_ward_crosswalk_2015_to_2010.dta", replace
export delimited using "$out/q6_ward_crosswalk_2015_to_2010.csv", replace

****************************************************

capture log close


