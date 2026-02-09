***************************************
*Experimental Design and Implementation
*Assignment -- STATA Basic
*Warren Burroughs
***************************************

*Question 1*
cd "C:\Users\warre\OneDrive\Desktop\Georgetown\SecondSemester\Experimental_Design\Week3\assignment_ Stata 1\q1_data"
use student.dta

*Merge so each student is linked with their associated teacher
rename primary_teacher teacher
merge m:1 teacher using "teacher.dta"
drop _merge
order experience, af(teacher)

*Merge so teacher is linked with their associated school
merge m:1 school using "school.dta"
drop _merge

*Merge so subject is linked with rest of dataset
merge m:1 subject using "subject.dta"
drop _merge

save student_achievement.dta


*a) Mean student attendance for schools located in the "South"?
sum attendance if loc=="South"
/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180
*/
///The mean attendance for schools in the South is 177.4776 days.

*b) Of students in high school, what proportion have a primary teacher who teaches a tested subject (tested=1)
tab tested if level=="High"
/*
     tested |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        769       55.77       55.77
          1 |        610       44.23      100.00
------------+-----------------------------------
      Total |      1,379      100.00
*/
/// 44.23% of high school students have a primary school teacher who teaches a tested subject

*c) What is the mean gpa of all students in the district?
sum gpa
/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334
*/
/// The GPA mean for the district is 3.60144

*d) Mean attendance for each middle school?
bysort school: sum attendance if level=="Middle" //Show me for each school the summary statistics if the level is middle school.
/*
-> school = Joseph Darby Middle School

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        304    177.4408    2.824302        165        180

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-> school = Mahatma Ghandi Middle School

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        317    177.3344    3.256228        153        180

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-> school = Malala Yousafzai Middle School

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        418    177.5478    2.823991        162        180
*/
/// Joseph Darby Middle School: 177.4408
/// Mahatma Ghandi Middle School: 177.3344 
/// Malala Yousafzai Middle School: 177.5478

clear

*Question 2*
cd "C:\Users\warre\OneDrive\Desktop\Georgetown\SecondSemester\Experimental_Design\Week3\assignment_ Stata 1"

use q2_village_pixel

*a) Create a dummy variable showing whether or not there is variation in payout status
bysort pixel: tab payout
/*
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-> pixel = KE3556

     payout |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        117      100.00      100.00
------------+-----------------------------------
      Total |        117      100.00

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-> pixel = KE3557

     payout |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        236      100.00      100.00
------------+-----------------------------------
      Total |        236      100.00

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-> pixel = KE3558

     payout |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        104      100.00      100.00
------------+-----------------------------------
      Total |        104      100.00

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-> pixel = KE3631

     payout |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        154      100.00      100.00
------------+-----------------------------------
      Total |        154      100.00

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-> pixel = KE3632

     payout |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        291      100.00      100.00
------------+-----------------------------------
      Total |        291      100.00

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-> pixel = KE3633

     payout |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |         56      100.00      100.00
------------+-----------------------------------
      Total |         56      100.00
*/
///All pixels are consistent. I told STATA look at each pixel and tell me how many ones and zeros there are for each pixel. This tabstat shows that all pixels are pixel consistent.
gen pixel_consistenet=1 
///Or do by pixel: pixel_consistent=1 if payout=1 & payout=2

*b) Create a dummy variable that shows when a village exists in multiple pixels.

bysort village: gen hhnum = _n // allows us to see which households are in the same village
bysort village pixel: gen unique = _n == 1 // Generates a tag that displays if a household is in a unique pixel (first household is always in a unique pixel)
bysort village: egen boundaries = total(unique) // Shows how many pixels a village is in.
tab village if boundaries==2 //Shows which villages are in 2 pixels
/*
    Please select the |
 name of the village. |      Freq.     Percent        Cum.
----------------------+-----------------------------------
             MUDHIERO |          5        4.03        4.03
               MUNJAL |          5        4.03        8.06
                 YIEM |          3        2.42       10.48
               HAWONO |          5        4.03       14.52
                ORAWO |          6        4.84       19.35
          KOMBO OPIYO |          4        3.23       22.58
            OGUDA 'A' |          4        3.23       25.81
                 SIND |          3        2.42       28.23
                 UYON |          5        4.03       32.26
               MUMBIA |          2        1.61       33.87
          OCHIENG 'D' |          2        1.61       35.48
       LINGANYIRO 'B' |          5        4.03       39.52
              OMBONYA |          6        4.84       44.35
          ONYANGO 'A' |          4        3.23       47.58
          OGARAMA 'A' |          6        4.84       52.42
          OGARAMA 'B' |          3        2.42       54.84
            UKAKA 'A' |          3        2.42       57.26
           UKANDA 'B' |          5        4.03       61.29
                LUNGA |          4        3.23       64.52
                SKALA |          4        3.23       67.74
               HULWIK |          4        3.23       70.97
               USIDIA |          5        4.03       75.00
                DHILA |          4        3.23       78.23
              MALOMBA |          4        3.23       81.45
              NYATOMA |          5        4.03       85.48
              KANYAVA |          5        4.03       89.52
          KOBIERO 'B' |          2        1.61       91.13
             NYALWENY |          2        1.61       92.74
                IDIGO |          6        4.84       97.58
              KISENYE |          3        2.42      100.00
----------------------+-----------------------------------
                Total |        124      100.00

*/
gen pixel_village = 1 if boundaries>1 //For villages that are in more than one pixel, mark it as 1
replace pixel_village = 0 if pixel_village==. // For vilalges that are in only one pixel, mark it as 0
gen id_pixel_village = 1 if pixel_village == 1 & hhnum == 1
tab id_pixel_village // Allows us to see how many villages are in pixel_village
/*
id_pixel_vi |
      llage |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |         30      100.00      100.00
------------+-----------------------------------
      Total |         30      100.00
*/
list village if id_pixel_village == 1 // Tells us which villages are in pixel_village

*c) 
gen pixel_check = 1 if pixel_village==0 // 1 if village is in only 1 pixel
sort village pixel // Sort so villages are together but payout is also ordered
bysort village: replace pixel_check = 3 if payout[1] != payout[_N] & pixel_village==1 // For a village, if the first observation in payout is 0, but the last observation in payout is 1, and they span multiple villages, mark pixel_check as 3
bysort village: replace pixel_check = 2 if pixel_village==1 & payout[1] == payout[_N] // For a village, if the first and last observation of the village have the same payout, then mark as 2.


*Question 3*
clear
use q3_proposal_review
rename Rewiewer1 Reviewer1
rename Review1Score Reviewer1Score // Variable names spelled incorrectly/there are discrepancies in naming

*Make a loop so each reviewer has their own variable which records each score they've given
foreach r in ahs103 am3944 ass95 ato12 bp557 fg443 ft227 glp38 mp1792 nbs56 nd549 oo140 sa1600 scb136 yc577 ynd3 {
	gen `r'_score = Reviewer1Score if Reviewer1 =="`r'"
	replace `r'_score = Reviewer2Score if Reviewer2 =="`r'"
	replace `r'_score = Reviewer3Score if Reviewer3 =="`r'"
	egen mean_`r' = mean(`r'_score) //Generate variable for each reviewer's mean and standard deviation
	egen sd_`r' = sd(`r'_score)
}
*Q3.1
*Generate the standardized score after the nonstandardized score (Variable with a lot of missing observations for now)
gen stand_r1_score=., af(Reviewer1Score)
gen stand_r2_score=., af(Reviewer2Score)
gen stand_r3_score=., af(Reviewer3Score)
*In each of the standardized variables, add the standardized score by using the formula St Score = (score-mean)/sd
foreach r in ahs103 am3944 ass95 ato12 bp557 fg443 ft227 glp38 mp1792 nbs56 nd549 oo140 sa1600 scb136 yc577 ynd3 {
	replace stand_r1_score = (Reviewer1Score - mean_`r')/sd_`r' if Reviewer1=="`r'"
	replace stand_r2_score = (Reviewer2Score - mean_`r')/sd_`r' if Reviewer2=="`r'"
	replace stand_r3_score = (Reviewer3Score - mean_`r')/sd_`r' if Reviewer3=="`r'"
}

*b)
*Generate a variable that shows the average standard score for each proposal
gen avg_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score)/3, af(AverageScore)

*c)
*Rank each proposal based on average standard score.
gsort -avg_stand_score
gen rank=_n, af(avg_stand_score)

*Question 4*
global wd "\Users\warre\OneDrive\Desktop\Georgetown\SecondSemester\Experimental_Design\Week3\assignment_ Stata 1"
global excel_t21 "$wd/q4_Pakistan_district_table21.xlsx"
clear

*setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135) this will take 1-5 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring  //import
	display as error `i' //display the loop number

	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	*regexm is used to find words or patterns in code. This code is saying to keep only if "18 AND" is found in the code. 
	keep in 1 //there are 3 of them, but we want the first one (the others are for urban and rural)
	
	*Loop through every variable in the dataset
	foreach var of varlist _all{
		*If there are missing rows, without printing to the screen, count it
		quietly count if missing(`var')
		*Check the saved result. If r(N) is 1, then the variable is empty.
		if r(N) == 1 {
			*Delete the variable
			drop `var'
			*Print a message saying that the variable is dropped
			display "Drop empty variable `var'"
		}
 	}
	
	**Alternatively, we could download the ssc package "missing" which would do the same thing as above
	
	**Make variables a number (if we don't do this it's going to append weirdly)
	rename * var#, addnumber // * is wildcard; rename every variable with a number in consectutive order
	rename var1 table21
	
	*Get rid of discrepencies in naming
	replace table21 = "18 AND ABOVE" if regexm(table21, "18 AND") | regexm(table21, "OVERALL")
	
	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}

*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %40s table21 var*

*Rename to display data from excel
rename var2 all_totalpop
rename var3 all_CNI
rename var4 all_noCNI
rename var5 m_totalpop
rename var6 m_CNI
rename var7 m_noCNI
rename var8 f_totalpop
rename var9 f_CNI
rename var10 f_noCNI
rename var11 trans_totalpop
rename var12 trans_CNI
rename var13 trans_noCNI

save pakistan_ID_bydistrict.dta



*Question 5*
clear

*Import file
import delimited "shl_ps0101114.html", delimiter("|") // We add a character that's not in any of the code so each line of code becomes it's own observation

*Identify the rows with data
drop if !strpos(v1, "ALBEHIJE PRIMARY SCHOOL - PS0101114") & !strpos(v1, "WASTANI WA SHULE") & !strpos(v1, "KUNDI LA SHULE : Wanafunzi chini ya 40") & !strpos(v1, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI: 22 kati ya 46") & !strpos(v1, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA  : 74 kati ya 290") & !strpos(v1, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA : 545 kati ya 5664") & !strpos(v1, "WALIOFANYA MTIHANI : 16")

//ssc install sxpose2

sxpose2, clear // Turns observations in v1 to variables

*Create School Name and School ID
rename _var1 school
split school, parse("-") gen(part)
rename part1 school_n
rename part2 school_id
order school_n school_id, b(school)
replace school_n = "ALBEHIJE PRIMARY SCHOOL"
drop school

*Destring and translate number of test takers
rename _var2 test_takers
label variable test_takers "Number of Test Takers"
destring test_takers, replace ignore("WALIOFANYA MTIHANI : ")

*Destring and translate average grade
rename _var3 avg_grade
label variable avg_grade "Average Grade"
destring avg_grade, replace ignore("WASTANI WA SHULE  :")

*Destring and translate under or over 40
rename _var4 group
label variable group "1 = Under 40 2 = Above 40"
destring group, replace ignore("KUNDI LA SHULE : Wanafunzi chini ya ")
recode group (40=1)

*Destring and translate council ranking
rename _var5 council
label variable council "Rank in Council out of 46"
destring council, replace ignore("NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI: " " kati ya 46")

*Destring and translate region ranking
rename _var6 regional 
label variable regional "Rank in Region out of 290"
destring regional, replace ignore("NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA  : " "kati ya 290")

*Destring and translate national ranking
rename _var7 national
label variable national "Rank in Nation out of 5664"
destring national, replace ignore("NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA : " "kati ya 5664")
recode national (.=545)















