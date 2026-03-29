********************************************************************************
** 	TITLE	: Assignment_02_EA.do
**	PURPOSE	: Work for assignment two 
**  PROJECT	: gui2de research and fieldwork analysis course 
**	AUTHOR	: Emilia Antunez
**	DATE	: February 19 2026
**	EDITTED	: Fberuary 19 2026
********************************************************************************
























*------------------------------------------------------------------------------*
**# WORKING DIRECTORY  
*------------------------------------------------------------------------------*

if c(username) == "PJ" { 
	global wd "/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Stata2HW"
}
else if c(username) == ""{ //People are going to put their name and their filepath here so that it runs in their machine
	global wd ""
}
else {
	display as error //"Define user specific file path"
}


// Set working directory dynamically
cd "$wd"





// Set global variables for dataset locations

*Bonus question

global q_bonus_hw1 "$wd/q5_Tz_student_roster_html.dta"

*Question 1
global q1_student_raw "$wd/01_data/q1_psle_student_raw.dta"

*Question 2 

global q2_population_excel "$wd/01_data/q2_CIV_populationdensity.xlsx"
global q2_section "$wd/01_data/q2_CIV_Section_0"

*Question 3 
global q3_gps "$wd/01_data/q3_GPSData.dta"


*Question 4 
global q4_election_excel "$wd/01_data/q4_Tz_election_2010_raw.xls"
global q4_election "$wd/01_data/q4_Tz_election_template.dta"


*Question 5 
global q5_psle_2020 "$wd/01_data/q5_psle_2020_data.dta"
global q5_school_location "$wd/01_data/q5_school_location.dta"




**Bonus Question

global Tz_GIS_2015_2010_intersection "$wd/01_data/Tz_GIS_2015_2010_intersection.dta"
global Tz_elec_15_clean "$wd/01_data/Tz_elec_15_clean.dta"
global Tz_elec_10_clean "$wd/01_data/Tz_elec_10_clean.dta"


















*------------------------------------------------------------------------------*
**# QUESTION 1 HW2 
*------------------------------------------------------------------------------*

*This builds on the bonus from the previous Stata assignment. We downloaded the PSLE data of students from 138 schools in Arusha District in Tanzania (previously we only had data of just 1 school) You can build on your code from the previous assignment to create a student level dataset for these 138 schools.


*STEP 0. Upload dataset
use $q1_student_raw

rename s rawdata
gen cleaned = rawdata




*STEP 1. Start cleaning

* Put delimiter before every candidate ID like PS0101114-0001 so that we can split each string line in the student's id
replace cleaned = ustrregexra(cleaned, "(PS\d{7}-\d{4})", "|||$1")

* Remove anything before the first delimiter (row-by-row)
gen first = strpos(cleaned, "|||")
replace cleaned = substr(cleaned, first+3, .) if first>0
drop first

*Split for each candidate, I create a variable for each candidate so I can then reshape
split cleaned, parse("|||") gen(rec)







*STEP 3. Reshape

reshape long rec, i(schoolcode) j(studentnum)

*I have many empty rows, so I need to erase them
drop if missing(rec)
drop if ustrtrim(rec) == ""







*STEP 4. Get the variables from the line string

*Get variable candidate id
gen candidate_id = ustrregexs(1) if ustrregexm(rec, "(PS\d{7}-\d{4})")



*Make all text, take out those weird symbols
gen rec_txt = ustrregexra(rec, "<[^>]+>", " ")

*Clean whitespace
replace rec_txt = subinstr(rec_txt, char(13), " ", .)
replace rec_txt = subinstr(rec_txt, char(10), " ", .)
replace rec_txt = ustrregexra(rec_txt, "\s+", " ")

* Normalize curly apostrophe to straight apostrophe
replace rec_txt = subinstr(rec_txt, "'", "'", .)
replace rec_txt = ustrtrim(rec_txt)

* Normalize modifier apostrophes (common in names) to straight apostrophe
replace rec_txt = subinstr(rec_txt, "ʼ", "'", .)
replace rec_txt = subinstr(rec_txt, "ʻ", "'", .)




* Generate variable gender
gen gender = ustrregexs(1) if ustrregexm(rec_txt,"PS\d{7}-\d{4}\s+[0-9]{11}\s+([MF])\s+")





*Get name of candidates 
gen cand_name = ustrregexs(1) if ustrregexm(rec_txt, "PS\d{7}-\d{4}\s+[0-9]{11}\s+[MF]\s+([A-Z][A-Z '\-]+?)\s+Kiswahili")

* I had 8 names that the code wasn't detecting, I added this to capture ANYTHING as the name, stopping at Kiswahili or *W, and not have those missing values
replace cand_name = ustrregexs(1) if missing(cand_name) & ///
    ustrregexm(rec_txt, "PS\d{7}-\d{4}\s+[0-9]{11}\s+[MF]\s+(.+?)\s+(Kiswahili|\*W)")

	
	
	
*--- Get grades ---*
gen grades_txt = rec_txt

* Normalize Unicode dash "–" to regular "-"
replace grades_txt = subinstr(grades_txt, "–", "-", .)

* Split into 7 parts (Kiswahili, English, Maarifa, Hisabati, Science, Uraia, Average Grade)
split grades_txt, parse(",") gen(subject)

* Trim spaces
forvalues i = 1/7 {
    replace subject`i' = ustrtrim(subject`i')
}


*Extract grade
forvalues i = 1/7 {
    gen grade`i' = ustrregexs(1) if ustrregexm(subject`i', "-\s*([A-Z])\s*$")
}

*Rename variables
rename grade1 Kiswahili
rename grade2 English
rename grade3 Maarifa
rename grade4 Hisabati
rename grade5 Science
rename grade6 Uraia
rename grade7 Average_Grade







	
*STEP 5. Order variables 	
*Order variables
order candidate_id gender cand_name Kiswahili English Maarifa Hisabati Science Uraia Average_Grade, a(studentnum)

*Drop variables I don't need (I don't know if I should though, would you recommend?)
drop rec cleaned rec_txt grades_txt subject1 subject2 subject3 subject4 subject5 subject6 subject7






















*------------------------------------------------------------------------------*
**# QUESTION 2 HW2 
*------------------------------------------------------------------------------*

*We have household survey data and population density data of Côte d'Ivoire. Merge departmente-level density data from the excel sheet (CIV_populationdensity.xlsx) into the household data (CIV_Section_O.dta) i.e. add population density column to the CIV_Section_0 dataset.



*STEP 1. Prepare density dataset
import excel $q2_population_excel, firstrow clear

rename NOMCIRCONSCRI~N dept_name
rename DENSITEAUKM pop_density

*Keep only department rows. This will be the key to merge later
keep if strpos(upper(dept_name), "DEPARTEMENT") > 0

*Clean words inside variable
gen dept_clean = upper(dept_name)

replace dept_clean = subinstr(dept_clean, "DEPARTEMENT DE ", "", .)
replace dept_clean = subinstr(dept_clean, "DEPARTEMENT D'", "", .)
replace dept_clean = subinstr(dept_clean, "DEPARTEMENT DU ", "", .)
replace dept_clean = subinstr(dept_clean, "DEPARTEMENT DES ", "", .)
replace dept_clean = subinstr(dept_clean, "DEPARTEMENT LA ", "", .)  
replace dept_clean = subinstr(dept_clean, "DEPARTEMENT D' ", "DEPARTEMENT D'", .)
replace dept_clean = trim(dept_clean)
tempfile dens
save `dens'






*STEP 2. Prepare household dataset
use $q2_section, clear

*Department variable is not string
decode b06_departemen, gen(dept_clean)

replace dept_clean = upper(trim(dept_clean))

*Arrha department is written differently. I'm gonna change it so it's the same in both datasets.
replace dept_clean = "ARRAH" if dept_clean=="ARRHA"






*STEP 3. Merge
merge m:1 dept_clean using `dens'

drop SUPERFICIEKM2 POPULATION




























*------------------------------------------------------------------------------*
**# QUESTION 3 HW2 
*------------------------------------------------------------------------------*

/*We have the GPS coordinates for 111 households from a particular village. You are a field manager and your job is to assign these households to 19 enumerators (~6 surveys per enumerator per day) in such a way that each enumerator is assigned 6 households that are close to each other (this would reduce the amount of time they spend walking from one house to another.) Manually assigning them for each village will take you a lot of time. Your job is to write an algorithm that would auto assign each household (i.e. add a column and assign it a value 1-19 which can be used as enumerator ID). Note: Your code should still work if I run it on data from another village.*/


*STEP 0 – use dataset, install geodist
clear all
use $q3_gps, clear
ssc install geodist






*STEP 2 – locals and variables to store results and make easy writing

local K 19
*enumerators
local G 6
*target households per enumerator


gen byte unassigned = 1 
*we will assign hh to closest point, this code will help us keep track of which ones have not been assigned yet. Makes it type byte (small integer, memory efficient)
gen int enumerator_id = .
*here we will put the id 1 to 19. Makes it type int (integer)






*STEP 3 – loop --> 1) Create 19 enumerator groups, 2) Each group should have up to 6 households, and 3) Households in a group should be geographically close

forvalues e = 1/`K' {
*K is the local 19 we defined earlier. If we ever decide to make more groups, we just change that number

	quietly count if unassigned==1 
	*count observations that have not been assigned to one hh
	if r(N)==0 break
	*If there are 0 unassigned households left, stop the loop
	
		*pick a seed household (first unassigned) 
		quietly levelsof id if unassigned==1, local(seeds)
		*We ask it to give us the id of unassigned hh, then store ids inside a local "seeds"

		local seed : word 1 of `seeds'
		*Take the first value from that list and store it in a new local macro called seed.
		
		replace enumerator_id = `e' if id==`seed'
		*For each id, assign the enumerator_id, which could be between 1 and 19
		
		replace unassigned    = 0   if id==`seed'
		*The hh is being assigned an enumerator_id, so the value changes from 1 to 0
		
		
		
			 * --- now grow the group up to G households --- *
			 forvalues j = 2/`G' {
			 *We already have one hh, so this loops makes 5 iterations (it runs from hh 2 to hh 6)
			 
				quietly count if unassigned==1
				if r(N)==0 continue, break   // no more households
				
				
				
				
				* --- compute centroid of CURRENT group e --- *
				* The centroid is the center or "average" position of all points within a shape!
				
				quietly summarize latitude  if enumerator_id==`e', meanonly
				*it calculates the mean latitude of only the hh assigned to desired enumerator 
				local cen_lat = r(mean)
				*Take the value stored in r(mean) and store it in a local macro called cen_lat.
				
				quietly summarize longitude if enumerator_id==`e', meanonly
				local cen_lon = r(mean)
				
				
				
				
				* --- calculate distance of each unassigned hh to the centroid --- *
				cap drop dtmp
				**Delete variable dtmp if it doesn't exist. Cap avoids error if it doesn't exist.
				
				geodist latitude longitude `cen_lat' `cen_lon' if unassigned==1, gen(dtmp)
				* dtmp = distance from each unassigned hh to the centroid of the current group
				
				* choose the single closest unassigned household
        
		preserve
		*Creating a temporary snapshot of the dataset as is, with all the previous data
            
			keep if unassigned==1
			*Now we temporarily shrink the dataset to: Only hh that are still available.
            
			sort dtmp
			*This sorts the remaining hh by distance to centroid. Smallest distance first.
            
			keep in 1
			*Keep only 1st observation (others are temporarily removed). Closest unassigned hh. 
            
			local pick = id[1]
			*Since there is only one row left: id[1] is the id of the closest household.
        
		restore
		*Go back to the full dataset exactly as it was before preserve

        * assign that picked hh to enumerator e
        replace enumerator_id = `e' if id==`pick'
		*Wr still remember the value stored in pick.
		
        replace unassigned    = 0   if id==`pick'
    }
}

drop unassigned dtmp
tab enumerator_id

*Check if it worked
scatter latitude longitude, by(enumerator_id, cols(5)) msymbol(o)
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
*------------------------------------------------------------------------------*
**# QUESTION 4
*------------------------------------------------------------------------------*	
/*2010 election data (Tz_election_2010_raw.xlsx) from Tanzania is not usable in its current format. You have to create a dataset in the wide form, where each row is a unique ward, and votes received by each party are given in separate columns. You can check the following dta file as a template for your output: Tz_elec_template. Your objective is to clean the dataset in such a way that it resembles the format of the template dataset.*/
	

*STEP 0. 
import excel $q4_election_excel, clear 

*Rename to make easier
rename A region
rename B district
rename C constituency
rename D ward










*STEP 1. Loop
*Make local with the name of the variables I will use for loop
local variables region district constituency ward



*Build a loop so that it fills all the rows with the corresponding region, district, constituency and ward. This is important because we have a lot of empty cells and the reason is that each row represents one candidate. 
foreach v of local variables {
    replace `v' = `v'[_n-1] if missing(`v')
}

*Drop things that are not useful and rename variables that are useful
drop E  
drop F 
drop G 
rename H party
rename I votes
drop J 


*Drop rows that are not important
drop in 1/6
	
	

	
	
	

	
*STEP 2. Clean variables so that we can reshape


*Votes variables is string, so we need to change it in order to reshape because the values in votes will be what the party variable measures.

replace votes = "" if upper(trim(votes)) == "UN OPPOSSED"
*I need to change unoppossed for empty in order to destring. I usse upper to temporarily convert everything to uppercase just for the comparison, so that unoppossed is written differently in different cells that it doesn't make a difference. Trim just takes the spaces.

destring votes, replace ignore(",")
*Now I was able to destring, and it generated 599 missing values, which means there were 599 candidates who were unoppossed, concerning fact about Tanzania's democracy!!

bysort region district constituency ward: gen n_candidates = _N
*I need to generate a variable that has the number of candidates, as in the example


*Clean the parties
gen party_clean = upper(strtrim(party))
*strtrim() removes leading and trailing spaces from a string.

replace party_clean = subinstr(party_clean, "-", "_", .)
*subinstr replaces one piece of text inside a string with another.

replace party_clean = subinstr(party_clean, " ", "_", .)

	

*I tried to reshape, but there were duplicates. I found them so I could deal with them.	
duplicates report region district constituency ward party_clean
 duplicates list region district constituency ward party_clean
 

 *We find that the problem is that in NANGANDO, two contenders ran udner the same party. That's why I can't reshape. You can't have the same party twice in the same ward. That confuses stata. The best approach if duplicates represent the same party in the same ward is to aggregate votes within ward–party.

*This code will make that each party inside each ward adds its votes into one row. We are losing information, because tecnically we would be losing the name of the candidate. But it's not improtant for this assigment
collapse (sum) votes (max) n_candidates, by(region district constituency ward party_clean) 


*Collapse reduces the dataset by grouping. Sum will add up all votes in that group. Max n_candidates helps us keep the total number of cadidate that were in the race, which was 4.


	
	
	
	
	
	
	
	
	
*STEP 3. Reshape!!

reshape wide votes, ///
    i(region district constituency ward) ///
    j(party_clean) string

	
	
	
	
	
	
	
	
	
	
	
	
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
*------------------------------------------------------------------------------*
**# QUESTION 5
*------------------------------------------------------------------------------*


/*PSLE dataset contains data of 17,329 schools. We have the region and district of each school but for our analysis we need the ward information. There is another dataset (q5_school_location) that has the ward information of 19,733 schools. Your job is to identify ward information for 17,329 schools on the PSLE dataset using the q5_school_location.dta. Note: Final dataset should be the PSLE dataset + ward column (i.e. N = 17,329). Hint: You might have to try different methods to get the best results, even then you might have some schools where we can't find ward information.*/  



*It only matched  11,161 out of 17,329 :(




*STEP 1: Clean PSLE (MASTER DATASET)
use $q5_psle_2020, clear

* --- Standardiz* geographic keys --- *

replace region_name = lower(trim(region_name))
*We replace because with lower case so that it's easier to match with location dataset

gen council_name = lower(trim(district_name)), a(region_name)
*We generate this variable because location dataset calls "distric" as a council 

drop district_name
*We don't need anymore, it's only repeating what council_name has



* ---- Clean school name ---- *
gen school_name_clean = lower(schoolname), a(schoolname)

replace school_name_clean = ustrregexra(school_name_clean, "[^a-z0-9 ]", " ")
**For every character in school_name_clean that is: not a letter, not a number, not a space, it gets replaced with a space.

replace school_name_clean = itrim(school_name_clean)
*Erase spaces before and spaces after the words



foreach w in primary school {
*Take each item in this list and temporarily call it w. The list is:primary school
	
    replace school_name_clean = ustrregexra(school_name_clean, "\b`w'\b", "")
}
*This loop helps us erase "primary school" from the variable. \b means word boundary in regex. w is the placeholder of the word "primary" and the word "school". The, the third part "" is an empty space. It's telling stata to replace those words with an empty space, to erase them.

replace school_name_clean = itrim(school_name_clean)


replace school_name_clean = ustrregexra(school_name_clean, "\bps[0-9]+\b", "")
*I'm doing the same as before, in the loop, but instead I'm removing the school codes (PS...). ---> Remove any token that looks like ps followed by numbers.
replace school_name_clean = itrim(school_name_clean)

* Create unique id
gen long psle_id = _n

tempfile psle_clean
save `psle_clean', replace
*I don't want to save this file, so I create a temporary file.









*STEP 2: Clean LOCATION (USING DATASET)
use $q5_school_location, clear

* Standardize geographic keys
gen region_name  = lower(trim(Region))
gen council_name = lower(trim(Council))

* Clean school name
gen name2_clean = lower(School)
replace name2_clean = ustrregexra(name2_clean, "[^a-z0-9 ]", " ")
replace name2_clean = itrim(name2_clean)

foreach w in primary school {
    replace name2_clean = ustrregexra(name2_clean, "\b`w'\b", "")
}
replace name2_clean = itrim(name2_clean)

replace name2_clean = ustrregexra(name2_clean, "\bps[0-9]+\b", "")
replace name2_clean = itrim(name2_clean)

keep region_name council_name name2_clean Ward
* Keep only what we need to join them

tempfile loc_clean
save `loc_clean', replace










* STEP 3: Join by Region + Council (Restrict Candidate Pool)
*WHY joining and not merging? i don't have unique keys, only similar words. joinby creates all possible combinations within the specified grouping variables.


use `psle_clean', clear

joinby region_name council_name using `loc_clean'
*For each PSLE school in a given (region, council), pair it with every location school in the same (region, council). It does NOT match by school name yet. It just creates candidate pairs. Because you cannot run fuzzy string matching across two separate datasets. Stata must have both variables in the same dataset to compare them. 










* STEP 4: Score similarity (shared words)


* --- Split into words ---*
split school_name_clean, parse(" ") gen(w)
*It'll be easier to compare and see if the schools in the datasets are the same. If we don't split, we would be comparing the full strings and they might not be identical. After this, we can check: For each word in PSLE, does it appear in the location name?


unab wvars : w*
* Get the list of created w-variables (w1 w2 ... whatever exists). It expands a variable pattern into the full list of variable names. Then, it takes all the variables starting with w and store their names in a local macro called wvars.

gen score = 0
foreach v of local wvars {
    replace score = score + (`v' != "" & ustrregexm(name2_clean, "\b" + `v' + "\b"))
}
*Loop to check if the word for each wvars variable (w1, w2, etc..) is non-empty AND it appears in the location school name.
* If it's empy: v != ""
* If the word in variable v appears as a whole word inside name2_clean: name2_clean, "\b" + `v' + "\b"
*it generates a value of 1 if both are true



gen len_gap = abs(length(school_name_clean) - length(name2_clean))
* Tie-breaker: closer length is better. Length calculates the amount of characters in each of the variables. It's expected that the schools that have less difference between characters will be the right match. It's added to the score


gsort psle_id -score len_gap
by psle_id: keep if _n == 1
* Keep best candidate per PSLE school: This line sorts the data by: 
*psle_id (so rows for the same PSLE school are together)
*-score → highest score first
*len_gap → smallest length difference first
*So within each PSLE school, the best candidate (highest similarity, closest length) will be at the top.


replace Ward = "" if score < 2
* Optional: require a minimum score to avoid weak matches










* STEP 5: Merge Ward back to PSLE (N unchanged) 


keep psle_id Ward score
tempfile matched
save `matched', replace

use $q5_psle_2020, clear
gen long psle_id = _n
merge 1:1 psle_id using `matched', nogen


















*------------------------------------------------------------------------------*
**# BONUS QUESTION 
*------------------------------------------------------------------------------*
/* Between 2010 and 2015, the number of wards in Tanzania went from 3,333 to 3,944. This happened by
dividing existing ward into 2 (or in some cases three or more) new wards. You have to create a dataset where each row is a 2015 ward matched with the corresponding parent ward from 2010. It's a trivial task to match wards that weren't divided, but it's impossible to match wards that were divided without additional information. Thankfully, we had access to shapefiles from 2012 and 2017. We used ArcGIS to create a new dataset that tells us the percentage area of 2015 ward that overlaps a 2010 ward. You can use information from this dataset to match wards that were divided.
*/



use $Tz_GIS_2015_2010_intersection, clear
use $Tz_elec_15_clean, clear
use $Tz_elec_10_clean, clear











