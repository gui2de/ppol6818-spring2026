********************************************************************************
* CHECK 3: Automated Matomo Data Cleaning & Descriptive Statistics Workflow
* HFC Assignment | PPOL 6818
* Authors: Anurita Srivastava, Aqsa Zaidi, Harold Shi, Naomi Yang
*
* Issue: Matomo CSVs are wide-format with hundreds of actionDetails column
* blocks. Exports from different date ranges have different column counts,
* making a naive append fail. ~60% of sessions have no userId (anonymous),
* and shared devices mean visitorId does not always uniquely identify a teacher.
*
* This workflow:
*  1. Imports both CSV exports robustly (handles UTF-16LE, variable column counts)
*  2. Renames v* columns using label-based regex (builds on 20260210_Cleaning_Aqsa.do)
*  3. Drops irrelevant variables
*  4. Appends both exports (force = handles differing column sets)
*  5. Cleans session-level variables (dates, userId, visitorType)
*  6. Identifies module completion events via URL pattern matching
*  7. Collapses to user level
*  8. Outputs descriptive statistics and three charts
*
* Inputs:  (in parent directory, one level up from hfc_assignment/)
*   "Export _  _ December 13, 2025 - January 18, 2026.csv"
*   "Export _  _ July 27 - September 3, 2025.csv"
*
* Outputs:
*   matomo_sessions_clean.dta        — clean session-level dataset (saved in out_dir)
*   matomo_users_clean.dta           — user-level dataset (saved in out_dir)
*   output/check3_top_urls.png
*   output/check3_top_regions.png
*   output/check3_completion_funnel.png
*   output/check3_device_type.png
*   output/check3_monthly_users.png
*   output/check3_hour_of_day.png
*   output/check3_new_vs_returning.png
*   output/check3_session_duration.png
********************************************************************************

set maxvar 32767
clear all

* ============================================================
* USER SETTINGS — adjust these two paths only
* csv_dir : folder containing all monthly Matomo CSV exports
* out_dir : hfc_assignment folder for outputs
* ============================================================
local csv_dir "C:\Users\aqsaz\Documents\Georgetown\Spring 2026\Experimental Design\PAP\hfc_assignment\data"
local out_dir "C:\Users\aqsaz\Documents\Georgetown\Spring 2026\Experimental Design\PAP\hfc_assignment\data"

* Ensure output subfolder exists
capture mkdir `"`out_dir'\output"'

********************************************************************************
* PROGRAM: clean_matomo_csv
* Cleans one Matomo CSV export in memory.
* Call AFTER import delimited.
********************************************************************************

capture program drop clean_matomo_csv
program define clean_matomo_csv

    * -------------------------------------------------------------------------
    * A. RENAME v* COLUMNS via variable label
    * Matomo exports four types of unlabelled v* columns:
    *   time_to_initial_play, pageLoadTimeMilliseconds,
    *   siteSearchCategory, siteSearchKeyword
    * -------------------------------------------------------------------------

    * time_to_initial_play — first block has a named column
    capture rename time_to_initial_playactiondetail ttipactiondetails1

    foreach v of varlist v* {
        local lab : variable label `v'

        if regexm(`"`lab'"', `"^time_to_initial_play \(actionDetails ([0-9]+)\)$"') {
            local ad = regexs(1)
            capture rename `v' ttipactiondetails`ad'
        }
        else if regexm(`"`lab'"', `"^pageLoadTimeMilliseconds \(actionDetails ([0-9]+)\)$"') {
            local ad = regexs(1)
            capture rename `v' pltmsactiondetails`ad'
        }
        else if regexm(`"`lab'"', `"^siteSearchCategory \(actionDetails ([0-9]+)\)$"') {
            local ad = regexs(1)
            capture rename `v' ssearchcatactiondetails`ad'
        }
        else if regexm(`"`lab'"', `"^siteSearchKeyword \(actionDetails ([0-9]+)\)$"') {
            local ad = regexs(1)
            capture rename `v' ssearchkwactiondetails`ad'
        }
    }

    * -------------------------------------------------------------------------
    * B. DROP IRRELEVANT VARIABLES
    * -------------------------------------------------------------------------

    * Visual / icon columns (no analytical value)
    capture drop *icon* *svg*

    * Ecommerce / advertising / campaign (not used by MEWAKA eLMS)
    capture drop visitecommerce* *ecommerce* totalabandoned* ///
                 campaign* adclick* adprovider* sitecurrency*

    * Redundant code-format variables (keep human-readable counterparts)
    capture drop regioncode languagecode operatingsystemcode countrycode ///
                 browsercode continentcode countryflag fingerprint

    * Action-level columns not needed for analysis
    capture drop pageidactiondetails* idpageviewactiondetails* ///
                 timestampactiondetails* plugini* pageviewposition* ///
                 sitesearchcount* ssearchcatactiondetails* ///
                 pltmsactiondetails* ttipactiondetails* ssearchkwactiondetails*

    * Session-level noise
    capture drop goalconversion* sitename sessionreplayurl events ///
                 visitconverted* formconversions idsite

    * -------------------------------------------------------------------------
    * C. STANDARDISE COLUMN TYPES THAT MAY DIFFER ACROSS EXPORTS
    * -------------------------------------------------------------------------

    * actions and interactions may import as string in some exports
    foreach v in actions interactions {
        capture confirm string variable `v'
        if _rc == 0 {
            destring `v', replace force
        }
    }

end

********************************************************************************
* IMPORT AND CLEAN ALL CSVs IN csv_dir (dynamic — works for any number of files)
* Intermediate chunks saved as temp_chunk_#.dta, deleted after appending.
********************************************************************************

* Scan folder for all Matomo export CSVs (filename pattern: Export*.csv)
local files : dir `"`csv_dir'"' files "Export*.csv"
local nfiles : word count `files'

if `nfiles' == 0 {
    di as error "No CSV files matching 'Export*.csv' found in: `csv_dir'"
    exit 111
}

di _n "Found `nfiles' CSV file(s) to process:"
foreach f of local files {
    di "  `f'"
}

* Loop: import, clean, save numbered chunk
local i = 1
foreach f of local files {

    di _n "=== [`i'/`nfiles'] Importing: `f' ==="
    import delimited using `"`csv_dir'\\`f'"', ///
        encoding("UTF-16LE") clear varnames(1) ///
        bindquote(strict) maxquotedrows(unlimited)

    di "  Rows: " _N "   Columns: " c(k)
    clean_matomo_csv

    gen export_file_n = `i'
    gen export_filename = "`f'"

    save `"`out_dir'\\temp_chunk_`i'.dta"', replace
    di "  Cleaned and saved to temp_chunk_`i'.dta"

    local i = `i' + 1
}

********************************************************************************
* APPEND ALL CHUNKS (force tolerates differing column sets across exports)
********************************************************************************

di _n "=== Appending `nfiles' cleaned exports ==="
use `"`out_dir'\\temp_chunk_1.dta"', clear

forvalues j = 2/`nfiles' {
    append using `"`out_dir'\\temp_chunk_`j'.dta"', force
    di "  Appended chunk `j'"
}

* Remove intermediate chunk files
forvalues j = 1/`nfiles' {
    erase `"`out_dir'\\temp_chunk_`j'.dta"'
}
di "Temporary chunk files removed."

di "Combined rows before dedup: " _N

* De-duplicate on session ID (idvisit) in case date ranges overlap
duplicates drop idvisit, force
di "Combined rows after dedup:  " _N

********************************************************************************
* CLEAN SESSION-LEVEL VARIABLES
********************************************************************************

* --- Date ---
* serverdate format: "2025-07-27" (YMD)
capture gen visit_date = date(serverdate, "YMD")
if _rc != 0 {
    * Try alternative format from serverDatePretty if serverdate missing
    gen visit_date = date(serverdatepretty, "DMY") if missing(visit_date)
}
format visit_date %td
drop serverdate

* --- userId: teacher identifier ---
* userId is a phone number (e.g. "0744937555"); empty for anonymous sessions
capture confirm string variable userid
if _rc != 0 tostring userid, replace force

replace userid = strtrim(userid)
replace userid = "" if inlist(userid, "0", ".", "NA", "na", "N/A")
replace userid = "" if length(userid) < 5   // shorter than a valid phone number
gen has_userid = (userid != "" & !missing(userid))
label variable has_userid "Session has linked userId (logged-in teacher)"

* --- Visitor type ---
capture confirm variable visitortype
if _rc == 0 {
    gen new_visitor = (visitortype == "new")
    label variable new_visitor "First-time visitor in this session"
}

* --- Session duration ---
capture confirm variable visitduration
if _rc == 0 {
    label variable visitduration "Session duration (seconds)"
    gen visitduration_min = visitduration / 60
    label variable visitduration_min "Session duration (minutes)"
}

********************************************************************************
* IDENTIFY KEY EVENTS VIA URL PATTERN MATCHING
* eLMS runs at: tcpd.tie.go.tz (Moodle-based)
* Quiz attempt URL:    /mod/quiz/attempt.php
* Quiz summary/review: /mod/quiz/summary.php or /mod/quiz/review.php
* Course page:         /course/view.php
* Login page:          /login/index.php
********************************************************************************

gen quiz_attempt  = 0
gen quiz_complete = 0
gen course_visit  = 0
gen login_hit     = 0

quietly ds urlactiondetails*
local urlvars `r(varlist)'
local n_action_cols : word count `urlvars'
di "URL action-detail columns found: `n_action_cols'"

foreach v of local urlvars {
    replace quiz_attempt  = 1 if regexm(`v', "/mod/quiz/attempt")          & `v' != ""
    replace quiz_complete = 1 if regexm(`v', "/mod/quiz/(summary|review)")  & `v' != ""
    replace course_visit  = 1 if regexm(`v', "/course/view")               & `v' != ""
    replace login_hit     = 1 if regexm(`v', "/login/index")               & `v' != ""
}

* Login-only session: visited login but not any course or module content
gen login_only = (login_hit == 1 & course_visit == 0 & quiz_attempt == 0)

label variable quiz_attempt  "Session included quiz attempt page"
label variable quiz_complete "Session included quiz completion/review page"
label variable course_visit  "Session included a course overview page"
label variable login_only    "Session: login page only, no content accessed"

********************************************************************************
* SAVE CLEAN SESSION-LEVEL DATASET
********************************************************************************

save `"`out_dir'\matomo_sessions_clean.dta"', replace
di _n "Session-level dataset saved: matomo_sessions_clean.dta"
di "Total sessions: " _N
count if has_userid == 1
di "  Logged-in sessions (userId present): " r(N) " (" %4.1f `=r(N)/_N*100' "%)"
count if login_only == 1
di "  Login-only sessions: " r(N)
count if quiz_complete == 1
di "  Sessions with quiz completion: " r(N)

********************************************************************************
* FIGURE 1: Top 15 Most Visited URLs
* Uses session-level data (all sessions, not just logged-in).
* Reshapes wide URL columns to long, strips query strings, counts by path.
********************************************************************************

di _n "=== Generating Figure 1: Top URLs ==="
preserve

    * Keep only session ID and all URL action-detail columns
    keep idvisit urlactiondetails*

    * Reshape to long: one row per session-action
    quietly ds urlactiondetails*
    local urlvars_exist `r(varlist)'
    if "`urlvars_exist'" != "" {

        reshape long urlactiondetails, i(idvisit) j(action_n)
        rename urlactiondetails raw_url

        drop if raw_url == "" | missing(raw_url)

        * Extract URL path: everything after the domain, before ? or #
        gen url_path = regexs(1) if regexm(raw_url, "tie\.go\.tz(/[^?#]*)")
        * Fallback: keep full URL if domain not matched (external/other)
        replace url_path = "(external / other)" if url_path == "" | missing(url_path)

        * Shorten for chart display (max 55 chars)
        gen url_label = url_path
        replace url_label = substr(url_path, 1, 52) + "..." ///
            if length(url_path) > 55

        * Count hits per path
        contract url_label url_path, freq(n_hits)
        gsort -n_hits
        keep in 1/15

        graph hbar (asis) n_hits, ///
            over(url_label, sort(n_hits) descending label(labsize(vsmall))) ///
            bar(1, color(navy%75)) ///
            ytitle("Number of Page Hits") ///
            title("Top 15 Most Visited Pages", size(medium)) ///
            subtitle("All sessions (anonymous + logged-in)") ///
            note("Path extracted from tcpd.tie.go.tz URLs" ///
                 "Source: Matomo exports | PPOL 6818 HFC Assignment")

        graph export `"`out_dir'\output\check3_top_urls.png"', replace width(1400)
        di "Figure 1 saved: output/check3_top_urls.png"
    }
    else {
        di "Warning: No urlactiondetails* columns found — Figure 1 skipped."
    }

restore

********************************************************************************
* FIGURE 2: Top Regions by Number of Sessions
* Uses session-level region variable (human-readable, not regioncode).
* Falls back to city if region is missing or unavailable.
********************************************************************************

di _n "=== Generating Figure 2: Top Regions ==="
preserve

    * Try region first, then city as fallback
    local geo_var ""
    foreach candidate in region city country {
        capture confirm variable `candidate'
        if _rc == 0 {
            quietly count if `candidate' != "" & !missing(`candidate')
            if r(N) > 0 {
                local geo_var `candidate'
                continue, break
            }
        }
    }

    if "`geo_var'" == "" {
        di "Warning: No region/city/country variable found — Figure 2 skipped."
    }
    else {
        di "  Using geographic variable: `geo_var'"

        keep `geo_var'
        drop if `geo_var' == "" | missing(`geo_var')

        contract `geo_var', freq(n_sessions)
        gsort -n_sessions
        keep in 1/15

        * Shorten long region names for display
        gen geo_label = `geo_var'
        replace geo_label = substr(`geo_var', 1, 35) + "..." ///
            if length(`geo_var') > 38

        local gtitle = proper("`geo_var'")
        graph hbar (asis) n_sessions, ///
            over(geo_label, sort(n_sessions) descending label(labsize(small))) ///
            bar(1, color(maroon%75)) ///
            ytitle("Number of Sessions") ///
            title("Top 15 `gtitle's by Session Volume", size(medium)) ///
            subtitle("All sessions (anonymous + logged-in)") ///
            note("Source: Matomo exports | PPOL 6818 HFC Assignment")

        graph export `"`out_dir'\output\check3_top_regions.png"', replace width(1400)
        di "Figure 2 saved: output/check3_top_regions.png"
    }

restore

********************************************************************************
* COLLAPSE TO USER LEVEL (logged-in sessions only)
********************************************************************************

di _n "=== Collapsing to user level ==="
keep if has_userid == 1

bysort userid (visit_date): gen session_seq = _n

collapse ///
    (sum)     quiz_attempt quiz_complete course_visit login_only ///
    (count)   total_sessions = idvisit ///
    (max)     reported_visit_count = visitcount ///
              days_since_first = dayssincefirstvisit ///
              days_since_last  = dayssincelastvisit ///
    (min)     first_seen = visit_date ///
    (mean)    avg_session_dur = visitduration ///
    (firstnm) is_new_visitor = new_visitor ///
    , by(userid)

format first_seen %td

* Engagement indicators
gen ever_completed_quiz  = (quiz_complete >= 1)
gen multi_session        = (total_sessions >= 2)
gen ever_visited_course  = (course_visit >= 1)
gen login_only_user      = (total_sessions == login_only)   // all sessions were login-only

label variable ever_completed_quiz  "Completed at least one quiz/assessment"
label variable multi_session        "Had 2 or more sessions (sustained engagement)"
label variable ever_visited_course  "Visited at least one course overview page"
label variable login_only_user      "All sessions were login-only (never accessed content)"
label variable total_sessions       "Total number of sessions in data"
label variable days_since_first     "Days since first session in data"
label variable days_since_last      "Days since most recent session"
label variable avg_session_dur      "Average session duration (seconds)"

save `"`out_dir'\matomo_users_clean.dta"', replace
di "User-level dataset saved: matomo_users_clean.dta"

********************************************************************************
* DESCRIPTIVE STATISTICS
********************************************************************************

count
local n_users = r(N)
count if ever_completed_quiz == 1
local n_completers = r(N)
count if multi_session == 1
local n_multi = r(N)
count if login_only_user == 1
local n_loginonly = r(N)
count if ever_visited_course == 1 & ever_completed_quiz == 0
local n_course_only = r(N)

di _n "=== CHECK 3: DESCRIPTIVE STATISTICS ==="
di "Unique logged-in users (userId present):  " %6.0f `n_users'
di "  Ever completed a quiz:                  " %6.0f `n_completers' ///
   "  (" %4.1f `=`n_completers'/`n_users'*100' "%)"
di "  Multi-session (>=2 visits):             " %6.0f `n_multi' ///
   "  (" %4.1f `=`n_multi'/`n_users'*100' "%)"
di "  Login-only (never accessed content):    " %6.0f `n_loginonly' ///
   "  (" %4.1f `=`n_loginonly'/`n_users'*100' "%)"
di "  Course access, no quiz completion:      " %6.0f `n_course_only' ///
   "  (" %4.1f `=`n_course_only'/`n_users'*100' "%)"

di _n "Key variable summaries:"
tabstat total_sessions quiz_complete days_since_first days_since_last avg_session_dur, ///
    stat(mean sd p50 p75 p90) columns(statistics) format(%6.1f)

********************************************************************************
* FIGURE 3: Engagement funnel (bar chart)
********************************************************************************

* Build funnel categories (mutually exclusive, ordered)
gen funnel_cat = 4   // default: login only
replace funnel_cat = 3 if ever_visited_course == 1   // accessed course
replace funnel_cat = 2 if quiz_attempt == 1          // started quiz
replace funnel_cat = 1 if ever_completed_quiz == 1   // completed quiz

label define funnel_lbl ///
    1 "Quiz completed" ///
    2 "Quiz attempted (no completion)" ///
    3 "Course accessed (no quiz)" ///
    4 "Login only"
label values funnel_cat funnel_lbl

graph hbar (count) total_sessions, over(funnel_cat, label(labsize(small))) ///
    bar(1, color(navy%80))   bar(2, color(navy%50)) ///
    bar(3, color(navy%30))   bar(4, color(gs12)) ///
    ytitle("Number of Users") ///
    title("eLMS Engagement Funnel", size(medium)) ///
    subtitle("Logged-in users by deepest engagement stage") ///
    note("Source: Matomo exports Jul 2025 – Jan 2026 | PPOL 6818 HFC Assignment")

graph export `"`out_dir'\output\check3_completion_funnel.png"', replace width(1200)
di "Figure 3 saved: output/check3_completion_funnel.png"

* Figures 4–8 reload the session-level dataset (not user-level)
use `"`out_dir'\matomo_sessions_clean.dta"', clear

********************************************************************************
* FIGURE 4: Device Type Breakdown
* Shows share of sessions by device category (mobile / desktop / tablet).
* Directly relevant to Tanzania connectivity: rural teachers often access
* the eLMS via mobile, which constrains module completion behaviour.
********************************************************************************

di _n "=== Generating Figure 4: Device Type Breakdown ==="

capture confirm variable devicetype
if _rc != 0 {
    di "Warning: 'devicetype' not found — Figure 4 skipped."
}
else {
    preserve
        keep devicetype
        drop if devicetype == "" | missing(devicetype)
        contract devicetype, freq(n_sessions)
        egen total = sum(n_sessions)
        gen pct = n_sessions / total * 100
        gsort -n_sessions

        graph hbar (asis) pct, over(devicetype, sort(pct) descending label(labsize(small))) ///
            bar(1, color(navy%75)) ///
            ytitle("Share of Sessions (%)") ///
            title("Sessions by Device Type", size(medium)) ///
            subtitle("All sessions (anonymous + logged-in)") ///
            note("Source: Matomo exports | PPOL 6818 HFC Assignment") ///
            yline(50, lpattern(dash) lcolor(gs10))

        graph export `"`out_dir'\output\check3_device_type.png"', replace width(1200)
        di "Figure 4 saved: output/check3_device_type.png"
    restore
}

********************************************************************************
* FIGURE 5: Monthly Active Users Trend
* Counts unique logged-in users (userId present) per calendar month.
* As monthly exports accumulate this chart shows whether engagement is
* growing, stable, or declining — a real-time baseline for H1 and H2.
********************************************************************************

di _n "=== Generating Figure 5: Monthly Active Users Trend ==="

preserve
    keep if has_userid == 1
    capture confirm variable visit_date
    if _rc != 0 {
        di "Warning: 'visit_date' not found — Figure 5 skipped."
    }
    else {
        * One row per user-month (avoid double-counting repeat visitors)
        gen month = mofd(visit_date)
        format month %tm
        bysort month userid: keep if _n == 1

        collapse (count) n_users = visit_date, by(month)
        sort month

        twoway bar n_users month, ///
            barwidth(0.8) color(navy%75) ///
            xtitle("Month") ytitle("Unique Logged-in Users") ///
            title("Monthly Active Users", size(medium)) ///
            subtitle("Unique userId-linked sessions per calendar month") ///
            note("Source: Matomo exports | PPOL 6818 HFC Assignment") ///
            xlabel(, format(%tmMon-YY) angle(45) labsize(small))

        graph export `"`out_dir'\output\check3_monthly_users.png"', replace width(1200)
        di "Figure 5 saved: output/check3_monthly_users.png"
    }
restore

********************************************************************************
* FIGURE 6: Hour-of-Day Usage Pattern
* Shows when during the day teachers are logging in.
* A spike outside school hours (before 8am, after 4pm) suggests self-directed
* engagement; a spike during school hours may indicate classroom-driven logins.
********************************************************************************

di _n "=== Generating Figure 6: Hour-of-Day Usage ==="

capture confirm variable visitserverhour
if _rc != 0 {
    di "Warning: 'visitserverhour' not found — Figure 6 skipped."
}
else {
    preserve
        keep visitserverhour
        drop if missing(visitserverhour)
        contract visitserverhour, freq(n_sessions)

        graph bar (asis) n_sessions, over(visitserverhour, label(labsize(small))) ///
            bar(1, color(navy%70)) ///
            ytitle("Number of Sessions") ///
            title("Sessions by Hour of Day", size(medium)) ///
            subtitle("Server time (EAT = UTC+3); all sessions" ///
                     "School hours approx. 07:30–15:30 EAT") ///
            note("Source: Matomo exports | PPOL 6818 HFC Assignment")

        graph export `"`out_dir'\output\check3_hour_of_day.png"', replace width(1300)
        di "Figure 6 saved: output/check3_hour_of_day.png"
    restore
}

********************************************************************************
* FIGURE 7: New vs Returning Users by Month
* Stacked bar showing new vs returning visitor share per month.
* A declining new-user share with stable returning share signals retention;
* the inverse (always new) confirms the one-visit drop-off documented in TIE
* admin data (avg time since last login > 1 year).
********************************************************************************

di _n "=== Generating Figure 7: New vs Returning by Month ==="

capture confirm variable visitortype
if _rc != 0 {
    di "Warning: 'visitortype' not found — Figure 7 skipped."
}
else {
    preserve
        capture confirm variable visit_date
        if _rc != 0 {
            di "Warning: 'visit_date' not found — Figure 7 skipped."
        }
        else {
            gen month = mofd(visit_date)
            format month %tm
            drop if visitortype == "" | missing(visitortype)

            contract month visitortype, freq(n_sessions)

            reshape wide n_sessions, i(month) j(visitortype) string
            rename n_sessionsnew     n_new
            rename n_sessionsreturning n_returning
            foreach v in n_new n_returning {
                replace `v' = 0 if missing(`v')
            }
            gen total = n_new + n_returning
            gen pct_new       = n_new / total * 100
            gen pct_returning = n_returning / total * 100
            sort month

            * Convert month to string for legible x-axis labels
            gen month_str = string(month, "%tmMon-YY")

            graph bar (asis) pct_new pct_returning, ///
                over(month_str, label(angle(45) labsize(small))) ///
                stack ///
                bar(1, color(navy%80)) bar(2, color(maroon%60)) ///
                ytitle("Share of Sessions (%)") ///
                title("New vs Returning Users by Month", size(medium)) ///
                subtitle("Stacked: new (navy) + returning (maroon)") ///
                legend(order(1 "New visitor" 2 "Returning visitor") rows(1)) ///
                note("Source: Matomo exports | PPOL 6818 HFC Assignment")

            graph export `"`out_dir'\output\check3_new_vs_returning.png"', replace width(1300)
            di "Figure 7 saved: output/check3_new_vs_returning.png"
        }
    restore
}

********************************************************************************
* FIGURE 8: Session Duration Distribution
* Histogram of time-on-platform per session (minutes, capped at 60).
* Sessions under 1 minute are likely bounces (login then exit);
* longer sessions indicate genuine module engagement.
********************************************************************************

di _n "=== Generating Figure 8: Session Duration Distribution ==="

capture confirm variable visitduration
if _rc != 0 {
    di "Warning: 'visitduration' not found — Figure 8 skipped."
}
else {
    preserve
        keep visitduration
        drop if missing(visitduration)
        gen duration_min = visitduration / 60

        histogram duration_min if duration_min <= 60, ///
            frequency width(2) start(0) ///
            fcolor(navy%70) lcolor(white) ///
            xtitle("Session Duration (minutes)") ///
            ytitle("Number of Sessions") ///
            title("Session Duration Distribution", size(medium)) ///
            subtitle("Sessions up to 60 minutes shown; all sessions included") ///
            xline(1, lpattern(dash) lcolor(orange) lwidth(medium)) ///
            note("Orange line = 1-minute bounce threshold" ///
                 "Source: Matomo exports | PPOL 6818 HFC Assignment")

        graph export `"`out_dir'\output\check3_session_duration.png"', replace width(1200)
        di "Figure 8 saved: output/check3_session_duration.png"
    restore
}

di _n "=== CHECK 3 COMPLETE ==="
