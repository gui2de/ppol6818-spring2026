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

*Q4 input file (OCR-extracted workbook)
global xls21 "$data/q4_Pakistan_district_table21.xlsx"
confirm file "$xls21"

*Start log
capture log close
log using "$out/Q4.log", text replace

****************************************************

*Create empty tempfile to append to with proper skeleton
tempfile table21 one
clear
set obs 0
gen int district_id = .
gen str398 table21 = ""
forvalues k = 2/13 {
    gen double v`k' = .
}
save `table21', replace

*Run loop through all sheets and import
forvalues i = 1/135 {

    import excel "$xls21", sheet("Table `i'") firstrow clear allstring
    di as txt "Now processing sheet: `i'"        // update on load progress
	
****************************************************
    * Post-fix: OCR pattern inside sheet
    *  - Row n has "OVERALL" and the true label/id
    *  - Row n+1 has the actual data but shifted left by 1
    *  - Shift row t+1 right, move label down, then drop row t
****************************************************

    ds TABLE21PAKISTANICITIZEN1, not
    local cols `r(varlist)'

    gen byte __overall  = regexm(upper(TABLE21PAKISTANICITIZEN1), "OVERALL")
    gen byte __shiftrow = (__overall[_n-1] == 1)

    *Move the label/id from the OVERALL row into the shifted row
    replace TABLE21PAKISTANICITIZEN1 = TABLE21PAKISTANICITIZEN1[_n-1] if __shiftrow

    *Shift all other columns one place right on the shifted row
    local n : word count `cols'
    forvalues j = `n'(-1)2 {
        local cur  : word `j' of `cols'
        local prev : word `=`j'-1' of `cols'
        replace `cur' = `prev' if __shiftrow
    }

    *First numeric column becomes blank after shift
    local first : word 1 of `cols'
    replace `first' = "" if __shiftrow

    *Drop the OVERALL row now that its label was moved down
    drop if __overall

    drop __overall __shiftrow

****************************************************
	
	*Keep rows containing "18 AND"
	keep if regexm(upper(TABLE21PAKISTANICITIZEN1), "18 AND")	// scans for rows with "18 AND"

	count
	if r(N)==0 {
		di as error "WARNING: no '18 AND' row in Table `i'"		// flags sheets without identified "18 AND" row without breaking code
		continue
	}

	*Among candidate rows, keep the row with the most numeric-looking cells
	*To avoid accidentally keeping the OVERALL/header row
	ds TABLE21PAKISTANICITIZEN1, not
	local candvars `r(varlist)'

	gen nnums = 0
	foreach x of local candvars {
		gen __tmp = trim(`x')
		replace __tmp = subinstr(__tmp, ",", "", .)
		replace nnums = nnums + regexm(__tmp, "^[0-9]+$") if !missing(__tmp)
		drop __tmp
	}

	gsort -nnums
	keep in 1		// keep the "18 AND" row with most numeric values
	drop nnums

    rename TABLE21PAKISTANICITIZEN1 table21

    *Create id to append to table21
    gen district_id = `i'    // labeling the districts by sheet n

    *Extract columns 2–13

    *Create target numeric variables
    forvalues k = 2/13 {
        gen double v`k' = .      // creating variables v2, v3, ... within loop
    }

*Collect all numeric chunks from the kept row and fill v2-v13
ds table21 district_id v2-v13, not
local datavars `r(varlist)'

local nums ""

foreach x of local datavars {
    local s = trim(`x'[1])
    local s = subinstr("`s'", ",", "", .)
    local s = subinstr("`s'", "%", "", .)

    while regexm("`s'", "([0-9]+)") {
        local chunk = regexs(1)
        local nums "`nums' `chunk'"
        local s = regexr("`s'", "[0-9]+", " ")
    }
}

*Clear and fill v2-v13
forvalues k = 2/13 {
    replace v`k' = .
}

local found = 0
foreach n of local nums {
    local ++found
    if `found' > 12 continue, break
    local idx = `found' + 1
    replace v`idx' = real("`n'") in 1
}

*Count explicit missing markers in the kept row (dash/dot/etc.)
local nmiss = 0
foreach x of local datavars {
    local s2 = upper(trim(`x'[1]))
    if inlist("`s2'", ".", "-", "—", "–", "NA", "N/A") local ++nmiss
}

*Only flag as OCR problem if we cannot account for 12 slots
if (`found' + `nmiss' < 12) {
    di as error "Table `i': `found' numeric + `nmiss' explicit-missing = " ///
        (`found'+`nmiss') " (<12). Likely OCR/alignment problem."
}
else if (`found' != 12) {
    di as txt "Table `i': `found' numeric values; `nmiss' explicit missing markers (OK if missing categories)."
}

if (`found' != 12) di as error "Table `i' extracted `found' numeric values (expected 12)"

****************************************************

    keep district_id table21 v2-v13

    save `one', replace        // saves single row of data in memory to 'one'
    use `table21', clear
    append using `one'         // adds the saved 'one' row onto master table21
    save `table21', replace
}

****************************************************

*Final checks, flags, and outputs

*Load the completed master dataset
use `table21', clear

******************************************************************
* Post-Fix "OVERALL" rows:
*	For any row n with table21 containing "OVERALL":
*    1) Store row n's district_id
*    2) Shift row (n+1) one column to the RIGHT:
*         district_id -> table21
*        table21     -> v2
*        v2          -> v3
*         ...
*         v12         -> v13
*    3) Put stored district_id into district_id of (n+1)
*    4) Drop row n
* Couldn't figure this part out
******************************************************************/

* Identify OVERALL rows and the row below
//gen byte __overall = regexm(upper(table21), "OVERALL")
//gen byte __below   = (__overall[_n-1] == 1)

* Carry district_id from OVERALL row down to the row below
//gen double __did = .
//replace __did = district_id if __overall
//replace __did = __did[_n-1] if __below
//replace district_id = __did if __below & !missing(__did)

* Fix label on the real row
//replace table21 = "18 AND ABOVE" if __below

* Detect misalignment on the below-row:
* if v13 is missing but v12 is not missing, things are shifted left (common pattern)
//gen byte __shift = __below & missing(v13) & !missing(v12)

* Shift NUMERIC columns right by one (v12->v13, ..., v2->v3) and set v2 missing
//replace v13 = v12 if __shift
//forvalues k = 12(-1)3 {
    //replace v`k' = v`=`k'-1' if __shift
//}
//replace v2 = . if __shift

* Drop OVERALL rows
//drop if __overall

* Cleanup
//drop __overall __below __did __shift

******************************************************************

*Confirm number of districts processed
count
di as txt "Total districts in final dataset: " r(N)

*Identify rows with missing extracted values
egen miss = rowmiss(v2-v13)

di as txt "Summary of missing extracted values:"
tab miss

*List districts that did NOT extract all 12 values
di as error "Districts with incomplete extraction"
list district_id table21 miss if miss > 0, clean noobs

*Save flagged districts separately for later review
preserve
keep if miss > 0
save "$out/Q4_table21_flagged_districts.dta", replace
restore

drop miss

*Save final dataset (including flagged districts)
save "$out/Q4_table21_18+.dta", replace
export delimited district_id table21 v2-v13 using "$out/Q4_table21_18+.csv", replace

****************************************************

log close
