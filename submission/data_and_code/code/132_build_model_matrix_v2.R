#!/usr/bin/env Rscript
# ============================================================
# Script 132: v2 建模矩阵 —— 发现年定年 + 覆盖缺口努力 + 面积加权气候
# Build the v2 modelling matrix: discovery-year dating, coverage-gap effort,
# area-weighted provincial climate
# ============================================================
# Scientific question / 科学问题:
#   在正确对齐观测时点、正确处理努力缺失、并校正报告完整度之后,
#   气候变化与调查努力如何共同关联于正式新记录的【生成风险】?
#
# 相对 v1 的三处结构性修正 / Three structural corrections over v1:
#   (1) 定年: 事件年由【发表年】改为【发现年】(83.1% 的事件年份改变)。
#       随之而来的两个生存分析后果必须一并处理:
#         - 发现年 < 2002 者为【现患病例】(2002 年前该种已在该省出现),
#           不再处于风险中 => 整对剔除, 而非截尾。
#         - 发现年 <= 2024 但发表于 2025 者, v1 因发表年超窗而丢失
#           => 按发现年重新纳入(强制纳入规则)。
#   (2) 努力: structural_zero 改判为【覆盖缺口】(见 131), 主分析按缺失处理。
#   (3) 气候: 省级序列改为【按网格-省重叠面积加权】的均值, 与方法学描述一致
#       (v1 为未加权均值)。基线统一为 1980-2000, 省端与物种端同源。
#
# 报告完整度 / Reporting completeness:
#   附上 offset(log c_t), c_t 由发表滞后经验 CDF 给出(见 130)。
#
# 变量定义 / Variable definitions (s=物种, p=省, t=年; 基线 1980-2000):
#   x(s,p,t)    = [T(p,t) − T_base(p)] − [N(s,t) − N_base(s)]   物种特异气候梯度
#   clim_change = x 在 [t−W+1, t] 的滑动均值                     累积气候变化
#   clim_var    = x(t) − clim_change(t)                          年度气候变异
#
# Input / 输入:
#   analysis_v2/data/events_discovery_dated.csv          (130)
#   analysis_v2/data/effort_panel_v2.csv                 (131)
#   analysis_v2/tables/tbl_reporting_completeness.csv    (130)
#   analysis_final/data/panel_full_{grid,species}.csv    (120)
#   analysis_rebuilt/data/grid_province_lookup.csv       (含 olap 面积权重)
#   analysis_species_specific/data/model_thr{50,100,200}.parquet  (候选池与迁徙分组)
#
# Output / 输出:
#   analysis_v2/data/model_v2_thr{50,100,200}.parquet
#   analysis_v2/data/components_v2_{indicator}_W{5,10,15,20}.parquet
#   analysis_v2/tables/tbl_riskset_bridge_v2.csv
#   analysis_v2/tables/tbl_area_weight_effect.csv
#
# Main packages / 主要包: data.table, arrow
# 运行 / Run: Rscript --no-init-file code/132_build_model_matrix_v2.R
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow) })
options(warn = 1)

V2  <- normalizePath(".", mustWork = TRUE)
RB  <- file.path(V2, "analysis_rebuilt")
SS  <- file.path(V2, "analysis_species_specific")
FN  <- file.path(V2, "analysis_final")
OUT <- file.path(V2, "analysis_v2")
msg <- function(...) cat(sprintf("[132 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

INDS  <- c("tavg_annual", "tavg_winter", "tmax_warm", "tmin_cold")
WINS  <- c(5L, 10L, 15L, 20L)
THRS  <- c(50L, 100L, 200L)
YR_FROM <- 2002L; YR_TO <- 2024L

bridge <- list()
add_b <- function(thr, step, pairs, rows, events, note = "")
  bridge[[length(bridge) + 1L]] <<- data.table(threshold = thr, step = step,
    pairs = pairs, rows = rows, events = events, note = note)

# ---- 1. 省级序列: 面积加权 vs 未加权 -------------------------------------
gp  <- fread(file.path(FN, "data", "panel_full_grid.csv"))
g2p <- fread(file.path(RB, "data", "grid_province_lookup.csv"), encoding = "UTF-8")
gp  <- merge(gp, g2p[, .(grid_cell, province, olap)], by = "grid_cell")

prov <- gp[, .(T_t    = stats::weighted.mean(val,      olap, na.rm = TRUE),
               T_base = stats::weighted.mean(baseline, olap, na.rm = TRUE)),
           by = .(province, year, indicator)]
prov_unw <- gp[, .(T_t_unw = mean(val, na.rm = TRUE)), by = .(province, year, indicator)]
awe <- merge(prov, prov_unw, by = c("province", "year", "indicator"))
awe[, diff := T_t - T_t_unw]
aw_smry <- awe[, .(mean_abs_diff = round(mean(abs(diff)), 4),
                   max_abs_diff  = round(max(abs(diff)), 4),
                   cor           = round(cor(T_t, T_t_unw), 6)), by = indicator]
print(aw_smry); fwrite(aw_smry, file.path(OUT, "tables", "tbl_area_weight_effect.csv"))
msg("省级序列(面积加权) ", min(prov$year), "-", max(prov$year), " | 省 ", uniqueN(prov$province))

sp  <- fread(file.path(FN, "data", "panel_full_species.csv"))
nat <- sp[, .(species, year, indicator, N_t = val, N_base = baseline)]

# ---- 2. 事件与风险集对 ----------------------------------------------------
ev <- fread(file.path(OUT, "data", "events_discovery_dated.csv"))[, .(species, province, ev_year = year)]
prevalent <- fread(file.path(OUT, "tables", "tbl_dating_comparison.csv"))[is.na(new_year) & !is.na(old_year),
                                                                          .(species, province)]
msg("事件 ", nrow(ev), " | 现患对(发现年<2002, 需整对剔除) ", nrow(prevalent))

eff  <- fread(file.path(OUT, "data", "effort_panel_v2.csv"))
comp_ct <- fread(file.path(OUT, "tables", "tbl_reporting_completeness.csv"))[, .(year, completeness, log_completeness)]

EFF_Z <- grep("^eff_.*_z$", names(eff), value = TRUE)
msg("努力口径列: ", paste(EFF_Z, collapse = ", "))

# ---- 3. 逐阈值构建 --------------------------------------------------------
for (thr in THRS) {
  b0 <- as.data.table(read_parquet(file.path(SS, "data", sprintf("model_thr%d.parquet", thr))))
  pool <- unique(b0[, .(species, province)])
  add_b(thr, "1. v1 candidate pairs", nrow(pool), NA_integer_, NA_integer_, "SDM pool + v1 forced events")

  # 剔除现患对 / drop prevalent pairs
  pool <- pool[!prevalent, on = .(species, province)]
  add_b(thr, "2. drop prevalent (discovered <2002)", nrow(pool), NA_integer_, NA_integer_,
        sprintf("%d pairs removed", nrow(prevalent)))

  # 强制纳入全部新定年事件 / force in every re-dated event
  miss <- ev[!pool, on = .(species, province)][, .(species, province)]
  pool <- unique(rbind(pool, miss))
  add_b(thr, "3. force in all re-dated events", nrow(pool), NA_integer_, NA_integer_,
        sprintf("%d event pairs added", nrow(miss)))

  # 迁徙分组: 沿用 v1, 新增对标 Unknown / migratory level, Unknown for new pairs
  mg <- unique(b0[, .(species, mig_grp)])
  pool <- merge(pool, mg, by = "species", all.x = TRUE)
  pool[is.na(mig_grp), mig_grp := "Unknown"]

  # 展开 species x province x year, 事件后吸收退出
  d <- pool[, .(year = YR_FROM:YR_TO), by = .(species, province, mig_grp)]
  d <- merge(d, ev, by = c("species", "province"), all.x = TRUE)
  d <- d[is.na(ev_year) | year <= ev_year]
  d[, event := as.integer(!is.na(ev_year) & year == ev_year)]
  add_b(thr, "4. expand with absorbing exit", uniqueN(d[, .(species, province)]), nrow(d), sum(d$event), "")

  # 努力 / effort
  d <- merge(d, eff[, c("province", "year", "effort_status_v2", EFF_Z), with = FALSE],
             by = c("province", "year"), all.x = TRUE)
  d <- merge(d, comp_ct, by = "year", all.x = TRUE)

  # 气候分量 / climate components (all indicators x windows for this pool)
  pp <- unique(d[, .(species, province)])
  for (ind in INDS) {
    cc <- merge(pp, prov[indicator == ind, .(province, year, T_t, T_base)],
                by = "province", allow.cartesian = TRUE)
    cc <- merge(cc, nat[indicator == ind, .(species, year, N_t, N_base)], by = c("species", "year"))
    cc[, x := (T_t - T_base) - (N_t - N_base)]
    setorder(cc, species, province, year)
    for (W in WINS) {
      cc[, clim_change := frollmean(x, W, align = "right"), by = .(species, province)]
      cc[, clim_var := x - clim_change]
      out <- cc[year >= YR_FROM & year <= YR_TO, .(species, province, year, x, clim_change, clim_var)]
      if (thr == 50L)
        write_parquet(out, file.path(OUT, "data", sprintf("components_v2_%s_W%d.parquet", ind, W)))
      if (ind == "tavg_annual" && W == 15L) {
        d <- merge(d, out[, .(species, province, year, x, clim_change, clim_var)],
                   by = c("species", "province", "year"), all.x = TRUE)
      }
    }
  }

  # 主分析可用行: 努力(gap 口径)与气候分量均非缺失
  d[, usable_main := is.finite(eff_visits_gap_z) & is.finite(clim_change) & is.finite(clim_var)]
  add_b(thr, "5. usable under main specification", uniqueN(d[usable_main == TRUE, .(species, province)]),
        sum(d$usable_main), sum(d$event[d$usable_main]),
        "coverage-gap effort + W15 tavg_annual components non-missing")

  write_parquet(d, file.path(OUT, "data", sprintf("model_v2_thr%d.parquet", thr)))
  msg(sprintf("thr%3d: 全表 %s 行 / %d 事件 | 主口径可用 %s 行 / %d 事件 / %d 种 / %d 省",
      thr, format(nrow(d), big.mark = ","), sum(d$event),
      format(sum(d$usable_main), big.mark = ","), sum(d$event[d$usable_main]),
      uniqueN(d[usable_main == TRUE]$species), uniqueN(d[usable_main == TRUE]$province)))
}

bt <- rbindlist(bridge)
print(bt[threshold == 50L])
fwrite(bt, file.path(OUT, "tables", "tbl_riskset_bridge_v2.csv"))
msg("wrote model_v2_thr*.parquet / tbl_riskset_bridge_v2.csv | DONE")
