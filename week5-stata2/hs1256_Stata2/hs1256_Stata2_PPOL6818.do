//Harold Shi
//PPOL6818
//Stata2

//Question1
cd "D:\Stata2\q1"
use q1_psle_student_raw.dta, clear

***Preliminary CLeaning
replace s = lower(s)
replace s = subinstr(s, char(10), "", .)
replace s = subinstr(s, char(13), "", .)

***HTML Split, Reshape & Cleaning
split s, parse("<tr") gen(row)
drop s
reshape long row, i(schoolcode) j(id)
drop if missing(row)
drop if strpos(row, "candidate") > 0
keep if strpos(row, "ps0") > 0
split row, parse("</td>") gen(col)
foreach v of varlist col* {
    replace `v' = regexs(1) if regexm(`v', ">([^<>]+)<")
}
keep if regexm(col1, "^ps[0-9]+-[0-9]+$")

***Split scores
split col5, parse(",") gen(score)
foreach v of varlist score* {
    replace `v' = regexs(1) if regexm(`v', "-\s*([a-z])")
}

***Rename Vars
rename col1 candidate
rename col2 examno
rename col3 sex
rename col4 name
rename score1 kiswahili
rename score2 english
rename score3 maarifa
rename score4 hisabati
rename score5 science
rename score6 uraia
rename score7 averagegrade

***Finalize Dataset
drop row id col5 col6
replace schoolcode = subinstr(schoolcode, ".htm", "", .)
compress

***Save
save q1_psle_student_clean.dta, replace
clear

//Question2
cd "D:\Stata2\q2"
import excel "q2_CIV_populationdensity.xlsx", firstrow clear
rename *, lower

***excel multilevel cleaning
keep if strpos(lower(nomcirconscription), "departement") > 0

***cross-datasets matching
replace nomcirconscription = subinstr(nomcirconscription, "DEPARTEMENT DE ", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "DEPARTEMENT DU ", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "DEPARTEMENT D' ", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "DEPARTEMENT D'", "", .)
replace nomcirconscription = strtrim(nomcirconscription)
replace nomcirconscription = lower(nomcirconscription)
rename nomcirconscription department
save "q2_CIV_populationdensity.dta", replace
clear

***.dta datasets cleaning
use "q2_CIV_Section_0.dta", clear
rename b06_departemen department
rename b04_district district
rename b05_region region
rename b07_souspref souspref
rename b08_commune commune
rename b09_zd zd
rename b10_nomvillag nomvillag
rename b11_quartcpt quartcpt
decode department, gen(department_str)
drop department
rename department_str department
save "q2_CIV_Section_0.dta", replace
clear

***merge
use "q2_CIV_Section_0.dta", clear
merge m:1 department using q2_CIV_populationdensity.dta
drop _merge

***finalize
rename densiteaukm density
rename superficiekm2 area_km2
save CIV_Section_0_with_density.dta, replace
clear

//Question3
cd "D:\Stata2\q3"
use "q3_GPS Data.dta", clear

***interoperatablize
count
local N = r(N)
local k = ceil(`N'/6)

***catagorize
sort latitude longitude
gen enumerator = ceil(_n/6)

***Check
tab enumerator
twoway scatter latitude longitude, by(enumerator)

***finalize
save q3_GPS_assigned.dta, replace
clear

//Question4
cd "D:\Stata2\q4"
import excel "q4_Tz_election_2010_raw.xls", sheet("Sheet1") firstrow clear

***Change
rename THEUNITEDREPUBLICOFTANZANIA region
rename B district
rename C constituency
rename D ward
rename E candidate_name
rename F sex_m
rename G sex_f
rename H party
rename I votes
rename J elected
gen sex = "M" if sex_m == "M"
replace sex = "F" if sex_f == "F"
drop sex_m sex_f

***clearing
drop in 1/4
drop if missing(candidate_name)
replace votes = "0" if votes == "UN OPPOSSED"
destring votes, replace

***matching
replace region = region[_n-1] if missing(region)
replace district = district[_n-1] if missing(district)
replace constituency = constituency[_n-1] if missing(constituency)
replace ward = ward[_n-1] if missing(ward)

***checking by elected
bys region district constituency ward: count if elected=="ELECTED"

***Reshape & Corresponding Preparation
collapse (sum) votes, ///
    by(region district constituency ward party)
bys region district constituency ward: gen total_candidates = _N
bys region district constituency ward: egen ward_total_votes = total(votes)
encode party, gen(party_id)
label list
//party_id:
//           1 AFP
//           2 APPT - MAENDELEO
//           3 CCM
//           4 CHADEMA
//           5 CHAUSTA
//           6 CUF
//           7 DP
//           8 JAHAZI ASILIA
//           9 MAKIN
//          10 NCCR-MAGEUZI
//          11 NLD
//          12 NRA
//          13 SAU
//          14 TADEA
//          15 TLP
//          16 UDP
//          17 UMD
//          18 UPDP

drop party
reshape wide votes, ///
    i(region district constituency ward total_candidates ward_total_votes) ///
    j(party_id)
	
***sort & finalize
sort region district constituency ward
rename votes1 votes_AFP_10
rename votes2 votes_APPTMAENDELEO_10
rename votes3 votes_CCM_10
rename votes4 votes_CHADEMA_10
rename votes5 votes_CHAUSTA_10
rename votes6 votes_CUF_10
rename votes7 votes_DP_10
rename votes8 votes_JAHAZIASILTA_10
rename votes9 votes_MAKIN_10
rename votes10 votes_NCCR_MAGEUZI_10
rename votes11 votes_NLD_10
rename votes12 votes_NRA_10
rename votes13 votes_SAU_10
rename votes14 votes_TADEA_10
rename votes15 votes_TLP_10
rename votes16 votes_UDP_10
rename votes17 votes_UMD_10
rename votes18 votes_UPDP_10
//rename votes19 votes_other_10 There is no "other" in the raw dataset.
save "q4_Tz_election_2010_cleaned.dta", replace
clear

//Question5
cd "D:\Stata2\q5"
use q5_psle_2020_data.dta, clear

***varname & letter standardize
**psle
rename region_name region
rename district_name district
rename schoolname school

replace region   = upper(region)
replace district = upper(district)
replace school   = upper(school)

replace school = subinstr(school,"PRIMARY SCHOOL","",.)
replace school = substr(school,1,strpos(school,"-")-1)
replace school = strtrim(school)

save q5_psle_std.dta, replace

**loc
use q5_school_location.dta, clear

rename Region region
rename Council district
rename School school

replace region   = upper(region)
replace district = upper(district)
replace school   = upper(school)

keep region district school Ward NECTACentreNo
*We need the ward information

rename Ward ward
collapse (first) ward, by(region district school)
save q5_loc_std.dta, replace

***merge
use q5_psle_std.dta, clear
merge m:1 region district school using q5_loc_std.dta

***finalize
keep if _merge!=2
save q5_cleaned_merged.dta, replace
clear