## Tables

**Table 1.** Step-by-step decomposition from the previously published specification to the corrected main model.

| Step | Change | *n* | Events | HR effort | HR warming | HR variability | HR interaction |
|---|---|---|---|---|---|---|---|
| S0 | previously published | 182,485 | 655 | 1.788 | 1.394 | 0.850 | 0.876 |
| S1 | + discovery-year dating | 181,134 | 646 | 1.305 | 1.437 | 0.971 | 0.859 |
| S2 | + coverage-gap effort | 175,686 | 638 | 1.267 | 1.432 | 0.958 | 0.863 |
| S3 | + area-weighted climate | 175,901 | 649 | 1.289 | 1.432 | 0.958 | 0.863 |
| S4 | + completeness offset | 175,901 | 649 | 1.448 | 1.428 | 0.962 | 0.862 |
| S5 | + province × year effect | 175,901 | 649 | **1.404** | **1.362** | **0.995** | **0.849** |

**Table 2.** Main model. Discrete-time proportional hazards, complementary log-log link; *n* = 175,901; 649 events; 392 species; 31 provinces; AIC 8,313.2. Cluster bootstrap: 300 resamples of provinces. Permutation null medians are from the strongest constrained null (N3, events shuffled among the species at risk within each province-year) for the climate terms and the interaction, and from N2 (effort shuffled across years within province) for effort; 199 permutations each. Because these nulls preserve the provincial-annual structure, their medians rather than unity are the correct reference for the corresponding effect sizes.

| Term | HR per SD | 95% CI (Wald) | 95% CI (province cluster bootstrap) | Permutation null median | *P* |
|---|---|---|---|---|---|
| Accumulated warming | 1.362 | 1.216–1.524 | 1.20–1.72 | 1.157 | 8.3 × 10⁻⁸ |
| Survey effort | 1.404 | 1.245–1.583 | 1.21–1.76 | 0.980 | 2.9 × 10⁻⁸ |
| Annual climate variability | 0.995 | 0.909–1.090 | 0.90–1.13 | 0.955 | 0.92 |
| Warming × effort | 0.849 | 0.761–0.948 | 0.74–0.99 | 0.955 | 3.7 × 10⁻³ |
| σ species | 0.405 | | |
| σ province | 0.326 | | |
| σ province × year | 0.804 | | |

**Table 3.** Random-effect structure comparison on four criteria.

| Structure | ΔAIC | McFadden *R*² | Marginal *R*² | Conditional *R*² | Marginal AUC | Conditional AUC | ICC |
|---|---|---|---|---|---|---|---|
| species | 163.1 | 0.0142 | 0.108 | 0.183 | 0.613 | 0.687 | 0.084 |
| species + province | 98.7 | 0.0220 | 0.124 | 0.274 | 0.612 | 0.721 | 0.172 |
| + year | 74.8 | 0.0250 | 0.069 | 0.277 | 0.607 | 0.737 | 0.224 |
| **+ province × year (main)** | **5.25** | **0.0331** | **0.082** | **0.411** | **0.612** | **0.854** | **0.358** |
| + species warming slope | 4.48 | 0.0334 | 0.080 | 0.403 | 0.612 | 0.865 | 0.351 |
| + province effort slope | 0.00 | 0.0339 | 0.082 | 0.395 | 0.611 | 0.852 | 0.341 |

**Table 4.** Model adequacy.

| Check | Statistic | *P* | Reading |
|---|---|---|---|
| KS uniformity | 0.0016 | 0.74 | calibrated |
| Dispersion | 0.947 | 0.59 | correct |
| Zero inflation | 1.000 | 0.59 | none |
| Outliers | 95 | < 0.001 | expected at 0.37% event rate |
| Grouped by year | 2 of 23 levels | 0.0018 | at nominal rate |
| Grouped by province | 2 of 31 levels | 0.024 | at nominal rate |
| Moran's *I* | −0.038 | 0.86 | no spatial structure |
| PH: warming × time | −0.022 | 0.82 | assumption holds |
| PH: effort × time | −0.211 | 7.7 × 10⁻⁴ | effort returns decline |

**Table 5.** Ecological rationale for every component of the main model. Each row states why the
component is in the model, what its estimate means, and one falsifiable prediction the
specification implies. All predictions are tested in the paper. The full version, with the
prediction column, is `tables/tbl_v2_ecological_rationale.csv` and `docs/ECOLOGICAL_RATIONALE.md`.

| Component | Why it is in the model | What the estimate means |
|---|---|---|
| Response: first record only | A species-province pair can acquire a first record once; treating re-documentation as new information would inflate the event count | The annual probability of crossing from undocumented to documented |
| cloglog link | Discrete-time analogue of proportional hazards; coefficients are hazard ratios and do not depend on the length of the time step | exp(β) is directly comparable with survival-analysis literature |
| Risk set with absorbing exit | Only species whose modelled range approaches a province are plausible candidates; pairs recorded before 2002 are prevalent, not incident, cases | Hazard conditional on being a plausible, not-yet-recorded candidate |
| Accumulated warming, *W* = 15 yr | Range boundaries integrate climate over years to decades; referencing to the species' own range is essential because absolute warming is near-uniform across China | HR 1.362 per 0.179 °C of province-minus-range warming |
| Annual variability | Separates decadal signal from year-to-year weather, so neither term can absorb the other | HR 0.995: weather in the discovery year adds nothing |
| Survey effort | A species can only be recorded where someone is looking; required for the climate coefficient to be interpretable | HR 1.404 per 1 SD; one SD multiplies annual visits by 7.75 |
| Warming × effort | Sparsely surveyed provinces are disproportionately montane with steep climatic gradients, and densely surveyed ones have already absorbed much of their Wallacean shortfall | HR 0.849: warming matters most where coverage is sparse |
| Offset log *c*(*t*) | Records enter only after publication, so recent years are under-represented; under incomplete reporting this is exactly an offset, not an approximation | Corrects for right-censoring without consuming a degree of freedom |
| (1\|species), SD 0.405 | Body size, song conspicuousness, habitat accessibility, density and taxonomic attention | ×1.50 per SD; species span a 3.7-fold range |
| (1\|province), SD 0.326 | Area, terrain complexity, habitat diversity, observer population, research tradition | ×1.39 per SD |
| (1\|province:year), SD 0.804 | The scale at which the observation process operates: regional campaigns, festivals, new reserves, local reporting channels | ×2.23 per SD, larger than either fixed effect; levels span 13-fold |
| Baseline 1980–2000 | Must end before the analysis period, or part of the warming being tested is written into the reference | Anomalies measured against the most recent non-overlapping period |

---

**Table 6.** Migratory stratification. Full results in `tables/tbl_v2_migratory_ladder.csv`,
`tbl_v2_migratory_stratified.csv` and `tbl_v2_migratory_interaction_by_group.csv`.

| Group | Events | Warming HR (95% CI) | Effort HR (95% CI) | Warming × effort HR | *P* |
|---|---|---|---|---|---|
| Resident | 218 | 1.363 (1.158–1.605) | 1.293 (1.110–1.506) | 0.942 | 0.54 |
| Partial migrant | 156 | 1.507 (1.244–1.826) | 1.270 (1.030–1.566) | 1.053 | 0.62 |
| Long-distance migrant | 175 | 1.514 (1.265–1.812) | 1.344 (1.130–1.598) | 0.753 | 0.0022 |
| *Moderation tests* | | LR *P* = 0.693 | LR *P* = 0.854 | three-way LR *P* = 0.256 | |

**Table 7.** Species-level range measures, all from phylogenetic logistic regression on the dated
tree. Full results in `tables/tbl_v2_species_range_measures.csv` and
`tbl_v2_species_range_circularity.csv`.

| Measure | *n* | Species with a record | OR per SD (95% CI) | *P* |
|---|---|---|---|---|
| Global range area (AVONET) | 1,298 | 334 | 1.456 (1.204–1.762) | 1.1 × 10⁻⁴ |
| China range area (BirdLife, clipped) | 1,003 | 312 | 1.653 (1.420–1.925) | 9.0 × 10⁻¹¹ |
| Provinces occupied — *not reported as a result* | 1,298 | 334 | 2.09 | 5 × 10⁻¹⁵ |

**Table 8.** Province-level models. Full results in `tables/tbl_v2_province_*.csv`.

| Model | Dispersion | *P* | AICc |
|---|---|---|---|
| Poisson | 5.60 | 2.3 × 10⁻¹⁷ | 302.2 |
| Negative binomial | 1.24 | 0.20 | 246.5 |
| Negative binomial, recent effort as offset | 1.52 | — | 266.8 |

| Term | Counts, IRR | Rate per unit of effort, IRR |
|---|---|---|
| Regional species richness | **1.27** (*P* = 0.036) | 0.89 |
| Early survey effort (2002–2008) | 0.92 | **0.71** (*P* = 0.028) |
| Recent survey effort (2009–2024) | 0.93 | *offset* |
| GDP per capita | 1.10 | **0.61** (*P* = 0.0027) |
| Administrative area | 1.17 | 1.20 |
| Habitat heterogeneity | 0.99 | 1.03 |

**Table 9.** Species-level effects fitted separately within taxonomic and migratory groups, all
from phylogenetic logistic regression on the dated tree. Only significant terms are shown; full
results in `tables/tbl_v2_species_group_effects.csv`.

| Grouping | Group | *n* species | With records | Significant terms (OR, *P*) |
|---|---|---|---|---|
| Taxonomic | Passeriformes | 710 | 203 | Range size 1.53 (0.0020); partial migrant 2.01 (0.0081) |
| | Non-passerines | 588 | 131 | Partial migrant 3.19 (3.3 × 10⁻⁴) |
| | All species | 1,298 | 334 | Range size 1.44; partial migrant 1.91; open habitat 0.55 |
| Migratory | Resident | 567 | 116 | Range size 1.60 (0.0042) |
| | Partial migrant | 228 | 91 | Granivore 0.28 (0.044) |
| | Migratory | 503 | 127 | Hand-wing index 0.51 (3.8 × 10⁻⁴); body mass 1.74 (0.0037); open habitat 0.42 (0.013) |

## Figure legends

**Fig. 1 | Survey effort and accumulated warming contribute comparably to the hazard of a new provincial record.**
**a**, Hazard ratios per standard deviation with 95% Wald confidence intervals, for the four fixed effects, at three species-distribution-model thresholds. The dashed line marks unity. Note that unity is not the appropriate null for the warming terms: design-preserving permutation nulls that retain the provincial-annual climate and event structure are centred on 1.16 for accumulated warming and 0.96 for the interaction (Extended Data Fig. 5a), so the increment attributable to species-specific referencing is smaller than the distance from unity suggests. **b**, Marginal predictions of the annual hazard against accumulated warming at the 10th, 50th and 90th percentiles of survey effort; ribbons are 95% confidence intervals on the fixed-effect linear predictor. **c**, Relative importance of each term under four independent criteria: loss of AIC, loss of fixed-effect AUC, loss of conditional *R*², and the absolute standardised coefficient. Larger values indicate greater importance. **d**, Discrimination attributable to fixed effects alone as terms are added, with the random structure held at the main model.

**Fig. 2 | Dating records to publication rather than to discovery is a systematic source of bias.**
**a**, Distribution of the delay between discovery and publication (bars, left axis as per cent of records) and the resulting reporting completeness *c*(*t*) implied by a compilation extending to 2025 publications (line). **b**, Annual counts of new provincial records under the two dating conventions. The shaded band marks years in which the discovery-year series is right-censored because the corresponding papers have not yet appeared. **c**, Hazard ratios for the four fixed effects across the five-step decomposition from the previously published specification (S0) to the corrected main model (S5). The shaded column marks the re-dating step.

**Fig. 3 | The result does not depend on any freely chosen analytical decision.**
**a**, Hazard ratio for accumulated warming across four climate indicators and four accumulation windows; asterisks denote significance. **b**, ΔAIC across the same grid, all cells fitted on identical rows. **c**, Hazard ratios for survey effort (triangles) and accumulated warming (circles) across four effort proxies and three treatments of the 24 implausible zero cells. AIC is not comparable across missing-data rules because the sample sizes differ, so only coefficients are shown.

**Fig. 4 | Random-effect structures evaluated on fit, explanatory power, variance structure and ecological meaning.**
**a**, ΔAIC; the main model is highlighted. **b**, Conditional *R*², conditional AUC and marginal AUC. Marginal AUC is flat across structures, confirming that the random terms absorb observational heterogeneity without redistributing the fixed-effect signal. **c**, Random-effect standard deviations on the latent scale; no component collapses in any structure.

**Fig. 5 | Anatomy of the model, in units a reader can picture.**
**a**, Construction of the species-referenced climate gradient, shown as 15-year trailing means for one province and two species. Yunnan has warmed more than the Chinese range of *Aethopyga christinae* and less than that of *Coracias garrulus*, so the same province in the same year yields opposite values of *x* for the two species. **b**, Variance of each climate term partitioned into variation between province-years and variation within a province-year, the latter arising purely from differences among species. **c**, Partial effects in natural units: annual hazard against how much more the province has warmed than the species' range, at three levels of survey effort expressed as annual visits. **d**, Every variance component and both focal fixed effects expressed as the hazard multiplier per one standard deviation, on a common axis.

**Fig. 6 | The observation process made visible.**
**a**, Species random intercepts as hazard multipliers, grouped by migratory strategy; diamonds are group medians. **b**, Province random intercepts mapped, after controlling for effort and climate; grey denotes provincial units outside the analysis scope. Base map GS(2019)1822. **c**, Province-by-year random intercepts, the largest variance component in the model. Provinces are ordered by their mean. **d**, Hazard ratio for survey effort as a function of year, from the model that allows effects to vary through time; the ribbon is the 95% confidence interval.

**Fig. 7 | Accumulation window and climate baseline.**
Windows of 5, 10, 15 and 20 years against three series: the main WorldClim 10-arc-minute data with a 1980–2000 baseline, the same baseline computed from CRU TS at 0.5° as a control for data source and resolution, and CRU TS with a 1970–2000 baseline. **a**, Hazard ratio for accumulated warming. **b**, Hazard ratio for survey effort. **c**, Hazard ratio for the interaction. **d**, ΔAIC within each series; circles mark the optimum. Ribbons are 95% confidence intervals.

**Fig. 8 | Migratory strategy shifts the baseline hazard but does not moderate either driver.**
**a**, Risk-set rows, events and species in each group; the three groups with a known strategy carry 549 events in total. **b**, Group-specific hazard ratios from models fitted separately within each group, with 95% confidence intervals. **c**, ΔAIC across the moderation ladder; red text is the likelihood-ratio *P* value against the model with a migratory main effect only. **d**, Group-specific warming × effort interaction derived from the three-way model; filled points are significant within group, open points are not. The formal test for heterogeneity among groups is not significant.

**Fig. 9 | Species-level correlates of new provincial records.**
**a**, Continuous traits, as odds ratios per standard deviation with 95% confidence intervals, under three treatments of phylogenetic non-independence. Filled points are significant. **b**, Categorical contrasts against their reference levels. **c**, Range measured as an area, from two independent sources, against range measured as a count of provinces occupied. **d**, For every term, the number of phylogenetic treatments in which it is significant, with the range of odds ratios across treatments.

**Fig. 10 | Province-level counts of new records.**
**a**, Model comparison: Poisson against negative binomial, with and without recent effort as an offset. **b**, Incidence rate ratios per standard deviation from the two negative-binomial models. **c**, Hierarchical partitioning of explained deviance into independent and joint contributions. **d**, Partial correlation of each predictor with the record count, holding the others constant.

**Fig. 11 | Directionality of new records relative to the species' known range.**
Bearing from the centroid of each species' BirdLife range to the record, binned into eight 45° sectors. Radar and wind-rose forms are provided for the overall data, for the six largest orders overlaid, and for each of the sixteen best-sampled orders individually. Every order panel carries both sample sizes, new records and species, because one species can contribute records in several provinces. Overlay panels use each order's own proportions; absolute sample sizes are in the legend.

**Fig. M1 | Mechanistic projection of the latent generation hazard, restricted to the fitted covariate support.**
Provincial hazard relative to 2024 under two SSP scenarios at three horizons, aggregating only species-province cells whose accumulated warming and survey effort fall inside the 1st–99th percentile of the fitted data. The percentage on each panel is the share of cells that qualify.

**Fig. M2 | Machine-learning projection under identical inputs and the same support mask.**

**Fig. M3 | TreeSHAP interpretation of the gradient-boosted model.** **a**, Mean absolute SHAP contribution per feature. **b**, SHAP dependence, monotone increasing for both accumulated warming and survey effort.

**Fig. M4 | The two model families agree inside the fitted range and diverge outside it.**
**a**, Province-year mean predicted hazard, 2002–2024. **b**, First-to-99th-percentile range of each predictor in the fitted data and in each scenario-horizon combination. **c**, Province-level projected hazard ratios, with rank correlation and directional agreement per panel.

**Extended Data Fig. 1 | Simulation-based residual diagnostics for the main model.**
**a**, Quantile–quantile plot of DHARMa scaled residuals against the uniform distribution, from 500 simulations; every 40th point is drawn. **b**, Kolmogorov–Smirnov *P* values for the residuals of each year and each province, against the nominal 5% level. **c**, Moran's *I* of province-mean residuals against a null distribution from 999 permutations of province labels, with inverse-distance weights. **d**, Rate of change of each focal coefficient with time on the log-hazard scale, testing the proportional-hazards assumption.

**Extended Data Fig. 3 | The same mechanistic projection without the support mask**, shown to indicate the magnitude of the extrapolation.

**Extended Data Fig. 5 | Design-preserving null models, resampling and influence.**
**a**, Null distributions of the four fixed effects under three permutation schemes, each destroying exactly one association while holding the risk set, the per-province-year event counts, the effort and completeness marginals and the random-effect hierarchy fixed (199 permutations each); red lines mark the observed values. The null for accumulated warming is centred near 1.16 rather than unity because permuting within province-years preserves the covariance between provincial-annual climate and provincial-annual event counts. **b**, Wald and cluster bootstrap confidence intervals, resampling species (392 clusters) and provinces (31 clusters), 300 times each. **c**, Actual coverage of the nominal 95% interval under a parametric bootstrap of 150 simulations from the fitted model, with the bias of each coefficient annotated. **d**, Relative change in each hazard ratio when each province, and each of ten species deciles, is held out. Draws converging to degenerate optima (|log hazard ratio| > 2) are excluded throughout; their number is 3 of 199 in the third null, 3 of 300 in the species bootstrap, and none elsewhere.
