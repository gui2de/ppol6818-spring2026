* ── Q1.─────────────────────────────
cd "/Users/anu/Downloads/"
use "q1_psle_student_raw.dta", clear

* Collapse all whitespace
replace s = ustrregexra(s, "[\r\n\s]+", " ")

* Replace HTML non-breaking space entities
replace s = subinstr(s, "&nbsp;", " ", .)

* Insert our custom delimiter
replace s = ustrregexra(s, "(?i)</tr>", "</TR>||END||")

* Create a numeric school identifier
gen long school_id = _n

* Split based on our custom delimiter
split s, parse("||END||") gen(part)
drop s

reshape long part, i(school_id) j(j)

* Drop empty rows
drop if missing(part) | part == " " | part == ""

* Keep only student rows
keep if ustrregexm(part, "PS[0-9]{7}-[0-9]{4}")

* Extract student demographics 
gen can_id = ustrregexs(1) if ustrregexm(part, "(PS[0-9]{7}-[0-9]{4})")
gen school_code = substr(can_id, 1, strpos(can_id, "-") - 1)
gen pre_num = ustrregexs(1) if ustrregexm(part, "([0-9]{10,})")
gen gender = ustrregexs(1) if ustrregexm(part, ">([MF])<")
gen fullname = ustrregexs(1) if ustrregexm(part, "<P>([^<]+)</FONT>")

* Extract subject grades 
gen swahili = ustrregexs(1) if ustrregexm(part, "(?i)Kiswahili - ([A-Z])")
gen eng   = ustrregexs(1) if ustrregexm(part, "(?i)English - ([A-Z])")
gen maarifa   = ustrregexs(1) if ustrregexm(part, "(?i)Maarifa - ([A-Z])")  
gen hisabati  = ustrregexs(1) if ustrregexm(part, "(?i)Hisabati - ([A-Z])") 
gen science   = ustrregexs(1) if ustrregexm(part, "(?i)Science - ([A-Z])")
gen uraia     = ustrregexs(1) if ustrregexm(part, "(?i)Uraia - ([A-Z])")   
gen avg   = ustrregexs(1) if ustrregexm(part, "(?i)Average Grade - ([A-Z])")

*  Keep only the variables we need
keep school_code can_id gender pre_num fullname swahili eng maarifa hisabati science uraia avg

drop if missing(can_id) | missing(fullname)

* Save dataset
save "q1_psle_student_clean.dta", replace
di _n "Saved: q1_psle_student_clean.dta"


* ── Q2.─────────────────────────────

* Import and Clean Population Density Data
import excel "/Users/anu/Downloads/q2_CIV_populationdensity.xlsx", firstrow clear

* We identify département rows by the presence of the word "departement"
keep if strpos(lower(NOMCIRCONSCRIPTION), "departement")

* Create a lower-case key variable to match against the household data
gen dept_name = lower(trim(NOMCIRCONSCRIPTION))

* Strip the administrative prefix from each département name.
foreach prefix in "departement d' " "departement d'" "departement de " "departement du " {
    replace dept_name = subinstr(dept_name, "`prefix'", "", 1)
}

replace dept_name = trim(dept_name)

rename DENSITEAUKM pop_density_km2
label var pop_density_km2 "Population density (persons per km²)"

* Keep only the merge key and the target variable
keep dept_name pop_density_km2

duplicates drop dept_name, force

tempfile density_data
save `density_data'

* Check
list dept_name pop_density_km2, clean noobs

* Load Household Data
use "q2_CIV_Section_0.dta", clear

* b06_departemen is a numeric labelled (encoded) variable.
decode b06_departemen, gen(dept_name)
replace dept_name = lower(trim(dept_name))

* Correct the two spelling discrepancies  between the DTA value labels and the
replace dept_name = "arrah"    if dept_name == "arrha"
replace dept_name = "gbeleban" if dept_name == "gbelegban"

* Merge 
merge m:1 dept_name using `density_data', keep(1 3) nogen

* Post-Merge Check
count if missing(pop_density_km2)

summ pop_density_km2, detail

* Save dataset
save "q2_finaldataset.dta", replace
di _n "Saved: q2_finaldataset.dta"


* ── Q3.─────────────────────────────

use "q3_GPS_Data.dta", clear

local num_enumerators = 19      // total enumerators available
local survey_days     = 1       // days allocated for this village

* total clusters needed
local clusters = `num_enumerators' * `survey_days'

* Divide village into latitude strips
local lat_segments = ceil(sqrt(`clusters'))
egen lat_group = cut(latitude), group(`lat_segments')

*  Create longitude direction
gen lon_order = longitude
replace lon_order = -longitude if mod(lat_group,2)==1

sort lat_group lon_order

* Assign households sequentially to clusters
gen cluster_id = ceil(_n * `clusters' / _N)

* Convert clusters into enumerator assignments
gen enumerator_id = mod(cluster_id - 1, `num_enumerators') + 1

drop lat_group lon_order cluster_id
sort enumerator_id

tab enumerator_id

* Save dataset
save "q3_GPS_Data_clean.dta", replace
di _n "Saved: q3_GPS_Data_clean.dta"


* ── Q4.─────────────────────────────

* Import Excel sheet 
local raw_xls "/Users/anu/Downloads/q4_Tz_election_2010_raw.xls"

* create temp storage dataset
tempfile combined
save `combined', emptyok replace

foreach sh in Sheet1 {

    import excel using "`raw_xls'", sheet("`sheet'") clear

     * Rename by column position
    rename (A B C D H I) (region district constituency ward party_name vote_count)

	 * Fill down Geography columns
    foreach locvar in region district constituency ward {
        replace `locvar' = `locvar'[_n-1] if missing(`locvar') | trim(`locvar')==""
    }

     * Drop non-data rows 
    drop if missing(party_name)
    drop if party_name == "POLITICAL PARTY" | party_name == "SEX"

     * Clean the Votes variable 
    capture confirm string variable vote_count
    if !_rc {
        replace vote_count = subinstr(vote_count,",","",.)
        replace vote_count = "0" if vote_count=="UN OPPOSSED"
        destring vote_count, replace force
    }

    replace vote_count = 0 if missing(vote_count)

    * Clean Party Names
	replace party_name = trim(party_name)

	* remove rows that are not actual party observations
	drop if missing(party_name)
	drop if party_name == "" 
	drop if party_name == "POLITICAL PARTY"
	drop if party_name == "SEX"

    * Create a valid variable-name code
    gen party_id = ustrregexra(party_name,"[^a-zA-Z0-9]","")

	* ensure reshape variable has no missing values
	drop if missing(party_id) | party_id==""

	* combine duplicates if a party appears multiple times in a ward
	collapse (sum) vote_count, by(region district constituency ward party_id)

	* Reshape Long → Wide
	reshape wide vote_count, i(region district constituency ward) j(party_id) string

    * append cleaned sheet
    append using `combined'
    save `combined', replace
}

* Load Combined Data
use `combined', clear


* rename vote columns to match template year format
foreach v of varlist vote_count* {
    rename `v' `v'_2010
}

* Calculate Summary Variables
egen ward_votes_total_2010 = rowtotal(vote_count*)
egen parties_contesting_2010 = rownonmiss(vote_count*)


* Save dataset
save "q4_clean_tanzania_election_2010.dta", replace
di _n "Saved: q4_clean_tanzania_election_2010.dta"


* ── Q5.─────────────────────────────

* Prepare the School Registry (Location) Dataset
use "q5_school_location.dta", clear

* Normalise the join keys
* NECTA code:
gen necta_key = upper(trim(NECTACentreNo))

* Region:
gen reg_key = upper(trim(Region))

* Council → district key:
gen dist_key = upper(trim(regexr(Council, "\([^)]*\)", "")))

* School name key:
gen sch_key = upper(ustrregexra(School, "\r|\n|PRIMARY SCHOOL", " "))
replace sch_key = itrim(trim(ustrregexra(sch_key, "[^A-Z0-9 ]", " ")))

* Keep only the columns needed for merging
rename Ward ward

* Save Pass 2 tempfile
preserve
    duplicates drop reg_key dist_key sch_key, force
    tempfile loc_by_name
    save "`loc_by_name'"
restore

* Save Pass 1 tempfile
* Drop rows where NECTA is missing
keep if necta_key != "" & necta_key != "N/A"
duplicates drop necta_key, force
tempfile loc_by_necta
save "`loc_by_necta'"

* Load PSLE Data
use "q5_psle_2020_data.dta", clear

* Extract NECTA code from PSLE data
gen necta_key = upper(regexs(0)) if regexm(lower(school_code_address), "(ps[0-9]+)")

replace necta_key = upper(regexs(0)) if missing(necta_key) & regexm(lower(schoolname), "(ps[0-9]+)")

* Merge the datasets
merge m:1 necta_key using "`loc_by_necta'", keepusing(ward) keep(1 3) nogen

* Normalise PSLE name fields for Pass 2
gen reg_key  = upper(trim(region_name))
gen dist_key = upper(trim(regexr(district_name, "\([^)]*\)", "")))

* School name: 
gen sch_key = upper(regexr(schoolname, "\s*-\s*PS[0-9]+.*$", ""))
replace sch_key = ustrregexra(sch_key, "\r|\n|PRIMARY SCHOOL", " ")
replace sch_key = itrim(trim(ustrregexra(sch_key, "[^A-Z0-9 ]", " ")))

* PASS 2: Join
merge m:1 reg_key dist_key sch_key using "`loc_by_name'", update keepusing(ward) keep(1 3 4 5) nogen

* Drop all temporary key variables
drop necta_key reg_key dist_key sch_key

* Verify row count is unchanged
count

* Compress to reduce file size
compress

* Save dataset
save "q5_finaldataset.dta", replace
di _n "Saved: q5_finaldataset.dta"


* ── Q6.─────────────────────────────

* Prepare 2015 election dataset 
use "Tz_elec_15_clean.dta", clear

collapse (first) ward_id_15 district_15 total_candidates_15 ward_total_votes_15, by(region_15 ward_15)

tempfile elec15
save `elec15'

* Prepare 2010 election dataset
use "Tz_elec_10_clean.dta", clear

collapse (first) ward_id_10 district_10 total_candidates_10 ward_total_votes_10, by(region_10 ward_10)

tempfile elec10
save `elec10'

* Load intersection dataset
use "Tz_GIS_2015_2010_intersection.dta", clear

keep region_gis_2017 ward_gis_2017 region_gis_2012 ward_gis_2012 percentage

rename region_gis_2017 region_15
rename ward_gis_2017   ward_15
rename region_gis_2012 region_10
rename ward_gis_2012   ward_10

* Merge 2015 election data
merge m:1 region_15 ward_15 using `elec15', keepusing(ward_id_15 district_15 total_candidates_15 ward_total_votes_15) keep(1 3) nogen

* Merge 2010 election data
merge m:1 region_10 ward_10 using `elec10', keepusing(ward_id_10 district_10 total_candidates_10 ward_total_votes_10) keep(1 3) nogen

bysort ward_id_15 (percentage): keep if _n == _N

*Identify wards that split
bysort ward_id_10: gen n_2015_children = _N

sort ward_id_15
count

* Save dataset
save "q6_ward_2015_2010.dta", replace
di _n "Saved: q6_ward_2015_2010.dta"


