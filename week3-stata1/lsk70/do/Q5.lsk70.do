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
log using "$out/Q5.log", text replace

****************************************************

*Import html file
local htmlfile "data/shl_ps0101114.html"

dir "data"

local raw = fileread("`htmlfile'")	// read file as text

clear
set obs 1
gen strL page = `"`raw'"'	// puts text into one long row

*Quick check
display substr(page, 1, 300)

*Convert raw HTML into searchable plain text

*Remove all HTML tags like <H1>, <P>, <TABLE>, etc.
replace page = ustrregexra(page, "<[^>]+>", " ")

*Replace HTML non-breaking spaces
replace page = subinstr(page, "&nbsp;", " ", .)

*Convert newlines/tabs into spaces, then collapse repeated spaces
replace page = ustrregexra(page, "[\r\n\t]+", " ")
replace page = ustrregexra(page, "\s+", " ")

*Trim leading/trailing spaces
replace page = strtrim(page)

*Quick check
display substr(page, 1, 400)

*Create output variables (empty)
gen str80 school_name = ""     // school name is text
gen str20 school_code = ""     // code is text

gen students_tested  = .       // numeric (.) means missing for now
gen school_avg_score = .       // numeric ""

gen under40 = .               // numeric: 1=under40, 0=40+

gen council_rank   = .
gen council_total  = .
gen region_rank    = .
gen region_total   = .
gen national_rank  = .
gen national_total = .


*Remove school name header
replace page = ustrregexra(page, "(?i)\bEXAMINATION\s+RESULTS\b", "")
replace page = strtrim(page)
replace page = ustrregexra(page, "\s+", " ")

*Extract school name + code
if ustrregexm(page, "([A-Z ]+SCHOOL)\s*-\s*(PS[0-9]{7})") {
    replace school_name = strtrim(ustrregexs(1))
    replace school_code = strtrim(ustrregexs(2))
}

list school_name school_code, noobs

*Extract students tested
if ustrregexm(page, "WALIOFANYA\s+MTIHANI\s*:\s*([0-9]+)") {
    replace students_tested = real(ustrregexs(1))
}

*Extract school average score
if ustrregexm(page, "WASTANI\s+WA\s+SHULE\s*:\s*([0-9]+(\.[0-9]+)?)") {
    replace school_avg_score = real(ustrregexs(1))
}

*Under-40 group indicator
if ustrregexm(page, "Wanafunzi\s+chini\s+ya\s*40") replace under40 = 1
if ustrregexm(page, "40\s+(na|au)\s+zaidi")      replace under40 = 0

*Council ranking
if ustrregexm(page, "KIHALMASHAURI\s*:\s*([0-9]+)\s*kati\s+ya\s*([0-9]+)") {
    replace council_rank  = real(ustrregexs(1))
    replace council_total = real(ustrregexs(2))
}

*Region ranking
if ustrregexm(page, "KIMKOA\s*:\s*([0-9]+)\s*kati\s+ya\s*([0-9]+)") {
    replace region_rank  = real(ustrregexs(1))
    replace region_total = real(ustrregexs(2))
}

*National ranking
if ustrregexm(page, "KITAIFA\s*:\s*([0-9]+)\s*kati\s+ya\s*([0-9]+)") {
    replace national_rank  = real(ustrregexs(1))
    replace national_total = real(ustrregexs(2))
}

*Quick check
list school_name school_code students_tested school_avg_score under40 ///
     council_rank council_total region_rank region_total national_rank national_total, noobs
****************************************************
*Drop any extra vars
keep school_name school_code students_tested school_avg_score under40 ///
     council_rank council_total region_rank region_total national_rank national_total

order school_name school_code students_tested school_avg_score under40 ///
      council_rank council_total region_rank region_total national_rank national_total

*Export outputs
export delimited using "$out/Q5_school_level.csv", replace
save "$out/Q5_school_level.dta", replace

****************************************************

log close

