# Part 2: Sampling noise in an infinite superpopulation.

In this part, I extend the analysis of sampling variability by moving from a fixed population (Part 1) to an infinite superpopulation framework. Instead of repeatedly sampling from a fixed dataset, each simulation generates a new dataset from the same underlying data-generating process (DGP). This setup reflects the standard assumption in statistical inference that data are drawn from a larger or conceptually infinite population.
2. Data Generating Process
I used the same DGP as in Part 1. For each simulation and sample size N, the dataset is generated as:
y=2+1.5x+u

where:
	x∼N(0,1)
	u∼N(0,2)
The true coefficient on xis therefore 1.5.
Unlike Part 1, the dataset is re-generated in every simulation, meaning each run draws a fresh sample from the superpopulation.
3. Simulation Design
I defined a Stata program that:
	Generates a dataset of size Nusing the DGP above 
	Runs a regression of yon x
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
	At very small sample sizes (e.g., 4, 8, 16), the estimates are highly variable 
	As sample size increases, both SEM and confidence interval width decline steadily 
	The rate of decline slows at very large sample sizes, reflecting diminishing marginal gains in precision 
Table: Summary Statistics
The summary table reports:
	Mean and median beta estimates 
	Standard deviation of beta estimates 
	Mean SEM 
	Mean confidence interval width 
Key patterns:
	The mean beta estimate remains close to the true value of 1.5, indicating unbiasedness 
	The variability of beta estimates decreases as sample size increases 
	Both SEM and confidence interval width shrink monotonically with larger N
5. Comparison with Part 1
The key difference between Part 1 and Part 2 lies in how the data are generated:
	In Part 1, sampling is from a fixed population of 10,000 observations 
	In Part 2, each simulation generates a new dataset from an underlying superpopulation 
This has important implications:
	In Part 1, once N=10,000, the sample equals the full population, and sampling variability disappears 
	In Part 2, even very large samples still exhibit some randomness because each dataset is newly generated 
	However, the magnitude of this randomness becomes extremely small as Nincreases 
6. Interpretation
This exercise illustrates how sampling variability behaves under the classical assumption of an infinite population:
	Larger samples produce more precise estimates because they reduce the variance of the estimator 
	The decline in SEM and confidence interval width reflects increased statistical precision 
	Unlike the fixed population case, variability never fully disappears, but it becomes negligible at large sample sizes 
7. Conclusion
Part 2 reinforces the fundamental principle that precision improves with sample size. While small samples produce highly variable estimates, larger samples yield stable and tightly concentrated estimates around the true parameter. The superpopulation framework provides a more realistic representation of empirical research settings, where data are assumed to be drawn from a broader underlying process rather than a fixed, finite population.
 
