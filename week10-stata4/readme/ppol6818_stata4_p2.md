# Part 2: De-biasing a parameter estimate using controls

## 1. DGP & Program

In this activity, the outcome of interest is monthly household consumption expenditure USD, $cons$. The DGP is:

- Confounder variable : **Mobile money agent access**, $agentacc$ ~ Uniform(0,1)
```stata
gen agentacc = runiform()
```
- X/Treatment variable : **Mobile money access** dummy, $mmacc$. This treatment should be driven by agent access (Confounder) and noise. Splited at median to have treatement rate of 0.5.
```stata
gen random_t = rnormal() + 0.8*agent 
gen mmacc = 0
summ random_t, d
replace mmacc = 1 if random_t>`r(p50)'
```
- Mediator variable : **Frequency of balance check**, $balancech$. Caused by MM access, and then affect monthly consumption.
```stata
gen balancech = 0.5* mmacc + 0.3*runiform()
```
- Y/Outcome variable : **Monthly consumption**, $cons$. Affected by MM access (directly), agent access (confounder), and balance checking (mediator).
  - To have total treatment effect of 0.3 SD, 
- Collider variable : **Mobile credit usage**, $credit$

```stata
gen credit_use = 0.4*mmacc + 0.3*cons + 0.3*rnormal()
```

By running regressions, 

$$
cons_i = \beta_0 + \beta_1 mmacc_i + \beta_2 prim_i + \beta_3 high_i + \beta_4 col_i + \beta_5 inc_i + \epsilon_i
$$

However, in this simulation, I assumed an **Infinite Superpopulation**, instead of fixed 10,000 households. For the simplicity, the program below is only designed to capture the statistics of $mmacc_i$.
where the true parameter values are 
$\beta_0$ = 100, $\beta_1$ = 20, $\beta_2$ = 7, $\beta_3$ = 10, $\beta_4$ = 5, $\beta_5$ = 0.15, and $\varepsilon_i \sim \mathcal{N}(0, 1)$.

The regressors are drawn as follows:

- $mmacc_i$ :                   **Mobile money access** indicator, equal to 1 if household $i$ holds an active mobile money account
- $prim_i$, $high_i$, $col_i$ : **Education** dummies to indicate the highest education level of household $i$, constructed from a `runiform(0 1)`, yielding approximately 30% shares each, with the remaiing 10% having zero year of education. 
- $inc_i$ :                     **Monthly income** variable (USD), calculated by `runiform(0 1)*1000`.

