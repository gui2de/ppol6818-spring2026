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
log using "$out/Q3.log", text replace

****************************************************

*Loaf Q3 data
use "$data/q3_proposal_review.dta", clear

*Fix typos / align naming
rename Rewiewer1 Reviewer1
rename Review1Score Reviewer1Score

*Rename score vars to match stub ReviewerScore#
rename Reviewer1Score ReviewerScore1
rename Reviewer2Score ReviewerScore2
rename Reviewer3Score ReviewerScore3

*Keep only needed vars
keep proposal_id Reviewer1 Reviewer2 Reviewer3 ///
     ReviewerScore1 ReviewerScore2 ReviewerScore3

*Reshape wide -> long
reshape long Reviewer ReviewerScore, i(proposal_id) j(revpos)

rename Reviewer netid
rename ReviewerScore score

*Check
list proposal_id revpos netid score in 1/12, sep(0)

*Reviewer-specific mean and SD of raw scores
bys netid: egen reviewer_mean = mean(score)		// for unique net id's take mean across scores
bys netid: egen reviewer_sd   = sd(score)		// "" take sd accross scores

*Sanity checks
count if reviewer_sd == 0 & !missing(reviewer_sd)	// check bc sd=0 creates error in z score
count if missing(score)

*Standardized (z) score for each review
gen double stand_score = (score - reviewer_mean) / reviewer_sd

*Rename variables for restructuring
keep proposal_id revpos stand_score
reshape wide stand_score, i(proposal_id) j(revpos)

rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

*Quick check
list proposal_id stand_r1_score stand_r2_score stand_r3_score in 1/10, sep(0)

*Create var for avg standardized score across reviewers
egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)

*Create ranking from highest to lowest score
egen rank = rank(-average_stand_score)
sort rank

*Quick check
list proposal_id average_stand_score rank in 1/10, sep(0)

*Export ranking list
export delimited using "$out/Q3_ranked_proposals.csv", replace

****************************************************

log close


