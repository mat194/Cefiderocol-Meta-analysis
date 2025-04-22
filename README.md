<p align="center">
  <img src="Utils/idcare_logo.png" alt="IDCare Logo" width="150" style="margin-right: 40px;"/>
  <img src="Utils/logo_UNIVR.png" alt="University of Verona Logo" width="150"/>
</p>

# Cefiderocol-Meta-analysis
## Project Overview
This repository contains the code and supporting materials for a systematic review and meta-analysis evaluating the effectiveness of cefiderocol combination versus monotherapy in infections caused by multidrug-resistant and carbapenem-resistant Gram-negative bacteria. The meta-analysis focuses on outcomes such as mortality, clinical cure, and microbiological eradication. Analyses include forest plots, influence diagnostics, and contour-enhanced funnel plots.
## Structure

```bash
.
├── Data                             # Folder containing raw and cleaned data used for the meta-analysis
│   └── Meta-analysis Cefiderocol_github.xlsx 
│
├── Plots                            # Output folder for generated plots from the meta-analysis
│   ├── forestplot_mortality.png     # Forest plot for the mortality outcome
│   ├── baujat_mortality.png         # Baujat plot for identifying influential studies for mortality
│   └── ...                          # Additional plots (influence, leave-one-out, funnel) for each outcome
│
├── Utils                            # Utilities
├── README.md                        
└── Script.R                         # Main R script for running the meta-analysis, generating plots, and performing diagnostics
```
## Data
The file `Meta-analysis Cefiderocol_github.xlsx` contains study-level data used for the meta-analysis. The following table explains the meaning of each column:

| **Column Name**                   | **Description**                                                                 |
|----------------------------------|---------------------------------------------------------------------------------|
| `First author, year` | Name of the first author and publication year, used to identify the study.     |
| `Type of study`                  | Study design (e.g., RCT, retrospective, prospective).                          |
| `Country`                        | Country where the study was conducted.                                         |
| `Mono/multicentric`             | Indicates whether the study was monocentric or multicentric.                   |
| `Target Pathogen`               | Pathogen targeted in the study (e.g., CRAB, MDR).                              |
| `Outcome`                        | Clinical endpoint reported (e.g., mortality, clinical cure, microbiological cure). |
| `No. of patients (total)`       | Total number of patients included in the study.                                |
| `ABT mainly used in combo (>20%)` | Antibiotics used in combination therapy when it accounted for >20% of cases.   |
| `Fav outcome combo`             | Number of favorable outcomes in the combination therapy group.                 |
| `Neg outcome combo`             | Number of unfavorable outcomes in the combination therapy group.               |
| `Fav outcome mono`              | Number of favorable outcomes in the monotherapy group.                         |
| `Neg outcome mono`              | Number of unfavorable outcomes in the monotherapy group.                       |
| `adjusted OR`                   | Adjusted odds ratio for the outcome, if reported.                              |
| `aOR lower`                     | Lower bound of the 95% confidence interval for the adjusted OR.                |
| `aOR upper`                     | Upper bound of the 95% confidence interval for the adjusted OR.                |
| `Analysis mode`                 | Type of statistical analysis used (e.g., univariate, multivariate).            |
## Methods
Random-effects models were applied using the restricted maximum-likelihood (REML) estimator to pool odds ratios (ORs) for dichotomous outcomes (mortality, clinical cure, microbiological cure). When available, adjusted effect sizes (adjusted ORs with 95% confidence intervals) were pooled using the inverse variance method; otherwise, crude odds ratios were calculated and included in the analysis.

Heterogeneity was assessed using the Chi-squared test and the I² statistic. A 95% prediction interval was included to reflect the expected range of treatment effects in future studies. Publication bias was evaluated using contour-enhanced funnel plots, and Egger’s test was not performed due to the limited number of studies per outcome (n < 10), which limits statistical power. Influence diagnostics included Baujat plots and leave-one-out analysis to explore robustness and study-level effects on heterogeneity and pooled estimates.

All analyses were conducted in R using the `meta`, `dmetar`, and `tidyverse` packages. Visualizations were automatically generated and saved as high-resolution `.png` files for each outcome.
## Citation and dissemination
