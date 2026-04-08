# Assignment: Survey 2 - Remote Work Efficiency

## Survey Links
* **Google Sheet Form (Code):** [https://docs.google.com/spreadsheets/d/1PbTbxqbltNK65YTHf-wJQ_xa43uYOFeMpPIoTkhBHUo/edit?usp=sharing]
* **SurveyCTO Fill-out Link:** [https://gui2de.surveycto.com/collect/zs352_survey_2_2026?caseid=]

## Context for Peer Reviewer
This survey evaluates the efficiency and well-being of full-time employees working remotely. 
It utilizes several advanced SurveyCTO features required for this assignment, including:
* A pre-loaded server dataset (`survey2_data.csv`).
* The `search()` function to load departments and cascade employee names.
* The `pulldata()` function to automatically fetch baseline demographic data (age, phone number) based on the selected employee.
* Logical consistency checks using `calculate` (e.g., verifying total hours worked against a breakdown of tasks).
* A 5-point Likert scale to measure outcomes related to productivity and burnout.

**Target Population:** Full-time tech employees working from home (assumes baseline data is pre-loaded).

Comments by peer reviwer Abhinav below: 

Love the idea behind the survey - I think it's a very relevant topic given how work culture has evolved in the past 20-30 years! 
You mention using everything required to be used in the checklist for this assignment which is great! 
Consent check works correctly which is good!
Pre-loaded dataset works correctly. I chose my name and was able to see phone number and age! 
Multiple options being able to be selected for the tools provided by company option was well done! 
Total hours spent working yesterday was restricted from 0 to 24 which is good 
Following question asked "of those hours, how many were spent in a meeting?" - This number should be less than or equal to the previously inputted number but this check was missing! Would fix this! 
Oh never mind, I see what you have done! You have a sum check that checks if the sum adds up the first input. I input 23 initally and then my numbers added up to 99 and the sum check stopped me! Good touch! I still like checks on each sub-question as well (checking if I enter less than or equal to 23 every time if I initally input 23) but having an overall sum check is necessary and well done! 
Likert scale questions work well! 
Would recommend adding an ending message at the end of the survey! 

Overall, great job! Very well done! Don't see any big flaws and very clearly and concisely done! Code looks good as well! 

