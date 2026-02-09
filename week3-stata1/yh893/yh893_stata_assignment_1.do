********************************************************************************
* Assisgnment: STATA 1
* Author: Yubing Han
* Date: Jan 31, 2026
********************************************************************************

clear all
set more off
cap log close
global class "/Users/serovia/Desktop/assignment__Stata_1_export"
log using "$class/output/stata1.log", replace text

********************************************************************************
* Q1
********************************************************************************

use "$class/q1_data/student.dta",clear

rename primary_teacher teacher

merge m:1 teacher using "$class/q1_data/teacher.dta"
tab _merge
drop _merge

merge m:1 school using "$class/q1_data/school.dta" 
tab _merge
drop _merge

merge m:1 subject using "$class/q1_data/subject.dta"
tab _merge 
drop _merge

save "$class/q1_data/q1_merge.dta",replace

*** （a)
sum attendance if loc == "South"
/* The mean student attendance for schools located in the "South" is 177.4776

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180

*/

***  (b)
sum tested if level=="High"

/* Among students enrolled in high school, about 44.23% of primary teacher teaches a tested subject.

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
      tested |      1,379    .4423495    .4968455          0          1

*/
	  
***  (c)
sum gpa

/* The mean GPA of all students is 3.60.

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334

*/		 
		 
***  (d)
preserve
keep if level=="Middle"

collapse (mean) mean_attendance = attendance, by(school)
sort school
list school mean_attendance

restore


/*
The mean attendance for Joseph Darby Middle School is 177.44, for Mahatma Ghandi Middle School is 177.33, and the mean attendance for Malala Yousafzai Middle School is 177.55.
     +-------------------------------------------+
     |                         school   mean_a~e |
     |-------------------------------------------|
  1. |     Joseph Darby Middle School   177.4408 |
  2. |   Mahatma Ghandi Middle School   177.3344 |
  3. | Malala Yousafzai Middle School   177.5479 |
     +-------------------------------------------+
*/

********************************************************************************
* Q2
********************************************************************************

use "$class/q2_village_pixel.dta",clear

***  (a)

bysort pixel: egen p_min = min(payout)
bysort pixel: egen p_max = max(payout)

gen pixel_consistent = (p_min == p_max)

tab pixel_consistent,mis

/* 

The payout status is consistent within each pixel.

pixel_consi |
      stent |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        958      100.00      100.00
------------+-----------------------------------
      Total |        958      100.00
*/



***  (b)

bysort village pixel: gen first = (_n == 1)
bysort village: egen total_pixels = total(first)

gen pixel_village = (total_pixels > 1)

tab pixel_village,mi

/*

pixel_villa |
         ge |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        834       87.06       87.06
          1 |        124       12.94      100.00
------------+-----------------------------------
      Total |        958      100.00
*/



***  (c)

bysort village pixel: gen tag = (_n == 1)
bysort village: egen num_pixels = total(tag)

bysort village: egen v_min = min(payout)
bysort village: egen v_max = max(payout)

gen v_pay_diff = (v_min != v_max)

gen category = .
replace category = 1 if num_pixels == 1
replace category = 2 if num_pixels > 1 & v_pay_diff == 0
replace category = 3 if num_pixels > 1 & v_pay_diff == 1

tab category
list village hhid if category == 2, clean

/*



   category |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        834       87.06       87.06
          2 |         50        5.22       92.28
          3 |         74        7.72      100.00
------------+-----------------------------------
      Total |        958      100.00

              village        hhid  
170.           HAWONO   120507103  
171.           HAWONO   120507101  
172.           HAWONO   120507102  
173.           HAWONO   120507104  
174.           HAWONO   120507111  
201.            ORAWO   120508209  
202.            ORAWO   120508202  
203.            ORAWO   120508206  
204.            ORAWO   120508208  
205.            ORAWO   120508203  
206.            ORAWO   120508204  
266.        OGUDA 'A'   120610605  
267.        OGUDA 'A'   120610602  
268.        OGUDA 'A'   120610604  
269.        OGUDA 'A'   120610609  
278.             SIND   120611102  
279.             SIND   120611101  
280.             SIND   120611108  
342.   LINGANYIRO 'B'   120813801  
343.   LINGANYIRO 'B'   120813803  
344.   LINGANYIRO 'B'   120813804  
345.   LINGANYIRO 'B'   120813811  
346.   LINGANYIRO 'B'   120813807  
385.      ONYANGO 'A'   120814911  
386.      ONYANGO 'A'   120814907  
387.      ONYANGO 'A'   120814901  
388.      ONYANGO 'A'   120814903  
534.        UKAKA 'A'   131120509  
535.        UKAKA 'A'   131120506  
536.        UKAKA 'A'   131120510  
571.       UKANDA 'B'   131221904  
572.       UKANDA 'B'   131221901  
573.       UKANDA 'B'   131221909  
574.       UKANDA 'B'   131221912  
575.       UKANDA 'B'   131221905  
615.            LUNGA   131424206  
616.            LUNGA   131424211  
617.            LUNGA   131424205  
618.            LUNGA   131424204  
635.            SKALA   131424609  
636.            SKALA   131424604  
637.            SKALA   131424610  
638.            SKALA   131424602  
739.          MALOMBA   141728101  
740.          MALOMBA   141728102  
741.          MALOMBA   141728108  
742.          MALOMBA   141728103  
950.          KISENYE   131336109  
951.          KISENYE   131336107  
952.          KISENYE   131336101  

*/


********************************************************************************
* Q3
********************************************************************************

use "$class/q3_proposal_review",clear

***  (1)

rename Rewiewer1   netid1
rename Reviewer2   netid2
rename Reviewer3   netid3

rename Review1Score     score1
rename Reviewer2Score   score2
rename Reviewer3Score   score3

tempfile q3_proposal_review
save `q3_proposal_review'

reshape long netid score, i(proposal_id) j(rpos)

bysort netid: egen mean_netid = mean(score)
bysort netid: egen sd_netid   = sd(score)

gen stand_score = (score - mean_netid) / sd_netid

bysort netid: gen n_reviews = _N
sum n_reviews
count if sd_netid==0
replace stand_score = 0 if sd_netid==0

keep proposal_id rpos stand_score
reshape wide stand_score, i(proposal_id) j(rpos)

rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score


***  (2)

egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)

list proposal_id average_stand_score, clean

/*
       propos~d   average~e  
  1.        105    1.095271  
  2.        114    1.072452  
  3.         65    1.044625  
  4.         77    1.008047  
  5.         75    .9732648  
  6.         84    .9473619  
  7.         78    .8316699  
  8.         86    .7812539  
  9.         33    .7636148  
 10.         46    .7450528  
 11.        100    .7416676  
 12.         71    .7415178  
 13.         52    .7378891  
 14.         18    .7267417  
 15.         58    .7149979  
 16.        111    .7030721  
 17.         45    .6455194  
 18.         26    .6384386  
 19.         57    .6203605  
 20.         91    .6177917  
 21.         59    .5999078  
 22.         51      .58099  
 23.         68    .5744227  
 24.        112    .5701222  
 25.        108    .5421028  
 26.         44     .537549  
 27.          9    .4922419  
 28.         92    .4815972  
 29.         88    .4754057  
 30.         13    .4664439  
 31.          8    .4652879  
 32.         27    .4590366  
 33.        119    .4119876  
 34.        118    .4004899  
 35.         72    .3999041  
 36.         80    .3998114  
 37.         98    .3851046  
 38.        127    .3832116  
 39.         61    .3781382  
 40.         23    .3775783  
 41.         87    .3715229  
 42.        101    .3645006  
 43.         81     .340217  
 44.         34     .331895  
 45.          1    .3252122  
 46.        102    .3138168  
 47.         21    .3068023  
 48.         89    .2978317  
 49.         20    .2847954  
 50.         60    .2836112  
 51.         70    .2527658  
 52.          6    .2434245  
 53.         38    .2388154  
 54.         82    .2378837  
 55.         54    .2189656  
 56.          7    .2158407  
 57.        115    .2090245  
 58.          5    .1790622  
 59.         97    .1515814  
 60.        121    .1502939  
 61.        106    .1460983  
 62.         74    .1363005  
 63.         56    .1150404  
 64.         19    .0994265  
 65.         11    .0898294  
 66.        109    .0561058  
 67.         83    .0508828  
 68.         73    .0453763  
 69.         76     .042334  
 70.         66    .0403362  
 71.          2    .0200854  
 72.         48    .0183095  
 73.         24    .0141794  
 74.         79     .006878  
 75.          4   -.0065622  
 76.         63   -.0157364  
 77.         37    -.050355  
 78.        107   -.0567466  
 79.         36   -.0792831  
 80.         42   -.0863086  
 81.         39   -.1105848  
 82.         41   -.1297291  
 83.         49    -.136815  
 84.         32   -.1419489  
 85.         29   -.1437951  
 86.        123   -.1462509  
 87.         16   -.1467661  
 88.         69   -.1711105  
 89.        126     -.19283  
 90.         43   -.1963764  
 91.         12   -.2585053  
 92.         94   -.2853558  
 93.        116   -.2925999  
 94.        128   -.2953591  
 95.         96   -.3043826  
 96.         62    -.319337  
 97.         14   -.3695991  
 98.         10   -.3828385  
 99.         64   -.3955375  
100.         67   -.4003882  
101.        125   -.4201696  
102.         28    -.441319  
103.         50   -.4577913  
104.         95   -.5827793  
105.         35   -.6131604  
106.         25   -.6394829  
107.        103   -.6426669  
108.         99   -.6473259  
109.        104   -.6497627  
110.          3   -.7326094  
111.        110   -.7750164  
112.         55   -.8080467  
113.        124   -.8506027  
114.        120   -.8973653  
115.         15   -.9119349  
116.         30   -.9445913  
117.        117   -.9878452  
118.         47   -1.095129  
119.         17     -1.1018  
120.        113   -1.103523  
121.        122   -1.111115  
122.         22   -1.167012  
123.         31   -1.211635  
124.         93   -1.212618  
125.         40   -1.386134  
126.         53   -1.479764  
127.         90   -1.567573  
128.         85   -2.177107  

*/

***  (3)

gsort -average_stand_score
gen rank = _n

list proposal_id rank, clean

/*
      propos~d   rank  
  1.        105      1  
  2.        114      2  
  3.         65      3  
  4.         77      4  
  5.         75      5  
  6.         84      6  
  7.         78      7  
  8.         86      8  
  9.         33      9  
 10.         46     10  
 11.        100     11  
 12.         71     12  
 13.         52     13  
 14.         18     14  
 15.         58     15  
 16.        111     16  
 17.         45     17  
 18.         26     18  
 19.         57     19  
 20.         91     20  
 21.         59     21  
 22.         51     22  
 23.         68     23  
 24.        112     24  
 25.        108     25  
 26.         44     26  
 27.          9     27  
 28.         92     28  
 29.         88     29  
 30.         13     30  
 31.          8     31  
 32.         27     32  
 33.        119     33  
 34.        118     34  
 35.         72     35  
 36.         80     36  
 37.         98     37  
 38.        127     38  
 39.         61     39  
 40.         23     40  
 41.         87     41  
 42.        101     42  
 43.         81     43  
 44.         34     44  
 45.          1     45  
 46.        102     46  
 47.         21     47  
 48.         89     48  
 49.         20     49  
 50.         60     50  
 51.         70     51  
 52.          6     52  
 53.         38     53  
 54.         82     54  
 55.         54     55  
 56.          7     56  
 57.        115     57  
 58.          5     58  
 59.         97     59  
 60.        121     60  
 61.        106     61  
 62.         74     62  
 63.         56     63  
 64.         19     64  
 65.         11     65  
 66.        109     66  
 67.         83     67  
 68.         73     68  
 69.         76     69  
 70.         66     70  
 71.          2     71  
 72.         48     72  
 73.         24     73  
 74.         79     74  
 75.          4     75  
 76.         63     76  
 77.         37     77  
 78.        107     78  
 79.         36     79  
 80.         42     80  
 81.         39     81  
 82.         41     82  
 83.         49     83  
 84.         32     84  
 85.         29     85  
 86.        123     86  
 87.         16     87  
 88.         69     88  
 89.        126     89  
 90.         43     90  
 91.         12     91  
 92.         94     92  
 93.        116     93  
 94.        128     94  
 95.         96     95  
 96.         62     96  
 97.         14     97  
 98.         10     98  
 99.         64     99  
100.         67    100  
101.        125    101  
102.         28    102  
103.         50    103  
104.         95    104  
105.         35    105  
106.         25    106  
107.        103    107  
108.         99    108  
109.        104    109  
110.          3    110  
111.        110    111  
112.         55    112  
113.        124    113  
114.        120    114  
115.         15    115  
116.         30    116  
117.        117    117  
118.         47    118  
119.         17    119  
120.        113    120  
121.        122    121  
122.         22    122  
123.         31    123  
124.         93    124  
125.         40    125  
126.         53    126  
127.         90    127  
128.         85    128  

*/




********************************************************************************
* Q4
********************************************************************************

global excel_t21 "$class/q4_Pakistan_district_table21.xlsx"

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
	
	forvalues j = 1/12 {
		gen x`j' = ""
	}

	local k = 1
foreach col in B C D E F G H I J K L M N O P Q R S T U V W X Y  Z AA AB AC{
	capture confirm variable `col'
    if _rc != 0 continue
	
    if `k' <= 12 {
        replace x`k' = `col' if x`k'=="" & regexm(`col', "[0-9]")
        count if x`k' != ""
        if r(N) == 1 local k = `k' + 1
    }
}

keep table table21 x1-x12
	
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %40s table21

use `table21', clear
br

********************************************************************************
* Q5 (Professors, these contains contents generated by ChatGPT.)
********************************************************************************

use "$class/q5/q5_Tz_student_roster_html.dta", clear

gen shl_info = regexs(1) if regexm(s, "<H3><P [^>]+>([^<]+)")

replace shl_info = ustrtrim(shl_info)

split shl_info, parse(" - ") gen(part)
rename part1 school_name
rename part2 school_code

gen students = regexs(1) if regexm(s, "WALIOFANYA MTIHANI : ([0-9]+)")

gen avg_score = regexs(1) if regexm(s, "WASTANI WA SHULE[ ]+: ([0-9.]+)")

gen group_under_40 = regexm(s, "Wanafunzi chini ya 40")

gen rank_council = regexs(1) if regexm(s, "KIHALMASHAURI: ([0-9]+ kati ya [0-9]+)")
gen rank_region  = regexs(1) if regexm(s, "KIMKOA[ ]+: ([0-9]+ kati ya [0-9]+)")
gen rank_national = regexs(1) if regexm(s, "KITAIFA : ([0-9]+ kati ya [0-9]+)")

keep in 1
keep school_name school_code students avg_score group_under_40 rank_council rank_region rank_national

destring students avg_score, replace

browse





log close
