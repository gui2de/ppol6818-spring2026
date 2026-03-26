## Stata4_Part2
### 1. Overview:
This project examines how different model specifications affect the estimation of a treatment effect under a known data generating process (DGP). The true treatment effect is set to 0.3 standard deviations, and the goal is to evaluate how bias and variance evolve as sample size increases.
The simulation includes key causal structures: a confounder, a mediator, and a collider, each of which affects estimation differently depending on whether it is included as a control.

### 2. Data Generating Process (DGP)：
The DGP includes：
A binary treatment variable (treat)
A standardized outcome (y)
A confounder affecting both treatment and outcome
A mediator affected by treatment and influencing the outcome
A collider affected by both treatment and outcome
A categorical region variable used for fixed effects

The outcome is standardized to have standard deviation 1, so the true treatment effect is interpretable as 0.3 SD.

### 3. Model Specifications
M1: y = β * treat + ε
M2: y = β * treat + confounder + ε
M3: y = β * treat + mediator + ε
M4: y = β * treat + collider + ε
M5: y = β * treat + confounder + mediator + ε
M6: y = β * treat + confounder + collider + ε
M7: y = β * treat + confounder + i.region + ε

Simulations are repeated 300 times for each sample size:
N ∈ {100, 250, 500, 1000, 2500, 5000}


### 4. Summary table:
| N    | M1    | M2    | M3    | M4    | M5    | M6    | M7    |
| ---- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| 100  | 1.136 | 0.406 | 0.455 | 0.482 | 0.159 | 0.145 | 0.411 |
| 250  | 1.140 | 0.400 | 0.464 | 0.494 | 0.161 | 0.137 | 0.403 |
| 500  | 1.139 | 0.407 | 0.458 | 0.495 | 0.162 | 0.143 | 0.408 |
| 1000 | 1.139 | 0.402 | 0.453 | 0.494 | 0.155 | 0.143 | 0.401 |
| 2500 | 1.140 | 0.402 | 0.456 | 0.495 | 0.157 | 0.142 | 0.402 |
| 5000 | 1.140 | 0.403 | 0.457 | 0.495 | 0.157 | 0.142 | 0.403 |

### 5. Results

#### Mean Estimated Treatment Effect

![Mean Beta](C:/Users/86186/Desktop/Experimental design/stata4/mean_beta_by_N_fixed.png)

The mean estimated treatment effects show clear differences across model specifications:

- M1 (no controls) is severely upward biased (~1.14)
- M2 and M7 (with confounder) are closest to the true value (0.3), but still upward biased (~0.40)
- M3 (mediator) and M4 (collider) produce biased estimates
- M5 and M6 underestimate the treatment effect (~0.15)


#### Mean Estimated Treatment Effect (Detailed View)

##### Models 1–4

![Mean Beta M1-M4](C:/Users/86186/Desktop/Experimental design/stata4/mean_beta_M1_M4.png)

- M1 shows strong upward bias due to omitted variables
- M2 improves substantially after controlling for the confounder
- M3 and M4 remain biased due to incorrect controls

##### Models 5–7

![Mean Beta M5-M7](C:/Users/86186/Desktop/Experimental design/stata4/mean_beta_M5_M7.png)

- M5 and M6 consistently underestimate the treatment effect
- M7 performs similarly to M2, indicating fixed effects help but do not eliminate bias


#### Bias

![Bias](C:/Users/86186/Desktop/Experimental design/stata4/bias_by_N_fixed.png)

The bias results show that:

- Bias remains stable across sample sizes
- Increasing N does not reduce bias from misspecification
- M1 has large positive bias
- M5 and M6 have negative bias


#### Variance (Standard Deviation)

![SD](C:/Users/86186/Desktop/Experimental design/stata4/sd_beta_by_N_fixed.png)

- Variance decreases as sample size increases
- All models converge in precision
- However, biased models remain incorrect even with large N


## Stata4_Part3
### Overview

This project generates a choropleth map at the regional level by merging publicly available socioeconomic data with a geographic shapefile. The goal is to visualize spatial variation in low-income population share across Virginia.

### Data Sources

The analysis combines two main data sources:

- **Shapefile (geometry data)**  
  - File: `Low_Income_Communities.shp`  
  - Contains polygon boundaries for geographic units (e.g., counties or tracts)

- **Public data (CSV)**  
  - File: `Low_Income_Communities.csv`  
  - Key variable: `pctpopli` (percentage of population in low-income communities)  
  - Identifier: `objectid`

### Methodology

The workflow follows three main steps:

1. **Convert shapefile to Stata format**  
   - Used `shp2dta` to generate:
     - Attribute dataset (`lowincome_db.dta`)
     - Coordinate dataset (`lowincome_coord.dta`)

2. **Prepare and merge datasets**  
   - Imported CSV data using `import delimited`  
   - Standardized variable names to lowercase  
   - Merged shapefile attributes and CSV data using `objectid` as the key  
   - Kept only matched observations

3. **Generate choropleth map**  
   - Used `spmap` to visualize `pctpopli`  
   - Applied quantile classification  
   - Used a red color gradient to represent intensity  


### Results

![Low-Income Map](C:/Users/86186/Desktop/Experimental design/stata4/part3 data/low_income_clean_map.png)

The choropleth map shows clear spatial variation in the share of residents living in low-income communities across Virginia:

- Higher concentrations appear in many rural and economically disadvantaged areas  
- Lower shares are observed in several metro-adjacent and more economically developed regions  
- The distribution highlights significant geographic inequality in socioeconomic conditions  


### Conclusion

This analysis demonstrates how merging publicly available data with geographic shapefiles enables effective spatial visualization. The results reveal meaningful regional disparities in low-income population distribution and provide insight into areas that may require targeted policy intervention.