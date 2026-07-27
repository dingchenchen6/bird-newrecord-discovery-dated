#!/usr/bin/env Rscript
# ============================================================
# Script 153: Fig9-alt / Fig10-alt —— 仿 GEB 原文图式的可选版本
# Alternative species- and province-level figures in the original GEB style
# ============================================================
# 目的 / Objective:
#   为物种水平与省级水平各提供一套【与 GEB 原文图式一致】的图, 与脚本 150
#   的森林图版本并存, 投稿时可择一。原文图式与本研究的对应:
#
#   GEB Fig3a  三组的后验密度山脊图        -> Fig9alt a  三种系统发育处理的
#              (all mammals / bats /                     参数分布山脊图
#               non-flying)                              (正态近似, 非后验)
#   GEB Fig3b  分类性状的堆叠柱 + 卡方标注 -> Fig9alt b  同式, 五个分类性状
#   GEB Fig4a-f 偏回归散点(各自配色)       -> Fig10alt a-f 同式, 六个预测因子
#   GEB Fig4g  百分比堆叠柱(相对重要性)    -> Fig10alt g  层次分割的独立贡献
#   GEB Fig4h  斜率 ± 95% CI(与 g 同色)    -> Fig10alt h  负二项模型系数
#
# 与原文的一处必要差别 / One necessary difference:
#   原文的山脊是【贝叶斯后验】。本研究物种水平用系统发育逻辑回归与 glmmTMB,
#   给出的是点估计与标准误, 故山脊画的是【估计量的抽样分布(正态近似)】。
#   形状含义相近, 但坐标轴与图注必须如实标明, 不能称之为后验。
#
# Input / 输入:  analysis_v2/tables/tbl_v2_species_fast_effects.csv
#                analysis_v2/data/species_traits_harmonised_v2.csv
#                analysis_v2/tables/tbl_v2_province_{coefficients,hp,partial}.csv
#                analysis_v2/data/province_level_model_data_v2.csv
# Output / 输出: analysis_v2/figures_alt/Fig9alt_*.{png,pdf,svg,pptx}
#                analysis_v2/figures_alt/Fig10alt_*.{png,pdf,svg,pptx}
#
# Main packages / 主要包: ggplot2, ggridges, patchwork, MASS, officer, rvg
# 运行 / Run: Rscript --no-init-file code/153_geb_original_style_figures.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(ggridges); library(patchwork)
  library(MASS); library(officer); library(rvg)
})
options(warn = 1); set.seed(42)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
TAB <- file.path(OUT, "tables"); FIG <- file.path(OUT, "figures_alt")
dir.create(FIG, showWarnings = FALSE, recursive = TRUE)
msg <- function(...) cat(sprintf("[153 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

# 原文的柔和配色 / the muted palette of the original figures
GEBCOL <- c("#7FC7C0", "#F4A582", "#B2ABD2", "#F6C445", "#2C7FB8",
            "#8C96C6", "#A6D96A", "#D2843C")
theme_geb <- function(base = 9) theme_bw(base_size = base, base_family = "sans") +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major = element_line(linewidth = 0.22, colour = "grey90"),
        panel.border = element_rect(linewidth = 0.4, colour = "grey35"),
        strip.background = element_rect(fill = "grey92", colour = "grey35", linewidth = 0.4),
        strip.text = element_text(face = "bold", size = base - 0.5),
        axis.text = element_text(colour = "grey15"),
        plot.title = element_text(face = "bold", size = base + 1, hjust = 0),
        plot.subtitle = element_text(size = base - 1, colour = "grey30", hjust = 0),
        plot.tag = element_text(face = "bold", size = base + 2),
        plot.tag.position = c(0.012, 0.98),
        legend.key.size = unit(9, "pt"), legend.background = element_blank(),
        plot.margin = margin(5, 7, 5, 7))
save_fig <- function(p, name, w, h, src = NULL) {
  for (ext in c("png", "pdf", "svg"))
    tryCatch({ f <- file.path(FIG, paste0(name, ".", ext))
      if (ext == "png") ggsave(f, p, width = w, height = h, dpi = 450, bg = "white")
      else if (ext == "pdf") ggsave(f, p, width = w, height = h, device = grDevices::cairo_pdf)
      else ggsave(f, p, width = w, height = h, device = grDevices::svg)
    }, error = function(e) msg("  ", ext, " failed: ", conditionMessage(e)))
  tryCatch({ ppt <- add_slide(read_pptx(), "Blank", "Office Theme")
    ppt <- ph_with(ppt, dml(ggobj = p, bg = "white"),
                   location = ph_location(left = 0.2, top = 0.2, width = w, height = h))
    print(ppt, target = file.path(FIG, paste0(name, ".pptx")))
  }, error = function(e) msg("  pptx failed: ", conditionMessage(e)))
  if (!is.null(src)) fwrite(src, file.path(FIG, paste0("source_data_", name, ".csv")))
  msg("  saved ", name)
}

# ==========================================================================
# Fig 9-alt  物种水平(仿 GEB Fig3)
# ==========================================================================
eff <- fread(file.path(TAB, "tbl_v2_species_fast_effects.csv"))
sp  <- fread(file.path(OUT, "data", "species_traits_harmonised_v2.csv"))

LAB <- c(z_log_range = "Range size", z_log_mass = "Body mass",
         z_log_hwi = "Hand-wing index", z_log_clutch = "Clutch size",
         z_log_congeners = "No. of congeners",
         z_log_habbreadth = "Habitat breadth", z_log_dietbreadth = "Diet breadth")
# (a) 山脊图: 按【生态学分组】而非按系统发育处理 —— 与 GEB 原文一致
#     (原文三条脊是 all mammals / bats / non-flying mammals)
#     本研究给出两套分组: 分类学(雀形目 / 非雀形目 / 全部) 与 迁徙类型。
#     每组各自用系统发育树(phyloglm)拟合, 组内重新标准化。
gm <- fread(file.path(TAB, "tbl_v2_species_group_effects.csv"))
mk_ridge <- function(which_grouping, lv, cols, ttl, sub) {
  # NB: 参数名不能与列名相同, 否则 data.table 的 i 表达式解析不出外部变量
  g <- gm[grouping == which_grouping & term %in% names(LAB)]
  g[, lab := factor(LAB[term], levels = rev(unname(LAB)))]
  g[, grp := factor(group, levels = lv)]
  dr <- g[, .(x = rnorm(4000, estimate, se)), by = .(lab, grp)]
  ns <- unique(g[, .(grp, n, n_events)])[order(grp)]
  leg <- sprintf("%s (%d spp., %d with records)", ns$grp, ns$n, ns$n_events)
  dr[, grp := factor(leg[match(grp, ns$grp)], levels = leg)]
  ggplot(dr, aes(x = x, y = lab, fill = grp, colour = grp)) +
    geom_vline(xintercept = 0, linetype = 2, colour = "grey40", linewidth = 0.4) +
    geom_density_ridges(alpha = 0.55, scale = 1.3, linewidth = 0.3, rel_min_height = 0.006) +
    scale_fill_manual(values = cols, name = NULL) +
    scale_colour_manual(values = cols, name = NULL) +
    labs(x = "Estimate (log-odds)", y = "Predictors", title = ttl, subtitle = sub) +
    theme_geb() + theme(legend.position = "top", legend.text = element_text(size = 7))
}
p9a1 <- mk_ridge("Taxonomic", c("All species", "Passeriformes", "Non-passerines"),
                 GEBCOL[c(1, 3, 2)],
                 "Species-level predictors by taxonomic group",
                 paste("Each group fitted separately on the dated phylogeny (Ives & Garland).",
                       "
Sampling distributions of the estimates, not posteriors; mass excluding zero indicates support."))
p9a2 <- mk_ridge("Migratory strategy", c("Resident", "Partial migrant", "Migratory"),
                 GEBCOL[c(4, 2, 5)],
                 "Species-level predictors by migratory strategy",
                 "Same models fitted within each migratory class")
p9a <- p9a1 | p9a2

# (b) 分类性状: 堆叠柱 + 卡方检验标注(与原文同式)
CATS <- c(migration_final = "Migratory strategy", trophic_niche = "Trophic niche",
          habitat_density = "Habitat density", iucn_group = "IUCN Red List status",
          endemic_final = "Endemism")
bars <- rbindlist(lapply(names(CATS), function(v) {
  x <- sp[!is.na(get(v)) & nzchar(as.character(get(v)))]
  tb <- table(as.character(x[[v]]), x$new_record_v2)
  ex <- suppressWarnings(chisq.test(tb))
  use_f <- any(ex$expected < 5)
  pv <- if (use_f) fisher.test(tb, simulate.p.value = TRUE, B = 10000)$p.value else ex$p.value
  sr <- ex$stdres[, "1"]
  padj <- p.adjust(2 * pnorm(-abs(sr)), method = "holm")
  data.table(trait = CATS[[v]], level = rownames(tb),
             n0 = as.numeric(tb[, "0"]), n1 = as.numeric(tb[, "1"]),
             std_resid = as.numeric(sr), p_adj = padj,
             test_lab = sprintf("%s (df = %d), p = %s",
                                if (use_f) "Fisher" else "Chi-sq", ex$parameter,
                                format.pval(pv, digits = 2)))
}))
# 每个性状单独成图并自带图例 —— 原文即如此; 若共用一个图例, 五个性状的
# 水平会被混在一起按字母排序, 完全不可读。
# NB: one legend per trait, as in the original; a shared legend would merge the
#     levels of five unrelated traits into one alphabetical list.
mk_bar <- function(tr_lab, cols) {
  bs <- bars[trait == tr_lab]
  bl <- melt(bs, id.vars = c("trait", "level", "std_resid", "p_adj", "test_lab"),
             measure.vars = c("n0", "n1"), variable.name = "grp", value.name = "n")
  bl[, grp := factor(grp, labels = c("New record = 0", "New record = 1"))]
  sg <- bs[std_resid > 1.96 & p_adj < 0.05]
  lab <- paste0(bs$test_lab[1],
                if (nrow(sg)) paste0("\n", paste(sprintf("%s: std. resid. = %.2f, adj. p = %s",
                    sg$level, sg$std_resid, format.pval(sg$p_adj, digits = 2)), collapse = "\n")) else "")
  ggplot(bl, aes(grp, n, fill = level)) +
    geom_col(width = 0.6, colour = "grey30", linewidth = 0.22) +
    annotate("text", x = 0.45, y = Inf, label = lab, hjust = 0, vjust = 1.2,
             size = 2.0, colour = "grey20", fontface = "italic") +
    scale_fill_manual(values = cols[seq_len(uniqueN(bl$level))], name = NULL) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.42))) +
    labs(x = NULL, y = "Number of species", title = tr_lab) +
    theme_geb() +
    theme(legend.position = "top", legend.text = element_text(size = 6),
          legend.key.size = unit(6.5, "pt"), legend.margin = margin(0, 0, -3, 0),
          plot.title = element_text(face = "bold", size = 8.5, hjust = 0.5))
}
PALS <- list(c("#B8E3DE", "#7FC7C0", "#2E8B84"),
             c("#C6DBEF", "#9ECAE1", "#6BAED6", "#4292C6", "#2171B5", "#08519C", "#08306B"),
             c("#FDD0A2", "#FD8D3C", "#A63603"),
             c("#FCBBA1", "#FB6A4A", "#A50F15"),
             c("#DADAEB", "#807DBA"))
p9b <- wrap_plots(Map(mk_bar, unname(CATS), PALS), nrow = 2) +
  plot_annotation(theme = theme(plot.margin = margin(0, 0, 0, 0)))

p9b_lab <- wrap_elements(p9b) +
  labs(title = "Categorical traits and the occurrence of new records",
       subtitle = "Pearson chi-square or Fisher exact tests; Holm-adjusted standardised residuals > 1.96 are flagged") +
  theme(plot.title = element_text(face = "bold", size = 10, hjust = 0),
        plot.subtitle = element_text(size = 8, colour = "grey30", hjust = 0))
F9 <- p9a / p9b_lab + plot_annotation(tag_levels = "a") + plot_layout(heights = c(1, 1.25))
save_fig(F9, "Fig9alt_species_level_geb_style", 13.6, 10.8, src = bars)

# ==========================================================================
# Fig 10-alt  省级水平(仿 GEB Fig4)
# ==========================================================================
pd <- fread(file.path(OUT, "data", "province_level_model_data_v2.csv"))
cf <- fread(file.path(TAB, "tbl_v2_province_coefficients.csv"))[model == "NB main" & term != "(Intercept)"]
hp <- fread(file.path(TAB, "tbl_v2_province_hp.csv"))

PLAB <- c(z_early_effort = "Early survey efforts", z_recent_effort = "Current survey efforts",
          z_richness = "Species richness", z_gdp = "Per capita GDP",
          z_area = "Area", z_habitat = "Habitat heterogeneity")
PRED <- names(PLAB)
PCOL <- setNames(c("#F6C445", "#F4A582", "#4A2C2A", "#D7301F", "#E7298A", "#9E9AC8"), PRED)

# (a-f) 偏回归散点: 各预测因子对"去掉它的模型残差"的独立效应
pan <- list()
for (i in seq_along(PRED)) {
  v <- PRED[i]; rest <- setdiff(PRED, v)
  m_wo <- MASS::glm.nb(as.formula(paste("new_record_count ~", paste(rest, collapse = " + "))), data = pd)
  r_y <- residuals(m_wo, type = "deviance")
  r_x <- residuals(lm(as.formula(paste(v, "~", paste(rest, collapse = " + "))), data = pd))
  dd <- data.table(rx = r_x, ry = r_y)
  fitl <- lm(ry ~ rx, data = dd); sm <- summary(fitl)$coefficients
  pan[[i]] <- ggplot(dd, aes(rx, ry)) +
    geom_smooth(method = "lm", formula = y ~ x, colour = PCOL[[v]],
                fill = PCOL[[v]], alpha = 0.22, linewidth = 0.55) +
    geom_point(size = 1.4, colour = "grey10") +
    annotate("text", x = Inf, y = Inf, hjust = 1.06, vjust = 1.4, size = 2.4,
             colour = "grey15", fontface = "italic",
             label = sprintf("beta == %.3f", sm[2, 1]), parse = TRUE) +
    annotate("text", x = Inf, y = Inf, hjust = 1.1, vjust = 3.0, size = 2.4,
             colour = "grey15", fontface = "italic",
             label = sprintf("italic(p) == %s", format.pval(sm[2, 4], digits = 2)), parse = TRUE) +
    labs(x = paste0("Residuals (", PLAB[[v]], ")"), y = "Residuals (New records)") +
    theme_geb()
}

# (g) 相对重要性 100% 堆叠柱
hp[, lab := PLAB[predictor]]
hp[, pct := 100 * independent / sum(independent)]
hp[, lab := factor(lab, levels = PLAB[PRED])]
r2 <- 20.5
p10g <- ggplot(hp, aes(x = factor(1), y = pct, fill = lab)) +
  geom_col(width = 0.55, colour = "grey30", linewidth = 0.25) +
  scale_fill_manual(values = unname(PCOL), name = NULL) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 100)) +
  labs(x = sprintf("Deviance explained = %.1f%%", r2), y = "Relative importance estimates (%)") +
  theme_geb() + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
                      legend.position = "none")

# (h) 系数 ± 95% CI, 与 (g) 同色
cf[, lab := factor(PLAB[term], levels = rev(PLAB[PRED]))]
p10h <- ggplot(cf, aes(estimate, lab, colour = lab)) +
  geom_vline(xintercept = 0, linetype = 2, colour = "grey25", linewidth = 0.45) +
  geom_errorbarh(aes(xmin = estimate - 1.96 * se, xmax = estimate + 1.96 * se),
                 height = 0.16, linewidth = 0.55) +
  geom_point(size = 2.6) +
  scale_colour_manual(values = rev(unname(PCOL)), guide = "none") +
  scale_y_discrete(position = "right") +
  labs(x = "Slope estimate", y = NULL) +
  theme_geb()

F10 <- (pan[[1]] | pan[[2]]) / (pan[[3]] | pan[[4]]) / (pan[[5]] | pan[[6]]) /
  (p10g | p10h) +
  plot_annotation(tag_levels = "a",
    title = "Provincial-level predictors of new bird distribution records",
    subtitle = paste("a-f, partial residual plots showing the independent effect of each predictor after controlling for the others.",
                     "\ng, relative importance from hierarchical partitioning. h, slope estimates with 95% confidence intervals",
                     "\nfrom the negative-binomial model; colours in h match g."),
    theme = theme(plot.title = element_text(face = "bold", size = 11),
                  plot.subtitle = element_text(size = 8, colour = "grey30"))) +
  plot_layout(heights = c(1, 1, 1, 1.15))
save_fig(F10, "Fig10alt_province_level_geb_style", 8.6, 11.4, src = hp)

msg("DONE")
