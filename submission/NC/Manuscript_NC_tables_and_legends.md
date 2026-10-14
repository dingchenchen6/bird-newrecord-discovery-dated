## Tables

**Table 1.** Step-by-step decomposition from the previously published specification to the corrected main model.

| Step | Change | *n* | Events | HR effort | HR warming | HR variability | HR interaction |
|---|---|---|---|---|---|---|---|
| S0 | previously published | 182,485 | 655 | 1.788 | 1.394 | 0.850 | 0.876 |
| S1 | + discovery-year dating | 180,873 | 646 | 1.309 | 1.440 | 0.971 | 0.852 |
| S2 | + coverage-gap effort | 175,425 | 638 | 1.271 | 1.435 | 0.958 | 0.856 |
| S3 | + area-weighted climate | 175,640 | 649 | 1.300 | 1.434 | 0.958 | 0.856 |
| S4 | + completeness offset | 175,640 | 649 | 1.467 | 1.430 | 0.961 | 0.854 |
| S5 | + province × year effect | 175,640 | 649 | **1.429** | **1.365** | **0.995** | **0.839** |

**Table 2.** Main model. Discrete-time proportional hazards, complementary log-log link; *n* = 175,640; 649 events; 392 species; 31 provinces; AIC 8,308.5. Cluster bootstrap: 300 resamples of provinces. Permutation null medians are from the strongest constrained null (N3, events shuffled among the species at risk within each province-year) for the climate terms and the interaction, and from N2 (effort shuffled across years within province) for effort; 199 permutations each. Because these nulls preserve the provincial-annual structure, their medians rather than unity are the correct reference for the corresponding effect sizes.

| Term | HR per SD | 95% CI (Wald) | 95% CI (province cluster bootstrap) | Permutation null median | *P* |
|---|---|---|---|---|---|
| Accumulated warming | 1.365 | 1.219–1.528 | 1.20–1.72 | 1.161 | 7.2 × 10⁻⁸ |
| Survey effort | 1.429 | 1.268–1.611 | 1.24–1.78 | 0.979 | 4.9 × 10⁻⁹ |
| Annual climate variability | 0.995 | 0.908–1.089 | 0.90–1.13 | 0.965 | 0.91 |
| Warming × effort | 0.839 | 0.752–0.936 | 0.73–0.99 | 0.960 | 1.7 × 10⁻³ |
| σ species | 0.404 | | |
| σ province | 0.332 | | |
| σ province × year | 0.798 | | |

**Table 3.** Random-effect structure comparison on four criteria.

| Structure | ΔAIC | McFadden *R*² | Marginal *R*² | Conditional *R*² | Marginal AUC | Conditional AUC | ICC |
|---|---|---|---|---|---|---|---|
| species | 160.6 | 0.0147 | 0.113 | 0.187 | 0.614 | 0.688 | 0.084 |
| species + province | 95.5 | 0.0225 | 0.129 | 0.279 | 0.613 | 0.722 | 0.172 |
| + year | 73.1 | 0.0254 | 0.085 | 0.282 | 0.613 | 0.737 | 0.216 |
| **+ province × year (main)** | **3.32** | **0.0335** | **0.088** | **0.413** | **0.612** | **0.853** | **0.356** |
| + species warming slope | 2.60 | 0.0338 | 0.085 | 0.405 | 0.612 | 0.864 | 0.349 |
| + province effort slope | 0.00 | 0.0341 | 0.088 | 0.400 | 0.611 | 0.851 | 0.342 |

## Figure legends

**Fig. 1 | Dating records to publication rather than to discovery is a systematic source of bias.**
**a**, Distribution of the delay between discovery and publication (bars, left axis as per cent of the 1,028 records with a parseable discovery year) and the resulting reporting completeness *c*(*t*) implied by a compilation extending to 2025 publications (line). **b**, Annual counts of new provincial records under the two dating conventions. The shaded band marks years in which the discovery-year series is right-censored because the corresponding papers have not yet appeared. **c**, Hazard ratios (point estimates) for the four fixed effects across the five-step decomposition from the previously published specification (S0) to the corrected main model (S5). The shaded column marks the re-dating step.

**Fig. 2 | Survey effort and accumulated warming contribute comparably to the hazard of a new provincial record.**
**a**, Hazard ratios per standard deviation with 95% Wald confidence intervals, for the four fixed effects, at three species-distribution-model thresholds (main threshold: *n* = 175,640 species × province × year cells, 649 events). The dashed line marks unity. Note that unity is not the appropriate null for the warming terms: design-preserving permutation nulls that retain the provincial-annual climate and event structure are centred on 1.16 for accumulated warming and 0.95–0.96 for the interaction (Supplementary Fig. S11a), so the increment attributable to species-specific referencing is smaller than the distance from unity suggests. **b**, Marginal predictions of the annual hazard against accumulated warming at the 10th, 50th and 90th percentiles of survey effort; ribbons are 95% confidence intervals on the fixed-effect linear predictor. **c**, Relative importance of each term under four independent criteria: loss of AIC, loss of fixed-effect AUC, loss of conditional *R*², and the absolute standardised coefficient. Larger values indicate greater importance. **d**, Discrimination (area under the ROC curve, AUC) attributable to fixed effects alone as terms are added, with the random structure held at the main model.

**Fig. 3 | Anatomy of the model, in units a reader can picture.**
**a**, Construction of the species-referenced climate gradient, shown as 15-year trailing means for one province and two species. Yunnan has warmed more than the Chinese range of *Aethopyga christinae* and less than that of *Coracias garrulus*, so the same province in the same year yields opposite values of *x* for the two species. **b**, Variance of each climate term partitioned into variation between province-years and variation within a province-year, the latter arising purely from differences among species. **c**, Partial effects in natural units: annual hazard against how much more the province has warmed than the species' range, at three levels of survey effort expressed as annual visits. **d**, Every variance component and both focal fixed effects expressed as the hazard multiplier per one standard deviation, on a common axis.

**Fig. 4 | The observation process made visible.**
**a**, Species random intercepts as hazard multipliers (*n* = 392 species), grouped by migratory strategy; diamonds are group medians. **b**, Province random intercepts mapped, after controlling for effort and climate; grey denotes provincial units outside the analysis scope. Base map GS(2019)1822. **c**, Province-by-year random intercepts, the largest variance component in the model. Provinces are ordered by their mean. **d**, Hazard ratio for survey effort as a function of year, from the model that allows effects to vary through time; the ribbon is the 95% confidence interval (effort × time interaction, Wald *P* = 2.1 × 10⁻³).

**Fig. 5 | Direction of new records relative to species' range centroids, against geometric and observational nulls.**
**a**, Share of the 642 records with a range centroid in each of eight 45° sectors of bearing from the centroid of the species' global range (solid line), with the shares expected if each record fell at random among its species' candidate provinces (dashed; geometry) or among them in proportion to their 2002–2024 survey visits (dotted; geometry + effort), from 999 Monte Carlo draws. **b**, Ratio of observed to expected records per sector under the two nulls (log scale); bars show the 95% Monte Carlo interval of the null expressed as a ratio, and filled points mark sectors with Holm-adjusted two-sided *P* < 0.05. Against a uniform expectation direction departs strongly (χ² = 580.1, df = 7, *P* = 4.6 × 10⁻¹²¹); against the geometric null only weakly (χ² = 10.8, Monte Carlo *P* = 0.039); against the geometry + effort null the departure points north (χ² = 26.8, *P* = 0.001). **c**, Observed shares for the six orders with most records; each polygon gives the share of that order's own records per sector, and the key gives the numbers of records and species, because one species can contribute records in several provinces. Wind roses for the sixteen best-sampled orders are provided in the Supplementary Information.

**Fig. 6 | The result does not depend on any freely chosen analytical decision.**
**a**, Hazard ratio for accumulated warming across four climate indicators and four accumulation windows; asterisks denote two-sided Wald *P* < 0.05 (*), < 0.01 (**) and < 0.001 (***). **b**, ΔAIC across the same grid, all cells fitted on identical rows. **c**, Hazard ratios with 95% Wald confidence intervals for survey effort (triangles) and accumulated warming (circles) across four effort proxies and three treatments of the 24 implausible zero cells. AIC is not comparable across missing-data rules because the sample sizes differ, so only coefficients are shown.

**Fig. 7 | The two model families agree inside the fitted range and diverge outside it.**
**a**, Province-year mean predicted hazard, 2002–2024, from the mechanistic and gradient-boosted models (Spearman ρ = 0.56). **b**, First-to-99th-percentile range of each predictor in the fitted data and in each scenario-horizon combination. **c**, Province-level projected hazard ratios, with rank correlation and directional agreement per panel.