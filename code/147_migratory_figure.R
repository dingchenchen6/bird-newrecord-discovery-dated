#!/usr/bin/env Rscript
# ============================================================
# Script 147: Fig8 —— 迁徙策略的调节作用
# Fig8: migratory strategy as a moderator
# ============================================================
# 目的 / Objective:
#   把迁徙分层的结果画成图, 并让"哪些结论有统计支持、哪些只是提示"一目了然。
#
# 面板 / Panels:
#   a  各组样本量与事件数(读者需先知道检验力从哪来)
#   b  分层拟合的三个系数, 组间 95% CI 是否重叠
#   c  交互阶梯的 dAIC 与似然比检验 P 值 —— 正式的调节检验
#   d  由三阶交互模型导出的各组 气候x努力 交互
#
# 关键的诚实呈现 / The honest reading this figure must convey:
#   气候与努力效应在三组中都显著且 CI 大幅重叠, 正式的调节检验全部不显著。
#   气候x努力交互看似只集中在长距离候鸟, 但三阶交互的整体检验 P = 0.256,
#   关键对比 P = 0.078 —— 属于提示, 不是已确立的组间差异。
#
# Input / 输入:  analysis_v2/tables/tbl_v2_migratory_{ladder,stratified,interaction_by_group}.csv
# Output / 输出: analysis_v2/figures/Fig8_migratory_strategy_v2.{png,pdf,svg,pptx}
#
# Main packages / 主要包: data.table, ggplot2, patchwork, officer, rvg
# 运行 / Run: Rscript --no-init-file code/147_migratory_figure.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(patchwork); library(officer); library(rvg)
})
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
TAB <- file.path(OUT, "tables"); FIG <- file.path(OUT, "figures")
msg <- function(...) cat(sprintf("[147 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

OI <- c(blue = "#0072B2", orange = "#E69F00", green = "#009E73", red = "#D55E00",
        purple = "#CC79A7", sky = "#56B4E9", grey = "#999999")
GCOL <- c(Resident = OI[["green"]], Partial = OI[["orange"]], `Long-distance` = OI[["blue"]])
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

st  <- fread(file.path(TAB, "tbl_v2_migratory_stratified.csv"))[grouping == "three-level"]
lad <- fread(file.path(TAB, "tbl_v2_migratory_ladder.csv"))
gi  <- fread(file.path(TAB, "tbl_v2_migratory_interaction_by_group.csv"))
LV  <- c("Resident", "Partial", "Long-distance")
st[, group := factor(group, levels = LV)]
gi[, group := factor(group, levels = LV)]

# ---- a 样本量 ----
sz <- melt(st[, .(group, `Risk-set rows (000s)` = n / 1000, Events = events,
                  Species = species)], id.vars = "group")
p8a <- ggplot(sz, aes(group, value, fill = group)) +
  geom_col(width = 0.62) +
  geom_text(aes(label = ifelse(variable == "Risk-set rows (000s)",
                               sprintf("%.0fk", value), sprintf("%.0f", value))),
            vjust = -0.35, size = 2.5, colour = "grey20") +
  facet_wrap(~variable, scales = "free_y", nrow = 1) +
  scale_fill_manual(values = GCOL, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.16))) +
  labs(x = NULL, y = NULL, title = "Power comes from all three groups",
       subtitle = "Every group carries at least 156 events, so none is a token category") +
  theme_pub() + theme(axis.text.x = element_text(angle = 18, hjust = 1),
                      panel.grid.major.y = element_line(linewidth = 0.25, colour = "grey92"))

# ---- b 分层系数 ----
fb <- rbindlist(list(
  st[, .(group, term = "Accumulated warming", HR = HR_change, lo = lo_change, hi = hi_change, P = P_change)],
  st[, .(group, term = "Survey effort",       HR = HR_effort, lo = lo_effort, hi = hi_effort, P = P_effort)]))
fb[, term := factor(term, levels = c("Accumulated warming", "Survey effort"))]
p8b <- ggplot(fb, aes(HR, group, colour = group)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
  geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.6) +
  geom_point(size = 2.1) +
  geom_text(aes(label = sprintf("%.2f", HR)), vjust = -1.0, size = 2.4, colour = "grey20") +
  facet_wrap(~term, nrow = 1) +
  scale_colour_manual(values = GCOL, guide = "none") +
  labs(x = "Hazard ratio per 1 SD (95% CI)", y = NULL,
       title = "Both drivers act in every migratory group",
       subtitle = "Confidence intervals overlap heavily; no group is exempt from either driver") +
  theme_pub() + theme(panel.grid.major.y = element_blank())

# ---- c 调节检验 ----
lc <- copy(lad)[, code := sub(" .*", "", model)]
lc[, code := factor(code, levels = lc$code)]
lc[, lab := ifelse(is.na(LR_P), "", sprintf("P = %.2f", LR_P))]
p8c <- ggplot(lc, aes(code, dAIC, fill = dAIC == 0)) +
  geom_col(width = 0.62) +
  geom_text(aes(label = sprintf("%.1f", dAIC)), vjust = -0.4, size = 2.6, colour = "grey20") +
  geom_text(aes(label = lab), y = 0.6, size = 2.3, colour = OI[["red"]]) +
  scale_fill_manual(values = c(`TRUE` = OI[["blue"]], `FALSE` = OI[["grey"]]), guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.16))) +
  labs(x = NULL, y = "Delta AIC",
       title = "Migratory strategy shifts the baseline, not the slopes",
       subtitle = paste("M0 main model | M1 + migratory main effect | M2 + warming x migratory |",
                        "M3 + effort x migratory\nM4 + both | M5 + three-way warming x effort x migratory.",
                        "Red: likelihood-ratio P against M1")) +
  theme_pub()

# ---- d 各组交互 ----
gi[, sig := P < 0.05]
p8d <- ggplot(gi, aes(HR_int, group, colour = group)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
  geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.6) +
  geom_point(aes(shape = sig), size = 2.3) +
  geom_text(aes(label = sprintf("%.2f (P = %.3f)", HR_int, P)), vjust = -1.0, size = 2.4, colour = "grey20") +
  scale_colour_manual(values = GCOL, guide = "none") +
  scale_shape_manual(values = c(`FALSE` = 1, `TRUE` = 16), guide = "none") +
  labs(x = "Warming x effort hazard ratio (95% CI)", y = NULL,
       title = "A hint, not a result",
       subtitle = paste("The interaction is significant only among long-distance migrants, but the formal test for",
                        "\nheterogeneity is not (three-way LR P = 0.26; long-distance vs resident contrast P = 0.078).",
                        "\nWith 156-218 events per group the design cannot resolve group differences in an interaction.")) +
  theme_pub() + theme(panel.grid.major.y = element_blank())

F8 <- (p8a | p8b) / (p8c | p8d) + plot_annotation(tag_levels = "a")
save_fig(F8, "Fig8_migratory_strategy_v2", 11.4, 7.6,
         src = rbindlist(list(
           st[, .(panel = "b", group, term = "warming", HR = HR_change, lo = lo_change, hi = hi_change, P = P_change)],
           st[, .(panel = "b", group, term = "effort",  HR = HR_effort, lo = lo_effort, hi = hi_effort, P = P_effort)],
           gi[, .(panel = "d", group, term = "warming x effort", HR = HR_int, lo, hi, P)]), fill = TRUE))
msg("DONE")
