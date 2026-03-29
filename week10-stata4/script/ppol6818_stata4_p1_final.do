/*===========================
	
	Author: Kenshi Kawade
	Date: March 25, 2026
	Title: ppol6818 stata4
	Part: 1 of 3
	
=============================*/

if c(username) == "kkawade" {
    global wd "/Users/kkawade/GU_Class/ppol6818ex"
}

if c(username) == "username" {
    global wd "yourpathway"
}

cd "$wd/week_10/02_data"

/*===========================
Part 1. Fuzzy matching
=============================*/
* Explore how wards structure change 

** 2010 wards
use "Tz_elec_10_clean.dta", replace
codebook ward_id_10 // 3333 wards in 2010
codebook region_10 //21 regions
codebook district_10 //131 dis

//clean str vars
foreach v of varlist region_10 district_10 ward_10 {
    replace `v' = strtrim(strlower(`v'))
}

//generate keys for merging
gen ward =  ward_10 
gen district =district_10 
gen  region =region_10

save "ward10_prep.dta", replace

** 2015 wards
use "Tz_elec_15_clean.dta", replace 
codebook ward_id_15 // 3944 wards in 2015
codebook region_15 //25 regions
codebook district_15 //178 dis

//clean str vars
foreach v of varlist region_15 district_15 ward_15 {
    replace `v' = strtrim(strlower(`v'))
}

//generate keys for merging
gen   ward = ward_15
gen  district =district_15
gen  region = region_15

save "ward15_prep.dta", replace

** merge 2010 and 2015
merge 1:1 region district ward using "ward10_prep.dta", force

save "Tz_ward_1015.dta", replace

** investigate region situation in 2015
use "Tz_ward_1015.dta", clear
duplicates drop region_10 region_15, force
keep region_10 region_15
count if region_10 == region_15 //21 regions in 2010 still exists in 2015 -> there are 4 regions newly created in 2015
duplicates tag region_15, gen(id)
tab region_15 if id == 0
/* new regions in 2015
geita
katavi
njombe
simiyu
*/

** investigate district situation in 2015
use "Tz_ward_1015.dta", clear
keep district_*
duplicates drop district_*, force
count if district_10 == district_15 //only 115 districts are matched -> 16 districts in 2010 no longer exists 
duplicates tag district_15, gen(id)
keep if id == 0
drop if district_10 == district_15 
tab district_15
/* new 63 districts 
district_15
mji kondoa
wilaya ya chemba
wilaya ya mpwapwa
mji wa geita
wilaya ya bukombe
wilaya ya chato
wilaya ya geita
wilaya ya mbogwe
wilaya ya nyanghwale
mji wa mafinga
wilaya ya kyerwa
manispaa ya mpanda
wilaya ya mlele
wilaya ya mpanda
wilaya ya mpimbwe
wilaya ya nsimbo
manispaa ya kigoma ujiji
mji wa kasulu
wilaya ya buhigwe
wilaya ya kakonko
wilaya ya uvinza
manispaa ya lindi
mji wa mbulu
mji wa bunda
mji wa tarime
wilaya ya butiama
mji wa tunduma
wilaya ya busokelo
wilaya ya momba
wilaya ya gairo
wilaya ya malinyi
mji wa masasi
mji wa nanyamba
mji wa newala
manispaa ya ilemela
wilaya ya buchosa
mji wa makambako
mji wa njombe
wilaya ya ludewa
wilaya ya makete
wilaya ya njombe
wilaya ya wangingombe
wilaya ya chalinze
wilaya ya kalambo
mji wa mbinga
wilaya ya madaba
wilaya ya nyasa
mji wa kahama
wilaya ya msalala
wilaya ya ushetu
mji wa bariadi
wilaya ya bariadi
wilaya ya busega
wilaya ya itilima
wilaya ya maswa
wilaya ya meatu
wilaya ya ikungi
wilaya ya mkalama
mji wa nzega
wilaya ya kaliua
wilaya ya uyui
mji wa handeni
wilaya ya bumbuli
*/

** investigte ward situation in 2015
use "Tz_ward_1015.dta", clear

order ward region district region_10 district_10 ward_10  ward_15 district_15 region_15 _merge

count if _merge == 3 //2379 wards are the same name in both 10 and 15
count if _merge == 1 //1565 wards are only in master -> they are newly created wards in 2015
count if _merge == 2 //954 wards are only in using -> they existed but no longer in 2015

preserve
keep if _merge == 2
keep ward region district region_10 district_10 ward_10 
save "unmatched_ward10.dta"
restore

preserve
keep if _merge == 1
keep ward region district ward_15 district_15 region_15
save "unmatched_ward15.dta"
restore

** Fuzzy match with unmatched wards and gis wards
// prepare for fuzzy match
use "Tz_GIS_2015_2010_intersection.dta", clear 

rename (region_gis_2017 district_gis_2017 ward_gis_2017) (region_15 district_15 ward_15)
rename (region_gis_2012 district_gis_2012 ward_gis_2012) (region_10 district_10 ward_10)
sort region_15 district_15 ward_15
gen dist_id = _n

tempfile gis_15
save `gis_15'

// fuzzy match 1 : merge unmatched 2015 wards to gis wards
use "unmatched_ward15.dta", clear 
keep region_15 district_15 ward_15
duplicates drop
sort region_15 district_15 ward_15
gen idvar = _n

reclink region_15 district_15 ward_15 using `gis_15', idmaster(idvar) idusing(dist_id) gen(fuzscore) 

// adopt fuzzy score above 0.7 as matched enough
sort fuzscore
count if fuzscore >= 0.7 //1344 out of 1566 are matched enough 
drop if fuzscore <0.7
gen dist_id2 = _n
drop _merge
tempfile gis_10
save `gis_10'

// fuzzy match 2 : merge unmatched 2010 wards to gis wards that fuzzy matched with unmatched 2015wards
use "unmatched_ward10.dta", clear 
keep region_10 district_10 ward_10
duplicates drop
sort region_10 district_10 ward_10
gen idvar2 = _n

reclink region_10 district_10 ward_10 using `gis_10', idmaster(idvar2) idusing(dist_id2) gen(fuzscore2)

// adopt same fuzzy score as matched enough 
sort fuzscore2
count if fuzscore2 >= 0.7 //703 out of 954 unmatched wards in 2010 are matched enough with 2012 wards 
drop if fuzscore2 < 0.7

save "merged_70fuzz.dta", replace

// using 703 wards that I defined matched enough with gis wards to see how many wards were divided 
bysort Uward_10 Uregion_10: gen division = _N

preserve
	bysort Uward_10 Uregion_10: keep if _n == 1
	count if division == 2
	di "2010 wards divided into 2 = " r(N)
restore

preserve
	bysort Uward_10 Uregion_10: keep if _n == 1
	count if division >= 3
	di "2010 wards divided into 3 or more = " r(N)
restore

bysort Uward_10 Uregion_10: keep if _n == 1

gen divided = (division > 1)

bysort Uregion_10: egen total_wards = count(Uward_10)
bysort Uregion_10: egen divided_wards = sum(divided)
gen division_rate = divided_wards / total_wards

bysort Uregion_10: keep if _n == 1
gsort -division_rate

list Uregion_10 total_wards divided_wards division_rate, clean noobs



















*============================================================
* FROM HERE: reclink to match remaining 1565 unmatched 2015
* wards to their 2010 parents
*============================================================


use "Tz_ward_1015.dta", clear
sort region district ward
drop if _merge == 3 | _merge == 2
drop _merge
keep ward_id_15 region_15 district_15 ward_15 region




* Split into old-region and new-region subsets
preserve
    keep if !inlist(region_15, "simiyu", "geita", "katavi", "njombe")
    isid ward_id_15
    save "unmatched_old.dta", replace // 1145wards
restore

preserve
    keep if inlist(region_15, "simiyu", "geita", "katavi", "njombe")
    isid ward_id_15
    save "unmatched_new.dta", replace //420wards
restore

* --- Pass 2: old regions ---
use "unmatched_old.dta", clear

reclink ward_15 district region using "ward10_prep.dta", ///
    idmaster(ward_id_15)                    ///
    idusing(ward_id_10)                     ///
    uvarlist(ward_10 district_10 region_10) ///
    required(region)                        ///
    wmatch(2 1 1)                           ///
    gen(fuzscore)                           ///
    uprefix(u_)

	

gen match_pass = 2
save "pass2_fuzzy.dta", replace

* Save confident matches to exclude in Pass 3
preserve
    keep if fuzscore >= 0.85
    keep ward_id_15 ward_id_10
    save "matched_pairs.dta", replace
restore

*------------------------------------------------------------
* PASS 3: reclink for NEW-region wards (no region block)
*------------------------------------------------------------

use "unmatched_new.dta", clear

reclink ward_15 using "ward10_prep_nodups.dta", ///
    idmaster(ward_id_15)         ///
    idusing(ward_id_10)          ///
    uvarlist(ward_10)            ///
    exclude("matched_pairs.dta") ///
    gen(fuzscore)                ///
    uprefix(u_)

gen match_pass = 3
save "pass3_fuzzy.dta", replace

*============================================================
* COMBINE ALL MATCHES INTO FINAL PANEL
*============================================================

* Start with exact matches from original merge
use "Tz_ward_1015.dta", clear
keep if _merge == 3
drop _merge
gen match_pass = 1
gen fuzscore   = .

* Append fuzzy results
append using "pass2_fuzzy.dta"
append using "pass3_fuzzy.dta"

* Remove duplicates — exact (pass 1) takes priority
sort ward_id_15 match_pass
by ward_id_15: keep if _n == 1

* Consolidate ward_id_10 (reclink stores idusing without prefix)
* ward_id_10 already populated directly by reclink

* Label match quality
gen match_method = "exact"      if match_pass == 1
replace match_method = "fuzzy"     if inlist(match_pass,2,3) & fuzscore >= 0.85
replace match_method = "fuzzy_low" if inlist(match_pass,2,3) & fuzscore <  0.85 ///
                                    & !missing(fuzscore)
replace match_method = "unmatched" if missing(ward_id_10)

label variable match_method "Matching method"
label variable fuzscore     "reclink score (0-1)"
label variable match_pass   "1=exact 2=fuzzy old-region 3=fuzzy new-region"

* Bring in 2010 attributes for fuzzy-matched rows
merge m:1 ward_id_10 using "ward10_prep.dta", ///
    keepusing(region_10 district_10 ward_10 ///
              total_candidates_10 ward_total_votes_10) ///
    keep(master match) update nogen

* Bring in 2015 attributes
merge m:1 ward_id_15 using "ward15_prep.dta", ///
    keepusing(region_15 district_15 ward_15 ///
              total_candidates_15 ward_total_votes_15) ///
    keep(master match) update nogen

order ward_id_15 region_15 district_15 ward_15 ///
      ward_id_10 region_10 district_10 ward_10 ///
      match_method fuzscore match_pass ///
      total_candidates_15 ward_total_votes_15 ///
      total_candidates_10 ward_total_votes_10

sort ward_id_15
save "Tz_ward_panel_2010_2015.dta", replace

di "===== MATCHING SUMMARY ====="
tab match_method

*============================================================
* Q1: HOW MANY WARDS WERE DIVIDED INTO EXACTLY 2?
* Q2: HOW MANY WARDS WERE DIVIDED INTO 3 OR MORE?
*============================================================

use "Tz_ward_panel_2010_2015.dta", clear

* Use only confident matches
keep if inlist(match_method, "exact", "fuzzy")

* Count how many 2015 wards share the same 2010 parent
bysort ward_id_10: gen n_children = _N
label variable n_children "# of 2015 wards from this 2010 parent"

* Collapse to one row per 2010 ward
bysort ward_id_10: keep if _n == 1

gen byte divided    = (n_children > 1)
gen byte divided_2  = (n_children == 2)
gen byte divided_3p = (n_children >= 3)

di as text _newline ///
   "=============================================" _newline ///
   "WARD DIVISION SUMMARY (2010 → 2015)"          _newline ///
   "============================================="

count if !divided
di "  Not divided:          " r(N)

count if divided_2
di "  Divided into 2:       " r(N)

count if divided_3p
di "  Divided into 3+:      " r(N)

di _newline "Full split-size distribution:"
tab n_children

* Sanity check: how many 2010 wards are accounted for?
count
di "Total 2010 wards accounted for: " r(N) " (out of 3333)"

save "ward_divisions_2010.dta", replace

*============================================================
* Q3: REGION-LEVEL DIVISION RATES
*============================================================

use "ward_divisions_2010.dta", clear

collapse (sum)   divided divided_2 divided_3p ///
         (count) total_2010_wards = ward_id_10, by(region_10)

gen division_rate = divided / total_2010_wards
format division_rate %6.4f

label variable total_2010_wards "# 2010 wards in region"
label variable divided          "# divided (any)"
label variable divided_2        "# divided into exactly 2"
label variable divided_3p       "# divided into 3+"
label variable division_rate    "Share of 2010 wards divided"

gsort -division_rate

di _newline as text ///
   "============================================="  _newline ///
   "REGION-LEVEL WARD DIVISION RATES"              _newline ///
   "============================================="
list region_10 total_2010_wards divided divided_2 divided_3p ///
     division_rate, sep(0) noobs ab(20)

save "region_division_rates.dta", replace
