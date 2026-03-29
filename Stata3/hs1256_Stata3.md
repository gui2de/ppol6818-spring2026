\# README – Part 1: Sampling Noise in a Fixed Population



Since I am not familiar with composing README file as I never did this before, ChatGPT is used to organize the following file,



\## 1. Data Generating Process (DGP)



I construct a fixed population of 10,000 individuals. The data-generating process is defined as:



\- The independent variable \\( X \\) is drawn from a uniform distribution:  

&#x20; \\( X \\sim U(0,1) \\)

\- The error term \\( u \\) follows a standard normal distribution:  

&#x20; \\( u \\sim N(0,1) \\)

\- The outcome variable is generated as:  

&#x20; \\( Y = 1 + 2X + u \\)



Thus, the true population coefficient on \\( X \\) is \*\*2\*\*.



\---



\## 2. Simulation Design



A fixed dataset of 10,000 observations is generated and saved. From this population, repeated random samples are drawn.



For each sample size \\( N \\in \\{10, 100, 1000, 10000\\} \\):



\- 500 random samples are drawn

\- A regression of \\( Y \\) on \\( X \\) is estimated

\- The following statistics are recorded:

&#x20; - Estimated coefficient (beta)

&#x20; - Standard error (SE)

&#x20; - p-value

&#x20; - Confidence interval bounds



This results in a total of \*\*2,000 regression estimates\*\*.



\---



\## 3. Results



\### 3.1 Variation in Beta Estimates



!\[Beta Boxplot](beta\_box.png)



The boxplot of estimated coefficients shows that:



\- At small sample size (N=10), the estimates are highly dispersed, ranging widely and often far from the true value of 2

\- As sample size increases, the distribution of beta estimates becomes increasingly concentrated

\- At N=10,000, the estimates are almost identical across simulations and tightly centered around the true value



This demonstrates that larger samples reduce sampling variability and improve estimation accuracy.



\---



\### 3.2 Variation in Standard Errors



!\[SE Boxplot](se\_box.png)



The boxplot of standard errors shows a clear downward trend:



\- At N=10, the standard error is large and highly variable

\- At N=100 and N=1000, standard errors decrease substantially

\- At N=10,000, the standard error becomes very small and nearly constant across simulations



This confirms that standard errors decrease as sample size increases.



\---



\### 3.3 Summary Table



The summary statistics show that:



\- Mean beta approaches the true value (≈2) as N increases

\- The variability of beta decreases with N

\- Confidence interval width shrinks as N increases

\- The proportion of statistically significant results increases with sample size



\---



\## 4. Interpretation



The results illustrate key statistical principles:



1\. \*\*Sampling variability decreases with sample size\*\*  

&#x20;  Small samples produce unstable estimates with high dispersion.



2\. \*\*Consistency of estimators\*\*  

&#x20;  As sample size increases, estimated coefficients converge to the true population parameter.



3\. \*\*Standard errors shrink with larger samples\*\*  

&#x20;  This leads to narrower confidence intervals and more precise inference.



4\. \*\*Statistical power increases with sample size\*\*  

&#x20;  Larger samples make it easier to detect the true effect.



\---



\## 5. Conclusion



This simulation demonstrates that in a fixed population setting:



\- Small samples produce noisy and unreliable estimates  

\- Large samples produce stable and accurate estimates  

\- Standard errors and confidence intervals decrease with sample size  



Overall, increasing sample size improves both the precision and reliability of regression estimates.



\# README – Part 2: Sampling Noise in an Infinite Superpopulation



\## 1. Data Generating Process (DGP)



In Part 2, I use a superpopulation framework rather than a fixed finite population. For each simulation, I generate a new dataset from the same data generating process.



The DGP is:



\- \\( X \\sim N(0,1) \\)

\- \\( u \\sim N(0,1) \\)

\- \\( Y = 2 + 1.5X + u \\)



Thus, the true coefficient on \\( X \\) is \*\*1.5\*\*.



The key difference from Part 1 is that I do not repeatedly sample from one fixed dataset. Instead, I generate a new random sample in every simulation. This corresponds to sampling from an infinite superpopulation.



\---



\## 2. Simulation Design



I wrote a Stata program that takes the sample size \\( N \\) as an argument, generates a new dataset of size \\( N \\), runs a regression of \\( Y \\) on \\( X \\), and returns:



\- sample size

\- estimated coefficient

\- standard error

\- p-value

\- lower confidence bound

\- upper confidence bound



I then used the `simulate` command to run the program 500 times for each sample size.



The sample sizes include:



\- the first twenty powers of 2, from 4 up to 2,097,152

\- the powers of 10 from 10 to 1,000,000



In total, this produces \*\*13,000 regression estimates\*\*.



\---



\## 3. Results



\### 3.1 Beta Estimates



!\[Beta Boxplot](p2\_beta\_box.png)



The beta boxplot shows that the coefficient estimates are highly variable at very small sample sizes, especially at \\( N = 4 \\), \\( N = 8 \\), and \\( N = 10 \\). At those sample sizes, the estimates are widely dispersed and can deviate substantially from the true value of 1.5.



As sample size increases, the estimates become much more concentrated around the true coefficient. The spread of the beta distribution shrinks steadily, and at very large sample sizes the estimates are almost identical across simulations.



This pattern shows that sampling noise becomes much smaller as \\( N \\) grows. In the superpopulation setting, the estimator converges clearly toward the true parameter.



\---



\### 3.2 Standard Errors



!\[SE Boxplot](p2\_se\_box.png)



The standard error boxplot shows a sharp decline in standard errors as sample size increases. At very small sample sizes, standard errors are large and highly dispersed. As \\( N \\) becomes larger, standard errors shrink rapidly and become nearly zero relative to the scale of the coefficient.



This is exactly what I would expect from statistical theory: the precision of the estimator improves with sample size, and the standard error falls approximately with the rate \\( 1/\\sqrt{N} \\).



\---



\### 3.3 Confidence Intervals



Because the standard errors shrink with sample size, the confidence intervals also become narrower as \\( N \\) increases. At small sample sizes, the intervals are wide and reflect substantial uncertainty about the coefficient estimate. At large sample sizes, the intervals become extremely tight, indicating much greater precision.



\---



\## 4. Interpretation



This simulation highlights several important statistical patterns.



First, when sample sizes are very small, the regression estimates are noisy. The coefficient estimates vary widely from one simulation to another, and the standard errors are large. This means that inference based on very small samples is unstable.



Second, as sample size increases, the coefficient estimates become more concentrated around the true coefficient of 1.5. This illustrates the consistency of the OLS estimator.



Third, standard errors and confidence intervals shrink steadily with larger samples. As a result, statistical inference becomes much more precise.



Overall, the superpopulation setting makes the asymptotic pattern especially clear: larger samples produce more stable estimates, smaller standard errors, and narrower confidence intervals.



\---



\## 5. Why I Can Use Larger Sample Sizes Than in Part 1



In Part 1, I worked with a fixed population of 10,000 observations. Because that population was finite, I could not draw a sample larger than 10,000.



In Part 2, I assume an infinite superpopulation. I am no longer restricted by a fixed dataset. Instead, I generate a new random sample directly from the DGP in every simulation. This allows me to consider much larger sample sizes, such as 100,000 and 1,000,000.



This is the main reason why Part 2 can explore much larger values of \\( N \\) than Part 1.



\---



\## 6. Why Standard Errors and Confidence Intervals Differ from Part 1



The results in Part 2 differ from those in Part 1 because the sampling framework is different.



In Part 1, I repeatedly sampled from one fixed finite population. That means the simulations were tied to one particular realized dataset. Even though the population was generated from a random process, once it was fixed, all subsequent sampling came from that same finite set of observations.



In Part 2, each simulation generates an entirely new sample from the underlying DGP. This makes the setup much closer to the theoretical model of repeated random sampling from a population distribution.



As a result:



\- the behavior of the estimator in Part 2 is smoother

\- the decline in standard errors is more systematic

\- the confidence intervals shrink more cleanly as sample size increases



In other words, Part 2 more closely reflects the theoretical large-sample properties of regression estimators.



\---



\## 7. Comparison with Part 1



Compared with Part 1, Part 2 shows the same broad pattern but in a cleaner and more theoretical way.



In both parts, larger sample sizes reduce the variability of beta estimates and shrink standard errors. However, Part 2 makes these relationships more transparent because each simulation is based on a fresh draw from the superpopulation rather than repeated sampling from one fixed dataset.



Part 1 is useful for showing sampling noise in a finite population. Part 2 is useful for showing how regression estimators behave under repeated sampling from the population-generating process itself.



Thus, Part 1 and Part 2 illustrate related but distinct ideas:



\- Part 1 focuses on sampling variation from a fixed finite population

\- Part 2 focuses on repeated sampling from an infinite superpopulation



\---



\## 8. Conclusion



In this part, I simulated regression estimates under an infinite superpopulation framework. I found that:



\- beta estimates are highly dispersed at very small sample sizes

\- beta estimates converge toward the true coefficient of 1.5 as sample size increases

\- standard errors decrease rapidly with sample size

\- confidence intervals become narrower as sample size grows



Compared with Part 1, Part 2 allows me to examine much larger sample sizes and shows the large-sample behavior of regression estimators more clearly. The results are consistent with the theoretical expectation that larger samples produce more precise and stable estimates.



\# README – Part 3: Power Calculations for Individual-Level Randomization



\## 1. Data Generating Process



I define the untreated outcome as a standard normal variable:



\- \\( Y\_0 \\sim N(0,1) \\)



I allow for heterogeneous treatment effects across individuals. The individual treatment effect is drawn from a uniform distribution:



\- \\( \\tau \\sim U(0,0.2) \\)



This implies an average treatment effect of 0.1 standard deviations. The treated outcome is defined as:



\- \\( Y\_1 = Y\_0 + \\tau \\)



\---



\## 2. Experimental Design



I consider an individually randomized controlled trial in which treatment is randomly assigned at the individual level.



In the baseline setting:



\- 50% of individuals are assigned to treatment

\- 50% are assigned to control

\- The goal is to detect an average treatment effect of 0.1 standard deviations

\- The significance level is 5%

\- The target power is 80%



\---



\## 3. Baseline Power Calculation



I use Stata’s `power twomeans` command to calculate the required sample size.



The results show that:



\- Total sample size required: \*\*3,142\*\*

\- Sample size per group: \*\*1,571\*\*



This means that to detect a treatment effect of 0.1 standard deviations with 80% power under equal assignment, I need approximately 3,142 individuals in total.



\---



\## 4. Adjustment for Attrition



I next assume that 15% of the sample attrits, with similar attrition rates in both treatment and control groups.



Attrition reduces the effective sample size used for analysis. To maintain 80% power, I must increase the initial sample size.



I adjust the required sample size as follows:



\- Required analysis sample size: 3,142

\- Adjusted recruitment size:  

&#x20; \\( 3142 / 0.85 \\approx 3696.47 \\)



After rounding up:



\- Required recruitment sample size: \*\*3,697\*\*



Thus, accounting for attrition increases the required number of individuals that must be recruited.



\---



\## 5. Unequal Treatment Assignment



I then consider a scenario where only 30% of individuals can receive treatment, and the remaining 70% are assigned to control.



Using a treatment-to-control ratio of 0.3/0.7, I recompute the required sample size.



The results show:



\- Total sample size required: \*\*4,424\*\*

\- Control group size: \*\*3,403\*\*

\- Treatment group size: \*\*1,021\*\*



Compared to the equal assignment case, the total required sample size increases substantially.



The reason is that statistical efficiency is maximized when treatment and control groups are balanced. When only 30% of individuals receive treatment, the variance of the estimator increases, which requires a larger sample size to achieve the same level of power.



\---



\## 6. Interpretation



The results highlight three important points.



First, detecting a relatively small effect size of 0.1 standard deviations requires a large sample even under ideal conditions.



Second, attrition increases the required sample size because some observations are lost before the final analysis. To compensate for this loss, the initial sample must be inflated.



Third, unequal treatment assignment reduces statistical efficiency. When the treatment group is much smaller than the control group, the variance of the estimated treatment effect increases, leading to a higher required total sample size.



\---



\## 7. Conclusion



In this part, I calculated the sample size required to detect a treatment effect of 0.1 standard deviations under different design conditions.



I found that:



\- Under equal assignment, 3,142 individuals are required

\- With 15% attrition, the required recruitment size increases to 3,697

\- When only 30% of individuals receive treatment, the required sample size increases further to 4,424



These results demonstrate that statistical power depends not only on the effect size, but also on practical features of the experimental design such as attrition and treatment allocation.



\# README – Part 4: Power Calculations for Cluster Randomization



\## 1. Data Generating Process



In this part, I study a cluster randomized trial in which treatment is assigned at the school level, and the outcome represents individual students' math scores.



I generate the data using a two-level structure:



\- a school-level component shared by all students within a school

\- an individual-level error term varying across students



Specifically:



\- the school-level variance is set to 0.3

\- the individual-level variance is set to 0.7



The untreated outcome is defined as the sum of these two components. This structure produces an intra-cluster correlation (ICC) of approximately \*\*0.322\*\*.



Treatment is assigned at the school level, with half of the schools treated and half as controls. Individual treatment effects are heterogeneous and drawn from a uniform distribution between 0.15 and 0.25, implying an average treatment effect of 0.2 standard deviations.



\---



\## 2. Experimental Design



I simulate a cluster randomized controlled trial where:



\- treatment is assigned at the school level

\- outcomes are measured at the student level

\- standard errors are clustered at the school level



I define a program that allows me to vary both:



\- the number of clusters (schools)

\- the cluster size (number of students per school)



For each configuration, I run 500 simulations and compute statistical power as the proportion of simulations in which the treatment effect is statistically significant at the 5% level.



\---



\## 3. ICC Verification



Using a one-way ANOVA (`loneway y0 school\_id`), I estimate the ICC to be:



\- \*\*ICC ≈ 0.322\*\*



This confirms that students within the same school are positively correlated. As a result, observations within a cluster are not independent, which reduces the effective sample size compared to individual-level randomization.



\---



\## 4. Effect of Increasing Cluster Size



I first fix the number of clusters at 200 and vary the cluster size using powers of 2.



!\[Power by Cluster Size](part4\_power\_by\_cluster\_size.png)



The results show that power increases as cluster size increases, but the gains diminish rapidly. Power rises quickly at small cluster sizes, then flattens out.



For example:



\- increasing cluster size from very small values produces substantial gains in power

\- beyond roughly \*\*64 to 128 students per school\*\*, additional increases yield only modest improvements



This occurs because students within the same school are correlated. Once a cluster reaches a moderate size, additional students provide limited new independent information.



Based on this pattern, I would recommend a cluster size in the range of \*\*64–128 students per school\*\*, as larger cluster sizes provide little additional benefit relative to their cost.



\---



\## 5. Number of Schools Required for 80% Power



Next, I fix the cluster size at 15 students per school and vary the number of schools.



From the simulation results, the smallest number of schools that achieves at least 80% power is:



\- \*\*280 schools\*\*



At this point, power reaches approximately 0.83.



This result shows that increasing the number of clusters is highly effective for improving power. In cluster randomized trials, schools are the units that provide independent variation.



\---



\## 6. Effect of Imperfect Adoption



I then consider a scenario in which only 70% of schools assigned to treatment actually adopt the intervention.



This reduces the effective treatment effect because not all treated schools implement the program. As a result, the observed difference between treatment and control groups becomes smaller.



Under this setting, the number of schools required to achieve 80% power increases to:



\- \*\*580 schools\*\*



This is more than double the requirement under full compliance, highlighting the large impact of imperfect adoption on statistical power.



\---



\## 7. Interpretation



This analysis illustrates several important features of cluster randomized trials.



First, the ICC plays a central role. Because students within the same school are correlated, the effective sample size is smaller than the total number of observations.



Second, increasing cluster size yields diminishing returns. After a certain point, adding more students within a school does little to improve power.



Third, the number of clusters is the primary determinant of power. Increasing the number of schools is much more effective than increasing the number of students per school.



Fourth, imperfect adoption substantially reduces power by weakening the effective treatment contrast. This requires a much larger number of clusters to compensate.



\---



\## 8. Conclusion



In this part, I analyze power in a cluster randomized trial with an ICC of approximately 0.322.



I find that:



\- increasing cluster size improves power, but with diminishing returns

\- a cluster size of around 64–128 is a reasonable balance between efficiency and cost

\- with 15 students per school, at least \*\*280 schools\*\* are required to achieve 80% power

\- when only 70% of schools adopt the treatment, the required number of schools increases to \*\*580\*\*



Overall, this analysis shows that in cluster randomized trials, statistical power depends primarily on the number of clusters rather than the number of individuals within each cluster, and is highly sensitive to both ICC and treatment compliance.

