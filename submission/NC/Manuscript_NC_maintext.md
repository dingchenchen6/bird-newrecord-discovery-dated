# Warming and survey effort contribute comparably to new bird distribution records when dated to discovery

Chenchen Ding^1^, et al.

^1^ Institute of Ecology, College of Urban and Environmental Sciences, Peking University, Beijing 100871, China

Correspondence: Chenchen Ding (chenchen.ding@pku.edu.cn)

## Abstract

New provincial distribution records are a primary source of evidence for climate-driven range shifts, yet each record requires a bird, an observer and a publication. We analysed the China Bird New Record dataset (1,029 provincial records, 2000–2025) with a discrete-time hazard model on 175,640 species × province × year cells, dating each record to its discovery and modelling the observation process explicitly. Dating records to publication, the usual practice, inflated the survey-effort hazard ratio by 37% (1.79 versus 1.31) and produced a spurious climate-variability effect. After correction, accumulated warming relative to each species' historical range (hazard ratio 1.36 per standard deviation) and survey effort (1.43) contributed comparably and interacted negatively, so warming mattered most where effort was low. Permutation nulls attribute an increment of about 1.18 to species-specific warming beyond shared provincial climate. A province-by-year random effect, which absorbs survey campaigns and other regional pulses, was the largest variance component (×2.22 per standard deviation), and the return on effort fell from 2.14 in 2002 to 1.13 in 2024 while that on warming did not. Documented range gains thus reflect climate and observation in similar measure, and the date attached to a record decides which appears to dominate.

## Introduction

Records of species in places where they had not been documented before are among the most widely used evidence that ranges are shifting with climate. Range boundaries have moved poleward and upslope in many taxa as temperatures have risen^1–3^, and the resulting redistribution affects ecosystems and human well-being^4^. In China, compilations of provincial new bird records have been read as evidence of northward and poleward shifts^5–6^. A new record, however, is not an observation of movement. It is the last link in a chain of three events: a species occupies a place, someone detects it there, and the detection is published. Only the first link is ecological, and imperfect detection and uneven sampling can create apparent range changes where none occurred^7–8^.

The difficulty is that observation has grown as quickly as the climate has changed. Documented distributions reflect where people look as well as where organisms live^9–13^, and in mainland China the annual number of birding visits in the eBird and China Bird Report databases rose about 200-fold between 2002–2004 and 2022–2024 (Methods), the period over which the shifts above were reported. Any series of new records from these years will correlate with the growth of observation, whatever the contribution of climate. Opportunistic records yield unbiased trends only when the recording process is modelled^14^, and gaps and biases in such data are best treated as a missing-data problem^15^, yet compilations of first records have not been analysed in this way.

Each link in the chain leaves its own signature. The first concerns time. Compilations date each record by its year of publication, but publication lags discovery. Because observation expanded year on year, a record dated to publication is credited to a year in which more people were looking than when it was made, and because recent discoveries are still unpublished, the latest years are incomplete. The size and direction of the resulting bias have not been measured. The second concerns scale. Observation grows in pulses: a survey campaign, a birding festival, a new reserve or a new reporting platform raises documentation in one province in one year. Models with random effects for species and region alone cannot represent such pulses, so their magnitude is unknown, and so is whether they distort estimates of the drivers. The third concerns the benchmark for climate: a warming effect measured relative to each species' own range should be compared with what shared regional climate would produce if species identity carried no information. Finally, projections of record generation are rarely checked against the range of conditions to which the models were fitted^16–18^.

We asked whether warming measurably raises the rate at which new provincial bird records are generated in China once the publication and observation steps are modelled explicitly, and how its contribution compares with that of survey effort. Using the China Bird New Record dataset (CBNR), which gives dates of discovery as well as of publication for 1,029 provincial records^19–20^, we built a risk set of every species × province × year in which a first record could have occurred and modelled its annual hazard with a complementary log-log link, the discrete-time form of a proportional-hazards model^21–22^. Records were dated to discovery, with an offset for the incompleteness of recent years; survey effort entered as a covariate and province-year pulses as a random intercept; and warming was expressed relative to each species' historical Chinese range and evaluated against permutation nulls that preserve the structure of the data. None of these steps is specific to birds or to China.

We tested four predictions, specified before the robustness analyses were run. (H1) Dating records to publication inflates the effort coefficient and creates a spurious effect of year-to-year climate variability but leaves accumulated warming unchanged, because a lag of one or two years moves a record into a year with more observers and different weather while barely altering a 15-year mean. (H2) Province-year pulses are the largest source of unexplained variation, yet absorbing them leaves the discrimination achieved by the fixed effects unchanged. (H3) Warming and effort interact negatively: a species can be recorded for the first time in a province only once, so where effort has long been high, many of the species that warming favours will already have been recorded. (H4) For the same reason, the return on effort declines as the stock of detectable but undocumented occurrences is drawn down, whereas the return on warming, which keeps adding candidates as climates shift, does not.

## Results

### The risk set and the dating problem

Of the 1,029 records, 1,028 (99.9%) carry a parseable discovery date and 684 match a species × province cell in the candidate pool; 657 fall within the 2002–2024 window (Supplementary Table S7; Supplementary Fig. S15). Twenty-six records predate 2002 and describe species already present at its start, so they were removed from the risk set as prevalent cases.

Publication lags discovery by a median of one year and a mean of 2.09; 81.7% lag by at least one year and 26.8% by three or more (Fig. 1a). Re-dating changes the assigned year of 526 of 633 comparable events (83.1%), with a median shift of −1 year and a mean of −1.83 years. The two conventions produce qualitatively different time series (Fig. 1b): the publication-year series rises monotonically to 67 events in 2024, whereas the discovery-year series peaks at 59 in 2019 and falls to 14 in 2024. Neither can be used as it stands: the publication-year rise aggregates delayed reports, and the discovery-year fall reflects right-censoring, which we corrected directly.

Because the observed hazard is approximately the true hazard times the reporting completeness *c*(*t*), and the complementary log-log link is logarithmic in the hazard, *c*(*t*) enters exactly as an offset log *c*(*t*), computed from the pooled lag distribution, whose stationarity we verified (Supplementary Note S1), and included throughout.

After requiring non-missing effort and climate components, the risk set at the 50-cell threshold (8,319 species × province pairs, 185,478 rows and 657 events) yields modelling data of 175,640 rows, 649 events, 392 species and 31 provincial units.

### Publication-year dating inflates the apparent role of survey effort

We decomposed the difference between the previously published specification and the corrected one into five steps (each changing one analytical choice; step S3 also recovers 215 rows and 11 events whose unweighted provincial climate series were missing, so S0–S2 and S3–S5 differ slightly in sample) (Fig. 1c; Table 1).

Re-dating alone moves the survey-effort hazard ratio from 1.788 to 1.309, so that the publication-year estimate is 37% larger than the corrected one, and moves the annual-variability hazard ratio from 0.850 (*P* = 1.8 × 10⁻⁴) to 0.971 (*P* = 0.48). The accumulated-warming coefficient barely changes (1.394 → 1.440), and neither does the interaction (0.876 → 0.852), as H1 predicted. The remaining corrections are comparatively minor: treating structural zeros in the effort database as coverage gaps moves effort by −0.038; area-weighting the provincial climate series moves it by +0.029; the completeness offset restores +0.167, recovering signal that right-censoring had attenuated; and the province-by-year random intercept removes a further 0.038.

Both shifts follow from the timing of publication. Publication year and the size of the observational database increase together, so a record assigned to its publication year sits in a cell whose recorded effort exceeds the effort that produced the observation. The same shift detaches the record from the weather of the year in which the bird was seen, which is why a spurious negative coefficient on annual climate variability appears under publication-year dating and disappears under discovery-year dating. A 15-year trailing mean of warming barely moves when a record shifts by one or two years.

### Warming and effort contribute comparably

In the frozen main model, both drivers raise the hazard and the effect sizes are similar (Fig. 2a; Table 2). One standard deviation of accumulated warming relative to a species' historical range multiplies the annual hazard by 1.365 (95% CI 1.219–1.528; *P* = 7.2 × 10⁻⁸); one standard deviation of survey effort multiplies it by 1.429 (1.268–1.611; *P* = 4.9 × 10⁻⁹). Annual climate variability has no effect (0.995, 0.908–1.089; *P* = 0.91). The two main effects interact negatively (0.839, 0.752–0.936; *P* = 1.7 × 10⁻³): the marginal effect of warming is steepest where effort is low and flattens where coverage is already dense (Fig. 2b).

The warming coefficient must be read against a benchmark above unity (Supplementary Fig. S11). Permuting warming among species within a province-year, or the event indicator among species at risk, still returns about 1.16, because both permutations preserve the covariance between provincial-annual climate and event counts. The observed 1.365 lies outside that null (*P* = 0.005 for both), but only the increment, 1.365/1.161 ≈ 1.18, is attributable to referencing warming to each species' range; the remainder is a baseline that the null shares. Effort behaves differently. Permuting it across years within a province collapses its hazard ratio to 0.979, with a null interval covering unity, so the effort effect arises from the timing of effort within provinces. A province-cluster bootstrap widens the Wald intervals to 1.20–1.72 for warming and 1.24–1.78 for effort; both lower bounds remain above unity, and the interaction stays below it (0.73–0.99).

In natural units (Fig. 3c), one standard deviation of accumulated warming is 0.179 °C: a province that has warmed by that much more than a species' own historical Chinese range carries a 36% higher annual hazard for that species. Across the observed range of the variable, −0.65 °C to +0.61 °C, the implied hazard spans roughly ninefold. One standard deviation of survey effort corresponds to a 7.89-fold increase in annual provincial visits, from a median of 60.5 visits per year to about 478.

Much of the variation in the climate variable lies among species within the same province and year (Fig. 3a, b): 39% of the variance in accumulated warming and 55% of that in the raw gradient. In Yunnan in 2020, accumulated warming ranges from +0.309 °C for *Aethopyga christinae*, whose Chinese range has warmed less than Yunnan has, to −0.280 °C for *Coracias garrulus*, whose range has warmed more. A province-level warming index would give both species the same value.

Four independent importance criteria agree that warming and effort are of comparable weight, with warming slightly ahead on discrimination (Fig. 2c). Dropping accumulated warming costs 29.9 AIC units and 0.053 of marginal AUC; dropping survey effort costs 33.4 AIC units and 0.033 of marginal AUC. The interaction costs 7.8 AIC units. Dropping annual variability improves AIC by 2.0 units; we retain it as one half of a pre-specified decomposition.

The discrimination ladder shows the same balance (Fig. 2d). With the random structure held at the main model, fixed-effect-only AUC rises from 0.410 for the null model to 0.559 with effort alone, 0.580 with accumulated warming alone, and 0.610 with both. Climate alone discriminates better than effort alone; neither alone approaches the pair.

### Separating the observation process requires a province-by-year level

We evaluated six random-effect structures against four criteria, of which AIC is only one (Table 3; Supplementary Fig. S1). Adding a province-by-year intercept to the conventional species + province structure improves AIC by 92.1 units, raises conditional *R*² from 0.279 to 0.413, raises conditional AUC from 0.722 to 0.853, and raises the intraclass correlation from 0.172 to 0.356. Marginal AUC, the discrimination attributable to the fixed effects, is flat across all six structures (0.611–0.614), so the added level absorbs observational heterogeneity without redistributing the fixed-effect signal, as H2 predicted.

Two structures with random slopes fit marginally better, a species-specific slope on accumulated warming (ΔAIC 2.6) and a province-specific slope on effort (ΔAIC 0.0, the AIC optimum), but both *reduce* conditional *R*² (0.405 and 0.400 respectively, against 0.413), and their fixed effects are indistinguishable from those of the main model (effort 1.422 and 1.404; warming 1.351 and 1.368; Supplementary Fig. S1). We therefore froze the three-level intercept structure, the most parsimonious of the three indistinguishable options and the one with the highest explanatory power. No variance component collapses in any structure (minimum standard deviation 0.272).

### What each level of the model represents

Each random term corresponds to a distinct process, and the fitted magnitudes are themselves results (Fig. 3d, Fig. 4; Supplementary Table S2).

*Species (SD 0.404).* Species differ in detectability for reasons that no covariate in the model captures. One standard deviation multiplies the hazard by 1.50, and the fitted species span a 3.7-fold range.

*Province (SD 0.332).* Provinces differ in their baseline setting for discovery, from area and terrain to observer population and research tradition. One standard deviation multiplies the hazard by 1.39.

*Province by year (SD 0.798).* This is the largest variance component in the model. One standard deviation multiplies the hazard by 2.22, more than either fixed effect, and the fitted levels span a thirteenfold range (Fig. 4c). It represents the scale at which observation operates: a regional survey campaign, a provincial birding festival, a newly established protected area or a new local reporting channel raises the documentation rate for one province in one year.

*Reporting completeness offset.* This known correction consumes no degrees of freedom; omitting it attenuates the effort coefficient from 1.404 to 1.264, because censoring is concentrated in the recent, high-effort years.

### Migratory strategy shifts the baseline hazard but moderates neither driver

Migratory strategy shifts the baseline hazard: adding it as a main effect improves fit (ΔAIC 6.2) and is the best model in the ladder. It does not, however, moderate either driver. Adding warming × strategy, effort × strategy, both, or the full three-way term each *worsens* AIC, and none is supported by a likelihood-ratio test (*P* = 0.692, 0.638, 0.792 and 0.260). Fitting each group separately gives overlapping intervals. Group sizes, group-specific hazard ratios and a warming × effort interaction confined to long-distance migrants, which we treat as a hypothesis because the heterogeneity test is not significant, are in Supplementary Note S3 (Supplementary Fig. S3; Supplementary Table S3).

### Which species, and which provinces

Two coarser questions complement the hazard model: which species yield a new provincial record at all, and which provinces accumulate more of them (Supplementary Note S4; Supplementary Figs S4, S5; Supplementary Tables S4–S6).

*Species level.* Across the 1,298 modelled species and three treatments of phylogenetic non-independence, two effects hold. Partial migrants are about twice as likely as residents to yield a new provincial record (odds ratio 1.89–2.50 across treatments, all *P* < 0.001), and range size raises the odds by 1.23–1.46 per standard deviation. This converges with the hazard model from a different direction: partial migrants also carry the highest raw event rate there (0.418% against 0.29–0.33%). Range size has to be measured as an area, because the trait database's provincial counts, published in 2022, already contain the records used as the response. The two independent area measures agree, giving 1.456 for global and 1.653 for Chinese range area (Supplementary Table S4).

*Province level.* Counts of new records per province are overdispersed relative to Poisson and are modelled as negative binomial. The informative specification treats recent survey effort as an offset, so that the response becomes the discovery rate per unit of effort: provinces already well covered in 2002–2008 then yield fewer records per unit of recent effort (0.70, *P* = 0.023), as does higher GDP per capita (0.61, *P* = 0.0026). Hierarchical partitioning attributes 51.2% of the explained deviance to species richness, 32.9% to area and 9% to the two effort terms combined, with the full model explaining 20.6% of deviance.

At the provincial scale, then, effort appears as diminishing returns, the same signal that the hazard model shows as an effort coefficient falling through time.

### Records lie slightly north of where geometry and effort place them

Bearings from the centroid of each species' global range^23^ to its new records are far from uniform (χ² = 580.1, df = 7, *P* = 4.6 × 10⁻¹²¹; Fig. 5a): east holds 237 of 642 records (36.9%) and northeast 179 (27.9%), whereas south and west hold 20 and 19. A uniform expectation is the wrong benchmark, however. Many of these species have ranges centred west or south of China, so a record anywhere in China lies east or north of the centroid by position alone. Reassigning each record at random among its species' candidate provinces reproduces the pattern closely: 234.8 records are expected to the east and 158.6 to the northeast, no sector departs from expectation after Holm correction, and the omnibus departure is small (χ² = 10.8, Monte Carlo *P* = 0.039; Fig. 5a, b; Supplementary Tables S9, S10).

Weighting the candidate provinces by their 2002–2024 survey visits adds the observation process to the null, and the departure that remains points north (χ² = 26.8, *P* = 0.001). Records fall to the northeast (179 against 151.8 expected) and northwest (31 against 17.7) more often, and to the east (237 against 264.3) less often, than the distribution of survey effort predicts (Holm-adjusted *P* = 0.016–0.024); the southern deficit (20 against 32.4) is marginal (Holm-adjusted *P* = 0.050), and the three northern sectors hold 40.2% of records against 32.8% expected. Of the five best-sampled orders, only Passeriformes departs from both nulls under both placements of provinces (*P* ≤ 0.007). The eastward concentration of raw bearings therefore reflects China's position relative to species' global ranges; once geometry and effort are accounted for, new records lie modestly poleward of expectation.

### The return on survey effort is declining

Proportional hazards holds for warming (interaction with time β < 0.001, *P* = 1.00) but not for effort (β = −0.190, *P* = 2.1 × 10⁻³). The departure is itself a result: allowing the effort coefficient to vary through time, its hazard ratio falls from 2.14 (95% CI 1.61–2.85) in 2002 to 1.13 (0.93–1.37) in 2024, crossing into non-significance in the early 2020s (Fig. 4d). The warming term shows no such decline, as H4 predicted, although we did not test the two time interactions against each other.

### Robustness

None of the conclusions depends on the analytical choices we were free to vary (Fig. 6; Supplementary Note S5).

*Species-distribution-model threshold.* Raising the requirement from 50 to 200 suitable cells changes the risk set from 175,640 to 155,207 rows but leaves the coefficients essentially fixed (effort 1.429, 1.431, 1.437; warming 1.365, 1.379, 1.375; interaction 0.839, 0.840, 0.839).

*Accumulation window and climate baseline.* We tested windows of 5, 10, 15 and 20 years against three climate series (Supplementary Fig. S2). The warming coefficient rises with window length in every series, from 1.16–1.22 at five years to 1.38–1.40 at twenty, as expected of a process that integrates climate over decades. A 3–23-year grid (Supplementary Table S8) places the optimum at 18–20 years, interior to the tested range; we retain the pre-specified 15 years, within 2.1–6.0 AIC units of it. Baseline period, data source and climate indicator move the estimate only slightly (Supplementary Note S5).

Across all twelve combinations the effort coefficient is flat at 1.37–1.43 and the interaction negative (0.82–0.96); because changing the climate specification leaves the effort estimate unchanged, the two terms are separately identified.

*Effort proxy and missing-data rule.* All twelve combinations of four proxies (visits, observers, birding days, records) and three treatments of the 24 implausible zero cells (coverage gap, bounded within-province interpolation, zero-filling) give effort hazard ratios between 1.25 and 1.55 and warming hazard ratios between 1.33 and 1.39. Supplementary Note S5 gives the evidence that these cells are gaps in database coverage.

### Model adequacy

Simulation-based residual diagnostics indicate a well-calibrated model (Supplementary Fig. S9; Supplementary Table S1). Scaled residuals are uniform (Kolmogorov–Smirnov *P* = 0.86), dispersion is correct (*P* = 0.51) and there is no zero inflation (*P* = 0.52). Province-mean residuals show no spatial autocorrelation (Moran's *I* = −0.042; permutation *P* = 0.76). The outlier test is significant (86 outliers), as expected for a binary outcome with an event rate of 0.37%.

Three resampling analyses complete the assessment (Supplementary Note S6; Supplementary Fig. S11). A cluster bootstrap shows that provincial clustering inflates the standard errors by a factor of 1.30–1.53, whereas species clustering does not (0.89–1.19); Table 2 reports both. A parametric bootstrap recovers the coefficients with absolute bias below 0.01 on the log-hazard scale and gives actual coverage of 92.0–93.3% for the nominal 95% interval. Leaving out each province, and each of ten species deciles, moves the coefficients by at most 3.9%: no single province or species group carries the result.

### How far can these relationships be projected?

We projected the fitted hazard under SSP2-4.5 and SSP5-8.5 for 2030, 2050 and 2080 and asked how much of each scenario lies inside the range over which the model was fitted (Fig. 7b). The historical species-specific gradient has a standard deviation of only 0.18 °C, because provincial and range-wide anomalies largely move together. Future province-minus-range warming differentials reach 2 °C, more than ten standard deviations beyond the fitted range, and effort leaves its fitted range sooner still, because its 2024 level is already the highest observed. Only 45.7% of species-province cells fall inside the fitted covariate support under SSP2-4.5 in 2030, 6.3% in 2050 and none in 2080; under SSP5-8.5, 30.3% in 2030 and none thereafter.

Restricted to cells inside the support, the mechanistic model projects hazard ratios relative to 2024 of 0.95 to 1.50 (Supplementary Fig. S6). Applied without the mask, the same model produces ratios up to 88 (Supplementary Fig. S10).

A gradient-boosted comparison model trained on the same three predictors shows why the support matters (Supplementary Note S7; Supplementary Figs S7, S8). Within the observed range the two model families track each other across province-years (Spearman ρ = 0.56); outside it they agree on the direction of change in only 8.6% of cells, and in none under SSP5-8.5 in 2080. The cause is structural: tree ensembles saturate once covariates leave the training support, whereas the complementary log-log model extrapolates linearly on the log-hazard scale.

Treating climate and effort as independent scenario axes shows which governs future record generation (Supplementary Fig. S16): with effort frozen at 2024, switching SSP2-4.5 for SSP5-8.5 leaves the national expectation unchanged (26.1 versus 25.9 per year in 2030), whereas effort growing at half its observed pace raises the 2050 expectation from 26.8 to 79–89, with no cells left in support. A random forest and XGBoost under identical designs behave alike, leading on leave-species folds but trailing on temporal and leave-one-province prediction, while all three families agree on where records will fall (ρ 0.59–0.89; Supplementary Note S8; Supplementary Figs S17, S18). On the same scenario grid the families diverge sharply: from a common 2024 total, the mechanistic model reaches 79.3 records per year by 2050 under continued effort growth, the random forest stays at 23.9 and XGBoost falls to 7.4 (Supplementary Figs S19, S20).

### Records inside nature reserves track the observation process

Twenty-six per cent of new records fall inside the 1,028 mapped Chinese nature reserves, against a land-area share of 10.4%, an apparent 2.5-fold enrichment that would ordinarily be read as evidence that the network is receiving redistributing species. Birding effort is not concentrated in reserves: the checklist-weighted share inside is 10.8%, indistinguishable from the area share. Matching each event to 200 checklist-weighted controls from the same province and year reduces the enrichment to an odds ratio of 1.71 (95% CI 1.39–2.11), and to 1.57 (1.26–1.96) with elevation, longitude and two bioclimatic covariates.

The residual association is itself largely observational: it rests on 68 reserves, the top two holding 27.3% (a block bootstrap over hosts widens the interval to 0.89–3.19), it is confined to the period of rapid growth in birdwatching (2.05, 1.61–2.59, for 2013–2023 against 0.97, 0.62–1.50, for 2002–2012), and checklists inside reserves record 24% more species per visit. Because within-site observation bias cannot be conditioned out, we declared in advance how the result would be read: a null would be strong evidence, a positive one weak. The 1.57 odds ratio is therefore an upper bound on any ecological contribution, and record counts inside reserves should not index reserve performance (Supplementary Note S2; Supplementary Figs S12–S14).

## Discussion

New provincial bird records in China reflect both the movement of birds and the growth of birdwatching, in similar measure. Once records are dated to discovery and observation is modelled explicitly, a standard deviation of warming relative to a species' historical range raises the annual hazard of a first record about as much as a standard deviation of survey effort (hazard ratios 1.36 and 1.43). Which of the two appears to dominate depends on a field that analyses of such compilations seldom question: the date. We had expected effort to dominate, given the growth of birdwatching; that expectation held only under publication-year dating.

Publication dating biases estimates in a predictable direction (H1). Publication lags discovery by about two years and observation grew almost every year, so a record dated to publication is credited to a year in which more people were looking than when the bird was found, and the error favours whichever covariate trends with observer numbers. The problem extends beyond new records: most new plant species are described from specimens collected years or decades earlier^24^, and assessments of alien-species accumulation rest on dated first records^25^. Any analysis relating such series to trending covariates is exposed to the same bias. The first remedy is to record the date of observation, as CBNR does. Where that is impossible, a completeness offset like ours, the discrete-time counterpart of the reporting-delay adjustments used in epidemiological surveillance^26^, corrects the expected hazard for records not yet published.

The two drivers also behave differently through time. The return on effort fell from 2.14 in 2002 to 1.13 in 2024, and provinces that were well surveyed in 2002–2008 later yielded fewer records per unit of effort, whereas the return on warming showed no detectable change (H4). We read this as the difference between a stock and a flow. Effort draws down a stock of occurrences that were detectable but undocumented, the Wallacean shortfall^9^; warming keeps adding to it as the climate of each province moves relative to species' ranges. The negative interaction (H3) fits the same reading: where effort has long been high, many of the species that warming favours have already been recorded, and the pairs left at risk respond less. Depletion of this kind is expected in hazard analyses, because the most susceptible units leave the risk set first^27^. Geography offers an alternative: sparsely surveyed provinces are disproportionately western and montane, where steep gradients may make a given amount of warming more consequential, and this alone could produce a negative interaction. Nor did we test the two time trends against each other. If the stock-and-flow reading is correct, the share of new records that reflects redistribution will grow as the stock is exhausted, and new-record series will become more informative about climate, provided that their dating and the observation process are modelled.

The warming coefficient also needs the right benchmark. Permutations that retain provincial-annual climate but scramble species identity still return a hazard ratio of about 1.16, so the component attributable to referencing warming to each species' own range is about 1.18. The rest is an association between provincial climate and the number of records in a province-year, which may be climatic or observational and which a species-blind analysis would reproduce. Direction makes the same point more sharply: the apparent eastward concentration of new records is what China's position relative to species' global ranges produces when records fall at random among candidate provinces. Against a null that also follows survey effort, records lie further north than expected, with 40.2% in the three northern sectors against 32.8%. Directional readings of new records^5–6^ therefore need a geometric and observational benchmark; against one, the poleward signal in these data is detectable but modest.

Projection meets a different limit. Because the species-referenced gradient varied little and effort is projected past its observed peak, late-century scenarios push all species–province cells outside the fitted support, where the mechanistic and machine-learning models agree on the direction of change in fewer than one cell in ten. The scenario projections also apply the effort coefficient estimated over the whole period, although its value had fallen to 1.13 by 2024, so the effort-driven rise they imply is an upper bound. Projections of record generation should report the share of projected cells inside the fitted support^16–18^. Where that share is small, a near-term surface with an explicit support mask is more defensible than a century-scale map.

Several limitations bound these conclusions. The events are published records, and the model has no explicit detection component, so the coefficients describe the generation of documented records; a species present but unreported is counted as absent, and no coefficient measures range expansion itself. The province-by-year intercept absorbs provincial climate anomalies as well as survey pulses, which protects the fixed effects from observational confounding but, if anything, biases the warming estimate towards zero. Effort is measured per province and year, far more coarsely than the sites observers visit, and the directional nulls likewise place records at province level. The candidate pool rests on species-distribution models whose thresholds we varied but whose structure we did not, and vagrants without established Chinese ranges were excluded, so the results describe dynamics at range margins. The most recent years remain right-censored: the completeness offset corrects the expected hazard but cannot recover unpublished records. The design is observational, and no coefficient should be read as causal.

A province-year pulse of one standard deviation multiplies the hazard of a first record by 2.22, more than either driver, so survey campaigns change the biodiversity record quickly and should be placed deliberately. Because effort acts on a logarithmic scale and well-surveyed provinces yield fewer records per unit of new effort, additional visits document most where surveys are sparse, which is also where warming raises the hazard most. Because the return on effort has fallen within two decades, a plateau in new records should not be taken to mean that redistribution has slowed. Records inside nature reserves track where people watch birds and should not be used to score reserve performance. Finally, compilers of new-record data can make every later analysis more reliable, at little cost, by publishing both the date of observation and the date of publication for each record.

## Methods

### Event data and dating

New provincial-level bird distribution records for China were taken from version 2 of the China Bird New Record dataset (CBNR; 1,029 records covering 2000–2025)^19–20^, compiled from peer-reviewed publications with a large-language-model-assisted extraction pipeline followed by manual validation of every record^19^. Each record carries a discovery date and a source publication year. We parsed a four-digit year from the discovery date field, obtaining a usable year for 1,028 of 1,029 records. Nine further records reported a discovery year later than the publication year, which is internally inconsistent; for these ten records in total we substituted publication year minus the median lag of one year, and flagged the substitution in the released data.

Species names were harmonised by trying, in order, the Catalogue of Life China 2026, BirdLife International v10 and Clements v2025 names supplied with the compilation, retaining the first that matched the candidate pool; provincial names were harmonised by mapping Xizang to Tibet. Taiwan, Hong Kong and Macao were excluded because the survey-effort compilation does not cover them.

For each species × province pair we retained the earliest event year; later reports of the same pair were treated as re-documentation. Pairs whose earliest record predates 2002 describe species already present at the start of the analysis window and were removed from the risk set as prevalent rather than incident cases. Every remaining event was forced into the risk set irrespective of its species-distribution-model status.

### Reporting completeness

Let *F* be the empirical cumulative distribution of non-negative publication lags and *P*max = 2025 the latest publication year in the compilation. A record discovered in year *t* can have appeared only if its lag is at most *P*max − *t*, so the expected share of year-*t* discoveries already reported is *c*(*t*) = *F*(*P*max − *t*). We verified that lag is stationary across discovery years using Spearman correlation and a Wilcoxon comparison of the first and second halves of the well-reported period (2002–2018), and by comparing the cumulative distributions directly. Under incomplete reporting the observed hazard is approximately *c*(*t*)·*h*(*t*); with a complementary log-log link this is exactly an offset, log(−log(1 − *p*obs)) = η + log *c*(*t*), which we include in every model. Sensitivity analyses omitting the offset and truncating the window at 2021 are reported.

### Risk set

The candidate pool for each species comprises every province in which its species distribution model marks at least a threshold number of suitable grid cells, plus every province in which the species was actually recorded. Cells are those of the 2.5-arc-minute climate surface and have a median area of 18.3 km² (about 4.3 km on a side), so the three thresholds of 50, 100 and 200 cells require roughly 0.9, 1.8 and 3.7 thousand km² of suitable habitat within the province. Each species × province pair contributes one row per year from 2002 until the year of its first record, after which it exits the risk set (absorbing exit). At the 50-cell threshold this yields 8,319 pairs, 185,478 rows and 657 events.

### Climate variables

Monthly temperature surfaces at 10 arc-minutes for 1980–2024 were taken from the WorldClim 2.1 downscaling of CRU TS 4.09^28–29^. We computed four indicators: annual mean temperature, winter mean temperature, warmest-month maximum temperature and coldest-month minimum temperature. Provincial series *T*(*p*,*t*) are area-weighted means over the 100 km analysis grid, weighted by the area of overlap between each grid cell and the province; species-range series *N*(*s*,*t*) are means over the species' Chinese range polygon^30^. Baselines *T*base and *N*base are 1980–2000 means at both ends.

The species-referenced climate gradient is

  *x*(*s*,*p*,*t*) = [*T*(*p*,*t*) − *T*base(*p*)] − [*N*(*s*,*t*) − *N*base(*s*)],

that is, how much more the target province has warmed than the species' own historical range. This is decomposed, strictly backward-looking, into an accumulated component and a residual:

  clim_change(*s*,*p*,*t*) = mean of *x* over [*t* − *W* + 1, *t*],
  clim_var(*s*,*p*,*t*) = *x*(*s*,*p*,*t*) − clim_change(*s*,*p*,*t*),

with *W* ∈ {5, 10, 15, 20} years. Because the surfaces extend back to 1980, no analysis-period rows are lost to the trailing window at any *W*. The main specification uses annual mean temperature with *W* = 15.

### Survey effort

Provincial annual survey effort was compiled from deduplicated eBird/GBIF occurrence records and China Bird Report checklists (http://www.birdreport.cn) and expressed through four proxies: number of visits, number of distinct observers, number of birding days and number of records. eBird checklists for 2024, absent from the original download, were added from a separate GBIF download (https://doi.org/10.15468/dl.vfeeak) with the same visit definition; Guangdong in 2024, where China Bird Report records cover only 14 days, was treated as missing. Thirty-nine province-years (Hong Kong, Macao and Taiwan) have no coverage in the source database. A further 24 mainland province-years were recorded as exactly zero. We treat these as coverage gaps rather than true zeros: in 22 of 24, the adjacent years in the same province record between one and 27 visits. In the main analysis these cells are missing; sensitivity analyses zero-fill them (the previously published treatment) and impute them by within-province linear interpolation on the log scale, which is bounded by the neighbouring observed values. Each proxy is log1p-transformed and standardised within the analysis scope separately for each missing-data rule. Summed over mainland provinces, annual visits rose from a mean of 493 in 2002–2004 to 99,156 in 2022–2024.

### Model

We model the annual hazard that species *s* is first recorded in province *p* in year *t* as a discrete-time proportional-hazards model with a complementary log-log link^21–22,31^:

  log(−log(1 − *h*(*s*,*p*,*t*))) = β₀ + β₁·clim_change_z + β₂·effort_z + β₃·(clim_change_z × effort_z) + β₄·clim_var_z + log *c*(*t*) + *u*ₛ + *v*ₚ + *w*ₚₜ,

with *u*ₛ ~ N(0, σ²species), *v*ₚ ~ N(0, σ²province) and *w*ₚₜ ~ N(0, σ²province×year). All predictors are standardised on the analysis sample, so coefficients are hazard ratios per standard deviation. Models were fitted with glmmTMB 1.1^31^.

Six random-effect structures were compared on four criteria: AIC and BIC; explanatory power (McFadden pseudo-*R*², Nakagawa marginal and conditional *R*²^32^, and marginal and conditional AUC); variance-component identifiability; and the ecological interpretability of each term. The structure reported above was frozen before the robustness analyses were run.

### Resampling and null models

Three design-preserving permutation nulls were constructed, each breaking exactly one association: N1 shuffles accumulated warming among species within each province-year; N2 shuffles survey effort across years within each province; N3 shuffles the event indicator among the species at risk within each province-year. Every null therefore leaves the risk-set size, the per-province-year event count, the marginal distributions of effort and reporting completeness, and the random-effect hierarchy identical to the observed data. Each null was run 199 times and two-sided empirical *P* values were computed from the permutation quantiles. Cluster bootstraps resampled species (392 clusters) and provinces (31 clusters) with replacement, 300 times each; only the resampled grouping variable was renamed, so that the crossed random-effect structure being bootstrapped is preserved. A parametric bootstrap simulated 150 response vectors from the fitted model, including fresh random-effect draws, and refitted. Influence was assessed by refitting with each province, and each of ten randomly assigned species deciles, held out.

A small number of resamples converge to degenerate optima. These leave percentile intervals unaffected but corrupt any statistic based on a mean or a standard deviation, so draws with any |log hazard ratio| exceeding 2 were excluded and their number is reported (3 of 199 in N3; 3 of 300 in the species bootstrap; none elsewhere). Inference is based on percentile quantities throughout. All refits used glmmTMB with `profile = TRUE`, which reduces fit time from 61 to 39 seconds while changing coefficients by less than 10⁻³.

### Diagnostics

Residual diagnostics used simulation-based scaled residuals with 500 simulations^33^: uniformity, dispersion, outliers, zero inflation, and grouped uniformity by year and by province. Spatial autocorrelation was assessed as Moran's *I* on province-mean residuals with inverse-distance weights and a 999-permutation null. Proportional hazards were tested by adding interactions between each focal term and standardised year.

### Projections

CMIP6 four-model ensemble median deltas for annual mean temperature were computed for SSP2-4.5 and SSP5-8.5 at 2030, 2050 and 2080, separately for each province and each species range, and added to both ends of the climate gradient. Effort was grown at 0.30 (SSP2-4.5) and 0.60 (SSP5-8.5) standard deviations per decade. Predictions set the province-by-year random effect to its expectation and the completeness offset to log 1, so the projected quantity is the latent generation hazard. For projection, Guangdong's 2024 effort was carried forward from 2023. Support was defined as the 1st–99th percentile of the fitted accumulated warming and effort; main projection figures aggregate only cells inside this range, and the share of qualifying cells is reported on every panel.

To separate the two scenario axes we also projected the frozen model over a 2 × 2 × 2 grid: SSP2-4.5 or SSP5-8.5 deltas; effort frozen at 2024 or growing at 0.6 SD per decade (observed pace 1.22); horizons 2030 and 2050. Province-by-year effects for future years were set to their expectation, species and province effects retained, and provincial expectations summed over species. Future county surfaces hold the 2024 allocation shares fixed.

### Model-family comparison

The projection comparison used a gradient-boosted model (XGBoost, 400 rounds, learning rate 0.05, depth 4)^34^ on the same three predictors, with exact TreeSHAP attributions^35^. For the cross-validated comparison, a random forest (ranger, 800 trees, class-balanced down-sampling) and XGBoost (300 rounds, learning rate 0.05, depth 5, positive-class weight n₀/n₁) were fitted to the province-level risk set under the main model's four validation schemes with identical folds and to the prefecture- and county-level allocation sets under temporal and leave-one-province splits with within-stratum rank skill. Hyperparameters were fixed, not tuned per fold.

### Direction of new records

Bearings from the centroid of each species' global range (AVONET^23^) to each record, computed as the planar angle of the longitude and latitude differences, were binned into eight 45° sectors. Because a uniform expectation ignores where China lies relative to these centroids, observed sector counts were compared with two Monte Carlo nulls (999 draws) that reassign every record to one of its species' candidate provinces, located at the mean position of that province's new records, with equal probability (geometry) or with probability proportional to the province's 2002–2024 survey visits (geometry + effort). Sector-wise two-sided *P* values were Holm-corrected, and an omnibus χ² against the null expectation was referred to its Monte Carlo distribution. A sensitivity analysis placed each province at a point on its surface.

### Use of generative AI

The authors used Claude (Anthropic) to assist with drafting and editing text, checking numerical consistency and writing figure code; they reviewed and verified all content and take full responsibility for it.

## Data availability

The new-record data analysed in this study are version 2 of the China Bird New Record dataset (CBNR)^20^, openly available under a CC BY 4.0 licence at https://doi.org/10.5281/zenodo.20809949. Nature-reserve boundaries^36^ are openly available at https://doi.org/10.5281/zenodo.14875797. Historical monthly climate (WorldClim 2.1 downscaling of CRU TS 4.09) and CMIP6 projections are publicly available from WorldClim (https://www.worldclim.org). Species range maps^30^ are available on request from BirdLife International (http://datazone.birdlife.org/species/requestdis); their licence does not permit redistribution. Survey-effort indicators were derived from eBird/GBIF occurrence records (2024 records: https://doi.org/10.15468/dl.vfeeak) and China Bird Report checklists (http://www.birdreport.cn); the raw records remain subject to their providers' terms, and the province-year effort panel used in all analyses is provided in the project repository^37^ together with the risk set, the derived climate panels and every result table.

## Code availability

All analysis code (R 4.5.1 with glmmTMB 1.1.14, DHARMa 0.4.7, ranger 0.18.0, xgboost 3.2.1.1, sf 1.0.23 and terra 1.8.86) is available in the project repository^37^ (https://github.com/dingchenchen6/bird-newrecord-discovery-dated) and will be archived with a DOI on Zenodo upon acceptance. Numbered scripts reproduce every number, table and figure from the released inputs; a smoke test re-derives the four main-model coefficients in about two minutes.

## References

1. Parmesan, C. & Yohe, G. A globally coherent fingerprint of climate change impacts across natural systems. *Nature* **421**, 37–42 (2003). https://doi.org/10.1038/nature01286

2. Chen, I.-C., Hill, J. K., Ohlemüller, R., Roy, D. B. & Thomas, C. D. Rapid range shifts of species associated with high levels of climate warming. *Science* **333**, 1024–1026 (2011). https://doi.org/10.1126/science.1206432

3. Lenoir, J. & Svenning, J.-C. Climate-related range shifts – a global multidimensional synthesis and new research directions. *Ecography* **38**, 15–28 (2015). https://doi.org/10.1111/ecog.00967

4. Pecl, G. T. et al. Biodiversity redistribution under climate change: impacts on ecosystems and human well-being. *Science* **355**, eaai9214 (2017). https://doi.org/10.1126/science.aai9214

5. Chen, S. et al. Chinese provincial-level new records for 96 resident bird species reveal poleward range shifts. *Avian Res.* **16**, 100310 (2025). https://doi.org/10.1016/j.avrs.2025.100310

6. Xing, X. et al. Where are the provincial-level new records in China from the past 20 years, and which traits determine their shift directions? *Front. Ecol. Evol.* **12**, 1415268 (2024). https://doi.org/10.3389/fevo.2024.1415268

7. Hughes, A. C. et al. Sampling biases shape our view of the natural world. *Ecography* **44**, 1259–1269 (2021). https://doi.org/10.1111/ecog.05926

8. Tingley, M. W. & Beissinger, S. R. Detecting range shifts from historical species occurrences: new perspectives on old data. *Trends Ecol. Evol.* **24**, 625–633 (2009). https://doi.org/10.1016/j.tree.2009.05.009

9. Hortal, J. et al. Seven shortfalls that beset large-scale knowledge of biodiversity. *Annu. Rev. Ecol. Evol. Syst.* **46**, 523–549 (2015). https://doi.org/10.1146/annurev-ecolsys-112414-054400

10. Diniz-Filho, J. A. F. et al. Macroecological links between the Linnean, Wallacean, and Darwinian shortfalls. *Front. Biogeogr.* **15**, e59566 (2023). https://doi.org/10.21425/F5FBG59566

11. Moura, M. R. & Jetz, W. Shortfalls and opportunities in terrestrial vertebrate species discovery. *Nat. Ecol. Evol.* **5**, 631–639 (2021). https://doi.org/10.1038/s41559-021-01411-5

12. Oliver, R. Y., Meyer, C., Ranipeta, A., Winner, K. & Jetz, W. Global and national trends, gaps, and opportunities in documenting and monitoring species distributions. *PLoS Biol.* **19**, e3001336 (2021). https://doi.org/10.1371/journal.pbio.3001336

13. Boakes, E. H. et al. Distorted views of biodiversity: spatial and temporal bias in species occurrence data. *PLoS Biol.* **8**, e1000385 (2010). https://doi.org/10.1371/journal.pbio.1000385

14. Isaac, N. J. B., van Strien, A. J., August, T. A., de Zeeuw, M. P. & Roy, D. B. Statistics for citizen science: extracting signals of change from noisy ecological data. *Methods Ecol. Evol.* **5**, 1052–1060 (2014). https://doi.org/10.1111/2041-210X.12254

15. Bowler, D. E. et al. Treating gaps and biases in biodiversity data as a missing data problem. *Biol. Rev.* **100**, 50–67 (2025). https://doi.org/10.1111/brv.13127

16. Elith, J., Kearney, M. & Phillips, S. The art of modelling range-shifting species. *Methods Ecol. Evol.* **1**, 330–342 (2010). https://doi.org/10.1111/j.2041-210X.2010.00036.x

17. Mesgaran, M. B., Cousens, R. D. & Webber, B. L. Here be dragons: a tool for quantifying novelty due to covariate range and correlation change when projecting species distribution models. *Divers. Distrib.* **20**, 1147–1159 (2014). https://doi.org/10.1111/ddi.12209

18. Yates, K. L. et al. Outstanding challenges in the transferability of ecological models. *Trends Ecol. Evol.* **33**, 790–802 (2018). https://doi.org/10.1016/j.tree.2018.08.001

19. Ding, C. et al. A dataset of provincial-level new distribution records for birds in China from 2000 to 2025. *Sci. Data* (in review).

20. Ding, C. et al. A dataset of provincial-level new distribution records for birds in China from 2000 to 2025 (China Bird New Record dataset, CBNR), version 2. Zenodo https://doi.org/10.5281/zenodo.20809949 (2026).

21. Allison, P. D. Discrete-time methods for the analysis of event histories. *Sociol. Methodol.* **13**, 61–98 (1982). https://doi.org/10.2307/270718

22. Singer, J. D. & Willett, J. B. It's about time: using discrete-time survival analysis to study duration and the timing of events. *J. Educ. Stat.* **18**, 155–195 (1993). https://doi.org/10.3102/10769986018002155

23. Tobias, J. A. et al. AVONET: morphological, ecological and geographical data for all birds. *Ecol. Lett.* **25**, 581–597 (2022). https://doi.org/10.1111/ele.13898

24. Bebber, D. P. et al. Herbaria are a major frontier for species discovery. *Proc. Natl Acad. Sci. USA* **107**, 22169–22171 (2010). https://doi.org/10.1073/pnas.1011841108

25. Seebens, H. et al. No saturation in the accumulation of alien species worldwide. *Nat. Commun.* **8**, 14435 (2017). https://doi.org/10.1038/ncomms14435

26. Lawless, J. F. Adjustments for reporting delays and the prediction of occurred but not reported events. *Can. J. Stat.* **22**, 15–31 (1994). https://doi.org/10.2307/3315820

27. Hernán, M. A. The hazards of hazard ratios. *Epidemiology* **21**, 13–15 (2010). https://doi.org/10.1097/EDE.0b013e3181c1ea43

28. Harris, I., Osborn, T. J., Jones, P. & Lister, D. Version 4 of the CRU TS monthly high-resolution gridded multivariate climate dataset. *Sci. Data* **7**, 109 (2020). https://doi.org/10.1038/s41597-020-0453-3

29. Fick, S. E. & Hijmans, R. J. WorldClim 2: new 1-km spatial resolution climate surfaces for global land areas. *Int. J. Climatol.* **37**, 4302–4315 (2017). https://doi.org/10.1002/joc.5086

30. BirdLife International & Handbook of the Birds of the World. Bird species distribution maps of the world, version 2024. http://datazone.birdlife.org/species/requestdis (2024).

31. Brooks, M. E. et al. glmmTMB balances speed and flexibility among packages for zero-inflated generalized linear mixed modeling. *R J.* **9**, 378–400 (2017). https://doi.org/10.32614/RJ-2017-066

32. Nakagawa, S. & Schielzeth, H. A general and simple method for obtaining *R*² from generalized linear mixed-effects models. *Methods Ecol. Evol.* **4**, 133–142 (2013). https://doi.org/10.1111/j.2041-210x.2012.00261.x

33. Hartig, F. DHARMa: residual diagnostics for hierarchical (multi-level/mixed) regression models. R package version 0.4 (2024). https://CRAN.R-project.org/package=DHARMa

34. Chen, T. & Guestrin, C. XGBoost: a scalable tree boosting system. In *Proc. 22nd ACM SIGKDD Int. Conf. Knowledge Discovery and Data Mining* 785–794 (2016). https://doi.org/10.1145/2939672.2939785

35. Lundberg, S. M. et al. From local explanations to global understanding with explainable AI for trees. *Nat. Mach. Intell.* **2**, 56–67 (2020). https://doi.org/10.1038/s42256-019-0138-9

36. China Nature Reserve Specimen Resource Sharing Platform. List and vector boundaries of nature reserves in China. Zenodo https://doi.org/10.5281/zenodo.14875797 (2024).

37. Ding, C. Analysis code for 'Warming and survey effort contribute comparably to new bird distribution records when dated to discovery'. GitHub https://github.com/dingchenchen6/bird-newrecord-discovery-dated (2026).

## Acknowledgements

We thank the birdwatchers who contributed observations to eBird and China Bird Report, and the authors of the publications compiled in CBNR. [Funding sources and grant numbers to be added by the authors.]

## Author contributions

[To be completed by the authors using CRediT roles; see CRediT_and_authors_TEMPLATE.md.]

## Competing interests

The authors declare no competing interests.
