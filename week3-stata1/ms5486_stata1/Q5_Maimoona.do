*Maimoona Mohsin 
*Experimental Design 
*PS1_ Question5 
*Please see word for answers 

new 

cd "C:\Users\maimo\OneDrive\Desktop\Semester 2\Experimental Design & Implement\Stata 1 assignment"
use q5_Tz_student_roster_html



* 1) School name + code
gen school_name = regexs(1) if regexm(s, "([A-Z ]+ PRIMARY SCHOOL)")
gen school_code = regexs(1) if regexm(s, "(PS[0-9]+)")

* 2) Students who took test
gen students_tested = real(regexs(1)) if regexm(s, "WALIOFANYA MTIHANI *: *([0-9]+)")

* 3) School average score
gen avg_score = real(regexs(1)) if regexm(s, "WASTANI WA SHULE *: *([0-9.]+)")

* 4) Student group: under 40 vs 40+
gen group_40plus = .
replace group_40plus = 0 if regexm(s, "chini ya 40")
replace group_40plus = 1 if regexm(s, "40") & missing(group_40plus)

* 5) Rankings (rank + total)
gen rank_council  = real(regexs(1)) if regexm(s, "KIHALMASHAURI: *([0-9]+) kati ya ([0-9]+)")
gen total_council = real(regexs(2)) if regexm(s, "KIHALMASHAURI: *([0-9]+) kati ya ([0-9]+)")

gen rank_region  = real(regexs(1)) if regexm(s, "KIMKOA *: *([0-9]+) kati ya ([0-9]+)")
gen total_region = real(regexs(2)) if regexm(s, "KIMKOA *: *([0-9]+) kati ya ([0-9]+)")

gen rank_national  = real(regexs(1)) if regexm(s, "KITAIFA *: *([0-9]+) kati ya ([0-9]+)")
gen total_national = real(regexs(2)) if regexm(s, "KITAIFA *: *([0-9]+) kati ya ([0-9]+)")

list school_name school_code students_tested avg_score group_40plus ///
     rank_council total_council rank_region total_region rank_national total_national

keep school_name school_code students_tested avg_score group_40plus ///
rank_council total_council rank_region total_region rank_national total_national



