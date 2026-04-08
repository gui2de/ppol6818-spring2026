******************************
******Stata 2 Assignment******
*******Stephanie Petrov*******
******************************

cd /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata2
global Stata2 /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata2

*******************QUESTION 1*********************

*build on your code from the previous assignment to create a student level dataset for these 138 schools

***first part of question - bonus from previous Stata assignment***

cd /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata1/assignment__Stata_1_export/q5 

infix str2000 rawline 1-2000 using "shl_ps0101114.html", clear //opening the html file in a way that's readable for stata
gen student_num = sum(regexm(rawline, "PS0101114-[0-9]{4}"))
drop if student_num == 0
gen cand_id     = regexs(1) if regexm(rawline, "(PS0101114-[0-9]{4})")
gen prem_number = regexs(1) if regexm(rawline, `"CENTER">([0-9]{11})</FONT>"')
gen sex         = regexs(1) if regexm(rawline, `"CENTER">(M|F)</FONT>"')
gen name        = regexs(1) if regexm(rawline, `"SIZE=1><P>([A-Z ]+)</FONT></TD>"')
gen kiswahili   = regexs(1) if regexm(rawline, "Kiswahili - ([A-E])")
gen english     = regexs(1) if regexm(rawline, "English - ([A-E])")
gen maarifa     = regexs(1) if regexm(rawline, "Maarifa - ([A-E])")
gen hisabati    = regexs(1) if regexm(rawline, "Hisabati - ([A-E])")
gen science     = regexs(1) if regexm(rawline, "Science - ([A-E])")
gen uraia       = regexs(1) if regexm(rawline, "Uraia - ([A-E])")
gen average     = regexs(1) if regexm(rawline, "Average Grade - ([A-E])") 

collapse (firstnm) cand_id prem_number sex name kiswahili english maarifa hisabati science uraia average, by(student_num)
drop student_num
gen schoolcode = "PS0101114"
rename maarifa knowledge
rename hisabati mathematics
br

cd /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata2
save "/Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata2/_1_data_export/shl_clean.dta",  replace

***second part of the question - build on the bonus to create new dataset***

use "$Stata2/_1_data_export/q1_psle_student_raw.dta", clear
gen schoolcode_clean = ""
replace schoolcode_clean = "PS" + regexs(1) if regexm(schoolcode, "ps([0-9]+)\.htm")
replace s = subinstr(s, "\r\n", "", .)

split s, p("<TR>") gen(row)
reshape long row, i(schoolcode) j(rownum)
drop if missing(row)
keep if regexm(row, "PS[0-9]+-[0-9]+")
gen cand_id = ""
replace cand_id = regexs(1) if regexm(row, "([A-Z]{2}[0-9]+-[0-9]+)")
gen prem_number = ""
replace prem_number = regexs(1) if regexm(row, ">([0-9]{11})<")
gen sex = ""
replace sex = regexs(1) if regexm(row, "SIZE=1><P ALIGN=.CENTER.>(M|F)<")
gen name = ""
replace name = regexs(1) if regexm(row, "VALIGN=.LEFT.[^>]*>.*<P>([^<]+)</FONT>") //creating the dataset

gen kiswahili   = ""
gen english     = ""
gen knowledge   = ""
gen mathematics = ""
gen science     = ""
gen uraia       = ""
gen average     = ""
replace kiswahili   = regexs(1) if regexm(row, "Kiswahili - ([A-E])")
replace english     = regexs(1) if regexm(row, "English - ([A-E])")
replace knowledge   = regexs(1) if regexm(row, "Maarifa - ([A-E])")
replace mathematics = regexs(1) if regexm(row, "Hisabati - ([A-E])")
replace science     = regexs(1) if regexm(row, "Science - ([A-E])")
replace uraia       = regexs(1) if regexm(row, "Uraia - ([A-E])")
replace average     = regexs(1) if regexm(row, "Average Grade - ([A-E])")

keep cand_id prem_number sex name kiswahili english knowledge mathematics science uraia average schoolcode_clean
rename schoolcode_clean schoolcode

save "all_schools_student_clean.dta", replace
describe



*******************QUESTION 2*********************

//household survey data and population density data of Côte d'Ivoire
///merge departmente-level density data from the excel sheet (CIV_populationdensity.xlsx) into the household data (CIV_Section_O.dta) 
//i.e. add population density column to the CIV_Section_0 dataset

import excel $Stata2/_1_data_export/q2_CIV_populationdensity.xlsx, firstrow clear
save CIV_populationdensity.dta, replace
list in 1/15

keep if strpos(NOMCIRCONSCRIPTION, "DEPARTEMENT") > 0 //only keeping department rows b/c that's what I want to merge by
gen department = lower(NOMCIRCONSCRIPTION) //new var in lowercase to match the master dataset
replace department = regexr(department, "departement d[eu]?[' ]+", "") //keep ONLY department name
replace department = strtrim(department) //removes any blanks
sort department
save CIV_populationdensity_department.dta, replace //new .dta


use $Stata2/_1_data_export/q2_CIV_Section_0.dta, clear //back to master dataset
codebook b06_departemen //this value is numeric; need to convert to string
decode b06_departemen, gen(department) // converting to string and creating a new variable for merging that matches the using datase
sort department 
merge m:1 department using "CIV_populationdensity_department.dta", generate(department_merge)
tab department_merge // 12,827 matched
br



*******************QUESTION 3*********************

*111 households in a village, assign these households to 19 enumerators, 6 surveys per enumerator per day 
*each enumerator is assigned 6 households close to each other
*write an algorithm that would auto assign each household 
*add a column and assign it a value 1-19 which can be used as enumerator ID

use $Stata2/_1_data_export/q3_GPS_Data.dta, clear
sort longitude latitude
gen enumerator_id = ceil(_n/6) //6 surveys per enumerator per day - this will work for other villages because it will sort households per location, then assign an enumerator to each household so that each enumerator surveys 6 households, except for the last enumerator who will only survey 3 because the total number of households (111) is not divisible by 19 or 6.
tab enumerator_id



*******************QUESTION 4**********************
*create a dataset in the wide form where each row is a unique ward
*votes received by each party are given in separate columns

use $Stata2/_1_data_export/q4_Tz_election_template.dta, clear 
br //taking a look at the template
sort ward_10

import excel $Stata2/_1_data_export/q4_Tz_election_2010_raw.xls, firstrow cellrange(A5) clear //importing the excel sheet
rename COSTITUENCY CONSTITUENCY
foreach var of varlist REGION DISTRICT CONSTITUENCY WARD  {
	replace `var' = `var'[_n-1] if `var' == ""
} //filling in the missing blanks with the appropriate value

drop if WARD==""

rename *, lower 
foreach var of varlist region district constituency ward {
	replace `var'=lower(`var')
}

//making sure all values and variables are lowercase to match the template
tab politicalparty
replace politicalparty = regexr(politicalparty, "[ -]+", "_") //removing spaces in party names
tab politicalparty
drop candidatename sex g electedcandidate k

encode ttlvotes, gen(votes_) //coding from string to numeric
collapse (sum) votes, by(region district constituency ward politicalparty) //collapsing data to get one row per ward
reshape wide votes_, i(region district constituency ward) j(politicalparty) string //reshape to wide
save Tz_election_CLEANED.dta, replace


*******************QUESTION 5*********************

*PSLE dataset contains data for 17,329 schools - we have region and district but need ward info
*school_location dataset has ward info for 19,733 schools
*identify ward information for 17,329 schools on PSLE dataset using school_location.dta
*final dataset should be the PSLE dataset + ward column (N=17,329)
*hint - might have some schools without ward information

use $Stata2/_1_data_export/q5_school_location.dta, clear
keep NECTACentreNo Ward //only want these two variables for the merge
replace NECTACentreNo = strtrim(NECTACentreNo)
replace NECTACentreNo = "" if NECTACentreNo == "n/a"
replace NECTACentreNo = "" if NECTACentreNo == "N/A"
drop if NECTACentreNo == ""
duplicates drop NECTACentreNo, force //remove duplicates, likely data error - schools that are matched to multiple wards
save "$Stata2/_1_data_export/school_location_ward.dta", replace
br

use "$Stata2/_1_data_export/q5_psle_2020_data.dta", clear
replace school_code_address = strtrim(school_code_address) //trim leading spaces
gen NECTACentreNo = upper(regexs(1)) if regexm(school_code_address, "shl_(ps[0-9]+)\.htm") //gen the NECTA variable for the merge

merge m:1 NECTACentreNo using "$Stata2/_1_data_export/school_location_ward.dta", ///
    keepusing(Ward) ///
    keep(1 3) ///
    gen(wardmerge)

count                       //17,329 schools
count if wardmerge == 3     //17,037 matches 
count if wardmerge == 1     //292 schools have no ward info
save "$Stata2/_1_data_export/q5_psle_with_ward_clean.dta", replace



