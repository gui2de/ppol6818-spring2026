
* ---------------------------------------------------------
* Stata 1
* ---------------------------------------------------------
cd "/Users/lukekeller/Desktop/ppol6818-spring2026/week3-stata1/zs352-stata1/stata1.data"

use "student.dta", clear
rename primary_teacher teacher  

* Merge
merge m:1 teacher using "teacher.dta", keep(match) nogenerate
merge m:1 school using "school.dta", keep(match) nogenerate
merge m:1 subject using "subject.dta", keep(match) nogenerate

* ---------------------------------------------------------
* Question 1
* ---------------------------------------------------------

* (a) South 
summarize attendance if loc == "South"
/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180
*/

* (b) tested=1
summarize tested if level == "High"
/*
   Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
      tested |      1,379    .4423495    .4968455          0          1
*/

* (c) averagre GPA
summarize gpa
/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      4,490     3.60144      .23159   2.974333   3.769334
*/

* (d) Middle School Average Attendance
tabstat attendance if level == "Middle", by(school) statistics(mean)
/*
          school |      Mean
-----------------+----------
Joseph Darby Mid |  177.4408
Mahatma Ghandi M |  177.3344
Malala Yousafzai |  177.5478
-----------------+----------
           Total |  177.4514
----------------------------
*/

* ---------------------------------------------------------
* Question 2
* ---------------------------------------------------------

use "/Users/lukekeller/Desktop/ppol6818-spring2026/week3-stata1/zs352-stata1/stata1.data/q2_village_pixel.dta", clear

* (a) 
bysort pixel: egen max_payout = max(payout)
bysort pixel: egen min_payout = min(payout)

gen pixel_consistent = (max_payout == min_payout)

tab pixel_consistent
/*
pixel_consi |
      stent |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        958      100.00      100.00
------------+-----------------------------------
      Total |        958      100.00
*/
drop max_payout min_payout

* (b) 
bysort village pixel: gen tag = (_n == 1)
bysort village: egen num_pixels = total(tag)

gen pixel_village = (num_pixels > 1)

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

drop tag num_pixels

* (c) 
bysort village: egen v_max_pay = max(payout)
bysort village: egen v_min_pay = min(payout)
gen v_pay_consistent = (v_max_pay == v_min_pay)

gen category = .
replace category = 1 if pixel_village == 0
replace category = 2 if pixel_village == 1 & v_pay_consistent == 1
replace category = 3 if pixel_village == 1 & v_pay_consistent == 0

* 
list hhid if category == 2

/*
     +-----------+
     |      hhid |
     |-----------|
170. | 120507103 |
171. | 120507101 |
172. | 120507102 |
173. | 120507111 |
174. | 120507104 |
     |-----------|
201. | 120508209 |
202. | 120508203 |
203. | 120508202 |
204. | 120508204 |
205. | 120508206 |
     |-----------|
206. | 120508208 |
266. | 120610605 |
267. | 120610602 |
268. | 120610604 |
269. | 120610609 |
     |-----------|
278. | 120611102 |
279. | 120611108 |
280. | 120611101 |
342. | 120813801 |
343. | 120813804 |
     |-----------|
344. | 120813807 |
345. | 120813803 |
346. | 120813811 |
385. | 120814907 |
386. | 120814911 |
     |-----------|
387. | 120814901 |
388. | 120814903 |
534. | 131120509 |
535. | 131120506 |
536. | 131120510 |
     |-----------|
571. | 131221904 |
572. | 131221901 |
573. | 131221909 |
574. | 131221912 |
575. | 131221905 |
     |-----------|
615. | 131424211 |
616. | 131424206 |
617. | 131424204 |
618. | 131424205 |
635. | 131424609 |
     |-----------|
636. | 131424604 |
637. | 131424610 |
638. | 131424602 |
739. | 141728101 |
740. | 141728108 |
     |-----------|
741. | 141728103 |
742. | 141728102 |
950. | 131336109 |
951. | 131336107 |
952. | 131336101 |
     +-----------+
*/

drop v_max_pay v_min_pay v_pay_consistent

* ---------------------------------------------------------
* Question 3
* ---------------------------------------------------------
cd "/Users/lukekeller/Desktop/ppol6818-spring2026/week3-stata1/zs352-stata1/stata1.data"
use "q3_proposal_review.dta", clear

* (1)
rename Rewiewer1 reviewer_id1
rename Reviewer2 reviewer_id2
rename Reviewer3 reviewer_id3
rename Review1Score score1
rename Reviewer2Score score2
rename Reviewer3Score score3


reshape long reviewer_id score, i(proposal_id) j(review_pos)

bysort reviewer_id: egen r_mean = mean(score)
bysort reviewer_id: egen r_sd = sd(score)

gen stand_score = (score - r_mean) / r_sd


drop score r_mean r_sd
reshape wide reviewer_id stand_score, i(proposal_id) j(review_pos)


rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

* (2) 
egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)

* (3) 
gsort -average_stand_score
gen Rank = _n

list proposal_id average_stand_score Rank in 1/128
/*
+-----------------------------+
     | propos~d   average~e   Rank |
     |-----------------------------|
  1. |      105    1.095271      1 |
  2. |      114    1.072452      2 |
  3. |       65    1.044625      3 |
  4. |       77    1.008047      4 |
  5. |       75    .9732648      5 |
     |-----------------------------|
  6. |       84    .9473619      6 |
  7. |       78    .8316699      7 |
  8. |       86    .7812539      8 |
  9. |       33    .7636148      9 |
 10. |       46    .7450528     10 |
     |-----------------------------|
 11. |      100    .7416676     11 |
 12. |       71    .7415178     12 |
 13. |       52    .7378891     13 |
 14. |       18    .7267417     14 |
 15. |       58    .7149979     15 |
     |-----------------------------|
 16. |      111    .7030721     16 |
 17. |       45    .6455194     17 |
 18. |       26    .6384386     18 |
 19. |       57    .6203605     19 |
 20. |       91    .6177917     20 |
     |-----------------------------|
 21. |       59    .5999078     21 |
 22. |       51      .58099     22 |
 23. |       68    .5744227     23 |
 24. |      112    .5701222     24 |
 25. |      108    .5421028     25 |
     |-----------------------------|
 26. |       44     .537549     26 |
 27. |        9    .4922419     27 |
 28. |       92    .4815972     28 |
 29. |       88    .4754057     29 |
 30. |       13    .4664439     30 |
     |-----------------------------|
 31. |        8    .4652879     31 |
 32. |       27    .4590366     32 |
 33. |      119    .4119876     33 |
 34. |      118    .4004899     34 |
 35. |       72    .3999041     35 |
     |-----------------------------|
 36. |       80    .3998114     36 |
 37. |       98    .3851046     37 |
 38. |      127    .3832116     38 |
 39. |       61    .3781382     39 |
 40. |       23    .3775783     40 |
     |-----------------------------|
 41. |       87    .3715229     41 |
 42. |      101    .3645006     42 |
 43. |       81     .340217     43 |
 44. |       34     .331895     44 |
 45. |        1    .3252122     45 |
     |-----------------------------|
 46. |      102    .3138168     46 |
 47. |       21    .3068023     47 |
 48. |       89    .2978317     48 |
 49. |       20    .2847954     49 |
 50. |       60    .2836112     50 |
     |-----------------------------|
 51. |       70    .2527658     51 |
 52. |        6    .2434245     52 |
 53. |       38    .2388154     53 |
 54. |       82    .2378837     54 |
 55. |       54    .2189656     55 |
     |-----------------------------|
 56. |        7    .2158407     56 |
 57. |      115    .2090245     57 |
 58. |        5    .1790622     58 |
 59. |       97    .1515814     59 |
 60. |      121    .1502939     60 |
     |-----------------------------|
 61. |      106    .1460983     61 |
 62. |       74    .1363005     62 |
 63. |       56    .1150404     63 |
 64. |       19    .0994265     64 |
 65. |       11    .0898294     65 |
     |-----------------------------|
 66. |      109    .0561058     66 |
 67. |       83    .0508828     67 |
 68. |       73    .0453763     68 |
 69. |       76     .042334     69 |
 70. |       66    .0403362     70 |
     |-----------------------------|
 71. |        2    .0200854     71 |
 72. |       48    .0183095     72 |
 73. |       24    .0141794     73 |
 74. |       79     .006878     74 |
 75. |        4   -.0065622     75 |
     |-----------------------------|
 76. |       63   -.0157364     76 |
 77. |       37    -.050355     77 |
 78. |      107   -.0567466     78 |
 79. |       36   -.0792831     79 |
 80. |       42   -.0863086     80 |
     |-----------------------------|
 81. |       39   -.1105848     81 |
 82. |       41   -.1297291     82 |
 83. |       49    -.136815     83 |
 84. |       32   -.1419489     84 |
 85. |       29   -.1437951     85 |
     |-----------------------------|
 86. |      123   -.1462509     86 |
 87. |       16   -.1467661     87 |
 88. |       69   -.1711105     88 |
 89. |      126     -.19283     89 |
 90. |       43   -.1963764     90 |
     |-----------------------------|
 91. |       12   -.2585053     91 |
 92. |       94   -.2853558     92 |
 93. |      116   -.2925999     93 |
 94. |      128   -.2953591     94 |
 95. |       96   -.3043826     95 |
     |-----------------------------|
 96. |       62    -.319337     96 |
 97. |       14   -.3695991     97 |
 98. |       10   -.3828385     98 |
 99. |       64   -.3955375     99 |
100. |       67   -.4003882    100 |
     |-----------------------------|
101. |      125   -.4201696    101 |
102. |       28    -.441319    102 |
103. |       50   -.4577913    103 |
104. |       95   -.5827793    104 |
105. |       35   -.6131604    105 |
     |-----------------------------|
106. |       25   -.6394829    106 |
107. |      103   -.6426669    107 |
108. |       99   -.6473259    108 |
109. |      104   -.6497627    109 |
110. |        3   -.7326094    110 |
     |-----------------------------|
111. |      110   -.7750164    111 |
112. |       55   -.8080467    112 |
113. |      124   -.8506027    113 |
114. |      120   -.8973653    114 |
115. |       15   -.9119349    115 |
     |-----------------------------|
116. |       30   -.9445913    116 |
117. |      117   -.9878452    117 |
118. |       47   -1.095129    118 |
119. |       17     -1.1018    119 |
120. |      113   -1.103523    120 |
     |-----------------------------|
121. |      122   -1.111115    121 |
122. |       22   -1.167012    122 |
123. |       31   -1.211635    123 |
124. |       93   -1.212618    124 |
125. |       40   -1.386134    125 |
     |-----------------------------|
126. |       53   -1.479764    126 |
127. |       90   -1.567573    127 |
128. |       85   -2.177107    128 |
     +-----------------------------+
*/

* ---------------------------------------------------------
* Question 4
* ---------------------------------------------------------
clear all

global wd "/Users/lukekeller/Desktop/ppol6818-spring2026/week3-stata1/zs352-stata1/stata1.data" 
global excel_t21 "$wd/q4_Pakistan_district_table21.xlsx"

* Set up the tempfile
tempfile table21
save `table21', replace emptyok

* Loop through all 135 tables
forvalues i=1/135 {
    
    import excel "$excel_t21", sheet("Table `i'") clear allstring
    
    gen keep_row = 0
    foreach v of varlist _all {
        
        capture replace keep_row = 1 if regexm(`v', "18 AND")
    }
    
    keep if keep_row == 1
    drop keep_row
    
    if _N == 0 {
        display as error "Warning: No '18 AND ABOVE' row found in Table `i'"
        continue 
    }

    
    
    local counter = 1
    foreach v of varlist _all {
        if missing(`v') | trim(`v') == "" | `v' == "." {
            drop `v'
        }
        else {
            * Rename the valid column to a temp name
            rename `v' temp_col_`counter'
            local counter = `counter' + 1
        }
    }
    
    
    gen age_group = temp_col_1
    
    forvalues k = 2/13 {
        capture gen col`k' = temp_col_`k'
    }
    
    gen district_id = `i'
    
    capture keep district_id age_group col*
    
    append using `table21'
    save `table21', replace
}

* Load the final data
use `table21', clear

* Format all columns starting with 'col' to be readable
format %15s col*
browse

* ---------------------------------------------------------
* Question 5
* ---------------------------------------------------------
clear all

local file_path "/Users/lukekeller/Desktop/ppol6818-spring2026/week3-stata1/zs352-stata1/stata1.data/shl_ps0101114 (1).html"

import delimited "`file_path'", clear varnames(nonames) delimiters("$$$") encoding("utf-8")
rename v1 raw_data

gen school_name = ""
gen school_code = ""
gen students_took_test = .
gen avg_score = .
gen student_group = ""
gen rank_council = ""
gen rank_region = ""
gen rank_national = ""

capture replace school_name = regexs(1) if regexm(raw_data, "([A-Z ]+ PRIMARY SCHOOL) - (PS[0-9]+)")
capture replace school_code = regexs(2) if regexm(raw_data, "([A-Z ]+ PRIMARY SCHOOL) - (PS[0-9]+)")

replace school_code = school_code[_n-1] if school_code == "" & _n > 1
replace school_name = school_name[_n-1] if school_name == "" & _n > 1

replace students_took_test = real(regexs(1)) if regexm(raw_data, "WALIOFANYA MTIHANI[^0-9]*([0-9]+)")

replace avg_score = real(regexs(1)) if regexm(raw_data, "WASTANI WA SHULE[^0-9]*([0-9\.]+)")

gen is_group_row = regexm(raw_data, "KUNDI LA SHULE")
replace student_group = "Under 40" if is_group_row == 1 & regexm(raw_data, "chini ya 40")
replace student_group = "40 or above" if is_group_row == 1 & !regexm(raw_data, "chini ya 40")
drop is_group_row

replace rank_council = regexs(1) + " out of " + regexs(2) if regexm(raw_data, "KIHALMASHAURI[^0-9]*([0-9]+) kati ya ([0-9]+)")

replace rank_region = regexs(1) + " out of " + regexs(2) if regexm(raw_data, "KIMKOA[^0-9]*([0-9]+) kati ya ([0-9]+)")

replace rank_national = regexs(1) + " out of " + regexs(2) if regexm(raw_data, "KITAIFA[^0-9]*([0-9]+) kati ya ([0-9]+)")

collapse (firstnm) school_name school_code students_took_test avg_score student_group rank_*, fast

list, clean noobs
/*
                school_name   school~de   studen~t   avg_sc~e   studen~p   rank_council     rank_region     rank_nat
> ional  
    ALBEHIJE PRIMARY SCHOOL   PS0101114         16    217.375   Under 40   22 out of 46   74 out of 290   545 out of
>  5664  
*/

* ---------------------------------------------------------
* Bonus Question
* ---------------------------------------------------------
clear all

local file_path "/Users/lukekeller/Desktop/ppol6818-spring2026/week3-stata1/zs352-stata1/stata1.data/shl_ps0101114 (1).html"

import delimited "`file_path'", clear varnames(nonames) delimiters("$$$") 
rename v1 raw_data

gen schoolcode = ""
gen cand_id = ""
gen prem_number = ""
gen gender = ""
gen student_name = ""
gen subjects_str = "" 

capture regexm(raw_data, "(PS[0-9]+-[0-9]+)")
replace cand_id = regexs(1) if regexs(1) != ""

capture regexm(raw_data, "([0-9]{10,})")
replace prem_number = regexs(1) if regexs(1) != ""

capture regexm(raw_data, ">([MF])<")
replace gender = regexs(1) if regexs(1) != ""

capture regexm(raw_data, ">([A-Z ]{3,})<")
replace student_name = regexs(1) if regexs(1) != "" 
replace student_name = "" if student_name == "CANDIDATE NAME" | student_name == "SUBJECTS" | student_name == "SEX"

replace subjects_str = raw_data if regexm(raw_data, "Kiswahili") & regexm(raw_data, "English")


foreach var in cand_id prem_number gender student_name {
    replace `var' = `var'[_n-1] if `var' == "" & _n > 1
}

count if subjects_str != ""
if r(N) == 0 {
    display as error 
    
    browse
    exit
}


keep if subjects_str != ""

local subjects "Kiswahili English Maarifa Hisabati Science Uraia"

foreach sub in `subjects' {
    gen `sub' = ""
    capture regexm(subjects_str, "`sub'.*-.*([A-F])") 
    replace `sub' = regexs(1) if regexs(1) != ""
}

gen average = ""
capture regexm(subjects_str, "Average Grade.*-.*([A-F])")
replace average = regexs(1) if regexs(1) != ""

replace schoolcode = substr(cand_id, 1, 9)
keep schoolcode cand_id prem_number gender student_name Kiswahili English Maarifa Hisabati Science Uraia average
order schoolcode cand_id prem_number gender student_name

list, clean noobs

