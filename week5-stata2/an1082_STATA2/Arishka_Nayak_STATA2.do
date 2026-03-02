clear all
cd "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\Assignment 5\01_data"


********************************************************************************
*QUESTION 1: WEB SCRAPING
********************************************************************************

use q1_psle_student_raw.dta, clear

split s, parse("<TR>") gen(st)

gen id = _n
reshape long st, i(id) j(student_num)
keep if strpos(st, "Kiswahili") > 0


gen cand_id = ustrregexs(0) if ustrregexm(st, "PS[0-9]+-[0-9]+")
gen prem_num = ustrregexs(0) if ustrregexm(st, "[0-9]{11}")
gen gender = ustrregexs(1) if ustrregexm(st, `"<P ALIGN="CENTER">(M|F)</FONT>"')
gen name = ustrregexs(1) if ustrregexm(st, "<P>([^<]+)</FONT>")

gen kiswahili = ustrregexs(1) if ustrregexm(st, "Kiswahili - ([A-E])")
gen english   = ustrregexs(1) if ustrregexm(st, "English - ([A-E])")
gen maarifa   = ustrregexs(1) if ustrregexm(st, "Maarifa - ([A-E])")
gen hisabati  = ustrregexs(1) if ustrregexm(st, "Hisabati - ([A-E])")
gen science   = ustrregexs(1) if ustrregexm(st, "Science - ([A-E])")
gen uraia     = ustrregexs(1) if ustrregexm(st, "Uraia - ([A-E])")
gen average   = ustrregexs(1) if ustrregexm(st, "Average Grade - ([A-E])")


*SCHOOL NAME AND CODE*
gen schoolname = ustrregexs(1) if ustrregexm(s, "<H3><P[^>]*>([^<]+)")
gen scode = ustrregexs(1) if ustrregexm(schoolname, "(PS[0-9]+)")
replace schoolname = ustrregexra(schoolname, "-?\s*PS[0-9]+", "")

replace schoolname = trim(schoolname)
sort id student_num
by id: replace schoolname = schoolname[1] if missing(schoolname)
by id: replace scode = scode[1] if missing(scode)


drop s st id student_num schoolcode
order scode schoolname cand_id prem_num name gender

********************************************************************************
*QUESTION 2: COTE DIVOIRE POPULATION DENSITY
********************************************************************************
import excel "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\Assignment 5\01_data\q2_CIV_populationdensity.xlsx", sheet("Population density") firstrow clear
rename NOMCIRCONSCRIPTION nomcirconscription
rename SUPERFICIEKM2 superficiekm2
rename POPULATION population
rename DENSITEAUKM densiteaukm2

keep if strpos(nomcirconscription, "DEPARTEMENT") > 0

replace nomcirconscription = subinstr(nomcirconscription, "DEPARTEMENT D' ", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "DEPARTEMENT D'", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "DEPARTEMENT DU ", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "DEPARTEMENT DE ", "", .)
rename nomcirconscription dept_name
rename densiteaukm2 density
save "department_data.dta", replace

*****************************************
use q2_CIV_Section_0.dta, clear
decode b06_departemen, gen(dept_name)
replace dept_name=trim(itrim(upper(dept_name)))

replace dept_name = "ARRAH" if dept_name == "ARRHA"

merge m:1 dept_name using department_data.dta
drop _merge


label variable dept_name "departement"
label variable b10_nomvillag "nom de la locality"
label variable b09_zd "zone de denombrement (zd)"
label variable b07_souspref "sous-prefecture"
label variable b05_region "region"
label variable b06_departemen "departement"

********************************************************************************
*QUESTION 3: ENUMERATOR ASSIGNMENT BASED ON GPS
********************************************************************************
use "q3_GPS Data.dta", clear	

set seed 1234
cluster kmeans latitude longitude, k(19) name(enum_group)
sort enum_group latitude longitude
gen enumerator_id=ceil(_n/5.85)

replace enumerator_id=19 if enumerator_id>19
drop enum_group





********************************************************************************
*QUESTION 4: DATA CLEANING: ELECTION DATA
********************************************************************************


import excel "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\Assignment 5\01_data\q4_Tz_election_2010_raw.xls", sheet("Sheet1") cellrange(A5:K7927) firstrow clear

rename REGION region
rename DISTRICT district
rename COSTITUENCY constituency
rename WARD ward
rename CANDIDATENAME candidate_name
rename POLITICALPARTY party
rename TTLVOTES cand_total
drop SEX G K ELECTEDCANDIDATE

replace district = district[_n-1] if district == "" | district == " "
replace constituency = constituency[_n-1] if constituency == "" | constituency == " "
replace region = region[_n-1] if region == "" | region==" "
replace region = region[_n+1] if region == "" & region[_n+1] != ""
replace ward=ward[_n-1] if ward=="" | ward==" "


replace cand_total = "0" if strpos(upper(cand_total), "UN OPPOSSED")
destring cand_total, replace ignore(",")
drop if region=="ARUSHA" & ward==""

bysort region district constituency ward: gen total_candidates = _N
bysort region district constituency ward: egen ward_total_votes = sum(cand_total)
egen ward_id=group(region district constituency ward)

foreach var of varlist region district constituency ward party {
    replace `var' = lower(`var')
}

keep region district constituency ward total_candidates ward_total_votes ward_id party cand_total

replace party = upper(trim(party))
replace party = subinstr(party, " ", "_", .)
replace party = subinstr(party, "-", "_", .)

collapse (sum) cand_total, by(region district constituency ward total_candidates ward_total_votes ward_id party)

reshape wide cand_total, i(region district constituency ward total_candidates ward_total_votes ward_id) j(party) string

rename cand_total* votes_*_10	

foreach v in region district constituency ward total_candidates ward_total_votes ward_id {
    rename `v' `v'_10
}






********************************************************************************
*QUESTION 5: SCHOOL-LEVEL WARD INFORMATION
********************************************************************************
use "q5_school_location.dta", clear
destring StandardVI*, replace
gen examinees7 = StandardVIIBoys + StandardVIIGirls
drop if examinees7 == 0
replace NECTACentreNo = " . " if NECTACentreNo == "n/a"
replace NECTACentreNo = upper(trim(NECTACentreNo))
drop if School == "MWILAMVYA ENGLISH MEDIUM"
rename NECTACentreNo school_code
keep Ward School school_code
duplicates drop school_code, force
tempfile clean_location
save `clean_location'


********************************************************************************
use "q5_psle_2020_data.dta", clear

gen school_code = ustrregexs(1) if ustrregexm(school_code_address, "_(.*?)\.htm")
replace school_code = upper(trim(school_code))

merge m:1 school_code using `clean_location'

drop if _merge == 2
count

drop _merge

