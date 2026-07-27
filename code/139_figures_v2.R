#!/usr/bin/env Rscript
# ============================================================
# Script 139: v2 主图件(投稿级)
# v2 main figure set, submission quality
# ============================================================
# 目的 / Objective:
#   将 v2 结果制成可直接投稿的图件(英文标注), 每图输出
#   PNG(450 dpi) + 矢量 PDF + SVG + 可编辑 PPTX + source data。
#
# 主模型 / Main model (frozen):
#   event ~ clim_change_z * effort_z + clim_var_z + offset(log c_t)
#           + (1|species) + (1|province) + (1|province:year)
#   binomial(cloglog); tavg_annual, W = 15 yr, effort = visits (coverage-gap)
#
# 图件清单 / Figures:
#   Fig1 主结果:  (a) 系数森林图 x 三档 SDM 阈值
#                 (b) 交互: 不同努力水平下累积变暖的边际风险
#                 (c) 相对重要性(四口径)
#                 (d) 判别力阶梯(仅固定效应的边际 AUC)
#   Fig2 定年校正: (a) 发表滞后与报告完整度
#                 (b) 发表年 vs 发现年的事件年序列
#                 (c) v1→v2 系数瀑布
#   Fig3 规格稳健: (a) 气候指标 x 窗口 的 HR 热图
#                 (b) 同上的 dAIC 热图
#                 (c) 努力代理 x 缺失处理 的森林图
#   Fig4 随机结构: (a) dAIC (b) 条件 R^2 与 AUC (c) 方差分量
#
# 设计规范 / Design standards:
#   Okabe-Ito 色盲友好配色; HR 轴以 1 为参考线; 误差棒为 95% Wald CI;
#   面板字母加粗左上; 直接标注优先于图例。
#
# 重要说明 / Important note on AIC comparability:
#   Fig3c(努力口径)与 Fig1a(阈值)跨越不同的样本量, AIC 不可比,
#   故这两处只比较【系数】, 不画 AIC。
#
# Input / 输入:  analysis_v2/tables/*.csv, analysis_v2/data/fit_R3.rds
# Output / 输出: analysis_v2/figures/Fig{1,2,3,4}_*.{png,pdf,svg,pptx} + source_data_*.csv
#
# Main packages / 主要包: data.table, ggplot2, patchwork, glmmTMB, officer, rvg
# 运行 / Run: Rscript --no-init-file code/139_figures_v2.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(ggplot2); library(glmmTMB)
  library(patchwork); library(officer); library(rvg)
})
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
TAB <- file.path(OUT, "tables"); FIG <- file.path(OUT, "figures")
dir.create(FIG, showWarnings = FALSE, recursive = TRUE)
msg <- function(...) cat(sprintf("[139 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

OI <- c(blue = "#0072B2", orange = "#E69F00", green = "#009E73", red = "#D55E00",
        purple = "#CC79A7", sky = "#56B4E9", yellow = "#F0E442", grey = "#999999")

theme_pub <- function(base = 9) {
  theme_classic(base_size = base, base_family = "sans") +
    theme(axis.line = element_line(linewidth = 0.35, colour = "grey20"),
          axis.ticks = element_line(linewidth = 0.3, colour = "grey20"),
          axis.text = element_text(colour = "grey15"),
          axis.title = element_text(colour = "grey5"),
          panel.grid.major.y = element_line(linewidth = 0.25, colour = "grey92"),
          strip.background = element_blank(),
          strip.text = element_text(face = "bold", size = base, hjust = 0),
          plot.title = element_text(face = "bold", size = base + 1, hjust = 0),
          plot.subtitle = element_text(size = base - 0.8, colour = "grey30", hjust = 0),
          plot.tag = element_text(face = "bold", size = base + 3),
          plot.tag.position = c(0.005, 0.985),
          legend.key.size = unit(9, "pt"),
          legend.text = element_text(size = base - 1),
          legend.title = element_text(size = base - 1, face = "bold"),
          plot.margin = margin(6, 8, 6, 8))
}

save_fig <- function(p, name, w, h, src = NULL) {
  for (ext in c("png", "pdf", "svg"))
    tryCatch({
      f <- file.path(FIG, paste0(name, ".", ext))
      if (ext == "png") ggsave(f, p, width = w, height = h, dpi = 450, bg = "white")
      else if (ext == "pdf") ggsave(f, p, width = w, height = h, device = grDevices::cairo_pdf)
      else ggsave(f, p, width = w, height = h, device = grDevices::svg)
    }, error = function(e) msg("  ", ext, " failed: ", conditionMessage(e)))
  # 可编辑 PPTX: rvg::dml 把每个图形元素转成 PowerPoint 原生矢量形状
  tryCatch({
    ppt <- add_slide(read_pptx(), "Blank", "Office Theme")
    ppt <- ph_with(ppt, dml(ggobj = p, bg = "white"),
                   location = ph_location(left = 0.2, top = 0.2, width = w, height = h))
    print(ppt, target = file.path(FIG, paste0(name, ".pptx")))
  }, error = function(e) msg("  pptx failed: ", conditionMessage(e)))
  if (!is.null(src)) fwrite(src, file.path(FIG, paste0("source_data_", name, ".csv")))
  msg("  saved ", name, " (png/pdf/svg/pptx)")
}

# Wald CI 由系数与 P 值反解 / recover Wald SE from the coefficient and its P value
se_from_p <- function(b, p) {
  z <- stats::qnorm(pmax(p, .Machine$double.xmin) / 2, lower.tail = FALSE)
  abs(b) / z
}
ci_dt <- function(b, p) { s <- se_from_p(b, p)
  data.table(HR = exp(b), lo = exp(b - 1.96 * s), hi = exp(b + 1.96 * s)) }

# 把一张结果表按若干项拉长为森林图数据 / reshape a results table into forest-plot rows
forest_rows <- function(dt, terms, id_cols) {
  rbindlist(lapply(terms, function(tm) {
    out <- dt[, ..id_cols]
    out[, term := TERM_LAB[[tm]]]
    cbind(out, ci_dt(dt[[tm]], dt[[TERM_P[[tm]]]]))
  }))
}

TERM_LAB <- c(b_effort = "Survey effort", b_change = "Accumulated warming",
              b_var = "Annual climate variability", b_int = "Warming x effort")
TERM_P   <- c(b_effort = "P_effort", b_change = "P_change", b_var = "P_var", b_int = "P_int")

rd <- function(f) if (file.exists(file.path(TAB, f))) fread(file.path(TAB, f)) else NULL

# ==========================================================================
# Fig 1  主结果
# ==========================================================================
C <- rd("tbl_v2_C_threshold.csv"); E <- rd("tbl_v2_E_importance.csv"); D <- rd("tbl_v2_D_ladder.csv")

# (a) 系数森林图 x 三档阈值
# 阈值是【省内适宜 SDM 栅格数】的下限, 不是缓冲区半径。
# 栅格中位面积 18.3 km2 (约 4.3 km 见方), 故 50/100/200 格约合 0.9/1.8/3.7 千 km2。
C[, threshold := paste0(threshold_km, " cells")]
fa <- forest_rows(C, names(TERM_LAB), "threshold")
fa[, term := factor(term, levels = rev(TERM_LAB))]
fa[, threshold := factor(threshold, levels = c("50 cells", "100 cells", "200 cells"))]
p1a <- ggplot(fa, aes(HR, term, colour = threshold)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
  geom_linerange(aes(xmin = lo, xmax = hi), position = position_dodge(0.6), linewidth = 0.55) +
  geom_point(position = position_dodge(0.6), size = 1.9) +
  scale_colour_manual(values = unname(OI[c("blue", "orange", "green")]), name = "Minimum suitable\ncells per province") +
  scale_x_continuous(trans = "log", breaks = c(0.8, 0.9, 1, 1.2, 1.4, 1.6)) +
  labs(x = "Hazard ratio per 1 SD (95% CI)", y = NULL,
       title = "Effort and warming contribute independently",
       subtitle = "Discrete-time proportional hazards, cloglog link") +
  theme_pub() + theme(legend.position = c(0.86, 0.22))

# (b) 交互: 不同努力水平下累积变暖的边际风险
m <- readRDS(file.path(OUT, "data", "fit_R3.rds"))
dm <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
dm[, c("x", "clim_change", "clim_var") := NULL]
cc <- as.data.table(read_parquet(file.path(OUT, "data", "components_v2_tavg_annual_W15.parquet")))
dm <- merge(dm, cc[, .(species, province, year, clim_change, clim_var)], by = c("species", "province", "year"))
dm <- dm[is.finite(clim_change) & is.finite(clim_var) & is.finite(eff_visits_gap_z)]
zs <- function(x) as.numeric(scale(x))
dm[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var), effort_z = zs(eff_visits_gap_z))]

cf <- fixef(m)$cond; V <- vcov(m)$cond
int_nm <- grep(":", names(cf), value = TRUE)[1]
grid <- CJ(clim_change_z = seq(quantile(dm$clim_change_z, .02), quantile(dm$clim_change_z, .98), length.out = 60),
           effort_z = as.numeric(quantile(dm$effort_z, c(.10, .50, .90))))
grid[, eff_lab := factor(effort_z, labels = c("Low effort (10th pct)", "Median effort", "High effort (90th pct)"))]
X <- cbind(1, grid$clim_change_z, grid$effort_z, 0, grid$clim_change_z * grid$effort_z)
colnames(X) <- c("(Intercept)", "clim_change_z", "effort_z", "clim_var_z", int_nm)
X <- X[, names(cf), drop = FALSE]
eta <- as.numeric(X %*% cf); sev <- sqrt(rowSums((X %*% V) * X))
grid[, `:=`(haz = 1 - exp(-exp(eta)), lo = 1 - exp(-exp(eta - 1.96 * sev)),
            hi = 1 - exp(-exp(eta + 1.96 * sev)))]
p1b <- ggplot(grid, aes(clim_change_z, 100 * haz, colour = eff_lab, fill = eff_lab)) +
  geom_ribbon(aes(ymin = 100 * lo, ymax = 100 * hi), alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.7) +
  scale_colour_manual(values = unname(OI[c("sky", "blue", "red")]), name = NULL) +
  scale_fill_manual(values = unname(OI[c("sky", "blue", "red")]), guide = "none") +
  labs(x = "Accumulated warming relative to the species' range (z)",
       y = "Annual hazard of a new provincial record (%)",
       title = "Warming matters most where effort is low",
       subtitle = "Marginal predictions at fixed-effect level; ribbons are 95% CI") +
  theme_pub() + theme(legend.position = c(0.28, 0.86))

# (c) 相对重要性
imp <- melt(E[, .(term, dAIC, dAUCm, dR2c, abs_beta)], id.vars = "term")
imp[, variable := factor(variable, levels = c("dAIC", "dAUCm", "dR2c", "abs_beta"),
    labels = c("ΔAIC", "ΔAUC", "ΔR²", "|β|"))]
imp[, term := factor(term, levels = E[order(rank_mean)]$term)]
p1c <- ggplot(imp, aes(value, term, fill = term)) +
  geom_col(width = 0.65) + geom_vline(xintercept = 0, colour = "grey50", linewidth = 0.3) +
  facet_wrap(~variable, scales = "free_x", nrow = 1) +
  scale_fill_manual(values = unname(OI[c("green", "blue", "purple", "grey")]), guide = "none") +
  scale_x_continuous(breaks = scales::breaks_pretty(n = 3), labels = scales::label_number(drop0trailing = TRUE)) +
  labs(x = "Loss when the term is dropped from the full model",
       y = NULL, title = "Warming and effort are of comparable importance",
       subtitle = "ΔAIC and ΔAUC on fixed effects, ΔR² conditional, |β| standardised; larger = more important") +
  theme_pub() + theme(panel.grid.major.y = element_blank(),
                      panel.grid.major.x = element_line(linewidth = 0.25, colour = "grey92"),
                      panel.spacing.x = unit(10, "pt"))

# (d) 判别力阶梯
D2 <- copy(D)[, lab := sub("^F[0-9] ", "", model)]
D2[, lab := factor(lab, levels = D2$lab)]
p1d <- ggplot(D2, aes(lab, AUC_marginal, group = 1)) +
  geom_hline(yintercept = 0.5, linetype = 2, colour = "grey55", linewidth = 0.35) +
  geom_line(colour = OI[["grey"]], linewidth = 0.5) +
  geom_point(size = 2.4, colour = OI[["blue"]]) +
  geom_text(aes(label = sprintf("%.3f", AUC_marginal)), vjust = -1.1, size = 2.5, colour = "grey20") +
  scale_y_continuous(limits = c(0.38, 0.68)) +
  labs(x = NULL, y = "AUC from fixed effects only",
       title = "Neither factor alone is sufficient",
       subtitle = "Discrimination gained as fixed effects are added; random structure held at the main model") +
  theme_pub() + theme(axis.text.x = element_text(angle = 20, hjust = 1))

F1 <- (p1a | p1b) / (p1c | p1d) + plot_annotation(tag_levels = "a")
save_fig(F1, "Fig1_main_results_v2", 11.2, 8.0,
         src = rbindlist(list(fa[, .(panel = "a", term, group = threshold, HR, lo, hi)],
                              grid[, .(panel = "b", term = "hazard", group = eff_lab,
                                       HR = haz, lo, hi)]), fill = TRUE))

# ==========================================================================
# Fig 2  定年校正
# ==========================================================================
lag  <- rd("tbl_publication_lag.csv"); comp <- rd("tbl_reporting_completeness.csv")
dec  <- rd("tbl_change_decomposition.csv"); cmp <- rd("tbl_dating_comparison.csv")

p2a <- ggplot(lag[lag >= 0 & lag <= 12], aes(lag, pct)) +
  geom_col(fill = OI[["blue"]], width = 0.75, alpha = 0.85) +
  geom_line(data = comp, aes(x = 2025 - year, y = 100 * completeness),
            colour = OI[["red"]], linewidth = 0.7, inherit.aes = FALSE) +
  geom_point(data = comp, aes(x = 2025 - year, y = 100 * completeness),
             colour = OI[["red"]], size = 1.1, inherit.aes = FALSE) +
  annotate("text", x = 7.5, y = 92, label = "Reporting completeness c(t)",
           colour = OI[["red"]], size = 2.7, hjust = 0) +
  annotate("text", x = 4.2, y = 33, label = "Publication lag\n(% of records)",
           colour = OI[["blue"]], size = 2.7, hjust = 0) +
  labs(x = "Years between discovery and publication", y = "Per cent",
       title = "Records appear in print years after they are made",
       subtitle = "Median lag 1 yr, mean 2.09 yr; 81.7% of records lag by at least one year") +
  theme_pub()

ts <- rbind(cmp[!is.na(new_year), .(year = new_year, dating = "Discovery year (v2)")],
            cmp[!is.na(old_year), .(year = old_year, dating = "Publication year (v1)")])[, .N, by = .(year, dating)]
p2b <- ggplot(ts, aes(year, N, colour = dating)) +
  geom_line(linewidth = 0.7) + geom_point(size = 1.2) +
  scale_colour_manual(values = unname(OI[c("blue", "orange")]), name = NULL) +
  annotate("rect", xmin = 2021.5, xmax = 2024.5, ymin = -Inf, ymax = Inf,
           fill = "grey70", alpha = 0.18) +
  annotate("text", x = 2023, y = max(ts$N) * 0.97, label = "right-censored\nby publication lag",
           size = 2.4, colour = "grey30") +
  labs(x = NULL, y = "New provincial records",
       title = "Publication-year dating manufactures a terminal surge",
       subtitle = "The same events, dated two ways; 83.1% change year") +
  theme_pub() + theme(legend.position = c(0.24, 0.87))

wf <- melt(dec[, .(step, `Survey effort` = HR_effort, `Accumulated warming` = HR_change,
                   `Annual variability` = HR_var, `Warming x effort` = HR_int)], id.vars = "step")
wf[, step := factor(step, levels = dec$step)]
p2c <- ggplot(wf, aes(step, value, colour = variable, group = variable)) +
  geom_hline(yintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
  geom_line(linewidth = 0.65) + geom_point(size = 2) +
  scale_colour_manual(values = unname(OI[c("blue", "green", "grey", "purple")]), name = NULL) +
  annotate("rect", xmin = 1.5, xmax = 2.5, ymin = -Inf, ymax = Inf, fill = OI[["red"]], alpha = 0.10) +
  annotate("text", x = 2, y = 1.72, label = "re-dating", size = 2.5, colour = OI[["red"]]) +
  labs(x = NULL, y = "Hazard ratio per 1 SD",
       title = "Re-dating is the single decisive correction",
       subtitle = "S0 v1 published -> S1 discovery-year -> S2 effort gaps -> S3 area weights -> S4 offset -> S5 province x year") +
  theme_pub() + theme(legend.position = "right",
                      axis.text.x = element_text(angle = 0))

F2 <- (p2a | p2b) / p2c + plot_annotation(tag_levels = "a") + plot_layout(heights = c(1, 0.95))
save_fig(F2, "Fig2_dating_correction_v2", 11.2, 7.4, src = dec)

# ==========================================================================
# Fig 3  规格稳健性
# ==========================================================================
IW <- rd("tbl_v2_indicator_window.csv"); B <- rd("tbl_v2_B_effort.csv")
if (!is.null(IW)) {
  IW[, ind_lab := factor(indicator,
      levels = c("tavg_annual", "tmax_warm", "tmin_cold", "tavg_winter"),
      labels = c("Annual mean T", "Warmest-month Tmax", "Coldest-month Tmin", "Winter mean T"))]
  IW[, star := fifelse(P_change < 0.001, "***", fifelse(P_change < 0.01, "**",
                fifelse(P_change < 0.05, "*", "")))]
  p3a <- ggplot(IW, aes(factor(window), ind_lab, fill = HR_change)) +
    geom_tile(colour = "white", linewidth = 0.7) +
    geom_text(aes(label = sprintf("%.2f%s", HR_change, star)), size = 2.6, colour = "grey10") +
    scale_fill_gradient2(midpoint = 1, low = OI[["sky"]], mid = "white", high = OI[["red"]],
                         name = "HR") +
    labs(x = "Accumulation window (years)", y = NULL,
         title = "Only annual mean temperature carries the signal",
         subtitle = "Hazard ratio for accumulated warming; * P<0.05, ** P<0.01, *** P<0.001") +
    theme_pub() + theme(panel.grid.major.y = element_blank())
  p3b <- ggplot(IW, aes(factor(window), ind_lab, fill = dAIC)) +
    geom_tile(colour = "white", linewidth = 0.7) +
    geom_text(aes(label = sprintf("%.0f", dAIC)), size = 2.6, colour = "grey10") +
    scale_fill_gradient(low = OI[["green"]], high = "white", name = "Delta AIC") +
    labs(x = "Accumulation window (years)", y = NULL,
         title = "Model support across climate specifications",
         subtitle = "Delta AIC relative to the best cell; all fitted on the same rows") +
    theme_pub() + theme(panel.grid.major.y = element_blank())
} else { p3a <- p3b <- ggplot() + theme_void() }

if (!is.null(B)) {
  fb <- forest_rows(B, c("b_effort", "b_change"), c("proxy", "treatment"))
  fb[, treatment := factor(treatment, levels = c("gap", "imp", "zero"),
      labels = c("coverage gap (main)", "bounded imputation", "zero-filled (v1)"))]
  fb[, proxy := factor(proxy, levels = c("visits", "observers", "days", "record"),
      labels = c("Visits", "Observers", "Birding days", "Records"))]
  p3c <- ggplot(fb, aes(HR, proxy, colour = treatment, shape = term)) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
    geom_linerange(aes(xmin = lo, xmax = hi), position = position_dodge(0.7), linewidth = 0.5) +
    geom_point(position = position_dodge(0.7), size = 1.8) +
    scale_colour_manual(values = unname(OI[c("blue", "orange", "grey")]), name = "Missing-data rule") +
    scale_shape_manual(values = c(16, 17), name = NULL) +
    labs(x = "Hazard ratio per 1 SD (95% CI)", y = NULL,
         title = "Robust to the choice of effort proxy and missing-data rule",
         subtitle = "AIC is not comparable across rules (different sample sizes); coefficients are") +
    theme_pub() + theme(legend.position = "right")
} else p3c <- ggplot() + theme_void()

F3 <- (p3a | p3b) / p3c + plot_annotation(tag_levels = "a") + plot_layout(heights = c(1, 1.15))
save_fig(F3, "Fig3_specification_robustness_v2", 11.2, 7.6,
         src = rbindlist(list(IW, if (!is.null(B)) B), fill = TRUE))

# ==========================================================================
# Fig 4  随机效应结构的多准则评价
# ==========================================================================
R <- rd("tbl_v2_re_evaluation.csv")
RE_LAB <- c(R0 = "species", R1 = "species + province\n(v1)", R2 = "+ year",
            R3 = "+ province x year\n(MAIN)", R4 = "+ species warming slope",
            R5 = "+ province effort slope")
R[, lab := factor(RE_LAB[structure], levels = RE_LAB)]
p4a <- ggplot(R, aes(lab, dAIC, fill = structure == "R3")) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%.1f", dAIC)), vjust = -0.5, size = 2.5, colour = "grey20") +
  scale_fill_manual(values = c(`TRUE` = OI[["blue"]], `FALSE` = OI[["grey"]]), guide = "none") +
  labs(x = NULL, y = "Delta AIC", title = "Fit",
       subtitle = "Lower is better") + theme_pub() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))
p4b <- ggplot(melt(R[, .(lab, `Conditional R2` = R2_conditional,
                         `Conditional AUC` = AUC_conditional, `Marginal AUC` = AUC_marginal)],
                   id.vars = "lab"),
              aes(lab, value, colour = variable, group = variable)) +
  geom_line(linewidth = 0.6) + geom_point(size = 2) +
  scale_colour_manual(values = unname(OI[c("green", "blue", "orange")]), name = NULL) +
  labs(x = NULL, y = "Explained variation / discrimination",
       title = "Explanatory power",
       subtitle = "Marginal AUC is flat across structures") +
  theme_pub() + theme(axis.text.x = element_text(angle = 25, hjust = 1),
                      legend.position = c(0.28, 0.5))
vcm <- rbindlist(lapply(seq_len(nrow(R)), function(i) {
  parts <- strsplit(R$re_sd[i], "; ")[[1]]
  data.table(lab = R$lab[i], structure = R$structure[i],
             raw = sub("=.*", "", parts), sd = as.numeric(sub(".*=", "", parts)))
}))
# glmmTMB 对同一分组变量的第二个随机项命名为 <group>.1, 即随机斜率
VC_LAB <- c(species = "Species intercept", province = "Province intercept",
            year = "Year intercept", prov_year = "Province x year intercept",
            species.1 = "Species slope (warming)", province.1 = "Province slope (effort)")
vcm[, term := factor(VC_LAB[raw], levels = VC_LAB)]
p4c <- ggplot(vcm, aes(lab, sd, fill = term)) +
  geom_col(position = "stack", width = 0.65) +
  scale_fill_manual(values = unname(OI[c("blue", "orange", "sky", "green", "purple", "red")]),
                    name = "Random term", drop = FALSE) +
  labs(x = NULL, y = "Random-effect SD (latent scale)",
       title = "Variance structure",
       subtitle = "No component collapses to zero") +
  theme_pub() + theme(axis.text.x = element_text(angle = 25, hjust = 1),
                      legend.position = "right")
F4 <- (p4a | p4b | p4c) + plot_annotation(tag_levels = "a")
save_fig(F4, "Fig4_random_structure_v2", 12.5, 4.4, src = R)

msg("all v2 figures written to ", FIG, " | DONE")
