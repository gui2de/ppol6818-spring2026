*Output in Box: https://georgetown.box.com/s/o1noiy5yzpose0r16pc6q6zfiz9eu7bn*

**Part 1: Sampling noise in a fixed population**
1. Develop some data generating process for data X’s and for outcome Y.
I generated a normally distributed x and a normally distributed error term u, and then defined the y as y = 1 + 0.8x + u.

2. Write a do-file that creates a fixed population of 10,000 individual observations and generate random X’s for them (use set seed to make sure it will always create the same data set). Create the Ys from the Xs with a true relationship and an error source. Save this data set in your Box folder.
I created a fixed population of 10,000 observations using set seed 12345, this is saved it as fixed_pop.dta.

3. Write a do-file defining a program that: (a) loads this data; (b) randomly samples a subset whose sample size is an argument to the program; (c) performs a regression of Y on X; and (e) returns the N, beta, SEM, p-value, and confidence intervals into r().
The program is called sim_fixed.
4. Using the simulate command, run your program 500 times each at sample sizes N = 10, 100, 1,000, and 10,000. Load the resulting data set of 2,000 regression results into Stata.
The results were saved as part1_results.dta.
5. Create at least one figure and at least one table showing the variation in your beta estimates depending on the sample size, and characterize the size of the SEM and confidence intervals as N gets larger.
I created a table and a boxplot. The main summary numbers are in two output files: part1_table.csv and part1_sem_ciw_table.csv.
From part1_table.csv, the mean beta estimates are: 0.802 at N = 10; 0.807 at N = 100; 0.810 at N = 1,000; 0.810 at N = 10,000. The average estimate stays very close to the true coefficient of 0.8. The standard deviation of beta is 0.381 at N = 10, 0.099 at N = 100, 0.032 at N = 1,000, and 0.000 at N = 10,000. The estimates are very noisy in small samples and much more stable in large samples.
From part1_sem_ciw_table.csv, the mean standard error is: 0.352 at N = 10; 0.102 at N = 100; 0.032 at N = 1,000; 0.010 at N = 10,000. The mean confidence interval is: 1.624 at N = 10; 0.406 at N = 100; 0.126 at N = 1,000; 0.040 at N = 10,000. These show that the precision improves as the sample gets larger.

6. Fully describe your results in your README file, including figures and tables as appropriate.
The key conclusion is that in the fixed-population setting, the beta estimate stays stays close to the true value of 0.8, but the amount of sampling noise depends heavily on sample size. Small samples produce much more variation across simulations, while larger samples produce more similar estimates, smaller standard errors, and narrower confidence intervals. At N = 10,000, the sample is the entire population, so cross-simulation sampling variation disappears.

**Part 2: Sampling noise in an infinite superpopulation.**
1. Write a do-file defining a program that: (a) randomly creates a data set whose sample size is an argument to the program following your DGP from Part 1 including a true relationship and an error source; (b) performs a regression of Y on one X; and (c) returns the N, beta, SEM, p-value, and confidence intervals into r().
The program is called sim_superpop, which creates a new dataset every time it is called.

2. Using the simulate command, run your program 500 times each at sample sizes corresponding to the first twenty powers of two (ie, 4, 8, 16 ...); as well as at N = 10, 100, 1,000, 10,000, 100,000, and 1,000,000. Load the resulting data set of 13,000 regression results into Stata.
The results were saved as part2_results.dta.

3. Create at least one figure and at least one table showing the variation in your beta estimates depending on the sample size, and characterize the size of the SEM and confidence intervals as N gets larger.
I created part2_table.csv, part2_beta_box.png, and part2_precision.png.
From part2_table.csv, the mean beta estimates are: 0.804 at N = 4, 0.779 at N = 10, 0.802 at N = 100, 0.801 at N = 1,000, 0.799 at N = 10,000, 0.800 at N = 100,000, and 0.800 at N = 1,000,000.
The standard deviation of beta falls from 1.077 at N = 4 to 0.367 at N = 10, 0.105 at N = 100, 0.031 at N = 1,000, 0.009 at N = 10,000, and about 0.001 at N = 1,000,000.

4. Fully describe your results in your README file, including figures and tables as appropriate.
The main result is that larger samples again produce more stable beta estimates, smaller standard errors, and narrower confidence intervals. However, unlike Part 1, there is still variation at N = 10,000, because each simulation generates a new sample rather than reusing a fixed population. Refer to part2_table.csv, part2_beta_box.png, and part2_precision.png for more information.

5. In particular, take care to discuss the reasons why you are able to draw a larger sample size than in Part 1, and why the sizes of the SEM and confidence intervals might be different at the powers of ten than in Part 1. Can you visualize Part 1 and Part 2 together meaningfully, and create a comparison table?
Part 1 is limited by a fixed population of 10,000 observations, so the largest possible sample is 10,000. In Part 2, each simulation generates a new sample, which makes much larger sample sizes possible. The comparison is shown in part1_part2_comparison.csv and part1_part2_beta_compare_clean.png. SEMs and confidence intervals also differ because Part 1 samples without replacement from a fixed finite population, whereas Part 2 draws a new random sample each time. As a result, sampling variation in Part 1 goes to zero as N approaches the full population, while in Part 2 it remains positive even at large N because each simulation creates a new dataset.

**Part 3: Power calculations for individual-level randomization**
1. Develop a data generating process for some Y that is normally disturbed around 0 with standard deviation of 1.
I generated untreated outcomes as normally distributed around zero with standard deviation one. 

2. The average treatment effect should be 0.1 sd (with the effects being uniformly distributed between 0.0 – 0.2 sd)
I generated individual treatment effects from a uniform distribution between 0 and 0.2, so the average treatment effect is 0.1 standard deviations.

3. The proportion of individuals receiving treatment should be 0.5 (i.e. half in control, and half in treatment) Calculate the number of individuals required to reach 80% power when you are trying to detect 0.1 sd treatment effect.
With 50% treated, the first total sample size that reaches at least 80 percent power is 3,100, and the empirical power at that point is 0.812.

4. Now assume, 15% of the sample will attrite (assume similar attrition rates in control and treatment arms.) How does this change your sample size calculations from the previous part?
With 15% attrition, the initial sample rises to 3,648.

5. Now assume the intervention is very expensive and we can only afford to provide this specific treatment to 30% of the sample. How would this change the sample size needed for 80% power.
When only 30% of the sample receives treatment, the first total sample size that reaches at least 80 percent power is 3,400, with empirical power at 0.802.

**Part 4: Power calculations for cluster randomization**
1. Develop data generating process for data for Y (assume math score of each individual student) in a school. We can only assign treatment at the school-level.

2. Your function should be able to change the number of clusters (i.e. schools) and the cluster size (i.e. number of students in each school)
Refer to program one_cluster_rct and get_cluster_power.

3. Make sure the rho/icc is ~ 0.3 when generating these clusters.
I set the school level variance to 0.3 and the student level variance to 0.7, which targets an ICC of about 0.3.

4. Divide the schools evenly between treatment and control arms. And generate a treatment effect of 0.2 sd (with the effects being uniformly distributed between 0.15 – 0.25 sd)
I generated school level treatment effects from a uniform distribution between 0.15 and 0.25, the average treatment effect is 0.2 standard deviations.

5. Holding the number of clusters fixed at 200, what happens to the power when you increase the cluster size (use first 10 powers of 2) What cluster size would you recommend and why?
When I hold the number of schools fixed at 200 and increase the number of students per school, power increases at first but then flattens out. This pattern is shown in part4_power_by_cluster_size.csv and part4_power_by_cluster_size.png. The reason is that students within the same school are correlated, so adding more students to the same school yields diminishing returns. Based on this pattern, I would recommend a moderate cluster size such as 16 or 32 students per school.

6. Now hold the cluster size fixed (15 students/school). How many schools do you need in your RCT to get 80% to detect 0.2 sd treatment effect.
With cluster size fixed at 15 students/school, the first one that reaches at least 80% power requires 300 schools, with empirical power about 0.872. As seen in part4_power_by_numschools.csv.

7. Now assume that only 70% of the schools actually adopt your treatment. How many schools do you need now to get 80% power?
When only 70% of treated schools actually adopt the treatment, the first design that reaches at least 80 percent power requires 580 schools, with empirical power about 0.826. As seen in part4_power_by_numschools_adopt70.csv.