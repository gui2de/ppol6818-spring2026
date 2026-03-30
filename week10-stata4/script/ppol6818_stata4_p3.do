/*===========================
	
	Author: Kenshi Kawade
	Date: March 25, 2026
	Title: ppol6818 stata4
	Part: 3 of 3
	
=============================*/

if c(username) == "kkawade" {
    global wd "/Users/kkawade/GU_Class/ppol6818ex"
}

if c(username) == "username" {
    global wd "yourpathway"
}

cd "$wd/week_10/02_data"



import excel "/Users/kkawade/gu_class/ppol6818ex/week_10/02_data/state_unemp.xlsx", sheet("Sheet1") firstrow clear
replace state = strlower(state)
save "$wd/week_10/03_output/stateemp.dta", replace

shp2dta using "$wd/week_10/02_data/States_shapefile", ///
data("us_states_db") coor("us_states_co") genid(id) replace

use "us_states_db.dta", clear
rename State_Name state
replace state = strlower(state)

merge 1:1 state using "$wd/week_10/03_output/stateemp.dta"

spmap unemp using "us_states_co.dta", id(id) ///
	title("Unemployment Rates for States, Seasonally Adjusted (2025)") subtitle("Source: U.S. Bureau of Labor Statistics") clnumber(4) fcolor(Blues)

graph export "$wd/week_10/03_output/ppol6818_stata4_spmap.png",replace
