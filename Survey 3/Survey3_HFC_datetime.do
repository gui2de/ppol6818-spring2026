clear all
set seed 12345
set obs 500

**DGP

gen child_id = _n
gen enumerator_id = ceil(runiform()*5)

* Simulate survey date (all surveys conducted on the same day: 2024-03-15)
gen survey_date = date("2024-03-15", "YMD")
format survey_date %td

* Simulate start time: random hour between 8am and 4pm (in minutes since midnight)
gen start_minutes = floor(runiform()*(16-8)*60) + 8*60

* Simulate survey duration: between 20 and 60 minutes
gen duration_true = floor(runiform()*40) + 20

* End time = start + duration (clean data)
gen end_minutes = start_minutes + duration_true

**Errors

* Error Type 1: End time BEFORE start time (enumerator swapped the times)
replace end_minutes = start_minutes - floor(runiform()*30 + 5) in 1/10

* Error Type 2: Implausibly short duration (< 5 minutes — survey takes at least 20)
replace end_minutes = start_minutes + floor(runiform()*4 + 1) in 11/20

* Error Type 3: Implausibly long duration (> 180 minutes — likely left device open)
replace end_minutes = start_minutes + floor(runiform()*120 + 181) in 21/25

* Error Type 4: End time crosses midnight (end_minutes > 1440)
replace end_minutes = 1430 + floor(runiform()*60 + 20) in 26/28

**Convert to readable clock times (stored as strings for display)

gen start_hour = floor(start_minutes / 60)
gen start_min  = mod(start_minutes, 60)
gen end_hour   = floor(end_minutes / 60)
gen end_min    = mod(end_minutes, 60)

* Compute observed duration in minutes
gen duration_obs = end_minutes - start_minutes

**HFC: Date and Time Checks

* Flag 1: End time before start time
gen flag_reversed = (end_minutes < start_minutes)

* Flag 2: Duration too short (under 5 minutes)
gen flag_too_short = (duration_obs >= 0 & duration_obs < 5)

* Flag 3: Duration too long (over 180 minutes)
gen flag_too_long = (duration_obs > 180)

* Flag 4: End time past midnight (end_minutes >= 1440)
gen flag_past_midnight = (end_minutes >= 1440)

* Combined flag
gen is_time_error = (flag_reversed == 1 | flag_too_short == 1 | flag_too_long == 1 | flag_past_midnight == 1)

* Error type label
gen error_type = ""
replace error_type = "Reversed"      if flag_reversed == 1
replace error_type = "Too short"     if flag_too_short == 1
replace error_type = "Too long"      if flag_too_long == 1
replace error_type = "Past midnight" if flag_past_midnight == 1

**Summary by enumerator

di ""
di "===== HFC: DATE/TIME CHECK — SUMMARY BY ENUMERATOR ====="
di ""

bysort enumerator_id: egen enum_total  = count(child_id)
bysort enumerator_id: egen enum_errors = total(is_time_error)
gen enum_error_rate = round((enum_errors / enum_total) * 100, 0.1)

preserve
collapse (first) enum_total enum_errors enum_error_rate, by(enumerator_id)
list enumerator_id enum_total enum_errors enum_error_rate, table divider noobs
restore

**Tabular Output: Flagged Records

di ""
di "===== HFC: DATE/TIME CHECK — FLAGGED RECORDS ====="
di ""

list child_id enumerator_id survey_date ///
     start_hour start_min end_hour end_min ///
     duration_obs error_type ///
     if is_time_error == 1, ///
     table divider noobs

**Scatterplot: Start vs End Time

* Label extreme cases (reversed or past midnight)
gen flag_label = string(child_id) if (flag_reversed == 1 | flag_past_midnight == 1)

twoway ///
  (scatter end_minutes start_minutes if is_time_error == 0, ///
      mcolor(blue%30) msize(small)) ///
  (scatter end_minutes start_minutes if is_time_error == 1, ///
      mcolor(red) msize(medium) mlabel(flag_label) mlabsize(vsmall) mlabcolor(red)), ///
  title("HFC Date/Time Check: Start vs. End Time", size(medium)) ///
  subtitle("Nigeria Immunization RCT - Baseline Pilot", size(vsmall)) ///
  xtitle("Start Time (minutes since midnight)") ///
  ytitle("End Time (minutes since midnight)") ///
  xline(480 960, lcolor(gs12) lpattern(dash)) ///
  yline(480 960 1440, lcolor(orange) lpattern(dash)) ///
  legend(order(1 "Valid Records" 2 "Flagged Records") position(6) ring(1) size(vsmall)) ///
  note("Note: Points below the 45-degree line have end time before start time." ///
       "Vertical/horizontal dashed lines mark 8am and 4pm (480 and 960 min)." ///
       "Orange line at 1440 marks midnight.")

* Add 45-degree reference line (end = start, i.e. zero duration)
addplot: (function y = x, range(480 960) lcolor(gs10) lpattern(solid))
