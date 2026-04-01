*********************************************************
*Name: Catherine Morris
*Class: Gui2de Spring 2026
*Assignment: Stata 2 
*Date: February 22, 2026
*Edited:February 26, 2026
*Edited: February 27, 2026
*********************************************************



**Q1: Tanzania Student Data (138 Schools)


/*Build on Assignment 1's single-school HTML parsing to create a student-level dataset from #138 schools**. The file `q1_psle_student_raw.dta` has 138 rows, each containing an HTML page (`s`) and a school code (`schoolcode`) */



cd "/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Stata2HW/01_data"
pwd


***still can't get global to work for whatever reason, apologies

clear all

use "q1_psle_student_raw.dta", clear
save "q1_tanzania_temp.dta", replace


describe   
inspect
misstable summarize


replace s = subinstr(s, char(13), "", .)

**Extract school level variables
gen school_name = ""
replace school_name = regexs(1) if regexm(s, "([A-Z][A-Z ]+[A-Z]) - (PS[0-9]+)")

gen school_code = ""
replace school_code = regexs(2) if regexm(s, "([A-Z][A-Z ]+[A-Z]) - (PS[0-9]+)")

gen str10 n_students_str = ""
replace n_students_str = regexs(1) if regexm(s, "WALIOFANYA MTIHANI *: *([0-9]+)")
destring n_students_str, gen(n_students) force
drop n_students_str

gen str20 school_avg_str = ""
replace school_avg_str = regexs(1) if regexm(s, "WASTANI WA SHULE *: *([0-9]+[.][0-9]+)")
destring school_avg_str, gen(school_avg) force
drop school_avg_str

* Save school info + raw HTML for the loop
tempfile school_html
save `school_html'

**loop over each school
tempfile students
* Create empty file with the right structure
clear
gen schoolcode   = ""
gen school_name  = ""
gen school_code  = ""
gen n_students   = .
gen school_avg   = .
gen cand_no      = ""
gen prem_no      = ""
gen sex          = ""
gen student_name = ""
gen kiswahili    = ""
gen english      = ""
gen maarifa      = ""
gen hisabati     = ""
gen science      = ""
gen uraia        = ""
gen avg_grade    = ""
save `students'

use `school_html', clear
local nschools = _N

forvalues i = 1/`nschools' {

    use `school_html', clear
    keep if _n == `i'
    

    keep s schoolcode school_name school_code n_students school_avg

    split s, p("</TR>")
    drop s

    gen id = 1
    reshape long s, i(id) j(chunk)
    drop id chunk
    drop if missing(s) | s == ""
    keep if regexm(s, "PS[0-9]+-[0-9]+")


    gen cand_no = ""
    replace cand_no = regexs(0) if regexm(s, "PS[0-9]+-[0-9]+")

    gen prem_no = ""
    replace prem_no = regexs(1) if regexm(s, ">([0-9]{11})<")

    gen sex = ""
	replace sex = ustrregexs(1) if ustrregexm(rec_txt,"PS\d{7}-\d{4}\s+[0-9]{11}\s+([MF])\s+")

    gen student_name = ""
    replace student_name = strtrim(regexs(1)) if regexm(s, "<P>([A-Z ]+)</FONT>")

    gen kiswahili = ""
    replace kiswahili = regexs(1) if regexm(s, "Kiswahili - ([A-E])")
    gen english = ""
    replace english   = regexs(1) if regexm(s, "English - ([A-E])")
    gen maarifa = ""
    replace maarifa   = regexs(1) if regexm(s, "Maarifa - ([A-E])")
    gen hisabati = ""
    replace hisabati  = regexs(1) if regexm(s, "Hisabati - ([A-E])")
    gen science = ""
    replace science   = regexs(1) if regexm(s, "Science - ([A-E])")
    gen uraia = ""
    replace uraia     = regexs(1) if regexm(s, "Uraia - ([A-E])")
    gen avg_grade = ""
    replace avg_grade = regexs(1) if regexm(s, "Average Grade - ([A-E])")

    drop s

    append using `students'
    save `students', replace
}

br


*Relabel  


label variable schoolcode    "School code (from raw data)"
label variable school_name   "School name"
label variable school_code   "NECTA school code"
label variable n_students    "Number of students who sat the exam"
label variable school_avg    "School average score"
label variable cand_no       "Candidate number"
label variable prem_no       "PREM registration number"
label variable sex           "Student sex (M/F)"
label variable student_name  "Student full name"
label variable kiswahili     "Kiswahili grade"
label variable english       "English grade"
label variable maarifa       "Maarifa grade"
label variable hisabati      "Hisabati (Math) grade"
label variable science       "Science grade"
label variable uraia         "Uraia grade"
label variable avg_grade     "Average grade"

sort schoolcode cand_no
describe
list in 1/10
save "q1_psle_student_final.dta", replace


***checking file for ID card purposes and key

use "q1_psle_student_final.dta", clear
codebook cand_no

describe   
inspect
misstable summarize

 ***checking to see if 138 schools came through
egen school_id = group(schoolcode)
tab school_id
***looks like they did



*************************************************************************
/* Q2: Côte d'Ivoire Population Density


Merge departement-level population density from `q2_CIV_populationdensity.xlsx` into household survey data `q2_CIV_Section_0.dta`. The goal is to add a population density column to the 12,899-row household dataset.

*/



cd "/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Stata2HW/01_data"
clear all


import excel "q2_CIV_populationdensity.xlsx", firstrow clear
br

describe   

**variable names are hard to use

rename NOMCIRCONSCRIPTION  nom
rename DENSITEAUKM        density

* Save a temp file
tempfile density_full
save `density_full'

use `density_full', clear

*Keeping only department rows
keep if strpos(nom, "DEPARTEMENT") == 1

replace nom = strlower(strtrim(nom))

replace nom = regexr(nom, "^departement d' ?", "")

foreach prefix in "departement de " "departement du " "departement des " {
    replace nom = subinstr(nom, "`prefix'", "", 1)
}

replace nom = strtrim(nom)
replace nom = "arrha" if nom == "arrah"


duplicates report nom
 
keep nom density

assert _N == 108

tempfile density_lookup
save `density_lookup'

*Checking household data

use "q2_CIV_Section_0.dta", clear


assert _N == 12899
describe b06_departemen



local vtype : type b06_departemen

if substr("`vtype'", 1, 3) == "str" {
   
    gen nom = strlower(strtrim(b06_departemen))
}
else {
  
    decode b06_departemen, gen(nom)
    replace nom = strlower(strtrim(nom))
}

*Check for department names 
codebook nom
  

*Merge density into household data using "many-to-one"

merge m:1 nom using `density_lookup'

tab _merge

***Check unmatched households
count if _merge == 1
if r(N) > 0 {
    di as error "WARNING: `r(N)' household rows did not match a density value."
    di as error "Unmatched departement names:"
    levelsof nom if _merge == 1, local(unmatched)
    foreach name of local unmatched {
        di as error "  >> `name'"
    }
  
}


drop if _merge == 2   // drop the 1 density-only row (attiegouakro)
drop _merge nom
  

***Check/save

assert _N == 12899


summarize density, detail
count if missing(density)
  

tab b06_departemen if missing(density)


label variable density "Population density (persons per km²), departement level"
note density: "Source: q2_CIV_populationdensity.xlsx, DEPARTEMENT-level rows only"

save "q2_merged.dta", replace


describe
di "Merge complete. Rows: `=_N'.  Columns: `=c(k)'."

br

save "q2.dta", replace

use "q2.dta", clear

codebook hh1
br

describe 





/* Q3: Enumerator Assignment based on GPS

Assign 111 households to 19 enumerators (~6 per enumerator) based on GPS proximity. Each enumerator should be assigned households that are geographically close to each other. */


clear all


**rename file to include missing _

use "q3_GPSData.dta", clear


* Saving a working copy 
save "q3_GPS_Data_work.dta", replace
use "q3_GPS_Data_work.dta", clear

describe

misstable summarize
inspect


summarize latitude longitude


gen enumerator_id = .

local total_hh  = _N        // 111
local n_enum    = 19
local big_groups = mod(`total_hh', `n_enum')   // 111 mod 19 = 16
local small_groups = `n_enum' - `big_groups'   // 3
local big_size   = ceil(`total_hh' / `n_enum') // 6
local small_size = floor(`total_hh' / `n_enum') // 5

display "Enumerators with `big_size' HH: `big_groups'"
display "Enumerators with `small_size' HH: `small_groups'"

*Loop

forvalues e = 1/`n_enum' {

    
    if `e' <= `big_groups' {
        local grp_size = `big_size'
    }
    else {
        local grp_size = `small_size'
    }

*Finding "seed" household for each enumerator

    quietly summarize latitude  if enumerator_id == .
    local clat = r(mean)
    quietly summarize longitude if enumerator_id == .
    local clon = r(mean)

    capture drop _dist_to_centroid
    gen _dist_to_centroid = sqrt((latitude - `clat')^2 + ///
        (longitude - `clon')^2) if enumerator_id == .

    quietly summarize _dist_to_centroid
    local max_dist = r(max)

    quietly summarize id if ///
        abs(_dist_to_centroid - `max_dist') < 0.000001 ///
        & enumerator_id == .
    local seed_id = r(min)

    quietly summarize latitude  if id == `seed_id'
    local slat = r(mean)
    quietly summarize longitude if id == `seed_id'
    local slon = r(mean)



    capture drop _dist_to_seed
    gen _dist_to_seed = sqrt((latitude - `slat')^2 + ///
        (longitude - `slon')^2) if enumerator_id == .

* Rank and assign


    capture drop _rank



    if `e' == `n_enum' {
        replace enumerator_id = `e' if enumerator_id == .
    }
    else {
		sort _dist_to_seed id
		gen _rank = sum(enumerator_id == .)
		replace _rank = . if enumerator_id != .
    }

    display "Enumerator `e': assigned `grp_size' HH (seed id=`seed_id')"
}

*Dropping unnecessary variables
capture drop _dist_to_centroid _dist_to_seed _rank

*Checking
tab enumerator_id, missing


assert enumerator_id != .
bysort enumerator_id: gen n_in_group = _N
tab enumerator_id n_in_group
 

label variable enumerator_id "Assigned enumerator (1-19)"
drop n_in_group

br

save "q3.dta", replace

use "q3.dta", clear

codebook id

describe

misstable summarize



/*Q4: 2010 Tanzania Election Data Cleaning

Transform the messy `q4_Tz_election_2010_raw.xls` into a clean wide-format dataset matching `q4_Tz_election_template.dta`: one row per ward (3,333 wards), with party vote totals in separate columns. */



clear all



* Import and clean the raw data

import excel "q4_Tz_election_2010_raw.xls", clear

* Save a temp file
tempfile q4_tanz
save `q4_tanz'


describe
br
**data looks messy and variables are letters

* Drop the title/header rows 
drop if _n <= 5


* Rename columns, labels found on row 3
rename A region
rename B district
rename C constituency
rename D ward
rename E candidate_name
rename F sex_m
rename G sex_f
rename H party
rename I votes_str
rename J elected

*checking template

tempfile q4_tanz
save `q4_tanz'

use "q4_Tz_election_template.dta"

br

describe

/*region_10       str13   %13s                * Region (2010)
district_10     str28   %28s                * District (2010)
constituency_10 str25   %25s                * Constituency (2010)
ward_10         str22   %22s                * Ward (2010)
total_candid~10 float   %9.0g               * Total Candidates in the ward (2010)
ward_total_v~10 float   %9.0g               * Total Votes in the ward (2010)
ward_id_10      float   %9.0g                 group(region district ward)
votes_AFP_10    int     %10.0g                1 votes
votes_APPT_M~10 int     %10.0g                2 votes
votes_CCM_10    int     %10.0g                3 votes
votes_CHADEM~10 int     %10.0g                4 votes
votes_CHAUST~10 int     %10.0g                5 votes
votes_CUF_10    int     %10.0g                6 votes
votes_DP_10     int     %10.0g                7 votes
votes_JAHAZI~10 int     %10.0g                8 votes
votes_MAKIN_10  int     %10.0g                9 votes
votes_NCCR_M~10 int     %10.0g                10 votes
votes_NLD_10    int     %10.0g                11 votes
votes_NRA_10    int     %10.0g                12 votes
votes_SAU_10    int     %10.0g                13 votes
votes_TADEA_10  int     %10.0g                14 votes
votes_TLP_10    int     %10.0g                15 votes
votes_UDP_10    int     %10.0g                16 votes
votes_UMD_10    int     %10.0g                17 votes
votes_UPDP_10   int     %10.0g                18 votes
votes_other_10  int     %10.0g                19 votes
                                            * indicated variables have notes
*/

use `q4_tanz', clear

***I guess this didn't save the temp file so I'll need to start over

*** row three identifies: LOCAL GOVERNMENT ELECTION RESULTS: 2010


clear all
set more off


* Import and clean the raw data

import excel "q4_Tz_election_2010_raw.xls", clear

* Save a temp file
tempfile q4_tanz
save `q4_tanz'

describe
br

***I think we can drop rows 1-6 after renaming variables

save "q4_tanz.dta", replace

*further cleaning and renaming to correspond with template


rename A region_10
rename B district_10
rename C constituency_10
rename D ward_10
rename E candidate_name
rename F sex_m
rename G sex_f
rename H party
rename I ward_total_votes_10
rename J elected

* stray K variable

sum K
drop K


drop if _n <= 6

***destringing votes

sum ward_total_votes_10

tab ward_total_votes_10 if ward_total_votes_10 == "UN OPPOSSED"

replace ward_total_votes_10 = "" if ward_total_votes_10 == "UN OPPOSSED"
destring ward_total_votes_10, replace

***creating dummy variable for elected
gen elected_10 = (elected == "ELECTED")
drop elected



* Collapse sex_m and sex_f into one column
gen sex = "M" if sex_m == "M"
replace sex = "F" if sex_f == "F"
drop sex_m sex_f

gen sex_num = 1 if sex == "M"
replace sex_num = 2 if sex == "F"



* Region, district, constituency are mostly blank, they likely have to be filled down


foreach var of varlist region_10 district_10 constituency_10 ward_10 {
    replace `var' = `var'[_n-1] if `var' == "" & _n > 1
}


browse region_10 district_10 constituency_10 ward_10

**hopefully this is the right order, I'm not sure how to crosscheck that.


*rename votes column
rename ward_total_votes_10 votes

*NANGANDO duplicate (2 CCM, 2 CUF) 
* Keep only the highest-vote candidate per ward-party
gsort region_10 district_10 constituency_10 ward_10 party -votes
bysort region_10 district_10 constituency_10 ward_10 party: keep if _n == 1

* Drop candidate-level vars not needed in wide 
drop candidate_name sex sex_num elected_10

*reshape wide
*reshape wide votes, ///
    i(region_10 district_10 constituency_10 ward_10) ///
    j(party) string
    // Creates: votesCCM, votesCHADEMA, etc.
	
	
*Emilia: Here the line stopped. I'm gonna try and see what's wrong

tab party	//there are spaces and that's why it doesn't reshape

gen party_clean = party
replace party_clean = subinstr(party_clean, " ", "_", .)

reshape wide votes, ///
    i(region_10 district_10 constituency_10 ward_10) ///
    j(party_clean) string

	 reshape error
*Rename to match template format 
foreach var of varlist votes* {
    local p = subinstr("`var'", "votes", "", 1)
    rename `var' votes_`p'_10
}

* Add ward totals and merge in ward_id_10 
gen votes_other_10 = .

merge 1:1 region_10 district_10 constituency_10 ward_10 ///
    using "q4_Tz_election_template.dta", ///
    keepusing(ward_id_10 total_candidates_10) nogen

*computing ward total votes
egen ward_total_votes_10 = rowtotal(votes_AFP_10 votes_APPT_MAENDELEO_10 ///
    votes_CCM_10 votes_CHADEMA_10 votes_CHAUSTA_10 votes_CUF_10 ///
    votes_DP_10 votes_JAHAZIASILIA_10 votes_MAKIN_10 votes_NCCR_MAGEUZI_10 ///
    votes_NLD_10 votes_NRA_10 votes_SAU_10 votes_TADEA_10 votes_TLP_10 ///
    votes_UDP_10 votes_UMD_10 votes_UPDP_10), missing

*ordering column to match template
order region_10 district_10 constituency_10 ward_10 ///
    total_candidates_10 ward_total_votes_10 ward_id_10 ///
    votes_AFP_10 votes_APPT_MAENDELEO_10 votes_CCM_10 ///
    votes_CHADEMA_10 votes_CHAUSTA_10 votes_CUF_10 ///
    votes_DP_10 votes_JAHAZIASILIA_10 votes_MAKIN_10 ///
    votes_NCCR_MAGEUZI_10 votes_NLD_10 votes_NRA_10 ///
    votes_SAU_10 votes_TADEA_10 votes_TLP_10 ///
    votes_UDP_10 votes_UMD_10 votes_UPDP_10 votes_other_10

* review
assert _N == 3333

***comes back false

di _N

***3446

duplicates report region_10 district_10 constituency_10 ward_10

br

***there is continued messiness in the ward names

*** starting over again

clear all

* Import and clean the raw data
import excel "q4_Tz_election_2010_raw.xls", clear
* Save a temp file
tempfile q4_tanz
save `q4_tanz'
describe
br
***I think we can drop rows 1-6 after renaming variables
save "q4_tanz.dta", replace
*further cleaning and renaming to correspond with template
rename A region_10
rename B district_10
rename C constituency_10
rename D ward_10
rename E candidate_name
rename F sex_m
rename G sex_f
rename H party
rename I ward_total_votes_10
rename J elected
* stray K variable
sum K
drop K
drop if _n <= 6
***destringing votes
sum ward_total_votes_10
tab ward_total_votes_10 if ward_total_votes_10 == "UN OPPOSSED"
replace ward_total_votes_10 = "" if ward_total_votes_10 == "UN OPPOSSED"
destring ward_total_votes_10, replace
***creating dummy variable for elected
gen elected_10 = (elected == "ELECTED")
drop elected
* Collapse sex_m and sex_f into one column
gen sex = "M" if sex_m == "M"
replace sex = "F" if sex_f == "F"
drop sex_m sex_f
gen sex_num = 1 if sex == "M"
replace sex_num = 2 if sex == "F"
*region, district, constituency are mostly blank, fill down
foreach var of varlist region_10 district_10 constituency_10 ward_10 {
    replace `var' = `var'[_n-1] if `var' == "" & _n > 1
}

*clean ward names
replace ward_10 = strlower(strtrim(ward_10))
replace region_10 = strlower(strtrim(region_10))
replace district_10 = strlower(strtrim(district_10))
replace ward_10 = subinstr(ward_10, "'", "", .)
replace ward_10 = subinstr(ward_10, "`", "", .)
replace ward_10 = subinstr(ward_10, "-", "", .)
replace ward_10 = subinstr(ward_10, "/", "", .)
replace ward_10 = subinstr(ward_10, "(", "", .)
replace ward_10 = subinstr(ward_10, ")", "", .)
replace ward_10 = subinstr(ward_10, `"""', "", .)
replace ward_10 = strtrim(ward_10)
replace ward_10 = itrim(ward_10)

* Clean party names to match template
replace party = strtrim(party)
replace party = "APPT_MAENDELEO" if party == "APPT - MAENDELEO"
replace party = "JAHAZIASILIA"   if party == "JAHAZI ASILIA"
replace party = "NCCR_MAGEUZI"   if party == "NCCR-MAGEUZI"

*rename votes column
rename ward_total_votes_10 votes

gsort region_10 district_10 constituency_10 ward_10 party -votes
bysort region_10 district_10 constituency_10 ward_10 party: keep if _n == 1

drop candidate_name sex sex_num elected_10

* reshape wide
reshape wide votes, ///
    i(region_10 district_10 constituency_10 ward_10) ///
    j(party) string
*rename to match template format 
foreach var of varlist votes* {
    local p = subinstr("`var'", "votes", "", 1)
    rename `var' votes_`p'_10
}
* Add ward totals and merge in ward_id_10 
gen votes_other_10 = .
merge 1:1 region_10 district_10 constituency_10 ward_10 ///
    using "q4_Tz_election_template.dta", ///
    keepusing(ward_id_10 total_candidates_10) nogen

egen ward_total_votes_10 = rowtotal(votes_AFP_10 votes_APPT_MAENDELEO_10 ///
    votes_CCM_10 votes_CHADEMA_10 votes_CHAUSTA_10 votes_CUF_10 ///
    votes_DP_10 votes_JAHAZIASILIA_10 votes_MAKIN_10 votes_NCCR_MAGEUZI_10 ///
    votes_NLD_10 votes_NRA_10 votes_SAU_10 votes_TADEA_10 votes_TLP_10 ///
    votes_UDP_10 votes_UMD_10 votes_UPDP_10), missing

	
*order columns to match template 
order region_10 district_10 constituency_10 ward_10 ///
    total_candidates_10 ward_total_votes_10 ward_id_10 ///
    votes_AFP_10 votes_APPT_MAENDELEO_10 votes_CCM_10 ///
    votes_CHADEMA_10 votes_CHAUSTA_10 votes_CUF_10 ///
    votes_DP_10 votes_JAHAZIASILIA_10 votes_MAKIN_10 ///
    votes_NCCR_MAGEUZI_10 votes_NLD_10 votes_NRA_10 ///
    votes_SAU_10 votes_TADEA_10 votes_TLP_10 ///
    votes_UDP_10 votes_UMD_10 votes_UPDP_10 votes_other_10
* verify
assert _N == 3333


*** it keeps saying the assertion is false, which means I've created too many wards somehow or they are duplicated?

duplicates list ward_id_10

/* Obs   ward_i~0 |
  |-----------------|
  |  795          . |
  |  796          . |
  |  797          . |
  |  798          . |
  |  799          . |
  |-----------------|
  |  800          . |
  |  801          . |
  |  802          . |
  |  803          . |
  |  804          . |
  |-----------------|
  |  805          . |
  |  806          . |
  |  807          . |
  |  808          . |
  |  809          . |
  |-----------------|
  |  810          . |
  |  811          . |
  |  812          . |
  |  813          . |
  |  982          . |
  |-----------------|
  | 1317          . |
  +-----------------
*/

duplicates list ward_10

/* Group    Obs             ward_10 |
  |----------------------------------|
  |     1    795              bangwe |
  |     1   3334              bangwe |
  |     2    526                boma |
  |     2   1695                boma |
  |     2   3267                boma |
  |----------------------------------|
  |     3    775            bugarama |
  |     3   2722            bugarama |
  |     4    796             buhanda |
  |     4   3335             buhanda |
  |     5   2136            bukandwe |
  |----------------------------------|
  |     5   2673            bukandwe |
  |     6   2815              bukene |
  |     6   3016              bukene |
  |     7   1448              bumera |
  |     7   2639              bumera |
  |----------------------------------|
  |     8   1792               bungu |
  |     8   2323               bungu |
  |     8   3203               bungu |
  |     9    695             businde |
  |     9    797             businde |
  |----------------------------------|
  |     9   3336             businde |
  |    10   1352             butimba |
  |    10   2034             butimba |
  |    11    798          buzebazeba |
  |    11   3337          buzebazeba |
  |----------------------------------|
  |    12   2991            chabutwa |
  |    12   3053            chabutwa |
  |    13    214            chamwino |
  |    13   1696            chamwino |
  |    14    202           changombe |
  |----------------------------------|
  |    14    215           changombe |
  |    15    141             chanika |
  |    15    674             chanika |
  |    15   3160             chanika |
  |    16    308            chemchem |
  |----------------------------------|
  |    16   2338            chemchem |
  |    16   2965            chemchem |
  |    17    255             chikola |
  |    17   2899             chikola |
  |    18   1875          chikongola |
  |----------------------------------|
  |    18   1995          chikongola |
  |    19   1543             chitete |
  |    19   1626             chitete |
  |    20    391              chunyu |
  |    20   1181              chunyu |
  |----------------------------------|
  |    21   3131                duga |
  |    21   3272                duga |
  |    22      4            engutoto |
  |    22     88            engutoto |
  |    23   1235             gehandu |
  |----------------------------------|
  |    23   1282             gehandu |
  |    24    799               gungu |
  |    24   3338               gungu |
  |    25   1809               gwata |
  |    25   2273               gwata |
  |----------------------------------|
  |    26    460               idete |
  |    26   1725               idete |
  |    27    892             igalula |
  |    27   2199             igalula |
  |    27   3071             igalula |
  |----------------------------------|
  |    28   1602               igoma |
  |    28   2036               igoma |
  |    29    677              ihanda |
  |    29   1642              ihanda |
  |    30   1562               ikama |
  |----------------------------------|
  |    30   1661               ikama |
  |    31   1400               ikoma |
  |    31   1420               ikoma |
  |    32    558              ikondo |
  |    32    758              ikondo |
  |----------------------------------|
  |    33    124               ilala |
  |    33    404               ilala |
  |    34   1606              ilembo |
  |    34   2365              ilembo |
  |    35    660             ilemela |
  |----------------------------------|
  |    35   2026             ilemela |
  |    36   2676          ilolangulu |
  |    36   3084          ilolangulu |
  |    37    462               ilula |
  |    37   2096               ilula |
  |----------------------------------|
  |    38   1565              ipande |
  |    38   2890              ipande |
  |    39   1484              isanga |
  |    39   2620              isanga |
  |    39   2766              isanga |
  |----------------------------------|
  |    40   1546            isongole |
  |    40   1664            isongole |
  |    41   1684               itete |
  |    41   1847               itete |
  |    42   1515               itewe |
  |----------------------------------|
  |    42   1611               itewe |
  |    43   1548              itumba |
  |    43   2997              itumba |
  |    44    510              itundu |
  |    44   3113              itundu |
  |----------------------------------|
  |    45    223              iyumbu |
  |    45   2944              iyumbu |
  |    46    125            jangwani |
  |    46   1877            jangwani |
  |    47    800              kagera |
  |----------------------------------|
  |    47   2224              kagera |
  |    47   3339              kagera |
  |    48    882             kagunga |
  |    48   2201             kagunga |
  |    49      5            kaloleni |
  |----------------------------------|
  |    49    907            kaloleni |
  |    50   2492           kambarage |
  |    50   2600           kambarage |
  |    51   1531               kanga |
  |    51   1826               kanga |
  |----------------------------------|
  |    51   2299               kanga |
  |    52   1532            kapalala |
  |    52   2379            kapalala |
  |    53    546             kasanga |
  |    53   1795             kasanga |
  |----------------------------------|
  |    53   2424             kasanga |
  |    54   2731            kashishi |
  |    54   3100            kashishi |
  |    55    801             kasimbu |
  |    55   3340             kasimbu |
  |----------------------------------|
  |    56    802         kasingirima |
  |    56   3341         kasingirima |
  |    57    633              katoma |
  |    57   2072              katoma |
  |    58    634              katoro |
  |----------------------------------|
  |    58   2053              katoro |
  |    59    803            katubuka |
  |    59   3342            katubuka |
  |    60   1341              ketare |
  |    60   1453              ketare |
  |----------------------------------|
  |    61   1728             kibaoni |
  |    61   2382             kibaoni |
  |    62    636            kibirizi |
  |    62    804            kibirizi |
  |    62   3343            kibirizi |
  |----------------------------------|
  |    63   1698          kichangani |
  |    63   1848          kichangani |
  |    64    805              kigoma |
  |    64   3344              kigoma |
  |    65   1087              kikole |
  |----------------------------------|
  |    65   1666              kikole |
  |    66    204            kilakala |
  |    66   1701            kilakala |
  |    67    227            kilimani |
  |    67    316            kilimani |
  |----------------------------------|
  |    67   2497            kilimani |
  |    68   3152              kilole |
  |    68   3240              kilole |
  |    69   2126            kiloleli |
  |    69   2747            kiloleli |
  |----------------------------------|
  |    69   3057            kiloleli |
  |    70   2978            kiloleni |
  |    70   3116            kiloleni |
  |    71    134             kimanga |
  |    71   3323             kimanga |
  |----------------------------------|
  |    72    806             kipampa |
  |    72   3345             kipampa |
  |    73   2408              kipili |
  |    73   3059              kipili |
  |    74    978            kirongwe |
  |----------------------------------|
  |    74   2302            kirongwe |
  |    75   1780             kisanga |
  |    75   3060             kisanga |
  |    76   2139              kisesa |
  |    76   2791              kisesa |
  |----------------------------------|
  |    77   1018            kisiwani |
  |    77   3294            kisiwani |
  |    78   2500             kitanda |
  |    78   2527             kitanda |
  |    79   1764              kitete |
  |----------------------------------|
  |    79   2979              kitete |
  |    80    807           kitongoni |
  |    80   3346           kitongoni |
  |    81    143             kitunda |
  |    81   3061             kitunda |
  |----------------------------------|
  |    82    684             kituntu |
  |    82   2945             kituntu |
  |    83    228   kiwanja cha ndege |
  |    83   1704   kiwanja cha ndege |
  |    84   1587             kongolo |
  |----------------------------------|
  |    84   2141             kongolo |
  |    85    808         machinjioni |
  |    85   3347         machinjioni |
  |    86   1497           maendeleo |
  |    86   1616           maendeleo |
  |----------------------------------|
  |    87   1533             magamba |
  |    87   2385             magamba |
  |    88    163            magomeni |
  |    88   1770            magomeni |
  |    88   2252            magomeni |
  |----------------------------------|
  |    89    467             mahenge |
  |    89   1865             mahenge |
  |    90    565           mahongole |
  |    90   1591           mahongole |
  |    91     92             majengo |
  |----------------------------------|
  |    91    231             majengo |
  |    91    809             majengo |
  |    91    914             majengo |
  |    91   1110             majengo |
  |    91   1498             majengo |
  |----------------------------------|
  |    91   1881             majengo |
  |    91   2355             majengo |
  |    91   2459             majengo |
  |    91   2565             majengo |
  |    91   2702             majengo |
  |----------------------------------|
  |    91   2843             majengo |
  |    91   3136             majengo |
  |    91   3301             majengo |
  |    91   3348             majengo |
  |    92   1429            majimoto |
  |----------------------------------|
  |    92   2386            majimoto |
  |    93    262             makanda |
  |    93   2905             makanda |
  |    94   1020             makanya |
  |    94   3245             makanya |
  |----------------------------------|
  |    95    493             makonde |
  |    95   1060             makonde |
  |    96     93            makuyuni |
  |    96    964            makuyuni |
  |    96   3213            makuyuni |
  |----------------------------------|
  |    97    109             malambo |
  |    97   2623             malambo |
  |    98    550           malangali |
  |    98   1553           malangali |
  |    98   2356           malangali |
  |----------------------------------|
  |    99    359              malolo |
  |    99   1185              malolo |
  |    99   1782              malolo |
  |    99   2980              malolo |
  |   100   1521               mamba |
  |----------------------------------|
  |   100   2387               mamba |
  |   100   3228               mamba |
  |   101    294               manda |
  |   101    494               manda |
  |   101   1003               manda |
  |----------------------------------|
  |   102   1092             mandawa |
  |   102   1187             mandawa |
  |   103   1093              masoko |
  |   103   1617              masoko |
  |   103   1676              masoko |
  |----------------------------------|
  |   104   1247           masqaroda |
  |   104   1294           masqaroda |
  |   105   1957            masuguru |
  |   105   3302            masuguru |
  |   106   1458             matongo |
  |----------------------------------|
  |   106   2624             matongo |
  |   106   2880             matongo |
  |   107   3258             mbaramo |
  |   107   3303             mbaramo |
  |   108    177               mbezi |
  |----------------------------------|
  |   108   2312               mbezi |
  |   109   2682              mbogwe |
  |   109   3038              mbogwe |
  |   110    361               mbuga |
  |   110   1867               mbuga |
  |----------------------------------|
  |   111   1524             mbugani |
  |   111   2039             mbugani |
  |   111   2981             mbugani |
  |   112   1535             mbuyuni |
  |   112   1711             mbuyuni |
  |----------------------------------|
  |   112   1896             mbuyuni |
  |   113    207            miburani |
  |   113   2303            miburani |
  |   114    602            miembeni |
  |   114    917            miembeni |
  |----------------------------------|
  |   115   1103              milola |
  |   115   1852              milola |
  |   116   1712               mindu |
  |   116   2569               mindu |
  |   117    918            mji mpya |
  |----------------------------------|
  |   117   1714            mji mpya |
  |   118    194            mjimwema |
  |   118    568            mjimwema |
  |   118   2464            mjimwema |
  |   119   2465               mjini |
  |----------------------------------|
  |   119   2606               mjini |
  |   120    377               mkoka |
  |   120   1158               mkoka |
  |   121   2344              mkongo |
  |   121   2538              mkongo |
  |----------------------------------|
  |   122   1738               mkula |
  |   122   2130               mkula |
  |   123   1715              mkundi |
  |   123   1899              mkundi |
  |   123   2014              mkundi |
  |----------------------------------|
  |   124   1817             mkuyuni |
  |   124   2042             mkuyuni |
  |   125    378               mlali |
  |   125   1836               mlali |
  |   126    500            mlangali |
  |----------------------------------|
  |   126   1648            mlangali |
  |   127    440               mlowa |
  |   127    569               mlowa |
  |   128    343               mondo |
  |   128   2173               mondo |
  |----------------------------------|
  |   128   2735               mondo |
  |   128   2751               mondo |
  |   129   1632               mpapa |
  |   129   2517               mpapa |
  |   130    281              msanga |
  |----------------------------------|
  |   130   2292              msanga |
  |   131    157             msasani |
  |   131   1679             msasani |
  |   132   1023              msindo |
  |   132   2540              msindo |
  |----------------------------------|
  |   133    265               msisi |
  |   133   2930               msisi |
  |   134   1883              mtonya |
  |   134   1986              mtonya |
  |   135   1115                mtua |
  |----------------------------------|
  |   135   1163                mtua |
  |   136    554             mtwango |
  |   136    570             mtwango |
  |   137    668             muganza |
  |   137    785             muganza |
  |----------------------------------|
  |   137    816             muganza |
  |   138    298            muungano |
  |   138    669            muungano |
  |   138   1574            muungano |
  |   138   1942            muungano |
  |----------------------------------|
  |   138   3117            muungano |
  |   139   2100             mwamala |
  |   139   2827             mwamala |
  |   139   3026             mwamala |
  |   140   2771         mwamashimba |
  |----------------------------------|
  |   140   3003         mwamashimba |
  |   141    986              mwanga |
  |   141   2884              mwanga |
  |   142    810    mwanga kaskazini |
  |   142   3349    mwanga kaskazini |
  |----------------------------------|
  |   143    811       mwanga kusini |
  |   143   3350       mwanga kusini |
  |   144    987             mwaniko |
  |   144   2174             mwaniko |
  |   145   1575               mwaya |
  |----------------------------------|
  |   145   1742               mwaya |
  |   145   1869               mwaya |
  |   146   1068              mwenge |
  |   146   1916              mwenge |
  |   146   2829              mwenge |
  |----------------------------------|
  |   147   1069          nachingwea |
  |   147   1164          nachingwea |
  |   147   1191          nachingwea |
  |   148   1195            nanganga |
  |   148   1920            nanganga |
  |----------------------------------|
  |   149   1944           nanguruwe |
  |   149   1993           nanguruwe |
  |   150   2609               ndala |
  |   150   3045               ndala |
  |   151   2610            ndembezi |
  |----------------------------------|
  |   151   3007            ndembezi |
  |   152    417               nduli |
  |   152    442               nduli |
  |   153     30             nduruma |
  |   153   2234             nduruma |
  |----------------------------------|
  |   154    920              ngambo |
  |   154   2985              ngambo |
  |   155   1071               ngapa |
  |   155   2580               ngapa |
  |   156    921               njoro |
  |----------------------------------|
  |   156   1025               njoro |
  |   156   1267               njoro |
  |   157   2654               nkoma |
  |   157   2814               nkoma |
  |   158   1619             nsalala |
  |----------------------------------|
  |   158   2830             nsalala |
  |   159   2392              nsimbo |
  |   159   3089              nsimbo |
  |   160   2740               ntobo |
  |   160   3011               ntobo |
  |----------------------------------|
  |   161    644             nyakato |
  |   161   1332             nyakato |
  |   161   2029             nyakato |
  |   162   1333           nyamatare |
  |   162   1436           nyamatare |
  |----------------------------------|
  |   163   2710           nyandekwa |
  |   163   3012           nyandekwa |
  |   164     31        oldonyosambu |
  |   164    114        oldonyosambu |
  |   165   1471               pemba |
  |----------------------------------|
  |   165   1841               pemba |
  |   166   1072             rahaleo |
  |   166   1885             rahaleo |
  |   167    418               ruaha |
  |   167   1785               ruaha |
  |----------------------------------|
  |   167   1871               ruaha |
  |   168   1507              ruanda |
  |   168   1655              ruanda |
  |   168   2523              ruanda |
  |   169    812              rubuga |
  |----------------------------------|
  |   169   3351              rubuga |
  |   170    813             rusimbi |
  |   170   3352             rusimbi |
  |   171   1026                ruvu |
  |   171   2280                ruvu |
  |----------------------------------|
  |   172   2079               senga |
  |   172   2363               senga |
  |   173   2212                sima |
  |   173   2636                sima |
  |   174    902               simbo |
  |----------------------------------|
  |   174   3013               simbo |
  |   175    386          songambele |
  |   175    711          songambele |
  |   175   1270          songambele |
  |   175   3119          songambele |
  |----------------------------------|
  |   176   1028            stesheni |
  |   176   1177            stesheni |
  |   177   2152              sukuma |
  |   177   2789              sukuma |
  |   178   1621               swaya |
  |----------------------------------|
  |   178   1682               swaya |
  |   179   1510             tembela |
  |   179   1622             tembela |
  |   180    211              temeke |
  |   180   1923              temeke |
  |----------------------------------|
  |   181     17              terrat |
  |   181   1321              terrat |
  |   182   1086               tingi |
  |   182   2491               tingi |
  |   183   2247               tumbi |
  |----------------------------------|
  |   183   2988               tumbi |
  |   184    198               tungi |
  |   184   1721               tungi |
  |   185    247               uhuru |
  |   185   1301               uhuru |
  |----------------------------------|
  |   186   2179             usagara |
  |   186   3151             usagara |
  |   187    574            utengule |
  |   187   1745            utengule |
  |   188   2720               uyogo |
  |----------------------------------|
  |   188   3125               uyogo |
  +----------------------------------+
*/

sort ward_10

**I think I need to collapse these duplicate rows into each other; however, I'm not sure how to do so without potentially deleting useful info. 

***Also in some cases these wards seem to exist across multiple constituencies (for example: Boma). So I think it's better to leave well enough alone.

use "q4_tanz.dta", clear

br

describe

save "q4_tanz.dta", replace

codebook ward_10


































********************************************************************************

/*Q5: Tanzania PSLE School Matching


Match 17,329 PSLE schools to the `q5_school_location` dataset (19,733 schools) to get ward information. The final dataset should have 17,329 rows + a ward column.  */


clear all


clear all

use "q5_psle_2020_data.dta", clear

describe
br

save "q5_psle_work.dta", replace
***it looks like the observations are a mix of string and number, so I need to extract the code amd fix the formatting

gen school_code = ""
replace school_code = upper(regexs(1)) if ///
    regexm(strtrim(school_code_address), "shl_(ps[0-9]+)\.htm")

* Checking
count if school_code == ""
    // Should be 0

* Also cleaning the school name 
gen school_name_clean = schoolname
replace school_name_clean = strtrim(school_name_clean)
replace school_name_clean = upper(school_name_clean)

replace school_name_clean = regexs(1) if ///
    regexm(school_name_clean, "^(.+) PRIMARY SCHOOL")
replace school_name_clean = strtrim(school_name_clean)

replace school_name_clean = regexs(1) if ///
    regexm(school_name_clean, "^(.+) - PS[0-9]+")
replace school_name_clean = strtrim(school_name_clean)

***Checking out the location data

use "q5_school_location.dta", clear

describe

save "q5_school_location_work.dta", replace

**we can use the school code to merge the data sets. In this case that is the variable NECTACentreNo

rename NECTACentreNo school_code
replace school_code = strtrim(upper(school_code))

* Clean school name for fuzzy matching
gen loc_school_name = upper(strtrim(School))

***looking for duplicates

duplicates tag school_code, gen(dup)
tab dup


/*         dup |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     17,925       90.84       90.84
          1 |         22        0.11       90.95
       1785 |      1,786        9.05      100.00
------------+-----------------------------------
      Total |     19,733      100.00
*/



browse if dup == 1

**looking at this output, I see that some schools straddle multiple wards. However, the "RegNo" variable differs. So I should clean that. The main takeaway is that RegNo may be the more reliable indicator in this dataset


gen reg_nom = RegNo
replace reg_nom = strtrim(reg_nom)
replace reg_nom = upper(reg_nom)
replace reg_nom = subinstr(reg_nom, " ", "", .)

* Extract just the numeric part after "EM."
replace reg_nom = regexs(1) if ///
    regexm(reg_nom, "^EM\.([0-9]+)$")

*trim
replace reg_nom = strtrim(reg_nom)

* Check for any that didn't match
count if !regexm(reg_nom, "^[0-9]+$")
list reg_nom if !regexm(reg_nom, "^[0-9]+$")

/* |  reg_nom |
       |----------|
 1330. |    EA.12 |
 6091. | EM.8480. |
10043. |   EA.116 |
15268. | EM.9011. |
*/

**I guess some had an EA prefix

replace reg_nom = subinstr(reg_nom, "EA.", "", .)
replace reg_nom = subinstr(reg_nom, "EM.", "", .)
replace reg_nom = subinstr(reg_nom, ".", "", .)  
replace reg_nom = strtrim(reg_nom)

count if !regexm(reg_nom, "^[0-9]+$")
list reg_nom if !regexm(reg_nom, "^[0-9]+$")

**This seems to have worked

br

***So I'm going to keep reg_nom as hopefully a more complete identifying variable after the merge

***And then clean up the school_code

*replace school_code = "." if school_code == "N/A"

*EMILIA CHANGE
replace school_code = "" if school_code == "N/A"

count if school_code == ""

**for some reason it's making me nervous that school_code is a string variable
destring school_code, replace

list school_code if school_code == .

replace school_code = subinstr(school_code, "PS", "", .)

destring school_code, replace


**Then I'm going to do the same in the other file

save "q5_school_location_work.dta", replace

use "q5_psle_work.dta", clear

replace school_code = subinstr(school_code, "PS", "", .)

destring school_code, replace

list school_code if school_code == .

*no missings

save "q5_psle_work.dta", replace

****temp files probably would have been useful here


**Then the merge
use "q5_school_location_work.dta", clear

save "q5_location_formerge.dta", replace

* Merge - use m:1 since location has some duplicate school_codes
use "q5_psle_work.dta", clear
merge m:1 school_code using "q5_location_formerge.dta"

duplicates list school_code

***Error response: variable school_code does not uniquely identify observations in the using data

duplicates list school_code

/*Duplicates in terms of school_code

(0 observations are duplicates) */

use "q5_location_formerge.dta", clear
duplicates list school_code

*okay, there are tons of duplicates here as noted earlier. The reg_nom var is the unique identifier... but there seems to be no way to bring that into the original file. So I guess I'm just going to have to drop the duplicates and hope for the best


duplicates drop school_code, force
duplicates list school_code

**no more duplicates


save "q5_location_formerge.dta", replace

use "q5_psle_work.dta", clear
destring school_code, replace
merge m:1 school_code using "q5_location_formerge.dta"

*** this seems to have worked 

save "q5_psle_work.dta", replace

tab _merge
/*
   Matching result from |
                  merge |      Freq.     Percent        Cum.
------------------------+-----------------------------------
        Master only (1) |        292        1.60        1.60
         Using only (2) |        900        4.94        6.54
            Matched (3) |     17,037       93.46      100.00
------------------------+-----------------------------------
                  Total |     18,229      100.00

*/ 

*merged, more or less, but this remains a little messy

**and i don't have the right number of rows

***I think this is the best I can do

***I think I needed to create an identifier from the og file that would match with reg_nom. In class, Beatrice spent time talking about a "cross" command? Maybe I was supposed to use that somehow. I'm not sure.



describe

misstable summarize


***Oh wait I scrolled to the end of the file and the nonmatched schools just have "." as their serial number, but student and school information

***I'm going to check if these are duplicates by checking one school name at random



count if School == "SHINNING STAR"
  1

  **This only appears once. So these are maybe schools that are in one data set but not another? probably I could just drop them if serial == . , but I'm not sure if that would be deleting important info. I'm going to save and wrap up work
  
 
use "q5_psle_work.dta", clear

codebook school_code
