# Ecological rationale for every model component

This table states, for each element of the main model, why it is there (ecological or
observational rationale), what its estimate means in plain terms, and one falsifiable
prediction that the specification implies. The predictions are all tested in the paper.

Main model:

```
event ~ clim_change_z * effort_z + clim_var_z + offset(log c_t)
        + (1|species) + (1|province) + (1|province:year)
family = binomial("cloglog")
```

## Response

**Specification.** event = 1 in the year a species is first formally recorded in a province, 0 before

**Why it is in the model.** A new provincial record is a one-off transition: a species-province pair can acquire its first record only once. Modelling it as a repeated binary outcome would treat re-documentation as new information, which it is not.

**What the estimate means.** The quantity modelled is the annual probability that a species crosses from undocumented to documented in a province.

**Falsifiable prediction.** If records were re-documentations rather than first records, event years would cluster after the first, not before.

## Link function

**Specification.** complementary log-log

**Why it is in the model.** cloglog is the discrete-time analogue of a continuous proportional-hazards model: the coefficients are hazard ratios and do not depend on the length of the time step. Logit coefficients would change if the panel were monthly rather than annual.

**What the estimate means.** exp(beta) is a hazard ratio per one standard deviation, directly comparable with survival-analysis literature.

**Falsifiable prediction.** Refitting on a coarser time step should leave cloglog coefficients approximately unchanged but shift logit ones.

## Risk set

**Specification.** species x province x year, absorbing exit after the first record; pairs recorded before 2002 removed

**Why it is in the model.** Only species whose modelled range is close enough to a province can plausibly be recorded there, so the denominator is the set of ecologically plausible opportunities rather than all species. A pair already recorded before the window is a prevalent, not an incident, case and is not at risk.

**What the estimate means.** The hazard is conditional on being a plausible candidate that has not yet been recorded.

**Falsifiable prediction.** Tightening the candidate pool from a 50 km to a 200 km buffer should change the denominator but not the coefficients.

## Accumulated warming (clim_change)

**Specification.** trailing W = 15 year mean of x, where x = province anomaly - species-range anomaly, both relative to 1980-2000

**Why it is in the model.** Range boundaries integrate climate over years to decades: a boundary shifts when conditions have been favourable long enough for colonisation and establishment, not because one year was warm. Referencing to the species' own range is essential because absolute warming is near-uniform across China and therefore cannot explain which species should appear where.

**What the estimate means.** HR 1.362 per 0.179 degC: a province that has warmed 0.18 degC more than a species' own historical range has 36% higher annual hazard for that species.

**Falsifiable prediction.** The coefficient should strengthen as W lengthens from 3 to about 15-20 years and then plateau; a purely weather-driven process would show the opposite.

## Annual variability (clim_var)

**Specification.** x minus its trailing mean, the same year's residual

**Why it is in the model.** Separates the decadal signal from year-to-year weather. Included so that the accumulated term cannot absorb a weather effect, and so that a weather effect, if present, is visible.

**What the estimate means.** HR 0.995, P = 0.92: weather in the year of discovery adds nothing once decadal warming is accounted for.

**Falsifiable prediction.** If new records were driven by irruptions or cold snaps, this term would be non-null and the accumulated term would weaken.

## Survey effort (effort_z)

**Specification.** log1p of annual provincial visits, standardised; coverage gaps treated as missing

**Why it is in the model.** A species can only be recorded where someone is looking. Effort is the observation-process counterpart of the ecological process and must be in the model for the climate coefficient to be interpretable.

**What the estimate means.** HR 1.404 per 1 SD; one SD multiplies annual visits by 7.75.

**Falsifiable prediction.** Substituting observers, birding days or records for visits should give a similar coefficient if all four index the same latent effort.

## Warming x effort

**Specification.** product of the two standardised terms

**Why it is in the model.** Two non-exclusive mechanisms predict a negative interaction. Ecologically, sparsely surveyed provinces are disproportionately western and montane, where climatic gradients are steep. Observationally, densely surveyed provinces have already absorbed much of their Wallacean shortfall, so few candidate species remain regardless of climate.

**What the estimate means.** HR 0.849: the marginal effect of warming is steepest where effort is low and flattens where coverage is dense.

**Falsifiable prediction.** If the observational mechanism dominates, the marginal return of effort should also decline through time as gaps are filled - which it does (P = 7.7e-4).

## Offset log c(t)

**Specification.** log of the share of year-t discoveries expected to have been published by 2025

**Why it is in the model.** Records enter the compilation only after publication, so recent years are systematically under-represented. Under incomplete reporting the observed hazard is approximately c(t) times the true hazard, and because the link is logarithmic in the hazard this is exactly an offset rather than an approximation.

**What the estimate means.** Corrects the estimated hazard for right-censoring without consuming a degree of freedom.

**Falsifiable prediction.** Omitting the offset should attenuate the effort coefficient, since censoring is concentrated in the high-effort recent years - and it does (1.372 to 1.245).

## Random intercept: species

**Specification.** (1|species), SD 0.405

**Why it is in the model.** Species differ in intrinsic detectability for reasons the fixed effects do not capture: body size, song conspicuousness, habitat accessibility, population density and taxonomic attention.

**What the estimate means.** One SD multiplies the hazard by 1.50; the fitted species span a 3.7-fold range.

**Falsifiable prediction.** Conspicuous, vocal, open-habitat species should sit at the upper end.

## Random intercept: province

**Specification.** (1|province), SD 0.326

**Why it is in the model.** Provinces differ in their baseline setting for discovery: area, terrain complexity, habitat diversity, observer population and regional research tradition.

**What the estimate means.** One SD multiplies the hazard by 1.39.

**Falsifiable prediction.** Large, topographically complex provinces with active birding communities should sit at the upper end.

## Random intercept: province x year

**Specification.** (1|province:year), SD 0.804

**Why it is in the model.** The observation process operates at the level of a particular region in a particular year: regional survey campaigns, provincial birding festivals, newly established protected areas, and local reporting channels. A model with only species and province intercepts cannot absorb this, so it leaks into whichever fixed effect trends with observational capacity.

**What the estimate means.** The single largest variance component. One SD multiplies the hazard by 2.23, more than either fixed effect; the fitted levels span a 13-fold range.

**Falsifiable prediction.** Adding this level should raise conditional discrimination sharply while leaving fixed-effect discrimination unchanged - conditional AUC rises 0.721 to 0.854 while marginal AUC stays at 0.612.

## Climate baseline

**Specification.** 1980-2000 at both the province and the species-range end

**Why it is in the model.** The baseline defines the climate a species is historically accustomed to and the climate a province historically had. It must end before the analysis period, otherwise part of the warming being tested is written into the reference itself.

**What the estimate means.** Anomalies are measured against the most recent complete period that does not overlap 2002-2024.

**Falsifiable prediction.** Baselines that overlap the study period should attenuate the climate coefficient - and they do: 1.362 (1980-2000), 1.289 (1981-2010), 1.231 (1991-2020).

