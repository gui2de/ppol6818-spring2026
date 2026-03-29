# Sunduss Hamdan (sh1930) - Assignment 8 README File

---

## Part 1: Fuzzy Matching – Tanzania Wards

I used the GIS intersection dataset, keeping overlaps of 50% or more as meaningful matches, then counted how many 2015 wards mapped to each 2010 parent ward. To identify parentless and orphan wards I merged against the 2015 and 2010 election datasets by ward name and region.

| Question | Answer |
|---|---|
| Q1: Wards in both 2010 and 2015 | 2,735 |
| Q2: Parentless wards | 439 |
| Q3: Orphan wards | 614 |
| Q4: Divided into 2 | 466 |
| Q5: Divided into 3+ | 37 |

**Q6: Division rate by region**

| Region | Total Wards | Divided | Division Rate |
|---|---|---|---|
| Rukwa | 63 | 25 | 0.397 |
| Morogoro | 150 | 50 | 0.333 |
| Katavi | 42 | 12 | 0.286 |
| Mtwara | 144 | 39 | 0.271 |
| Arusha | 121 | 30 | 0.248 |
| Mwanza | 153 | 34 | 0.222 |
| Geita | 97 | 20 | 0.206 |
| Kigoma | 109 | 22 | 0.202 |
| Tabora | 164 | 30 | 0.183 |
| Simiyu | 109 | 19 | 0.174 |
| Mara | 150 | 23 | 0.153 |
| Manyara | 120 | 18 | 0.150 |
| Ruvuma | 137 | 20 | 0.146 |
| Dar es Salaam | 89 | 13 | 0.146 |
| Tanga | 204 | 26 | 0.127 |
| Pwani | 106 | 12 | 0.113 |
| Dodoma | 187 | 20 | 0.107 |
| Mbeya | 207 | 21 | 0.101 |
| Njombe | 95 | 9 | 0.095 |
| Lindi | 130 | 12 | 0.092 |
| Iringa | 90 | 8 | 0.089 |
| Kilimanjaro | 151 | 13 | 0.086 |
| Shinyanga | 117 | 9 | 0.077 |
| Singida | 123 | 9 | 0.073 |
| Kagera | 180 | 9 | 0.050 |

---

## Part 2: De-biasing a Parameter Estimate

**DGP:** True treatment effect = 0.3 sd. Treatment is influenced by a confounder, so naive OLS is upward biased.

| Variable | Role | Effect on Y |
|---|---|---|
| Confounder | Affects treatment and Y | +0.5 |
| Treatment | Endogenous (influenced by confounder) | +0.3 (true effect) |
| Mediator | Caused by treatment, affects Y | Blocks path if controlled |
| Collider | Caused by treatment and Y | Opens backdoor if controlled |

**Models:**

| Model | Controls | Expected behaviour |
|---|---|---|
| 1 | None | Upward bias |
| 2 | Confounder | Unbiased, converges to 0.3 |
| 3 | Confounder + Mediator | Attenuated |
| 4 | Collider | Biased |
| 5 | All | Biased |

200 replications at N = 50, 100, 250, 500, 1000, 2500.

**Figure:** `bias_mean_beta.png` — mean beta by model and N. Only Model 2 converges to the true value of 0.3. All models show decreasing variance as N grows.

---

## Part 3: Choropleth Map

Choropleth of US state unemployment rates (2022 annual average, BLS) merged with the US Census Bureau state shapefile. Nevada had the highest rate (5.4%) and South Dakota the lowest (2.0%).

**Figure:** `choropleth_unemp.png`
