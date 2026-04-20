********************************************************************************
* CHECK 1: Teacher Registration Integrity
* HFC Assignment | PPOL 6818
* Authors: Anurita Srivastava, Aqsa Zaidi, Harold Shi, Naomi Yang
*
* Issue: Duplicate/misassigned teacher registrations corrupt the school-level
* completion rate denominator and the composite resource index used for
* stratification. This check flags: (1) duplicate phone numbers within a
* school, (2) teachers appearing in >1 school, and (3) large discrepancies
* between Matomo teacher counts and TIE admin teacher counts per school.
*
* Input:  data/sim_roster.dta  (simulated; generated below if not found)
* Output: output/check1_flagged_schools.xlsx
*         output/check1_flag_rate.png
********************************************************************************

clear all
set seed 20260419

* Set working directory to this file's folder
cd "C:\Users\aqsaz\Documents\Georgetown\Spring 2026\Experimental Design\PAP\hfc_assignment"
capture mkdir data
capture mkdir output

********************************************************************************
* SIMULATE DATA (run this block once to create sim_roster.dta)
* Skip if data/sim_roster.dta already exists.
********************************************************************************

capture confirm file "data/sim_roster.dta"
if _rc != 0 {

    * --- Parameters ---
    local n_wards   20
    local n_schools  5   // schools per ward
    local n_teachers 15  // teachers per school (registered on eLMS)

    local total_schools  = `n_wards' * `n_schools'         // 100
    local total_teachers = `total_schools' * `n_teachers'  // 1,500

    * --- Base roster ---
    set obs `total_teachers'

    gen school_id = ceil(_n / `n_teachers')
    gen ward_id   = ceil(school_id / `n_schools')
    gen teacher_id = _n

    * Simulate phone numbers (9-digit Tanzania numbers: 07XXXXXXXX)
    gen long phone_num = 700000000 + floor(runiform() * 100000000)
    tostring phone_num, gen(phone) format("%10.0f")
    replace phone = "0" + substr(phone, 2, .)  // ensure leading 0

    * TIE admin count per school (ground truth)
    gen tie_count = `n_teachers'

    * --- Introduce duplicates (~5% of teachers: same phone, new teacher_id) ---
    gen dup_flag = (runiform() < 0.05)
    local dup_source = floor(`total_teachers' * 0.05)
    forvalues i = 1/`dup_source' {
        local orig = floor(runiform() * `total_teachers') + 1
        qui replace phone = phone[`orig'] if dup_flag == 1 & _n == `i'
    }

    * --- Introduce cross-school teachers (~3%: teacher_id appears in 2 schools) ---
    gen cross_flag = (runiform() < 0.03)
    local n_cross = floor(`total_teachers' * 0.03)
    gen school_id_orig = school_id
    forvalues i = 1/`n_cross' {
        local new_school = floor(runiform() * `total_schools') + 1
        qui replace school_id = `new_school' if cross_flag == 1 & _n == `i'
    }

    * --- Introduce Matomo count mismatches (~10% of schools) ---
    * Matomo count will be derived from data; simulate by inflating some records
    gen matomo_inflate = (runiform() < 0.10) & !dup_flag
    * Add ghost teachers (inflate Matomo count for these schools)
    expand 2 if matomo_inflate, gen(ghost)
    replace teacher_id = teacher_id + `total_teachers' if ghost == 1
    replace dup_flag   = 0 if ghost == 1
    replace cross_flag = 0 if ghost == 1

    sort school_id teacher_id
    save "data/sim_roster.dta", replace
    di "Simulated roster saved: data/sim_roster.dta"
}

********************************************************************************
* CHECK 1A: Duplicate phone numbers within a school
********************************************************************************

use "data/sim_roster.dta", clear

* Flag: same phone appears >1 time within a school
duplicates tag phone school_id, gen(dup_phone_raw)
gen flag_dup_phone = (dup_phone_raw > 0)

********************************************************************************
* CHECK 1B: Teachers appearing in more than one school
********************************************************************************

* Count how many distinct schools each teacher_id appears in
bysort teacher_id: gen n_schools_per_teacher = _N
gen flag_cross_school = (n_schools_per_teacher > 1)

********************************************************************************
* CHECK 1C: Matomo count vs TIE admin count per school
********************************************************************************

* Matomo count = observed rows per school in this roster
bysort school_id: gen matomo_count = _N

* Compute mismatch ratio (use tie_count from data)
gen count_ratio = matomo_count / tie_count
gen flag_count_mismatch = (count_ratio > 1.20 | count_ratio < 0.80)
* i.e. >20% divergence in either direction

********************************************************************************
* COLLAPSE TO SCHOOL LEVEL
********************************************************************************

collapse (max)   flag_dup_phone flag_cross_school flag_count_mismatch ///
         (mean)  count_ratio ///
         (first) ward_id tie_count matomo_count, by(school_id)

gen any_flag = (flag_dup_phone == 1 | flag_cross_school == 1 | flag_count_mismatch == 1)

label variable flag_dup_phone       "Flag: duplicate phone within school"
label variable flag_cross_school    "Flag: teacher linked to >1 school"
label variable flag_count_mismatch  "Flag: Matomo/TIE count diverges >20%"
label variable count_ratio          "Matomo count / TIE admin count"
label variable any_flag             "Any flag raised"

********************************************************************************
* OUTPUT 1: Excel flag table
********************************************************************************

export excel school_id ward_id tie_count matomo_count count_ratio ///
    flag_dup_phone flag_cross_school flag_count_mismatch any_flag ///
    using "output/check1_flagged_schools.xlsx", ///
    sheet("Flagged Schools") firstrow(variables) replace

di "Flagged schools exported to output/check1_flagged_schools.xlsx"
di "Total schools with any flag: " %3.0f `=_N' " schools reviewed"
count if any_flag == 1
di "  of which " r(N) " flagged (" %4.1f `=r(N)/_N*100' "%)"

********************************************************************************
* OUTPUT 2: Bar chart — flag rate by ward
********************************************************************************

collapse (mean) any_flag (sum) n_flagged = any_flag (count) n_schools = school_id, ///
    by(ward_id)

rename any_flag ward_flag_rate

graph bar ward_flag_rate, over(ward_id, label(angle(45) labsize(vsmall))) ///
    ytitle("Share of Schools Flagged") ///
    title("Check 1: Registration Integrity Flag Rate by Ward", size(medium)) ///
    note("Flags: duplicate phone, cross-school teacher, Matomo/TIE count mismatch (>20%)" ///
         "Simulated data | PPOL 6818 HFC Assignment") ///
    yline(0.10, lpattern(dash) lcolor(orange)) ///
    bar(1, color(navy%70))

graph export "output/check1_flag_rate.png", replace width(1200)
di "Bar chart saved to output/check1_flag_rate.png"
