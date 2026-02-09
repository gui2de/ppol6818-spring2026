***** Assignment Stata 1 *****
***** Gavin Gondalwala *****

cd /Users/gavinaligondalwala/Documents/Georgetown/Spring2026/ExperimentalDesign/ExpDesStata1/Stata1_Data

*** Question 1: Cleaning ***
use teacher
merge m:1 school using school.dta
tab _merge
drop _merge
save /Users/gavinaligondalwala/Documents/Georgetown/Spring2026/ExperimentalDesign/ExpDesStata1/Stata1_Data/teacher_school.dta

use student
rename primary_teacher teacher
merge m:1 teacher using teacher_school.dta
tab _merge
drop _merge
save /Users/gavinaligondalwala/Documents/Georgetown/Spring2026/ExperimentalDesign/ExpDesStata1/Stata1_Data/teacher_school_student.dta

tab subject
merge m:1 subject using subject.dta
tab _merge
drop _merge
rename stdnt_num student
save /Users/gavinaligondalwala/Documents/Georgetown/Spring2026/ExperimentalDesign/ExpDesStata1/Stata1_Data/teacher_school_student_subject.dta

*****************************************

*** Question 1 ***
** a.
use teacher_school_student_subject
tab attendance, missing
sum attendance
sum attend if loc=="South"

* The mean student attendance for schools in the South is 177.4776 days per student

** b.
tab teacher subject /* No teacher teaches two subjects -- NTS: ??? Would there have been an easier way to do this? ie. Gondalwala teaches Math (tested) and Other (Untested) */
sum student if level=="High" /* 1,379 total high schoolers */
sum student if level=="High" & tested==1 /* 610 students */
display 610/1379 /* = .44234953 */

* 0.4423, or 44.23%, of students enrolled in high school have a primary teacher who teaches a tested subject

** c.
/* NTS: use school
sum gpa
the result is 3.604183. 
Why is this not the same as the entire data set, when the average of a school is what is filled in to each student? Since different numbers of students per school?*/

sum gpa /* using teacher_school_student_subject.dta */

* The mean GPA of all students in the district is 3.60144

** d.
bysort school: sum attendance if level=="Middle"

/* The mean attendance days for each middle school are
- Joseph Darby Middle School: 177.4408 days
- Mahatma Ghandi Middle School: 177.3344 days
- Malala Yousafzai Middle School: 177.5478 days
*/


*****************************************************

*** Question 2 ***
use q2_village_pixel

** a.
help bysort

bysort pixel: egen min_payout = min(payout)
bysort pixel: egen max_payout = max(payout)
gen pixel_consistent=1 if min_payout==max_payout /* 1= same payouts, 0=different patouts */
drop min_payout max_payout
/* NTS:
tab pixel payout
gen pixel_consistent=1
? Why couldn't I just do this? When wouldn't this have worked?
*/

** b. 
tab pixel 
destring pixel, generate(pixel_destring) ignore("KE" [, ignoreopts]) /* tabbed to confirm all pixels start with KE, then destring for bysort because of error "type mismatch"
? NTS: Why did I not get this above? */

bysort village: egen min_pixel = min(pixel_de)
bysort village: egen max_pixel = max(pixel_de)
gen pixel_village=0 if min_pixel==max_pixel /* 0=all households w/i village in 1 pixel. 1= split pixels */
replace pixel_village=1 if min_pixel != max_pixel
drop min_pix max_pix

** c. 
gen partc = 1 if pixel_village==0 /* Villages that are entirely within a pixel take the value of 1 from Part B. */
replace partc=2 if pixel_village==1 & pixel_consistent==1
replace partc=3 if pixel_village==1 & pixel_consistent==0

list hhid if partc==2
/* Household IDs of homes in villages that span multiple pixels but have the same payout:
110202203 |
 49. | 110202207 |
 50. | 110202210 |
 51. | 110202212 |
 52. | 110202201 |
     |-----------|
 55. | 110202505 |
 56. | 110202510 |
 57. | 110202506 |
 58. | 110202501 |
 59. | 110202509 |
     |-----------|
 82. | 110203507 |
 83. | 110203505 |
 84. | 110203509 |
170. | 120507104 |
171. | 120507102 |
     |-----------|
172. | 120507101 |
173. | 120507103 |
174. | 120507111 |
201. | 120508209 |
202. | 120508202 |
     |-----------|
203. | 120508204 |
204. | 120508206 |
205. | 120508203 |
206. | 120508208 |
255. | 120610109 |
     |-----------|
256. | 120610102 |
257. | 120610107 |
258. | 120610103 |
266. | 120610609 |
267. | 120610602 |
     |-----------|
268. | 120610604 |
269. | 120610605 |
278. | 120611108 |
279. | 120611101 |
280. | 120611102 |
     |-----------|
281. | 120611201 |
282. | 120611205 |
283. | 120611209 |
284. | 120611210 |
285. | 120611206 |
     |-----------|
312. | 120712310 |
313. | 120712305 |
321. | 120712803 |
322. | 120712801 |
342. | 120813811 |
     |-----------|
343. | 120813803 |
344. | 120813807 |
345. | 120813801 |
346. | 120813804 |
375. | 120814710 |
     |-----------|
376. | 120814703 |
377. | 120814711 |
378. | 120814702 |
379. | 120814705 |
380. | 120814704 |
     |-----------|
385. | 120814907 |
386. | 120814911 |
387. | 120814901 |
388. | 120814903 |
492. | 121019210 |
     |-----------|
493. | 121019203 |
494. | 121019201 |
495. | 121019204 |
496. | 121019209 |
497. | 121019208 |
     |-----------|
498. | 121019306 |
499. | 121019308 |
500. | 121019309 |
534. | 131120510 |
535. | 131120509 |
     |-----------|
536. | 131120506 |
571. | 131221912 |
572. | 131221904 |
573. | 131221905 |
574. | 131221901 |
     |-----------|
575. | 131221909 |
615. | 131424204 |
616. | 131424211 |
617. | 131424206 |
618. | 131424205 |
     |-----------|
635. | 131424609 |
636. | 131424610 |
637. | 131424602 |
638. | 131424604 |
651. | 141525312 |
     |-----------|
652. | 141525310 |
653. | 141525302 |
654. | 141525309 |
718. | 141627407 |
719. | 141627401 |
     |-----------|
720. | 141627408 |
721. | 141627412 |
722. | 141627405 |
728. | 141727707 |
729. | 141727712 |
     |-----------|
730. | 141727709 |
731. | 141727701 |
739. | 141728101 |
740. | 141728102 |
741. | 141728108 |
     |-----------|
742. | 141728103 |
755. | 141728601 |
756. | 141728606 |
757. | 141728608 |
758. | 141728607 |
     |-----------|
759. | 141728603 |
828. | 152431708 |
829. | 152431707 |
830. | 152431702 |
831. | 152431706 |
     |-----------|
832. | 152431703 |
865. | 162533002 |
866. | 162533008 |
872. | 162533401 |
873. | 162533408 |
     |-----------|
890. | 162633907 |
891. | 162633912 |
892. | 162633908 |
893. | 162633906 |
894. | 162633902 |
     |-----------|
895. | 162633905 |
950. | 131336101 |
951. | 131336107 |
952. | 131336109 |
*/


************************************

*** Question 3 ***
use q3_proposal_review
rename Rewiewer1 Reviewer1

rename Review1Score scorerev1
rename Reviewer2Score scorerev2
rename Reviewer3Score scorerev3

reshape long Reviewer scorerev, i(proposal_id) j(number)

bysort Reviewer: sum scorerev

bysort Reviewer: egen meanrev = mean(scorerev)
bysort Reviewer: egen sdrev = sd(scorerev)
***
reshape wide Reviewer scorerev meanrev sdrev, i(proposal_id) j(number)

gen stand_r1_score=((scorerev1-meanrev1)/sdrev1), after (Reviewer1)
gen stand_r2_score=((scorerev2-meanrev2)/sdrev2), after (Reviewer2)
gen stand_r3_score=((scorerev3-meanrev3)/sdrev3), after (Reviewer3)

gen average_stand_score=((stand_r1_score+stand_r2_score+stand_r3_score)/3), after(proposal_id)

gsort -average_stand_score

egen proposal_rank = rank(average_stand_score), field
order proposal_rank, after(average_stand_score)


**************************************

*** Question 4 ***
*** Hint ***
global wd "/Users/gavinaligondalwala/Documents/Georgetown/Spring2026/ExperimentalDesign/ExpDesStata1"

global excel_t21 "$wd/q4_Pakistan_district_table21.xlsx"

clear

tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135) this will take 1-5 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
	display as error `i' //display the loop number

	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	rename TABLE21PAKISTANICITIZEN1 table21

	
	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %40s table21 B C D E F G H I J K L M N O P Q R S T U V W X Y  Z AA AB AC

********* Mine 
order table, before(table21)

rename (B-AC) col#, addnumber

reshape long col, i(table) j(orig_order)

drop if col == ""

bysort table (orig_order): gen new_order = _n

drop table21
drop orig_order

reshape wide col, i(table) j(new_order)


********************************************************************************

*** Question 5 ***

use q5_Tz_student_roster_html
import delimited using "shl_ps0101114.html", delimiter("|") clear varnames(nonames)

gen school_avg = ""
replace school_avg = substr(v1, strpos(v1, ":") + 1, .) if strpos(v1, "WASTANI WA SHULE")

gen testers = ""
replace testers = substr(v1, strpos(v1, ":") + 1, .) if strpos(v1, "WALIOFANYA MTIHANI")

gen student_group = ""
replace student_group = substr(v1, strpos(v1, ":") + 1, .) + " (Under 40)" if strpos(v1, "KUNDI LA SHULE")

gen council_rank = ""
replace council_rank = substr(v1, strpos(v1, ":") + 1, .) if strpos(v1, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI")

gen region_rank = ""
replace region_rank = substr(v1, strpos(v1, ":") + 1, .) if strpos(v1, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA")

gen national_rank = ""
replace national_rank = substr(v1, strpos(v1, ":") + 1, .) if strpos(v1, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA")

gen school_name = "ALBEHIJE PRIMARY SCHOOL" if strpos(v1, "SCHOOL")

gen school_code = "PS0101114" if strpos(v1, "PS0101114")

drop if missing(school_avg) & missing(testers) & missing(student_group) & missing(council_rank) & missing(region_rank) & missing(national_rank) & missing(school_name) & missing(school_code)

collapse (firstnm) school_avg testers student_group council_rank region_rank national_rank school_name school_code

order school_name school_code, before(school_avg)

foreach var of varlist *_rank {
    
    split `var', parse(" kati ya") limit(1)
    
	drop `var'
	
}

foreach var of varlist *_rank1 {
    
    destring `var', replace 
	
}

foreach var of varlist _all {
    capture confirm string variable `var'
    if !_rc {
        replace `var' = stritrim(trim(`var'))
    }
}


foreach var of varlist school_avg testers {
    capture confirm string variable `var'
    if !_rc {
        destring `var', replace ignore(" ")
    }
}























