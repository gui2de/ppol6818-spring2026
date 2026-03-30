**********Question 1***********

*** preparation ***
cd C:\Users\24547\Desktop\stata1\q1_data
use student.dta, clear
rename primary_teacher teacher
merge m:1 teacher using teacher.dta
drop _merge
merge m:1 school using school.dta
drop _merge
save student_teacher_school_merged.dta, replace 
browse
merge m:1 subject using subject.dta
drop _merge
save final.dta, replace

**Question a**
summarize attendance if loc == "South"
*The mean value is 177.4746

**Question b**
tab tested if level == "High", missing
*The proportion of having a primary teacher who teaches a tested subject is 44.23%.(TESTED=1)*

**Question c**
summarize gpa
*The mean gpa of all students in the district is 3.60144.

**Question d**
bysort school:summarize attendance if level == "Middle"

*Joseph Darby Middle School mean value :177.4408
*Mahatma Ghandi Middle School mean value:177.3344
*Malala Yousafzai Middle School mean value:177.5458

/*Comments from Ziqiao-Question1
The codes for Question 1 ran smoothly.
In Question d, while your code technically produced the correct means 
for Middle schools, I noticed that the output was cluttered with '0 observations' 
for all Elementary and High schools. 

I would recommend 
using the tabstat command with a by(school) option. 

Also, I noticed a minor decimal rounding discrepancy in your written comments 
for Question a and d compared to the Stata results—I've flagged those in the code.
For question a, the mean is 177.4776; 
For question d, the mean of Malala Yousafzai Middle School mean value:177.5478

. summarize attendance if loc == "South"

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180


-> school = Malala Yousafzai Middle School

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        418    177.5478    2.823991        162        180

--------------------------------------------------------------------------------------------------------------------
*/


***********Question 2*************
cd C:\Users\24547\Desktop\stata1
use q2_village_pixel.dta, clear

**Question a**
bysort pixel: egen min_pay = min(payout)
bysort pixel: egen max_pay = max(payout)

gen pixel_consistent = (min_pay == max_pay)
tab pixel_consistent

*From the result we can see all variables are consistent.

**Question b**
sort village pixel
by village pixel: gen tag = (_n == 1)
by village: egen n_pix = total(tag)
gen pixel_village = (n_pix > 1)
tab pixel_village

*From the result of tab command, only 12.94% fall within more than one pixel.


**Question c**
bysort village pixel: egen pay_pix = min(payout)
bysort village pixel: gen tag_pix = (_n==1)

bysort village: egen vmin = min(cond(tag_pix==1, pay_pix, .))
bysort village: egen vmax = max(cond(tag_pix==1, pay_pix, .))

gen payout_diff_across_pixels = (vmin != vmax)

gen village_class = .
replace village_class = 1 if pixel_village==0
replace village_class = 2 if pixel_village==1 & payout_diff_across_pixels==0
replace village_class = 3 if pixel_village==1 & payout_diff_across_pixels==1

tab village_class

preserve
keep if village_class==2
keep hhid
duplicates drop
list hhid
restore

**The id of villages that span multiple pixels but have the same payout status across pixels are shown here.


/*Comments from Ziqiao-Question 2
The code for Question 2 ran smoothly
Question b: you used sort and by as two separate commands. I suggest combining 
them into bysort, which is more efficient and readable.
For Question c, our logic was similar, but you used a more complex method 
with the cond() function inside egen to handle village-level payouts. 
My approach was slightly more direct, but yours is equally valid!
*/


******Question 3********

**Q1
cd "C:\Users\24547\Desktop\stata1"
use "q3_proposal_review.dta", clear
rename Rewiewer1 reviewer1
rename Reviewer2 reviewer2
rename Reviewer3 reviewer3

rename Review1Score score1
rename Reviewer2Score score2
rename Reviewer3Score score3

reshape long reviewer score, i(proposal_id) j(pos)

bysort reviewer: egen mean_r = mean(score)
bysort reviewer: egen sd_r   = sd(score)

gen stand_score = (score - mean_r) / sd_r

drop mean_r sd_r
reshape wide reviewer score stand_score, i(proposal_id) j(pos)

rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score


**Q2

tab stand_r1_score, missing
tab stand_r2_score, missing
tab stand_r3_score, missing  ///In order to check if there is missing value.

gen average_standard_score = (stand_r1_score + stand_r2_score + stand_r3_score) / 3

**Q3

egen rank = rank(-average_standard_score)

/*Comments from Ziqiao-Question 3
All codes in Question 3 ran smoothly.
For Q2, I used rowmean(stand_r1_score stand_r2_score stand_r3_score). 
Using the arithmetic formula (a+b+c)/3 to calculate averages is risky in Stata 
if there are missing values. If one reviewer didn't provide a score, 
the entire calculation would return a missing value. Therefore, I recommend using rowmean
For Q3, I really liked your use of egen rank. In my own assignment, 
I used gsort and _n, which creates a simple sequential list but doesn't 
handle tied scores as well as your method does. 
*/


********Question 4***********

clear all
set more off

global wd "C:\Users\24547\Desktop\stata1" 
global excel_t21 "$wd/q4_Pakistan_district_table21.xlsx"


clear

tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135)
forvalues i = 1/135 {

    import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring
    display as error "`i'"

    keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND") == 1
    keep in 1

    rename TABLE21PAKISTANICITIZEN1 table21
    gen table = `i'
*Identify all variables in the current sheet
    ds
    local allvars `r(varlist)'
*Exclude non-numeric candidates (text label and sheet id)	
    local candvars : list allvars - table21
    local candvars : list candvars - table
*Clean and convert candidate columns to numeric
    foreach x of local candvars {
        capture confirm variable `x'
        if _rc continue
        capture replace `x' = subinstr(`x', ",", "", .)
        capture destring `x', replace force
    }
*Collect columns with valid numeric values and compress into v2–v13
    local j = 2
    foreach x of local candvars {
        capture confirm variable `x'
        if _rc continue
        quietly summarize `x'
        if r(N) > 0 & r(min) < . {
            gen v`j' = `x'
            local ++j
            if `j' > 13 continue, break
        }
    }
*Fill remaining columns with missing values if fewer than 12 numeric columns
    forvalues k = `j'/13 {
        gen v`k' = .
    }
*Keep only the standardized output variables
    keep table table21 v2-v13
   
    append using `table21'
    save `table21', replace
}

use `table21', clear

/*Comments from Ziqiao-Question 4
All codes ran smoothly.
We approached the 'numeric cleaning' differently. 
You used destring inside the loop with subinstr to remove commas. 
My approach was more focused on identifying columns by their physical order. 
Your method of checking r(min) < . to verify valid numeric data is a clever way to ensure column consistency.
*/

********Question 5**********

clear all
set more off
use "C:\Users\24547\Desktop\stata1\q5\q5_Tz_student_roster_html.dta", clear
rename s html_line
replace html_line = ustrtrim(html_line)
gen strL html = ""
quietly {
    forvalues i = 1/`=_N' {
        replace html = html + " " + html_line[`i'] in 1
    }
}
keep in 1

* Clean
replace html = ustrregexra(html, "[\r\n\t]+", " ")
replace html = ustrregexra(html, "\s+", " ")
replace html = upper(html)

* Gen variables
gen str80 school_name = ""
gen str20 school_code = ""
gen took_test = .
gen avg_score = .
gen byte group_under40 = .   
gen council_rank = .
gen council_total = .
gen region_rank = .
gen region_total = .
gen national_rank = .
gen national_total = .

* Scratch school name and code
replace school_code = ustrregexs(1) if ustrregexm(html, "(PS[0-9]{7,})")
replace school_name = strtrim(ustrregexs(1)) if ustrregexm(html, "([A-Z0-9 \.\-']+?)\s*-\s*PS[0-9]{7,}")
replace school_name = strtrim(ustrregexs(1)) if ustrregexm(html, "([A-Z0-9 \.\-']+?PRIMARY SCHOOL)\s*-\s*(PS[0-9]{7,})")
replace school_name = proper(school_name)

* Number of students who took the test & avg scores
replace took_test = real(ustrregexs(1)) if ustrregexm(html, "WALIOFANYA MTIHANI\s*:\s*([0-9]{1,5})")
replace avg_score = real(ustrregexs(1)) if ustrregexm(html, "WASTANI WA SHULE\s*:\s*([0-9]+(\.[0-9]+)?)")

* Student group（under40 vs 40+）
replace group_under40 = 1 if ustrregexm(html, "KUNDI LA SHULE\s*:\s*WANAfunzi CHINI YA 40") | ///
                            ustrregexm(html, "KUNDI LA SHULE\s*:\s*WANAfunzi\s*CHINI\s*YA\s*40")

replace group_under40 = 0 if ustrregexm(html, "KUNDI LA SHULE\s*:\s*WANAfunzi\s*40\s*AU\s*ZAIDI")

* Rank: x kati ya y
* council: KIH...MASHAURI
* region : KIMKOA
* national: KITAIFA
replace council_rank  = real(ustrregexs(1)) if ustrregexm(html, "KIHALMASHAURI\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")
replace council_total = real(ustrregexs(2)) if ustrregexm(html, "KIHALMASHAURI\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")

replace region_rank  = real(ustrregexs(1)) if ustrregexm(html, "KIMKOA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")
replace region_total = real(ustrregexs(2)) if ustrregexm(html, "KIMKOA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")

replace national_rank  = real(ustrregexs(1)) if ustrregexm(html, "KITAIFA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")
replace national_total = real(ustrregexs(2)) if ustrregexm(html, "KITAIFA\s*:\s*([0-9]{1,5})\s*KATI YA\s*([0-9]{1,5})")

keep school_name school_code took_test avg_score group_under40 ///
     council_rank council_total region_rank region_total national_rank national_total
list, noobs
save "q5_school_level_summary.dta", replace

/*Comments from Ziqiao-Question 5
We used very different methods: 
you treated the entire HTML as one long string in one observation, 
while I treated it as multiple rows and used collapse. 
Your method avoids row-filling (_n-1). I think it's very smart to do so!
*/


********Bonus Question*******

clear all
set more off
cd C:\Users\24547\Desktop\stata1\q5
local fpath "shl_ps0101114.html"

clear
set obs 1
gen strL rest = ""

file open fh using "`fpath'", read text
file read fh line
while r(eof)==0 {
    replace rest = rest + " " + `"`line'"' in 1
    file read fh line
}
file close fh


replace rest = ustrregexra(rest, "[\r\n\t]+", " ")
replace rest = ustrregexra(rest, "\s+", " ")


tempname H
tempfile out
postfile `H' str15 schoolcode str20 cand_id str1 gender str20 prem_number ///
              str80 name str1 kiswahili str1 english str1 maarifa str1 hisabati ///
              str1 science str1 uraia str1 average using `out', replace


local rowpat "<TR><TD[^>]*>[^<]*<FONT[^>]*><P[^>]*>(PS[0-9]+-[0-9]+)</FONT></TD>.*?<P[^>]*>([0-9]+)</FONT></TD>.*?<P[^>]*>([MF])</FONT></TD>.*?<P>([^<]+)</FONT></TD>.*?<P[^>]*>([^<]*Average Grade[^<]*)</FONT>"


while ustrregexm(rest[1], "`rowpat'") {
    local cand = ustrregexs(1)
    local prem = ustrregexs(2)
    local sex  = ustrregexs(3)
    local nm   = ustrtrim(ustrregexs(4))
    local gstr = ustrtrim(ustrregexs(5))

    
    local sc = ustrregexra("`cand'", "-.*$", "")

    
    local kis "" 
    local eng ""
    local maa ""
    local his ""
    local sci ""
    local ura ""
    local avg ""

    if ustrregexm("`gstr'", "Kiswahili\s*-\s*([A-Z])")      local kis = ustrregexs(1)
    if ustrregexm("`gstr'", "English\s*-\s*([A-Z])")        local eng = ustrregexs(1)
    if ustrregexm("`gstr'", "Maarifa\s*-\s*([A-Z])")        local maa = ustrregexs(1)
    if ustrregexm("`gstr'", "Hisabati\s*-\s*([A-Z])")       local his = ustrregexs(1)
    if ustrregexm("`gstr'", "Science\s*-\s*([A-Z])")        local sci = ustrregexs(1)
    if ustrregexm("`gstr'", "Uraia\s*-\s*([A-Z])")          local ura = ustrregexs(1)
    if ustrregexm("`gstr'", "Average Grade\s*-\s*([A-Z])")  local avg = ustrregexs(1)

    post `H' ("`sc'") ("`cand'") ("`sex'") ("`prem'") ("`nm'") ///
             ("`kis'") ("`eng'") ("`maa'") ("`his'") ("`sci'") ("`ura'") ("`avg'")

    
    local match = ustrregexs(0)
    local pos = ustrpos(rest[1], "`match'")
    replace rest = usubstr(rest, `pos' + ustrlen("`match'"), .) in 1
}

postclose `H'
use `out', clear


order schoolcode cand_id gender prem_number name kiswahili english maarifa hisabati science uraia average
compress

count
list in 1/5, noobs

save "q6_student_level.dta", replace
export delimited using "q6_student_level.csv", replace
****************************************************

/*Comments from Ziqiao-Bonus Question
The code ran smoothly.
Our logic for subject extraction was similar, but your implementation was much more efficient. 
I used a foreach loop to extract each subject, while you integrated it into the rowpat 
and then used specific if checks for each subject within the while loop. 
*/
