cd "/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Stata4HW"



/* REVIEW

I couldn't make the comments in the github website because you didn't upload through a pull request, but your work was great! It literraly ran perfectly on my computer.*/






* ============================================================
* Part 1: Fuzzy Matching
* Tanzania Ward Matching 2010-2015
* ============================================================

clear all
set more off

* ------------------------------------------------------------
* Q1: How many wards exist in both 2010 and 2015?
* Q2: Parentless wards (in 2015 but not in 2010)
* Q3: Orphan wards (in 2010 but not in 2015)
* Strategy: merge on region + ward name (district boundaries changed,
*           so region+district+ward would be too strict)
* ------------------------------------------------------------

* Load 2015 ward data
use "Tz_elec_15_clean.dta", clear

* Standardize names for matching
gen region_lower = lower(strtrim(region_15))
gen ward_lower   = lower(strtrim(ward_15))

* Create matching key
gen rw_key = region_lower + "|" + ward_lower

tempfile w15
save `w15'

* Load 2010 ward data
use "Tz_elec_10_clean.dta", clear

gen region_lower = lower(strtrim(region_10))
gen ward_lower   = lower(strtrim(ward_10))
gen rw_key = region_lower + "|" + ward_lower

tempfile w10
save `w10'

* Merge 2015 (master) with 2010 (using) on region + ward name
use `w15', clear
merge m:m rw_key using `w10'

* Q1: wards matched in both years
tab _merge

* Count unique 2015 wards by merge status
preserve
    keep if _merge == 3
    bysort ward_id_15: keep if _n == 1
    count
    di "Q1 - Wards in both 2010 and 2015: " r(N)
restore

* Q2: parentless wards (in 2015 only)
preserve
    keep if _merge == 1
    bysort ward_id_15: keep if _n == 1
    count
    di "Q2 - Parentless wards (2015 only): " r(N)
restore

* Q3: orphan wards (in 2010 only)
preserve
    keep if _merge == 2
    bysort ward_id_10: keep if _n == 1
    count
    di "Q3 - Orphan wards (2010 only): " r(N)
restore


* ------------------------------------------------------------
* Q4: How many wards were divided into two?
* Q5: How many wards were divided into three or more?
* Strategy: use GIS intersection data. Group by 2012 (parent) ward
*           and count how many distinct 2017 (child) wards it maps to.
* ------------------------------------------------------------

use "Tz_GIS_2015_2010_intersection.dta", clear

* Create a unique key for each 2012 parent ward
gen parent_key = region_gis_2012 + "|" + district_gis_2012 + "|" + ward_gis_2012

* Create a unique key for each 2017 child ward
gen child_key = region_gis_2017 + "|" + district_gis_2017 + "|" + ward_gis_2017

* For each parent ward, count distinct child wards
bysort parent_key child_key: keep if _n == 1
bysort parent_key: gen n_children = _N

* Keep one row per parent ward
bysort parent_key: keep if _n == 1

* Q4: divided into exactly 2
count if n_children == 2
di "Q4 - Divided into 2: " r(N)

* Q5: divided into 3 or more
count if n_children >= 3
di "Q5 - Divided into 3+: " r(N)

* Breakdown of 3+
tab n_children if n_children >= 3

* Not divided (sanity check)
count if n_children == 1
di "Not divided: " r(N)


* ------------------------------------------------------------
* Q6: Region-level ward division rates
* ------------------------------------------------------------

gen was_divided = (n_children > 1)

* Collapse by region: count total wards and divided wards
preserve
    collapse (count) total_wards=n_children (sum) divided_wards=was_divided, ///
             by(region_gis_2012)
    gen division_rate = divided_wards / total_wards
    format division_rate %9.3f
    gsort -division_rate
    list region_gis_2012 total_wards divided_wards division_rate, noobs clean
restore

* ============================================================
* PPOL6818 Assignment 08 - Part 2: De-biasing a Parameter Estimate
* ============================================================

clear all
set more off
set seed 20240401

* ============================================================
* 1. Define the simulation program
* ============================================================

capture program drop sim_dgp
program define sim_dgp, rclass

    syntax, n(integer)

    clear
    set obs `n'

    * --- True treatment effect (0.3 sd) ---
    local beta = 0.3

    * --- Confounder C: causes both T and Y ---
    *     Omitting C from regression biases beta upward
    gen C = runiform()

    * --- Treatment T: influenced by confounder C ---
    *     Prob(T=1) increases with C, so T and C are correlated
    gen T = (runiform() < 0.3 + 0.4 * C)

    * --- Outcome Y: determined by T and C + noise ---
    *     True causal effect of T on Y is beta = 0.3
    *     C also directly affects Y (coefficient = 0.5)
    gen Y = `beta' * T + 0.5 * C + rnormal(0, 1)

    * --- Mediator M: T -> M -> Y ---
    *     M is part of the causal pathway from T to Y
    *     Controlling for M absorbs part of T's effect
    gen M = 0.4 * T + rnormal(0, 1)

    *     Add mediator's contribution to Y
    replace Y = Y + 0.3 * M

    * --- Collider Z: caused by both T and Y ---
    *     Conditioning on Z opens a spurious path T <- Z -> Y
    gen Z = 0.5 * T + 0.5 * Y + rnormal(0, 1)

    * --- Model 1: Y on T only (omitted C => biased) ---
    reg Y T
    return scalar b1 = _b[T]

    * --- Model 2: Y on T + C (correct spec => unbiased) ---
    reg Y T C
    return scalar b2 = _b[T]

    * --- Model 3: Y on T + C + M (mediator controlled => attenuated) ---
    reg Y T C M
    return scalar b3 = _b[T]

    * --- Model 4: Y on T + C + Z (collider controlled => biased) ---
    reg Y T C Z
    return scalar b4 = _b[T]

    * --- Model 5: Y on T + C + M + Z (both bad controls) ---
    reg Y T C M Z
    return scalar b5 = _b[T]

end


* ============================================================
* 2. Run simulations across sample sizes
* ============================================================

* Store results in a temporary file
tempfile results
postfile handle int(sim_id) int(N) ///
    double(b1 b2 b3 b4 b5) ///
    using `results'

local reps = 500
local sizes 50 100 500 1000 5000

local sim_counter = 0

foreach n of local sizes {
    forvalues i = 1/`reps' {
        local ++sim_counter
        qui sim_dgp, n(`n')
        post handle (`sim_counter') (`n') ///
            (r(b1)) (r(b2)) (r(b3)) (r(b4)) (r(b5))
    }
    di "Completed N = `n'"
}

postclose handle


* ============================================================
* 3. Analyze results: compute mean and variance of beta by model and N
* ============================================================

use `results', clear

* Reshape to long format: one row per sim × model
rename b1 b_1
rename b2 b_2
rename b3 b_3
rename b4 b_4
rename b5 b_5

reshape long b_, i(sim_id N) j(model)
rename b_ beta

* Label models
label define model_lbl ///
    1 "T only (omit C)" ///
    2 "T + C (correct)" ///
    3 "T + C + M (mediator)" ///
    4 "T + C + Z (collider)" ///
    5 "T + C + M + Z (both)"
label values model model_lbl

* Collapse to mean and sd of beta by model and N
preserve
    collapse (mean) mean_beta=beta (sd) sd_beta=beta, by(model N)

    * True effect: beta = 0.3 (direct) + 0.3*0.4 = 0.42 (total via mediator)
    * Model 2 should recover total effect ≈ 0.42
    * Model 3 should recover direct effect ≈ 0.3
    local true_total = 0.3 + 0.3 * 0.4
    local true_direct = 0.3

    * --- Table ---
    list model N mean_beta sd_beta, sepby(model) noobs clean

    * Compute bias relative to total effect for display
    gen bias = mean_beta - `true_total'
    format mean_beta sd_beta bias %9.4f
    list model N mean_beta bias sd_beta, sepby(model) noobs clean
restore


* ============================================================
* 4. Figures
* ============================================================

preserve
    collapse (mean) mean_beta=beta (sd) sd_beta=beta, by(model N)

    local true_total = 0.42

    * --- Figure 1: Mean of beta across N, by model ---
    twoway ///
        (connected mean_beta N if model==1, lp(dash)    mc(red)    lc(red))    ///
        (connected mean_beta N if model==2, lp(solid)   mc(blue)   lc(blue))   ///
        (connected mean_beta N if model==3, lp(shortdash) mc(green) lc(green)) ///
        (connected mean_beta N if model==4, lp(longdash) mc(orange) lc(orange)) ///
        (connected mean_beta N if model==5, lp(dot)     mc(purple) lc(purple)) ///
        , yline(`true_total', lp(solid) lc(black) lw(medthick))               ///
        legend(order(                                                           ///
            1 "T only (omit C)"                                                 ///
            2 "T + C (correct)"                                                 ///
            3 "T + C + M (mediator)"                                            ///
            4 "T + C + Z (collider)"                                            ///
            5 "T + C + M + Z (both)"                                            ///
        ) rows(2) size(small))                                                  ///
        ytitle("Mean of {&beta}")                                               ///
        xtitle("Sample Size (N)")                                               ///
        title("Mean Estimated Treatment Effect by Model and N")                 ///
        note("Horizontal line = true total effect (0.42). 500 reps per cell.")  ///
        scheme(s2color)
    graph export "fig1_mean_beta.png", replace width(1200)

    * --- Figure 2: SD (variance proxy) of beta across N, by model ---
    twoway ///
        (connected sd_beta N if model==1, lp(dash)    mc(red)    lc(red))    ///
        (connected sd_beta N if model==2, lp(solid)   mc(blue)   lc(blue))   ///
        (connected sd_beta N if model==3, lp(shortdash) mc(green) lc(green)) ///
        (connected sd_beta N if model==4, lp(longdash) mc(orange) lc(orange)) ///
        (connected sd_beta N if model==5, lp(dot)     mc(purple) lc(purple)) ///
        , legend(order(                                                       ///
            1 "T only (omit C)"                                               ///
            2 "T + C (correct)"                                               ///
            3 "T + C + M (mediator)"                                          ///
            4 "T + C + Z (collider)"                                          ///
            5 "T + C + M + Z (both)"                                          ///
        ) rows(2) size(small))                                                ///
        ytitle("SD of {&beta}")                                               ///
        xtitle("Sample Size (N)")                                             ///
        title("Convergence: SD of Treatment Effect by Model and N")           ///
        note("500 reps per cell.")                                            ///
        scheme(s2color)
    graph export "fig2_sd_beta.png", replace width(1200)

restore

* ============================================================
* Part 3: Choropleth Map
* Map: CCM vote share by region, Tanzania 2015 ward elections
* ============================================================

clear all
set more off

* Install required packages (run once)
* ssc install spmap
* ssc install shp2dta
* ssc install mif2dta

* ============================================================
* Step 2: Convert shapefile to Stata format
* shp2dta creates two .dta files:
*   - tzcoord.dta: polygon coordinates for drawing
*   - tzdb.dta:    attribute table with region names and _ID
* ============================================================

shp2dta using "gadm41_TZA_1", ///
    database(tzdb) coordinates(tzcoord) ///
    genid(id) replace


* ============================================================
* Step 3: Prepare election data — CCM vote share by region
* ============================================================

use "Tanzania_election_2015_raw.dta", clear

* Total votes by region and party
collapse (sum) votes, by(region party)
tempfile party_votes
save `party_votes'

* Total votes by region (all parties)
use `party_votes', clear
collapse (sum) total_votes=votes, by(region)
tempfile region_totals
save `region_totals'

* CCM vote share
use `party_votes', clear
keep if party == "CCM"
rename votes ccm_votes
merge m:1 region using `region_totals', nogen

gen ccm_share = ccm_votes / total_votes * 100
format ccm_share %9.1f

* Standardize region name to match shapefile (title case)
replace region = proper(lower(region))
replace region = "Dar Es Salaam" if region == "Dar es salaam"

list region ccm_share, noobs clean

tempfile election
save `election'


* ============================================================
* Step 4: Merge election data with shapefile database
* Open tzdb.dta to check the region name variable, then merge
* ============================================================

use "tzdb.dta", clear

* Check what the region name variable is called in the shapefile
* (common names: NAME_1, REGION, name, etc.)
describe
list id NAME_1 in 1/5

* Rename to match our election data
rename NAME_1 region

* Merge with election data
merge 1:1 region using `election'
tab _merge

* Keep all regions (even if unmatched) so the map draws completely
drop _merge

save "tzdb_merged.dta", replace


* ============================================================
* Step 5: Draw the choropleth map
* ============================================================

* Basic choropleth — CCM vote share
spmap ccm_share using "tzcoord.dta", id(id) ///
    clmethod(quantile) clnumber(6) ///
    fcolor(Blues) ///
    ndlab("Missing") ndfcolor(gs8) ///
    legend(size(2.5)) ///
    title("CCM Vote Share in 2015 Ward Elections (%)") ///
    subtitle("By Region") ///
    note("Source: Tanzania Election Commission, 2015")

graph export "fig3_choropleth.png", replace width(1600)


* custom breaks for more intuitive categories
spmap ccm_share using "tzcoord.dta", id(id) ///
    clmethod(custom) ///
    clbreaks(30 40 50 55 60 65 70) ///
    fcolor(RdBu) ///
    ndlab("Missing") ndfcolor(gs8) ///
    ocolor(white ..) osize(thin ..) ///
    legend(size(2.5) position(8)) ///
    title("CCM Vote Share in 2015 Ward Elections (%)") ///
    subtitle("By Region") ///
    note("Source: Tanzania Election Commission, 2015")

graph export "fig3_choropleth_v2.png", replace width(1600)
