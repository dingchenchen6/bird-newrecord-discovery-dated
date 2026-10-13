# Data dictionary

Every file shipped in `data/` and every result table in `tables/`, with the columns that matter.
Units: temperatures in °C, hazards as annual probabilities, coefficients as hazard ratios per
one standard deviation of the standardised predictor.

---

## `data/events_discovery_dated.csv` — 657 rows

The event table after re-dating. One row per species × province pair that acquired its first
formal record inside 2002–2024.

| Column | Type | Meaning |
|---|---|---|
| `species` | chr | Scientific name harmonised to the candidate pool (COL China 2026, else BirdLife v10, else Clements v2025) |
| `province` | chr | Provincial unit; `Xizang` mapped to `Tibet`; Taiwan, Hong Kong and Macao excluded |
| `year` | int | **Event year = discovery year.** Falls back to `pub_year − 1` when the discovery year is unparseable or later than publication (8 of 657) |
| `date_source` | chr | `discovery_date` (649) or `publication_minus_median_lag` (8) |
| `disc_year` | int | Year parsed from the compilation's discovery-date field |
| `pub_year` | int | Source publication year |
| `lag` | int | `pub_year − year`; negative values indicate the fallback was applied |
| `longitude`, `latitude` | num | Record coordinates, WGS84 |

## `data/effort_panel_v2.csv` — 782 province-years

Provincial annual survey effort under three missing-data rules.

| Column | Type | Meaning |
|---|---|---|
| `province`, `year` | chr, int | Key |
| `effort_status` | chr | Original classification: `observed` (719), `structural_zero` (24), `no_data` (39) |
| `effort_status_v2` | chr | Reclassified: `observed`, `coverage_gap` (the former structural zeros), `no_coverage` |
| `in_scope` | lgl | Whether the province-year is inside the analysis scope |
| `n_visits`, `n_observers`, `n_birding_days`, `effort_record` | num | Raw counts as compiled |
| `cnt_{proxy}_{rule}` | num | Counts under each rule: `gap` (missing), `zero` (zero-filled, the previously published treatment), `imp` (within-province linear interpolation on the log scale) |
| `eff_{proxy}_{rule}_z` | num | log1p-transformed and standardised within the analysis scope, separately per rule |

Proxies are `visits`, `observers`, `days`, `record`. In 22 of the 24 coverage-gap cells the
adjacent years in the same province record 1–27 visits; see `tables/tbl_effort_gap_audit.csv`.

## `data/model_v2_thr50.parquet` — 185,478 rows

The complete risk set at the 50 km species-distribution-model buffer, before dropping rows with
missing covariates.

| Column | Type | Meaning |
|---|---|---|
| `species`, `province`, `year` | chr, chr, int | Key |
| `mig_grp` | chr | Migratory group carried over from the candidate pool; `Unknown` for forced-in pairs |
| `ev_year` | int | Event year for the pair, `NA` if never recorded |
| `event` | int | 1 in the event year, 0 otherwise. Rows after the event year do not exist (absorbing exit) |
| `effort_status_v2` | chr | As above |
| `eff_*_z` | num | Twelve standardised effort variables (4 proxies × 3 rules) |
| `completeness`, `log_completeness` | num | Reporting completeness *c*(*t*) and its log, the model offset |
| `x`, `clim_change`, `clim_var` | num | Climate gradient and its decomposition, annual mean temperature at *W* = 15 |
| `usable_main` | lgl | Non-missing under the main specification (175,901 rows, 649 events) |

`data/model_thr{50,100,200}.parquet` are the upstream candidate pools used by script 132 to
define which species × province pairs enter the risk set at each buffer.

## `data/components_v2_tavg_annual_W15.parquet`

Climate components for the main specification. Script 132 regenerates all sixteen
indicator × window combinations from the panels below.

| Column | Meaning |
|---|---|
| `x` | `[T(p,t) − T_base(p)] − [N(s,t) − N_base(s)]`, how much more the province has warmed than the species' own historical range |
| `clim_change` | Trailing 15-year mean of `x`, strictly backward-looking |
| `clim_var` | `x − clim_change`, the annual residual |

Baseline is 1980–2000 at both the provincial and the species-range end.

## `data/panel_full_grid.csv.gz`, `data/panel_full_species.csv`

Full 1980–2024 series for four temperature indicators, extracted from the WorldClim 2.1
downscaling of CRU TS 4.09. `panel_full_grid` is per 100 km grid cell; `panel_full_species` is
per species range polygon. `baseline` is the 1980–2000 mean. Provincial series are area-weighted
means over grid cells, weighted by `olap` in `data/grid_province_lookup.csv` (overlap area in m²).

## `data/tbl_F_cmip6_delta.csv`

CMIP6 four-model ensemble median warming deltas, `unit` ∈ {`province`, `species`}, for
SSP2-4.5 and SSP5-8.5 at 2030, 2050 and 2080. Applied to **both** ends of the climate gradient;
applying to one end only would create a climate signal out of spatially uniform warming.

---

## Result tables

| File | Contents |
|---|---|
| `tbl_event_flow_bridge.csv` | 1,029 released records → 657 analysed events, step by step |
| `tbl_publication_lag.csv` | Distribution of publication lag |
| `tbl_reporting_completeness.csv` | *c*(*t*) and `log_completeness` per year, the model offset |
| `tbl_lag_stationarity.csv` | Spearman and Wilcoxon tests justifying the pooled lag CDF |
| `tbl_dating_comparison.csv` | Every event under both dating conventions |
| `tbl_effort_gap_audit.csv` | Adjacent-year visit counts for each of the 24 coverage gaps |
| `tbl_effort_treatment_summary.csv` | Usable province-years and z-range per missing-data rule |
| `tbl_riskset_bridge_v2.csv` | Candidate pairs → risk set → usable rows, per threshold |
| `tbl_area_weight_effect.csv` | Area-weighted minus unweighted provincial series, per indicator |
| `tbl_change_decomposition.csv` | **The S0–S5 waterfall.** One correction per step |
| `tbl_v2_re_ladder.csv` | Random-effect structures R0–R5, coefficients and variance components |
| `tbl_v2_re_evaluation.csv` | The same structures on four criteria including *R*² and AUC |
| `tbl_v2_indicator_window.csv` | 4 climate indicators × 4 accumulation windows |
| `tbl_v2_B_effort.csv` | 4 effort proxies × 3 missing-data rules |
| `tbl_v2_C_threshold.csv` | Three SDM buffers |
| `tbl_v2_D_ladder.csv` | Fixed-effect ladder with marginal and conditional discrimination |
| `tbl_v2_E_importance.csv` | Relative importance under four criteria |
| `tbl_v2_diagnostics.csv` | DHARMa tests, Moran's *I*, proportional hazards |
| `tbl_v2_future_province_projection.csv` | Provincial projections, `scope` distinguishes all rows from within-support |
| `tbl_v2_future_support.csv` | Share of cells inside the fitted covariate support per scenario-horizon |

Note on AIC: the effort missing-data rules and the SDM thresholds change the number of rows, so
AIC is **not** comparable across `tbl_v2_B_effort.csv` or `tbl_v2_C_threshold.csv`. Those
comparisons are made on coefficients.
