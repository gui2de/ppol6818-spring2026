/*==============================================================================
*Name: Catherine Morris
*Class: Gui2de Spring 2026
*Assignment: Stata 4
*Date: March 28, 2026

==============================================================================*/
/*==============================================================================
PART 1 
Between 2010 and 2015, the number of wards in Tanzania went from 3,333 to 3,944. This happened by dividing existing ward into 2 (or in some cases three or more) new wards. You have to create a dataset where each row is a 2015 ward matched with the corresponding parent ward from 2010. It's a trivial task to match wards that weren't divided, but it's impossible to match wards that were divided without additional information. Thankfully, we had access to shapefiles from 2012 and 2017. We used ArcGIS to create a new dataset that tells us the percentage area of 2015 ward that overlaps a 2010 ward. You can use information from this dataset to match wards that were divided. Can you generate the following insights:
1)	How many wards exist both in 2010 and 2015?
2)	How many are "parentless" wards (i.e. exist in 2015 but not in 2010)
3)	How many are "orphan" wards? (i.e. exist in 2010 but not in 2015)
4)	How many wards were divided into two wards between 2010 and 2015?
5)	How many wards were divided into three or more wards between 2010 and 2015?
6)	List regions along with the rate of ward division
==============================================================================*/

*Establishing file path 
clear all

if c(username) == "cam_cew" {
	global path "/Users/cam_cew/Desktop/Experimental_design/Stata_4"
} 
display "${path}"


**creating a temp file for 2015 data. Since we are only looking at wards, I will drop all other variables, as recommended in class
tempfile wards15

use "${path}/Tz_elec_15_clean.dta", clear
keep region_15 district_15 ward_15
foreach var in region_15 district_15 ward_15 {
    replace `var' = strtrim(strlower(`var'))
}

**creating a year variable so I can keep track of which data set is which

gen year = 2015
rename (region_15 district_15 ward_15) (region district ward)
save `wards15'

codebook region district ward

** there are "embedded blanks" but no leading or trailing blanks, 0 missings

** creating a temp file for 2010 data 


tempfile wards10
use "${path}/Tz_elec_10_clean.dta", clear
keep region_10 district_10 ward_10
foreach var in region_10 district_10 ward_10 {
    replace `var' = strtrim(strlower(`var'))
}

gen year = 2010
rename (region_10 district_10 ward_10) (region district ward)

save `wards10'

codebook region district ward

**again embedded blanks and no missing

*merge
use `wards15', clear
merge 1:1 region district ward using `wards10'

count if _merge == 3   // Q1: in both
count if _merge == 1   // Q2: parentless (2015 only)
count if _merge == 2   // Q3: orphan (2010 only)

display 2379+1565
*3944 (aligns with 2015 total)
display 2379+954
*3333 (aligns with 2010 total)

/*Q1-3 ANSWERS

Q1: 2,379 wards exist in both years
Q2: 1,565 parentless wards (new in 2015)
Q3: 954 orphan wards (disappeared from 2010)
*/

use "${path}/Tz_GIS_2015_2010_intersection.dta", clear
tempfile arcgis

*count how many 2015 ward "children" each 2010 ward has
bysort region_gis_2012 district_gis_2012 ward_gis_2012: gen n_children = _N

duplicates drop region_gis_2012 district_gis_2012 ward_gis_2012, force

count if n_children == 2    
count if n_children >= 3    

/*Q4-5 ANSWERS

Q4: 466
Q5: 37
*/

preserve

    gen divided = (n_children > 1)
    collapse (sum) divided (count) total_wards = divided, by(region_gis_2012)
    gen division_rate = (divided / total_wards) * 100
    sort division_rate
    list region_gis_2012 total_wards divided division_rate

restore

/*Q6 output

  | region_g~2012   total_~s   divided   divisi~e |
     |-----------------------------------------------|
  1. |        kagera        180         9          5 |
  2. |       singida        123         9   7.317073 |
  3. |     shinyanga        118         9   7.627119 |
  4. |   kilimanjaro        152        13   8.552631 |
  5. |        iringa         91         8   8.791209 |
     |-----------------------------------------------|
  6. |         lindi        133        12   9.022556 |
  7. |        njombe         96         9      9.375 |
  8. |         mbeya        215        21   9.767442 |
  9. |        dodoma        188        20    10.6383 |
 10. |         pwani        106        12   11.32076 |
     |-----------------------------------------------|
 11. |         tanga        209        26   12.44019 |
 12. |        ruvuma        139        20   14.38849 |
 13. | dar es salaam         89        13   14.60674 |
 14. |       manyara        122        18    14.7541 |
 15. |          mara        152        23   15.13158 |
     |-----------------------------------------------|
 16. |        simiyu        111        19   17.11712 |
 17. |        tabora        166        30   18.07229 |
 18. |        kigoma        109        22   20.18349 |
 19. |         geita         97        20   20.61856 |
 20. |        mwanza        153        34   22.22222 |
     |-----------------------------------------------|
 21. |        arusha        122        30   24.59016 |
 22. |        mtwara        148        39   26.35135 |
 23. |        katavi         42        12   28.57143 |
 24. |      morogoro        152        50   32.89474 |
 25. |         rukwa         63        25   39.68254 
*/

/*==============================================================================
Part 2: De-biasing a parameter estimate using controls

1.Develop some data generating process for data X's and for outcome Y, with a treatment variable and treatment effect (0.3 sd) 
2.This DGP should include: 

1.In addition to creating Y & treatment variables, also create confounder, mediator and a collider var (wrt Ys & treatment)
2.Each of these covariates should be clearly labelled (i.e. put a comment in the code next to where you generate each covariate explaining how it affects the generation of Y).
3.This process need not be complex, you could do everything with basic operations and uniformly distributed random values plus some dataset manipulation.

3.Construct at least five different regression models with combinations of these covariates. (Type h fvvarlist for information on using fixed effects in regression.) Run these regressions at different sample sizes, using a program like last week. Collect as many regression runs as you think you need for each, and produce figures and tables comparing the biasedness and convergence of the models as N grows. Can you produce a figure showing the mean and variance of beta for different regression models, as a function of N? Can you visually compare these to the "true" parameter value?

Fully describe your results in a README file, including figures and tables as appropriate

==============================================================================*/


clear all
set seed 2023

if c(username) == "cam_cew" {
    global path "/Users/cam_cew/Desktop/Experimental_design/Stata_4"
}

*output tempfile
tempfile results
save `results', emptyok

*setting simulation parameters
local reps 500
local sample_sizes 50 100 250 500 1000 2500 5000


*outer loop: sample sizes

foreach n of local sample_sizes {
    
    forvalues i = 1/`reps' {
        
        clear
        set obs `n'
        
        
        /* DGP */
        
        * Confounder: exogenous, affects both treatment and Y
        gen confounder = runiform()
        
        * Treatment: caused by confounder 
        gen treatment = (0.5*confounder + runiform() > 0.5)
        
        * Mediator: caused by treatment, sits on causal path between treatment and Y
        gen mediator = 0.5*treatment + runiform()
        
        * Outcome Y: true treatment effect is 0.3, also affected by confounder and mediator
        * Model 3 (T + confounder + mediator) is the correct specification
        * because it isolates the direct effect of treatment on Y
        gen y = 0.3*treatment + 0.5*confounder + 0.4*mediator + rnormal(0,1)
        
        * Collider: caused by both treatment and Y
        * controlling for it opens a spurious back door path
        gen collider = 0.5*treatment + 0.5*y + runiform()
        
       
        /* Regressions */
        
        * Model 1: Y ~ T only
        * omits confounder and mediator — expect upward bias
        reg y treatment
        mat a = r(table)
        local b1 = a[1,1]
        
        * Model 2: Y ~ T + confounder
        * controls for confounder but misses indirect path through mediator — still biased
        reg y treatment confounder
        mat a = r(table)
        local b2 = a[1,1]
        
        * Model 3: Y ~ T + confounder + mediator
        * correct specification — isolates direct effect, expect ~0.3
        reg y treatment confounder mediator
        mat a = r(table)
        local b3 = a[1,1]
        
        * Model 4: Y ~ T + confounder + collider
        * controlling for collider opens back door — expect bias
        reg y treatment confounder collider
        mat a = r(table)
        local b4 = a[1,1]
        
        * Model 5: Y ~ T + confounder + mediator + collider
        * collider bias dominates — expect bias
        reg y treatment confounder mediator collider
        mat a = r(table)
        local b5 = a[1,1]
        
 
        /* Store results */
      
        clear
        set obs 1
        gen iteration   = `i'
        gen sample_size = `n'
        gen b1          = `b1'
        gen b2          = `b2'
        gen b3          = `b3'
        gen b4          = `b4'
        gen b5          = `b5'
        
        append using `results'
        save `results', replace
    }
    
    display "Done with N = `n'"
}


/* Analysis */

use `results', clear

* Collapse to mean and SD of each beta by sample size
collapse (mean) mean_b1=b1 mean_b2=b2 mean_b3=b3 mean_b4=b4 mean_b5=b5 ///
         (sd)   sd_b1=b1   sd_b2=b2   sd_b3=b3   sd_b4=b4   sd_b5=b5, ///
         by(sample_size)

* True treatment effect for reference
gen true_effect = 0.3

list sample_size mean_b1 mean_b2 mean_b3 mean_b4 mean_b5 true_effect


/* Generating figures — one plot per model */


foreach j in 1 2 3 4 5 {
    twoway ///
        (line mean_b`j' sample_size) ///
        (rarea mean_b`j' sd_b`j' sample_size, color(blue%20)) ///
        (line true_effect sample_size, lpattern(dash) lcolor(red)), ///
        title("Model `j': Mean Beta by Sample Size") ///
        xtitle("Sample Size") ///
        ytitle("Beta Estimate") ///
        legend(label(1 "Mean Beta") label(2 "SD Band") label(3 "True Effect (0.3)"))
    graph export "${path}/model`j'_plot.png", replace
}

/* Generating single combined figure depciting mean beta across models */

twoway ///
    (line mean_b1 sample_size, lcolor(red)) ///
    (line mean_b2 sample_size, lcolor(orange)) ///
    (line mean_b3 sample_size, lcolor(green)) ///
    (line mean_b4 sample_size, lcolor(blue)) ///
    (line mean_b5 sample_size, lcolor(purple)) ///
    (line true_effect sample_size, lpattern(dash) lcolor(black)), ///
    title("Mean Beta by Model and Sample Size") ///
    xtitle("Sample Size") ///
    ytitle("Beta Estimate") ///
    legend(label(1 "Model 1: T only") ///
           label(2 "Model 2: T + Confounder") ///
           label(3 "Model 3: Correct") ///
           label(4 "Model 4: + Collider") ///
           label(5 "Model 5: Everything") ///
           label(6 "True Effect (0.3)"))
graph export "${path}/all_models_beta_plot.png", replace

/* Generating single combined figure depicting standard deviation across models */

twoway ///
    (line sd_b1 sample_size, lcolor(red)) ///
    (line sd_b2 sample_size, lcolor(orange)) ///
    (line sd_b3 sample_size, lcolor(green)) ///
    (line sd_b4 sample_size, lcolor(blue)) ///
    (line sd_b5 sample_size, lcolor(purple)), ///
    title("Variance of Beta by Model and Sample Size") ///
    xtitle("Sample Size") ///
    ytitle("Standard Deviation of Beta") ///
    legend(label(1 "Model 1: T only") ///
           label(2 "Model 2: T + Confounder") ///
           label(3 "Model 3: Correct") ///
           label(4 "Model 4: + Collider") ///
           label(5 "Model 5: Everything"))
graph export "${path}/all_models_sd_plot.png", replace



/*==============================================================================
Part 3: Spatial analysis

Generate any choropleth map at region/state level, where you have to merge some publicly available data (e.g. population, average income, number of accidents etc.) with the shapefile before generating the choropleth map.

==============================================================================*/

ssc install shp2dta
ssc install spmap

* Find/convert shapefile
* Decided to focus on NH since that's where my parents live, and decided to look at percentage of renters by county since renters are getting squeezed in NH. It's a rural state, but Airbnbs and short term rentals have captured what once was the cheap rental housing in the state.

* I used Census data which I had to download from various sources, including here:

/* NH Tenure: https://data.census.gov/table?q=B25003:+Tenure&g=040XX00US33$0600000 (NH county "tenure data" -- choose "County subdivisions", "New Hampshire" and search b25003 at the top. Downloads as 2023 5-year data). Unzip the file and add the files to your path file 

Census shapefile: https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html

Use 2024 county subdivision shapefile for New Hampshire (cb_2024_33_cousub_500k). Also be sure to unzip and add files to your path file. Getting the directory to go to the right place was a major issue for me.

Note that the years don't add up perfectly, but I think that will have to be okay for the purposes of this assignment because I am running out of time.

To anyone reviewing this assignment, we were told that this should take us "20 minutes." This took me hours, mostly because of having to track down the right data and clean it. Just for future reference

*/

clear all
if c(username) == "cam_cew" {
    global path "/Users/cam_cew/Desktop/Experimental_design/Stata_4"
}
display "${path}"


* convert shapefile to Stata format

tempfile nh_data nh_coord census shapefile

shp2dta using "${path}/cb_2024_33_cousub_500k.shp", ///
    data(`nh_data') ///
    coor("${path}/nh_cousub_coord.dta") replace genid(id)


* import and clean Census tenure data

import delimited "${path}/ACSDT5Y2023.B25003-Data.csv", ///
    varnames(1) rowrange(2) clear

* keep only essential variables -- fix renter import issue (originally brought in header as data)
keep geo_id b25003_001e b25003_003e
rename geo_id GEOIDFQ
rename b25003_001e total
rename b25003_003e renters
drop in 1
destring total renters, replace force
gen pct_renters = (renters / total) * 100
save `census'


* merge with shapefile data

use `nh_data', clear
save `shapefile'

use `shapefile', clear
merge 1:1 GEOIDFQ using `census'


/* just a few aren't matched, good enough

merge 1:1 GEOIDFQ using `census'

    Result                      Number of obs
    -----------------------------------------
    Not matched                             2
        from master                         0  (_merge==1)
        from using                          2  (_merge==2)

    Matched                               259  (_merge==3)
*/


*Generate map

spmap pct_renters using "${path}/nh_cousub_coord.dta", id(id) ///
    clnumber(6) clmethod(boxplot) fcolor(BuRd) ///
    ndfcolor(gs8) ndlab("Missing") ///
    legend(size(*1.4)) ///
    title("Percentage of Renters") ///
    subtitle("New Hampshire Towns, 2023")

	
	graph export "${path}/nh_renters_map.png", replace
	
**the legend placement looks a mess, redoing

spmap pct_renters using "${path}/nh_cousub_coord.dta", id(id) ///
    clnumber(6) clmethod(boxplot) fcolor(BuRd) ///
    ndfcolor(gs8) ndlab("Missing") ///
    legend(size(*1.4) pos(4) ring(1)) ///
    title("Percentage of Renters") ///
    subtitle("New Hampshire Towns, 2023")
	
	graph export "${path}/nh_renters_map.png", replace
	
	
*** the percentages were unrounded and needed a percentage sign

replace pct_renters = round(pct_renters, 0.1)
format pct_renters %4.1f

spmap pct_renters using "${path}/nh_cousub_coord.dta", id(id) ///
    clnumber(6) clmethod(boxplot) fcolor(BuRd) ///
    ndfcolor(gs8) ndlab("Missing") ///
    legend(size(*1.4) pos(4) ring(1)) ///
    title("Percentage of Renters (%)") ///
    subtitle("New Hampshire Towns, 2023")
	
	graph export "${path}/nh_renters_map.png", replace
	
*** if this were a graph for my job, I'd definitely spend more time perfecting it, but I think I've reached the end of my rope on this assignment. So, I'm going to call it a day. Thanks for reading through
	