*Problem 1*
cd "C:\Users\24547\Desktop\stata2"
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
/*Comments from Ziqiao
All codes in question 1 ran smoothly.
The code ran completely from top to bottom without any errors or breaks.
I really liked your strategy of splitting the string by the <TR> tag and then using reshape long. It's a very clever and efficient way to isolate each student's HTML block into a separate row before applying the regular expressions.
*/

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
merge m:1 department using "density_clean.dta"
drop _merge //drop the new variable//

/*Comments from Ziqiao
The code stopped with the error: variable department_str not found r(111);.
I found that right before the merge command, you correctly renamed the variable to department (rename department_str department). However, in the very next line, you used the old name department_str as the merge key. I fixed it by changing the line to merge m:1 department using "density_clean.dta", and then it worked perfectly!
On the line save "density_clean.dta", I highly recommend adding , replace at the end (save "density_clean.dta", replace). Without it, if someone runs your Do-file twice, Stata will throw an error saying the file already exists.
*/

*problem 3*
use "q3_GPS Data.dta", clear
local num_enumerators = 19
cluster kmeans lat lon, k(19) name(group_cluster)
gen enumerator_id = group_cluster
label variable enumerator_id "Assigned Enumerator ID (1-19)"
cluster drop group_cluster
tab enumerator_id
/*Comments from Ziqiao
The code also broke at Question 3. It stopped with the error: variable lat not found r(111);
This happened because the dataset for Question 3 wasn't loaded into Stata's memory before running the cluster command.
I added the use "..." , clear command right before.
*/

*problem 4*
import excel "q4_Tz_election_2010_raw.xls", sheet("Sheet1") firstrow clear
rename A Region
rename B District
rename C Costituency
rename D Ward
rename E Candidate_name
rename F Sex_M
rename H Political_party
rename I Votes

replace Region = Region[_n-1] if missing(Region)
replace District = District[_n-1] if missing(District)
replace Costituency = Costituency[_n-1] if missing(Costituency)
replace Ward = Ward[_n-1] if missing(Ward)

destring Votes, replace force 

replace Sex_M = "F" if Sex_M == ""
rename Sex_M Sex

save "q4_clean_long.dta", replace
/*Comments from Ziqiao
The destring Votes command failed and returned Votes: contains characters not specified in ignore(); no replace.
This happened because you ran destring before dropping the first 5 rows (drop in 1/5). At the time of destringing, the 4th row still contained the string header "TTL VOTES", which prevented Stata from converting the column to numeric.
Q4 also requires aggregating the total votes/candidates and reshaping the data from "long" to "wide" format, so you need to use collapse and reshape wide
*/
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

***Revised code
use "q5_school_location.dta", clear
rename NECTACentreNo ps_number
tempfile location_dict 
save `location_dict'

use "q5_psle_2020_data.dta", clear
gen ps_number = substr(schoolname, strrpos(schoolname, "PS"), .)
replace ps_number = trim(ps_number)
replace region_name = proper(region_name)
rename region_name Region

merge m:1 ps_number using `location_dict'


drop if _merge == 2  
drop _merge

/*Comments from Ziqiao
Different Approach: I think it's a great option to use strrpos and substr
Error: The code breaks at the merge step with a variable ps_number not found error. This happens because you renamed NECTACentreNo to ps_number in the location dataset, but you didn't save the file before running use "ps_number".
At the very end, drop if region=="" will break because Stata is case-sensitive and you renamed the variable to Region
*/

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

/*Comments from Ziqiao
I think your code to build the crosswalk is conceptually correct.The only remaining steps were to merge 1:1 this crosswalk into the 2015 election dataset, and then merge m:1 that result into the 2010 dataset.
*/


