*Maimoona Mohsin* 
*PS- Experimental Design - Q4 - Pakistan CNIC* 
*Please see word for answers 

clear all 
set more off 

global wd "C:\Users\maimo\OneDrive\Desktop\Semester 2\Experimental Design & Implement\Stata 1 assignment"
cd "$wd"
global excel_t21_Maimoona "C:\Users\maimo\OneDrive\Desktop\Semester 2\Experimental Design & Implement\Stata 1 assignment\q4_Pakistan_district_table21.xlsx"

display "$excel_t21_Maimoona"

import excel "$excel_t21_Maimoona", sheet("Table 1") firstrow clear allstring

dir "*.xlsx"

import excel "$excel_t21_Maimoona", sheet("Table 1") firstrow clear allstring

describe 

list if regexm(TABLE21PAKISTANICITIZEN1, "18 AND")

keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND")
keep in 1

list 

*So far i have Imported Table 1 then found all "18 AND ABOVE" rows and kept  only the first one (the total)* 

rename TABLE21PAKISTANICITIZEN1 table21
describe

keep table21 B C D E F G H I J K L M
describe

gen table = 1
list

tempfile table21
save `table21', replace emptyok

forvalues i = 1/135 {
	 import excel "$excel_t21_Maimoona", sheet("Table `i'") firstrow clear allstring
	 display as error `i'
	 keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND")
	 keep in 1
	 rename TABLE21PAKISTANICITIZEN1 table21
	 gen table = `i'
	 append using `table21'
	 save `table21', replace
}

save "q4_table21_18andabove.dta", replace

use "q4_table21_18andabove.dta", clear
count

duplicates list table

duplicates drop table, force

count 


drop if table21=="OVERALL"

rename B  all_total
rename C  all_obtained
rename D  all_not

rename E  male_total
rename F  male_obtained
rename G  male_not

rename H  female_total
rename I  female_obtained
rename J  female_not

rename K  trans_total
rename L  trans_obtained
rename M  trans_not

foreach v in all_total all_obtained all_not ///
           male_total male_obtained male_not ///
           female_total female_obtained female_not ///
           trans_total trans_obtained trans_not {
    replace `v' = "." if trim(`v') == ""
}


keep table table21 ///
     all_total all_obtained all_not ///
     male_total male_obtained male_not ///
     female_total female_obtained female_not ///
     trans_total trans_obtained trans_not

*non numbers into missing 

foreach v in all_total all_obtained all_not ///
           male_total male_obtained male_not ///
           female_total female_obtained female_not ///
           trans_total trans_obtained trans_not {
    replace `v' = "." if trim(`v')=="" | `v'=="-" | `v'=="—"
}

foreach v in all_total all_obtained all_not ///
           male_total male_obtained male_not ///
           female_total female_obtained female_not ///
           trans_total trans_obtained trans_not {
    replace `v' = subinstr(`v', ",", "", .)
    destring `v', replace
}

gen check_all = all_total - (all_obtained + all_not)
list table all_total all_obtained all_not if check_all != 0 & !missing(check_all)






