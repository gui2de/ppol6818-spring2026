# Survey 2: Urban Delivery Rider Endline Survey

## Survey Description
This is an endline survey targeting urban food delivery and courier riders 
in Chinese cities (Meituan, Ele.me, etc.). It covers four modules: 
respondent identification, demographics, work quantification, and health outcomes.

- **Target population:** Urban delivery riders in China  
- **Survey type:** Endline (follow-up from baseline)  
- **Total questions:** 27  

## Links

- **SurveyCTO Form (Google Sheets): https://docs.google.com/spreadsheets/d/1qtvp_RcFiJZNXr1taMJ-F7KErYPJucTP/edit?usp=drive_link&ouid=100558683691038492251&rtpof=true&sd=true

- **Survey Fill-out Link: https://gui2de.surveycto.com/collect/Survey2_qy111_Qingfeng?caseid=
- 
## Notes for Peer Reviewer
- Server dataset `qy111_respondent_dataset` contains 22 baseline respondents.
- Module 1 uses `search()` for cascading respondent selection and `pulldata()` to auto-fill phone and city.
- Module 3 includes `calculate` fields for weekly working hours and total income consistency checks.
- Module 4 includes Likert-scale questions on platform fairness and job satisfaction.
