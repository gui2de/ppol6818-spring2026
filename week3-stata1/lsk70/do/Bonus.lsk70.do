****************************************************
* PPOL 6818 – Stata Assignment 1
* Luke Keller
*
* Folder structure:
* lsk70/
* ├── do/        (do-files)
* ├── data/      (raw inputs: .dta, .xlsx, .pdf)
* └── outputs/   (log files, generated outputs)
****************************************************

clear all
set more off

*Working directory set-up
if c(username) == "lukekeller" {
    global wd "/Users/lukekeller/Desktop/ppol6818-spring2026/week3-stata1/lsk70"
}

*Subfolder set-up
global do    "$wd/do"
global data  "$wd/data"
global out   "$wd/outputs"

cd "$wd"

*Create outputs folder if it doesn't already exist
capture mkdir "$out"

*Start log
capture log close
log using "$out/bonus.log", text replace

****************************************************

local htmlfile "$data/shl_ps0101114.html"

local raw = fileread("`htmlfile'")

*Put raw HTML into a 1-row dataset so we can manipulate with regex
clear
set obs 1
gen strL page_raw = `"`raw'"'

*Clean HTML into plain text
gen strL page = page_raw

*Remove tags
replace page = ustrregexra(page, "<[^>]+>", " ")

*Replace HTML spacing entities
replace page = subinstr(page, "&nbsp;", " ", .)

*Normalize whitespace (turn line breaks into spaces, collapse repeats)
replace page = ustrregexra(page, "[\r\n\t]+", " ")
replace page = ustrregexra(page, "\s+", " ")
replace page = strtrim(page)

*Quick check
display substr(page, 1, 500)

*Split cleaned page into student blocks

*Add a delimiter before each candidate id: PS#######-####

replace page = ustrregexra(page, "(PS[0-9]{7}-[0-9]{4})", "|||$1")

*Split into separate variables at the delimiter
split page, parse("|||") gen(block)

*The block1 is everything before the first student
drop block1

*Reshape blocks wide -> long (16 rows)
gen id = 1
reshape long block, i(id) j(student_index)

drop id student_index

*Quick check
count
list block in 1/2, noobs

****************************************************

*Create student-level variables

gen str20 cand_id = ""
gen str20 prem_number = ""
gen str1  gender = ""
gen str60 name = ""
gen strL  grades = ""

*Parse each block into components

replace cand_id = ustrregexs(1) if ustrregexm(block, ///	
    "^\s*(PS[0-9]{7}-[0-9]{4})\s+([0-9]{8,})\s+([MF])\s+(.+?)\s+(Kiswahili.*)$")	// looks for pattern given in parenthesis within string, then (1, 2, ..., n) refers to which bit of remebered information it grabs
	
replace prem_number = ustrregexs(2) if ustrregexm(block, ///
    "^\s*(PS[0-9]{7}-[0-9]{4})\s+([0-9]{8,})\s+([MF])\s+(.+?)\s+(Kiswahili.*)$")

replace gender = ustrregexs(3) if ustrregexm(block, ///
    "^\s*(PS[0-9]{7}-[0-9]{4})\s+([0-9]{8,})\s+([MF])\s+(.+?)\s+(Kiswahili.*)$")

replace name = strtrim(ustrregexs(4)) if ustrregexm(block, ///
    "^\s*(PS[0-9]{7}-[0-9]{4})\s+([0-9]{8,})\s+([MF])\s+(.+?)\s+(Kiswahili.*)$")

replace grades = ustrregexs(5) if ustrregexm(block, ///
    "^\s*(PS[0-9]{7}-[0-9]{4})\s+([0-9]{8,})\s+([MF])\s+(.+?)\s+(Kiswahili.*)$")

*Parse school code from cand_id
gen str12 schoolcode = substr(cand_id, 1, 9)	// string, start, length (takes 9 didgets starting at 1)

*Quick check
list schoolcode cand_id prem_number gender name in 1/5, noobs

****************************************************

*Extract subject grades

*Creat var placeholders
gen str1 kiswahili = ""
gen str1 english   = ""
gen str1 maarifa   = ""
gen str1 hisabati  = ""
gen str1 science   = ""
gen str1 uraia     = ""
gen str1 average   = ""

*Pull out each letter from respective subjects, mapping to vars
replace kiswahili = ustrregexs(1) if ustrregexm(grades, "Kiswahili\s*-\s*([A-E])")
replace english   = ustrregexs(1) if ustrregexm(grades, "English\s*-\s*([A-E])")
replace maarifa   = ustrregexs(1) if ustrregexm(grades, "Maarifa\s*-\s*([A-E])")
replace hisabati  = ustrregexs(1) if ustrregexm(grades, "Hisabati\s*-\s*([A-E])")
replace science   = ustrregexs(1) if ustrregexm(grades, "Science\s*-\s*([A-E])")
replace uraia     = ustrregexs(1) if ustrregexm(grades, "Uraia\s*-\s*([A-E])")

replace average   = ustrregexs(1) if ustrregexm(grades, "Average\s+Grade\s*-\s*([A-E])")

****************************************************

*Finalize dataset and save outputs

* Keep only required variables
keep schoolcode cand_id gender prem_number name ///
     kiswahili english maarifa hisabati science uraia average

*Order nicely
order schoolcode cand_id gender prem_number name ///
      kiswahili english maarifa hisabati science uraia average

*Save outputs
save "$out/bonus_studentlevel.dta", replace
export delimited using "$out/bonus_studentlevel.csv", replace

****************************************************

log close
