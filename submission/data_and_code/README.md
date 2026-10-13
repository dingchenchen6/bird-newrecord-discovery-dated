# Data and code for the submission

Frozen snapshot (20261013) of the reproducibility core of the public repository
<https://github.com/dingchenchen6/bird-newrecord-discovery-dated>, prepared for peer review. It reproduces the main model and every
display item of the manuscript. The repository remains the maintained version.

## Contents

| Folder / file | What it holds |
|---|---|
| `code/` | Analysis pipeline (84 scripts). Scripts 130–154 fit and summarise the models; 160–192 run the conservation, downscaling, machine-learning and null-model modules; 200–220 build the submission package, the figures and their editable versions. Run in numerical order. |
| `data/`, `data_admin/` | Modelling data: discovery-dated events, effort panel, model matrices (three thresholds), climate panels, traits, protected-area and administrative-unit tables (45 MB) |
| `tables/` | Every result table cited in the manuscript and the Supplementary Information |
| `source_data/{GCB,NEE,NC}/` | Source data for each main figure, named by that journal's figure number (long format, one row per plotted value, `panel` column) |
| `environment/` | `renv.lock`, R `sessionInfo()`, Python package versions, environment notes and the data dictionary |
| `setup_workspace.R`, `tests/smoke_test.R` | Build the working layout, then refit the main model and check it against the published coefficients (about two minutes) |
| `config.R` | Paths to external inputs that are not redistributed (below) |

## Quick start

```bash
Rscript --no-init-file setup_workspace.R
Rscript --no-init-file tests/smoke_test.R
```

Run both from this folder. R 4.5 with the packages listed in `environment/renv.lock`
(glmmTMB, data.table, arrow, ggplot2, patchwork, sf) is sufficient for scripts 131–154.

## External inputs (not redistributed)

- **CBNR v2**, the record compilation: CC BY 4.0, <https://doi.org/10.5281/zenodo.20809949> (input of script 130).
- **Species range maps** (BirdLife International and Handbook of the Birds of the World, 2024):
  available on request from BirdLife; the licence does not permit redistribution.
- **Climate**: WorldClim 2.1 downscaling of CRU TS 4.09 and CMIP6 projections, <https://www.worldclim.org>.
- **Standard base map** GS(2019)1822, Ministry of Natural Resources of China, <http://bzdt.ch.mnr.gov.cn/>.

The distributed panels already contain every derived quantity these inputs supply, so only
upstream rebuilds (scripts 130, 132 from raw panels, 141 maps) need them; set their paths in `config.R`.

## Source data map

| Journal | Figure | Source figure | File copied |
|---|---|---|---|
| GCB | Figure1 | `Fig1_main_results_v2` | `source_data_TJ_Fig_main_results.csv` |
| GCB | Figure2 | `Fig2_dating_correction_v2` | `source_data_TJ_Fig_dating_correction.csv` |
| GCB | Figure3 | `Fig3_specification_robustness_v2` | `source_data_TJ_Fig_specification_robustness.csv` |
| GCB | Figure4 | `Fig5_model_anatomy_v2` | `source_data_TJ_Fig_model_anatomy.csv` |
| GCB | Figure5 | `Fig6_observation_process_v2` | `source_data_TJ_Fig_observation_process.csv` |
| GCB | Figure6 | `overall_direction_null` | `source_data_TJ_Fig_direction_null.csv` |
| GCB | Figure7 | `FigM4_mech_vs_ml_agreement_v2` | `source_data_TJ_Fig_mech_vs_ml.csv` |
| NEE | Fig1 | `Fig1_main_results_v2` | `source_data_TJ_Fig_main_results.csv` |
| NEE | Fig2 | `Fig2_dating_correction_v2` | `source_data_TJ_Fig_dating_correction.csv` |
| NEE | Fig3 | `Fig6_observation_process_v2` | `source_data_TJ_Fig_observation_process.csv` |
| NEE | Fig4 | `overall_direction_null` | `source_data_TJ_Fig_direction_null.csv` |
| NEE | Fig5 | `FigM4_mech_vs_ml_agreement_v2` | `source_data_TJ_Fig_mech_vs_ml.csv` |
| NC | Fig1 | `Fig2_dating_correction_v2` | `source_data_TJ_Fig_dating_correction.csv` |
| NC | Fig2 | `Fig1_main_results_v2` | `source_data_TJ_Fig_main_results.csv` |
| NC | Fig3 | `Fig5_model_anatomy_v2` | `source_data_TJ_Fig_model_anatomy.csv` |
| NC | Fig4 | `Fig6_observation_process_v2` | `source_data_TJ_Fig_observation_process.csv` |
| NC | Fig5 | `overall_direction_null` | `source_data_TJ_Fig_direction_null.csv` |
| NC | Fig6 | `Fig3_specification_robustness_v2` | `source_data_TJ_Fig_specification_robustness.csv` |
| NC | Fig7 | `FigM4_mech_vs_ml_agreement_v2` | `source_data_TJ_Fig_mech_vs_ml.csv` |

The submitted figures and their redesigned versions (`figures_polished/` in each journal folder)
plot the same values; both are documented by the files above.

## Licence

Code: MIT (`LICENSE`). Data derived from CBNR: CC BY 4.0, cite the dataset DOI above.
