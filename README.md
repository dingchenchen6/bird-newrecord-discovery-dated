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
code/        analysis pipeline, scripts 130-154, run in numerical order
data/        modelling datasets and the panels needed to rebuild them
tables/      every result table cited in the manuscript and report
figures/     Fig1-Fig10 and the diagnostic panel
figures_alt/     species- and province-level figures in the original GEB style
figures_direction/  radar and wind-rose plots of record direction, overall and by order
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
| `153_geb_original_style_figures.R` | Fig9alt, Fig10alt in the original GEB layout | no |
| `154_directional_windrose_radar.R` | Directionality of records: radar and wind-rose by order | yes (AVONET centroids) |
| `160_thermal_niche_specs.R` | Alternative climate proxies: thermal extremes, heat exposure, niche tracking; heat-exposure moderation of the warming effect | no |
| `161_niche_sensitivity_grid.R` | Formal sensitivity grid: 6 proxies × 4 windows, plus the moderation across 3 thresholds and 4 effort proxies | no |
| `162_niche_sensitivity_figures.R` | Fig12, Fig13 | no |
| `163_climate_proxy_comparison.R` | Aligned comparison of all eight climate proxies, with the ecological rationale for each | no |

Script 160 takes the accumulation window as its argument, writing an unsuffixed set of tables for
*W* = 15 and a `_W20` set for *W* = 20:

```bash
Rscript --no-init-file code/160_thermal_niche_specs.R 15
Rscript --no-init-file code/160_thermal_niche_specs.R 20
```

Script 161 is run once per specification and then merged (29 fits in total, about an hour):

```bash
for s in S0_tavg_annual S1_tmax_warm S2_niche_prox S3_niche_track S4_heat_exposure S4M_exposure_moderates extra; do
  Rscript --no-init-file code/161_niche_sensitivity_grid.R $s
done
Rscript --no-init-file code/161_niche_sensitivity_grid.R --merge
```

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

**SDM thresholds are cell counts, not buffer radii.** A province enters a species' candidate pool
when its species distribution model marks at least 50, 100 or 200 suitable cells inside it. Cells
come from the 2.5-arc-minute climate surface and have a median area of 18.3 km² (about 4.3 km on a
side), so the three thresholds require roughly 0.9, 1.8 and 3.7 thousand km² of suitable habitat
within the province. Coefficients are unchanged across all three.

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
| Fig9alt, Fig10alt | The same two analyses laid out as in the companion mammal paper (`figures_alt/`) |
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
poor for continuous traits (NRMSE 1.00; categorical PFC 0.11), so imputed values are marked and
can be excluded. Only 51 of the 1,298 modelled species (3.9%) carry an imputed value among the
main-model traits. Refitting without them keeps 17 of 20 terms at the same sign and significance
and preserves all three significant effects: range size 1.456 to 1.309, partial migrant 1.889 to
2.200, open habitat 0.541 to 0.598. On that reduced subset phyloglm reports alpha at its upper
bound and does not converge cleanly - the full model's alpha of 0.597 is already close to the
0.620 bound, which reflects weak phylogenetic signal at this scale - so the sensitivity was
repeated under taxonomic nesting and phylogenetic eigenvectors, which converge and return the same
headline effects (`tables/tbl_v2_species_imputation_sensitivity*.csv`).

Phylogenetic non-independence is handled with the dated tree itself, by phylogenetic logistic
regression (Ives & Garland, alpha = 0.60); taxonomic nesting and phylogenetic eigenvector
regression are coarser alternatives run to confirm nothing depends on the choice. Two results
hold under all three:

| Term | Taxonomic nesting | Eigenvectors | phyloglm |
|---|---|---|---|
| Partial migrant vs resident | 2.49 (P = 9.5e-6) | 2.50 (P = 5.9e-6) | 1.91 (P = 8.1e-4) |
| Global range size, per SD | 1.27 (P = 0.017) | 1.23 (P = 0.029) | 1.45 (P = 1.4e-4) |

Body mass, clutch size, habitat breadth, diet breadth, number of congeners, hand-wing index,
IUCN status, endemism and trophic niche are all null.

**Range must be an area, not a count of provinces.** Both area measures are independent of the
response and agree, under the tree-based model:

| Measure | n | OR per SD (95% CI) | P |
|---|---|---|---|
| Global range area (AVONET) | 1,298 | 1.456 (1.204-1.762) | 1.1e-4 |
| China range area (BirdLife, clipped) | 1,003 | 1.653 (1.420-1.925) | 9.0e-11 |

The count of provinces occupied does not qualify. The trait database was published in 2022, so
its provincial counts already contain the 2002-2021 records used as the response: species with a
new record occupy a median of 14 provinces against 4 for those without, the count returns an odds
ratio of 2.09 (P = 5e-15), and it absorbs the area effect entirely when both are entered
(area 0.96, P = 0.70). Only the area measures are reported.

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

## Two layouts for the species- and province-level figures

Both analyses ship in two interchangeable layouts, so either can be used at submission.

| | `figures/` | `figures_alt/` |
|---|---|---|
| Species level | Fig9: forest plots of odds ratios across three phylogenetic treatments, plus the range-measure comparison | Fig9alt: ridgeline distributions by ecological group - taxonomic and migratory - plus stacked bars with chi-square annotations, laid out as in the mammal paper |
| Province level | Fig10: model comparison, coefficient plot, hierarchical partitioning, partial correlations | Fig10alt: six partial residual panels with beta and p annotated, a 100% stacked importance column, and slope estimates with matching colours |

One difference from the original is unavoidable and is stated on the figure: the mammal paper's
ridgelines are Bayesian posteriors, whereas the species-level models here are phylogenetic
logistic regression and glmmTMB, so the ridgelines show the sampling distribution of each
estimate under a normal approximation. The shape carries the same reading, but it is not a
posterior and is not labelled as one.

## Directionality of new records

Each record's direction is the bearing from the centroid of the species' BirdLife range to the
record itself, binned into eight 45-degree sectors. Centroids come from AVONET and cover 642 of
the 657 events (97.7%), spanning 361 species and 20 orders.

New records are strongly non-random in direction (chi-square = 580.1, df = 7,
P = 4.6e-121). Two sectors are over-represented after Holm correction: **East** (237 records,
36.9%, against 80.2 expected) and **Northeast** (179, 27.9%). South and West are the emptiest
(20 and 19). The pattern holds within every well-sampled order: Passeriformes (376.6, P = 2.5e-77),
Anseriformes (64.0), Accipitriformes (52.5), Charadriiformes (45.5) and Columbiformes (29.1) all
reject uniformity, and in each the significant sectors are East, Northeast or both.

Figures follow the layout of the existing bird directional task — ggradar for the radar form,
`coord_polar` for the wind-rose form, one colour per order, a header strip, and PNG/PDF/PPTX
output. Three things differ:

- events are the discovery-dated v2 set rather than publication-dated;
- **every order panel carries both sample sizes in its header strip** — new records and species —
  because one species can contribute records in several provinces and the two counts can give
  different directional profiles;
- directional tests are included (chi-square goodness-of-fit against uniform, plus one-sided
  exact binomial tests per sector with Holm correction), which the earlier script did not have.

The overlay figures use each order's own proportions rather than raw counts: Passeriformes
contributes 388 of 642 records and on an absolute scale flattens every other order against the
centre. Absolute sample sizes stay in the legend.

## Group-specific species-level effects

Pooling all species hides two patterns. Fitting the same phylogenetic model within groups:

| Grouping | Group | n | With records | Significant terms |
|---|---|---|---|---|
| Taxonomic | Passeriformes | 710 | 203 | Range size 1.53 (P = 0.0020); partial migrant 2.01 (P = 0.0081) |
| | Non-passerines | 588 | 131 | Partial migrant 3.19 (P = 3.3e-4) |
| Migratory | Resident | 567 | 116 | Range size 1.60 (P = 0.0042) |
| | Partial migrant | 228 | 91 | Granivore 0.28 (P = 0.044) |
| | Migratory | 503 | 127 | Hand-wing index 0.51 (P = 3.8e-4); body mass 1.74 (P = 0.0037); open habitat 0.42 (P = 0.013) |

Among full migrants, two traits that are null in the pooled model become significant and point the
same way: lower dispersal ability raises the odds of a new record, and larger body mass raises them
too. Both fit a vagrancy mechanism - a migrant with poor flight efficiency is more easily displaced
off route, and a large bird far outside its range is more likely to be noticed. The pooled model
averages these against residents, for whom neither applies, and returns zero.

The ridgeline figure in `figures_alt/` therefore splits by ecological group, as the mammal paper
does, rather than by statistical treatment.

## 保护地关联模块 / Protected-area module

把新纪录生成风险接到保护规划上,回答三个规划者会问的问题。完整方法、
数值与局限见 [`docs/CONSERVATION_MODULE.md`](docs/CONSERVATION_MODULE.md)。

**估计量口径**:全部结论只适用于 1028 处**已制图的、以国家级为主的、2012 年前建立的
自然保护区**;不含 2021 年起的国家公园、自然公园与生态保护红线。

| 问题 | 结果 |
|---|---|
| 保护区内的新纪录能否算保护成效? | 表观富集 2.5 倍;以观鸟人实际去过的地点为对照、按省×年匹配后 OR 1.57 (1.26–1.96),但按宿主保护区重抽后 CI 跨 1,且只在 2013 年后出现——**不能作为成效指标** |
| 首次记录是否更容易在保护区内转为持续存在? | 否。控制后续观测努力后 OR 1.01 (0.62–1.64);全样本 41.1% 被再检出、22.5% 在 ≥3 年被检出 |
| 保护网络是否建在增温慢的地方? | 用**格级实测**增温:落差仅 1.2 倍,分层置换 P = 0.48。8.5 倍的落差是把省级值当格级值用造成的 |

**交付产品**:监测嫁接优先级——39.3 万 km² 高增温低观测格落在已建保护区内(可直接加挂监测),
160.3 万 km² 落在保护体系之外(需另投调查力量)。

**已判定不可估而删除**:建区前后 DiD(172 条区内事件无一早于宿主建区年)、
方向性连通(与已发表的观测性解释循环)、保护空缺图(矢量完整度约三成,会制造假空缺)。

脚本 `code/160`–`code/166`;结果表 `tables/tbl_pa_*.csv`;图件 `figures_pa/FigP1`–`FigP3`。

## 降尺度到市县 / Downscaling to prefecture and county

省级新纪录预测能否做到市县水平?能,但要把预测拆成两段——
省级风险(已冻结)× 省内分配(新建条件 logit)。完整方法见
[`docs/DOWNSCALING_MODULE.md`](docs/DOWNSCALING_MODULE.md)。

**样本外技能**(2002–2018 拟合 → 2019–2024 预测,指标为真实单元的预测排名分位,0.5 = 随机):

| | 市级(备择中位 13) | 县级(备择中位 103) |
|---|---|---|
| 分配模型 | **0.348**,top-1 30.1%,top-3 60.7% | **0.229**,top-1 16.1%,前 10% 命中 45.4% |
| 仅观鸟努力 | 0.396 | 0.311 |
| 仅面积 | 0.477 | 0.372 |
| 随机 | 0.559 | 0.496 |

县级 top-1 命中率约为随机期望(1/103)的 17 倍。留一省验证:29 个省中 27 个优于随机
(中位分位 0.248),重庆与海南例外。

**最强的预测变量是到该物种已知分布区的距离**(县级 OR 0.238 / 1 SD log km),
而不是观鸟努力(1.755)。落点份额最高的县依次为墨脱、浦东、滨海、阿拉善左旗、
罗山、沙坡头、崇明、洋县、珲春、勐腊——模型事先不知道这些是公认的边界与热点县。

**外推年限不由县级这一段决定**:县级分配可稳定外推,但省级风险到 2050 年
只剩 10.4%(SSP2-4.5)的物种-省组合落在拟合范围内,县级面继承这一限制。
因此近期(至 2030 年)可作操作性产品,2050 年后只作情景演示。

脚本 `code/170`–`code/173`;结果表 `tables/tbl_alloc_*.csv`、`tables/tbl_county_surface_top50.csv`;
图件 `figures_admin/FigC1`–`FigC2`。

## 随机森林对照 / Random forest comparison

在省级发生与市县级落点两个任务上,把随机森林与机制模型放在同一批数据、同一套验证方案下比较。
完整方法见 [`docs/RF_COMPARISON_MODULE.md`](docs/RF_COMPARISON_MODULE.md)。

**省级 PR-AUC**(事件率 0.369%,故以 PR-AUC 为主指标):

| 验证方案 | 离散风险模型 | 随机森林(最优版) |
|---|---|---|
| 随机 5 折 | 0.0110(条件) | **0.0137** |
| 留物种 5 折 | 0.0054 | **0.0121** |
| 留省 5 折 | **0.0056** | 0.0053 |
| 时间前推 2019–2024 | **0.0098** | 0.0070 |

**市县级落点**(排名分位,0.5 = 随机):时间前推下两族打平(县级 0.229 vs 0.223);
换成留一省,机制模型明显胜出(县级 0.278 vs 0.339,top-1 10.4% vs 6.8%)。

**三点结论**:
1. 随机森林在内插时更强,在外推(换省、换年份、换气候情景)时掉到基线附近
2. 它的概率不可直接使用——概率森林把风险压扁(校准斜率 0.03–0.30),
   类平衡森林放大约 40 倍(Brier 0.15 vs 0.0037);只能用来排序
3. 随机森林置换重要性把**年份**排在第一位,前四位有三个属于观测过程——
   等于独立复现了本文主论点:新纪录数据里最强的信号是观测过程

外推行为:随机森林在约 2.9 SD 处返回边界叶值并恒定在 6.7%,cloglog 继续线性外推。
两者都不被数据验证,但前者是算法产物,后者是可审查的假设。

脚本 `code/180`–`code/182`;结果表 `tables/tbl_rf_*.csv`;图件 `figures_rf/FigR1`–`FigR2`。
