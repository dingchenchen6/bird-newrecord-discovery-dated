#!/usr/bin/env Rscript
# ============================================================
# Script 150: Fig9 物种水平 / Fig10 省级水平(仿 GEB 原文的图式, 有优化)
# Fig9 species-level and Fig10 province-level, in the style of the mammal paper
# ============================================================
# 图式对应 / Correspondence with the mammal paper's figures:
#   GEB Fig3 物种水平系数森林图  -> Fig9a  (加了显著性着色与效应方向注释)
#   GEB 列联分析(表格呈现)       -> Fig9b  (改为可视化: 各水平的新纪录比例 +
#                                          标准化残差, 比表格更易读)
#   GEB Fig4 省级努力驱动         -> Fig10b (加了两个模型并列, 显示 offset 的作用)
#   GEB 层次分割(表格)            -> Fig10c (改为条形图并标注独立/共同贡献)
#
# 优化之处 / What is optimised relative to the original:
#   - 系数图按效应大小排序并直接标注比值, 不必回表查数
#   - 分类变量图同时显示样本量, 避免小样本水平被过度解读
#   - 省级图并列"计数模型"与"每单位努力的发现率模型", 让 offset 的含义显形
#   - 层次分割图把共同贡献一并画出(可为负), 而不是只画独立贡献
#
# Input / 输入:  analysis_v2/tables/tbl_v2_species_*.csv, tbl_v2_province_*.csv
# Output / 输出: analysis_v2/figures/Fig{9,10}_*.{png,pdf,svg,pptx} + source data
#
# Main packages / 主要包: data.table, ggplot2, patchwork, officer, rvg
# 运行 / Run: Rscript --no-init-file code/150_geb_style_figures.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(patchwork); library(officer); library(rvg)
})
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
TAB <- file.path(OUT, "tables"); FIG <- file.path(OUT, "figures")
msg <- function(...) cat(sprintf("[150 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

OI <- c(blue = "#0072B2", orange = "#E69F00", green = "#009E73", red = "#D55E00",
        purple = "#CC79A7", sky = "#56B4E9", yellow = "#F0E442", grey = "#999999")
theme_pub <- function(base = 9) theme_classic(base_size = base, base_family = "sans") +
  theme(axis.line = element_line(linewidth = 0.35, colour = "grey20"),
        axis.ticks = element_line(linewidth = 0.3, colour = "grey20"),
        axis.text = element_text(colour = "grey15"), axis.title = element_text(colour = "grey5"),
        panel.grid.major.y = element_line(linewidth = 0.25, colour = "grey92"),
        strip.background = element_blank(),
        strip.text = element_text(face = "bold", size = base, hjust = 0),
        plot.title = element_text(face = "bold", size = base + 1, hjust = 0),
        plot.subtitle = element_text(size = base - 0.8, colour = "grey30", hjust = 0),
        plot.tag = element_text(face = "bold", size = base + 3), plot.tag.position = c(0.005, 0.985),
        legend.key.size = unit(9, "pt"), legend.text = element_text(size = base - 1),
        legend.title = element_text(size = base - 1, face = "bold"),
        plot.margin = margin(6, 8, 6, 8))
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
rd <- function(f) if (file.exists(file.path(TAB, f))) fread(file.path(TAB, f)) else NULL

TERM_LAB <- c(
  z_log_mass = "Body mass", z_log_hwi = "Hand-wing index (dispersal)",
  z_log_range = "Range size (provinces)", z_log_clutch = "Clutch size",
  z_log_congeners = "Number of congeners",
  z_early_effort = "Early survey effort (2002-2008)", z_recent_effort = "Recent survey effort (2009-2024)",
  z_richness = "Regional species richness", z_gdp = "GDP per capita",
  z_area = "Administrative area", z_habitat = "Habitat heterogeneity")
CAT_PREFIX <- c("migration", "trophic_niche", "habitat_density", "iucn_group", "endemic_status")
CAT_LABEL  <- c(migration = "Migration", trophic_niche = "Trophic niche",
                habitat_density = "Habitat density", iucn_group = "IUCN status",
                endemic_status = "Endemism")
pretty_term <- function(x) {
  out <- TERM_LAB[x]; bad <- is.na(out)
  # brms 的分类项形如 trophic_nicheGranivore -> "Trophic niche: Granivore"
  out[bad] <- vapply(x[bad], function(t) {
    hit <- CAT_PREFIX[startsWith(t, CAT_PREFIX)]
    if (!length(hit)) return(gsub("_", " ", t))
    hit <- hit[which.max(nchar(hit))]
    lev <- gsub("\\.", " ", sub(paste0("^", hit), "", t))
    paste0(CAT_LABEL[[hit]], ": ", gsub("_", " ", lev))
  }, character(1))
  unname(out)
}

# ==========================================================================
# Fig 9  物种水平(三种系统发育处理互为对照)
# ==========================================================================
TERM_LAB2 <- c(z_log_mass = "Body mass", z_log_hwi = "Hand-wing index (dispersal)",
  z_log_range = "Global range size", z_log_clutch = "Clutch size",
  z_log_congeners = "Number of congeners", z_log_habbreadth = "Habitat breadth (BIRDBASE HB)",
  z_log_dietbreadth = "Diet breadth (BIRDBASE DB)")
CAT_PRE <- c("migration_final", "trophic_niche", "habitat_density", "iucn_group", "endemic_final")
CAT_LAB <- c(migration_final = "Migration", trophic_niche = "Trophic niche",
             habitat_density = "Habitat density", iucn_group = "IUCN status",
             endemic_final = "Endemism")
lab_of <- function(x) vapply(x, function(t) {
  if (t %in% names(TERM_LAB2)) return(unname(TERM_LAB2[t]))
  hit <- CAT_PRE[startsWith(t, CAT_PRE)]
  if (!length(hit)) return(gsub("_", " ", t))
  hit <- hit[which.max(nchar(hit))]
  paste0(CAT_LAB[[hit]], ": ", gsub("\\.", " ", sub(paste0("^", hit), "", t)))
}, character(1))

eff <- rd("tbl_v2_species_fast_effects.csv")
cmp <- rd("tbl_v2_species_fast_compare.csv")
cir <- rd("tbl_v2_species_range_circularity.csv")
fitt <- rd("tbl_v2_species_fast_fit.csv")
MCOL <- c(`M1 taxonomic nesting` = OI[["blue"]], `M2 phylogenetic eigenvectors` = OI[["green"]],
          `M3 phyloglm` = OI[["orange"]])

if (!is.null(eff)) {
  eff[, lab := lab_of(term)]
  eff[, kind := fifelse(grepl("^z_log_", term), "Continuous traits", "Categorical contrasts")]
  ord <- eff[model == "M3 phyloglm"][order(odds_ratio)]$lab
  eff[, lab := factor(lab, levels = unique(c(ord, setdiff(lab, ord))))]
  p9a <- ggplot(eff[kind == "Continuous traits"], aes(odds_ratio, lab, colour = model)) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
    geom_linerange(aes(xmin = OR_lo, xmax = OR_hi), position = position_dodge(0.62), linewidth = 0.5) +
    geom_point(aes(shape = significant), position = position_dodge(0.62), size = 2) +
    scale_colour_manual(values = MCOL, name = NULL) +
    scale_shape_manual(values = c(`FALSE` = 1, `TRUE` = 16), guide = "none") +
    scale_x_continuous(trans = "log10") +
    labs(x = "Odds ratio per 1 SD (95% CI)", y = NULL,
         title = "Only range size survives among continuous traits",
         subtitle = "Filled points are significant. Body mass, clutch size, habitat breadth and diet breadth are all null") +
    theme_pub() + theme(legend.position = "bottom", panel.grid.major.y = element_blank())
  p9b <- ggplot(eff[kind == "Categorical contrasts"], aes(odds_ratio, lab, colour = model)) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
    geom_linerange(aes(xmin = OR_lo, xmax = OR_hi), position = position_dodge(0.62), linewidth = 0.5) +
    geom_point(aes(shape = significant), position = position_dodge(0.62), size = 2) +
    scale_colour_manual(values = MCOL, guide = "none") +
    scale_shape_manual(values = c(`FALSE` = 1, `TRUE` = 16), guide = "none") +
    scale_x_continuous(trans = "log10") +
    labs(x = "Odds ratio vs reference level (95% CI)", y = NULL,
         title = "Partial migrants stand out",
         subtitle = "References: resident, invertivore, dense habitat, Least Concern, non-endemic") +
    theme_pub() + theme(panel.grid.major.y = element_blank())
} else { p9a <- p9b <- ggplot() + theme_void() }

p9c <- if (!is.null(cir)) {
  cc <- copy(cir)[, lab := c("Global range size\n(independent of the response)",
                             "Chinese provinces occupied\n(contains the response)")]
  ggplot(cc, aes(odds_ratio, lab, fill = p_value < 0.05)) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
    geom_col(width = 0.5) +
    geom_text(aes(label = sprintf("OR = %.2f, P = %.2g", odds_ratio, p_value)),
              hjust = -0.06, size = 2.5, colour = "grey20") +
    scale_fill_manual(values = c(`TRUE` = OI[["red"]], `FALSE` = OI[["grey"]]), guide = "none") +
    scale_x_continuous(limits = c(0, 3.2)) +
    labs(x = "Odds ratio per 1 SD", y = NULL,
         title = "Why range size must be measured globally",
         subtitle = paste("The trait database was published in 2022, so its provincial counts already contain the",
                          "\n2002-2021 records used as the response. Entered together, the global measure is absorbed.")) +
    theme_pub() + theme(panel.grid.major.y = element_blank())
} else ggplot() + theme_void()

p9d <- if (!is.null(cmp)) {
  cm <- copy(cmp)[, lab := lab_of(term)]
  cm[, agreement := fifelse(n_significant == n_models, "significant in all three",
                     fifelse(n_significant > 0, "significant in some", "not significant"))]
  cm[, agreement := factor(agreement, levels = c("significant in all three", "significant in some", "not significant"))]
  setorder(cm, -n_significant, -same_direction)
  cm[, lab := factor(lab, levels = rev(lab))]
  ggplot(cm, aes(n_significant, lab, fill = agreement)) +
    geom_col(width = 0.62) +
    geom_text(aes(label = OR_range), hjust = -0.1, size = 2.2, colour = "grey25") +
    scale_fill_manual(values = c(`significant in all three` = OI[["red"]],
                                 `significant in some` = OI[["orange"]],
                                 `not significant` = OI[["grey"]]), name = NULL) +
    scale_x_continuous(breaks = 0:3, limits = c(0, 4.6)) +
    labs(x = "Number of phylogenetic treatments in which the term is significant", y = NULL,
         title = "Robustness to how phylogeny is handled",
         subtitle = "Taxonomic nesting, phylogenetic eigenvectors, phylogenetic logistic regression;\ntext gives the range of odds ratios across the three") +
    theme_pub() + theme(legend.position = "bottom", panel.grid.major.y = element_blank(),
                        axis.text.y = element_text(size = 6.4))
} else ggplot() + theme_void()

F9 <- (p9a | p9b) / (p9c | p9d) + plot_annotation(tag_levels = "a") + plot_layout(heights = c(1, 1.1))
save_fig(F9, "Fig9_species_level_v2", 12.4, 8.4, src = eff)

# ==========================================================================
# Fig 10  省级水平
# ==========================================================================
mo <- rd("tbl_v2_province_models.csv"); cf <- rd("tbl_v2_province_coefficients.csv")
hp <- rd("tbl_v2_province_hp.csv"); pr <- rd("tbl_v2_province_partial.csv")

p10a <- if (!is.null(mo)) {
  m2 <- melt(mo[, .(model, AICc, dispersion)], id.vars = "model")
  m2[, model := factor(model, levels = mo$model)]
  m2[, variable := factor(variable, levels = c("AICc", "dispersion"),
       labels = c("AICc (lower is better)", "Dispersion (1 is ideal)"))]
  ggplot(m2, aes(model, value, fill = model)) +
    geom_col(width = 0.6) +
    geom_hline(data = data.frame(variable = factor("Dispersion (1 is ideal)",
                 levels = levels(m2$variable)), y = 1),
               aes(yintercept = y), linetype = 2, colour = "grey45", linewidth = 0.35) +
    geom_text(aes(label = sprintf("%.2f", value)), vjust = -0.35, size = 2.5, colour = "grey20") +
    facet_wrap(~variable, scales = "free_y", nrow = 1) +
    scale_fill_manual(values = unname(OI[c("grey", "blue", "green")]), guide = "none") +
    scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
    labs(x = NULL, y = NULL, title = "Poisson is rejected, negative binomial is not",
         subtitle = "Poisson dispersion 5.60 (P = 2.3e-17); the negative binomial reduces it to 1.24 (P = 0.20)") +
    theme_pub() + theme(axis.text.x = element_text(angle = 16, hjust = 1, size = 7))
} else ggplot() + theme_void()

p10b <- if (!is.null(cf)) {
  cb <- cf[term != "(Intercept)"]
  cb[, lab := pretty_term(term)]
  cb[, model := factor(model, levels = c("NB main", "NB offset"),
       labels = c("Counts", "Rate per unit of recent effort"))]
  ord <- cb[model == levels(cb$model)[1]][order(IRR)]$lab
  cb[, lab := factor(lab, levels = ord)]
  ggplot(cb, aes(IRR, lab, colour = significant)) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
    geom_linerange(aes(xmin = IRR_lo, xmax = IRR_hi), linewidth = 0.55) +
    geom_point(size = 2) +
    geom_text(aes(label = sprintf("%.2f", IRR)), vjust = -0.95, size = 2.2, colour = "grey25") +
    facet_wrap(~model, nrow = 1) +
    scale_colour_manual(values = c(`TRUE` = OI[["red"]], `FALSE` = OI[["grey"]]),
                        labels = c(`TRUE` = "P < 0.05", `FALSE` = "n.s."), name = NULL) +
    scale_x_continuous(trans = "log10") +
    labs(x = "Incidence rate ratio per 1 SD (95% CI)", y = NULL,
         title = "Effort shows up as diminishing returns",
         subtitle = paste("Left: both efforts as predictors. Right: recent effort as an offset, so the response is the",
                          "discovery rate\nper unit of effort. Provinces already well covered in 2002-2008 then yield fewer records")) +
    theme_pub() + theme(legend.position = "bottom", panel.grid.major.y = element_blank())
} else ggplot() + theme_void()

p10c <- if (!is.null(hp)) {
  hm <- melt(hp[, .(predictor, Independent = independent, Joint = joint)], id.vars = "predictor")
  hm[, lab := pretty_term(predictor)]
  hm[, lab := factor(lab, levels = pretty_term(hp[order(independent)]$predictor))]
  ggplot(hm, aes(100 * value, lab, fill = variable)) +
    geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.35) +
    geom_col(width = 0.6) +
    scale_fill_manual(values = unname(OI[c("blue", "yellow")]), name = NULL) +
    labs(x = "Contribution to explained deviance (%)", y = NULL,
         title = "Hierarchical partitioning",
         subtitle = "Full model explains 20.5% of deviance; independent contributions sum to 19.9%") +
    theme_pub() + theme(legend.position = "bottom", panel.grid.major.y = element_blank(),
                        panel.grid.major.x = element_line(linewidth = 0.25, colour = "grey92"))
} else ggplot() + theme_void()

p10d <- if (!is.null(pr)) {
  pd <- copy(pr); pd[, lab := pretty_term(predictor)]
  setorder(pd, partial_r); pd[, lab := factor(lab, levels = lab)]
  pd[, sig := p_value < 0.05]
  ggplot(pd, aes(partial_r, lab, fill = sig)) +
    geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.35) +
    geom_col(width = 0.6) +
    geom_text(aes(label = sprintf("r = %.2f, P = %.2f", partial_r, p_value)),
              hjust = ifelse(pd$partial_r >= 0, -0.06, 1.06), size = 2.2, colour = "grey25") +
    scale_fill_manual(values = c(`TRUE` = OI[["red"]], `FALSE` = OI[["sky"]]), guide = "none") +
    scale_x_continuous(limits = c(-0.55, 0.75)) +
    labs(x = "Partial correlation with new-record count", y = NULL,
         title = "Partial regression",
         subtitle = "Each predictor against the residuals of a model holding all the others constant") +
    theme_pub() + theme(panel.grid.major.y = element_blank(),
                        panel.grid.major.x = element_line(linewidth = 0.25, colour = "grey92"))
} else ggplot() + theme_void()

F10 <- (p10a | p10b) / (p10c | p10d) + plot_annotation(tag_levels = "a") +
  plot_layout(heights = c(1, 0.95))
save_fig(F10, "Fig10_province_level_v2", 12.0, 8.0,
         src = rbindlist(list(mo, cf, hp, pr), fill = TRUE))
msg("DONE")
