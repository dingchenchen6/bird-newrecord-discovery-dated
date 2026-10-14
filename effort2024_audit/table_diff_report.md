# 结果表新旧对比 / Result tables before and after the 2024 effort correction

修正前快照 `temp/snapshot_pre_effort2024_20261013/tables`;修正后 `analysis_v2/tables`。逐格明细见 `table_diff_cells.csv`。

| 表 | 状态 | 行(前) | 行(后) | 最大相对差 | 行变化 |
|---|---|---|---|---|---|
| _iw_tavg_annual.csv | 52 cells changed | 4 | 4 | 0.855 |  |
| _iw_tavg_winter.csv | 52 cells changed | 4 | 4 | 0.796 |  |
| _wb_1980_2000.csv | 171 cells changed | 9 | 9 | 0.861 |  |
| _wb_1981_2010.csv | 171 cells changed | 9 | 9 | 0.868 |  |
| _wb_1991_2020.csv | 171 cells changed | 9 | 9 | 0.88 |  |
| tbl_alloc_ladder.csv | unchanged | 30 | 30 |  |  |
| tbl_alloc_skill.csv | unchanged | 10 | 10 |  |  |
| tbl_alloc_skill_province.csv | unchanged | 47 | 47 |  |  |
| tbl_area_weight_effect.csv | unchanged | 4 | 4 |  |  |
| tbl_bootstrap_ci.csv | unchanged | 8 | 8 |  |  |
| tbl_change_decomposition.csv | 61 cells changed | 6 | 6 | 1e+09 |  |
| tbl_county_surface_top50.csv | unchanged | 50 | 50 |  |  |
| tbl_dating_comparison.csv | unchanged | 679 | 679 |  |  |
| tbl_effort_gap_audit.csv | unchanged | 24 | 24 |  |  |
| tbl_effort_treatment_summary.csv | 8 cells changed | 3 | 3 | 0.027 |  |
| tbl_event_flow_bridge.csv | unchanged | 6 | 6 |  |  |
| tbl_future_multimodel_grid.csv | unchanged | 744 | 744 |  |  |
| tbl_future_scenario_grid.csv | unchanged | 248 | 248 |  |  |
| tbl_influence_loo.csv | unchanged | 41 | 41 |  |  |
| tbl_lag_stationarity.csv | unchanged | 2 | 2 |  |  |
| tbl_null_models.csv | unchanged | 12 | 12 |  |  |
| tbl_pa_buffer_sensitivity.csv | unchanged | 4 | 4 |  |  |
| tbl_pa_c1_jackknife.csv | unchanged | 68 | 68 |  |  |
| tbl_pa_c1_ladder.csv | unchanged | 8 | 8 |  |  |
| tbl_pa_c1_robustness.csv | unchanged | 7 | 7 |  |  |
| tbl_pa_c1_strata_info.csv | unchanged | 643 | 643 |  |  |
| tbl_pa_c3_fracreg.csv | unchanged | 9 | 9 |  |  |
| tbl_pa_c3_permutation.csv | unchanged | 1 | 1 |  |  |
| tbl_pa_c3_priority_cells.csv | unchanged | 157 | 157 |  |  |
| tbl_pa_c3_priority_quadrants.csv | unchanged | 4 | 4 |  |  |
| tbl_pa_c3_warming_quintiles.csv | unchanged | 5 | 5 |  |  |
| tbl_pa_c5_persistence.csv | unchanged | 2 | 2 |  |  |
| tbl_pa_checklist_quality.csv | unchanged | 2 | 2 |  |  |
| tbl_pa_concentration.csv | unchanged | 68 | 68 |  |  |
| tbl_pa_discovery_method.csv | unchanged | 3 | 3 |  |  |
| tbl_pa_inventory.csv | unchanged | 4 | 4 |  |  |
| tbl_pa_simpson_by_province.csv | unchanged | 31 | 31 |  |  |
| tbl_parametric_bootstrap.csv | unchanged | 4 | 4 |  |  |
| tbl_publication_lag.csv | unchanged | 23 | 23 |  |  |
| tbl_reporting_completeness.csv | unchanged | 23 | 23 |  |  |
| tbl_rf_alloc_importance.csv | unchanged | 16 | 16 |  |  |
| tbl_rf_alloc_province.csv | unchanged | 141 | 141 |  |  |
| tbl_rf_alloc_skill.csv | unchanged | 8 | 8 |  |  |
| tbl_rf_importance.csv | unchanged | 7 | 7 |  |  |
| tbl_rf_province_cv.csv | unchanged | 69 | 69 |  |  |
| tbl_rf_province_summary.csv | unchanged | 17 | 17 |  |  |
| tbl_riskset_bridge_v2.csv | 3 cells changed | 15 | 15 | 0.00148 |  |
| tbl_v2_B_effort.csv | 211 cells changed | 12 | 12 | 0.84 |  |
| tbl_v2_C_threshold.csv | 48 cells changed | 3 | 3 | 0.834 |  |
| tbl_v2_D_ladder.csv | 62 cells changed | 6 | 6 | 0.83 |  |
| tbl_v2_E_importance.csv | 32 cells changed | 4 | 4 | 1.93 |  |
| tbl_v2_baseline_sensitivity.csv | 213 cells changed | 12 | 12 | 0.923 |  |
| tbl_v2_diagnostics.csv | 21 cells changed | 14 | 14 | 1.79 | rows -3 +3 |
| tbl_v2_direction_by_order.csv | unchanged | 160 | 160 |  |  |
| tbl_v2_direction_geometric_null.csv | 322 cells changed | 192 | 192 | 4 |  |
| tbl_v2_direction_geometric_null_summary.csv | 68 cells changed | 24 | 24 | 1 |  |
| tbl_v2_direction_null_si_omnibus.csv | 4 cells changed | 24 | 24 | 0.2 | rows -10 +10 |
| tbl_v2_direction_null_si_sectors.csv | 2 cells changed | 16 | 16 | 0.389 | rows -7 +7 |
| tbl_v2_direction_overall.csv | unchanged | 8 | 8 |  |  |
| tbl_v2_direction_tests.csv | unchanged | 120 | 120 |  |  |
| tbl_v2_ecological_rationale.csv | unchanged | 12 | 12 |  |  |
| tbl_v2_future_province_projection.csv | 1537 cells changed | 236 | 222 | 70.4 | rows -14 +0 |
| tbl_v2_future_support.csv | 18 cells changed | 6 | 6 | 1 |  |
| tbl_v2_indicator_window.csv | 223 cells changed | 16 | 16 | 191 |  |
| tbl_v2_migratory_interaction_by_group.csv | 12 cells changed | 3 | 3 | 0.255 |  |
| tbl_v2_migratory_ladder.csv | 25 cells changed | 6 | 6 | 1.83 |  |
| tbl_v2_migratory_stratified.csv | 85 cells changed | 5 | 5 | 0.737 |  |
| tbl_v2_province_coefficients.csv | 89 cells changed | 13 | 13 | 0.183 |  |
| tbl_v2_province_diagnostics.csv | 4 cells changed | 2 | 2 | 0.0983 |  |
| tbl_v2_province_hp.csv | 17 cells changed | 6 | 6 | 0.158 |  |
| tbl_v2_province_models.csv | 11 cells changed | 3 | 3 | 0.0258 |  |
| tbl_v2_province_partial.csv | 18 cells changed | 6 | 6 | 0.544 |  |
| tbl_v2_province_vif.csv | 6 cells changed | 6 | 6 | 0.0708 |  |
| tbl_v2_re_evaluation.csv | 19 cells changed | 6 | 6 | 0.892 | rows -5 +5 |
| tbl_v2_re_ladder.csv | 12 cells changed | 7 | 7 | 0.892 | rows -6 +6 |
| tbl_v2_species_fast_compare.csv | unchanged | 20 | 20 |  |  |
| tbl_v2_species_fast_effects.csv | unchanged | 60 | 60 |  |  |
| tbl_v2_species_fast_fit.csv | unchanged | 3 | 3 |  |  |
| tbl_v2_species_group_effects.csv | unchanged | 113 | 113 |  |  |
| tbl_v2_species_imputation_sensitivity.csv | unchanged | 20 | 20 |  |  |
| tbl_v2_species_imputation_sensitivity_alt.csv | unchanged | 50 | 50 |  |  |
| tbl_v2_species_range_circularity.csv | unchanged | 2 | 2 |  |  |
| tbl_v2_species_range_measures.csv | unchanged | 2 | 2 |  |  |
| tbl_v2_species_vif.csv | unchanged | 7 | 7 |  |  |
| tbl_v2_trait_coverage.csv | unchanged | 20 | 20 |  |  |
| tbl_v2_trait_imputation_oob.csv | unchanged | 2 | 2 |  |  |
| tbl_v2_trait_resolution.csv | unchanged | 10 | 10 |  |  |
| tbl_v2_trait_sources.csv | unchanged | 9 | 9 |  |  |
| tbl_v2_window_baseline_sensitivity.csv | 538 cells changed | 27 | 27 | 1.21e+11 |  |
| tbl_xgb_alloc_province_county.csv | unchanged | 29 | 29 |  |  |
| tbl_xgb_alloc_province_prefecture.csv | unchanged | 18 | 18 |  |  |
| tbl_xgb_alloc_skill.csv | unchanged | 4 | 4 |  |  |
| tbl_xgb_province_cv.csv | unchanged | 48 | 48 |  |  |
| tbl_xgb_province_summary.csv | unchanged | 12 | 12 |  |  |
| _iw_tmax_warm.csv | new table | 0 | 4 |  |  |
| _iw_tmin_cold.csv | new table | 0 | 4 |  |  |
