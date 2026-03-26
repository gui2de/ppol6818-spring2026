// Stata4_QingyueChen

// Part1: Fuzzy Matching
clear all
set more off

cd "C:\Users\86186\Desktop\Experimental design\stata4\part1"

use "Tz_elec_10_clean.dta", clear

foreach v in region_10 district_10 ward_10 {
    replace `v' = lower(strtrim(itrim(`v')))
}

duplicates drop region_10 district_10 ward_10, force
gen key10 = region_10 + "|" + district_10 + "|" + ward_10

tempfile w2010
save `w2010'

use "Tz_elec_15_clean.dta", clear

foreach v in region_15 district_15 ward_15 {
    replace `v' = lower(strtrim(itrim(`v')))
}

duplicates drop region_15 district_15 ward_15, force
gen key15 = region_15 + "|" + district_15 + "|" + ward_15

tempfile w2015
save `w2015'

use `w2015', clear
rename key15 key
tempfile temp15
save `temp15'

use `w2010', clear
rename key10 key

merge 1:1 key using `temp15'

count if _merge == 3
display "1) Wards in both 2010 and 2015: " r(N)

preserve
    keep if _merge == 3
    gen match_type = "exact"
    tempfile exact
    save `exact'
restore

preserve
    keep if _merge == 2
    keep region_15 district_15 ward_15
    tempfile unmatched15
    save `unmatched15'
restore

use "Tz_GIS_2015_2010_intersection.dta", clear

foreach v in region_gis_2017 district_gis_2017 ward_gis_2017 ///
             region_gis_2012 district_gis_2012 ward_gis_2012 {
    replace `v' = lower(strtrim(itrim(`v')))
}

gsort +ward_gis_2017 -percentage
by ward_gis_2017: keep if _n == 1

rename ward_gis_2017 ward_15
rename ward_gis_2012 ward_10
rename region_gis_2012 region_10
rename district_gis_2012 district_10

keep ward_15 ward_10 region_10 district_10 percentage

tempfile crosswalk
save `crosswalk'

use `unmatched15', clear

merge m:1 ward_15 using `crosswalk'

count if _merge == 1
display "2) Parentless wards: " r(N)

preserve
    keep if _merge == 3
    gen match_type = "gis"
    tempfile gis
    save `gis'
restore

use `exact', clear
append using `gis'

gen parent_key = region_10 + "|" + district_10 + "|" + ward_10
gen child_key  = region_15 + "|" + district_15 + "|" + ward_15

tempfile final
save `final'

use `w2010', clear
gen parent_key = key10

tempfile all2010
save `all2010'

use `final', clear
keep parent_key
duplicates drop parent_key, force
tempfile used_parent
save `used_parent'

use `all2010', clear
merge 1:1 parent_key using `used_parent'

count if _merge == 1
display "3) Orphan wards: " r(N)

use `final', clear

bysort parent_key: gen n_children = _N
bysort parent_key: keep if _n == 1

count if n_children == 2
display "4) Split into 2 wards: " r(N)

count if n_children >= 3
display "5) Split into 3 or more wards: " r(N)

tempfile division
save `division'

use `w2010', clear
gen one = 1
collapse (sum) total_wards = one, by(region_10)

tempfile total
save `total'

use `division', clear
gen divided = (n_children >= 2)

collapse (sum) divided_wards = divided, by(region_10)

merge 1:1 region_10 using `total', nogen
replace divided_wards = 0 if missing(divided_wards)

gen division_rate = divided_wards / total_wards
format division_rate %9.3f

sort division_rate
display "6) Region division rates:"
list region_10 divided_wards total_wards division_rate, noobs

use `final', clear
save "Tz_parent_mapping_final.dta", replace

// Part 1: Results
* 1) Wards existing in both 2010 and 2015
* A total of 2,379 wards were matched exactly between 2010 and 2015, indicating no administrative boundary change.

* 2) Parentless wards (2015 only)
* There are 168 parentless wards, meaning these wards exist in 2015 but could not be matched to any 2010 ward using either exact matching or GIS overlap.

* 3) Orphan wards (2010 only)
* There are 954 orphan wards, which existed in 2010 but do not appear in 2015 as standalone units, suggesting they were fully absorbed or restructured.

* 4) Wards divided into exactly two wards
* A total of 182 wards from 2010 were split into exactly two wards by 2015.

* 5) Wards divided into three or more wards
* There are 22 wards that were split into three or more wards, indicating more substantial administrative fragmentation.

* 6) Region-level ward division rates
/* list region_10 divided_wards total_wards division_rate, noobs

  +------------------------------------------------+
  |     region_10   divide~s   total_~s   divisi~e |
  |------------------------------------------------|
  | dar es salaam          0         90      0.000 |
  |         pwani          0        112      0.000 |
  |         lindi          1        141      0.007 |
  |        iringa          2        189      0.011 |
  |   kilimanjaro          2        153      0.013 |
  |------------------------------------------------|
  |         tanga          4        206      0.019 |
  |       manyara          3        123      0.024 |
  |     shinyanga          7        245      0.029 |
  |       singida          4        124      0.032 |
  |        kagera          7        203      0.034 |
  |------------------------------------------------|
  |          mara          6        154      0.039 |
  |        arusha          6        122      0.049 |
  |         mbeya         11        218      0.050 |
  |        dodoma         10        190      0.053 |
  |        tabora          9        163      0.055 |
  |------------------------------------------------|
  |        mwanza         12        214      0.056 |
  |        ruvuma         10        140      0.071 |
  |      morogoro         13        181      0.072 |
  |        mtwara         14        149      0.094 |
  |         rukwa         10        106      0.094 |
  |------------------------------------------------|
  |        kigoma         13        110      0.118 |
  |        simiyu         19          .          . |
  |         geita         21          .          . |
  |        katavi         12          .          . |
  |        njombe          8          .          . |
  +------------------------------------------------+
*/

* Ward division rates vary significantly across regions.
* Regions with no division include: Dar es Salaam (0.000), Pwani (0.000)
* Regions with moderate division rates (~3%–6%) include: Shinyanga (0.029), Kagera (0.034), Mwanza (0.056)
* Regions with high division rates (>7%) include: Ruvuma (0.071), Morogoro (0.072), Mtwara (0.094), Rukwa (0.094), Kigoma (0.118)
* Kigoma exhibits the highest division rate (11.8%), suggesting particularly intensive administrative restructuring in that region.
* Some newly created regions (e.g., Simiyu, Geita, Katavi, Njombe) have missing denominators for 2010 wards, so division rates could not be calculated for them.


// Part 2: De-biasing a parameter estimate using controls
clear all
set more off
set seed 20260325

cd "C:\Users\86186\Desktop\Experimental design\stata4\part2"

capture program drop sim_once
program define sim_once, rclass
    version 16.0
    syntax, N(integer)

    clear
    set obs `n'

    gen u1 = runiform()
    gen u2 = runiform()
    gen e_t = rnormal()
    gen e_m = rnormal()
    gen e_y = rnormal()
    gen e_c = rnormal()

    gen region = ceil(runiform()*5)

    gen confounder = 2*u1 + u2 + rnormal()
    * Confounder affects both treatment assignment and outcome Y

	gen treat_star = 0.8*confounder + 0.3*u2 + 0.2*region + e_t
	summarize treat_star, detail
	gen treat = (treat_star > r(p50))
    * Treatment is partly determined by the confounder

    gen mediator = 0.8*treat + 0.5*confounder + e_m
    * Mediator is caused by treatment and also affects Y

    gen y0 = 0.3*treat + 0.8*confounder + 0.6*mediator + 0.2*u2 + e_y
    quietly summarize y0
    gen y = (y0 - r(mean))/r(sd)
    * Outcome depends on treatment, confounder, and mediator; standardized to SD = 1

    gen collider = 0.8*treat + 0.8*y + e_c
    * Collider is caused by both treatment and outcome Y

    quietly regress y treat
    return scalar b1 = _b[treat]

    quietly regress y treat confounder
    return scalar b2 = _b[treat]

    quietly regress y treat mediator
    return scalar b3 = _b[treat]

    quietly regress y treat collider
    return scalar b4 = _b[treat]

    quietly regress y treat confounder mediator
    return scalar b5 = _b[treat]

    quietly regress y treat confounder collider
    return scalar b6 = _b[treat]

    quietly regress y treat confounder i.region
    return scalar b7 = _b[treat]
end

capture erase "sim_results_part2.dta"

postfile results int N int rep double b1 b2 b3 b4 b5 b6 b7 ///
    using "sim_results_part2.dta", replace

local nlist 100 250 500 1000 2500 5000
local reps 300

foreach N of local nlist {
    forvalues r = 1/`reps' {
        quietly sim_once, n(`N')
        post results (`N') (`r') ///
            (r(b1)) (r(b2)) (r(b3)) (r(b4)) (r(b5)) (r(b6)) (r(b7))
    }
}

postclose results

use "sim_results_part2.dta", clear

gen true_beta = 0.3

foreach m of numlist 1/7 {
    gen bias`m' = b`m' - true_beta
}

collapse ///
    (mean) mean_b1=b1 mean_b2=b2 mean_b3=b3 mean_b4=b4 mean_b5=b5 mean_b6=b6 mean_b7=b7 ///
    (sd)   sd_b1=b1   sd_b2=b2   sd_b3=b3   sd_b4=b4   sd_b5=b5   sd_b6=b6   sd_b7=b7 ///
    (mean) mean_bias1=bias1 mean_bias2=bias2 mean_bias3=bias3 mean_bias4=bias4 ///
           mean_bias5=bias5 mean_bias6=bias6 mean_bias7=bias7, by(N)

save "summary_part2.dta", replace
export delimited using "summary_part2.csv", replace

use "summary_part2.dta", clear

gen true_line = 0.3
gen zero_line = 0

twoway ///
    (connected mean_b1 N, msymbol(o)) ///
    (connected mean_b2 N, msymbol(o)) ///
    (connected mean_b3 N, msymbol(o)) ///
    (connected mean_b4 N, msymbol(o)) ///
    (connected mean_b5 N, msymbol(o)) ///
    (connected mean_b6 N, msymbol(o)) ///
    (connected mean_b7 N, msymbol(o)) ///
    (line true_line N, lpattern(dash)), ///
    title("Mean Beta by Sample Size") ///
    xtitle("Sample Size") ///
    ytitle("Mean Estimated Beta") ///
    legend(order(1 "M1" 2 "M2" 3 "M3" 4 "M4" 5 "M5" 6 "M6" 7 "M7" 8 "True=0.3") ///
           cols(4) size(vsmall) position(6) ring(0) region(lstyle(none))) ///
    graphregion(color(white)) ///
    plotregion(margin(medium))
graph export "mean_beta_by_N_fixed.png", replace

twoway ///
    (connected sd_b1 N, msymbol(o)) ///
    (connected sd_b2 N, msymbol(o)) ///
    (connected sd_b3 N, msymbol(o)) ///
    (connected sd_b4 N, msymbol(o)) ///
    (connected sd_b5 N, msymbol(o)) ///
    (connected sd_b6 N, msymbol(o)) ///
    (connected sd_b7 N, msymbol(o)), ///
    title("SD of Beta by Sample Size") ///
    xtitle("Sample Size") ///
    ytitle("SD of Estimated Beta") ///
    legend(order(1 "M1" 2 "M2" 3 "M3" 4 "M4" 5 "M5" 6 "M6" 7 "M7") ///
           cols(4) size(vsmall) position(6) ring(0) region(lstyle(none))) ///
    graphregion(color(white)) ///
    plotregion(margin(medium))
graph export "sd_beta_by_N_fixed.png", replace

twoway ///
    (connected mean_bias1 N, msymbol(o)) ///
    (connected mean_bias2 N, msymbol(o)) ///
    (connected mean_bias3 N, msymbol(o)) ///
    (connected mean_bias4 N, msymbol(o)) ///
    (connected mean_bias5 N, msymbol(o)) ///
    (connected mean_bias6 N, msymbol(o)) ///
    (connected mean_bias7 N, msymbol(o)) ///
    (line zero_line N, lpattern(dash)), ///
    title("Bias by Sample Size") ///
    xtitle("Sample Size") ///
    ytitle("Mean Bias") ///
    legend(order(1 "M1" 2 "M2" 3 "M3" 4 "M4" 5 "M5" 6 "M6" 7 "M7" 8 "Zero") ///
           cols(4) size(vsmall) position(6) ring(0) region(lstyle(none))) ///
    graphregion(color(white)) ///
    plotregion(margin(medium))
graph export "bias_by_N_fixed.png", replace

* M1 = treat only
* M2 = treat + confounder
* M3 = treat + mediator
* M4 = treat + collider
* M5 = treat + confounder + mediator
* M6 = treat + confounder + collider
* M7 = treat + confounder + fixed effects

twoway ///
    (connected mean_b1 N, msymbol(o)) ///
    (connected mean_b2 N, msymbol(o)) ///
    (connected mean_b3 N, msymbol(o)) ///
    (connected mean_b4 N, msymbol(o)) ///
    (line true_line N, lpattern(dash)), ///
    title("Mean Beta by Sample Size: M1-M4") ///
    xtitle("Sample Size") ///
    ytitle("Mean Estimated Beta") ///
    legend(order(1 "M1" 2 "M2" 3 "M3" 4 "M4" 5 "True=0.3") ///
           cols(3) size(small) position(6) ring(0) region(lstyle(none))) ///
    graphregion(color(white)) ///
    plotregion(margin(medium))
graph export "mean_beta_M1_M4.png", replace

twoway ///
    (connected mean_b5 N, msymbol(o)) ///
    (connected mean_b6 N, msymbol(o)) ///
    (connected mean_b7 N, msymbol(o)) ///
    (line true_line N, lpattern(dash)), ///
    title("Mean Beta by Sample Size: M5-M7") ///
    xtitle("Sample Size") ///
    ytitle("Mean Estimated Beta") ///
    legend(order(1 "M5" 2 "M6" 3 "M7" 4 "True=0.3") ///
           cols(2) size(small) position(6) ring(0) region(lstyle(none))) ///
    graphregion(color(white)) ///
    plotregion(margin(medium))
graph export "mean_beta_M5_M7.png", replace


// Part 3
clear all
set more off

cd "C:\Users\86186\Desktop\Experimental design\stata4\part3"

cap which spmap
if _rc ssc install spmap

cap which shp2dta
if _rc ssc install shp2dta

shp2dta using "low_income_shape\Low_Income_Communities.shp", ///
    data("lowincome_db.dta") ///
    coor("lowincome_coord.dta") ///
    genid(id) replace

use "lowincome_db.dta", clear
rename *, lower
describe
list in 1/10

keep objectid id
tempfile lowshape
save `lowshape'

import delimited "Low_Income_Communities.csv", clear
rename *, lower
describe
list in 1/10

keep objectid pctpopli countyname
rename pctpopli low_income_pct

tempfile lowcsv
save `lowcsv'

use `lowshape', clear
merge 1:1 objectid using `lowcsv'

tab _merge
keep if _merge == 3
drop _merge

save "lowincome_merged.dta", replace

spmap low_income_pct using "lowincome_coord.dta", id(id) ///
    clnumber(6) ///
    clmethod(quantile) ///
    fcolor(Reds2) ///
    ocolor(black ..) ///
    ndfcolor(gs14) ///
    ndocolor(gs8) ///
    title("Share of Residents in Low-Income Communities, Virginia", size(*1.2)) ///
    subtitle("Higher concentrations are clustered across many rural counties, while several metro-adjacent areas show comparatively lower shares.", size(*0.9)) ///
    legend(position(11) ring(0) size(*0.9) region(lstyle(none))) ///
    plotregion(margin(medium)) ///
    graphregion(color(white))
	
graph export "low_income_clean_map.png", replace

