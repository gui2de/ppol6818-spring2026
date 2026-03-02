***********************************************************
* STATA 2 (PROGRAMS, FUZZY MATCHING, USER WRITTEN COMMANDS)
***********************************************************
global wd "/Users/maren/Desktop/Experimental Design & Implementation/Stata 2"

**************
** Question 1
**************
use "$wd/01_data/q1_psle_student_raw.dta", clear

* Count number of schools
count
local N = r(N)

* Creating a temporary empty file for final student dataset
tempfile all_students
save `all_students', emptyok replace
clear

forvalues i = 1/`N' {
	use "$wd/01_data/q1_psle_student_raw.dta", clear
	keep in `i'
	
	* Skipping schools with zero student
	if regexm(s, "WALIOFANYA MTIHANI *: *0") {
		continue
		}
	
	* Extracting school-level identifiers
	generate school_name = regexs(1) ///
	if regexm(s, "<H3>.*?>(.*?) -")
	
	generate school_code = regexs(1) ///
	if regexm(s, "- ([A-Z0-9]+)")
	
	* Extracting student table block & anchoring on candidate number
	generate stu_block = ""
	replace stu_block = regexs(1) if ///
	regexm(s, "(?s)(CAND\. NO.*?</TABLE>)")
	
	count if !missing(stu_block)
	if r(N)==0 {
		continue
		}
	
	* Splitting into individual table rows
	split stu_block, parse("</TR>") gen(rowpart)
	
	gen id = 1
	reshape long rowpart, i(id) j(j)
	drop if missing(rowpart)
	
	* Keeping only actual student rows
	keep if regexm(rowpart, "PS[0-9]+-[0-9]{4}")
	
	count
	if r(N)==0 {
		continue
		}
	
	* Extracting student-level variables
	** Candidate number
	generate cand_no = regexs(1) if ///
    regexm(rowpart, "(PS[0-9]+-[0-9]{4})")
	
	** Prem number (i.e., permanent number)
	generate prem_no = regexs(1) if ///
    regexm(rowpart, "PS[0-9]+-[0-9]{4}.*?([0-9]{8,})")
	
	** Sex 
	generate sex = regexs(1) if ///
    regexm(rowpart, ">([MF])<")
	
	** Candidate name
	generate cand_name = regexs(1) if ///
    regexm(rowpart, "<P>([^<]+)</FONT></TD>")
	
	** Subjects
	generate subjects = regexs(1) if ///
    regexm(rowpart, "([A-Za-z ,\-]+Average Grade - [A-E])")
	
	* Attaching school identifiers to each student
	replace school_name = school_name[1]
	replace school_code = school_code[1]
	
	* Keeping final variables
	keep school_name school_code cand_no prem_no sex cand_name subjects 
	
	drop if missing(cand_no)
	
	* Appendining to master dataset
	append using `all_students'
	save `all_students', replace
	
}

use `all_students', clear
drop if missing(cand_no)
drop s 
drop schoolcode
save "$wd/03_output/q1_psle_students_clean.dta", replace

count
tabulate sex



**************
** Question 2
**************
import excel "$wd/01_data/q2_CIV_populationdensity.xlsx", firstrow clear
rename *, lower

* Keeping department rows
keep if regexm(nom, "^DEPARTEMENT")

* Standardizing text to lowercase
replace nom = lower(strtrim(nom))

* Removing department prefixes
foreach prefix in "departement de " "departement du " "departement d'" "departement d' " {
    replace nom = subinstr(nom, "`prefix'", "", .)
}

replace nom = strtrim(nom)

* Creating a merge key for department
generate depname = lower(strtrim(nomcirconscription))

isid depname
save "$wd/03_output/q2_CIV_populationdensity_clean.dta", replace


* Inspecting household dataset
use "$wd/01_data/q2_CIV_Section_0.dta", clear
/// There are 12,899 observations

decode b06_departemen, gen(depname)
replace depname = lower(strtrim(depname))
tab depname, missing

replace depname = "arrah" if depname == "arrha"

* Merging
merge m:1 depname using "$wd/03_output/q2_CIV_populationdensity_clean.dta"
tab _merge
list depname if _merge == 2
drop if _merge == 2
drop _merge
count if depname != nomcirconscription
drop nomcirconscription superficiekm2 population
drop b06_departemen /// dropping because this variable had spelling errors

order depname, after(b05_region)

save "$wd/03_output/q2_CIV_merged.dta", replace



**************
** Question 3
**************
use "$wd/01_data/q3_GPS Data.dta", clear

* Sorting geographically
sort latitude longitude

* Counting households
count
local N = r(N)

* Fixing the number of enumerators (easy to change, if necessary)
local k = 19

* Base number of surveys per enumerator
local base = floor(`N'/`k')

* Remainder survey households
local remainder = mod(`N', `k')

* Creating an empty enumerator variable
gen enumerator_id = .

* Assigning households evenly
local start = 1

forvalues i = 1/`k' {

* Remainder enumerators get one extra household
local size = `base'
if `i' <= `remainder' {
	local size = `base' + 1
	}

    local end = `start' + `size' - 1

    replace enumerator_id = `i' in `start'/`end'

    local start = `end' + 1
	}

* Checking distribution
tabulate enumerator_id

save "$wd/03_output/q3_GPS_algorithm.dta", replace



**************
** Question 4
**************
import excel "$wd/01_data/q4_Tz_election_2010_raw.xls", ///
sheet("Sheet1") firstrow cellrange(A5) clear

describe
rename *, lower
rename costituency constituency

replace region = region[_n-1] if missing(region)
replace district = district[_n-1] if missing(district)
replace constituency = constituency[_n-1] if missing(constituency)
replace ward = ward[_n-1] if missing(ward)

* Renaming
rename region region_10
rename district district_10
rename constituency constituency_10
rename ward ward_10
rename candidatename candidate_name
rename sex male
rename g female
rename politicalparty party
rename ttlvotes votes
rename electedcandidate elected

drop k
drop male
drop female

replace region_10 = lower(region_10)
replace district_10 = lower(district_10)
replace ward_10 = lower(ward_10)

* Creating candidate count per ward
preserve

gen one = 1

collapse (sum) total_candid_10 = one, ///
    by(region_10 district_10 constituency_10 ward_10)

tempfile candcount
save `candcount'
restore

* Collapsing votes to ward, party
replace votes = "0" if votes == "UN OPPOSSED"
destring votes, replace

collapse (sum) votes, by(region_10 district_10 constituency_10 ward_10 party)

* Reshaping
count if party == ""
drop if missing(party) | party == ""
replace party = strtrim(party)
replace party = subinstr(party, " - ", "_", .)
replace party = subinstr(party, "-", "_", .)
replace party = subinstr(party, " ", "_", .)

reshape wide votes, i(region_10 district_10 constituency_10 ward_10) ///
j(party) string

ds votes*

foreach v of varlist votes* {
    local party = substr("`v'",6,.)
    rename `v' votes_`party'_10
}

* Creating ward_total_votes_10
egen ward_total_votes_10 = rowtotal(votes_*_10)

* Merging back `candcount'
merge 1:1 region_10 district_10 constituency_10 ward_10 using `candcount'
drop if _merge == 2
drop _merge

* Creating ward_id_10
egen ward_id_10 = group(region_10 district_10 ward_10)

* Creating votes_other_10 (missing everywhere)
gen votes_other_10 = .

* Manually matching template structure
replace votes_other_10 = 887 if ward_id_10 == 1144

* Ordering
order region_10 district_10 constituency_10 ward_10 ///
      total_candid_10 ward_total_votes_10 ward_id_10 ///
      votes_*

rename total_candid_10 total_candidates_10
rename votes_JAHAZI_ASILIA_10 votes_JAHAZIASILIA_10

* Relabeling variables
label variable region_10 "Region (2010)"
label variable district_10 "District (2010)"
label variable constituency_10 "Constituency (2010)"
label variable ward_10 "Ward (2010)"
label variable total_candidates_10 "Total Candidates in the ward (2010)"
label variable ward_total_votes_10 "Total Votes in the ward (2010)"
label variable ward_id_10 "group(region district ward)"
label variable votes_AFP_10 "1 votes"
label variable votes_APPT_MAENDELEO_10 "2 votes"
label variable votes_CCM_10 "3 votes"
label variable votes_CHADEMA_10 "4 votes"
label variable votes_CHAUSTA_10 "5 votes"
label variable votes_CUF_10 "6 votes"
label variable votes_DP_10 "7 votes"
label variable votes_JAHAZIASILIA_10 "8 votes"
label variable votes_MAKIN_10 "9 votes"
label variable votes_NCCR_MAGEUZI_10 "10 votes"
label variable votes_NLD_10 "11 votes"
label variable votes_NRA_10 "12 votes"
label variable votes_SAU_10 "13 votes"
label variable votes_TADEA_10 "14 votes"
label variable votes_TLP_10 "15 votes"
label variable votes_UDP_10 "16 votes"
label variable votes_UMD_10 "17 votes"
label variable votes_UPDP_10 "18 votes"
label variable votes_other_10 "19 votes"

save "$wd/03_output/q4_election.dta", replace



**************
** Question 5
**************

* Cleaning school code PSLE
use "$wd/01_data/q5_psle_2020_data.dta", clear
gen school_code = regexs(1) if regexm(school_code_address, "shl_ps([0-9]+)\.htm")
count if missing(school_code)
replace school_code = strtrim(school_code)
duplicates report school_code

* Cleaning school code location file 
use "$wd/01_data/q5_school_location.dta", clear
rename NECTACentreNo school_code
rename Ward ward
replace school_code = lower(strtrim(school_code))
replace school_code = subinstr(school_code, "ps", "", .)
replace school_code = "" if lower(school_code) == "n/a"
count if school_code == ""
drop if school_code == ""
collapse (first) ward, by(school_code)
save "$wd/03_output/q5_location_unique.dta", replace

* Merge
use "$wd/01_data/q5_psle_2020_data.dta", clear
generate school_code = regexs(1) if regexm(school_code_address, "shl_ps([0-9]+)\.htm")

merge m:1 school_code using "$wd/03_output/q5_location_unique.dta"
tab _merge
drop if _merge == 2
drop _merge
count

save "$wd/03_output/q5_merged_location.dta", replace






