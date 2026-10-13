# Supplementary Information



**Warming and survey effort contribute comparably to new bird distribution records when dated to discovery**



Chenchen Ding, et al.



## Supplementary Notes

### Supplementary Note S1. Risk-set construction, publication-lag stationarity and the completeness offset

The released compilation contains 1,029 provincial-level new bird records with a parseable discovery date for 1,028 (99.9%). Of these, 684 could be matched to a species × province cell in the candidate pool defined by species-distribution models plus forced inclusion of every observed event; 657 fall within the 2002–2024 analysis window (Supplementary Table S9). Twenty-six records were discovered before 2002 and therefore describe species already present at the start of the window; because such pairs are prevalent rather than incident cases, we removed them from the risk set entirely rather than treating them as censored. Conversely, eleven species × province pairs whose records were published in 2025 but discovered by 2024 re-enter the analysis under discovery-year dating; under publication-year dating they had been lost beyond the window edge.

Publication lags discovery by a median of one year and a mean of 2.09 years; 81.7% of records lag by at least one year and 26.8% by three or more (Fig. 2a). Re-dating changes the assigned year of 526 of 633 comparable events (83.1%), with a median shift of −1 year and a mean of −1.83 years. The two dating conventions produce qualitatively different time series (Fig. 2b): the publication-year series rises monotonically to 67 events in 2024, whereas the discovery-year series peaks at 59 in 2019 and falls to 14 in 2024. Neither series is a clean description of reality: the publication-year rise is an artefact of aggregating delayed reports, and the discovery-year fall is right-censoring, because records made in 2023–2024 have not yet appeared in print.

We quantified the censoring directly. The compilation extends to publications appearing in 2025, so a record discovered in year *t* can only have been observed if its lag is at most 2025 − *t*. Using the pooled empirical lag distribution, the expected share of discoveries already reported falls from 99.7% for 2002 to 89.5% for 2021, 83.4% for 2022, 73.2% for 2023 and 56.7% for 2024. The pooled distribution is justified because publication lag is stationary over the study period (Spearman correlation between discovery year and lag ρ = −0.016, *P* = 0.685; Wilcoxon comparison of 2002–2010 with 2011–2018 *P* = 0.851; cumulative distributions differ by at most three percentage points at every lag). Because the observed hazard under incomplete reporting is approximately the product of the true hazard and the completeness *c*(*t*), and the complementary log-log link is logarithmic in the hazard, *c*(*t*) enters the linear predictor exactly as an offset log *c*(*t*). We include this offset throughout.

The final risk set at the 50-cell species-distribution-model threshold comprises 8,319 species × province pairs, 185,478 species-province-years and 657 events. After requiring non-missing effort and climate components, the modelling data contain 175,901 rows, 649 events, 392 species and 31 provincial units. The spatial and temporal pattern of the released compilation (dense in the east and south, sparse but not empty in the west, and rising roughly ninefold in annual count between 2002–2004 and 2022–2024) is summarised in Supplementary Fig. S18.

Let *F* be the empirical cumulative distribution of non-negative publication lags and *P*max = 2025 the latest publication year in the compilation. A record discovered in year *t* can have appeared only if its lag is at most *P*max − *t*, so the expected share of year-*t* discoveries already reported is *c*(*t*) = *F*(*P*max − *t*). We verified that lag is stationary across discovery years using Spearman correlation and a Wilcoxon comparison of the first and second halves of the well-reported period (2002–2018), and by comparing the cumulative distributions directly. Under incomplete reporting the observed hazard is approximately *c*(*t*)·*h*(*t*); with a complementary log-log link this is exactly an offset, log(−log(1 − *p*obs)) = η + log *c*(*t*), which we include in every model. Sensitivity analyses omitting the offset and truncating the window at 2021 are reported.

The candidate pool for each species comprises every province in which its species distribution model marks at least a threshold number of suitable grid cells, plus every province in which the species was actually recorded. Cells are those of the 2.5-arc-minute climate surface and have a median area of 18.3 km² (about 4.3 km on a side), so the three thresholds of 50, 100 and 200 cells require roughly 0.9, 1.8 and 3.7 thousand km² of suitable habitat within the province. Each species × province pair contributes one row per year from 2002 until the year of its first record, after which it exits the risk set (absorbing exit). At the 50-cell threshold this yields 8,319 pairs, 185,478 rows and 657 events.

### Supplementary Note S2. Importance criteria and the species-specific climate gradient

In the frozen main model, both drivers raise the hazard and the effect sizes are similar (Fig. 1a; Table 1). One standard deviation of accumulated warming relative to a species' historical range multiplies the annual hazard by 1.362 (95% CI 1.216–1.524; *P* = 8.3 × 10⁻⁸); one standard deviation of survey effort multiplies it by 1.404 (1.245–1.583; *P* = 2.9 × 10⁻⁸). Annual climate variability has no effect (0.995, 0.909–1.090; *P* = 0.92). The two main effects interact negatively (0.849, 0.761–0.948; *P* = 3.7 × 10⁻³): the marginal effect of warming is steepest where effort is low and flattens where coverage is already dense (Fig. 1b).

Two qualifications follow from the resampling analyses described below and should be carried through any reading of these effect sizes. First, the reference point for the warming coefficient is not unity. Permuting accumulated warming among species within a province-year, or permuting the event indicator among the species at risk in a province-year, still returns a hazard ratio of 1.157–1.167, because both permutations preserve the covariance between provincial-annual climate and provincial-annual event counts. The observed 1.362 lies outside that null distribution (*P* = 0.005 in both cases), but the increment attributable to the species-specific referencing is 1.362/1.157 ≈ 1.18 rather than 1.36; the remainder is a structural baseline shared with the null. The effort coefficient behaves differently: permuting effort across years within a province collapses it to 0.980, with the null 95% interval covering unity, so it derives from the temporal alignment of effort and events rather than from any cross-sectional contrast between well- and poorly surveyed provinces. Second, the Wald intervals are slightly narrow with respect to provincial clustering. A cluster bootstrap resampling provinces widens them to 1.20–1.72 for warming and 1.21–1.76 for effort; both lower bounds still exceed unity, and the interaction remains bounded away from it (0.74–0.99). Resampling species instead leaves the intervals essentially unchanged, so the species-level clustering is already absorbed by the random effects.

Because standardised coefficients are hard to picture, we report both in natural units (Supplementary Fig. S4c). One standard deviation of accumulated warming is **0.179 °C**: a province that has warmed by that much more than a species' own historical Chinese range carries a 36% higher annual hazard for that species. Across the observed range of the variable, −0.65 °C to +0.61 °C, the implied hazard spans roughly ninefold. One standard deviation of survey effort corresponds to a **7.75-fold** increase in annual provincial visits, from a median of 60 visits per year to about 465. The sign of the climate variable is also informative: a negative value means the province has warmed *less* than the species' range, and such cells carry a correspondingly lower hazard.

The climate variable is genuinely species-specific, not a relabelled regional index (Supplementary Fig. S4a, b). Decomposing its variance, 39% of the variation in accumulated warming and 55% of the variation in the raw gradient arise *within* province-years, that is, purely from differences among species. In Yunnan in 2020, for example, accumulated warming ranges from +0.309 °C for *Aethopyga christinae*, whose Chinese range has warmed less than Yunnan has, to −0.280 °C for *Coracias garrulus*, whose range has warmed more. A province-level warming index cannot make that distinction and therefore cannot say which species should appear where.

Four independent importance criteria agree that warming and effort are of comparable weight, with warming slightly ahead on discrimination (Fig. 1c). Dropping accumulated warming costs 28.7 AIC units and 0.053 of marginal AUC; dropping survey effort costs 29.5 AIC units and 0.032 of marginal AUC. The interaction costs 6.5 AIC units. Annual variability costs −2.0 AIC units, that is, the model is marginally better without it; we retain it because it is one half of a pre-specified decomposition and its null result is itself informative.

The discrimination ladder makes the point most directly (Fig. 1d). With the random structure held at the main model, fixed-effect-only AUC rises from 0.411 for the null model to 0.559 with effort alone, 0.580 with accumulated warming alone, and 0.610 with both. Climate alone discriminates better than effort alone; neither alone approaches the pair. This is a different conclusion from the one reached under publication-year dating, where effort dominated.

### Supplementary Note S3. Random-effect structure selection

We evaluated six random-effect structures against four criteria rather than AIC alone (Supplementary Fig. S1; Supplementary Table S2). Adding a province-by-year intercept to the conventional species + province structure improves AIC by 93.4 units, raises conditional *R*² from 0.274 to 0.411, raises conditional AUC from 0.721 to 0.854, and raises the intraclass correlation from 0.172 to 0.358. By contrast, marginal AUC, which measures the discrimination attributable to fixed effects, is flat across all six structures (0.607–0.613), confirming that the random structure absorbs observational heterogeneity without redistributing the fixed-effect signal.

Two further structures were tested. A species-specific random slope on accumulated warming (ΔAIC 4.5 relative to the best) and a province-specific random slope on effort (ΔAIC 0.0, the AIC optimum) both fit marginally better, but both *reduce* conditional *R*² (0.403 and 0.395 respectively, against 0.411 for the simpler structure), and their fixed effects are indistinguishable from those of the main model (effort 1.397 and 1.372; warming 1.348 and 1.366). We therefore freeze the three-level intercept structure as the sole main model. It is the most parsimonious of the three statistically indistinguishable options, it has the highest explanatory power, and every one of its terms has a direct ecological or observational reading: intrinsic species detectability, regional survey context, and the province-year shocks through which surveys, festivals and reporting channels actually operate. No variance component collapses in any structure (minimum standard deviation 0.274).

Each random term corresponds to a distinct process, and the fitted magnitudes are themselves results (Supplementary Fig. S4d, Fig. 3; Supplementary Table S4).

*Species (SD 0.405).* Species differ in intrinsic detectability for reasons no covariate in the model captures: body size, song conspicuousness, habitat accessibility, population density and taxonomic attention. One standard deviation multiplies the hazard by 1.50, and the fitted species span a 3.7-fold range. Grouping the species intercepts by migratory strategy shows overlapping distributions with a modestly higher median for partial migrants than for residents or long-distance migrants (Fig. 3a), consistent with partial migrants combining range-edge mobility with the year-round observability that long-distance migrants lack.

*Province (SD 0.326).* Provinces differ in their baseline setting for discovery: area, terrain complexity, habitat diversity, observer population and regional research tradition. One standard deviation multiplies the hazard by 1.39 (Fig. 3b).

*Province by year (SD 0.804).* This is the single largest variance component in the model, and it is the reason the level was added. One standard deviation multiplies the hazard by 2.23 (more than either fixed effect), and the fitted levels span a thirteenfold range (Fig. 3c). Ecologically it represents the scale at which the observation process actually operates: a regional survey campaign, a provincial birding festival, a newly established protected area, or a new local reporting channel raises the documentation rate for one province in one year. Because such shocks are not shared nationally, a model with only species and province intercepts cannot absorb them, and they leak into whichever fixed effect trends with observational capacity. The magnitude of this component is the quantitative expression of the paper's central caution: the biodiversity record moves for reasons that have nothing to do with the birds.

*Reporting completeness offset.* Not a free parameter but a known correction, so it consumes no degrees of freedom. Omitting it attenuates the effort coefficient from 1.372 to 1.245, because censoring is concentrated in the recent, high-effort years.

### Supplementary Note S4. Migratory stratification

New provincial records could plausibly arise by different routes in different migratory
strategies. Residents disperse slowly, so a first record should more often mark a genuine
boundary shift. Long-distance migrants are highly mobile and can appear far outside their range
as vagrants or storm-displaced individuals, processes driven by navigation error and weather
rather than by decadal warming at the destination, and they are visible only on passage. We
therefore tested whether migratory strategy moderates either driver (Supplementary Fig. S5; Supplementary Table S5).

The analysis uses the three groups with a known strategy: 137 resident, 72 partial-migrant and
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

Fitting each group separately gives the same picture (Supplementary Fig. S5b). Accumulated warming raises the
hazard in every group: 1.363 (95% CI 1.158–1.605) in residents, 1.507 (1.244–1.826) in partial
migrants and 1.514 (1.265–1.812) in long-distance migrants. So does survey effort, at 1.293,
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
hypothesis for a larger compilation rather than as a result (Supplementary Fig. S5d).

### Supplementary Note S5. Species-level and province-level companion analyses

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

Two effects hold under all three treatments (Supplementary Fig. S6a, b, d). Partial migrants are about twice as
likely as residents to yield a new provincial record (odds ratio 1.91–2.50 across treatments, all
*P* < 0.001), and range size raises the odds by 1.23–1.46 per standard deviation. This converges
with the hazard model from a different direction: partial migrants also carry the highest raw
event rate there (0.417% against 0.29–0.33%). Body mass, clutch size, habitat breadth, diet
breadth, number of congeners, hand-wing index, IUCN status, endemism and trophic niche are all
null, in contrast to the mammal study, where smaller-bodied, nocturnal and data-deficient
species were more likely to be newly recorded.

Pooling all species conceals two group-specific patterns that a stratified fit recovers
(Supplementary Fig. S6alt a, b; Supplementary Table S8). Splitting taxonomically, range size acts within Passeriformes
(1.53, *P* = 0.0020) but not within non-passerines, whereas the partial-migrant effect is present
in both and is stronger outside the passerines (3.19, *P* = 3.3 × 10⁻⁴, against 2.01,
*P* = 0.0081). Splitting instead by migratory strategy is more revealing. Among residents only
range size matters (1.60, *P* = 0.0042). Among full migrants neither range size nor migratory
class can act, and two traits that are null in the pooled model become significant: the hand-wing
index, a standard index of dispersal ability, *lowers* the odds (0.51, *P* = 3.8 × 10⁻⁴), and body
mass raises them (1.74, *P* = 0.0037). Both fit a vagrancy mechanism. A migrant with poor flight
efficiency is more easily displaced off its normal route, and a large-bodied bird sitting far
outside its range is more likely to be noticed and reported. The pooled model averages these
against residents, for whom neither applies, and returns zero for both.

*Imputed traits.* Trait gaps were filled by random forest, but the out-of-bag error for
continuous traits is no better than mean imputation (NRMSE 1.00; the categorical error is
acceptable at PFC 0.11), so imputed values are flagged per trait and should not be treated as
equivalent to measured ones. Only 51 of the 1,298 modelled species (3.9%) carry an imputed value
among the main-model traits, and 12 of those have a record. Refitting without them leaves the
conclusions intact. Of the 20 terms, 17 retain the same sign and significance, and all three
significant effects survive: range size 1.456 → 1.309 (*P* 1.1 × 10⁻⁴ → 4.5 × 10⁻³), partial
migrant 1.889 → 2.200 (9.7 × 10⁻⁴ → 6.5 × 10⁻⁵), open habitat 0.541 → 0.598 (2.1 × 10⁻³ →
1.1 × 10⁻²). One caveat belongs with this: on the reduced subset the phylogenetic logistic
regression reports α at its upper bound and fails to converge cleanly. The full model's α of 0.597
is already close to that bound of 0.620, which indicates weak phylogenetic signal at this scale
rather than a problem specific to the subset. We therefore repeated the sensitivity under
taxonomic nesting and phylogenetic eigenvectors, which converge normally and return the same two
headline effects (partial migrant 2.59 and 2.57, both *P* < 5 × 10⁻⁶; range size 1.22,
*P* = 0.041).

Range size must be measured as an **area**, not as a count of provinces occupied (Supplementary Fig. S6c;
Supplementary Table S6). Both area measures are independent of the response and agree: global range area gives
an odds ratio of 1.456 (95% CI 1.204–1.762, *P* = 1.1 × 10⁻⁴, n = 1,298) and Chinese range area,
taken from BirdLife polygons clipped to China, gives 1.653 (1.420–1.925, *P* = 9.0 × 10⁻¹¹,
n = 1,003). The count of provinces occupied does not qualify: the trait database was published in
2022 and its provincial counts therefore already contain the 2002–2021 records used as the
response. Species with a new record occupy a median of 14 provinces against 4 for those without,
that variable returns an odds ratio of 2.09 (*P* = 5 × 10⁻¹⁵), and it absorbs the area effect
entirely when both are entered (area 0.96, *P* = 0.70). We report only the area measures.

*Province level.* Counts of new records per province are overdispersed relative to Poisson
(dispersion 5.60, *P* = 2.3 × 10⁻¹⁷); a negative binomial is adequate (1.24, *P* = 0.20, θ = 6.11)
and passes simulation-based diagnostics (Supplementary Fig. S7a; Supplementary Table S7). In the count model only regional
species richness is significant (incidence rate ratio 1.27, *P* = 0.036). The informative model is
the one that treats recent survey effort as an offset, so that the response becomes the discovery
rate per unit of effort: there, provinces already well covered in 2002–2008 yield fewer records
per unit of recent effort (0.71, *P* = 0.028), as does higher GDP per capita (0.61, *P* = 0.0027)
(Supplementary Fig. S7b). Hierarchical partitioning attributes 51.2% of the explained deviance to species
richness, 33.3% to area and 9% to the two effort terms combined, with the full model explaining
20.5% of deviance (Supplementary Fig. S7c).

Effort therefore appears at the provincial scale not as a count effect but as diminishing
returns; the hazard model shows the same signal as an effort coefficient that falls through time.
Two analyses at different levels, on different response variables, converge on the conclusion that
China's observational capacity is now large enough that additional effort recovers progressively
less of what remains undocumented.

One adaptation must be stated. The mammal study measured historical survey effort as publication
counts for 1949–2000. No bird analogue exists in these data: the observation database holds seven
reports before 2000 and 29 of 31 provinces have none. Early (2002–2008) and recent (2009–2024)
coverage therefore take that role, which preserves the question of whether provinces already well
covered show diminishing returns, but on a shorter timescale than the original.

### Supplementary Note S6. Direction of new records against geometric and effort-weighted nulls

Bearings from the centroid of each species' global range (AVONET) to its new records are far from uniform (χ² = 580.1, df = 7, *P* = 4.6 × 10⁻¹²¹; Fig. 4a): east holds 237 of 642 records (36.9%) and northeast 179 (27.9%), whereas south and west hold 20 and 19. A uniform expectation is the wrong benchmark, however. Many of these species have ranges centred west or south of China, so a record anywhere in China lies east or north of the centroid by position alone. We therefore built two Monte Carlo nulls (999 draws) in which every record is reassigned to one of its species' candidate provinces, located at the mean position of that province's new records, either with equal probability (geometry) or in proportion to the province's 2002–2024 survey visits (geometry + effort).

The geometric null reproduces the pattern closely: 234.8 records are expected to the east and 158.6 to the northeast, no sector departs from expectation after Holm correction, and the omnibus departure is small (χ² = 10.8, Monte Carlo *P* = 0.039; Fig. 4b; Supplementary Table S11). Adding survey effort to the null reveals a departure that points north (χ² = 25.8, *P* = 0.001). Records fall to the northeast (179 against 153.2 expected) and northwest (31 against 17.9) more often, and to the east (237 against 263.9) and south (20 against 32.1) less often, than the distribution of survey effort predicts (Holm-adjusted *P* = 0.016–0.036); the three northern sectors hold 40.2% of records against 33.0% expected.

Among the five best-sampled orders (Supplementary Table S12), Passeriformes departs from both nulls under both placements of provinces (*P* ≤ 0.007), with its northern sectors in excess (38.7% against 30.4% under the effort-weighted null). Anseriformes departs from both nulls only when provinces are placed at the mean position of their records, a departure carried by three records to the west against 0.6 expected. Accipitriformes, Charadriiformes and Columbiformes are consistent with geometry alone (*P* = 0.23–0.57). Placing every province at a point on its surface gives the same overall result (χ² = 12.0 and 22.5 for the two nulls).

The eastward concentration of raw bearings therefore reflects China's position relative to species' global ranges and carries no information about observers or climate. Net of geometry and effort, new records lie modestly poleward of expectation. Because the nulls place records at province level and weight provinces by total visits, finer-grained effort data could sharpen or weaken this residual signal.

### Supplementary Note S7. Full robustness suite

The conclusions do not depend on any freely chosen analytical decision (Supplementary Fig. S2).

*Species-distribution-model threshold.* A province enters a species' candidate pool when the species distribution model marks at least a threshold number of suitable cells inside it. Cells are those of the 2.5-arc-minute climate surface and have a median area of 18.3 km², so thresholds of 50, 100 and 200 cells correspond to roughly 0.9, 1.8 and 3.7 thousand km² of suitable habitat. Raising the requirement from 50 to 200 cells changes the risk set from 175,901 to 155,435 rows but leaves the coefficients essentially fixed (effort 1.404, 1.405, 1.411; warming 1.362, 1.376, 1.372; interaction 0.849, 0.851, 0.850).

*Climate indicator.* Annual mean temperature carries the signal; warmest-month maximum temperature carries a weaker version of it (hazard ratio 1.30, ΔAIC 9.0 behind the best cell) but shows no interaction with effort; coldest-month minimum temperature and winter mean temperature show no signal at any window (hazard ratios 0.96–1.08, all *P* > 0.12). Annual mean temperature integrates the whole thermal regime, whereas seasonal extremes describe conditions that constrain overwintering or breeding but not the year-round climatic envelope within which a range boundary sits.

*Accumulation window and climate baseline.* Both are analyst choices rather than data-determined ones, so we tested them jointly at windows of 5, 10, 15 and 20 years against the two baselines in common use for this kind of anomaly, 1980–2000 and 1970–2000 (Supplementary Fig. S3).

The 1970–2000 baseline cannot be computed from the WorldClim 2.1 downscaling used in the main analysis, which begins in 1980. We therefore rebuilt the entire climate chain from CRU TS 4.09 at its native 0.5°, which reaches back to 1901, and fitted *both* baselines on it. This separates two things that would otherwise be confounded: comparing WorldClim 1980–2000 with CRU 1980–2000 isolates the effect of changing data source and resolution, and comparing CRU 1980–2000 with CRU 1970–2000 isolates the effect of the baseline period itself.

Three results follow, and each has an ecological reading rather than being merely a robustness statement.

First, the warming coefficient rises with window length in every series, from about 1.16–1.21 at five years to 1.36–1.40 at twenty years (Supplementary Fig. S3a). This is the signature expected of a process that integrates climate over years to decades: a five-year window measures weather rather than climate and dilutes the signal, whereas a boundary shifts only when conditions have been favourable long enough for colonisation and establishment. A finer grid spanning 3 to 23 years (Supplementary Table S10) places the optimum at 18–20 years with AIC rising again by 23 years, so the optimum is interior rather than an artefact of the tested range. We retain 15 years as pre-specified; it lies within 2.2–5.6 AIC units of the optimum in every series.

Second, the effort coefficient is flat at 1.34–1.41 across all twelve combinations (Supplementary Fig. S3b), and the interaction is negative throughout (0.87–1.00; Supplementary Fig. S3c). If the climate and effort terms were competing for the same variance, changing the climate specification would move the effort estimate. It does not, which is direct evidence that the two are separately identified.

Third, the choice between the two baselines is immaterial, and if anything the longer one strengthens the result: at *W* = 15 the hazard ratio is 1.361 under CRU 1970–2000 against 1.307 under CRU 1980–2000, and the main WorldClim 1980–2000 estimate of 1.362 sits between the two. Changing data source and resolution moves the estimate by a similar small amount (1.362 to 1.307), so neither choice is decisive. One caveat follows from the resolution difference and matters for interpretation: because the 0.5° CRU grid smooths the sub-grid topographic variation that the 10-arc-minute downscaling retains, one standard deviation of accumulated warming is 0.058 °C in the CRU series against 0.179 °C in the main one. Standardised hazard ratios remain comparable, but the natural-unit statements in this paper refer to the main, higher-resolution series.

*Effort proxy and missing-data rule.* All twelve combinations of four proxies (visits, observers, birding days, records) and three treatments of the 24 implausible zero cells (coverage gap, bounded within-province interpolation, zero-filling) give effort hazard ratios between 1.25 and 1.52 and warming hazard ratios between 1.35 and 1.37. Because the three missing-data rules yield different sample sizes, AIC is not comparable across them and we compare coefficients only. The coverage-gap interpretation is strongly supported by the data: in 22 of the 24 cells flagged as structural zeros, the immediately adjacent years within the same province record between one and 27 visits, so these are gaps in database coverage rather than years in which birdwatching ceased.

### Supplementary Note S8. Model adequacy and resampling

Simulation-based residual diagnostics indicate a well-calibrated model (Supplementary Fig. S8; Supplementary Table S3). Scaled residuals are uniform (Kolmogorov–Smirnov *P* = 0.74), dispersion is correct (*P* = 0.59) and there is no zero inflation (*P* = 0.59). Two of 23 year levels and two of 31 province levels show within-group deviation at *P* < 0.05, close to the nominal rate. Province-mean residuals show no spatial autocorrelation (Moran's *I* = −0.038 against an expectation of −0.033; permutation *P* = 0.86). The outlier test is significant (95 outliers, *P* < 0.001), as is expected of a binary outcome with an event rate of 0.37%; we report it for completeness rather than as evidence of misspecification.

Three resampling analyses complete the assessment (Supplementary Fig. S9). Three design-preserving permutation nulls, each destroying exactly one association while holding the risk set, the per-province-year event counts, the effort and completeness marginals and the random-effect hierarchy fixed, place every reported coefficient outside its null distribution except annual climate variability, which is null under the design as it is in the fitted model (*P* = 0.16 and 0.31). A cluster bootstrap of 300 resamples shows that provincial clustering inflates the standard errors by a factor of 1.26–1.59 relative to the model-based values, whereas species clustering does not (0.86–1.17); Table 1 therefore reports both intervals. A parametric bootstrap of 150 simulations recovers the coefficients with absolute bias below 0.01 on the log-hazard scale and gives actual coverage of 91.3–95.3% for the nominal 95% interval, consistent with the cluster result. Leaving out each province in turn, and each of ten species deciles, moves the coefficients by at most 4.2%, with 9 of 164 combinations exceeding 3%: no single province or species group carries the result.

The proportional-hazards assumption holds for the focal climate term: the interaction between accumulated warming and time is negligible (β = −0.022, *P* = 0.82). It does not hold for effort (β = −0.211, *P* = 7.7 × 10⁻⁴), which is a substantive result rather than a diagnostic failure: the marginal return of an additional standard deviation of survey effort has declined over 2002–2024, consistent with the progressive saturation of easily detectable gaps. In a model that allows both effects to vary through time, the fixed effects are unchanged in direction and magnitude (effort 1.527, warming 1.369, variability 0.996), and only the interaction loses significance (0.864, *P* = 0.12).

Three design-preserving permutation nulls were constructed, each breaking exactly one association: N1 shuffles accumulated warming among species within each province-year; N2 shuffles survey effort across years within each province; N3 shuffles the event indicator among the species at risk within each province-year. Every null therefore leaves the risk-set size, the per-province-year event count, the marginal distributions of effort and reporting completeness, and the random-effect hierarchy identical to the observed data. Each null was run 199 times and two-sided empirical *P* values were computed from the permutation quantiles. Cluster bootstraps resampled species (392 clusters) and provinces (31 clusters) with replacement, 300 times each; only the resampled grouping variable was renamed, so that the crossed random-effect structure being bootstrapped is preserved. A parametric bootstrap simulated 150 response vectors from the fitted model, including fresh random-effect draws, and refitted. Influence was assessed by refitting with each province, and each of ten randomly assigned species deciles, held out.

A small number of resamples converge to degenerate optima. These leave percentile intervals unaffected but corrupt any statistic based on a mean or a standard deviation, so draws with any |log hazard ratio| exceeding 2 were excluded and their number is reported (3 of 199 in N3; 3 of 300 in the species bootstrap; none elsewhere). Inference is based on percentile quantities throughout. All refits used glmmTMB with `profile = TRUE`, which reduces fit time from 61 to 39 seconds while changing coefficients by less than 10⁻³.

### Supplementary Note S9. Projection detail and covariate support

We projected the fitted hazard under CMIP6 SSP2-4.5 and SSP5-8.5 for 2030, 2050 and 2080, applying the four-model ensemble delta to both the provincial and the species-range end of the climate gradient, and growing effort at scenario-differentiated rates. Applying the delta to one end only would create a climate signal from spatially uniform warming. We then asked how much of each scenario lies inside the range over which the model was fitted (Fig. 5b).

The answer sharply constrains what can be claimed. The historical species-specific gradient has a standard deviation of only 0.18 °C, because provincial and range-wide anomalies largely move together. Future province-minus-range warming differentials reach 2 °C, more than ten standard deviations beyond the fitted range. Consequently, only 47.8% of species-province cells fall inside the fitted covariate support under SSP2-4.5 in 2030, 10.4% in 2050 and 2.1% in 2080; under SSP5-8.5 the corresponding figures are 34.2%, 2.1% and 1.9%.

Restricted to cells inside the support, the mechanistic model projects hazard ratios relative to 2024 of 0.79 to 2.94 (Supplementary Fig. S10). Applied without the mask, the same model produces ratios up to 78 (Supplementary Fig. S11). We regard the masked surfaces as the defensible result and the unmasked ones as an illustration of how far the extrapolation reaches.

A gradient-boosted comparison model trained on the same three predictors reinforces the point. Within the observed range the two model families track each other across province-years (Spearman ρ = 0.54). Outside it they diverge completely: rank correlations across province-scenario cells range from −0.04 to 0.18, and the two agree on the direction of change in only 23.7% of cells, falling to 6.5% under SSP5-8.5 in 2080. The mechanistic model projects increases in 176 of 186 cells; the machine-learning model in 42. The cause is structural: tree ensembles return boundary leaf values once covariates leave the training support and therefore saturate, whereas the complementary log-log model extrapolates linearly on the log-hazard scale. Neither behaviour is validated by the data. TreeSHAP attributions within the training range are monotone increasing for both warming and effort (Supplementary Fig. S17), consistent with the mechanistic coefficients.

CMIP6 four-model ensemble median deltas for annual mean temperature were computed for SSP2-4.5 and SSP5-8.5 at 2030, 2050 and 2080, separately for each province and each species range, and added to both ends of the climate gradient. Effort was grown at 0.30 (SSP2-4.5) and 0.60 (SSP5-8.5) standard deviations per decade. Predictions set the province-by-year random effect to its expectation and the completeness offset to log 1, so the projected quantity is the latent generation hazard. Support was defined as the 1st–99th percentile of the fitted accumulated warming and effort; main projection figures aggregate only cells inside this range, and the share of qualifying cells is reported on every panel.

To separate the two scenario axes we also projected the frozen model over a 2 × 2 × 2 grid: SSP2-4.5 or SSP5-8.5 deltas; effort frozen at 2024 or growing at 0.6 SD per decade (observed pace 1.19); horizons 2030 and 2050. Province-by-year effects for future years were set to their expectation, species and province effects retained, and provincial expectations summed over species. Future county surfaces hold the 2024 allocation shares fixed.

### Supplementary Note S10. Nature-reserve conditional logistic analysis

Twenty-six per cent of new records fall inside one of the 1,028 mapped Chinese nature reserves, against a land-area share of 10.4%. This apparent 2.5-fold enrichment would ordinarily be read as evidence that the reserve network is receiving redistributing species. We tested that reading against the observation process directly, using 2.86 million GBIF/eBird checklists (172,079 checklists at 43,571 distinct locations, 2002–2023) to define availability as *where birdwatchers actually went*. Each event was matched to 200 control locations drawn from the same province and year, weighted by the checklists recorded there, and analysed by conditional logistic regression (Supplementary Fig. S13).

Nationally, birding effort is not concentrated in reserves: the checklist-weighted share inside reserves is 10.8%, indistinguishable from the area share. Conditioning on province and year, the enrichment falls from 2.5-fold to an odds ratio of 1.71 (95% CI 1.39–2.11), and to 1.57 (1.26–1.96) after adding elevation, longitude and two bioclimatic covariates. The distance analogue is consistent (0.82 per standard deviation of log distance to the nearest reserve, 0.75–0.90).

Three features of the residual association argue that it too is largely observational. First, it is carried by very few sites: the 172 inside-reserve events fall in only 68 reserves (6.6% of the 1,028), the top two account for 27.3%, and a block bootstrap resampling host reserves rather than records widens the interval to 0.89–3.19. Dropping the two largest hosts leaves 1.16 (0.92–1.47). Second, it is confined to the period of rapid growth in birdwatching: the odds ratio is 2.05 (1.61–2.59) for 2013–2023 but 0.97 (0.62–1.50) for 2002–2012, although the mapped reserve network gained no area after 2012. Third, checklists made inside reserves record 18.9 species on average against 15.3 outside, a 24% difference in per-visit yield that stratification by province and year cannot remove. Two competing explanations were tested and rejected: the enrichment is not driven by professional survey work (inside-reserve share is 28.5% for birdwatching-type discoveries, 26.3% for specimen, camera-trap and ringing discoveries), and it is not an artefact of coordinate precision (the share rises smoothly from 26.2% to 37.6% across 0–5 km buffers, with no threshold jump).

Because within-site observation bias cannot be conditioned out, we treat the inference as asymmetric and state the rule in advance: a null result would be strong evidence, a positive result weak. The odds ratio of 1.57 is therefore an upper bound on any ecological contribution, and the operational conclusion is that counts of new records inside reserves should not be used as an indicator of reserve performance.

Whether a first record becomes a persistent presence is unrelated to reserve status. Using subsequent detections of the same species in the same province in the checklist layer, 41.1% of first records were re-detected at least once and 22.5% in three or more later years. Subsequent survey effort grew from 148 checklists province-wide in 2002 to 14,974 in 2023 and dominates re-detection. Once it is controlled for, the inside-versus-outside odds ratios are 1.01 (0.62–1.64) and 1.10 (0.61–1.99) (Supplementary Fig. S14). The confidence intervals are slightly wider than our pre-declared equivalence bounds of 0.67–1.5, so we report no detectable difference rather than equivalence. These figures also give the first empirical handle on the vagrancy objection: provincial first records are not predominantly vagrants, but neither are they predominantly colonisations.

Finally, the reserve network shows no measurable mismatch with observed warming, contrary to a widely repeated expectation. The warming fields distributed with the gridded panel are provincial values broadcast to cells, with only 31 distinct values nationally. With warming recomputed at the cell level from CRU TS 4.09 instead, the area-weighted reserve coverage across warming quintiles ranges only from 8.5% to 11.8%, a 1.2-fold spread, against the 8.5-fold spread the broadcast field implies (Supplementary Fig. S15a). An area-weighted fractional logit gives β = −0.022 (−0.107 to 0.063, P = 0.61), and permuting coverage 999 times within province × 500 m elevation strata places the observed within-stratum correlation (ρ = −0.013) squarely inside the null envelope (P = 0.48). What the network does lack is monitoring: crossing the upper tercile of warming with the lower tercile of recent birding effort identifies 39.3 × 10⁴ km² inside existing reserves, where standardised monitoring could be grafted onto existing management, and 160.3 × 10⁴ km² outside any mapped reserve, where new survey capacity would be required.

All statements in this section apply only to the 1,028 mapped, predominantly national-level reserves established before 2012; the vector layer excludes the national parks designated from 2021, nature parks, and the ecological conservation red lines. Because reserve status has almost no temporal variation within the study window (none of the 172 inside-reserve events pre-dates its host reserve's designation), we make no causal claim and report no before–after or difference-in-differences estimate.

---

### Supplementary Note S11. Model families, prediction scales and independent climate × effort scenarios

Treating climate and survey effort as independent scenario axes separates their influence on future record generation (Supplementary Fig. S19). With effort frozen at its 2024 level, switching from SSP2-4.5 to SSP5-8.5 leaves the national expectation essentially unchanged (23.2 versus 23.1 first records per year in 2030; 23.6 versus 23.7 in 2050). Allowing effort to keep growing at 0.6 SD per decade (half the observed 2002–2024 pace) raises the 2050 expectation to 57–62 records per year, but only 2% of species–province cells then remain inside the fitted covariate support, against 40–44% under frozen effort. The projected record stream is therefore governed by the survey-effort scenario rather than the climate scenario, and the effort-driven increase lies almost entirely outside the range in which the model can be trusted.

Two further tree-ensemble families fitted under identical validation designs behave like the gradient-boosted model: a random forest and XGBoost lead the mechanistic model on leave-species folds (PR-AUC 0.0120 and 0.0118 versus 0.0054) but fall behind it on temporal forward-prediction (0.0067 and 0.0072 versus 0.0098) and on leave-one-province allocation at county level (rank percentile 0.31 and 0.35 versus 0.28; Supplementary Fig. S20). The three families nevertheless agree on where the next records will fall: Spearman ρ between their 2024 prediction surfaces is 0.62–0.90 across province, prefecture and county (Supplementary Fig. S21). Run through the same scenario grid, however, the families diverge sharply in how much scenarios matter (Supplementary Fig. S22 and Supplementary Fig. S23). After calibrating all three to the same 2024 national total (22.4 records per year), the mechanistic model rises to 57.4 records per year under SSP2-4.5 with continued effort growth in 2050, whereas the random forest stays locked at 23.0 and XGBoost falls to 6.1. Both ensembles return boundary leaf values once year and effort leave the training range, so their projected trend, flat in one case and reversed in the other, is an artefact of the algorithm rather than an estimate that the data can adjudicate.

The projection comparison used a gradient-boosted model (XGBoost, 400 rounds, learning rate 0.05, depth 4)^36^ on the same three predictors, with exact TreeSHAP attributions^35^. For the cross-validated comparison, a random forest (ranger, 800 trees, class-balanced down-sampling) and XGBoost (300 rounds, learning rate 0.05, depth 5, positive-class weight n₀/n₁) were fitted to the province-level risk set under the main model's four validation schemes with identical folds and to the prefecture- and county-level allocation sets under temporal and leave-one-province splits with within-stratum rank skill. Hyperparameters were fixed, not tuned per fold.

## Supplementary Tables

### Supplementary Table S1. Step-by-step decomposition S0–S5

Step-by-step decomposition from the previously published specification to the corrected main model.

| Step | Change | *n* | Events | HR effort | HR warming | HR variability | HR interaction |
|---|---|---|---|---|---|---|---|
| S0 | previously published | 182,485 | 655 | 1.788 | 1.394 | 0.850 | 0.876 |
| S1 | + discovery-year dating | 181,134 | 646 | 1.305 | 1.437 | 0.971 | 0.859 |
| S2 | + coverage-gap effort | 175,686 | 638 | 1.267 | 1.432 | 0.958 | 0.863 |
| S3 | + area-weighted climate | 175,901 | 649 | 1.289 | 1.432 | 0.958 | 0.863 |
| S4 | + completeness offset | 175,901 | 649 | 1.448 | 1.428 | 0.962 | 0.862 |
| S5 | + province × year effect | 175,901 | 649 | **1.404** | **1.362** | **0.995** | **0.849** |

### Supplementary Table S2. Random-effect structure comparison on four criteria

Random-effect structure comparison on four criteria.

| Structure | ΔAIC | McFadden *R*² | Marginal *R*² | Conditional *R*² | Marginal AUC | Conditional AUC | ICC |
|---|---|---|---|---|---|---|---|
| species | 163.1 | 0.0142 | 0.108 | 0.183 | 0.613 | 0.687 | 0.084 |
| species + province | 98.7 | 0.0220 | 0.124 | 0.274 | 0.612 | 0.721 | 0.172 |
| + year | 74.8 | 0.0250 | 0.069 | 0.277 | 0.607 | 0.737 | 0.224 |
| **+ province × year (main)** | **5.25** | **0.0331** | **0.082** | **0.411** | **0.612** | **0.854** | **0.358** |
| + species warming slope | 4.48 | 0.0334 | 0.080 | 0.403 | 0.612 | 0.865 | 0.351 |
| + province effort slope | 0.00 | 0.0339 | 0.082 | 0.395 | 0.611 | 0.852 | 0.341 |

### Supplementary Table S3. Model adequacy checks

Model adequacy.

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

### Supplementary Table S4. Ecological rationale for every model component

Ecological rationale for every component of the main model. Each row states why the
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

### Supplementary Table S5. Migratory stratification

Migratory stratification. Full results in `tables/tbl_v2_migratory_ladder.csv`,
`tbl_v2_migratory_stratified.csv` and `tbl_v2_migratory_interaction_by_group.csv`.

| Group | Events | Warming HR (95% CI) | Effort HR (95% CI) | Warming × effort HR | *P* |
|---|---|---|---|---|---|
| Resident | 218 | 1.363 (1.158–1.605) | 1.293 (1.110–1.506) | 0.942 | 0.54 |
| Partial migrant | 156 | 1.507 (1.244–1.826) | 1.270 (1.030–1.566) | 1.053 | 0.62 |
| Long-distance migrant | 175 | 1.514 (1.265–1.812) | 1.344 (1.130–1.598) | 0.753 | 0.0022 |
| *Moderation tests* | | LR *P* = 0.693 | LR *P* = 0.854 | three-way LR *P* = 0.256 | |

### Supplementary Table S6. Species-level range measures

Species-level range measures, all from phylogenetic logistic regression on the dated
tree. Full results in `tables/tbl_v2_species_range_measures.csv` and
`tbl_v2_species_range_circularity.csv`.

| Measure | *n* | Species with a record | OR per SD (95% CI) | *P* |
|---|---|---|---|---|
| Global range area (AVONET) | 1,298 | 334 | 1.456 (1.204–1.762) | 1.1 × 10⁻⁴ |
| China range area (BirdLife, clipped) | 1,003 | 312 | 1.653 (1.420–1.925) | 9.0 × 10⁻¹¹ |
| Provinces occupied (*not reported as a result*) | 1,298 | 334 | 2.09 | 5 × 10⁻¹⁵ |

### Supplementary Table S7. Province-level models

Province-level models. Full results in `tables/tbl_v2_province_*.csv`.

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

### Supplementary Table S8. Species-level effects within groups

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

### Supplementary Table S9. Risk-set bridge from compilation to modelling data

| threshold | step | pairs | rows | events | note |
|---|---|---|---|---|---|
| 50 | 1. v1 candidate pairs | 8330 |  |  | SDM pool + v1 forced events |
| 50 | 2. drop prevalent (discovered <2002) | 8308 |  |  | 22 pairs removed |
| 50 | 3. force in all re-dated events | 8319 |  |  | 11 event pairs added |
| 50 | 4. expand with absorbing exit | 8319 | 185478 | 657 |  |
| 50 | 5. usable under main specification | 8140 | 175901 | 649 | coverage-gap effort + W15 tavg_annual components non-missing |
| 100 | 1. v1 candidate pairs | 7667 |  |  | SDM pool + v1 forced events |
| 100 | 2. drop prevalent (discovered <2002) | 7645 |  |  | 22 pairs removed |
| 100 | 3. force in all re-dated events | 7656 |  |  | 11 event pairs added |
| 100 | 4. expand with absorbing exit | 7656 | 170229 | 657 |  |
| 100 | 5. usable under main specification | 7656 | 165135 | 649 | coverage-gap effort + W15 tavg_annual components non-missing |
| 200 | 1. v1 candidate pairs | 7225 |  |  | SDM pool + v1 forced events |
| 200 | 2. drop prevalent (discovered <2002) | 7203 |  |  | 22 pairs removed |
| 200 | 3. force in all re-dated events | 7217 |  |  | 14 event pairs added |
| 200 | 4. expand with absorbing exit | 7217 | 160132 | 657 |  |
| 200 | 5. usable under main specification | 7217 | 155435 | 649 | coverage-gap effort + W15 tavg_annual components non-missing |

### Supplementary Table S10. Fine accumulation-window grid, 3–23 years

| indicator | window | n | events | AIC | HR_change | P_change | HR_effort | P_effort | HR_var | P_var | HR_int | P_int | cor_change_var | sd_change | sd_var |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| tavg_annual | 5 | 175901 | 649 | 8334.74547010848 | 1.16687433053163 | 0.00308143421236181 | 1.39203175633644 | 8.22817372592171e-08 | 1.0102091915128 | 0.824289105225732 | 0.897275949066271 | 0.044704290400132 | 0.0229924154514988 | 0.244518445153784 | 0.307624841763943 |
| tavg_annual | 10 | 175901 | 649 | 8327.8514269459 | 1.21277497955454 | 0.000613392432158084 | 1.4067312756397 | 3.39416619968756e-08 | 1.02214487466341 | 0.632978890821376 | 0.846781407584866 | 0.00195203763706829 | -0.00202422619321214 | 0.204928042873436 | 0.340835089204242 |
| tavg_annual | 15 | 175901 | 649 | 8313.15361099188 | 1.36164754167317 | 8.33903878612454e-08 | 1.4038169859134 | 2.89651690863056e-08 | 0.995095739809156 | 0.91565385817717 | 0.84924794872335 | 0.00365005267236242 | -0.00581566949011493 | 0.179344940725948 | 0.35561002852531 |
| tavg_annual | 20 | 175901 | 649 | 8310.95070849146 | 1.39643304332344 | 1.48837451312238e-08 | 1.39987775187103 | 3.06713113126806e-08 | 1.0000016932692 | 0.999971191251049 | 0.823324494218752 | 0.000330950948500261 | 0.0396801488719948 | 0.15415453723643 | 0.360154997655603 |

### Supplementary Table S11. Direction of new records by sector against Monte Carlo geometric and effort-weighted nulls

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
| Geometry + effort | North | 48 | 41.1 | 32–50 | 1.17 | 0.492 |
| Geometry + effort | Northeast | 179 | 153.2 | 139–169 | 1.17 | 0.016 |
| Geometry + effort | East | 237 | 263.9 | 246–282 | 0.90 | 0.036 |
| Geometry + effort | Southeast | 52 | 64.7 | 53–75 | 0.80 | 0.168 |
| Geometry + effort | South | 20 | 32.1 | 24–40 | 0.62 | 0.036 |
| Geometry + effort | Southwest | 56 | 49.6 | 42–58 | 1.13 | 0.492 |
| Geometry + effort | West | 19 | 19.7 | 12–27 | 0.96 | 0.988 |
| Geometry + effort | Northwest | 31 | 17.9 | 11–26 | 1.74 | 0.028 |

### Supplementary Table S12. Omnibus tests of direction against Monte Carlo nulls, all records and five orders

| Scope | Null | Records | χ² vs null | Monte Carlo P | East sectors obs./exp. (%) | North sectors obs./exp. (%) |
|---|---|---|---|---|---|---|
| Overall | Geometry | 642 | 10.8 | 0.039 | 72.9 / 71.4 | 40.2 / 36.6 |
| Overall | Geometry + effort | 642 | 25.8 | 0.001 | 72.9 / 75.0 | 40.2 / 33.0 |
| Overall | Geometry (surface point) | 642 | 12.0 | 0.018 | 72.9 / 71.9 | 40.2 / 37.5 |
| Overall | Geometry + effort (surface point) | 642 | 22.5 | 0.001 | 72.9 / 75.5 | 40.2 / 33.8 |
| Passeriformes | Geometry | 388 | 14.6 | 0.007 | 73.2 / 70.3 | 38.7 / 35.2 |
| Passeriformes | Geometry + effort | 388 | 22.8 | 0.001 | 73.2 / 74.7 | 38.7 / 30.4 |
| Passeriformes | Geometry (surface point) | 388 | 19.3 | 0.003 | 73.2 / 71.1 | 38.7 / 36.1 |
| Passeriformes | Geometry + effort (surface point) | 388 | 25.2 | 0.001 | 73.2 / 75.3 | 38.7 / 31.6 |
| Anseriformes | Geometry | 35 | 11.5 | 0.009 | 77.1 / 77.1 | 2.9 / 2.9 |
| Anseriformes | Geometry + effort | 35 | 11.6 | 0.005 | 77.1 / 77.0 | 2.9 / 2.9 |
| Anseriformes | Geometry (surface point) | 35 | 8.4 | 0.127 | 77.1 / 77.0 | 2.9 / 3.2 |
| Anseriformes | Geometry + effort (surface point) | 35 | 9.2 | 0.051 | 77.1 / 77.0 | 2.9 / 3.0 |
| Accipitriformes | Geometry | 55 | 4.5 | 0.419 | 74.5 / 76.3 | 49.1 / 40.0 |
| Accipitriformes | Geometry + effort | 55 | 8.1 | 0.088 | 74.5 / 79.7 | 49.1 / 37.9 |
| Accipitriformes | Geometry (surface point) | 55 | 5.1 | 0.339 | 74.5 / 76.5 | 49.1 / 40.5 |
| Accipitriformes | Geometry + effort (surface point) | 55 | 8.0 | 0.101 | 74.5 / 79.7 | 49.1 / 38.3 |
| Charadriiformes | Geometry | 32 | 5.4 | 0.230 | 84.4 / 83.5 | 40.6 / 35.7 |
| Charadriiformes | Geometry + effort | 32 | 6.2 | 0.225 | 84.4 / 85.2 | 40.6 / 34.3 |
| Charadriiformes | Geometry (surface point) | 32 | 4.7 | 0.335 | 84.4 / 84.1 | 40.6 / 35.9 |
| Charadriiformes | Geometry + effort (surface point) | 32 | 6.1 | 0.192 | 84.4 / 85.7 | 40.6 / 34.5 |
| Columbiformes | Geometry | 18 | 3.6 | 0.568 | 77.8 / 66.4 | 61.1 / 61.5 |
| Columbiformes | Geometry + effort | 18 | 3.1 | 0.678 | 77.8 / 74.0 | 61.1 / 60.2 |
| Columbiformes | Geometry (surface point) | 18 | 3.8 | 0.500 | 77.8 / 67.1 | 61.1 / 60.8 |
| Columbiformes | Geometry + effort (surface point) | 18 | 3.3 | 0.610 | 77.8 / 75.2 | 61.1 / 59.5 |

## Supplementary Figures

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig4_random_structure_v2.png)

**Fig. S1 | Random-effect structures evaluated on fit, explanatory power, variance structure and ecological meaning.**
**a**, ΔAIC; the main model is highlighted. **b**, Conditional *R*², conditional AUC and marginal AUC. Marginal AUC is flat across structures, confirming that the random terms absorb observational heterogeneity without redistributing the fixed-effect signal. **c**, Random-effect standard deviations on the latent scale; no component collapses in any structure.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig3_specification_robustness_v2.png)

**Fig. S2 | The result does not depend on any freely chosen analytical decision.**
**a**, Hazard ratio for accumulated warming across four climate indicators and four accumulation windows; asterisks denote two-sided Wald *P* < 0.05 (*), < 0.01 (**) and < 0.001 (***). **b**, ΔAIC across the same grid, all cells fitted on identical rows. **c**, Hazard ratios with 95% Wald confidence intervals for survey effort (triangles) and accumulated warming (circles) across four effort proxies and three treatments of the 24 implausible zero cells. AIC is not comparable across missing-data rules because the sample sizes differ, so only coefficients are shown.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig7_window_baseline_sensitivity_v2.png)

**Fig. S3 | Accumulation window and climate baseline.**
Windows of 5, 10, 15 and 20 years against three series: the main WorldClim 10-arc-minute data with a 1980–2000 baseline, the same baseline computed from CRU TS at 0.5° as a control for data source and resolution, and CRU TS with a 1970–2000 baseline. **a**, Hazard ratio for accumulated warming. **b**, Hazard ratio for survey effort. **c**, Hazard ratio for the interaction. **d**, ΔAIC within each series; circles mark the optimum. Ribbons are 95% confidence intervals.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig5_model_anatomy_v2.png)

**Fig. S4 | Anatomy of the model, in units a reader can picture.**
**a**, Construction of the species-referenced climate gradient, shown as 15-year trailing means for one province and two species. Yunnan has warmed more than the Chinese range of *Aethopyga christinae* and less than that of *Coracias garrulus*, so the same province in the same year yields opposite values of *x* for the two species. **b**, Variance of each climate term partitioned into variation between province-years and variation within a province-year, the latter arising purely from differences among species. **c**, Partial effects in natural units: annual hazard against how much more the province has warmed than the species' range, at three levels of survey effort expressed as annual visits. **d**, Every variance component and both focal fixed effects expressed as the hazard multiplier per one standard deviation, on a common axis.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig8_migratory_strategy_v2.png)

**Fig. S5 | Migratory strategy shifts the baseline hazard but does not moderate either driver.**
**a**, Risk-set rows, events and species in each group; the three groups with a known strategy carry 549 events in total. **b**, Group-specific hazard ratios from models fitted separately within each group, with 95% confidence intervals. **c**, ΔAIC across the moderation ladder; red text is the likelihood-ratio *P* value against the model with a migratory main effect only. **d**, Group-specific warming × effort interaction derived from the three-way model; filled points are significant within group, open points are not. The formal test for heterogeneity among groups is not significant.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig9_species_level_v2.png)

**Fig. S6 | Species-level correlates of new provincial records.**
**a**, Continuous traits, as odds ratios per standard deviation with 95% confidence intervals, under three treatments of phylogenetic non-independence. Filled points are significant. **b**, Categorical contrasts against their reference levels. **c**, Range measured as an area, from two independent sources, against range measured as a count of provinces occupied. **d**, For every term, the number of phylogenetic treatments in which it is significant, with the range of odds ratios across treatments.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/Fig10_province_level_v2.png)

**Fig. S7 | Province-level counts of new records.**
**a**, Model comparison: Poisson against negative binomial, with and without recent effort as an offset. **b**, Incidence rate ratios per standard deviation from the two negative-binomial models. **c**, Hierarchical partitioning of explained deviance into independent and joint contributions. **d**, Partial correlation of each predictor with the record count, holding the others constant.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/FigS1_dharma_v2.png)

**Fig. S8 | Simulation-based residual diagnostics for the main model.**
**a**, Quantile–quantile plot of DHARMa scaled residuals against the uniform distribution, from 500 simulations; every 40th point is drawn. **b**, Kolmogorov–Smirnov *P* values for the residuals of each year and each province, against the nominal 5% level. **c**, Moran's *I* of province-mean residuals against a null distribution from 999 permutations of province labels, with inverse-distance weights. **d**, Rate of change of each focal coefficient with time on the log-hazard scale, testing the proportional-hazards assumption.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures/FigS5_resampling_v2.png)

**Fig. S9 | Design-preserving null models, resampling and influence.**
**a**, Null distributions of the four fixed effects under three permutation schemes, each destroying exactly one association while holding the risk set, the per-province-year event counts, the effort and completeness marginals and the random-effect hierarchy fixed (199 permutations each); red lines mark the observed values. The null for accumulated warming is centred near 1.16 rather than unity because permuting within province-years preserves the covariance between provincial-annual climate and provincial-annual event counts. **b**, Wald and cluster bootstrap confidence intervals, resampling species (392 clusters) and provinces (31 clusters), 300 times each. **c**, Actual coverage of the nominal 95% interval under a parametric bootstrap of 150 simulations from the fitted model, with the bias of each coefficient annotated. **d**, Relative change in each hazard ratio when each province, and each of ten species deciles, is held out. Draws converging to degenerate optima (|log hazard ratio| > 2) are excluded throughout; their number is 3 of 199 in the third null, 3 of 300 in the species bootstrap, and none elsewhere.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_future/FigM1_future_mechanistic_v2.png)

**Fig. S10 | Mechanistic projection of the latent generation hazard, restricted to the fitted covariate support.**
Provincial hazard relative to 2024 under two SSP scenarios at three horizons, aggregating only species-province cells whose accumulated warming and survey effort fall inside the 1st–99th percentile of the fitted data. The percentage on each panel is the share of cells that qualify.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_future/FigS3_future_unmasked_v2.png)

**Fig. S11 | The same mechanistic projection without the support mask**, shown to indicate the magnitude of the extrapolation.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_future/FigM2_future_ml_v2.png)

**Fig. S12 | Machine-learning projection under identical inputs and the same support mask.**
Provincial hazard relative to 2024 from the gradient-boosted model under the same SSP scenarios, horizons and 1st–99th-percentile support mask as the mechanistic projection; the percentage on each panel is the share of qualifying cells.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_pa/en/FigP1_pa_enrichment.png)

**Fig. S13 | Enrichment of new records inside mapped nature reserves, decomposed against the observation process.** **a**, Share of records, checklist-weighted birding effort, birding locations and land area inside the 1,028 mapped reserves. **b**, Conditional logistic estimand ladder, each event matched to 200 same-province same-year checklist-weighted control locations. **c**, Robustness across host-reserve exclusions, period splits and discovery-method subsets. **d**, Concentration of inside-reserve events among host reserves.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_pa/en/FigP2_pa_persistence.png)

**Fig. S14 | Reserve status does not raise the probability that a first record becomes a persistent presence.** Re-detection of the same species in the same province in the GBIF/eBird layer, raw and adjusted for subsequent survey effort, with pre-declared equivalence bounds.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_pa/en/FigP3_pa_mismatch_monitoring.png)

**Fig. S15 | The mapped reserve network shows no measurable mismatch with observed cell-level warming.** **a**, Area-weighted reserve coverage across warming quintiles under provincial-broadcast versus recomputed cell-level warming. **b**, Stratified permutation within province × elevation bands. **c**–**d**, Monitoring-grafting priority classes.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_direction/combined/order_direction_windrose_facets.png)

**Fig. S16 | Per-order directionality of new records relative to species' range centroids.** Wind-rose panels for the sixteen best-sampled orders, each annotated with its number of records and species.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_future/FigM3_shap_interpretability_v2.png)

**Fig. S17 | TreeSHAP interpretation of the gradient-boosted model.** **a**, Mean absolute SHAP contribution per feature. **b**, SHAP dependence, monotone increasing for both accumulated warming and survey effort.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigST1_spatiotemporal_pattern.png)

**Fig. S18 | Spatial and temporal pattern of the released compilation.** **a**, All 1,029 records of CBNR v2, coloured by year of report. **b**, Cumulative records per province. **c**, Annual counts by reported year (bars) and, for the modelled subset, by discovery year (line); their offset motivates the dating correction. **d**, Latitude and longitude of records against year with loess fits. Data: CBNR v2, Zenodo record 20809949 (CC-BY-4.0).

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigMS3_future_scenarios.png)

**Fig. S19 | Future scenarios with climate and survey effort as independent axes.** Predicted number of first records per province under SSP2-4.5 and SSP5-8.5, with effort frozen at 2024 or growing at 0.6 SD per decade, for **a** 2030 and **b** 2050; **c**, county surfaces for 2050 under fixed 2024 allocation shares. Colour is log10 of the expected number; transparency encodes the fraction of species–province cells inside the fitted covariate support; national totals and support fractions are given per panel.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigMS2_multiscale_model_skill.png)

**Fig. S20 | Skill of three model families across validation designs.** **a**, Province-level PR-AUC for the mechanistic model, a random forest and XGBoost under random, leave-species, leave-province and temporal folds (event rate 0.369%; error bars fold SD). **b**, Rank skill of the same families in prefecture- and county-level allocation under temporal forward-prediction and leave-one-province splits (0.5 = random).

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigMS1_multiscale_model_maps_si.png)

**Fig. S21 | Prediction surfaces of three model families at three administrative scales, 2024.** Rows: province, prefecture, county; columns: mechanistic two-stage model, random forest, XGBoost. Each column is internally consistent (its own province stage times its own within-province allocation); colour scales are shared within rows (log10 expected number of records). Basemap GS(2019)1822.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigMS4_future_scenarios_by_model_si.png)

**Fig. S22 | Future projections under the scenario grid, by model family.** **a**–**c**, Predicted first records per province in 2050 for the mechanistic model (**a**), a random forest (**b**) and XGBoost (**c**) under SSP2-4.5 and SSP5-8.5 crossed with effort frozen at 2024 or growing at 0.6 SD per decade. Colour is log10 of the expected number, shared across all twelve maps; transparency encodes the fraction of species–province cells inside the fitted covariate support; national totals and support fractions are given per panel. **d**, National totals across all eight scenarios and both horizons; all three families are calibrated to the same 2024 baseline (22.4 records per year), so the scenario slopes are each family's own.

![](/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/analysis_v2/figures_multiscale/en/FigMS5_future_multiscale_by_model_si.png)

**Fig. S23 | Multi-scale prediction surfaces under one future scenario (SSP2-4.5, continued effort growth, 2050).** Rows: province, prefecture, county; columns: mechanistic model, random forest, XGBoost. Each column is internally consistent (its own provincial expectation times its own within-province allocation shares); prefecture and county surfaces hold the 2024 allocation shares fixed. Colour scales are shared within rows (log10); transparency encodes the in-support fraction. Basemap GS(2019)1822.