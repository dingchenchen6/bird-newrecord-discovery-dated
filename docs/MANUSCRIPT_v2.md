# Warming and survey effort contribute comparably to the generation of new bird distribution records once records are dated to discovery

**Chenchen Ding**<sup>1</sup>, et al.

<sup>1</sup> Institute of Ecology, College of Urban and Environmental Sciences, Peking University, Beijing 100871, China

Correspondence: dingchenchen@pku.edu.cn

---

## Abstract

New provincial and national distribution records are the raw material from which range shifts are inferred, yet a record is generated only when a species is present, someone is looking, and the observation is written up. Disentangling these components has proved difficult because the ecological and observational processes covary. Here we assemble a complete species × province × year risk set for 1,029 documented new bird records in China (2002–2024) and model the annual hazard that a species is newly recorded in a province using a discrete-time proportional-hazards formulation. We first show that the near-universal practice of dating such records to their year of publication is a systematic source of bias: publication lags the observation by a median of one year and a mean of 2.09 years, 81.7% of records lag by at least one year, and re-dating changes the year of 83.1% of events. Under publication-year dating, survey effort appears to raise the hazard by 79% per standard deviation and annual climate variability appears to suppress it; after re-dating, the effort coefficient falls by 37% and the variability effect vanishes entirely, while the accumulated-warming coefficient is unchanged. In the corrected analysis, accumulated warming relative to a species' historical range (hazard ratio 1.36 per SD, 95% CI 1.22–1.52) and survey effort (1.40, 1.25–1.58) contribute comparably, and warming in fact discriminates slightly better between event and non-event cells than effort does. The two interact negatively (0.85, 0.76–0.95): warming matters most where survey coverage is sparse. A province-by-year random intercept, which isolates the observation process from the ecological one, raises conditional discrimination from 0.72 to 0.85 and conditional *R*² from 0.27 to 0.41. Results are unchanged across three species-distribution-model thresholds, four survey-effort proxies, three missing-data rules and four accumulation windows. Projections under CMIP6 scenarios are constrained by a strict support diagnostic: beyond 2030, fewer than one tenth of species-province cells fall inside the fitted covariate range, so we report late-century surfaces as scenario illustrations rather than forecasts. Our results establish that documented range gains in a rapidly warming, rapidly digitising region reflect climate and observation in roughly equal measure, and that the date attached to a record determines which of the two appears to dominate.

**Keywords:** Wallacean shortfall; imperfect detection; range shift; discrete-time survival analysis; publication lag; citizen science; climate velocity; China

---

## Introduction

Documented species distributions are a joint product of where organisms occur and where people look<sup>1–4</sup>. This has been recognised for decades, and yet the inferential consequences remain incompletely handled in the literature on climate-driven range shifts<sup>5–8</sup>. When a species is reported for the first time from an administrative unit, the record is often read as evidence of range expansion; but the same record is equally consistent with a long-standing population that has only now been detected, or with a stable population in a region whose observer base has recently grown<sup>16,19–21</sup>. Distinguishing these possibilities is not a technical nicety. It determines whether a body of records constitutes evidence of biodiversity redistribution or of the filling of the Wallacean shortfall<sup>1,2</sup>.

China offers unusual leverage on this problem. Over the past two decades the country has warmed rapidly while its birdwatching community has expanded from a few thousand to hundreds of thousands of participants, and a national compilation of provincial-level new bird records now exists with dates of discovery as well as of publication<sup>9,25,37</sup>. The simultaneous expansion of the climatic and the observational signal is precisely what makes the attribution hard, and precisely what makes a formal risk-set analysis necessary.

Three specific gaps motivate this study.

**First, the temporal alignment of events has not been examined.** Records compiled from the literature carry two dates: when the bird was seen, and when the paper appeared. Almost all analyses of such compilations use the latter, because it is the field that primary sources reliably report. We show below that this choice is consequential. Publication lag is not a small, random offset; it is a right-skewed delay with a mean above two years that, critically, is correlated in aggregate with the growth of the observational infrastructure. Aligning an event to the year of publication therefore aligns it to a year in which the effort database was systematically larger, manufacturing covariance between effort and event occurrence.

**Second, the observation process operates at a spatiotemporal scale that most models do not represent.** Regional survey campaigns, provincial birdwatching festivals, new protected areas and local reporting channels act at the level of a particular province in a particular year. A model with species and region random intercepts, the conventional choice<sup>55</sup>, cannot absorb this variation; it leaks into the fixed effects and inflates whichever covariate happens to trend with observational capacity.

**Third, projections of future record generation have been made without checking whether the scenarios lie inside the fitted data.** Species-specific climate gradients are differences between two anomalies that largely covary, so their historical standard deviation is small. Future warming differentials between a province and a species' range are not small. The ratio between the two determines how far any projection extrapolates, and this ratio has not been reported.

Here we address all three. We construct a complete risk set — every species × province × year cell in which a new record could have occurred, with absorbing exit after the first record — and model the annual hazard with a complementary log-log link, the discrete-time analogue of a proportional-hazards model<sup>[A1,A2]</sup>. We re-date every event to its year of discovery, correct the resulting right-censoring with an explicit reporting-completeness offset, treat structurally implausible zeros in the effort database as coverage gaps rather than true absences of observation, and add a province-by-year random intercept. We then quantify how much each of these corrections matters, using a step-by-step decomposition in which exactly one thing changes at a time.

We ask three questions. (i) How large is the bias introduced by publication-year dating, and which coefficients does it affect? (ii) Once corrected, what are the relative contributions of accumulated warming and survey effort to the hazard of a new record, and do they interact? (iii) Over what range of future conditions can the fitted relationship legitimately be projected?

We hypothesised that effort would dominate, as reported previously<sup>10,37</sup>, and that the climate signal would be modest. Both expectations proved wrong in an informative way: effort dominance was largely an artefact of dating, and after correction the two drivers are of comparable importance.

---

## Results

### The risk set and the dating problem

The released compilation contains 1,029 provincial-level new bird records with a parseable discovery date for 1,028 (99.9%). Of these, 684 could be matched to a species × province cell in the candidate pool defined by species-distribution models plus forced inclusion of every observed event; 657 fall within the 2002–2024 analysis window (Extended Data Table 1). Twenty-six records were discovered before 2002 and therefore describe species already present at the start of the window; because such pairs are prevalent rather than incident cases, we removed them from the risk set entirely rather than treating them as censored. Conversely, eleven species × province pairs whose records were published in 2025 but discovered by 2024 re-enter the analysis under discovery-year dating; under publication-year dating they had been lost beyond the window edge.

Publication lags discovery by a median of one year and a mean of 2.09 years; 81.7% of records lag by at least one year and 26.8% by three or more (Fig. 2a). Re-dating changes the assigned year of 526 of 633 comparable events (83.1%), with a median shift of −1 year and a mean of −1.83 years. The two dating conventions produce qualitatively different time series (Fig. 2b): the publication-year series rises monotonically to 67 events in 2024, whereas the discovery-year series peaks at 59 in 2019 and falls to 14 in 2024. Neither series is a clean description of reality — the publication-year rise is an artefact of aggregating delayed reports, and the discovery-year fall is right-censoring, because records made in 2023–2024 have not yet appeared in print.

We quantified the censoring directly. The compilation extends to publications appearing in 2025, so a record discovered in year *t* can only have been observed if its lag is at most 2025 − *t*. Using the pooled empirical lag distribution, the expected share of discoveries already reported falls from 99.7% for 2002 to 89.5% for 2021, 83.4% for 2022, 73.2% for 2023 and 56.7% for 2024. The pooled distribution is justified because publication lag is stationary over the study period (Spearman correlation between discovery year and lag ρ = −0.016, *P* = 0.685; Wilcoxon comparison of 2002–2010 with 2011–2018 *P* = 0.851; cumulative distributions differ by at most three percentage points at every lag). Because the observed hazard under incomplete reporting is approximately the product of the true hazard and the completeness *c*(*t*), and the complementary log-log link is logarithmic in the hazard, *c*(*t*) enters the linear predictor exactly as an offset log *c*(*t*). We include this offset throughout.

The final risk set at the 50 km species-distribution-model threshold comprises 8,319 species × province pairs, 185,478 species-province-years and 657 events. After requiring non-missing effort and climate components, the modelling data contain 175,901 rows, 649 events, 392 species and 31 provincial units.

### Publication-year dating inflates the apparent role of survey effort

We decomposed the difference between the previously published specification and the corrected one into five steps, changing exactly one thing at each (Fig. 2c; Table 1).

Re-dating alone moves the survey-effort hazard ratio from 1.788 to 1.305, a reduction of 37% in the excess hazard, and moves the annual-variability hazard ratio from 0.850 (*P* = 1.8 × 10⁻⁴) to 0.971 (*P* = 0.48). The accumulated-warming coefficient is essentially untouched (1.394 → 1.437), as is the interaction (0.876 → 0.859). The remaining corrections are comparatively minor: treating structural zeros in the effort database as coverage gaps moves effort by −0.038; area-weighting the provincial climate series moves it by +0.022; the completeness offset restores +0.159, recovering signal that right-censoring had attenuated; and the province-by-year random intercept removes a further 0.044.

The mechanism is transparent. Publication year and the size of the observational database both increase through time, so assigning an event to its publication year places it in a cell whose recorded effort is systematically higher than the effort that actually generated the observation. This inflates the effort coefficient. It also decorrelates the event from the weather of the year in which the bird was actually seen, which is why a spurious negative coefficient on annual climate variability appears under publication-year dating and disappears under discovery-year dating. Accumulated warming, being a fifteen-year trailing mean, is robust to a shift of one or two years — which is exactly why it survives the correction unchanged.

### Warming and effort contribute comparably

In the frozen main model, both drivers raise the hazard and the effect sizes are similar (Fig. 1a; Table 2). One standard deviation of accumulated warming relative to a species' historical range multiplies the annual hazard by 1.362 (95% CI 1.216–1.524; *P* = 8.3 × 10⁻⁸); one standard deviation of survey effort multiplies it by 1.404 (1.245–1.583; *P* = 2.9 × 10⁻⁸). Annual climate variability has no effect (0.995, 0.909–1.090; *P* = 0.92). The two main effects interact negatively (0.849, 0.761–0.948; *P* = 3.7 × 10⁻³): the marginal effect of warming is steepest where effort is low and flattens where coverage is already dense (Fig. 1b).

Because standardised coefficients are hard to picture, we report both in natural units (Fig. 5c). One standard deviation of accumulated warming is **0.179 °C**: a province that has warmed by that much more than a species' own historical Chinese range carries a 36% higher annual hazard for that species. Across the observed range of the variable, −0.65 °C to +0.61 °C, the implied hazard spans roughly ninefold. One standard deviation of survey effort corresponds to a **7.75-fold** increase in annual provincial visits, from a median of 60 visits per year to about 465. The sign of the climate variable is also informative: a negative value means the province has warmed *less* than the species' range, and such cells carry a correspondingly lower hazard.

The climate variable is genuinely species-specific, not a relabelled regional index (Fig. 5a, b). Decomposing its variance, 39% of the variation in accumulated warming and 55% of the variation in the raw gradient arise *within* province-years, that is, purely from differences among species. In Yunnan in 2020, for example, accumulated warming ranges from +0.309 °C for *Aethopyga christinae*, whose Chinese range has warmed less than Yunnan has, to −0.280 °C for *Coracias garrulus*, whose range has warmed more. A province-level warming index cannot make that distinction and therefore cannot say which species should appear where.

Four independent importance criteria agree that warming and effort are of comparable weight, with warming slightly ahead on discrimination (Fig. 1c). Dropping accumulated warming costs 28.7 AIC units and 0.053 of marginal AUC; dropping survey effort costs 29.5 AIC units and 0.032 of marginal AUC. The interaction costs 6.5 AIC units. Annual variability costs −2.0 AIC units, that is, the model is marginally better without it; we retain it because it is one half of a pre-specified decomposition and its null result is itself informative.

The discrimination ladder makes the point most directly (Fig. 1d). With the random structure held at the main model, fixed-effect-only AUC rises from 0.411 for the null model to 0.559 with effort alone, 0.580 with accumulated warming alone, and 0.610 with both. Climate alone discriminates better than effort alone; neither alone approaches the pair. This is a different conclusion from the one reached under publication-year dating, where effort dominated.

### Separating the observation process requires a province-by-year level

We evaluated six random-effect structures against four criteria rather than AIC alone (Fig. 4; Table 3). Adding a province-by-year intercept to the conventional species + province structure improves AIC by 93.4 units, raises conditional *R*² from 0.274 to 0.411, raises conditional AUC from 0.721 to 0.854, and raises the intraclass correlation from 0.172 to 0.358. Crucially, marginal AUC — the discrimination attributable to fixed effects — is flat across all six structures (0.607–0.613), confirming that the random structure absorbs observational heterogeneity without redistributing the fixed-effect signal.

Two further structures were tested. A species-specific random slope on accumulated warming (ΔAIC 4.5 relative to the best) and a province-specific random slope on effort (ΔAIC 0.0, the AIC optimum) both fit marginally better, but both *reduce* conditional *R*² (0.403 and 0.395 respectively, against 0.411 for the simpler structure), and their fixed effects are indistinguishable from those of the main model (effort 1.397 and 1.372; warming 1.348 and 1.366). We therefore freeze the three-level intercept structure as the sole main model: it is the most parsimonious of the three statistically indistinguishable options, it has the highest explanatory power, and every one of its terms has a direct ecological or observational reading — intrinsic species detectability, regional survey context, and the province-year shocks through which surveys, festivals and reporting channels actually operate. No variance component collapses in any structure (minimum standard deviation 0.274).

### What each level of the model means, and why it is there

Each random term corresponds to a distinct process, and the fitted magnitudes are themselves results (Fig. 5d, Fig. 6; Table 5).

*Species (SD 0.405).* Species differ in intrinsic detectability for reasons no covariate in the model captures: body size, song conspicuousness, habitat accessibility, population density and taxonomic attention. One standard deviation multiplies the hazard by 1.50, and the fitted species span a 3.7-fold range. Grouping the species intercepts by migratory strategy shows overlapping distributions with a modestly higher median for partial migrants than for residents or long-distance migrants (Fig. 6a), consistent with partial migrants combining range-edge mobility with the year-round observability that long-distance migrants lack.

*Province (SD 0.326).* Provinces differ in their baseline setting for discovery — area, terrain complexity, habitat diversity, observer population and regional research tradition. One standard deviation multiplies the hazard by 1.39 (Fig. 6b).

*Province by year (SD 0.804).* This is the single largest variance component in the model, and it is the reason the level was added. One standard deviation multiplies the hazard by 2.23 — more than either fixed effect — and the fitted levels span a thirteenfold range (Fig. 6c). Ecologically it represents the scale at which the observation process actually operates: a regional survey campaign, a provincial birding festival, a newly established protected area, or a new local reporting channel raises the documentation rate for one province in one year. Because such shocks are not shared nationally, a model with only species and province intercepts cannot absorb them, and they leak into whichever fixed effect trends with observational capacity. The magnitude of this component is the quantitative expression of the paper's central caution: the biodiversity record moves for reasons that have nothing to do with the birds.

*Reporting completeness offset.* Not a free parameter but a known correction, so it consumes no degrees of freedom. Omitting it attenuates the effort coefficient from 1.372 to 1.245, because censoring is concentrated in the recent, high-effort years.

### Migratory strategy shifts the baseline, not the drivers

New provincial records could plausibly arise by different routes in different migratory
strategies. Residents disperse slowly, so a first record should more often mark a genuine
boundary shift. Long-distance migrants are highly mobile and can appear far outside their range
as vagrants or storm-displaced individuals, processes driven by navigation error and weather
rather than by decadal warming at the destination, and they are visible only on passage. We
therefore tested whether migratory strategy moderates either driver (Fig. 8; Table 6).

The analysis uses the three groups with a known strategy — 137 resident, 72 partial-migrant and
107 long-distance-migrant species, carrying 218, 156 and 175 events respectively. Species whose
strategy is unrecorded are excluded rather than treated as a fourth category: their event rate is
0.791% against 0.29–0.42% in the other groups, and they hold a third as many risk-set rows per
species, because a species without trait data entered the candidate pool only by virtue of having
a record. That is a selection artefact, not an ecological class.

Migratory strategy shifts the baseline hazard: adding it as a main effect improves fit
(ΔAIC 6.2 relative to the model without it) and is the best model in the ladder. It does not,
however, moderate either driver. Adding warming × strategy, effort × strategy, both, or the full
three-way warming × effort × strategy each *worsens* AIC, and none is supported by a
likelihood-ratio test (*P* = 0.693, 0.854, 0.899 and 0.256 respectively).

Fitting each group separately gives the same picture (Fig. 8b). Accumulated warming raises the
hazard in every group — 1.363 (95% CI 1.158–1.605) in residents, 1.507 (1.244–1.826) in partial
migrants and 1.514 (1.265–1.812) in long-distance migrants — and so does survey effort, at 1.293,
1.270 and 1.344. The confidence intervals overlap almost completely, as the formal tests imply.
Our prior expectation that warming would matter least for long-distance migrants was not borne
out: their point estimate is the highest of the three, though indistinguishable from the others.
The stratified fits use a reduced random structure of species and province intercepts, because
689 province-year levels are not identifiable from 156–218 events; the ladder, which uses all 549
events, retains the full structure.

One pattern is worth flagging without claiming it. The warming × effort interaction is confined to
long-distance migrants (0.753, 0.628–0.903, *P* = 0.0022) and is absent in residents (0.942,
*P* = 0.54) and partial migrants (1.053, *P* = 0.62). But the test that matters for this claim is
whether the groups differ, and it is not significant: the three-way likelihood-ratio test gives
*P* = 0.256 and the long-distance-versus-resident contrast *P* = 0.078. With at most 218 events per
group the design cannot resolve group differences in an interaction term, so we report this as a
hypothesis for a larger compilation rather than as a result (Fig. 8d).

### Which species, and which provinces

The hazard model asks what governs the risk that a given species is recorded in a given province
in a given year. Two complementary questions operate at coarser levels: which species are more
likely to yield a new provincial record at all, and which provinces accumulate more of them. We
address both following the framework of the companion mammal study, adapted to birds
(Figs 9, 10; Tables 7, 8).

*Species level.* The pool is the 1,445 Chinese bird species of the national ecological trait
database, of which 1,312 match the dated Clements phylogeny and 361 acquired at least one new
provincial record; these carry 636 of the 657 events, the remainder belonging to 13 species that
are post-2022 taxonomic splits absent from the pool. Traits come from three sources in order of
precedence: the Chinese database for body mass, morphometrics, multi-category diet, clutch size,
nest type and site, flocking, migratory status and endemism; BIRDBASE for habitat breadth (the
number of major habitats used), diet breadth (the number of major food types consumed) and IUCN
status; and AVONET for the hand-wing index and global range area. Phylogenetic non-independence
is handled with the tree itself, using phylogenetic logistic regression (Ives & Garland,
estimated α = 0.60), with taxonomic nesting and phylogenetic eigenvector regression as coarser
alternatives to confirm that nothing depends on the choice.

Two effects hold under all three treatments (Fig. 9a, b, d). Partial migrants are about twice as
likely as residents to yield a new provincial record (odds ratio 1.91–2.50 across treatments, all
*P* < 0.001), and range size raises the odds by 1.23–1.46 per standard deviation. This converges
with the hazard model from a different direction: partial migrants also carry the highest raw
event rate there (0.417% against 0.29–0.33%). Body mass, clutch size, habitat breadth, diet
breadth, number of congeners, hand-wing index, IUCN status, endemism and trophic niche are all
null — a contrast with the mammal study, where smaller-bodied, nocturnal and data-deficient
species were more likely to be newly recorded.

Range size must be measured as an **area**, not as a count of provinces occupied (Fig. 9c;
Table 7). Both area measures are independent of the response and agree: global range area gives
an odds ratio of 1.456 (95% CI 1.204–1.762, *P* = 1.1 × 10⁻⁴, n = 1,298) and Chinese range area,
taken from BirdLife polygons clipped to China, gives 1.653 (1.420–1.925, *P* = 9.0 × 10⁻¹¹,
n = 1,003). The count of provinces occupied does not qualify: the trait database was published in
2022 and its provincial counts therefore already contain the 2002–2021 records used as the
response. Species with a new record occupy a median of 14 provinces against 4 for those without,
that variable returns an odds ratio of 2.09 (*P* = 5 × 10⁻¹⁵), and it absorbs the area effect
entirely when both are entered (area 0.96, *P* = 0.70). We report only the area measures.

*Province level.* Counts of new records per province are overdispersed relative to Poisson
(dispersion 5.60, *P* = 2.3 × 10⁻¹⁷); a negative binomial is adequate (1.24, *P* = 0.20, θ = 6.11)
and passes simulation-based diagnostics (Fig. 10a; Table 8). In the count model only regional
species richness is significant (incidence rate ratio 1.27, *P* = 0.036). The informative model is
the one that treats recent survey effort as an offset, so that the response becomes the discovery
rate per unit of effort: there, provinces already well covered in 2002–2008 yield fewer records
per unit of recent effort (0.71, *P* = 0.028), as does higher GDP per capita (0.61, *P* = 0.0027)
(Fig. 10b). Hierarchical partitioning attributes 51.2% of the explained deviance to species
richness, 33.3% to area and 9% to the two effort terms combined, with the full model explaining
20.5% of deviance (Fig. 10c).

Effort therefore appears at the provincial scale not as a count effect but as diminishing
returns — the same signal the hazard model shows as an effort coefficient that falls through time.
Two analyses at different levels, on different response variables, converge on the conclusion that
China's observational capacity is now large enough that additional effort recovers progressively
less of what remains undocumented.

One adaptation must be stated. The mammal study measured historical survey effort as publication
counts for 1949–2000. No bird analogue exists in these data: the observation database holds seven
reports before 2000 and 29 of 31 provinces have none. Early (2002–2008) and recent (2009–2024)
coverage therefore take that role, which preserves the question — do provinces already well
covered show diminishing returns? — on a shorter timescale than the original.

### The return on survey effort is declining

The proportional-hazards assumption holds for accumulated warming (interaction with time β = −0.022, *P* = 0.82) but not for effort (β = −0.211, *P* = 7.7 × 10⁻⁴). This is a substantive result rather than a diagnostic failure. Allowing the effort coefficient to vary through time, its hazard ratio falls from 2.18 (95% CI 1.63–2.90) in 2002 to 1.07 (0.88–1.30) in 2024, crossing into non-significance in the early 2020s (Fig. 6d). Two decades of intensifying observation have used up the readily detectable gaps, so an additional standard deviation of effort now yields far fewer first records than it did at the start of the period. That the climate term shows no such decline is the sharpest available evidence that the two coefficients are capturing different processes: a saturating observational process and a non-saturating climatic one.

### Robustness

The conclusions do not depend on any freely chosen analytical decision (Fig. 3).

*Species-distribution-model threshold.* Tightening the candidate pool from a 50 km to a 200 km buffer changes the risk set from 175,901 to 155,435 rows but leaves the coefficients essentially fixed (effort 1.404, 1.405, 1.411; warming 1.362, 1.376, 1.372; interaction 0.849, 0.851, 0.850).

*Climate indicator.* Annual mean temperature carries the signal; warmest-month maximum temperature carries a weaker version of it (hazard ratio 1.30, ΔAIC 9.0 behind the best cell) but shows no interaction with effort; coldest-month minimum temperature and winter mean temperature show no signal at any window (hazard ratios 0.96–1.08, all *P* > 0.12). Annual mean temperature integrates the whole thermal regime, whereas seasonal extremes describe conditions that constrain overwintering or breeding but not the year-round climatic envelope within which a range boundary sits.

*Accumulation window and climate baseline.* Both are analyst choices rather than data-determined ones, so we tested them jointly at windows of 5, 10, 15 and 20 years against the two baselines in common use for this kind of anomaly, 1980–2000 and 1970–2000 (Fig. 7).

The 1970–2000 baseline cannot be computed from the WorldClim 2.1 downscaling used in the main analysis, which begins in 1980. We therefore rebuilt the entire climate chain from CRU TS 4.09 at its native 0.5°, which reaches back to 1901, and fitted *both* baselines on it. This separates two things that would otherwise be confounded: comparing WorldClim 1980–2000 with CRU 1980–2000 isolates the effect of changing data source and resolution, and comparing CRU 1980–2000 with CRU 1970–2000 isolates the effect of the baseline period itself.

Three results follow, and each has an ecological reading rather than being merely a robustness statement.

First, the warming coefficient rises with window length in every series, from about 1.16–1.21 at five years to 1.36–1.40 at twenty years (Fig. 7a). This is the signature expected of a process that integrates climate over years to decades: a five-year window measures weather rather than climate and dilutes the signal, whereas a boundary shifts only when conditions have been favourable long enough for colonisation and establishment. A finer grid spanning 3 to 23 years (Extended Data Table 2) places the optimum at 18–20 years with AIC rising again by 23 years, so the optimum is interior rather than an artefact of the tested range. We retain 15 years as pre-specified; it lies within 2.2–5.6 AIC units of the optimum in every series.

Second, the effort coefficient is flat at 1.34–1.41 across all twelve combinations (Fig. 7b), and the interaction is negative throughout (0.87–1.00; Fig. 7c). If the climate and effort terms were competing for the same variance, changing the climate specification would move the effort estimate. It does not, which is direct evidence that the two are separately identified.

Third, the choice between the two baselines is immaterial, and if anything the longer one strengthens the result: at *W* = 15 the hazard ratio is 1.361 under CRU 1970–2000 against 1.307 under CRU 1980–2000, and the main WorldClim 1980–2000 estimate of 1.362 sits between the two. Changing data source and resolution moves the estimate by a similar small amount (1.362 to 1.307), so neither choice is decisive. One caveat follows from the resolution difference and matters for interpretation: because the 0.5° CRU grid smooths the sub-grid topographic variation that the 10-arc-minute downscaling retains, one standard deviation of accumulated warming is 0.058 °C in the CRU series against 0.179 °C in the main one. Standardised hazard ratios remain comparable, but the natural-unit statements in this paper refer to the main, higher-resolution series.

*Effort proxy and missing-data rule.* All twelve combinations of four proxies (visits, observers, birding days, records) and three treatments of the 24 implausible zero cells (coverage gap, bounded within-province interpolation, zero-filling) give effort hazard ratios between 1.25 and 1.52 and warming hazard ratios between 1.35 and 1.37. Because the three missing-data rules yield different sample sizes, AIC is not comparable across them and we compare coefficients only. The coverage-gap interpretation is strongly supported by the data: in 22 of the 24 cells flagged as structural zeros, the immediately adjacent years within the same province record between one and 27 visits, so these are gaps in database coverage rather than years in which birdwatching ceased.

### Model adequacy

Simulation-based residual diagnostics indicate a well-calibrated model (Extended Data Fig. 1; Table 4). Scaled residuals are uniform (Kolmogorov–Smirnov *P* = 0.74), dispersion is correct (*P* = 0.59) and there is no zero inflation (*P* = 0.59). Two of 23 year levels and two of 31 province levels show within-group deviation at *P* < 0.05, close to the nominal rate. Province-mean residuals show no spatial autocorrelation (Moran's *I* = −0.038 against an expectation of −0.033; permutation *P* = 0.86). The outlier test is significant (95 outliers, *P* < 0.001), as is expected of a binary outcome with an event rate of 0.37%; we report it for completeness rather than as evidence of misspecification.

The proportional-hazards assumption holds for the focal climate term: the interaction between accumulated warming and time is negligible (β = −0.022, *P* = 0.82). It does not hold for effort (β = −0.211, *P* = 7.7 × 10⁻⁴), which is a substantive result rather than a diagnostic failure: the marginal return of an additional standard deviation of survey effort has declined over 2002–2024, consistent with the progressive saturation of easily detectable gaps. In a model that allows both effects to vary through time, the fixed effects are unchanged in direction and magnitude (effort 1.527, warming 1.369, variability 0.996), and only the interaction loses significance (0.864, *P* = 0.12).

### How far can these relationships be projected?

We projected the fitted hazard under CMIP6 SSP2-4.5 and SSP5-8.5 for 2030, 2050 and 2080, applying the four-model ensemble delta to both the provincial and the species-range end of the climate gradient — applying it to one end only would create a climate signal from spatially uniform warming — and growing effort at scenario-differentiated rates. We then asked how much of each scenario lies inside the range over which the model was fitted (Fig. M4b).

The answer sharply constrains what can be claimed. The historical species-specific gradient has a standard deviation of only 0.18 °C, because provincial and range-wide anomalies largely move together. Future province-minus-range warming differentials reach 2 °C, more than ten standard deviations beyond the fitted range. Consequently, only 47.8% of species-province cells fall inside the fitted covariate support under SSP2-4.5 in 2030, 10.4% in 2050 and 2.1% in 2080; under SSP5-8.5 the corresponding figures are 34.2%, 2.1% and 1.9%.

Restricted to cells inside the support, the mechanistic model projects hazard ratios relative to 2024 of 0.79 to 2.94 (Fig. M1). Applied without the mask, the same model produces ratios up to 78 (Extended Data Fig. 3). We regard the masked surfaces as the defensible result and the unmasked ones as an illustration of how far the extrapolation reaches.

A gradient-boosted comparison model trained on the same three predictors reinforces the point. Within the observed range the two model families track each other across province-years (Spearman ρ = 0.54). Outside it they diverge completely: rank correlations across province-scenario cells range from −0.04 to 0.18, and the two agree on the direction of change in only 23.7% of cells, falling to 6.5% under SSP5-8.5 in 2080. The mechanistic model projects increases in 176 of 186 cells; the machine-learning model in 42. The cause is structural: tree ensembles return boundary leaf values once covariates leave the training support and therefore saturate, whereas the complementary log-log model extrapolates linearly on the log-hazard scale. Neither behaviour is validated by the data. TreeSHAP attributions within the training range are monotone increasing for both warming and effort (Fig. M3), consistent with the mechanistic coefficients.

---

## Discussion

Three results have implications beyond this dataset.

**The date attached to a record is a modelling decision, not a bookkeeping detail.** Compilations of new distribution records — provincial, national, or regional — are assembled from the published literature, and publication year is the field that primary sources report consistently. Our decomposition shows that using it inflates the apparent contribution of survey effort by 37% and manufactures an effect of annual climate variability that does not exist. The bias is directional and predictable: because publication year and observational capacity both trend upward, the misalignment always favours the covariate that trends with observer numbers. Any compilation-based analysis that reports an effort or sampling-intensity effect without discovery dates should be read with this in mind. Where discovery dates are unavailable, our completeness framework provides a partial remedy, but the first-order fix is to record and report the observation date.

**Accumulated warming is not a minor addition to a sampling story.** After correction, warming relative to a species' historical range and survey effort contribute comparably to the hazard of a new provincial record, and warming discriminates slightly better between event and non-event cells. This is not a claim that new records are unbiased evidence of range expansion; the effort effect remains large, and the province-by-year variance component (standard deviation 0.804 on the latent scale) is the single largest source of heterogeneity in the model, reflecting how strongly the observation process varies in space and time. It is a claim that the climate signal is not an artefact of where people look, because it survives the inclusion of effort at four proxies, three missing-data rules, three candidate-pool definitions and a random structure that absorbs province-year observational shocks.

The negative interaction refines this. Warming raises the hazard most where survey effort is low. Two readings are consistent with the data and are not mutually exclusive. Ecologically, sparsely surveyed provinces in China are disproportionately western and montane, where climatic gradients are steep and small temperature changes translate into large habitat displacements. Observationally, densely surveyed provinces have already absorbed much of their Wallacean shortfall, so the pool of species available to be newly recorded is depleted regardless of climate. The declining marginal return of effort through time, which we detect as a violation of proportional hazards for that term alone, supports the second reading. Distinguishing them will require data on detection probability conditional on presence, which provincial compilations do not provide.

**Projection is limited by covariate support, not by scenario availability.** It is straightforward to push a fitted hazard model through CMIP6 surfaces to 2080 and produce a map. Our support diagnostic shows that fewer than one in fifty species-province cells then resembles anything in the fitted data, because the species-specific climate gradient — a difference between two covarying anomalies — has a historical standard deviation an order of magnitude smaller than the future warming differentials imposed on it. The consequence is not merely wide uncertainty; it is that mechanistic and machine-learning models trained on identical data disagree on the direction of change in three quarters of cells. We recommend that projections of record generation, and of range-shift indicators built on species-specific climate differentials more generally, report the fraction of projected cells inside the fitted support as a matter of routine<sup>[A3–A5]</sup>. Where that fraction is small, the honest product is a near-term surface with an explicit support mask, not a century-scale map.

**Implications for monitoring and conservation planning.** Three practical points follow. First, the province-by-year variance component identifies where monitoring investment changes what is documented: a single province-year shock of one standard deviation multiplies the hazard by 2.2, more than either driver at one standard deviation. Targeted survey campaigns therefore have large and immediate effects on the biodiversity record, which is a reason to allocate them deliberately rather than opportunistically. Second, the negative interaction implies that survey effort added to under-covered, climatically dynamic provinces yields more new documentation per unit effort than the same investment in well-covered provinces — a straightforward prioritisation rule. Third, because the marginal return of effort has declined measurably within two decades, monitoring programmes should expect diminishing returns in new-record generation and should not read a plateau in new records as evidence that redistribution has slowed.

**Limitations.** Our events are formal published records, not detections; a species present but undocumented contributes to the non-event cells, so all coefficients describe the generation of *documented* records rather than of range expansions per se. This is the sense in which our framing is deliberately narrower than an attribution claim. The effort panel is provincial and annual, which is coarse relative to the scale at which observers actually operate. The candidate pool is defined by species-distribution models, whose thresholds we varied but whose structural assumptions we did not. Vagrant taxa without established Chinese ranges were excluded, so our results describe range-margin dynamics rather than long-distance displacement. Finally, the discovery-year series is right-censored at its most recent end; the completeness offset corrects the expected hazard but cannot recover the individual records that have not yet been published.

---

## Methods

### Event data and dating

New provincial-level bird distribution records for China were taken from the released compilation of 1,029 records covering 2000–2025<sup>25</sup>. Each record carries a discovery date and a source publication year. We parsed a four-digit year from the discovery date field, obtaining a usable year for 1,028 of 1,029 records. Nine further records reported a discovery year later than the publication year, which is internally inconsistent; for these ten records in total we substituted publication year minus the median lag of one year, and flagged the substitution in the released data.

Species names were harmonised by trying, in order, the Catalogue of Life China 2026, BirdLife International v10 and Clements v2025 names supplied with the compilation, retaining the first that matched the candidate pool; provincial names were harmonised by mapping Xizang to Tibet. Taiwan, Hong Kong and Macao were excluded because the survey-effort compilation does not cover them.

For each species × province pair we retained the earliest event year; later reports of the same pair were treated as re-documentation. Pairs whose earliest record predates 2002 describe species already present at the start of the analysis window and were removed from the risk set as prevalent rather than incident cases. Every remaining event was forced into the risk set irrespective of its species-distribution-model status.

### Reporting completeness

Let *F* be the empirical cumulative distribution of non-negative publication lags and *P*max = 2025 the latest publication year in the compilation. A record discovered in year *t* can have appeared only if its lag is at most *P*max − *t*, so the expected share of year-*t* discoveries already reported is *c*(*t*) = *F*(*P*max − *t*). We verified that lag is stationary across discovery years using Spearman correlation and a Wilcoxon comparison of the first and second halves of the well-reported period (2002–2018), and by comparing the cumulative distributions directly. Under incomplete reporting the observed hazard is approximately *c*(*t*)·*h*(*t*); with a complementary log-log link this is exactly an offset, log(−log(1 − *p*obs)) = η + log *c*(*t*), which we include in every model. Sensitivity analyses omitting the offset and truncating the window at 2021 are reported.

### Risk set

The candidate pool for each species comprises the provinces intersecting its BirdLife International range polygon buffered by 50, 100 or 200 km, plus every province in which the species was actually recorded. Each species × province pair contributes one row per year from 2002 until the year of its first record, after which it exits the risk set (absorbing exit). At the 50 km threshold this yields 8,319 pairs, 185,478 rows and 657 events.

### Climate variables

Monthly temperature surfaces at 10 arc-minutes for 1980–2024 were taken from the WorldClim 2.1 downscaling of CRU TS 4.09<sup>53,54</sup>. We computed four indicators: annual mean temperature, winter mean temperature, warmest-month maximum temperature and coldest-month minimum temperature. Provincial series *T*(*p*,*t*) are area-weighted means over the 100 km analysis grid, weighted by the area of overlap between each grid cell and the province; species-range series *N*(*s*,*t*) are means over the species' Chinese range polygon. Baselines *T*base and *N*base are 1980–2000 means at both ends.

The species-referenced climate gradient is

  *x*(*s*,*p*,*t*) = [*T*(*p*,*t*) − *T*base(*p*)] − [*N*(*s*,*t*) − *N*base(*s*)],

that is, how much more the target province has warmed than the species' own historical range. This is decomposed, strictly backward-looking, into an accumulated component and a residual:

  clim_change(*s*,*p*,*t*) = mean of *x* over [*t* − *W* + 1, *t*],
  clim_var(*s*,*p*,*t*) = *x*(*s*,*p*,*t*) − clim_change(*s*,*p*,*t*),

with *W* ∈ {5, 10, 15, 20} years. Because the surfaces extend back to 1980, no analysis-period rows are lost to the trailing window at any *W*. The main specification uses annual mean temperature with *W* = 15.

### Survey effort

Provincial annual survey effort was compiled from integrated observation records and expressed through four proxies: number of visits, number of distinct observers, number of birding days and number of records. Thirty-nine province-years (Hong Kong, Macao and Taiwan) have no coverage in the source database. A further 24 mainland province-years were recorded as exactly zero. We treat these as coverage gaps rather than true zeros: in 22 of 24, the adjacent years in the same province record between one and 27 visits. In the main analysis these cells are missing; sensitivity analyses zero-fill them (the previously published treatment) and impute them by within-province linear interpolation on the log scale, which is bounded by the neighbouring observed values. Each proxy is log1p-transformed and standardised within the analysis scope separately for each missing-data rule.

### Model

We model the annual hazard that species *s* is first recorded in province *p* in year *t* as a discrete-time proportional-hazards model with a complementary log-log link<sup>[A1,A2],55</sup>:

  log(−log(1 − *h*(*s*,*p*,*t*))) = β₀ + β₁·clim_change_z + β₂·effort_z + β₃·(clim_change_z × effort_z) + β₄·clim_var_z + log *c*(*t*) + *u*ₛ + *v*ₚ + *w*ₚₜ,

with *u*ₛ ~ N(0, σ²species), *v*ₚ ~ N(0, σ²province) and *w*ₚₜ ~ N(0, σ²province×year). All predictors are standardised on the analysis sample, so coefficients are hazard ratios per standard deviation. Models were fitted with glmmTMB 1.1<sup>55</sup>.

Six random-effect structures were compared on four criteria: AIC and BIC; explanatory power (McFadden pseudo-*R*², Nakagawa marginal and conditional *R*²<sup>56</sup>, and marginal and conditional AUC); variance-component identifiability; and the ecological interpretability of each term. The structure reported above was frozen before the robustness analyses were run.

### Diagnostics

Residual diagnostics used simulation-based scaled residuals with 500 simulations<sup>[A6]</sup>: uniformity, dispersion, outliers, zero inflation, and grouped uniformity by year and by province. Spatial autocorrelation was assessed as Moran's *I* on province-mean residuals with inverse-distance weights and a 999-permutation null. Proportional hazards were tested by adding interactions between each focal term and standardised year.

### Projections

CMIP6 four-model ensemble median deltas for annual mean temperature were computed for SSP2-4.5 and SSP5-8.5 at 2030, 2050 and 2080, separately for each province and each species range, and added to both ends of the climate gradient. Effort was grown at 0.30 (SSP2-4.5) and 0.60 (SSP5-8.5) standard deviations per decade. Predictions set the province-by-year random effect to its expectation and the completeness offset to log 1, so the projected quantity is the latent generation hazard. Support was defined as the 1st–99th percentile of the fitted accumulated warming and effort; main projection figures aggregate only cells inside this range, and the share of qualifying cells is reported on every panel. A gradient-boosted comparison model (XGBoost, 400 rounds, learning rate 0.05, depth 4)<sup>36</sup> was trained on the same three predictors, and exact TreeSHAP attributions were computed for interpretation<sup>35</sup>.

### Data and code availability

All modelling data, analysis code, result tables, figures in four formats including editable PowerPoint, and this manuscript are archived in the accompanying repository. Species range polygons (BirdLife International) and CRU TS climate surfaces are third-party licensed and are not redistributed; paths to local copies are configured in `config.R`. A smoke test reproduces the headline coefficients from the shipped data in approximately two minutes.

---

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

**Table 2.** Main model. Discrete-time proportional hazards, complementary log-log link; *n* = 175,901; 649 events; 392 species; 31 provinces; AIC 8,313.2.

| Term | HR per SD | 95% CI | *P* |
|---|---|---|---|
| Accumulated warming | 1.362 | 1.216–1.524 | 8.3 × 10⁻⁸ |
| Survey effort | 1.404 | 1.245–1.583 | 2.9 × 10⁻⁸ |
| Annual climate variability | 0.995 | 0.909–1.090 | 0.92 |
| Warming × effort | 0.849 | 0.761–0.948 | 3.7 × 10⁻³ |
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

## References

1. Hortal, J. et al. Seven shortfalls that beset large-scale knowledge of biodiversity. *Annu. Rev. Ecol. Evol. Syst.* **46**, 523–549 (2015). https://doi.org/10.1146/annurev-ecolsys-112414-054400
2. Diniz-Filho, J. A. F. et al. Macroecological links between the Linnean, Wallacean, and Darwinian shortfalls. *Front. Biogeogr.* **15**, e59566 (2023). https://doi.org/10.21425/F5FBG59566
3. Moura, M. R. & Jetz, W. Shortfalls and opportunities in terrestrial vertebrate species discovery. *Nat. Ecol. Evol.* **5**, 631–639 (2021). https://doi.org/10.1038/s41559-021-01411-5
4. Oliver, R. Y., Meyer, C., Ranipeta, A., Winner, K. & Jetz, W. Global and national trends, gaps, and opportunities in documenting and monitoring species distributions. *PLoS Biol.* **19**, e3001336 (2021). https://doi.org/10.1371/journal.pbio.3001336
5. Parmesan, C. & Yohe, G. A globally coherent fingerprint of climate change impacts across natural systems. *Nature* **421**, 37–42 (2003). https://doi.org/10.1038/nature01286
6. Chen, I.-C., Hill, J. K., Ohlemüller, R., Roy, D. B. & Thomas, C. D. Rapid range shifts of species associated with high levels of climate warming. *Science* **333**, 1024–1026 (2011). https://doi.org/10.1126/science.1206432
7. Lenoir, J. & Svenning, J.-C. Climate-related range shifts – a global multidimensional synthesis and new research directions. *Ecography* **38**, 15–28 (2015). https://doi.org/10.1111/ecog.00967
8. Pecl, G. T. et al. Biodiversity redistribution under climate change: impacts on ecosystems and human well-being. *Science* **355**, eaai9214 (2017). https://doi.org/10.1126/science.aai9214
9. Chen, S. et al. Chinese provincial-level new records for 96 resident bird species reveal poleward range shifts. *Avian Res.* **16**, 100310 (2025). https://doi.org/10.1016/j.avrs.2025.100310
10. Ding, C., Ding, J., Qiao, H., Jiang, Z. & Wang, Z. Taxonomic and spatiotemporal patterns and ecological correlates of new mammal distribution records in China. *Glob. Ecol. Biogeogr.* **34**, e70165 (2025). https://doi.org/10.1111/geb.70165
11. Sullivan, B. L. et al. eBird: a citizen-based bird observation network in the biological sciences. *Biol. Conserv.* **142**, 2282–2292 (2009). https://doi.org/10.1016/j.biocon.2009.05.006
12. Chandler, M. et al. Contribution of citizen science towards international biodiversity monitoring. *Biol. Conserv.* **213**, 280–294 (2017). https://doi.org/10.1016/j.biocon.2016.09.004
13. Isaac, N. J. B., van Strien, A. J., August, T. A., de Zeeuw, M. P. & Roy, D. B. Statistics for citizen science: extracting signals of change from noisy ecological data. *Methods Ecol. Evol.* **5**, 1052–1060 (2014). https://doi.org/10.1111/2041-210X.12254
14. MacKenzie, D. I. et al. Estimating site occupancy rates when detection probabilities are less than one. *Ecology* **83**, 2248–2255 (2002). https://doi.org/10.1890/0012-9658(2002)083[2248:ESORWD]2.0.CO;2
15. Miller-ter Kuile, A. et al. If you're rare, should I care? How imperfect detection changes relationships between biodiversity and global change drivers. *Glob. Change Biol.* **31**, e70362 (2025). https://doi.org/10.1111/gcb.70362
16. Hughes, A. C. et al. Sampling biases shape our view of the natural world. *Ecography* **44**, 1259–1269 (2021). https://doi.org/10.1111/ecog.05926
17. Lahoz-Monfort, J. J. & Magrath, M. J. L. A comprehensive overview of technologies for species and habitat monitoring and conservation. *BioScience* **71**, 1038–1062 (2021). https://doi.org/10.1093/biosci/biab073
18. Burton, A. C. et al. Wildlife camera trapping: a review and recommendations for linking surveys to ecological processes. *J. Appl. Ecol.* **52**, 675–685 (2015). https://doi.org/10.1111/1365-2664.12432
19. Tingley, M. W. & Beissinger, S. R. Detecting range shifts from historical species occurrences: new perspectives on old data. *Trends Ecol. Evol.* **24**, 625–633 (2009). https://doi.org/10.1016/j.tree.2009.05.009
20. Boakes, E. H. et al. Distorted views of biodiversity: spatial and temporal bias in species occurrence data. *PLoS Biol.* **8**, e1000385 (2010). https://doi.org/10.1371/journal.pbio.1000385
21. Bowler, D. E. et al. Treating gaps and biases in biodiversity data as a missing data problem. *Biol. Rev.* **100**, 50–67 (2025). https://doi.org/10.1111/brv.13127
22. Beck, J., Böller, M., Erhardt, A. & Schwanghart, W. Spatial bias in the GBIF database and its effect on modeling species' geographic distributions. *Ecol. Inform.* **19**, 10–15 (2014). https://doi.org/10.1016/j.ecoinf.2013.11.002
23. Meyer, C., Kreft, H., Guralnick, R. & Jetz, W. Global priorities for an effective information basis of biodiversity distributions. *Nat. Commun.* **6**, 8221 (2015). https://doi.org/10.1038/ncomms9221
24. Schrodt, F. et al. Advancing causal inference in ecology: pathways for biodiversity change detection and attribution. *Methods Ecol. Evol.* **16**, 2276–2304 (2025). https://doi.org/10.1111/2041-210X.70131
25. Ding, C. et al. A dataset of provincial-level new distribution records for birds in China from 2000 to 2025. *Sci. Data* (submitted).
26. Devictor, V., Julliard, R., Couvet, D. & Jiguet, F. Birds are tracking climate warming, but not fast enough. *Proc. R. Soc. B* **275**, 2743–2748 (2008). https://doi.org/10.1098/rspb.2008.0878
27. Devictor, V. et al. Differences in the climatic debts of birds and butterflies at a continental scale. *Nat. Clim. Change* **2**, 121–124 (2012). https://doi.org/10.1038/nclimate1347
28. La Sorte, F. A. & Thompson, F. R. Poleward shifts in winter ranges of North American birds. *Ecology* **88**, 1803–1812 (2007). https://doi.org/10.1890/06-1072.1
29. Loarie, S. R. et al. The velocity of climate change. *Nature* **462**, 1052–1055 (2009). https://doi.org/10.1038/nature08649
30. Burrows, M. T. et al. The pace of shifting climate in marine and terrestrial ecosystems. *Science* **334**, 652–655 (2011). https://doi.org/10.1126/science.1210288
31. Pinsky, M. L., Worm, B., Fogarty, M. J., Sarmiento, J. L. & Levin, S. A. Marine taxa track local climate velocities. *Science* **341**, 1239–1242 (2013). https://doi.org/10.1126/science.1239352
32. Poloczanska, E. S. et al. Global imprint of climate change on marine life. *Nat. Clim. Change* **3**, 919–925 (2013). https://doi.org/10.1038/nclimate1958
33. Williams, J. W. & Jackson, S. T. Novel climates, no-analog communities, and ecological surprises. *Front. Ecol. Environ.* **5**, 475–482 (2007). https://doi.org/10.1890/070037
34. Mahony, C. R., Cannon, A. J., Wang, T. & Aitken, S. N. A closer look at novel climates: new methods and insights at continental to landscape scales. *Glob. Change Biol.* **23**, 3934–3955 (2017). https://doi.org/10.1111/gcb.13645
35. Lundberg, S. M. et al. From local explanations to global understanding with explainable AI for trees. *Nat. Mach. Intell.* **2**, 56–67 (2020). https://doi.org/10.1038/s42256-019-0138-9
36. Chen, T. & Guestrin, C. XGBoost: a scalable tree boosting system. In *Proc. 22nd ACM SIGKDD Int. Conf. Knowledge Discovery and Data Mining* 785–794 (2016). https://doi.org/10.1145/2939672.2939785
37. Xing, X. et al. Where are the provincial-level new records in China from the past 20 years? *Front. Ecol. Evol.* **12**, 1415268 (2024). https://doi.org/10.3389/fevo.2024.1415268
38. Guillera-Arroita, G. Modelling of species distributions, range dynamics and communities under imperfect detection: advances, challenges and opportunities. *Ecography* **40**, 281–295 (2017). https://doi.org/10.1111/ecog.02445
39. Rumpf, S. B. et al. Range dynamics of mountain plants decrease with elevation. *Proc. Natl Acad. Sci. USA* **115**, 1848–1853 (2018). https://doi.org/10.1073/pnas.1713936115
40. Freeman, B. G., Scholer, M. N., Ruiz-Gutierrez, V. & Fitzpatrick, J. W. Climate change causes upslope shifts and mountaintop extirpations in a tropical bird community. *Proc. Natl Acad. Sci. USA* **115**, 11982–11987 (2018). https://doi.org/10.1073/pnas.1804224115
41. Mi, X. et al. The global significance of biodiversity science in China: an overview. *Natl Sci. Rev.* **8**, nwab032 (2021). https://doi.org/10.1093/nsr/nwab032
42. Amano, T., Lamming, J. D. L. & Sutherland, W. J. Spatial gaps in global biodiversity information and the role of citizen science. *BioScience* **66**, 393–400 (2016). https://doi.org/10.1093/biosci/biw022
43. Callaghan, C. T., Poore, A. G. B., Major, R. E., Rowley, J. J. L. & Cornwell, W. K. Optimizing future biodiversity sampling by citizen scientists. *Proc. R. Soc. B* **286**, 20191487 (2019). https://doi.org/10.1098/rspb.2019.1487
44. Kelling, S. et al. Using semistructured surveys to improve citizen science data for monitoring biodiversity. *BioScience* **69**, 170–179 (2019). https://doi.org/10.1093/biosci/biz010
45. Dickinson, J. L., Zuckerberg, B. & Bonter, D. N. Citizen science as an ecological research tool: challenges and benefits. *Annu. Rev. Ecol. Evol. Syst.* **41**, 149–172 (2010). https://doi.org/10.1146/annurev-ecolsys-102209-144636
46. Bowler, D. E. et al. Mapping human pressures on biodiversity across the planet uncovers anthropogenic threat complexes. *People Nat.* **2**, 380–394 (2020). https://doi.org/10.1002/pan3.10071
47. Sunday, J. M., Bates, A. E. & Dulvy, N. K. Thermal tolerance and the global redistribution of animals. *Nat. Clim. Change* **2**, 686–690 (2012). https://doi.org/10.1038/nclimate1539
48. Guisan, A. & Thuiller, W. Predicting species distribution: offering more than simple habitat models. *Ecol. Lett.* **8**, 993–1009 (2005). https://doi.org/10.1111/j.1461-0248.2005.00792.x
49. Elith, J., Phillips, S. J., Hastie, T., Dudík, M., Chee, Y. E. & Yates, C. J. A statistical explanation of MaxEnt for ecologists. *Divers. Distrib.* **17**, 43–57 (2011). https://doi.org/10.1111/j.1472-4642.2010.00725.x
50. Guillera-Arroita, G. et al. Is my species distribution model fit for purpose? Matching data and models to applications. *Glob. Ecol. Biogeogr.* **24**, 276–292 (2015). https://doi.org/10.1111/geb.12268
51. Phillips, S. J. et al. Sample selection bias and presence-only distribution models: implications for background and pseudo-absence data. *Ecol. Appl.* **19**, 181–197 (2009). https://doi.org/10.1890/07-2153.1
52. Johnston, A. et al. Analytical guidelines to increase the value of community science data: an example using eBird data to estimate species distributions. *Divers. Distrib.* **27**, 1265–1277 (2021). https://doi.org/10.1111/ddi.13271
53. Harris, I., Osborn, T. J., Jones, P. & Lister, D. Version 4 of the CRU TS monthly high-resolution gridded multivariate climate dataset. *Sci. Data* **7**, 109 (2020). https://doi.org/10.1038/s41597-020-0453-3
54. Fick, S. E. & Hijmans, R. J. WorldClim 2: new 1-km spatial resolution climate surfaces for global land areas. *Int. J. Climatol.* **37**, 4302–4315 (2017). https://doi.org/10.1002/joc.5086
55. Brooks, M. E. et al. glmmTMB balances speed and flexibility among packages for zero-inflated generalized linear mixed modeling. *R J.* **9**, 378–400 (2017). https://doi.org/10.32614/RJ-2017-066
56. Nakagawa, S. & Schielzeth, H. A general and simple method for obtaining *R*² from generalized linear mixed-effects models. *Methods Ecol. Evol.* **4**, 133–142 (2013). https://doi.org/10.1111/j.2041-210x.2012.00261.x
57. Pebesma, E. Simple Features for R: standardized support for spatial vector data. *R J.* **10**, 439–446 (2018). https://doi.org/10.32614/RJ-2018-009
58. Lenoir, J. et al. Species better track climate warming in the oceans than on land. *Nat. Ecol. Evol.* **4**, 1044–1059 (2020). https://doi.org/10.1038/s41559-020-1198-2
59. Scheffers, B. R. et al. The broad footprint of climate change from genes to biomes to people. *Science* **354**, aaf7671 (2016). https://doi.org/10.1126/science.aaf7671
60. Román-Palacios, C. & Wiens, J. J. Recent responses to climate change reveal the drivers of species extinction and survival. *Proc. Natl Acad. Sci. USA* **117**, 4211–4217 (2020). https://doi.org/10.1073/pnas.1913007117
61. Lehikoinen, A. et al. Declining population trends of European mountain birds. *Glob. Change Biol.* **25**, 577–588 (2019). https://doi.org/10.1111/gcb.14522
62. Rosenberg, K. V. et al. Decline of the North American avifauna. *Science* **366**, 120–124 (2019). https://doi.org/10.1126/science.aaw1313
63. van Strien, A. J., van Swaay, C. A. M. & Termaat, T. Opportunistic citizen science data of animal species produce reliable estimates of distribution trends if analysed with occupancy models. *J. Appl. Ecol.* **50**, 1450–1458 (2013). https://doi.org/10.1111/1365-2664.12158
64. Kéry, M., Royle, J. A., Schmid, H. et al. Importance of sampling design and analysis in animal population studies. *J. Appl. Ecol.* **45**, 981–986 (2008). https://doi.org/10.1111/j.1365-2664.2007.01421.x
65. Steen, V. A., Elphick, C. S. & Tingley, M. W. An evaluation of stringent filtering to improve species distribution models from citizen science data. *Divers. Distrib.* **25**, 1857–1869 (2019). https://doi.org/10.1111/ddi.12985
66. Fink, D. et al. Modeling avian full annual cycle distribution and population trends with citizen science data. *Ecol. Appl.* **30**, e02056 (2020). https://doi.org/10.1002/eap.2056
67. Zizka, A. et al. CoordinateCleaner: standardized cleaning of occurrence records from biological collection databases. *Methods Ecol. Evol.* **10**, 744–751 (2019). https://doi.org/10.1111/2041-210X.13152
68. Bird, T. J. et al. Statistical solutions for error and bias in global citizen science datasets. *Biol. Conserv.* **173**, 144–154 (2014). https://doi.org/10.1016/j.biocon.2013.07.037
69. Sofaer, H. R. et al. Development and delivery of species distribution models to inform decision-making. *BioScience* **69**, 544–557 (2019). https://doi.org/10.1093/biosci/biz045
70. Hurlbert, A. H. & Liang, Z. Spatiotemporal variation in avian migration phenology: citizen science reveals effects of climate change. *PLoS ONE* **7**, e31662 (2012). https://doi.org/10.1371/journal.pone.0031662
71. Thomas, C. D. Climate, climate change and range boundaries. *Divers. Distrib.* **16**, 488–495 (2010). https://doi.org/10.1111/j.1472-4642.2010.00642.x
72. Allison, P. D. Discrete-time methods for the analysis of event histories. *Sociol. Methodol.* **13**, 61–98 (1982). https://doi.org/10.2307/270718
73. Singer, J. D. & Willett, J. B. It's about time: using discrete-time survival analysis to study duration and the timing of events. *J. Educ. Stat.* **18**, 155–195 (1993). https://doi.org/10.3102/10769986018002155
74. Elith, J., Kearney, M. & Phillips, S. The art of modelling range-shifting species. *Methods Ecol. Evol.* **1**, 330–342 (2010). https://doi.org/10.1111/j.2041-210X.2010.00036.x
75. Zurell, D., Elith, J. & Schröder, B. Predicting to new environments: tools for visualizing model behaviour and impacts on mapped distributions. *Divers. Distrib.* **18**, 628–634 (2012). https://doi.org/10.1111/j.1472-4642.2012.00887.x
76. Mesgaran, M. B., Cousens, R. D. & Webber, B. L. Here be dragons: a tool for quantifying novelty due to covariate range and correlation change when projecting species distribution models. *Divers. Distrib.* **20**, 1147–1159 (2014). https://doi.org/10.1111/ddi.12209
77. Yates, K. L. et al. Outstanding challenges in the transferability of ecological models. *Trends Ecol. Evol.* **33**, 790–802 (2018). https://doi.org/10.1016/j.tree.2018.08.001
78. Hartig, F. DHARMa: residual diagnostics for hierarchical (multi-level/mixed) regression models. R package version 0.4 (2024). https://CRAN.R-project.org/package=DHARMa
79. Barr, D. J., Levy, R., Scheepers, C. & Tily, H. J. Random effects structure for confirmatory hypothesis testing: keep it maximal. *J. Mem. Lang.* **68**, 255–278 (2013). https://doi.org/10.1016/j.jml.2012.11.001
80. Schielzeth, H. & Forstmeier, W. Conclusions beyond support: overconfident estimates in mixed models. *Behav. Ecol.* **20**, 416–420 (2009). https://doi.org/10.1093/beheco/arn145
81. Tredennick, A. T., Hooker, G., Ellner, S. P. & Adler, P. B. A practical guide to selecting models for exploration, inference, and prediction in ecology. *Ecology* **102**, e03336 (2021). https://doi.org/10.1002/ecy.3336
82. Mundlak, Y. On the pooling of time series and cross section data. *Econometrica* **46**, 69–85 (1978). https://doi.org/10.2307/1913646

*In-text superscripts [A1]–[A6] refer to references 72, 73, 74, 76, 77 and 78 respectively. All digital object identifiers were verified against Crossref on 26 July 2026. Reference 25 is a companion data descriptor currently under review and will be updated on acceptance.*

---

## Figure legends

**Fig. 1 | Survey effort and accumulated warming contribute comparably to the hazard of a new provincial record.**
**a**, Hazard ratios per standard deviation with 95% Wald confidence intervals, for the four fixed effects, at three species-distribution-model buffers. The dashed line marks no effect. **b**, Marginal predictions of the annual hazard against accumulated warming at the 10th, 50th and 90th percentiles of survey effort; ribbons are 95% confidence intervals on the fixed-effect linear predictor. **c**, Relative importance of each term under four independent criteria: loss of AIC, loss of fixed-effect AUC, loss of conditional *R*², and the absolute standardised coefficient. Larger values indicate greater importance. **d**, Discrimination attributable to fixed effects alone as terms are added, with the random structure held at the main model.

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

**Table 6.** Migratory stratification. Full results in `tables/tbl_v2_migratory_ladder.csv`,
`tbl_v2_migratory_stratified.csv` and `tbl_v2_migratory_interaction_by_group.csv`.

| Group | Events | Warming HR (95% CI) | Effort HR (95% CI) | Warming × effort HR | *P* |
|---|---|---|---|---|---|
| Resident | 218 | 1.363 (1.158–1.605) | 1.293 (1.110–1.506) | 0.942 | 0.54 |
| Partial migrant | 156 | 1.507 (1.244–1.826) | 1.270 (1.030–1.566) | 1.053 | 0.62 |
| Long-distance migrant | 175 | 1.514 (1.265–1.812) | 1.344 (1.130–1.598) | 0.753 | 0.0022 |
| *Moderation tests* | | LR *P* = 0.693 | LR *P* = 0.854 | three-way LR *P* = 0.256 | |

**Fig. 9 | Species-level correlates of new provincial records.**
**a**, Continuous traits, as odds ratios per standard deviation with 95% confidence intervals, under three treatments of phylogenetic non-independence. Filled points are significant. **b**, Categorical contrasts against their reference levels. **c**, Range measured as an area, from two independent sources, against range measured as a count of provinces occupied. **d**, For every term, the number of phylogenetic treatments in which it is significant, with the range of odds ratios across treatments.

**Fig. 10 | Province-level counts of new records.**
**a**, Model comparison: Poisson against negative binomial, with and without recent effort as an offset. **b**, Incidence rate ratios per standard deviation from the two negative-binomial models. **c**, Hierarchical partitioning of explained deviance into independent and joint contributions. **d**, Partial correlation of each predictor with the record count, holding the others constant.

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

**Fig. M1 | Mechanistic projection of the latent generation hazard, restricted to the fitted covariate support.**
Provincial hazard relative to 2024 under two SSP scenarios at three horizons, aggregating only species-province cells whose accumulated warming and survey effort fall inside the 1st–99th percentile of the fitted data. The percentage on each panel is the share of cells that qualify.

**Fig. M2 | Machine-learning projection under identical inputs and the same support mask.**

**Fig. M3 | TreeSHAP interpretation of the gradient-boosted model.** **a**, Mean absolute SHAP contribution per feature. **b**, SHAP dependence, monotone increasing for both accumulated warming and survey effort.

**Fig. M4 | The two model families agree inside the fitted range and diverge outside it.**
**a**, Province-year mean predicted hazard, 2002–2024. **b**, First-to-99th-percentile range of each predictor in the fitted data and in each scenario-horizon combination. **c**, Province-level projected hazard ratios, with rank correlation and directional agreement per panel.

**Extended Data Fig. 1 | Simulation-based residual diagnostics for the main model.**

**Extended Data Fig. 3 | The same mechanistic projection without the support mask**, shown to indicate the magnitude of the extrapolation.
