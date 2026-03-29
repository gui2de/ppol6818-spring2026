*-------------------------*
* Stata Assignment 2      |
* Warren Burroughs        |
*                         |
*-------------------------|


* Your directory here:
global wd "C:\Users\warre\OneDrive\Desktop\Georgetown\SecondSemester\Experimental_Design\Assignments\assignment_Stata_2\01_data"
cd $wd



clear
*Question 1*

use q1_psle_student_raw.dta


*Step 1) Reshape dataset to prepare for data extraction
*---------------------------------------------------------
*Split the html links so each variable has a student
split s, parse(">PS") gen(student_num_)

*Reshape the data so that the dataset is in long format
gen school_id = _n, bef(s)
reshape long student_num_@, i(school_id) j(student)

*Drop extra variables
drop if student_num==""


*Step 2) Extract data
*-------------------------------------------------------------
*Generate Student Variables
gen cand_no = ustrregexs(1) if ustrregexm(student_num_, "(\d+-\d+)\s*<\s*(/FONT)")
gen prem_no = ustrregexs(1) if ustrregexm(student_num_, "(201\d+)\s*<\s*(/FONT)")
gen gender = ustrregexs(1) if ustrregexm(student_num_, "(M)\s*<\s*(/FONT)")
replace gender = ustrregexs(1) if ustrregexm(student_num_, "(F)\s*<\s*(/FONT)")
gen name = ustrregexs(2) if ustrregexm(student_num_, "(<P)\s*>\s*([A-Z]+\s*[A-Z]+\s*[A-Z]+)")
gen kiswahili_grade = ustrregexs(2) if ustrregexm(student_num_, "(Kiswahili)\s*-\s*([A-Z])")
gen english_grade = ustrregexs(2) if ustrregexm(student_num_, "(English)\s*-\s*([A-Z])")
gen maarifa = ustrregexs(2) if ustrregexm(student_num_, "(Maarifa)\s*-\s*([A-Z])")
gen hisabati= ustrregexs(2) if ustrregexm(student_num_, "(Hisabati)\s*-\s*([A-Z])")
gen science= ustrregexs(2) if ustrregexm(student_num_, "(Science)\s*-\s*([A-Z])")
gen uraia= ustrregexs(2) if ustrregexm(student_num_, "(Uraia)\s*-\s*([A-Z])")
gen average= ustrregexs(2) if ustrregexm(student_num_, "(Average Grade)\s*-\s*([A-Z])")

*Drop and replace code
drop student_num_ s
drop if cand_no == ""
replace schoolcode = subinstr(schoolcode, "shl_ps", "PS", .)
replace schoolcode = subinstr(schoolcode, ".htm", "", .)
bysort school_id: replace student = _n







*--------------------------------------------------------------------------------
clear
*Question 2*
*Step 1) Import Excel with variables as firstrow
*-------------------------------------------------
import excel q2_CIV_populationdensity.xlsx, firstrow


*Step 2) Data cleaning to match the master file 
*-------------------------------------------------
*Drop all observations that are not department level data
keep if strpos(NOMCIRCONSCRIPTION, "DEPARTEMENT") != 0

*Make the observations and variables lowercase
foreach v of varlist * {
	capture replace `v' = strlower(`v')
}
rename *, lower

*Clean department level data so that they no longer include the word department or their prefixes
replace nomcirconscription = subinstr(nomcirconscription, "departement d' ", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "departement d'", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "departement du ", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "departement de ", "", .)

*Rename to match master
rename nomcirconscription dept

*Save
save q2_excel_import.dta, replace


*Step 3) Clean and Merge 
*------------------------------------------------------------
clear
use q2_CIV_Section_0.dta

*Use decode to turn variable from int to string
decode b06_departemen, gen(dept)

*Clean mispelled observations
replace dept = "arrah" if dept == "arrha"

*Merge many to 1
merge m:1 dept using "q2_excel_import.dta"

drop _merge







*--------------------------------------------------------------------------------


clear
*Question 3*
use q3_GPS_Data.dta

set seed 4000 /// So we get the same group each time

*Step 1) Create spatial groups: 
*--------------------------------------------------
**Use "cluster kmeans" command to create 19 clusters, using the mean of latitude and longitude and longitude as the center.
cluster kmeans lat lon, k(19) name(cluster_id)

sort cluster_id
tab cluster_id
//Unfortunately, these groups are not equal!
//Some enumerator's will get lots of villages, and some will get few
//We want each to have 6 to make the work fair
 
 
*Step 2) Deduce which id is closest to the cluster center and keep the closests ones 
*---------------------------------------------------------------------------
**Figure out what coordinates are the centers
bysort cluster_id: egen clus_lat = mean(latitude)
bysort cluster_id: egen clus_lon= mean(longitude)

**Use geodist command to generate a variable that shows each id's distance from center
geodist latitude longitude clus_lat clus_lon, gen(distance_center)

**Now rank them based on distance
bysort cluster_id (distance_center): gen rank=_n

**Assign the 6 closest house. Additional houses are marked missing.
gen final_cluster_group = cluster_id if rank<=6


*Step 3) Assign remaining ids with new spatial groups 
*-------------------------------------------------------
**Count and store which observations are missing
count if final_cluster_group == .
local remaining = r(N)

**Run a loop which assigns each remaining id to a new group_id
while `remaining' > 0 {
	
	*Store the id we are currently working on assigning
	quietly sum id if final_c == .
	local current_id = r(min) 
	//Takes the next id reamining and stores it as 'current_id'
	//The minimum value is always the next remaining id for every loop
	
	*Find current_id coordinates
	quietly sum latitude if id == `current_id'
	local cur_lat = r(mean)
	quietly sum longitude if id == `current_id'
	local cur_lon = r(mean)
	//Since only one coordinate for `current_id', the mean is always the right latitude and longitude
	
	*Record current size of cluster
	capture drop current_size //Drop this variable from previous loops
	bysort final_cluster_group: egen current_size = count(id)
	//This variable counts the number of observations in each final cluster group-- giving us the current size
	
	*Calculate distance from cluster center
	capture drop temp_dist //Drop this variable from previous loops 
	geodist `cur_lat' `cur_lon' clus_lat clus_lon, gen(temp_dist)
	//Creates a variable that measures the distance of the current id to each cluster's coordinate.
	
	*Don't look at full clusters or unassaigned groups
	quietly replace temp_dist = . if current_size >=6 | final_cluster_group == .
	
	*Sort so closest cluster is at the top
	sort temp_dist
	local best_cluster = final_cluster_group[1]
	//We've now found the best cluster for this ID!
	
	*Assign house to best cluster
	replace final_cluster_group = `best_cluster' if id == `current_id'
	//For this id, mark the final_cluster_group variable as their best cluster
	
	*Rerun loop with new count of remaining houses
	quietly count if final_cluster_group == .
	local remaining = r(N)
}


*Step 4) Clean up 
*--------------------------------------------------------------
* Drop the temporary variables
drop clus_lat clus_lon distance_center rank current_size temp_dist

* View final group sizes
tabulate final_cluster



*-------------------------------------------------------------------------------



clear
*Question 4
**Step 1) Import File 
*-----------------------------------------------------------
**Make a global of the excel file
global TanzaniaPSLE "q4_Tz_election_2010_raw.xls"

**Trying to open the excel file results in broken data
import excel $TanzaniaPSLE, cellrange(A5:I7927) firstrow
//Specifying cell range drops title
//First row becomes varnames


**Step 2) Clean data
*-----------------------------------------------------------
*Drop Sex (not in template)
drop SEX G

*Ensure that there are no extra spaces in the string variables
replace REGION = trim(REGION)
replace DISTRICT = trim(DISTRICT)
replace COSTITUENCY = trim(COSTITUENCY)
replace WARD = trim(WARD)

*Fix formatting
replace WARD = WARD[_n-1] if missing(WARD)
replace COSTITUENCY = COSTITUENCY[_n-1] if missing(COSTITUENCY)
replace DISTRICT = DISTRICT[_n-1] if missing(DISTRICT)
replace REGION = REGION[_n-1] if missing(REGION)
drop if _n==1

*Remove characters that shouldn't be in varnames
replace POLITICALPARTY = subinstr(POLITICALPARTY, " - ", "_", .)
replace POLITICALPARTY = subinstr(POLITICALPARTY, "-", "_", .)
replace POLITICALPARTY = subinstr(POLITICALPARTY, " ", "", .)


**Step 3) Generate and clean variables in preperation for reshaping 
*-------------------------------------------------------------------
*Generate a variable that counts how many candidates are running in each ward
bysort REGION DISTRICT COSTITUENCY WARD: egen tot_cand = count(WARD)
order tot_cand, af(WARD)

*Generate a variable that displays the total votes in each ward
replace TTL = "0" if regexm(TTL, "UN OPPOSSED") == 1 //Need numeric observation
destring TTL, replace
bysort REGION DISTRICT COSTITUENCY WARD: egen ward_total_votes = total(TTLVOTES)

*Generate an id variable that uniquely identifies each observation to easily sort the data
sort REGION DISTRICT COSTITUENCY WARD
gen id = _n

*Make each observation and variable lowercase
foreach v of varlist * {
	capture replace `v' = strlower(`v')
}
rename *, lower

*Rename for efficiency
rename ttlvotes votes


**Step 4) Reshape and Clean 
*---------------------------------------------------------------
*Reshape using votes as the stub, region/district/costituency/candidatename as the unique identification, and politicalparty as the observations becoming variables. Use string option as j is a string variable.
reshape wide votes, i(region district cost ward candidatename) j(politicalparty) string

*Order variables
order tot_cand ward_total_votes id, af(ward)
order id, af(ward_total_votes)

*Generate a variable that identifies which number a candidate is within a ward
sort id
bysort region district cost ward: gen ward_num = _n, af(id)


*We need to collapse the dataset so there's only on ward observation per constituency
*By generating a variable that shows the total of a party's number of votes, each observation within a ward in this new variable has the number of votes, allowing us to collapse later.
foreach var of varlist votes* {
	bysort region district cost ward: egen _`var' = total(`var') if `var' != 0 //Ignore unopposed candidates for now; will address in the loop after next
	order _`var', af(`var')
}

*Note missings
foreach var of varlist _votes*{
	replace `var' = . if `var' == 0 
}

*Address candidates that ran unopposed and drop the variable made by the reshaping
foreach var of varlist votes*{
	replace _`var' = 0 if `var'==0
	drop `var'
}

*Make the dataset display one ward per observation per costituency
duplicates drop cost ward, force


*Step 5) Finishing Touches 
*-----------------------------------------------------
drop ward_num candidatename
sort id
replace id = _n //Update id variable to reflect current dataset

**Note: There's a variable called votes_other in the template and I have no idea why there is one observation in that variable. The data from the excel document gives no indication as to why it is labeled as other, especially since that both parties running in this district (CCM and CUF) are already accounted for in the other variables. 




*-----------------------------------------------------------------------------



*Question 5*
clear
use q5_psle_2020_data.dta

*Edit variables to match other dataset
replace school_code = subinstr(school_code_address, "shl_ps", "PS", .)
replace school_code = subinstr(school_code_address, ".htm", "", .)

save q5_progress.dta, replace

*Clean data to match other dataset
clear
use q5_school_location.dta

rename NECTA school_code_address
drop if school_code_address == "n/a"
duplicates drop school_code_address, force
replace school_code_address = trim(school_code_address)

save q5_progress2nd.dta, replace

clear
use q5_progress.dta
replace school_code_address = trim(school_code_address)

merge 1:1 school_code_address using q5_progress2nd.dta

drop if _merge==2 // These schools did not exist in our master dataset
drop region_name district_name schoolname //Duplicates
drop _merge





