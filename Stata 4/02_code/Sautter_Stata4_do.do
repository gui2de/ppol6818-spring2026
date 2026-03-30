**********
* STATA 4
**********
global wd "/Users/maren/Desktop/Experimental Design & Implementation/Stata 4"


**************************
** Part 1: Fuzzy Matching
**************************
clear all
set more off

** Loading 2015 TZ data
use "Tz_elec_15_clean.dta", clear
keep region_15 district_15 ward_15

** Standardizing strings
foreach v in region_15 district_15 ward_15 {
    replace `v' = lower(trim(`v'))
}

rename region_15 region
rename district_15 district
rename ward_15 ward


tempfile d2015
save `d2015'

** Loading 2010 TZ data
use "Tz_elec_10_clean.dta", clear
keep region_10 district_10 ward_10

foreach v in region_10 district_10 ward_10 {
    replace `v' = lower(trim(`v'))
}

rename region_10 region
rename district_10 district
rename ward_10 ward

tempfile d2010
save `d2010'

** Merging
merge 1:1 region district ward using `d2015'

count if _merge == 1 // In 2010 only (orphan wards)
count if _merge == 2 // In 2015 only (parentless wards)
count if _merge == 3 // In both

display 2379 + 954 // works, it equals 2010 total of 3333
display 2379 + 1565 // also works, equals 2015 total = 3944

** 1) How many wards exist both in 2010 and 2015? 
* 2379 

** 2) How many are "parentless" wards (i.e. exist in 2015 but not in 2010)
* 1565

** 3) How many are "orphan" wards? (i.e. exist in 2010 but not in 2015)
* 954

** Using intersection data to identify splits
use "Tz_GIS_2015_2010_intersection.dta", clear
bysort region_gis_2012 district_gis_2012 ward_gis_2012: ///
    gen split_count = _N
bysort region_gis_2012 district_gis_2012 ward_gis_2012: keep if _n == 1

** 4)How many wards were divided into two wards between 2010 and 2015?
count if split_count == 2
* 466

** How many wards were divided into three or more wards between 2010 and 2015?
count if split_count >= 3
* 37

** Creating split indicator and collapsing to region level
generate was_split = split_count > 1	

collapse (sum) num_split = was_split ///
         (count) total_wards = was_split, ///
         by(region_gis_2012)

generate division_rate = num_split / total_wards
sort division_rate
generate perc_division = division_rate * 100

** 6) List regions along with the rate of ward division
list region_gis_2012 total_wards num_split perc_division, clean


*********************************************************
** Part 2: De-biasing a parameter estimate using controls
******************************************************+**

clear all
set more off
set seed 202629

** Defining program

capture program drop sim_controls
program define sim_controls, rclass
    syntax, N(integer)

    clear
    set obs `n'

    * confounder
    gen c = rnormal()

    * treatment
    gen t_latent = 0.8*c + rnormal()
    gen treat = (t_latent > 0)

    * mediator
    gen m = 0.4*treat + 0.3*c + rnormal()

    * outcome
    gen y = 0.1*treat + 0.7*c + 0.5*m + rnormal() 

    * collider
    gen k = 0.7*treat + 0.7*y + rnormal() // depends on treat and Y

	
    * Regression model

    * Model 1: naive
    quietly reg y treat
    return scalar b1 = _b[treat]

    * Model 2: controls for confounder 
    quietly reg y treat c
    return scalar b2 = _b[treat]

    * Model 3: controls for confounder + mediator 
    quietly reg y treat c m
    return scalar b3 = _b[treat]

    * Model 4: adds collider 
    quietly reg y treat c k
    return scalar b4 = _b[treat]

    * Model 5: everything 
    quietly reg y treat c m k
    return scalar b5 = _b[treat]
end


** Running simulation

tempfile results
save `results', emptyok replace

local reps 500
local sizes 50 100 200 400 800 1600 3200 

foreach n of local sizes {

    di "Running N = `n'"

    simulate ///
        b1=r(b1) b2=r(b2) b3=r(b3) b4=r(b4) b5=r(b5), ///
        reps(`reps') nodots: sim_controls, n(`n')

    gen sample_size = `n'

    * True values
    gen true_direct = 0.3
    gen true_total  = 0.6

    * Bias relative to direct effect
    gen bias_b1 = b1 - true_direct
    gen bias_b2 = b2 - true_direct
    gen bias_b3 = b3 - true_direct
    gen bias_b4 = b4 - true_direct
    gen bias_b5 = b5 - true_direct

    collapse ///
        (mean) mean_b1=b1 mean_b2=b2 mean_b3=b3 mean_b4=b4 mean_b5=b5 ///
               mean_bias_b1=bias_b1 mean_bias_b2=bias_b2 mean_bias_b3=bias_b3 ///
               mean_bias_b4=bias_b4 mean_bias_b5=bias_b5 ///
        (sd)   sd_b1=b1 sd_b2=b2 sd_b3=b3 sd_b4=b4 sd_b5=b5, ///
        by(sample_size)

    append using `results'
    save `results', replace
}

use `results', clear
sort sample_size

** Creating SD bands
foreach j in 1 2 3 4 5 {
    gen upper_b`j' = mean_b`j' + sd_b`j'
    gen lower_b`j' = mean_b`j' - sd_b`j'
}


** Visualizing

twoway ///
    (line sd_b1 sample_size, lcolor(maroon)) ///
    (line sd_b2 sample_size, lcolor(erose)) ///
    (line sd_b3 sample_size, lcolor(midblue)) ///
    (line sd_b4 sample_size, lcolor(forest_green)) ///
    (line sd_b5 sample_size, lcolor(purple)), ///
    title("Standard Deviation of Beta by Sample Size") ///
    xtitle("Sample Size") ///
    ytitle("SD of Estimated Beta") ///
    legend(order(1 "Naive" ///
                 2 "Confounder only" ///
                 3 "Confounder + Mediator" ///
                 4 "Confounder + Collider" ///
                 5 "All variables"))
graph export "${wd}/03_output/part2_full.png", replace
	
	
* Model 1				 
twoway ///
    (rarea upper_b1 lower_b1 sample_size, color(maroon%20)) ///
    (line mean_b1 sample_size, lcolor(maroon)) ///
    (function y = 0.3, range(sample_size) lpattern(dash) lcolor(black)), ///
    title("Model 1 (Naive): Mean Beta with SD Band") ///
    xtitle("Sample Size") ///
    ytitle("Estimated Beta") ///
    legend(order(1 "SD band" ///
                 2 "Mean beta" ///
                 3 "True parameter (0.3)"))
graph export "${wd}/03_output/part2_model1.png", replace


* Model 2				 
twoway ///
    (rarea upper_b2 lower_b2 sample_size, color(erose%20)) ///
    (line mean_b2 sample_size, lcolor(erose)) ///
    (function y = 0.3, range(sample_size) lpattern(dash) lcolor(black)), ///
    title("Model 2 (Confounder Only): Mean Beta with SD Band") ///
    xtitle("Sample Size") ///
    ytitle("Estimated Beta") ///
    legend(order(1 "SD band" ///
                 2 "Mean beta" ///
                 3 "True parameter (0.3)"))
graph export "${wd}/03_output/part2_model2.png", replace


* Model 3				 
twoway ///
    (rarea upper_b3 lower_b3 sample_size, color(midblue%20)) ///
    (line mean_b3 sample_size, lcolor(midblue)) ///
    (function y = 0.3, range(sample_size) lpattern(dash) lcolor(black)), ///
    title("Model 3 (Confounder + Mediator): Mean Beta with SD Band") ///
    xtitle("Sample Size") ///
    ytitle("Estimated Beta") ///
    legend(order(1 "SD band" ///
                 2 "Mean beta" ///
                 3 "True parameter (0.3)"))
graph export "${wd}/03_output/part2_model3.png", replace


* Model 4				 
twoway ///
    (rarea upper_b4 lower_b4 sample_size, color(forest_green%20)) ///
    (line mean_b4 sample_size, lcolor(forest_green)) ///
    (function y = 0.3, range(sample_size) lpattern(dash) lcolor(black)), ///
    title("Model 4 (Confounder + Collider): Mean Beta with SD Band") ///
    xtitle("Sample Size") ///
    ytitle("Estimated Beta") ///
    legend(order(1 "SD band" ///
                 2 "Mean beta" ///
                 3 "True parameter (0.3)"))
graph export "${wd}/03_output/part2_model4.png", replace


* Model 5				 
twoway ///
    (rarea upper_b5 lower_b5 sample_size, color(purple%20)) ///
    (line mean_b5 sample_size, lcolor(purple)) ///
    (function y = 0.3, range(sample_size) lpattern(dash) lcolor(black)), ///
    title("Model 5 (All Variables): Mean Beta with SD Band") ///
    xtitle("Sample Size") ///
    ytitle("Estimated Beta") ///
    legend(order(1 "SD band" ///
                 2 "Mean beta" ///
                 3 "True parameter (0.3)"))
graph export "${wd}/03_output/part2_model5.png", replace


* Table for Markdown
list sample_size ///
     mean_b1 sd_b1 ///
     mean_b2 sd_b2 ///
     mean_b3 sd_b3 ///
     mean_b4 sd_b4 ///
     mean_b5 sd_b5, ///
     clean noobs



****************************
** Part 3: Spatial Analysis
****************************

** Shapefile 
ssc install shp2dta
ssc install spmap

clear all
set more off

tempfile va_data va_coord

shp2dta using "${wd}/01_data/cb_2020_us_county_500k.shp", ///
    data("${wd}/01_data/va_data.dta") ///
    coor("${wd}/01_data/va_coord.dta") ///
    genid(id) replace
	
use "${wd}/01_data/va_data.dta", clear
keep if STATEFP == "51"

gen fips = STATEFP + COUNTYFP
save "${wd}/01_data/va_counties.dta", replace //has 133 observations, this checks out. Virginia has 133 county-level administrative units.

** County-level data from County Health Rankings & Roadmpas 
import excel "$wd/01_data/va_statistics.xlsx", firstrow clear

rename FIPS fips 

** Merging
merge 1:1 fips using "${wd}/01_data/va_counties.dta"
tab _merge // everything worked, all 133 obs merged
save "${wd}/03_output/va_map_merged.dta", replace

** Running cloropleth map
spmap perc_rural using "${wd}/01_data/va_coord.dta", id(id) ///
    clmethod(custom) ///
    clbreaks(0 25 50 75 100) ///
    fcolor(Blues) ///
    ndfcolor(gs12) ndlab("Missing") ///
    legend(size(*1.5) pos(4) ring(1)) ///
    plotregion(margin(12 12 12 12)) ///
    title("Percent Rural Population") ///
    subtitle("Virginia Counties, 2023") ///
	note("Source: U.S. Census Bureau; County Health Rankings & Roadmaps")
	
	graph export "${wd}/03_output/q3_cloroplethva.png", replace
	
	
	
	

