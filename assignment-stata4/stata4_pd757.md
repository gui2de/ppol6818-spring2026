Part 2: De-biasing a parameter estimate using controls


I created a simple DGP with an outcome (Y), a binary treatment variable, a confounder, a mediator, and a collider. The true total treatment effect was set to 0.3. Each covariate was labeled in the do file.

I then estimated six regression models with different combinations of controls: treatment only, treatment plus confounder, treatment plus mediator, treatment plus collider, treatment plus confounder and mediator, and treatment plus confounder and collider. I ran these models at different sample sizes and stored the estimated treatment coefficients. 

I then produced a summary table of mean beta and variance by model and sample size, a figure of mean beta across sample sizes, and a figure of variance of beta across sample sizes.

The figures and table show that only the model controlling for the confounder recovers the true treatment effect of 0.3. The other models remain biased and converge to incorrect values as sample size increases. At the same time, the variance of the estimated coefficients declines with larger sample sizes for all models, indicating greater precision but not necessarily greater accuracy.