****************************************************
* PPOL 6818 – Stata Assignment 1
* Luke Keller
*
* Folder structure:
* lsk70/
* ├── do/        (do-files)
* ├── data/      (raw inputs: .dta, .xlsx, .pdf)
* └── outputs/   (log files, generated outputs)
****************************************************

clear all					
set more off 

*Working directory set-up

if c(username) == "lukekeller" {
	global wd "/Users/lukekeller/Desktop/ppol6818-spring2026/week3-stata1/lsk70"
} 

*Subfolder set-up

global do    "$wd/do"
global data  "$wd/data"    
global out   "$wd/outputs"

cd "$wd"

*Create outputs folder if it doesn't alreadt exist
capture mkdir "$out"

*Start log
capture log close
log using "$out/Q1.log", text replace

****************************************************

*Check keys*

*Teacher key should be unique in teacher.dta
preserve
use "$data/teacher.dta", clear
isid teacher
restore

*Subject key should be unique in subject.dta
preserve
use "$data/subject.dta", clear
isid subject
restore

*School key should be unique in school.dta
preserve
use "$data/school.dta", clear
isid school
restore

****************************************************

*Set up an edited student-level data set for analaysis

*Load student data
use "$data/student.dta", clear
isid stdnt_num
describe

*Standardize teacher ID name for merging
rename primary_teacher teacher

*Merge teacher info onto students
merge m:1 teacher using "$data/teacher.dta"
tab _merge

*Checked _merge, so can clean it up
drop _merge

* Merge subject info onto student-teacher data
merge m:1 subject using "$data/subject.dta"
tab _merge
drop if _merge == 2   // drop subject-only rows (if any)
drop _merge

* Merge school info onto student-teacher-subject data
merge m:1 school using "$data/school.dta"
tab _merge
drop if _merge == 2   // drop school-only rows (if any)
drop _merge

****************************************************

*Answer assignment questions

*a: Mean attendance for schools in the South
mean attendance if loc == "South"

*b: Proportion of HS students with tested-subject teacher
mean tested if level == "High"

*c: Mean GPA of all students in district

*GPA currently measured at school level, must be weighted by n students

*Counting n students per school and saving for calculations
preserve
	collapse (count) n_students = stdnt_num, by(school)		// aggregates data by schools with only column as requested computed statistic, count
	tempfile counts_school		// creates a named place/path for the data
	save `counts_school', replace	// sends the data to the aforementioned labeled place
restore

*Merging school counts with school gpa
preserve
	keep school gpa		// drops all columns except school, gpa
	bys school: keep if _n == 1 // makes groups according to school then drops all rows except the first per group
	
	merge 1:1 school using `counts_school'
    tab _merge
    assert _merge == 3
    drop _merge

	*Calculating weighted mean
    gen double gpa_x_n = gpa * n_students		// double: asking for more precise
    quietly summarize gpa_x_n
    scalar num = r(sum)		// num = numerator, sum of gpa x n students for every school
    quietly summarize n_students	
    scalar den = r(sum)		// den = denominator, sum of total students in district
	display num / den
restore

*d: Mean attendenace for each middle school
preserve
    keep if level == "Middle"

    collapse (mean) mean_attendance = attendance, by(school)

    sort school		// alphebetizes results
    list, sep(0)	// removes gaps in table (cosmetic)

    export delimited using "$out/Q1d_middle_school_mean_attendance.csv", replace
restore		// exports as csv to outputs folder

****************************************************

log close



