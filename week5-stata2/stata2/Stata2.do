// QingyueChen - Stata2 assignment 
 
* Q1
clear all
set more off

cd "C:\Users\86186\Desktop\stata2"

* Load raw HTML dataset
use "q1_psle_student_raw.dta", clear

* Clean school codes
replace schoolcode = subinstr(schoolcode, "shl_", "", .)
replace schoolcode = subinstr(schoolcode, ".htm", "", .)

* Standardize HTML to uppercase
replace s = upper(s)

* Split HTML into table rows
split s, parse("<TR") gen(row)
drop s row1

gen school_row = _n
reshape long row, i(school_row schoolcode) j(student_index)
rename row s

* Keep only valid student rows
drop if s == ""
drop if strpos(s, "PS") == 0
drop if strpos(s, "CANDIDATE NO") > 0

* Candidate ID
gen pos_ps = strpos(s, "PS")
gen cand_id = ""
replace cand_id = substr(s, pos_ps, 15) if pos_ps > 0
replace cand_id = subinstr(cand_id, "<", "", .)
replace cand_id = subinstr(cand_id, ">", "", .)
replace cand_id = trim(cand_id)

* prem_number
gen prem_number = ""
gen s_after_id = s
replace s_after_id = substr(s_after_id, pos_ps + 15, .) if pos_ps > 0
replace prem_number = regexs(1) if regexm(s_after_id, ">([0-9]{8,})<")
replace prem_number = trim(prem_number)
drop s_after_id

* Gender
gen gender = ""
replace gender = "M" if strpos(s, ">M<") > 0
replace gender = "F" if strpos(s, ">F<") > 0

* NAME (robust): name is embedded in <P ...> or <FONT ...>

gen name = ""
replace name = regexs(1) if regexm(s, "P ALIGN=""LEFT"">([A-Z][A-Z ]+[A-Z])</")
replace name = regexs(1) if name=="" & regexm(s, "<P[^>]*>([A-Z][A-Z ]+[A-Z])</")
replace name = regexs(1) if name=="" & regexm(s, ">([A-Z][A-Z ]+[A-Z])</FONT>") ///
    & strpos(s, "KISWAHILI -") == 0

* Clean spaces
replace name = ustrtrim(name)
replace name = regexr(name, " +", " ")

* Subject grades
gen kiswahili = ""
gen english   = ""
gen maarifa   = ""
gen hisabati  = ""
gen science   = ""
gen uraia     = ""
gen avg_grade = ""

replace kiswahili = regexs(1) if regexm(s, "KISWAHILI - ([A-E])")
replace english   = regexs(1) if regexm(s, "ENGLISH - ([A-E])")
replace maarifa   = regexs(1) if regexm(s, "MAARIFA - ([A-E])")
replace hisabati  = regexs(1) if regexm(s, "HISABATI - ([A-E])")
replace science   = regexs(1) if regexm(s, "SCIENCE - ([A-E])")
replace uraia     = regexs(1) if regexm(s, "URAIA - ([A-E])")
replace avg_grade = regexs(1) if regexm(s, "AVERAGE GRADE - ([A-E])")

* Final cleanup
keep schoolcode cand_id prem_number gender name kiswahili english maarifa hisabati science uraia avg_grade
order schoolcode cand_id prem_number gender name kiswahili english maarifa hisabati science uraia avg_grade

drop if cand_id == ""

save "q1_psle_student_level_final.dta", replace

* Verify
list cand_id prem_number gender name kiswahili english maarifa in 1/20, abbrev(60)
count if name==""


*********************************************
 
* Q2
clear all
set more off
cd "C:\Users\86186\Desktop\stata2"

* Clean department-level data from Excel
import excel "q2_CIV_populationdensity.xlsx", sheet("Population density") firstrow clear
keep NOMCIRCONSCRI~N SUPERFICIEKM2 POPULATION DENSITEAUKM

rename NOMCIRCONSCRI~N dept_raw
rename SUPERFICIEKM2   dept_area_km2
rename POPULATION      dept_population
rename DENSITEAUKM     pop_density

* Drop header rows (not actual department names)
gen dept_upper = upper(dept_raw)
drop if regexm(dept_upper, "^(DISTRICT|REGION|DEPARTEMENT)")

* Merge key
gen dept_merge = lower(trim(itrim(dept_raw)))
replace dept_merge = subinstr(dept_merge, "'", "'", .)
replace dept_merge = subinstr(dept_merge, "  ", " ", .)

* One row per department
bysort dept_merge: keep if _n==1

keep dept_merge dept_area_km2 dept_population pop_density
tempfile deptdata
save `deptdata', replace

* Load household data & build same key
use "q2_CIV_Section_0.dta", clear

decode b06_departemen, gen(dept_merge)
replace dept_merge = lower(trim(itrim(dept_merge)))
replace dept_merge = subinstr(dept_merge, "'", "'", .)
replace dept_merge = subinstr(dept_merge, "  ", " ", .)

* Merge
merge m:1 dept_merge using `deptdata'

tab _merge
drop if _merge == 2
drop _merge

save "q2_CIV_integrated_final.dta", replace


****************************************************

* Q3 
clear all
set more off

* Load data
cd "C:\Users\86186\Desktop\stata2"
use "q3_GPS Data.dta", clear

local K = 19
local MAXSIZE = 6
local MINSIZE = floor(_N/`K')  

* Detect LAT/LON
local LAT ""
local LON ""

foreach v in latitude lat LAT Latitude y Y gps_lat GPS_lat {
    capture confirm variable `v'
    if !_rc local LAT "`v'"
    if "`LAT'" != "" continue, break
}
foreach v in longitude lon LON Longitude x X gps_lon GPS_lon {
    capture confirm variable `v'
    if !_rc local LON "`v'"
    if "`LON'" != "" continue, break
}

if "`LAT'"=="" | "`LON'"=="" {
    di as error "Cannot find latitude/longitude variables. Please set LAT/LON manually."
    exit 198
}

* Ensure unique hhid
capture confirm variable hhid
if _rc gen long hhid = _n

capture isid hhid
if _rc {
    gen long hhid2 = _n
    drop hhid
    rename hhid2 hhid
}
isid hhid, sort

* Convert degrees -> approx meters
quietly summarize `LAT', meanonly
local lat0 = r(mean)

gen double y_m = `LAT' * 110540
gen double x_m = `LON' * 111320 * cos(`lat0' * _pi/180)

* Initial clustering
capture drop enum_id
cluster kmeans x_m y_m, k(`K') iter(300) start(random) generate(enum_id)
label var enum_id "Enumerator ID (GPS-based, balanced to 5-6)"

* Balancing loop
tempfile cent mover
local maxiter = 8000

forvalues it = 1/`maxiter' {

    * unique temp vars each iteration -> never "already defined"
    tempvar gsize down dtarget

    * group sizes
    bysort enum_id: gen int `gsize' = _N
    quietly summarize `gsize', meanonly
    local max_now = r(max)
    local min_now = r(min)

    * stop
    if (`max_now' <= `MAXSIZE' & `min_now' >= `MINSIZE') {
        di as txt "Balancing finished in `it' iterations."
        continue, break
    }

    * centroids + sizes (file has cx cy sz)
    preserve
        keep enum_id x_m y_m
        collapse (mean) cx=x_m cy=y_m (count) sz=x_m, by(enum_id)
        save `cent', replace
    restore
    capture drop cx cy sz

    merge m:1 enum_id using `cent', nogen keep(match master) keepusing(cx cy sz)

    gen double `down' = sqrt((x_m-cx)^2 + (y_m-cy)^2)

    * CASE A: oversized (>MAXSIZE) -> move one OUT
    if (`max_now' > `MAXSIZE') {

        quietly levelsof enum_id if `gsize'==`max_now' & `gsize'>`MAXSIZE', local(overlist)
        local from : word 1 of `overlist'

        preserve
            keep if enum_id==`from'
            gsort -`down'
            keep in 1
            keep hhid x_m y_m
            save `mover', replace
            local move_hhid = hhid[1]
        restore

        preserve
            use `cent', clear
            keep if sz < `MAXSIZE'
            cross using `mover'
            gen double d = sqrt((cx-x_m)^2 + (cy-y_m)^2)
            sort d
            local to = enum_id[1]
        restore

        replace enum_id = `to' if hhid==`move_hhid'
    }

    * CASE B: underfilled (<MINSIZE) -> pull one IN
    else if (`min_now' < `MINSIZE') {

        quietly levelsof enum_id if `gsize'==`min_now' & `gsize'<`MINSIZE', local(underlist)
        local to : word 1 of `underlist'

        * get centroid for underfilled group
        preserve
            use `cent', clear
            keep if enum_id==`to'
            local tcx = cx[1]
            local tcy = cy[1]
        restore

        gen double `dtarget' = sqrt((x_m-`tcx')^2 + (y_m-`tcy')^2)
        gsort `dtarget'

        * move the closest household from a donor group (>MINSIZE)
        quietly replace enum_id = `to' if `gsize'>`MINSIZE' & _n==1
    }

    * clean centroid vars to avoid merge collisions next iteration
    drop cx cy sz
}

* Final checks
bysort enum_id: gen final_n = _N
tab final_n
tab enum_id

sort enum_id hhid
list enum_id `LAT' `LON' hhid in 1/60

save "q3_GPS_Balanced_Final.dta", replace

*********************************************

* Q4
clear all
set more off
cd "C:\Users\86186\Desktop\stata2"

* Import raw Excel data
import excel "q4_Tz_election_2010_raw.xls", sheet("Sheet1") cellrange(A5) firstrow clear

* Clean variable names
rename REGION region_10
rename DISTRICT district_10
rename COSTITUENCY constituency_10
rename WARD ward_10
rename POLITICALPARTY party
rename TTLVOTES votes_str

* Convert votes to numeric
destring votes_str, gen(votes) ignore(",") force
drop votes_str

* Remove empty rows
drop if party == "" & votes == .

* Fill in the "Merged Cell" gaps (Fill-down logic)
foreach var of varlist region_10 district_10 constituency_10 ward_10 {
    replace `var' = `var'[_n-1] if `var' == "" | `var' == "."
}

* Handle Reshape Error: Aggregate votes by party per ward
collapse (sum) votes, by(region_10 district_10 constituency_10 ward_10 party)

* Calculate summary variables for the template
egen total_candidates = count(party), by(region_10 district_10 constituency_10 ward_10)
egen ward_total_votes = sum(votes), by(region_10 district_10 constituency_10 ward_10)

* Prepare party names for variable headers
replace party = subinstr(party, " ", "_", .)
replace party = subinstr(party, "-", "_", .)

* Reshape from LONG to WIDE
reshape wide votes, i(region_10 district_10 constituency_10 ward_10 total_candidates ward_total_votes) j(party) string

* Final formatting to match template
rename votes* votes_*
egen ward_id_10 = group(region_10 district_10 constituency_10 ward_10)

* Order variables like the template provided
order region_10 district_10 constituency_10 ward_10 total_candidates ward_total_votes ward_id_10

* Save final dataset
save "q4_Tz_election_cleaned_final.dta", replace

* Verify output
list in 1/10

*********************************************

* Q5
clear all
set more off
cd "C:\Users\86186\Desktop\stata2"

* Prepare the Location Data
use "q5_school_location.dta", clear

* Standardize the NECTA Center Number to match the PSLE format
rename NECTACentreNo necta_code
replace necta_code = lower(trim(necta_code))

* Keep only the key and the Ward info
keep necta_code Ward
duplicates drop necta_code, force

tempfile location_cleaned
save `location_cleaned'

* Prepare the PSLE Data
use "q5_psle_2020_data.dta", clear

* CRITICAL STEP: Extract the NECTA code from the HTML path
gen necta_code = school_code_address

* Remove the prefix and the extension to leave only the code
replace necta_code = subinstr(necta_code, "shl_", "", .)
replace necta_code = subinstr(necta_code, ".htm", "", .)
replace necta_code = lower(trim(necta_code))

* Perform the Merge
merge 1:1 necta_code using `location_cleaned'

* Finalize per Q5 requirements (N = 17,329)
drop if _merge == 2
tab _merge

* Clean up variables
rename Ward ward
drop _merge necta_code

* Save and Verify
save "q5_psle_with_wards_final.dta", replace
count
list schoolname ward in 1/20

*********************************************

* Q6
clear all
set more off

* Set the working directory
cd "C:\Users\86186\Desktop\stata2"

* Prepare the GIS Crosswalk (Parent-Child mapping)
use "Tz_GIS_2015_2010_intersection.dta", clear

* Sort by 2015 ward and overlap percentage
gsort + ward_gis_2017 - percentage

* Keep only the best parent match for each 2015 geographic unit
by ward_gis_2017: keep if _n == 1

* Rename variables to match standard template naming
rename ward_gis_2017 ward_15
rename ward_gis_2012 ward_10
rename region_gis_2017 region_15
rename district_gis_2017 district_15
rename region_gis_2012 region_10
rename district_gis_2012 district_10

* Standardize all text keys to lowercase and trim spaces
foreach var of varlist region_15 district_15 ward_15 region_10 district_10 ward_10 {
    replace `var' = lower(trim(itrim(`var')))
}

keep ward_15 region_15 district_15 ward_10 region_10 district_10
tempfile crosswalk
save `crosswalk'

* Load 2015 Election Results (Master File)
use "Tz_elec_15_clean.dta", clear

* Standardize master keys to match crosswalk
foreach var of varlist region_15 district_15 ward_15 {
    replace `var' = lower(trim(itrim(`var')))
}

* Merge with Crosswalk to identify the 2010 Parent Ward
merge 1:1 region_15 district_15 ward_15 using `crosswalk'

* Keep only the 3,944 observations from 2015
drop if _merge == 2
drop _merge

* Final Merge: Bring in 2010 Election Results
preserve
    use "Tz_elec_10_clean.dta", clear
    foreach var of varlist region_10 district_10 ward_10 {
        replace `var' = lower(trim(itrim(`var')))
    }
    tempfile election_10_std
    save `election_10_std'
restore

* Match the standardized 2010 results using the full geographic key
merge m:1 region_10 district_10 ward_10 using `election_10_std'

* Cleanup and Save
drop if _merge == 2
tab _merge
save "Tz_Election_Integrated_Final_Clean.dta", replace