/*Q1: Tanzania Student Data 
This builds on the bonus from the previous Stata assignment. We downloaded the PSLE data of students from 138 schools in Arusha District in Tanzania (previously we only had data of just 1 school) You can build on your code from the previous assignment to create a student level dataset for these 138 schools. schoolcode, cand_id, gender, prem_number, name, grade variables for: Kiswahili, English, maarifa, hisabati, science, uraia, average */
clear
cd "C:\ExpDesign\StataAssignment2"
use q1_psle_student_raw.dta
describe
rename s raw_html

**Make the html readable
replace raw_html = ustrregexra(raw_html, "<[^>]+>", " ")
replace raw_html = ustrregexra(raw_html, "[[:space:]]+", " ")

**Create temporary file to save the school codes and html information
tempfile schools
save `schools'

**Set up empty variables for what the html contains
clear
set obs 0

gen schoolcode = ""
gen cand_id = ""
gen prem_number = ""
gen gender = ""
gen name = ""
gen kiswahili = ""
gen english = ""
gen maarifa = ""
gen hisabati = ""
gen science = ""
gen uraia = ""
gen average = ""

**Create temporary file to save (empty) student level data fields
tempfile students
save `students', replace

**Bring school file back up
use `schools', clear

/**Loop to fill student level fields with information from the html file 
from the school file */
quietly {
    forvalues i = 1/`=_N' {

        local text = raw_html[`i']
        local scode = schoolcode[`i']

        while regexm("`text'", ///
        "(PS[0-9]+-[0-9]+)[ ]+([0-9]+)[ ]+([MF])[ ]+([A-Z ]+)[ ]+Kiswahili - ([A-E]), English - ([A-E]), Maarifa - ([A-E]), Hisabati - ([A-E]), Science - ([A-E]), Uraia - ([A-E]), Average Grade - ([A-E])") {

            use `students', clear
            set obs `=_N+1'

            replace schoolcode = "`scode'" in L
            replace cand_id     = regexs(1) in L
            replace prem_number = regexs(2) in L
            replace gender      = regexs(3) in L
            replace name        = trim(regexs(4)) in L
            replace kiswahili   = regexs(5) in L
            replace english     = regexs(6) in L
            replace maarifa     = regexs(7) in L
            replace hisabati    = regexs(8) in L
            replace science     = regexs(9) in L
            replace uraia       = regexs(10) in L
            replace average     = regexs(11) in L

            save `students', replace

            local text = subinstr("`text'", regexs(0), "", 1)
        }

        use `schools', clear
    }
}

use `students', clear

save q1_psle_student_clean.dta

/* Q2: Côte d'Ivoire Population Density
We have household survey data and population density data of Côte d'Ivoire. Merge departmente-level density data from the excel sheet (CIV_populationdensity.xlsx) into the household data (CIV_Section_O.dta) i.e. add population density column to the CIV_Section_0 dataset. */

clear all
cd "C:\ExpDesign\StataAssignment2"
import excel "q2_CIV_populationdensity", firstrow clear
rename NOMCIRCONSCRIPTION constituency
rename SUPERFICIEKM2 area
rename POPULATION population
rename DENSITEAUKM density_pop

**Get rid of all caps
replace constituency = lower(constituency)

**Keep only departement constituencies
keep if regexm(constituency, "^departement")

**Format so that only the name of the departement appears
replace constituency = subinstr(constituency, "departement du ", "", .)
replace constituency = subinstr(constituency, "departement de ", "", .)
replace constituency = subinstr(constituency, "departement d'", "", .)
replace constituency = subinstr(constituency, " ", "", .)

**Label variables appropriately
rename constituency departement
rename density_pop density_departement

**Get rid of extraneous variables
keep departement density_departement

**save 
tempfile dep_density
save `dep_density'

**load .dta file, create a string departement variable, and fix the misspelling of arrah
use "q2_CIV_Section_0", clear
decode b06_departemen, gen(departement)
replace departement = "arrah" if departement == "arrha"

**merge the two files
merge m:1 departement using `dep_density'

**get rid of extraneous information. Gbeleban is a new departement with no hh data
drop if departement == "gbeleban"
drop _merge departement

save "q2_CIV_Section_clean"

/*Q3: Enumerator Assignment based on GPS
We have the GPS coordinates for 111 households from a particular village. You are a field manager and your job is to assign these households to 19 enumerators (~6 surveys per enumerator per day) in such a way that each enumerator is assigned 6 households that are close to each other (this would reduce the amount of time they spend walking from one house to another.) Manually assigning them for each village will take you a lot of time. Your job is to write an algorithm that would auto assign each household (i.e. add a column and assign it a value 1-19 which can be used as enumerator ID). Note: Your code should still work if I run it on data from another village. */

clear all
cd "C:\ExpDesign\StataAssignment2"
use "Q3_GPS Data"

**Make distances sorted by closeness
sort latitude longitude

**Have an ordinal list of all observations
gen count = _n

**Keep track of how many observations are in the dataset
count
local N = r(N)

**Make a new variable indicating how many hh each of the 19 enumerators visit
gen hh_per_enumeratory = `N' / 19

**Assign enumerators based on ordinal count and the number of hh each enumerator visits
gen enumerator = 1 if count <= hh_per_enumeratory
replace enumerator = 2 if count >= hh_per_enumeratory & count <= 2 * hh_per_enumeratory
replace enumerator = 3 if count >= 2 * hh_per_enumeratory & count <= 3 * hh_per_enumeratory
replace enumerator = 4 if count >= 3 * hh_per_enumeratory & count <= 4 * hh_per_enumeratory
replace enumerator = 5 if count >= 4 * hh_per_enumeratory & count <= 5 * hh_per_enumeratory
replace enumerator = 6 if count >= 5 * hh_per_enumeratory & count <= 6 * hh_per_enumeratory
replace enumerator = 7 if count >= 6 * hh_per_enumeratory & count <= 7 * hh_per_enumeratory
replace enumerator = 8 if count >= 7 * hh_per_enumeratory & count <= 8 * hh_per_enumeratory
replace enumerator = 9 if count >= 8 * hh_per_enumeratory & count <= 9 * hh_per_enumeratory
replace enumerator = 10 if count >= 9 * hh_per_enumeratory & count <= 10 * hh_per_enumeratory
replace enumerator = 11 if count >= 10 * hh_per_enumeratory & count <= 11 * hh_per_enumeratory
replace enumerator = 12 if count >= 11 * hh_per_enumeratory & count <= 12 * hh_per_enumeratory
replace enumerator = 13 if count >= 12 * hh_per_enumeratory & count <= 13 * hh_per_enumeratory
replace enumerator = 14 if count >= 13 * hh_per_enumeratory & count <= 14 * hh_per_enumeratory
replace enumerator = 15 if count >= 14 * hh_per_enumeratory & count <= 15 * hh_per_enumeratory
replace enumerator = 16 if count >= 15 * hh_per_enumeratory & count <= 16 * hh_per_enumeratory
replace enumerator = 17 if count >= 16 * hh_per_enumeratory & count <= 17 * hh_per_enumeratory
replace enumerator = 18 if count >= 17 * hh_per_enumeratory & count <= 18 * hh_per_enumeratory
replace enumerator = 19 if count >= 18 * hh_per_enumeratory & count <= 19 * hh_per_enumeratory

*Ensure there are the correct number of hh per enumerator and the correct number of enumerators.
tab enumerator
drop hh_per_enumeratory

save q3_GPS_Data_clean

/*Q4: 2010 Tanzania Election Data cleaning
2010 election data (Tz_election_2010_raw.xlsx) from Tanzania is not usable in its current format. You have to create a dataset in the wide form, where each row is a unique ward, and votes received by each party are given in separate columns. You can check the following dta file as a template for your output: Tz_elec_template. Your objective is to clean the dataset in such a way that it resembles the format of the template dataset. */

clear all
cd "C:\ExpDesign\StataAssignment2"
import excel "q4_Tz_election_2010_raw", cellrange(A7)

**get rid of extraneous variables
drop F G K

rename A region
rename B district
rename C constituency
rename D ward
rename E candidate
rename H party
rename I votes 
rename J elected

destring votes, replace force

**fill in blanks for region, district, constituency, and ward
foreach var in region district constituency ward {
    replace `var' = `var'[_n-1] if `var' == "" & _n > 1
}

egen total_candidates = count(candidate), by(ward)

bysort ward: egen ward_total_votes = total(votes)

**get rid of spaces in party names
replace party = "APPT_MAENDELEO" if party == "APPT - MAENDELEO"
replace party = "JAHAZI_ASILIA" if party == "JAHAZI ASILIA"

**add party votes together if in the same ward
bysort ward party: egen party_votes = total(votes)
bysort ward party: keep if _n == 1

**these values are missing and shouldn't be 0
replace party_votes = . if party_votes == 0
replace ward_total_votes = . if ward_total_votes == 0

**extraneous
drop candidate votes elected

**ensure each ward is unique
egen ward_id = group(region district constituency ward)

rename party_votes votes 

*force party names to be readable by stata
replace party = strtoname(party)

reshape wide votes, i(ward_id) j(party, string)

**order like in the template
order region district constituency ward total_candidates ward_total_votes ward_id

save "q4_Tz_election_2010_clean"

/*Q5: Tanzania PSLE data
PSLE dataset contains data of 17,329 schools. We have the region and district of each school but for our analysis we need the ward information. There is another dataset (q5_school_location) that has the ward information of 19,733 schools. Your job is to identify ward information for 17,329 schools on the PSLE dataset using the q5_school_location.dta. Note: Final dataset should be the PSLE dataset + ward column (i.e. N = 17,329). Hint: You might have to try different methods to get the best results, even then you might have some schools where we can't find ward information. */

clear all
cd "C:\ExpDesign\StataAssignment2"
use "q5_psle_2020_data"

**isolate school code from schoolname observations and save
gen school_code = regexs(1) if regexm(schoolname, "(PS[0-9]+)")
count if missing(school_code)
save "q5_psle_2020_data_interim", replace

use "q5_school_location"

**ensure school_code is a unique identifier and matches other dataset
rename NECTACentreNo school_code
keep school_code Ward
drop if school_code == "n/a"
bysort school_code: keep if _n == 1

merge 1:1 school_code using "q5_psle_2020_data_interim"

drop if _merge == 1 
drop if _merge == 2
drop _merge

save "q5_psle_2020_data_clean", replace

/*Q6: Tanzania Election data Merging (Bonus Question)
Between 2010 and 2015, the number of wards in Tanzania went from 3,333 to 3,944. This happened by dividing existing wards into 2 (or in some cases three or more) new wards. You have to create a dataset where each row is a 2015 ward matched with the corresponding parent ward from 2010. It's a trivial task to match wards that weren't divided, but it's impossible to match wards that were divided without additional information. Thankfully, we had access to shapefiles from 2012 and 2017. We used ArcGIS to create a new dataset that tells us the percentage area of 2015 ward that overlaps a 2010 ward. You can use information from this dataset to match wards that were divided. */
