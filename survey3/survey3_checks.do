/*-----------------------------------------//
**Survey 3 
PPOL6818
High-frequency Checks


********************************************************************************/
set more off
clear
drop _all

********************************************************************************
*A. CHANGE DATE BELOW EVERYDAY
********************************************************************************
global date 20260413			

********************************************************************************
*B. INTEROPERABILITY
********************************************************************************
 
if c(username)=="ac2221" {
	global user "Arnesh's file path"
	}
	
else if c(username)=="kkawade" {
	global user "~/gu_class/ppol6818ex/week_12"
	}

else if {
	display as error "Update the global according to your machine before running this do file"
	exit 
	}
	
cd "$user/02_data"
use "survey_data_3errors_final.dta", clear


*-----------------------------------------------------------------------*
* Check 1: Duplicate Respondent IDs
duplicates tag respondent_id, generate(dup_flag)
list respondent_id dup_flag if dup_flag > 0, sepby(respondent_id)




* Check 2: Income and Hours Consistency Check
* Consistency in hours worked 
lookfor hour
codebook hours

preserve

gen hourser = (hours_worked > 50)
keep if hourser == 1

//save "$user/03_outcome/survey_data_hourserror.dta", replace

restore

* Consistency in income

preserve 

gen incomeerr = (biwk_income < 0 )
keep if incomeerr == 1

//save "$user/03_outcome/survey_data_incomeerror.dta", replace

restore



* Check 3: Budget Constraint Check
lookfor expenditure

gen residual = bonus_received_2wk+ other_benefit_amt_2wk - food_spend_2wk- phone_bill_biwk - broadband_cost_biwk - tv_subscription_biwk - transport_cost_2wk - fuel_cost_2wk - vehicle_tax_2wk - car_insurance_2wk - cleaning_spend_2wk - utility_bill_biwk - energy_spend_2wk - edu_spend_2wk - student_loan_payment_2wk + tuition_grant_received_2wk - personal_care_spend_2wk - alcohol_cig_spend_2wk - nonessential_clothing_2wk - extracurricular_spend_2wk - religious_spend_2wk - private_hc_spend_2wk - total_health_spend_2wk - rent_or_mortgage_biwk - utility_bill_biwk_housing + biwk_income - home_insurance_2wk + remittances + current_savings - net_borrowing +asset_sales

gen inflow = bonus_received_2wk + other_benefit_amt_2wk + tuition_grant_received_2wk + biwk_income + remittances + current_savings

gen flag_residual = 1 if residual < 0.3*inflow & residual < 0
replace flag_residual = 0 if flag_residual ==.


//save "$user/03_outcome/survey_data_morespendthanincome.dta", replace
