*Maimoona Mohsin 
*Experiment Design and Learning 
*Assignment 2 


display c(username)

if c(username)== "maimo" { 
	global wd "C:\Users\maimo\OneDrive\Desktop\Semester 2\Experimental Design & Implement\Stata 2 assignment"
}

else if c(username)== "" {
	global wd " "
}
else {
	display as error "Define user specific file path"
}

*file paths 
global q1 "$wd/q1_psle_student_raw"


*Question 1 
use "$q1", clear

keep in 1

gen s_low = lower(s)

split s_low, parse("<tr") gen(row)

keep row1 row7-row22

gen id = 1

reshape long row, i(id) j(student)

browse

gen cand_id = regexs(1) if regexm(row, ">(ps[0-9-]+)<")

browse cand_id row

/*regexm() = detector

parentheses = what to keep

regexs(1) = retrieve what you kept */ 

gen prem_number = regexs(1) if regexm(row, ">([0-9]{11})<")

browse cand_id prem_number

gen sex = regexs(1) if regexm(row, ">([mf])<")
browse cand_id prem_number sex

gen name = regexs(1) if regexm(row, ">([a-z ]{3,})<")
browse cand_id sex name
gen kiswahili = regexs(1) if regexm(row, "kiswahili - ([a-e])")
browse name kiswahili

gen english = regexs(1) if regexm(row, "english - ([a-e])")

browse name kiswahili english

 display row[2]
gen hisabati = regexs(1) if regexm(row, "hisabati - ([a-e]),")
browse name hisabati

drop if missing(cand_id)


gen schoolcode = substr(cand_id, 1, 10)


gen maarifa = regexs(1) if regexm(row, "maarifa - ([a-e]),")
gen science = regexs(1) if regexm(row, "science - ([a-e]),")

gen uraia = regexs(1) if regexm(row, "uraia - ([a-e]),")
gen average = regexs(1) if regexm(row, "grade - ([a-e])")

use "$q1", clear
clear
save "$wd\all_students.dta", emptyok replace
use "$q1", clear

forvalues i = 1/138 {

    preserve
    keep if _n == `i'

    gen s_low = lower(s)
    split s_low, parse("<tr") gen(row)
    keep row*

    gen id = 1
    reshape long row, i(id) j(student)

    drop if !regexm(row, "ps[0-9-]+")

    gen cand_id = regexs(1) if regexm(row, ">(ps[0-9-]+)<")
    gen prem_number = regexs(1) if regexm(row, ">([0-9]{11})<")
    gen sex = regexs(1) if regexm(row, ">([mf])<")
    gen name = regexs(1) if regexm(row, ">([a-z ]{3,})<")

    gen kiswahili = regexs(1) if regexm(row, "kiswahili - ([a-e]),")
    gen english   = regexs(1) if regexm(row, "english - ([a-e]),")
    gen maarifa   = regexs(1) if regexm(row, "maarifa - ([a-e]),")
    gen hisabati  = regexs(1) if regexm(row, "hisabati - ([a-e]),")
    gen science   = regexs(1) if regexm(row, "science - ([a-e]),")
    gen uraia     = regexs(1) if regexm(row, "uraia - ([a-e]),")
    gen average   = regexs(1) if regexm(row, "grade - ([a-e])")

    gen schoolcode = substr(cand_id, 1, 10)

    keep schoolcode cand_id prem_number sex name kiswahili english maarifa hisabati science uraia average

    append using "$wd\all_students.dta"
    save "$wd\all_students.dta", replace

    restore
}

use "$wd\all_students.dta", clear
count
browse

drop if missing(cand_id)
count if missing(cand_id)

count 
*sanity check for me 

bysort schoolcode: gen tag = _n==1
count if tag==1
drop tag

*Question 2 
* Q2 file paths
global civ_household "$wd/q2_CIV_Section_0.dta"
global civ_density   "$wd/q2_CIV_populationdensity.xlsx"

clear 
import excel "$civ_density", firstrow clear


gen departement = lower(NOMCIRCONSCRIPTION)
replace departement = trim(departement)

keep if strpos(departement,"departement")>0

replace departement = subinstr(departement,"departement de ","",.)
replace departement = subinstr(departement,"departement d' ","",.)
replace departement = subinstr(departement,"departement du ","",.)

save "$wd/q2_density_clean.dta", replace


use "$civ_household", clear
decode b06_departemen, gen(departement)
replace departement = lower(departement)
replace departement = trim(departement)

merge m:1 departement using "$wd/q2_density_clean.dta"
tab _merge

drop if _merge == 2

tab _merge
drop _merge

*Question 3 
*FILe paths 
* Q3 file path
global q3 "$wd/q3_GPS Data.dta"

use "$q3", clear 
cluster drop _all

cluster kmeans latitude longitude, k(19) generate(enumerator_id)

tab enumerator_id

summarize latitude longitude

sort enumerator_id
browse

/* I used k-means clustering on the latitude and longitude coordinates to divide households into 19 geographically compact clusters. Each cluster represents one enumerator's assignment. Because the algorithm uses only GPS coordinates and does not rely on village-specific values, it will work for any other village dataset with latitude and longitude variable
*/ 

*Question 4 
*file path 
global q4 "$wd/q4_Tz_election_2010_raw"
global q4template"$wd/q4_Tz_election_template"


use "$q4template", clear 

clear
import excel "$q4", cellrange(A4) clear

list in 1/10
describe

rename A region
rename B district
rename C constituency
rename D ward
rename E candidate
rename F sex_m
rename G sex_f
rename H party
rename I votes
rename J elected
drop K

drop in 1/3

list in 1/10

gen rowid = _n
sort rowid
replace region = region[_n-1] if missing(region)
replace district = district[_n-1] if missing(district)
replace constituency = constituency[_n-1] if missing(constituency)
replace ward = ward[_n-1] if missing(ward)
list region district constituency ward party votes in 1/15

duplicates report ward party
*i figured votes in strng - fixing that 
describe votes

list votes if real(votes)==.

replace votes = "" if votes == "UN OPPOSSED"

destring votes, replace

des votes 

collapse (sum) votes, by(region district constituency ward party)
des 
duplicates report ward party

duplicates report region district constituency ward party

replace party = lower(party)
replace party = subinstr(party, " ", "_", .)
replace party = subinstr(party, "-", "_", .)

tab party

*changing the format now 
reshape wide votes, ///
    i(region district constituency ward) ///
    j(party) string
des 

save "$wd/Tz_election_2010_clean.dta", replace


save "$wd/q4_Tz_election_2010_clean.dta", replace


*question 5 
* File paths
global q5_psle "$wd/q5_psle_2020_data.dta"
global q5_loc  "$wd/q5_school_location.dta"


* clean Location Dataset

use "$q5_loc", clear

* Create clean NECTA code
rename NECTACentreNo necta_code
replace necta_code = upper(necta_code)

* Remove invalid codes
drop if necta_code=="N/A"

* Keep only variables needed
keep necta_code Ward

* Remove duplicate NECTA codes
duplicates drop necta_code, force

* Remove hidden spaces
replace necta_code = trim(necta_code)
replace necta_code = itrim(necta_code)

* Save cleaned location file
save "$wd/q5_location_clean_final.dta", replace

* Prepare PSLE Dataset

use "$q5_psle", clear

* Extract NECTA code from school_code_address
gen necta_code = school_code_address
replace necta_code = subinstr(necta_code, "shl_", "", .)
replace necta_code = subinstr(necta_code, ".htm", "", .)
replace necta_code = upper(necta_code)

* Remove hidden spaces
replace necta_code = trim(necta_code)
replace necta_code = itrim(necta_code)

*merging 

merge 1:1 necta_code using "$wd/q5_location_clean_final.dta"

* Keep only PSLE schools (master dataset)
keep if _merge==1 | _merge==3

drop _merge


save "$wd/q5_psle_with_ward.dta", replace





