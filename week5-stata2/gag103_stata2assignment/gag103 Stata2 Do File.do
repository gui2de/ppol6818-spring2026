***** Assignment Stata 2 *****
***** Gavin Gondalwala *****

// Global working directory:
global wd "/Users/gavinaligondalwala/Documents/Georgetown/Spring2026/ExperimentalDesign/Stata2/02_data" // Setting global for working directory for peer review

// Globals for Datasets:
global psle_raw "$wd/q1_psle_student_raw.dta"
global q2_excel "$wd/q2_CIV_populationdensity.xlsx"
global q2_section "$wd/q2_CIV_Section_0.dta"
global q3_gps "$wd/q3_GPS_Data.dta" // Note: had to rename this original file. Download did not have an underscore between GPS and Data
global q4_tz_excel "$wd/q4_Tz_election_2010_raw.xls"
global tz_elec_15_raw "$wd/Tanzania_election_2015_raw.dta"
global tz_elec_15_clean "$wd/Tz_elec_15_clean.dta"
global tz_elec_10_clean "$wd/Tz_elec_10_clean.dta"
global tz_15_10_gis "$wd/Tz_GIS_2015_2010_intersection.dta"
global kenya_baseline "$wd/kenya_education_baseline.dta"
global kenya_endline  "$wd/kenya_education_endline.dta"
global store_location "$wd/store_location_bufferzone.dta"
global q5_psle "$wd/q5_psle_2020_data.dta"
global q5_location "$wd/q5_school_location.dta"

*************************************************************

***** Question 1 *****

use $psle_raw, clear

// Cleaning Data to Extract Variables 
keep s
rename s source_html
gen school_row = _n
split source_html, parse("<TR>") limit(300) gen(var) // Extracts HTML into observations
drop source_html

// Reshape School-Candidate ID
reshape long var, i(school_row) j(row_number)
keep if ustrregexm(var, "PS[0-9]+-[0-9]+") 
rename var raw_data

// Extracting School Information
gen school_id=ustrregexs(1) if ustrregexm(raw_data, "(PS[0-9]+-[0-9]+)") // Creates a school ID based on a recognized PS expression
gen schoolcode=substr(school_id, 1, 9)

gen prem_number=ustrregexs(1) if ustrregexm(raw_data, "([0-9]{11})")

gen gender=""
replace gender="M" if ustrregexm(raw_data, ">M</FONT>") // Searching raw data for an individual M or F offset by a font marker
replace gender="F" if ustrregexm(raw_data, ">F</FONT>")

gen name=ustrregexs(1) if ustrregexm(raw_data, "<P>([A-Z ]+)</FONT>")

gen kiswahili=ustrregexs(1) if ustrregexm(raw_data, "Kiswahili - ([A-F])")
gen english=ustrregexs(1) if ustrregexm(raw_data, "English - ([A-F])")
gen maarifa=ustrregexs(1) if ustrregexm(raw_data, "Maarifa - ([A-F])")
gen hisabati=ustrregexs(1) if ustrregexm(raw_data, "Hisabati - ([A-F])")
gen science=ustrregexs(1) if ustrregexm(raw_data, "Science - ([A-F])")
gen uraia=ustrregexs(1) if ustrregexm(raw_data, "Uraia - ([A-F])")
gen average=ustrregexs(1) if ustrregexm(raw_data, "Average Grade - ([A-F])")

keep schoolcode school_id prem_number gender name kiswahili english maarifa hisabati science uraia average

*************************************************************

***** Question 2 *****

// Importing Excel file:
tempfile q2_exceltemp
import excel $q2_excel, firstrow clear
keep if strpos(department, "DEPARTEMENT")>0

// Cleaning Excel for Merge
replace department = lower(department)
replace department = regexr(department, "^departement (d'|de|du )?", "") // Removes everything other than the name. Regexr = replace matched text
replace department = trim(department) // Removes spaces
save `q2_exceltemp'

// Cleaning Master
use $q2_section
describe
rename b04 district
rename b05 region
rename b10 village
rename b11 neighborhood
decode b06, generate(department) // Makes a string variable based on labels for merge
order department, after(b06)

tab mil, missing nol
tab mil, missing
rename mil urban // Redefining variable for clarity
replace urban=0 if urban==2
label define urban_lab 0 "Rural" 1 "Urban"
label values urban urban_lab 
replace department="arrah" if department=="arrha" // Addresses a misspelling impacting merge.

// Merging
merge m:1 department using `q2_exceltemp'
tab _merge
list department if DENSITEAUKM==.
compare department DENSITEAUKM // All jointly defined
drop _merge
rename DENSITEAUKM pop_density
rename SUPERFICIEKM2 area
rename POPULATION population

*************************************************************

***** Question 3 *****

use $q3_gps, clear
describe
isid id // 111 unique IDs/HHs

sort latitude longitude // Sorts by latitude then longitude to get homes closest together
gen enum_id = ceil(_n/6) // Creates groupings of 6 surveys. Adjust 6 for number of surveys you wish each enumerator to give.
tab enum // 6 for enumerators 1-18, 3 for enumerator 19

*************************************************************

***** Question 4 *****

import excel $q4_tz_excel, cellrange(A5) firstrow clear
drop in 1
drop K
save $wd/q4_tz.dta, replace
global q4_tz "$wd/q4_tz.dta"
use $q4_tz, clear

// Cleaning
generate male=1 if SEX=="M"
replace male=0 if G=="F"
drop SEX G
order male, after(CANDIDATENAME)

tab ELECTED, missing // 3,331 elected, 4590 missing
generate elected=1 if ELECTED=="ELECTED"
replace elected=0 if ELECTED!="ELECTED"
compare elected ELECTED // 3331 jointly defined
order elected, after(TTLVOTES)
drop ELECTED

tab TTLVOTES // 599 unopposed
replace TTLVOTES="-998" if TTLVOTES=="UN OPPOSSED" // Coding unopposed as -998
destring TTLVOTES, replace
replace TTLVOTES=. if TTLVOTES==-998

foreach var of varlist _all {
    local lowername = lower("`var'")
    rename `var' `lowername'
} // Makes all variables lowercase

count if ward=="" // 4,588 missing ward values
replace ward=ward[_n-1] if missing(ward) // Fills missing wards

rename costituency constituency
count if constituency=="" // 7,732 missing
replace constituency=constituency[_n-1] if missing(constituency)

count if district=="" // 7,790 missing values
replace district=district[_n-1] if missing(district)

count if region=="" // 7,900 missing values
replace region=region[_n-1] if missing(region)

tab political, missing // 18 political parties, none missing
replace political="JAHAZI-ASILIA" if political=="JAHAZI ASILIA"
replace political=regexr(political, "\s*-\s*", "-")

// Reshape
drop elected
sum if ward=="NANGANDO" & politicalparty=="CCM" // 1812
sum ttlvotes if ward=="UTENGULE" & politicalparty=="CCM" // 3108

collapse (sum) ttlvotes, by(ward politicalparty)
duplicates report ward political // No duplicates, collapse successful
replace politicalparty = subinstr(politicalparty, "-", "_", .) // Removes hyphens (not allowed in var names)

reshape wide ttlvotes, i(ward) j(political) string

*************************************************************

***** Question 5 *****

// Cleaning location file for merge
tempfile clean_location

use $q5_location, clear
rename NECTA school_code
duplicates report school_code
duplicates tag school_code, generate(dup_marker)
gsort -dup // 1,785 duplicates are n/a. 
count if school_code=="n/a" // 1,786
replace school_code="." if school_code=="n/a" // Replaces n/a with appropriate missing values for merge
destring Standard*, replace
generate examinees_standard7=StandardVIIBoys+StandardVIIGirls, after(StandardVIIGirls) // Generates a variable to calculate if a school has 7th graders. PSLE is only taken by 7th graders, so duplicate schools with no 7th graders are dropped.
drop if examinees_standard7==0 // Eliminates schools with no testers
drop dup_marker

drop if School=="MWILAMVYA ENGLISH MEDIUM" // The only duplicate that remains is PS0608042. Since Master set does not reference "English Medium", the school "MWILAMVYA ENGLISH MEDIUM" is being dropped from the dataset.

save `clean_location'

tempfile clean_no_m
drop if school_code=="."
keep Ward School school_code
save `clean_no_m'


/*
I was trying to find a way to make more matches than just school-code based by generating markers based on location, but I ran into too many duplicates. Peer reviewer, I would love if you have any insight into how this could work, if it could! It was a longshot on my part; this is not a note I would put into an official submission, but I would appreciate help from a peer review if you have insight!

// Trying to match schools with missing codes
tempfile clean_loc_nocode
use `clean_location'
drop if school_code !="."
duplicates report School
duplicates tag School, generate(dup_marker)
drop dup
replace Region=strupper(Region)
* old: generate no_loc_code=word(School, 1) + "_" + word(Region, 1)
gen no_loc_code = word(School, 1) + "_" + word(School, 2) + "_" + word(Region, 1)
duplicates report no_loc_code
duplicates tag no_loc_code, generate(dup_marker)
drop if dup_marker>0
drop dup

save `clean_loc_nocode'

// Master:No Loc
use $q5_psle // Need to parse school_code_address. get schoolcode number on its own, match JUST PS######### from NECTACentreNo
gen school_code = ustrregexs(1) if ustrregexm(school_code_address, "_(.*?)\.htm") // Extracts the school code for merge
replace school_code=strupper(school_code) // Matching for merge
* old: generate no_loc_code=word(schoolname, 2) + "_" + word(region_name, 1)
gen no_loc_code = word(schoolname, 1) + "_" + word(schoolname, 2) + "_" + word(region_name, 1)

duplicates report no_loc_code
duplicates tag no_loc_code, generate(dup_marker)
drop if dup_marker>0 & school_code==""
drop dup
merge 1:1 no_loc_code using `clean_loc_nocode' // Matched 6 schools with no school code
drop if school_code=="" // Removes observations from Using Only
*/

// Cleaning Master
use $q5_psle // Need to parse school_code_address. get schoolcode number on its own, match JUST PS######### from NECTACentreNo
gen school_code = ustrregexs(1) if ustrregexm(school_code_address, "_(.*?)\.htm") // Extracts the school code for merge
replace school_code=strupper(school_code) // Matching for merge

// Merge
merge 1:1 school_code using `clean_no_m'
drop if schoolname==""
order Ward, after(district_name)
drop School _merge school_code

















