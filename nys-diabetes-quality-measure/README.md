# NYS Diabetes Quality Measure

## NYS Medicaid Diabetes Care Quality, 2018 to 2024

A SAS and R analysis of published New York State Department of Health QARR data. It looks at four diabetes care measures for Medicaid Managed Care members, compares Medicaid with commercial HMO and PPO plans, and tests whether regions of the state differ from the statewide rate.

This is a personal project that uses published, aggregated data. It does not use claims or member-level data.

## Question

For adults with diabetes in Medicaid Managed Care, how did diabetes care measures change from 2018 to 2024, how does Medicaid compare with commercial plans, and do regions of New York differ from the statewide rate?

## Data

Seven yearly QARR Health Disparities datasets, published by NYS DOH on Health Data NY. They are listed under Issue 5, Health Care Disparities in New York State, on the [Managed Care Reports page](https://www.health.ny.gov/health_care/managed_care/reports/).

| Year | Dataset |
|------|---------|
| 2018 | https://health.data.ny.gov/Health/Quality-Assurance-Reporting-Requirements-QARR-Heal/ajt9-v6nf |
| 2019 | https://health.data.ny.gov/Health/Quality-Assurance-Reporting-Requirements-QARR-Heal/brzd-i7d8 |
| 2020 | https://health.data.ny.gov/Health/Quality-Assurance-Reporting-Requirements-QARR-Heal/jier-ihfc |
| 2021 | https://health.data.ny.gov/Health/Quality-Assurance-Reporting-Requirements-QARR-Heal/kt3x-cqb6 |
| 2022 | https://health.data.ny.gov/Health/Quality-Assurance-Reporting-Requirements-QARR-Heal/x3xn-abgk |
| 2023 | https://health.data.ny.gov/Health/Quality-Assurance-Reporting-Requirements-QARR-Heal/xbgs-xi9h/about_data |
| 2024 | https://health.data.ny.gov/Health/Quality-Assurance-Reporting-Requirements-QARR-Heal/4uwr-x7ke/about_data |

The seven raw files hold 25,161 rows in total (3,610 / 3,162 / 3,259 / 3,350 / 3,650 / 3,827 / 4,303 for 2018 to 2024). The raw files are not stored in this repo. Download them from the links above and save them as `QARR_Health_Disparities_2018.csv` through `QARR_Health_Disparities_2024.csv`.

The four diabetes measures account for 1,091 of those rows. Those rows are in `data/rates.csv`.

| Measure | Years | Rows |
|---|---|---|
| BP Control <140/90 | 2018–2024 | 354 |
| HbA1c Control <8% | 2018–2023 | 297 |
| Eye Exam | 2018–2024 | 383 |
| Glycemic Status <8% | 2024 only | 57 |

## Methods

- **Cleaning:** numbers stored as text were converted, column names and measure names were standardised across years, and data-quality flags were added.
- **Exclusions:** 54 of 1,091 rows were excluded: 24 with implausible rates, 18 in a category reported in only one year, and 12 with an unknown region. 1,037 rows were used.
- **Single rates:** Wilson 95% intervals from the published rate and reported denominator (999 rows).
- **Medicaid vs commercial:** difference in published rates with an approximate 95% interval.
- **Regions:** each Medicaid region was tested against the rest of the state with a two-proportion z-test on counts. A gap counts as **meaningful** when p < 0.05, the counts and the published rates point the same way, and the published gap is at least 3 points.

## Findings

### 1. Trends (Medicaid statewide rate, %)

| Measure | 2018 | 2019 | 2020 | 2021 | 2022 | 2023 | 2024 |
|---|---|---|---|---|---|---|---|
| BP Control <140/90 | 65 | – | 56 | 62 | 65 | 69 | 73 |
| HbA1c Control <8% | 59 | – | 49 | 55 | 56 | 62 | – |
| Eye Exam | 66 | 64 | 59 | 61 | 61 | 62 | 62 |
| Glycemic Status <8% | – | – | – | – | – | – | 64 |

- All measures fell in 2020, the first COVID-19 year.
- Blood pressure control recovered fully and reached its highest level in 2024 (73%).
- HbA1c control recovered to 62% by 2023.
- Eye exams have not recovered and stayed around 61–62%, below the 2018 rate of 66%.

### 2. Medicaid compared with commercial plans

- **Lower than Commercial HMO** on blood pressure and HbA1c control. The gap was largest in 2020 (−9 points for BP, −14 for HbA1c) and has narrowed since (−2 for BP in 2024, −3 for HbA1c in 2023). Medicaid is 5 points lower on Glycemic Status in 2024.
- **Higher than Commercial PPO** on blood pressure control (+2 to +7 points every year) and on eye exams (+10 to +13 points every year). HbA1c control is about the same or slightly lower (−4 to +1).
- Eye exam rates for Medicaid and Commercial HMO are close in most years.

### 3. Regional differences within Medicaid

Of 106 region-years tested, **35 showed a meaningful gap**: 23 below and 12 above the rest of the state.

| Region | BP Control | Eye Exam | HbA1c Control |
|---|---|---|---|
| Hudson Valley | Below in 4 of 6 yrs | Below in 4 of 6 yrs | Below in 4 of 5 yrs |
| Northeast | **Above in 5 of 6 yrs** | – | – |
| Western | Above in 3 of 6 yrs | – | – |
| Central | Above in 2 of 6 yrs | Below in 3 of 7 yrs | Below in 1 of 5 yrs |
| Long Island | Below in 2 of 6 yrs | Below in 2 of 7 yrs | Below in 2 of 5 yrs |
| New York City | Below in 1 of 6 yrs | Above in 1 of 7 yrs | Above in 1 of 5 yrs |

- **Hudson Valley** is the most consistent low performer, below the rest of the state on all three measures.
- **Northeast** is consistently higher on blood pressure control (about 8 points on average).
- **New York City** is close to the rest of the state on all measures.

## Results check

Every key result was recalculated independently in R from the SAS output, and all checks passed:

| Check | Result |
|---|---|
| Row counts and exclusions (1,091 rows; 24 / 18 / 12 excluded; 999 with intervals) | PASS |
| Wilson 95% intervals | PASS |
| Hand-checked number: Medicaid BP 2023 = 7,276 / 10,577 (published 69%) | PASS |
| 38 Medicaid vs commercial gaps and their intervals | PASS |
| Regional p-values, gaps and the 35 meaningful gaps | PASS |
| R's `prop.test` agrees with the hand-written test | PASS |

## Limitations

- **Not risk-adjusted.** Differences between payers and regions partly reflect who is enrolled (age, health, income), not only quality of care.
- **Approximate intervals.** Intervals and tests use published rates and reported denominators, not member-level data. Some published rates differ slightly from numerator ÷ denominator because of chart-review sampling.
- **Oversized denominators.** Some rows report a denominator that does not fit the published rate. These have no interval and were not tested (3 payer comparisons and 2 region-years).
- **Missing years.** The 2019 file has no Medicaid BP or HbA1c data. HbA1c Control ends in 2023, and Glycemic Status (2024) is a different measure, so the two are not joined into one trend.
- **Many comparisons.** With 106 regional tests, a few meaningful gaps would be expected by chance. Patterns that repeat across years (Hudson Valley, Northeast) are more reliable than single-year results.
- **Rest of state is NYC-heavy.** New York City holds about half of Medicaid members, so "rest of state" is strongly shaped by NYC.

## Files and run order

| Step | File | What it does |
|---|---|---|
| 1 | `sas/Program_1.sas` | Imports the seven raw CSV files |
| 2 | `sas/Program_2.sas` | Compares columns across years and fixes a column-name typo |
| 3 | `sas/Program_3.sas` | Cleans numbers stored as text and stacks the years |
| 4 | `sas/Program_4.sas` | Checks truncation, missing values and region names |
| 5 | `sas/Program_5.sas` | Standardises category and measure names |
| 6 | `sas/Program_6_Analysis_Dataset.sas` | Builds the diabetes dataset and data-quality flags |
| 7 | `sas/Program_6b_Rates.sas` | Builds `qarr.rates`: exclusions and 95% intervals |
| 8 | `sas/Program_7.sas` | Medicaid minus commercial gaps |
| 9 | `sas/Regional_Gap_Vs_State.sas` | Medicaid region vs rest of state tests |
| 10 | `sas/Export_Data.sas` | Exports the three result tables to CSV |
| 11 | `R/R_crosscheck.R` | Rechecks the results and draws the figures |

Set `%let path =` in Program_1 and Export_Data, and `data_dir` in the R script, to your own folder.

**Output data:** `data/rates.csv` (1,091 rows), `data/payer_gap.csv` (38 comparisons), `data/region_gap.csv` (108 region-years).

**Figures:** `figures/fig1_statewide_trends.png`, `figures/fig2_medicaid_vs_commercial_gap.png`, `figures/fig3_regional_gaps.png`.

## Tools

SAS for data preparation and analysis; R (readr, dplyr, tidyr, ggplot2) for the results check and figures.

## What I learned

- **Public data needs a lot of cleaning before analysis.** The same dataset changed from year to year: a misspelled column name, numbers stored as text, different capitalisation, and measure names that changed over time. Checking columns across all years before stacking them saved errors later.
- **Check the data against itself.** Comparing each published rate with numerator ÷ denominator, and each denominator with its usual size, found rows that did not make sense (for example 2019 Commercial HMO rates of 3–12%). Excluding them with a written reason kept the results honest and explainable.
- **Measures change.** HbA1c Control was replaced by Glycemic Status in 2024, and HbA1c Testing was retired. Reading the measure definitions stopped me from joining two different measures into one trend.
- **Statistical significance is not the same as importance.** With large denominators, very small gaps become significant. Adding a 3-point minimum and requiring the counts and published rates to agree kept the focus on gaps that matter.
- **Compare a region with the rest of the state, not with the statewide rate.** The statewide rate already includes the region, so subtracting the region's counts gives a fairer test.
- **Cross-checking in a second language builds confidence.** Recalculating every result in R showed that the SAS results were correct, and it was a good way to catch mistakes.
- **Document as you go.** Keeping notes on row counts and exclusions at each step made it possible to rebuild a missing program and confirm it gave exactly the same results.
