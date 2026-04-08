# Stata03_Assignment_ReadMeFile_SH1930

## Part 1

The table below shows results from 500 replications at each sample size.

| N | Mean Beta | SD of Beta | Mean SEM | Mean CI Width |
|---|-----------|------------|----------|---------------|
| 10 | 2.034 | 0.744 | 0.707 | 3.261 |
| 100 | 2.011 | 0.208 | 0.204 | 0.811 |
| 1,000 | 2.022 | 0.065 | 0.064 | 0.252 |
| 10,000 | 2.020 | 0.000 | 0.020 | 0.079 |

The mean beta stays close to 2 at all sample sizes, so I think the estimator is unbiased. The variation around that mean shrinks a lot as N increases. At N=10 the SD of beta is 0.74, meaning individual estimates regularly fall far from the truth, while at N=10,000 there's essentially no variation at all since we're drawing the entire population every time. 

## Part 2

500 replications were run at the first 20 powers of 2 and at N = 10, 100, 1,000, 10,000, 100,000, and 1,000,000. The reason we can draw larger samples here than in Part 1 is that Part 1 uses a fixed population of 10,000, you can't sample more than 10,000 observations from it. In Part 2 each replication generates a brand new dataset, so there's no ceiling on sample size.



