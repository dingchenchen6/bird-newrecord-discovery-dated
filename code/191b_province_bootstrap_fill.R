#!/usr/bin/env Rscript
# ============================================================
# Script 191b: 补跑省级聚类自助法中因进程崩溃丢失的重抽样
# Refit the province-cluster bootstrap resamples lost to a worker crash
# ============================================================
# Scientific question / 科学问题:
#   无(补跑步骤)。191 的省级聚类自助法中, 第 5 个并行进程在 TMB 求值时段错误崩溃,
#   mclapply 预分配给它的 50 次重抽样(i = 5, 11, …, 299)全部丢失, 只剩 250 次;正文写的是 300 次。
#   None (repair step): in script 191 one parallel worker segfaulted inside TMB, and mclapply's
#   prescheduling lost all 50 resamples assigned to it (i = 5, 11, ..., 299), leaving 250 of 300.
#
# Objective / 分析目标:
#   以与 191 完全相同的数据、模型与逐次种子(set.seed(20000 + i))补跑缺失序号, 使结果与无崩溃时一致;
#   改为逐任务派发(mc.preschedule = FALSE), 单次崩溃只影响该次。先复算 i = 1 验证可逐值复现。
#   Refit the missing indices with the same data, model and per-resample seed as 191, so the result
#   equals a crash-free run; dispatch one task at a time so a crash can only lose that task.
#   Index i = 1 is refitted first to verify exact reproduction.
#
# Input data / 输入数据: analysis_v2/data/model_v2_thr50.parquet, boot_draws.rds(191)
# Main workflow / 主要流程: 复现核对 → 补跑缺失序号 → 合并 → 按 191 算法重建 tbl_bootstrap_ci.csv
# Expected output / 预期输出: boot_draws.rds(省级 300 行)、tbl_bootstrap_ci.csv
# Key assumptions / 关键假设: 缺失序号 = 预分配给第 5 个进程的 i ≡ 5 (mod 6);各次种子独立于调度
# Main packages / 主要包: data.table, arrow, glmmTMB, parallel
# Output directory / 输出路径: analysis_v2/data/, analysis_v2/tables/
# Run / 运行: Rscript --no-init-file code/191b_province_bootstrap_fill.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(glmmTMB); library(parallel)
})

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_DT <- file.path(V2, "analysis_v2/data")
D_TB <- file.path(V2, "analysis_v2/tables")
NBOOT <- 300L; NCORE <- 6L; CONV_MAX <- 2
msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

# ---- 与 191 逐行一致的数据与函数 / data and functions verbatim from 191 ----
d <- as.data.table(read_parquet(file.path(D_DT, "model_v2_thr50.parquet")))[usable_main == TRUE]
zs <- function(x) as.numeric(scale(x))
d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var), effort_z = eff_visits_gap_z)]
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
boot_cluster <- function(dd, cl_col) {
  cls <- unique(dd[[cl_col]])
  pick <- sample(cls, length(cls), replace = TRUE)
  rbindlist(lapply(seq_along(pick), function(j) {
    sub <- copy(dd[get(cl_col) == pick[j]])
    set(sub, j = cl_col, value = paste0(pick[j], "#", j))
    sub
  }))
}
one <- function(i) { set.seed(20000L + i); fit_coef(boot_cluster(d, "province")) }

res <- readRDS(file.path(D_DT, "boot_draws.rds"))
m <- res$cluster$province
stopifnot(nrow(m) == 250L)

# ---- 1. 复现核对: i = 1 必须与第一行逐值相同 / exact reproduction check on i = 1 ----
msg("复现核对 i = 1 / reproduction check")
chk <- one(1L)
dev <- max(abs(chk - m[1, ]))
msg(sprintf("  与原第 1 行最大偏差 / max deviation from row 1: %.2e", dev))
if (!is.finite(dev) || dev > 1e-6) stop("无法复现原重抽样, 停止 / cannot reproduce the original resample")

# ---- 2. 补跑缺失序号 / refit the missing indices ----
miss <- seq(5L, NBOOT, by = NCORE)             # 预分配给第 5 个进程的序号 / indices of worker 5
msg("补跑 / refitting ", length(miss), " 次:i = ", paste(head(miss, 4), collapse = ", "), ", …, ", tail(miss, 1))
t0 <- Sys.time()
new <- mclapply(miss, one, mc.cores = NCORE, mc.preschedule = FALSE)
ok <- vapply(new, function(x) is.numeric(x) && length(x) == length(TERMS), logical(1))
msg(sprintf("  用时 %.1f 分钟, 返回 %d / %d", as.numeric(difftime(Sys.time(), t0, units = "mins")), sum(ok), length(miss)))
new_m <- do.call(rbind, new[ok])
m_all <- rbind(m, new_m)
res$cluster$province <- m_all
saveRDS(res, file.path(D_DT, "boot_draws.rds"))

# ---- 3. 按 191 的算法重建汇总表 / rebuild the summary exactly as in 191 ----
obs <- res$observed; se0 <- res$se
ci <- rbindlist(lapply(names(res$cluster), function(cl) {
  mm <- res$cluster[[cl]]
  n_all <- sum(complete.cases(mm))
  keep <- complete.cases(mm) & apply(abs(mm) < CONV_MAX, 1, all)
  n_drop <- n_all - sum(keep)
  mm <- mm[keep, , drop = FALSE]
  rbindlist(lapply(TERMS, function(tt) {
    data.table(cluster = cl, term = tt, n_dropped = n_drop,
               observed_HR = exp(obs[[tt]]),
               model_lo = exp(obs[[tt]] - 1.96 * se0[[tt]]),
               model_hi = exp(obs[[tt]] + 1.96 * se0[[tt]]),
               boot_lo = exp(quantile(mm[, tt], .025)),
               boot_hi = exp(quantile(mm[, tt], .975)),
               boot_se = sd(mm[, tt]), model_se = se0[[tt]],
               se_ratio = sd(mm[, tt]) / se0[[tt]], n_boot = nrow(mm))
  }))
}))
fwrite(ci, file.path(D_TB, "tbl_bootstrap_ci.csv"))
print(ci[, .(cluster, term, HR = round(observed_HR, 3), boot = sprintf("%.2f-%.2f", boot_lo, boot_hi),
             SE比 = round(se_ratio, 2), n = n_boot, 剔除 = n_dropped)])
msg("完成 / done")
