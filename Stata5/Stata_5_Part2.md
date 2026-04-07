 Results
1. Bias across model specifications
The figure below shows the average estimated treatment effect across different sample sizes.
The dashed line represents the true value (0.3).
Model 2 (confounder only) is closest to the true value across all sample sizes.
Model 1 (no controls) shows strong upward bias due to omitted variable bias.
Model 3 (with mediator) produces downward bias, as it blocks part of the treatment effect.
Model 4 (with collider) also deviates due to collider bias.
Model 5 (all controls) performs worst, combining multiple sources of bias.

2.  Convergence as sample size grows

The second figure shows the standard deviation of estimates.

As sample size increases, the variance of all estimators decreases.
This demonstrates consistency: estimates become more precise with larger samples.
However, biased models (Models 1, 3, 4, 5) do not converge to the true value, even as variance shrinks.

Increasing sample size reduces variance but does not eliminate bias.

 Conclusion

This simulation highlights three important insights:

Omitting confounders leads to biased estimates (OVB).
Controlling for mediators can bias estimates downward by blocking causal pathways.
Controlling for colliders introduces bias through spurious correlations.

Overall, the results demonstrate that correct model specification is crucial for causal inference, and that adding more variables does not necessarily improve estimates.