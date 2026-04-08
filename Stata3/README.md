Part 1
I generated a fixed population of 10,000 observations.
The covariate X is drawn from a standard normal distribution, and the outcome Y is generated according to the model:
Y = 1 + 2X + ε, where ε ~ N(0,1)
Then, I repeatedly drew random samples of size N = 10, 100, 1,000, and 10,000 from the fixed population. For each sample size, I ran 500 simulations and estimated an OLS regression of Y on X.
Table: Summary statistics by sample size
The results show that the estimated coefficients are centered around the true value of 2 across all sample sizes.
However, the variability of the estimates decreases substantially as the sample size increases. When N = 10, the standard deviation of the estimated beta is relatively large (around 0.40), indicating high sampling variability. As N increases to 100 and 1,000, the standard deviation shrinks considerably, and by N = 10,000, the estimates are extremely concentrated around the true value. 
Similarly, the average standard error and the width of the confidence intervals decrease as the sample size increases. This indicates that larger samples provide more precise estimates.
 
Figure 1 shows the distribution of estimated coefficients (β) across different sample sizes (N = 10, 100, 1,000, and 10,000). The dashed vertical line represents the true coefficient, which is 2.
The figure clearly illustrates that as the sample size increases, the distribution of the estimated coefficients becomes more concentrated around the true value. When N = 10, the distribution is relatively wide and dispersed, indicating a high degree of sampling variability. The estimates vary substantially across simulations, and the density curve is flat and spread out. As the sample size increases to 100 and 1,000, the distribution becomes progressively narrower, showing reduced variability in the estimated coefficients. When N = 10,000, the distribution is extremely tightly centered around the true value, indicating that the estimates are highly stable and precise.
Overall, this figure demonstrates that larger sample sizes reduce sampling noise and lead to more accurate and reliable estimates of the true parameter.
 
Figure 2 shows that both the standard error and the confidence interval width decrease as the sample size increases. The decline is steep when moving from small to medium sample sizes and becomes more gradual at larger sample sizes. This indicates that larger samples produce more precise estimates with less uncertainty.

 
Figure 3 summarizes the distribution of beta estimates using boxplots, highlighting the median, spread, and presence of outliers across different sample sizes. As the sample size increases, the interquartile range shrinks and the estimates become more tightly clustered around the true value (2). In small samples (N = 10), the estimates show substantial variability and several extreme outliers, whereas in large samples (N = 10,000), the distribution is highly concentrated with almost no dispersion.
Compared to Figure 1, this figure emphasizes the reduction in variability and the disappearance of outliers, providing a clearer view of how estimate stability improves with larger sample sizes.

Part 2
In this part, I simulate data from an infinite superpopulation.
For each simulation, I generate new data following the same DGP as in Part 1:
    X∼N(0,1)
    ϵ∼N(0,1)
    Y=1+2X+ϵ
The true coefficient is 2.
Unlike Part 1, the data are newly generated in each simulation, rather than sampled from a fixed dataset.
For each sample size N, I generate a new dataset, run a regression of Yon X, and repeat this process 500 times. I consider a wide range of sample sizes, including both powers of two and standard values such as 10, 100, and 1,000. This produces a total of 13,000 regression results, which are used to study how estimates behave as sample size increases. 
 
The table shows that the estimated coefficients are very close to the true value of 2 across all sample sizes, and the bias is negligible. As the sample size increases, the variation in the estimates becomes smaller, and both the standard error and the confidence interval width decrease. This indicates that larger samples lead to more stable and more precise estimates. This shows that estimates become more stable and precise with larger samples.



 
Figure 1 shows the distribution of beta estimates for selected sample sizes. When the sample size is small, the estimates are widely spread. As the sample size increases, the distribution becomes more concentrated around the true value. For very large samples, the estimates are tightly clustered near 2, showing very little variation.
 
Figure 2 shows how the standard error and the confidence interval width change with the sample size. Both decrease as Nincreases. The reduction is faster at smaller sample sizes and becomes more gradual as the sample size grows. This shows that precision improves with larger samples.

 
Although Part 1 and Part 2 use different data generating processes, the results are very similar. This is because both approaches are based on the same underlying DGP, so the statistical properties of the estimates are consistent. The comparison figure shows that the two lines almost overlap, indicating that both approaches lead to consistent results. 
