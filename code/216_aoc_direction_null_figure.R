#!/usr/bin/env Rscript
# ============================================================
# Script 216: 报告用方位零假设图 / Talk version of the direction-null figure
# ============================================================
# 科学问题 / Scientific question:
#   新纪录方位的「偏东」有多少来自几何(中国相对物种全球分布区的位置)?
#   扣除几何与观测努力后还剩什么? 投影在会场屏幕上要一眼可读。
#   How much of the eastward bias of new records is geometry, and what is
#   left once geometry and survey effort are both accounted for?
#
# 分析目标 / Objective:
#   把脚本 214 的结果画成适合 16:9 幻灯片左栏的两层图(上: 观测份额与两个零假设
#   期望的风玫瑰; 下: 各方位观测/期望比及 95% 蒙特卡洛区间), 字号按投影放大。
#   Two stacked panels sized for a slide's left column, with projection-size text.
#
# 输入数据 / Input: analysis_v2/tables/tbl_v2_direction_geometric_null.csv(脚本 214)
# 主要流程 / Workflow: 读表 → 份额与比值 → 两个面板 → 纵向拼接 → PNG/PDF
# 预期输出 / Output: analysis_v2/figures_aoc/FigAOC_direction_null.{png,pdf}
# 关键假设 / Key assumptions: 与论文主图(脚本 154 的 overall_direction_null)同源同口径,
#   只改版式与字号 / same numbers as the paper figure; layout and type size only
# 主要包 / Packages: data.table, ggplot2, patchwork, scales
# 运行 / Run (任务根目录 / from task root): Rscript --no-init-file code/216_aoc_direction_null_figure.R
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork); library(scales) })
OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
FIG <- file.path(OUT, "figures_aoc"); dir.create(FIG, showWarnings = FALSE)
DIRLV <- c("North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest")
SHORT <- setNames(c("N", "NE", "E", "SE", "S", "SW", "W", "NW"), DIRLV)

gn <- fread(file.path(OUT, "tables", "tbl_v2_direction_geometric_null.csv"))[
  scope == "Overall (records)" & null %in% c("geometric", "geometric_effort")]
stopifnot(nrow(gn) == 16L)                                   # 8 方位 × 2 零假设 / 8 sectors × 2 nulls
NLAB <- c(geometric = "Expected: geography", geometric_effort = "Expected: geography + birders")
NCOL <- c("Observed" = "grey10", "Expected: geography" = "#0072B2", "Expected: geography + birders" = "#D55E00")
NLTY <- c("Observed" = "solid", "Expected: geography" = "22", "Expected: geography + birders" = "12")

# ---- a 份额风玫瑰 / share wind rose ----
shr <- rbind(gn[null == "geometric", .(direction, series = "Observed", share = observed / sum(observed))],
             gn[, .(direction, series = NLAB[null], share = null_mean / sum(null_mean)), by = null][, null := NULL])
shr[, `:=`(direction = factor(direction, levels = DIRLV), series = factor(series, levels = names(NCOL)))]
ym <- 0.45                                   # 几何+努力 的东向期望 41.1% / effort-null East is 41.1%
pa <- ggplot(shr, aes(direction, share, group = series, colour = series, linetype = series)) +
  annotate("segment", x = DIRLV, xend = DIRLV, y = 0, yend = ym, colour = "grey82", linewidth = 0.4) +
  geom_polygon(fill = NA, linewidth = 1.1, key_glyph = "path") +
  geom_point(size = 1.8, show.legend = FALSE) +
  scale_x_discrete(labels = SHORT) +
  scale_colour_manual(values = NCOL) + scale_linetype_manual(values = NLTY) +
  scale_y_continuous(limits = c(0, ym), breaks = c(0.1, 0.2, 0.3, 0.4), labels = percent) +
  coord_polar(start = -pi / 8, clip = "off") +
  labs(x = NULL, y = NULL, colour = NULL, linetype = NULL, title = "a  Share of 642 records by direction") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
        panel.grid.major.y = element_line(colour = "grey85", linewidth = 0.35, linetype = "22"),
        axis.text.y = element_text(size = 10, colour = "grey45"),
        axis.text.x = element_text(size = 13, colour = "grey10", face = "bold"),
        plot.title = element_text(size = 14, face = "bold"),
        legend.position = "right", legend.text = element_text(size = 12),
        legend.key.width = unit(12, "mm"), plot.margin = margin(2, 4, 2, 4))

# ---- b 观测/期望比 / observed-to-expected ratio ----
rt <- gn[, .(null = factor(NLAB[null], levels = NLAB), direction = factor(SHORT[direction], levels = SHORT),
             ratio, lo = null_lo / null_mean, hi = null_hi / null_mean, sig = mc_p_holm < 0.05)]
dg <- position_dodge(width = 0.6)
pb <- ggplot(rt, aes(direction, ratio, colour = null)) +
  geom_hline(yintercept = 1, colour = "grey55", linewidth = 0.5) +
  geom_linerange(aes(ymin = lo, ymax = hi), position = dg, linewidth = 3.6, alpha = 0.25) +
  geom_point(aes(shape = sig), position = dg, size = 3.2, stroke = 0.9, fill = "white") +
  scale_colour_manual(values = NCOL[NLAB], guide = "none") +
  scale_shape_manual(values = c(`FALSE` = 21, `TRUE` = 16),
                     labels = c(`FALSE` = "not significant", `TRUE` = "Holm P < 0.05"), name = NULL) +
  scale_y_continuous(trans = "log2", breaks = c(0.5, 0.75, 1, 1.5, 2), labels = c("0.5", "0.75", "1", "1.5", "2")) +
  labs(x = NULL, y = "Observed / expected", title = "b  Records against each null (bands: 95% null range)") +
  theme_classic(base_size = 13) +
  theme(axis.text = element_text(size = 12, colour = "grey10"), plot.title = element_text(size = 14, face = "bold"),
        legend.position = "top", legend.justification = "right", legend.text = element_text(size = 12),
        legend.margin = margin(0, 0, -6, 0), plot.margin = margin(2, 6, 2, 4))

# wrap_elements: 不按面板对齐, 否则 a 的侧边图例会把 b 的绘图区挤窄
# NB: wrap panels so a's side legend does not narrow b's plotting area
p <- wrap_elements(full = pa) / wrap_elements(full = pb) + plot_layout(heights = c(1.15, 1))
ggsave(file.path(FIG, "FigAOC_direction_null.png"), p, width = 7.4, height = 6.6, dpi = 300, bg = "white")
ggsave(file.path(FIG, "FigAOC_direction_null.pdf"), p, width = 7.4, height = 6.6, device = grDevices::cairo_pdf, bg = "white")
cat("[216] wrote FigAOC_direction_null.{png,pdf}\n")
