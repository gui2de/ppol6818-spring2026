/*==============================================================================
  HFC Assignment — Simulated Data + 4 Quality Checks
  Women's Agricultural Role RCT (Nigeria)

  Checks:
    1. B2b cross-wave change (flag |diff| >= 3)
    2. Internal consistency: women surveyed vs B2b roster
    3. Enumerator-level treatment-control outcome gap
    4. Reference period (interview date) consistency

  Author: Yubing Han | April 2026
==============================================================================*/

clear all
set more off
set seed 20260418

local outdir "/Users/serovia/Downloads"   // <-- change to your path

/*==============================================================================
  PART 1: DATA SIMULATION (DGP)

  Structure:
    135 villages (45 control | 45 T1 | 45 T2)
    20 households per village = 2,700 total households
    10 enumerators, randomly assigned at village level

  Key variables:
    b2b_bl / b2b_el   adult women in HH at baseline / endline
    n_women_surv      additional women actually surveyed (endline)
    female_agri       binary LFPR outcome
    interview_date    date interview was conducted
    duration          survey duration in minutes

  Embedded errors (one cluster per check):
    Check 1 — enum 3 and village 15 have large B2b jumps
    Check 2 — enum 7 and enum 5 skip follow-up modules
    Check 3 — enum 9 has an anomalously large T-C gap
    Check 4 — enum 2 interviewed off-season (June–July)
==============================================================================*/

* ---- Village-level frame ----
clear
set obs 135
gen village_id = _n
gen arm   = 0
replace arm = 1 if village_id > 45  & village_id <= 90
replace arm = 2 if village_id > 90
gen treat1 = (arm == 1)
gen treat2 = (arm == 2)

* Random enumerator assignment (so each enum covers multiple arms)
gen enum_id = ceil(runiform() * 10)

* Village random effect (ICC = 0.228, p = 0.328)
gen u_v = rnormal(0, sqrt(0.228 * 0.328 * 0.672))

* ---- Expand to household level ----
expand 20
bysort village_id: gen hh_num = _n
gen hhid = (village_id - 1) * 20 + hh_num

* ---- B2b: adult women in household ----
gen b2b_bl = 2 + floor(runiform() * 3)     // baseline: mostly 2–4
replace b2b_bl = 1 if runiform() < 0.15    // 15% of HHs have only 1 woman
gen b2b_el = b2b_bl + round(rnormal(0, 0.4))  // small natural change
replace b2b_el = max(b2b_el, 1)

* Embed Check 1 errors: large jumps clustered by enumerator and village
replace b2b_el = b2b_bl + 4 if enum_id == 3  & hh_num <= 6
replace b2b_el = b2b_bl - 3 if village_id == 15 & hh_num <= 4
replace b2b_el = max(b2b_el, 1)

* ---- Women surveyed at endline ----
* Expected: b2b_el - 1  (primary respondent already captured)
gen n_women_surv = b2b_el - 1
replace n_women_surv = max(n_women_surv, 0)

* Embed Check 2 errors: enumerators skipping follow-up modules
replace n_women_surv = 0               if enum_id == 7 & b2b_el >= 3 & hh_num <= 10
replace n_women_surv = n_women_surv - 1 if enum_id == 5 & b2b_el >= 4 & hh_num <= 5
replace n_women_surv = max(n_women_surv, 0)

* ---- Female LFPR (binary outcome) ----
gen p_i = 0.328 + 0.10*treat1 + 0.15*treat2 + u_v
replace p_i = min(max(p_i, 0.01), 0.99)
gen female_agri = rbinomial(1, p_i)

* Embed Check 3 error: enum 9 has anomalously large T-C gap
replace female_agri = 1 if enum_id == 9 & arm == 1
replace female_agri = 0 if enum_id == 9 & arm == 0

* ---- Interview date ----
* Valid post-harvest window: October–December 2026
gen interview_date = mdy(10,1,2026) + floor(runiform() * 91)
format interview_date %td

* Embed Check 4 errors: enum 2 interviewed during growing season
replace interview_date = mdy(6,1,2026) + floor(runiform()*61) if enum_id == 2

* A few random stray interviews outside the window
gen _tmp = runiform() < 0.015
replace interview_date = mdy(3,1,2026) + floor(runiform()*30) if _tmp & enum_id != 2
drop _tmp

* ---- Survey duration (minutes) ----
gen duration = max(round(rnormal(45, 10)), 15)
replace duration = max(round(rnormal(11, 3)), 5) if enum_id == 4  // suspiciously fast

* ---- Save ----
keep hhid village_id hh_num enum_id arm treat1 treat2 ///
     b2b_bl b2b_el n_women_surv female_agri interview_date duration
order hhid village_id hh_num enum_id arm treat1 treat2 ///
      b2b_bl b2b_el n_women_surv female_agri interview_date duration

save "`outdir'/hfc_simulated_data.dta", replace
display as result "Simulated dataset saved: 2,700 households, 135 villages, 10 enumerators"


/*==============================================================================
  CHECK 1: B2b Cross-Wave Change
  
  Flag: |b2b_el - b2b_bl| >= 3
  Then check whether flagged households cluster by enumerator or village.
  
  Rationale: A jump of 3+ adult women between waves is implausible as
  natural household change. If flags cluster around one enumerator or
  village, it signals systematic recording error rather than true
  composition change. Errors here corrupt the denominator of female
  LFPR, compressing treatment effects toward zero.
==============================================================================*/

use "`outdir'/hfc_simulated_data.dta", clear

gen b2b_diff    = b2b_el - b2b_bl
gen flag_check1 = (abs(b2b_diff) >= 3)

display as result _newline "============================================================"
display as result "  CHECK 1: B2b Cross-Wave Change (threshold: |diff| >= 3)"
display as result "============================================================"
quietly count if flag_check1
display "Total flagged households: " r(N)

* By enumerator
display _newline "Flag count and rate by enumerator:"
preserve
collapse (sum) n_flag=flag_check1 (count) n_hh=flag_check1, by(enum_id)
gen flag_pct = round(n_flag / n_hh * 100, 0.1)
list enum_id n_hh n_flag flag_pct if n_flag > 0, noobs clean
restore

* By village (top offenders)
display _newline "Villages with 2+ flagged households:"
preserve
collapse (sum) n_flag=flag_check1 (first) enum_id arm, by(village_id)
gsort -n_flag
list village_id enum_id arm n_flag if n_flag >= 2, noobs clean
restore

* Export
preserve
keep if flag_check1 == 1
keep hhid village_id enum_id arm b2b_bl b2b_el b2b_diff
export excel using "`outdir'/check1_b2b_flags.xlsx", firstrow(variables) replace
display as result "Output: check1_b2b_flags.xlsx"
restore


/*==============================================================================
  CHECK 2: Internal Consistency — Women Surveyed vs B2b Roster
  
  Flag: n_women_surv < (b2b_el - 1) for any household with b2b_el > 1
  
  Rationale: If B2b says there are N adult women, the survey should
  capture responses from N-1 additional women beyond the primary
  respondent. A shortfall means the enumerator skipped follow-up
  questions, leaving gaps in the decision-making module — our
  primary outcome — for those women.
==============================================================================*/

use "`outdir'/hfc_simulated_data.dta", clear

gen expected    = b2b_el - 1
gen missing_w   = expected - n_women_surv
gen flag_check2 = (missing_w > 0) & (b2b_el > 1)

display as result _newline "============================================================"
display as result "  CHECK 2: Internal Consistency (women surveyed vs roster)"
display as result "============================================================"
quietly count if flag_check2
display "Total flagged households: " r(N)

display _newline "Flags by enumerator (count and avg women skipped):"
preserve
collapse (sum) n_flag=flag_check2 (mean) avg_missing=missing_w ///
    (count) n_hh=flag_check2, by(enum_id)
gen avg_missing_r = round(avg_missing, 0.01)
list enum_id n_hh n_flag avg_missing_r if n_flag > 0, noobs clean
restore

preserve
keep if flag_check2 == 1
keep hhid village_id enum_id arm b2b_el expected n_women_surv missing_w
export excel using "`outdir'/check2_consistency_flags.xlsx", firstrow(variables) replace
display as result "Output: check2_consistency_flags.xlsx"
restore


/*==============================================================================
  CHECK 3: Enumerator-Level Treatment-Control Gap in Female LFPR
  
  Flag: enumerators whose (T1 mean − Control mean) is > 2 SD from
  the cross-enumerator mean gap.
  
  Rationale: Because treatment is randomly assigned across villages,
  every enumerator should observe a roughly similar T-C difference.
  A large outlier suggests the enumerator's data is systematically
  different — either from fabrication, interviewer bias, or
  differential effort across treatment arms.
==============================================================================*/

use "`outdir'/hfc_simulated_data.dta", clear

* Step 1: village means → enumerator × arm means
collapse (mean) female_agri (first) enum_id arm, by(village_id)
keep if arm == 0 | arm == 1       // T1 vs Control comparison

collapse (mean) female_agri, by(enum_id arm)
reshape wide female_agri, i(enum_id) j(arm)
rename female_agri0 mean_ctrl
rename female_agri1 mean_t1
gen tc_gap = mean_t1 - mean_ctrl
drop if missing(tc_gap)           // drop enumerators with only 1 arm

* Step 2: flag outliers (|z| > 2)
sum tc_gap
local gap_mean = r(mean)
local gap_sd   = r(sd)
local upper    = `gap_mean' + 2 * `gap_sd'
local lower    = `gap_mean' - 2 * `gap_sd'

gen gap_z       = (tc_gap - `gap_mean') / `gap_sd'
gen flag_check3 = (abs(gap_z) > 2)

display as result _newline "============================================================"
display as result "  CHECK 3: Enumerator T-C Gap in Female LFPR"
display as result "============================================================"
display "Cross-enumerator mean gap = " %5.3f `gap_mean'
display "Cross-enumerator SD       = " %5.3f `gap_sd'
display "Flag bounds: [" %5.3f `lower' ", " %5.3f `upper' "]"
display _newline
list enum_id mean_ctrl mean_t1 tc_gap gap_z flag_check3, noobs clean

* Scatter plot
twoway ///
    (scatter tc_gap enum_id if flag_check3 == 0, ///
        msymbol(circle) mcolor(navy) msize(medlarge)) ///
    (scatter tc_gap enum_id if flag_check3 == 1, ///
        msymbol(diamond) mcolor(red) msize(large) ///
        mlabel(enum_id) mlabpos(12) mlabcolor(red)), ///
    yline(`gap_mean', lcolor(gs8) lpattern(dash)) ///
    yline(`upper', lcolor(red) lpattern(dot)) ///
    yline(`lower', lcolor(red) lpattern(dot)) ///
    title("Check 3: Enumerator-Level T-C Gap in Female LFPR") ///
    xtitle("Enumerator ID") ytitle("Mean LFPR: T1 minus Control") ///
    legend(order(1 "Normal" 2 "Flagged (|z| > 2)")) ///
    note("Dashed = cross-enum mean  |  Dotted = +/- 2 SD bounds")

graph export "`outdir'/check3_enumerator_gap.png", replace width(1200)
export excel using "`outdir'/check3_enumerator_flags.xlsx", firstrow(variables) replace
display as result "Output: check3_enumerator_gap.png + check3_enumerator_flags.xlsx"


/*==============================================================================
  CHECK 4: Reference Period Consistency
  
  Flag: any interview conducted outside October–December 2026
  (the pre-specified post-harvest data collection window)
  
  Rationale: Our before-after comparisons require that "last
  agricultural season" means the same calendar period for every
  household at every wave. Interviews conducted in other months
  capture different seasonal conditions and are not comparable
  to the rest of the panel, which would introduce noise into
  treatment effect estimates.
==============================================================================*/

use "`outdir'/hfc_simulated_data.dta", clear

gen imonth      = month(interview_date)
gen iyear       = year(interview_date)
gen flag_check4 = (imonth < 10 | imonth > 12 | iyear != 2026)

display as result _newline "============================================================"
display as result "  CHECK 4: Reference Period Consistency"
display as result "  Valid window: October–December 2026"
display as result "============================================================"
quietly count if flag_check4
display "Total flagged interviews: " r(N)

display _newline "Flags by enumerator:"
preserve
collapse (sum) n_flag=flag_check4 (count) n_hh=flag_check4, by(enum_id)
list enum_id n_hh n_flag if n_flag > 0, noobs clean
restore

display _newline "Month distribution of flagged interviews:"
tab imonth if flag_check4

* Timeline scatter: interview dates by enumerator
twoway ///
    (scatter interview_date enum_id if flag_check4 == 0, ///
        msymbol(circle) mcolor(navy%40) msize(small)) ///
    (scatter interview_date enum_id if flag_check4 == 1, ///
        msymbol(diamond) mcolor(red) msize(medium)), ///
    yline(`=mdy(10,1,2026)', lcolor(green) lpattern(dash)) ///
    yline(`=mdy(12,31,2026)', lcolor(green) lpattern(dash)) ///
    title("Check 4: Interview Dates by Enumerator") ///
    xtitle("Enumerator ID") ytitle("Interview Date") ///
    legend(order(1 "In-window (Oct–Dec 2026)" 2 "Out-of-window (flagged)")) ///
    note("Green lines = valid collection window: Oct 1 – Dec 31, 2026")

graph export "`outdir'/check4_dates.png", replace width(1200)

preserve
keep if flag_check4 == 1
keep hhid village_id enum_id interview_date imonth iyear
export excel using "`outdir'/check4_date_flags.xlsx", firstrow(variables) replace
display as result "Output: check4_dates.png + check4_date_flags.xlsx"
restore


display as result _newline "============================================================"
display as result "  ALL 4 CHECKS COMPLETE"
display as result "  Outputs saved to: `outdir'"
display as result "    hfc_simulated_data.dta"
display as result "    check1_b2b_flags.xlsx"
display as result "    check2_consistency_flags.xlsx"
display as result "    check3_enumerator_flags.xlsx"
display as result "    check3_enumerator_gap.png"
display as result "    check4_date_flags.xlsx"
display as result "    check4_dates.png"
display as result "============================================================"
