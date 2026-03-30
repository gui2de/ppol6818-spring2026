********************************************************************
* Assignment Stata 8 - Part 3
* Qingya Yang
********************************************************************
cd "D:\yqy\硕士-mpp\第四学期\experimental design\assignment-stata4"

********************************************************************
*** Part 3: Spatial Analysis - Choropleth Map
*** Variable: GDP per Capita by Province, China 2021
********************************************************************

* Convert Shapefile to Stata format (run once)
shp2dta using "shapefile\gadm41_CHN_1.shp", ///
    database("china_db.dta")                ///
    coordinates("china_coord.dta")          ///
    genid(id) replace

* Remove duplicate rows in shapefile database (Xinjiang & Xizang have multiple entries)
duplicates drop NAME_1, force
save "china_db_dedup.dta", replace

* Load statistical data and keep 2021 observations
use "Part3_dataset.dta", clear
keep if year == 2021
keep province gdp_percap
rename province NAME_1

* Correct province names to match GADM Shapefile spelling
replace NAME_1 = "Nei Mongol"     if NAME_1 == "Inner Mongolia"
replace NAME_1 = "Ningxia Hui"    if NAME_1 == "Ningxia"
replace NAME_1 = "Xinjiang Uygur" if NAME_1 == "Xinjiang"

* Merge statistical data with deduplicated shapefile database
merge 1:1 NAME_1 using "china_db_dedup.dta"

* Check merge results
* _merge==2 is expected for Hong Kong, Macau, and Xizang
* (present in Shapefile but not in our dataset)
list NAME_1 _merge if _merge != 3

drop _merge
save "china_db_merged.dta", replace

* Generate choropleth map
use "china_db_merged.dta", clear

spmap gdp_percap using "china_coord.dta", ///
    id(id)                                ///
    clnumber(5)                           ///
    clmethod(quantile)                    ///
    fcolor(Blues)                         ///
    ocolor(white ..)                      ///
    osize(0.1 ..)                         ///
    legend(size(*1.2) pos(7))             ///
    title("GDP per Capita by Province", size(*1.3)) ///
    subtitle("China, 2021 (Yuan)")        ///
    note("Source: GADM Shapefile + Part3_dataset.dta" ///
         "Classification: Quantile (5 classes)")

* Export map as image
graph export "choropleth_gdp_2021.png", replace width(2400)
