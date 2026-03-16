

global wd "/Users/yousrahussain/Library/CloudStorage/OneDrive-GeorgetownUniversity/Experimental Design"
*update the wd global so that it refers to the Box folder filepath on your machine

global excel_t21 "$wd//Assignment/q4_Pakistan_district_table21.xlsx"


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
	
***Dropping empty cells 
foreach v of varlist _all {
        capture count if !missing(`v')
        if r(N) == 0 {
            drop `v'
        }
    }

*** Standardizing column numbers 
rename * col#, addnumber
rename col1 table21

**to remove the empty spaces
replace table21 = "18 AND ABOVE" if regexm(table21, "18 AND") | regexm(table21, "OVERALL")

**what columns to keep 
capture keep table21 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13 table_number
	
	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %40s table21 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13
