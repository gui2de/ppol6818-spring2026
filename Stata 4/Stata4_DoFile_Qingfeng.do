cd "C:\Users\余青锋\OneDrive\Experimental Design\Stata 4"

* ============================================================
* PPOL6818 Assignment 08 — Part 1: Fuzzy Matching
* Tanzania Ward Boundary Changes, 2010–2015
* ============================================================

clear all
set more off

* ────────────────────────────────────────────────────────────
*  Step 1 — Name-based merge to identify common, parentless
*           and orphan wards  (Q1–Q3)
*
*  Matching strategy: standardize region and ward names to
*  lowercase, then concatenate as a composite key. District
*  names are excluded because some district boundaries were
*  redrawn between 2010 and 2015.
* ────────────────────────────────────────────────────────────

* ---- Prepare the 2015 ward list ----
use "Tz_elec_15_clean.dta", clear

gen region_lc = lower(strtrim(region_15))
gen ward_lc   = lower(strtrim(ward_15))
gen match_key = region_lc + "_" + ward_lc        // composite key

tempfile wards_2015
save `wards_2015'

* ---- Prepare the 2010 ward list ----
use "Tz_elec_10_clean.dta", clear

gen region_lc = lower(strtrim(region_10))
gen ward_lc   = lower(strtrim(ward_10))
gen match_key = region_lc + "_" + ward_lc

tempfile wards_2010
save `wards_2010'

* ---- Merge: 2015 as master, 2010 as using ----
use `wards_2015', clear
merge m:m match_key using `wards_2010'

tab _merge

* Q1: Wards present in both years (_merge == 3)
preserve
    keep if _merge == 3
    bysort ward_id_15: keep if _n == 1          // unique 2015 wards
    count
    di as result "Q1 — Wards existing in both 2010 and 2015: " r(N)
restore

* Q2: Parentless wards — in 2015 only (_merge == 1)
preserve
    keep if _merge == 1
    bysort ward_id_15: keep if _n == 1
    count
    di as result "Q2 — Parentless wards (2015 only): " r(N)
restore

* Q3: Orphan wards — in 2010 only (_merge == 2)
preserve
    keep if _merge == 2
    bysort ward_id_10: keep if _n == 1
    count
    di as result "Q3 — Orphan wards (2010 only): " r(N)
restore


* ────────────────────────────────────────────────────────────
*  Step 2 — GIS-based ward division analysis  (Q4–Q5)
*
*  The intersection dataset records the spatial overlap
*  between 2012 (≈ 2010) parent wards and 2017 (≈ 2015)
*  child wards. For each parent we count the number of
*  distinct children it maps to.
* ────────────────────────────────────────────────────────────

use "Tz_GIS_2015_2010_intersection.dta", clear

* Build unique identifiers for parent (2012) and child (2017) wards
gen str parent_id = region_gis_2012 + "_" + district_gis_2012 + "_" + ward_gis_2012
gen str child_id  = region_gis_2017 + "_" + district_gis_2017 + "_" + ward_gis_2017

* Deduplicate parent–child pairs
bysort parent_id child_id: keep if _n == 1

* Count how many child wards each parent maps to
bysort parent_id: gen num_children = _N

* Collapse to one observation per parent ward
bysort parent_id: keep if _n == 1

* Q4: Parents that split into exactly 2 children
count if num_children == 2
di as result "Q4 — Wards divided into exactly 2: " r(N)

* Q5: Parents that split into 3 or more children
count if num_children >= 3
di as result "Q5 — Wards divided into 3+: " r(N)

* Distribution of splits
tab num_children

* Sanity check: undivided wards
count if num_children == 1
di as result "     (Undivided wards: " r(N) ")"


* ────────────────────────────────────────────────────────────
*  Step 3 — Regional ward division rates  (Q6)
* ────────────────────────────────────────────────────────────

gen byte divided = (num_children >= 2)

preserve
    collapse (count) n_wards = num_children  ///
             (sum)   n_divided = divided,    ///
             by(region_gis_2012)

    gen rate_division = n_divided / n_wards
    format rate_division %9.3f
    gsort -rate_division

    di _n
    di as text "{hline 60}"
    di as text "Q6 — Ward division rate by region"
    di as text "{hline 60}"
    list region_gis_2012 n_wards n_divided rate_division, ///
         noobs clean
restore



* ============================================================
* Part 2
* De-biasing a Parameter Estimate Using Controls
* ============================================================

clear all
set more off
set seed 68180802

* ────────────────────────────────────────────────────────────
*  1. Define the data-generating process (DGP) as a program
* ────────────────────────────────────────────────────────────

capture program drop run_dgp
program define run_dgp, rclass

    syntax, ssize(integer)

    clear
    set obs `ssize'

    * True causal effect of treatment on outcome: 0.3 sd
    local tau = 0.3

    * ── Confounder (W) ──────────────────────────────────────
    *  W affects BOTH treatment assignment and the outcome.
    *  Omitting W from a regression will produce upward-biased
    *  estimates of the treatment effect because W is positively
    *  correlated with both D and Y.
    gen W = runiform()

    * ── Treatment (D) ──────────────────────────────────────
    *  Binary treatment whose probability depends on confounder W.
    *  Higher W → higher chance of receiving treatment.
    gen D = (runiform() < 0.25 + 0.45 * W)

    * ── Outcome (Y) ────────────────────────────────────────
    *  Y is a linear function of D (causal, coef = tau = 0.3)
    *  and W (confounding, coef = 0.5), plus noise.
    gen Y = `tau' * D + 0.5 * W + rnormal(0, 1)

    * ── Mediator (P) ──────────────────────────────────────
    *  P lies on the causal pathway D → P → Y.
    *  Controlling for P absorbs part of D's effect, so the
    *  coefficient on D will be attenuated (biased toward 0).
    gen P = 0.4 * D + rnormal(0, 1)

    *  P feeds back into Y (indirect pathway)
    replace Y = Y + 0.3 * P

    * ── Collider (S) ──────────────────────────────────────
    *  S is caused by both D and Y (a "common effect").
    *  Conditioning on S opens a non-causal path D ← S → Y
    *  and introduces collider bias.
    gen S = 0.5 * D + 0.5 * Y + rnormal(0, 1)

    * ── Five regression specifications ─────────────────────
    *  Spec 1: omit confounder → biased upward
    reg Y D
    return scalar coef1 = _b[D]

    *  Spec 2: include confounder only → correct (recovers total effect)
    reg Y D W
    return scalar coef2 = _b[D]

    *  Spec 3: include confounder + mediator → attenuated
    reg Y D W P
    return scalar coef3 = _b[D]

    *  Spec 4: include confounder + collider → collider bias
    reg Y D W S
    return scalar coef4 = _b[D]

    *  Spec 5: include confounder + mediator + collider → double bad controls
    reg Y D W P S
    return scalar coef5 = _b[D]

end


* ────────────────────────────────────────────────────────────
*  2. Monte Carlo: iterate across sample sizes
* ────────────────────────────────────────────────────────────

local mc_file "mc_sim_results.dta"
postfile pf int(iter) int(sample_n)  ///
    double(coef1 coef2 coef3 coef4 coef5)  ///
    using `mc_file', replace

local nreps = 500
local sample_sizes 50 100 500 1000 5000

local k = 0

foreach sz of local sample_sizes {
    forvalues r = 1/`nreps' {
        local ++k
        qui run_dgp, ssize(`sz')
        post pf (`k') (`sz')  ///
            (r(coef1)) (r(coef2)) (r(coef3)) (r(coef4)) (r(coef5))
    }
    di as text "  → sample size `sz' done"
}

postclose pf


* ────────────────────────────────────────────────────────────
*  3. Reshape and summarise
* ────────────────────────────────────────────────────────────

use "mc_sim_results.dta", clear

* Rename for reshape
rename coef1 coef_1
rename coef2 coef_2
rename coef3 coef_3
rename coef4 coef_4
rename coef5 coef_5

reshape long coef_, i(iter sample_n) j(spec)
rename coef_ beta_hat

* Descriptive labels for each specification
label define spec_lbl  ///
    1 "D only (omit W)"  ///
    2 "D + W (correct)"  ///
    3 "D + W + P (mediator)"  ///
    4 "D + W + S (collider)"  ///
    5 "D + W + P + S (all)"
label values spec spec_lbl

* Compute summary statistics by specification × sample size
*   True total effect = 0.3 (direct) + 0.3 × 0.4 (via mediator) = 0.42
local tau_total = 0.3 + 0.3 * 0.4

preserve
    collapse (mean) avg_beta = beta_hat  ///
             (sd)   se_beta  = beta_hat, by(spec sample_n)

    gen bias = avg_beta - `tau_total'
    format avg_beta se_beta bias %9.4f

    di _n
    di as text "{hline 65}"
    di as text "  Summary: mean(beta), bias, and sd(beta) by specification & N"
    di as text "{hline 65}"
    list spec sample_n avg_beta bias se_beta, sepby(spec) noobs clean
restore


* ────────────────────────────────────────────────────────────
*  4. Figures — bias and convergence
* ────────────────────────────────────────────────────────────

preserve
    collapse (mean) avg_beta = beta_hat  ///
             (sd)   se_beta  = beta_hat, by(spec sample_n)

    local tau_total = 0.42

    * ── Figure 1: average estimated beta vs sample size ────
    twoway  ///
        (connected avg_beta sample_n if spec==1, ///
            lp(dash)      mc(cranberry) lc(cranberry))  ///
        (connected avg_beta sample_n if spec==2, ///
            lp(solid)     mc(navy)      lc(navy))       ///
        (connected avg_beta sample_n if spec==3, ///
            lp(shortdash) mc(forest_green) lc(forest_green))  ///
        (connected avg_beta sample_n if spec==4, ///
            lp(longdash)  mc(dkorange)  lc(dkorange))   ///
        (connected avg_beta sample_n if spec==5, ///
            lp(dot)       mc(lavender)  lc(lavender))   ///
        , yline(`tau_total', lp(solid) lc(black) lw(medthick))  ///
        legend(order(  ///
            1 "D only (omit W)"  ///
            2 "D + W (correct)"  ///
            3 "D + W + P (mediator)"  ///
            4 "D + W + S (collider)"  ///
            5 "D + W + P + S (all)"   ///
        ) rows(2) size(small))  ///
        ytitle("Average {&beta}{subscript:D}")  ///
        xtitle("Sample size")  ///
        title("Bias Comparison: Mean Treatment Effect Estimate")  ///
        note("Reference line = true total effect (0.42). 500 iterations per cell.")  ///
        scheme(s2color)
    graph export "fig_part2_mean.png", replace width(1200)

    * ── Figure 2: standard deviation of beta vs sample size ─
    twoway  ///
        (connected se_beta sample_n if spec==1, ///
            lp(dash)      mc(cranberry) lc(cranberry))  ///
        (connected se_beta sample_n if spec==2, ///
            lp(solid)     mc(navy)      lc(navy))       ///
        (connected se_beta sample_n if spec==3, ///
            lp(shortdash) mc(forest_green) lc(forest_green))  ///
        (connected se_beta sample_n if spec==4, ///
            lp(longdash)  mc(dkorange)  lc(dkorange))   ///
        (connected se_beta sample_n if spec==5, ///
            lp(dot)       mc(lavender)  lc(lavender))   ///
        , legend(order(  ///
            1 "D only (omit W)"  ///
            2 "D + W (correct)"  ///
            3 "D + W + P (mediator)"  ///
            4 "D + W + S (collider)"  ///
            5 "D + W + P + S (all)"   ///
        ) rows(2) size(small))  ///
        ytitle("SD of {&beta}{subscript:D}")  ///
        xtitle("Sample size")  ///
        title("Convergence: Variability of Estimates as N Grows")  ///
        note("500 iterations per cell.")  ///
        scheme(s2color)
    graph export "fig_part2_sd.png", replace width(1200)

restore


* ============================================================
* Part 3: Spatial Analysis
* Choropleth: CCM party vote share by region (Tanzania 2015)
* ============================================================

clear all
set more off

* Required user-written packages (uncomment on first run)
* ssc install spmap, replace
* ssc install shp2dta, replace
* ssc install mif2dta, replace


* ────────────────────────────────────────────────────────────
*  Step 1 — Convert the GADM shapefile into Stata format
*  shp2dta outputs two files:
*    tz_attr.dta   = attribute table (region names + polygon id)
*    tz_poly.dta   = polygon coordinates for drawing borders
* ────────────────────────────────────────────────────────────

shp2dta using "gadm41_TZA_1",  ///
    database(tz_attr) coordinates(tz_poly)  ///
    genid(poly_id) replace


* ────────────────────────────────────────────────────────────
*  Step 2 — Build region-level CCM vote share from raw data
* ────────────────────────────────────────────────────────────

use "Tanzania_election_2015_raw.dta", clear

* Aggregate votes to region × party level
collapse (sum) votes, by(region party)
save "region_party_votes.dta", replace

* Compute each region's total votes (all parties combined)
collapse (sum) all_votes = votes, by(region)
save "region_all_votes.dta", replace

* Keep only CCM rows and merge back total votes
use "region_party_votes.dta", clear
keep if party == "CCM"
rename votes votes_ccm

merge m:1 region using "region_all_votes.dta", nogen

* Calculate vote share (%)
gen pct_ccm = votes_ccm / all_votes * 100
format pct_ccm %5.1f

* Harmonize region names to title case (match shapefile)
replace region = proper(lower(region))
replace region = "Dar Es Salaam" if region == "Dar es salaam"

list region pct_ccm, noobs clean

save "election_by_region.dta", replace


* ────────────────────────────────────────────────────────────
*  Step 3 — Merge election data onto the shapefile attributes
* ────────────────────────────────────────────────────────────

use "tz_attr.dta", clear

describe
list poly_id NAME_1 in 1/5

* Match variable name to election dataset
rename NAME_1 region

merge 1:1 region using "election_by_region.dta"
tab _merge

* Retain all regions so the map is complete even without data
drop _merge

save "tz_attr_merged.dta", replace


* ────────────────────────────────────────────────────────────
*  Step 4 — Draw choropleth maps
* ────────────────────────────────────────────────────────────

* --- Version 1: quantile classification, blue palette ---
spmap pct_ccm using "tz_poly.dta", id(poly_id)  ///
    clmethod(quantile) clnumber(5)  ///
    fcolor(Blues2)  ///
    ndlab("No data") ndfcolor(gs10)  ///
    ocolor(white ..) osize(vthin ..)  ///
    legend(size(2.5) position(7))  ///
    title("CCM Vote Share by Region — 2015 Ward Elections")  ///
    subtitle("Percentage of total valid votes")  ///
    note("Data: Tanzania National Electoral Commission")
graph export "fig_part3_map_v1.png", replace width(1400)

* --- Version 2: custom breakpoints, diverging palette ---
spmap pct_ccm using "tz_poly.dta", id(poly_id)  ///
    clmethod(custom)  ///
    clbreaks(30 40 50 55 60 65 70)  ///
    fcolor(Reds)  ///
    ndlab("No data") ndfcolor(gs10)  ///
    ocolor(white ..) osize(vthin ..)  ///
    legend(size(2.5) position(7))  ///
    title("CCM Vote Share by Region — 2015 Ward Elections")  ///
    subtitle("Custom intervals, percentage points")  ///
    note("Data: Tanzania National Electoral Commission")
graph export "fig_part3_map_v2.png", replace width(1400)