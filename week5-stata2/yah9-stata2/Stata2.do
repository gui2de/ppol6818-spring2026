cd "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment"


*******
**Bonus Question 
*******

/*

This task involves string cleaning and data wrangling. We scrapped student
data for a school from a Tanzanian government website. Unfortunately, the formatting of the
data is a mess. Your task is to create a student level dataset with the following variables:
schoolcode, cand_id, gender, prem_number, name, grade variables for: Kiswahili, English,
maarifa, hisabati, science, uraia, average.
Note: This is a student level dataset, and should have 16 rows (same as the number of
students in that school).

*/

***********
**Question 1
***********

/*

This builds on the bonus from the previous Stata assignment. We downloaded the PSLE data of students from 138 schools in Arusha District in Tanzania (previously we only had data of just 1 school) You can build on your code from the previous assignment to create a student level dataset for these 138 schools.
*/

* Downloading directory page 
copy "https://maktaba.tetea.org/exam-results/PSLE2021/distr_0101.htm" "directory.html", replace

* Load it and split by table cells to find the links
clear
set obs 1
gen strL s = fileread("directory.html")
split s, parse("<TD") gen(col)
drop s
gen id = 1
reshape long col, i(id) j(n)

* School Codes 
gen school_code = regexs(1) if regexm(col, "shl_(ps[0-9]+).htm")
keep if !missing(school_code)
keep school_code

levelsof school_code, local(schools)

tempfile master_data //tempfile to store results
save `master_data', emptyok

* Loop through each school
foreach s in `schools' {
    
    display "Processing School: `s'..."
    
    * Specific school page 
    cap copy "https://maktaba.tetea.org/exam-results/PSLE2021/shl_`s'.htm" "temp.html", replace
    if _rc != 0 continue // Skip if the link is broken
    
    * Load and process 
    preserve
        clear
        set obs 1
        gen strL raw = fileread("temp.html")
        split raw, parse("</TR>") gen(row)
        gen id = 1
        reshape long row, i(id) j(n)
        
        * Filter for student rows
        keep if strpos(row, upper("`s'")) > 0
        drop if strpos(row, "CANDIDATE NAME") > 0
        
        * Clean and Split
        replace row = subinstr(row, char(10), " ", .)
        replace row = subinstr(row, char(13), " ", .)
        split row, parse("<TD") gen(col)
        
        * Extract Variables
        gen schoolcode = regexs(1) if regexm(row, "(PS[0-9]+)-[0-9]+")
        gen cand_id = regexs(1) if regexm(row, "(PS[0-9]+-[0-9]+)")
        gen name = regexs(1) if regexm(col5, "<P>(.+)</FONT>")
		gen sex_m = regexm(row, `"ALIGN="CENTER">M<"')
		gen prem_number = regexs(1) if regexm(col3, "([0-9]{11})")
		gen average = regexs(1) if regexm(row, "Average Grade - ([A-E])")
        
        * Extract Grades
        local subjects "Kiswahili English Maarifa Hisabati Science Uraia"
        foreach sub in `subjects' {
            gen `sub' = regexs(1) if regexm(col6, "`sub' - ([A-F])")
        }
        
        * Append data to master file
        append using `master_data'
        save `master_data', replace
    restore
}

* Load the final combined dataset
use `master_data', clear

drop id n row raw col1 col2 col3 col4 col5 col6 col7 school_code //don't need these extractions anymore
drop if schoolcode == ""

order schoolcode prem_n sex_m name cand_id Kis Eng Maar Hisab Scien Urai average

//Noticed grades for some subjects were empty 

local subjects "Kiswahili English Maarifa Hisabati Science Uraia average"
        foreach sub in `subjects' {
			replace `sub' = "W" if `sub' == ""
		}

rename average average_grade

br

*********
**Question 2
*********

/*
We have household survey data and population density data of Côte d'Ivoire. Merge department-level density data from the excel sheet (CIV_populationdensity.xlsx) into the household data (CIV_Section_O.dta) i.e. add population density column to the CIV_Section_0 dataset.
*/

clear

cd "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment"

import excel "q2_CIV_populationdensity.xlsx", sheet("Population density") firstrow clear

keep if strpos(NOMCIRCONSCRIPTION, "DEPARTEMENT") == 1

* Removing prefixes and standardize to lowercase
gen dept = lower(NOMCIRCONSCRIPTION)
replace dept = subinstr(dept, "departement de ", "", 1)
replace dept = subinstr(dept, "departement du ", "", 1)
replace dept = subinstr(dept, "departement d' ", "", 1)
replace dept = subinstr(dept, "departement d'", "", 1)
replace dept = trim(dept)

tempfile density_temp
save `density_temp'

* Household survey data 
use "q2_CIV_Section_0.dta", clear

decode b06_departemen, gen(dept_name_str)

gen dept = lower(trim(dept_name_str))

replace dept = "arrah" if dept == "arrha" //Fixed spelling mismatch

merge m:1 dept using `density_temp'

drop if _merge == 2  //drop density rows that didn't match any households
drop dept _merge NOM SUPER POPULATION

*********
**Question 3
*********
/*

We have the GPS coordinates for 111 households from a particular village. You are a field manager and your job is to assign these households to 19 enumerators (~6 surveys per enumerator per day) in such a way that each enumerator is assigned 6 households that are close to each other (this would reduce the amount of time they spend walking from one house to another.) Manually assigning them for each village will take you a lot of time. Your job is to write an algorithm that would auto assign each household (i.e. add a column and assign it a value 1-19 which can be used as enumerator ID). Note: Your code should still work if I run it on data from another village.

*/


clear 

cd "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment"

use q3_gps.dta

* Get the total number of observations
count
local total = r(N)

local k = round(`total' / 6)

* Use cluster kmeans to find clusters by distances of houses 

cluster kmeans latitude longitude, k(`k') name(house_cluster) //will need to replace name

sort house_cluster latitude longitude 

gen enumerator_id = ceil(_n / 6)


**********
**Question 4 
**********

/*

2010 election data (Tz_election_2010_raw.xlsx) from Tanzania is not usable in its current format. You have to create a dataset in the wide form, where each row is a unique ward, and votes received by each party are given in separate columns. You can check the following dta file as a template for your output: Tz_elec_template. Your objective is to clean the dataset in such a way that it resembles the format of the template dataset.

*/ 

clear

cd "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment"

import excel "q4_Tz_election_2010_raw.xls", sheet("Sheet1") cellrange(A5) firstrow clear

rename REGION region
rename DISTRICT district
rename COSTITUENCY constituency
rename WARD ward
rename CANDIDATENAME cand_name
rename POLITICALPARTY party
rename TTLVOTES votes

* Fill out the wards, districts, constituencies 

foreach var in region district constituency ward {
    replace `var' = `var'[_n-1] if missing(`var')
}

drop if missing(cand_name)

* Cleaning Votes 

replace votes = lower(trim(itrim(votes)))
replace votes = subinstr(votes, char(160), "", .)

* Handles "unopposed", "unoppossed", etc. and destrings vote 
replace votes = "0" if strpos(votes, "oppo") > 0 
replace votes = "0" if votes == "" | votes == "."
replace votes = subinstr(votes, ",", "", .)
destring votes, replace

* Calculating ward totals 

bysort region district constituency ward: gen total_candidates_10 = _N
bysort region district constituency ward: egen ward_total_votes_10 = sum(votes)

* Cleaning Party 
replace party = "Unknown" if party == ""
* Standardize to match template suffixes (e.g., CCM instead of CHAMA_CHA...)
replace party = "CCM" if party == "CHAMA_CHA_MAPINDUZI" 
replace party = subinstr(party, " ", "_", .)
replace party = subinstr(party, ".", "", .)
replace party = subinstr(party, "-", "_", .)

collapse (first) total_candidates_10 ward_total_votes_10 (sum) votes, by(region district constituency ward party)

reshape wide votes, i(region district constituency ward) j(party) string

rename region region_10
rename district district_10
rename constituency constituency_10
rename ward ward_10

foreach v of varlist votes* {
    rename `v' `v'_10
}

gen ward_id_10 = _n



*******
**Question 5 
*******

/*

PSLE dataset contains data of 17,329 schools. We have the region and district of each school but for our analysis we need the ward information. There is another dataset (q5_school_location) that has the ward information of 19,733 schools. Your job is to identify ward information for 17,329 schools on the PSLE dataset using the q5_school_location.dta. Note: Final dataset should be the PSLE dataset + ward column (i.e. N = 17,329). Hint: You might have to try different methods to get the best results, even then you might have some schools where we can't find ward information. 

*/ 

cd "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment"

* Location Data 

use "q5_school_location.dta", clear
rename NECTACentreNo school_code

* Cleaning school code (some have na)
replace school_code = trim(itrim(school_code))
drop if lower(school_code) == "n/a" | missing(school_code)

* Duplicates check 
duplicates report school_code
duplicates drop school_code, force
isid school_code

* Save to a temporary file
tempfile location_data
save "`location_data'"

* Master Data 
use "q5_psle_2020_data.dta", clear

* School code through regex 
gen school_code = regexs(0) if regexm(schoolname, "PS[0-9]+")
replace school_code = trim(itrim(school_code))

* Merge 
merge m:1 school_code using "`location_data'", keepusing(Ward)

tab _merge
drop _merge

********
**Question 6
********

/*

Between 2010 and 2015, the number of wards in Tanzania went from 3,333 to 3,944. This happened by
dividing existing ward into 2 (or in some cases three or more) new wards. You have to create a dataset where each row is a 2015 ward matched with the corresponding parent ward from 2010. It's a trivial task to match wards that weren't divided, but it's impossible to match wards that were divided without additional information. Thankfully, we had access to shapefiles from 2012 and 2017. We used ArcGIS to create a new dataset that tells us the percentage area of 2015 ward that overlaps a 2010 ward. You can use information from this dataset to match wards that were divided.

*/ 

cd "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design/Assignment"


* GIS Mapping File 
use "Tz_GIS_2015_2010_intersection.dta", clear

* Standardize geography names
foreach var in region_gis_2017 district_gis_2017 ward_gis_2017 {
    replace `var' = trim(itrim(lower(`var')))
}


replace district_gis_2017 = subinstr(district_gis_2017, " urban", "_u", .)
replace district_gis_2017 = subinstr(district_gis_2017, " rural", "_r", .)

* Keep the 2010 parent with the highest overlap
gsort region_gis_2017 district_gis_2017 ward_gis_2017 -percentage
by region_gis_2017 district_gis_2017 ward_gis_2017: keep if _n == 1

* Rename to match the 2015 election data variables
rename (region_gis_2017 district_gis_2017 ward_gis_2017) (region_15 district_15 ward_15)
rename (region_gis_2012 district_gis_2012 ward_gis_2012) (region_10 district_10 ward_10)

tempfile mapping
save "`mapping'"


* 2015 data 
use "Tz_elec_15_clean.dta", clear

* Standardize names
foreach var in region_15 district_15 ward_15 {
    replace `var' = trim(itrim(lower(`var')))
}

replace district_15 = district_15 + "_u" if strpos(district_15, "jiji") > 0 | strpos(district_15, "manispaa") > 0
replace district_15 = district_15 + "_r" if strpos(district_15, "wilaya") > 0

* Cleaning 
local prefixes "wilaya ya " "jiji la " "manispaa ya " "mji wa " "halmashauri ya "
foreach p in `prefixes' {
    replace district_15 = subinstr(district_15, "`p'", "", .)
}
replace district_15 = trim(district_15)
 
* Verification
isid region_15 district_15 ward_15


merge 1:1 region_15 district_15 ward_15 using "`mapping'", keep(master match) //some worked some didn't

