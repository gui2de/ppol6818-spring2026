use /Users/anu/Downloads/q2_village_pixel.dta, clear
bysort pixel: egen min_payout = min(payout)
bysort pixel: egen max_payout = max(payout)
gen pixel_consistent = (min_payout == max_payout)
label define pixcon 0 "Inconsistent" 1 "Consistent"
label values pixel_consistent pixco
tab pixel_consistent

bysort village: egen n_pixels = nvals(pixel)

gen pixel_village = (n_pixels > 1)
label define pixvil 0 "Single pixel village" 1 "Multiple pixel village"
label values pixel_village pixvil

preserve
collapse (min) min_payout (max) max_payout, by(village pixel)
gen pixel_payout_consistent = (min == max)
drop min max
tempfile vp
save mew
restore

merge m:1 village pixel using mew, nogen

bysort village: egen village_min = min(payout)
bysort village: egen village_max = max(payout)

gen village_payout_diff = (village_min != village_max)

gen village_class = .

replace village_class = 1 if n_pixels == 1
replace village_class = 2 if n_pixels > 1 & village_payout_diff == 0
replace village_class = 3 if n_pixels > 1 & village_payout_diff == 1

label define vclass 1 "Single pixel village" ///
                    2 "Multi-pixel, same payout" ///
                    3 "Multi-pixel, different payout"
label values village_class vclass

list hhid village pixel payout if village_class == 2

