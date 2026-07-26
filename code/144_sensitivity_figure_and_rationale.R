#!/usr/bin/env Rscript
# ============================================================
# Script 144: 窗口与基线敏感性图 + 模型各组件的生态学依据表
# Window/baseline sensitivity figure, and the ecological rationale table
# ============================================================
# 目的 / Objective:
#   (1) 把累积窗口 W 与气候基线期这两个人为选择的敏感性画成图, 并显示
#       它们的影响本身是有生态学解释的, 而不只是"结果稳健"。
#   (2) 把主模型每一个组件(响应、连接函数、风险集、每个固定效应、交互、
#       每个随机项、offset)的生态学依据、含义与可证伪预测写成一张表,
#       供正文与附录直接引用。
#
# Fig7 敏感性 / Sensitivity
#   a  累积变暖 HR vs 窗口长度, 三条基线
#   b  调查努力 HR vs 窗口长度 —— 应当平坦(努力不依赖气候口径)
#   c  交互 HR vs 窗口长度
#   d  各基线内的 dAIC 曲线, 标出最优窗口
#
# Input / 输入:  analysis_v2/tables/tbl_v2_window_baseline_sensitivity.csv
# Output / 输出: analysis_v2/figures/Fig7_window_baseline_sensitivity_v2.*
#                analysis_v2/tables/tbl_v2_ecological_rationale.csv
#                analysis_v2/docs/ECOLOGICAL_RATIONALE.md
#
# Main packages / 主要包: data.table, ggplot2, patchwork, officer, rvg
# 运行 / Run: Rscript --no-init-file code/144_sensitivity_figure_and_rationale.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(patchwork); library(officer); library(rvg)
})
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
FIG <- file.path(OUT, "figures"); TAB <- file.path(OUT, "tables"); DOC <- file.path(OUT, "docs")
dir.create(DOC, showWarnings = FALSE, recursive = TRUE)
msg <- function(...) cat(sprintf("[144 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

OI <- c(blue = "#0072B2", orange = "#E69F00", green = "#009E73", red = "#D55E00",
        purple = "#CC79A7", sky = "#56B4E9", grey = "#999999")
theme_pub <- function(base = 9) theme_classic(base_size = base, base_family = "sans") +
  theme(axis.line = element_line(linewidth = 0.35, colour = "grey20"),
        axis.ticks = element_line(linewidth = 0.3, colour = "grey20"),
        axis.text = element_text(colour = "grey15"), axis.title = element_text(colour = "grey5"),
        panel.grid.major.y = element_line(linewidth = 0.25, colour = "grey92"),
        strip.background = element_blank(), strip.text = element_text(face = "bold", size = base, hjust = 0),
        plot.title = element_text(face = "bold", size = base + 1, hjust = 0),
        plot.subtitle = element_text(size = base - 0.8, colour = "grey30", hjust = 0),
        plot.tag = element_text(face = "bold", size = base + 3), plot.tag.position = c(0.005, 0.985),
        legend.key.size = unit(9, "pt"), legend.text = element_text(size = base - 1),
        legend.title = element_text(size = base - 1, face = "bold"), plot.margin = margin(6, 8, 6, 8))
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

# ==================== Fig 7 ====================
# 窗口 5/10/15/20 x 基线 {1980-2000, 1970-2000}
# 1970-2000 基线只能由 CRU TS 0.5° 给出(WorldClim 降尺度自 1980 起), 故同时
# 拟合 CRU 的 1980-2000, 把"换基线"与"换数据源"拆成两个独立对比。
s <- fread(file.path(TAB, "tbl_v2_baseline_sensitivity.csv"))
s[, base_lab := factor(paste0(fifelse(grepl("WorldClim", source), "WorldClim 10' ", "CRU TS 0.5° "), baseline),
     levels = c("WorldClim 10' 1980-2000", "CRU TS 0.5° 1980-2000", "CRU TS 0.5° 1970-2000"),
     labels = c("WorldClim 10' , 1980-2000 (main)",
                "CRU TS 0.5° , 1980-2000 (source control)",
                "CRU TS 0.5° , 1970-2000 (longer baseline)"))]
COLS <- unname(OI[c("blue", "grey", "green")])
best <- s[, .SD[which.min(AIC)], by = base_lab]

band <- function(lo, hi, y, ylab, ttl, sub, ref = 1) {
  ggplot(s, aes(window, get(y), colour = base_lab, fill = base_lab)) +
    geom_hline(yintercept = ref, linetype = 2, colour = "grey55", linewidth = 0.35) +
    geom_ribbon(aes(ymin = get(lo), ymax = get(hi)), alpha = 0.12, colour = NA) +
    geom_line(linewidth = 0.7) + geom_point(size = 1.4) +
    scale_colour_manual(values = COLS, name = "Climate baseline") +
    scale_fill_manual(values = COLS, guide = "none") +
    scale_x_continuous(breaks = sort(unique(s$window))) +
    labs(x = "Accumulation window W (years)", y = ylab, title = ttl, subtitle = sub) +
    theme_pub()
}

p7a <- band("lo_change", "hi_change", "HR_change", "Hazard ratio per 1 SD",
  "The warming signal is decadal, not annual",
  "Every source and baseline gives the same rise from W = 5 to W = 20") +
  theme(legend.position = c(0.60, 0.18), legend.text = element_text(size = 6.2),
        legend.title = element_text(size = 6.8), legend.key.height = unit(8, "pt"),
        legend.background = element_rect(fill = "white", colour = NA))
p7b <- band("lo_effort", "hi_effort", "HR_effort", "Hazard ratio per 1 SD",
  "The effort coefficient does not care",
  "1.34-1.41 across all twelve combinations, as expected if the two terms are separately identified") +
  theme(legend.position = "none")
p7c <- band("lo_int", "hi_int", "HR_int", "Hazard ratio per 1 SD",
  "The interaction is negative throughout",
  "Warming x effort stays below 1 at every window, source and baseline") +
  theme(legend.position = "none")
p7d <- ggplot(s, aes(window, dAIC, colour = base_lab)) +
  geom_line(linewidth = 0.7) + geom_point(size = 1.4) +
  geom_point(data = best, aes(window, dAIC), size = 3.4, shape = 21, stroke = 0.8, fill = NA) +
  scale_colour_manual(values = COLS, guide = "none") +
  scale_x_continuous(breaks = sort(unique(s$window))) +
  labs(x = "Accumulation window W (years)", y = "Delta AIC within series",
       title = "All three series select a 15-20 year window",
       subtitle = paste("Circles mark the AIC optimum; W = 15 is within 2.2-5.6 units of it in every series.",
                        "\nA finer grid (3-23 yr, Extended Data Table 2) places the optimum at 18-20 yr and shows AIC rising again by 23 yr,",
                        "\nso the optimum is interior rather than an artefact of stopping at 20.")) +
  theme_pub()

F7 <- (p7a | p7b) / (p7c | p7d) + plot_annotation(tag_levels = "a")
save_fig(F7, "Fig7_window_baseline_sensitivity_v2", 11.2, 7.4, src = s)

# ==================== 生态学依据表 ====================
R <- function(component, spec, rationale, reading, prediction)
  data.table(component = component, specification = spec,
             ecological_rationale = rationale, interpretation = reading,
             falsifiable_prediction = prediction)

rat <- rbindlist(list(
R("Response", "event = 1 in the year a species is first formally recorded in a province, 0 before",
  "A new provincial record is a one-off transition: a species-province pair can acquire its first record only once. Modelling it as a repeated binary outcome would treat re-documentation as new information, which it is not.",
  "The quantity modelled is the annual probability that a species crosses from undocumented to documented in a province.",
  "If records were re-documentations rather than first records, event years would cluster after the first, not before."),

R("Link function", "complementary log-log",
  "cloglog is the discrete-time analogue of a continuous proportional-hazards model: the coefficients are hazard ratios and do not depend on the length of the time step. Logit coefficients would change if the panel were monthly rather than annual.",
  "exp(beta) is a hazard ratio per one standard deviation, directly comparable with survival-analysis literature.",
  "Refitting on a coarser time step should leave cloglog coefficients approximately unchanged but shift logit ones."),

R("Risk set", "species x province x year, absorbing exit after the first record; pairs recorded before 2002 removed",
  "Only species whose modelled range is close enough to a province can plausibly be recorded there, so the denominator is the set of ecologically plausible opportunities rather than all species. A pair already recorded before the window is a prevalent, not an incident, case and is not at risk.",
  "The hazard is conditional on being a plausible candidate that has not yet been recorded.",
  "Tightening the candidate pool from a 50 km to a 200 km buffer should change the denominator but not the coefficients."),

R("Accumulated warming (clim_change)", "trailing W = 15 year mean of x, where x = province anomaly - species-range anomaly, both relative to 1980-2000",
  "Range boundaries integrate climate over years to decades: a boundary shifts when conditions have been favourable long enough for colonisation and establishment, not because one year was warm. Referencing to the species' own range is essential because absolute warming is near-uniform across China and therefore cannot explain which species should appear where.",
  "HR 1.362 per 0.179 degC: a province that has warmed 0.18 degC more than a species' own historical range has 36% higher annual hazard for that species.",
  "The coefficient should strengthen as W lengthens from 3 to about 15-20 years and then plateau; a purely weather-driven process would show the opposite."),

R("Annual variability (clim_var)", "x minus its trailing mean, the same year's residual",
  "Separates the decadal signal from year-to-year weather. Included so that the accumulated term cannot absorb a weather effect, and so that a weather effect, if present, is visible.",
  "HR 0.995, P = 0.92: weather in the year of discovery adds nothing once decadal warming is accounted for.",
  "If new records were driven by irruptions or cold snaps, this term would be non-null and the accumulated term would weaken."),

R("Survey effort (effort_z)", "log1p of annual provincial visits, standardised; coverage gaps treated as missing",
  "A species can only be recorded where someone is looking. Effort is the observation-process counterpart of the ecological process and must be in the model for the climate coefficient to be interpretable.",
  "HR 1.404 per 1 SD; one SD multiplies annual visits by 7.75.",
  "Substituting observers, birding days or records for visits should give a similar coefficient if all four index the same latent effort."),

R("Warming x effort", "product of the two standardised terms",
  "Two non-exclusive mechanisms predict a negative interaction. Ecologically, sparsely surveyed provinces are disproportionately western and montane, where climatic gradients are steep. Observationally, densely surveyed provinces have already absorbed much of their Wallacean shortfall, so few candidate species remain regardless of climate.",
  "HR 0.849: the marginal effect of warming is steepest where effort is low and flattens where coverage is dense.",
  "If the observational mechanism dominates, the marginal return of effort should also decline through time as gaps are filled - which it does (P = 7.7e-4)."),

R("Offset log c(t)", "log of the share of year-t discoveries expected to have been published by 2025",
  "Records enter the compilation only after publication, so recent years are systematically under-represented. Under incomplete reporting the observed hazard is approximately c(t) times the true hazard, and because the link is logarithmic in the hazard this is exactly an offset rather than an approximation.",
  "Corrects the estimated hazard for right-censoring without consuming a degree of freedom.",
  "Omitting the offset should attenuate the effort coefficient, since censoring is concentrated in the high-effort recent years - and it does (1.372 to 1.245)."),

R("Random intercept: species", "(1|species), SD 0.405",
  "Species differ in intrinsic detectability for reasons the fixed effects do not capture: body size, song conspicuousness, habitat accessibility, population density and taxonomic attention.",
  "One SD multiplies the hazard by 1.50; the fitted species span a 3.7-fold range.",
  "Conspicuous, vocal, open-habitat species should sit at the upper end."),

R("Random intercept: province", "(1|province), SD 0.326",
  "Provinces differ in their baseline setting for discovery: area, terrain complexity, habitat diversity, observer population and regional research tradition.",
  "One SD multiplies the hazard by 1.39.",
  "Large, topographically complex provinces with active birding communities should sit at the upper end."),

R("Random intercept: province x year", "(1|province:year), SD 0.804",
  "The observation process operates at the level of a particular region in a particular year: regional survey campaigns, provincial birding festivals, newly established protected areas, and local reporting channels. A model with only species and province intercepts cannot absorb this, so it leaks into whichever fixed effect trends with observational capacity.",
  "The single largest variance component. One SD multiplies the hazard by 2.23, more than either fixed effect; the fitted levels span a 13-fold range.",
  "Adding this level should raise conditional discrimination sharply while leaving fixed-effect discrimination unchanged - conditional AUC rises 0.721 to 0.854 while marginal AUC stays at 0.612."),

R("Climate baseline", "1980-2000 at both the province and the species-range end",
  "The baseline defines the climate a species is historically accustomed to and the climate a province historically had. It must end before the analysis period, otherwise part of the warming being tested is written into the reference itself.",
  "Anomalies are measured against the most recent complete period that does not overlap 2002-2024.",
  "Baselines that overlap the study period should attenuate the climate coefficient - and they do: 1.362 (1980-2000), 1.289 (1981-2010), 1.231 (1991-2020).")))

fwrite(rat, file.path(TAB, "tbl_v2_ecological_rationale.csv"))

md <- c("# Ecological rationale for every model component",
        "",
        "This table states, for each element of the main model, why it is there (ecological or",
        "observational rationale), what its estimate means in plain terms, and one falsifiable",
        "prediction that the specification implies. The predictions are all tested in the paper.",
        "",
        "Main model:",
        "",
        "```",
        "event ~ clim_change_z * effort_z + clim_var_z + offset(log c_t)",
        "        + (1|species) + (1|province) + (1|province:year)",
        "family = binomial(\"cloglog\")",
        "```",
        "")
for (i in seq_len(nrow(rat)))
  md <- c(md, sprintf("## %s", rat$component[i]), "",
          sprintf("**Specification.** %s", rat$specification[i]), "",
          sprintf("**Why it is in the model.** %s", rat$ecological_rationale[i]), "",
          sprintf("**What the estimate means.** %s", rat$interpretation[i]), "",
          sprintf("**Falsifiable prediction.** %s", rat$falsifiable_prediction[i]), "")
writeLines(md, file.path(DOC, "ECOLOGICAL_RATIONALE.md"))
msg("wrote tbl_v2_ecological_rationale.csv (", nrow(rat), " components) and ECOLOGICAL_RATIONALE.md")
msg("DONE")
