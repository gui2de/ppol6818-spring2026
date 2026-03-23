# Part 4: Power calculations for cluster randomization
## Instructions
1. Develop data generating process for data for Y (assume math score of each individual student) in a school. We can only assign treatment at the school-level.
2. Your function should be able to change the number of clusters (i.e. schools) and the cluster size (i.e. number of students in each school)
3. Make sure the rho/icc is ~ 0.3 when generating these clusters. [Hint](https://www.statalist.org/forums/forum/general-stata-discussion/general/1460617-how-to-simulate-clustered-data-with-a-specific-intra-class-correlation).
4. Divide the schools evenly between treatment and control arms. And generate a treatment effect of 0.2 sd (with the effects being uniformly distributed between 0.15 – 0.25 sd)
5. Holding the number of clusters fixed at 200, what happens to the power when you increase the cluster size (use first 10 powers of 2) What cluster size would you recommend and why?
6. Now hold the cluster size fixed (15 students/school). How many schools do you need in your RCT to get 80% to detect 0.2 sd treatment effect.
7. Now assume that only 70% of the schools actually adopt your treatment. How many schools do you need now to get 80% power?

## Define a Program 
First, I set my DGP as followed:
- unit: students
- X: treatment
- Y: math ~ Normal(0, 1) at student level
- icc = 0.3 = rho
- clusters: schools
- clus size: number of students in each school

The program is defined below. What this function does is;

1. Generate student obs
2. Generate math scores with ICC = rho = 0.3
	1. Variance decomposition: math score ij = school effect j + individual effect ij
   2. school effect ~ N(0, sqrt(0.3)) because school effect contributes 0.3 to total variance
    3. individual effect ~ N(0, sqrt(0.7)) because ind effect contributes 0.7 to total variance
    4. Total variance = 1, ICC = 0.3/1.0 = 0.3
3. Assign treatment at school level
    1. `treatment' share of schools get treatment (randomised at school level)
    2. Within treated schools, adopt share actually implement the treatment
    3. Treatment effect ~ Uniform(0.15, 0.25), ATE = 0.2 SD
4. 	Reflect partial adoption within treated schools

```stata
capture program drop powerclus
program define powerclus, rclass
    syntax, n_clus(integer) s_clus(integer) rho(real) treat(real) adopt(real)

    clear

    local N = `n_clus' * `s_clus' // N = total number of students (obs)
    set obs `N'

    gen sc_id = ceil(_n / `s_clus')  // school id 
	gen st_id = _n

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

	* randomly assign willingness to adopt the treatement
    bysort sc_id: gen adopt_rand = runiform() if _n == 1
    bysort sc_id: replace adopt_rand = adopt_rand[1]
	
	* how many treated schools actually adopt the treatement
    gen actual_treat = treated_school * (adopt_rand <= `adopt')

    * Observed math score with treatment effect for actually-treated students
    replace math = math + treateff * actual_treat

    * regression with cluster-robust standard errors
    *cluster SEs at school level because students within schools are correlated 
    qui reg math actual_treat, vce(cluster sc_id)
    return scalar reject_yn = (r(table)["pvalue","actual_treat"] < 0.05)

end
```

## What cluster size would you recommend out of first 10 powers of 2 and why?
### Codes and Outcomes
```stata
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
```
I would recommend cluster size of **1024** as it has the highest power. However, it depends on the financial or physical restrictions. To have at least 80% of power, we only need cluster size of **128**.





