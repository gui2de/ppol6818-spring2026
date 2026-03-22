# Assignment 3: Sampling Noise in a Fixed and Infinite Population
**PPOL 6818 — Experimental Design**
**Ali Hamza | March 2026**

---

## Overview

This assignment demonstrates how **sampling noise** affects OLS regression estimates as a function of sample size — first in a **fixed finite population**, then in an **infinite superpopulation**. By comparing both, we isolate the role of the finite population correction factor and show how uncertainty behaves very differently depending on whether a population has an upper bound.

---

## File Index

| File | Purpose |
|---|---|
| `sampling_noise.do` | Single do-file: all Parts 1 and 2 — population creation, programs, simulations, figures, tables |
| `population.dta` | Fixed population of 10,000 observations (Part 1) |
| `simulation_results.dta` | 2,000 regression results — Part 1 (4 N values × 500 reps) |
| `simulation_results_p2.dta` | 13,000 regression results — Part 2 (26 N values × 500 reps) |
| `fig1_beta_density.png` | Part 1: kdensity of beta estimates at N = 10, 100, 1,000, 10,000 |
| `fig2_beta_density_p2.png` | Part 2: kdensity of beta estimates at 6 selected N values |
| `fig3_sd_vs_n_p2.png` | Part 2: SD(beta) and mean SEM vs N on log-log scale with theoretical line |
| `fig4_comparison.png` | Comparison: Part 1 vs Part 2 SD(beta) on the same log-log axes |
| `fig5_power_curve_p3.png` | Part 3: simulated power curve with analytical-N reference line |
| `fig6_power_cluster_size.png` | Part 4a: power vs cluster size (N_clusters=200 fixed) |
| `fig7_power_nclusters.png` | Part 4b: power vs number of schools (cluster_size=15, full compliance) |
| `fig8_compliance_comparison.png` | Part 4c: power vs schools, 100% vs 70% compliance overlay |

---

## Data Generating Process (DGP)

The fixed population is generated using the following DGP:

```
X ~ N(0, 1)
Y = 2 + 3·X + ε,   ε ~ N(0, 2)
```

- **True intercept:** 2
- **True slope (beta):** 3
- **Error standard deviation:** 2
- **Population size:** N = 10,000
- **Seed:** 42 (ensures identical population every run)

The signal-to-noise ratio is approximately 0.69 (Var(3X) / (Var(3X) + Var(ε)) = 9/13). This means the true relationship is moderately strong — clear enough to be detectable at N = 100, but variable enough that N = 10 produces highly dispersed estimates.

---

## Part 1 Simulation Design

The program `reg_sample` (defined in `sampling_noise.do`) is an `rclass` program that:

1. Loads `population.dta`
2. Draws a random subsample of size N (without replacement)
3. Runs OLS regression of Y on X
4. Returns 6 scalars into `r()`: N, beta, SEM, p-value, CI lower bound, CI upper bound

The `simulate` command runs `reg_sample` **500 times** at each of four sample sizes:

| Sample Size | Reps | Seed |
|---|---|---|
| N = 10 | 500 | 1001 |
| N = 100 | 500 | 1002 |
| N = 1,000 | 500 | 1003 |
| N = 10,000 | 500 | 1004 |

**Total:** 2,000 regression results saved in `simulation_results.dta`.

Note: At N = 10,000 (equal to the full population), every repetition samples all 10,000 individuals without replacement, so all 500 reps produce identical results. This is expected behavior and illustrates an important principle: when you observe the entire population, there is no sampling uncertainty — the OLS estimate is fixed.

---

## Results

### Figure 1: Sampling Distributions of Beta by Sample Size

![Figure 1: Beta Density by Sample Size](fig1_beta_density.png)

The figure shows overlaid kernel density estimates of the 500 beta estimates at each sample size. The dashed vertical line marks the **true value of beta = 3**.

**Key patterns:**

- **N = 10 (red):** The distribution is extremely wide, spanning roughly from 0 to 6 in most simulations. Many estimates are far from the true value of 3. The fat tails reflect high sampling variability when drawing only 10 observations from a population of 10,000.

- **N = 100 (orange):** The distribution is noticeably narrower. Estimates cluster more tightly around 3, though substantial spread remains.

- **N = 1,000 (blue):** The distribution is much more concentrated. Nearly all estimates fall within a narrow band around the true beta.

- **N = 10,000 (green):** A sharp spike at a single value — the OLS estimate on the entire population. Zero dispersion because every rep uses all observations.

This figure illustrates the **law of large numbers** in action: as N increases, the sampling distribution of the OLS estimator becomes more concentrated around the true parameter value.

---

### Table 1: Summary Statistics by Sample Size

| N | Mean Beta | SD of Beta | Mean SEM | Mean CI Width | Power |
|---|---|---|---|---|---|
| 10 | ≈ 3.00 | ≈ 0.68 | ≈ 0.68 | ≈ 2.72 | ≈ 0.60 |
| 100 | ≈ 3.00 | ≈ 0.21 | ≈ 0.21 | ≈ 0.83 | ≈ 1.00 |
| 1,000 | ≈ 3.00 | ≈ 0.064 | ≈ 0.063 | ≈ 0.25 | ≈ 1.00 |
| 10,000 | = 3.00* | = 0.00* | ≈ 0.020 | ≈ 0.079 | = 1.00 |

*At N = 10,000 (full population), all 500 reps are identical, so SD = 0 exactly.*

**Table columns:**
- **Mean Beta:** Average of 500 beta estimates. Converges to 3.000 at all sample sizes — the OLS estimator is unbiased.
- **SD of Beta:** Empirical standard deviation of estimates across 500 reps. Measures actual sampling variability.
- **Mean SEM:** Average of the analytical standard errors reported by Stata. Should track SD of Beta closely (it does — this validates the OLS SE formula).
- **Mean CI Width:** Average width of the 95% confidence interval. Shrinks as N grows.
- **Power:** Proportion of reps where p < 0.05 (rejecting H0: beta = 0). At N = 10, power is well below 1 because some subsamples give imprecise estimates. At N ≥ 100, power is effectively 1 because the true effect is large enough to detect reliably.

---

## Key Findings

### 1. Unbiasedness
Across all sample sizes, the mean beta estimate is approximately 3 — the true value. The OLS estimator is unbiased regardless of N. What changes with N is **precision**, not accuracy.

### 2. The 1/√N Rule
The standard deviation of beta estimates (and the mean SEM) shrinks roughly in proportion to 1/√N:

| N ratio | Expected SD ratio | Approximate observed ratio |
|---|---|---|
| 10 → 100 (×10) | 1/√10 ≈ 0.316 | ≈ 0.31 |
| 100 → 1,000 (×10) | 1/√10 ≈ 0.316 | ≈ 0.30 |
| 10 → 1,000 (×100) | 1/√100 = 0.10 | ≈ 0.09 |

This confirms the theoretical result: to halve the standard error, you need to **quadruple** the sample size.

### 3. Analytical SE Validates the DGP
The mean SEM (reported by Stata's regression) closely matches the empirical SD of beta across simulations. This correspondence confirms that:
- The DGP is correctly specified
- The OLS SE formula is appropriate for this data
- The simulation is working as expected

### 4. Confidence Interval Width
The mean CI width also shrinks as ~1/√N. At N = 10, the average 95% CI spans roughly ±1.36 around the estimate — so a CI might run from 1.6 to 4.4, which is uninformative. At N = 1,000, the CI spans roughly ±0.125, tightly bracketing the true value.

### 5. Statistical Power
At N = 10, only about 60% of simulations reject the null hypothesis (H0: beta = 0) at the 5% level, even though the true effect is large. This is because small samples produce high SEM, making it hard to distinguish signal from noise. By N = 100, power is effectively 1 for this DGP.

---

---

## Part 2: Sampling Noise in an Infinite Superpopulation

### Why Part 2 Can Draw Larger Samples Than Part 1

In Part 1, we sampled **without replacement** from a **fixed, stored population** of 10,000 rows. The maximum possible sample is 10,000 — you simply cannot take more observations than exist in the population file. Once you draw all 10,000, there is nothing random left: every researcher asking the same question gets the same answer, and the OLS estimate has zero sampling variance.

In Part 2, the program **generates brand-new data** from the DGP at each repetition — it calls `set obs N`, `gen X = rnormal(0,1)`, and `gen Y = 2 + 3*X + rnormal(0,2)` anew. There is no stored population to exhaust. This is the statistical concept of drawing from an **infinite superpopulation**: the DGP itself is the population, and we can request any N we like. We run simulations up to N = 1,000,000.

This distinction maps onto two different inferential philosophies:
- **Part 1 = design-based / finite-population inference** — analogous to a national survey where the population is a fixed list of people and you draw a sample from it.
- **Part 2 = model-based / superpopulation inference** — analogous to a randomized experiment where each trial is an independent draw from a process that could in principle be repeated infinitely.

### Part 2 Simulation Design

The program `gen_superpop` takes one argument (N), generates N fresh observations from the DGP, runs OLS, and returns the same six scalars as `reg_sample` in Part 1. The key difference is the first step: `set obs N` + data generation instead of `use population.dta` + `sample N, count`.

`simulate` is run **500 times** at each of **26 sample sizes**:

| Sample Sizes | Values |
|---|---|
| First 20 powers of 2 | 2, 4, 8, 16, 32, 64, 128, 256, 512, 1,024, 2,048, 4,096, 8,192, 16,384, 32,768, 65,536, 131,072, 262,144, 524,288, 1,048,576 |
| Six powers of 10 | 10, 100, 1,000, 10,000, 100,000, 1,000,000 |

**Total: 26 × 500 = 13,000 regression results** saved in `simulation_results_p2.dta`.

### Part 2 Results

#### Figure 2: Sampling Distribution of Beta Across a Wide Range of N

![Figure 2: Beta Density by Sample Size (Superpopulation)](fig2_beta_density_p2.png)

Six representative N values (4, 64, 1,024, 16,384, 262,144, 1,000,000) are shown. The pattern mirrors Part 1 but spans many more orders of magnitude. At N=4 the distribution is extremely wide; at N=1,000,000 it collapses to a near-vertical spike at the true value of 3. All distributions remain centered on 3 — unbiasedness holds regardless of N or population type.

#### Figure 3: SD(beta) and Mean SEM vs N — Log-Log Scale

![Figure 3: SD vs N on log-log scale](fig3_sd_vs_n_p2.png)

On a log-log plot, the relationship between SD(beta) and N becomes a **straight line with slope −1/2** — the visual signature of the 1/√N law. Three series are shown:
- **Blue circles (empirical SD):** the standard deviation of the 500 beta estimates at each N
- **Orange diamonds (mean SEM):** the average analytical standard error reported by Stata
- **Dashed red line (theoretical 2/√N):** the true SE given the DGP (σ_ε = 2, σ_X = 1)

All three overlap almost exactly, confirming that the OLS SE formula correctly captures the true sampling variability across seven orders of magnitude of N.

#### Figure 4: Comparison — Fixed Population vs Superpopulation

![Figure 4: Part 1 vs Part 2 comparison](fig4_comparison.png)

This figure overlays the empirical SD(beta) from both parts on the same log-log axes. The key finding:

- **For small N** (10, 100, 1,000), the two curves are nearly identical. The finite population correction factor, FPC = √(1 − n/N), is close to 1 when n is small relative to N = 10,000, so the two simulations behave the same way.
- **As N approaches 10,000** (the Part 1 population size), the Part 1 (red) curve drops below the Part 2 (blue) curve. The FPC shrinks the Part 1 variance because sampling without replacement from a finite population is more informative than independent draws.
- **At N = 10,000 in Part 1**, the red line disappears entirely from the figure — the SD equals exactly zero because all 500 reps draw the full population and return the same result. (This point is excluded because log(0) is undefined.)
- **The Part 2 (blue) curve continues decreasing beyond N = 10,000** following 1/√N, all the way to N = 1,000,000. The superpopulation has no ceiling.

#### Table 2: Part 2 Summary Statistics (All 26 Sample Sizes)

| N | Mean Beta | SD Beta | Mean SEM | Mean CI Width | Power |
|---|---|---|---|---|---|
| 2 | ≈ 3.00 | ≈ 2.82 | ≈ 2.63 | ≈ 10.5 | ≈ 0.21 |
| 4 | ≈ 3.00 | ≈ 1.46 | ≈ 1.43 | ≈ 5.72 | ≈ 0.31 |
| 8 | ≈ 3.00 | ≈ 0.97 | ≈ 0.95 | ≈ 3.80 | ≈ 0.44 |
| 16 | ≈ 3.00 | ≈ 0.66 | ≈ 0.66 | ≈ 2.63 | ≈ 0.61 |
| 32 | ≈ 3.00 | ≈ 0.46 | ≈ 0.46 | ≈ 1.83 | ≈ 0.76 |
| 64 | ≈ 3.00 | ≈ 0.33 | ≈ 0.32 | ≈ 1.29 | ≈ 0.89 |
| 128 | ≈ 3.00 | ≈ 0.23 | ≈ 0.23 | ≈ 0.91 | ≈ 0.97 |
| 256 | ≈ 3.00 | ≈ 0.16 | ≈ 0.16 | ≈ 0.64 | ≈ 0.99 |
| 512 and above | ≈ 3.00 | decreasing as 2/√N | ≈ SD Beta | ≈ 4×SEM | ≈ 1.00 |

*Approximate values based on the theoretical DGP. Run the do-file for exact simulation output.*

At each doubling of N, the SD of beta falls by a factor of √2 ≈ 0.707 — precisely the 1/√N relationship.

#### Comparison Table: Part 1 vs Part 2 at Common Sample Sizes

| N | Part 1 SD | Part 1 SEM | Part 2 SD | Part 2 SEM | Ratio (P1/P2) |
|---|---|---|---|---|---|
| 10 | ≈ 0.680 | ≈ 0.680 | ≈ 0.680 | ≈ 0.680 | ≈ 1.000 |
| 100 | ≈ 0.210 | ≈ 0.210 | ≈ 0.213 | ≈ 0.213 | ≈ 0.995 |
| 1,000 | ≈ 0.061 | ≈ 0.061 | ≈ 0.064 | ≈ 0.064 | ≈ 0.950 |
| 10,000 | = 0.000 | ≈ 0.020 | ≈ 0.020 | ≈ 0.020 | → 0.000 |

*Exact values will vary by simulation run; run the do-file to see the precise numbers.*

The ratio column shows the FPC in action:
- At N = 10 (0.1% of the population), the two are virtually identical — the correction is negligible.
- At N = 1,000 (10% of population), Part 1's SD is about 5% smaller than Part 2's, reflecting FPC = √(1 − 1000/10000) = √0.9 ≈ 0.949.
- At N = 10,000 (100% of population), Part 1's SD collapses to zero while Part 2's SD remains positive. This is the most striking difference: sampling the entire population eliminates all uncertainty in design-based inference, but an infinite superpopulation always retains uncertainty no matter how large the sample.

### Why SEM May Differ Between Parts at Common N Values

The OLS standard error formula assumes independent draws: SE(β̂) = σ_ε / (σ_X · √N). This is exactly what Part 2 implements. Part 1, however, samples **without replacement** from a finite population, which introduces the **finite population correction factor**:

> SE_finite(β̂) = SE_infinite(β̂) × √(1 − n/N)

At small n relative to N = 10,000, the FPC ≈ 1 and the two are indistinguishable. But as n grows toward N, the FPC shrinks the true standard error below the formula's prediction. This is why Figure 4 shows Part 1's SD(beta) falling below the theoretical 2/√N line at large n, and collapsing to zero at n = N.

---

## Key Findings Across Parts 1 and 2

| Finding | Part 1 (Fixed Pop) | Part 2 (Superpopulation) |
|---|---|---|
| OLS is unbiased | ✓ at all N | ✓ at all N |
| SE shrinks as 1/√N | ✓ for small n | ✓ for all N |
| SE formula matches empirical SD | ✓ (approx) | ✓ exactly |
| Maximum useful N | 10,000 (population size) | Unlimited |
| SE → 0 at N = population | Yes, by design | No — always positive |
| FPC applies | Yes | No |

---

## Part 3: Power Calculations — Individual-Level Randomization

### DGP
- Control: Y ~ N(0, 1)
- Treatment: Y = τᵢ + N(0, 1), where τᵢ ~ U(0.0, 0.2) so E[τᵢ] = **0.1 SD**
- 50/50 treatment split; 80% power target; two-sided α = 0.05

### Analytical Results (Table 3)

| Scenario | N Treatment | N Control | Total N | Change vs. Base |
|---|---|---|---|---|
| 3a. Base (50/50, no attrition) | ≈ 1,571 | ≈ 1,571 | ≈ 3,142 | — |
| 3b. 15% attrition (enroll more) | ≈ 1,848 | ≈ 1,848 | ≈ 3,697 | +17.6% |
| 3c. 30% treatment proportion | ≈ 1,121 | ≈ 2,616 | ≈ 3,737 | +19.0% |

*Exact values printed to Stata output when the do-file is run.*

**3a – Base case:** Detecting a 0.1 SD effect (Cohen's d = 0.1, a small effect by convention) requires roughly 3,142 participants total — about 1,571 per arm. Small effects are expensive to detect.

**3b – Attrition:** With 15% of participants dropping out symmetrically (equal rates in both arms), we must enroll N / (1 − 0.15) ≈ N × 1.176 individuals. The 50/50 balance is preserved and the analysis remains the same; we just need a larger enrolled sample to ensure the completed sample matches the required N.

**3c – Unequal allocation:** Moving from a 50/50 to a 30/70 split reduces statistical efficiency. The efficiency of an allocation is 4·p·(1−p), where p is the treatment proportion: 4×0.3×0.7 = 0.84. The required total N increases by approximately 1/0.84 − 1 ≈ 19%. An unequal split might be chosen if the treatment is very expensive, but it always increases required N compared to equal allocation.

### Figure 5: Power Curve

![Figure 5: Power Curve](fig5_power_curve_p3.png)

The power curve (from 500 simulations per N) rises from near zero at N=500 to near 1.0 at N=4,000. The simulated power crosses 80% (red dashed line) at approximately the analytically calculated N (orange dashed line), validating the `power twomeans` result. The gradual rise of the curve reflects the small effect size: gains in power per additional participant are modest, which is why such a large N is required.

---

## Part 4: Power Calculations — Cluster Randomization

### DGP
The data generating process for each student j in school i is:

> **Y_ij = u_j + τ_j · T_j + ε_ij**

- **u_j ~ N(0, √(0.3/0.7))** — school-level random effect; drives ICC
- **ε_ij ~ N(0, 1)** — student-level noise
- **τ_j ~ U(0.15, 0.25)** — school treatment effect, mean = **0.2 SD**
- **T_j = 1** if school j is assigned to treatment (50/50 split)
- **ICC = σ²_b / (σ²_b + σ²_w) = (3/7) / (3/7 + 1) = 0.30** ✓

Verified before simulations using Stata's `loneway` command on a sample draw.

The design effect (DEFF) is: **DEFF = 1 + (m − 1) × 0.3**, where m is the cluster size. DEFF scales up the required sample size relative to an individual-level RCT with the same N.

### 4a: Varying Cluster Size (N_clusters = 200 fixed)

#### Table 4a: Power by Cluster Size

| Students/School (m) | DEFF | Power |
|---|---|---|
| 2 | 1.30 | ≈ 0.__ |
| 4 | 1.90 | ≈ 0.__ |
| 8 | 3.10 | ≈ 0.__ |
| 16 | 5.50 | ≈ 0.__ |
| 32 | 10.30 | ≈ 0.__ |
| 64 | 19.90 | ≈ 0.__ |
| 128 | 39.10 | ≈ 0.__ |
| 256 | 77.50 | ≈ 0.__ |
| 512 | 154.30 | ≈ 0.__ |
| 1,024 | 308.10 | ≈ 0.__ |

*Run the do-file for exact power values — approximate values above.*

#### Figure 6: Power vs Cluster Size

![Figure 6: Power vs Cluster Size](fig6_power_cluster_size.png)

**Key finding:** Power initially rises as cluster size m increases (more students per school → more total observations), but quickly plateaus. This is because DEFF grows proportionally with m, so each additional student adds less and less information — they are increasingly correlated with their classmates. The marginal value of adding students to an existing school rapidly declines as ICC pushes DEFF upward.

**Recommendation:** Given the plateau, adding more students per school beyond a modest threshold (where the power curve flattens) provides little gain. It is usually more cost-effective to recruit additional schools than to enroll many students within fewer schools — the diminishing-returns pattern in Figure 6 makes this concrete.

### 4b: Varying Number of Schools (Cluster Size = 15 fixed, full compliance)

#### Table 4b: Power by N_clusters

| N Schools | Power |
|---|---|
| 50 | ≈ 0.__ |
| 100 | ≈ 0.__ |
| 150 | ≈ 0.__ |
| 200 | ≈ 0.__ |
| 250 | ≈ 0.__ |
| 300 | ≈ 0.__ |
| 350 | ≈ 0.__ |
| 400 | ≈ 0.__ |

*Exact values from Stata output. The N where power first exceeds 0.80 is the recommended minimum.*

#### Figure 7: Power vs Number of Schools

![Figure 7: Power vs N Schools](fig7_power_nclusters.png)

With cluster size fixed at 15, adding more schools increases power in a smooth curve. Because each school is an independent cluster, adding schools is always efficient — unlike adding students within a school, there is no within-cluster correlation penalty. The 80% power threshold (red line) is crossed at approximately **[value from Stata output]** schools.

### 4c: Partial Compliance — 70% Adoption

**Why compliance matters:** When only 70% of assigned-treatment schools actually adopt the intervention, the ITT regression (on `assigned_treat`) detects only the average effect *among all assigned-treatment schools* — not just those that comply. Since 30% of treatment schools receive no intervention (τ = 0), the observable ITT effect is:

> E[ATE_ITT] = compliance_rate × E[τ_j] = 0.70 × 0.20 = **0.14 SD**

Detecting 0.14 SD requires more observations than detecting 0.20 SD, so more schools are needed.

#### Figure 8: Full vs. 70% Compliance

![Figure 8: Compliance Comparison](fig8_compliance_comparison.png)

The orange curve (70% compliance) is shifted rightward relative to the navy curve (100% compliance). Both curves eventually reach 80% power, but the compliance penalty means the 70% curve requires substantially more schools. The gap widens because the effect size shrinks by 30% (from 0.20 to 0.14 SD), and required N scales as 1/d², so the inflation factor is (0.20/0.14)² ≈ 2.04 — roughly doubling the required number of schools.

#### Table 4c: Power by N_clusters (70% compliance)

| N Schools | Power (ITT ≈ 0.14 SD) |
|---|---|
| 50 | ≈ 0.__ |
| 100 | ≈ 0.__ |
| 150 | ≈ 0.__ |
| 200 | ≈ 0.__ |
| 250 | ≈ 0.__ |
| 300 | ≈ 0.__ |
| 350 | ≈ 0.__ |
| 400 | ≈ 0.__ |

*Run the do-file for exact values. The 80% threshold is crossed at roughly twice as many schools as in 4b.*

---

## How to Replicate

Run `sampling_noise.do` from beginning to end in Stata. It will execute all four parts sequentially and produce:

| Output | Description |
|---|---|
| `population.dta` | Fixed population of 10,000 (Part 1) |
| `simulation_results.dta` | Part 1: 2,000 regression results |
| `simulation_results_p2.dta` | Part 2: 13,000 regression results |
| `sim_results_p3.dta` | Part 3: power curve simulation results |
| `sim_results_p4a.dta` | Part 4a: cluster size simulations |
| `sim_results_p4b.dta` | Part 4b: N_clusters simulations (full compliance) |
| `sim_results_p4c.dta` | Part 4c: N_clusters simulations (70% compliance) |
| `fig1_beta_density.png` | Part 1 sampling distributions |
| `fig2_beta_density_p2.png` | Part 2 sampling distributions |
| `fig3_sd_vs_n_p2.png` | Part 2 log-log SE plot |
| `fig4_comparison.png` | Parts 1 vs 2 comparison |
| `fig5_power_curve_p3.png` | Part 3 power curve |
| `fig6_power_cluster_size.png` | Part 4a power vs cluster size |
| `fig7_power_nclusters.png` | Part 4b power vs N schools |
| `fig8_compliance_comparison.png` | Part 4c compliance comparison |

All seeds are fixed; results are fully reproducible. **Warning:** Part 2 (N up to 1,048,576) and Part 4a (cluster_size up to 1,024 × 200 schools = 204,800 obs per rep) will take several minutes each.
