#!/usr/bin/env Rscript
# ============================================================
# Script 133: v2 模型选择 —— 随机效应阶梯 + 气候规格重选
# v2 model selection: random-effect ladder and re-selection of the climate spec
# ============================================================
# Scientific question / 科学问题:
#   在 v2 数据(发现年定年、覆盖缺口努力、面积加权气候、报告完整度 offset)下,
#   哪一种随机效应结构与气候度量口径能同时满足:
#     (a) AIC 最优; (b) 方差分量可识别(不塌缩); (c) 努力效应仍稳健;
#     (d) 结构与科学假设一致(物种、地区、地区-年三级异质性)。
#
# 阶梯 / Ladder (固定效应恒为 clim_change_z * effort_z + clim_var_z):
#   R0  (1|species)
#   R1  (1|species) + (1|province)                     [v1 主模型结构]
#   R2  (1|species) + (1|province) + (1|year)
#   R3  (1|species) + (1|province) + (1|province:year) [用户指定待检验]
#   R4  R3 + (0 + clim_change_z | species)             物种特异气候斜率
#   R5  R3 + (0 + effort_z | province)                 省特异努力斜率
#
# offset / 报告完整度:
#   全部模型均带 offset(log_completeness)。cloglog 下观测风险 ~ c_t * h_t,
#   故 log(-log(1-p)) = eta + log(c_t) 精确成立(小风险近似)。
#   另拟合无 offset 版本作敏感性对照。
#
# 气候规格 / Climate specification:
#   在选定的随机效应结构下, 重跑 4 指标 x 4 窗口, 按 AIC 与努力/气候系数
#   的稳健性重新选择主口径(v1 为 tavg_annual, W=15)。
#
# Input / 输入:  analysis_v2/data/model_v2_thr50.parquet
#                analysis_v2/data/components_v2_{ind}_W{W}.parquet
# Output / 输出: analysis_v2/tables/tbl_v2_re_ladder.csv
#                analysis_v2/tables/tbl_v2_indicator_window.csv
#                analysis_v2/data/main_model_v2.rds
#
# Main packages / 主要包: glmmTMB, data.table, arrow
# 运行 / Run: Rscript --no-init-file code/133_model_selection_v2.R
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
msg <- function(...) cat(sprintf("[133 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

EFFORT <- "eff_visits_gap_z"     # 主努力代理: visits, 覆盖缺口口径
IND0   <- "tavg_annual"; W0 <- 15L
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

zs <- function(x) as.numeric(scale(x))

prep <- function(thr = 50L, ind = IND0, W = W0, effort = EFFORT) {
  d <- as.data.table(read_parquet(file.path(OUT, "data", sprintf("model_v2_thr%d.parquet", thr))))
  d[, c("x", "clim_change", "clim_var") := NULL]
  cc <- as.data.table(read_parquet(file.path(OUT, "data", sprintf("components_v2_%s_W%d.parquet", ind, W))))
  d <- merge(d, cc[, .(species, province, year, clim_change, clim_var)],
             by = c("species", "province", "year"))
  d <- d[is.finite(clim_change) & is.finite(clim_var) & is.finite(get(effort))]
  d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var),
           effort_z = zs(get(effort)), prov_year = interaction(province, year, drop = TRUE))]
  d[]
}

# NB: 必须把 offset 写进公式。glmmTMB 的 `offset=` 参数在此数据上会触发
# segfault (getParameterOrder), 公式内 offset() 则正常。
fit1 <- function(d, re, offset = TRUE) {
  f <- as.formula(paste("event ~ clim_change_z * effort_z + clim_var_z +",
                        if (offset) "offset(log_completeness) +" else "", re))
  tryCatch(glmmTMB(f, data = d, family = binomial("cloglog")),
           error = function(e) { msg("  FAILED: ", conditionMessage(e)); NULL })
}

summ <- function(m, label, d, offset) {
  if (is.null(m) || !is.finite(AIC(m))) return(data.table(model = label, converged = FALSE))
  cf <- summary(m)$coefficients$cond
  vc <- glmmTMB::VarCorr(m)$cond
  sdv <- vapply(vc, function(v) sqrt(v[1, 1]), numeric(1))
  g <- function(t, k) if (t %in% rownames(cf)) cf[t, k] else NA_real_
  it <- grep(":", rownames(cf), value = TRUE)[1]
  data.table(model = label, converged = TRUE, offset = offset,
             n = nrow(d), events = sum(d$event), AIC = AIC(m), logLik = as.numeric(logLik(m)),
             HR_effort = exp(g("effort_z", 1)),        P_effort = g("effort_z", 4),
             HR_change = exp(g("clim_change_z", 1)),   P_change = g("clim_change_z", 4),
             HR_var    = exp(g("clim_var_z", 1)),      P_var    = g("clim_var_z", 4),
             HR_int    = exp(g(it, 1)),                P_int    = g(it, 4),
             min_re_sd = min(sdv), re_terms = paste(sprintf("%s=%.3f", names(sdv), sdv), collapse = "; "))
}

# ---- 1. 随机效应阶梯 ----
d <- prep()
msg("建模数据: ", format(nrow(d), big.mark = ","), " 行 | ", sum(d$event), " 事件 | ",
    uniqueN(d$species), " 种 | ", uniqueN(d$province), " 省 | province:year ", uniqueN(d$prov_year), " 层")

RE <- c(
  R0 = "(1|species)",
  R1 = "(1|species) + (1|province)",
  R2 = "(1|species) + (1|province) + (1|year)",
  R3 = "(1|species) + (1|province) + (1|prov_year)",
  R4 = "(1|species) + (1|province) + (1|prov_year) + (0 + clim_change_z|species)",
  R5 = "(1|species) + (1|province) + (1|prov_year) + (0 + effort_z|province)")

res <- list()
for (nm in names(RE)) {
  t0 <- Sys.time()
  m  <- fit1(d, RE[[nm]], offset = TRUE)
  res[[nm]] <- summ(m, sprintf("%s: %s", nm, RE[[nm]]), d, "yes")
  msg(sprintf("  %s  AIC=%s  HR_effort=%.3f  HR_change=%.3f  HR_int=%.3f  min_re_sd=%.4f  [%.0fs]",
      nm, if (is.null(res[[nm]]$AIC)) "NA" else format(round(res[[nm]]$AIC, 1), big.mark = ","),
      res[[nm]]$HR_effort %||% NA, res[[nm]]$HR_change %||% NA, res[[nm]]$HR_int %||% NA,
      res[[nm]]$min_re_sd %||% NA, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  if (!is.null(m)) saveRDS(m, file.path(OUT, "data", sprintf("fit_%s.rds", nm)))
}
# 无 offset 对照 / no-offset control on the best structure
lad <- rbindlist(res, fill = TRUE)
best <- lad[converged == TRUE][which.min(AIC)]$model
best_key <- sub(":.*", "", best)
msg("AIC 最优: ", best)
m_noff <- fit1(d, RE[[best_key]], offset = FALSE)
lad <- rbind(lad, summ(m_noff, sprintf("%s (no offset)", best), d, "no"), fill = TRUE)
fwrite(lad, file.path(OUT, "tables", "tbl_v2_re_ladder.csv"))
print(lad[, .(model, AIC, HR_effort, HR_change, HR_int, min_re_sd)])

msg("阶梯完成, 进入指标 x 窗口重选")
saveRDS(list(best_key = best_key, RE = RE), file.path(OUT, "data", "_re_choice.rds"))
