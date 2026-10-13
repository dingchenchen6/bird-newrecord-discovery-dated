#!/usr/bin/env Rscript
# ============================================================
# Script 146: 迁徙策略对气候与努力效应的调节
# Migratory strategy as a moderator of the warming and effort effects
# ============================================================
# 科学问题 / Scientific question:
#   迁徙策略是否改变【气候变暖】与【调查努力】关联于新记录生成风险的方式?
#   若改变, 说明"新记录"这一事件在不同迁徙类型中对应着不同的生成过程,
#   而不是同一过程的强弱之分。
#
# 生态学假设 / Ecological hypotheses:
#   H1 留鸟 (Resident)
#      扩散能力受限, 一次新的省级记录更可能反映真实的分布区推移。
#      => 预期气候效应最强。
#   H2 长距离候鸟 (Long-distance)
#      高机动性; 新记录可能来自迷鸟、越冬地偏移或风暴驱替, 这些过程由导航
#      误差与天气事件驱动, 与目标省相对该物种分布区的【累积】变暖关系较弱。
#      同时它们仅在过境期可见, 观测窗口窄。
#      => 预期气候效应最弱, 努力效应相对更重要。
#   H3 部分迁徙 (Partial)
#      兼具分布区边缘的机动性与全年可观测性。
#      => 预期居于两者之间。
#
# Unknown 组必须排除 / Why the Unknown group is excluded:
#   该组事件率 0.791%, 是其余各组(0.29-0.42%)的 2.4 倍, 且每物种的风险集行数
#   仅为留鸟的三分之一。原因是这些物种缺少迁徙属性、之所以进入候选池正是因为
#   它们有记录事件(强制纳入规则)。这是选择性偏倚, 不是一个可比的生态类别,
#   因此调节分析只用三个已知组(549 个事件)。
#
# 两套分组 / Two groupings:
#   三分类 Resident / Partial / Long-distance     主分析(各组事件 >= 156, 足够)
#   二分类 Resident / Migratory                   较粗的敏感性对照
#
# 分析设计 / Design:
#   A 交互阶梯: 在主模型上逐步加入 迁徙主效应、气候×迁徙、努力×迁徙
#   B 分层拟合: 各组单独拟合完整主模型, 给出组内四个系数(最透明的读法)
#
# Input / 输入:  analysis_v2/data/{model_v2_thr50.parquet, components_v2_*, }
# Output / 输出: analysis_v2/tables/tbl_v2_migratory_ladder.csv
#                analysis_v2/tables/tbl_v2_migratory_stratified.csv
#
# Main packages / 主要包: glmmTMB, data.table, arrow
# 运行 / Run: Rscript --no-init-file code/146_migratory_strategy.R
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
msg <- function(...) cat(sprintf("[146 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

EFFORT <- "eff_visits_gap_z"; IND <- "tavg_annual"; W <- 15L
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a
RE_MAIN <- "(1|species) + (1|province) + (1|prov_year)"
zs <- function(v) as.numeric(scale(v))

d <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
d[, c("x", "clim_change", "clim_var") := NULL]
cc <- as.data.table(read_parquet(file.path(OUT, "data", sprintf("components_v2_%s_W%d.parquet", IND, W))))
d <- merge(d, cc[, .(species, province, year, clim_change, clim_var)], by = c("species", "province", "year"))
d <- d[is.finite(clim_change) & is.finite(clim_var) & is.finite(get(EFFORT))]

# 只保留有迁徙属性的三组 / keep the three groups with known strategy
d[, mig := factor(as.character(mig_grp), levels = c("Resident", "Partial", "Long-distance"))]
d <- d[!is.na(mig)]
d[, mig2 := factor(fifelse(mig == "Resident", "Resident", "Migratory"),
                   levels = c("Resident", "Migratory"))]
# 标准化在【分析子集上】重做, 使系数是该子集内的每 1 SD
d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var),
         effort_z = zs(get(EFFORT)), prov_year = interaction(province, year, drop = TRUE))]
msg("调节分析样本: ", format(nrow(d), big.mark = ","), " 行 | ", sum(d$event), " 事件 | ",
    uniqueN(d$species), " 种")
print(d[, .(rows = .N, events = sum(event), species = uniqueN(species)), by = mig][order(-events)])

fit <- function(fx, dat = d, re = RE_MAIN) {
  f <- as.formula(paste("event ~", fx, "+ offset(log_completeness) +", re))
  tryCatch(glmmTMB(f, data = dat, family = binomial("cloglog")),
           error = function(e) { msg("  FAILED: ", conditionMessage(e)); NULL })
}
row_of <- function(m, lab, dat, note = "") {
  if (is.null(m)) return(data.table(model = lab, converged = FALSE))
  cf <- summary(m)$coefficients$cond
  data.table(model = lab, converged = TRUE, note = note,
             n = nrow(dat), events = sum(dat$event), df = attr(logLik(m), "df"), AIC = AIC(m))
}

# ================= A 交互阶梯 =================
LADDER <- c(
  "M0 main model (no migratory term)"      = "clim_change_z * effort_z + clim_var_z",
  "M1 + migratory main effect"             = "clim_change_z * effort_z + clim_var_z + mig",
  "M2 + warming x migratory"               = "clim_change_z * effort_z + clim_var_z + mig + clim_change_z:mig",
  "M3 + effort x migratory"                = "clim_change_z * effort_z + clim_var_z + mig + effort_z:mig",
  "M4 + both interactions"                 = "clim_change_z * effort_z + clim_var_z + mig + clim_change_z:mig + effort_z:mig",
  "M5 + three-way warming x effort x mig"   = "clim_change_z * effort_z * mig + clim_var_z")
SKIP_LADDER <- nzchar(Sys.getenv("SKIP_LADDER"))
lad <- list(); fits <- list()
for (nm in if (SKIP_LADDER) character(0) else names(LADDER)) {
  t0 <- Sys.time(); m <- fit(LADDER[[nm]]); fits[[nm]] <- m
  lad[[nm]] <- row_of(m, nm, d, LADDER[[nm]])
  msg(sprintf("  %-38s AIC=%8.1f df=%d [%.0fs]", nm,
      if (is.null(m)) NA_real_ else AIC(m), if (is.null(m)) NA_integer_ else attr(logLik(m), "df"),
      as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  invisible(gc())
}
if (!SKIP_LADDER) {
lt <- rbindlist(lad, fill = TRUE)
lt[, dAIC := round(AIC - min(AIC, na.rm = TRUE), 2)]
# 似然比检验: 每一步相对 M1 / LR tests against the migratory-main-effect model
lrt <- function(a, b) {
  if (is.null(fits[[a]]) || is.null(fits[[b]])) return(c(NA, NA))
  an <- anova(fits[[a]], fits[[b]])
  c(an$Chisq[2], an$`Pr(>Chisq)`[2])
}
lt[, `:=`(LR_chisq = NA_real_, LR_P = NA_real_)]
for (k in c("M2 + warming x migratory", "M3 + effort x migratory", "M4 + both interactions",
            "M5 + three-way warming x effort x mig")) {
  v <- lrt("M1 + migratory main effect", k)
  lt[model == k, `:=`(LR_chisq = v[1], LR_P = v[2])]
}
# 由 M5 导出各组的 气候x努力 交互, 便于与分层拟合互相印证
m5 <- fits[["M5 + three-way warming x effort x mig"]]
if (!is.null(m5)) {
  b <- fixef(m5)$cond; V <- vcov(m5)$cond; base <- "clim_change_z:effort_z"
  gi <- rbindlist(lapply(levels(d$mig), function(g) {
    idx <- if (g == "Resident") base else c(base, paste0(base, ":mig", g))
    est <- sum(b[idx]); se <- sqrt(sum(V[idx, idx]))
    data.table(group = g, HR_int = exp(est), lo = exp(est - 1.96 * se), hi = exp(est + 1.96 * se),
               P = 2 * pnorm(-abs(est / se)))
  }))
  fwrite(gi, file.path(OUT, "tables", "tbl_v2_migratory_interaction_by_group.csv"))
  print(gi)
  saveRDS(m5, file.path(OUT, "data", "fit_mig_3way.rds"))
}
fwrite(lt, file.path(OUT, "tables", "tbl_v2_migratory_ladder.csv"))
print(lt[, .(model, df, AIC, dAIC, LR_chisq = round(LR_chisq, 2), LR_P = signif(LR_P, 3))])
}

# ================= B 分层拟合 =================
# 组内事件数只有 156-331, 而省×年有 689 层。用主模型的三层随机结构分层拟合时
# 方差分量会塌缩到 0 且 Hessian 非正定(实测 Resident 与 Long-distance 均如此),
# 这样的系数不可报告。因此分层拟合自动降阶: 先试三层, 若不收敛或任一分量塌缩
# 则退回 (1|species)+(1|province), 并在结果表中记录实际使用的结构。
# NB: within-group event counts cannot identify 689 province-year levels; the fit
#     falls back to a two-level structure and records which one was used.
FX <- "clim_change_z * effort_z + clim_var_z"
RE_FULL <- RE_MAIN
RE_RED  <- "(1|species) + (1|province)"
ok_fit <- function(m) {
  if (is.null(m)) return(FALSE)
  if (!is.finite(AIC(m))) return(FALSE)
  vc <- glmmTMB::VarCorr(m)$cond
  min(vapply(vc, function(v) sqrt(v[1, 1]), numeric(1))) > 0.01
}
fit_strat <- function(dat) {
  m <- fit(FX, dat, RE_FULL)
  if (ok_fit(m)) return(list(m = m, re = "species + province + province:year"))
  m2 <- fit(FX, dat, RE_RED)
  list(m = m2, re = "species + province (reduced: full structure not identifiable)")
}

strat <- list()
grab <- function(m, lab, dat, grouping, re_used = NA_character_) {
  if (is.null(m)) return(data.table(grouping = grouping, group = lab, converged = FALSE))
  cf <- summary(m)$coefficients$cond
  it <- grep(":", rownames(cf), value = TRUE)[1]
  g <- function(t, k) if (t %in% rownames(cf)) cf[t, k] else NA_real_
  vc <- glmmTMB::VarCorr(m)$cond
  data.table(grouping = grouping, group = lab, converged = TRUE, re_structure = re_used,
    n = nrow(dat), events = sum(dat$event), species = uniqueN(dat$species), AIC = AIC(m),
    HR_change = exp(g("clim_change_z", 1)),
    lo_change = exp(g("clim_change_z", 1) - 1.96 * g("clim_change_z", 2)),
    hi_change = exp(g("clim_change_z", 1) + 1.96 * g("clim_change_z", 2)), P_change = g("clim_change_z", 4),
    HR_effort = exp(g("effort_z", 1)),
    lo_effort = exp(g("effort_z", 1) - 1.96 * g("effort_z", 2)),
    hi_effort = exp(g("effort_z", 1) + 1.96 * g("effort_z", 2)), P_effort = g("effort_z", 4),
    HR_var = exp(g("clim_var_z", 1)), P_var = g("clim_var_z", 4),
    HR_int = exp(g(it, 1)),
    lo_int = exp(g(it, 1) - 1.96 * g(it, 2)),
    hi_int = exp(g(it, 1) + 1.96 * g(it, 2)), P_int = g(it, 4),
    min_re_sd = min(vapply(vc, function(v) sqrt(v[1, 1]), numeric(1))))
}
for (g in levels(d$mig)) {
  sd_ <- d[mig == g]
  # 组内重新标准化, 使 HR 为"该组内每 1 SD" / restandardise within group
  sd_[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var), effort_z = zs(get(EFFORT)))]
  t0 <- Sys.time(); r <- fit_strat(sd_); m <- r$m
  strat[[paste0("3_", g)]] <- grab(m, g, sd_, "three-level", r$re)
  msg(sprintf("  [3-level] %-15s n=%s ev=%3d  HR_ch=%.3f(%.0e)  HR_eff=%.3f(%.0e)  HR_int=%.3f [%.0fs]",
      g, format(nrow(sd_), big.mark = ","), sum(sd_$event),
      strat[[paste0("3_", g)]]$HR_change %||% NA, strat[[paste0("3_", g)]]$P_change %||% NA,
      strat[[paste0("3_", g)]]$HR_effort %||% NA, strat[[paste0("3_", g)]]$P_effort %||% NA,
      strat[[paste0("3_", g)]]$HR_int %||% NA, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  rm(m, r, sd_); invisible(gc())
}
for (g in levels(d$mig2)) {
  sd_ <- d[mig2 == g]
  sd_[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var), effort_z = zs(get(EFFORT)))]
  t0 <- Sys.time(); r <- fit_strat(sd_); m <- r$m
  strat[[paste0("2_", g)]] <- grab(m, g, sd_, "two-level", r$re)
  msg(sprintf("  [2-level] %-15s n=%s ev=%3d  HR_ch=%.3f(%.0e)  HR_eff=%.3f(%.0e)  HR_int=%.3f [%.0fs]",
      g, format(nrow(sd_), big.mark = ","), sum(sd_$event),
      strat[[paste0("2_", g)]]$HR_change %||% NA, strat[[paste0("2_", g)]]$P_change %||% NA,
      strat[[paste0("2_", g)]]$HR_effort %||% NA, strat[[paste0("2_", g)]]$P_effort %||% NA,
      strat[[paste0("2_", g)]]$HR_int %||% NA, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  rm(m, r, sd_); invisible(gc())
}
st <- rbindlist(strat, fill = TRUE)
fwrite(st, file.path(OUT, "tables", "tbl_v2_migratory_stratified.csv"))
print(st[, .(grouping, group, events, HR_change = round(HR_change, 3), P_change = signif(P_change, 2),
             HR_effort = round(HR_effort, 3), P_effort = signif(P_effort, 2),
             HR_int = round(HR_int, 3), P_int = signif(P_int, 2))])
msg("wrote tbl_v2_migratory_{ladder,stratified}.csv | DONE")
