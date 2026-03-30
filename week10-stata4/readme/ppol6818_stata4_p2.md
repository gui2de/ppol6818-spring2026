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
- Y/Outcome variable : **Monthly consumption**, $cons$. Affected by MM access (directly), agent access (confounder) and noises.
  - 0.3 SD is the true effect in this simulation. 
```stata
gen cons = rnormal() + 1.5*agent + 0.3*mmacc 
```
- Collider variable : **Mobile credit usage**, $credit$. Affected by both consumption and MM access. 
```stata
gen credit_use = 0.4*mmacc + 0.3*cons + 0.3*rnormal()
```

By running regressions, I investigate how those covariates affect the outcome variable. 

## 2. Regression analysis
### i. Confounder check
First, let's look at the outcomes of 2 regression models written below. I simulated 500 times with 1000 samples. 

1. Monthly consumption on Agent access
   
$$
\hat{cons} = \hat{\beta_0} + \hat{\beta_1} agentacc + \epsilon_i
$$

2. MM access on Agent access

$$
\hat{mmacc} = \hat{\beta_0} + \hat{\beta_1} mmacc + \epsilon_i
$$

I can confirm that $agentacc$ is the confounder of my X and Y variable, rather than IV, by looking at these models and their significance. 

 |   Variable |        Obs  |      Mean  |  Std. dev.  |  
 |:---|:---:|:---:|---:|
 | cons on agentacc |        500  |  1.36e-30   | 3.04e-29  |  
| mmacc on agentacc |        500   | .0000497   | .0004433   |

As we can see, the $\hat{\beta_1}$'s are both statistically significant, which means that $agentacc$ affects both $mmacc$ and $cons$. This is a definition of confounder. 

### ii. Covariates Models
There are 5 different regression models I ran, including;

1. Restricted: Consumption on MM access

$$
\hat{cons} = \hat{\beta_0} + \hat{\beta_1} mmacc +  \epsilon_i
$$

2. Confounder controlled: Consumption on MM access and Agent access

$$
\hat{cons} = \hat{\beta_0} + \hat{\beta_1} mmacc + \hat{\beta_2} agentacc + \epsilon_i
$$

3. Mediator controlled: Consumption on MM access, Agent access, and Balance check

$$
\hat{cons} = \hat{\beta_0} + \hat{\beta_1} mmacc + \hat{\beta_2} agentacc + \hat{\beta_3} balancech + \epsilon_i
$$

4. Collidor controlled: Consumption on MM access, Agent access, and Credit use

$$
\hat{cons} = \hat{\beta_0} + \hat{\beta_1} mmacc + \hat{\beta_2} agentacc + \hat{\beta_3} credit + \epsilon_i
$$

5. Everything: Consumption on MM access, Agent access, Balance check, and Credit use 

$$
\hat{cons} = \hat{\beta_0} + \hat{\beta_1} mmacc + \hat{\beta_2} agentacc + \hat{\beta_3} balancech + \hat{\beta_3} credit + \epsilon_i
$$

I am going to focus on how precise each model estimates $\beta_1$, while the true effect is 0.3. My assumption here is that model 2 would do the best job in capturing the true effect of MM access as I can control for the confounder to see its direct effect on consumption. 

<br>

Let's look at the distribution of $\hat{\beta_1}$ for sample size of 1000. 

<img width="1526" height="916" alt="image" src="https://github.com/user-attachments/assets/c0cd6cbf-44c9-4af9-9501-cd98e9243660" />

- In model 1, when it does not include confounder in its model, the distribution is far right of the true coefficient. This means that estimated $\beta_1$ is overestimated (upward biased) by excluding the confounder, agent access. This makes sense because the correlation between 1) mmacc and agentacc and 2) cons and agentacc both would be positive; If the hh has better access to mobile money agent, they would have better mobile money access and easier way to spend the mobile money.
- In model 2, as I assumed above, $\beta_1$ was estimated around the true effect. Model 3 did also good job estimating the effect, but has wider variation, which came from controlling mediator variable.
- When I included collider var in model 4 and 5, the $\beta_1$ get way underestimated, which makes sense because the collider by its definition is not the driver of Y variable, so adding them would bring a huge bias in the models.
<br>

Secondly, I simulated the same models with different sample sizes from 100 to 3000. 

The results are outputed in boxplot and line graph below. 

<img width="1526" height="916" alt="image" src="https://github.com/user-attachments/assets/4e7d89eb-8a69-4cfe-8820-5624046379bb" />

<img width="1526" height="916" alt="image" src="https://github.com/user-attachments/assets/cbaccfaf-9b9e-4100-8430-bbb706db45c6" />

- Overall, as we observed with only 1000 of sample size, 1) model 1 is overestimating $\beta_1$, 2) model 2 and 3 are estimating $\beta_1$ closer to 0.3, with more variation in model 3, and 3) model 4 and 5 are way underestimating $\beta_1$.
- From the boxplot, it can be observed that adding mediator would bring the model more variation and that adding collider would bring big downward bias in the model.
- Another thing we can observe from the boxplot is that standard deviation of the model gets smaller as the sample size gets bigger. The line graph below shows how the S.D. converes over the different sample size up to 3000.

<img width="1526" height="916" alt="image" src="https://github.com/user-attachments/assets/57fae749-502e-416c-ab8f-a00288f7cbdb" />

- As I mentioned above, the models with mediator have bigger S.D. as a whole.
- The converging standard deviation with bigger sample size aligns with that as we can observe more households, the sample gets more representative of the whole population and the true effect. 


