#!/usr/bin/env Rscript
# ============================================================
# Script 137: v2 全规格比较矩阵
# Full specification-comparison matrix for the v2 pipeline
# ============================================================
# 科学问题 / Scientific question:
#   主模型的结论(努力与累积变暖各自独立提升新记录生成风险, 且两者存在
#   负向交互)是否依赖于任何一个可自由选择的分析决策?
#
# 四个区块 / Four blocks (主结构恒为 R3: 种 + 省 + 省×年, 带完整度 offset):
#   B  努力代理 x 缺失处理: visits/observers/days/records x gap/zero/imp
#   C  SDM 阈值: 50 / 100 / 200 km(候选池收紧, 风险集分母改变)
#   D  固定效应阶梯: 逐项加入, 报告 AIC 与整体解释率(不只看 AIC)
#   E  相对重要性: 去一项(drop-one)后的 ΔAIC、Δ条件 R^2、Δ条件 AUC,
#      以及标准化系数的绝对值 —— 四个口径交叉验证重要性排序
#
# 用法 / Usage (分块运行, 避免多次拟合累积内存被系统杀掉):
#   Rscript --no-init-file code/137_full_comparison_matrix.R B
#   Rscript --no-init-file code/137_full_comparison_matrix.R C
#   Rscript --no-init-file code/137_full_comparison_matrix.R D
#   Rscript --no-init-file code/137_full_comparison_matrix.R E
#
# Output / 输出: analysis_v2/tables/tbl_v2_{B_effort,C_threshold,D_ladder,E_importance}.csv
#
# Main packages / 主要包: glmmTMB, pROC, data.table, arrow
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
msg <- function(...) cat(sprintf("[137 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

RE_MAIN <- "(1|species) + (1|province) + (1|prov_year)"
IND0 <- "tavg_annual"; W0 <- 15L
zs <- function(x) as.numeric(scale(x))
blk <- (commandArgs(trailingOnly = TRUE))[1]
if (is.na(blk)) stop("需要区块参数: B / C / D / E")

prep <- function(thr = 50L, effort = "eff_visits_gap_z", ind = IND0, W = W0) {
  d <- as.data.table(read_parquet(file.path(OUT, "data", sprintf("model_v2_thr%d.parquet", thr))))
  d[, c("x", "clim_change", "clim_var") := NULL]
  cc <- as.data.table(read_parquet(file.path(OUT, "data", sprintf("components_v2_%s_W%d.parquet", ind, W))))
  d <- merge(d, cc[, .(species, province, year, clim_change, clim_var)], by = c("species", "province", "year"))
  d <- d[is.finite(clim_change) & is.finite(clim_var) & is.finite(get(effort))]
  d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var),
           effort_z = zs(get(effort)), prov_year = interaction(province, year, drop = TRUE))]
  d[]
}
fit <- function(d, fx = "clim_change_z * effort_z + clim_var_z", re = RE_MAIN) {
  f <- as.formula(paste("event ~", fx, "+ offset(log_completeness) +", re))
  tryCatch(glmmTMB(f, data = d, family = binomial("cloglog")),
           error = function(e) { msg("  FAILED: ", conditionMessage(e)); NULL })
}
auc_of <- function(p, y) as.numeric(pROC::auc(pROC::roc(y, p, quiet = TRUE, direction = "<")))
perf <- function(m, d) {
  if (is.null(m)) return(list(AIC = NA_real_, R2c = NA_real_, AUCc = NA_real_, AUCm = NA_real_))
  vc <- glmmTMB::VarCorr(m)$cond
  vre <- sum(vapply(vc, function(v) v[1, 1], numeric(1)))
  eta <- as.numeric(predict(m, type = "link"))
  vf  <- stats::var(as.numeric(predict(m, newdata = d, type = "link", re.form = NA)))
  list(AIC = AIC(m),
       R2c = (vf + vre) / (vf + vre + pi^2 / 6),
       AUCc = auc_of(as.numeric(predict(m, type = "response")), d$event),
       AUCm = auc_of(as.numeric(predict(m, newdata = d, type = "response", re.form = NA)), d$event))
}
coefs <- function(m) {
  if (is.null(m)) return(list())
  cf <- summary(m)$coefficients$cond
  it <- grep(":", rownames(cf), value = TRUE)[1]
  g <- function(t, k) if (!is.na(t) && t %in% rownames(cf)) cf[t, k] else NA_real_
  list(HR_effort = exp(g("effort_z", 1)), P_effort = g("effort_z", 4),
       HR_change = exp(g("clim_change_z", 1)), P_change = g("clim_change_z", 4),
       HR_var = exp(g("clim_var_z", 1)), P_var = g("clim_var_z", 4),
       HR_int = exp(g(it, 1)), P_int = g(it, 4),
       b_effort = g("effort_z", 1), b_change = g("clim_change_z", 1),
       b_var = g("clim_var_z", 1), b_int = g(it, 1))
}

# ================= B: 努力代理 x 缺失处理 =================
if (blk == "B") {
  res <- list()
  for (px in c("visits", "observers", "days", "record"))
    for (trt in c("gap", "zero", "imp")) {
      col <- sprintf("eff_%s_%s_z", px, trt)
      d <- prep(effort = col)
      m <- fit(d); p <- perf(m, d); cf <- coefs(m)
      res[[paste(px, trt)]] <- data.table(proxy = px, treatment = trt, n = nrow(d),
        events = sum(d$event), AIC = p$AIC, R2_conditional = p$R2c,
        AUC_conditional = p$AUCc, AUC_marginal = p$AUCm)[, names(cf) := cf]
      msg(sprintf("  B %-9s %-4s AIC=%8.1f R2c=%.3f AUCc=%.3f | HR_eff=%.3f(%.0e) HR_ch=%.3f HR_int=%.3f",
          px, trt, p$AIC, p$R2c, p$AUCc, cf$HR_effort, cf$P_effort, cf$HR_change, cf$HR_int))
      rm(m, d); invisible(gc())
    }
  tb <- rbindlist(res); tb[, dAIC := AIC - min(AIC, na.rm = TRUE)]
  fwrite(tb, file.path(OUT, "tables", "tbl_v2_B_effort.csv")); print(tb)
}

# ================= C: SDM 阈值 =================
if (blk == "C") {
  res <- list()
  for (thr in c(50L, 100L, 200L)) {
    d <- prep(thr = thr); m <- fit(d); p <- perf(m, d); cf <- coefs(m)
    res[[as.character(thr)]] <- data.table(threshold_km = thr, n = nrow(d), events = sum(d$event),
      species = uniqueN(d$species), AIC = p$AIC, R2_conditional = p$R2c,
      AUC_conditional = p$AUCc)[, names(cf) := cf]
    msg(sprintf("  C thr%3d n=%s ev=%d AIC=%8.1f R2c=%.3f | HR_eff=%.3f HR_ch=%.3f HR_int=%.3f(%.0e)",
        thr, format(nrow(d), big.mark = ","), sum(d$event), p$AIC, p$R2c,
        cf$HR_effort, cf$HR_change, cf$HR_int, cf$P_int))
    rm(m, d); invisible(gc())
  }
  tb <- rbindlist(res); fwrite(tb, file.path(OUT, "tables", "tbl_v2_C_threshold.csv")); print(tb)
}

# ================= D: 固定效应阶梯 =================
if (blk == "D") {
  FX <- c(
    "F0 null"                    = "1",
    "F1 effort"                  = "effort_z",
    "F2 climate"                 = "clim_change_z",
    "F3 effort + climate"        = "clim_change_z + effort_z",
    "F4 + annual variability"    = "clim_change_z + effort_z + clim_var_z",
    "F5 + interaction (MAIN)"    = "clim_change_z * effort_z + clim_var_z")
  d <- prep(); res <- list()
  for (nm in names(FX)) {
    m <- fit(d, FX[[nm]]); p <- perf(m, d); cf <- coefs(m)
    res[[nm]] <- data.table(model = nm, fixed_effects = FX[[nm]],
      df = if (is.null(m)) NA_integer_ else attr(logLik(m), "df"),
      AIC = p$AIC, R2_conditional = p$R2c, AUC_conditional = p$AUCc,
      AUC_marginal = p$AUCm)[, names(cf) := cf]
    msg(sprintf("  D %-26s AIC=%8.1f R2c=%.3f AUCm=%.3f AUCc=%.3f", nm, p$AIC, p$R2c, p$AUCm, p$AUCc))
    rm(m); invisible(gc())
  }
  tb <- rbindlist(res, fill = TRUE); tb[, dAIC := AIC - min(AIC, na.rm = TRUE)]
  fwrite(tb, file.path(OUT, "tables", "tbl_v2_D_ladder.csv")); print(tb[, .(model, df, AIC, dAIC, R2_conditional, AUC_marginal)])
}

# ================= E: 相对重要性 =================
if (blk == "E") {
  d <- prep()
  full_fx <- "clim_change_z * effort_z + clim_var_z"
  mf <- fit(d, full_fx); pf <- perf(mf, d); cff <- coefs(mf)
  DROP <- c(
    "survey effort"          = "clim_change_z + clim_var_z",
    "accumulated warming"    = "effort_z + clim_var_z",
    "annual variability"     = "clim_change_z * effort_z",
    "climate x effort"       = "clim_change_z + effort_z + clim_var_z")
  BETA <- c("survey effort" = abs(cff$b_effort), "accumulated warming" = abs(cff$b_change),
            "annual variability" = abs(cff$b_var), "climate x effort" = abs(cff$b_int))
  res <- list()
  for (nm in names(DROP)) {
    m <- fit(d, DROP[[nm]]); p <- perf(m, d)
    res[[nm]] <- data.table(term = nm, dropped_formula = DROP[[nm]],
      AIC_without = p$AIC, dAIC = p$AIC - pf$AIC,
      R2c_without = p$R2c, dR2c = pf$R2c - p$R2c,
      AUCm_without = p$AUCm, dAUCm = pf$AUCm - p$AUCm,
      abs_beta = unname(BETA[nm]))
    msg(sprintf("  E drop %-22s dAIC=%+8.1f  dR2c=%+.4f  dAUCm=%+.4f  |beta|=%.3f",
        nm, p$AIC - pf$AIC, pf$R2c - p$R2c, pf$AUCm - p$AUCm, BETA[nm]))
    rm(m); invisible(gc())
  }
  tb <- rbindlist(res)
  for (v in c("dAIC", "dR2c", "dAUCm", "abs_beta"))
    tb[[paste0("rank_", v)]] <- rank(-tb[[v]], ties.method = "min")
  tb[, rank_mean := round(rowMeans(.SD), 2), .SDcols = patterns("^rank_")]
  setorder(tb, rank_mean)
  fwrite(tb, file.path(OUT, "tables", "tbl_v2_E_importance.csv"))
  print(tb[, .(term, dAIC = round(dAIC, 1), dR2c = round(dR2c, 4), dAUCm = round(dAUCm, 4),
               abs_beta = round(abs_beta, 3), rank_mean)])
}
msg("block ", blk, " DONE")
