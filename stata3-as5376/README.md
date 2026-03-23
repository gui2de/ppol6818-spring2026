# Stata03_Assignment_ReadMeFile_as5376

# Part 1
With a true population parameter of 1.5, our sampling distributions across 1,000 repetitions reveal three key findings:

1. Consistency of the Point Estimate- Regardless of the sample size, the mean β remains remarkably stable, hovering between 1.51 and 1.54. This confirms that our OLS estimator is unbiased.

2. The Narrowing of Uncertainty- At N=10, the SD is 0.9300, leading to a wide confidence interval that spans from negative to positive. At N=1000, the SD collapses to 0.0807, and the confidence interval becomes much tighter around the truth.

3. The Finite Population Limit- Because our "Fixed Population" consists of exactly 10,000 individuals, sampling 10,000 people means we are conducting a census rather than a sample. Hence, the SD drops to 0.0.

Summary Table: Statistics

Sample Size   | Mean β	  | Std. Dev   | Mean     | SE| 95% CI (Lower) |	95% CI (Upper)
|-------------|-----------|------------|----------|---------------|
 10         |   1.5427   0.8837     -0.4953       3.5806               0.9300
  100       |   1.5138   0.2555      1.0068       2.0207               0.2597
  1000      |   1.5269   0.0803      1.3694       1.6844               0.0807
  10000     |   1.5254   0.0253      1.4757       1.5750               0.0000
  Total     |   1.5272   0.3112      0.8392       2.2152               0.4842


# Part 2


Unlike Part 1, where the variation vanished at N=10,000, the Superpopulation model maintains a non-zero SD and SE across all tiers. Even at the highest sample size, there is still "room for error" because we are only taking a slice of an infinite process. 

Summary Table: Superpopulation Statistics

Sample Size	Mean β	Std. Dev (β)	Mean Std. Error	95% CI (Lower)	95% CI (Upper)
|---|-----------|------------|----------|---------------|
10	1.5122	0.9241	0.8814	-0.4823	3.5067
100	1.4985	0.2581	0.2548	0.9929	2.0041
1,000	1.5011	0.0811	0.0805	1.3432	1.6589
10,000	1.4999	0.0255	0.0254

# Part 4
## q6
To detect a 0.2 SD effect with an ICC of 0.3 and 15 students per school, you require a total of 274 schools (137 treatment, 137 control), totaling 4,110 students.

## q7
If only 70% of assigned schools adopt the treatment, it requires us to increase sample to approx560 schools to maintain 80% power