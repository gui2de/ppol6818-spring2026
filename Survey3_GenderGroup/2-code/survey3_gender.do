****************************************************************
*** Group Assignment: Survey 3 
* Zimu Zhai, Qingya Yang, Peggy Wang, Felicity Loveland-Patterson 
****************************************************************

* *** Set Global Paths — change only this line for your computer ***
global root   "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-survey3"
global data   "$root\4-dataset"
global output "$root\3-output"

****************************************************************
*** Part 1: Generate Simulated Dataset
****************************************************************
clear all
set seed 12345

capture mkdir "$data"

set obs 200

* Identifiers & Treatment
gen couple_id = _n
gen treatment_arm = mod(_n, 4) + 1
* 1 = Control, 2 = Father Quota, 3 = Training, 4 = Both

* Demographics 
gen household_income = rnormal(80000, 20000)
replace household_income = max(household_income, 20000)  // no negative income

gen infant_age_weeks = round(runiform(0, 12))

* Labor Market 
gen wage_father = rnormal(30, 8)
replace wage_father = max(wage_father, 10)

gen wage_mother = rnormal(24, 7)
replace wage_mother = max(wage_mother, 10)

gen hours_paid_mother = rnormal(35, 8)
replace hours_paid_mother = max(hours_paid_mother, 0)

gen hours_paid_father = rnormal(45, 8)
replace hours_paid_father = max(hours_paid_father, 0)

* Housework Hours 
gen hw_total_father = rnormal(8, 4)
replace hw_total_father = max(hw_total_father, 0)

gen hw_total_mother = rnormal(18, 5)
replace hw_total_mother = max(hw_total_mother, 0)

* Mechanism Variables 
gen gender_attitude_score = rnormal(50, 10)
replace gender_attitude_score = min(max(gender_attitude_score, 0), 100)
* scale: 0 = most traditional, 100 = most egalitarian

gen perceived_fairness_mother = round(rnormal(3, 1))
replace perceived_fairness_mother = min(max(perceived_fairness_mother, 1), 5)
* scale: 1 = very unfair, 5 = very fair

* Label Variables
label variable couple_id "Unique household identifier"
label variable treatment_arm "1=Control 2=FQ 3=Training 4=Both"
label variable household_income "Annual household income (USD)"
label variable infant_age_weeks "Age of infant in weeks"
label variable wage_father "Father hourly wage (USD)"
label variable wage_mother "Mother hourly wage (USD)"
label variable hours_paid_mother "Mother weekly paid work hours"
label variable hours_paid_father "Father's weekly paid work hours"
label variable hw_total_father "Father total weekly housework hours"
label variable hw_total_mother "Mother total weekly housework hours"
label variable gender_attitude_score "Gender attitude score (0-100)"
label variable perceived_fairness_mother "Perceived fairness (1-5)"

* Save 
save "$data\baseline_simulated.dta", replace

****************************************************************
*** Part 2: HFC Check: Infant Age & Paternity Leave Eligibility
*   Check 1 - infant_age_weeks out of plausible biological range (0-52 weeks)
*   Check 2 - treatment_arm = 2 or 4 but infant_age_weeks > 12 
*             (paternity leave window already closed)
****************************************************************

clear all
set more off

use "$data\baseline_simulated_witherrors.dta", clear

* Define thresholds 
local min_age       = 0
local max_age       = 52   
local max_paternity = 12    //paternity leave must be taken within 12 weeks

* Generate flag variables 

** Flag 1: infant age out of plausible range
gen flag_range = 0
replace flag_range = 1 if infant_age_weeks < `min_age' | ///
                          infant_age_weeks > `max_age'
label var flag_range "Flag: infant_age_weeks out of range (0-52)"

** Flag 2: paternity leave logic inconsistency
gen flag_logic = 0
replace flag_logic = 1 if (treatment_arm == 2 | treatment_arm == 4) & ///
                           infant_age_weeks > `max_paternity'
label var flag_logic "Flag: paternity arm but infant_age_weeks > 12"

** Combined flag
gen flagged = (flag_range == 1 | flag_logic == 1)
label var flagged "Any flag triggered"


*  List flagged observations
di " FLAG 1: infant_age_weeks out of plausible range (0-52 weeks)"
list couple_id treatment_arm infant_age_weeks if flag_range == 1, ///
    noobs sep(0) abbrev(20)

di " FLAG 2: Paternity arm (2 or 4) but infant_age_weeks > 12 "
list couple_id treatment_arm infant_age_weeks if flag_logic == 1, ///
    noobs sep(0) abbrev(20)

* Export flagged observations to Excel 

** Sheet 1: Flag 1 — range errors
preserve
keep if flag_range == 1
gen flag_reason = "infant_age_weeks out of plausible range (0-52 weeks)"
keep couple_id treatment_arm infant_age_weeks wage_father wage_mother flag_reason
export excel using "$output\part2_InfantAge_Output.xlsx", ///
    sheet("Flag1_AgeOutOfRange") sheetreplace firstrow(variables)
restore

** Sheet 2: Flag 2 — logic inconsistency
preserve
keep if flag_logic == 1
gen flag_reason = "treatment_arm=2 or 4 but infant_age_weeks > 12"
keep couple_id treatment_arm infant_age_weeks wage_father wage_mother flag_reason
export excel using "$output\part2_InfantAge_Output.xlsx", ///
    sheet("Flag2_LogicInconsistency") sheetreplace firstrow(variables)
restore

** Sheet 3: All flagged
preserve
keep if flagged == 1
gen flag_reason = ""
replace flag_reason = "Age out of range" if flag_range == 1
replace flag_reason = "Paternity logic error" if flag_logic == 1
replace flag_reason = "Both flags" if flag_range == 1 & flag_logic== 1
keep couple_id treatment_arm infant_age_weeks wage_father wage_mother flag_reason
export excel using "$output\part2_InfantAge_Output.xlsx", ///
    sheet("All_Flagged") sheetreplace firstrow(variables)
restore

** Sheet 4: Full dataset with flags
export excel using "$output\part2_InfantAge_Output.xlsx", ///
    sheet("Full_Data_with_Flags") sheetreplace firstrow(variables)

****************************************************************
*** Part 3: HFC Check: Housework and Paid Work Hours 
*   Check 1 - hours_paid_father & hours_paid_mother must be <= 112 & > 0
*   Check 2 - hw_total_father & hw_total_mother must be <= 112 & > 0
*   Check 3 - hours_paid_father + hw_total_father must be <= 112 & > 0, and hours_paid_mother + hw_total_mother must be <= 112 & > 0
* (112 hours is one week - 8 hours a night for sleep, 168-7*8=112)
****************************************************************

gen flag_workhours = 0
replace flag_workhours = 1 if hours_paid_father < 0 | hours_paid_father >= 112 | hours_paid_mother < 0 | hours_paid_mother >= 112
** No changes made **

gen flag_hw_hours = 0
replace flag_hw_hours = 1 if hw_total_father < 0 | hw_total_father >= 112 | hw_total_mother < 0 | hw_total_mother >= 112
** No changes made **

gen flag_combined_hours = 0 
replace flag_combined_hours = 1 if hours_paid_father + hw_total_father < 0 | hours_paid_father + hw_total_father >= 112 | hours_paid_mother + hw_total_mother < 0 | hours_paid_mother + hw_total_mother >= 112
** No changes made **

****************************************************************
*** Part 4: HFC Check: Duplicate Couple IDs &  Invalid Treatment Arm Codes 
****************************************************************

use "$data\baseline_simulated_witherrors.dta", clear

replace couple_id     = 3 in 6
replace treatment_arm = 5 in 11
replace treatment_arm = 0 in 16

save "$data\baseline_simulated_witherrors.dta", replace

* SUB-CHECK A — Duplicate couple_id

di _newline
di "──────────────────────────────────────────────"
di "  SUB-CHECK A: Duplicate couple_id"
di "──────────────────────────────────────────────"

duplicates tag couple_id, generate(dup_flag)

* Count and report
quietly count if dup_flag > 0
local n_dups = r(N)

if `n_dups' == 0 {
    di as text "  [OK] All couple_id values are unique. No duplicates detected."
}
else {
    di as error "  [CRITICAL] `n_dups' rows share a non-unique couple_id:"
    list couple_id treatment_arm dup_flag if dup_flag > 0, ///
        separator(0) abbreviate(20)

    preserve
        keep if dup_flag > 0
        keep couple_id treatment_arm dup_flag
        gen issue = "Duplicate couple_id"
        export excel using "$output\part4_duplicate.xlsx", ///
            firstrow(variables) replace
        di as result "  >> Exported to part4_duplicate.xlsx"
    restore
}

*SUB-CHECK B — Invalid treatment_arm

di _newline
di "──────────────────────────────────────────────"
di "  SUB-CHECK B: Invalid treatment_arm"
di "──────────────────────────────────────────────"

gen arm_invalid = !inlist(treatment_arm, 1, 2, 3, 4)
label variable arm_invalid "=1 if treatment_arm not in {1,2,3,4}"

quietly count if arm_invalid == 1
local n_invalid = r(N)

if `n_invalid' == 0 {
    di as text "  [OK] All treatment_arm values are valid (1–4)."
}
else {
    di as error "  [CRITICAL] `n_invalid' rows have an invalid treatment_arm:"
    list couple_id treatment_arm if arm_invalid == 1, ///
        separator(0) abbreviate(20)

    preserve
        keep if arm_invalid == 1
        keep couple_id treatment_arm
        gen issue = "Invalid treatment_arm (not in {1,2,3,4})"
        export excel using "$output\part4_invalid_arm.xlsx", ///
            firstrow(variables) replace
        di as result "  >> Exported to part4_invalid_arm.xlsx"
    restore
}


*COMBINED FLAGGED EXPORT

di _newline
di "──────────────────────────────────────────────"
di "  COMBINED FLAG EXPORT"
di "──────────────────────────────────────────────"

gen flag_part4 = (dup_flag > 0) | (arm_invalid == 1)
label variable flag_part4 "=1 if flagged by Part 4 (any sub-check)"

quietly count if flag_part4 == 1
local n_total_flags = r(N)

di as result "  TOTAL FLAGGED RECORDS: `n_total_flags'"

if `n_total_flags' > 0 {

    gen issue_part4 = ""
    replace issue_part4 = "Duplicate couple_id"             if dup_flag > 0 & arm_invalid == 0
    replace issue_part4 = "Invalid treatment_arm"           if dup_flag == 0 & arm_invalid == 1
    replace issue_part4 = "Duplicate couple_id + Invalid arm" if dup_flag > 0 & arm_invalid == 1

    preserve
        keep if flag_part4 == 1
        keep couple_id treatment_arm dup_flag arm_invalid issue_part4
        sort couple_id
        export excel using "$output\part4_flagged_all.xlsx", ///
            firstrow(variables) replace
        di as result "  >> All flags exported to part4_flagged_all.xlsx"
    restore
}
else {
    di as text "  [OK] No flags — no export needed."
}

*TREATMENT ARM DISTRIBUTION BAR CHART

di _newline
di "──────────────────────────────────────────────"
di "  GENERATING BAR CHART (corrected colors)"
di "──────────────────────────────────────────────"

preserve

    contract treatment_arm, freq(_freq)
    sort treatment_arm

    gen arm_num = treatment_arm

    gen freq_valid   = _freq if inlist(treatment_arm, 1, 2, 3, 4)
    gen freq_invalid = _freq if inlist(treatment_arm, 0, 5)

    * 0="Invalid (0)", 1="Control (T1)", 2="Father Quota (T2)",
    * 3="Training (T3)", 4="Both (T4)", 5="Invalid (5)"

    twoway ///
        (bar freq_valid   arm_num, ///
            color("31 73 125") barwidth(0.7) lcolor(white) lwidth(thin)) ///
        (bar freq_invalid arm_num, ///
            color("192 0 0")   barwidth(0.7) lcolor(white) lwidth(thin)) ///
        , ///
        xlabel( ///
            0 `""Invalid" "(arm=0)""' ///
            1 `""Control" "(T1)""'    ///
            2 `""Father Quota" "(T2)""' ///
            3 `""Training" "(T3)""'   ///
            4 `""Both" "(T4)""'       ///
            5 `""Invalid" "(arm=5)""' ///
            , labsize(small) angle(0) noticks) ///
        ylabel(0(10)60, labsize(small) grid glcolor(gs14) glpattern(dash)) ///
        ytitle("Number of couples", size(medsmall)) ///
        xtitle("") ///
        title("Check 1: treatment_arm Distribution", ///
              size(medium) color(navy) margin(b=3)) ///
        subtitle("Valid arms (1–4) shown in {bf:{&bull} navy}  |  " ///
                 "Invalid arms (0, 5) shown in {bf:{&bull} red}", ///
                 size(small)) ///
        note("N = 200 couples  |  baseline_simulated.dta  |  " ///
             "Injected errors: arm=0 (row 16), arm=5 (row 11)", ///
             size(vsmall)) ///
        legend(off) ///
        graphregion(color(white)) bgcolor(white) ///
        ysize(4) xsize(6.5)

    gen label_y = _freq + 1.2 

    twoway ///
        (bar freq_valid   arm_num, ///
            color("31 73 125") barwidth(0.7) lcolor(white) lwidth(thin)) ///
        (bar freq_invalid arm_num, ///
            color("192 0 0")   barwidth(0.7) lcolor(white) lwidth(thin)) ///
        (scatter label_y arm_num, ///
            msymbol(none) mlabel(_freq) mlabcolor(black) mlabsize(small) ///
            mlabposition(12)) ///
        , ///
        xlabel( ///
            0 `""Invalid" "(arm=0)""' ///
            1 `""Control" "(T1)""'    ///
            2 `""Father Quota" "(T2)""' ///
            3 `""Training" "(T3)""'   ///
            4 `""Both" "(T4)""'       ///
            5 `""Invalid" "(arm=5)""' ///
            , labsize(small) angle(0) noticks) ///
        ylabel(0(10)60, labsize(small) grid glcolor(gs14) glpattern(dash)) ///
        ytitle("Number of couples", size(medsmall)) ///
        xtitle("") ///
        title("Check 1: treatment_arm Distribution", ///
              size(medium) color(navy) margin(b=3)) ///
        subtitle("Valid arms (1–4) in {bf:navy}  |  Invalid arms (0, 5) in {bf:red}", ///
                 size(small)) ///
        note("N = 200 couples  |  baseline_simulated.dta  |  " ///
             "Injected errors: arm=0 (row 16), arm=5 (row 11)", ///
             size(vsmall)) ///
        legend(off) ///
        graphregion(color(white)) bgcolor(white) ///
        ysize(4) xsize(6.5)

    graph export "$output\part4_arm_distribution.png", replace width(1400)
    di as result "  >> Chart saved to part4_arm_distribution.png"

restore

di _newline(2)
di "================================================================"
di "  PART 4 SUMMARY"
di "================================================================"
di "  Sub-check A  Duplicate couple_id      `n_dups' row(s) flagged"
di "  Sub-check B  Invalid treatment_arm    `n_invalid' row(s) flagged"
di "  ─────────────────────────────────────────────────────────────"
di "  TOTAL FLAGS                           `n_total_flags' row(s)"
di "================================================================"
di "  Outputs written to: $output"
di "    part4_duplicate.xlsx"
di "    part4_invalid_arm.xlsx"
di "    part4_flagged_all.xlsx"
di "    part4_arm_distribution.png"
di "================================================================"

drop dup_flag arm_invalid flag_part4
capture drop issue_part4

