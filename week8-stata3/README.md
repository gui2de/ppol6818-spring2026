<b>Part 1: Sampling Noise (Fixed Population)</b>

Methodology: Created a fixed universe of 10,000 "housing" observations with a true $\beta$ of 65. 
We then sampled subsets using bsample.

Key Findings: At $N=10$, the variation in beta was massive (low precision). As $N goes to $10,000$, the Standard Error (SEM) collapsed toward zero, and the estimate converged exactly to 65.

<b>Part 2: Sampling Noise (Superpopulation)</b>

Methodology: Instead of drawing from a saved file, we "generated the world" fresh for every iteration.

Comparison: Unlike Part 1, we could draw $N=1,000,000$ because we aren't limited by a pre-saved dataset.

SEM Differences: The SEM in Part 1 approaches zero as we reach the population size (10,000). In Part 2, the SEM continues to decrease as $N$ grows, following the Law of Large Numbers.

<b>PART 2(5)</b>

In Part 1, the Standard Error at $N=10,000$ represents the absolute limit of sampling. Because the population is fixed, we have perfect information. However, in Part 2, at $N=10,000$, the SEM is still just a 'snapshot' of an infinite process. 

Why Part 2 allows for larger $N$: Because Part 2 uses a stochastic program (DGP) rather than a static file, we are not limited by a "Census" size. We can simulate a million observations because we are testing the mathematical law rather than a specific group.

The Behavior of SEM: In Part 1, the Standard Error hits a "floor" dictated by the population size (10,000). In Part 2, the SEM continues to follow the $1/\sqrt{N}$ rule. At $N=1,000,000$, the SEM is 10x smaller than at $N=10,000$.

The $N=2$ Anomaly: In the Part 2 simulation for $N=2$, the CIs were blank. This occurs because a regression on two points yields a perfect fit (zero residuals), leaving zero degrees of freedom to calculate uncertainty.

### Comparison Table: Part 1 vs. Part 2 (Summary of Results)

| Sample Size ($N$) | Part 1: Mean $\beta$ | Part 2: Mean $\beta$ | Part 1: Mean SE | Part 2: Mean SE |
| :--- | :--- | :--- | :--- | :--- |
| **10** | 64.992 | 64.978 | 0.346 | 0.340 |
| **100** | 64.988 | 65.000 | 0.100 | 0.100 |
| **1,000** | 64.992 | 64.996 | 0.031 | 0.031 |
| **10,000** | 64.992 | 64.999 | **0.009** | **0.010** |
| **100,000** | *N/A* | 64.999 | *N/A* | 0.003 |
| **1,000,000** | *N/A* | **64.999** | *N/A* | **0.001** |

---

#### Key Observations:
* **"With Census":** In Part 1, at $N=10,000$, the Standard Error ($0.009$) is slightly lower than Part 2 ($0.010$) because we have sampled the entire fixed population. 
* **With Superpopulation:** Part 2 allows us to scale to $N=1,000,000$, reaching a level of precision ($SE = 0.001$) that is physically impossible in the finite world of Part 1.


### Table: Comparison of 95% Confidence Intervals (Part 1 vs. Part 2)

| Sample Size (N) | Part 1: Mean CI [Low, High] | Part 2: Mean CI [Low, High] | CI Width (Part 2) |
| :--- | :--- | :--- | :--- |
| **10** | [64.192, 65.791] | [64.192, 65.763] | 1.571 |
| **100** | [64.789, 65.187] | [64.800, 65.200] | 0.400 |
| **1,000** | [64.930, 65.054] | [64.934, 65.058] | 0.124 |
| **10,000** | [64.973, 65.012] | [64.979, 65.018] | 0.039 |
| **100,000** | *N/A (Exceeds Pop)* | [64.993, 65.006] | 0.013 |
| **1,000,000** | *N/A (Exceeds Pop)* | [64.997, 65.001] | 0.004 |

---


<b>Part 3: Power Calculations (Individual Level)</b>

<i>FINDINGS:</i>

Baseline: To detect a 0.1 SD effect with 80% power, the required sample size is 3,142.

Attrition (15%): Accounting for a 15% drop-out rate in both groups, the required recruitment size increases to 3,696 ($3142 / 0.85$).

Unbalanced Design (30/70): If only 30% of the sample receives treatment, the loss of efficiency requires a larger total $N$ of 3,742 to maintain 80% power.

<b>Part 4: Power Calculations (Cluster Level)</b>

Holding the number of schools at 200 with an ICC ($\rho$) of 0.3:

Recommendation: A cluster size of 32 students per school.

Reasoning: Due to the high correlation between students in the same school, increasing the number of students beyond 32 yields diminishing returns. It is much more effective to add more schools than more students per school.

<b>Optimal Number of Clusters</b> 

Requirement: To detect a 0.2 SD effect with 15 students per school and 80% power, we require 300 schools.Non-Adoption Tax: If only 70% of schools adopt the treatment (30% non-compliance), the "Intent-to-Treat" (ITT) effect is diluted. To maintain 80% power, the school requirement jumps significantly to 650 schools.

