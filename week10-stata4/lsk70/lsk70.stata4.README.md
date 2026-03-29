(Graphs included in lsk70 folder)

Regression Models

Six models were estimated:

T only
T + C
T + M
T + K
T + C + M
T + C + K

Each model was simulated 500 times across varying sample sizes (N = 100 to 5000).

Key Findings
1. Bias does not disappear with larger sample size

The bias plot shows that each model’s bias remains essentially constant as sample size increases. This demonstrates that increasing N improves precision but does not correct for incorrect model specification.

Models omitting the confounder (e.g., T only) exhibit substantial upward bias
Models including the collider (e.g., T + K, T + C + K) introduce new bias
Models including the mediator (T + M) estimate a different causal quantity and are therefore biased relative to the direct effect

Only the correctly specified model (T + C + M) produces estimates centered around the true parameter.

2. Variance decreases as sample size increases

The variance plot shows that the variance of the estimated treatment effect decreases rapidly as N increases for all models.

This confirms that:

Larger samples produce more precise estimates
However, precision does not imply accuracy

Even biased models become highly precise at large sample sizes.

3. Convergence to incorrect values under misspecification

The mean estimate plot shows that each model converges to a fixed value as sample size increases. However, these values differ across models and do not necessarily equal the true parameter.

This demonstrates that:

Estimators are converging (consistent)
But they may converge to the wrong value if the model is misspecified

Only the correctly specified model converges to the true effect of 0.3.

Conceptual Insights
Bias vs. Variance Tradeoff

This simulation clearly separates bias and variance:

Variance decreases with sample size
Bias is determined by model specification

Thus, increasing sample size cannot fix bias caused by omitted variables or improper controls.

Importance of Correct Controls

The results highlight the importance of including appropriate control variables:

Confounders must be included to avoid omitted variable bias
Colliders should not be controlled for, as they induce bias
Mediators must be handled carefully, depending on whether the goal is to estimate direct or total effects
Consistency Requires Correct Specification

A key takeaway is that consistency depends not only on sample size but also on correct model specification. Large samples ensure convergence, but not necessarily to the true parameter.

Conclusion

This simulation demonstrates that increasing sample size improves the precision of estimates but does not eliminate bias caused by incorrect model specification. Only models that correctly account for the causal structure of the data recover the true treatment effect. This highlights the importance of theory-driven model selection and careful consideration of the roles of confounders, mediators, and colliders in empirical analysis.