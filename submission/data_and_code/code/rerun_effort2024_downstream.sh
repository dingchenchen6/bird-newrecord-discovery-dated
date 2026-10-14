#!/bin/zsh
# ============================================================
# 2024 年努力修正后的下游重跑 / downstream rerun after the 2024 effort correction
# 前置 / prerequisite: code/rerun_effort2024_models.sh 已完成(fit_R3 与各结果表)
# 三路并行 / three lanes:
#   A 图件与解剖、省级 GEB、方位零假设与方位图 / figures, anatomy, province-level GEB, direction null and figures
#   B 未来投影、县级分配与曲面、随机森林/XGB、多尺度图、情景地图(含英文版)
#     projections, county allocation, RF/XGB, multiscale and scenario maps (with English versions)
#   C 零模型 → 自助法与影响 → 重抽样与诊断图(各自 6 进程并行)
#     null models -> bootstrap and influence -> resampling and diagnostics figures (6 workers each)
# 日志 / logs: logs/rerun2024/<script>.log;进度 logs/rerun2024/driver_downstream.log
# 用法 / Usage: zsh code/rerun_effort2024_downstream.sh [A] [B] [C]   (缺省三路全跑 / default: all lanes)
#   C 路只依赖建模矩阵, 可与模型层并行先跑 / lane C needs only the model matrix and may start early
# ============================================================
set -u
cd "${0:A:h}/.."
L=logs/rerun2024
mkdir -p $L
D=$L/driver_downstream.log

run() {
  local name=$1; shift
  echo "[driver $(date +%H:%M:%S)] start $name" >> $D
  Rscript --no-init-file "$@" > $L/$name.log 2>&1
  local st=$?
  echo "exit $st" >> $L/$name.log
  echo "[driver $(date +%H:%M:%S)] done  $name exit $st" >> $D
}

laneA() {
  run 139 code/139_figures_v2.R
  run 143 code/143_ecological_anatomy_figures.R
  run 144 code/144_sensitivity_figure_and_rationale.R
  run 149 code/149_province_level_geb.R
  run 150 code/150_geb_style_figures.R
  run 153 code/153_geb_original_style_figures.R
  run 214 code/214_direction_geometric_null.R
  run 154 code/154_directional_windrose_radar.R
  run 216 code/216_aoc_direction_null_figure.R
}
laneB() {
  run 141 code/141_future_projection_v2.R
  run 171 code/171_allocation_model.R
  run 172 code/172_county_surface.R
  run 173 code/173_county_figures.R
  run 180 code/180_rf_vs_hazard_province.R
  run 181 code/181_rf_vs_clogit_units.R
  run 182 code/182_rf_figures.R
  run 183 code/183_xgb_province.R
  run 184 code/184_xgb_alloc_units.R
  run 185 code/185_multiscale_prediction_maps.R
  run 185_en code/185_multiscale_prediction_maps_en.R
  run 187 code/187_future_scenario_maps.R
  run 187_en code/187_future_scenario_maps_en.R
  run 188 code/188_future_multimodel_maps.R
  run 188_en code/188_future_multimodel_maps_en.R
  run 210 code/210_aoc_county_figure.R
}
laneC() {
  run 190 code/190_null_models.R
  run 191 code/191_bootstrap_influence.R
  run 191_fig code/191_resampling_figure.R
  run 192 code/192_diagnostics_robustness_figures.R
}
LANES=(${@:-A B C})
for x in $LANES; do
  case $x in
    A) laneA & ;;
    B) laneB & ;;
    C) laneC & ;;
  esac
done
wait
echo "[driver $(date +%H:%M:%S)] ALL DOWNSTREAM DONE" >> $D
