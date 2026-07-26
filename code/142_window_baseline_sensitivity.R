#!/usr/bin/env Rscript
# ============================================================
# Script 142: 累积窗口与基线期的敏感性分析
# Sensitivity of the accumulated-warming term to window length and baseline period
# ============================================================
# 科学问题 / Scientific question:
#   "累积变暖"需要两个人为选择: (a) 回看多少年 W; (b) 用哪一段作气候基线。
#   两者都不是数据决定的, 因此必须证明结论不依赖于它们。
#
# 生态学依据 / Ecological rationale for the window:
#   W 代表"物种边界响应气候的整合时间"。太短(3-5 年)时 clim_change 里混进
#   年际天气噪声, 度量的是天气而非气候; 太长(>20 年)时窗口跨越了物种世代与
#   种群周转的时间尺度, 早期年份对当下边界的信息量下降。鸟类分布边界的推移
#   通常在十年尺度上可检出, 故预期最优 W 落在 10-20 年。
#
# 生态学依据 / Ecological rationale for the baseline:
#   基线定义"该物种历史上习惯的气候"与"该省历史的气候"。1980-2000 是本研究
#   分析期(2002-2024)之前最近的完整时段, 不与分析期重叠, 因此不会把响应变量
#   所处年份的气候写进基线。WMO 式 30 年常态(1981-2010, 1991-2020)与分析期
#   部分重叠, 作为对照可检验这一选择是否关键。
#
# 网格 / Grid:
#   W       3, 5, 8, 10, 12, 15, 18, 20, 23 年 (W=23 时 2002 年的窗口恰为 1980-2002)
#   基线    1980-2000 (主) | 1981-2010 | 1991-2020
#
# 用法 / Usage (按基线分进程, 避免多次拟合累积内存被杀):
#   Rscript --no-init-file code/142_window_baseline_sensitivity.R 1980_2000
#   Rscript --no-init-file code/142_window_baseline_sensitivity.R 1981_2010
#   Rscript --no-init-file code/142_window_baseline_sensitivity.R 1991_2020
#   Rscript --no-init-file code/142_window_baseline_sensitivity.R --merge
#
# Output / 输出: analysis_v2/tables/tbl_v2_window_baseline_sensitivity.csv
#
# Main packages / 主要包: glmmTMB, data.table, arrow
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)

V2  <- normalizePath(".", mustWork = TRUE)
RB  <- file.path(V2, "analysis_rebuilt")
FN  <- file.path(V2, "analysis_final")
OUT <- file.path(V2, "analysis_v2")
msg <- function(...) cat(sprintf("[142 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

WINS <- c(3L, 5L, 8L, 10L, 12L, 15L, 18L, 20L, 23L)
BASES <- list(`1980_2000` = c(1980L, 2000L), `1981_2010` = c(1981L, 2010L), `1991_2020` = c(1991L, 2020L))
IND <- "tavg_annual"; EFFORT <- "eff_visits_gap_z"
RE_MAIN <- "(1|species) + (1|province) + (1|prov_year)"
YR_FROM <- 2002L; YR_TO <- 2024L
zs <- function(v) as.numeric(scale(v))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) && args[1] == "--merge") {
  sh <- list.files(file.path(OUT, "tables"), "^_wb_.*\\.csv$", full.names = TRUE)
  tb <- rbindlist(lapply(sh, fread))
  tb[, dAIC_within_baseline := AIC - min(AIC), by = baseline]
  setorder(tb, baseline, window)
  fwrite(tb, file.path(OUT, "tables", "tbl_v2_window_baseline_sensitivity.csv"))
  print(tb[, .(baseline, window, n, events, HR_change = round(HR_change, 3),
               P_change = signif(P_change, 2), HR_effort = round(HR_effort, 3),
               HR_int = round(HR_int, 3), P_int = signif(P_int, 2),
               dAIC = round(dAIC_within_baseline, 1))])
  msg("merged ", length(sh), " shards | DONE"); quit(status = 0)
}
BKEY <- if (length(args)) args[1] else "1980_2000"
stopifnot(BKEY %in% names(BASES))
BASE <- BASES[[BKEY]]
msg("基线期 ", BASE[1], "-", BASE[2])

# ---- 省级(面积加权)与物种分布区序列, 按指定基线重算异常 ----
gp  <- fread(file.path(FN, "data", "panel_full_grid.csv"))[indicator == IND]
g2p <- fread(file.path(RB, "data", "grid_province_lookup.csv"), encoding = "UTF-8")
gp  <- merge(gp, g2p[, .(grid_cell, province, olap)], by = "grid_cell")
prov <- gp[, .(T_t = stats::weighted.mean(val, olap, na.rm = TRUE)), by = .(province, year)]
prov <- merge(prov, gp[year %between% BASE, .(T_t = stats::weighted.mean(val, olap, na.rm = TRUE)),
                       by = .(province, year)][, .(T_base = mean(T_t)), by = province], by = "province")

sp <- fread(file.path(FN, "data", "panel_full_species.csv"))[indicator == IND]
nat <- merge(sp[, .(species, year, N_t = val)],
             sp[year %between% BASE, .(N_base = mean(val)), by = species], by = "species")
msg("省级序列 ", uniqueN(prov$province), " 省 | 物种序列 ", uniqueN(nat$species), " 种")

# ---- 风险集与努力 ----
d0 <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
d0[, c("x", "clim_change", "clim_var") := NULL]
d0 <- d0[is.finite(get(EFFORT))]
d0[, prov_year := interaction(province, year, drop = TRUE)]
pp <- unique(d0[, .(species, province)])

cc <- merge(pp, prov, by = "province", allow.cartesian = TRUE)
cc <- merge(cc, nat, by = c("species", "year"))
cc[, x := (T_t - T_base) - (N_t - N_base)]
setorder(cc, species, province, year)

res <- list()
for (W in WINS) {
  cc[, clim_change := frollmean(x, W, align = "right"), by = .(species, province)]
  cc[, clim_var := x - clim_change]
  d <- merge(d0, cc[year %between% c(YR_FROM, YR_TO), .(species, province, year, clim_change, clim_var)],
             by = c("species", "province", "year"))
  d <- d[is.finite(clim_change) & is.finite(clim_var)]
  d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var), effort_z = zs(get(EFFORT)))]
  f <- as.formula(paste("event ~ clim_change_z * effort_z + clim_var_z + offset(log_completeness) +", RE_MAIN))
  t0 <- Sys.time()
  m <- tryCatch(glmmTMB(f, data = d, family = binomial("cloglog")),
                error = function(e) { msg("  FAILED W", W, ": ", conditionMessage(e)); NULL })
  if (is.null(m)) next
  cf <- summary(m)$coefficients$cond
  it <- grep(":", rownames(cf), value = TRUE)[1]
  g <- function(t, k) if (t %in% rownames(cf)) cf[t, k] else NA_real_
  se <- function(t) g(t, 2)
  res[[as.character(W)]] <- data.table(
    baseline = paste0(BASE[1], "-", BASE[2]), window = W, n = nrow(d), events = sum(d$event),
    AIC = AIC(m), sd_change_degC = stats::sd(d$clim_change), sd_var_degC = stats::sd(d$clim_var),
    cor_change_var = cor(d$clim_change, d$clim_var),
    HR_change = exp(g("clim_change_z", 1)), lo_change = exp(g("clim_change_z", 1) - 1.96 * se("clim_change_z")),
    hi_change = exp(g("clim_change_z", 1) + 1.96 * se("clim_change_z")), P_change = g("clim_change_z", 4),
    HR_effort = exp(g("effort_z", 1)), lo_effort = exp(g("effort_z", 1) - 1.96 * se("effort_z")),
    hi_effort = exp(g("effort_z", 1) + 1.96 * se("effort_z")), P_effort = g("effort_z", 4),
    HR_var = exp(g("clim_var_z", 1)), P_var = g("clim_var_z", 4),
    HR_int = exp(g(it, 1)), lo_int = exp(g(it, 1) - 1.96 * se(it)),
    hi_int = exp(g(it, 1) + 1.96 * se(it)), P_int = g(it, 4))
  msg(sprintf("  W=%2d  n=%s ev=%d  AIC=%8.1f  HR_ch=%.3f(%.0e)  HR_eff=%.3f  HR_int=%.3f(%.3f)  SD_ch=%.3f°C  [%.0fs]",
      W, format(nrow(d), big.mark = ","), sum(d$event), AIC(m),
      res[[as.character(W)]]$HR_change, res[[as.character(W)]]$P_change,
      res[[as.character(W)]]$HR_effort, res[[as.character(W)]]$HR_int, res[[as.character(W)]]$P_int,
      res[[as.character(W)]]$sd_change_degC, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  rm(m, d); invisible(gc())
}
fwrite(rbindlist(res), file.path(OUT, "tables", sprintf("_wb_%s.csv", BKEY)))
msg("wrote shard for baseline ", BKEY, " | DONE")
