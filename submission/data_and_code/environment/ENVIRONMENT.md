# Computing environment

The analysis was run and verified on the following configuration.

| | |
|---|---|
| R | 4.5.1 (2025-06-13) |
| Platform | aarch64-apple-darwin20 (Apple silicon) |
| OS | macOS 15.5 |
| Cores / RAM | 10 / 24 GB |

## Package versions

| Package | Version | Used for |
|---|---|---|
| data.table | 1.18.4 | all data manipulation |
| arrow | 24.0.0 | Parquet I/O |
| glmmTMB | 1.1.14 | the hazard models |
| TMB | 1.9.18 | glmmTMB backend |
| ggplot2 | 4.0.1 | figures |
| patchwork | 1.3.2 | figure composition |
| scales | 1.4.0 | axis transforms and breaks |
| sf | 1.0.23 | province polygons and base map |
| terra | 1.8.86 | climate raster extraction |
| exactextractr | 0.10.1 | area-weighted zonal statistics |
| DHARMa | 0.4.7 | simulation-based residual diagnostics |
| performance | 0.15.2 | Nakagawa *R*² |
| pROC | 1.19.0.1 | AUC |
| xgboost | 3.2.1.1 | machine-learning comparison model |
| officer | 0.7.4 | PPTX output |
| rvg | 0.4.2 | vector graphics inside PPTX |
| readxl | 1.4.5 | reading the record compilation |

Install what is missing:

```r
install.packages(c("data.table", "arrow", "glmmTMB", "ggplot2", "patchwork", "scales",
                   "sf", "terra", "exactextractr", "DHARMa", "performance", "pROC",
                   "xgboost", "officer", "rvg", "readxl"))
```

Only `data.table`, `arrow` and `glmmTMB` are required to reproduce the headline model. The rest
are needed for figures, diagnostics and projections.

## Runtimes

Measured on the configuration above.

| Step | Time |
|---|---|
| `setup_workspace.R` | < 5 s |
| `tests/smoke_test.R` | ~2 min |
| One mixed-model fit (175,901 rows, three random terms) | 70–90 s |
| `133_model_selection_v2.R` (7 fits) | ~11 min |
| `134_indicator_window_v2.R` (per indicator, 4 fits) | ~5 min |
| `137_full_comparison_matrix.R` block B (12 fits) | ~17 min |
| `138_diagnostics_v2.R` (500 simulations + PH model) | ~7 min |
| `139_figures_v2.R` | ~1 min |
| `141_future_projection_v2.R` | ~4 min |

## Two practical notes

**Memory.** Fitting sixteen mixed models in a single R session was killed by the OS without an
error message on a 24 GB machine. Scripts 134 and 137 therefore take an argument and are run
once per block, with explicit `gc()` between fits. Do not merge them back into one loop.

**The offset must go in the formula.** Passing `offset = <vector>` to `glmmTMB` alongside
`data =` segfaulted in `getParameterOrder` on this dataset, even for the simplest random
structure. Writing `offset(log_completeness)` inside the model formula works. This is noted in
the scripts where it matters.

## Determinism

Seeds are set to 42 in the diagnostics and projection scripts. glmmTMB fits are deterministic
given identical data and package versions. DHARMa residual simulations and the permutation test
for Moran's *I* depend on the seed; coefficient results do not.
