****************Question 1********************
cd /Users/peggy/Desktop/assignment__Stata___export/01_data
use q1_psle_student_raw.dta,clear

replace schoolcode = upper(regexs(1)) if regexm(schoolcode, "(ps[0-9]{7})")

gen txt = s
replace txt = ustrregexra(txt, "<[^>]*>", " ")        
replace txt = ustrregexra(txt, "&nbsp;|&#160;", " ")    
replace txt = ustrregexra(txt, "\\\\r\\\\n|\\\\r\\\\n|\\\\n", " ") 
replace txt = ustrregexra(txt, "[\r\n\t]+", " ")    
replace txt = ustrregexra(txt, "\\\\'", "")                  
replace txt = strtrim(txt)

gen cut = ustrregexra(txt, "(PS[0-9]{7}-[0-9]{4})", "|||$1")
split cut, parse("|||") gen(seg)

drop txt cut seg1 s 
keep schoolcode seg*
reshape long seg, i(schoolcode) j(row)
drop if missing(seg) | strtrim(seg)==""

gen cand_id = regexs(1) if regexm(seg, "(PS[0-9]{7}-[0-9]{4})")
gen prem_number = regexs(1) if regexm(seg, "PS[0-9]{7}-[0-9]{4} *([0-9]{8,15})")
gen gender = regexs(1) if regexm(seg, "PS[0-9]{7}-[0-9]{4} *[0-9]{8,15} *([MF])")
gen name = strtrim(regexs(1)) if regexm(seg, " [MF] ([A-Z ]+?) Kiswahili")

foreach subj in Kiswahili English Maarifa Hisabati Science Uraia {
    local lower_subj = strlower("`subj'")
    gen `lower_subj' = regexs(1) if regexm(seg, "`subj' *- *([A-EX])")
}
gen average = regexs(1) if regexm(seg, "Average Grade *- *([A-EX])") 

keep schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average

save q1_psle_student_raw.dta, replace






****************Question 2********************
cd /Users/peggy/Desktop/assignment__Stata___export/01_data

import excel using "q2_CIV_populationdensity.xlsx", firstrow clear
rename (NOMCIRCONSCRIPTION SUPERFICIEKM2 POPULATION DENSITEAUKM) ///
       (nom_circ superficie population density)
keep if regexm(nom_circ, "^DEPARTEMENT")	   
	   
gen dept_merge = lower(strtrim( ///
    regexr(regexr(nom_circ, ///
        "^DEPARTEMENT (DE L'|DE LA |DES |DU |DE |D' |D')", ""), ///
        "^ ", "") ))	
		
keep dept_merge density	   
	   
save density_data	

use q2_CIV_Section_0.dta
	   
decode b06_departemen, gen(dept_merge)
replace dept_merge = "arrah"    if dept_merge == "arrha"
	   
merge m:1 dept_merge using density_data
tab _merge
*gbeleban has no households in survey in xlsx
drop if _merge == 2
drop _merge dept_merge

save density_data.dta, replace




****************Question 3********************
cd /Users/peggy/Desktop/assignment__Stata___export/01_data
use "q3_GPS Data.dta", clear

sort latitude longitude
gen enumerator_id = mod(_n - 1, 19) + 1





****************Question 4********************
cd /Users/peggy/Desktop/assignment__Stata___export/01_data
import excel using "q4_Tz_election_2010_raw.xls", ///
    cellrange(A5) firstrow clear allstring

rename (REGION DISTRICT COSTITUENCY WARD CANDIDATENAME ///
        SEX G POLITICALPARTY TTLVOTES ELECTEDCANDIDATE) ///
       (region district constituency ward candidate ///
        sex_m sex_f party votes elected)

drop if missing(party) | party == "POLITICAL PARTY"

foreach var of varlist region district constituency ward {
    replace `var' = `var'[_n-1] if missing(`var') | `var' == ""
}

replace votes = "0" if votes == "UN OPPOSSED"
destring votes, replace

replace party = "APPT_MAENDELEO" if party == "APPT - MAENDELEO"
replace party = "JAHAZIASILIA"   if party == "JAHAZI ASILIA"
replace party = "NCCR_MAGEUZI"   if party == "NCCR-MAGEUZI"

gen byte known = 0
foreach p in AFP APPT_MAENDELEO CCM CHADEMA CHAUSTA CUF DP ///
             JAHAZIASILIA MAKIN NCCR_MAGEUZI NLD NRA SAU TADEA ///
             TLP UDP UMD UPDP {
    replace known = 1 if party == "`p'"
}
drop known

foreach var of varlist region district {
    replace `var' = lower(`var')
    replace `var' = strtrim(`var')
    replace `var' = subinstr(`var', "'", "", .)
    replace `var' = subinstr(`var', "-", "", .)
    replace `var' = subinstr(`var', "/", "", .)
}

replace ward = lower(ward)
replace ward = strtrim(ward)
foreach ch in "'" "-" "/" "(" ")" "." {
    replace ward = subinstr(ward, "`ch'", "", .)
}
replace ward = subinstr(ward, `"""', "", .)
replace ward = itrim(ward)

bysort region district constituency ward: gen total_candidates_10 = _N

collapse (sum) votes (max) total_candidates_10, ///
    by(region district constituency ward party)

reshape wide votes, ///
    i(region district constituency ward total_candidates_10) ///
    j(party) string

foreach p in AFP APPT_MAENDELEO CCM CHADEMA CHAUSTA CUF DP ///
             JAHAZIASILIA MAKIN NCCR_MAGEUZI NLD NRA SAU TADEA ///
             TLP UDP UMD UPDP other {
    capture rename votes`p' votes_`p'_10
}

capture confirm variable votes_other_10
if _rc gen votes_other_10 = .

egen ward_total_votes_10 = rowtotal(votes_AFP_10 votes_APPT_MAENDELEO_10 ///
    votes_CCM_10 votes_CHADEMA_10 votes_CHAUSTA_10 votes_CUF_10 ///
    votes_DP_10 votes_JAHAZIASILIA_10 votes_MAKIN_10 votes_NCCR_MAGEUZI_10 ///
    votes_NLD_10 votes_NRA_10 votes_SAU_10 votes_TADEA_10 votes_TLP_10 ///
    votes_UDP_10 votes_UMD_10 votes_UPDP_10 votes_other_10), missing

gen ward_id_10 = _n

foreach var of varlist votes_AFP_10 votes_APPT_MAENDELEO_10 ///
    votes_CHADEMA_10 votes_CHAUSTA_10 votes_CUF_10 votes_DP_10 ///
    votes_JAHAZIASILIA_10 votes_MAKIN_10 votes_NCCR_MAGEUZI_10 ///
    votes_NLD_10 votes_NRA_10 votes_SAU_10 votes_TADEA_10 ///
    votes_TLP_10 votes_UDP_10 votes_UMD_10 votes_UPDP_10 votes_other_10 {
    capture replace `var' = . if `var' == 0
}

rename (region district constituency ward) ///
       (region_10 district_10 constituency_10 ward_10)

save q4_Tz_election_2010.dta





****************Question 5********************
cd /Users/peggy/Desktop/assignment__Stata___export/01_data
use "q5_school_location.dta", clear

gen scode = upper(strtrim(NECTACentreNo))
drop if scode == "N/A" | missing(scode)
bysort scode: keep if _n == 1

gen region_n = upper(strtrim(Region))

gen name_c = upper(strtrim(School))
replace name_c = ustrregexra(name_c, "\bPRIMARY\b|\bSCHOOL\b", "")
replace name_c = ustrregexra(name_c, "[^A-Z0-9 ]", "")
replace name_c = strtrim(itrim(name_c))

keep scode region_n name_c Ward
save 1, replace

use "q5_psle_2020_data.dta", clear

gen scode = upper(ustrregexs(1)) if ustrregexm(school_code_address, "(ps[0-9]+)")

gen region_n = upper(strtrim(region_name))

gen name_c = upper(strtrim(schoolname))
replace name_c = ustrregexra(name_c, " - PS[0-9].*", "")
replace name_c = ustrregexra(name_c, "\\\\r\\\\n.*", "")
replace name_c = ustrregexra(name_c, "\bPRIMARY\b|\bSCHOOL\b", "")
replace name_c = ustrregexra(name_c, "[^A-Z0-9 ]", "")
replace name_c = strtrim(itrim(name_c))

gen ward = ""

merge m:1 scode using 1, keepusing(Ward) keep(master match) nogen
replace ward = Ward if missing(ward) & !missing(Ward)
drop Ward

count if !missing(ward)

preserve
    use 1, clear
    bysort region_n name_c: keep if _n == 1
    keep region_n name_c Ward
    rename Ward ward_m2
    save 2, replace
restore

merge m:1 region_n name_c using 2, keep(master match) nogen
replace ward = ward_m2 if missing(ward) & !missing(ward_m2)
drop ward_m2

count if !missing(ward)
di "M2 (+name/region): " r(N) " matched"

replace ward = "Kitunda"        if scode == "PS0201019" & missing(ward)
replace ward = "Gararagua"      if scode == "PS0702207" & missing(ward)
replace ward = "Kifula"         if scode == "PS0702234" & missing(ward)
replace ward = "Rabour"         if scode == "PS0903051" & missing(ward)
replace ward = "Msolwa Station" if scode == "PS1101059" & missing(ward)
replace ward = "Sanje"          if scode == "PS1101060" & missing(ward)
replace ward = "Hembeti"        if scode == "PS1101142" & missing(ward)
replace ward = "Kisawasawa"     if scode == "PS1101159" & missing(ward)
replace ward = "Kibaoni"        if scode == "PS1101180" & missing(ward)
replace ward = "Mwendakulima"   if scode == "PS1701106" & missing(ward)
replace ward = "Majiri"         if scode == "PS1807014" & missing(ward)
replace ward = "Masiwani"       if scode == "PS2006047" & missing(ward)

count if !missing(ward)
di "M3 (+manual fuzzy): " r(N) " matched"
count if missing(ward)
di "Unmatched: " r(N) " (not in location dataset)"

keep region_name district_name schoolname school_code_address ///
     region_code district_code serial ward

assert _N == 17329

save "q5_psle_with_ward.dta", replace





****************Question 6n(Bouns Question)********************
cd /Users/peggy/Desktop/assignment__Stata___export/01_data
use "Tz_elec_10_clean.dta", clear

gen wc = ustrregexra(lower(strtrim(ward_10)),   "[^a-z0-9 ]", "")
gen rc = ustrregexra(lower(strtrim(region_10)), "[^a-z0-9 ]", "")
replace wc = strtrim(itrim(wc))
replace rc = strtrim(itrim(rc))

bysort rc wc: keep if _n == 1

keep ward_id_10 district_10 ward_10 total_candidates_10 ward_total_votes_10 rc wc
save _10, replace


use "Tz_GIS_2015_2010_intersection.dta", clear

gen wc17 = ustrregexra(lower(strtrim(ward_gis_2017)),   "[^a-z0-9 ]", "")
gen rc17 = ustrregexra(lower(strtrim(region_gis_2017)), "[^a-z0-9 ]", "")
gen wc12 = ustrregexra(lower(strtrim(ward_gis_2012)),   "[^a-z0-9 ]", "")
gen rc12 = ustrregexra(lower(strtrim(region_gis_2012)), "[^a-z0-9 ]", "")
replace wc17 = strtrim(itrim(wc17))
replace rc17 = strtrim(itrim(rc17))
replace wc12 = strtrim(itrim(wc12))
replace rc12 = strtrim(itrim(rc12))

bysort rc17 wc17 (percentage): keep if _n == _N
keep rc17 wc17 rc12 wc12

rename (rc17 wc17) (rc wc)
save gis, replace


use "Tz_elec_15_clean.dta", clear

gen wc = ustrregexra(lower(strtrim(ward_15)),   "[^a-z0-9 ]", "")
gen rc = ustrregexra(lower(strtrim(region_15)), "[^a-z0-9 ]", "")
replace wc = strtrim(itrim(wc))
replace rc = strtrim(itrim(rc))

merge m:1 rc wc using _10, keep(master match) nogen
rename (ward_id_10 district_10 ward_10 total_candidates_10 ward_total_votes_10) ///
       (wid10_d dist10_d w10_d cand10_d votes10_d)

save 1, replace


use "Tz_elec_15_clean.dta", clear

gen wc = ustrregexra(lower(strtrim(ward_15)),   "[^a-z0-9 ]", "")
gen rc = ustrregexra(lower(strtrim(region_15)), "[^a-z0-9 ]", "")
replace wc = strtrim(itrim(wc))
replace rc = strtrim(itrim(rc))

merge m:1 rc wc using gis, keep(master match) nogen

merge m:1 rc wc using _10, keep(master match) nogen
rename (ward_id_10 district_10 ward_10 total_candidates_10 ward_total_votes_10) ///
       (wid10_g dist10_g w10_g cand10_g votes10_g)

save 2, replace

use 1, clear

merge 1:1 ward_id_15 using 2, keep(master match) nogen

gen     ward_id_10          = wid10_d
replace ward_id_10          = wid10_g           if missing(ward_id_10)
gen     ward_10             = w10_d
replace ward_10             = w10_g             if missing(ward_10)
gen     district_10         = dist10_d
replace district_10         = dist10_g          if missing(district_10)
gen     total_candidates_10 = cand10_d
replace total_candidates_10 = cand10_g          if missing(total_candidates_10)
gen     ward_total_votes_10 = votes10_d
replace ward_total_votes_10 = votes10_g         if missing(ward_total_votes_10)

drop wid10_* dist10_* w10_* cand10_* votes10_* rc wc

count if !missing(ward_id_10)
di "Matched: " r(N) " / 3944"
count if missing(ward_id_10)
di "Unmatched: " r(N)

assert _N == 3944
save "q6_Tz_elec_10_15_merged.dta", replace




































