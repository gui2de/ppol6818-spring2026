***==========================================================================***
*** Sunduss' Stata 2 Assignment Do File ***
***==========================================================================***

***==========================================================================***
*** Q1: Tanzania Student Data ***
***==========================================================================***

global wd "/Users/sunduss/Downloads"

use "$wd/q1_psle_student_raw (1).dta", clear

* Split HTML on <TR> — each student row becomes a separate variable
* There are at most ~60 students per school, so split into 70 vars to be safe
split s, parse(<TR>) gen(chunk)

* Drop the HTML string and reshape to long (one row per chunk per school)
drop s
reshape long chunk, i(schoolcode) j(row_num)
drop if missing(chunk)

* The first 5 chunks are headers — only keep actual student rows
* Student rows contain a candidate number like "PS0101001-0001"
keep if regexm(chunk, "PS[0-9]+-[0-9]+")

* Extract fields using regex
gen cand_no  = regexs(1) if regexm(chunk, ">(PS[0-9]+-[0-9]+)<")
gen prem_no  = regexs(1) if regexm(chunk, ">([0-9]{11})<")
gen sex      = regexs(1) if regexm(chunk, ">(M|F)<")
gen name     = regexs(1) if regexm(chunk, "SIZE=1><P>(.*)</FONT>")
gen kiswahili = regexs(1) if regexm(chunk, "Kiswahili - ([A-Z])")
gen english   = regexs(1) if regexm(chunk, "English - ([A-Z])")
gen maarifa   = regexs(1) if regexm(chunk, "Maarifa - ([A-Z])")
gen hisabati  = regexs(1) if regexm(chunk, "Hisabati - ([A-Z])")
gen science   = regexs(1) if regexm(chunk, "Science - ([A-Z])")
gen uraia     = regexs(1) if regexm(chunk, "Uraia - ([A-Z])")
gen avg_grade = regexs(1) if regexm(chunk, "Average Grade - ([A-Z])")

* Clean up and save
drop chunk row_num
save "$wd/q1_psle_students_clean.dta", replace

***==========================================================================***
*** Q2: Côte d'Ivoire Population Density ***
***==========================================================================***

global wd "/Users/sunduss/Downloads/_1_data_export"

import excel "$wd/q2_CIV_populationdensity.xlsx", firstrow clear
rename NOMCIRCONSCRIPTION nom
rename DENSITEAUKM pop_density
keep if regexm(nom, "^DEPARTEMENT")
gen departement = regexr(nom, "^DEPARTEMENT D[EU]?'? ?", "")
replace departement = lower(strtrim(departement))
keep departement pop_density
tempfile density
save `density'

use "$wd/q2_CIV_Section_0.dta", clear
decode b06_departemen, gen(departement)
replace departement = lower(strtrim(departement))
replace departement = "arrah" if departement == "arrha"

merge m:1 departement using `density', keep(master match) nogenerate

drop departement
save "$wd/q2_CIV_Section_0_with_density.dta", replace

***==========================================================================***
*** Q3: Enumerator Assignment based on GPS ***
***==========================================================================***

global wd "/Users/sunduss/Downloads"

use "$wd/q3_GPS Data.dta", clear

* Note: I couldn't use geodist so sorted by coordinates and assigned groups of 6 sequentially
sort latitude longitude
gen enumerator_id = ceil(_n / 6)

tab enumerator_id

save "$wd/q3_GPS_assigned.dta", replace

***==========================================================================***
*** Q4: 2010 Tanzania Election Data cleaning ***
***==========================================================================***

global wd "/Users/sunduss/Downloads/_1_data_export (1)"

import excel "$wd/q4_Tz_election_2010_raw.xls", cellrange(A5) firstrow clear

rename REGION region
rename DISTRICT district
rename COSTITUENCY constituency
rename WARD ward
rename POLITICALPARTY party
rename TTLVOTES votes_str
drop CANDIDATENAME SEX G ELECTEDCANDID~E K

foreach var of varlist region district constituency ward {
    replace `var' = `var'[_n-1] if `var' == ""
}

destring votes_str, gen(votes) force
drop votes_str
drop if party == "" | votes == .

foreach var of varlist region district constituency ward {
    replace `var' = lower(strtrim(`var'))
}

replace party = "NCCR_MAGEUZI"   if party == "NCCR-MAGEUZI"
replace party = "JAHAZIASILIA"   if party == "JAHAZI ASILIA"
replace party = "APPT_MAENDELEO" if party == "APPT - MAENDELEO"

bysort region district constituency ward: gen total_candidates_10 = _N
bysort region district constituency ward: egen ward_total_votes_10 = total(votes)

collapse (sum) votes (first) total_candidates_10 ward_total_votes_10, by(region district constituency ward party)

reshape wide votes, i(region district constituency ward) j(party) string

foreach var of varlist votes* {
    rename `var' votes_`=substr("`var'",6,.)'_10
}

gen votes_other_10 = .

sort region district constituency ward
gen ward_id_10 = _n

rename region region_10
rename district district_10
rename constituency constituency_10
rename ward ward_10

order region_10 district_10 constituency_10 ward_10 total_candidates_10 ward_total_votes_10 ward_id_10 votes_AFP_10 votes_APPT_MAENDELEO_10 votes_CCM_10 votes_CHADEMA_10 votes_CHAUSTA_10 votes_CUF_10 votes_DP_10 votes_JAHAZIASILIA_10 votes_MAKIN_10 votes_NCCR_MAGEUZI_10 votes_NLD_10 votes_NRA_10 votes_SAU_10 votes_TADEA_10 votes_TLP_10 votes_UDP_10 votes_UMD_10 votes_UPDP_10 votes_other_10

save "$wd/q4_Tz_election_2010_clean.dta", replace

***==========================================================================***
*** Q5: Tanzania PSLE data ***
***==========================================================================***

global wd "/Users/sunduss/Downloads/_1_data_export (2)"

use "$wd/q5_psle_2020_data.dta", clear
gen school_code = upper(regexs(1)) if regexm(school_code_address, "shl_(ps[0-9]+)\.htm")

preserve
    use "$wd/q5_school_location.dta", clear
    keep NECTACentreNo Ward
    rename NECTACentreNo school_code
    rename Ward ward
    duplicates drop school_code, force
    tempfile location
    save `location'
restore

merge m:1 school_code using `location', keep(master match) nogenerate

gen clean_name = regexr(schoolname, " - PS[0-9]+.*", "")
replace clean_name = lower(strtrim(clean_name))

preserve
    keep if ward == ""
    keep serial clean_name
    gen id_master = serial
    tempfile unmatched
    save `unmatched'
restore

preserve
    use "$wd/q5_school_location.dta", clear
    keep Ward School
    rename Ward ward_fuzzy
    rename School clean_name
    replace clean_name = lower(strtrim(clean_name))
    gen id_using = _n
    tempfile location_fuzzy
    save `location_fuzzy'
restore

* Note: I could not install reclink2 for some reason so I used matchit instead. 

use `unmatched', clear
matchit id_master clean_name using `location_fuzzy', idusing(id_using) txtusing(clean_name) sim(bigram) gen(score)

bysort id_master (score): keep if _n == _N
keep if score >= 0.6

merge m:1 id_using using `location_fuzzy', keep(match) nogenerate keepusing(ward_fuzzy)

keep id_master ward_fuzzy score
rename id_master serial
tempfile fuzzy_results
save `fuzzy_results'

use "$wd/q5_psle_2020_data.dta", clear
gen school_code = upper(regexs(1)) if regexm(school_code_address, "shl_(ps[0-9]+)\.htm")

merge m:1 school_code using `location', keep(master match) nogenerate
merge 1:1 serial using `fuzzy_results', keep(master match) nogenerate

replace ward = ward_fuzzy if ward == "" & ward_fuzzy != ""
drop ward_fuzzy school_code clean_name

save "$wd/q5_psle_2020_with_ward.dta", replace

***==========================================================================***
*** Q6: Tanzania Election data Merging (Bonus Question)
***==========================================================================***

global wd "/Users/sunduss/Downloads/_1_data_export (3)"

use "$wd/Tz_GIS_2015_2010_intersection.dta", clear
bysort region_gis_2017 ward_gis_2017 (percentage): keep if _n == _N
keep region_gis_2017 ward_gis_2017 region_gis_2012 ward_gis_2012 percentage
rename region_gis_2017 region_15
rename ward_gis_2017 ward_15
tempfile gis_crosswalk
save `gis_crosswalk'

use "$wd/Tz_elec_15_clean.dta", clear
merge m:1 region_15 ward_15 using `gis_crosswalk', keep(master match) nogenerate

preserve
    use "$wd/Tz_elec_10_clean.dta", clear
    keep ward_id_10 region_10 district_10 ward_10
    bysort region_10 ward_10 (ward_id_10): keep if _n == 1
    rename region_10 region_gis_2012
    rename ward_10   ward_gis_2012
    tempfile elec10
    save `elec10'
restore

merge m:1 region_gis_2012 ward_gis_2012 using `elec10', keep(master match) nogenerate

keep ward_id_15 region_15 district_15 ward_15 ward_id_10 ward_gis_2012 region_gis_2012 percentage

save "$wd/q6_ward_crosswalk_2015_2010.dta", replace




