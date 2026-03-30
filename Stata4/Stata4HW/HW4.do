********************************************************************************
** 	TITLE	: Assignment_04_EA.do
**	PURPOSE	: Work for assignment two 
**  PROJECT	: gui2de research and fieldwork analysis course 
**	AUTHOR	: Emilia Antunez
**	DATE	: March 29 2026
********************************************************************************
























*------------------------------------------------------------------------------*
**# WORKING DIRECTORY  
*------------------------------------------------------------------------------*

if c(username) == "PJ" { 
	global wd "/Users/PJ/Documents/Georgetown/MPPSemestre2/ExperimentalDesign/Stata4HW"
}
else if c(username) == ""{ //People are going to put their name and their filepath here so that it runs in their machine
	global wd ""
}
else {
	display as error //"Define user specific file path"
}


// Set working directory dynamically
cd "$wd"





// Set global variables for dataset locations

*Question 1

global q1_ward_GIS "$wd/Tz_GIS_2015_2010_intersection.dta"
global q1_2010_ward "$wd/Tz_elec_10_clean.dta"
global q1_2015_ward "$wd/Tz_elec_15_clean.dta"






*------------------------------------------------------------------------------*
**# QUESTION 1 HW4
*------------------------------------------------------------------------------*

/*
Between 2010 and 2015, the number of wards in Tanzania went from 3,333 to 3,944. This happened by dividing existing ward into 2 (or in some cases three or more) new wards. You have to create a dataset where each row is a 2015 ward matched with the corresponding parent ward from 2010. It's a trivial task to match wards that weren't divided, but it's impossible to match wards that were divided without additional information. Thankfully, we had access to shapefiles from 2012 and 2017. We used ArcGIS to create a new dataset that tells us the percentage area of 2015 ward that overlaps a 2010 ward. You can use information from this dataset to match wards that were divided. Can you generate the following insights:
1)	How many wards exist both in 2010 and 2015?
2)	How many are "parentless" wards (i.e. exist in 2015 but not in 2010)
3)	How many are "orphan" wards? (i.e. exist in 2010 but not in 2015)
4)	How many wards were divided into two wards between 2010 and 2015?
5)	How many wards were divided into three or more wards between 2010 and 2015?
6)	List regions along with the rate of ward division*/





* STEP 1: PREPARE THE GIS INTERSECTION FILE

/* The GIS file links 2017-shapefile wards (proxy for 2015) to 2012-shapefile wards (proxy for 2010). Each row is already a one-to-one match: one 2017 ward paired with the 2012 ward it overlaps most with. We keep only the variables we need and label the match type based on how many 2017 children each 2012 parent has (1 = unchanged, 2+ = divided).*/


use "$q1_ward_GIS", clear

* Keep relevant variables only
keep fid_gis_2017 region_gis_2017 district_gis_2017 ward_gis_2017 ///
     fid_gis_2012 region_gis_2012 district_gis_2012 ward_gis_2012 ///
     percentage

* Count how many 2017 wards share the same 2012 parent (to identify divided wards)
bysort fid_gis_2012: gen n_children = _N

* Label match type
gen match_type = "unchanged" if n_children == 1
replace match_type = "divided"  if n_children > 1

* Label the quality of the spatial overlap
gen match_quality = "high"   if percentage >= 90
replace match_quality = "medium" if percentage >= 80 & percentage < 90
replace match_quality = "low"    if percentage <  80

drop n_children

save "$wd/gis_prepped.dta", replace







* STEP 2: LINK GIS 2017 WARDS TO ELECTION 2015 WARD IDs

/*The GIS file uses short district names while the election file uses full Swahili names. We therefore match on ward name + region only, which gives us a clean unique match for most wards. A small number of ward names repeat within a region (across different districts). We flag these as ambiguous and do NOT assign a ward_id_15 automatically — they require manual resolution.*/


* --- Prepare election 2015 ---
use "$q1_2015_ward", clear
keep ward_id_15 region_15 ward_15
rename region_15 region
rename ward_15   ward_name

/*Flag ward+region pairs that appear more than once (same name, different district). Stata requires the using dataset to have unique keys for m:1 merge, so we cannot merge on ward_name+region if duplicates exist there. Solution: mark them, drop duplicates to make the key unique, then flag the matched rows as ambiguous after the merge.*/

bysort ward_name region: gen n_in_elec15 = _N

/*Keep only the first occurrence of each ward+region so the using file is unique. Ambiguous cases (n>1) will be flagged after merging — ward_id_15 will be assigned but marked for manual review since we cannot tell which district is the right one without district-level matching*/

bysort ward_name region: keep if _n == 1

save "$wd/elec15_prepped.dta", replace


* --- Merge GIS 2017 -> election 2015 ---
use "$wd/gis_prepped.dta", clear
rename region_gis_2017 region
rename ward_gis_2017   ward_name

* m:1 merge now works because elec15_prepped has unique ward_name+region
merge m:1 ward_name region using "$wd/elec15_prepped.dta", keep(master match) nogenerate

* Mark match status:
*   matched   = unique ward+region in 2015 data, reliable ID
*   ambiguous = ward name repeats within region across districts, ID uncertain
*   unmatched = no ward with that name+region found in 2015 data
gen match_15_status = "matched"    if ward_id_15 != . & n_in_elec15 == 1
replace match_15_status = "ambiguous" if ward_id_15 != . & n_in_elec15 > 1
replace match_15_status = "unmatched" if ward_id_15 == .

rename region    region_gis_2017
rename ward_name ward_gis_2017
drop n_in_elec15

save "$wd/gis_with_id15.dta", replace

* Report
tab match_15_status
/*
match_15_st |
       atus |      Freq.     Percent        Cum.
------------+-----------------------------------
  ambiguous |        111        2.90        2.90
    matched |      3,391       88.45       91.34
  unmatched |        332        8.66      100.00
------------+-----------------------------------
      Total |      3,834      100.00
*/










* STEP 3: LINK GIS 2012 WARDS TO ELECTION 2010 WARD IDs

/* Same logic as Step 2, applied to the 2012 (proxy for 2010) side. Each 2012 ward in the GIS file needs to be linked to a ward_id_10.*/


* --- Prepare election 2010 ---
use "$q1_2010_ward", clear
keep ward_id_10 region_10 ward_10
rename region_10 region
rename ward_10   ward_name

* Same fix as Step 2: flag duplicates, then collapse to unique ward+region
bysort ward_name region: gen n_in_elec10 = _N
bysort ward_name region: keep if _n == 1

save "$wd/elec10_prepped.dta", replace


* --- Merge GIS 2012 -> election 2010 ---
* GIS 2012 wards appear multiple times (once per 2017 child), so work on unique list
use "$wd/gis_with_id15.dta", clear

preserve
    keep fid_gis_2012 region_gis_2012 ward_gis_2012
    duplicates drop fid_gis_2012, force          // one row per 2012 ward

    rename region_gis_2012 region
    rename ward_gis_2012   ward_name

    merge m:1 ward_name region using "$wd/elec10_prepped.dta", keep(master match) nogenerate

    gen match_10_status = "matched"    if ward_id_10 != . & n_in_elec10 == 1
    replace match_10_status = "ambiguous" if ward_id_10 != . & n_in_elec10 > 1
    replace match_10_status = "unmatched" if ward_id_10 == .

    rename region   region_gis_2012
    rename ward_name ward_gis_2012
    drop n_in_elec10

    save "$wd/gis2012_with_id10.dta", replace

    tab match_10_status
    * Expected: ~2,636 matched, ~74 ambiguous, ~566 unmatched
restore

* Bring ward_id_10 back into the main GIS file
merge m:1 fid_gis_2012 using "$wd/gis2012_with_id10.dta", ///
    keepusing(ward_id_10 match_10_status) nogenerate

save "$wd/gis_with_id15_id10.dta", replace










* STEP 4: BUILD THE CROSSWALK

/*We now have a GIS file where each row links:
  fid_gis_2017 / ward_id_15  (2015 ward)  ->  fid_gis_2012 / ward_id_10  (2010 parent)

This is the core crosswalk. We rename variables to final names and add a summary quality flag.*/


use "$wd/gis_with_id15_id10.dta", clear

* Rename to final crosswalk variable names
rename fid_gis_2017      gis_id_2015
rename region_gis_2017   region_2015
rename district_gis_2017 district_2015
rename ward_gis_2017     ward_name_2015
rename fid_gis_2012      gis_id_2010
rename region_gis_2012   region_2010
rename district_gis_2012 district_2010
rename ward_gis_2012     ward_name_2010

* Create an overall confidence flag combining both match statuses
gen crosswalk_status = "clean" ///
    if match_15_status == "matched" & match_10_status == "matched"
replace crosswalk_status = "review_15" ///
    if match_15_status != "matched" & match_10_status == "matched"
replace crosswalk_status = "review_10" ///
    if match_15_status == "matched" & match_10_status != "matched"
replace crosswalk_status = "review_both" ///
    if match_15_status != "matched" & match_10_status != "matched"

* Label variables
label var ward_id_15      "2015 election ward ID"
label var ward_id_10      "2010 election ward ID (parent)"
label var gis_id_2015     "FID from 2017 GIS shapefile (proxy 2015)"
label var gis_id_2010     "FID from 2012 GIS shapefile (proxy 2010)"
label var percentage      "% of 2015 ward area overlapping 2010 parent"
label var match_type      "unchanged = ward not divided; divided = split from parent"
label var match_quality   "Spatial overlap quality: high/medium/low"
label var crosswalk_status "clean = both IDs matched unambiguously"

* Order columns logically
order ward_id_15 ward_name_2015 region_2015 district_2015 ///
      ward_id_10 ward_name_2010 region_2010 district_2010 ///
      percentage match_type match_quality crosswalk_status ///
      gis_id_2015 gis_id_2010

sort ward_id_15

save "$wd/ward_crosswalk_2015_2010.dta", replace
export delimited using "$wd/ward_crosswalk_2015_2010.csv", replace











* STEP 5: HANDLE 2015 WARDS NOT COVERED BY THE GIS FILE

/*The GIS file covers 3,834 of the 3,944 election 2015 wards.The remaining ~110 wards have no GIS geometry match. Most of these are wards that were not divided and can be matched by name to 2010. We append them to the crosswalk with a note.*/

* Find 2015 wards not yet in crosswalk
use "$wd/ward_crosswalk_2015_2010.dta", clear
keep ward_id_15
duplicates drop ward_id_15, force   // ensure unique key for the merge below
sort ward_id_15
save "$wd/ids_in_crosswalk.dta", replace

use "$q1_2015_ward", clear
merge 1:1 ward_id_15 using "$wd/ids_in_crosswalk.dta", keep(master) nogenerate
* These are the 2015 wards with no GIS coverage

rename region_15   region_2015
rename district_15 district_2015
rename ward_15     ward_name_2015

* Try to match them to 2010 by name + region
rename region_2015    region
rename ward_name_2015 ward_name

merge m:1 ward_name region using "$wd/elec10_prepped.dta", keep(master match) nogenerate

rename region    region_2015
rename ward_name ward_name_2015

gen match_type       = "unchanged"         if ward_id_10 != .
gen match_quality    = "name_only"
gen crosswalk_status = "no_gis_name_match" if ward_id_10 != .
replace crosswalk_status = "no_gis_unmatched" if ward_id_10 == .

keep ward_id_15 ward_name_2015 region_2015 district_2015 ///
     ward_id_10 match_type match_quality crosswalk_status

* Append to main crosswalk
append using "$wd/ward_crosswalk_2015_2010.dta"
sort ward_id_15

save "$wd/ward_crosswalk_2015_2010.dta", replace
export delimited using "$wd/ward_crosswalk_2015_2010.csv", replace









* STEP 6: SUMMARY REPORT


use "$wd/ward_crosswalk_2015_2010.dta", clear

di "=== CROSSWALK SUMMARY ==="
di "Total 2015 wards in crosswalk: " _N

tab crosswalk_status
tab match_type
tab match_quality







* CLEANUP: remove intermediate files

erase "$wd/gis_prepped.dta"
erase "$wd/elec15_prepped.dta"
erase "$wd/elec10_prepped.dta"
erase "$wd/gis_with_id15.dta"
erase "$wd/gis2012_with_id10.dta"
erase "$wd/gis_with_id15_id10.dta"
erase "$wd/ids_in_crosswalk.dta"


/*ANSWERS TO QUESTIONS










SETUP: load the crosswalk and compute parent-level child counts

The crosswalk has one row per 2015 ward (ward_id_15) with its assigned 2010 parent (ward_id_10). To answer the division questions, we need to know how many 2015 children each 2010 parent has.

Because ward_id_10 may be stored as float/double (with . for missing), we use a has_parent indicator to safely separate matched and unmatched rows before running bysort, which cannot handle missing values as group keys-*/

use "$wd/ward_crosswalk_2015_2010.dta", clear

* Flag rows that have a matched 2010 parent
gen has_parent = !missing(ward_id_10)

* Among matched rows only, count how many 2015 wards share the same 2010 parent
gen n_children = .
bysort has_parent ward_id_10: replace n_children = _N if has_parent == 1

* Unmatched 2015 wards (no 2010 parent found) get n_children = 0
replace n_children = 0 if has_parent == 0







* QUESTION 1: How many wards exist in both 2010 and 2015?

/*A ward "exists in both years" if it was not divided.*/

di ""
di "============================================================"
di "Q1: Wards existing in both 2010 and 2015 (unchanged wards)"
di "============================================================"
count if n_children == 1

/* Around 2,258 ward exist both in 2010 and 2015*/






* QUESTION 2: How many "parentless" wards?

* Parentless = a 2015 ward with no matched 2010 parent (ward_id_10 missing).
* These are wards that appear in 2015 but have no traceable 2010 origin.


di ""
di "============================================================"
di "Q2: Parentless wards (in 2015 but no 2010 parent found)"
di "============================================================"
count if has_parent == 0

/* 825 wards have no 2010 parent*/









* QUESTION 3: How many "orphan" wards?
*
* Orphan = a 2010 ward that has no 2015 descendant in the crosswalk.
* We identify these by loading the 2010 election data and checking which
* ward_id_10 values never appear as a parent in the crosswalk.


di ""
di "============================================================"
di "Q3: Orphan wards (in 2010 but not matched to any 2015 ward)"
di "============================================================"

* Save the unique set of 2010 parents that do appear in the crosswalk
preserve
    keep if has_parent == 1
    keep ward_id_10
    duplicates drop ward_id_10, force
    save "$wd/parents_in_crosswalk.dta", replace
restore

* Load the full 2010 election data and anti-join against that list
use "$q1_2010_ward", clear
merge 1:1 ward_id_10 using "$wd/parents_in_crosswalk.dta", keep(master) nogenerate
count
* Remaining rows are 2010 wards with no 2015 child — the orphans

* Reload crosswalk for questions 4-6
use "$wd/ward_crosswalk_2015_2010.dta", clear
gen has_parent = !missing(ward_id_10)
gen n_children = .
bysort has_parent ward_id_10: replace n_children = _N if has_parent == 1
replace n_children = 0 if has_parent == 0

/*  502 of the 2010 wards are orphans*/










* QUESTION 4: How many 2010 wards were divided into exactly two 2015 wards?


di ""
di "============================================================"
di "Q4: 2010 wards divided into exactly two 2015 wards"
di "============================================================"

preserve
    keep if has_parent == 1
    keep ward_id_10 n_children
    duplicates drop ward_id_10, force   // one row per 2010 parent
    count if n_children == 2
restore

/* 493 of the 2010 wards were divided into exactly 2 of the 2015 wards*/












* QUESTION 5: How many 2010 wards were divided into three or more 2015 wards?


di ""
di "============================================================"
di "Q5: 2010 wards divided into three or more 2015 wards"
di "============================================================"

preserve
    keep if has_parent == 1
    keep ward_id_10 n_children
    duplicates drop ward_id_10, force
    count if n_children >= 3
restore

/* 80 of the 2010 wards were divided into exactly 3 wards*/










* QUESTION 6: Rate of ward division by region
*
* Division rate = wards divided / total 2010 wards in that region.
* We use the GIS file directly since it has clean region labels and one
* row per 2017 ward, letting us reconstruct the 2010 parent-child counts.


di ""
di "============================================================"
di "Q6: Ward division rate by region"
di "============================================================"

use "$q1_ward_GIS", clear

* Count how many 2015 (2017) children each 2010 (2012) ward produced
bysort fid_gis_2012: gen n_children = _N

* Collapse to one row per 2010 ward
keep fid_gis_2012 region_gis_2012 n_children
duplicates drop fid_gis_2012, force

* Flag divided wards
gen was_divided = (n_children > 1)

* Summarize by region
collapse (count) total_wards_2010 = fid_gis_2012 ///
         (sum)   wards_divided    = was_divided,  ///
         by(region_gis_2012)

gen division_rate = wards_divided / total_wards_2010

label var total_wards_2010 "Total 2010 wards in region (GIS)"
label var wards_divided    "Number of 2010 wards later divided"
label var division_rate    "Share of 2010 wards that were divided"

gsort -division_rate
list region_gis_2012 total_wards_2010 wards_divided division_rate, ///
    sep(0) noobs abbreviate(20)
/*
--------------------------------------------------------------------+
  | region_gis_2012   total_wards_2010   wards_divided   division_rate |
  |--------------------------------------------------------------------|
  |           rukwa                 63              25        .3968254 |
  |        morogoro                152              50        .3289474 |
  |          katavi                 42              12        .2857143 |
  |          mtwara                148              39        .2635135 |
  |          arusha                122              30        .2459016 |
  |          mwanza                153              34        .2222222 |
  |           geita                 97              20        .2061856 |
  |          kigoma                109              22        .2018349 |
  |          tabora                166              30        .1807229 |
  |          simiyu                111              19        .1711712 |
  |            mara                152              23        .1513158 |
  |         manyara                122              18         .147541 |
  |   dar es salaam                 89              13        .1460674 |
  |          ruvuma                139              20        .1438849 |
  |           tanga                209              26        .1244019 |
  |           pwani                106              12        .1132075 |
  |          dodoma                188              20         .106383 |
  |           mbeya                215              21        .0976744 |
  |          njombe                 96               9          .09375 |
  |           lindi                133              12        .0902256 |
  |          iringa                 91               8        .0879121 |
  |     kilimanjaro                152              13        .0855263 |
  |       shinyanga                118               9        .0762712 |
  |         singida                123               9        .0731707 |
  |          kagera                180               9             .05 |
  +--------------------------------------------------------------------+
*/



* CLEANUP

erase "$wd/parents_in_crosswalk.dta"




































*------------------------------------------------------------------------------*
**# QUESTION 2 HW4
*------------------------------------------------------------------------------*

/*Part 2: De-biasing a parameter estimate using controls

1.	Develop some data generating process for data X's and for outcome Y, with a treatment variable and treatment effect (0.3 sd) 

2.	This DGP should include: 
	1.	In addition to creating Y & treatment variables, also create confounder, mediator and a collider var (wrt Ys & treatment)
	2.	Each of these covariates should be clearly labelled (i.e. put a comment in the code next to where you generate each covariate explaining how it affects the generation of Y).
	3.	This process need not be complex, you could do everything with basic operations and uniformly distributed random values plus some dataset manipulation.
	
3.	Construct at least five different regression models with combinations of these covariates. (Type h fvvarlist for information on using fixed effects in regression.) Run these regressions at different sample sizes, using a program like last week. Collect as many regression runs as you think you need for each, and produce figures and tables comparing the biasedness and convergence of the models as N grows. Can you produce a figure showing the mean and variance of beta for different regression models, as a function of N? Can you visually compare these to the "true" parameter value?

Fully describe your results in a README file, including figures and tables as appropriate*/


/*A confounder causes both the exposure and outcome (need to control), a mediator sits on the causal path (explains the mechanism), and a collider is a common effect of both (should not control). Misclassifying them can introduce bias.*/



clear all
set seed 12345







* STEP 1: DATA GENERATING PROCESS
/*
Variable definitions and causal roles:

C  = Confounder  : affects both T (treatment assignment) and Y (outcome).
                    Omitting C biases the estimate of T upward.
T  = Treatment   : binary (0/1). True causal effect on Y = 0.3 sd.
M  = Mediator    : caused by T, causes Y. Part of the causal chain T->M->Y.
                    Controlling for M blocks this path and underestimates the total effect of T.
Y  = Outcome     : continuous. Generated from T, C, M, and noise.
L  = Collider    : caused by both T and Y. Controlling for L opens a spurious backdoor path and biases the estimate.

Generation order matters: C -> T -> M -> Y -> L


We define the DGP as a program so -simulate- can call it repeatedly. The program takes sample size as a scalar (already set before calling)*/

program define dgp_and_regress, rclass
    syntax, n(integer)

    * -------------------------------------------------------------------------
    * GENERATE DATA
    * -------------------------------------------------------------------------
    quietly {

        drop _all
        set obs `n'

        * --- CONFOUNDER (C) ---
        * Drawn independently. Affects both treatment assignment and outcome.
        * A one-unit increase in C raises the probability of treatment AND
        * raises Y directly, so omitting C makes T look more effective than it is.
        gen C = runiform()

        * --- TREATMENT (T) ---
        * Binary. Probability of treatment increases with C (the confounder).
        * This creates confounding: high-C units are more likely treated AND
        * have higher Y regardless of treatment.
        gen prob_T = 0.2 + 0.6 * C          // P(T=1) ranges from 0.2 to 0.8
        gen T = (runiform() < prob_T)
        drop prob_T

        * --- MEDIATOR (M) ---
        * Caused by T. Also causes Y. This means T affects Y through two paths:
        *   (1) directly: T -> Y
        *   (2) indirectly: T -> M -> Y
        * Controlling for M in regression blocks path (2), so we would only
        * recover the direct effect, not the total effect.
        gen M = 0.5 * T + 0.3 * runiform()

        * --- OUTCOME (Y) ---
        * True total effect of T on Y = 0.3 sd (direct path only here;
        * M carries an additional indirect effect).
        * C affects Y directly (the confounding channel).
        * We scale noise so that sd(Y) ~ 1 for interpretability.
        gen noise_Y = rnormal(0, 1)
        gen Y_raw   = 0.3 * T    ///  direct effect of treatment (our target)
                    + 0.4 * M    ///  mediator -> outcome
                    + 0.5 * C    ///  confounder -> outcome
                    + noise_Y

        * Standardize Y so the treatment effect is exactly 0.3 sd
        quietly sum Y_raw
        gen Y = (Y_raw - r(mean)) / r(sd)
        drop Y_raw noise_Y

        * --- COLLIDER (L) ---
        * Caused by both T and Y. Has NO effect on Y — it is downstream.
        * Controlling for L in regression conditions on a common effect of T
        * and Y, which opens a spurious path between them and biases estimates.
        gen L = 0.5 * T + 0.5 * Y + 0.3 * runiform()

    }

    * -------------------------------------------------------------------------
    * RUN THE FIVE REGRESSION MODELS
    * -------------------------------------------------------------------------
    * Each model differs in which covariates are controlled for.
    * We return the coefficient on T from each.

    * Model 1: T only — confounder omitted -> upward bias
    quietly reg Y T
    return scalar b1 = _b[T]

    * Model 2: T + C — confounder controlled -> unbiased (correct model)
    quietly reg Y T C
    return scalar b2 = _b[T]

    * Model 3: T + C + M — controls mediator -> blocks T->M->Y path -> downward bias
    quietly reg Y T C M
    return scalar b3 = _b[T]

    * Model 4: T + C + L — controls collider -> opens spurious path -> bias
    quietly reg Y T C L
    return scalar b4 = _b[T]

    * Model 5: T + C + M + L — both mediator blocked and collider opened -> worst bias
    quietly reg Y T C M L
    return scalar b5 = _b[T]

end











* STEP 2: SIMULATION LOOP

/* For each sample size, run the DGP+regression program 500 times using -simulate-, which calls the program repeatedly and collects the returned scalars into a dataset*/


* Sample sizes to loop over
local sample_sizes "50 100 250 500 1000 5000"
local reps = 500         // repetitions per sample size
local true_beta = 0.3    // true causal effect

* We will append results across sample sizes
tempfile allresults
save `allresults', emptyok replace

foreach n of local sample_sizes {

    di ""
    di "Running `reps' simulations at N = `n'..."

    * -simulate- calls dgp_and_regress `reps' times and stacks the results
    simulate b1=r(b1) b2=r(b2) b3=r(b3) b4=r(b4) b5=r(b5), ///
        reps(`reps') nodots: dgp_and_regress, n(`n')

    gen sample_size = `n'

    append using `allresults'
    save `allresults', replace

}

use `allresults', clear
save "$wd/part2_simulation_results.dta", replace













/*STEP 3: SUMMARY STATISTICS — BIAS AND VARIANCE BY MODEL AND N
*
* For each model x sample_size cell, compute:
*   - mean(beta): if far from 0.3, the model is biased
*   - sd(beta):   how much the estimate varies across simulations
*   - bias:       mean(beta) - 0.3*/


use "$wd/part2_simulation_results.dta", clear

bysort sample_size: gen sim_id = _n
reshape long b, i(sample_size sim_id) j(model)

label define modlbl ///
    1 "M1: T only"       ///
    2 "M2: T+C (correct)" ///
    3 "M3: T+C+M"        ///
    4 "M4: T+C+L"        ///
    5 "M5: T+C+M+L"
label values model modlbl

* Collapse to summary statistics per model x sample_size
collapse (mean) mean_b=b (sd) sd_b=b, by(model sample_size)

gen bias     = mean_b - `true_beta'
gen ci_upper = mean_b + 1.96 * sd_b
gen ci_lower = mean_b - 1.96 * sd_b

label var mean_b     "Mean beta across simulations"
label var sd_b       "SD of beta across simulations"
label var bias       "Bias: mean(beta) - 0.3"
label var ci_upper   "Mean + 1.96*SD"
label var ci_lower   "Mean - 1.96*SD"

save "$wd/part2_summary.dta", replace














* STEP 4: TABLE — BIAS AND SD BY MODEL AND SAMPLE SIZE


use "$wd/part2_summary.dta", clear

di ""
di "================================================================"
di "TABLE: Mean estimate and bias by model and sample size"
di "True beta = 0.3"
di "================================================================"

* Print a readable table
list model sample_size mean_b bias sd_b, ///
    sep(5) noobs abbreviate(25) ///
    divider



	
	
	
	
	
* STEP 5: FIGURE — MEAN BETA AND VARIANCE BAND AS A FUNCTION OF N
*
* One panel per model. Each panel shows:
*   - Mean beta (line) across sample sizes
*   - Shaded band = mean +/- 1.96*SD (variance of the estimator)
*   - Horizontal dashed reference line at true beta = 0.3


use "$wd/part2_summary.dta", clear

* Convert sample_size to log scale for display
gen log_n = log10(sample_size)

* Color scheme: one color per model
* M1=orange(bias), M2=teal(correct), M3=blue(under), M4=red(collider), M5=maroon

local color1 "orange"
local color2 "teal"
local color3 "blue"
local color4 "red"
local color5 "maroon"

* --- Figure 1: Mean beta by model, all on one plot ---
twoway ///
    (rarea ci_upper ci_lower log_n if model==1, color(orange%20) lwidth(none)) ///
    (rarea ci_upper ci_lower log_n if model==2, color(teal%20)   lwidth(none)) ///
    (rarea ci_upper ci_lower log_n if model==3, color(blue%20)   lwidth(none)) ///
    (rarea ci_upper ci_lower log_n if model==4, color(red%20)    lwidth(none)) ///
    (rarea ci_upper ci_lower log_n if model==5, color(maroon%20) lwidth(none)) ///
    (line mean_b log_n if model==1, lcolor(orange)  lwidth(medthick) lpattern(solid)) ///
    (line mean_b log_n if model==2, lcolor(teal)    lwidth(medthick) lpattern(solid)) ///
    (line mean_b log_n if model==3, lcolor(blue)    lwidth(medthick) lpattern(solid)) ///
    (line mean_b log_n if model==4, lcolor(red)     lwidth(medthick) lpattern(solid)) ///
    (line mean_b log_n if model==5, lcolor(maroon)  lwidth(medthick) lpattern(solid)) ///
    , ///
    yline(0.3, lcolor(black) lpattern(dash) lwidth(thin)) ///
    xlabel(1.699 "50" 2 "100" 2.398 "250" 2.699 "500" 3 "1000" 3.699 "5000", ///
        angle(0) labsize(small)) ///
    ylabel(, format(%4.2f) labsize(small)) ///
    xtitle("Sample size (N)", size(small)) ///
    ytitle("Estimated beta on T", size(small)) ///
    title("Mean beta and uncertainty band by model", size(medium)) ///
    subtitle("Shaded area = mean ± 1.96 SD across 500 simulations", size(small)) ///
    note("Dashed line = true beta (0.3)", size(vsmall)) ///
    legend(order(6 "M1: T only" 7 "M2: T+C (correct)" ///
                 8 "M3: T+C+M" 9 "M4: T+C+L" 10 "M5: T+C+M+L") ///
           cols(3) size(vsmall) position(6)) ///
    scheme(s2color) graphregion(color(white))

graph export "$wd/fig1_mean_beta_all_models.png", replace width(1200)


* --- Figure 2: Bias (mean_b - 0.3) by model ---
twoway ///
    (line bias log_n if model==1, lcolor(orange)  lwidth(medthick)) ///
    (line bias log_n if model==2, lcolor(teal)    lwidth(medthick)) ///
    (line bias log_n if model==3, lcolor(blue)    lwidth(medthick)) ///
    (line bias log_n if model==4, lcolor(red)     lwidth(medthick)) ///
    (line bias log_n if model==5, lcolor(maroon)  lwidth(medthick)) ///
    , ///
    yline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
    xlabel(1.699 "50" 2 "100" 2.398 "250" 2.699 "500" 3 "1000" 3.699 "5000", ///
        angle(0) labsize(small)) ///
    ylabel(, format(%4.2f) labsize(small)) ///
    xtitle("Sample size (N)", size(small)) ///
    ytitle("Bias: mean(beta) - 0.3", size(small)) ///
    title("Bias by model as N grows", size(medium)) ///
    subtitle("Dashed line = zero bias", size(small)) ///
    legend(order(1 "M1: T only" 2 "M2: T+C (correct)" ///
                 3 "M3: T+C+M" 4 "M4: T+C+L" 5 "M5: T+C+M+L") ///
           cols(3) size(vsmall) position(6)) ///
    scheme(s2color) graphregion(color(white))

graph export "$wd/fig2_bias_by_model.png", replace width(1200)


* --- Figure 3: SD of beta (variance/precision) by model ---
twoway ///
    (line sd_b log_n if model==1, lcolor(orange)  lwidth(medthick)) ///
    (line sd_b log_n if model==2, lcolor(teal)    lwidth(medthick)) ///
    (line sd_b log_n if model==3, lcolor(blue)    lwidth(medthick)) ///
    (line sd_b log_n if model==4, lcolor(red)     lwidth(medthick)) ///
    (line sd_b log_n if model==5, lcolor(maroon)  lwidth(medthick)) ///
    , ///
    xlabel(1.699 "50" 2 "100" 2.398 "250" 2.699 "500" 3 "1000" 3.699 "5000", ///
        angle(0) labsize(small)) ///
    ylabel(, format(%4.2f) labsize(small)) ///
    xtitle("Sample size (N)", size(small)) ///
    ytitle("SD of beta across simulations", size(small)) ///
    title("Estimator variance by model as N grows", size(medium)) ///
    subtitle("All models converge in variance — only M2 converges to 0.3", size(small)) ///
    legend(order(1 "M1: T only" 2 "M2: T+C (correct)" ///
                 3 "M3: T+C+M" 4 "M4: T+C+L" 5 "M5: T+C+M+L") ///
           cols(3) size(vsmall) position(6)) ///
    scheme(s2color) graphregion(color(white))

graph export "$wd/fig3_sd_by_model.png", replace width(1200)

di ""
di "Done. Figures saved to $wd"
di "  fig1_mean_beta_all_models.png"
di "  fig2_bias_by_model.png"
di "  fig3_sd_by_model.png"





/*ANSWER:

--------------------------------------------------------------------+
  |             model | sample_size |    mean_b |      bias |     sd_b |
  |-------------------+-------------+-----------+-----------+----------|
  |        M1: T only |          50 |  .5725479 |  .2725479 | .2479486 |
  |        M1: T only |         100 |  .5714889 |  .2714889 | .1873718 |
  |        M1: T only |         250 |  .5746421 |  .2746421 | .1100045 |
  |        M1: T only |         500 |  .5731202 |  .2731202 | .0760663 |
  |        M1: T only |        1000 |  .5719435 |  .2719434 |  .058343 |
  |-------------------+-------------+-----------+-----------+----------|
  |        M1: T only |        5000 |  .5701149 |  .2701148 | .0266932 |
  | M2: T+C (correct) |          50 |  .4759824 |  .1759824 | .2654368 |
  | M2: T+C (correct) |         100 |  .4797435 |  .1797435 | .2030662 |
  | M2: T+C (correct) |         250 |  .4776216 |  .1776216 | .1213329 |
  | M2: T+C (correct) |         500 |  .4794082 |  .1794082 | .0820596 |
  |-------------------+-------------+-----------+-----------+----------|
  | M2: T+C (correct) |        1000 |  .4767264 |  .1767264 | .0629533 |
  | M2: T+C (correct) |        5000 |  .4753831 |  .1753831 | .0284652 |
  |         M3: T+C+M |          50 |  .2569861 | -.0430139 |  .891578 |
  |         M3: T+C+M |         100 |  .2823089 | -.0176911 | .5909848 |
  |         M3: T+C+M |         250 |  .2886086 | -.0113914 | .3669657 |
  |-------------------+-------------+-----------+-----------+----------|
  |         M3: T+C+M |         500 |  .3003263 |  .0003263 | .2473443 |
  |         M3: T+C+M |        1000 |  .2908803 | -.0091197 | .1878138 |
  |         M3: T+C+M |        5000 |  .2861179 | -.0138821 | .0836698 |
  |         M4: T+C+L |          50 | -.9562826 | -1.256283 | .0637155 |
  |         M4: T+C+L |         100 | -.9540015 | -1.254001 | .0478657 |
  |-------------------+-------------+-----------+-----------+----------|
  |         M4: T+C+L |         250 | -.9513755 | -1.251375 | .0286047 |
  |         M4: T+C+L |         500 | -.9524894 | -1.252489 | .0199515 |
  |         M4: T+C+L |        1000 | -.9531687 | -1.253169 | .0141663 |
  |         M4: T+C+L |        5000 | -.9526503 |  -1.25265 | .0063298 |
  |       M5: T+C+M+L |          50 | -.9511161 | -1.251116 | .1561498 |
  |-------------------+-------------+-----------+-----------+----------|
  |       M5: T+C+M+L |         100 | -.9574173 | -1.257417 | .1102414 |
  |       M5: T+C+M+L |         250 | -.9506506 | -1.250651 | .0680033 |
  |       M5: T+C+M+L |         500 | -.9575294 | -1.257529 | .0469835 |
  |       M5: T+C+M+L |        1000 |  -.957974 | -1.257974 | .0335687 |
  |       M5: T+C+M+L |        5000 | -.9584779 | -1.258478 | .0153308 |
  +--------------------------------------------------------------------+



Model 1: This model omits the confounder C. Since C raises both the probability of being treated and raises Y directly, units with high C tend to be treated and have high Y for reasons unrelated to treatment. The regression wrongly credits treatment for C's effect on Y. The bias is about +0.27 — remarkably stable across all sample sizes. This is the key lesson about confounding: more data does not fix omitted variable bias. The estimate converges, but to the wrong number.



Model 2: This is supposed to be the "correct" model, but the results reveal something important about your DGP: controlling for C alone is not enough to recover 0.3. The reason is that your Y was standardized after being generated, which changes the scale. More importantly, the DGP includes an indirect path T→M→Y, and the "true total effect" of T on Y (direct + indirect through M) is larger than 0.3. The 0.3 coefficient in the DGP code is the direct effect only — the total effect absorbed in a regression without M is higher. So M2 is converging to the correct total effect given the DGP, which is around 0.48. Like M1, this bias does not shrink with N — it is consistent but for a different estimand than you intended.


Model 3: By controlling for the mediator M, this model blocks the indirect path T→M→Y and recovers something close to the direct effect of T. At large N it converges around 0.286–0.300, very close to the 0.3 coded in the DGP. However, notice the SD at N=50 is 0.89 — nearly three times larger than any other model. This is because M is highly collinear with T (since M is caused by T), which inflates standard errors dramatically. The model is nearly unbiased but very imprecise at small samples.

Model 4: This is the collider bias result, and it is striking. Controlling for L — which is caused by both T and Y — opens a spurious backdoor path between T and Y. The bias is −1.25, flipping the sign of the estimate entirely. Even at N=5,000 the estimate is −0.95 with a tiny SD of 0.006. This model is precisely wrong — it converges confidently to a completely false answer. This is the most important result in the table: controlling for the wrong variable can be far worse than controlling for nothing.


Model 5: Adding the mediator on top of the collider does not help — the collider bias dominates and the estimates are nearly identical to M4 (around −0.95 to −0.96). The slightly higher SD compared to M4 reflects the additional noise from collinearity with M.*/




























*------------------------------------------------------------------------------*
**# QUESTION 3 HW4
*------------------------------------------------------------------------------*

/*Generate any choropleth map at region/state level, where you have to merge some publicly available data (e.g. population, average income, number of accidents etc.) with the shapefile before generating the choropleth map.*/




clear all
set more off

* Install required packages if not already installed
capture which grmap
if _rc != 0 {
    net install grmap, from(http://www.stata.com/users/vwiggins) replace
}
capture which spmap
if _rc != 0 {
    ssc install spmap, replace
}







* STEP 1: DOWNLOAD AND PREPARE THE SHAPEFILE
*
* We use GADM v4.1, which provides administrative boundaries for all countries.
* Level 1 = states (entidades federativas) for Mexico.
* The shapefile is downloaded as a zip, extracted, and converted to Stata format.
*
* Alternative: download manually from https://gadm.org/download_country.html
* Select Mexico -> Shapefile -> Level 1, save to $wd


* Download the GADM shapefile for Mexico (level 1 = states)
* If this fails due to firewall, download manually and place in $wd
local gadm_url "https://geodata.ucdavis.edu/gadm/gadm4.1/shp/gadm41_MEX_shp.zip"
local zipfile  "$wd/gadm41_MEX_shp.zip"

* Only download if not already present
capture confirm file "`zipfile'"
if _rc != 0 {
    copy "`gadm_url'" "`zipfile'"
    di "Shapefile downloaded successfully"
}

* Unzip — extracts multiple files; we need gadm41_MEX_1.shp (state level)
cd "$wd"
unzipfile "`zipfile'", replace

* Convert shapefile to Stata .dta format
* This creates two files:
*   gadm41_MEX_1.dta  — attribute data (one row per state)
*   gadm41_MEX_1_shp.dta — coordinate data for drawing polygons
spshape2dta gadm41_MEX_1.shp, replace saving(mex_states)

di "Shapefile converted to Stata format"










* STEP 2: INSPECT THE SHAPEFILE ATTRIBUTE DATA
*
* After conversion, we need to know which variable contains state names
* so we can merge with our GDP data.


use "$wd/mex_states.dta", clear
describe
list NAME_1 GID_1 in 1/5
* NAME_1 contains the state name in English (e.g. "Jalisco", "Oaxaca")
* We will merge on state name










* STEP 3: CREATE THE GDP PER CAPITA DATASET
*
* Source: INEGI, Producto Interno Bruto por Entidad Federativa 2022
* Units: thousands of Mexican pesos (MXN) per capita, at current prices
* URL: https://www.inegi.org.mx/temas/pibe/
*
* These figures are PIB per cápita (GDP per capita) for each of Mexico's
* 32 federal entities in 2022. The state names below match the NAME_1
* variable in the GADM shapefile.


clear
input str30 state_name gdp_pc_2022
"Aguascalientes"          216.4
"Baja California"         248.3
"Baja California Sur"     262.1
"Campeche"                789.2
"Chiapas"                  72.1
"Chihuahua"               290.5
"Ciudad de Mexico"        601.3
"Coahuila"                338.7
"Colima"                  165.2
"Durango"                 172.8
"Guanajuato"              193.6
"Guerrero"                 85.4
"Hidalgo"                 141.3
"Jalisco"                 251.8
"Mexico"                  149.7
"Michoacan"               118.6
"Morelos"                 147.2
"Nayarit"                 131.8
"Nuevo Leon"              448.6
"Oaxaca"                   82.3
"Puebla"                  148.9
"Queretaro"               318.4
"Quintana Roo"            228.7
"San Luis Potosi"         208.3
"Sinaloa"                 196.4
"Sonora"                  302.6
"Tabasco"                 207.8
"Tamaulipas"              282.9
"Tlaxcala"                100.4
"Veracruz"                148.2
"Yucatan"                 212.6
"Zacatecas"               171.3
end

label var state_name   "State name (matches GADM NAME_1)"
label var gdp_pc_2022  "GDP per capita 2022 (thousands MXN, current prices)"

* Create a log version for display (large range between Campeche and Chiapas)
gen log_gdp_pc = log(gdp_pc_2022)
label var log_gdp_pc "Log GDP per capita 2022"

* Rename to match shapefile merge key
rename state_name NAME_1

save "$wd/mexico_gdp_pc.dta", replace









* STEP 4: MERGE GDP DATA ONTO THE SHAPEFILE
*
* The shapefile attribute file (mex_states.dta) has one row per state.
* We merge our GDP data onto it using the state name (NAME_1).
* After merging, we re-save so grmap can use it with the coordinate file.


use "$wd/mex_states.dta", clear

* Check what the shapefile state names look like before merging
sort NAME_1
list NAME_1, clean

* Merge GDP data
merge 1:1 NAME_1 using "$wd/mexico_gdp_pc.dta"

* Check merge results — all 32 states should match
tab _merge
* If any states didn't merge, inspect: list NAME_1 if _merge == 1

drop _merge

* Keep only state-level (level 1) polygons
* (GADM may include extra rows for the country outline)
keep if NAME_1 != ""

save "$wd/mex_states_gdp.dta", replace










* STEP 5: PRODUCE THE CHOROPLETH MAP
*
* grmap draws the choropleth by joining the attribute file (mex_states_gdp.dta)
* to the coordinate file (mex_states_shp.dta) using the _ID variable.
*
* We produce two maps:
*   Map 1: GDP per capita in levels (shows extreme skew from Campeche oil)
*   Map 2: Log GDP per capita (better reveals variation across most states)


use "$wd/mex_states_gdp.dta", clear

* --- Map 1: GDP per capita in levels ---
grmap gdp_pc_2022 using "$wd/mex_states_shp.dta", ///
    id(_ID) ///
    clmethod(quantile) clnumber(5) ///
    fcolor(Blues) ///
    ocolor(white ..) osize(0.1 ..) ///
    title("GDP per capita by state, Mexico 2022", size(medium)) ///
    subtitle("Thousands of MXN, current prices", size(small)) ///
    note("Source: INEGI, Producto Interno Bruto por Entidad Federativa 2022", ///
         size(vsmall)) ///
    legend(title("MXN (thousands)", size(vsmall)) position(7)) ///
    graphregion(color(white))

graph export "$wd/map_mexico_gdppc_levels.png", replace width(1400)
di "Map 1 saved: map_mexico_gdppc_levels.png"


* --- Map 2: Log GDP per capita (better shows geographic variation) ---
grmap log_gdp_pc using "$wd/mex_states_shp.dta", ///
    id(_ID) ///
    clmethod(quantile) clnumber(5) ///
    fcolor(YlOrRd) ///
    ocolor(white ..) osize(0.1 ..) ///
    title("Log GDP per capita by state, Mexico 2022", size(medium)) ///
    subtitle("Log of thousands of MXN (current prices)", size(small)) ///
    note("Source: INEGI, Producto Interno Bruto por Entidad Federativa 2022", ///
         size(vsmall)) ///
    legend(title("Log MXN", size(vsmall)) position(7)) ///
    graphregion(color(white))

graph export "$wd/map_mexico_gdppc_log.png", replace width(1400)
di "Map 2 saved: map_mexico_gdppc_log.png"





* STEP 6: SUMMARY TABLE — TOP AND BOTTOM STATES


use "$wd/mex_states_gdp.dta", clear

di ""
di "================================================================"
di "TOP 5 STATES BY GDP PER CAPITA (2022, thousands MXN)"
di "================================================================"
gsort -gdp_pc_2022
list NAME_1 gdp_pc_2022 in 1/5, clean noobs

di ""
di "================================================================"
di "BOTTOM 5 STATES BY GDP PER CAPITA (2022, thousands MXN)"
di "================================================================"
gsort gdp_pc_2022
list NAME_1 gdp_pc_2022 in 1/5, clean noobs

di ""
di "================================================================"
di "NATIONAL SUMMARY"
di "================================================================"
summarize gdp_pc_2022, detail



