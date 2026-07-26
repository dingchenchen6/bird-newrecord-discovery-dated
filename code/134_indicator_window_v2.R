#!/usr/bin/env Rscript
# ============================================================
# Script 134: v2 气候规格重选 —— 4 指标 x 4 窗口
# v2 re-selection of the climate specification: 4 indicators x 4 windows
# ============================================================
# 科学问题 / Scientific question:
#   在冻结的主随机效应结构(R3: 种 + 省 + 省×年)下, 哪一个气候指标与
#   哪一个累积窗口最能刻画"驱动新记录生成风险"的变暖信号?
#   v1 的选择(tavg_annual, W=15)在发表年定年下得到, 必须在发现年定年下重选。
#
# 指标 / Indicators:
#   tavg_annual 年均温 | tavg_winter 冬季均温 | tmax_warm 最热月最高温 | tmin_cold 最冷月最低温
# 窗口 / Windows: 5 / 10 / 15 / 20 年(严格只回看)
#
# 判据 / Selection criteria (按优先级):
#   1. AIC; 2. 气候主效应的方向与显著性; 3. 努力效应的稳健性;
#   4. 气候变化与气候变异的可分离性(两者相关性低)。
#
# Input / 输入:  analysis_v2/data/model_v2_thr50.parquet
#                analysis_v2/data/components_v2_{ind}_W{W}.parquet
# Output / 输出: analysis_v2/tables/_iw_{indicator}.csv (分片)
#                analysis_v2/tables/tbl_v2_indicator_window.csv (合并)
#
# 注意 / NB: 16 次拟合放在同一进程中会被系统杀掉(内存累积, 无错误输出),
#   故按指标分进程运行, 每个进程只拟合 4 个窗口, 最后合并分片。
#
# Main packages / 主要包: glmmTMB, data.table, arrow
# 运行 / Run: for i in tavg_annual tavg_winter tmax_warm tmin_cold; do
#               Rscript --no-init-file code/134_indicator_window_v2.R $i; done
#             Rscript --no-init-file code/134_indicator_window_v2.R --merge
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
msg <- function(...) cat(sprintf("[134 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

EFFORT <- "eff_visits_gap_z"
RE_MAIN <- "(1|species) + (1|province) + (1|prov_year)"   # 冻结的主结构 R3
ALL_INDS <- c("tavg_annual", "tavg_winter", "tmax_warm", "tmin_cold")
WINS <- c(5L, 10L, 15L, 20L)
zs <- function(x) as.numeric(scale(x))

args <- commandArgs(trailingOnly = TRUE)
# --merge: 合并各指标分片 / merge the per-indicator shards and exit
if (length(args) && args[1] == "--merge") {
  sh <- list.files(file.path(OUT, "tables"), "^_iw_.*\\.csv$", full.names = TRUE)
  tb <- rbindlist(lapply(sh, fread))
  tb[, dAIC := AIC - min(AIC)]
  setorder(tb, AIC)
  fwrite(tb, file.path(OUT, "tables", "tbl_v2_indicator_window.csv"))
  print(tb[, .(indicator, window, AIC, dAIC = round(dAIC, 1),
               HR_change, P_change, HR_effort, HR_int, cor_change_var)])
  msg("merged ", length(sh), " shards -> tbl_v2_indicator_window.csv | DONE")
  quit(status = 0)
}
INDS <- if (length(args)) args[1] else ALL_INDS
stopifnot(all(INDS %in% ALL_INDS))
msg("本进程指标: ", paste(INDS, collapse = ", "))

base <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
base[, c("x", "clim_change", "clim_var") := NULL]
base <- base[is.finite(get(EFFORT))]
base[, prov_year := interaction(province, year, drop = TRUE)]

res <- list()
for (ind in INDS) for (W in WINS) {
  cc <- as.data.table(read_parquet(file.path(OUT, "data", sprintf("components_v2_%s_W%d.parquet", ind, W))))
  d  <- merge(base, cc[, .(species, province, year, clim_change, clim_var)],
              by = c("species", "province", "year"))
  d  <- d[is.finite(clim_change) & is.finite(clim_var)]
  d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var), effort_z = zs(get(EFFORT)))]
  f <- as.formula(paste("event ~ clim_change_z * effort_z + clim_var_z + offset(log_completeness) +", RE_MAIN))
  t0 <- Sys.time()
  m <- tryCatch(glmmTMB(f, data = d, family = binomial("cloglog")),
                error = function(e) { msg("  FAILED ", ind, " W", W, ": ", conditionMessage(e)); NULL })
  if (is.null(m)) next
  cf <- summary(m)$coefficients$cond
  it <- grep(":", rownames(cf), value = TRUE)[1]
  g <- function(t, k) if (t %in% rownames(cf)) cf[t, k] else NA_real_
  res[[paste(ind, W)]] <- data.table(
    indicator = ind, window = W, n = nrow(d), events = sum(d$event), AIC = AIC(m),
    HR_change = exp(g("clim_change_z", 1)), P_change = g("clim_change_z", 4),
    HR_effort = exp(g("effort_z", 1)),      P_effort = g("effort_z", 4),
    HR_var    = exp(g("clim_var_z", 1)),    P_var    = g("clim_var_z", 4),
    HR_int    = exp(g(it, 1)),              P_int    = g(it, 4),
    cor_change_var = cor(d$clim_change, d$clim_var),
    sd_change = stats::sd(d$clim_change), sd_var = stats::sd(d$clim_var))
  msg(sprintf("  %-12s W=%2d  AIC=%8.1f  HR_ch=%.3f(P=%.1e)  HR_eff=%.3f  HR_int=%.3f  cor=%.3f  [%.0fs]",
      ind, W, AIC(m), exp(g("clim_change_z", 1)), g("clim_change_z", 4),
      exp(g("effort_z", 1)), exp(g(it, 1)), cor(d$clim_change, d$clim_var),
      as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  rm(m, d, cc); invisible(gc())          # 显式释放, 避免多次拟合累积内存
}
tb <- rbindlist(res)
for (ind in INDS)
  fwrite(tb[indicator == ind], file.path(OUT, "tables", sprintf("_iw_%s.csv", ind)))
msg("wrote shard(s) for ", paste(INDS, collapse = ", "), " | DONE")
