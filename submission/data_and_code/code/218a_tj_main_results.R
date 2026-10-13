#!/usr/bin/env Rscript
# ============================================================
# Script 218a: 顶刊版主结果图与规格稳健性图
# Top-journal redesign: main-results and specification-robustness figures
# ============================================================
# Scientific question / 科学问题:
#   调查努力与"相对于物种历史分布区的累积增温"是否以相当的强度共同决定某物种
#   在某省被首次记录(新分布记录)的年风险? 该结论是否独立于 SDM 阈值、气候指标、
#   累积窗口、努力代理与缺失值处理等分析选择?
#   Do survey effort and accumulated warming relative to a species' historical range
#   contribute comparably to the annual hazard of a new provincial record, and is the
#   conclusion independent of SDM threshold, climate indicator, accumulation window,
#   effort proxy and missing-data rule?
#
# Objective / 分析目标:
#   只重做 139 号脚本中 Fig1 与 Fig3 的视觉设计(Nature 双栏 183 mm), 科学内容与每个
#   绘图数值保持不变; 数据准备代码自 139 原样复制, 不重新拟合任何模型。
#   Redesign only the visuals of Fig1 and Fig3 of script 139 at Nature double-column
#   width; content and every plotted number unchanged; data preparation copied verbatim
#   from 139; no model is refitted.
#
# Input data / 输入数据:
#   analysis_v2/tables/tbl_v2_C_threshold.csv, tbl_v2_E_importance.csv, tbl_v2_D_ladder.csv,
#     tbl_v2_indicator_window.csv, tbl_v2_B_effort.csv
#   analysis_v2/data/fit_R3.rds(冻结主模型 / frozen main model), model_v2_thr50.parquet,
#     components_v2_tavg_annual_W15.parquet(边际预测的协变量分布 / covariates for predictions)
#   analysis_v2/figures/source_data_Fig{1,3}_*_v2.csv(仅用于逐值核对 / for verification only)
#
# Main workflow / 主要流程:
#   1. 载入共享主题 218 与 139 的辅助函数 / load the shared theme and the 139 helpers
#   2. Fig1 a–d: 森林图、边际预测、重要性小倍数、判别力阶梯
#      forest plot, marginal predictions, importance small multiples, AUC ladder
#   3. Fig3 a–c: HR 热图、ΔAIC 热图、努力代理 × 缺失规则森林图
#      HR heatmap, ΔAIC heatmap, effort proxy × missing-data rule forest plot
#   4. 导出拼版图、单面板与长格式源数据 / export composites, single panels, long source data
#   5. 与 139 源数据逐值核对, 不一致即中止 / verify against the 139 source data; stop on mismatch
#
# Expected output / 预期输出:
#   TJ_Fig_main_results.{pdf,png,svg}(183 x 125 mm)
#   TJ_Fig_specification_robustness.{pdf,png,svg}(183 x 120 mm)
#   panels/TJ_Fig_*_{a,b,c,d}.{pdf,png,svg}; source_data_TJ_Fig_*.csv
#
# Key assumptions / 关键假设:
#   主模型 = 50 格阈值(fit_R3 / model_v2_thr50)、年均温、15 年窗口、访问次数 + 覆盖缺口规则;
#   95% CI 为 Wald 区间, 由系数与 P 值反解(同 139)。
#   Main model = 50-cell threshold, annual mean T, 15-yr window, visits with the
#   coverage-gap rule; 95% Wald CIs recovered from coefficient and P value (as in 139).
#
# Main packages / 主要包: data.table, arrow, glmmTMB, ggplot2, patchwork, scales, colorspace
# Output directory / 输出路径: analysis_v2/figures_topjournal/(单面板在 panels/ / panels in panels/)
# Run / 运行: Rscript --no-init-file code/218a_tj_main_results.R(工作目录 = 任务根 / cwd = task root)
# ============================================================

source("code/218_theme_topjournal.R")
suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)
grDevices::pdf(NULL)   # 空设备: 避免在工作目录生成 Rplots.pdf / null device, no stray Rplots.pdf

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
TAB <- file.path(OUT, "tables"); FIG <- file.path(OUT, "figures")
msg <- function(...) cat(sprintf("[218a %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

# ---------- 139 辅助函数(原样复制)/ helpers copied verbatim from 139 ----------
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

# ---------- 设计层辅助 / design-layer helpers ----------
# 显示用的符号(避免源文件编码问题)/ display glyphs as escapes, encoding-safe
TIMES <- "×"; NDASH <- "–"
disp  <- function(x) sub(" x ", paste0(" ", TIMES, " "), x, fixed = TRUE)   # "x" -> "×"
# 轴标签: 最长的项名折为两行, 给数据区让出宽度 / axis labels: wrap the longest term name
axis_lab <- function(x) sub("Annual climate variability", "Annual climate\nvariability", disp(x), fixed = TRUE)
# tint() 对 amount 不向量化(矩阵按列回收), 逐元素调用 / tint() is not vectorised over amount
tint_v <- function(cols, amts) unname(mapply(tint, cols, amts))
# 四项在所有面板中的统一顺序(自上而下)/ one term order, top to bottom, for every panel
TERM_ORDER <- names(TERM_COL)
TERM_Y     <- setNames(rev(seq_along(TERM_ORDER)), TERM_ORDER)
# 森林图与棒棒糖图不需要 y 轴线 / forest and lollipop panels drop the y axis line
no_y_axis <- theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())
T6 <- pt2mm(6); T55 <- pt2mm(5.5)

# ==========================================================================
# Fig 1  主结果 / main results
# ==========================================================================
C <- rd("tbl_v2_C_threshold.csv"); E <- rd("tbl_v2_E_importance.csv"); D <- rd("tbl_v2_D_ladder.csv")

# ---- (a) 系数森林图 x 三档阈值 / coefficients at three SDM thresholds ----
# 阈值是【省内适宜 SDM 栅格数】的下限; 主模型为 50 格(fit_R3 即 model_v2_thr50)。
# Threshold = minimum number of suitable SDM cells per province; the main model is 50 cells.
C[, threshold := paste0(threshold_km, " cells")]
fa <- forest_rows(C, names(TERM_LAB), "threshold")
# 主阈值用该项语义色, 敏感性阈值依次变浅; 主估计置于每组最上方
# Main threshold in the term's full colour, sensitivity thresholds progressively lighter, main on top
THR <- data.table(threshold = c("50 cells", "100 cells", "200 cells"),
                  off = c(0.25, 0, -0.25), amt = c(0, 0.30, 0.55))
fa <- merge(fa, THR, by = "threshold", sort = FALSE)
fa[, `:=`(y = TERM_Y[term] + off, col = tint_v(TERM_COL[term], amt))]
fa_main <- fa[threshold == "50 cells"]
# 阈值直接标注在最上一组左侧(文字比线略深以保证可读)/ direct labels on the top group
fa_lab  <- fa[term == "Survey effort"][, txt := tint_v(TERM_COL[term], amt * 0.7)]

p1a <- ggplot(fa) +
  geom_vline(xintercept = 1, linetype = "22", colour = TJ$neutral, linewidth = 0.25) +
  geom_segment(aes(x = lo, xend = hi, y = y, yend = y, colour = col), linewidth = 0.4) +
  geom_point(aes(HR, y, colour = col), size = 1.3) +
  geom_text(data = fa_lab, aes(lo / 1.015, y, label = threshold, colour = txt),
            hjust = 1, size = T55) +
  # 主阈值估计值列于右侧 / main-threshold estimate printed at the right
  geom_text(data = fa_main, aes(1.79, y, label = sprintf("%.2f", HR), colour = col),
            hjust = 1, size = T6) +
  scale_colour_identity() +
  scale_x_continuous(transform = "log", breaks = c(0.8, 0.9, 1, 1.2, 1.4, 1.6),
                     labels = label_number(accuracy = 0.1)) +
  scale_y_continuous(breaks = TERM_Y, labels = axis_lab(names(TERM_Y))) +
  # coord 的 expand = FALSE 会覆盖刻度扩展, 故显式给出 y 范围 / explicit ylim, coord ignores scale expansion
  coord_cartesian(xlim = c(0.74, 1.80), ylim = c(0.48, 4.52), expand = FALSE) +
  guides(x = guide_axis(cap = "upper")) +
  labs(x = "Hazard ratio per 1 SD (95% CI)", y = NULL,
       title = "Effort and warming contribute comparably") +
  theme_tj(grid = "x") + no_y_axis

# ---- (b) 交互: 不同努力水平下累积变暖的边际风险(139 原样)/ marginal predictions, verbatim ----
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
rm(m, dm, cc); invisible(gc())

# 设计层: 努力三档用蓝色单色阶(浅→深), 右端直接标注并以细引线错开
# Design: effort levels as a light-to-dark blue ramp; right-end labels fanned out with leader lines
EFF_COL <- setNames(c(tint(TJ$effort, 0.50), TJ$effort, colorspace::darken(TJ$effort, 0.30)),
                    levels(grid$eff_lab))
ends <- grid[, .SD[which.max(clim_change_z)], by = eff_lab]
ends[, `:=`(lab = c("Low effort\n(10th pct)", "Median\neffort", "High effort\n(90th pct)")[as.integer(eff_lab)],
            y_lab = 100 * haz + c(-0.105, 0, 0.105)[as.integer(eff_lab)],
            x_end = clim_change_z, x_lab = clim_change_z + 0.32)]
XB <- c(min(grid$clim_change_z) - 0.08, max(grid$clim_change_z) + 1.30)
int_main <- fa_main[term == "Warming x effort"]
int_txt  <- sprintf("Warming %s effort: HR %.2f (%.2f%s%.2f)", TIMES, int_main$HR, int_main$lo, NDASH, int_main$hi)

p1b <- ggplot(grid, aes(clim_change_z, 100 * haz)) +
  geom_ribbon(aes(ymin = 100 * lo, ymax = 100 * hi, fill = eff_lab), alpha = 0.15, colour = NA) +
  geom_line(aes(colour = eff_lab), linewidth = 0.5) +
  geom_segment(data = ends, aes(x = x_end + 0.06, xend = x_lab - 0.05, y = 100 * haz, yend = y_lab,
                                colour = eff_lab), linewidth = 0.25) +
  geom_text(data = ends, aes(x_lab, y_lab, label = lab, colour = eff_lab),
            hjust = 0, lineheight = 0.9, size = T6) +
  annotate("text", x = XB[1] + 0.08, y = 0.70, label = int_txt, hjust = 0, vjust = 1,
           size = T6, colour = TJ$interaction) +
  scale_colour_manual(values = EFF_COL, guide = "none") +
  scale_fill_manual(values = EFF_COL, guide = "none") +
  scale_x_continuous(breaks = -2:2, labels = c("−2", "−1", "0", "1", "2")) +
  scale_y_continuous(breaks = seq(0, 0.6, 0.2), labels = label_number(drop0trailing = TRUE)) +
  coord_cartesian(xlim = XB, ylim = c(0, 0.72), expand = FALSE) +
  guides(x = guide_axis(cap = "upper")) +
  labs(x = "Accumulated warming relative to the species' range (z)",
       y = "Annual hazard of a new record (%)",
       title = "Warming matters most where effort is low") +
  theme_tj() +
  # x 轴标题居中于数据区而非标注区 / centre the x title over the data, not the label zone
  theme(axis.title.x = element_text(hjust = (mean(range(grid$clim_change_z)) - XB[1]) / diff(XB)))

# ---- (c) 相对重要性: 四准则小倍数棒棒糖图 / importance criteria as small-multiple lollipops ----
imp <- melt(E[, .(term, dAIC, dAUCm, dR2c, abs_beta)], id.vars = "term")
imp[, variable := factor(variable, levels = c("dAIC", "dAUCm", "dR2c", "abs_beta"),
    labels = c("ΔAIC", "ΔAUC", "ΔR²", "|β|"))]
# 重要性表的项名映射到统一项名 / map importance-table names onto the shared term names
IMP_TERM <- c("survey effort" = "Survey effort", "accumulated warming" = "Accumulated warming",
              "annual variability" = "Annual climate variability", "climate x effort" = "Warming x effort")
imp[, `:=`(term_std = IMP_TERM[term], y = TERM_Y[IMP_TERM[term]])]
# 每个小面板只标 0 与不超过上限的最大"整"值, 避免窄面板刻度拥挤
# Two labelled ticks per facet (0 and the largest nice value inside the limits): narrow facets
two_ticks <- function(lims) {
  k <- 10^floor(log10(lims[2])); nice <- c(1, 2, 2.5, 3, 4, 5) * k
  c(0, max(nice[nice <= lims[2]]))
}

p1c <- ggplot(imp, aes(y = y)) +
  geom_vline(xintercept = 0, colour = TJ$rule, linewidth = 0.25) +
  geom_segment(aes(x = 0, xend = value, yend = y, colour = term_std), linewidth = 0.5) +
  geom_point(aes(x = value, colour = term_std), size = 1.5) +
  facet_wrap(~variable, nrow = 1, scales = "free_x") +
  scale_colour_manual(values = TERM_COL, guide = "none") +
  scale_x_continuous(breaks = two_ticks, labels = label_number(drop0trailing = TRUE),
                     expand = expansion(mult = 0.14)) +
  scale_y_continuous(breaks = TERM_Y, labels = axis_lab(names(TERM_Y)), expand = expansion(add = 0.5)) +
  labs(x = "Loss when the term is dropped from the full model", y = NULL,
       title = "Warming and effort matter equally") +
  theme_tj() + no_y_axis + theme(panel.spacing.x = unit(9, "pt"))

# ---- (d) 判别力阶梯 / AUC ladder ----
D2 <- copy(D)[, lab := sub("^F[0-9] ", "", model)]
D2[, lab := factor(lab, levels = D2$lab)]
# 类别标签: 句首大写、两行换行, "climate" 即累积增温项 clim_change_z, 与全图统一称 warming
# Category labels: sentence case, wrapped; "climate" is clim_change_z, named "warming" as elsewhere
LADDER_LAB <- c("null" = "Null", "effort" = "Effort", "climate" = "Warming",
                "effort + climate" = "Effort +\nwarming", "+ annual variability" = "+ Annual\nvariability",
                "+ interaction (MAIN)" = paste0("+ Warming ", TIMES, "\neffort (main)"))
D2[, `:=`(x = seq_len(.N), main = grepl("MAIN", model))]

p1d <- ggplot(D2, aes(x, AUC_marginal)) +
  annotate("rect", xmin = 5.55, xmax = 6.45, ymin = -Inf, ymax = Inf, fill = TJ$band) +
  geom_hline(yintercept = 0.5, linetype = "22", colour = TJ$neutral, linewidth = 0.25) +
  annotate("text", x = 0.6, y = 0.5, label = "Chance", hjust = 0, vjust = -0.5,
           size = T55, colour = TJ$subink) +
  geom_line(colour = TJ$neutral, linewidth = 0.5) +
  geom_point(aes(size = main, colour = main)) +
  geom_text(aes(label = sprintf("%.3f", AUC_marginal), colour = main,
                fontface = ifelse(main, "bold", "plain")), vjust = -1.0, size = T6) +
  scale_size_manual(values = c(`FALSE` = 1.4, `TRUE` = 2.0), guide = "none") +
  scale_colour_manual(values = c(`FALSE` = TJ$subink, `TRUE` = TJ$ink), guide = "none") +
  scale_x_continuous(breaks = D2$x, labels = unname(LADDER_LAB[as.character(D2$lab)])) +
  scale_y_continuous(breaks = seq(0.4, 0.6, 0.1), labels = label_number(accuracy = 0.1)) +
  coord_cartesian(xlim = c(0.5, 6.5), ylim = c(0.38, 0.68), expand = FALSE) +
  labs(x = NULL, y = "AUC from fixed effects only", title = "Neither factor alone is sufficient") +
  theme_tj() + theme(axis.text.x = element_text(lineheight = 0.9, vjust = 1))

# ---- 拼版与导出 / assemble and export ----
# free(type = "label"): c 的 x 轴标题紧贴自身刻度, 不与 d 的两行类别标签对齐
# free(type = "label") keeps c's x title next to its own ticks instead of aligning with d's two-line labels
F1 <- p1a + p1b + free(p1c, type = "label", side = "b") + p1d +
  plot_layout(design = "AB\nCD", widths = c(1, 1), heights = c(1, 0.92)) + tj_tags()
H1 <- 125
tj_save(F1, "TJ_Fig_main_results", 183, H1)
tj_panel(p1a, "TJ_Fig_main_results_a", 110, 72)
tj_panel(p1b, "TJ_Fig_main_results_b", 110, 75)
tj_panel(p1c, "TJ_Fig_main_results_c", 120, 62)
tj_panel(p1d, "TJ_Fig_main_results_d", 100, 70)

src1 <- rbindlist(list(
  fa[, .(panel = "a", term = disp(term), group = threshold, estimate = HR, lo, hi,
         unit = "hazard ratio per 1 SD", main_spec = threshold == "50 cells")],
  grid[, .(panel = "b", term = "annual hazard of a new record", group = as.character(eff_lab),
           x_var = "clim_change_z", x = clim_change_z, effort_z, estimate = 100 * haz,
           lo = 100 * lo, hi = 100 * hi, unit = "per cent")],
  imp[, .(panel = "c", term = disp(term_std), group = as.character(variable), estimate = value,
          unit = "loss when the term is dropped (|beta|: absolute standardised coefficient)")],
  D2[, .(panel = "d", term = model, group = "AUC_marginal", estimate = AUC_marginal,
         unit = "AUC from fixed effects only", main_spec = main)]
), fill = TRUE)
tj_source(src1, "TJ_Fig_main_results")

# ==========================================================================
# Fig 3  规格稳健性 / specification robustness
# ==========================================================================
IW <- rd("tbl_v2_indicator_window.csv"); B <- rd("tbl_v2_B_effort.csv")
IW[, ind_lab := factor(indicator,
    levels = c("tavg_annual", "tmax_warm", "tmin_cold", "tavg_winter"),
    labels = c("Annual mean T", "Warmest-month Tmax", "Coldest-month Tmin", "Winter mean T"))]
IW[, star := fifelse(P_change < 0.001, "***", fifelse(P_change < 0.01, "**",
              fifelse(P_change < 0.05, "*", "")))]
# 主指标置顶 / main indicator on top
IW[, ind_y := factor(ind_lab, levels = rev(levels(ind_lab)))]
main_cell <- IW[indicator == "tavg_annual" & window == 15]

# 按底色亮度选择白字或墨字 / white or ink text by fill luminance
lum <- function(cols) {
  m <- grDevices::col2rgb(cols) / 255
  m <- ifelse(m <= 0.03928, m / 12.92, ((m + 0.055) / 1.055)^2.4)
  as.numeric(c(0.2126, 0.7152, 0.0722) %*% m)
}
txt_on <- function(pal, v) ifelse(lum(pal(v)) < 0.30, "white", TJ$ink)

# 热图共用主题: 无轴线、色条置顶右侧 / shared heatmap theme: no axis lines, colour bar top right
theme_heat <- theme_tj() + theme(
  axis.line = element_blank(), axis.ticks = element_blank(),
  legend.position = "top", legend.justification = c(1, 0), legend.direction = "horizontal",
  # ggplot2 >= 3.5 中横向色条长度 = 5 x legend.key.width / bar length is 5 x key width
  legend.title.position = "left", legend.key.width = unit(3.6, "mm"), legend.key.height = unit(1.8, "mm"),
  legend.title = element_text(size = 6, vjust = 1, margin = margin(r = 4)), legend.box.spacing = unit(2, "pt"),
  legend.margin = margin(0, 0, 0, 0))
heat_base <- function(d) {
  ggplot(d, aes(factor(window), ind_y)) +
    scale_x_discrete(expand = c(0, 0)) + scale_y_discrete(expand = c(0, 0)) +
    labs(x = "Accumulation window (years)", y = NULL) + theme_heat
}
# 主规格外框(内缩, 不压白色格线)/ main-specification outline, inset from the white grid
main_box <- function() geom_tile(data = main_cell, fill = NA, colour = TJ$ink, linewidth = 0.45,
                                 width = 0.95, height = 0.93)

# ---- (a) HR 热图: 增温单色阶 / HR heatmap, warming single-hue ramp ----
HR_LIM <- c(0.95, 1.40)
hr_pal <- col_numeric(tj_ramp(TJ$warming, 7), domain = HR_LIM)
IW[, txt_hr := txt_on(hr_pal, HR_change)]
p3a <- heat_base(IW) +
  geom_tile(aes(fill = HR_change), colour = "white", linewidth = 0.6) + main_box() +
  geom_text(aes(label = sprintf("%.2f%s", HR_change, star), colour = txt_hr), size = T6) +
  scale_colour_identity() +
  scale_fill_gradientn(colours = tj_ramp(TJ$warming, 7), limits = HR_LIM,
                       breaks = c(1, 1.2, 1.4), name = "HR") +
  labs(title = "Signal is strongest for annual mean T",
       caption = "*P < 0.05; **P < 0.01; ***P < 0.001") +
  theme(plot.caption = element_text(hjust = 1, size = 5.5, colour = TJ$subink, margin = margin(t = 2)))

# ---- (b) ΔAIC 热图: 中性灰单色阶, 越深越好 / ΔAIC heatmap, neutral ramp, darker = better ----
AIC_LIM <- c(0, 34)
aic_pal <- col_numeric(rev(tj_ramp(TJ$neutral, 7)), domain = AIC_LIM)
IW[, txt_aic := txt_on(aic_pal, dAIC)]
p3b <- heat_base(IW) +
  geom_tile(aes(fill = dAIC), colour = "white", linewidth = 0.6) + main_box() +
  geom_text(aes(label = sprintf("%.0f", dAIC), colour = txt_aic), size = T6) +
  scale_colour_identity() +
  scale_fill_gradientn(colours = rev(tj_ramp(TJ$neutral, 7)), limits = AIC_LIM,
                       breaks = c(0, 10, 20, 30), name = "ΔAIC") +
  labs(title = "Annual mean T fits best")

# ---- (c) 努力代理 x 缺失规则(139 原样)/ effort proxy x missing-data rule, verbatim ----
fb <- forest_rows(B, c("b_effort", "b_change"), c("proxy", "treatment"))
fb[, treatment := factor(treatment, levels = c("gap", "imp", "zero"),
    labels = c("coverage gap (main)", "bounded imputation", "zero-filled (v1)"))]
fb[, proxy := factor(proxy, levels = c("visits", "observers", "days", "record"),
    labels = c("Visits", "Observers", "Birding days", "Records"))]
# 设计层: 按系数分面; 主规则用该系数语义色, 其余规则用灰色; 主规则置于每组最上方
# Design: facet by coefficient; main rule in the coefficient's colour, others grey, main on top
RULE <- data.table(treatment = levels(fb$treatment), off = c(0.25, 0, -0.25),
                   grey = c(NA, "#6E6E6E", "#A8A8A8"),
                   lab = c("Coverage gap (main)", "Bounded imputation", "Zero-filled (v1)"))
fb <- merge(fb, RULE, by = "treatment", sort = FALSE)
fb[, `:=`(coef = factor(term, levels = c("Accumulated warming", "Survey effort")),
          y = (5 - as.integer(proxy)) + off)]
fb[, col := fifelse(is.na(grey), TERM_COL[term], grey)]
# 标注文字比浅灰线略深, 保证 5.5 pt 可读 / label text a touch darker than the light-grey line
fb_lab <- fb[coef == "Accumulated warming" & proxy == "Visits"][, txt := fifelse(col == "#A8A8A8", "#8C8C8C", col)]

p3c <- ggplot(fb) +
  geom_vline(xintercept = 1, linetype = "22", colour = TJ$neutral, linewidth = 0.25) +
  geom_segment(aes(x = lo, xend = hi, y = y, yend = y, colour = col), linewidth = 0.4) +
  geom_point(aes(HR, y, colour = col), size = 1.3) +
  geom_text(data = fb_lab, aes(hi + 0.012, y, label = lab, colour = txt), hjust = 0, size = T55) +
  facet_wrap(~coef, nrow = 1) +
  scale_colour_identity() +
  scale_x_continuous(breaks = seq(1, 1.6, 0.2), labels = label_number(accuracy = 0.1)) +
  scale_y_continuous(breaks = 4:1, labels = levels(fb$proxy)) +
  coord_cartesian(xlim = c(0.96, 1.76), ylim = c(0.48, 4.52), expand = FALSE) +
  labs(x = "Hazard ratio per 1 SD (95% CI)", y = NULL,
       title = "Robust to effort proxy and missing-data rule") +
  theme_tj(grid = "x") + no_y_axis + theme(panel.spacing.x = unit(12, "pt"))

# ---- 拼版与导出 / assemble and export ----
# 拼版中 b 与 a 共用行标签, 故去掉 b 的 y 轴文字; 单面板导出保留
# In the composite b shares a's row labels, so b's y text is dropped; the panel export keeps it
F3 <- p3a + (p3b + theme(axis.text.y = element_blank())) + p3c +
  plot_layout(design = "AB\nCC", heights = c(1, 1.12)) + tj_tags()
H3 <- 120
tj_save(F3, "TJ_Fig_specification_robustness", 183, H3)
tj_panel(p3a, "TJ_Fig_specification_robustness_a", 100, 68)
tj_panel(p3b, "TJ_Fig_specification_robustness_b", 100, 68)
tj_panel(p3c, "TJ_Fig_specification_robustness_c", 160, 75)

src3 <- rbindlist(list(
  IW[, .(panel = "a", term = as.character(ind_lab), indicator, window, estimate = HR_change,
         p_value = P_change, label = star, unit = "hazard ratio per 1 SD, accumulated warming",
         main_spec = indicator == "tavg_annual" & window == 15)],
  IW[, .(panel = "b", term = as.character(ind_lab), indicator, window, estimate = dAIC,
         unit = "delta AIC relative to the best cell", main_spec = indicator == "tavg_annual" & window == 15)],
  fb[, .(panel = "c", term, group = as.character(treatment), proxy = as.character(proxy),
         estimate = HR, lo, hi, unit = "hazard ratio per 1 SD",
         main_spec = treatment == "coverage gap (main)" & proxy == "Visits")]
), fill = TRUE)
tj_source(src3, "TJ_Fig_specification_robustness")

# ==========================================================================
# 核对: 与 139 源数据逐值比较, 任何差异即中止 / verify against 139 source data, stop on any mismatch
# ==========================================================================
tol <- 1e-9
o1 <- fread(file.path(FIG, "source_data_Fig1_main_results_v2.csv"))
ka <- merge(o1[panel == "a"], fa[, .(term, group = threshold, HR2 = HR, lo2 = lo, hi2 = hi)],
            by = c("term", "group"))
stopifnot(nrow(ka) == 12, max(abs(ka$HR - ka$HR2), abs(ka$lo - ka$lo2), abs(ka$hi - ka$hi2)) < tol)
ob <- o1[panel == "b"]
stopifnot(nrow(ob) == nrow(grid), all(ob$group == as.character(grid$eff_lab)),
          max(abs(ob$HR - grid$haz), abs(ob$lo - grid$lo), abs(ob$hi - grid$hi)) < 1e-12)
o3 <- fread(file.path(FIG, "source_data_Fig3_specification_robustness_v2.csv"))
k3 <- merge(o3[!is.na(indicator) & indicator != ""], IW[, .(indicator, window, HR2 = HR_change,
            d2 = dAIC, s2 = star)], by = c("indicator", "window"))
stopifnot(nrow(k3) == 16, max(abs(k3$HR_change - k3$HR2), abs(k3$dAIC - k3$d2)) < tol,
          all(fifelse(is.na(k3$star), "", k3$star) == k3$s2))
oB <- forest_rows(o3[!is.na(proxy) & proxy != ""], c("b_effort", "b_change"), c("proxy", "treatment"))
kc <- merge(oB[, .(proxy, treatment = as.character(treatment), term, HR, lo, hi)],
            fb[, .(proxy = c("visits", "observers", "days", "record")[as.integer(proxy)],
                   treatment = c("gap", "imp", "zero")[as.integer(factor(treatment, levels = RULE$treatment))],
                   term, HR2 = HR, lo2 = lo, hi2 = hi)], by = c("proxy", "treatment", "term"))
stopifnot(nrow(kc) == 24, max(abs(kc$HR - kc$HR2), abs(kc$lo - kc$lo2), abs(kc$hi - kc$hi2)) < tol)
msg("verified: Fig1 a (12), b (", nrow(grid), "), Fig3 a/b (16), c (24) identical to 139 source data")
msg("TJ figures written to ", TJ_DIR, " | DONE")
