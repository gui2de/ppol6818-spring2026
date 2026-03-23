* Part 1, Do-File 1: Data Generating Process (DGP)

* Set working directory
cd "/Users/gracehuang/Documents/MPP/PPOL6818_mac/Stata 3"

clear
* Use set seed to make sure it will always create the same data set 
set seed 2026 

* Create a fixed population of 10,000 individual observations 
set obs 10000

* Develop data generating process for data X's 
gen x = rnormal(50, 10)

* Create the Ys from the Xs with a true relationship and an error source 
gen error = rnormal(0, 5)
gen y = 5 + (2 * x) + error

* Save this data set in your folder
save "Part1_Fixed_Population.dta", replace
