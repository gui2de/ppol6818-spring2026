cd "C:\Users\yzqri\Downloads"

********Question 1*********

clear all
set more off

use q1_psle_student_raw.dta, clear

* 1) Load the new raw dataset (school-level; HTML stored in s)
confirm variable schoolcode
confirm variable s

* 2) Postfile container (student-level)
tempname H
tempfile out

postfile `H' ///
    str15 schoolcode ///
    str20 cand_id ///
    str1  gender ///
    str20 prem_number ///
    str80 name ///
    str1  kiswahili ///
    str1  english ///
    str1  maarifa ///
    str1  hisabati ///
    str1  science ///
    str1  uraia ///
    str1  average ///
    using `out', replace

* 3) Same row pattern as your old code (kept as-is)
local rowpat "<TR><TD[^>]*>[^<]*<FONT[^>]*><P[^>]*>(PS[0-9]+-[0-9]+)</FONT></TD>.*?<P[^>]*>([0-9]+)</FONT></TD>.*?<P[^>]*>([MF])</FONT></TD>.*?<P>([^<]+)</FONT></TD>.*?<P[^>]*>([^<]*Average Grade[^<]*)</FONT>"

* 4) Loop over schools (each obs)
quietly count
local N = r(N)

forvalues i = 1/`N' {

    * Pull school code from dataset
    local scode = schoolcode[`i']

    * Create a 1-row temp "rest" like your original approach
    preserve
        keep in `i'
        keep schoolcode s
        gen strL rest = s

        * ---- Clean common issues in s ----
        * Some s values may be like b'....' (Python bytes repr). Remove wrapper if present.
        quietly {
            replace rest = subinstr(rest, "b'", "", 1) if substr(rest,1,2)=="b'"
            replace rest = substr(rest, 1, length(rest)-1) if substr(rest, -1, 1)=="'"
        }

        * Remove literal escaped BOM if present
        replace rest = subinstr(rest, "\xef\xbb\xbf", "", .)

        * Normalize whitespace (same as your code)
        replace rest = ustrregexra(rest, "[\r\n\t]+", " ")
        replace rest = ustrregexra(rest, "\s+", " ")
        replace rest = strtrim(rest)

        * ---- Extract student rows ----
        while ustrregexm(rest[1], "`rowpat'") {

            local cand = ustrregexs(1)
            local prem = ustrregexs(2)
            local sex  = ustrregexs(3)
            local nm   = ustrtrim(ustrregexs(4))
            local gstr = ustrtrim(ustrregexs(5))

            * schoolcode from cand (same logic you used)
            local sc = ustrregexra("`cand'", "-.*$", "")

            * If you'd rather trust dataset schoolcode, uncomment next line:
            * local sc "`scode'"

            * Grades
            local kis ""
            local eng ""
            local maa ""
            local his ""
            local sci ""
            local ura ""
            local avg ""

            if ustrregexm("`gstr'", "Kiswahili\s*-\s*([A-Z])")      local kis = ustrregexs(1)
            if ustrregexm("`gstr'", "English\s*-\s*([A-Z])")        local eng = ustrregexs(1)
            if ustrregexm("`gstr'", "Maarifa\s*-\s*([A-Z])")        local maa = ustrregexs(1)
            if ustrregexm("`gstr'", "Hisabati\s*-\s*([A-Z])")       local his = ustrregexs(1)
            if ustrregexm("`gstr'", "Science\s*-\s*([A-Z])")        local sci = ustrregexs(1)
            if ustrregexm("`gstr'", "Uraia\s*-\s*([A-Z])")          local ura = ustrregexs(1)
            if ustrregexm("`gstr'", "Average Grade\s*-\s*([A-Z])")  local avg = ustrregexs(1)

            post `H' ("`sc'") ("`cand'") ("`sex'") ("`prem'") ("`nm'") ///
                     ("`kis'") ("`eng'") ("`maa'") ("`his'") ("`sci'") ("`ura'") ("`avg'")

            * Drop the matched chunk so the loop can find the next student
            local match = ustrregexs(0)
            local pos = ustrpos(rest[1], "`match'")
            replace rest = usubstr(rest, `pos' + ustrlen("`match'"), .) in 1
        }
    restore
}

postclose `H'

* 5) Finalize output dataset
use `out', clear
order schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average
compress

count
list in 1/10, noobs

save "q6_student_level_138.dta", replace
export delimited using "q6_student_level_138.csv", replace

display "Done: q6_student_level_138.dta and q6_student_level_138.csv"


****************Question 2*************************

clear all
set more off

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


**************Question 3******************

clear all
set more off

use "C:\Users\yzqri\Downloads\q3_GPS Data.dta", clear

local K = 19
local MAXSIZE = 6

local LAT ""
local LON ""

foreach v in latitude lat LAT Latitude y Y gps_lat {
    capture confirm variable `v'
    if !_rc local LAT "`v'"
    if "`LAT'" != "" continue, break
}
foreach v in longitude lon LON Longitude x X gps_lon {
    capture confirm variable `v'
    if !_rc local LON "`v'"
    if "`LON'" != "" continue, break
}

if "`LAT'"=="" | "`LON'"=="" {
    di as error "Cannot find latitude/longitude variables. Please set LAT/LON manually."
    exit 198
}

capture confirm variable hhid
if _rc {
    gen long hhid = _n
}
isid hhid, sort

*----------------------------
* 4) Convert degrees -> approx meters (for Euclidean distance)
*----------------------------
quietly summarize `LAT'
local lat0 = r(mean)

gen double y_m = `LAT' * 110540
gen double x_m = `LON' * 111320 * cos(`lat0' * _pi/180)


* 5) Initial spatial clustering (kmeans) 
cluster kmeans x_m y_m, k(`K') iter(300) start(random) generate(enum_id)

label var enum_id "Enumerator ID (GPS-based)"


*----------------------------
* 6) Balancing: ensure each enumerator has <= MAXSIZE households (robust)
*----------------------------
tempfile cent mover

while 1 {

    * 
    cap drop _sz cx cy d_own

    * 
    bysort enum_id: gen int _sz = _N
    quietly summarize _sz, meanonly
    local max_now = r(max)

    * 
    if (`max_now' <= `MAXSIZE') {
        drop _sz
        exit
    }

    * 
    preserve
        keep enum_id x_m y_m
        collapse (mean) cx=x_m cy=y_m (count) sz=x_m, by(enum_id)
        save `cent', replace
    restore

    * 
    merge m:1 enum_id using `cent', nogen keep(match master)

    gen double d_own = sqrt((x_m-cx)^2 + (y_m-cy)^2)
    bysort enum_id: replace _sz = _N

    * 
    quietly levelsof enum_id if _sz>`MAXSIZE', local(overlist)
    local from : word 1 of `overlist'

    * 
    preserve
        keep if enum_id==`from'
        gsort -d_own
        keep in 1
        keep hhid x_m y_m
        save `mover', replace
        local move_hhid = hhid[1]
    restore

    * 
    preserve
        use `cent', clear
        keep if sz < `MAXSIZE'
        cross using `mover'
        gen double d = sqrt((cx-x_m)^2 + (cy-y_m)^2)
        sort d
        local to = enum_id[1]
    restore

    * 
    replace enum_id = `to' if hhid==`move_hhid'

    * 
    cap drop cx cy d_own _sz
}

*----------------------------
* 7) Final checks
*----------------------------
bysort enum_id: gen final_n = _N
tab final_n
sort enum_id hhid


**************Question 4***************

clear all
set more off

import excel "q4_Tz_election_2010_raw.xls", sheet("Sheet1") cellrange(A5) firstrow clear

*rename these variables as the sample
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

* Prepare party names
replace party = subinstr(party, " ", "_", .)
replace party = subinstr(party, "-", "_", .)

reshape wide votes, i(region_10 district_10 constituency_10 ward_10 total_candidates ward_total_votes) j(party) string

* Final formatting
rename votes* votes_*
egen ward_id_10 = group(region_10 district_10 constituency_10 ward_10)

* New order
order region_10 district_10 constituency_10 ward_10 total_candidates ward_total_votes ward_id_10


save "q4_Tz_election_cleaned_final.dta", replace

***************Question 5*****************

clear all
set more off

use "C:\Users\yzqri\Downloads\q5_school_location.dta", clear

rename NECTACentreNo necta_code
replace necta_code = lower(trim(necta_code))

keep necta_code Ward
duplicates drop necta_code, force

tempfile location_cleaned
save `location_cleaned'

use "C:\Users\yzqri\Downloads\q5_psle_2020_data.dta", clear

gen necta_code = school_code_address
replace necta_code = subinstr(necta_code, "shl_", "", .)
replace necta_code = subinstr(necta_code, ".htm", "", .)
replace necta_code = lower(trim(necta_code)) //Exact the school code.

merge 1:1 necta_code using `location_cleaned'

*Merge results: merge=1  no ward data
*               merge=2  no original school
*               merge=3  completely matched


drop if _merge == 2
tab _merge  // Now we have 17,329 observations in total.

save "q5_psle_with_wards_final.dta", replace


*************Question 6************

clear all
set more off
use "C:\Users\yzqri\Downloads\Tz_GIS_2015_2010_intersection.dta", clear

* Sort by 2015 ward and overlap percentage
gsort + ward_gis_2017 - percentage

* Keep only the best parent match for each 2015 geographic unit
by ward_gis_2017: keep if _n == 1

* Rename variables
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

use "Tz_elec_15_clean.dta", clear
foreach var of varlist region_15 district_15 ward_15 {
    replace `var' = lower(trim(itrim(`var')))
}

* Merge 
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

* Match using crosswalk
merge m:1 region_10 district_10 ward_10 using `election_10_std'

drop if _merge == 2
tab _merge
save "Tz_Election_Integrated_Final_Clean.dta", replace


