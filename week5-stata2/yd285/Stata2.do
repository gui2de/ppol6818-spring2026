clear all
cd "C:\Users\ASUS\Desktop\research_design\assignments\stata2\01_data"

*Q1
****************************************************
* Inputs: q1_psle_student_raw.dta
* Outputs: psle2021_student_level.dta + .csv
****************************************************
clear all
set more off

use "q1_psle_student_raw.dta", clear
rename schoolcode schoolfile   // avoid name conflict later
assert !missing(s)

tempfile oneSchool allstudents
save `oneSchool', replace

* empty master dataset
clear
set obs 0
gen str30 schoolcode  = ""
gen str30 cand_id     = ""
gen str1  gender      = ""
gen str30 prem_number = ""
gen str120 name       = ""
gen str1  kiswahili   = ""
gen str1  english     = ""
gen str1  maarifa     = ""
gen str1  hisabati    = ""
gen str1  science     = ""
gen str1  uraia       = ""
gen str1  average     = ""
save `allstudents', replace

use `oneSchool', clear
local N = _N

forvalues i = 1/`N' {

    preserve
        keep in `i'

        * Working HTML
        gen strL html = s

        * Strip wrapper b'...' if present
        replace html = substr(html, 3, .) if substr(html,1,2)=="b'"
        replace html = substr(html, 1, ustrlen(html)-1) if substr(html, ustrlen(html), 1)=="'"

        * Remove BOM if present as escapes
        replace html = subinstr(html, "\xef\xbb\xbf", "", .)

        * clean whitespace 
        replace html = ustrregexra(html, "[\r\n\t]+", " ")
        replace html = ustrregexra(html, "\s+", " ")
        replace html = ustrtrim(html)

        * focus from student section if possible
        gen long p = strpos(html, "CAND. NO")
        if p>0 replace html = substr(html, p, .)
        drop p

        * Split into <TR> rows using </TR> as separator
        gen strL tr = html
        replace tr = ustrregexra(tr, "</TR>", "<<<ROW>>>")
        replace tr = ustrregexra(tr, "</tr>", "<<<ROW>>>")

        split tr, parse("<<<ROW>>>") gen(r)
        drop tr html s

        gen id = 1
        reshape long r, i(id) j(k)
        drop if missing(r)
        replace r = ustrtrim(r)

        * keep only rows that contain a candidate id
        keep if ustrregexm(r, "PS[0-9]+-[0-9]+")
        rename r rowhtml
        drop id k

        * ---- Extract fields 
        gen cand_id = ustrregexs(1) if ustrregexm(rowhtml, "(PS[0-9]+-[0-9]{3,5})")
        gen schoolcode = ustrregexs(1) if ustrregexm(cand_id, "^(PS[0-9]+)")

        gen prem_number = ustrregexs(1) if ustrregexm(rowhtml, "PS[0-9]+-[0-9]{3,5}.*?<P[^>]*>\s*([0-9]{6,})\s*</")
        gen gender      = ustrregexs(1) if ustrregexm(rowhtml, ">\s*([MF])\s*</")
        gen name        = ustrregexs(1) if ustrregexm(rowhtml, "([A-Z][A-Z '.-]{3,})\s*</")
        replace name = ustrtrim(name)

        gen kiswahili = ustrregexs(1) if ustrregexm(rowhtml, "Kiswahili\s*-\s*([A-Z])")
        gen english   = ustrregexs(1) if ustrregexm(rowhtml, "English\s*-\s*([A-Z])")
        gen maarifa   = ustrregexs(1) if ustrregexm(rowhtml, "Maarifa\s*-\s*([A-Z])")
        gen hisabati  = ustrregexs(1) if ustrregexm(rowhtml, "Hisabati\s*-\s*([A-Z])")
        gen science   = ustrregexs(1) if ustrregexm(rowhtml, "Science\s*-\s*([A-Z])")
        gen uraia     = ustrregexs(1) if ustrregexm(rowhtml, "Uraia\s*-\s*([A-Z])")
        gen average   = ustrregexs(1) if ustrregexm(rowhtml, "Average Grade\s*-\s*([A-Z])")

        keep schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average
        order schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average
        compress

        tempfile part
        save `part', replace
    restore

    use `allstudents', clear
    append using `part'
    save `allstudents', replace

    if mod(`i',10)==0 {
        di as text "Processed schools: `i' / `N'  | students so far: " _N
    }

    use `oneSchool', clear
}

use `allstudents', clear
compress
save "psle2021_student_level.dta", replace
export delimited using "psle2021_student_level.csv", replace
di as text "Done -> psle2021_student_level.dta / .csv"

*Q2
*******************************************************
* Inputs: q2_CIV_Section_0.dta, q2_CIV_populationdensity.xlsx
* Outputs: CIV_Section_0_merged.dta
*******************************************************

clear all
set more off 

local hh_dta    "q2_CIV_Section_0.dta"
local dens_xlsx "q2_CIV_populationdensity.xlsx"
local out_dta   "CIV_Section_0_merged.dta"


* create a cleaned string key for merging

capture program drop make_key
program define make_key
    syntax varname(string) , genname(name)

    gen strL `genname' = ustrlower(ustrtrim(`varlist'))
    replace `genname' = ustrnormalize(`genname', "nfd")
    replace `genname' = ustrregexra(`genname', "\p{M}", "")     // remove diacritics
    replace `genname' = subinstr(`genname', char(160), " ", .)  // NBSP -> space
    replace `genname' = ustrregexra(`genname', "\s+", " ")
    replace `genname' = ustrtrim(`genname')
end

*=====================================================*
* A) Prepare Excel density data (keep DEPARTEMENT rows only)
*=====================================================*
tempfile dens_clean

import excel "`dens_xlsx'", firstrow clear
compress

rename NOMCIRCONSCRIPTION nom_circ
rename DENSITEAUKM        pop_density

* Build a cleaned key for filtering "DEPARTEMENT ..."
make_key nom_circ, genname(nom_key_raw)

keep if regexm(nom_key_raw, "^(departement)\b")

* Remove "departement de/du/d'/des ..." prefix to get department name
gen str80 dept_name = nom_key_raw
replace dept_name = ustrregexra(dept_name, "^departement\s+(d'|de|du|des)\s+", "")
replace dept_name = ustrregexra(dept_name, "^departement\s+", "")
replace dept_name = ustrtrim(dept_name)

* Ensure density is numeric
capture confirm numeric variable pop_density
if _rc!=0 {
    destring pop_density, replace ignore(" ,")
}

* Create merge key and ensure it is not strL
make_key dept_name, genname(dept_key)
recast str dept_key
keep dept_key pop_density dept_name
duplicates report dept_key
duplicates drop dept_key, force

save `dens_clean', replace

*=====================================================*
* B) Prepare household data (decode value labels to strings)
*=====================================================*
use "`hh_dta'", clear
compress

* Department variable is numeric with value labels
describe b06_departemen

* Convert value labels to strings (e.g., "abidjan")
decode b06_departemen, gen(dept_name_hh)

* Create the same merge key
make_key dept_name_hh, genname(dept_key)

*=====================================================*
* C) Merge density into household data
*=====================================================*
recast str dept_key
merge m:1 dept_key using `dens_clean'
tab _merge

keep if _merge==1 | _merge==3
drop _merge

save "`out_dta'", replace
display "Saved merged file: `out_dta'"

* Q3 — Input: q3_GPS Data.dta
clear all
set more off
use "q3_GPS Data.dta", clear

* A) Initial assignment: k-means clustering into 19 geographic groups
cluster kmeans latitude longitude, k(19) name(enum_id) start(krandom) iterate(100) 
tab enum_id

* B) Balance group sizes to ~6 households each (111 = 16*6 + 3*5)
*    Set three groups to have cap=5; all others cap=6
local maxiter = 1000

forvalues it = 1/`maxiter' {

    * Stop if every group size is 5 or 6
    bys en: gen n = _N
    quietly count if !inlist(n,5,6)
    if r(N)==0 {
        di "Done at iteration `it'"
        drop n
        exit
    }
    drop n

    * Recompute caps each iteration (cap depends on current group membership)
    tempvar cap gsize c_lat c_lon d2 mover
    gen byte `cap' = 6
    replace `cap' = 5 if inlist(en,17,18,19)

    * Group sizes and centroids
    bys en: gen int `gsize' = _N
    bys en: egen double `c_lat' = mean(latitude)
    bys en: egen double `c_lon' = mean(longitude)

    * Pick one over-cap group
    quietly levelsof en if `gsize' > `cap', local(over)
    local g : word 1 of `over'

    * Select the farthest household from its group centroid (tie-break by id)
    gen double `d2' = (latitude-`c_lat')^2 + (longitude-`c_lon')^2
    gen byte `mover' = 0
    gsort en -`d2' id
    by en: replace `mover' = 1 if en==`g' & _n==1

    * Coordinates of the household to move
    quietly summarize latitude if `mover', meanonly
    local mlat = r(mean)
    quietly summarize longitude if `mover', meanonly
    local mlon = r(mean)

    * Find the nearest under-cap group centroid and move the household there
    preserve
        keep en latitude longitude
        collapse (mean) clat=latitude clon=longitude (count) n=latitude, by(en)

        gen byte capg = 6
        replace capg = 5 if inlist(en,17,18,19)
        keep if n < capg

        gen double dist2 = (`mlat'-clat)^2 + (`mlon'-clon)^2
        sort dist2
        local target = en[1]
    restore

    replace en = `target' if `mover'
}

* Final group sizes (16 groups of 6 and 3 groups of 5)
tab en

*Q4
*******************************************************
* Inputs: q4_Tz_election_2010_raw.xls
* Outputs: tz_election_2010_wide.dta, tz_election_2010_wide.xlsx
*******************************************************

clear all
set more off
global in  "q4_Tz_election_2010_raw.xls"
global out "./"

*******************************************************
* 1) Import raw sheet (read everything as strings)
*******************************************************
import excel using "$in", sheet(Sheet1) allstring clear

*******************************************************
* 2) Locate the true header row and re-import from there
*******************************************************
gen long _row = _n
gen byte _hit = regexm(upper(trim(A)), "REGION")

quietly summarize _row if _hit
local headerrow = r(min)

display "headerrow = `headerrow'"

clear
import excel using "$in", sheet(Sheet1) cellrange(A`headerrow':J7927) firstrow clear

*******************************************************
* 3) Standardize variable names and align key columns
*******************************************************
ds
foreach v of varlist _all {
    local nv = lower("`v'")
    local nv = subinstr("`nv'"," ","_",.)
    local nv = subinstr("`nv'","-","_",.)
    rename `v' `nv'
}

capture confirm variable region
if _rc {
    * rename region_name region
}
capture confirm variable district
if _rc {
    * rename district_name district
}
capture confirm variable constituency
if _rc {
    * rename constituency_name constituency
}
capture confirm variable ward
if _rc {
    * rename ward_name ward
}
capture confirm variable political_party
if _rc {
    capture confirm variable politicalparty
    if !_rc rename politicalparty political_party
    capture confirm variable party
    if !_rc rename party political_party
}
capture confirm variable ttl_votes
if _rc {
    capture confirm variable ttlvotes
    if !_rc rename ttlvotes ttl_votes
    capture confirm variable totalvotes
    if !_rc rename totalvotes ttl_votes
    capture confirm variable votes
    if !_rc rename votes ttl_votes
}

*******************************************************
* 4) Basic cleaning: numeric votes, drop blanks, forward-fill IDs
*******************************************************
destring ttl_votes, replace ignore(" ,") force
drop if missing(ttl_votes)

rename costituency constituency
foreach x in region district constituency ward {
    replace `x' = `x'[_n-1] if missing(`x')
}

*******************************************************
* 5) Clean party names and map to a controlled list (+ OTHER)
*******************************************************
gen party_std = upper(trim(political_party))

replace party_std = subinstr(party_std,"-","_",.)
replace party_std = subinstr(party_std,"/","_",.)
replace party_std = subinstr(party_std," ","_",.)

replace party_std = "APPT_MAENDELEO" if party_std=="APPT___MAENDELEO" | party_std=="APPT_MAENDELEO"
replace party_std = "NCCR_MAGEUZI"   if party_std=="NCCR_MAGEUZI"     | party_std=="NCCR__MAGEUZI"
replace party_std = "JAHAZIASILIA"   if party_std=="JAHAZI_ASILIA"    | party_std=="JAHAZIASILIA"

local parties "AFP APPT_MAENDELEO CCM CHADEMA CHAUSTA CUF DP JAHAZIASILIA MAKIN NCCR_MAGEUZI NLD NRA SAU TADEA TLP UDP UMD UPDP"

gen byte keep_party = 0
foreach p of local parties {
    replace keep_party = 1 if party_std=="`p'"
}
replace party_std = "OTHER" if keep_party==0
drop keep_party

*******************************************************
* 6) Ward-level totals: candidates and total votes
*******************************************************
bysort region district constituency ward: egen total_candidates_10 = count(ttl_votes)
bysort region district constituency ward: egen ward_total_votes_10 = total(ttl_votes)

*******************************************************
* 7) Aggregate to ward×party and reshape wide
*******************************************************
gen party_j = strtoname(party_std)

collapse (sum) ttl_votes ///
         (first) total_candidates_10 ward_total_votes_10, ///
         by(region district constituency ward party_j)

reshape wide ttl_votes, i(region district constituency ward) j(party_j) string

rename ttl_votes* votes_*_10

foreach p of local parties {
    capture confirm variable votes_`p'_10
    if _rc gen votes_`p'_10 = 0
}
capture confirm variable votes_OTHER_10
if _rc gen votes_OTHER_10 = 0
rename votes_OTHER_10 votes_other_10

*******************************************************
* 9) Create ward_id_10 as a grouped identifier
*******************************************************
egen ward_id_10 = group(region district ward)

*******************************************************
* 10) Add year suffix to IDs and order columns
*******************************************************
rename region       region_10
rename district     district_10
rename constituency constituency_10
rename ward         ward_10

order region_10 constituency_10 district_10 ward_10 total_candidates_10 ward_total_votes_10 ward_id_10 ///
      votes_AFP_10 votes_APPT_MAENDELEO_10 votes_CCM_10 votes_CHADEMA_10 votes_CHAUSTA_10 ///
      votes_CUF_10 votes_DP_10 votes_JAHAZIASILIA_10 votes_MAKIN_10 votes_NCCR_MAGEUZI_10 ///
      votes_NLD_10 votes_NRA_10 votes_SAU_10 votes_TADEA_10 votes_TLP_10 votes_UDP_10 ///
      votes_UMD_10 votes_UPDP_10 votes_other_10 

*******************************************************
* 11) Export
*******************************************************
save "$out/tz_election_2010_wide.dta", replace
export excel using "$out/tz_election_2010_wide.xlsx", firstrow(variables) replace

*******************************************************

*Q5
*******************************************************
* Inputs: q5_psle_2020_data.dta, q5_school_location.dta
* Outputs: q5_psle_2020_with_ward.dta
*******************************************************

clear all
set more off

* 0) Set data path (default: current working directory)
global data "."

* 1) Load PSLE and extract ps_code from schoolname
use "${data}/q5_psle_2020_data.dta", clear

* Extract trailing "PS" + 7 digits (e.g., PS0101005)
gen str9 ps_code = ""
replace ps_code = regexs(0) if regexm(schoolname, "PS[0-9]{7}$")

* Fallback if code length is not exactly 7 digits
replace ps_code = regexs(0) if missing(ps_code) & regexm(schoolname, "PS[0-9]{6,8}$")

replace ps_code = upper(trim(ps_code))

* Quick check: missing extracted codes
di "---- PSLE: ps_code missing count ----"
count if missing(ps_code)

tempfile psle
save `psle', replace


* 2) Load location data, prepare merge key, and deduplicate
use "${data}/q5_school_location.dta", clear

* Rename NECTACentreNo to ps_code for merging
rename NECTACentreNo ps_code
replace ps_code = upper(trim(ps_code))

* Drop invalid/missing keys
drop if missing(ps_code)
drop if ps_code == "N/A" | ps_code == "n/a"

* Keep required variables only
keep ps_code Ward Region Council

* Flag duplicate keys
duplicates tag ps_code, gen(dup_ps_code)

* Keep first observation per ps_code
bysort ps_code: keep if _n == 1

tempfile loc
save `loc', replace


* 3) Merge PSLE + Ward
use `psle', clear

merge m:1 ps_code using `loc', keepusing(Ward Region Council dup_ps_code)
drop if _merge==2

* Create a simple match indicator
gen byte matched = (_merge == 3)

di "---- Merge summary ----"
tab _merge

* Confirm final N
assert _N == 17329


* 4) Save final dataset
save "${data}/q5_psle_2020_with_ward.dta", replace
di "Saved: ${data}/q5_psle_2020_with_ward.dta"

*******************************************************
* End
*******************************************************
