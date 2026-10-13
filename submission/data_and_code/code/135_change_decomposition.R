#!/usr/bin/env Rscript
# ============================================================
# Script 135: v1 -> v2 的逐步变化分解(瀑布)
# Step-by-step decomposition of what changed between v1 and v2
# ============================================================
# 科学问题 / Scientific question:
#   v1 与 v2 的系数差异, 各由哪一处修正造成? 若不逐步分解, 读者与审稿人
#   无法判断结论的改变是"修 bug"还是"换模型"。
#
# 瀑布 / Waterfall (每步只改一处, 前四步固定用 v1 的随机效应结构 R1):
#   S0  v1 已发表口径: 发表年定年 + 零填充努力 + 未加权气候 + 无 offset
#   S1  + 发现年定年(含现患对剔除与 2025 年发表事件回收)
#   S2  + 努力覆盖缺口口径(structural_zero 视为缺失)
#   S3  + 面积加权省级气候序列
#   S4  + 报告完整度 offset(log c_t)
#   S5  + 省×年随机效应  => v2 主模型
#
# 读法 / How to read:
#   某一步之后系数发生实质变化 = 该处修正是该系数的主要驱动。
#
# Input / 输入:  v1: analysis_species_specific/data/model_thr50.parquet
#                    analysis_final/data/components_tavg_annual_W15.parquet
#                v2: analysis_v2/data/model_v2_thr50.parquet
#                    analysis_v2/data/components_v2_tavg_annual_W15.parquet
# Output / 输出: analysis_v2/tables/tbl_change_decomposition.csv
#
# Main packages / 主要包: glmmTMB, data.table, arrow
# 运行 / Run: Rscript --no-init-file code/135_change_decomposition.R
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)

V2  <- normalizePath(".", mustWork = TRUE)
OUT <- file.path(V2, "analysis_v2")
msg <- function(...) cat(sprintf("[135 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

RE1 <- "(1|species) + (1|province)"                        # v1 结构
RE3 <- "(1|species) + (1|province) + (1|prov_year)"        # v2 主结构
zs  <- function(x) as.numeric(scale(x))

fit_step <- function(d, re, use_offset, label, note) {
  d <- copy(d)[is.finite(clim_change) & is.finite(clim_var) & is.finite(effort_raw)]
  d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var), effort_z = zs(effort_raw))]
  if (grepl("prov_year", re)) d[, prov_year := interaction(province, year, drop = TRUE)]
  f <- as.formula(paste("event ~ clim_change_z * effort_z + clim_var_z +",
                        if (use_offset) "offset(log_completeness) +" else "", re))
  t0 <- Sys.time()
  m <- tryCatch(glmmTMB(f, data = d, family = binomial("cloglog")),
                error = function(e) { msg("  FAILED ", label, ": ", conditionMessage(e)); NULL })
  if (is.null(m)) return(NULL)
  cf <- summary(m)$coefficients$cond
  it <- grep(":", rownames(cf), value = TRUE)[1]
  g  <- function(t, k) if (t %in% rownames(cf)) cf[t, k] else NA_real_
  r <- data.table(step = label, change = note, n = nrow(d), events = sum(d$event), AIC = AIC(m),
    HR_effort = exp(g("effort_z", 1)),      P_effort = g("effort_z", 4),
    HR_change = exp(g("clim_change_z", 1)), P_change = g("clim_change_z", 4),
    HR_var    = exp(g("clim_var_z", 1)),    P_var    = g("clim_var_z", 4),
    HR_int    = exp(g(it, 1)),              P_int    = g(it, 4))
  msg(sprintf("  %-4s n=%s ev=%d | HR_eff=%.3f(%.0e) HR_ch=%.3f(%.0e) HR_var=%.3f(%.2f) HR_int=%.3f(%.3f) [%.0fs]",
      label, format(nrow(d), big.mark = ","), sum(d$event),
      r$HR_effort, r$P_effort, r$HR_change, r$P_change, r$HR_var, r$P_var, r$HR_int, r$P_int,
      as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  r
}

# ---------- 数据组件 ----------
v1   <- as.data.table(read_parquet("analysis_species_specific/data/model_thr50.parquet"))
cc1  <- as.data.table(read_parquet("analysis_final/data/components_tavg_annual_W15.parquet"))  # 未加权
v2   <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
cc2  <- as.data.table(read_parquet(file.path(OUT, "data", "components_v2_tavg_annual_W15.parquet")))  # 面积加权
v2[, c("x", "clim_change", "clim_var") := NULL]

out <- list()

# ---- S0: v1 已发表口径 ----
d0 <- merge(v1, cc1[, .(species, province, year, clim_change, clim_var)], by = c("species", "province", "year"))
d0[, effort_raw := eff_visits]
out$S0 <- fit_step(d0, RE1, FALSE, "S0", "v1 as published: publication-year dating, zero-filled effort, unweighted climate, no offset")

# ---- S1: + 发现年定年 ----
# v2 风险集 + v1 的努力(zero 口径, 等价于 v1 的 eff_visits)与 v1 的未加权气候
d1 <- merge(v2, cc1[, .(species, province, year, clim_change, clim_var)], by = c("species", "province", "year"))
d1[, effort_raw := eff_visits_zero_z]
out$S1 <- fit_step(d1, RE1, FALSE, "S1", "+ discovery-year dating (prevalent pairs dropped, 2025-published events recovered)")

# ---- S2: + 覆盖缺口努力 ----
d2 <- copy(d1)[, effort_raw := eff_visits_gap_z]
out$S2 <- fit_step(d2, RE1, FALSE, "S2", "+ coverage-gap effort (structural zeros treated as missing)")

# ---- S3: + 面积加权气候 ----
d3 <- merge(v2, cc2[, .(species, province, year, clim_change, clim_var)], by = c("species", "province", "year"))
d3[, effort_raw := eff_visits_gap_z]
out$S3 <- fit_step(d3, RE1, FALSE, "S3", "+ area-weighted provincial climate series")

# ---- S4: + 完整度 offset ----
out$S4 <- fit_step(d3, RE1, TRUE, "S4", "+ reporting-completeness offset log(c_t)")

# ---- S5: + 省x年随机效应 = v2 主模型 ----
out$S5 <- fit_step(d3, RE3, TRUE, "S5", "+ province-by-year random intercept  => v2 MAIN MODEL")

tb <- rbindlist(out, fill = TRUE)
# 相对上一步的变化 / change relative to the previous step
for (v in c("HR_effort", "HR_change", "HR_var", "HR_int"))
  tb[[paste0("d_", v)]] <- c(NA_real_, round(diff(tb[[v]]), 3))
fwrite(tb, file.path(OUT, "tables", "tbl_change_decomposition.csv"))
print(tb[, .(step, n, events, HR_effort, HR_change, HR_var, HR_int,
             d_HR_effort, d_HR_change, d_HR_var, d_HR_int)])
msg("wrote tbl_change_decomposition.csv | DONE")
