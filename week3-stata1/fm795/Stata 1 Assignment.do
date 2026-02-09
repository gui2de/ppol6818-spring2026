/***************************
Experimenta Design & Implementation
Stata 01 Assignment
Fabiha Moin 
7th February 2026
***********************************/

cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\assignment__Stata_1_export\q1_data"

/***************
Question 01 
*****************/ 

**part(a)

use student.dta
rename primary_teacher teacher
merge m:1 teacher using teacher.dta
drop _merge
merge m:1 school using school.dta
tab loc
summarize attend if loc=="South"

/*

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180


** Mean student attendance for schools located in South region is 177.4776 days

*/

**part(b)
merge m:1 subject using subject.dta
tab level 
tab tested
tab tested if level=="High"

/*

     tested |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        769       55.77       55.77
          1 |        610       44.23      100.00
------------+-----------------------------------
      Total |      1,379      100.00

** 44.23% of students that are enrolled in High School have a teacher who teaches a tested subject

*/

**part(c)
lookfor gpa
summarize gpa

/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334

** the mean gpa of all students in the district is 3.60144	

*/ 

**part(d)	 
table school if level=="Middle", statistic(mean attendance)

/*
--------------------------------------------
                                 |      Mean
---------------------------------+----------
school                           |          
  Joseph Darby Middle School     |  177.4408
  Mahatma Ghandi Middle School   |  177.3344
  Malala Yousafzai Middle School |  177.5478
  Total                          |  177.4514

*/  

/***************************
Question 02
************************/ 

cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\assignment__Stata_1_export"

use q2_village_pixel.dta

**part(a)

tab pixel payout
/*
           |        payout
     Pixel |         0          1 |     Total
-----------+----------------------+----------
    KE3556 |       117          0 |       117 
    KE3557 |         0        236 |       236 
    KE3558 |       104          0 |       104 
    KE3631 |         0        154 |       154 
    KE3632 |         0        291 |       291 
    KE3633 |        56          0 |        56 
-----------+----------------------+----------
     Total |       277        681 |       958 
*/

bysort pixel: egen min_payout = min(payout)
bysort pixel: egen max_payout = max(payout)

gen pixel_consistent=.
replace pixel_consistent=1 if min_payout==max_payout 
replace pixel_consistent=0 if min_payout!=max_payout 

**There are no inconsistencies within pixels 

**part(b)
bysort village (pixel): gen first_pixel=pixel[1]
gen diff_pixel=(pixel !=first_pixel)
bysort village: egen pixel_village = max(diff_pixel)

tab pixel_village 
/*

pixel_villa |
         ge |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        834       87.06       87.06
          1 |        124       12.94      100.00
------------+-----------------------------------
      Total |        958      100.00

*/

**part(c)
bysort village pixel: egen pixel_payout= min(payout)
bysort village (pixel): gen first_pixel_payout= pixel_payout[1]
bysort village: egen payout_diff_pixels=max(pixel_payout !=first_pixel_payout)

gen village_category=.
replace village_category=1 if pixel_village==0 
replace village_category=2 if pixel_village==1 & payout_diff_pixels==0
replace village_category=3 if pixel_village==1 & payout_diff_pixels==1
list hhid if village_category==2

/*
     +-----------+
     |      hhid |
     |-----------|
170. | 120507101 |
171. | 120507103 |
172. | 120507102 |
173. | 120507104 |
174. | 120507111 |
     |-----------|
201. | 120508209 |
202. | 120508203 |
203. | 120508206 |
204. | 120508202 |
205. | 120508208 |
     |-----------|
206. | 120508204 |
266. | 120610602 |
267. | 120610604 |
268. | 120610605 |
269. | 120610609 |
     |-----------|
278. | 120611102 |
279. | 120611101 |
280. | 120611108 |
342. | 120813801 |
343. | 120813807 |
     |-----------|
344. | 120813804 |
345. | 120813803 |
346. | 120813811 |
385. | 120814907 |
386. | 120814901 |
     |-----------|
387. | 120814911 |
388. | 120814903 |
534. | 131120506 |
535. | 131120509 |
536. | 131120510 |
     |-----------|
571. | 131221904 |
572. | 131221909 |
573. | 131221901 |
574. | 131221912 |
575. | 131221905 |
     |-----------|
615. | 131424211 |
616. | 131424206 |
617. | 131424205 |
618. | 131424204 |
635. | 131424609 |
     |-----------|
636. | 131424602 |
637. | 131424610 |
638. | 131424604 |
739. | 141728101 |
740. | 141728102 |
     |-----------|
741. | 141728108 |
742. | 141728103 |
950. | 131336109 |
951. | 131336107 |
952. | 131336101 |
     +-----------+
*/ 

/******************************
Question 03
***************************/ 

/**
psa: i am not proud of this code, i know there must have been a simpler way to do this. apologies in advance if you are reviewing this 

**code explanation: i generated a score variable for each reviewer using their unique ids then summarized those score variables to obtain the mean score and standard deviation for each reviewer's score. 

then for the stand_r1_score stand_r2_score and stand_r3_score i just step by step multiplied and divided the score by that reviewer's mean score and standard deviation using if reviewer1=="reviewers netID"

**/

**part(1)
use q3_proposal_review.dta

gen ahs103_score=. 
replace  ahs103_score=Review1Score if Rewiewer1=="ahs103"
replace ahs103_score=Reviewer2Score if Reviewer2=="ahs103"
replace ahs103_score=Reviewer3Score if Reviewer3=="ahs103"
summarize ahs103_score

gen am3944_score=. 
replace  am3944_score=Review1Score if Rewiewer1=="am3944"
replace am3944_score=Reviewer2Score if Reviewer2=="am3944"
replace am3944_score=Reviewer3Score if Reviewer3=="am3944"
summarize  am3944_score

gen ass95_score=. 
replace ass95=Review1Score if Rewiewer1=="ass95"
replace ass95_score=Reviewer2Score if Reviewer2=="ass95"
replace ass95_score=Reviewer3Score if Reviewer3=="ass95"
summarize  ass95_score

gen ato12_score=. 
replace ato12_score=Review1Score if Rewiewer1=="ato12"
replace ato12_score=Reviewer2Score if Reviewer2=="ato12"
replace ato12_score=Reviewer3Score if Reviewer3=="ato12"
summarize  ato12_score

gen bp557_score=. 
replace bp557_score=Review1Score if Rewiewer1=="bp557"
replace bp557_score=Reviewer2Score if Reviewer2=="bp557"
replace bp557_score=Reviewer3Score if Reviewer3=="bp557"
summarize  bp557_score

gen fg443_score=. 
replace fg443_score=Review1Score if Rewiewer1=="fg443"
replace fg443_score=Reviewer2Score if Reviewer2=="fg443"
replace fg443_score=Reviewer3Score if Reviewer3=="fg443"
summarize  fg443_score

gen ft227_score=. 
replace ft227_score=Review1Score if Rewiewer1=="ft227"
replace ft227_score=Reviewer2Score if Reviewer2=="ft227"
replace ft227_score=Reviewer3Score if Reviewer3=="ft227"
summarize ft227_score

gen  glp38_score=. 
replace  glp38_score=Review1Score if Rewiewer1=="glp38"
replace  glp38_score=Reviewer2Score if Reviewer2=="glp38"
replace  glp38_score=Reviewer3Score if Reviewer3=="glp38"
summarize  glp38_score

gen  mp1792_score=. 
replace  mp1792_score=Review1Score if Rewiewer1=="mp1792"
replace  mp1792_score=Reviewer2Score if Reviewer2=="mp1792"
replace  mp1792_score=Reviewer3Score if Reviewer3=="mp1792"
summarize  mp1792_score

gen  nbs56_score=. 
replace  nbs56_score=Review1Score if Rewiewer1=="nbs56"
replace  nbs56_score=Reviewer2Score if Reviewer2=="nbs56"
replace  nbs56_score=Reviewer3Score if Reviewer3=="nbs56"
summarize  nbs56_score

gen  nd549_score=. 
replace  nd549_score=Review1Score if Rewiewer1=="nd549"
replace  nd549_score=Reviewer2Score if Reviewer2=="nd549"
replace  nd549_score=Reviewer3Score if Reviewer3=="nd549"
summarize  nd549_score

gen  oo140_score=. 
replace  oo140_score=Review1Score if Rewiewer1=="oo140"
replace  oo140_score=Reviewer2Score if Reviewer2=="oo140"
replace  oo140_score=Reviewer3Score if Reviewer3=="oo140"
summarize  oo140_score

gen  sa1600_score=. 
replace  sa1600_score=Review1Score if Rewiewer1=="sa1600"
replace  sa1600_score=Reviewer2Score if Reviewer2=="sa1600"
replace  sa1600_score=Reviewer3Score if Reviewer3=="sa1600"
summarize  sa1600_score

gen  scb136_score=. 
replace  scb136_score=Review1Score if Rewiewer1=="scb136"
replace  scb136_score=Reviewer2Score if Reviewer2=="scb136"
replace  scb136_score=Reviewer3Score if Reviewer3=="scb136"
summarize  scb136_score

gen  yc577_score=. 
replace  yc577_score=Review1Score if Rewiewer1=="yc577"
replace  yc577_score=Reviewer2Score if Reviewer2=="yc577"
replace  yc577_score=Reviewer3Score if Reviewer3=="yc577"
summarize  yc577_score

gen  ynd3_score=. 
replace  ynd3_score=Review1Score if Rewiewer1=="ynd3"
replace  ynd3_score=Reviewer2Score if Reviewer2=="ynd3"
replace  ynd3_score=Reviewer3Score if Reviewer3=="ynd3"
summarize  ynd3_score


gen stand_r1_score=. 
gen stand_r2_score=.
gen stand_r3_score=.

replace stand_r1_score=(Reviewer2Score-4.195833)/0.7726179 if Rewiewer1=="ahs103"
replace stand_r2_score=(Reviewer2Score-4.195833)/0.7726179 if Reviewer2=="ahs103"
replace stand_r3_score=(Reviewer3Score-4.195833)/0.7726179 if Reviewer3=="ahs103"

replace stand_r1_score=(Reviewer2Score-3.808333)/0.9925447 if Rewiewer1=="am3944"
replace stand_r2_score=(Reviewer2Score-3.808333)/0.9925447 if Reviewer2=="am3944"
replace stand_r3_score=(Reviewer3Score-3.808333)/0.9925447 if Reviewer3=="am3944"

replace stand_r1_score=(Reviewer2Score-4.104167)/0.8322203 if Rewiewer1=="ass95"
replace stand_r2_score=(Reviewer2Score-4.104167)/0.8322203 if Reviewer2=="ass95"
replace stand_r3_score=(Reviewer3Score-4.104167)/0.8322203 if Reviewer3=="ass95"

replace stand_r1_score=(Reviewer2Score-3.854167)/0.957342 if Rewiewer1=="ato12"
replace stand_r2_score=(Reviewer2Score-3.854167)/0.957342 if Reviewer2=="ato12"
replace stand_r3_score=(Reviewer3Score-3.854167)/0.957342 if Reviewer3=="ato12"

replace stand_r1_score=(Reviewer2Score-3.633333)/0.9702831 if Rewiewer1=="bp557"
replace stand_r2_score=(Reviewer2Score-3.633333)/0.9702831 if Reviewer2=="bp557"
replace stand_r3_score=(Reviewer3Score-3.633333)/0.9702831 if Reviewer3=="bp557"

replace stand_r1_score=(Reviewer2Score-4.0125)/0.746186 if Rewiewer1=="fg443"
replace stand_r2_score=(Reviewer2Score-4.0125)/0.746186 if Reviewer2=="fg443"
replace stand_r3_score=(Reviewer3Score-4.0125)/0.746186 if Reviewer3=="fg443"

replace stand_r1_score=(Reviewer2Score-3.916667)/0.9572 if Rewiewer1=="ft227"
replace stand_r2_score=(Reviewer2Score-3.916667)/0.9572 if Reviewer2=="ft227"
replace stand_r3_score=(Reviewer3Score-3.916667)/0.9572 if Reviewer3=="ft227"

replace stand_r1_score=(Reviewer2Score- 4.066667)/1.037835 if Rewiewer1=="glp38"
replace stand_r2_score=(Reviewer2Score- 4.066667)/1.037835 if Reviewer2=="glp38"
replace stand_r3_score=(Reviewer3Score- 4.066667)/1.037835 if Reviewer3=="glp38"

replace stand_r1_score=(Reviewer2Score-3.9625)/1.026523 if Rewiewer1=="mp1792"
replace stand_r2_score=(Reviewer2Score-3.9625)/1.026523 if Reviewer2=="mp1792"
replace stand_r3_score=(Reviewer3Score-3.9625)/1.026523 if Reviewer3=="mp1792"

replace stand_r1_score=(Reviewer2Score- 3.679167)/1.008218 if Rewiewer1=="nbs56"
replace stand_r2_score=(Reviewer2Score- 3.679167)/1.008218 if Reviewer2=="nbs56"
replace stand_r3_score=(Reviewer3Score- 3.679167)/1.008218 if Reviewer3=="nbs56"

replace stand_r1_score=(Reviewer2Score-3.616667)/1.156707 if Rewiewer1=="nd549"
replace stand_r2_score=(Reviewer2Score-3.616667)/1.156707 if Reviewer2=="nd549"
replace stand_r3_score=(Reviewer3Score-3.616667)/1.156707 if Reviewer3=="nd549"

replace stand_r1_score=(Reviewer2Score-3.975)/0.9018098 if Rewiewer1=="oo140"
replace stand_r2_score=(Reviewer2Score-3.975)/0.9018098 if Reviewer2=="oo140"
replace stand_r3_score=(Reviewer3Score-3.975)/0.9018098 if Reviewer3=="oo140"

replace stand_r1_score=(Reviewer2Score-3.966667)/0.9388553 if Rewiewer1=="sa1600"
replace stand_r2_score=(Reviewer2Score-3.966667)/0.9388553 if Reviewer2=="sa1600"
replace stand_r3_score=(Reviewer3Score-3.966667)/0.9388553 if Reviewer3=="sa1600"

replace stand_r1_score=(Reviewer2Score-3.85)/0.9523426 if Rewiewer1=="scb136"
replace stand_r2_score=(Reviewer2Score-3.85)/0.9523426 if Reviewer2=="scb136"
replace stand_r3_score=(Reviewer3Score-3.85)/0.9523426 if Reviewer3=="scb136"

replace stand_r1_score=(Reviewer2Score-3.7125)/0.960214 if Rewiewer1=="yc577"
replace stand_r2_score=(Reviewer2Score-3.7125)/0.960214 if Reviewer2=="yc577"
replace stand_r3_score=(Reviewer3Score-3.7125)/0.960214 if Reviewer3=="yc577"

replace stand_r1_score=(Reviewer2Score-4.041667)/0.8314036 if Rewiewer1=="ynd3"
replace stand_r2_score=(Reviewer2Score-4.041667)/0.8314036 if Reviewer2=="ynd3"
replace stand_r3_score=(Reviewer3Score-4.041667)/0.8314036 if Reviewer3=="ynd3"

**part(2)
gen average_stand_score= (stand_r1_score+stand_r2_score+stand_r3_score)/3

**part(3)
gsort -average_stand_score
gen rank= _n


/*******************************
Question 04
**********************/
clear

global wd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design"
global excel_t21 "$wd\q4_Pakistan_district_table21.xlsx"

cd "$wd"

tempfile table21
save `table21', replace emptyok

forvalues i=1/135 {

    import excel "$excel_t21", sheet("Table `i'") firstrow allstring clear
    
    display as error "Processing Loop: `i'" 

    keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND") == 1
    keep in 1

    foreach v of varlist _all {
        count if !missing(`v')
        if r(N) == 0 {
            drop `v'
        }
    }

    rename * col#, addnumber
    rename col1 table21

    replace table21 = subinstr(table21, char(160), " ", .)
    replace table21 = trim(itrim(table21))
    replace table21 = "18 AND ABOVE" if regexm(table21, "18 AND") | regexm(table21, "OVERALL")

    gen TABLE = `i'

    if `i' > 1 {
        append using `table21'
    }
    save `table21', replace
}
use `table21', clear
format %40s col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13	


/*********************************
Question 05
********************************/
clear
	
cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\assignment__Stata_1_export\q5"

use q5_Tz_student_roster_html.dta

**Capturing school Name and School Code

gen school_name = "ALBEHIJE PRIMARY SCHOOL"
gen school_code = "PS0101114"

**part(1). Extracting Values for # of Students who took the test
gen n_students = real(regexs(1)) if regexm(s, "WALIOFANYA MTIHANI : ([0-9]+)")

**part(2). Extracting Values for Average Score
gen avg_score = real(regexs(1)) if regexm(s, "WASTANI WA SHULE   : ([0-9.]+)")

**part(3). Creating the Binary Variable for Student Group 
gen under_40 = strpos(s, "chini ya 40") > 0

**part(4). Extracting School Ranking within Council
gen rank_council = real(regexs(1)) if regexm(s, "KIHALMASHAURI: ([0-9]+) kati ya ([0-9]+)")
gen total_council = real(regexs(2)) if regexm(s, "KIHALMASHAURI: ([0-9]+) kati ya ([0-9]+)")

**part(5). Extracting School Ranking within Region
gen rank_region = real(regexs(1)) if regexm(s, "KIMKOA  : ([0-9]+) kati ya ([0-9]+)")
gen total_region = real(regexs(2)) if regexm(s, "KIMKOA  : ([0-9]+) kati ya ([0-9]+)")

**part(6). Extracting School Ranking at National Level 
gen rank_national = real(regexs(1)) if regexm(s, "KITAIFA : ([0-9]+) kati ya ([0-9]+)")
gen total_national = real(regexs(2)) if regexm(s, "KITAIFA : ([0-9]+) kati ya ([0-9]+)")

keep school_name school_code n_students avg_score under_40 rank_* total_*
keep if _n == 1

/***************************
Bonus Question
****************************/ 
clear

cd "C:\Users\fabih\OneDrive\Desktop\MIDP\Spring 2026\Experimental Design\assignment__Stata_1_export\q5"

use q5_Tz_student_roster_html.dta
keep s
keep in 1
rename s source_html 

**Splitting and Parsing
split source_html, parse("<TR>") limit(100) gen(v)
drop source_html

**Reshaping to create 1 row per TR tag
gen id = 1
reshape long v, i(id) j(row_number)

keep if strpos(v, "PS0101114-") > 0
rename v raw_data

**Extracting Required Variables

gen schoolcode = "PS0101114"
gen cand_id = ustrregexs(1) if ustrregexm(raw_data, "(PS0101114-[0-9]+)")
gen prem_number = ustrregexs(1) if ustrregexm(raw_data, "([0-9]{11})")
gen gender = ""
replace gender = "M" if ustrregexm(raw_data, ">M</FONT>")
replace gender = "F" if ustrregexm(raw_data, ">F</FONT>")
gen name = ustrregexs(1) if ustrregexm(raw_data, "<P>([A-Z ]+)</FONT>")

gen kiswahili = ustrregexs(1) if ustrregexm(raw_data, "Kiswahili - ([A-F])")
gen english   = ustrregexs(1) if ustrregexm(raw_data, "English - ([A-F])")
gen maarifa   = ustrregexs(1) if ustrregexm(raw_data, "Maarifa - ([A-F])")
gen hisabati  = ustrregexs(1) if ustrregexm(raw_data, "Hisabati - ([A-F])")
gen science   = ustrregexs(1) if ustrregexm(raw_data, "Science - ([A-F])")
gen uraia     = ustrregexs(1) if ustrregexm(raw_data, "Uraia - ([A-F])")
gen average   = ustrregexs(1) if ustrregexm(raw_data, "Average Grade - ([A-F])")

**Clean Up
keep schoolcode cand_id prem_number gender name kiswahili english maarifa hisabati science uraia average

