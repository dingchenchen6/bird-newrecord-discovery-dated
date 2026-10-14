#!/bin/zsh
# ============================================================
# 2024 年努力修正后的模型层重跑 / model-layer rerun after the 2024 effort correction
# 顺序 / order: 133(fit_R3 供下游使用)→ 134–138 四路并行 → 142/145 与 146/147 两路并行
#   133 first (downstream needs fit_R3), then 134–138 in four parallel lanes, then 142/145 and 146/147
# 前置 / prerequisites: 222 → 131 → 132 已完成 / already run
# 日志 / logs: logs/rerun2024/<script>.log;每步一行结束状态写到 logs/rerun2024/driver_models.log
# 用法 / Usage: zsh code/rerun_effort2024_models.sh   (cwd 任意 / any cwd)
# ============================================================
set -u
cd "${0:A:h}/.."
L=logs/rerun2024
mkdir -p $L
D=$L/driver_models.log

run() {
  local name=$1; shift
  echo "[driver $(date +%H:%M:%S)] start $name" >> $D
  Rscript --no-init-file "$@" > $L/$name.log 2>&1
  local st=$?
  echo "exit $st" >> $L/$name.log
  echo "[driver $(date +%H:%M:%S)] done  $name exit $st" >> $D
}

run 133 code/133_model_selection_v2.R

(
  for i in tavg_annual tavg_winter tmax_warm tmin_cold; do run 134_$i code/134_indicator_window_v2.R $i; done
  run 134_merge code/134_indicator_window_v2.R --merge
) &
( run 135 code/135_change_decomposition.R; run 136 code/136_re_structure_evaluation.R ) &
(
  for b in B C D E; do run 137_$b code/137_full_comparison_matrix.R $b; done
) &
( run 138 code/138_diagnostics_v2.R ) &
wait

(
  for b in 1980_2000 1981_2010 1991_2020; do run 142_$b code/142_window_baseline_sensitivity.R $b; done
  run 142_merge code/142_window_baseline_sensitivity.R --merge
  run 145 code/145_baseline_1970_sensitivity.R
) &
( run 146 code/146_migratory_strategy.R; run 147 code/147_migratory_figure.R ) &
wait
echo "[driver $(date +%H:%M:%S)] ALL MODELS DONE" >> $D
