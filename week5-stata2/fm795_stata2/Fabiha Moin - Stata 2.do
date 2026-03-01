/**********************
Fabiha Moin 
Experimental Design and Implementation 
Assignment: Stata 02 
Date: 27th February 2026 
**************************/ 

/******************
Question 01
********************/ 

use "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata 2\01_data\q1_psle_student_raw.dta"

**Cleaning Data to Extract Variables 
keep s
rename s source_html
**Generating Unique ID per School and Splitting 
gen school_row = _n
split source_html, parse("<TR>") limit(300) gen(v)
drop source_html
**Keeping Schools with Candidate IDs
reshape long v, i(school_row) j(row_number)
keep if ustrregexm(v, "PS[0-9]+-[0-9]+")
rename v raw_data

**Extracting Variables

gen cand_id = ustrregexs(1) if ustrregexm(raw_data, "(PS[0-9]+-[0-9]+)")
gen schoolcode = substr(cand_id, 1, 9)

gen prem_number = ustrregexs(1) if ustrregexm(raw_data, "([0-9]{11})")

gen gender = ""
replace gender = "M" if ustrregexm(raw_data, ">M</FONT>")
replace gender = "F" if ustrregexm(raw_data, ">F</FONT>")

gen name = ustrregexs(1) if ustrregexm(raw_data, "<P>([A-Z ]+)</FONT>")

gen kiswahili = ustrregexs(1) if ustrregexm(raw_data, "Kiswahili - ([A-F])")
gen english   = ustrregexs(1) if ustrregexm(raw_data, "English - ([A-F])")
gen maarifa   = ustrregexs(1) if ustrregexm(raw_data, "Maarifa - ([A-F])")
gen hisabati  = ustrregexs(1) if ustrregexm(raw_data, "Hisabati - ([A-F])")
gen science   = ustrregexs(1) if ustrregexm(raw_data, "Science - ([A-F])")
gen uraia     = ustrregexs(1) if ustrregexm(raw_data, "Uraia - ([A-F])")
gen average   = ustrregexs(1) if ustrregexm(raw_data, "Average Grade - ([A-F])")

keep schoolcode cand_id prem_number gender name kiswahili english maarifa hisabati science uraia average
save "q1_FINAL_stata2.dta"

/*********************
Question 02 
*********************/ 
clear 
cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata 2\01_data"


**Cleaning the Population Density Excel Data

import excel "q2_CIV_populationdensity.xlsx", sheet("Population density") firstrow clear

**Cleaning the Department Variable (NOMCIRCONSCRIPTION)

keep if strpos(upper(NOMCIRCONSCRIPTION), "DEPARTEMENT") > 0
gen department_clean = lower(NOMCIRCONSCRIPTION) // generating a new variable to clean the department variable
replace department_clean = subinstr(department_clean, "departement de ", "", .)
replace department_clean = subinstr(department_clean, "departement du ", "", .)
replace department_clean = subinstr(department_clean, "departement d' ", "", .)
replace department_clean = subinstr(department_clean, "departement d'", "", .)
replace department_clean = subinstr(department_clean, "departement ", "", .)
replace department_clean = trim(itrim(department_clean))
capture rename *DENSITE* pop_density // standardising the name for population density variable 

keep department_clean pop_density
duplicates drop department_clean, force
save "density_fix.dta", replace


**Cleaning Household data

use "q2_CIV_Section_0.dta", clear

decode department, gen(dept_str) // generating a string for department because it is a string variable in the population density 
gen department_clean = trim(itrim(lower(dept_str)))
replace department_clean = "arrah" if department_clean == "arrha"
replace department_clean = "sassandra" if department_clean == "sassandra"

**The Merge

merge m:1 department_clean using "density_fix.dta"

drop if _merge == 2
drop _merge department_clean dept_str // Keep only the households (drop extra departments from the density file that didn't match)
save "CIV_Section_0_Final.dta", replace
save "q2_FINAL_stata2.dta"
clear

/***************************
Question 03
***********************/ 

use "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata 2\01_data\q3_GPS Data.dta"

**Sorting by Latitude and Longitude
sort latitude longitude

**Generating Enumerator ID Variable
gen enumerator_id = ceil(_n * 19 / _N) // this divides the total count (_N) into 19 equal-sized blocks

**Verifying the counts
tab enumerator_id

save "q3_FINAL_stata2.dta"

clear


/********************
Question 04
**********************/

import excel "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata 2\01_data\q4_Tz_election_2010_raw.xls", sheet("Sheet1") cellrange(A5:K7927) firstrow

**Renaming Variables
rename REGION region_10
rename DISTRICT district_10
rename COSTITUENCY constituency_10
rename WARD ward_10
rename POLITICALPARTY party
rename TTLVOTES votes_raw
drop if missing(party) | party == ""

**Forward Filling the Ward, Constituency, and Region Identifiers
foreach var of varlist region_10 district_10 constituency_10 ward_10 {
    replace `var' = `var'[_n-1] if missing(`var') & _n > 1
}


**Cleaning Votes Variable
replace votes_raw = "0" if strpos(upper(votes_raw), "UN OPPOSSED") > 0
destring votes_raw, gen(votes_num) force
replace votes_num = 0 if missing(votes_num)

**Standradising Party Names
replace party = trim(itrim(upper(party)))
replace party = subinstr(party, "-", "_", .)
replace party = subinstr(party, " ", "_", .)
replace party = "APPT_MAENDELEO" if party == "APPT_MAENDELEO"
replace party = "JAHAZIASILIA" if party == "JAHAZI_ASILIA"

**Generating Ward Level Totals for Votes and candidates
bysort region_10 district_10 constituency_10 ward_10: gen total_candidates_10 = _N
bysort region_10 district_10 constituency_10 ward_10: egen ward_total_votes_10 = sum(votes_num)

**Reshaping data to Wide Format - To Have Votes for Each party
keep region_10 district_10 constituency_10 ward_10 party votes_num total_candidates_10 ward_total_votes_10
collapse (sum) votes_num (first) total_candidates_10 ward_total_votes_10, by(region_10 district_10 constituency_10 ward_10 party)
reshape wide votes_num, i(region_10 district_10 constituency_10 ward_10) j(party) string

**Reanming Columns
foreach var of varlist votes_num* {
    local newname = subinstr("`var'", "votes_num", "votes_", .)
    rename `var' `newname'_10
}

**Final Formatting - Sorting and Orderind Data 
sort region_10 district_10 constituency_10 ward_10
gen ward_id_10 = _n
foreach var of varlist region_10 district_10 ward_10 {
    replace `var' = lower(`var')
}

order total_candidates_10 ward_total_votes_10 ward_id_10, after(ward_10)
save "Tz_election_2010_cleaned.dta", replace

save "q4_FINAL_stata2.dta"

clear

/***********************
Question 05
************************/

**Cleaning and Prepping School Location Data
use "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata 2\01_data\q5_school_location.dta"
keep Region Council Ward School NECTACentreNo
rename Region region
rename Ward ward
rename School school
drop if NECTACentreNo == "n/a" | missing(NECTACentreNo)
duplicates drop NECTACentreNo, force
save "location_by_id.dta", replace

preserve
use "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata 2\01_data\q5_school_location.dta"
keep Region Council Ward School
rename Region region
rename Ward ward
gen school_clean = lower(School)
replace school_clean = subinstr(school_clean, "primary school", "", .)
replace school_clean = trim(itrim(school_clean))
replace region = lower(region)
duplicates drop school_clean region, force
tempfile unique_locations
save `unique_locations'
restore

**Cleaning and Prepping PSLE Data
use "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata 2\01_data\q5_psle_2020_data.dta"

gen NECTACentreNo = substr(schoolname, -11, 9)
gen school_clean = lower(schoolname)
replace school_clean = substr(school_clean, 1, strpos(school_clean, "-") - 1) if strpos(school_clean, "-") > 0
replace school_clean = subinstr(school_clean, "primary school", "", .)
replace school_clean = trim(itrim(school_clean))
rename region_name region
replace region = lower(region)

**Merge 1.0 - using School IDs
merge m:1 NECTACentreNo using "location_by_id.dta"
rename _merge merge_id
drop if merge_id == 2
capture drop _merge

**Mergge 2.0 - using region
merge m:1 school_clean region using `unique_locations', update
drop if _merge == 2  // dropping rows that came from school location data
count // finally 17,329 obs 

*Final Clean Up
drop merge_id School
order ward, after(district_name)
drop school_clean 
order NECTACentreNo, after(ward)

save "q5_FINAL_sata2.dta" 

clear



/*************************
Question 06
************************/ 
cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\Stata 2\01_data"

**Prepping GIS Mapping 2010 data 
preserve
use "Tz_GIS_2015_2010_intersection.dta", clear

foreach var in region_gis_2017 district_gis_2017 ward_gis_2017 {
        replace `var' = lower(strtrim(itrim(`var')))
    }
replace district_gis_2017 = subinstr(district_gis_2017, " urban", "", .)

**Renaming to match 2015 variable names
rename region_gis_2017   region_15
rename district_gis_2017 district_15
rename ward_gis_2017     ward_15
rename region_gis_2012   region_10_parent
rename district_gis_2012 district_10_parent
rename ward_gis_2012     ward_10_parent

tempfile gis_mapping
save `gis_mapping'
restore

**Prepping 2010 Name Lookup 

preserve
use "Tz_elec_10_clean.dta", clear
    
foreach var in region_10 district_10 ward_10 {
        replace `var' = lower(strtrim(itrim(`var')))
        replace `var' = subinstr(`var', "wilaya ya ", "", .)
        replace `var' = subinstr(`var', "jiji la ", "", .)
        replace `var' = subinstr(`var', "manispaa ya ", "", .)
        replace `var' = subinstr(`var', "mji wa ", "", .)
        replace `var' = subinstr(`var', "mji ", "", .)
		}
    
duplicates drop region_10 district_10 ward_10, force
    
**Renaming to match 2015 keys for the update merge
rename region_10   region_15
rename district_10 district_15
rename ward_10     ward_15
    
**Creating parent placeholders
gen region_10_name_match = region_15
gen district_10_name_match = district_15
gen ward_10_name_match = ward_15

tempfile name_lookup
save `name_lookup'
restore

**Loading 2015 Data to Merge Everything 

use "Tz_elec_15_clean.dta", clear

**Cleaning the 2015 names
foreach var in region_15 district_15 ward_15 {
    replace `var' = lower(strtrim(itrim(`var')))
    replace `var' = subinstr(`var', "wilaya ya ", "", .)
    replace `var' = subinstr(`var', "jiji la ", "", .)
    replace `var' = subinstr(`var', "manispaa ya ", "", .)
    replace `var' = subinstr(`var', "mji wa ", "", .)
    replace `var' = subinstr(`var', "mji ", "", .)
}

**Merge 01 - GIS Merge 
merge m:1 region_15 district_15 ward_15 using `gis_mapping'
drop if _merge == 2   // removing GIS wards that aren't in election data
drop _merge 
count 

**Merge 02 - Name Merge 
merge m:1 region_15 district_15 ward_15 using `name_lookup', update
drop if _merge == 2   // removing 2010 wards that aren't in 2015 election data
drop _merge           

**Final Fill for Wards Whose name Did Not Change
replace ward_10_parent = ward_15 if missing(ward_10_parent)
replace region_10_parent = region_15 if missing(region_10_parent)
replace district_10_parent = district_15 if missing(district_10_parent)

count  // 3,944, all matched!!

save "q6_FINAL_stata2.dta"


