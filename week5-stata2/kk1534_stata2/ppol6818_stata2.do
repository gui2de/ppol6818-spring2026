**** Exp Design ***
*** Assigment Stata2 ***
*** Kenshi Kawade ***

if c(username) == "kkawade" {
    global wd "/Users/kkawade/GU_Class/ppol6818ex"
}

cd "$wd/week_5/02_data"

** Q.1 **--------------------------------------------------------

use q1_psle_student_raw.dta, clear

rename s data
* Split the data into separate columns for every table row
split data, parse("<TR>") gen(row)

* Reshape so each row is a Stata observation
gen obs_id = _n
reshape long row, i(obs_id) j(row_num)

* Keep only the rows that actually contain student data
* We look for the candidate ID pattern to filter out headers and summary tables
keep if ustrregexm(row, "PS\d+-\d+")

* Extract the variables
gen cand_id = ustrregexs(2) if ustrregexm(row, "(PS\d+)\s*-\s*([0-9]+)")
gen prem_number = ustrregexs(1) if ustrregexm(row, "CENTER.*>(\d{11})")
gen gender = ustrregexs(1) if ustrregexm(row, "CENTER.*>([MF])")
gen name = ustrregexs(1) if ustrregexm(row, "<P>([^<]+)</FONT></TD>")

* Extract Subject Grades
foreach s in Kiswahili English Maarifa Hisabati Science Uraia {
    gen `s' = ustrregexs(1) if ustrregexm(row, "`s' - ([A-Z])")
}
gen average = ustrregexs(1) if ustrregexm(row, "Average Grade - ([A-Z])")

drop obs_id row_num row data

replace schoolcode = subinstr(schoolcode, "shl_ps", "PS", .)
replace schoolcode = subinstr(schoolcode, ".htm", "", .)

save "$wd/week_5/03_output/q1ans_psle_student_clean.dta", replace

** Q.2 **--------------------------------------------------------
use q2_CIV_Section_0.dta, clear
de q2_CIV_Section_0.dta

* Cleaning for merge
import excel q2_CIV_populationdensity.xlsx, firstrow clear

gen department = ""
replace department = regexs(1) if regexm(NOMCIRCONSCRIPTION, "^DEPARTEMENT.*?([A-Za-zÀ-ÿ-]+)$") /// I got this from LLM
replace department = lower(department)
drop if department == ""
rename DENSITEAUKM popdens
label variable popdens "population density in the department (km^2)"

save "$wd/week_5/03_output/q2_CIV_department.dta", replace
* 

use q2_CIV_Section_0.dta, clear

decode b06_departemen, gen(department)
merge m:1 department using "$wd/week_5/03_output/q2_CIV_department.dta", keepusing(popdens)
drop _merge

save"$wd/week_5/03_output/q2ans_CIV_merged.dta", replace

** Q.3 **--------------------------------------------------------
use q3_GPS_Data.dta, clear

* set seed for reproducibility 
set seed 80715

* Create kmeans cluster with random sample sizes each
cluster kmeans lat lon, k(19) name(cluster_id)
 
* Deduce which id is closest to the cluster center and keep the closests ones
**Figure out what coordinates are the centers
bysort cluster_id: egen clus_lat = mean(latitude)
bysort cluster_id: egen clus_lon = mean(longitude)

* Use geodist command to generate a variable that shows each id's distance from center
geodist lat lon clus_lat clus_lon, gen(distcent)

* Now rank them based on center distance
bysort cluster_id (distcent): gen rank=_n

**Assign the 6 closest house, which meets the requirement. Additional houses are marked missing.
gen final_cluster_group = cluster_id if rank<=6

* Count and store which observations are missing (remaining)
count if fin == .
local remaining = r(N)

**Run a loop which assigns each remaining id to a new group_id
while `remaining' > 0 {
	
	*Store the id we are currently working on assigning
	quietly sum id if fin == .
	local remained_id = r(min) 
	
	*Find remained_id coordinates
	quietly sum lat if id == `remained_id'
	local remained_lat = r(mean)
	quietly sum lon if id == `remained_id'
	local remained_lon = r(mean)

	*Record current size of remained clusters
	capture drop remained_size //Drop this variable from previous loops
	bysort fin: egen remained_size = count(id)
	
	*Calculate distance from cluster center
	capture drop temp_dist //Drop this variable from previous loops 
	geodist `remained_lat' `remained_lon' clus_lat clus_lon, gen(temp_dist)
	
	*Don't look at full clusters or unassaigned groups
	quietly replace temp_dist = . if remained_size >=6 | fin == .
	
	*Sort so closest cluster is at the top
	sort temp_dist
	local best_cluster = fin[1]
	
	*Assign house to best cluster
	replace fin = `best_cluster' if id == `remained_id'
	
	*Rerun loop with new count of remaining houses
	quietly count if fin == .
	local remaining = r(N)
}

* Drop the temporary variables
drop clus_lat clus_lon distcent rank remained_size temp_dist

tab fin

rename fin enum

save "$wd/week_5/03_output/q3ans_19enums.dta", replace

** Q.4 **--------------------------------------------------------
import excel q4_Tz_election_2010_raw.xls, cellrange(A5) firstrow clear

* Cleaning 
drop K
replace SEX = "F" if G == "F"
drop G
drop in 1

/*
There are 19 pol party categories in template including "others", but I don't see it in this dataset
*/

* Filling missing values for each vars
foreach var in REGION DISTRICT COSTITUENCY WARD {
    replace `var' = `var'[_n-1] if `var' == ""
}

* Generate id for each ward and party
egen ward_id = group(WARD)
egen pol_id = group(POLITICALPARTY), label

local polname : value label pol_id

levelsof pol_id, local(ids)                
foreach l in `ids' {
    local polname_`l' : label `polname' `l'
    local polname2_`l' = subinstr("`polname_`l''", " - ", "_", .)
	local polname2_`l' = subinstr("`polname2_`l''", "-", "_", .)
	local polname2_`l' = subinstr("`polname2_`l''", " ", "_", .)

    display "Value `l' is labeled: `polname2_`l''"
}

bysort ward_id: egen totalcand = count(pol_id) /// how many candidates in each ward

* Cleaning TTLVOTES and making totalvotes for each ward
replace TTLVOTES = ustrregexra(TTLVOTES, "[^0-9.]", "") // delete UN OPP
destring TTLVOTES, replace
bysort WARD : egen totalvotes = sum(TTL)
rename TTLVOTES votes

drop ELECTEDCANDIDATE CANDIDATENAME SEX POLITICALPARTY

* Make each ward to have 18 party rows with votes = . if they dont have 
fillin ward_id pol_id
gsort +ward_id

* Fix because there are wards with multiple candidates from the same party
* Make each ward have votes for 18 parties
replace votes = votes[_n-1] + votes[_n] if ward_id[_n-1] == ward_id[_n] & pol_id[_n-1] == pol_id[_n] 
drop if ward_id[_n] == ward_id[_n+1] & pol_id[_n] == pol_id[_n+1] 

* Reshape
reshape wide votes, i(ward_id REGION DISTRICT COSTITUENCY) j(pol_id)
drop if _fillin == 1

* Loop through each id and rename the column to its Label
foreach v in `ids' {
   
    * Rename the wide variable (e.g., votes_1 -> CCM)
    capture rename votes`v' votes_`polname2_`v'' 
}

* Final cleaning
order WARD ward_id totalcand totalvote, a(COSTITUENCY)
drop _fillin

save "$wd/week_5/03_output/q4ans_Tz_election.dta", replace

** Q.5 **--------------------------------------------------------
use q5_school_location.dta, clear

rename NECTACentreNo school_code
replace school_code = subinstr(school_code,"PS", "", .)
replace school_code = subinstr(school_code, "n/a", "", .)
destring school_code, replace

drop if school_code == .
duplicates drop school_code, force

save "$wd/week_5/03_output/q5_school_location_cleaned.dta",replace

use q5_psle_2020_data.dta, clear

rename school_code_address school_code
replace school_code = subinstr(school_code, "shl_ps", "", .)
replace school_code = subinstr(school_code, ".htm", "", .)
destring school_code, replace

merge 1:1 school_code using "$wd/week_5/03_output/q5_school_location_cleaned.dta"

drop if _merge == 2 
drop _merge

* Final cleaning
replace schoolname = ustrregexra(schoolname, " - PS[0-9]+", "")
replace region_code = subinstr(region_code, "results/reg_", "", .)
replace region_code = subinstr(region_code, ".htm", "", .)
destring region_code, replace
replace district_code = subinstr(district_code, "distr_", "", .)
replace district_code = subinstr(district_code, ".htm", "", .)
destring district_code, replace

save "$wd/week_5/03_output/q5ans_school_ward.dta", replace

** Q.6 **--------------------------------------------------------
use Tz_GIS_2015_2010_intersection.dta, clear

rename ward_gis_2017 ward_15    // unique = 3544
rename ward_gis_2012 ward_10    // unique = 3061

gsort +ward_15 -perc
bysort ward_15: keep if _n == 1

unique ward_15

codebook ward_10 ward_15

tempfile gis_id
save `gis_id'

use Tz_elec_15_clean.dta, clear  // unique = 3640/3944

sort ward_15
replace tot = tot[_n-1] + tot[_n] if ward_15[_n-1] == ward_15[_n] 
drop if ward_15[_n] == ward_15[_n+1]

merge 1:1 ward_15 using `gis_id', keep(master match)
drop _merge

tempfile gis_15
save `gis_15'

use Tz_elec_10_clean.dta, clear  // unique = 3109/3333

sort ward_10
replace tot = tot[_n-1] + tot[_n] if ward_10[_n-1] == ward_10[_n] 
drop if ward_10[_n] == ward_10[_n+1]

merge 1:m ward_10 using `gis_15', keep(master match) // obs = 3547...

save "$wd/week_5/03_output/q6ans_matched1015.dta", replace

