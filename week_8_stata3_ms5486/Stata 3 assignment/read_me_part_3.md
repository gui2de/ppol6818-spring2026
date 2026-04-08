# PART 3 Power calculations for individual-level randomization

In this part, I conduct power calculations for an individually randomized experiment. The objective is to determine the sample size required to detect a treatment effect of a given magnitude with 80% statistical power, and to examine how attrition and unequal treatment allocation affect these requirements.
2. Data Generating Process
I assume an outcome variable Ythat is normally distributed with mean 0 and standard deviation 1:
Y∼N(0,1)
Treatment effects are heterogeneous across individuals. For treated individuals, the treatment effect is drawn from a uniform distribution between 0.0 and 0.2 standard deviations:
TE∼"Uniform"(0.0,0.2)
This implies an average treatment effect (ATE) of:
ATE=0.1
This effect size corresponds to a modest but policy-relevant improvement in outcomes.
3. Baseline Power Calculation (50/50 Assignment)
I first consider a standard randomized controlled trial with equal allocation to treatment and control (50% each). Using Stata’s power twomeans command, I calculate the minimum sample size required to detect an effect size of 0.1 standard deviations with:
	Significance level: 5% 
	Power: 80% 
The required total sample size is approximately 3,100–3,200 individuals, with equal numbers in treatment and control groups.
4. Impact of Attrition (15%)
Next, I account for 15% attrition, assuming that attrition occurs equally in both treatment and control groups.
To maintain the same level of statistical power, the initial sample must be inflated to compensate for expected losses. Specifically, the required sample size is adjusted by dividing by 1-0.15=0.85.
This increases the total required sample size to approximately 3,700 individuals.
This highlights that attrition reduces effective sample size and therefore requires larger initial recruitment to preserve statistical power.
5. Unequal Treatment Allocation (30% Treated)
Finally, I consider a scenario where only 30% of individuals can receive treatment, due to cost constraints. This results in an imbalanced design with:
	30% treatment 
	70% control 
Unequal allocation reduces statistical efficiency because fewer treated observations are available to estimate the treatment effect.
As a result, the total sample size required to achieve 80% power increases relative to the 50/50 case, reaching approximately 3,700–3,800 individuals.
6. Interpretation
These results illustrate several important principles in experimental design:
	Balanced assignment (50/50) is the most statistically efficient design for a given total sample size 
	Attrition reduces effective sample size, requiring larger initial samples to maintain power 
	Unequal treatment allocation increases required sample size, especially when the treatment group is smaller 
In all cases, the ability to detect a given effect size depends critically on both the total sample size and how observations are allocated across treatment and control groups.
7. Conclusion
Part 3 demonstrates how power calculations can inform experimental design decisions. Detecting a modest treatment effect of 0.1 standard deviations requires a relatively large sample, particularly when accounting for real-world constraints such as attrition and limited treatment capacity. These findings emphasize the importance of planning for sufficient sample size and considering design trade-offs before implementing a randomized controlled trial.
