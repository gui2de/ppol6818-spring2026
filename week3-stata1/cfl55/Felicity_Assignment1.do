*Q1.a What is the mean student attendance for schools located in the "South"? 

clear all
cd "C:\ExpDesign\StataAssignment1"
use student.dta
rename primary_teacher teacher
sort teacher
bysort teacher: gen stdnt_teacher_id = _n
reshape wide grade attendance stdnt_num, i(teacher) j(stdnt_teacher_id)
merge 1:1 teacher using "C:\ExpDesign\StataAssignment1\teacher.dta"
reshape long grade attendance stdnt_num, i(teacher) j(stdnt_teacher_id)
gen south = 1 if school == "Horace Mann Elementary" | school == "Benjamin Franklin Elementary" | school == "Malala Yousafzai Middle School"
replace south = 0 if south == .
sum attendance if south == 1

/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |      1,181    177.4776    3.140854        158        180

 The mean student attendance for schools located in the "South" is 177.4776. */
 
 
*Q1.b Among students enrolled in high school, what proportion have a primary teacher who teaches a tested subject, i.e. "tested" = 1? 
 
clear all
cd "C:\ExpDesign\StataAssignment1"
use student.dta
rename primary_teacher teacher
sort teacher
bysort teacher: gen stdnt_teacher_id = _n
reshape wide grade attendance stdnt_num, i(teacher) j(stdnt_teacher_id)
merge 1:1 teacher using "C:\ExpDesign\StataAssignment1\teacher.dta"
reshape long grade attendance stdnt_num, i(teacher) j(stdnt_teacher_id)
tab grade
drop if grade < 9
tab subject
gen tested = 1 if subject == "Math" | subject == "Science" | subject == "Reading/Writing"
replace tested = 0 if tested == .
drop if grade == .
tab teacher tested, cell

/*
+-----------------+
| Key             |
|-----------------|
|    frequency    |
| cell percentage |
+-----------------+

           |        tested
   teacher |         0          1 |     Total
-----------+----------------------+----------
       148 |        27          0 |        27 
           |      1.96       0.00 |      1.96 
-----------+----------------------+----------
.......EMITTED MANY ROWS.....................
-----------+----------------------+----------
       195 |        38          0 |        38 
           |      2.76       0.00 |      2.76 
-----------+----------------------+----------
     Total |       769        610 |     1,379 
           |     55.77      44.23 |    100.00 

 
44.23% have a teacher who teaches a tested subject */


*Q1.c What is the mean gpa of all students in the district? 
clear all
cd "C:\ExpDesign\StataAssignment1"
use student.dta
sum stdnt_num
*4490 stdnt_num observations
rename primary_teacher teacher
sort teacher
bysort teacher: gen stdnt_teacher_id = _n
reshape wide grade attendance stdnt_num, i(teacher) j(stdnt_teacher_id)
merge 1:1 teacher using "C:\ExpDesign\StataAssignment1\teacher.dta"
reshape long grade attendance stdnt_num, i(teacher) j(stdnt_teacher_id)
drop grade attendance stdnt_teacher_id subject experience _merge
drop if stdnt_num == .
sum stdnt_num
*still 4490 stdnt_num observations
bysort school: gen stdnt_school_id = _n
reshape wide teacher stdnt_num, i(school) j(stdnt_school_id)
merge 1:1 school using "C:\ExpDesign\StataAssignment1\school.dta"
reshape long teacher stdnt_num, i(school) j(stdnt_school_id)
sum gpa

/*
     Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         gpa |      9,228    3.604183     .222013   2.974333   3.769334

The mean gpa is 3.6 */


*Q1.d What is the mean attendance for each middle school?
clear all
cd "C:\ExpDesign\StataAssignment1"
use student.dta
rename primary_teacher teacher
sort teacher
bysort teacher: gen stdnt_teacher_id = _n
reshape wide grade attendance stdnt_num, i(teacher) j(stdnt_teacher_id)
merge 1:1 teacher using "C:\ExpDesign\StataAssignment1\teacher.dta"
reshape long grade attendance stdnt_num, i(teacher) j(stdnt_teacher_id)
drop grade stdnt_teacher_id subject experience _merge teacher
drop if stdnt_num == .
bysort school: gen stdnt_school_id = _n
reshape wide attendance stdnt_num, i(school) j(stdnt_school_id)
merge 1:1 school using "C:\ExpDesign\StataAssignment1\school.dta"
reshape long attendance stdnt_num, i(school) j(stdnt_school_id)
drop if level != "Middle"
tab school 
sum attendance if school == "Joseph Darby Middle School"
/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        304    177.4408    2.824302        165        180    */
sum attendance if school == "Mahatma Ghandi Middle School"
/* 

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        317    177.3344    3.256228        153        180    */
sum attendance if school == "Malala Yousafzai Middle School"
/*

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  attendance |        418    177.5478    2.823991        162        180    */

*The mean attendance for each middle school is 177.44, 177.33, and 177.54


/*Q2.a The payout status should be consistent within each pixel. Verify whether this condition holds. 
Create a new dummy variable, "pixel_consistent", defined as – 
● pixel_consistent = 1 if all households within a pixel have the same payout status 
● pixel_consistent = 0 if there is any variation in payout status within a pixel */

clear all
cd "C:\ExpDesign\StataAssignment1"
use q2_village_pixel.dta
tab pixel payout, missing
ssc install egenmore
bysort hhid: egen check = nvals(pixel)
gen pixel_consistent = 1 if check == 1
replace pixel_consistent = 0 if check != 1
tab pixel_consistent
/* 
pixel_consi |
      stent |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        958      100.00      100.00
------------+-----------------------------------
      Total |        958      100.00

Yes, the payout status is consistent within each pixel. */

/* Q2.b In most cases, households within a village are in the same pixel, but some villages may span multiple pixels (boundary cases). 
Create a new village-level dummy variable, "pixel_village", defined as: 
● pixel_village = 0 if all households in a village fall within a single pixel 
● pixel_village = 1 if households in a village fall within more than one pixel */
 
clear all
cd "C:\ExpDesign\StataAssignment1"
use q2_village_pixel.dta
bysort village: egen check = nvals(pixel)
gen pixel_village = 0 if check == 1
replace pixel_village = 1 if check != 1
tab pixel_village
/* 
pixel_villa |
         ge |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        834       87.06       87.06
          1 |        124       12.94      100.00
------------+-----------------------------------
      Total |        958      100.00                 */

	  
/* Q2.c For this experiment, villages spanning multiple pixels only pose a problem if they also have different payout statuses across pixels. 
Using this criterion, classify households into the following categories: 
● Villages that are entirely within a single pixel (Value = 1) 
● Villages that span multiple pixels but have the same payout status across pixels 
(Create and report a list of all household IDs in these villages) (Value = 2) 
● Villages that span multiple pixels and have different payout statuses across pixels (Value = 3) 
Note: These 3 categories mentioned above are mutually exclusive and exhaustive, i.e. every single observation should fall into one of these categories. Also, the categories may or may not line up with what you created in (a) and (b) so read the instructions closely. */

clear all
cd "C:\ExpDesign\StataAssignment1"
use q2_village_pixel.dta
bysort village: egen check = nvals(pixel)
gen hh_classification = 1 if check == 1
bysort hhid: egen check2 = nvals(pixel)
replace hh_classification = 2 if check != 1 & check2 == 1
replace hh_classification = 3 if check != 1 & check2 != 1
tab hh_classification, missing

/*
hh_classifi |
     cation |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        834       87.06       87.06
          2 |        124       12.94      100.00
------------+-----------------------------------
      Total |        958      100.00
There are no values of 3 because there are no pixels for which payout status is variable. */


/* q3 Faculty members submitted 128 proposals for funding, but resources are available to fund only 50 grants. Each proposal was randomly assigned to three reviewers, and each reviewer assigned a score between 1 (lowest) and 5 (highest). Each reviewer evaluated 24 proposals and assigned a score. 
Since reviewers may differ in how strictly they score, you are asked to standardize scores at the reviewer level before computing final rankings. We think it will be better if we normalize the score wrt each reviewer (using unique ids) before calculating the average score. The formula is as follows: 
Standardized Score = (score – mean)/sd, where 
● mean = mean score of that particular reviewer (based on the NetID) 
● sd = standard deviation of scores of that particular reviewer (based on that NetID) 

q3.1 Using the reviewer NetID (not reviewer position 1, 2, or 3), complete the following tasks: 1. Create standardized score variables for each review: 
a. stand_r1_score 
b. stand_r2_score 
c. stand_r3_score */

clear all
cd "C:\ExpDesign\StataAssignment1"
use q3_proposal_review.dta
rename Rewiewer1 Reviewer1
rename Reviewer2Score Review2Score
rename Reviewer3Score Review3Score
foreach x in 1 2 3 {
	bysort Reviewer`x': egen mean`x' = mean(Review`x'Score)
	bysort Reviewer`x': egen sd`x' = sd(Review`x'Score)
	gen stand_r`x'_score = (Review`x'Score - mean`x')/sd`x'
	drop sd`x' mean`x'
}


*q3.2 Compute the average standardized score as "average_stand_score" for each proposal 
clear all
cd "C:\ExpDesign\StataAssignment1"
use q3_proposal_review.dta
rename Rewiewer1 Reviewer1
rename Reviewer2Score Review2Score
rename Reviewer3Score Review3Score
foreach x in 1 2 3 {
	bysort Reviewer`x': egen mean`x' = mean(Review`x'Score)
	bysort Reviewer`x': egen sd`x' = sd(Review`x'Score)
	gen stand_r`x'_score = (Review`x'Score - mean`x')/sd`x'
	drop sd`x' mean`x'
}
gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score)/3


/*q3.3 Rank proposals based on average_stand_score, where: 
a. Rank = 1 corresponds to the highest score 
b. Rank = 128 corresponds to the lowest score */

clear all
cd "C:\ExpDesign\StataAssignment1"
use q3_proposal_review.dta
rename Rewiewer1 Reviewer1
rename Reviewer2Score Review2Score
rename Reviewer3Score Review3Score
foreach x in 1 2 3 {
	bysort Reviewer`x': egen mean`x' = mean(Review`x'Score)
	bysort Reviewer`x': egen sd`x' = sd(Review`x'Score)
	gen stand_r`x'_score = (Review`x'Score - mean`x')/sd`x'
	drop sd`x' mean`x'
}
gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score)/3
sort average_stand_score
gen Rank = _n


/*Q4 You are given information on adults who possess a computerized national ID card in the file "Pakistan_district_table21.pdf". This PDF contains 135 tables, one for each district. The tables were extracted using OCR software, but the resulting data contain formatting inaccuracies.
Your task is to extract columns 2 through 13 from the first data row ("18 and above") in each district table and construct a dataset in which each row corresponds to one district. 
A hint do-file has been provided that includes code to loop through each table. You will need to modify or extend this code to ensure that the columns are correctly aligned across districts. 
Hint: While the table structure is mostly consistent, there are a small number of minor formatting anomalies. Be sure to inspect your output carefully and adjust your code as needed. */

clear all
global wd  "C:\ExpDesign\StataAssignment1"
global excel_t21 "$wd\q4_Pakistan_district_table21"
clear
tempfile table21
save `table21', replace emptyok
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring
	display as error `i'
	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1
	keep in 1
	rename TABLE21PAKISTANICITIZEN1 table21
	gen table=`i' 
	append using `table21' 
	save `table21', replace
}
use `table21', clear
format %20s table21 B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC
gen pop_total = B + C if B == "" | C == ""
order table21 table B pop_total
replace pop_total = B if pop_total == ""
replace B = "" if B == pop_total
drop B
replace C = "" if C == pop_total
replace pop_total = D if pop_total == ""
replace D = "" if D == pop_total
replace pop_total = E if pop_total == ""
replace E = "" if E == pop_total
gen obtained_cni_card = C + D if C == "" | D == ""
order table21 table pop_total C obtained_cni_card
replace obtained_cni_card = C if obtained_cni_card == ""
replace C = "" if C == obtained_cni_card
drop C
replace D = "" if obtained_cni_card == D
replace obtained_cni_card = E if obtained_cni_card == ""
replace E = "" if obtained_cni_card == E
replace obtained_cni_card = F if obtained_cni_card == ""
replace F = "" if obtained_cni_card == F
gen no_cni_card = D + E if D == "" | E == ""
order table21 table pop_total obtained_cni_card D no_cni_card
replace no_cni_card = D if no_cni_card == ""
replace D = "" if D == no_cni_card
drop D
replace E = "" if E == no_cni_card
replace no_cni_card = F if no_cni_card == ""
replace F = "" if F == no_cni_card
replace no_cni_card = G if no_cni_card == ""
replace G = "" if G == no_cni_card
replace no_cni_card = H if no_cni_card == ""
replace H = "" if H == no_cni_card
replace no_cni_card = I if no_cni_card == ""
replace I = "" if I == no_cni_card
gen male_pop_total = E + F if E == "" | F == ""
order table21 table pop_total obtained_cni_card no_cni_card E male_pop_total
replace male_pop_total = E if male_pop_total == ""
replace E = "" if E == male_pop_total
drop E
replace F = "" if F == male_pop_total
replace male_pop_total = G if male_pop_total == ""
replace G = "" if G == male_pop_total
replace male_pop_total = H if male_pop_total == ""
replace H = "" if H == male_pop_total
replace male_pop_total = I if male_pop_total == ""
replace I = "" if I == male_pop_total
replace male_pop_total = J if male_pop_total == ""
replace J = "" if J == male_pop_total
gen male_cni_card = F + G if F == "" | G == ""
order table21 table pop_total obtained_cni_card no_cni_card male_pop_total F male_cni_card
replace male_cni_card = F if male_cni_card == ""
replace F = "" if F == male_cni_card
drop F
replace G = "" if G == male_cni_card
replace male_cni_card = H if male_cni_card == ""
replace H = "" if H == male_cni_card
replace male_cni_card = I if male_cni_card == ""
replace I = "" if I == male_cni_card
replace male_cni_card = J if male_cni_card == ""
replace J = "" if J == male_cni_card
replace male_cni_card = K if male_cni_card == ""
replace K = "" if K == male_cni_card
replace male_cni_card = L if male_cni_card == ""
replace L = "" if L == male_cni_card
gen male_no_cni_card = G + H if G == "" | H == ""
order table21 table pop_total obtained_cni_card no_cni_card male_pop_total male_cni_card G male_no_cni_card
replace male_no_cni_card = G if male_no_cni_card == ""
replace G = "" if G == male_no_cni_card
drop G
replace male_no_cni_card = H if male_no_cni_card == ""
replace H = "" if H == male_no_cni_card
replace male_no_cni_card = I if male_no_cni_card == ""
replace I = "" if I == male_no_cni_card
replace male_no_cni_card = J if male_no_cni_card == ""
replace J = "" if J == male_no_cni_card
replace male_no_cni_card = K if male_no_cni_card == ""
replace K = "" if K == male_no_cni_card
replace male_no_cni_card = L if male_no_cni_card == ""
replace L = "" if L == male_no_cni_card
replace male_no_cni_card = M if male_no_cni_card == ""
replace M = "" if M == male_no_cni_card
replace male_no_cni_card = N if male_no_cni_card == ""
replace N = "" if N == male_no_cni_card
replace male_no_cni_card = O if male_no_cni_card == ""
replace O = "" if O == male_no_cni_card
gen female_pop_total = H + I if H == "" | I == ""
order table21 table pop_total obtained_cni_card no_cni_card male_pop_total male_cni_card male_no_cni_card H female_pop_total
replace female_pop_total = H if female_pop_total == ""
replace H = "" if H == female_pop_total
drop H
replace I = "" if I == female_pop_total
replace female_pop_total = J if female_pop_total == ""
replace J = "" if J == female_pop_total
replace female_pop_total = K if female_pop_total == ""
replace K = "" if K == female_pop_total
replace female_pop_total = L if female_pop_total == ""
replace L = "" if L == female_pop_total
replace female_pop_total = M if female_pop_total == ""
replace M = "" if M == female_pop_total
replace female_pop_total = N if female_pop_total == ""
replace N = "" if N == female_pop_total
replace female_pop_total = O if female_pop_total == ""
replace O = "" if O == female_pop_total
replace female_pop_total = P if female_pop_total == ""
replace P = "" if P == female_pop_total
replace female_pop_total = Q if female_pop_total == ""
replace Q = "" if Q == female_pop_total
gen female_cni_card = I + J if I == "" | J == ""
order table21 table pop_total obtained_cni_card no_cni_card male_pop_total male_cni_card male_no_cni_card female_pop_total I female_cni_card
replace female_cni_card = I if female_cni_card == ""
replace I = "" if I == female_cni_card
drop I
replace J = "" if J == female_cni_card
replace female_cni_card = K if female_cni_card == ""
replace K = "" if K == female_cni_card
replace female_cni_card = L if female_cni_card == ""
replace L = "" if L == female_cni_card
replace female_cni_card = M if female_cni_card == ""
replace M = "" if M == female_cni_card
replace female_cni_card = N if female_cni_card == ""
replace N = "" if N == female_cni_card
replace female_cni_card = O if female_cni_card == ""
replace O = "" if O == female_cni_card
replace female_cni_card = P if female_cni_card == ""
replace P = "" if P == female_cni_card
replace female_cni_card = Q if female_cni_card == ""
replace Q = "" if Q == female_cni_card
replace female_cni_card = R if female_cni_card == ""
replace R = "" if R == female_cni_card
replace female_cni_card = S if female_cni_card == ""
replace S = "" if S == female_cni_card
gen female_no_cni_card = J + K if J == "" | K == ""
order table21 table pop_total obtained_cni_card no_cni_card male_pop_total male_cni_card male_no_cni_card female_pop_total female_cni_card J female_no_cni_card
replace female_no_cni_card = J if female_no_cni_card == ""
replace J = "" if J == female_no_cni_card
drop J
replace K = "" if K == female_no_cni_card
replace female_no_cni_card = L if female_no_cni_card == ""
replace L = "" if L == female_no_cni_card
replace female_no_cni_card = M if female_no_cni_card == ""
replace M = "" if M == female_no_cni_card
replace female_no_cni_card = N if female_no_cni_card == ""
replace N = "" if N == female_no_cni_card
replace female_no_cni_card = O if female_no_cni_card == ""
replace O = "" if O == female_no_cni_card
replace female_no_cni_card = P if female_no_cni_card == ""
replace P = "" if P == female_no_cni_card
replace female_no_cni_card = Q if female_no_cni_card == ""
replace Q = "" if Q == female_no_cni_card
replace female_no_cni_card = R if female_no_cni_card == ""
replace R = "" if R == female_no_cni_card
replace female_no_cni_card = S if female_no_cni_card == ""
replace S = "" if S == female_no_cni_card
replace female_no_cni_card = T if female_no_cni_card == ""
replace T = "" if T == female_no_cni_card
replace female_no_cni_card = U if female_no_cni_card == ""
replace U = "" if U == female_no_cni_card
replace female_no_cni_card = V if female_no_cni_card == ""
replace V = "" if V == female_no_cni_card
gen trans_pop_total = K + L if K == "" | L == ""
order table21 table pop_total obtained_cni_card no_cni_card male_pop_total male_cni_card male_no_cni_card female_pop_total female_cni_card female_no_cni_card K trans_pop_total
replace trans_pop_total = K if trans_pop_total == ""
replace K = "" if K == trans_pop_total
drop K
replace L = "" if L == trans_pop_total
replace trans_pop_total = M if trans_pop_total == ""
replace M = "" if M == trans_pop_total
replace trans_pop_total = N if trans_pop_total == ""
replace N = "" if N == trans_pop_total
replace trans_pop_total = O if trans_pop_total == ""
replace O = "" if O == trans_pop_total
replace trans_pop_total = P if trans_pop_total == ""
replace P = "" if P == trans_pop_total
replace trans_pop_total = Q if trans_pop_total == ""
replace Q = "" if Q == trans_pop_total
replace trans_pop_total = R if trans_pop_total == ""
replace R = "" if R == trans_pop_total
replace trans_pop_total = S if trans_pop_total == ""
replace S = "" if S == trans_pop_total
replace trans_pop_total = T if trans_pop_total == ""
replace T = "" if T == trans_pop_total
replace trans_pop_total = U if trans_pop_total == ""
replace U = "" if U == trans_pop_total
replace trans_pop_total = V if trans_pop_total == ""
replace V = "" if V == trans_pop_total
replace trans_pop_total = W if trans_pop_total == ""
replace W = "" if W == trans_pop_total
replace trans_pop_total = X if trans_pop_total == ""
replace X = "" if X == trans_pop_total
gen trans_cni_card = L + M if L == "" | M == ""
order table21 table pop_total obtained_cni_card no_cni_card male_pop_total male_cni_card male_no_cni_card female_pop_total female_cni_card female_no_cni_card trans_pop_total L trans_cni_card
replace trans_cni_card = L if trans_cni_card == ""
replace L = "" if L == trans_cni_card
drop L
replace M = "" if M == trans_cni_card
replace trans_cni_card = N if trans_cni_card == ""
replace N = "" if N == trans_cni_card
replace trans_cni_card = O if trans_cni_card == ""
replace O = "" if O == trans_cni_card
replace trans_cni_card = P if trans_cni_card == ""
replace P = "" if P == trans_cni_card
replace trans_cni_card = Q if trans_cni_card == ""
replace Q = "" if Q == trans_cni_card
replace trans_cni_card = R if trans_cni_card == ""
replace R = "" if R == trans_cni_card
replace trans_cni_card = S if trans_cni_card == ""
replace S = "" if S == trans_cni_card
replace trans_cni_card = T if trans_cni_card == ""
replace T = "" if T == trans_cni_card
replace trans_cni_card = U if trans_cni_card == ""
replace U = "" if U == trans_cni_card
replace trans_cni_card = V if trans_cni_card == ""
replace V = "" if V == trans_cni_card
replace trans_cni_card = W if trans_cni_card == ""
replace W = "" if W == trans_cni_card
replace trans_cni_card = X if trans_cni_card == ""
replace X = "" if X == trans_cni_card
replace trans_cni_card = Y if trans_cni_card == ""
replace Y = "" if Y == trans_cni_card
replace trans_cni_card = Z if trans_cni_card == ""
replace Z = "" if Z == trans_cni_card
replace trans_cni_card = AA if trans_cni_card == ""
replace AA = "" if AA == trans_cni_card
replace trans_cni_card = AB if trans_cni_card == ""
replace AB = "" if AB == trans_cni_card
replace trans_cni_card = AC if trans_cni_card == ""
replace AC = "" if AC == trans_cni_card
gen trans_no_cni_card = M + N if M == "" | N == ""
order table21 table pop_total obtained_cni_card no_cni_card male_pop_total male_cni_card male_no_cni_card female_pop_total female_cni_card female_no_cni_card trans_pop_total trans_cni_card M trans_no_cni_card
replace trans_no_cni_card = M if trans_no_cni_card == ""
replace M = "" if M == trans_no_cni_card
drop M
replace N = "" if N == trans_no_cni_card
drop N
replace trans_no_cni_card = O if trans_no_cni_card == ""
replace O = "" if O == trans_no_cni_card
drop O
replace trans_no_cni_card = P if trans_no_cni_card == ""
replace P = "" if P == trans_no_cni_card
drop P
replace trans_no_cni_card = Q if trans_no_cni_card == ""
replace Q = "" if Q == trans_no_cni_card
drop Q
replace trans_no_cni_card = R if trans_no_cni_card == ""
replace R = "" if R == trans_no_cni_card
drop R
replace trans_no_cni_card = S if trans_no_cni_card == ""
replace S = "" if S == trans_no_cni_card
drop S
replace trans_no_cni_card = T if trans_no_cni_card == ""
replace T = "" if T == trans_no_cni_card
drop T
replace trans_no_cni_card = U if trans_no_cni_card == ""
replace U = "" if U == trans_no_cni_card
drop U
replace trans_no_cni_card = V if trans_no_cni_card == ""
replace V = "" if V == trans_no_cni_card
drop V
replace trans_no_cni_card = W if trans_no_cni_card == ""
replace W = "" if W == trans_no_cni_card
drop W
replace trans_no_cni_card = X if trans_no_cni_card == ""
replace X = "" if X == trans_no_cni_card
drop X
replace trans_no_cni_card = Y if trans_no_cni_card == ""
replace Y = "" if Y == trans_no_cni_card
drop Y
replace trans_no_cni_card = Z if trans_no_cni_card == ""
replace Z = "" if Z == trans_no_cni_card
drop Z
replace trans_no_cni_card = AA if trans_no_cni_card == ""
replace AA = "" if AA == trans_no_cni_card
drop AA
replace trans_no_cni_card = AB if trans_no_cni_card == ""
replace AB = "" if AB == trans_no_cni_card
drop AB
drop AC
replace trans_no_cni_card = "1" if trans_cni_card == "-1"
replace trans_no_cni_card = "4" if trans_cni_card == "-4"
replace trans_cni_card = "-" if trans_cni_card == "-1" | trans_cni_card == "-4"
save `table21', replace


/* Q5 This task focuses on string cleaning and data wrangling. Data for a school were scraped from a Tanzanian government website, but the resulting formatting is highly unstructured. Your task is to extract the following school-level variables: 
1. Number of students who took the test 
2. School average score 
3. Student group (binary indicator: under 40 vs 40 or above) 
4. School ranking within the council (for example, 22 out of 46) 
5. School ranking within the region (for example, 74 out of 290) 
6. School ranking at the national level (for example, 545 out of 5,664) 
In addition to these variables, also capture the school name and school code in two different columns. 
Note: This is a school level dataset, and should only contain one row with all the variables. All the school level information is given in the html file provided with the assignment files, which you can open using any browser. The page is in Swahili but it should be fairly straightforward to find the relevant information. You can use google translate if you have trouble finding the relevant parts of the webpage. */

clear all
cd "C:\ExpDesign\StataAssignment1"
view browse "shl_ps0101114.html"
set obs 1
gen school_name = "ALBEHIJE PRIMARY SCHOOL"
gen school_code = "PS0101114"
*Q5.1
gen num_stdnts = 16
*Q5.2
gen avg_score = 217.3750
*Q5.3
gen under40 = 1
*Q5.4
gen ranking_council = 22
*Q5.5
gen ranking_region = 74
*Q5.6
gen ranking_national = 545


/* Bonus Question: This task involves string cleaning and data wrangling. We scrapped student data for a school from a Tanzanian government website. Unfortunately, the formatting of the data is a mess. Your task is to create a student level dataset with the following variables: schoolcode, cand_id, gender, prem_number, name, grade variables for: Kiswahili, English, maarifa, hisabati, science, uraia, average. 
Note: This is a student level dataset, and should have 16 rows (same as the number of students in that school). 
Hint: you can get a better view of the string if you open the html page on a browser and view its source (which can be done by right clicking or hitting ctrl/command+U). */

clear all
cd "C:\ExpDesign\StataAssignment1"
view browse "shl_ps0101114.html"
*manually copied into Excel
import excel "Tanzania", firstrow clear
rename CANDNO cand_id
rename PREMNO prem_number 
rename SEX gender
rename CANDIDATENAME name
rename AverageGrade average
gen schoolcode = "PS0101114"
order schoolcode cand_id gender prem_number name Kisawahili
