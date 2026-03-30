
gen clean_html = s

gen clean_text = ustrregexra(clean_html, "<[^>]+>", "")

gen school_name = regexs(1) if regexm(clean_text, "([A-Z\s]+) - (PS\d{7})")
gen school_code = regexs(2) if regexm(clean_text, "([A-Z\s]+) - (PS\d{7})")

* Number of students
gen num_students = real(regexs(1)) if regexm(clean_text, "WALIOFANYA MTIHANI\s*[:]\s*(\d+)")

* Average score
gen avg_score = real(regexs(1)) if regexm(clean_text, "WASTANI WA SHULE\s*[:]\s*([\d\.]+)")

* Student group
gen student_group_bin = 1 if regexm(clean_text, "Wanafunzi chini ya 40")
replace student_group_bin = 0 if regexm(clean_text, "Wanafunzi 40 au zaidi")

* School rankings
gen rank_council = real(regexs(1)) if regexm(clean_text, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI\s*[:]\s*(\d+)\s*kati ya\s*(\d+)")

gen rank_region = real(regexs(1)) if regexm(clean_text, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA\s*[:]\s*(\d+)\s*kati ya\s*(\d+)")

gen rank_national = real(regexs(1)) if regexm(clean_text, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA\s*[:]\s*(\d+)\s*kati ya\s*(\d+)")

collapse (first) school_name school_code num_students avg_score ///
         student_group_bin rank_council rank_region ///
         rank_national 
