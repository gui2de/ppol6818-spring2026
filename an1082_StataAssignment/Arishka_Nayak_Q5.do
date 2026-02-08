clear all
cd "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\Assignment 3\assignment_ Stata 1\q5"
use q5_Tz_student_roster_html.dta

*Number of test takers*
gen t_takers=strpos(s, "WALIOFANYA MTIHANI")
*finds where test takers start; marks character start pos

gen t_chunk=substr(s,t_takers, 28)
*take a roughly long enough 

gen takers_clean=ustrregexra(t_chunk, "[^0-9.]","")
destring takers_clean, gen(testtakers)


*School Average Score*
gen p_avg = strpos(s, "WASTANI WA SHULE")
gen chunk_avg = substr(s, p_avg, 40)
gen avg_clean = ustrregexra(chunk_avg, "[^0-9.]", "")
destring avg_clean, gen(school_avg)


*Student group (binary indicator: under 40 vs 40 or above)*
gen p_group = strpos(s, "KUNDI LA SHULE")
gen chunk_slice=substr(s,p_group,60)
*roughly doing 60 characters

gen u40 = strpos(chunk_slice, "chini") > 0
label define group_lbl 1 "Under 40" 0 "40 or Above"
label values u40 group_lbl



*School ranking within the council (for example, 22 out of 46)*
gen cr_group=strpos(s, "KIHALMASHAURI")
gen cr_chunk=substr(s,cr_group,30)
*finds the chunk for rank

gen cr_clean = substr(cr_chunk, strpos(cr_chunk, ":") + 1, .)
*marks position after the :, highlights the portion after: for the rank words

replace cr_clean = subinstr(cr_clean, "kati ya", "out of", .)
*finds and replace to translate to English* not mandatory

replace cr_clean = ustrregexra(cr_clean, "<[^>]+>", "")
*removes html code

replace cr_clean = trim(cr_clean)



*School ranking within the region (for example, 74 out of 290)*
gen rr_group=strpos(s, "KIMKOA")
gen rr_chunk=substr(s,rr_group,30)
gen rr_clean=substr(rr_chunk, strpos(rr_chunk,":")+1, .)
replace rr_clean = subinstr(rr_clean, "kati ya", "out of", .)
replace rr_clean = ustrregexra(rr_clean, "<[^>]+>", "")
replace rr_clean = trim(rr_clean)



*School ranking at the national level (for example, 545 out of 5,664)*
gen nr_group=strpos(s, "KITAIFA")
gen nr_chunk=substr(s,nr_group,40)
gen nr_clean=substr(nr_chunk, strpos(nr_chunk,":")+1, .)
replace nr_clean = subinstr(nr_clean, "kati ya", "out of", .)
replace nr_clean = ustrregexra(nr_clean, "<[^>]+>", "")
replace nr_clean = trim(nr_clean)



*School Name and Code*
gen school_pos=strpos(s,"ALBEHIJE") 
gen schoolname=substr(s, school_pos,23)
replace schoolname = ustrregexra(schoolname, "<[^>]+>", "")
replace schoolname = trim(schoolname)
gen scode = ustrregexs(0) if ustrregexm(substr(s, school_pos, 100), "PS[0-9]+")





*Final cleaning of dataset
drop s takers_clean t_takers t_chunk p_avg chunk_avg avg_clean p_group chunk_slice cr_group cr_chunk rr_group rr_chunk nr_group nr_chunk 
drop school_pos 


rename cr_clean council_rank
rename rr_clean regional_rank 
rename nr_clean national_rank
label variable testtakers "Number of Test Takers"
label variable school_avg "School Average"
label variable u40 "Student Group"
label variable national_rank "National Rank"
label variable regional_rank "Regional Rank"
label variable council_rank "Council Rank"
label variable schoolname "Name of School"
label variable scode "School Code"


order schoolname scode



*Bonus Question 

clear
cd "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\Assignment 3\assignment_ Stata 1\q5"
use q5_Tz_student_roster_html.dta

split s, parse("<TR><TD") gen(st)
*splits all the words in s into groups of stuff between these <TR> brackets
gen id = _n
reshape long st, i(id) j(student_num)
keep if strpos(st, "Kiswahili") > 0
*keeps only rows with kiswahili in them (to remove the header rows and so on) 


gen cand_id = ustrregexs(0) if ustrregexm(st, "PS[0-9]+-[0-9]+")
*unicode str regex match: =true if pattern described exists
*ustrregexs: s here stands for subset
*pattern here is ID pattern
*gen code here extracts the id 
*finds a pattern between these brackets; number in bracket gives which part to capture
*0= entire pattern; 1= first part in ()


gen prem_number = ustrregexs(0) if ustrregexm(st, "[0-9]{11}")
gen gender = ustrregexs(1) if ustrregexm(st, `"<P ALIGN="CENTER">(M|F)</FONT>"')
gen name = ustrregexs(1) if ustrregexm(st, "<P>([^<]+)</FONT>")


* Use 'st' (the string) instead of 'student' (the number)
gen kiswahili = ustrregexs(1) if ustrregexm(st, "Kiswahili - ([A-E])")
gen english   = ustrregexs(1) if ustrregexm(st, "English - ([A-E])")
gen maarifa   = ustrregexs(1) if ustrregexm(st, "Maarifa - ([A-E])")
gen hisabati  = ustrregexs(1) if ustrregexm(st, "Hisabati - ([A-E])")
gen science   = ustrregexs(1) if ustrregexm(st, "Science - ([A-E])")
gen uraia     = ustrregexs(1) if ustrregexm(st, "Uraia - ([A-E])")
gen average   = ustrregexs(1) if ustrregexm(st, "Average Grade - ([A-E])")


**School name code 
gen school_pos=strpos(s,"ALBEHIJE") 
gen schoolname=substr(s, school_pos,23)
replace schoolname = ustrregexra(schoolname, "<[^>]+>", "")
replace schoolname = trim(schoolname)
gen scode = ustrregexs(0) if ustrregexm(substr(s, school_pos, 100), "PS[0-9]+")



*Final cleaning 
drop s st id student_num school_pos schoolname
order scode cand_id gender prem_number name 