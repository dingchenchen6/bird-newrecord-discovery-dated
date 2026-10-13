# Warming and survey effort contribute comparably to new bird distribution records when dated to discovery

Chenchen Ding^1^, et al.

^1^ Institute of Ecology, College of Urban and Environmental Sciences, Peking University, Beijing 100871, China

Correspondence: Chenchen Ding (chenchen.ding@pku.edu.cn)

## Abstract

New provincial distribution records are a primary source of evidence for climate-driven range shifts, yet each record requires a bird, an observer and a publication. We analysed the China Bird New Record dataset (1,029 provincial records, 2000–2025) with a discrete-time hazard model on 175,901 species × province × year cells, dating each record to its discovery and modelling the observation process explicitly. Dating records to publication, the usual practice, inflated the survey-effort hazard ratio by 37% (1.79 versus 1.31) and produced a spurious climate-variability effect. After correction, accumulated warming relative to each species' historical range (hazard ratio 1.36 per standard deviation) and survey effort (1.40) contributed comparably and interacted negatively. Permutation nulls attribute an increment of about 1.18 to species-specific warming beyond shared provincial climate. A province-by-year random effect, which absorbs survey campaigns and other regional pulses, was the largest variance component (×2.23 per standard deviation), and the return on effort fell from 2.18 in 2002 to 1.07 in 2024 while that on warming did not. Documented range gains thus reflect climate and observation in similar measure, and the date attached to a record decides which appears to dominate.

## Introduction

Records of species in places where they had not been documented before are among the most widely used evidence that ranges are shifting with climate^1–4^, and in China, compilations of provincial new bird records have been read as northward and poleward shifts^5–6^. A new record, however, is not an observation of movement. It is the last link in a chain of three events: a species occupies a place, someone detects it there, and the detection is published. Only the first link is ecological, and imperfect detection and uneven sampling can create apparent range changes where none occurred^7–8^.

The difficulty is that observation has grown as quickly as the climate has changed. Documented distributions reflect where people look as well as where organisms live^9–13^, and in mainland China the annual number of birding visits in the main checklist databases rose about 175-fold between 2002–2004 and 2022–2024 (Methods). Any series of new records from these years will correlate with observation whatever the contribution of climate, and opportunistic records yield unbiased trends only when the recording process is modelled^14–15^. Compilations of first records have not been analysed in this way, which leaves three problems open. First, compilations date records by publication, which lags discovery. Because observation grew every year, publication dating credits a record to a year with more observers than the one in which it was made, and it leaves the latest years incomplete. Second, observation grows in pulses, such as survey campaigns, festivals and new reporting platforms, that raise documentation in one province in one year and that models with species and region effects alone cannot represent. Third, a warming effect measured relative to each species' own range needs a benchmark that allows for shared regional climate, and projections of record generation are rarely checked against the conditions to which the models were fitted^16–18^.

We asked whether warming measurably raises the rate at which new provincial bird records are generated once the publication and observation steps are modelled, and how its contribution compares with that of survey effort. Using the China Bird New Record dataset (CBNR), which gives dates of discovery as well as of publication^19–20^, we modelled the annual hazard of a first record in every species × province × year at risk with a complementary log-log link^21–22^. Records were dated to discovery with a completeness offset, effort entered as a covariate and province-year pulses as a random intercept, and warming was evaluated against permutation nulls that preserve the data structure. We tested four predictions, specified before the robustness analyses: (H1) publication dating inflates the effort coefficient and creates a spurious effect of annual climate variability but leaves 15-year accumulated warming unchanged; (H2) province-year pulses are the largest variance component yet leave fixed-effect discrimination unchanged; (H3) warming and effort interact negatively, because where effort has long been high, many of the species that warming favours will already have been recorded; and (H4) the return on effort declines as the stock of detectable but undocumented occurrences is drawn down, whereas the return on warming, which keeps adding candidates as climates shift, does not.

## Results

### The risk set and the dating problem

The released compilation contains 1,029 provincial-level new bird records, with a parseable discovery date for 1,028 (99.9%). Of these, 684 matched a species × province cell in the candidate pool defined by species-distribution models plus forced inclusion of every observed event, and 657 fall within the 2002–2024 analysis window. After requiring non-missing effort and climate components, the modelling data contain 175,901 rows, 649 events, 392 species and 31 provincial units (Supplementary Note S1; Supplementary Table S9). Its spatio-temporal pattern is summarised in Supplementary Fig. S18.

Publication lags discovery by a median of one year and a mean of 2.09; 81.7% lag by at least one year and 26.8% by three or more (Fig. 2a). Re-dating changes the assigned year of 526 of 633 comparable events (83.1%), with a median shift of −1 year and a mean of −1.83 years. The two conventions produce qualitatively different time series (Fig. 2b): the publication-year series rises monotonically to 67 events in 2024, whereas the discovery-year series peaks at 59 in 2019 and falls to 14 in 2024. The former is an artefact of delayed reporting, the latter right-censoring. Because the observed hazard is the true hazard times the reporting completeness *c*(*t*) and the complementary log-log link is logarithmic in the hazard, *c*(*t*) enters exactly as an offset log *c*(*t*), included throughout.

### Publication-year dating inflates the apparent role of survey effort

We decomposed the difference between the previously published specification and the corrected one into five steps (each changing one analytical choice; step S3 also recovers 215 rows and 11 events whose unweighted provincial climate series were missing, so S0–S2 and S3–S5 differ slightly in sample) (Fig. 2c; Supplementary Table S1). Re-dating alone moves the survey-effort hazard ratio from 1.788 to 1.305, so that the publication-year estimate is 37% larger than the corrected one, and moves the annual-variability hazard ratio from 0.850 (*P* = 1.8 × 10⁻⁴) to 0.971 (*P* = 0.48); the accumulated-warming coefficient barely changes (1.394 → 1.437), as H1 predicted. The four remaining corrections (coverage-gap effort, area-weighted climate, the completeness offset and the province-by-year intercept) are smaller, although the completeness offset restores +0.159 by recovering signal that right-censoring had attenuated.

Both shifts follow from the timing of publication. Publication year and the size of the observational database increase together, so a record assigned to its publication year sits in a cell whose recorded effort exceeds the effort that produced the observation, and the record is detached from the weather of the year in which the bird was seen. A 15-year trailing mean of warming barely moves when a record shifts by one or two years.

### Warming and effort contribute comparably

In the frozen main model, both drivers raise the hazard and the effect sizes are similar (Fig. 1a; Table 1). One standard deviation of accumulated warming relative to a species' historical range multiplies the annual hazard by 1.362 (95% CI 1.216–1.524; *P* = 8.3 × 10⁻⁸); one standard deviation of survey effort multiplies it by 1.404 (1.245–1.583; *P* = 2.9 × 10⁻⁸). Annual climate variability has no effect (0.995, 0.909–1.090; *P* = 0.92). The two main effects interact negatively (0.849, 0.761–0.948; *P* = 3.7 × 10⁻³): the marginal effect of warming is steepest where effort is low and flattens where coverage is already dense (Fig. 1b).

The warming coefficient must be read against a benchmark above unity. Permuting warming among species within a province-year, or the event indicator among species at risk, still returns 1.157–1.167, because both permutations preserve the covariance between provincial-annual climate and event counts. The observed 1.362 lies outside that null (*P* = 0.005 for both), but only the increment, about 1.18, is attributable to referencing warming to each species' range. Permuting effort across years within a province instead collapses its hazard ratio to 0.980, so the effort effect arises from the timing of effort within provinces. A province-cluster bootstrap widens the Wald intervals to 1.20–1.72 for warming and 1.21–1.76 for effort; both lower bounds remain above unity.

In natural units, one standard deviation of warming is 0.179 °C: a province warmed by that much more than a species' own historical Chinese range carries a 36% higher annual hazard for it, while one standard deviation of effort is a 7.75-fold increase in annual visits. Much of the variance in the climate variable lies among species within the same province and year, and four importance criteria agree that the two drivers are of comparable weight (Supplementary Note S2; Supplementary Fig. S4).

The discrimination ladder shows the same balance (Fig. 1d): with the random structure fixed, fixed-effect AUC rises from 0.411 for the null model (which contains only the completeness offset and so falls below 0.5) to 0.559 with effort alone, 0.580 with warming alone and 0.610 with both. Climate alone discriminates better than effort alone, and neither approaches the pair; under publication-year dating the order reverses.

### Separating the observation process requires a province-by-year level

We evaluated six random-effect structures against four criteria, of which AIC is only one (Supplementary Table S2; Supplementary Fig. S1). Adding a province-by-year intercept to the conventional species + province structure improves AIC by 93.4 units, raises conditional *R*² from 0.274 to 0.411, raises conditional AUC from 0.721 to 0.854, and raises the intraclass correlation from 0.172 to 0.358. Marginal AUC is flat across all six structures (0.607–0.613), so the added level absorbs observational heterogeneity without redistributing the fixed-effect signal, as H2 predicted. Two random-slope alternatives fit marginally better on AIC but reduce conditional *R*² and leave the fixed effects unchanged, so we freeze the three-level intercept structure (Supplementary Note S3).

The random intercepts have standard deviations of 0.405 for species, 0.326 for province and 0.804 for province by year, so one standard deviation multiplies the hazard by 1.50, 1.39 and 2.23 respectively, and the fitted province-year levels span a thirteenfold range (Fig. 3c). The province-by-year term is the single largest variance component, larger than either fixed effect.

Ecologically, that component is the scale at which the observation process actually operates: a regional survey campaign, a provincial birding festival, a newly established protected area or a new local reporting channel raises the documentation rate for one province in one year, and such shocks are not shared nationally (Supplementary Note S3; Supplementary Table S4). The reporting-completeness offset is a known correction that consumes no degrees of freedom; omitting it attenuates the effort coefficient from 1.372 to 1.245, because censoring is concentrated in the recent, high-effort years.

### Migratory strategy shifts the baseline hazard but moderates neither driver

Migratory strategy shifts the baseline hazard, improving fit by ΔAIC 6.2, but moderates neither driver: warming and effort raise the hazard in residents, partial migrants and long-distance migrants alike, and no interaction with strategy is supported (Supplementary Note S4; Supplementary Table S5; Supplementary Fig. S5).

### Which species, and which provinces

Two traits predict which species yield a new provincial record: partial migrants are about twice as likely as residents (odds ratio 1.91–2.50 across three phylogenetic treatments, all *P* < 0.001), and range area raises the odds by 1.23–1.46 per standard deviation; nine other traits show none. At provincial level, with recent effort as an offset, provinces well covered in 2002–2008 yield fewer records per unit effort (0.71, *P* = 0.028), as do those with higher GDP per capita (0.61, *P* = 0.0027), the hazard model's saturation seen at a coarser scale (Supplementary Note S5; Supplementary Figs S6, S7).

### Records lie slightly north of where geometry and effort place them

Bearings from each species' global range centroid^23^ to its new records are far from uniform (χ² = 580.1, df = 7, *P* = 4.6 × 10⁻¹²¹; Fig. 4a): east holds 237 of 642 records (36.9%) and northeast 179 (27.9%). A uniform expectation is the wrong benchmark, however, because many of these species have ranges centred west or south of China. Reassigning each record at random among its species' candidate provinces reproduces the pattern closely (234.8 records expected to the east and 158.6 to the northeast; χ² = 10.8, Monte Carlo *P* = 0.039; no sector significant after Holm correction). Weighting the candidate provinces by their survey visits reveals a departure that points north (χ² = 25.8, *P* = 0.001): records fall to the northeast and northwest more often, and to the east and south less often, than the distribution of observers predicts (Holm-adjusted *P* = 0.016–0.036), and the three northern sectors hold 40.2% of records against 33.0% expected (Fig. 4b; Supplementary Note S6; Supplementary Tables S11, S12). Among orders, only Passeriformes departs consistently from both nulls. The eastward concentration of raw bearings thus reflects geography; net of geography and effort, new records lie modestly poleward of expectation.

### The return on survey effort is declining

Proportional hazards holds for warming (interaction with time β = −0.022, *P* = 0.82) but not for effort (β = −0.211, *P* = 7.7 × 10⁻⁴). The departure is itself a result: allowing the effort coefficient to vary through time, its hazard ratio falls from 2.18 (95% CI 1.63–2.90) in 2002 to 1.07 (0.88–1.30) in 2024, crossing into non-significance in the early 2020s (Fig. 3d). The warming term shows no such decline, as H4 predicted, although we did not test the two time interactions against each other.

### Robustness

None of the conclusions depends on the analytical choices we were free to vary (Supplementary Note S7; Supplementary Figs S2, S3; Supplementary Table S10). Raising the species-distribution-model threshold from 50 to 200 cells shrinks the risk set to 155,435 rows yet leaves the coefficients fixed (effort 1.404–1.411; warming 1.362–1.376; interaction 0.849–0.851), and all twelve combinations of four effort proxies and three zero-cell rules give effort 1.25–1.52 and warming 1.35–1.37. The structural form of the species-distribution models, the analysis grid and the eight-sector binning were not varied. Across three climate series, the warming coefficient rises with window length, from about 1.16–1.21 at five years to 1.36–1.40 at twenty, with an interior optimum, as expected of a process that integrates climate over years to decades. The pre-specified 15-year window lies within 2.2–5.6 AIC units of the optimum in every series, and the effort coefficient is flat at 1.34–1.41 across the same grid.

### Model adequacy

Simulation-based residual diagnostics indicate a well-calibrated model with no spatial autocorrelation in province-mean residuals; the significant outlier test (95 outliers, *P* < 0.001) is expected of a binary outcome with an event rate of 0.37% (Supplementary Note S8; Supplementary Table S3; Supplementary Figs S8, S9). Design-preserving permutation nulls place every reported coefficient except annual climate variability outside its null distribution; cluster and parametric bootstraps agree that provincial, but not species, clustering inflates the model-based standard errors; and leaving out each province, or each of ten species deciles, shows that no single province or species group carries the result.

### How far can these relationships be projected?

We projected the fitted hazard under CMIP6 SSP2-4.5 and SSP5-8.5 for 2030, 2050 and 2080, applying the four-model ensemble delta to both ends of the climate gradient, and asked how much of each scenario lies inside the range over which the model was fitted (Fig. 5b).

The historical species-specific gradient has a standard deviation of only 0.18 °C, whereas future province-minus-range warming differentials reach 2 °C, more than ten standard deviations beyond the fitted range; only 47.8% of species-province cells fall inside the fitted covariate support under SSP2-4.5 in 2030, 10.4% in 2050 and 2.1% in 2080 (34.2%, 2.1% and 1.9% under SSP5-8.5).

Inside the support the model projects hazard ratios relative to 2024 of 0.79–2.94; unmasked, up to 78. A gradient-boosted model tracks it inside the observed range but diverges outside, agreeing on direction in only 23.7% of cells (Fig. 5c; Supplementary Note S9; Supplementary Figs S10–S12). With climate and effort as independent axes, the climate pathway barely moves the national expectation (23.2 versus 23.1 per year in 2030) whereas continued effort growth more than doubles it by 2050, almost entirely outside the fitted support (Supplementary Fig. S19). Random forest and XGBoost agree with it on where records fall but, on the same scenario grid, stay flat or reverse (Supplementary Note S11; Supplementary Figs S20–S23).

### Records inside nature reserves track the observation process

Twenty-six per cent of new records fall inside the 1,028 mapped nature reserves against a land-area share of 10.4%, an apparent 2.5-fold enrichment. Matching each event to 200 checklist-weighted controls from the same province-year reduces it to 1.57 (1.26–1.96); three features indicate even this residual is largely observational: it rests on 68 reserves, the top two holding 27.3%; it is absent before 2013; and per-visit yield inside is 24% higher. Because within-site bias cannot be conditioned out, we declared in advance that a null would be strong evidence and a positive one weak; 1.57 is an upper bound, and record counts inside reserves should not index reserve performance (Supplementary Note S10; Supplementary Figs S13–S15).

## Discussion

New provincial bird records in China reflect both the movement of birds and the growth of birdwatching, in similar measure. Once records are dated to discovery and observation is modelled explicitly, a standard deviation of warming relative to a species' historical range raises the annual hazard of a first record about as much as a standard deviation of survey effort (hazard ratios 1.36 and 1.40). Which of the two appears to dominate depends on the date: we had expected effort to dominate, and it does, but only under publication-year dating.

Publication dating biases estimates in a predictable direction (H1). Because observation grew every year, a record credited to its publication year sits in a year with more observers than the one in which the bird was found, and the error favours whichever covariate trends with observer numbers. Many biodiversity time stamps share this property, from species descriptions based on specimens collected decades earlier^24^ to the dated first records used to track the accumulation of alien species^25^, and any analysis relating such series to trending covariates is exposed to the same bias. The first remedy is to record the date of observation. Where that is impossible, a completeness offset like ours, the discrete-time counterpart of reporting-delay adjustments in epidemiological surveillance^26^, corrects the expected hazard.

The two drivers also behave differently through time. The return on effort fell from 2.18 to 1.07 over two decades, and provinces that were well surveyed early later yielded fewer records per unit of effort, whereas the return on warming showed no detectable change (H4). We read this as the difference between a stock and a flow: effort draws down a stock of detectable but undocumented occurrences, the Wallacean shortfall^9^, while warming keeps adding to it as climates move relative to species' ranges. The negative interaction (H3) fits the same reading, because where effort has long been high, many of the species that warming favours have already been recorded; depletion of this kind is expected in hazard analyses^27^. Geography offers an alternative, since sparsely surveyed provinces are disproportionately western and montane, where steep gradients may make a given amount of warming more consequential; nor did we test the two time trends against each other. If the reading holds, new-record series will become more informative about climate as the stock is exhausted, provided their dating and the observation process are modelled.

The warming coefficient also needs the right benchmark. Nulls that scramble species identity within province-years centre on 1.157, so the component attributable to referencing warming to each species' own range is about 1.18. Direction makes the same point more sharply: the apparent eastward concentration of new records is what China's position relative to species' global ranges produces by chance, whereas against an effort-weighted null the records lie modestly north of expectation (40.2% in the three northern sectors against 33.0%). Directional readings of new records^5–6^ need such a benchmark.

Projection meets a different limit. By 2080 about 98% of species–province cells lie outside the fitted support, where mechanistic and machine-learning models agree on the direction of change in fewer than a quarter of cells, and the scenario projections apply a period-average effort coefficient that had fallen to 1.07 by 2024. Projections of record generation should report the share of cells inside the fitted support^16–18^; where that share is small, a near-term surface with an explicit support mask is more defensible than a century-scale map.

Several limitations bound these conclusions. The events are published records without an explicit detection model, so the coefficients describe the generation of documented records, and none measures range expansion itself. The province-by-year intercept absorbs provincial climate anomalies as well as survey pulses, which, if anything, biases the warming estimate towards zero. Effort is provincial and annual, the directional nulls place records at province level, the candidate pool rests on species-distribution models whose structure we did not vary, vagrants without established ranges were excluded, and the most recent years remain right-censored. The design is observational, and no coefficient should be read as causal.

For monitoring, a province-year pulse of one standard deviation multiplies the hazard by 2.23, more than either driver, so survey campaigns change the record quickly and should be placed deliberately, preferably where surveys are sparse, which is also where warming raises the hazard most. Because the return on effort has fallen, a plateau in new records does not mean that redistribution has slowed, and records inside reserves track where people watch birds and should not be used to score reserves. Compilers of new-record data can make every later analysis more reliable by publishing both the date of observation and the date of publication for each record.

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

Provincial annual survey effort was compiled from deduplicated eBird/GBIF occurrence records and China Bird Report checklists (http://www.birdreport.cn) and expressed through four proxies: number of visits, number of distinct observers, number of birding days and number of records. Thirty-nine province-years (Hong Kong, Macao and Taiwan) have no coverage in the source database. A further 24 mainland province-years were recorded as exactly zero. We treat these as coverage gaps rather than true zeros: in 22 of 24, the adjacent years in the same province record between one and 27 visits. In the main analysis these cells are missing; sensitivity analyses zero-fill them (the previously published treatment) and impute them by within-province linear interpolation on the log scale, which is bounded by the neighbouring observed values. Each proxy is log1p-transformed and standardised within the analysis scope separately for each missing-data rule. Summed over mainland provinces, annual visits rose from a mean of 493 in 2002–2004 to 86,380 in 2022–2024.

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

CMIP6 four-model ensemble median deltas for annual mean temperature were computed for SSP2-4.5 and SSP5-8.5 at 2030, 2050 and 2080, separately for each province and each species range, and added to both ends of the climate gradient. Effort was grown at 0.30 (SSP2-4.5) and 0.60 (SSP5-8.5) standard deviations per decade. Predictions set the province-by-year random effect to its expectation and the completeness offset to log 1, so the projected quantity is the latent generation hazard. Support was defined as the 1st–99th percentile of the fitted accumulated warming and effort; main projection figures aggregate only cells inside this range, and the share of qualifying cells is reported on every panel.

To separate the two scenario axes we also projected the frozen model over a 2 × 2 × 2 grid: SSP2-4.5 or SSP5-8.5 deltas; effort frozen at 2024 or growing at 0.6 SD per decade (observed pace 1.19); horizons 2030 and 2050. Province-by-year effects for future years were set to their expectation, species and province effects retained, and provincial expectations summed over species. Future county surfaces hold the 2024 allocation shares fixed.

### Model-family comparison

The projection comparison used a gradient-boosted model (XGBoost, 400 rounds, learning rate 0.05, depth 4)^34^ on the same three predictors, with exact TreeSHAP attributions^35^. For the cross-validated comparison, a random forest (ranger, 800 trees, class-balanced down-sampling) and XGBoost (300 rounds, learning rate 0.05, depth 5, positive-class weight n₀/n₁) were fitted to the province-level risk set under the main model's four validation schemes with identical folds and to the prefecture- and county-level allocation sets under temporal and leave-one-province splits with within-stratum rank skill. Hyperparameters were fixed, not tuned per fold.

### Direction of new records

Bearings from the centroid of each species' global range (AVONET^23^) to each record, computed as the planar angle of the longitude and latitude differences, were binned into eight 45° sectors. Because a uniform expectation ignores where China lies relative to these centroids, observed sector counts were compared with two Monte Carlo nulls (999 draws) that reassign every record to one of its species' candidate provinces, located at the mean position of that province's new records, with equal probability (geometry) or with probability proportional to the province's 2002–2024 survey visits (geometry + effort). Sector-wise two-sided *P* values were Holm-corrected, and an omnibus χ² against the null expectation was referred to its Monte Carlo distribution. A sensitivity analysis placed each province at a point on its surface.

### Use of generative AI

The authors used Claude (Anthropic) to assist with drafting and editing text, checking numerical consistency and writing figure code; they reviewed and verified all content and take full responsibility for it.

## Data availability

The new-record data analysed in this study are version 2 of the China Bird New Record dataset (CBNR)^20^, openly available under a CC BY 4.0 licence at https://doi.org/10.5281/zenodo.20809949. Nature-reserve boundaries^36^ are openly available at https://doi.org/10.5281/zenodo.14875797. Historical monthly climate (WorldClim 2.1 downscaling of CRU TS 4.09) and CMIP6 projections are publicly available from WorldClim (https://www.worldclim.org). Species range maps^30^ are available on request from BirdLife International (http://datazone.birdlife.org/species/requestdis); their licence does not permit redistribution. Survey-effort indicators were derived from eBird/GBIF occurrence records and China Bird Report checklists (http://www.birdreport.cn); the raw records remain subject to their providers' terms, and the province-year effort panel used in all analyses is provided in the project repository^37^ together with the risk set, the derived climate panels and every result table.

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

14. Bowler, D. E. et al. Treating gaps and biases in biodiversity data as a missing data problem. *Biol. Rev.* **100**, 50–67 (2025). https://doi.org/10.1111/brv.13127

15. Isaac, N. J. B., van Strien, A. J., August, T. A., de Zeeuw, M. P. & Roy, D. B. Statistics for citizen science: extracting signals of change from noisy ecological data. *Methods Ecol. Evol.* **5**, 1052–1060 (2014). https://doi.org/10.1111/2041-210X.12254

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
