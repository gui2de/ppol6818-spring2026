
# Question 1.6

We first defined the equation and what ultimately informed the data generation process as $$Y_i = 2X_i + \epsilon_i$$ for a fixed population of 10,000. Then we created a program that loads the population data to draw a random sample size and perform the regression. Using simulations, the sampling program was repeated 500 times for different sample sizes ranging from **10, 100, 1000, and 10,000.** 

The table below summarizes the mean and standard deviation of the estimates across the four sample sizes. 
### Simulation Results
The detailed **summary statistics** for the four sample sizes can be found here: 
[View Simulation Results Table (png)](./part1_table.png).
We observe that as sample size increases the beta starts converging more closely to the population value with lower standard errors. 

Similarly, as seen in the provided **histogram** here: [View Histogram](./beta_histogram.png), the distribution of $\hat{\beta}$ centers at 2.0 across all simulations, but the spread of the distribution collapses toward the true value as the sample size increases.

# Question 2.4 

The sample size in question 2 is being varied across 26 different levels ranging from n = 40 to n ~ 2, 000, 000 for the same equation as in question 1. 

### Simulation Results

The table below shows how across all 26 sample sizes, the Mean $\hat{\beta}$ remained centered at 2.0. This confirms that the OLS estimator is unbiased, meaning it provides the correct estimate on average, even when the sample size is critically small ($N=4$). Further, as $N$ increases, the SEM decreases at a decreasing rate. The table is here: [View Simulation Results Table (png)](./part2_table.png).  

The figure here: [View Histogram](./beta_histogram_2.png) illustrates the sampling distribution of $\hat{\beta}$ at four representative milestones ($N=4, 1024, 16384, 1000000$). The larger the sample size, the closer the bins are to the population average. 

# Question 2.5 

The table here: [View Table](./part2_4_table.png) depicts the comparison between a finite population and an infinite population. The comparison table demonstrates that the OLS estimator is unbiased across all specifications, as the mean Beta remains ~2.0. However, the precision of the estimate improves predictably. The standard errors are behaving similarly across the two sampling methods but Beta is closer to 2 for the infinite population. Further, in the previous part 2 table we have seen that the standard error gets closer to zero as sample size increases. This confirms that while small samples are accurate on average, large samples are required to achieve the high precision (low SEM) necessary for confident policy inference.

