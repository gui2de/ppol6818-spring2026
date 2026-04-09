* ---------------------------------------------------------
* Question 1
* ---------------------------------------------------------
clear all
set more off

local raw_data_path "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment/q1_psle_student_raw.dta"


tempfile master_data
save `master_data', emptyok

use "`raw_data_path'", clear
local total_schools = _N 

forvalues i = 1/`total_schools' {
    
    use "`raw_data_path'", clear
    keep in `i'
    
    tempname fh
    file open `fh' using "temp_school.txt", write text replace
    file write `fh' (s[1])
    file close `fh'
    
    import delimited "temp_school.txt", clear varnames(nonames) delimiters("$$$") encoding("utf-8")
    capture rename v1 raw_data
    
    capture confirm variable raw_data
    if _rc == 0 {
        
        gen cand_id = ""
        gen prem_number = ""
        gen gender = ""
        gen name = ""
        gen subjects_str = ""
        
        capture replace cand_id = regexs(1) if regexm(raw_data, "(PS[0-9]+-[0-9]+)")
        capture replace prem_number = regexs(1) if regexm(raw_data, "([0-9]{10,})")
        capture replace gender = regexs(1) if regexm(raw_data, ">([MF])<")
        
        capture replace name = regexs(1) if regexm(raw_data, ">([A-Z ]{3,})<")
        replace name = "" if inlist(name, "CANDIDATE NAME", "SUBJECTS", "SEX", "PREM NO", "CAND NO")
        
        replace subjects_str = raw_data if regexm(raw_data, "Kiswahili")
        
        foreach var in cand_id prem_number gender name {
            replace `var' = `var'[_n-1] if `var' == "" & _n > 1
        }
        
        keep if subjects_str != ""
        
        count
        if r(N) > 0 {
            local sub_list "Kiswahili English Maarifa Hisabati Science Uraia"
            foreach sub in `sub_list' {
                gen `sub' = ""
                capture replace `sub' = regexs(1) if regexm(subjects_str, "`sub'[^A-F]*([A-F])")
            }
            
            gen average = ""
            capture replace average = regexs(1) if regexm(subjects_str, "Average Grade[^A-F]*([A-F])")
            
            gen schoolcode = substr(cand_id, 1, 9)
            
            rename (Kiswahili English Maarifa Hisabati Science Uraia) (kiswahili english maarifa hisabati science uraia)
            
            keep schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average
            
            append using `master_data'
            save `master_data', replace
        }
    }
}

use `master_data', clear

capture erase "temp_school.txt"

order schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

browse

* ---------------------------------------------------------
* Question 2
* ---------------------------------------------------------
clear all

import excel "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment/q2_CIV_populationdensity.xlsx", clear

rename A merge_id
rename B superficie
rename C population
rename D density

drop in 1

destring superficie population density, replace force

replace merge_id = lower(trim(merge_id)) 

drop if merge_id == ""
duplicates drop merge_id, force

tempfile pop_density
save `pop_density', replace

use "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment/q2_CIV_Section_0.dta", clear

decode b06_departemen, generate(merge_id)
replace merge_id = lower(trim(merge_id)) 

merge m:1 merge_id using `pop_density'

order merge_id b10_nomvillag density population
browse

drop if _merge == 2

drop _merge

save "C:\Users\24547\Desktop\stata2\q2_CIV_Section_0_merged.dta", replace

* ---------------------------------------------------------
* Question 3
* ---------------------------------------------------------
clear all

cd "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment"

use q3_gps.dta

sort latitude longitude

gen enumerator_id = ceil(_n / 6)

tab enumerator_id


* ---------------------------------------------------------
* Question 4
* ---------------------------------------------------------
clear all

use "C:\Users\24547\Desktop\stata2\q4_Tz_election_template.dta", clear

import excel "C:\Users\24547\Desktop\stata2\q4_Tz_election_2010_raw.xls", firstrow clear
describe
browse

clear all


cd "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment"

import excel "q4_Tz_election_2010_raw.xls", sheet("Sheet1") cellrange(A5) firstrow clear

rename REGION region_10
rename DISTRICT district_10
rename COSTITUENCY constituency_10
rename WARD ward_10
rename CANDIDATENAME cand_name
rename POLITICALPARTY party
rename TTLVOTES votes

keep region_10 district_10 constituency_10 ward_10 party votes

replace region_10 = region_10[_n-1] if missing(region_10)
replace district_10 = district_10[_n-1] if missing(district_10)
replace constituency_10 = constituency_10[_n-1] if missing(constituency_10)
replace ward_10 = ward_10[_n-1] if missing(ward_10)

replace region_10 = strtrim(region_10)
replace district_10 = strtrim(district_10)
replace constituency_10 = strtrim(constituency_10)
replace ward_10 = strlower(strtrim(ward_10))

replace party = strtrim(party)
replace party = subinstr(party, "-", "_", .)
replace party = subinstr(party, " ", "_", .)

destring votes, replace force

drop if missing(party) | missing(votes)


bysort region_10 district_10 constituency_10 ward_10: egen ward_total_votes_10 = sum(votes)
bysort region_10 district_10 constituency_10 ward_10: gen total_candidates_10 = _N

collapse (sum) votes (firstnm) ward_total_votes_10 total_candidates_10, by(region_10 district_10 constituency_10 ward_10 party)

rename votes votes_

reshape wide votes_, i(region_10 district_10 constituency_10 ward_10) j(party) string

rename votes_* votes_*_10

egen ward_id_10 = group(region_10 district_10 ward_10)

order region_10 district_10 constituency_10 ward_10 total_candidates_10 ward_total_votes_10 ward_id_10 votes_*

browse

* ---------------------------------------------------------
* Question 5
* ---------------------------------------------------------
clear all

use "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment/q5_school_location.dta", clear

rename NECTACentreNo school_code

replace school_code = upper(trim(school_code))

drop if school_code == ""
duplicates drop school_code, force

keep school_code Ward

tempfile location_dict
save `location_dict', replace


use "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment/q5_psle_2020_data.dta", clear

gen school_code = ""
replace school_code = upper(regexs(1)) if regexm(school_code_address, "(ps[0-9]+)")

replace school_code = upper(regexs(1)) if missing(school_code) & regexm(schoolname, "(PS[0-9]+)")

merge m:1 school_code using `location_dict'

keep if _merge == 1 | _merge == 3

drop _merge

save "C:\Users\24547\Desktop\stata2\q5_psle_2020_data_merged.dta", replace

