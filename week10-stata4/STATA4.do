***STATA 4
**Part 1
**Warren Burroughs
**Worked with Abhinav

*Write your cd here
global yourcd "C:\Users\warre\OneDrive\Desktop\Georgetown\SecondSemester\Experimental_Design\Assignments\assignments_stata_4"
cd $yourcd

*Cleaning data for merging. Making sure that region, district, and ward are the same variable name in both datasets
use Tz_elec_15_clean, clear
bysort district_15 (ward_15): gen w_num15 = _n, af(district_15)
rename region_15 region
rename district_15 district
rename ward_15 ward
save Tz_elec_15_progress.dta

use Tz_elec_10_clean, clear
bysort district_10 (ward_10): gen w_num10 = _n, af(district_10)
rename region_10 region
rename district_10 district
rename ward_10 ward
save Tz_elec_10_progress.dta


*Use reclink2 to merge
use Tz_elec_15_progress, clear // 2015 is master file
reclink2 ward region district using Tz_elec_10_progress.dta, idmaster(ward_id_15) idusing(ward_id_10) gen(reclink) required(region district) manytoone
order w_num10 ward w_num15 Uward reclink // reclink creates Uward
sort ward_id_10
duplicates tag ward_id_10 if _merge == 3, gen(match_tag)
tab match_tag
/*
  match_tag |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |      2,115       72.63       72.63
          1 |        626       21.50       94.13
          2 |        126        4.33       98.45
          3 |         40        1.37       99.83
          4 |          5        0.17      100.00
------------+-----------------------------------
      Total |      2,912      100.00
*/
display (2115/1) + (626/2) + (126/3) + (40/4) + (5/5)
//1.1: 2,481 exist in 2010 and 2015
tab _merge
//1.2: 1,120 were only in 2015 (parentless); from _merge == 1, only found in master 

display (3944 - 2481) - 1120
//343 wards in 2015 are still unaccounted for

//3333 - 2481 = 852 
//1.3: 852 wards in 2010 are still unaccounted for

**********

use Tz_GIS_2015_2010_intersection.dta, clear

*Generate variable that counts duplicates within wards within districts
gen count_2012 = 0
bysort district_gis_2012 ward_gis_2012: replace count_2012 = _N
tab count_2012 

*Generate variable that counts number of 2012 wards that were split
gen match_count = 0
bysort district_gis_2012 ward_gis_2012: replace match_count = match_count + 1 if ward_gis_2012 == ward_gis_2017

count if count_2012 == 2 & match_count == 1
//1.4: 453 wards were divided into two wards between 2010 and 2015

count if count_2012 > 2 & match_count == 1
//1.5 32 wards

*1.6 Generate variables that calculates (Number of wards within a region that were divided)/(total wards within in a region not counting duplicates)

//How many times was a ward divided?
bysort ward_gis_2012: gen divided = count_2012 if _n == 1 & count_2012 != 1

//Was a ward divided?
gen d_indicator = 1 if divided != .

//Is the ward a unique ward?
gen unique = 1 if count_2012 == 1 | d_indicator == 1

//How many wards in the regions?
bysort region_gis_2012: egen ward_in_region = total(unique)

//How many wards in the region were divided?
bysort region_gis_2012: egen d_counter = total(d_indicator)

//Division rate
gen division_rate = d_counter/ward_in_region

*1.6 Output/Answer
bysort region_gis_2012: list region_gis_2012 division_rate if _n == 1





*---------------------------------------------------------------------
**Part 2

*2.1 
capture program drop part2
program define part2, rclass
	syntax, sample_size(int)
	clear
	set obs `sample_size'
	gen x = rnormal(10,1)
	gen error = rnormal(1,0.1)
	gen y = x*2 + error
	sum y
	scalar define treat_sd = r(sd)
	display treat_sd
	gen treatment_effect = 0.3*treat_sd

	gen t_group = 0
	gen rand = runiform()
	sum ran, detail
	replace t_group = 1 if rand > `r(p50)'
	tab t_group

	*2.2
	gen y_post = y + treatment_effect if t_group == 1 // Stage 1 of y post
	replace y_post = y if t_group == 0

	*Confounder: Something that impacts both X and Y
	gen confounder = rnormal(0,1)

	gen rand_confounder = rnormal(40 * confounder, 1)  
	gen t_confounder = 0
	sum rand_confounder, d
	replace t_confounder = 1 if rand_confounder < `r(p50)'

	gen y_confounder = y_post + 200*confounder 


	*Mediator: Caused by the treatment and subsequently causes Y
	gen mediator = rnormal(40 + 100*treatment_effect, 1)
	gen y_mediator = x*2 + 10*mediator + error

	*Collider: Something that both X and Y impacts
	gen collider = 100*x + 200*y_post + error
	
	//Baseline
	regress y_post x
	matrix base = r(table) 
	matrix list base
	return scalar base_beta = base[1,1]
	//Not controlling for confounder (but confounder is present)
	regress y_confounder x
	matrix confounder_nc = r(table) 
	matrix list confounder_nc
	return scalar confounder_nc_beta = confounder_nc[1,1]
	//Controlling for confounder
	regress y_confounder x confounder
	matrix confounder_c = r(table) 
	matrix list confounder_c
	return scalar confounder_c_beta = confounder_c[1,1]
	//Not controlling for mediator
	regress y_mediator x
	matrix mediator_nc = r(table) 
	matrix list mediator_nc
	return scalar mediator_nc_beta = mediator_nc[1,1]
	//Controlling for mediator
	regress y_mediator x mediator
	matrix mediator_c = r(table) 
	matrix list mediator_c
	return scalar mediator_c_beta = mediator_c[1,1]
	//Controlling for collider (not controlling for collider is baseline)
	regress y_post x collider
	matrix collider_c = r(table) 
	matrix list collider_c
	return scalar collider_c_beta = collider_c[1,1]
	
end



clear
tempfile part2_3
save `part2_3', emptyok
foreach n of numlist 10000 1000 100 10 {
	//Loop is in descencding order so the final datafile's observations are in ascending order according to sample size
	
	clear
	
	simulate base_beta=r(base_beta) confounder_nc_beta=r(confounder_nc_beta) 	confounder_c_beta=r(confounder_c_beta) mediator_nc_beta=r(mediator_nc_beta) 		mediator_c_beta=r(mediator_c_beta) collider_c_beta=r(collider_c_beta), 		reps(100): part2, sample_size(`n')
	
	gen N = `n'
	
	append using `part2_3'
	save `"`part2_3'"', replace
}

dtable base_beta confounder_nc_beta confounder_c_beta mediator_nc mediator_c_beta collider_c_beta, by(N, nototals) nosample 

/*
---------------------------------------------------------------------------------
                                                   N                             
                            10             100           1000           10000    
---------------------------------------------------------------------------------
r(base_beta)           2.009 (0.126)  2.004 (0.031)  2.002 (0.009)  2.000 (0.003)
r(confounder_nc_beta) 1.119 (70.217) 2.716 (21.093)  2.102 (7.080)  2.296 (2.078)
r(confounder_c_beta)   2.012 (0.125)  2.005 (0.031)  2.002 (0.009)  2.000 (0.003)
r(mediator_nc_beta)    2.524 (4.073)  1.914 (0.935)  1.995 (0.310)  2.011 (0.089)
r(mediator_c_beta)     2.005 (0.043)  2.000 (0.010)  2.000 (0.003)  2.000 (0.001)
r(collider_c_beta)    -0.499 (0.002) -0.499 (0.000) -0.499 (0.000) -0.499 (0.000)
---------------------------------------------------------------------------------
*/


hist base_beta, freq xline(2) by(N)
hist confounder_nc_beta, freq xline(2) by(N)
hist confounder_c_beta, freq xline(2) by(N)
hist mediator_nc_beta, freq xline(2) by(N)
hist mediator_c_beta, freq xline(2) by(N)
hist collider_c_beta, freq xline(2) by(N) //xline is so far away




*------------------------------------------------------------------------
**Part 3
//ssc install shp2dta

*Get database and coordinates file from shp2dta
shp2dta using tl_2022_11_tract, database(dc_db) coordinates(dc_coord) replace

*Download Data from below link and import
//https://opdatahub.dc.gov/datasets/acs-5-year-economic-characteristics-of-dc-census-tracts-2018-2022/explore?location=38.893721%2C-77.014562%2C11&showTable=true
import excel "ACS_5-Year_Economic_Characteristics_of_DC_Census_Tracts_2018-2022.xlsx", firstrow clear 

*Clean data based on website
rename DP03_0001E employment
label variable employment "EMPLOYMENT STATUS: Population 16 years and over"
drop DP*
rename OBJECTID _ID

save dc_analysis.dta

use dc_db.dta, clear

*Clean to merge
destring _ID, replace
drop GEOID
drop TRACTCE

merge 1:1 _ID using dc_analysis.dta 


spmap employment using dc_coord.dta, id(_ID) legend(size(*1)) legend(position(5)) fcolor(BuRd) clnumber(5) title("No. of people employed by Tract in DC (2022)")

