
global excel_t21 "/Users/anu/Downloads/q4_Pakistan_district_table21.xlsx"

clear

*setting up an empty tempfile
tempfile table21
clear
save `table21', emptyok replace

forvalues i = 1/135 {
    display "Processing Table `i' ..."

    * Import sheet as all string, no first row
    import excel "$excel_t21", sheet("Table `i'") clear allstring

    * Get all variable names
    ds
    local varlist "`r(varlist)'"

    * Skip if sheet is empty
    if "`varlist'" == "" {
        display "Sheet `i' is empty. Skipping."
        continue
    }

    * First column in this sheet
    local firstcol : word 1 of `varlist'

    * Keep rows containing "18 AND"
    capture keep if regexm(`firstcol', "18 AND")

    * Skip if no matching row
    if _N == 0 {
        display "Sheet `i' has no '18 AND' row. Skipping."
        continue
    }

    * Keep only first matching row
    keep in 1

    * Keep columns 2–13 (or as many exist)
    local varcount : word count `varlist'
    local keepvars ""
    forvalues j = 2/`=min(13, `varcount')' {
        local keepvars "`keepvars' `: word `j' of `varlist''"
    }
    keep `keepvars'

    * Rename columns dynamically
    local j = 2
    foreach var of varlist * {
        rename `var' col`j'
        local ++j
    }

    * Add district identifier
    gen district = `i'

    * Append to master dataset
    append using `table21'
    save `table21', replace
}

* Load final dataset
use `table21', clear
order district col2-col13

display "All done! Dataset ready."
