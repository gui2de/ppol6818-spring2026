*Problem 1*
use "q1_psle_student_raw.dta"
keep s
rename s primitive_html
replace primitive_html = ustrtrim(primitive_html)
split primitive_html, parse("<TR>") limit(500) gen(row_) //split the code//
drop primitive_html
gen school_num = _n
reshape long row_, i(school_num) j(student_num)
keep if ustrregexm(row_, "PS[0-9]+-[0-9]+")
 rename row_ raw_data
gen cand_id = ustrregexs(1) if ustrregexm(raw_data, "(PS[0-9]+-[0-9]+)")
gen schoolcode = substr(cand_id, 1, 9)
gen prem_number = ustrregexs(1) if ustrregexm(raw_data, "([0-9]{11})")
gen gender = ustrregexs(1) if ustrregexm(raw_data, ">([MF])</FONT>")
gen name = ustrregexs(1) if ustrregexm(raw_data, "<P>([A-Z \.'\-]+)</FONT>")
gen kiswahili = ustrregexs(1) if ustrregexm(raw_data, "Kiswahili - ([A-F])")
gen english   = ustrregexs(1) if ustrregexm(raw_data, "English - ([A-F])")
gen maarifa   = ustrregexs(1) if ustrregexm(raw_data, "Maarifa - ([A-F])")
gen hisabati  = ustrregexs(1) if ustrregexm(raw_data, "Hisabati - ([A-F])")
gen science   = ustrregexs(1) if ustrregexm(raw_data, "Science - ([A-F])")
gen uraia     = ustrregexs(1) if ustrregexm(raw_data, "Uraia - ([A-F])")
gen average   = ustrregexs(1) if ustrregexm(raw_data, "Average Grade - ([A-F])")
keep schoolcode cand_id prem_number gender name kiswahili english maarifa hisabati science uraia average
order schoolcode cand_id name gender prem_number
label variable schoolcode "School Registration Code"
label variable cand_id "Candidate ID"
label variable name "Student Name"
save "q1_PSLE_CLEAN_STUDENTS.dta", replace 

*problem 2*
import excel "q2_CIV_populationdensity.xlsx", sheet("Population density") firstrow clear
rename NOMCIRCONSCRIPTION department
replace department = subinstr(department, "DEPARTEMENT DE ", "", .)
replace department = subinstr(department, "DEPARTEMENT D' ", "", .)
replace department = subinstr(department, "DEPARTEMENT D'", "", .)
replace department = trim(upper(department))
keep if strpos(department, "REGION") == 0 & strpos(department, "DISTRICT") == 0
duplicates drop department, force
save "density_clean.dta" //transfer excel to the dta file//
use "q2_CIV_Section_0.dta", clear
decode b06, gen(department_str)
replace department_str = trim(upper(department_str))
rename department_str department
merge m:1 department_str using "density_clean.dta"
drop _merge //drop the new variable//

*problem 3*
local num_enumerators = 19
cluster kmeans lat lon, k(19) name(group_cluster)
gen enumerator_id = group_cluster
label variable enumerator_id "Assigned Enumerator ID (1-19)"
cluster drop group_cluster
tab enumerator_id

*problem 4*
import excel "q4_Tz_election_2010_raw.xls", sheet("Sheet1") firstrow clear
rename THEUNI Region
rename B District
rename D Ward
replace Region = Region[_n-1] if missing(Region)
replace District = District[_n-1] if missing(District)
replace Ward = Ward[_n-1] if missing(Ward)
rename C Costituency
replace Costituency = Costituency[_n-1] if missing(Costituency)
rename E Candidate_name
rename F Sex_M
rename G Sex_F
rename H Political_party
rename I Votes
rename J Elected_candidate
destring Votes, replace ignore(",")
drop in 1/5
drop Sex_F
rename Sex_M Sex
replace Sex = "F" if Sex == ""
save "q5"

*problem 5*
use "q5_psle_2020_data.dta" 
gen ps_number = substr(schoolname, strrpos(schoolname, "PS"), .)
replace ps_number = trim(ps_number)
replace region_name = proper(region_name)
rename region_name Region
recast str13 Region, force
recast str9 ps_number, force
save "ps_number"

use "q5_school_location.dta"
rename NECTACentreNo ps_number

use "ps_number"
merge 1:m ps_number using "q5_school_location.dta"
drop if region==""
//I tried my best, but I still did not get n=17329//

*problem 6*
use "Tz_GIS_2015_2010_intersection.dta", clear
foreach var of varlist ward_gis_2017 ward_gis_2012 {
    replace `var' = trim(itrim(upper(`var')))
}
gsort ward_gis_2017 -overlap_percent
by ward_gis_2017: keep if _n == 1
rename ward_gis_2012 parent_ward_2012
label variable parent_ward_2012 "Original 2012 Parent Ward"
save "ward_2017_to_2012_crosswalk.dta"
// I tried my best to solve the problem 6, but it seems it is still diffcult for me to figure out how to solve it. The intersection file is likely "messy" because boundaries don't align perfectly. One 2015 ward might overlap a large chunk of its true 2010 parent, but also tiny slivers of neighboring 2010 wards due to GPS "noise" or slight boundary shifts. Since one 2015 ward may overlap multiple 2010 boundaries due to GPS shifts, we use the intersection data to identify which 2010 ward contains the largest percentage of area for each 2015 child. However, although I got some logic chains to solve this, but still I give up.




