# ============================================================
# Scientific question / 科学问题:
# 主模型的头条系数,会不会只是风险集构造、随机效应结构或稀有事件设计的产物?
# 用「设计保持」的置换零模型回答:每个零模型只破坏一条特定关联,
# 其余全部结构原封不动,再看观测系数是否落在零分布之外。
# Are the headline coefficients artefacts of the risk-set construction, the
# random-effect structure, or the rare-event design? Each permutation null
# destroys exactly one association and preserves everything else.
#
# Objective / 分析目标:
#   N1 气候零模型:省 × 年层内把累积变暖在物种间重排
#      → 检验「物种特异的气候参照」是否携带信息,而不只是省-年气候
#   N2 努力零模型:省内把调查努力在年份间重排
#      → 检验努力与事件的时间对齐是否真实
#   N3 事件零模型:省 × 年层内把事件指示在当年在险物种间重排
#      → 最强的约束零模型,把观测过程的边际完全固定,只问「是哪个物种」可否预测
#
# Input data / 输入数据:
#   analysis_v2/data/model_v2_thr50.parquet   175,901 行,649 事件
#
# Expected output / 预期输出:
#   analysis_v2/data/null_perm_draws.rds          逐次置换的系数
#   analysis_v2/tables/tbl_null_models.csv        观测值 vs 零分布
#
# Key assumptions / 关键假设:
#   - 置换在层内进行,因此风险集大小、每省每年的事件数、努力与报告完整度的
#     边际分布、以及随机效应的层级结构在零模型下与观测数据完全一致。
#   - N3 的重排只在「当年仍在风险集内」的行之间进行;因为吸收退出已经在
#     建模矩阵里实现,该省该年的全部行按定义都是在险行。
#   - 每个零模型 199 次置换,给出双侧经验 P 值的分辨率 0.005。
#   - 主指标是基于分位数的经验 P;z 统计量仅作参考,因为少数发散拟合会把
#     零分布的均值与标准差拉坏。发散拟合按 |log HR| < 2 过滤并报告剔除个数。
#   - 拟合用 profile=TRUE(单次 39 秒 vs 61 秒,系数差 8e-4),
#     并行 6 进程。
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
NPERM <- 199L
NCORE <- 6L
msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

d <- as.data.table(read_parquet(file.path(D_DT, "model_v2_thr50.parquet")))[usable_main == TRUE]
zs <- function(x) as.numeric(scale(x))
d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var),
         effort_z = eff_visits_gap_z, py = paste(province, year, sep = "_"))]
msg("数据 ", nrow(d), " 行,", sum(d$event), " 事件")

FM <- event ~ clim_change_z * effort_z + clim_var_z + offset(log_completeness) +
  (1 | species) + (1 | province) + (1 | province:year)
CTL <- glmmTMBControl(profile = TRUE)
TERMS <- c("clim_change_z", "effort_z", "clim_var_z", "clim_change_z:effort_z")

fit_coef <- function(dd) {
  f <- tryCatch(glmmTMB(FM, data = dd, family = binomial("cloglog"), control = CTL),
                error = function(e) NULL)
  if (is.null(f)) return(setNames(rep(NA_real_, length(TERMS)), TERMS))
  cf <- fixef(f)$cond
  setNames(cf[TERMS], TERMS)
}

msg("拟合观测模型 / observed fit")
obs <- fit_coef(d)
print(round(exp(obs), 4))

# ------------------------------------------------------------
# 三个设计保持的置换零模型
# ------------------------------------------------------------
#' N1:省 × 年层内,把累积变暖在物种间重排
perm_N1 <- function(dd) { dd <- copy(dd); dd[, clim_change_z := sample(clim_change_z), by = py]; dd }
#' N2:省内,把调查努力在年份间重排(整年一起搬,保持省-年结构)
perm_N2 <- function(dd) {
  dd <- copy(dd)
  key <- unique(dd[, .(province, year, effort_z)])
  key[, effort_new := sample(effort_z), by = province]
  dd[, effort_z := NULL]
  merge(dd, key[, .(province, year, effort_z = effort_new)], by = c("province", "year"))
}
#' N3:省 × 年层内,把事件指示在在险物种间重排
perm_N3 <- function(dd) { dd <- copy(dd); dd[, event := sample(event), by = py]; dd }

NULLS <- list(
  N1_气候的物种特异性 = perm_N1,
  N2_努力与事件的时间对齐 = perm_N2,
  N3_事件落在哪个物种 = perm_N3
)

draws <- list()
for (nm in names(NULLS)) {
  msg("零模型 ", nm, ":", NPERM, " 次置换,", NCORE, " 进程")
  t0 <- Sys.time()
  fn <- NULLS[[nm]]
  out <- mclapply(seq_len(NPERM), function(i) {
    set.seed(1000L + i)
    fit_coef(fn(d))
  }, mc.cores = NCORE)
  m <- do.call(rbind, out)
  draws[[nm]] <- m
  msg(sprintf("  完成,用时 %.1f 分钟,有效置换 %d / %d",
              as.numeric(difftime(Sys.time(), t0, units = "mins")),
              sum(complete.cases(m)), NPERM))
}
saveRDS(list(observed = obs, draws = draws), file.path(D_DT, "null_perm_draws.rds"))

# ------------------------------------------------------------
# 汇总:观测值 vs 零分布
# ------------------------------------------------------------
# 收敛过滤:少数置换会得到发散解(如 HR = 0 或 > 4),它们会把均值与标准差拉坏,
# 使 z 统计量失去意义,而基于分位数的经验 P 仍然有效。统一剔除并如实报告个数。
# A few permutations return degenerate optima; drop them and report how many.
CONV_MAX <- 2      # |log HR| 上限,对应 HR 落在 [0.14, 7.4] 之外即判为未收敛
res <- rbindlist(lapply(names(draws), function(nm) {
  m <- draws[[nm]]
  n_all <- sum(complete.cases(m))
  keep <- complete.cases(m) & apply(abs(m) < CONV_MAX, 1, all)
  n_drop <- n_all - sum(keep)
  if (n_drop > 0) msg(sprintf("  %s:剔除 %d / %d 次发散拟合", nm, n_drop, n_all))
  m <- m[keep, , drop = FALSE]
  rbindlist(lapply(TERMS, function(tt) {
    nd <- m[, tt]
    # 双侧经验 P:零分布中偏离其中心不小于观测偏离的比例
    ctr <- median(nd)
    p <- (sum(abs(nd - ctr) >= abs(obs[[tt]] - ctr)) + 1) / (length(nd) + 1)
    data.table(null_model = nm, term = tt,
               observed_HR = exp(obs[[tt]]),
               null_median_HR = exp(ctr),
               null_lo_HR = exp(quantile(nd, .025)),
               null_hi_HR = exp(quantile(nd, .975)),
               z_vs_null = (obs[[tt]] - mean(nd)) / sd(nd),
               P_perm = p, n_perm = length(nd), n_dropped = n_drop)
  }))
}))
fwrite(res, file.path(D_TB, "tbl_null_models.csv"))
cat("\n================ 设计保持的置换零模型 ================\n")
print(res[, .(null_model, term, 观测 = round(observed_HR, 3),
              零分布中位 = round(null_median_HR, 3),
              零分布95 = sprintf("%.3f-%.3f", null_lo_HR, null_hi_HR),
              z = round(z_vs_null, 1), P = signif(P_perm, 3))])
msg("完成 / done")
