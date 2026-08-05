# ============================================================
# Scientific question / 科学问题:
# 主模型的置信区间依赖随机效应结构被正确设定。如果这一假设不成立,
# 区间还站得住吗?另外,结果会不会由少数几个物种或省份撑起?
# The model-based CIs assume the random-effect structure is correctly
# specified. Cluster bootstrap gives design-robust intervals; a parametric
# bootstrap checks that the estimator recovers its own truth; leave-one-out
# refits show whether a few clusters carry the result.
#
# Objective / 分析目标:
#   1. 聚类自助:按物种、按省份分别重抽,给出设计稳健的百分位 CI
#   2. 参数自助:从拟合模型模拟新响应再拟合,检查系数回收与区间覆盖
#   3. 影响力:逐个剔除省份、逐组剔除物种,看四个系数怎么动
#
# Input data / 输入数据:
#   analysis_v2/data/model_v2_thr50.parquet
#
# Expected output / 预期输出:
#   analysis_v2/data/boot_draws.rds
#   analysis_v2/tables/tbl_bootstrap_ci.csv
#   analysis_v2/tables/tbl_parametric_bootstrap.csv
#   analysis_v2/tables/tbl_influence_loo.csv
#
# Key assumptions / 关键假设:
#   - 聚类自助 300 次、参数自助 150 次(单次拟合 39 秒,6 进程并行)。
#     重抽次数在正文中如实报告,不四舍五入成「1000 次」。
#   - 聚类自助按物种(392 个簇)与按省份(31 个簇)分别做。省份只有 31 个簇,
#     自助分布必然粗糙,结果只作参考并明确标注。
#   - 重抽后同一个簇可能被抽中多次,故对被重抽的那一层重新编号;
#     其余随机效应层级保持原名,以免破坏交叉结构。
#   - 参数自助从拟合模型模拟响应(含随机效应重抽),因此检验的是
#     「在模型自己的假设下,估计量能否无偏回收并给出名义覆盖」。
#   - 拟合一律用 profile=TRUE,并行 6 进程。
#
# Main packages / 主要包: glmmTMB, data.table, arrow, parallel
# Output directory / 输出路径: analysis_v2/data/, analysis_v2/tables/
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(glmmTMB); library(parallel)
})
set.seed(20260805)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_DT <- file.path(V2, "analysis_v2/data")
D_TB <- file.path(V2, "analysis_v2/tables")
NBOOT <- 300L; NPAR <- 150L; NCORE <- 6L
msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

d <- as.data.table(read_parquet(file.path(D_DT, "model_v2_thr50.parquet")))[usable_main == TRUE]
zs <- function(x) as.numeric(scale(x))
d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var),
         effort_z = eff_visits_gap_z)]

FM <- event ~ clim_change_z * effort_z + clim_var_z + offset(log_completeness) +
  (1 | species) + (1 | province) + (1 | province:year)
CTL <- glmmTMBControl(profile = TRUE)
TERMS <- c("clim_change_z", "effort_z", "clim_var_z", "clim_change_z:effort_z")

fit_coef <- function(dd) {
  f <- tryCatch(glmmTMB(FM, data = dd, family = binomial("cloglog"), control = CTL),
                error = function(e) NULL)
  if (is.null(f)) return(setNames(rep(NA_real_, length(TERMS)), TERMS))
  setNames(fixef(f)$cond[TERMS], TERMS)
}

msg("观测模型 / observed fit")
fit0 <- glmmTMB(FM, data = d, family = binomial("cloglog"), control = CTL)
obs <- setNames(fixef(fit0)$cond[TERMS], TERMS)
se0 <- summary(fit0)$coefficients$cond[TERMS, "Std. Error"]

# ------------------------------------------------------------
# 1. 聚类自助
# ------------------------------------------------------------
#' 按簇重抽并重新编号。**只重命名被重抽的那一层**:
#' 按物种重抽时省份必须保持原名,否则省与省 × 年随机效应会被打散
#' (省的水平数会从 31 膨胀到上万),那已经不是原来的模型了。
#' Rename only the resampled clustering variable; renaming the others would
#' destroy the crossed random-effect structure being bootstrapped.
boot_cluster <- function(dd, cl_col) {
  cls <- unique(dd[[cl_col]])
  pick <- sample(cls, length(cls), replace = TRUE)
  rbindlist(lapply(seq_along(pick), function(j) {
    sub <- copy(dd[get(cl_col) == pick[j]])
    set(sub, j = cl_col, value = paste0(pick[j], "#", j))
    sub
  }))
}

# 收敛过滤:少数重抽会得到发散解,它们不影响百分位 CI,却会把 sd 拉大若干倍,
# 使「自助 SE / 模型 SE」这一比值失去意义。统一剔除并如实报告个数。
# Degenerate optima leave percentile CIs intact but inflate sd; filter and report.
CONV_MAX <- 2
boot_res <- list()
for (cl in c("species", "province")) {
  msg("聚类自助(按 ", cl, "):", NBOOT, " 次")
  t0 <- Sys.time()
  m <- do.call(rbind, mclapply(seq_len(NBOOT), function(i) {
    set.seed(20000L + i); fit_coef(boot_cluster(d, cl))
  }, mc.cores = NCORE))
  boot_res[[cl]] <- m
  saveRDS(boot_res, file.path(D_DT, "boot_draws_partial.rds"))   # 分阶段落盘
  n_ok <- sum(complete.cases(m))
  n_conv <- sum(complete.cases(m) & apply(abs(m) < CONV_MAX, 1, all))
  msg(sprintf("  用时 %.1f 分钟,拟合成功 %d / %d,其中收敛 %d",
              as.numeric(difftime(Sys.time(), t0, units = "mins")), n_ok, NBOOT, n_conv))
}

ci <- rbindlist(lapply(names(boot_res), function(cl) {
  m <- boot_res[[cl]]
  n_all <- sum(complete.cases(m))
  keep <- complete.cases(m) & apply(abs(m) < CONV_MAX, 1, all)
  n_drop <- n_all - sum(keep)
  m <- m[keep, , drop = FALSE]
  rbindlist(lapply(TERMS, function(tt) {
    data.table(cluster = cl, term = tt, n_dropped = n_drop,
               observed_HR = exp(obs[[tt]]),
               model_lo = exp(obs[[tt]] - 1.96 * se0[[tt]]),
               model_hi = exp(obs[[tt]] + 1.96 * se0[[tt]]),
               boot_lo = exp(quantile(m[, tt], .025)),
               boot_hi = exp(quantile(m[, tt], .975)),
               boot_se = sd(m[, tt]), model_se = se0[[tt]],
               se_ratio = sd(m[, tt]) / se0[[tt]], n_boot = nrow(m))
  }))
}))
fwrite(ci, file.path(D_TB, "tbl_bootstrap_ci.csv"))
cat("\n================ 聚类自助 CI vs 模型 CI ================\n")
print(ci[, .(cluster, term, 观测 = round(observed_HR, 3),
             模型CI = sprintf("%.2f-%.2f", model_lo, model_hi),
             自助CI = sprintf("%.2f-%.2f", boot_lo, boot_hi),
             SE比 = round(se_ratio, 2), n = n_boot, 剔除 = n_dropped)])

# ------------------------------------------------------------
# 2. 参数自助:系数回收与区间覆盖
# ------------------------------------------------------------
msg("参数自助:", NPAR, " 次模拟")
t0 <- Sys.time()
sims <- simulate(fit0, nsim = NPAR)
par_out <- do.call(rbind, mclapply(seq_len(NPAR), function(i) {
  # glmmTMB 对二项模型的 simulate 每次返回「成功/失败」两列矩阵,取第一列
  dd <- copy(d); dd[, event := as.integer(sims[[i]][, 1])]
  f <- tryCatch(glmmTMB(FM, data = dd, family = binomial("cloglog"), control = CTL),
                error = function(e) NULL)
  if (is.null(f)) return(setNames(rep(NA_real_, 2 * length(TERMS)), NULL))
  cf <- fixef(f)$cond[TERMS]
  se <- summary(f)$coefficients$cond[TERMS, "Std. Error"]
  c(cf, se)
}, mc.cores = NCORE))
msg(sprintf("  用时 %.1f 分钟", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
par_out <- par_out[complete.cases(par_out), , drop = FALSE]
pb <- rbindlist(lapply(seq_along(TERMS), function(j) {
  est <- par_out[, j]; se <- par_out[, length(TERMS) + j]
  lo <- est - 1.96 * se; hi <- est + 1.96 * se
  data.table(term = TERMS[j], truth_HR = exp(obs[[j]]),
             mean_est_HR = exp(mean(est)),
             bias_logHR = mean(est) - obs[[j]],
             # 年度气候变异的 log HR 接近 0,相对偏倚会被接近零的分母放大成伪值,
             # 因此只在 |log HR| > 0.05 时报告相对偏倚 / relative bias is undefined near zero
             rel_bias_pct = fifelse(abs(obs[[j]]) > 0.05,
                                    100 * (mean(est) - obs[[j]]) / abs(obs[[j]]), NA_real_),
             coverage_95 = mean(lo <= obs[[j]] & obs[[j]] <= hi),
             n_sim = length(est))
}))
fwrite(pb, file.path(D_TB, "tbl_parametric_bootstrap.csv"))
cat("\n================ 参数自助:系数回收与覆盖 ================\n")
print(pb[, .(term, 真值 = round(truth_HR, 3), 均值估计 = round(mean_est_HR, 3),
             绝对偏倚 = sprintf("%+.4f", bias_logHR),
             相对偏倚 = fifelse(is.na(rel_bias_pct), "—", sprintf("%+.1f%%", rel_bias_pct)),
             `95%覆盖` = sprintf("%.1f%%", 100 * coverage_95), n = n_sim)])

# ------------------------------------------------------------
# 3. 影响力:留一省 / 留一物种组
# ------------------------------------------------------------
msg("影响力:逐省剔除 + 物种十等分剔除")
provs <- sort(unique(d$province))
sp <- unique(d$species); grp <- setNames(rep_len(1:10, length(sp)), sample(sp))
jobs <- c(lapply(provs, function(p) list(type = "省", lab = p, idx = which(d$province != p))),
          lapply(1:10, function(g) list(type = "物种十等分", lab = paste0("G", g),
                                        idx = which(grp[d$species] != g))))
inf <- do.call(rbind, mclapply(jobs, function(j) {
  cf <- fit_coef(d[j$idx])
  c(cf, NA)
}, mc.cores = NCORE))
influ <- data.table(type = sapply(jobs, `[[`, "type"), dropped = sapply(jobs, `[[`, "lab"))
for (j in seq_along(TERMS)) influ[[TERMS[j]]] <- exp(inf[, j])
for (j in seq_along(TERMS)) influ[[paste0("d_", TERMS[j])]] <-
  (exp(inf[, j]) - exp(obs[[j]])) / exp(obs[[j]])
fwrite(influ, file.path(D_TB, "tbl_influence_loo.csv"))
cat("\n================ 影响力:对每个系数偏移最大的 3 个 ================\n")
for (tt in TERMS) {
  z <- influ[order(-abs(get(paste0("d_", tt))))][1:3]
  cat("\n", tt, "(观测 HR", round(exp(obs[[tt]]), 3), ")\n")
  print(z[, .(type, dropped, HR = round(get(tt), 3),
              变化 = sprintf("%+.1f%%", 100 * get(paste0("d_", tt))))])
}

saveRDS(list(observed = obs, se = se0, cluster = boot_res, parametric = par_out,
             influence = influ), file.path(D_DT, "boot_draws.rds"))
msg("完成 / done")
