* Stata 2
* Q1: Tanzania Student Data

clear all
set more off

global raw "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-stata2\dataset\q1_psle_student_raw.dta"
global out "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-stata2\dataset\q1_psle_students_138schools.dta"

use "$raw", clear
assert !missing(s) & !missing(schoolcode)

gen str10 school_id = ""
replace school_id = upper( regexs(0) ) if regexm(upper(schoolcode), "PS[0-9]+")
replace school_id = substr(school_id, 1, 9) 

* Clean HTML into line-based text, keep candidate table rows 
*   - Turn </TR> into line breaks (char(10))
*   - Turn </TD> into pipe separators |
*   - Drop all remaining tags <...>

gen strL txt = s

* remove leading "b'" and trailing "'" if present
replace txt = subinstr(txt, "b'", "", 1)
replace txt = regexr(txt, "'\s*$", "")

* normalize whitespace/newlines
replace txt = subinstr(txt, char(13), " ", .)
replace txt = subinstr(txt, char(10), " ", .)

* make table structure explicit
replace txt = ustrregexra(txt, "(?i)</tr>", char(10))
replace txt = ustrregexra(txt, "(?i)</td>", "|")

* drop all remaining HTML tags
replace txt = ustrregexra(txt, "<[^>]+>", " ")

* collapse repeated spaces
replace txt = ustrregexra(txt, "[ \t]+", " ")
replace txt = strtrim(txt)

split txt, parse("`=char(10)'") gen(line)

drop txt s
gen long school_rowid = _n

reshape long line, i(school_rowid) j(lineno)
drop if missing(line)
replace line = strtrim(line)

* keep only candidate data lines (contain candidate number like PS0101114-0001)
keep if regexm(line, "PS[0-9]+-[0-9]{4}")

* Split candidate line into fields 
* Expected after cleaning: cand_no | prem_no | sex | candidate_name | subjects ...
split line, parse("|") gen(f)

* sometimes extra empty pieces appear; trim all
forvalues k = 1/15 {
    capture confirm variable f`k'
    if !_rc replace f`k' = strtrim(f`k')
}

* Keep first 5 fields that matter
gen str20 cand_no        = f1
gen str20 prem_no        = f2
gen str1  sex            = f3
gen str80 candidate_name = f4

* Subjects field can be long; if f5 missing due to weird separators, try to reconstruct
gen strL subjects = f5

* If subjects spilled into f6+ (rare), append them back
forvalues k = 6/15 {
    capture confirm variable f`k'
    if !_rc replace subjects = subjects + " " + f`k' if !missing(f`k')
}
replace subjects = strtrim(subjects)

* school_id: if missing from filename, derive from cand_no prefix
replace school_id = substr(cand_no, 1, 9) if missing(school_id) & !missing(cand_no)

* drop obvious header/garbage rows if any slipped through
drop if cand_no=="CAND. NO" | cand_no=="CAND.NO"

* tidy
drop line f*
order school_id schoolcode cand_no prem_no sex candidate_name subjects

* Save student-level dataset 
compress
save "$out", replace


* Q2: Côte d'Ivoire Population Density
clear all
set more off

cd "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-stata2\dataset\"

import excel "q2_CIV_populationdensity.xlsx", firstrow clear

rename NOMCIRCONSCRIPTION departement
rename DENSITEAUKM density

replace departement = lower(itrim(trim(departement)))

keep departement density
duplicates drop departement, force

save "q2_CIV_density_clean.dta", replace

use "q2_CIV_Section_0.dta", clear

decode b06_departemen, gen(departement)

replace departement = lower(trim(departement))

merge m:1 departement using "q2_CIV_density_clean.dta", keepusing(density)

tab _merge
drop if _merge==2
drop _merge

save "q2_CIV_Section_0_with_density.dta", replace


*Q3: Enumerator Assignment based on GPS
clear all
set more off

use "q3_GPS Data.dta", clear

* sort geographically
sort latitude longitude

* create running index
gen hh_order = _n

* assign enumerator (6 HH per enumerator)
gen enum_id = ceil(hh_order/6)

replace enum_id = 19 if enum_id > 19

tab enum_id

save "q3_GPS_assigned_balanced.dta", replace


*Q4: 2010 Tanzania Election Data cleaning
clear all
set more off

use "q4_Tz_election_template.dta", clear
ds
local tmplvars `r(varlist)'

import excel "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-stata2\dataset\q4_Tz_election_2010_raw.xls", cellrange(A5) firstrow clear

rename REGION region
rename DISTRICT district
rename COSTITUENCY constituency
rename WARD ward
rename CANDIDATENAME candidate_name
rename POLITICALPARTY party
rename TTLVOTES votes

foreach v in region district constituency ward candidate_name party {
    replace `v' = itrim(trim(`v'))
}

* fill down merged/blank cells
foreach v in region district constituency ward {
    replace `v' = `v'[_n-1] if missing(`v') & _n>1
}

foreach v in region district constituency ward {
    replace `v' = lower(`v')
}

destring votes, replace ignore(",") force
replace votes = . if votes<0

replace party = upper(itrim(trim(party)))
replace party = subinstr(party, " ", "_", .)
replace party = subinstr(party, "-", "_", .)
replace party = subinstr(party, "/", "_", .)
replace party = subinstr(party, ".", "", .)
replace party = subinstr(party, "__", "_", .)

gen party_clean = party
replace party_clean = "APPT_MAENDELEO" if inlist(party_clean, "APPT", "MAENDELEO", "APPTMAENDELEO", "APPT_MAENDELEO")
replace party_clean = "NCCR_MAGEUZI"  if inlist(party_clean, "NCCR", "NCCR_MAGEUZI", "NCCRMAGEUZI", "NCCR-MAGEUZI", "NCCR_MAGEUZI")
replace party_clean = "JAHAZIASILIA" if inlist(party_clean, "JAHAZI_ASILIA", "JAHAZIASILIA", "JAHAZI", "JAHAZI_ASILIA")

gen byte in_tmpl = inlist(party_clean, "AFP","APPT_MAENDELEO","CCM","CHADEMA","CHAUSTA","CUF","DP","JAHAZIASILIA","MAKIN")
replace in_tmpl = 1 if inlist(party_clean, "NCCR_MAGEUZI","NLD","NRA","SAU","TADEA","TLP","UDP","UMD","UPDP")
replace party_clean = "OTHER" if in_tmpl==0
drop in_tmpl

gen str244 ward_key = region + "|" + district + "|" + constituency + "|" + ward
egen ward_key_id = group(ward_key)

bys ward_key_id: egen ward_total_votes_10 = total(votes)
bys ward_key_id: egen total_candidates_10 = count(candidate_name)

preserve
keep ward_key_id region district constituency ward ward_total_votes_10 total_candidates_10
bys ward_key_id: keep if _n==1
tempfile wardinfo
save `wardinfo', replace
restore

collapse (sum) votes (firstnm) region district constituency ward, by(ward_key_id party_clean)

rename votes votes_
reshape wide votes_, i(ward_key_id) j(party_clean) string

merge 1:1 ward_key_id using `wardinfo', nogen

egen ward_id_10 = group(region district ward)

rename region region_10
rename district district_10
rename constituency constituency_10
rename ward ward_10

foreach p in AFP APPT_MAENDELEO CCM CHADEMA CHAUSTA CUF DP JAHAZIASILIA MAKIN ///
             NCCR_MAGEUZI NLD NRA SAU TADEA TLP UDP UMD UPDP OTHER {
    capture confirm variable votes_`p'
    if _rc gen votes_`p' = 0
    rename votes_`p' votes_`p'_10
}
rename votes_OTHER_10 votes_other_10

drop ward_key ward_key_id

keep `tmplvars'
order `tmplvars'

save "q4_Tz_election_2010_clean_wide.dta", replace


* Q5: Tanzania PSLE data
clear all
set more off

use "q5_school_location.dta", clear

gen necta = upper(trim(NECTACentreNo))
drop if necta == "" | necta == "N/A"

gen region_clean = upper(trim(Region))
gen school_clean = upper(trim(School))
replace school_clean = subinstr(school_clean, "PRIMARY SCHOOL", "", .)
replace school_clean = itrim(trim(school_clean))

keep necta Ward region_clean school_clean
duplicates drop necta, force

tempfile loc_bycode
save `loc_bycode', replace

use `loc_bycode', clear
duplicates drop region_clean school_clean, force

tempfile loc_byname
save `loc_byname', replace


use "q5_psle_2020_data.dta", clear

gen necta = ""
replace necta = regexs(1) if regexm(upper(schoolname), "(PS[0-9]{7})")
replace necta = upper(trim(necta))

gen region_clean = upper(trim(region_name))

gen school_clean = upper(schoolname)
replace school_clean = subinstr(school_clean, char(13), " ", .)
replace school_clean = subinstr(school_clean, char(10), " ", .)
replace school_clean = subinstr(school_clean, "PRIMARY SCHOOL", "", .)
replace school_clean = regexr(school_clean, "\s*-\s*PS[0-9]{7}\s*", " ")
replace school_clean = itrim(trim(school_clean))

count
local N0 = r(N)

merge m:1 necta using `loc_bycode', keepusing(Ward) keep(1 3) gen(m_code)

gen ward = Ward
drop Ward

count
assert r(N) == `N0'

merge m:1 region_clean school_clean using `loc_byname', keepusing(Ward) keep(1 3) gen(m_name)

replace ward = Ward if trim(ward)=="" & m_name==3 & trim(Ward)!=""
drop Ward

count
assert r(N) == `N0'

count if trim(ward)==""
tab m_code
tab m_name if trim(ward)==""

save "q5_psle_2020_with_ward.dta", replace