/*==========================================================

	Author: Kenshi Kawade
	Title: stata3 assignement 
	Part: 4 out of 4

============================================================*/

if c(username) == "kkawade" {
    global boxd "/Users/kkawade/Library/CloudStorage/Box-Box/ppol6818"
}

// Replace username and path below
if c(username) == "username" { 
    global boxd  "C:/Users/username/Documents/username"  
}

* local directory
if c(username) == "kkawade" {
    global wd "/Users/kkawade/gu_class/ppol6818ex/week_8"
}

// Replace username and path below
if c(username) == "username" { 
    global wd  "C:/Users/username/Documents/username"  
}


cd "$boxd"

clear all
set more off
set seed 681803 // for reproducibility

/*==========================================================
1-3. DGP

unit: students
X: treatment; ipad access at school level
Y: math ~ Normal(0, 1) at student level
icc = 0.3 = rho
clusters: schools
clus size: number of students in each school

==========================================================*/

/*==========================================================
4. clustering program
==========================================================*/

capture program drop powerclus
program define powerclus, rclass
    syntax, n_clus(integer) s_clus(integer) rho(real) treat(real) adopt(real)

    clear

    local N = `n_clus' * `s_clus' // N = total number of students (obs)
    set obs `N'

    gen sc_id = ceil(_n / `s_clus')  // school id 
	gen st_id = _n

    /* ============================
    3. Generate math scores with ICC = rho = 0.3
	
    Variance decomposition: math score ij = school effect j + individual effect ij
    school effect ~ N(0, sqrt(0.3)) because school effect contributes 0.3 to total variance
    individual effect ~ N(0, sqrt(0.7)) because ind effect contributes 0.7 to total variance
    Total variance = 1, ICC = 0.3/1.0 = 0.3
    ============================*/
    local sc_sd = sqrt(`rho')          // school-level SD
    local st_sd = sqrt(1 - `rho')      // individual-level SD

    * generate each school-level effect per school, then merge to students
    tempfile student_effect
    save `student_effect', emptyok replace

    preserve
        keep sc_id
        bysort sc_id: keep if _n == 1          // one row per school
        gen sceff = rnormal(0, `sc_sd')               // school shock
        tempfile school_effect
        save `school_effect'
    restore

    merge m:1 sc_id using `school_effect', nogenerate

    * Individual-level noise
    gen steff = rnormal(0, `st_sd')

    * Baseline math score (no treatment yet)
    gen math = sceff + steff

    /* ==================================
    4. Assign treatment at school level
    `treatment' share of schools get treatment (randomised at school level)
    Within treated schools, adopt share actually implement the treatment
    Treatment effect ~ Uniform(0.15, 0.25), ATE = 0.2 SD
    ====================================*/

    * Randomly assign treatment to schools with `treat' share of treatment
    local n_treat = round(`n_clus' * `treat')

    bysort sc_id: gen rand_school = runiform() if _n == 1
    bysort sc_id: replace rand_school = rand_school[1]  // same value for all students in school

    * Rank schools by their random draw (unique ranking)
    egen school_rank = rank(rand_school), unique

    * The n_treat_schools lowest-ranked schools are assigned to treatment
    gen treated_school = (school_rank <= `n_treat')

	* Individual treatment effect ~ Uniform(0.15, 0.25), ATE = 0.2 SD
    gen treateff = runiform(0.15, 0.25)
	
    /*==============================
	7. Partial adoption (70%): within treated schools, only `adopt' fraction
    * actually implement the treatment (non-compliance)
	===================================*/
	* randomly assign willingness to adopt the treatement
    bysort sc_id: gen adopt_rand = runiform() if _n == 1
    bysort sc_id: replace adopt_rand = adopt_rand[1]
	
	* how many treated schools actually adopt the treatement
    gen actual_treat = treated_school * (adopt_rand <= `adopt')

    * Observed math score with treatment effect for actually-treated students
    replace math = math + treateff * actual_treat

    * regression with cluster-robust standard errors
    *cluster SEs at school level because students within schools are correlated 
    * -----------------------------------------------------------------------
    qui reg math actual_treat, vce(cluster sc_id)
    return scalar reject_yn = (r(table)["pvalue","actual_treat"] < 0.05)

end

/*==========================================================
5.

	n_clus: 200
	s_clus: 2 4 8 16 32 64 128 256 512 1024 
	treatment share: 0.5
	rho: 0.3
	adopt:1
	
	 What cluster size would you recommend and why?

==========================================================*/
tempname step5
postfile `step5' clus_size power using "$boxd/output/stata3_q5.dta", replace

foreach v in 2 4 8 16 32 64 128 256 512 1024 {
    qui simulate reject_yn = r(reject_yn), reps(500): powerclus, n_clus(200) s_clus(`v') rho(0.3) treat(0.5) adopt(1.0)
    quietly sum reject_yn
    local pw = r(mean)
    post `step5' (`v') (`pw')
    display as error "Cluster size = `v': Power = `pw'"
}

postclose `step5'

/*
Cluster size = 2: Power = .292
Cluster size = 4: Power = .26
Cluster size = 8: Power = .23
Cluster size = 16: Power = .214
Cluster size = 32: Power = .256
Cluster size = 64: Power = .418
Cluster size = 128: Power = .892
Cluster size = 256: Power = .906
Cluster size = 512: Power = .902
Cluster size = 1024: Power = .926
*/

/*==========================================================
6.

	n_clus: ?
	s_clus: 15
	treatment share: 0.5
	rho: 0.3
	adopt:1
	
	How many schools do you need in your RCT to get 80% to detect 0.2 sd treatment effect.
	
==========================================================*/


tempname step6
postfile `step6' n_clus power using "$boxd/output/stata3_q6.dta", replace

forvalues v = 500(100)1000 {
    qui simulate reject_yn = r(reject_yn), reps(500): powerclus, n_clus(`v') s_clus(15) rho(0.3) treat(0.5) adopt(1.0)
    quietly sum reject_yn
    local pw = r(mean)
    post `step6' (`v') (`pw')
    display as error "Number of school = `v': Power = `pw'"
}

postclose `step6'
** not enough yet

tempname step6
postfile `step6' n_clus power using "$boxd/output/stata3_q6.dta", replace

forvalues v = 2000(100)3000 {
    qui simulate reject_yn = r(reject_yn), reps(500): powerclus, n_clus(`v') s_clus(15) rho(0.3) treat(0.5) adopt(1.0)
    quietly sum reject_yn
    local pw = r(mean)
    post `step6' (`v') (`pw')
    display as error "Number of school = `v': Power = `pw'"
}

postclose `step6'

/*
Number of school = 2000: Power = .784
Number of school = 2100: Power = .79
Number of school = 2200: Power = .8159999999999999
Number of school = 2300: Power = .798
Number of school = 2400: Power = .866
Number of school = 2500: Power = .85
Number of school = 2600: Power = .9
Number of school = 2700: Power = .896
Number of school = 2800: Power = .9
Number of school = 2900: Power = .928
Number of school = 3000: Power = .914
*/

/*==========================================================
6.

	n_clus: ?
	s_clus: 15
	treatment share: 0.5
	rho: 0.3
	adopt:0.7
	
	How many schools do you need now to get 80% power?	
	
==========================================================*/

tempname step7
postfile `step7' n_clus power using "$boxd/output/stata3_q7.dta", replace

forvalues v = 3000(100)4000 {
    qui simulate reject_yn = r(reject_yn), reps(500): powerclus, n_clus(`v') s_clus(15) rho(0.3) treat(0.5) adopt(0.7)
    quietly sum reject_yn
    local pw = r(mean)
    post `step7' (`v') (`pw')
    display as error "Number of school = `v': Power = `pw'"
}

postclose `step7'

/*
Number of school = 3000: Power = .784
Number of school = 3100: Power = .794
Number of school = 3200: Power = .8080000000000001
Number of school = 3300: Power = .856
Number of school = 3400: Power = .866
Number of school = 3500: Power = .86
Number of school = 3600: Power = .868
Number of school = 3700: Power = .876
Number of school = 3800: Power = .89
Number of school = 3900: Power = .898
Number of school = 4000: Power = .882
*/




