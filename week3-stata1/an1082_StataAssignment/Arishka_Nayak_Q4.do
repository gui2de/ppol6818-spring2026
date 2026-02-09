	clear all
	global wd "C:\Users\arish\Desktop\McCourt\Spring 2026\Experimental Design\Assignment 3"
	*update the wd global so that it refers to the Box folder filepath on your machine

	global excel_t21 "C:/Users/arish/Desktop/McCourt/Spring 2026/Experimental Design/Assignment 3/assignment_ Stata 1/q4_Pakistan_district_table21.xlsx"

	clear

	*setting up an empty tempfile
	tempfile table21
	save `table21', replace emptyok

	forvalues i=1/135 {
		import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
		display as error `i' //display the loop number
**for each excel sheet, it is going to specifically go to Table 1

		keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
		*regexm=regular expressions, it will look for partial phrases 
		keep in 1 //there are 3 of them, but we want the first one
		
		foreach v of varlist _all{
			count if !missing(`v')
			if r(N) == 0 {
				drop `v'
			}
		}
		
		**here _all is a shortcut for all the variables
		**counts how many cells in that column actually have data
		**If all cells=zero, we delete.
		
		rename * col#, addnumber
		**renaming all cols to a generic sequence
		rename col1 table21
		
		
		replace table21 = "18 AND ABOVE" if regexm(table21, "18 AND") | regexm(table21, "OVERALL")
		**for all the - - - data points in the sheet
		
		gen table=`i' //to keep track of the sheet we imported the data from
		append using `table21' 
		save `table21', replace //saving the tempfile so that we don't lose any data
	}
	*load the tempfile
	use `table21', clear
	*fix column width issue so that it's easy to eyeball the data
format %40s table21 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13 

rename table21 age_group
rename col2  all_total
rename col3  all_cnic_obt
rename col4  all_cnic_nobt
rename col5  male_total
rename col6  male_cnic_yes
rename col7  male_cnic_no
rename col8  female_total
rename col9  female_cnic_yes
rename col10 female_cnic_no
rename col11 trans_total
rename col12 trans_cnic_yes
rename col13 trans_cnic_no

order table
sort table

