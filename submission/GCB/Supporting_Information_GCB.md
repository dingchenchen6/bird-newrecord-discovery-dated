# Supporting Information



**Warming and survey effort contribute comparably to new bird distribution records when dated to discovery**



Chenchen Ding, et al.



## Supplementary Notes

### Supplementary Note S1. Publication-lag stationarity and the reporting-completeness offset

The released compilation contains 1,029 provincial-level new bird records with a parseable discovery date for 1,028 (99.9%). Of these, 684 could be matched to a species × province cell in the candidate pool defined by species-distribution models plus forced inclusion of every observed event; 657 fall within the 2002–2024 analysis window (Table S7). Twenty-six records were discovered before 2002 and therefore describe species already present at the start of the window; because such pairs are prevalent rather than incident cases, we removed them from the risk set entirely rather than treating them as censored. Conversely, eleven species × province pairs whose records were published in 2025 but discovered by 2024 re-enter the analysis under discovery-year dating; under publication-year dating they had been lost beyond the window edge.

Publication lags discovery by a median of one year and a mean of 2.09 years; 81.7% of records lag by at least one year and 26.8% by three or more (Figure 2a). Re-dating changes the assigned year of 526 of 633 comparable events (83.1%), with a median shift of −1 year and a mean of −1.83 years. The two dating conventions produce qualitatively different time series (Figure 2b): the publication-year series rises monotonically to 67 events in 2024, whereas the discovery-year series peaks at 59 in 2019 and falls to 14 in 2024. Neither series is a clean description of reality: the publication-year rise is an artefact of aggregating delayed reports, and the discovery-year fall is right-censoring, because records made in 2023–2024 have not yet appeared in print.

We quantified the censoring directly. The compilation extends to publications appearing in 2025, so a record discovered in year *t* can only have been observed if its lag is at most 2025 − *t*. Using the pooled empirical lag distribution, the expected share of discoveries already reported falls from 99.7% for 2002 to 89.5% for 2021, 83.4% for 2022, 73.2% for 2023 and 56.7% for 2024. The pooled distribution is justified because publication lag is stationary over the study period (Spearman correlation between discovery year and lag ρ = −0.016, *P* = 0.685; Wilcoxon comparison of 2002–2010 with 2011–2018 *P* = 0.851; cumulative distributions differ by at most three percentage points at every lag). Because the observed hazard under incomplete reporting is approximately the product of the true hazard and the completeness *c*(*t*), and the complementary log-log link is logarithmic in the hazard, *c*(*t*) enters the linear predictor exactly as an offset log *c*(*t*). We include this offset throughout.

The final risk set at the 50-cell species-distribution-model threshold comprises 8,319 species × province pairs, 185,478 species-province-years and 657 events. After requiring non-missing effort and climate components, the modelling data contain 175,640 rows, 649 events, 392 species and 31 provincial units. The spatial and temporal pattern of the released compilation (dense in the east and south, sparse but not empty in the west, and rising roughly ninefold in annual count between 2002–2004 and 2022–2024) is summarised in Fig. S16.

Let *F* be the empirical cumulative distribution of non-negative publication lags and *P*max = 2025 the latest publication year in the compilation. A record discovered in year *t* can have appeared only if its lag is at most *P*max − *t*, so the expected share of year-*t* discoveries already reported is *c*(*t*) = *F*(*P*max − *t*). We verified that lag is stationary across discovery years using Spearman correlation and a Wilcoxon comparison of the first and second halves of the well-reported period (2002–2018), and by comparing the cumulative distributions directly. Under incomplete reporting the observed hazard is approximately *c*(*t*)·*h*(*t*); with a complementary log-log link this is exactly an offset, log(−log(1 − *p*obs)) = η + log *c*(*t*), which we include in every model. Sensitivity analyses omitting the offset and truncating the window at 2021 are reported.

### Supplementary Note S2. Migratory stratification

New provincial records could plausibly arise by different routes in different migratory strategies. Residents disperse slowly, so a first record should more often mark a genuine boundary shift. Long-distance migrants are highly mobile and can appear far outside their range as vagrants or storm-displaced individuals, processes driven by navigation error and weather rather than by decadal warming at the destination, and they are visible only on passage. We therefore tested whether migratory strategy moderates either driver (Fig. S3; Table S3).

The analysis uses the three groups with a known strategy: 137 resident, 72 partial-migrant and 107 long-distance-migrant species, carrying 218, 156 and 175 events respectively. Species whose strategy is unrecorded are excluded rather than treated as a fourth category: their event rate is 0.792% against 0.29–0.42% in the other groups, and they hold a third as many risk-set rows per species, because a species without trait data entered the candidate pool only by virtue of having a record. That is a selection artefact, not an ecological class.

Migratory strategy shifts the baseline hazard: adding it as a main effect improves fit (ΔAIC 6.2 relative to the model without it) and is the best model in the ladder. It does not, however, moderate either driver. Adding warming × strategy, effort × strategy, both, or the full three-way warming × effort × strategy each *worsens* AIC, and none is supported by a likelihood-ratio test (*P* = 0.692, 0.638, 0.792 and 0.260 respectively).

Fitting each group separately gives the same picture (Fig. S3b). Accumulated warming raises the hazard in every group: 1.363 (95% CI 1.158–1.604) in residents, 1.511 (1.243–1.837) in partial migrants and 1.512 (1.264–1.809) in long-distance migrants. So does survey effort, at 1.287, 1.338 and 1.333. The confidence intervals overlap almost completely, as the formal tests imply. Our prior expectation that warming would matter least for long-distance migrants was not borne out: their point estimate is the highest of the three, though indistinguishable from the others. The stratified fits use a reduced random structure of species and province intercepts, because 688 province-year levels are not identifiable from 156–218 events; the ladder, which uses all 549 events, retains the full structure.

One pattern is worth flagging without claiming it. The warming × effort interaction is confined to long-distance migrants (0.752, 0.627–0.902, *P* = 0.0022) and is absent in residents (0.941, *P* = 0.53) and partial migrants (1.029, *P* = 0.78). But the test that matters for this claim is whether the groups differ, and it is not significant: the three-way likelihood-ratio test gives *P* = 0.260 and the long-distance-versus-resident contrast *P* = 0.079. With at most 218 events per group the design cannot resolve group differences in an interaction term, so we report this as a hypothesis for a larger compilation rather than as a result (Fig. S3d).

### Supplementary Note S3. Species-level and province-level companion analyses

The hazard model asks what governs the risk that a given species is recorded in a given province in a given year. Two complementary questions operate at coarser levels: which species are more likely to yield a new provincial record at all, and which provinces accumulate more of them. We address both following the framework of the companion mammal study, adapted to birds (Figs 9, 10; Tables 7, 8).

*Species level.* The pool is the 1,445 Chinese bird species of the national ecological trait database, of which 1,312 match the dated Clements phylogeny and 361 acquired at least one new provincial record; these carry 636 of the 657 events, the remainder belonging to 13 species that are post-2022 taxonomic splits absent from the pool. Traits come from three sources in order of precedence: the Chinese database for body mass, morphometrics, multi-category diet, clutch size, nest type and site, flocking, migratory status and endemism; BIRDBASE for habitat breadth (the number of major habitats used), diet breadth (the number of major food types consumed) and IUCN status; and AVONET for the hand-wing index and global range area. Phylogenetic non-independence is handled with the tree itself, using phylogenetic logistic regression (Ives & Garland, estimated α = 0.60), with taxonomic nesting and phylogenetic eigenvector regression as coarser alternatives to confirm that nothing depends on the choice.

Two effects hold under all three treatments (Fig. S4a, b, d). Partial migrants are about twice as likely as residents to yield a new provincial record (odds ratio 1.89–2.50 across treatments, all *P* < 0.001), and range size raises the odds by 1.23–1.46 per standard deviation. This converges with the hazard model from a different direction: partial migrants also carry the highest raw event rate there (0.418% against 0.29–0.33%). Body mass, clutch size, habitat breadth, diet breadth, number of congeners, hand-wing index, IUCN status, endemism and trophic niche are all null, in contrast to the mammal study, where smaller-bodied, nocturnal and data-deficient species were more likely to be newly recorded.

Pooling all species conceals two group-specific patterns that a stratified fit recovers (Fig. S4alt a, b; Table S6). Splitting taxonomically, range size acts within Passeriformes (1.53, *P* = 0.0020) but not within non-passerines, whereas the partial-migrant effect is present in both and is stronger outside the passerines (3.19, *P* = 3.3 × 10⁻⁴, against 2.01, *P* = 0.0081). Splitting instead by migratory strategy is more revealing. Among residents only range size matters (1.60, *P* = 0.0042). Among full migrants neither range size nor migratory class can act, and two traits that are null in the pooled model become significant: the hand-wing index, a standard index of dispersal ability, *lowers* the odds (0.51, *P* = 3.8 × 10⁻⁴), and body mass raises them (1.74, *P* = 0.0037). Both fit a vagrancy mechanism. A migrant with poor flight efficiency is more easily displaced off its normal route, and a large-bodied bird sitting far outside its range is more likely to be noticed and reported. The pooled model averages these against residents, for whom neither applies, and returns zero for both.

*Imputed traits.* Trait gaps were filled by random forest, but the out-of-bag error for continuous traits is no better than mean imputation (NRMSE 1.00; the categorical error is acceptable at PFC 0.11), so imputed values are flagged per trait and should not be treated as equivalent to measured ones. Only 51 of the 1,298 modelled species (3.9%) carry an imputed value among the main-model traits, and 12 of those have a record. Refitting without them leaves the conclusions intact. Of the 20 terms, 17 retain the same sign and significance, and all three significant effects survive: range size 1.456 → 1.309 (*P* 1.1 × 10⁻⁴ → 4.5 × 10⁻³), partial migrant 1.889 → 2.200 (9.7 × 10⁻⁴ → 6.5 × 10⁻⁵), open habitat 0.541 → 0.598 (2.1 × 10⁻³ → 1.1 × 10⁻²). One caveat belongs with this: on the reduced subset the phylogenetic logistic regression reports α at its upper bound and fails to converge cleanly. The full model's α of 0.597 is already close to that bound of 0.620, which indicates weak phylogenetic signal at this scale rather than a problem specific to the subset. We therefore repeated the sensitivity under taxonomic nesting and phylogenetic eigenvectors, which converge normally and return the same two headline effects (partial migrant 2.59 and 2.57, both *P* < 5 × 10⁻⁶; range size 1.22, *P* = 0.041).

Range size must be measured as an **area**, not as a count of provinces occupied (Fig. S4c; Table S4). Both area measures are independent of the response and agree: global range area gives an odds ratio of 1.456 (95% CI 1.204–1.762, *P* = 1.1 × 10⁻⁴, n = 1,298) and Chinese range area, taken from BirdLife polygons clipped to China, gives 1.653 (1.420–1.925, *P* = 9.0 × 10⁻¹¹, n = 1,003). The count of provinces occupied does not qualify: the trait database was published in 2022 and its provincial counts therefore already contain the 2002–2021 records used as the response. Species with a new record occupy a median of 14 provinces against 4 for those without, that variable returns an odds ratio of 2.09 (*P* = 5 × 10⁻¹⁵), and it absorbs the area effect entirely when both are entered (area 0.96, *P* = 0.70). We report only the area measures.

*Province level.* Counts of new records per province are overdispersed relative to Poisson (dispersion 5.59, *P* = 2.8 × 10⁻¹⁷); a negative binomial is adequate (1.23, *P* = 0.20, θ = 6.12) and passes simulation-based diagnostics (Fig. S5a; Table S5). In the count model only regional species richness is significant (incidence rate ratio 1.27, *P* = 0.035). The informative model is the one that treats recent survey effort as an offset, so that the response becomes the discovery rate per unit of effort: there, provinces already well covered in 2002–2008 yield fewer records per unit of recent effort (0.70, *P* = 0.023), as does higher GDP per capita (0.61, *P* = 0.0026) (Fig. S5b). Hierarchical partitioning attributes 51.2% of the explained deviance to species richness, 32.9% to area and 9% to the two effort terms combined, with the full model explaining 20.6% of deviance (Fig. S5c).

Effort therefore appears at the provincial scale not as a count effect but as diminishing returns; the hazard model shows the same signal as an effort coefficient that falls through time. Two analyses at different levels, on different response variables, converge on the conclusion that China's observational capacity is now large enough that additional effort recovers progressively less of what remains undocumented.

One adaptation must be stated. The mammal study measured historical survey effort as publication counts for 1949–2000. No bird analogue exists in these data: the observation database holds seven reports before 2000 and 29 of 31 provinces have none. Early (2002–2008) and recent (2009–2024) coverage therefore take that role, which preserves the question of whether provinces already well covered show diminishing returns, but on a shorter timescale than the original.

### Supplementary Note S4. Resampling and null models: implementation detail

Three design-preserving permutation nulls were constructed, each breaking exactly one association: N1 shuffles accumulated warming among species within each province-year; N2 shuffles survey effort across years within each province; N3 shuffles the event indicator among the species at risk within each province-year. Every null therefore leaves the risk-set size, the per-province-year event count, the marginal distributions of effort and reporting completeness, and the random-effect hierarchy identical to the observed data. Each null was run 199 times and two-sided empirical *P* values were computed from the permutation quantiles. Cluster bootstraps resampled species (392 clusters) and provinces (31 clusters) with replacement, 300 times each; only the resampled grouping variable was renamed, so that the crossed random-effect structure being bootstrapped is preserved. A parametric bootstrap simulated 150 response vectors from the fitted model, including fresh random-effect draws, and refitted. Influence was assessed by refitting with each province, and each of ten randomly assigned species deciles, held out.

A small number of resamples converge to degenerate optima. These leave percentile intervals unaffected but corrupt any statistic based on a mean or a standard deviation, so draws with any |log hazard ratio| exceeding 2 were excluded and their number is reported (3 of 199 in N3; 3 of 300 in the species bootstrap; none elsewhere). Inference is based on percentile quantities throughout. All refits used glmmTMB with `profile = TRUE`, which reduces fit time from 61 to 39 seconds while changing coefficients by less than 10⁻³.



Simulation-based residual diagnostics indicate a well-calibrated model (Fig. S9; Table S1). Scaled residuals are uniform (Kolmogorov–Smirnov *P* = 0.86), dispersion is correct (*P* = 0.51) and there is no zero inflation (*P* = 0.52). None of 23 year levels and three of 31 province levels show within-group deviation at *P* < 0.05, consistent with the nominal rate. Province-mean residuals show no spatial autocorrelation (Moran's *I* = −0.042 against an expectation of −0.033; permutation *P* = 0.76). The outlier test is significant (86 outliers, *P* < 0.001), as is expected of a binary outcome with an event rate of 0.37%; we report it for completeness rather than as evidence of misspecification.

Three resampling analyses complete the assessment (Fig. S11). Three design-preserving permutation nulls, each destroying exactly one association while holding the risk set, the per-province-year event counts, the effort and completeness marginals and the random-effect hierarchy fixed, place every reported coefficient outside its null distribution except annual climate variability, which is null under the design as it is in the fitted model (*P* = 0.08 and 0.41). A cluster bootstrap of 300 resamples shows that provincial clustering inflates the standard errors by a factor of 1.30–1.53 relative to the model-based values, whereas species clustering does not (0.89–1.19); Table 2 (main text) therefore reports both intervals. A parametric bootstrap of 150 simulations recovers the coefficients with absolute bias below 0.01 on the log-hazard scale and gives actual coverage of 92.0–93.3% for the nominal 95% interval, consistent with the cluster result. Leaving out each province in turn, and each of ten species deciles, moves the coefficients by at most 3.9%, with 9 of 164 combinations exceeding 3%: no single province or species group carries the result.

The proportional-hazards assumption holds for the focal climate term: the interaction between accumulated warming and time is negligible (β < 0.001, *P* = 1.00). It does not hold for effort (β = −0.190, *P* = 2.1 × 10⁻³), which is a substantive result rather than a diagnostic failure: the marginal return of an additional standard deviation of survey effort has declined over 2002–2024, consistent with the progressive saturation of easily detectable gaps. In a model that allows both effects to vary through time, the fixed effects are unchanged in direction and magnitude (effort 1.549, warming 1.366, variability 0.996), and only the interaction loses significance (0.838, *P* = 0.06).

### Supplementary Note S5. Robustness of the climate signal to window, baseline, source and indicator

The conclusions do not depend on any freely chosen analytical decision (Figure 3).

*Species-distribution-model threshold.* A province enters a species' candidate pool when the species distribution model marks at least a threshold number of suitable cells inside it. Cells are those of the 2.5-arc-minute climate surface and have a median area of 18.3 km², so thresholds of 50, 100 and 200 cells correspond to roughly 0.9, 1.8 and 3.7 thousand km² of suitable habitat. Raising the requirement from 50 to 200 cells changes the risk set from 175,640 to 155,207 rows but leaves the coefficients essentially fixed (effort 1.429, 1.431, 1.437; warming 1.365, 1.379, 1.375; interaction 0.839, 0.840, 0.839).

*Climate indicator.* Annual mean temperature carries the signal; warmest-month maximum temperature carries a weaker version of it (hazard ratio 1.30, ΔAIC 10.4 behind the best cell) but shows no interaction with effort; coldest-month minimum temperature and winter mean temperature show no signal at any window (hazard ratios 0.96–1.08, all *P* > 0.11). Annual mean temperature integrates the whole thermal regime, whereas seasonal extremes describe conditions that constrain overwintering or breeding but not the year-round climatic envelope within which a range boundary sits.

*Accumulation window and climate baseline.* Both are analyst choices rather than data-determined ones, so we tested them jointly at windows of 5, 10, 15 and 20 years against the two baselines in common use for this kind of anomaly, 1980–2000 and 1970–2000 (Fig. S2).

The 1970–2000 baseline cannot be computed from the WorldClim 2.1 downscaling used in the main analysis, which begins in 1980. We therefore rebuilt the entire climate chain from CRU TS 4.09 at its native 0.5°, which reaches back to 1901, and fitted *both* baselines on it. This separates two things that would otherwise be confounded: comparing WorldClim 1980–2000 with CRU 1980–2000 isolates the effect of changing data source and resolution, and comparing CRU 1980–2000 with CRU 1970–2000 isolates the effect of the baseline period itself.

Three results follow, and each has an ecological reading rather than being merely a robustness statement.

First, the warming coefficient rises with window length in every series, from about 1.16–1.22 at five years to 1.38–1.40 at twenty years (Fig. S2a). This is the signature expected of a process that integrates climate over years to decades: a five-year window measures weather rather than climate and dilutes the signal, whereas a boundary shifts only when conditions have been favourable long enough for colonisation and establishment. A finer grid spanning 3 to 23 years (Table S8) places the optimum at 18–20 years with AIC rising again by 23 years, so the optimum is interior rather than an artefact of the tested range. We retain 15 years as pre-specified; it lies within 2.1–6.0 AIC units of the optimum in every series.

Second, the effort coefficient is flat at 1.37–1.43 across all twelve combinations (Fig. S2b), and the interaction is negative throughout (0.82–0.96; Fig. S2c). If the climate and effort terms were competing for the same variance, changing the climate specification would move the effort estimate. It does not, which is direct evidence that the two are separately identified.

Third, the choice between the two baselines is immaterial, and if anything the longer one strengthens the result: at *W* = 15 the hazard ratio is 1.366 under CRU 1970–2000 against 1.319 under CRU 1980–2000, and the main WorldClim 1980–2000 estimate of 1.365 sits between the two. Changing data source and resolution moves the estimate by a similar small amount (1.365 to 1.319), so neither choice is decisive. One caveat follows from the resolution difference and matters for interpretation: because the 0.5° CRU grid smooths the sub-grid topographic variation that the 10-arc-minute downscaling retains, one standard deviation of accumulated warming is 0.058 °C in the CRU series against 0.179 °C in the main one. Standardised hazard ratios remain comparable, but the natural-unit statements in this paper refer to the main, higher-resolution series.

*Effort proxy and missing-data rule.* All twelve combinations of four proxies (visits, observers, birding days, records) and three treatments of the 24 implausible zero cells (coverage gap, bounded within-province interpolation, zero-filling) give effort hazard ratios between 1.25 and 1.55 and warming hazard ratios between 1.33 and 1.39. Because the three missing-data rules yield different sample sizes, AIC is not comparable across them and we compare coefficients only. The coverage-gap interpretation is strongly supported by the data: in 22 of the 24 cells flagged as structural zeros, the immediately adjacent years within the same province record between one and 27 visits, so these are gaps in database coverage rather than years in which birdwatching ceased.

### Supplementary Note S6. Records inside nature reserves: design, estimand ladder and limits

Twenty-six per cent of new records fall inside one of the 1,028 mapped Chinese nature reserves, against a land-area share of 10.4%. This apparent 2.5-fold enrichment would ordinarily be read as evidence that the reserve network is receiving redistributing species. We tested that reading against the observation process directly, using 2.86 million GBIF/eBird checklists (172,079 checklists at 43,571 distinct locations, 2002–2023) to define availability as *where birdwatchers actually went*. Each event was matched to 200 control locations drawn from the same province and year, weighted by the checklists recorded there, and analysed by conditional logistic regression (Fig. S12).

Nationally, birding effort is not concentrated in reserves: the checklist-weighted share inside reserves is 10.8%, indistinguishable from the area share. Conditioning on province and year, the enrichment falls from 2.5-fold to an odds ratio of 1.71 (95% CI 1.39–2.11), and to 1.57 (1.26–1.96) after adding elevation, longitude and two bioclimatic covariates. The distance analogue is consistent (0.82 per standard deviation of log distance to the nearest reserve, 0.75–0.90).

Three features of the residual association argue that it too is largely observational. First, it is carried by very few sites: the 172 inside-reserve events fall in only 68 reserves (6.6% of the 1,028), the top two account for 27.3%, and a block bootstrap resampling host reserves rather than records widens the interval to 0.89–3.19. Dropping the two largest hosts leaves 1.16 (0.92–1.47). Second, it is confined to the period of rapid growth in birdwatching: the odds ratio is 2.05 (1.61–2.59) for 2013–2023 but 0.97 (0.62–1.50) for 2002–2012, although the mapped reserve network gained no area after 2012. Third, checklists made inside reserves record 18.9 species on average against 15.3 outside, a 24% difference in per-visit yield that stratification by province and year cannot remove. Two competing explanations were tested and rejected: the enrichment is not driven by professional survey work (inside-reserve share is 28.5% for birdwatching-type discoveries, 26.3% for specimen, camera-trap and ringing discoveries), and it is not an artefact of coordinate precision (the share rises smoothly from 26.2% to 37.6% across 0–5 km buffers, with no threshold jump).

Because within-site observation bias cannot be conditioned out, we treat the inference as asymmetric and state the rule in advance: a null result would be strong evidence, a positive result weak. The odds ratio of 1.57 is therefore an upper bound on any ecological contribution, and the operational conclusion is that counts of new records inside reserves should not be used as an indicator of reserve performance.

Whether a first record becomes a persistent presence is unrelated to reserve status. Using subsequent detections of the same species in the same province in the checklist layer, 41.1% of first records were re-detected at least once and 22.5% in three or more later years. Subsequent survey effort grew from 148 checklists province-wide in 2002 to 14,974 in 2023 and dominates re-detection. Once it is controlled for, the inside-versus-outside odds ratios are 1.01 (0.62–1.64) and 1.10 (0.61–1.99) (Fig. S13). The confidence intervals are slightly wider than our pre-declared equivalence bounds of 0.67–1.5, so we report no detectable difference rather than equivalence. These figures also give the first empirical handle on the vagrancy objection: provincial first records are not predominantly vagrants, but neither are they predominantly colonisations.

Finally, the reserve network shows no measurable mismatch with observed warming, contrary to a widely repeated expectation. The warming fields distributed with the gridded panel are provincial values broadcast to cells, with only 31 distinct values nationally. With warming recomputed at the cell level from CRU TS 4.09 instead, the area-weighted reserve coverage across warming quintiles ranges only from 8.5% to 11.8%, a 1.2-fold spread, against the 8.5-fold spread the broadcast field implies (Fig. S14a). An area-weighted fractional logit gives β = −0.022 (−0.107 to 0.063, P = 0.61), and permuting coverage 999 times within province × 500 m elevation strata places the observed within-stratum correlation (ρ = −0.013) squarely inside the null envelope (P = 0.48). What the network does lack is monitoring: crossing the upper tercile of warming with the lower tercile of recent birding effort identifies 39.3 × 10⁴ km² inside existing reserves, where standardised monitoring could be grafted onto existing management, and 160.3 × 10⁴ km² outside any mapped reserve, where new survey capacity would be required.

All statements in this section apply only to the 1,028 mapped, predominantly national-level reserves established before 2012; the vector layer excludes the national parks designated from 2021, nature parks, and the ecological conservation red lines. Because reserve status has almost no temporal variation within the study window (none of the 172 inside-reserve events pre-dates its host reserve's designation), we make no causal claim and report no before–after or difference-in-differences estimate.

---

### Supplementary Note S7. Model families, prediction scales and independent climate × effort scenarios

Treating climate and survey effort as independent scenario axes separates their influence on future record generation (Fig. S17). With effort frozen at its 2024 level, switching from SSP2-4.5 to SSP5-8.5 leaves the national expectation essentially unchanged (26.1 versus 25.9 first records per year in 2030; 26.8 versus 26.9 in 2050). Allowing effort to keep growing at 0.6 SD per decade (half the observed 2002–2024 pace) raises the 2050 expectation to 79–89 records per year, but no species–province cell then remains inside the fitted covariate support, against 38–43% under frozen effort. The projected record stream is therefore governed by the survey-effort scenario rather than the climate scenario, and the effort-driven increase lies entirely outside the range in which the model can be trusted.

Two further tree-ensemble families fitted under identical validation designs behave like the gradient-boosted model: a random forest and XGBoost lead the mechanistic model on leave-species folds (PR-AUC 0.0113 and 0.0103 versus 0.0060) but fall behind it on temporal forward-prediction (0.0067 and 0.0070 versus 0.0098) and on leave-one-province allocation at county level (rank percentile 0.31 and 0.35 versus 0.28; Fig. S18). The three families nevertheless agree on where the next records will fall: Spearman ρ between their 2024 prediction surfaces is 0.59–0.89 across province, prefecture and county (Fig. S19). Run through the same scenario grid, however, the families diverge sharply in how much scenarios matter (Fig. S20 and Fig. S21). After calibrating all three to the same 2024 national total (24.4 records per year), the mechanistic model rises to 79.3 records per year under SSP2-4.5 with continued effort growth in 2050, whereas the random forest stays locked at 23.9 and XGBoost falls to 7.4. Both ensembles return boundary leaf values once year and effort leave the training range, so their projected trend, flat in one case and reversed in the other, is an artefact of the algorithm rather than an estimate that the data can adjudicate.

The projection comparison used a gradient-boosted model (XGBoost, 400 rounds, learning rate 0.05, depth 4) (Chen & Guestrin, 2016) on the same three predictors, with exact TreeSHAP attributions (Lundberg et al., 2020). For the cross-validated comparison, a random forest (ranger, 800 trees, class-balanced down-sampling) and XGBoost (300 rounds, learning rate 0.05, depth 5, positive-class weight n₀/n₁) were fitted to the province-level risk set under the main model's four validation schemes with identical folds and to the prefecture- and county-level allocation sets under temporal and leave-one-province splits with within-stratum rank skill. Hyperparameters were fixed, not tuned per fold.

## Supplementary Tables

### Supplementary Table S1. Model adequacy checks

Model adequacy.

| Check | Statistic | *P* | Reading |
|---|---|---|---|
| KS uniformity | 0.0014 | 0.86 | calibrated |
| Dispersion | 0.946 | 0.51 | correct |
| Zero inflation | 1.000 | 0.52 | none |
| Outliers | 86 | < 0.001 | expected at 0.37% event rate |
| Grouped by year | 0 of 23 levels | 0.07 | at nominal rate |
| Grouped by province | 3 of 31 levels | 0.027 | at nominal rate |
| Moran's *I* | −0.042 | 0.76 | no spatial structure |
| PH: warming × time | 0.000 | 1.00 | assumption holds |
| PH: effort × time | −0.190 | 2.1 × 10⁻³ | effort returns decline |

### Supplementary Table S2. Ecological rationale for every component of the main model

Ecological rationale for every component of the main model. Each row states why the
component is in the model, what its estimate means, and one falsifiable prediction the
specification implies. All predictions are tested in the paper. The full version, with the
prediction column, is `tables/tbl_v2_ecological_rationale.csv` and `docs/ECOLOGICAL_RATIONALE.md`.

| Component | Why it is in the model | What the estimate means |
|---|---|---|
| Response: first record only | A species-province pair can acquire a first record once; treating re-documentation as new information would inflate the event count | The annual probability of crossing from undocumented to documented |
| cloglog link | Discrete-time analogue of proportional hazards; coefficients are hazard ratios and do not depend on the length of the time step | exp(β) is directly comparable with survival-analysis literature |
| Risk set with absorbing exit | Only species whose modelled range approaches a province are plausible candidates; pairs recorded before 2002 are prevalent, not incident, cases | Hazard conditional on being a plausible, not-yet-recorded candidate |
| Accumulated warming, *W* = 15 yr | Range boundaries integrate climate over years to decades; referencing to the species' own range is essential because absolute warming is near-uniform across China | HR 1.365 per 0.179 °C of province-minus-range warming |
| Annual variability | Separates decadal signal from year-to-year weather, so neither term can absorb the other | HR 0.995: weather in the discovery year adds nothing |
| Survey effort | A species can only be recorded where someone is looking; required for the climate coefficient to be interpretable | HR 1.429 per 1 SD; one SD multiplies annual visits by 7.89 |
| Warming × effort | Sparsely surveyed provinces are disproportionately montane with steep climatic gradients, and densely surveyed ones have already absorbed much of their Wallacean shortfall | HR 0.839: warming matters most where coverage is sparse |
| Offset log *c*(*t*) | Records enter only after publication, so recent years are under-represented; under incomplete reporting this is exactly an offset, not an approximation | Corrects for right-censoring without consuming a degree of freedom |
| (1\|species), SD 0.404 | Body size, song conspicuousness, habitat accessibility, density and taxonomic attention | ×1.50 per SD; species span a 3.7-fold range |
| (1\|province), SD 0.332 | Area, terrain complexity, habitat diversity, observer population, research tradition | ×1.39 per SD |
| (1\|province:year), SD 0.798 | The scale at which the observation process operates: regional campaigns, festivals, new reserves, local reporting channels | ×2.22 per SD, larger than either fixed effect; levels span 13-fold |
| Baseline 1980–2000 | Must end before the analysis period, or part of the warming being tested is written into the reference | Anomalies measured against the most recent non-overlapping period |

---

### Supplementary Table S3. Migratory stratification ladder and group-specific estimates

Migratory stratification. Full results in `tables/tbl_v2_migratory_ladder.csv`,
`tbl_v2_migratory_stratified.csv` and `tbl_v2_migratory_interaction_by_group.csv`.

| Group | Events | Warming HR (95% CI) | Effort HR (95% CI) | Warming × effort HR | *P* |
|---|---|---|---|---|---|
| Resident | 218 | 1.363 (1.158–1.604) | 1.287 (1.105–1.499) | 0.941 | 0.53 |
| Partial migrant | 156 | 1.511 (1.243–1.837) | 1.338 (1.084–1.651) | 1.029 | 0.78 |
| Long-distance migrant | 175 | 1.512 (1.264–1.809) | 1.333 (1.122–1.584) | 0.752 | 0.0022 |
| *Moderation tests* | | LR *P* = 0.692 | LR *P* = 0.638 | three-way LR *P* = 0.260 | |

### Supplementary Table S4. Species-level range measures under phylogenetic logistic regression

Species-level range measures, all from phylogenetic logistic regression on the dated
tree. Full results in `tables/tbl_v2_species_range_measures.csv` and
`tbl_v2_species_range_circularity.csv`.

| Measure | *n* | Species with a record | OR per SD (95% CI) | *P* |
|---|---|---|---|---|
| Global range area (AVONET) | 1,298 | 334 | 1.456 (1.204–1.762) | 1.1 × 10⁻⁴ |
| China range area (BirdLife, clipped) | 1,003 | 312 | 1.653 (1.420–1.925) | 9.0 × 10⁻¹¹ |
| Provinces occupied (*not reported as a result*) | 1,298 | 334 | 2.09 | 5 × 10⁻¹⁵ |

### Supplementary Table S5. Province-level count and rate models

Province-level models. Full results in `tables/tbl_v2_province_*.csv`.

| Model | Dispersion | *P* | AICc |
|---|---|---|---|
| Poisson | 5.59 | 2.8 × 10⁻¹⁷ | 302.1 |
| Negative binomial | 1.23 | 0.20 | 246.5 |
| Negative binomial, recent effort as offset | 1.56 | — | 266.4 |

| Term | Counts, IRR | Rate per unit of effort, IRR |
|---|---|---|
| Regional species richness | **1.27** (*P* = 0.035) | 0.88 |
| Early survey effort (2002–2008) | 0.92 | **0.70** (*P* = 0.023) |
| Recent survey effort (2009–2024) | 0.92 | *offset* |
| GDP per capita | 1.10 | **0.61** (*P* = 0.0026) |
| Administrative area | 1.17 | 1.22 |
| Habitat heterogeneity | 0.99 | 1.03 |

### Supplementary Table S6. Species-level effects within taxonomic and migratory groups

Species-level effects fitted separately within taxonomic and migratory groups, all
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

### Supplementary Table S7. Risk-set bridge from the released compilation to the modelling data

| threshold | step | pairs | rows | events | note |
|---|---|---|---|---|---|
| 50 | 1. v1 candidate pairs | 8330 |  |  | SDM pool + v1 forced events |
| 50 | 2. drop prevalent (discovered <2002) | 8308 |  |  | 22 pairs removed |
| 50 | 3. force in all re-dated events | 8319 |  |  | 11 event pairs added |
| 50 | 4. expand with absorbing exit | 8319 | 185478 | 657 |  |
| 50 | 5. usable under main specification | 8140 | 175640 | 649 | coverage-gap effort + W15 tavg_annual components non-missing |
| 100 | 1. v1 candidate pairs | 7667 |  |  | SDM pool + v1 forced events |
| 100 | 2. drop prevalent (discovered <2002) | 7645 |  |  | 22 pairs removed |
| 100 | 3. force in all re-dated events | 7656 |  |  | 11 event pairs added |
| 100 | 4. expand with absorbing exit | 7656 | 170229 | 657 |  |
| 100 | 5. usable under main specification | 7656 | 164891 | 649 | coverage-gap effort + W15 tavg_annual components non-missing |
| 200 | 1. v1 candidate pairs | 7225 |  |  | SDM pool + v1 forced events |
| 200 | 2. drop prevalent (discovered <2002) | 7203 |  |  | 22 pairs removed |
| 200 | 3. force in all re-dated events | 7217 |  |  | 14 event pairs added |
| 200 | 4. expand with absorbing exit | 7217 | 160132 | 657 |  |
| 200 | 5. usable under main specification | 7217 | 155207 | 649 | coverage-gap effort + W15 tavg_annual components non-missing |

### Supplementary Table S8. Fine grid of accumulation windows (3–23 years), annual mean temperature

| indicator | window | n | events | AIC | HR_change | P_change | HR_effort | P_effort | HR_var | P_var | HR_int | P_int | cor_change_var | sd_change | sd_var |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| tavg_annual | 5 | 175640 | 649 | 8330.40960219862 | 1.17050457534932 | 0.00255030799923006 | 1.41755334706731 | 1.45780870634732e-08 | 1.00898918532085 | 0.845110075753632 | 0.887676894007369 | 0.0264377350134999 | 0.0229841134800521 | 0.244623372287933 | 0.307834219592452 |
| tavg_annual | 10 | 175640 | 649 | 8322.1706687165 | 1.2210944859811 | 0.00040074318179533 | 1.43450157432002 | 4.91718315354132e-09 | 1.0207210078869 | 0.655108528110577 | 0.832911442249289 | 0.000587647738143069 | -0.00206105887739154 | 0.205001285492212 | 0.34106708277182 |
| tavg_annual | 15 | 175640 | 649 | 8308.54560518814 | 1.36477001403378 | 7.15210654224071e-08 | 1.4293404709696 | 4.92474652544969e-09 | 0.994530128578253 | 0.906021862441335 | 0.838920438768299 | 0.00173747816972681 | -0.00565762875472735 | 0.179396464698067 | 0.355813500677818 |
| tavg_annual | 20 | 175640 | 649 | 8306.45847282059 | 1.40000685980084 | 1.19649300342896e-08 | 1.4232847016538 | 5.91521292486089e-09 | 0.999554317783446 | 0.99242283687962 | 0.815586790511035 | 0.000152181259532048 | 0.0404009882445249 | 0.154081842607254 | 0.360328626309138 |

### Supplementary Table S9. Direction of new records by sector against Monte Carlo geometric and effort-weighted nulls (all records, 999 draws)

| Null | Sector | Observed | Expected | 95% null interval | Obs./exp. | P (Holm) |
|---|---|---|---|---|---|---|
| Geometry | North | 48 | 49.5 | 39–61 | 0.97 | 1.000 |
| Geometry | Northeast | 179 | 158.6 | 142–176 | 1.13 | 0.144 |
| Geometry | East | 237 | 234.8 | 218–252 | 1.01 | 1.000 |
| Geometry | Southeast | 52 | 64.9 | 53–78 | 0.80 | 0.240 |
| Geometry | South | 20 | 29.9 | 22–39 | 0.67 | 0.168 |
| Geometry | Southwest | 56 | 52.6 | 44–61 | 1.06 | 1.000 |
| Geometry | West | 19 | 25.0 | 17–35 | 0.76 | 1.000 |
| Geometry | Northwest | 31 | 26.8 | 18–36 | 1.16 | 1.000 |
| Geometry + effort | North | 48 | 41.2 | 32–52 | 1.17 | 0.570 |
| Geometry + effort | Northeast | 179 | 151.8 | 136–168 | 1.18 | 0.016 |
| Geometry + effort | East | 237 | 264.3 | 248–283 | 0.90 | 0.016 |
| Geometry + effort | Southeast | 52 | 65.0 | 54–76 | 0.80 | 0.112 |
| Geometry + effort | South | 20 | 32.4 | 24–40 | 0.62 | 0.050 |
| Geometry + effort | Southwest | 56 | 49.9 | 42–59 | 1.12 | 0.570 |
| Geometry + effort | West | 19 | 19.7 | 12–28 | 0.96 | 1.000 |
| Geometry + effort | Northwest | 31 | 17.7 | 10–26 | 1.75 | 0.024 |

### Supplementary Table S10. Omnibus tests of direction against Monte Carlo nulls, all records and the five best-sampled orders

| Scope | Null | Records | χ² vs null | Monte Carlo P | East sectors obs./exp. (%) | North sectors obs./exp. (%) |
|---|---|---|---|---|---|---|
| Overall | Geometry | 642 | 10.8 | 0.039 | 72.9 / 71.4 | 40.2 / 36.6 |
| Overall | Geometry + effort | 642 | 26.8 | 0.001 | 72.9 / 74.9 | 40.2 / 32.8 |
| Overall | Geometry (surface point) | 642 | 12.0 | 0.018 | 72.9 / 71.9 | 40.2 / 37.5 |
| Overall | Geometry + effort (surface point) | 642 | 23.5 | 0.001 | 72.9 / 75.4 | 40.2 / 33.5 |
| Passeriformes | Geometry | 388 | 14.6 | 0.007 | 73.2 / 70.3 | 38.7 / 35.2 |
| Passeriformes | Geometry + effort | 388 | 24.0 | 0.001 | 73.2 / 74.5 | 38.7 / 30.0 |
| Passeriformes | Geometry (surface point) | 388 | 19.3 | 0.003 | 73.2 / 71.1 | 38.7 / 36.1 |
| Passeriformes | Geometry + effort (surface point) | 388 | 26.0 | 0.002 | 73.2 / 75.2 | 38.7 / 31.3 |
| Anseriformes | Geometry | 35 | 11.5 | 0.009 | 77.1 / 77.1 | 2.9 / 2.9 |
| Anseriformes | Geometry + effort | 35 | 12.0 | 0.004 | 77.1 / 77.0 | 2.9 / 2.9 |
| Anseriformes | Geometry (surface point) | 35 | 8.4 | 0.127 | 77.1 / 77.0 | 2.9 / 3.2 |
| Anseriformes | Geometry + effort (surface point) | 35 | 9.5 | 0.050 | 77.1 / 77.0 | 2.9 / 3.0 |
| Accipitriformes | Geometry | 55 | 4.5 | 0.419 | 74.5 / 76.3 | 49.1 / 40.0 |
| Accipitriformes | Geometry + effort | 55 | 8.0 | 0.096 | 74.5 / 79.6 | 49.1 / 37.7 |
| Accipitriformes | Geometry (surface point) | 55 | 5.1 | 0.339 | 74.5 / 76.5 | 49.1 / 40.5 |
| Accipitriformes | Geometry + effort (surface point) | 55 | 8.3 | 0.074 | 74.5 / 79.7 | 49.1 / 37.8 |
| Charadriiformes | Geometry | 32 | 5.4 | 0.230 | 84.4 / 83.5 | 40.6 / 35.7 |
| Charadriiformes | Geometry + effort | 32 | 6.3 | 0.206 | 84.4 / 85.1 | 40.6 / 34.2 |
| Charadriiformes | Geometry (surface point) | 32 | 4.7 | 0.335 | 84.4 / 84.1 | 40.6 / 35.9 |
| Charadriiformes | Geometry + effort (surface point) | 32 | 6.2 | 0.178 | 84.4 / 85.4 | 40.6 / 34.3 |
| Columbiformes | Geometry | 18 | 3.6 | 0.568 | 77.8 / 66.4 | 61.1 / 61.5 |
| Columbiformes | Geometry + effort | 18 | 3.1 | 0.681 | 77.8 / 74.2 | 61.1 / 59.9 |
| Columbiformes | Geometry (surface point) | 18 | 3.8 | 0.500 | 77.8 / 67.1 | 61.1 / 60.8 |
| Columbiformes | Geometry + effort (surface point) | 18 | 3.3 | 0.635 | 77.8 / 75.1 | 61.1 / 59.5 |

## Supplementary Figures

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig4_random_structure_v2.png)

**Fig. S1 | Random-effect structures evaluated on fit, explanatory power, variance structure and ecological meaning.**
**a**, ΔAIC; the main model is highlighted. **b**, Conditional *R*², conditional AUC and marginal AUC. Marginal AUC is flat across structures, confirming that the random terms absorb observational heterogeneity without redistributing the fixed-effect signal. **c**, Random-effect standard deviations on the latent scale; no component collapses in any structure.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig7_window_baseline_sensitivity_v2.png)

**Fig. S2 | Accumulation window and climate baseline.**
Windows of 5, 10, 15 and 20 years against three series: the main WorldClim 10-arc-minute data with a 1980–2000 baseline, the same baseline computed from CRU TS at 0.5° as a control for data source and resolution, and CRU TS with a 1970–2000 baseline. **a**, Hazard ratio for accumulated warming. **b**, Hazard ratio for survey effort. **c**, Hazard ratio for the interaction. **d**, ΔAIC within each series; circles mark the optimum. Ribbons are 95% confidence intervals.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig8_migratory_strategy_v2.png)

**Fig. S3 | Migratory strategy shifts the baseline hazard but does not moderate either driver.**
**a**, Risk-set rows, events and species in each group; the three groups with a known strategy carry 549 events in total. **b**, Group-specific hazard ratios from models fitted separately within each group, with 95% confidence intervals. **c**, ΔAIC across the moderation ladder; red text is the likelihood-ratio *P* value against the model with a migratory main effect only. **d**, Group-specific warming × effort interaction derived from the three-way model; filled points are significant within group, open points are not. The formal test for heterogeneity among groups is not significant.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig9_species_level_v2.png)

**Fig. S4 | Species-level correlates of new provincial records.**
**a**, Continuous traits, as odds ratios per standard deviation with 95% confidence intervals, under three treatments of phylogenetic non-independence. Filled points are significant. **b**, Categorical contrasts against their reference levels. **c**, Range measured as an area, from two independent sources, against range measured as a count of provinces occupied. **d**, For every term, the number of phylogenetic treatments in which it is significant, with the range of odds ratios across treatments.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig10_province_level_v2.png)

**Fig. S5 | Province-level counts of new records.**
**a**, Model comparison: Poisson against negative binomial, with and without recent effort as an offset. **b**, Incidence rate ratios per standard deviation from the two negative-binomial models. **c**, Hierarchical partitioning of explained deviance into independent and joint contributions. **d**, Partial correlation of each predictor with the record count, holding the others constant.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_future/FigM1_future_mechanistic_v2.png)

**Fig. S6 | Mechanistic projection of the latent generation hazard, restricted to the fitted covariate support.**
Provincial hazard relative to 2024 under two SSP scenarios at three horizons, aggregating only species-province cells whose accumulated warming and survey effort fall inside the 1st–99th percentile of the fitted data. The percentage on each panel is the share of cells that qualify. Map lines delineate study areas and do not necessarily depict accepted national boundaries. Base map: standard map GS(2019)1822.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_future/FigM2_future_ml_v2.png)

**Fig. S7 | Machine-learning projection under identical inputs and the same support mask.**
Provincial hazard relative to 2024 from the gradient-boosted model under the same SSP scenarios, horizons and 1st–99th-percentile support mask as the mechanistic projection; the percentage on each panel is the share of qualifying cells. Map lines delineate study areas and do not necessarily depict accepted national boundaries. Base map: standard map GS(2019)1822.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_future/FigM3_shap_interpretability_v2.png)

**Fig. S8 | TreeSHAP interpretation of the gradient-boosted model.** **a**, Mean absolute SHAP contribution per feature. **b**, SHAP dependence, monotone increasing for both accumulated warming and survey effort.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/FigS1_dharma_v2.png)

**Fig. S9 | Simulation-based residual diagnostics for the main model.**
**a**, Quantile–quantile plot of DHARMa scaled residuals against the uniform distribution, from 500 simulations; every 40th point is drawn. **b**, Kolmogorov–Smirnov *P* values for the residuals of each year and each province, against the nominal 5% level. **c**, Moran's *I* of province-mean residuals against a null distribution from 999 permutations of province labels, with inverse-distance weights. **d**, Rate of change of each focal coefficient with time on the log-hazard scale, testing the proportional-hazards assumption.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_future/FigS3_future_unmasked_v2.png)

**Fig. S10 | The same mechanistic projection without the support mask**, shown to indicate the magnitude of the extrapolation. Map lines delineate study areas and do not necessarily depict accepted national boundaries. Base map: standard map GS(2019)1822.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/FigS5_resampling_v2.png)

**Fig. S11 | Design-preserving null models, resampling and influence.**
**a**, Null distributions of the four fixed effects under three permutation schemes, each destroying exactly one association while holding the risk set, the per-province-year event counts, the effort and completeness marginals and the random-effect hierarchy fixed (199 permutations each); red lines mark the observed values. The null for accumulated warming is centred near 1.16 rather than unity because permuting within province-years preserves the covariance between provincial-annual climate and provincial-annual event counts. **b**, Wald and cluster bootstrap confidence intervals, resampling species (392 clusters) and provinces (31 clusters), 300 times each. **c**, Actual coverage of the nominal 95% interval under a parametric bootstrap of 150 simulations from the fitted model, with the bias of each coefficient annotated. **d**, Relative change in each hazard ratio when each province, and each of ten species deciles, is held out. Draws converging to degenerate optima (|log hazard ratio| > 2) are excluded throughout; their number is 3 of 199 in the third null, 3 of 300 in the species bootstrap, and none elsewhere.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_pa/en/FigP1_pa_enrichment.png)

**Fig. S12 | Enrichment of new records inside mapped nature reserves, decomposed against the observation process.** **a**, Share of records, checklist-weighted birding effort, birding locations and land area falling inside the 1,028 mapped reserves. **b**, Conditional logistic estimand ladder matching each event to 200 same-province same-year checklist-weighted control locations. **c**, Robustness: host-reserve exclusions, period splits and discovery-method subsets. **d**, Concentration of inside-reserve events among host reserves.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_pa/en/FigP2_pa_persistence.png)

**Fig. S13 | Reserve status does not raise the probability that a first record becomes a persistent presence.** Re-detection of the same species in the same province in the GBIF/eBird layer, raw and adjusted for subsequent survey effort, with the pre-declared equivalence bounds.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_pa/en/FigP3_pa_mismatch_monitoring.png)

**Fig. S14 | The mapped reserve network shows no measurable mismatch with observed cell-level warming, and the monitoring gap decomposes into graftable and non-graftable areas.** **a**, Area-weighted reserve coverage across warming quintiles under the provincial-broadcast and the recomputed cell-level warming fields. **b**, Stratified permutation test within province × elevation bands. **c**–**d**, Monitoring-grafting priority classes. Map lines delineate study areas and do not necessarily depict accepted national boundaries. Base map: standard map GS(2019)1822.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_direction/combined/order_direction_windrose_facets.png)

**Fig. S15 | Per-order directionality of new records relative to species' range centroids.** Wind-rose panels for the sixteen orders, each carrying its number of records and species.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigST1_spatiotemporal_pattern.png)

**Fig. S16 | Spatial and temporal pattern of the released compilation.** **a**, All 1,029 records of CBNR v2, coloured by year of report. **b**, Cumulative records per province. **c**, Annual counts by reported year (bars) and, for the modelled subset, by discovery year (line); their offset motivates the dating correction. **d**, Latitude and longitude of records against year with loess fits. Data: CBNR v2, Zenodo record 20809949 (CC-BY-4.0). Map lines delineate study areas and do not necessarily depict accepted national boundaries. Base map: standard map GS(2019)1822.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigMS3_future_scenarios.png)

**Fig. S17 | Future scenarios with climate and survey effort as independent axes.** Predicted number of first records per province under SSP2-4.5 and SSP5-8.5, with effort frozen at 2024 or growing at 0.6 SD per decade, for **a** 2030 and **b** 2050; **c**, county surfaces for 2050 under fixed 2024 allocation shares. Colour is log10 of the expected number; transparency encodes the fraction of species–province cells inside the fitted covariate support; national totals and support fractions are given per panel. Map lines delineate study areas and do not necessarily depict accepted national boundaries. Base map: standard map GS(2019)1822.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigMS2_multiscale_model_skill.png)

**Fig. S18 | Skill of three model families across validation designs.** **a**, Province-level PR-AUC for the mechanistic model, a random forest and XGBoost under random, leave-species, leave-province and temporal folds (event rate 0.370%; error bars fold SD). **b**, Rank skill of the same families in prefecture- and county-level allocation under temporal forward-prediction and leave-one-province splits (0.5 = random).

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigMS1_multiscale_model_maps_si.png)

**Fig. S19 | Prediction surfaces of three model families at three administrative scales, 2024.** Rows: province, prefecture, county; columns: mechanistic two-stage model, random forest, XGBoost. Each column is internally consistent (its own province stage times its own within-province allocation); colour scales are shared within rows (log10 expected number of records). Basemap GS(2019)1822. Map lines delineate study areas and do not necessarily depict accepted national boundaries. Base map: standard map GS(2019)1822.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigMS4_future_scenarios_by_model_si.png)

**Fig. S20 | Future projections under the scenario grid, by model family.** **a**–**c**, Predicted first records per province in 2050 for the mechanistic model (**a**), a random forest (**b**) and XGBoost (**c**) under SSP2-4.5 and SSP5-8.5 crossed with effort frozen at 2024 or growing at 0.6 SD per decade. Colour is log10 of the expected number, shared across all twelve maps; transparency encodes the fraction of species–province cells inside the fitted covariate support; national totals and support fractions are given per panel. **d**, National totals across all eight scenarios and both horizons; all three families are calibrated to the same 2024 baseline (24.4 records per year), so the scenario slopes are each family's own. Map lines delineate study areas and do not necessarily depict accepted national boundaries. Base map: standard map GS(2019)1822.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigMS5_future_multiscale_by_model_si.png)

**Fig. S21 | Multi-scale prediction surfaces under one future scenario (SSP2-4.5, continued effort growth, 2050).** Rows: province, prefecture, county; columns: mechanistic model, random forest, XGBoost. Each column is internally consistent (its own provincial expectation times its own within-province allocation shares); prefecture and county surfaces hold the 2024 allocation shares fixed. Colour scales are shared within rows (log10); transparency encodes the in-support fraction. Basemap GS(2019)1822. Map lines delineate study areas and do not necessarily depict accepted national boundaries. Base map: standard map GS(2019)1822.