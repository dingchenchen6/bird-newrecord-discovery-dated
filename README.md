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
code/        analysis pipeline, scripts 130-141, run in numerical order
data/        modelling datasets and the panels needed to rebuild them
tables/      every result table cited in the manuscript and report
figures/     Fig1-Fig4 and the diagnostic panel
figures_future/  projection figures FigM1-FigM4 and the unmasked contrast
docs/        manuscript (English) and research report (Chinese)
tests/       smoke test reproducing the headline coefficients
```

Every figure ships as **PNG (450 dpi), PDF, SVG and editable PPTX**, plus the source data
behind it as CSV. In the PPTX every element is a native PowerPoint shape, so the figures can
be recoloured or relabelled without returning to R. Map figures omit SVG because it duplicates
the PDF at ten times the size.

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

Scripts 133–141 run entirely on data shipped in this repository. Scripts 130–132 rebuild the
event table, effort panel and modelling matrix from primary sources, some of which are
third-party licensed and are not redistributed here — set their paths in `config.R`.

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

Script 134 is run once per climate indicator and then merged:

```bash
for i in tavg_annual tavg_winter tmax_warm tmin_cold; do
  Rscript --no-init-file code/134_indicator_window_v2.R $i
done
Rscript --no-init-file code/134_indicator_window_v2.R --merge
```

Script 137 takes a block argument:

```bash
for b in B C D E; do Rscript --no-init-file code/137_full_comparison_matrix.R $b; done
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
