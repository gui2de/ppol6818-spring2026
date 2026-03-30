Data Generating Process (DGP)
The simulation uses normally distributed variables to map the following causal structure:
	Confounder (C): A variable that positively causes both $T$ and $Y$. Failing to control for $C$ results in omitted variable bias.
	Treatment (T): Influenced by C.
	Mediator (M): Influenced directly by T, and in turn, influences Y. The total effect of T on Y operates entirely through M (0.6 * 0.5 = 0.3).
	Outcome (Y): Influenced by M and C
	Collider (Z): Influenced by both T and Y
Regression Models 
We ran 200 iterations for each of five sample sizes (N = 50, 100, 500, 1000, 5000) using the following specifications:
	Naive Model (reg Y T): Does not control for the confounder C
	Correct Model (reg Y T C): Controls for the confounder C but correctly leaves out M and Z
	Mediator Bias (reg Y T C M): Controls for the confounder and the mediator.
	Collider Bias (reg Y T C Z): Controls for the confounder and the collider.
	Kitchen Sink (reg Y T C M Z): Controls for all available covariates.
Results and analysis
The mean_plot figure visualizes the estimated coefficients as N grows.
	Correct Model: Consistently converges precisely on the true parameter line (0.3). By controlling only for C, it correctly isolates the total causal effect of T.
	Naive Model: Consistently overestimates the effect (mean beta approx 0.62$). The positive correlation between C, T, and Y creates a massive upward omitted variable bias.
	Mediator Bias Model: Converges to 0.0. Because the entire effect of T travels through M in our DGP, controlling for M "blocks" the causal path, leading us to erroneously conclude that the treatment has no effect.
	Collider Bias Model: Shows a downward bias. By controlling for Z (which is a descendant of both T and Y), we open a non-causal "backdoor" path that artificially alters the correlation between treatment and outcome.
The var_plot figure demonstrates the Law of Large Numbers.
	For all models, the variance of the beta estimate shrinks exponentially as N increases.
	At N = 50, the estimates are highly dispersed. By N = 5000, the variance approaches zero, meaning the models perfectly predict their respective (biased or unbiased) estimands.
	Key takeaway: Having a massive sample size (low variance) does not eliminate structural causal bias (an inaccurate mean). The Naive model has low variance at N = 5000, but it is precisely wrong. Only structural causal logic (the Correct model) yields the true parameter.