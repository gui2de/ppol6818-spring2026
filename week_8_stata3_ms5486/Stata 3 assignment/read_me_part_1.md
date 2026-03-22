# PART 1 Sampling noise in a fixed population
This exercise examines how sampling variability affects regression estimates when the underlying population relationship is fixed. The goal is to demonstrate how coefficient estimates, standard errors, and confidence intervals change as sample size increases.
2. Data Generating Process
I constructed a fixed population of 10,000 observations using a simple linear data-generating process. The explanatory variable xwas drawn from a normal distribution, and the outcome variable ywas generated as:
y=2+1.5x+u

where uis a normally distributed error term. The true coefficient on xis therefore 1.5.
To ensure reproducibility, I set a random seed before generating the data. This guarantees that the same population is used across all simulations.
3. Simulation Design
I wrote a Stata program that:
	Loads the fixed population dataset 
	Randomly samples Nobservations 
	Runs a regression of yon x
	Returns key statistics including: 
	Sample size (N) 
	Estimated coefficient (β) 
	Standard error (SEM) 
	p-value 
	Confidence interval bounds 
Using the simulate command, I repeated this process 500 times for each of the following sample sizes:
	N=10
	N=100
	N=1,000
	N=10,000
This resulted in a total of 2,000 regression estimates.
4. Results
Figure: Distribution of Beta Estimates
The boxplot shows the distribution of estimated coefficients across simulations for each sample size.
Key observations:
	At N = 10, the estimates vary widely and are highly dispersed 
	At N = 100, variability decreases but is still noticeable 
	At N = 1,000, estimates are tightly clustered around the true value 
	At N = 10,000, estimates converge almost exactly to the true coefficient (1.5) 
This demonstrates that sampling noise is highest in small samples and decreases as sample size increases.
Table: Summary Statistics
The summary table reports:
	Mean and median beta estimates 
	Standard deviation of beta estimates 
	Mean standard error 
	Mean confidence interval width 
Key patterns:
	The mean beta estimate remains close to 1.5 across all sample sizes, indicating unbiasedness 
	The standard deviation of beta estimates decreases as sample size increases 
	The standard error (SEM) declines with larger N, reflecting increased precision 
	The confidence intervals become narrower as N increases 
5. Interpretation
The results clearly illustrate the role of sampling variability in statistical estimation:
	Even when the true relationship is fixed, different random samples produce different estimates 
	Small samples introduce substantial variability, making estimates less reliable 
	Larger samples reduce this variability, producing more stable and precise estimates 
	When the full population is observed (N = 10,000), sampling noise effectively disappears 
This aligns with statistical theory: the precision of estimators improves with larger sample sizes due to reduced variance.
6. Conclusion
This exercise highlights a fundamental principle in statistics: sampling noise decreases as sample size increases. While regression estimates are unbiased on average, small samples can produce highly variable results. Increasing sample size improves both accuracy and precision, as reflected in smaller standard errors and tighter confidence intervals.
 





































































































# PART B Sampling noise in an infinite superpopulation.
1. Overview
In this part, I extend the analysis of sampling variability by moving from a fixed population (Part 1) to an infinite superpopulation framework. Instead of repeatedly sampling from a fixed dataset, each simulation generates a new dataset from the same underlying data-generating process (DGP). This setup reflects the standard assumption in statistical inference that data are drawn from a larger or conceptually infinite population.
2. Data Generating Process
I used the same DGP as in Part 1. For each simulation and sample size  N, the dataset is generated as:
𝑦 = 2 + 1.5 𝑥 +𝑢
where:
x∼N(0,1)
u∼N(0,2)
The true coefficient on 𝑥 is therefore 1.5.
Unlike Part 1, the dataset is re-generated in every simulation, meaning each run draws a fresh sample from the superpopulation.
3. Simulation Design
I defined a Stata program that:
Generates a dataset of size  N using the DGP above Runs a regression of y on x
Returns:
Sample size (N)
Estimated coefficient (β)
Standard error (SEM)
p-value
Confidence interval bounds
Using the simulate command, I repeated this process 500 times for each of the following sample sizes:
First 20 powers of 2:
4,8,16,…,2,097,152
Additional values:
10,100,1,000,10,000,100,000,1,000,000
This resulted in a total of 13,000 regression estimates.
4. Results
Figure: Precision vs Sample Size
The figure shows how the mean standard error (SEM) and confidence interval width change with sample size (on a log scale).
Key observations:
At very small sample sizes (e.g., 4, 8, 16), the estimates are highly variable As sample  ize increases, both SEM and confidence interval width decline steadily The rate of decline slows at very large sample sizes, reflecting diminishing marginal gains in precision
Table: Summary Statistics
The summary table reports:
Mean and median beta estimates
Standard deviation of beta estimates
Mean SEM
Mean confidence interval width
Key patterns:
The mean beta estimate remains close to the true value of 1.5, indicating unbiasedness. The variability of beta estimates decreases as sample size increases
Both SEM and confidence interval width shrink monotonically with larger N
5. Comparison with Part 1
The key difference between Part 1 and Part 2 lies in how the data are generated:
In Part 1, sampling is from a fixed population of 10,000 observations
In Part 2, each simulation generates a new dataset from an underlying superpopulation
This has important implications:
In Part 1, once 𝑁=10,000
N=10,000, the sample equals the full population, and sampling variability disappears
In Part 2, even very large samples still exhibit some randomness because each dataset is newly generated
However, the magnitude of this randomness becomes extremely small as N increases
6. Interpretation
This exercise illustrates how sampling variability behaves under the classical assumption of an infinite population:
Larger samples produce more precise estimates because they reduce the variance of the estimator
The decline in SEM and confidence interval width reflects increased statistical precision
Unlike the fixed population case, variability never fully disappears, but it becomes negligible at large sample sizes
7. Conclusion
Part 2 reinforces the fundamental principle that precision improves with sample size. While small samples produce highly variable estimates, larger samples yield stable and tightly concentrated estimates around the true parameter. The superpopulation framework provides a more realistic representation of empirical research settings, where data are assumed to be drawn from a broader underlying process rather than a fixed, finite population