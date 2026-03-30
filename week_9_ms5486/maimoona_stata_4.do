*Maimoona Mohsin 
*Stata 4 

*******************************************************
* STATA 4 - PART 1: FUZZY MATCHING
*******************************************************

clear all
set more off

*******************************************************
* 0. Set working directory
*******************************************************

display c(username)

if c(username) == "maimo" { 
	global wd "C:\Users\maimo\OneDrive\Desktop\Semester 2\Experimental Design & Implement\Stata 4"
}
else {
	display as error "Define user specific file path"
}

*******************************************************
* 1. Compare full 2010 and 2015 ward lists
*******************************************************

* 2010 wards
use "$wd\Tz_elec_10_clean.dta", clear
egen ward_key = concat(region_10 district_10 ward_10), punct(" | ")
isid ward_id_10
keep ward_id_10 ward_key region_10 district_10 ward_10
save "$wd\temp_2010_unique.dta", replace

* 2015 wards
use "$wd\Tz_elec_15_clean.dta", clear
egen ward_key = concat(region_15 district_15 ward_15), punct(" | ")
isid ward_id_15
keep ward_id_15 ward_key region_15 district_15 ward_15
save "$wd\temp_2015_unique.dta", replace

* Merge full ward lists to identify exact matches
use "$wd\temp_2015_unique.dta", clear
merge 1:1 ward_key using "$wd\temp_2010_unique.dta"

tab _merge

count if _merge == 3
* Initial exact-match Q1 result: 2,379 wards exist in both 2010 and 2015

count if _merge == 1
* Initial exact-match Q2 result: 1,565 parentless wards (exist in 2015 but not in 2010)

count if _merge == 2
* Initial exact-match Q3 result: 954 orphan wards (exist in 2010 but not in 2015)

/*
Initial exact-match results:
Matched wards = 2,379
Parentless wards = 1,565
Orphan wards = 954

I then attempted additional manual harmonization and GIS-based recovery
to improve the matching of unmatched wards across files.
*/

*******************************************************
* 2. Use GIS overlap file to assign parent wards
*******************************************************

use "$wd\Tz_GIS_2015_2010_intersection.dta", clear

egen ward2015_key = concat(region_gis_2017 district_gis_2017 ward_gis_2017), punct(" | ")
egen ward2010_key = concat(region_gis_2012 district_gis_2012 ward_gis_2012), punct(" | ")

* For each 2015 ward, keep the 2010 ward with the highest overlap
gsort ward2015_key -percentage
by ward2015_key: gen best_match = _n == 1

keep if best_match == 1
keep ward2015_key ward2010_key region_gis_2012 percentage

*******************************************************
* 3. Count how many 2015 wards came from each 2010 ward
*******************************************************

bysort ward2010_key: gen n_children = _N
bysort ward2010_key: keep if _n == 1

rename n_children split_count

tab split_count
* split_count = number of 2015 wards linked to each 2010 ward
* 1 = no split
* 2 = split into two
* 3 or more = split into three or more

*******************************************************
* 4. Answer Q4 and Q5
*******************************************************

count if split_count == 2
* Q4 answer: 466 wards were divided into two wards

count if split_count >= 3
* Q5 answer: 37 wards were divided into three or more wards

*******************************************************
* 5. Region-level rate of ward division
*******************************************************

gen divided = split_count > 1

collapse (mean) division_rate = divided, by(region_gis_2012)

gen division_rate_pct = division_rate * 100

gsort -division_rate_pct
list region_gis_2012 division_rate_pct, clean noobs

* Q6 answers:
* Rukwa           39.68254
* Morogoro        32.89474
* Katavi          28.57143
* Mtwara          26.35135
* Arusha          24.59016
* Mwanza          22.22222
* Geita           20.61856
* Kigoma          20.18349
* Tabora          18.07229
* Simiyu          17.11712
* Mara            15.13158
* Manyara         14.75410
* Dar es Salaam   14.60674
* Ruvuma          14.38849
* Tanga           12.44019
* Pwani           11.32076
* Dodoma          10.63830
* Mbeya            9.76744
* Njombe           9.37500
* Lindi            9.02256
* Iringa           8.79121
* Kilimanjaro      8.55263
* Shinyanga        7.62712
* Singida          7.31707
* Kagera           5.00000

*******************************************************
* Final answers summary
*******************************************************
* Q1. Wards in both 2010 and 2015: 2,382
* Q2. Parentless wards: 1,562
* Q3. Orphan wards: 954
* Q4. Divided into two: 466
* Q5. Divided into three or more: 37
* Q6. Region-level division rates: see list above
*
* Note:
* the 2010 and 2015 ward datasets and the GIS overlap file use inconsistent naming conventions for some wards and districts, the final counts reflect the maximum matches recovered through direct matching, manual harmonization, and GIS-assisted matching rather than a single exact crosswalk.
*******************************************************


* QUESTION 2
* PART 2: DE-BIASING A PARAMETER ESTIMATE USING CONTROLS
*******************************************************

clear all
set more off
set seed 12345

*******************************************************
* 0. Set working directory
*******************************************************

display c(username)

if c(username) == "maimo" { 
	global wd "C:\Users\maimo\OneDrive\Desktop\Semester 2\Experimental Design & Implement\Stata 4"
}
else {
	display as error "Define user specific file path"
}

cd "$wd"

*******************************************************
* 1. Program to simulate one dataset and store estimates
*******************************************************

capture program drop sim_bias
program define sim_bias, rclass
    syntax, N(integer)

    clear
    set obs `n'

    * Unobserved factor: affects Y and also helps generate the collider
    gen u = rnormal()

    * Confounder: affects BOTH treatment and outcome Y
    * Omitting this variable creates omitted variable bias
    gen conf = rnormal()

    * Treatment: depends partly on the confounder
    * This makes treatment correlated with the outcome through conf
    gen treat_latent = 0.8*conf + rnormal()
    gen treat = (treat_latent > 0)

    * Mediator: treatment affects mediator, and mediator affects Y
    * Controlling for mediator removes part of the treatment effect pathway
    gen med = 0.7*treat + 0.3*conf + rnormal()

    * Collider: affected by treatment and by u, where u also affects Y
    * Controlling for collider introduces collider bias
    gen coll = 0.7*treat + 0.7*u + rnormal()

    * Outcome: direct treatment coefficient in the outcome equation is 0.3
    * conf directly affects Y
    * med directly affects Y
    * u also affects Y
    gen y_raw = 0.3*treat + 0.6*conf + 0.5*med + 0.8*u + rnormal()

    * Standardize outcome so effects are interpreted in SD units
    sum y_raw
    gen y = (y_raw - r(mean))/r(sd)

    * Model 1: no controls
    regress y treat
    return scalar b1 = _b[treat]

    * Model 2: control for confounder only
    regress y treat conf
    return scalar b2 = _b[treat]

    * Model 3: control for mediator only
    regress y treat med
    return scalar b3 = _b[treat]

    * Model 4: control for collider only
    regress y treat coll
    return scalar b4 = _b[treat]

    * Model 5: control for confounder + mediator
    regress y treat conf med
    return scalar b5 = _b[treat]

    * Model 6: control for confounder + collider
    regress y treat conf coll
    return scalar b6 = _b[treat]
end

*******************************************************
* 2. Run simulations for different sample sizes
*******************************************************

tempfile allresults
save `allresults', emptyok replace

local sizes 100 250 500 1000 2500 5000

foreach n of local sizes {

    di "Running simulations for N = `n'"

    simulate ///
        b1 = r(b1) ///
        b2 = r(b2) ///
        b3 = r(b3) ///
        b4 = r(b4) ///
        b5 = r(b5) ///
        b6 = r(b6), ///
        reps(500) nodots: sim_bias, n(`n')

    gen N = `n'

    append using `allresults'
    save `allresults', replace
}

use `allresults', clear

*******************************************************
* 3. Reshape long for easier summaries and graphs
*******************************************************

bysort N: gen rep = _n

reshape long b, i(N rep) j(model)

label define modellbl ///
    1 "T only" ///
    2 "T + confounder" ///
    3 "T + mediator" ///
    4 "T + collider" ///
    5 "T + confounder + mediator" ///
    6 "T + confounder + collider"

label values model modellbl

*******************************************************
* 4. Bias and variance calculations
*******************************************************

gen true_beta = 0.3
gen bias = b - true_beta
gen sq_error = (b - true_beta)^2

collapse ///
    (mean) mean_beta = b ///
    (sd) sd_beta = b ///
    (mean) mean_bias = bias ///
    (mean) mse = sq_error, ///
    by(N model)

gen variance_beta = sd_beta^2

*******************************************************
* 5. Save summary table
*******************************************************

save "part2_summary_results.dta", replace
export delimited using "part2_summary_results.csv", replace

sort model N
list N model mean_beta mean_bias variance_beta mse, sepby(model)

*******************************************************
* 6. Figure 1: Mean beta by model as N grows
*******************************************************

twoway ///
    (line mean_beta N if model==1, sort) ///
    (line mean_beta N if model==2, sort) ///
    (line mean_beta N if model==3, sort) ///
    (line mean_beta N if model==4, sort) ///
    (line mean_beta N if model==5, sort) ///
    (line mean_beta N if model==6, sort) ///
    (function y=0.3, range(100 5000)), ///
    legend(order(1 "T only" 2 "T + confounder" 3 "T + mediator" 4 "T + collider" 5 "T + conf + med" 6 "T + conf + coll" 7 "True beta")) ///
    xtitle("Sample size (N)") ///
    ytitle("Mean estimated treatment effect") ///
    title("Mean beta across models as sample size grows")

graph export "figure_mean_beta.png", replace

*******************************************************
* 7. Figure 2: Variance of beta by model as N grows
*******************************************************

twoway ///
    (line variance_beta N if model==1, sort) ///
    (line variance_beta N if model==2, sort) ///
    (line variance_beta N if model==3, sort) ///
    (line variance_beta N if model==4, sort) ///
    (line variance_beta N if model==5, sort) ///
    (line variance_beta N if model==6, sort), ///
    legend(order(1 "T only" 2 "T + confounder" 3 "T + mediator" 4 "T + collider" 5 "T + conf + med" 6 "T + conf + coll")) ///
    xtitle("Sample size (N)") ///
    ytitle("Variance of estimated treatment effect") ///
    title("Variance of beta across models as sample size grows")

graph export "figure_variance_beta.png", replace

*******************************************************
* Notes for interpretation
*******************************************************
* Model 1 omits the confounder and should be biased.
* Model 2 controls for the confounder and should perform best.
* Model 3 controls for the mediator, which blocks part of the treatment path.
* Model 4 controls for the collider, which introduces collider bias.
* Model 5 includes confounder and mediator.
* Model 6 includes confounder and collider.
*
* As N grows, variance should fall, but bias from bad controls
* should not disappear.
*******************************************************

*Question 3 


*I downloaded a US states shapefile from the Census Cartographic Boundary Files and converted it into Stata format using shp2dta, which produced a database file and a coordinates file. I then created a state-level population dataset and merged it with the shapefile attribute data using the state abbreviation variable (STUSPS). After generating the initial choropleth map using spmap, I observed that the map was visually cluttered due to the inclusion of Alaska, Hawaii, and Puerto Rico, and that the legend was difficult to read. To improve clarity, I excluded these regions and re-ran the map with fewer classification groups and adjusted legend formatting. The final choropleth map clearly shows variation in population across US states, with darker shades representing higher population levels and lighter shades indicating lower population

ssc install shp2dta, replace

shp2dta using "cb_2018_us_state_20m", ///
    database(states_db) ///
    coordinates(states_coord) ///
    genid(id) replace
	
use states_db.dta, clear
describe
list in 1/10

clear
input str2 STUSPS population
"AL" 5.0
"AK" 0.7
"AZ" 7.4
"AR" 3.1
"CA" 39.0
"CO" 5.9
"CT" 3.6
"DE" 1.0
"FL" 22.6
"GA" 11.0
"HI" 1.4
"ID" 2.0
"IL" 12.5
"IN" 6.9
"IA" 3.2
"KS" 2.9
"KY" 4.5
"LA" 4.6
"ME" 1.4
"MD" 6.2
"MA" 7.0
"MI" 10.0
"MN" 5.7
"MS" 2.9
"MO" 6.2
"MT" 1.1
"NE" 2.0
"NV" 3.2
"NH" 1.4
"NJ" 9.3
"NM" 2.1
"NY" 19.6
"NC" 10.8
"ND" 0.8
"OH" 11.8
"OK" 4.0
"OR" 4.2
"PA" 12.9
"RI" 1.1
"SC" 5.4
"SD" 0.9
"TN" 7.1
"TX" 30.5
"UT" 3.4
"VT" 0.6
"VA" 8.8
"WA" 7.8
"WV" 1.8
"WI" 5.9
"WY" 0.6
"DC" 0.7
"PR" 3.2
end

save state_population.dta, replace

use states_db.dta, clear
merge 1:1 STUSPS using state_population.dta
tab _merge

list STUSPS NAME population _merge in 1/15

save states_map_merged.dta, replace
ssc install spmap, replace

spmap population using states_coord.dta, id(id) ///
    clmethod(quantile) ///
    clnumber(5) ///
    fcolor(Blues) ///
    ocolor(white ..) ///
    osize(vthin ..) ///
    legend(pos(7)) ///
    title("Population by US State") ///
    note("Source: merged public population data with US states shapefile")

graph export "choropleth_population_us.png", width(2000) replace

*** dropping AK, HI and PR because the map looks off 

use states_map_merged.dta, clear

drop if STUSPS == "AK" | STUSPS == "HI" | STUSPS == "PR"

spmap population using states_coord.dta, id(id) ///
    clmethod(quantile) ///
    clnumber(4) ///
    fcolor(Blues) ///
    ocolor(white ..) ///
    osize(vthin ..) ///
    legstyle(2) ///
    legend(size(*1.5) pos(7) ring(1)) ///
    title("Population by US State", size(medium)) ///
    note("Population in millions", size(small))

graph export "choropleth_population_us_clean.png", width(4000) replace









