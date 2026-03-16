*******************************************************
* PPOL6818 - Stata 1
* Author: Grace Huang
*******************************************************

**************
* Question 1 *
**************
clear all
set more off
global data_dir "/Users/gracehuang/Documents/MPP/PPOL6818 local/Stata 1/q1"

use "$data_dir/student.dta", clear

* Merge the teacher dataset (link primary_teacher with teacher)
rename primary_teacher teacher
merge m:1 teacher using "$data_dir/teacher.dta"
drop if _merge == 2 // Drop teachers without matching students (if any)
drop _merge

* Merge the school dataset (matched by school variable)
merge m:1 school using "$data_dir/school.dta"
drop if _merge == 2
drop _merge

* Merge the subject dataset (matched by subject variable)
merge m:1 subject using "$data_dir/subject.dta"
drop if _merge == 2
drop _merge

* Question (a): Mean attendance for schools in the South
summarize attendance if loc == "South"

* Question (b): Proportion of high school students with tested-subject teachers
summarize tested if level == "High"

* Question (c): Mean GPA of all students in the district
summarize gpa

* Question (d): Mean attendance for each middle school
tabstat attendance if level == "Middle", by(school) stat(mean)

**************
* Question 2 *
**************
clear all
set more off
use "/Users/gracehuang/Documents/MPP/PPOL6818 local/Stata 1/q2_village_pixel.dta", clear

*******
* (a) *
*******

* Within each pixel, compute the standard deviation or range of payout.
* If the range equals 0, all households in the pixel have the same payout.
bysort pixel: egen payout_min = min(payout)
bysort pixel: egen payout_max = max(payout)

gen pixel_consistent = (payout_min == payout_max)

* Convert to 1/0 format
label define lb_consist 1 "Consistent" 0 "Inconsistent"
label values pixel_consistent lb_consist

tab pixel_consistent
drop payout_min payout_max

*******
* (b) *
*******

* Tag each unique village–pixel combination (the unique one equals 1, others 0)
egen pixel_tag = tag(village pixel)

* Number of distinct pixels in each village
bysort village: egen num_pixels = total(pixel_tag)

* Indicator for whether a village spans multiple pixels
gen pixel_village = (num_pixels > 1)

label define lb_pv 0 "Single Pixel" 1 "Multiple Pixels", replace
label values pixel_village lb_pv

tab pixel_village

*******
* (c) *
*******

* First obtain the payout for each village–pixel (assumed consistent within pixel)
bysort village pixel: egen pix_payout_min = min(payout)
bysort village pixel: egen pix_payout_max = max(payout)

* Use the payout value of each village–pixel to check consistency
* across pixels when a village spans multiple pixels
* Only use the first observation of each village–pixel (tag to avoid double counting)
egen vp_tag = tag(village pixel)

bysort village: egen v_pixpay_min = min(pix_payout_min) if vp_tag
bysort village: egen v_pixpay_max = max(pix_payout_min) if vp_tag
bysort village: egen v_pixpay_consistent = min(v_pixpay_min == v_pixpay_max)  // village-level constant

* Categorization
gen category = .
replace category = 1 if num_pixels == 1
replace category = 2 if num_pixels > 1 & v_pixpay_consistent == 1
replace category = 3 if num_pixels > 1 & v_pixpay_consistent == 0

label define lb_cat 1 "Single Pixel" 2 "Multi-Pixel/Same Payout" 3 "Multi-Pixel/Diff Payout", replace
label values category lb_cat

tab category

* List household IDs in Category 2
list hhid village pixel payout if category == 2

**************
* Question 3 *
**************
clear all
set more off
cd "/Users/gracehuang/Documents/MPP/PPOL6818 local/Stata 1"
use "q3_proposal_review.dta", clear

* Standardize variable names
rename Rewiewer1    netid1
rename Reviewer2    netid2
rename Reviewer3    netid3

rename Review1Score    score1
rename Reviewer2Score  score2
rename Reviewer3Score  score3

* Reshape the data from "wide" to "long"
* Each proposal_id will have 3 rows, one for each reviewer
reshape long score netid, i(proposal_id) j(reviewer_pos)

* Calculate mean and standard deviation at the reviewer (NetID) level
bysort netid: egen r_mean = mean(score)
bysort netid: egen r_sd   = sd(score)

* Create standardized scores
gen stand_score = (score - r_mean) / r_sd

* Drop auxiliary variables and reshape back to "wide" format
keep proposal_id reviewer_pos stand_score
reshape wide stand_score, i(proposal_id) j(reviewer_pos)

* Rename standardized score variables as required
rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

* Compute the average standardized score for each proposal
egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)

* Rank proposals: 1 = highest score, 128 = lowest score
gsort -average_stand_score
gen rank = _n

* Save or display results
label var rank "Proposal Rank (1=Highest)"
list proposal_id average_stand_score rank in 1/10

**************
* Question 4 *
**************
clear all
set more off
global excel_t21 "/Users/gracehuang/Documents/MPP/PPOL6818 local/Stata 1/q4_Pakistan_district_table21.xlsx"

* Set up an empty tempfile
tempfile table21
save `table21', replace emptyok

forvalues i = 1/135 {
    * Import one sheet at a time; allstring avoids OCR numeric issues
    import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring
	
	* Progress indicator
    di as error "Processing sheet `i'"

    * Keep ONLY the row that corresponds to the first data row: "18 AND ABOVE". 
    * Using regexm() is more robust to extra spaces or OCR noise.
    * There can be multiple "18 AND ..." rows (overall/rural/urban), but the instructions ask for the FIRST data row, so we keep the first match.
    keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND") == 1
    keep in 1

    * Store the row label (for eyeballing/QA later)
    rename TABLE21PAKISTANICITIZEN1 table21

    * District/sheet identifier (1..135)
    gen table = `i'

    * Create 12 empty slots for the 12 numbers we need (columns 2–13)
    forvalues j = 1/12 {
        gen x`j' = ""
    }

    * We don't trust that OCR columns line up perfectly across districts. Instead, we scan the remaining columns left-to-right and fill x1..x12 with the first 12 cells that look numeric.
    * 1) ds ... , not   => get a list of all other variables (the "data columns")
    * 2) loop over those variables in order
    * 3) if a cell contains digits, copy it into the current slot xk
    * 4) once xk is filled, move to x(k+1)
    local k = 1
	
	foreach col in B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC{
		* Check if the variable exists in the dataset
		capture confirm variable `col'
		
		* If the variable does not exist, skip to the next column
		if _rc != 0 continue
		
		* Ensure we haven't exceeded our limit of 12 target variables (x1 to x12)
		if `k' <= 12 {
			* Copy value from the current column (`col') to the target (`x`k'') ONLY IF:
			* The target slot is currently empty
			* The source value contains at least one digit (valid data)
			replace x`k' = `col' if x`k'=="" & regexm(`col', "[0-9]")
			
			* Check if the target slot `x`k'' was successfully filled
			count if x`k' != ""
			
			* If filled (count is 1), increment `k` to prepare the next slot
			if r(N) == 1 local k = `k' + 1
			}
	}

    * Keep only what we need (one row per district/sheet)
    keep table table21 x1-x12

    * Append this district row to the accumulating tempfile
    append using `table21'
    save `table21', replace
}

* Rename variables to meaningful names
rename x1  pop_all
rename x2  cnic_yes_all
rename x3  cnic_no_all
rename x4  pop_male
rename x5  cnic_yes_male
rename x6  cnic_no_male
rename x7  pop_female
rename x8  cnic_yes_female
rename x9  cnic_no_female
rename x10 pop_trans
rename x11 cnic_yes_trans
rename x12 cnic_no_trans

use `table21', clear
br

**************
* Question 5 *
**************
clear all
use "/Users/gracehuang/Documents/MPP/PPOL6818 local/Stata 1/q5/q5_Tz_student_roster_html.dta", clear

* 1. Split the long string
* We observe that each row is separated by <br>, so we split using <br>
split s, parse("<br>")
* Now we have variables s1, s2, s3, s4, s5, s6, etc., which we process separately

* 2. Extract School Name and School Code
* Both pieces of information are in s1. The format of s1 looks like:
* "...ALBEHIJE PRIMARY SCHOOL - PS0101114..."
* We split the name and the code using " - PS"
split s1, parse(" - PS") generate(info)
* info1 contains the school name "...ALBEHIJE PRIMARY SCHOOL"
* info2 contains the school code "0101114 ..."

* (A) Process School Name (info1)
* info1 contains HTML tags at the beginning (e.g. <H3><P...>), which we need to remove.
* We split by ">" since the school name is usually in the last segment.
split info1, parse(">") generate(name_part)
* Use a loop to keep the last non-empty string, which is typically the school name
gen school_name = ""
foreach v of varlist name_part* {
    replace school_name = `v'
}
* Remove any leading or trailing spaces
replace school_name = strtrim(school_name)

* (B) Process School Code (info2)
* info2 looks like "0101114  </P></H3>..."
* We only need the leading digits, which are usually followed by a space or "<"
* Then we add back the "PS" prefix
gen school_code = "PS" + substr(info2, 1, 7) // code length is 7 digits

* 3. Extract Number of Students
* This information is also in s1, identified by the keyword "WALIOFANYA MTIHANI :"
* We extract the value directly from s1
split s1, parse("WALIOFANYA MTIHANI :") generate(stu_split)
* stu_split2 contains the numeric part after the colon
destring stu_split2, generate(students_count) force
* (destring, force ignores non-numeric characters such as spaces)

* 4. Extract Average Score
* This information is in s2, identified by "WASTANI WA SHULE"
split s2, parse(":") generate(avg_split)
destring avg_split2, generate(school_avg) force

* 5. Extract Student Group (Binary Group)
* This information is in s3, identified by "KUNDI LA SHULE"
* If it contains "chini" (under), assign 0; otherwise assign 1
gen student_group = 0
replace student_group = 1 if strpos(s3, "juu") > 0 | strpos(s3, "above") > 0
* Alternatively, check for "NOT under"
* The question specifies under 40 vs 40 or above, so default 0 represents under 40

* 6. Extract Three Rankings
* These are in s4 (Council), s5 (Region), and s6 (National)
* The format is "NAFASI ... : 22 kati ya 46"
* We extract the part after the colon and replace "kati ya" with "out of"

* (A) Council Rank (s4)
split s4, parse(":") generate(rank_c)
gen rank_council = subinstr(rank_c2, "kati ya", "out of", .)
replace rank_council = strtrim(rank_council)

* (B) Region Rank (s5)
split s5, parse(":") generate(rank_r)
gen rank_region = subinstr(rank_r2, "kati ya", "out of", .)
replace rank_region = strtrim(rank_region)

* (C) National Rank (s6)
split s6, parse(":") generate(rank_n)
gen rank_national = subinstr(rank_n2, "kati ya", "out of", .)
replace rank_national = strtrim(rank_national)

* 7. Clean and keep final variables
keep school_name school_code students_count school_avg student_group rank_council rank_region rank_national

* View results
list

*********
* Bonus *
*********
clear all
set more off
use "/Users/gracehuang/Documents/MPP/PPOL6818 local/Stata 1/q5/q5_Tz_student_roster_html.dta", clear

* 1) Extract schoolcode (PS#######) from the raw string
gen schoolcode = ""
replace schoolcode = regexs(1) if regexm(s, "(PS[0-9]{7})")

* 2) Strip HTML tags and normalize whitespace
gen txt = s
replace txt = ustrregexra(txt, "<[^>]*>", " ")          // remove html tags
replace txt = ustrregexra(txt, "&nbsp;|&#160;", " ")    // html spaces (if any)
replace txt = ustrregexra(txt, "[\r\n\t]+", " ")        // remove line breaks/tabs
replace txt = ustrregexra(txt, " +", " ")               // collapse multiple spaces
replace txt = strtrim(txt)

* 3) Split into 16 student chunks by cand_id pattern
*    cand_id looks like: PS0101114-0001
gen cut = ustrregexra(txt, "(PS[0-9]{7}-[0-9]{4})", "|||$1")
split cut, parse("|||") gen(seg)

drop cut txt

* seg1 is header junk; student chunks are seg2-seg17 (16 chunks)
drop seg1
keep schoolcode seg*

* reshape to long: 16 rows (one per student)
reshape long seg, i(schoolcode) j(row)
drop if missing(seg) | strtrim(seg)==""

* safety check: we expect 16 rows
count
assert r(N)==16

* do NOT "keep if ..." here; instead assert (avoid silently dropping everything)
assert regexm(seg, "Kiswahili") & regexm(seg, "Average Grade")

* 4) Extract student identifiers and demographics
* cand_id
gen cand_id = ""
replace cand_id = regexs(1) if regexm(seg, "(PS[0-9]{7}-[0-9]{4})")

* prem_number:
* Usually appears right after cand_id; allow 8-15 digits to be robust to OCR
gen prem_number = ""
replace prem_number = regexs(1) if regexm(seg, "PS[0-9]{7}-[0-9]{4} *([0-9]{8,15})")

* gender (M/F): typically after prem_number
gen gender = ""
replace gender = regexs(1) if regexm(seg, "PS[0-9]{7}-[0-9]{4} *[0-9]{8,15} *([MF])")

* name: between gender and "Kiswahili"
gen name = ""
replace name = regexs(1) if regexm(seg, " [MF] ([A-Z ]+?) Kiswahili")
replace name = strtrim(name)

* 5) Extract subject grades (A-E)
gen kiswahili = ""
replace kiswahili = regexs(1) if regexm(seg, "Kiswahili *- *([A-E])")

gen english = ""
replace english = regexs(1) if regexm(seg, "English *- *([A-E])")

gen maarifa = ""
replace maarifa = regexs(1) if regexm(seg, "Maarifa *- *([A-E])")

gen hisabati = ""
replace hisabati = regexs(1) if regexm(seg, "Hisabati *- *([A-E])")

gen science = ""
replace science = regexs(1) if regexm(seg, "Science *- *([A-E])")

gen uraia = ""
replace uraia = regexs(1) if regexm(seg, "Uraia *- *([A-E])")

gen average = ""
replace average = regexs(1) if regexm(seg, "Average Grade *- *([A-E])")

* 6) Keep final dataset + checks
keep schoolcode cand_id gender prem_number name ///
     kiswahili english maarifa hisabati science uraia average

order schoolcode cand_id gender prem_number name ///
      kiswahili english maarifa hisabati science uraia average

* final checks
count
assert r(N)==16

* ensure key fields are not missing
assert schoolcode != ""
assert cand_id    != ""
assert prem_number != ""
assert inlist(gender,"M","F")
assert name != ""
assert kiswahili != "" & english != "" & maarifa != "" & hisabati != "" & science != "" & uraia != "" & average != ""

list, abbrev(24)

* 7) Save cleaned dataset
save "/Users/gracehuang/Documents/MPP/PPOL6818 local/Stata 1/q5/q5_Tz_student_roster_clean.dta", replace
