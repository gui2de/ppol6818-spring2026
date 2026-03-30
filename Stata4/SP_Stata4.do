****************************************************
* Stata 4
* Stephanie Petrov
*****************************************************

clear
cd /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata4/data

******************************************************************


* Part 1: Fuzzy Matching


******************************************************************


********************************************************************
*STEP 1: Identify ward counts in each dataset for 2010 and 2015*****
********************************************************************

use Tz_elec_10_clean.dta, clear
count //3333 wards in 2010

use Tz_elec_15_clean.dta, clear
count // 3,944 wards in 2015

********************************************************************
*STEP 2: Combine region, district, and ward in the GIS file to merge
********************************************************************

use Tz_GIS_2015_2010_intersection, clear
gen id_2012 = region_gis_2012 + "_" + district_gis_2012 + "_" + ward_gis_2012
gen id_2017 = region_gis_2017 + "_" + district_gis_2017 + "_" + ward_gis_2017

keep region_gis_2017 district_gis_2017 ward_gis_2017 ///
     region_gis_2012 district_gis_2012 ward_gis_2012 ///
     percentage id_2017 id_2012
	 
label variable ward_gis_2017     "Ward name 2017 (2015)"
label variable ward_gis_2012     "Ward name 2012 (2010)"
label variable region_gis_2017   "Region (2017)"
label variable district_gis_2017 "District (2017)"
label variable region_gis_2012   "Region (2012)"
label variable district_gis_2012 "District (2012)"
label variable percentage        "% of 2017 ward area from 2012 parent ward"
	 
save Tz_GIS_combined.dta, replace

**********************************************************************************
*STEP 3: Combine region, district, and ward in election datasets, check duplicates
**********************************************************************************

use Tz_elec_10_clean.dta, clear
gen id_2010 = region_10 + "_" + district_10 + "_" + ward_10
save Tz_elec_10_clean_new.dta, replace
duplicates report id_2010 //3333

use Tz_elec_15_clean.dta, clear
gen id_2015 = region_15 + "_" + district_15 + "_" + ward_15
save Tz_elec_15_clean_new.dta, replace
duplicates report id_2015 //3944

********************************************************************
*STEP 4: Prepare for merging
********************************************************************

use Tz_GIS_combined.dta, clear
rename ward_gis_2017  ward_15
rename region_gis_2017  region_15
rename district_gis_2017 district_15

drop district_15 //too different across datasets to merge effectively
bysort region_15 ward_15 (percentage): keep if _n == _N
duplicates report region_15 ward_15
save Tz_combined_formerge.dta, replace

********************************************************************
*STEP 5: Merge 2015 election data with the combined GIS database
********************************************************************
use Tz_elec_15_clean_new.dta, clear
merge m:1 region_15 ward_15 using Tz_combined_formerge.dta
tab _merge // 3,504 matched

drop if _merge==2
gen gis_matched = (_merge == 3)
label variable gis_matched "1 = matched via GIS to 2010 parent ward"
drop _merge

keep id_2015 region_15 district_15 ward_15 ///
     ward_gis_2012 region_gis_2012 ///
     percentage gis_matched

rename ward_gis_2012 ward_2010_parent
rename region_gis_2012 region_2010_parent
rename percentage pct_area_from_parent
tab gis_matched
save Tz_combined_wards.dta, replace

********************************************************************
*1). How many wards exist both in 2010 and 2015?
********************************************************************

use Tz_combined_wards.dta, clear
count if gis_matched == 1 & pct_area_from_parent >=95 
//2,325 wards existed in both 2010 and 2015. The 95% threshold helps account for slight variabilities.

********************************************************************
*(2). How many are "parentless" wards (i.e. exist in 2015 but not in 2010)?
********************************************************************

count if gis_matched == 0 
//440 wards are "parentless" and did not exist in 2010. Due to data limitations (differences between the election datasets and the GIS datasets that constrained our ability to merge by district), some of these wards may not necessarily be new wards but other wards that could not be matched.

********************************************************************
*(3). How many are "orphan" wards? (i.e. exist in 2010 but not in 2015)?
********************************************************************

use Tz_combined_wards.dta, clear
keep ward_2010_parent region_2010_parent
drop if missing(ward_2010_parent)
duplicates drop
rename ward_2010_parent ward_10
rename region_2010_parent region_10
save matched_parents.dta, replace

use Tz_elec_10_clean_new.dta, clear
merge m:1 region_10 ward_10 using matched_parents.dta
tab _merge
count if _merge==1 
//746 wards exist in 2010 but not matched as a 2015 ward.

********************************************************************
*(4) How many wards were divided into two wards between 2010 and 2015?
********************************************************************

use Tz_combined_formerge.dta, clear
* Count how many 2015 wards each 2012 ward created
bysort ward_gis_2012 region_15 (percentage): gen n_newward= _N
bysort ward_gis_2012 region_15: keep if _n == 1
count if n_newward == 2 
//461 wards were divided into two wards between 2010 and 2015.

********************************************************************
*(5)	How many wards were divided into three or more wards between 2010 and 2015?
********************************************************************

count if n_newward >=3 
//37 wards were divided into three or more wards between 2010 and 2015.

********************************************************************
*(6) List regions along with the rate of ward division.
********************************************************************

gen was_divided = (n_newward >=2)
collapse (count) total_wards = was_divided ///
	(sum) n_divided = was_divided, ///
	by (region_15)
	
gen division_rate = round((n_divided / total_wards) * 100, 0.1)
gsort -division_rate
list region_15 total_wards n_divided division_rate, separator (0) abbreviate(20)





******************************************************************


* Part 2: De-biasing a parameter estimate using controls


******************************************************************





*******************************************************************
*(1) Develop some data generating process for data X's and for outcome Y,
*with a treatment variable and treatment effect (0.3 sd). 
*******************************************************************


clear
set seed 32926
set obs 10000

*Everyone is randomly assigned a gpa.
gen gpa = runiform(3, 4)

*Treatment - if your gpa is above a 3.3, you pass.				
gen treat = (gpa >= 3.3) 	

*If your gpa is above 3.3, you graduate. if your gpa is below 3.3, you have a 50% chance of graduating. If you have a gpa above 3.3, you have a 80% chance of graduating. Treatment effect is 0.3.
gen graduated = treat
replace graduated = (runiform(0,1) < 0.5) if treat==0
replace graduated = (runiform(0,1)<0.8) if treat==1 

save gpa_pass.dta, replace

*******************************************************************
*(2)This DGP should include a confounder, mediator and a collider variable.
*******************************************************************

*******************************************************************
*Confounder: Influences both X and Y. 
*Collider: Influenced BY both X and Y. 
*Mediator: Influenced by X, and influences Y. 
*******************************************************************

gen attendance = (rnormal(0,1)>0)
*Confounder variable: Influences both gpa and graduation rate. Attendance impacts both gpa and graduation prospects.

gen honors = (0.5 * treat + rnormal(0,1)>0)
*Mediator variable: Sits on the causal path. Caused by gpa and impacts graduation rates. Students with certain gpas are invited to participate in the school's honors society, which gives them access to networking and extracurricular opportunities that impacts graduation rate. (Gpa is not a requirement to participate in the honors society, though, so some students with lower gpas may still be represented in this variable.)

gen employment = (0.5 * treat + 0.5 * graduated + rnormal(0,1) > 0)
*Collider variable: influenced by both gpa and graduation rate. Doesn't impact graduation rate. A student's gpa and whether or not they graduated could impact their ability to find a job post-graduation.

save gpa_pass.dta, replace


**********************************************************************************************
*(3) Construct at least five different regression models with combinations of these covariates. 

*Run these regressions at different sample sizes, using a program like last week. 

*Collect as many regression runs as you think you need for each, and produce figures and tables comparing the biasedness and convergence of the models as N grows. 

*Can you produce a figure showing the mean and variance of beta for different regression models, as a function of N? 

*Can you visually compare these to the "true" parameter value?
**********************************************************************************************

//Using sample sizes of 100, 500, 1000, 5000, 10000

clear
set seed 32926

capture program drop grad
program define grad, rclass
syntax, n(integer)


use gpa_pass.dta, clear
sample `n', count

**********************************
*Model 1: No Additional Covariates
**********************************

reg graduated treat
matrix table1 = r(table)
return scalar sem_gpa1 = _se[treat]
return scalar beta_gpa1 = _b[treat]
return scalar pval_gpa1 = table1[4, 1]
return scalar ci_lower1 = table1[5, 1]
return scalar ci_higher1 = table1[6, 1]
	
	
**********************************
*Model 2: Confounder Variable
**********************************

reg graduated treat attendance
matrix table2 = r(table)
return scalar sem_gpa2 = _se[treat]
return scalar beta_gpa2 = _b[treat]
return scalar pval_gpa2 = table2[4, 1]
return scalar ci_lower2 = table2[5, 1]
return scalar ci_higher2 = table2[6, 1]

**********************************
*Model 3: Collider Variable
**********************************

reg graduated treat employment
matrix table3 = r(table)
return scalar sem_gpa3 = _se[treat]
return scalar beta_gpa3 = _b[treat]
return scalar pval_gpa3 = table3[4, 1]
return scalar ci_lower3 = table3[5, 1]
return scalar ci_higher3 = table3[6, 1]


**********************************
*Model 4: Mediator Variable
**********************************

reg graduated treat honors
matrix table4 = r(table)
return scalar sem_gpa4 = _se[treat]
return scalar beta_gpa4 = _b[treat]
return scalar pval_gpa4 = table4[4, 1]
return scalar ci_lower4 = table4[5, 1]
return scalar ci_higher4 = table4[6, 1]

**********************************
*Model 5: Confounder + Mediator
**********************************

reg graduated treat attendance honors
matrix table5 = r(table)
return scalar sem_gpa5 = _se[treat]
return scalar beta_gpa5 = _b[treat]
return scalar pval_gpa5 = table5[4, 1]
return scalar ci_lower5 = table5[5, 1]
return scalar ci_higher5 = table5[6, 1]

end

foreach n in 100 500 1000 5000 10000 {
	simulate ///
	beta_gpa1 = r(beta_gpa1) sem_gpa1=r(sem_gpa1) pval_gpa1=r(pval_gpa1) ci_lower1=r(ci_lower1) ci_higher1=r(ci_higher1) ///
	beta_gpa2 = r(beta_gpa2) sem_gpa2=r(sem_gpa2) pval_gpa2=r(pval_gpa2) ci_lower2=r(ci_lower2) ci_higher2=r(ci_higher2) ///
	beta_gpa3 = r(beta_gpa3) sem_gpa3=r(sem_gpa3) pval_gpa3=r(pval_gpa3) ci_lower3=r(ci_lower3) ci_higher3=r(ci_higher3) ///
	beta_gpa4 = r(beta_gpa4) sem_gpa4=r(sem_gpa4) pval_gpa4=r(pval_gpa4) ci_lower4=r(ci_lower4) ci_higher4=r(ci_higher4) ///
	beta_gpa5 = r(beta_gpa5) sem_gpa5=r(sem_gpa5) pval_gpa5=r(pval_gpa5) ci_lower5=r(ci_lower5) ci_higher5=r(ci_higher5), ///
	reps(500) seed(32926): grad, n(`n')
	save sim_n`n'.dta, replace
	
}


foreach n in 100 500 1000 5000 10000 {
	use sim_n`n'.dta, clear
	capture drop n
	gen n = `n'
	save sim_n`n'.dta,replace
}

use sim_n100.dta, clear
foreach n in 500 1000 5000 10000 {
	append using sim_n`n'.dta
}

keep beta_gpa1 beta_gpa2 beta_gpa3 beta_gpa4 beta_gpa5 sem_gpa1 sem_gpa2 sem_gpa3 sem_gpa4 sem_gpa5 ci_lower1 ci_lower2 ci_lower3 ci_lower4 ci_lower5 ci_higher1 ci_higher2 ci_higher3 ci_higher4 ci_higher5 n
gen rep = _n
reshape long beta_gpa sem_gpa ci_lower ci_higher, i(rep n) j(model)

graph box beta_gpa*, over(model) over(n) ///
	title("Figure 1: Distribution of Beta by Regression Model and Sample Size") ///
	ytitle("Beta")
graph export figure1.png, replace


**Explanation: Figure 1 depicts how, across all 5 regression models, the distribution of beta decreases as the sample size increaes from 100 to 10000. As beta decreases, power increases, and the probability that we are able to reject the null hypothesis increases. As the sample size increases, the values of beta for all models cluster around the true treatment effect of 0.3.

	
bysort n model: tabstat beta_gpa sem_gpa ci_lower ci_higher, ///
	stat (mean sd min max) ///
	format(%9.4f)
	
**Explanation: This series of descriptive statistics tables demonstrates how, across all five regression models, the confidence intervals cluster around the true population mean as the sample sizes increase. Additionally, the beta and standard error both decrease as the sample size grows. 
	
	


******************************************************************


* Part 3: Spatial Analysis


******************************************************************


cd /Users/steph/Desktop/McCourt/Spring_2026/Exp_Design/Stata4
clear 

*Download ACS data
ssc install getcensus, replace
getcensus, key("b402218ab1aada82d0bdcbcd02870a730bfa6bcc") 
getcensus S2301, geography(tract) statefips(11) year(2022) sample(5)
save employmentdata.dta, replace

use employmentdata.dta, clear

describe
rename s2301_c01_001e pop_16plus
destring pop_16plus, replace ignore("-" "N" "(X)" "**")
rename s2301_c03_001e employment_rate
keep year state county tract geo_id name employment_rate pop_16plus
replace employment_rate = . if pop_16plus < 100
replace geo_id = substr(geo_id, -11, 11)
save employmentdata.dta, replace


*Download DC Census Tract data
local url "https://www2.census.gov/geo/tiger/TIGER2022/TRACT/tl_2022_11_tract.zip" 
copy "`url'" tl_2022_11_tract.zip, replace
unzipfile tl_2022_11_tract.zip, replace

ssc install shp2dta
ssc install spmap
shp2dta using tl_2022_11_tract.shp, ///
	database(dc_tracts)				///
	coordinates(dc_tract_coord)		///
	genid(_ID) replace
	
use dc_tracts, clear
rename GEOID geo_id
merge 1:1 geo_id using employmentdata.dta
tab _merge
save dc_merged.dta, replace

spmap employment_rate using dc_tract_coord.dta,  ///
	id(_ID)		///
	clnumber(5)		///
	clmethod(quantile) ///
	fcolor(Blues2) ///
	ocolor(white ..) ///
	osize(0.10 ..) ///
	ndfcolor(gs12) ///
	ndocolor(white ..) ///
	ndsize(0.10) ///
	ndlabel("Missing/No Employment Data") ///
	legend(title("Employment rate(%)", size(small)) ///
		position(7)) ///
	title("Employment Rate by DC Census Tract")		///
	subtitle("ACS 2022 5-year estimates, population 16+") ///
	note("Source: US Census Bureau S2301.", size(vsmall))

graph export "DC_employment_choropleth.png", replace

