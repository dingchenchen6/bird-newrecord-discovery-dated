# Warming, survey effort and the generation of new bird distribution records in China

Data, code, figures and manuscript for a discrete-time hazard analysis of provincial-level
new bird distribution records in China, 2002–2024.

**Headline result.** Dating records to the year they were *discovered* rather than the year
they were *published* changes the answer. Under publication-year dating survey effort appears
to dominate; after re-dating, accumulated warming relative to a species' historical range
(hazard ratio 1.36 per SD) and survey effort (1.40 per SD) contribute comparably, the two
interact negatively (0.85), and an apparent effect of annual climate variability disappears
entirely.

---

## What is in here

```
code/        analysis pipeline, scripts 130-152, run in numerical order
data/        modelling datasets and the panels needed to rebuild them
tables/      every result table cited in the manuscript and report
figures/     Fig1-Fig10 and the diagnostic panel
figures_future/  projection figures FigM1-FigM4 and the unmasked contrast
docs/        manuscript (English) and research report (Chinese)
tests/       smoke test reproducing the headline coefficients
```

Every figure ships as **PNG (450 dpi), PDF, SVG and editable PPTX**, plus the source data
behind it as CSV. In the PPTX every element is a native PowerPoint shape, so the figures can
be recoloured or relabelled without returning to R. Figures whose SVG exceeds 5 MB (the province
maps and the SHAP scatter) ship as PDF only — the SVG is six times the size of the PDF and
carries no extra information.

---

## Quick start

```bash
Rscript --no-init-file setup_workspace.R
Rscript --no-init-file tests/smoke_test.R
```

`setup_workspace.R` builds the working directory layout the scripts expect, hard-linking where
the filesystem allows so no extra disk is used. `smoke_test.R` refits the main model from the
shipped data and checks it against the published coefficients; it takes about two minutes.

---

## Reproducing the analysis

Scripts 133–144 run entirely on data shipped in this repository. Scripts 130–132 and 145 rebuild
the event table, effort panel, modelling matrix and CRU climate panels from primary sources,
some of which are third-party licensed and are not redistributed here — set their paths in
`config.R`.

| Script | Does what | Needs external data? |
|---|---|---|
| `130_redate_events_discovery.R` | Re-dates events to discovery year; publication-lag and reporting-completeness tables | yes (CBNR release) |
| `131_rebuild_effort_coverage_gap.R` | Rebuilds the effort panel with three missing-data rules | no |
| `132_build_model_matrix_v2.R` | Risk sets at three SDM thresholds, area-weighted climate, completeness offset | no |
| `133_model_selection_v2.R` | Random-effect ladder R0–R5 | no |
| `134_indicator_window_v2.R` | 4 climate indicators × 4 accumulation windows | no |
| `135_change_decomposition.R` | Step-by-step decomposition from the previous specification | no |
| `136_re_structure_evaluation.R` | Multi-criterion evaluation of random structures | no |
| `137_full_comparison_matrix.R` | Effort proxies, thresholds, fixed-effect ladder, relative importance | no |
| `138_diagnostics_v2.R` | DHARMa residuals, Moran's *I*, proportional hazards | no |
| `139_figures_v2.R` | Fig1–Fig4 | no |
| `141_future_projection_v2.R` | CMIP6 projections, support mask, mechanistic vs ML | yes (base map) |
| `142_window_baseline_sensitivity.R` | Fine window grid, 3–23 years | no |
| `143_ecological_anatomy_figures.R` | Fig5–Fig6, natural-unit effects and random effects | yes (base map) |
| `144_sensitivity_figure_and_rationale.R` | Fig7 and the ecological rationale table | no |
| `145_baseline_1970_sensitivity.R` | 1970–2000 baseline, rebuilt from CRU TS 0.5° | yes (CRU, ranges, grid) |
| `146_migratory_strategy.R` | Migratory stratification: moderation ladder and stratified fits | no |
| `147_migratory_figure.R` | Fig8 | no |
| `151_harmonise_species_traits.R` | Master trait table: Chinese trait database, BIRDBASE, AVONET, RF imputation | yes (three trait sources) |
| `152_species_level_fast.R` | Species-level fits under three phylogenetic treatments | yes (phylogeny) |
| `149_province_level_geb.R` | Province-level negative binomial, partial regression, hierarchical partitioning | no |
| `150_geb_style_figures.R` | Fig9, Fig10 | no |

Script 134 is run once per climate indicator and then merged:

```bash
for i in tavg_annual tavg_winter tmax_warm tmin_cold; do
  Rscript --no-init-file code/134_indicator_window_v2.R $i
done
Rscript --no-init-file code/134_indicator_window_v2.R --merge
```

Script 137 takes a block argument, and script 142 a baseline argument:

```bash
for b in B C D E; do Rscript --no-init-file code/137_full_comparison_matrix.R $b; done
```

```bash
for b in 1980_2000 1981_2010 1991_2020; do Rscript --no-init-file code/142_window_baseline_sensitivity.R $b; done
Rscript --no-init-file code/142_window_baseline_sensitivity.R --merge
```

Both are split this way because fitting sixteen mixed models in one R session exhausts memory
on a 24 GB machine and the process is killed without an error message.

---

## The model

```
event ~ clim_change_z * effort_z + clim_var_z + offset(log c_t)
        + (1|species) + (1|province) + (1|province:year)
family = binomial("cloglog")
```

A discrete-time proportional-hazards model on the complete species × province × year risk set,
with absorbing exit after the first record. `c_t` is reporting completeness, derived from the
empirical publication-lag distribution; because the observed hazard under incomplete reporting
is approximately `c_t · h_t` and the link is logarithmic in the hazard, `log c_t` enters exactly
as an offset.

| Term | HR per SD | 95% CI | P |
|---|---|---|---|
| Accumulated warming | 1.362 | 1.216–1.524 | 8.3 × 10⁻⁸ |
| Survey effort | 1.404 | 1.245–1.583 | 2.9 × 10⁻⁸ |
| Annual climate variability | 0.995 | 0.909–1.090 | 0.92 |
| Warming × effort | 0.849 | 0.761–0.948 | 3.7 × 10⁻³ |

*n* = 175,901 species-province-years, 649 events, 392 species, 31 provincial units,
AIC 8,313.2, conditional *R*² 0.411, conditional AUC 0.854.

---

## Three things worth knowing before reusing this

**Dating.** Publication lags discovery by a median of one year and a mean of 2.09 years, and
81.7% of records lag by at least one year. Re-dating changes 83.1% of event years. The
`tables/tbl_change_decomposition.csv` file isolates what each correction does.

**AIC comparability.** The effort missing-data rules and the SDM thresholds change the number
of rows, so AIC is not comparable across them. Those comparisons report coefficients only.
This is stated on the relevant figure panels.

**Projection support.** The species-specific climate gradient has a historical standard
deviation of 0.18 °C; future province-minus-range warming differentials reach 2 °C. By 2050
under SSP5-8.5 only 2.1% of species-province cells fall inside the fitted covariate range.
Main projection figures aggregate only cells inside that range and print the qualifying share
on every panel; `figures_future/FigS3_future_unmasked_v2.*` shows what the unmasked
extrapolation looks like, for contrast rather than for use.

---

## Data not redistributed here

Species range polygons (BirdLife International), CRU TS and WorldClim climate surfaces, CMIP6
projections and the official base map are third-party licensed. `config.R` documents where each
is obtained and lets you point the scripts at local copies, either by editing the file or by
setting the corresponding environment variables.

## Citing

The companion data descriptor for the underlying record compilation is under review; see
reference 25 of `docs/MANUSCRIPT_v2.md`.

## Licence

Code is released under the MIT licence (`LICENSE`). Derived result tables and figures are
released under CC BY 4.0. Third-party source data retain their original licences.

---

## Ecological rationale

Every component of the main model — the response definition, the link, the risk set, each fixed
effect, the interaction, the offset and each random term — has a stated ecological or
observational rationale, a plain-language reading of its estimate, and a falsifiable prediction
that the specification implies. See `docs/ECOLOGICAL_RATIONALE.md` and
`tables/tbl_v2_ecological_rationale.csv`. All twelve predictions are tested in the paper.

Effect sizes in natural units, so the standardised coefficients can be pictured:

| Quantity | One standard deviation |
|---|---|
| Accumulated warming | 0.179 °C of province-minus-range warming |
| Survey effort | a 7.75-fold increase in annual provincial visits |
| Species random intercept | hazard × 1.50 |
| Province random intercept | hazard × 1.39 |
| Province-by-year random intercept | hazard × 2.23 — larger than either fixed effect |

## Sensitivity of the two analyst choices in the climate variable

| Choice | Tested over | Result |
|---|---|---|
| Accumulation window | 5, 10, 15, 20 yr (and 3–23 yr on a finer grid) | Warming HR rises from ~1.17 to ~1.40; optimum interior at 18–20 yr; effort HR flat at 1.34–1.41 |
| Climate baseline | 1980–2000 and 1970–2000 | HR 1.362 (WorldClim 1980–2000, main), 1.307 (CRU 1980–2000), 1.361 (CRU 1970–2000) |

The 1970–2000 baseline needs data before 1980, which the WorldClim downscaling does not provide,
so that comparison is run entirely on CRU TS 4.09 at 0.5°. Fitting CRU with the 1980–2000
baseline as well separates the effect of changing the baseline from the effect of changing the
data source. Note that one standard deviation of accumulated warming is 0.058 °C in the CRU
series against 0.179 °C in the main one, because the coarser grid smooths sub-grid topography;
standardised hazard ratios stay comparable but natural-unit statements refer to the main series.

## Figures

| Figure | Shows |
|---|---|
| Fig1 | Main result: coefficients across thresholds, the interaction, relative importance, discrimination ladder |
| Fig2 | The dating correction: publication lag, the two event series, the S0–S5 waterfall |
| Fig3 | Robustness across climate indicators, windows, effort proxies and missing-data rules |
| Fig4 | Random-effect structures on four criteria |
| Fig5 | Anatomy of the model in natural units, and the species-specificity of the climate variable |
| Fig6 | The observation process: species, province and province-by-year random effects, and the declining return on effort |
| Fig7 | Accumulation window and climate baseline sensitivity |
| Fig8 | Migratory stratification: does strategy moderate either driver? |
| Fig9 | Species-level correlates under three phylogenetic treatments |
| Fig10 | Province-level counts: model choice, effort, hierarchical partitioning |
| FigM1–M4 | CMIP6 projections with the covariate-support mask, SHAP interpretation, mechanistic vs ML |
| FigS1, FigS3 | Residual diagnostics; unmasked extrapolation for contrast |

## Migratory strategy

Stratifying by migratory strategy uses the three groups with a known strategy — 137 resident,
72 partial-migrant and 107 long-distance-migrant species, carrying 218, 156 and 175 events.
Species without trait data are excluded rather than pooled: their event rate is 0.791% against
0.29–0.42% elsewhere because they entered the candidate pool only by virtue of having a record,
which is a selection artefact rather than an ecological class.

| Group | Events | Warming HR | Effort HR | Warming x effort HR |
|---|---|---|---|---|
| Resident | 218 | 1.363 (1.158–1.605) | 1.293 (1.110–1.506) | 0.942 (P = 0.54) |
| Partial migrant | 156 | 1.507 (1.244–1.826) | 1.270 (1.030–1.566) | 1.053 (P = 0.62) |
| Long-distance migrant | 175 | 1.514 (1.265–1.812) | 1.344 (1.130–1.598) | 0.753 (P = 0.0022) |

Strategy shifts the baseline hazard (main effect, dAIC 6.2) but moderates neither driver:
likelihood-ratio tests give P = 0.693 for warming x strategy, 0.854 for effort x strategy and
0.256 for the full three-way term. The warming x effort interaction is significant only among
long-distance migrants, but the test for whether the groups differ is not (P = 0.078 for the key
contrast), so that pattern is reported as a hypothesis rather than a finding.

Stratified fits drop the province-by-year random intercept: 689 levels are not identifiable from
156–218 events, and forcing the full structure collapses variance components and yields a
non-positive-definite Hessian. The moderation ladder, fitted on all 549 events, keeps it.

## Species-level and province-level analyses

Two further levels complement the hazard model, following the framework of the companion mammal
study (Ding et al. 2025, *Global Ecology and Biogeography*).

### Species level

Pool: the 1,445 Chinese bird species of the national ecological trait database, of which 1,312
match the Clements 2023 dated phylogeny and 361 acquired at least one new provincial record
(636 of the 657 events; 13 event species are post-2022 taxonomic splits absent from the pool).

Traits come from three sources in order of precedence — the Chinese trait database (mass,
morphometrics, multi-category diet, clutch, nest type and site, flocking, migration, endemism),
BIRDBASE v2025.1 (habitat breadth HB, diet breadth DB, specialisation index ESI, IUCN status)
and AVONET (hand-wing index, habitat density, trophic niche, global range size). Names are
resolved in three tiers: exact, BIRDBASE synonym bridge, and epithet-within-family. The last
tier **must** be constrained to family: without it, over half the apparent matches are wrong
(*Ardenna pacifica*, a shearwater, matches *Gavia pacifica*, a loon). Residual gaps (2.2-4.1%
of cells) are filled by random-forest imputation and flagged per trait; the out-of-bag error is
poor for continuous traits (NRMSE 1.00), so imputed values are marked and can be excluded.

Two results hold under all three phylogenetic treatments — taxonomic nesting, phylogenetic
eigenvectors, and phylogenetic logistic regression:

| Term | Taxonomic nesting | Eigenvectors | phyloglm |
|---|---|---|---|
| Partial migrant vs resident | 2.49 (P = 9.5e-6) | 2.50 (P = 5.9e-6) | 1.91 (P = 8.1e-4) |
| Global range size, per SD | 1.27 (P = 0.017) | 1.23 (P = 0.029) | 1.45 (P = 1.4e-4) |

Body mass, clutch size, habitat breadth, diet breadth, number of congeners, hand-wing index,
IUCN status, endemism and trophic niche are all null.

**Range size must be measured globally.** The trait database was published in 2022, so its count
of Chinese provinces occupied already contains the 2002-2021 records used as the response.
Species with a new record occupy a median of 14 provinces against 4 for those without. Using
that count gives an odds ratio of 2.06 (P = 3e-16); using AVONET global range size, which is
independent of Chinese provincial records, gives 1.27 (P = 0.017); entered together the global
measure is fully absorbed (0.96, P = 0.7). Only the global measure is reported as a result.

### Province level

Response: new records per province, discovery-dated. Poisson is rejected (dispersion 5.60,
P = 2.3e-17); the negative binomial is not (1.24, P = 0.20, theta 6.11), and DHARMa passes.

| Model | Significant terms |
|---|---|
| Counts | Regional species richness IRR 1.27 (P = 0.036) |
| Rate per unit of recent effort (offset) | Early survey effort IRR 0.71 (P = 0.028); GDP per capita IRR 0.61 (P = 0.0027) |

Hierarchical partitioning attributes 51.2% of explained deviance to species richness, 33.3% to
area and 9% to the two effort terms combined; the full model explains 20.5% of deviance. Effort
therefore appears at this scale not as a count effect but as diminishing returns, which is the
same signal the hazard model shows as a declining effort coefficient through time.

Note on the effort windows: the mammal study used publication counts from 1949-2000 as
historical survey effort. No bird analogue exists here - the observation database holds seven
reports before 2000 and 29 of 31 provinces have none - so early (2002-2008) and recent
(2009-2024) coverage take that role instead.
