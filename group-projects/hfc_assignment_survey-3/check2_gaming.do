********************************************************************************
* CHECK 2: Post-Report Completion Spike Detection (Gaming / Headteacher Coercion)
* HFC Assignment | PPOL 6818
* Authors: Anurita Srivastava, Aqsa Zaidi, Harold Shi, Naomi Yang
*
* Issue: Headteachers in treated wards (especially T2, which adds a structured
* accountability prompt) may pressure a subset of teachers to complete modules
* immediately after the monthly ward-ranking report is delivered. This would
* inflate the school completion metric without genuine engagement.
*
* This check combines two signals per school per report-delivery week:
*   (1) Z-score of completions relative to a rolling 4-week baseline
*   (2) HHI of completions (concentration among a few teachers)
* Schools with z-score > 2 AND HHI > 0.6 in ≥2 consecutive months
* are flagged as priority for follow-up in the endline coercion module.
*
* Input:  data/sim_matomo_weekly.dta  (simulated; generated below if not found)
* Output: output/check2_gaming_flags.xlsx
*         output/check2_spike_example.png
********************************************************************************

clear all
set seed 20260419

cd "C:\Users\aqsaz\Documents\Georgetown\Spring 2026\Experimental Design\PAP\hfc_assignment"
capture mkdir data
capture mkdir output

********************************************************************************
* SIMULATE DATA
* ~600 schools x 26 weeks; T1/T2 get reports on weeks 4,8,12,16,20,24
* ~10% of T2 schools have injected gaming spikes
********************************************************************************

capture confirm file "data/sim_matomo_weekly.dta"
if _rc != 0 {

    local n_wards   120
    local n_schools   5
    local n_weeks    26
    local total_schools = `n_wards' * `n_schools'   // 600

    * Build school-week panel
    set obs `=`total_schools' * `n_weeks''
    gen school_id = ceil(_n / `n_weeks')
    gen week      = mod(_n - 1, `n_weeks') + 1

    * Assign wards and arms
    gen ward_id = ceil(school_id / `n_schools')
    gen arm_num = mod(ward_id - 1, 3)   // 0=Control, 1=T1, 2=T2
    gen arm = "control"
    replace arm = "T1" if arm_num == 1
    replace arm = "T2" if arm_num == 2
    drop arm_num

    * Report delivery weeks for T1/T2
    gen report_week = 0
    foreach w in 4 8 12 16 20 24 {
        replace report_week = 1 if week == `w' & arm != "control"
    }

    * Baseline completions: low (study baseline ~2%), Poisson-ish
    gen completions          = rpoisson(0.4) if arm == "control"
    replace completions      = rpoisson(0.6) if arm == "T1"
    replace completions      = rpoisson(0.7) if arm == "T2"

    * n_completing_teachers: at most completions, max 15
    gen n_completing_teachers = min(completions, floor(runiform() * 15 + 1))
    replace n_completing_teachers = 0 if completions == 0

    * --- Inject genuine treatment effect (gradual rise for T1/T2 after week 4) ---
    replace completions = completions + round((week - 4) * 0.05) ///
        if arm != "control" & week > 4

    * --- Inject gaming spikes for ~10% of T2 schools ---
    bysort school_id: gen school_tag = _n == 1
    gen gaming_school = (runiform() < 0.10 & arm == "T2") if school_tag == 1
    bysort school_id: replace gaming_school = gaming_school[1]
    drop school_tag

    * Gaming spike: +8 completions on report weeks, concentrated in 2 teachers
    replace completions           = completions + 8 ///
        if gaming_school == 1 & report_week == 1
    replace n_completing_teachers = 2 ///
        if gaming_school == 1 & report_week == 1 & completions > 5

    * Floor at 0
    replace completions           = max(completions, 0)
    replace n_completing_teachers = max(n_completing_teachers, 0)

    save "data/sim_matomo_weekly.dta", replace
    di "Simulated weekly data saved: data/sim_matomo_weekly.dta"
}

********************************************************************************
* LOAD DATA
********************************************************************************

use "data/sim_matomo_weekly.dta", clear

* Restrict to treatment schools only for spike detection
keep if arm != "control"

sort school_id week

********************************************************************************
* STEP 1: BASELINE MEAN AND SD FROM NON-REPORT WEEKS ONLY
* Using non-report weeks avoids prior spikes contaminating the baseline —
* a rolling window that includes a previous gaming spike inflates the mean
* and SD, masking future spikes in the z-score.
********************************************************************************

bysort school_id: egen baseline_mean = mean(completions) if report_week == 0
bysort school_id: egen baseline_sd   = sd(completions)   if report_week == 0

* Propagate to all weeks for the same school (including report weeks)
bysort school_id (baseline_mean): replace baseline_mean = baseline_mean[1] ///
    if missing(baseline_mean)
bysort school_id (baseline_sd): replace baseline_sd = baseline_sd[1] ///
    if missing(baseline_sd)

* Floor SD at 0.5 to avoid division by zero in low-variance schools
replace baseline_sd = 0.5 if baseline_sd < 0.5 | missing(baseline_sd)

********************************************************************************
* STEP 2: Z-SCORE ON REPORT DELIVERY WEEKS
********************************************************************************

gen z_score = (completions - baseline_mean) / baseline_sd if report_week == 1

********************************************************************************
* STEP 3: WITHIN-SCHOOL HHI ON REPORT DELIVERY WEEKS
* HHI = 1 - (n_completing_teachers / completions)
* Approaches 1 when one teacher accounts for all completions (high concentration)
* Approaches 0 when completions spread broadly across teachers
********************************************************************************

gen hhi = .
replace hhi = 1 - (n_completing_teachers / completions) ///
    if report_week == 1 & completions > 0
replace hhi = 0 if report_week == 1 & completions == 0

********************************************************************************
* STEP 4: FLAG SCHOOLS WITH SPIKE + CONCENTRATION IN ≥2 REPORT MONTHS
********************************************************************************

gen flag_spike = (z_score > 2 & hhi > 0.60 & !missing(z_score) & !missing(hhi))

bysort school_id: gen cumulative_flags = sum(flag_spike)
bysort school_id: gen max_flags        = cumulative_flags[_N]

gen priority_flag = (max_flags >= 2)

label variable flag_spike     "Spike flag: z>2 AND HHI>0.6 on report week"
label variable max_flags      "Total spike flags across all report weeks"
label variable priority_flag  "Priority flag: spiked in >=2 report months"

********************************************************************************
* OUTPUT 1: Excel table of priority-flagged schools
********************************************************************************

preserve
    keep if priority_flag == 1
    keep school_id ward_id arm max_flags
    if _N > 0 {
        duplicates drop school_id, force
        sort ward_id school_id
        count
        di "Priority-flagged schools (>=2 months): " r(N)
        export excel school_id ward_id arm max_flags ///
            using "output/check2_gaming_flags.xlsx", ///
            sheet("Priority Schools") firstrow(variables) replace
        di "Gaming flags exported to output/check2_gaming_flags.xlsx"
    }
    else {
        di "No schools flagged in >=2 months — no Excel output produced."
    }
restore

********************************************************************************
* OUTPUT 2: Time-series chart — example T2 gaming school vs clean school
********************************************************************************

* Pick first gaming school and first clean T2 school for illustration
quietly levelsof school_id if gaming_school == 1 & arm == "T2", local(gaming_ids)
local eg_gaming : word 1 of `gaming_ids'

quietly levelsof school_id if gaming_school == 0 & arm == "T2", local(clean_ids)
local eg_clean : word 1 of `clean_ids'

twoway ///
    (line completions week if school_id == `eg_gaming', ///
        lcolor(maroon) lwidth(medium)) ///
    (line completions week if school_id == `eg_clean', ///
        lcolor(navy) lwidth(medium) lpattern(dash)) ///
    (scatter completions week if school_id == `eg_gaming' & flag_spike == 1, ///
        msymbol(X) mcolor(red) msize(large)), ///
    xline(4 8 12 16 20 24, lpattern(dot) lcolor(gray%60)) ///
    title("Check 2: Gaming Detection Example", size(medium)) ///
    subtitle("Red X = flagged spike (z>2, HHI>0.6)  |  Dotted lines = report delivery weeks") ///
    xtitle("Study Week") ytitle("Module Completions") ///
    legend(order(1 "Gaming school" 2 "Clean school" 3 "Flagged spike week") ///
           rows(3) size(small)) ///
    note("Simulated data | PPOL 6818 HFC Assignment")

graph export "output/check2_spike_example.png", replace width(1400)
di "Time-series chart saved to output/check2_spike_example.png"

********************************************************************************
* SUMMARY STATS
********************************************************************************

di ""
di "=== CHECK 2 SUMMARY ==="
quietly count if arm != "control"
local n_treat = r(N) / 26   // rough school count (26 weeks)
quietly count if priority_flag == 1
local n_priority = r(N) / 26
di "Treatment schools:        " %4.0f `n_treat'
di "Priority-flagged (>=2mo): " %4.0f `n_priority' " (" %4.1f `=`n_priority'/`n_treat'*100' "%)"
