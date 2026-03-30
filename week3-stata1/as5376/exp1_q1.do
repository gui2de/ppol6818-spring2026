log using "/Users/anu/Desktop/Stata/exp1.smcl"

use "/Users/anu/Downloads/q1_data_export/student.dta", clear
rename primary_teacher teacher
 
merge m:1 teacher using /Users/anu/Downloads/q1_data_export/teacher.dta, keep(match) 
merge m:1 school using  /Users/anu/Downloads/q1_data_export/school.dta, keep(match) nogen

keep if loc == "South"
sum attendance


use "/Users/anu/Downloads/q1_data_export/student.dta", clear
rename primary_teacher teacher

merge m:1 teacher using /Users/anu/Downloads/q1_data_export/teacher.dta, keep(match) 
merge m:1 school using  /Users/anu/Downloads/q1_data_export/school.dta, keep(match) nogen
merge m:1 subject using  /Users/anu/Downloads/q1_data_export/subject.dta, keep(match) nogen

keep if level == "High"
mean tested

use "/Users/anu/Downloads/q1_data_export/student.dta", clear

rename primary_teacher teacher
merge m:1 teacher using /Users/anu/Downloads/q1_data_export/teacher.dta, keep(match) 
merge m:1 school using  /Users/anu/Downloads/q1_data_export/school.dta, keep(match) nogen

sum gpa
keep if level == "Middle"
collapse (mean) attendance, by(school)
list
