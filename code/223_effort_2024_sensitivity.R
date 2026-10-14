#!/usr/bin/env Rscript
# ============================================================
# Scientific question / 科学问题:
#   2024 年努力数据缺 eBird 部分(脚本 222 查明), 冻结主模型的结论是否因此改变?
#   Does the missing 2024 eBird component (traced in script 222) change the frozen main model?
#
# Objective / 分析目标:
#   在主模型结构(cloglog;增温 × 努力 + 年际变率 + 报告完整度 offset;物种、省、省 × 年随机截距)
#   下比较六种努力口径, 并重拟合时变努力模型, 给出 2002 与 2024 年的努力回报。
#   Compare six effort specifications under the main model structure and refit the time-varying
#   model to obtain the return on effort in 2002 and 2024.
#
# Variants / 口径(2026-10-13 起主分析已改用修正数据 / the main analysis now uses the corrected data):
#   V0 修正前(未修正面板, 复现原冻结主模型)          before correction (uncorrected panel; the former frozen model)
#   V1 主模型(补入 eBird 2024, 广东 2024 为下载缺口)  main model (eBird 2024 added; Guangdong 2024 a download gap)
#   V2 V1 + 上海 2024 为缺口                        V1 with Shanghai 2024 also a gap
#   V3 修正前数据, 云南与广东 2024 为缺口             uncorrected data, Yunnan and Guangdong 2024 as gaps
#   V4 记录数口径                                   records-count proxy
#   V5 剔除 2024 年                                 without 2024
#
# Input data / 输入数据:
#   analysis_v2/data/model_v2_thr50.parquet, components_v2_tavg_annual_W15.parquet
#   analysis_v2/data/effort_panel_v2_uncorrected.csv(脚本 131 的未修正面板 / uncorrected panel from script 131)
#
# Main workflow / 主要流程:
#   1. 组装建模数据(同 133/138 的 prep), 按口径替换努力列并删去缺口行
#   2. 逐口径拟合主模型, 提取四个固定效应的 HR、Wald 95% CI、P 与 AIC
#   3. V0、V1、V4 拟合时变模型(增温 × 时间、努力 × 时间), 逐年计算努力 HR 及 CI
#   4. 写出表与图(固定效应森林图、努力回报时间曲线、2024 年分省访问量原值与修正值)
#   1. model data as in 133/138; 2. fit each variant; 3. time-varying models for V0, V1, V4;
#   4. tables and figures
#
# Expected output / 预期输出:
#   analysis_v2/tables/tbl_effort_2024_sensitivity.csv, tbl_effort_2024_timevarying.csv
#   analysis_v2/effort2024_audit/figures/Fig_effort2024_{coefficients,timevarying,provinces}.{pdf,png}
#
# Key assumptions / 关键假设:
#   各口径的努力列在其建模行上重新标准化(同 133 的 prep), HR 均为"每个标准差";
#   不同口径的行数不同时 AIC 不可比, 只比较效应量。V0 须复现修正前的冻结主模型(1.404/1.362/0.849),
#   V1 须与新主模型 fit_R3.rds 一致。
#   Effort is restandardised on each variant's rows, so HRs are per SD; AIC is comparable only for
#   identical rows. V0 must reproduce the former frozen model (1.404, 1.362, 0.849) and V1 the new fit_R3.
#
# Main packages / 主要包: glmmTMB, data.table, arrow, ggplot2, patchwork
# Output directory / 输出路径: analysis_v2/tables/, analysis_v2/effort2024_audit/
# Run / 运行: Rscript --no-init-file code/223_effort_2024_sensitivity.R   (cwd = task root)
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(glmmTMB); library(ggplot2); library(patchwork)
})
options(warn = 1)
source("code/218_theme_topjournal.R")      # TJ 调色板与主题 / palette and theme

V2  <- normalizePath(".", mustWork = TRUE)
OUT <- file.path(V2, "analysis_v2")
AUD <- file.path(OUT, "effort2024_audit")
dir.create(file.path(AUD, "figures"), recursive = TRUE, showWarnings = FALSE)
msg <- function(...) cat(sprintf("[223 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")
zs <- function(x) as.numeric(scale(x))

# =====================================================================
# 1. 建模数据 / model data (same as the prep() of scripts 133 and 138)
# =====================================================================
d0 <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
d0[, c("x", "clim_change", "clim_var") := NULL]
cc <- as.data.table(read_parquet(file.path(OUT, "data", "components_v2_tavg_annual_W15.parquet")))
d0 <- merge(d0, cc[, .(species, province, year, clim_change, clim_var)], by = c("species", "province", "year"))
un <- fread(file.path(OUT, "data", "effort_panel_v2_uncorrected.csv"))
d0 <- merge(d0, un[, .(province, year, eff_visits_unc_z = eff_visits_gap_z)], by = c("province", "year"), all.x = TRUE)

VARIANTS <- list(
  V0 = list(label = "Before correction (uncorrected 2024)", eff = "eff_visits_unc_z", drop = NULL),
  V1 = list(label = "Main model (eBird 2024 added)", eff = "eff_visits_gap_z", drop = NULL),
  V2 = list(label = "Main, Shanghai 2024 a gap", eff = "eff_visits_gap_z",
            drop = quote(province == "Shanghai" & year == 2024)),
  V3 = list(label = "Uncorrected; Yunnan, Guangdong 2024 gaps", eff = "eff_visits_unc_z",
            drop = quote(province %in% c("Yunnan", "Guangdong") & year == 2024)),
  V4 = list(label = "Records-count proxy", eff = "eff_record_gap_z", drop = NULL),
  V5 = list(label = "Without 2024", eff = "eff_visits_gap_z", drop = quote(year == 2024)))

prep <- function(v) {
  d <- copy(d0)
  if (!is.null(v$drop)) d <- d[!eval(v$drop)]
  d <- d[is.finite(clim_change) & is.finite(clim_var) & is.finite(get(v$eff))]
  d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var), effort_z = zs(get(v$eff)),
           prov_year = interaction(province, year, drop = TRUE), year_c = zs(year))]
  d[]
}

FORM <- event ~ clim_change_z * effort_z + clim_var_z + offset(log_completeness) +
  (1 | species) + (1 | province) + (1 | prov_year)
FORM_TV <- event ~ clim_change_z * effort_z + clim_var_z + clim_change_z:year_c + effort_z:year_c +
  offset(log_completeness) + (1 | species) + (1 | province) + (1 | prov_year)
TERMS <- c(effort = "effort_z", warming = "clim_change_z", variability = "clim_var_z",
           interaction = "clim_change_z:effort_z")

FIG_ONLY <- nzchar(Sys.getenv("FIG_ONLY"))   # 只重画图: 读已存结果表, 不重新拟合 / redraw figures from saved tables
# =====================================================================
# 2. 主模型各口径 / main model under each variant
# =====================================================================
rows <- list(); fits_tv <- list(); data_tv <- list()
for (k in if (FIG_ONLY) character(0) else names(VARIANTS)) {
  v <- VARIANTS[[k]]; d <- prep(v); t0 <- Sys.time()
  m <- glmmTMB(FORM, data = d, family = binomial("cloglog"))
  cf <- summary(m)$coefficients$cond
  for (tn in names(TERMS)) {
    b <- cf[TERMS[[tn]], 1]; se <- cf[TERMS[[tn]], 2]
    rows[[length(rows) + 1]] <- data.table(variant = k, label = v$label, term = tn, n = nrow(d),
      events = sum(d$event), HR = exp(b), lo = exp(b - 1.96 * se), hi = exp(b + 1.96 * se),
      P = cf[TERMS[[tn]], 4], AIC = AIC(m))
  }
  msg(sprintf("%s  n=%s events=%d  effort %.3f  warming %.3f  int %.3f  var %.3f  [%.0fs]", k,
      format(nrow(d), big.mark = ","), sum(d$event), exp(cf["effort_z", 1]), exp(cf["clim_change_z", 1]),
      exp(cf["clim_change_z:effort_z", 1]), exp(cf["clim_var_z", 1]), as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  if (k %in% c("V0", "V1", "V4")) data_tv[[k]] <- d
}
res <- if (FIG_ONLY) fread(file.path(OUT, "tables", "tbl_effort_2024_sensitivity.csv"))[, d_HR_vs_V0 := NULL] else rbindlist(rows)
v0 <- res[variant == "V0"]
pub <- c(effort = 1.404, warming = 1.362, interaction = 0.849, variability = 0.995)
dev <- max(abs(round(v0$HR[match(names(pub), v0$term)], 3) - pub))
msg("V0 复现修正前主模型 / reproduces the former frozen model: 最大偏差 ", dev)
if (dev > 0.001) stop("V0 未能复现修正前主模型 / V0 does not reproduce the former frozen model")
fr3 <- exp(glmmTMB::fixef(readRDS(file.path(OUT, "data", "fit_R3.rds")))$cond)
v1 <- res[variant == "V1"]
dev1 <- max(abs(v1$HR[match(names(TERMS), v1$term)] - fr3[TERMS]))
msg("V1 与新主模型 fit_R3 的最大偏差 / V1 vs the new fit_R3: ", signif(dev1, 3))
if (dev1 > 1e-6) stop("V1 与新主模型不一致 / V1 differs from the new main model")
res[, d_HR_vs_V0 := HR - v0$HR[match(term, v0$term)]]
fwrite(res, file.path(OUT, "tables", "tbl_effort_2024_sensitivity.csv"))

# =====================================================================
# 3. 时变模型 / time-varying models (V0, V1, V4)
# =====================================================================
tv <- list(); tvp <- list()
for (k in if (FIG_ONLY) character(0) else names(data_tv)) {
  d <- data_tv[[k]]; t0 <- Sys.time()
  m <- glmmTMB(FORM_TV, data = d, family = binomial("cloglog"))
  cf <- fixef(m)$cond; V <- vcov(m)$cond
  nm <- c("effort_z", "effort_z:year_c")
  yrs <- 2002:2024; yc <- (yrs - mean(d$year)) / sd(d$year)
  b_t <- cf[[nm[1]]] + cf[[nm[2]]] * yc
  se_t <- sqrt(V[nm[1], nm[1]] + yc^2 * V[nm[2], nm[2]] + 2 * yc * V[nm[1], nm[2]])
  tv[[k]] <- data.table(variant = k, label = VARIANTS[[k]]$label, year = yrs, HR = exp(b_t),
                        lo = exp(b_t - 1.96 * se_t), hi = exp(b_t + 1.96 * se_t))
  sc <- summary(m)$coefficients$cond
  tvp[[k]] <- data.table(variant = k, P_effort_time = sc["effort_z:year_c", 4], P_warming_time = sc["clim_change_z:year_c", 4],
                         HR_warming_tv = exp(sc["clim_change_z", 1]))
  msg(sprintf("%s 时变 / time-varying: effort HR 2002 %.2f → 2024 %.2f (%.2f–%.2f); P(effort×time) %.2g; P(warming×time) %.2f [%.0fs]",
      k, exp(b_t[1]), exp(b_t[23]), exp(b_t[23] - 1.96 * se_t[23]), exp(b_t[23] + 1.96 * se_t[23]),
      sc["effort_z:year_c", 4], sc["clim_change_z:year_c", 4], as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}
if (FIG_ONLY) {
  tvd <- fread(file.path(OUT, "tables", "tbl_effort_2024_timevarying.csv"))
} else {
  tvd <- merge(rbindlist(tv), rbindlist(tvp), by = "variant")
  fwrite(tvd, file.path(OUT, "tables", "tbl_effort_2024_timevarying.csv"))
}
TV_KEYS <- unique(tvd$variant)

# =====================================================================
# 4. 图 / figures
# =====================================================================
COLV <- c(V0 = TJ$ink, V1 = TJ$effort, V2 = tint(TJ$effort, 0.45), V3 = TJ$neutral, V4 = TJ$obs, V5 = TJ$warming)
res[, term_lab := factor(term, levels = c("warming", "effort", "interaction", "variability"),
                         labels = c("Accumulated warming", "Survey effort", "Warming x effort", "Annual variability"))]
res[, variant := factor(variant, levels = rev(names(VARIANTS)))]
p1 <- ggplot(res, aes(HR, variant, colour = variant)) +
  geom_vline(xintercept = 1, linetype = 2, colour = TJ$neutral, linewidth = 0.3) +
  geom_errorbar(aes(xmin = lo, xmax = hi), width = 0, linewidth = 0.5, orientation = "y") + geom_point(size = 1.6) +
  facet_wrap(~term_lab, nrow = 1, scales = "free_x") +
  scale_colour_manual(values = COLV, guide = "none") +
  scale_y_discrete(labels = function(x) paste0(x, "  ", sapply(x, function(z) VARIANTS[[z]]$label))) +
  labs(x = "Hazard ratio per SD (95% CI)", y = NULL,
       title = "Correcting 2024 effort changes the main model only slightly") + theme_tj(grid = "x")
ggsave(file.path(AUD, "figures", "Fig_effort2024_coefficients.pdf"), p1, width = 183 / 25.4, height = 70 / 25.4,
       device = grDevices::cairo_pdf)
ggsave(file.path(AUD, "figures", "Fig_effort2024_coefficients.png"), p1, width = 183 / 25.4, height = 70 / 25.4,
       dpi = 450, device = ragg::agg_png, bg = "white")

tvd[, variant_lab := paste(variant, label)]
p2 <- ggplot(tvd, aes(year, HR, colour = variant_lab, fill = variant_lab)) +
  geom_hline(yintercept = 1, linetype = 2, colour = TJ$neutral, linewidth = 0.3) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.12, colour = NA) + geom_line(linewidth = 0.6) +
  scale_colour_manual(values = setNames(COLV[TV_KEYS], unique(tvd$variant_lab)), name = NULL) +
  scale_fill_manual(values = setNames(COLV[TV_KEYS], unique(tvd$variant_lab)), name = NULL) +
  labs(x = NULL, y = "Hazard ratio per 1 SD of effort", title = "Return on survey effort through time") +
  theme_tj(grid = "y") + theme(legend.position = "inside", legend.position.inside = c(0.62, 0.86))
fa <- fread(file.path(OUT, "tables", "tbl_effort_2024_audit.csv"))[in_scope %in% c(TRUE, "TRUE") & mainland %in% c(TRUE, "TRUE")]
fa <- melt(fa[, .(province, `2023` = visits_2023, `2024 original` = visits_2024_orig, `2024 corrected` = visits_fix)],
           id.vars = "province", variable.name = "series", value.name = "visits")
ord <- fa[series == "2024 corrected"][order(visits), province]
fa[, province := factor(province, levels = ord)]
p3 <- ggplot(fa, aes(visits, province, colour = series, shape = series)) +
  geom_point(size = 1.3) + scale_x_log10(labels = scales::label_comma()) +
  scale_colour_manual(values = c(`2023` = TJ$neutral, `2024 original` = TJ$warming, `2024 corrected` = TJ$effort), name = NULL) +
  scale_shape_manual(values = c(`2023` = 1, `2024 original` = 4, `2024 corrected` = 16), name = NULL) +
  # 注记放在左侧空白处, 不越界 / notes sit in the empty left part of the panel
  annotate("text", x = 12, y = "Guangdong", label = "CBR 14 days; gap in V1", hjust = 0,
           size = pt2mm(5.5), colour = TJ$subink) +
  annotate("text", x = 12, y = "Shanghai", label = "CBR 153 days", hjust = 0,
           size = pt2mm(5.5), colour = TJ$subink) +
  labs(x = "Birding visits (log scale)", y = NULL, title = "2024 visits before and after adding eBird") +
  theme_tj(grid = "x") + theme(legend.position = "bottom", axis.text.y = element_text(size = TJ_BASE - 1.5))
pp <- (p3 | p2) + plot_layout(widths = c(0.9, 1.1)) + tj_tags()
ggsave(file.path(AUD, "figures", "Fig_effort2024_timevarying.pdf"), pp, width = 183 / 25.4, height = 105 / 25.4,
       device = grDevices::cairo_pdf)
ggsave(file.path(AUD, "figures", "Fig_effort2024_timevarying.png"), pp, width = 183 / 25.4, height = 105 / 25.4,
       dpi = 450, device = ragg::agg_png, bg = "white")
msg("DONE")
