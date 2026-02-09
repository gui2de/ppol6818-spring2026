*Question 1*
use "teacher.dta"
merge m:1 school using "school.dta"
drop _merge
merge m:1 subject using "subject.dta"
drop _merge
rename teacher primary_teacher
merge 1:m primary_teacher using "student.dta"
(a)
. sum attend if loc=="South"

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180
//The mean student attendance for school located in the "south" is about 177.4776

(b)

. tab test if grade<=12 & grade>=9

     tested |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        769       55.77       55.77
          1 |        610       44.23      100.00
------------+-----------------------------------
      Total |      1,379      100.00

//44.23% have a primary teacher who teaches a tested subject.

(c) 
. sum gpa

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334
//The average GPA in the district is about 3.60.

(d)
.
. sum attend if school=="Joseph Darby Middle School"

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        304    177.4408    2.824302        165        180

. sum attend if school=="Mahatma Ghandi Middle School"

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        317    177.3344    3.256228        153        180

. sum attend if school=="Malala Yousafzai Middle School"

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        418    177.5478    2.823991        162        180
//The mean attendance in Joseph Darby Middle School is about 177.4408, the mean attendance in Mahatma Ghandi Middle school is about 177.3344, the mean attendance in Malala Yousafzai Middle school is about 177.5478.

Question 2
use "q2_village_pixel.dta"
(a)
bysort pixel: egen payout_min = min(payout)
bysort pixel: egen payout_max = max(payout)
gen pixel_consistent = (payout_min == payout_max)
list pixel if pixel_consistent == 0, sepby(pixel)

(B)
bysort village pixel: gen pixel_tag = (_n == 1)
bysort village: egen n_pixels_village = total(pixel_tag)
generate pixel_village = 0 if n_pixels_village == 1
replace pixel_village = 1 if pixel_village == .

(c)
bysort village: egen village_payout_min = min(payout)
bysort village: egen village_payout_max = max(payout)
gen village_payout_diff = 1 if village_payout_min != village_payout_max
replace village_payout_diff = 0 if village_payout_diff == .
replace village_pixel_class = 1 if pixel_village == 0
replace village_pixel_class = 2 if pixel_village == 1 & village_payout_diff == 0
replace village_pixel_class = 3 if pixel_village == 1 & village_payout_diff == 1

Question 3
(a)
use "q3_proposal_review.dta"
rename Rewiewer1 Reviewer1
rename Review1Score ReviewScore1
rename Reviewer2Score ReviewScore2
rename Reviewer3Score ReviewScore3
reshape long Reviewer ReviewScore, i(proposal_id) j(Reviewnumber)
generate stand_r1_score = (ReviewScore - AverageScore)/StandardDevia if Reviewnumber == 1
generate stand_r2_score = (ReviewScore - AverageScore)/StandardDevia if Reviewnumber == 2
generate stand_r3_score = (ReviewScore - AverageScore)/StandardDevia if Reviewnumber == 3

(b)
replace stand_r1_score = 0 if stand_r1_score == .
replace stand_r2_score = 0 if stand_r2_score == .
replace stand_r3_score = 0 if stand_r3_score == .
gen total_stand_score = stand_r1_score +  stand_r2_score + stand_r3_score
bysort proposal_id: egen average_total_stand_score = mean(total_stand_score)

(c)
gsort -average_stand_score
gen rank = _n

Question 4
global wd "/Users/ah1152/Desktop/ppol6618"
*update the wd global so that it refers to the Box folder filepath on your machine

global excel_t21 "$wd//week_03/04_assignment/01_data/q4_Pakistan_district_table21.xlsx"

clear

*setting up an empty tempfile
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

Question 5
/*I got some of answers for question 5 through google translation
(a) there are 16 students who took the test
(b) The average score in the school is about 217.3750
(c) The student group is under 40
(d) The rank in the council is 22
(e) The rank in the region is 74
(f) The rank in the whole country is 545. */
use "q5_Tz_student_roster_html.dta"
generate number_test = 16
generate average_score = 217.3750
generate student_group<40 = 1
generate rank_council = 22
generate rank_region = 74
generate rank_country = 545







