cd "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 4/data"

cap which spmap
if _rc ssc install spmap, replace

* Convert the shapefile to Stata format
spshape2dta CA_Counties, replace


* Open shapefile attributes and identify county names
use CA_Counties.dta, clear
describe

gen county = upper(strtrim(NAME))
replace county = subinstr(county, " COUNTY", "", .)

keep _ID county
tempfile shp_ids
save `shp_ids'

* Prepare the coordinate file for mapping
use CA_Counties_shp.dta, clear
merge m:1 _ID using `shp_ids'
keep if _merge == 3
drop _merge
save CA_Counties_mapcoords.dta, replace

* Import the 2023 income-limits CSV
import delimited "ca_income_limits_2023.csv", clear varnames(1)

describe

replace county = upper(strtrim(county))
replace county = subinstr(county, " COUNTY", "", .)

keep county ami
tempfile income
save `income'


* Merge income data with county IDs
use `shp_ids', clear

replace county = upper(strtrim(county))
replace county = subinstr(county, " COUNTY", "", .)

merge 1:1 county using `income'

tab _merge

keep if _merge == 3
drop _merge
save CA_AMI_mapdata.dta, replace

* Draw the choropleth map
use CA_Counties_mapcoords.dta, clear
sort _ID
save CA_Counties_mapcoords.dta, replace

use CA_AMI_mapdata.dta, clear
sort _ID

spmap ami using CA_Counties_mapcoords.dta, id(_ID) ///
    clmethod(custom) clbreaks(83800 90000 100000 110000 130000 181300) ///
    title("California County Area Median Income (AMI)" "2023", size(medsmall)) ///
    legtitle("AMI (USD)")

graph export "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 4/data/part3_ca_ami_choropleth_2023.png", replace
