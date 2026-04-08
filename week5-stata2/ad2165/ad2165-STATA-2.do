//Abhinav Dutt STATA 2 assignment 1st March, 2026
//Worked together with Warren Burroughs 



global wd "C:\Github Local\ppol6818-spring2026\week5-stata2"
cd `$wd'



clear
//Question 1

use q1_psle_student_raw.dta


split s, parse(">PS") gen(student_num_) //splitting the html links and assigning every student to a different variable 

gen school_id = _n, bef(s)

reshape long student_num_@, i(school_id) j(student) //reshaping to long 


drop if student_num=="" // dropping missing/extras


//extracting data and generating student variables 

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

//finally, dropping and replacing 

drop student_num_ s
drop if cand_no == ""
replace schoolcode = subinstr(schoolcode, "shl_ps", "PS", .)
replace schoolcode = subinstr(schoolcode, ".htm", "", .)
bysort school_id: replace student = _n








clear
// Question 2

import excel q2_CIV_populationdensity.xlsx, firstrow // importing from excel, with first row as variable 




keep if strpos(NOMCIRCONSCRIPTION, "DEPARTEMENT") != 0 //dropping all data that is not department level data


foreach v of varlist * {
	capture replace `v' = strlower(`v') //making everything lowercase 
}
rename *, lower

*Clean department level data so that they no longer include the word department or their prefixes
replace nomcirconscription = subinstr(nomcirconscription, "departement d' ", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "departement d'", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "departement du ", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "departement de ", "", .)


rename nomcirconscription dept //to match master file 


save q2_excel_import.dta, replace //saving copy 
clear



use q2_CIV_Section_0.dta


decode b06_departemen, gen(dept) //converting int to string 


replace dept = "arrah" if dept == "arrha" //correcting mispelled 


merge m:1 dept using "q2_excel_import.dta"

drop _merge




//Question 3

use "q3_GPS Data.dta", clear

**Use "cluster kmeans" command to create 19 clusters, using the mean of latitude and longitude and longitude as the center.
cluster kmeans lat lon, k(19) name(cluster_id) //using cluster kmeans  to create spatial groups (side note: this command is amazing and I'm so impressed by it haha). Creating 19 cluters using mean of latitude and longitude to create center points. 

sort cluster_id
tab cluster_id

//We now have groups but the groups are of unequal size because that is the spatially most efficent outcome. However, we have to correct this so that each enumerator has roughly 6 houses so that survery work is distributed equally.
 

//coding the center coordinate 
bysort cluster_id: egen clus_lat = mean(latitude)
bysort cluster_id: egen clus_lon= mean(longitude)


geodist latitude longitude clus_lat clus_lon, gen(distance_center) //using geodist to calculate distance to cluster center 


bysort cluster_id (distance_center): gen rank=_n //rank based on distance 

gen final_cluster_group = cluster_id if rank<=6 //Making sure each cluter is capped at 6 


count if final_cluster_group == . //counting all unassigned houses due to our cluster cap being 6 
local remaining = r(N)

//loop to assign unassined houses to existing clusters that have less than 6 
while `remaining' > 0 {
	
	//storing current ID 
	quietly sum id if final_c == .
	local current_id = r(min) 
	//Takes the next id reamining and stores it as 'current_id'
	//The minimum value is always the next remaining id for every loop
	
	
	quietly sum latitude if id == `current_id'
	local cur_lat = r(mean)
	quietly sum longitude if id == `current_id'
	local cur_lon = r(mean)
	//Since there is only one coordinate for `current_id', the mean is always the desired latitude and longitude
	
	//Recording current size of cluster: 
	capture drop current_size //Drop this variable from previous loops
	bysort final_cluster_group: egen current_size = count(id)
	//This variable counts the number of observations in each final cluster group 
	
	//calculating distance from current cluster 
	capture drop temp_dist //Drop this variable from previous loops 
	geodist `cur_lat' `cur_lon' clus_lat clus_lon, gen(temp_dist)
	//Creates a variable that measures the distance of the current id to each cluster's coordinate.
	
	//ignoring already full flusters
	quietly replace temp_dist = . if current_size >=6 | final_cluster_group == .
	
	//sorting so closest is at the top 
	sort temp_dist
	local best_cluster = final_cluster_group[1]
	//We have now find the best cluster 
	
	//Assigning house to its best cluster 
	replace final_cluster_group = `best_cluster' if id == `current_id'
	//For this id, mark the final_cluster_group variable as their best cluster
	
	//loops now runs for next unassigned house 
	quietly count if final_cluster_group == .
	local remaining = r(N)
}



drop clus_lat clus_lon distance_center rank current_size temp_dist //droping temporary variables that we no longer need 

tabulate final_cluster //displays output 




clear

//Question 4


global TanzaniaPSLE "q4_Tz_election_2010_raw.xls" //new global for ease 

//Excel file has issues that we need to work with (this was very challenging)

import excel $TanzaniaPSLE, cellrange(A5:I7927) firstrow //Specifying cell range to drop title



drop SEX G //not in template 


replace REGION = trim(REGION)
replace DISTRICT = trim(DISTRICT)
replace COSTITUENCY = trim(COSTITUENCY)
replace WARD = trim(WARD)
//above makes sure that there are no extra spaces 


replace WARD = WARD[_n-1] if missing(WARD)
replace COSTITUENCY = COSTITUENCY[_n-1] if missing(COSTITUENCY)
replace DISTRICT = DISTRICT[_n-1] if missing(DISTRICT)
replace REGION = REGION[_n-1] if missing(REGION)
drop if _n==1
//above fixes formatting issues 


replace POLITICALPARTY = subinstr(POLITICALPARTY, " - ", "_", .)
replace POLITICALPARTY = subinstr(POLITICALPARTY, "-", "_", .)
replace POLITICALPARTY = subinstr(POLITICALPARTY, " ", "", .)
//removing characters that shouldn't be there! 



bysort REGION DISTRICT COSTITUENCY WARD: egen tot_cand = count(WARD)
order tot_cand, af(WARD)
// counting candidates running in each ward 


replace TTL = "0" if regexm(TTL, "UN OPPOSSED") == 1 //Need numeric observations
destring TTL, replace
bysort REGION DISTRICT COSTITUENCY WARD: egen ward_total_votes = total(TTLVOTES) //total votes in each ward 


sort REGION DISTRICT COSTITUENCY WARD
gen id = _n //so that we have unique IDs! 


foreach v of varlist * {
	capture replace `v' = strlower(`v')
}
rename *, lower //making everything lowercase 

rename ttlvotes votes



reshape wide votes, i(region district cost ward candidatename) j(politicalparty) string //reshaping according to desired specifications. String option done separately as it is string and done using j variable. 


order tot_cand ward_total_votes id, af(ward)
order id, af(ward_total_votes)


sort id
bysort region district cost ward: gen ward_num = _n, af(id) //identifying the number for the candidate within the ward 


//Collapsing so that there is only one ward within every constituency 

//Total number of party votes 
foreach var of varlist votes* {
	bysort region district cost ward: egen _`var' = total(`var') if `var' != 0 //Ignoring unopposed candidates for now; will address in next loop
	order _`var', af(`var')
}


foreach var of varlist _votes*{
	replace `var' = . if `var' == 0 //noting all missings 
}

//this is where we address unopposed candidates 
foreach var of varlist votes*{
	replace _`var' = 0 if `var'==0
	drop `var'
}


duplicates drop cost ward, force //dropping duplicates 



drop ward_num
sort id
replace id = _n //Updating ID to match current data

//votes_other column has one observation and we were all confused about that 




//Question 5

clear
use q5_psle_2020_data.dta


replace school_code = subinstr(school_code_address, "shl_ps", "PS", .)
replace school_code = subinstr(school_code_address, ".htm", "", .)
//above is done to match data set 

save q5_progress.dta, replace

//Cleaning data to match other dataset
clear
use q5_school_location.dta

rename NECTA school_code_address
drop if school_code_address == "n/a"
duplicates drop school_code_address, force
replace school_code_address = trim(school_code_address)

save q5_progress2nd.dta //saving 

clear
use q5_progress.dta
replace school_code_address = trim(school_code_address)

merge 1:1 school_code_address using q5_progress2nd.dta

drop if _merge==2 //we don't want these as _merge should be 

//Didn't have time to attempt bonus question as I was competing in a pokemon tournament in Seattle this weekend. Submitting this from the Seattle airport! Will attempt the bonus next time for sure!! 





