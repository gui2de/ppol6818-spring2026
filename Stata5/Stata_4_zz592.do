********************************************************************************
*Stata 2 Assignment
*Author: Zimu Zhai (Arlo)
*NetID: zz592
*Date: 03/29/2026
**********************************************
*****************************Part 1*******************************************

clear all
set more off

global data_dir "/Users/zhongguochimingdijianjian/Desktop/Experiment Design/Stata_4"
cd "$data_dir"


*1: Clean 2015 election data

use "Tz_elec_15_clean.dta", clear

replace ward_15     = lower(trim(ward_15))
replace region_15   = lower(trim(region_15))
replace district_15 = lower(trim(district_15))

* Rename to neutral names for merging
rename ward_15     ward_2015
rename region_15   region_2015
rename district_15 district_elec15       

save "elec15_clean.dta", replace

*2: Clean 2010 election data


use "Tz_elec_10_clean.dta", clear

replace ward_10     = lower(trim(ward_10))
replace region_10   = lower(trim(region_10))
replace district_10 = lower(trim(district_10))

rename ward_10     ward_2010
rename region_10   region_2010
rename district_10 district_elec10

save "elec10_clean.dta", replace


*3: Clean GIS dataset

use "Tz_GIS_2015_2010_intersection.dta", clear

rename ward_gis_2017     ward_2015
rename region_gis_2017   region_2015
rename district_gis_2017 district_gis_2015
rename ward_gis_2012     ward_2010
rename region_gis_2012   region_2010
rename district_gis_2012 district_gis_2010

replace ward_2015        = lower(trim(ward_2015))
replace region_2015      = lower(trim(region_2015))
replace district_gis_2015 = lower(trim(district_gis_2015))
replace ward_2010        = lower(trim(ward_2010))
replace region_2010      = lower(trim(region_2010))
replace district_gis_2010 = lower(trim(district_gis_2010))

save "gis_clean.dta", replace


*4: Children count per 2010 ward

use "gis_clean.dta", clear

keep if percentage >= 50

bysort ward_2010 region_2010: gen n_children = _N
bysort ward_2010 region_2010: keep if _n == 1

label var n_children "Number of 2015 wards overlapping this 2010 ward by >50%"
keep ward_2010 region_2010 district_gis_2010 n_children

save "gis_children_count.dta", replace


*5: Best-match GIS

use "gis_clean.dta", clear

bysort ward_2015 region_2015 (percentage): keep if _n == _N

save "gis_best_match.dta", replace


*6: Merge GIS with elec15


use "gis_best_match.dta", clear

joinby ward_2015 region_2015 using "elec15_clean.dta", unmatched(both)
* _merge from joinby:
*   1 = GIS only (no elec15 match found for this ward+region)
*   2 = elec15 only (elec15 ward+region not in GIS)
*   3 = matched

rename _merge merge_gis_elec15

gen id_match = (fid_gis_2017 == ward_id_15 - 1) if merge_gis_elec15 == 3

bysort ward_2015 region_2015 (id_match): keep if _n == _N

gen in_elec15 = (merge_gis_elec15 == 3)
label var in_elec15 "=1 if GIS ward matched to elec15"

drop id_match
save "gis_merged_elec15.dta", replace


*7: Merge with elec10

use "gis_merged_elec15.dta", clear

joinby ward_2010 region_2010 using "elec10_clean.dta", unmatched(both)
rename _merge merge_gis_elec10

* Prefer fid_gis_2012 == ward_id_10 - 1
gen id_match10 = (fid_gis_2012 == ward_id_10 - 1) if merge_gis_elec10 == 3
bysort ward_2015 region_2015 (id_match10): keep if _n == _N

gen in_elec10 = (merge_gis_elec10 == 3)
label var in_elec10 "=1 if GIS ward's 2010 parent matched to elec10"

drop id_match10
save "master_matched.dta", replace

di _n "Master dataset observations: " _N
tab merge_gis_elec15 merge_gis_elec10

* Question 1: Wards that exist in BOTH 2010 and 2015

use "master_matched.dta", clear

gen exact_name_match = (ward_2015 == ward_2010)
label var exact_name_match "Ward name identical in 2015 and 2010"

count if exact_name_match == 1 & in_elec15 == 1 & in_elec10 == 1
di as result "Wards with same name matched in both years: " r(N)


* Question 2: "Parentless" wards (in 2015 but no 2010 parent found)

count if in_elec10 == 0 & in_elec15 == 1
di as result "Parentless wards: " r(N)

preserve
    keep if in_elec10 == 0 & in_elec15 == 1
    keep ward_2015 region_2015 ward_2010 percentage
    sort region_2015 ward_2015
    save "q2_parentless_wards.dta", replace
    list ward_2015 region_2015 ward_2010 percentage, sep(0) noobs
restore

* QUESTION 3: "Orphan" wards (in 2010 but not in 2015)

* Get unique 2010 parents that appear in the master matched dataset
use "master_matched.dta", clear
keep ward_2010 region_2010
duplicates drop
gen was_matched_as_parent = 1
sort ward_2010 region_2010
save "matched_parents_list.dta", replace

use "elec10_clean.dta", clear

bysort ward_2010 region_2010 (ward_id_10): keep if _n == 1

sort ward_2010 region_2010

merge 1:1 ward_2010 region_2010 using "matched_parents_list.dta", ///
    gen(merge_orphan)

count if merge_orphan == 1
di as result "Orphan wards (2010 with no 2015 match): " r(N)

keep if merge_orphan == 1
keep ward_2010 region_2010 district_elec10
sort region_2010 ward_2010
save "q3_orphan_wards.dta", replace
list ward_2010 region_2010, sep(0) noobs


* QUESTION 4 & 5: Ward division counts

use "gis_children_count.dta", clear


count if n_children == 2
di as result "2010 wards split into exactly 2: " r(N)


count if n_children >= 3
di as result "2010 wards split into 3+: " r(N)

save "q4q5_division_summary.dta", replace


* QUESTION 6: Division rate by region


use "gis_children_count.dta", clear

gen was_divided = (n_children >= 2)

collapse ///
    (count) total_wards_2010 = n_children ///
    (sum)   wards_divided    = was_divided ///
    , by(region_2010)

gen division_rate = wards_divided / total_wards_2010
format division_rate %6.3f
label var total_wards_2010 "Total 2010 wards in region"
label var wards_divided    "2010 wards divided by 2015"
label var division_rate    "Share of 2010 wards divided"

gsort -division_rate
save "q6_division_by_region.dta", replace

list region_2010 total_wards_2010 wards_divided division_rate, sep(0) noobs

graph hbar division_rate, ///
    over(region_2010, sort(1) descending label(angle(45) labsize(small))) ///
    ytitle("Division rate") ///
    title("Rate of Ward Division by Region (2010–2015)") ///
    note("Division rate = wards split into 2+ / total 2010 wards in region") ///
    blabel(bar, format(%4.3f) size(tiny)) ///
    graphregion(color(white))

graph export "ward_division_rate_by_region.png", replace width(1400)


* FINAL SUMMARY


use "master_matched.dta", clear
gen exact_name_match = (ward_2015 == ward_2010)
count if exact_name_match == 1 & in_elec15 == 1 & in_elec10 == 1
di "Q1 – Wards in both years (exact name match): " r(N)
count if in_elec10 == 0 & in_elec15 == 1
di "Q2 – Parentless wards:                       " r(N)
use "q3_orphan_wards.dta", clear
count
di "Q3 – Orphan wards:                           " r(N)
use "q4q5_division_summary.dta", clear
count if n_children == 2
di "Q4 – Divided into exactly 2:                 " r(N)
count if n_children >= 3
di "Q5 – Divided into 3+:                        " r(N)
di "Q6 – See q6_division_by_region.dta and graph"

*****************************Part 2********************************************
clear all
set more off
set seed 12345

global data_dir "/Users/zhongguochimingdijianjian/Desktop/Experiment Design/Stata_4"
cd "$data_dir"


capture program drop mysim
program define mysim, rclass
    syntax, n(integer)

    clear
    set obs `n'

    * Confounder
    gen C = runiform()

    * Treatment
    gen T = (runiform() < 0.3 + 0.4*C)

    * Mediator
    gen M = 0.5*T + runiform()

    * Outcome: true direct effect of treatment = 0.3
    gen Y = 0.3*T + 0.5*C + 0.4*M + rnormal()

    * Collider
    gen K = 0.4*T + 0.4*Y + rnormal()

    * Model 1: no controls
    quietly reg Y T
    return scalar b1 = _b[T]

    * Model 2: correct model, control confounder only
    quietly reg Y T C
    return scalar b2 = _b[T]

    * Model 3: over-control mediator
    quietly reg Y T C M
    return scalar b3 = _b[T]

    * Model 4: collider bias
    quietly reg Y T C K
    return scalar b4 = _b[T]

    * Model 5: all controls
    quietly reg Y T C M K
    return scalar b5 = _b[T]
end

* Run simulations
local reps 200
local sizes 50 100 200 500 1000 2000

local first = 1

foreach n of local sizes {

    simulate b1=r(b1) b2=r(b2) b3=r(b3) b4=r(b4) b5=r(b5), ///
        reps(`reps') seed(12345): mysim, n(`n')

    gen N = `n'

    if `first' == 1 {
        save "sim_all.dta", replace
        local first = 0
    }
    else {
        append using "sim_all.dta"
        save "sim_all.dta", replace
    }
}

* Summary table

use "sim_all.dta", clear

collapse (mean) mean_b1=b1 mean_b2=b2 mean_b3=b3 mean_b4=b4 mean_b5=b5 ///
         (sd) sd_b1=b1 sd_b2=b2 sd_b3=b3 sd_b4=b4 sd_b5=b5, by(N)

list, noobs
save "sim_summary.dta", replace


* Figure 1: mean beta by model across N

twoway ///
    (connected mean_b1 N) ///
    (connected mean_b2 N) ///
    (connected mean_b3 N) ///
    (connected mean_b4 N) ///
    (connected mean_b5 N), ///
    yline(0.3, lpattern(dash) lcolor(black)) ///
    ytitle("Mean estimated coefficient on treatment") ///
    xtitle("Sample size") ///
    title("Bias across model specifications") ///
    legend(order(1 "No controls" ///
                 2 "Confounder only" ///
                 3 "Confounder + mediator" ///
                 4 "Confounder + collider" ///
                 5 "All controls"))

graph export "fig_bias.png", replace


* Figure 2: SD of beta by model across N

twoway ///
    (connected sd_b1 N) ///
    (connected sd_b2 N) ///
    (connected sd_b3 N) ///
    (connected sd_b4 N) ///
    (connected sd_b5 N), ///
    ytitle("SD of estimated coefficient") ///
    xtitle("Sample size") ///
    title("Convergence as sample size grows") ///
    legend(order(1 "No controls" ///
                 2 "Confounder only" ///
                 3 "Confounder + mediator" ///
                 4 "Confounder + collider" ///
                 5 "All controls"))

graph export "fig_convergence.png", replace


* Bias table

use "sim_all.dta", clear

foreach m in 1 2 3 4 5 {
    gen bias_b`m' = b`m' - 0.3
}

collapse (mean) bias_b1 bias_b2 bias_b3 bias_b4 bias_b5, by(N)

list, noobs
export delimited using "table_bias.csv", replace

***********************************Part 3***************************************

clear all
set more off

global data_dir "/Users/zhongguochimingdijianjian/Desktop/Experiment Design/Stata_4"
cd "$data_dir"

cap which spmap
if _rc ssc install spmap

cap which shp2dta
if _rc ssc install shp2dta

*  Convert shapefile to Stata format
shp2dta using "cb_2018_us_state_20m.shp", ///
    database(usdata) ///
    coordinates(uscoord) ///
    genid(id) ///
    replace

* Open shapefile attribute data and inspect merge key
use usdata, clear
describe

keep id STUSPS NAME
save usdata_clean, replace

* Import data

import delimited "https://raw.githubusercontent.com/plotly/datasets/master/2011_us_ag_exports.csv", clear

describe

* The file contains state abbreviations in variable "code"
rename code STUSPS

rename totalexports total_exports
rename beef beef_exports
rename pork pork_exports
rename poultry poultry_exports
rename dairy dairy_exports
rename fruitsfresh fruits_fresh
rename fruitsproc fruits_processed
rename totalveggies total_vegs
rename corn corn_exports
rename wheat wheat_exports
rename cotton cotton_exports

* Keep only what we need for the merge
keep state STUSPS total_exports
save exports_data, replace

* Merge public data with shapefile attribute data

use usdata_clean, clear
merge 1:1 STUSPS using exports_data

tab _merge

keep if _merge == 3
drop _merge

save mapdata_merged, replace

* Create choropleth map
spmap total_exports using uscoord, id(id) ///
    clnumber(6) ///
    clmethod(quantile) ///
    fcolor(Blues) ///
    ocolor(gs10 ..) ///
    osize(vthin ..) ///
    title("U.S. State Agricultural Exports") ///
    subtitle("Publicly available 2011 state-level data") ///
    legtitle("Total exports") ///
    note("Source: Plotly public dataset + U.S. Census shapefile") ///
    name(us_exports_map, replace)

graph export "part3_us_exports_map.png", replace width(2000)
