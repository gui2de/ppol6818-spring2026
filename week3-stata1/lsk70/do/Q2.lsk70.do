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
log using "$out/Q2.log", text replace

****************************************************
* Load Q2 data
use "$data/q2_village_pixel.dta", clear

*Answering questions

*a: Create variable checking if there is intra-pixel variation in payouts

bys pixel: egen min_payout = min(payout) 	// for each pixel group, ID min payout per pixel and tag each row with that data
bys pixel: egen max_payout = max(payout)	// "" ID max payout per pixel ""

gen pixel_consistent = (min_payout == max_payout)	// create new variable to ID when there is no variation in payout within pixel

tab pixel_consistent

*Within every pixel all households have the same payout status

*b: Create variable checking if village spans multiple pixels

bys village pixel: gen byte pixel_tag = (_n == 1)   // tag unique pixels within village groups
bys village: egen n_pixels = total(pixel_tag)       // count unique pixel tags per village

gen pixel_village = (n_pixels > 1)                  // =1 if village spans multiple pixels

tab pixel_village

*c: Classify villages based on pixel span and payout variation

*Define pixel-level payout (constant within pixel)
bys pixel: egen pixel_payout = min(payout)

*Within each village, check variation in pixel payouts
bys village: egen min_pixel_payout = min(pixel_payout)
bys village: egen max_pixel_payout = max(pixel_payout)

*Village classification
gen village_type = .

replace village_type = 1 if pixel_village == 0

replace village_type = 2 if pixel_village == 1 & min_pixel_payout == max_pixel_payout

replace village_type = 3 if pixel_village == 1 & min_pixel_payout != max_pixel_payout

tab village_type

*Export hhid for type 2 villages (included other data for context)
preserve
    keep if village_type == 2
    keep hhid village pixel payout
    sort village hhid
    export delimited using "$out/Q2c_value2_households.csv", replace
restore

****************************************************

log close
