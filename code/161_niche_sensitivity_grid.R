#!/usr/bin/env Rscript
# ============================================================
# Script 161: 替代气候代理的正式敏感性网格
# Formal sensitivity grid for the alternative climate proxies
# ============================================================
# Scientific question / 科学问题:
#   脚本 160 在 W=15 与 W=20 两个窗口上比较了六种气候代理。本脚本把它扩展成
#   一个正式的敏感性网格, 回答三个问题:
#     (1) 各代理的气候主效应与【气候 x 努力】交互, 随累积窗口如何变化?
#         尤其: tavg 系列的负交互与 tmax 系列的无交互, 是窗口的偶然还是结构?
#     (2) 热暴露调节项(S4M)在三档 SDM 阈值下是否稳健?
#     (3) 热暴露调节项在四种努力代理下是否稳健?
#
# 网格 / Grid:
#   A 窗口:  6 规格 x W {5, 10, 15, 20}                       = 24 拟合
#   B 阈值:  S4M x SDM 阈值 {100, 200} (50 已在 A 中)          =  2 拟合
#   C 努力:  S4M x {observers, days, records} (visits 已在 A)  =  3 拟合
#
# 规格 / Specifications (与 160 完全一致的构造):
#   S0 tavg_annual    x = [T-T_b] - [N-N_b]           主模型, 单调"越暖越好"
#   S1 tmax_warm      x 同上, 换最热月最高温            热极值
#   S2 niche_prox     x = -|gap(t)|                   生态位邻近度(水平量)
#   S3 niche_track    x = -|gap(t)| + |gap_b|         生态位追踪(单峰版 S0)
#   S4 heat_exposure  x = T_tmax(p,t) - N_tmax_b(s)   热暴露
#   S4M               S0 + 以 S4 的累积量调节 S0        机制性拓展
#
# AIC 可比性 / AIC comparability (关键):
#   A 组内所有拟合共用同一行集(每个窗口都在 2002-2024 上完整), 故 AIC 可比。
#   B 与 C 改变了样本量或标准化尺度, 【AIC 跨组不可比】, 只比较系数 ——
#   这与本仓库对阈值和努力口径的既有处理一致(见 139 脚本与正文 Fig3 说明)。
#
# Input / 输入:
#   analysis_v2/data/model_v2_thr{50,100,200}.parquet     (132)
#   analysis_final/data/panel_full_{grid,species}.csv     (120)
#   analysis_rebuilt/data/grid_province_lookup.csv
#
# Output / 输出:
#   analysis_v2/tables/_ns_{shard}.csv                    分片
#   analysis_v2/tables/tbl_v2_niche_sensitivity_grid.csv  合并
#
# 注意 / NB: 与脚本 134 同样的理由 —— 多次拟合放在同一进程会累积内存,
#   故按规格分进程, 每进程最多 4 次拟合, 最后合并。
#
# Main packages / 主要包: data.table, arrow, glmmTMB
# 运行 / Run:
#   for s in S0_tavg_annual S1_tmax_warm S2_niche_prox S3_niche_track \
#            S4_heat_exposure S4M_exposure_moderates extra; do
#     Rscript --no-init-file code/161_niche_sensitivity_grid.R $s
#   done
#   Rscript --no-init-file code/161_niche_sensitivity_grid.R --merge
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)

ROOT <- normalizePath(".", mustWork = TRUE)
OUT  <- file.path(ROOT, "analysis_v2")
RB   <- file.path(ROOT, "analysis_rebuilt")
FN   <- file.path(ROOT, "analysis_final")
TAB  <- file.path(OUT, "tables")
msg  <- function(...) cat(sprintf("[161 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

RE_MAIN <- "(1|species) + (1|province) + (1|prov_year)"
WINS    <- c(5L, 10L, 15L, 20L)
YR_FROM <- 2002L; YR_TO <- 2024L
SPECS   <- c("S0_tavg_annual", "S1_tmax_warm", "S2_niche_prox",
             "S3_niche_track", "S4_heat_exposure", "S4M_exposure_moderates")
LAB <- c(S0_tavg_annual = "Relative warming, annual mean (main)",
         S1_tmax_warm   = "Relative warming, warmest-month max",
         S2_niche_prox  = "Niche proximity, level",
         S3_niche_track = "Niche tracking, change",
         S4_heat_exposure = "Heat exposure",
         S4M_exposure_moderates = "Warming x heat-exposure moderation")
zs <- function(x) as.numeric(scale(x))

args <- commandArgs(trailingOnly = TRUE)

# ---- --merge: 合并分片 ----------------------------------------------------
if (length(args) && args[1] == "--merge") {
  sh <- list.files(TAB, "^_ns_.*\\.csv$", full.names = TRUE)
  tb <- rbindlist(lapply(sh, fread), fill = TRUE)
  # ΔAIC 只在窗口组内定义(同一行集); 阈值/努力组不参与
  tb[block == "A_window", dAIC := AIC - min(AIC)]
  setorder(tb, block, spec, window)
  fwrite(tb, file.path(TAB, "tbl_v2_niche_sensitivity_grid.csv"))
  cat("\n=== A. 窗口网格 / window grid ===\n")
  print(tb[block == "A_window", .(spec, window, AIC = round(AIC, 1), dAIC = round(dAIC, 1),
        HR_climate = round(HR_climate, 3), P_climate = signif(P_climate, 2),
        HR_int = round(HR_int, 3), P_int = signif(P_int, 2), sd_pyr = round(sd_prov_year, 3))])
  cat("\n=== B/C. 阈值与努力代理(AIC 不可比, 只看系数) ===\n")
  print(tb[block != "A_window", .(block, spec, threshold, effort, n, events,
        HR_climate = round(HR_climate, 3), HR_int = round(HR_int, 3),
        HR_mod = round(HR_moderation, 3), P_mod = signif(P_moderation, 2))])
  msg("merged ", length(sh), " shards -> tbl_v2_niche_sensitivity_grid.csv | DONE")
  quit(status = 0)
}
SHARD <- if (length(args)) args[1] else stop("give a spec name, 'extra', or --merge")
stopifnot(SHARD %in% c(SPECS, "extra"))
msg("分片: ", SHARD)

# ---- 1. 气候序列 ----------------------------------------------------------
gp  <- fread(file.path(FN, "data", "panel_full_grid.csv"))
g2p <- fread(file.path(RB, "data", "grid_province_lookup.csv"), encoding = "UTF-8")
gp  <- merge(gp, g2p[, .(grid_cell, province, olap)], by = "grid_cell")
prov <- gp[, .(T_t    = stats::weighted.mean(val,      olap, na.rm = TRUE),
               T_base = stats::weighted.mean(baseline, olap, na.rm = TRUE)),
           by = .(province, year, indicator)]
spn <- fread(file.path(FN, "data", "panel_full_species.csv"))
nat <- spn[, .(species, year, indicator, N_t = val, N_base = baseline)]
rm(gp); invisible(gc())

pair_series <- function(pp, ind) {
  cc <- merge(pp, prov[indicator == ind, .(province, year, T_t, T_base)],
              by = "province", allow.cartesian = TRUE)
  cc <- merge(cc, nat[indicator == ind, .(species, year, N_t, N_base)],
              by = c("species", "year"))
  setorder(cc, species, province, year)
  cc[]
}

# 由规格名给出逐年 x / annual series x for a given specification
make_x <- function(spec, S_tavg, S_tmax) {
  switch(spec,
    S0_tavg_annual   = copy(S_tavg)[, x := (T_t - T_base) - (N_t - N_base)],
    S1_tmax_warm     = copy(S_tmax)[, x := (T_t - T_base) - (N_t - N_base)],
    S2_niche_prox    = copy(S_tavg)[, x := -abs(T_t - N_t)],
    S3_niche_track   = copy(S_tavg)[, x := -abs(T_t - N_t) + abs(T_base - N_base)],
    S4_heat_exposure = copy(S_tmax)[, x := T_t - N_base],
    stop("unknown spec"))
}
components <- function(cc, W, prefix) {
  cc[, ch := frollmean(x, W, align = "right"), by = .(species, province)]
  cc[, vr := x - ch]
  out <- cc[year >= YR_FROM & year <= YR_TO, .(species, province, year, ch, vr)]
  setnames(out, c("ch", "vr"), paste0(prefix, c("_change", "_var")))
  out
}

# 统一的拟合与提取 / one fit, one row
fit_row <- function(d, spec, W, block, threshold, effort_nm) {
  moderated <- spec == "S4M_exposure_moderates"
  f <- as.formula(paste("event ~ clim_change_z * effort_z +",
                        if (moderated) "clim_change_z * exposure_z +" else "",
                        "clim_var_z + offset(log_completeness) +", RE_MAIN))
  t0 <- Sys.time()
  m <- tryCatch(glmmTMB(f, data = d, family = binomial("cloglog")),
                error = function(e) { msg("  FAILED ", spec, " W", W, ": ", conditionMessage(e)); NULL })
  if (is.null(m)) return(NULL)
  cf <- summary(m)$coefficients$cond
  g  <- function(t, k) if (t %in% rownames(cf)) cf[t, k] else NA_real_
  vc <- glmmTMB::VarCorr(m)$cond
  sdv <- vapply(vc, function(v) sqrt(v[1, 1]), numeric(1))
  ci <- function(t) { b <- g(t, 1); s <- g(t, 2)
    c(exp(b), exp(b - 1.96 * s), exp(b + 1.96 * s), g(t, 4)) }
  cl <- ci("clim_change_z"); it <- ci("clim_change_z:effort_z")
  ef <- ci("effort_z");      vr <- ci("clim_var_z")
  md <- if (moderated) ci("clim_change_z:exposure_z") else rep(NA_real_, 4)
  ex <- if (moderated) ci("exposure_z") else rep(NA_real_, 4)
  msg(sprintf("  %-24s W=%2d thr=%3s eff=%-18s AIC=%8.1f HR_cl=%.3f HR_int=%.3f [%.0fs]",
      spec, W, threshold, effort_nm, AIC(m), cl[1], it[1],
      as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  out <- data.table(
    block = block, spec = spec, label = LAB[[spec]], window = W,
    threshold = threshold, effort = effort_nm, n = nrow(d), events = sum(d$event),
    AIC = AIC(m), logLik = as.numeric(logLik(m)),
    HR_climate = cl[1], lo_climate = cl[2], hi_climate = cl[3], P_climate = cl[4],
    HR_effort  = ef[1], lo_effort  = ef[2], hi_effort  = ef[3], P_effort  = ef[4],
    HR_var     = vr[1], lo_var     = vr[2], hi_var     = vr[3], P_var     = vr[4],
    HR_int     = it[1], lo_int     = it[2], hi_int     = it[3], P_int     = it[4],
    HR_exposure = ex[1], lo_exposure = ex[2], hi_exposure = ex[3], P_exposure = ex[4],
    HR_moderation = md[1], lo_moderation = md[2], hi_moderation = md[3], P_moderation = md[4],
    sd_species = sdv[["species"]], sd_province = sdv[["province"]],
    sd_prov_year = sdv[["prov_year"]])
  rm(m); invisible(gc())
  out
}

# 给定阈值与努力代理, 备好基础表 / assemble the base table
# NB: 这里【不】标准化努力。z 化必须在所有缺失过滤完成之后, 在最终建模样本上
#     进行, 否则标准化的分母来自一个更大的样本, 系数会与脚本 134/160 及正文
#     报告的数字产生微小但真实的偏差。
make_base <- function(thr, effort_nm) {
  b <- as.data.table(read_parquet(file.path(OUT, "data", sprintf("model_v2_thr%d.parquet", thr))))
  b[, c("x", "clim_change", "clim_var") := NULL]
  b <- b[is.finite(get(effort_nm))]
  b[, prov_year := interaction(province, year, drop = TRUE)]
  b[]
}

# 在最终样本上一次性标准化全部预测变量 / standardise once, on the final sample
standardise <- function(d, effort_nm, moderated) {
  d[, `:=`(clim_change_z = zs(cl_change), clim_var_z = zs(cl_var), effort_z = zs(get(effort_nm)))]
  if (moderated) d[, exposure_z := zs(ex_change)]
  d[]
}

res <- list()

# ---- 2A. 窗口网格 ---------------------------------------------------------
if (SHARD %in% SPECS) {
  base <- make_base(50L, "eff_visits_gap_z")
  pp <- unique(base[, .(species, province)])
  S_tavg <- pair_series(pp, "tavg_annual"); S_tmax <- pair_series(pp, "tmax_warm")
  need_expo <- SHARD == "S4M_exposure_moderates"
  core_spec <- if (need_expo) "S0_tavg_annual" else SHARD

  for (W in WINS) {
    cc <- components(make_x(core_spec, S_tavg, S_tmax), W, "cl")
    d  <- merge(base, cc, by = c("species", "province", "year"))
    if (need_expo) {
      ee <- components(make_x("S4_heat_exposure", S_tavg, S_tmax), W, "ex")
      d  <- merge(d, ee, by = c("species", "province", "year"))
      d  <- d[is.finite(ex_change)]
    }
    d <- d[is.finite(cl_change) & is.finite(cl_var)]
    d <- standardise(d, "eff_visits_gap_z", need_expo)
    r <- fit_row(d, SHARD, W, "A_window", "50", "visits")
    if (!is.null(r)) res[[length(res) + 1L]] <- r
    rm(d, cc); invisible(gc())
  }
}

# ---- 2B/2C. 阈值与努力代理(均在 W = 15 上, 只针对 S4M) --------------------
if (SHARD == "extra") {
  W <- 15L
  grid <- rbind(
    data.table(block = "B_threshold", thr = c(100L, 200L), eff = "eff_visits_gap_z"),
    data.table(block = "C_effort", thr = 50L,
               eff = c("eff_observers_gap_z", "eff_days_gap_z", "eff_record_gap_z")))
  for (i in seq_len(nrow(grid))) {
    base <- make_base(grid$thr[i], grid$eff[i])
    pp <- unique(base[, .(species, province)])
    S_tavg <- pair_series(pp, "tavg_annual"); S_tmax <- pair_series(pp, "tmax_warm")
    cc <- components(make_x("S0_tavg_annual", S_tavg, S_tmax), W, "cl")
    ee <- components(make_x("S4_heat_exposure", S_tavg, S_tmax), W, "ex")
    d  <- merge(merge(base, cc, by = c("species", "province", "year")),
                ee, by = c("species", "province", "year"))
    d  <- d[is.finite(cl_change) & is.finite(cl_var) & is.finite(ex_change)]
    d  <- standardise(d, grid$eff[i], TRUE)
    r <- fit_row(d, "S4M_exposure_moderates", W, grid$block[i],
                 as.character(grid$thr[i]), sub("^eff_(.*)_gap_z$", "\\1", grid$eff[i]))
    if (!is.null(r)) res[[length(res) + 1L]] <- r
    rm(base, d, cc, ee, S_tavg, S_tmax); invisible(gc())
  }
}

tb <- rbindlist(res, fill = TRUE)
fwrite(tb, file.path(TAB, sprintf("_ns_%s.csv", SHARD)))
msg("wrote shard _ns_", SHARD, ".csv (", nrow(tb), " fits) | DONE")
