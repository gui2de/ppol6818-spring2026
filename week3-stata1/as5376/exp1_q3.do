rename Review1Score score1
rename Reviewer2Score score2
rename Reviewer3Score score3

rename Rewiewer1 reviewer1
rename Reviewer2 reviewer2
rename Reviewer3 reviewer3

reshape long score reviewer, i(proposal_id) j(review_num)

bysort reviewer: egen reviewer_mean = mean(score)
bysort reviewer: egen reviewer_sd   = sd(score)

gen stand_score = (score - reviewer_mean) / reviewer_sd

keep proposal_id review_num stand_score

reshape wide stand_score, i(proposal_id) j(review_num)

rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score) / 3

egen rank = rank(-average_stand_score), unique

summarize stand_r1_score stand_r2_score stand_r3_score
summarize average_stand_score
tab rank
