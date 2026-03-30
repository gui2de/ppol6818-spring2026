# De-biasing a parameter estimate using controls

The simulation we ran using our data generating process (with known true parameters) of different regression models and sample sizes helps us conceptualize omitted variable bias and statistical efficiency. We also evaluate how introducing various control variables such as confounders, mediators, and independent covariates alters the estimated treatment effect. 

## Data Generating Process 

We know that the true direct effect of the treatment on the outcome (Y) is strictly 0.3. The true total effect is 0.7. 200 iterations of 5 models were run at each sample size. The models were: 

- Model 1: Biased by confounder 
- Model 2: Total Effect (Controls for Confounder, leaves Mediator alone. True = 0.7)
- Model 3: Direct Effect (Controls for Confounder & Mediator. True = 0.3)
- Model 4: Direct Effect + Extra Covariate (Same true = 0.3, but lower variance)
- Model 5: Collider Bias Trap (Conditions on a collider)

## Results and Interpretation 

The primary objective of adding controls is to retrieve an unbiased estimate of the treatment effect. From looking at the mean $\beta$ estimates [View Mean Beta Estimate Results Table (png)](./mean_conv.png). Model 1 suffers from severe asymptotic bias; because it fails to control for xcon, the treatment falsely takes credit for the confounder's impact. As sample size grows, Model 1 simply becomes more precisely wrong. Models 2, 3, and 4 converge to their respective true parameters because the proper controls have been introduced to isolate the causal pathways.

While controlling for confounders eliminates bias, controlling for independent covariates (like x2) improves the efficiency of the estimator. See results here: [View Variance Results Table (png)](./variance_shrinks.png). Both Model 3 and Model 4 provide unbiased estimates of the true Direct Effect (0.3). However, Model 4 consistently exhibits lower variance across most sample sizes.

### Figure 1 (The Mean Plot): Bias & Consistency 

The graph "Convergence of Treatment Effect Estimates" (The Mean Plot) [View Convergence of Treatment Effect Estimates (png)](./mean_convergence_plot.png). This graph plots the average estimated treatment effect (Y-axis) for five different regression models across increasing sample sizes (X-axis). The black dashed line is the true Direct Effect (0.3), and the gray dashed line is the true Total Effect (0.7). The red line line is completely flat and way too high (around 0.85). It shows Omitted Variable Bias. The blue line (model 2) converges to 0.7 by controlling for the confounder. The green lines converge to 0.3 by controlling for both the confounder and mediator. The purple line (0.5) converges to a wrong number. 

### Figure 2 "Variance of Direct Effect Estimates" (The Variance Plot)

The graph [View Variance of Direct Effect Estimates as N Grows](./variance_plot.png) plots the variance for models 3 and models 4. At N less than 1000, the variance is high. As N approaches 5,000, the variance comes close to zero, meaning the estimates become more stable and precise. 







