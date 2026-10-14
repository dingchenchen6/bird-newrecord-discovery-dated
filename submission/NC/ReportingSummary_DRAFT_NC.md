# Nature Portfolio Reporting Summary — draft answers (NEE / NC)

*Paste each answer into the official fillable form (Adobe Reader required; flat reference copy:
https://www.nature.com/documents/nr-reporting-summary-flat.pdf). Items marked [AUTHORS] need
author input. Prepared 2026-09-24 against the current form structure.*

## Statistics

For all statistical analyses, the following items are present in the figure legends, table legends, main text or Methods:

| Item | Status | Where |
|---|---|---|
| Exact sample size (n) as a discrete number and unit | Confirmed | Table 1 and Methods: *n* = 175,640 species × province × year cells, 649 events, 392 species, 31 provincial units; figure legends |
| Distinct samples vs repeated measurement | Confirmed | Methods (risk set): each species × province pair contributes one row per year until its first record; repeated rows of the same pair and province-year are modelled with crossed random intercepts |
| Statistical tests and whether one- or two-sided | Confirmed | Two-sided Wald tests for model coefficients; two-sided empirical *P* values from 199 permutations; likelihood-ratio tests for nested models; χ² goodness-of-fit and one-sided exact binomial tests (Holm-corrected) for directional sectors |
| Description of all covariates tested | Confirmed | Methods (Model; Climate variables; Survey effort) |
| Assumptions or corrections | Confirmed | Simulation-based residual diagnostics (DHARMa), proportional-hazards test, spatial autocorrelation of province residuals, Holm correction for directional sectors |
| Full description of parameters with uncertainty | Confirmed | Hazard ratios per SD with 95% Wald CIs and province-cluster bootstrap intervals (Table 1); random-effect SDs |
| Test statistic, CIs, effect sizes, df and exact P | Confirmed | Hazard ratios with 95% CIs and exact *P*; χ² with df for directionality; ΔAIC for model comparison |
| Bayesian analysis: priors and MCMC settings | n/a | No Bayesian analyses were used |
| Hierarchical and complex designs: level of tests | Confirmed | Crossed random intercepts (species; province; province × year); cluster bootstraps at the species and province level |
| Effect sizes and how calculated | Confirmed | Hazard ratios (exp of cloglog coefficients per SD), odds ratios (species level), incidence rate ratios (province level) |

## Software and code

**Data collection.** No software was used to collect primary data. New-record data were taken from the China Bird New Record dataset (CBNR v2), compiled from peer-reviewed publications with a large-language-model-assisted extraction pipeline followed by manual validation of every record.

**Data analysis.** R 4.5.1 with glmmTMB 1.1.14 (discrete-time hazard GLMMs), DHARMa 0.4.7 (residual diagnostics), ranger 0.18.0 and xgboost 3.2.1.1 (model-family comparison), sf 1.0.23 and terra 1.8.86 (spatial processing), data.table 1.18.4 and ggplot2 4.0.1; Python 3.11 for document assembly. All custom code is available at https://github.com/dingchenchen6/bird-newrecord-discovery-dated and will be archived with a DOI on Zenodo upon acceptance.

## Data

The new-record data are version 2 of the China Bird New Record dataset (CBNR), openly available under a CC BY 4.0 licence at https://doi.org/10.5281/zenodo.20809949. Nature-reserve boundaries are openly available at https://doi.org/10.5281/zenodo.14875797. Historical monthly climate (WorldClim 2.1 downscaling of CRU TS 4.09) and CMIP6 projections are publicly available from WorldClim (https://www.worldclim.org). Species range maps are available on request from BirdLife International (http://datazone.birdlife.org/species/requestdis); their licence does not permit redistribution. Survey-effort indicators were derived from eBird/GBIF occurrence records (2024 records: https://doi.org/10.15468/dl.vfeeak) and China Bird Report checklists (http://www.birdreport.cn); the raw records remain subject to their providers' terms, and the province-year effort panel is provided in the project repository. [AUTHORS: add the GBIF download DOI for the 2002–2023 records, or register a GBIF derived dataset and cite its DOI.]

## Research involving human participants, their data, or biological material

Not applicable.

## Field-specific reporting

Ecological, evolutionary & environmental sciences.

## Ecological, evolutionary & environmental sciences study design

**Study description.** Observational macroecological study. We modelled the annual hazard that a bird species receives its first documented record in a Chinese provincial unit as a discrete-time proportional-hazards process (binomial GLMM, complementary log-log link) on a species × province × year risk set (2002–2024), with accumulated warming relative to each species' historical range, survey effort, their interaction and annual climate variability as fixed effects, a reporting-completeness offset, and crossed random intercepts for species, province and province × year.

**Research sample.** All 1,029 provincial new bird records in CBNR v2 (2000–2025; 568 species, 23 orders, 33 provincial units). After restricting to mainland provinces with survey-effort coverage, the 2002–2024 window, candidate cells defined by species-distribution models and complete covariates, the modelling data comprise 175,640 species × province × year cells with 649 events, 392 species and 31 provincial units. The sample is the complete compilation of peer-reviewed provincial new records rather than a sample drawn from it.

**Sampling strategy.** No sampling was performed: the analysis uses every record in the compilation and every species × province × year cell in the candidate risk set, so no sample-size calculation applies. Sensitivity of the risk set was assessed at species-distribution-model thresholds of 50, 100 and 200 suitable cells.

**Data collection.** Records were extracted from peer-reviewed publications into CBNR by the dataset authors (LLM-assisted extraction with manual validation of every record). Climate, range, protected-area and survey-effort layers were obtained from the sources listed under Data and processed by the authors with the released code. [AUTHORS: name who compiled and processed the data.]

**Timing and spatial scale.** Records published 2000–2025, dated to their year of discovery; annual time steps over 2002–2024. Spatial units are the 31 provincial-level units of mainland China; climate at 10 arc-minutes aggregated to a 100 km analysis grid and to provinces and species ranges. Projections for 2030, 2050 and 2080 under CMIP6 SSP2-4.5 and SSP5-8.5.

**Data exclusions.** Taiwan, Hong Kong and Macao were excluded because the survey-effort source does not cover them. Species × province pairs first recorded before 2002 were removed as prevalent rather than incident cases. Ten records with an unusable or internally inconsistent discovery year were re-dated to publication year minus the median lag. Cells lacking effort or climate components were excluded (185,478 → 175,640 cells; 657 → 649 events), including Guangdong in 2024, whose survey-effort source covers only 14 days of that year. Exclusion rules follow from data coverage and the risk-set definition and were fixed before model fitting. [AUTHORS: confirm.]

**Reproducibility.** All results are reproduced from the released code and data; a smoke test re-derives the four main-model coefficients. Conclusions were checked across 12 effort-proxy and missing-data combinations, three distribution-model thresholds, four climate indicators, four accumulation windows and three climate baselines, and against design-preserving permutation nulls (199 permutations), species- and province-cluster bootstraps (300 resamples), a parametric bootstrap (150 simulations) and leave-one-province and leave-one-species-decile refits.

**Randomization.** Not applicable: observational data with no allocation to treatment groups. Randomization was used only to construct permutation nulls, with fixed random seeds.

**Blinding.** Not applicable: records were compiled from the published literature and analysed with pre-specified models; blinding was not possible or relevant.

**Did the study involve field work?** No.

## Reporting for specific materials, systems and methods

Antibodies; eukaryotic cell lines; palaeontology and archaeology; animals and other research organisms; clinical data; dual-use research of concern; plants; ChIP-seq; flow cytometry; MRI-based neuroimaging — **not applicable** (the study analyses published occurrence records; no organisms were handled).
