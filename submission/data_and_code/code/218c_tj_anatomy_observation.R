#!/usr/bin/env Rscript
# ============================================================
# Script 218c: 顶刊版 —— 模型解剖图与观测过程图
#              Top-journal redesign: model anatomy and observation process
# ------------------------------------------------------------
# Scientific question / 科学问题:
#   主模型的每个参数在生态学与观测过程上意味着什么? 物种参照的增温梯度如何构造,
#   效应在自然单位下有多大, 观测过程(物种、省、省×年随机截距)与两个驱动因子相比有多重要?
#   What does each parameter of the main hazard model mean ecologically and for the
#   observation process: how the species-referenced warming gradient is built, how large
#   the effects are on natural scales, and how the observation process (species, province,
#   province x year intercepts) compares with the two drivers?
#
# Objective / 分析目标:
#   用统一的顶刊视觉规范(脚本 218 主题)重绘原 Fig5 / Fig6(脚本 143)。
#   科学内容与全部绘图数值不变, 只改视觉设计。
#   Redraw the original Fig5 / Fig6 (script 143) in the shared top-journal style
#   (script 218). Scientific content and every plotted number are unchanged.
#
# Input data / 输入数据:
#   analysis_v2/data/{model_v2_thr50.parquet, components_v2_tavg_annual_W15.parquet,
#                     fit_R3.rds, fit_R3_time_varying.rds, effort_panel_v2.csv}
#   analysis_final/data/panel_full_{grid,species}.csv
#   analysis_rebuilt/data/grid_province_lookup.csv
#   data/spatial/basemap_GS2019_1822/ (标准底图, 经 218 主题读取 / via the 218 theme)
#   analysis_v2/figures/source_data_Fig{5,6}_*_v2.csv (仅用于数值核对 / number checks only)
#
# Main workflow / 主要流程:
#   1. 按 143 原样准备数据, 不重拟合模型 / prepare data exactly as 143; no refits
#   2. 绘制模型解剖图 a–d / draw model-anatomy panels a–d
#   3. 绘制观测过程图 a–d / draw observation-process panels a–d
#   4. 与原图源数据逐值核对 / check values against the original source data
#   5. 导出整图、单面板与长格式源数据 / export figures, single panels, long source data
#
# Expected output / 预期输出:
#   TJ_Fig_model_anatomy.{pdf,png,svg}         183 x 132 mm
#   TJ_Fig_observation_process.{pdf,png[,svg]} 183 x 150 mm
#   panels/TJ_Fig_{model_anatomy,observation_process}_{a,b,c,d}.*
#   source_data_TJ_Fig_{model_anatomy,observation_process}.csv
#
# Key assumptions / 关键假设:
#   模型对象与原图相同(fit_R3, fit_R3_time_varying); 倍数色阶取 log2 尺度、以 1 为中性色,
#   上下限与刻度沿用原图(数据范围), 两侧色彩强度对称; 缺失/范围外用比 TJ$na 略深的灰,
#   以免与中性色(≈1)混淆。
#   Same model objects as the original; multiplier colour scales are log2 with 1 as the
#   neutral colour, original limits (data range) and breaks, symmetric colour intensity;
#   missing / out of scope is a grey a shade darker than TJ$na so it never reads as ≈1.
#
# Main packages / 主要包: data.table, arrow, glmmTMB, ggplot2 (>= 3.5), patchwork, sf, ggdist, ggtext
# Output directory / 输出路径: analysis_v2/figures_topjournal/ (+ panels/)
# Run / 运行: Rscript --no-init-file code/218c_tj_anatomy_observation.R  (cwd = task root)
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(ggplot2); library(glmmTMB)
  library(patchwork); library(sf); library(ggdist)
})
options(warn = 1); sf::sf_use_s2(FALSE)
source("code/218_theme_topjournal.R")   # 共享主题 / shared theme (TJ, theme_tj, tj_save ...)
# 全局主题只服务于 tj_china_map() 内部的包装层: 字母样式同 theme_tj, 外边距归零, 使地图标题与 a 对齐;
# 各面板均显式 + theme_tj()
# The global theme only serves the wrapper inside tj_china_map(): tag style as theme_tj, zero outer
# margin so the map title lines up with panel a; every panel adds theme_tj() explicitly
theme_set(theme_tj() + theme(plot.margin = margin(0, 0, 0, 0)))

V2  <- normalizePath(".", mustWork = TRUE)
RB  <- file.path(V2, "analysis_rebuilt"); FN <- file.path(V2, "analysis_final")
OUT <- file.path(V2, "analysis_v2"); FIG0 <- file.path(OUT, "figures")
msg <- function(...) cat(sprintf("[218c %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

# ---------------- 局部样式 / local style helpers ----------------
# 缺失与范围外: 比 TJ$na 深一档, 发散色阶的中性色(#F2F1EE)与 TJ$na 几乎无法区分
# Missing / out of scope: one shade darker than TJ$na, which is nearly identical to the
# neutral midpoint of TJ_DIV (#F2F1EE) and would read as "multiplier ≈ 1"
NA_COL <- "#C2C2BF"
ref_h  <- function(y) geom_hline(yintercept = y, linetype = 2, colour = TJ$neutral, linewidth = 0.25)
ref_v  <- function(x) geom_vline(xintercept = x, linetype = 2, colour = TJ$neutral, linewidth = 0.25)
minus  <- function(x) gsub("-", "−", x, fixed = TRUE)            # 真减号 / true minus sign
lab_1d <- scales::label_number(accuracy = 0.1, style_negative = "minus")

#' log2 发散色阶: 1 为中性色、两侧强度对称; 上下限(数据范围)与刻度沿用原图
#' log2 diverging fill, neutral at 1 with symmetric intensity; original limits and breaks
div_fill <- function(limits, breaks, name, key_h = 16, key_w = 2.2) {
  L    <- max(abs(log2(limits)))
  at   <- seq(log2(limits[1]), log2(limits[2]), length.out = 129)
  ramp <- grDevices::colorRamp(TJ_DIV, space = "Lab")
  cols <- grDevices::rgb(ramp((at + L) / (2 * L)), maxColorValue = 255)
  scale_fill_gradientn(
    colours = cols, values = seq(0, 1, length.out = 129), limits = limits, trans = "log2",
    breaks = breaks, labels = as.character(breaks), name = name, na.value = NA_COL,
    oob = scales::squish,
    guide = guide_colourbar(theme = theme(legend.key.height = unit(key_h, "mm"),
                                          legend.key.width = unit(key_w, "mm"))))
}

# =====================================================================
# 0. 数据(与 143 逐行一致)/ data, verbatim from script 143
# =====================================================================
d <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
d[, c("x", "clim_change", "clim_var") := NULL]
cc <- as.data.table(read_parquet(file.path(OUT, "data", "components_v2_tavg_annual_W15.parquet")))
d <- merge(d, cc, by = c("species", "province", "year"))
d <- d[is.finite(clim_change) & is.finite(clim_var) & is.finite(eff_visits_gap_z)]
CC_MU <- mean(d$clim_change); CC_SD <- stats::sd(d$clim_change)
EF_MU <- mean(d$eff_visits_gap_z); EF_SD <- stats::sd(d$eff_visits_gap_z)
d[, `:=`(clim_change_z = (clim_change - CC_MU) / CC_SD,
         clim_var_z = as.numeric(scale(clim_var)),
         effort_z = (eff_visits_gap_z - EF_MU) / EF_SD)]
m <- readRDS(file.path(OUT, "data", "fit_R3.rds"))
B <- fixef(m)$cond; V <- vcov(m)$cond; INT <- grep(":", names(B), value = TRUE)[1]
msg("数据 / data ", format(nrow(d), big.mark = ","), " rows | 1 SD warming = ", round(CC_SD, 3), " °C")

# =====================================================================
# 1. 模型解剖图 / Fig model anatomy
# =====================================================================
# ---- a 梯度的构造(143 原样)/ how the gradient is built (verbatim) ----
gp  <- fread(file.path(FN, "data", "panel_full_grid.csv"))[indicator == "tavg_annual"]
g2p <- fread(file.path(RB, "data", "grid_province_lookup.csv"), encoding = "UTF-8")
gp  <- merge(gp, g2p[, .(grid_cell, province, olap)], by = "grid_cell")
prov <- gp[, .(T_t = stats::weighted.mean(val, olap, na.rm = TRUE),
               T_base = stats::weighted.mean(baseline, olap, na.rm = TRUE)), by = .(province, year)]
spn <- fread(file.path(FN, "data", "panel_full_species.csv"))[indicator == "tavg_annual",
        .(species, year, N_t = val, N_base = baseline)]
EX_PROV <- "Yunnan"; EX_HI <- "Aethopyga christinae"; EX_LO <- "Coracias garrulus"
roll15 <- function(dt) { setorder(dt, year); dt[, anom := frollmean(anom, 15, align = "right")]; dt[!is.na(anom)] }
pv <- roll15(prov[province == EX_PROV, .(year, anom = T_t - T_base, who = paste0(EX_PROV, " (province)"))])
s1 <- roll15(spn[species == EX_HI, .(year, anom = N_t - N_base, who = paste0(EX_HI, " (range)"))])
s2 <- roll15(spn[species == EX_LO, .(year, anom = N_t - N_base, who = paste0(EX_LO, " (range)"))])
ex <- rbindlist(list(pv, s1, s2))
ex[, who := factor(who, levels = c(paste0(EX_PROV, " (province)"),
                                   paste0(EX_HI, " (range)"), paste0(EX_LO, " (range)")))]
gap_hi <- pv[year == 2020]$anom - s1[year == 2020]$anom
gap_lo <- pv[year == 2020]$anom - s2[year == 2020]$anom

# 设计: 省=墨色参照线; 两物种=深浅两档朱红(同属"增温"语义, 不与努力蓝混淆); 线端直接标注;
#       2020 年两个 x 以细双箭头 + 白底小标签标在差值处
# Design: province = ink reference; two species = vermilion and dark vermilion; labels at
#         the line ends; the two 2020 differences as thin arrows with white-backed labels
A_COL <- setNames(c(TJ$ink, TJ$warming, TJ_DIV[7]), levels(ex$who))
y20 <- c(prov = pv[year == 2020]$anom, hi = s1[year == 2020]$anom, lo = s2[year == 2020]$anom)
arr <- data.table(y0 = y20[["prov"]] + c(-1, 1) * 0.012, y1 = y20[c("hi", "lo")],
                  col = A_COL[2:3], lab = minus(sprintf("x = %+.2f °C", c(gap_hi, gap_lo))))
arr[, ylab := (y0 + y1) / 2]
ends <- ex[, .SD[which.max(year)], by = who]
A_XR <- range(ex$year) + c(-0.6, 0.6)
ends[, `:=`(name = c(EX_PROV, EX_HI, EX_LO)[as.integer(who)],
            kind = c("province", "range", "range")[as.integer(who)],
            face = c("plain", "italic", "italic")[as.integer(who)])]
p5a <- ggplot(ex, aes(year, anom, colour = who)) +
  annotate("segment", x = A_XR[1], xend = A_XR[2], y = 0, yend = 0, linetype = 2,
           colour = TJ$neutral, linewidth = 0.25) +   # 零线只画到数据末年 / zero line over the data only
  geom_line(linewidth = 0.5) +
  geom_segment(data = arr, aes(x = 2020, xend = 2020, y = y0, yend = y1), inherit.aes = FALSE,
               colour = arr$col, linewidth = 0.3,
               arrow = arrow(length = unit(2, "pt"), ends = "both", type = "closed")) +
  geom_label(data = arr, aes(x = 2019.4, y = ylab, label = lab), inherit.aes = FALSE,
             colour = arr$col, fill = "white", linewidth = 0, label.r = unit(0, "pt"),
             label.padding = unit(0.7, "pt"), size = pt2mm(6), family = "Arial") +
  geom_text(data = ends, aes(x = year + 0.8, label = name, fontface = face),
            hjust = 0, vjust = -0.12, size = pt2mm(6)) +
  geom_text(data = ends, aes(x = year + 0.8, label = kind), hjust = 0, vjust = 1.12, size = pt2mm(6)) +
  # 横轴只画到数据末年(range frame), 右侧留给线端标注 / axis line spans the data only;
  # the space to its right holds the line-end labels, so panels stay on one aligned grid
  annotate("segment", x = A_XR[1], xend = A_XR[2], y = -Inf, yend = -Inf, colour = TJ$rule, linewidth = 0.25) +
  scale_colour_manual(values = A_COL, guide = "none") +
  scale_x_continuous(breaks = c(2000, 2010, 2020), limits = c(A_XR[1], 2036.5), expand = c(0, 0)) +
  scale_y_continuous(labels = lab_1d) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = "15-yr mean anomaly vs 1980–2000 (°C)",
       title = "Climate is referenced to each species' range") +
  theme_tj() + theme(axis.line.x = element_blank())

# ---- b 方差分解(143 原样)/ variance partition (verbatim) ----
vp <- function(v) {
  tot <- var(d[[v]])
  btw <- var(d[, mean(get(v)), by = .(province, year)]$V1)
  wth <- mean(d[, .(vv = var(get(v)), n = .N), by = .(province, year)][n > 1]$vv)
  data.table(variable = v, source = c("Between province-years\n(regional climate)",
                                      "Within province-year\n(purely among species)"),
             share = c(btw / tot, wth / tot))
}
vpart <- rbindlist(lapply(c("x", "clim_change", "clim_var"), vp))
vpart[, share := share / sum(share), by = variable]
vpart[, variable := factor(variable, levels = c("clim_change", "clim_var", "x"),
      labels = c("Accumulated\nwarming", "Annual\nvariability", "Raw\ngradient x"))]

# 设计: 横向 100% 堆叠条; 组内(物种间)= 青绿, 从 0 起以便比较; 组间 = 中性灰; 图例改为直接标注
# Design: horizontal 100% bars; within (among species) = teal from 0; between = grey; direct labels
vb <- copy(vpart)[, comp := factor(fifelse(grepl("^Between", source), "between", "within"),
                                   levels = c("between", "within"))]
B_COL <- c(between = TJ$neutral, within = TJ$obs)
p5b <- ggplot(vb, aes(100 * share, variable, fill = comp)) +
  geom_col(width = 0.6, colour = "white", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.0f%%", 100 * share)), position = position_stack(vjust = 0.5),
            colour = "white", fontface = "bold", size = pt2mm(6)) +
  annotate("text", x = 0, y = 3.36, hjust = 0, vjust = 0, lineheight = 0.95, size = pt2mm(6),
           colour = TJ$obs, label = "Within province-year\n(purely among species)") +
  annotate("text", x = 100, y = 3.36, hjust = 1, vjust = 0, lineheight = 0.95, size = pt2mm(6),
           colour = TJ$subink, label = "Between province-years\n(regional climate)") +
  scale_fill_manual(values = B_COL, guide = "none") +
  scale_y_discrete(limits = rev, expand = expansion(add = c(0.45, 0.82))) +
  scale_x_continuous(breaks = seq(0, 100, 25), expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  labs(x = "Share of variance (%)", y = NULL, title = "Species identity carries much of the variance") +
  theme_tj() +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(),
        axis.text.y = element_text(lineheight = 0.95), plot.margin = margin(4, 8, 4, 4))

# ---- c 自然单位的偏效应(143 原样)/ partial effects on natural scales (verbatim) ----
eff_raw <- fread(file.path(OUT, "data", "effort_panel_v2.csv"))
obs <- eff_raw[effort_status_v2 == "observed" & in_scope %in% c(TRUE, 1, "TRUE")]
LV_SD <- stats::sd(log1p(obs$n_visits))
pred_line <- function(cc_deg, ef_z) {
  ccz <- (cc_deg - CC_MU) / CC_SD
  X <- cbind(1, ccz, ef_z, 0, ccz * ef_z)
  colnames(X) <- c("(Intercept)", "clim_change_z", "effort_z", "clim_var_z", INT)
  X <- X[, names(B), drop = FALSE]
  eta <- as.numeric(X %*% B); se <- sqrt(rowSums((X %*% V) * X))
  data.table(haz = 1 - exp(-exp(eta)), lo = 1 - exp(-exp(eta - 1.96 * se)),
             hi = 1 - exp(-exp(eta + 1.96 * se)))
}
gc1 <- CJ(cc_deg = seq(quantile(d$clim_change, .02), quantile(d$clim_change, .98), length.out = 60),
          ef_z = as.numeric(quantile(d$effort_z, c(.10, .50, .90))))
gc1 <- cbind(gc1, pred_line(gc1$cc_deg, gc1$ef_z))
gc1[, eff_lab := factor(ef_z, labels = sprintf("%s visits/yr",
     format(round(expm1(quantile(log1p(obs$n_visits), c(.10, .50, .90)))), big.mark = ",")))]

# 设计: 努力三档 = 单色蓝阶(浅→深); 右端三线汇合, 故直接标注放在左端分得开的位置
# Design: three effort levels as a light-to-dark blue ramp; lines converge at the right,
#         so the direct labels sit at the left where the lines are well separated
E_COL <- setNames(c(tint(TJ$effort, 0.35), TJ$effort, colorspace::darken(TJ$effort, 0.35)),
                  levels(gc1$eff_lab))
x_l <- min(gc1$cc_deg) + 0.008
e_lab <- gc1[cc_deg == min(cc_deg), .(eff_lab, txt = trimws(as.character(eff_lab)))]
e_lab[, `:=`(y = c(0.040, 0.178, 0.362), vj = c(1, 0, 0))]   # %; 3 visits 线下, 其余线上
p5c <- ggplot(gc1, aes(cc_deg, 100 * haz, colour = eff_lab, fill = eff_lab)) +
  ref_v(0) +
  geom_ribbon(aes(ymin = 100 * lo, ymax = 100 * hi), alpha = 0.16, colour = NA) +
  geom_line(linewidth = 0.5) +
  geom_text(data = e_lab, aes(x = x_l, y = y, label = txt, vjust = vj), inherit.aes = FALSE,
            colour = E_COL[as.character(e_lab$eff_lab)], hjust = 0, size = pt2mm(6)) +
  annotate("text", x = max(gc1$cc_deg), y = 0.004, hjust = 1, vjust = 0, size = pt2mm(6),
           lineheight = 0.95, colour = TJ$subink,
           label = sprintf("1 SD of warming = %.2f °C\n1 SD of effort = ×%.1f annual visits",
                           CC_SD, exp(LV_SD))) +
  scale_colour_manual(values = E_COL, guide = "none") +
  scale_fill_manual(values = E_COL, guide = "none") +
  scale_x_continuous(breaks = seq(-0.4, 0.4, 0.2), labels = lab_1d) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.03))) +
  labs(x = "Province warmed more than the species' range (°C)",
       y = "Annual hazard of a new record (%)", title = "Warming raises hazard most at low effort") +
  theme_tj()

# ---- d 层级方差 → 风险倍数(143 原样)/ hierarchical SDs as multipliers (verbatim) ----
vc <- glmmTMB::VarCorr(m)$cond
hier <- data.table(
  term = c("Species", "Province", "Province x year"),
  sd = vapply(vc[c("species", "province", "prov_year")], function(v) sqrt(v[1, 1]), numeric(1)),
  meaning = c("intrinsic detectability:\nbody size, song, habitat access,\ntaxonomic attention",
              "regional survey setting:\narea, terrain, habitat diversity,\nobserver population",
              "observation-process shocks:\nregional surveys, festivals,\nnew reserves, reporting channels"))
hier[, `:=`(mult = exp(sd), spread = exp(2 * 1.2816 * sd))]
fixed_ref <- data.table(term = c("Accumulated warming (fixed)", "Survey effort (fixed)"),
                        mult = c(exp(B[["clim_change_z"]]), exp(B[["effort_z"]])), sd = NA_real_,
                        meaning = "", spread = NA_real_)
hb <- rbind(hier, fixed_ref, fill = TRUE)

# 设计: 点-棒(自 1 起, log2 轴); 随机截距 = 青绿, 固定效应 = 各自语义色; 省×年置顶并加粗
# Design: dot-and-stick from 1 on log2; random = teal, fixed = term colours; province x year on top
hd <- copy(hb)[, `:=`(
  lab = c("Species", "Province", "Province × year", "Accumulated warming", "Survey effort"),
  grp = factor(c(rep("Random intercepts", 3), rep("Fixed effects", 2)),
               levels = c("Random intercepts", "Fixed effects")),
  col = c(TJ$obs, TJ$obs, TJ$obs, TERM_COL[["Accumulated warming"]], TERM_COL[["Survey effort"]]))]
hd[, `:=`(lab = factor(lab, levels = rev(c("Province × year", "Species", "Province",
                                           "Survey effort", "Accumulated warming"))),
          face = fifelse(term == "Province x year", "bold", "plain"))]
p5d <- ggplot(hd, aes(y = lab)) +
  ref_v(1) +
  geom_segment(aes(x = 1, xend = mult, yend = lab, colour = col), linewidth = 0.6) +
  geom_point(aes(x = mult, colour = col), size = 1.6) +
  geom_text(aes(x = mult, label = sprintf("×%.2f", mult), colour = col, fontface = face),
            hjust = -0.3, size = pt2mm(6)) +
  scale_colour_identity() +
  scale_x_continuous(trans = "log2", breaks = c(1, 1.5, 2, 2.5), labels = c("1", "1.5", "2", "2.5"),
                     limits = c(0.95, 2.75), expand = c(0, 0)) +
  facet_wrap(~grp, ncol = 1, scales = "free_y", space = "free_y") +
  labs(x = "Hazard multiplier per 1 SD", y = NULL, title = "Province-year shocks outweigh both drivers") +
  theme_tj() +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(),
        strip.text = element_text(size = TJ_BASE - 1, face = "plain", colour = TJ$subink, margin = margin(b = 1, t = 2)),
        panel.spacing = unit(3, "pt"))

# 单一 2×2 网格: 同列面板左缘对齐, b/d 字母上下对齐 / one 2x2 grid so columns and tags align
F5 <- p5a + p5b + p5c + p5d + plot_layout(ncol = 2, widths = c(1.1, 0.9)) + tj_tags()
tj_save(F5, "TJ_Fig_model_anatomy", 183, 132)
for (k in c("a", "b", "c", "d"))
  tj_panel(get(paste0("p5", k)), paste0("TJ_Fig_model_anatomy_", k), 120, 85)

# =====================================================================
# 2. 观测过程图 / Fig observation process
# =====================================================================
re <- ranef(m)$cond
sp_b <- data.table(species = rownames(re$species), b = re$species[[1]])
sp_b <- merge(sp_b, unique(d[, .(species, mig_grp)]), by = "species", all.x = TRUE)
sp_b[, mig_grp := factor(as.character(mig_grp),
     levels = c("Resident", "Partial", "Long-distance", "Unknown"))]

# ---- a 物种随机截距: 云雨图 / species intercepts as a raincloud ----
# 半小提琴(右)+ 抖动点(左, 固定种子)+ 组中位数菱形; 中位数在 log 尺度上取, 与原图 stat_summary 一致
# Half violin (right) + jittered points (left, fixed seed) + median diamond; the median is
# taken on the log scale exactly as stat_summary did on the log2 axis in the original
sa <- sp_b[!is.na(mig_grp)]
set.seed(218); sa[, xj := as.integer(mig_grp) - 0.2 + runif(.N, -0.11, 0.11)]
sa_med <- sa[, .(med = exp(median(b))), by = mig_grp]
p6a <- ggplot(sa, aes(mig_grp, exp(b))) +
  ref_h(1) +
  stat_slab(side = "right", position = position_nudge(x = 0.02), scale = 0.42, normalize = "groups",
            density = density_unbounded(bandwidth = "nrd0"), fill = tint(TJ$obs, 0.72),
            colour = TJ$obs, linewidth = 0.25) +
  geom_point(aes(x = xj), size = 0.55, alpha = 0.5, colour = TJ$obs, stroke = 0) +
  geom_point(data = sa_med, aes(x = as.integer(mig_grp) + 0.02, y = med), shape = 18, size = 2.2,
             colour = TJ$ink) +
  scale_y_continuous(trans = "log2", breaks = c(0.75, 1, 1.5, 2, 2.7),
                     labels = c("0.75", "1", "1.5", "2", "2.7")) +
  labs(x = NULL, y = "Species hazard multiplier", title = "Intrinsic detectability differs among species") +
  theme_tj()

# ---- b 省随机截距地图 / province intercepts on the standard map ----
pv_b <- data.table(province = rownames(re$province), b = re$province[[1]])
bm <- tj_basemap()
mp <- merge(bm$prov, pv_b, by = "province", all.x = TRUE)
mp$mult <- exp(mp$b)
p6b <- tj_china_map(geom_sf(data = mp, aes(fill = mult), colour = "white", linewidth = 0.1),
                    div_fill(range(exp(pv_b$b)), c(0.75, 1, 1.5, 2), "Province\nmultiplier",
                             key_h = 15),
                    bm = bm, title = "Regional baselines, net of effort and climate") +
  theme(plot.margin = margin(0, 0, 0, 0))   # 外层包装不再加边距, 标题与 a 对齐 / wrapper adds no margin

# ---- c 省×年随机截距热图(143 原样排序)/ province x year heatmap (original order) ----
# NB: 列名不能叫 key —— 那是 data.table() 的保留参数
py_b <- data.table(lvl = rownames(re$prov_year), b = re$prov_year[[1]])
py_b[, c("province", "year") := tstrsplit(lvl, "\\.", keep = 1:2)]
py_b[, year := as.integer(year)]
ord <- py_b[, .(m = mean(b)), by = province][order(m)]$province
py_b[, province := factor(province, levels = ord)]
# 模型中不存在的省-年(24 个努力覆盖缺口与广东 2024 年下载缺口)显式画成灰格, 不再留白(留白会被读成 ≈1)
# province-years absent from the model (24 coverage gaps and the Guangdong 2024 download gap) are grey cells
py_miss <- CJ(province = factor(ord, levels = ord), year = seq(min(py_b$year), max(py_b$year)))[
  !py_b, on = .(province, year)]
YR <- range(py_b$year)
# 注记由模型现算(省 × 年随机截距的 SD 与最大乘数), 不写死 / note computed from the fit, not typed in
SD_PY <- attr(glmmTMB::VarCorr(m)$cond$prov_year, "stddev")[[1]]
PY_NOTE <- sprintf("SD %.3f,\nup to\n%.0f-fold", SD_PY, max(exp(py_b$b)))
p6c <- ggplot(py_b, aes(year, province)) +
  geom_tile(data = py_miss, fill = NA_COL, colour = "white", linewidth = 0.2) +
  geom_tile(aes(fill = exp(b)), colour = "white", linewidth = 0.2) +
  div_fill(range(exp(py_b$b)), c(0.6, 1, 2, 4, 7), "Multiplier", key_h = 20) +
  annotate("text", x = YR[2] + 1.15, y = length(ord) - 10.4, hjust = 0, vjust = 1, size = pt2mm(6),
           lineheight = 0.95, colour = TJ$subink, label = PY_NOTE) +
  scale_x_continuous(breaks = seq(2002, 2024, 4), expand = c(0, 0)) +
  scale_y_discrete(limits = ord, expand = c(0, 0)) +   # 原图顺序 / original row order
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = NULL, title = "Observation shocks vary by province and year") +
  theme_tj() +
  theme(axis.line = element_blank(), axis.ticks.y = element_blank(),
        legend.justification.right = "top", legend.title = element_text(margin = margin(b = 3)))

# ---- d 努力回报随时间递减(143 原样)/ falling return on effort (verbatim) ----
mtv <- readRDS(file.path(OUT, "data", "fit_R3_time_varying.rds"))
cf <- fixef(mtv)$cond; Vt <- vcov(mtv)$cond
yrs <- 2002:2024; yc <- (yrs - mean(d$year)) / stats::sd(d$year)
nm <- c("effort_z", "effort_z:year_c")
nm <- nm[nm %in% names(cf)]
if (length(nm) < 2) nm <- c("effort_z", grep("^effort_z:", names(cf), value = TRUE)[1])
b_t <- cf[[nm[1]]] + cf[[nm[2]]] * yc
Vs <- Vt[nm, nm]
se_t <- sqrt(Vs[1, 1] + yc^2 * Vs[2, 2] + 2 * yc * Vs[1, 2])
dt6 <- data.table(year = yrs, hr = exp(b_t), lo = exp(b_t - 1.96 * se_t), hi = exp(b_t + 1.96 * se_t))
P_INT <- summary(mtv)$coefficients$cond[nm[2], "Pr(>|z|)"]
# P 值标注由模型现算: < 0.001 用科学记数(上标显式 5 pt), 否则两位有效数字
# P label from the fit: scientific notation below 0.001 (explicit 5 pt superscript), else 2 significant digits
P_LAB <- if (P_INT < 0.001) {
  ex <- floor(log10(P_INT))
  sprintf("Effort × time, *P* = %.1f × 10<sup><span style='font-size:5pt'>−%d</span></sup>", P_INT / 10^ex, -ex)
} else sprintf("Effort × time, *P* = %s", formatC(P_INT, digits = 2, format = "fg"))
msg("effort × time P = ", signif(P_INT, 3), " | label: ", P_LAB)
p6d <- ggplot(dt6, aes(year, hr)) +
  ref_h(1) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = TJ$effort, alpha = 0.18) +
  geom_line(colour = TJ$effort, linewidth = 0.5) +
  geom_point(data = dt6[c(1, .N)], colour = TJ$effort, size = 1.2) +
  geom_text(data = dt6[1], aes(label = sprintf("%.2f", hr)), hjust = -0.35, vjust = -0.6,
            colour = TJ$effort, size = pt2mm(6)) +
  geom_text(data = dt6[.N], aes(label = sprintf("%.2f", hr)), hjust = -0.45, vjust = 0.5,
            colour = TJ$effort, size = pt2mm(6)) +
  # 富文本: 上标显式 5 pt(plotmath 上标会缩到 4.2 pt, 低于下限)
  # rich text with an explicit 5 pt superscript (a plotmath superscript shrinks to 4.2 pt)
  ggtext::geom_richtext(data = data.frame(x = max(yrs), y = 3.0), aes(x, y), inherit.aes = FALSE,
           label = P_LAB,
           hjust = 1, vjust = 1, size = pt2mm(6), family = "Arial", colour = TJ$subink, fill = NA,
           label.colour = NA, label.padding = unit(0, "pt")) +
  scale_x_continuous(breaks = seq(2002, 2022, 4), expand = expansion(add = 0.6)) +
  scale_y_continuous(breaks = seq(1, 3, 0.5), labels = lab_1d) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = "Hazard ratio per 1 SD of effort", title = "The return on survey effort is falling") +
  theme_tj() + theme(plot.margin = margin(4, 14, 4, 4))

# a 不与下排热图的省名列对齐(否则左侧留白); 地图格加宽以匹配其 1.53 的宽高比
# panel a is freed from the heatmap's label column; the map cell is widened to suit its 1.53 aspect
F6 <- ((free(p6a) | p6b) + plot_layout(widths = c(0.74, 1.26))) /
      ((p6c | p6d) + plot_layout(widths = c(1.32, 0.68))) +
  plot_layout(heights = c(1, 1.32)) + tj_tags()
tj_save(F6, "TJ_Fig_observation_process", 183, 150)
tj_panel(p6a, "TJ_Fig_observation_process_a", 120, 85)
tj_panel(p6b, "TJ_Fig_observation_process_b", 120, 80)   # 贴合地图宽高比 / fits the map aspect
tj_panel(p6c, "TJ_Fig_observation_process_c", 120, 95)
# 单面板右侧留出末端数值标签(2024 年 HR)的位置, 否则幻灯片版会被裁掉
# room for the end-point label (2024 HR) in the single panel; the slide version clipped it
tj_panel(p6d + theme(plot.margin = margin(4, 30, 4, 4)), "TJ_Fig_observation_process_d", 120, 85)

# =====================================================================
# 3. 与原图源数据逐值核对 / check against the original source data
# =====================================================================
o5 <- fread(file.path(FIG0, "source_data_Fig5_model_anatomy_v2.csv"))
c5a <- merge(o5[!is.na(share), .(variable, source, share0 = share)],
             vpart[, .(variable = as.character(variable), source, share)], by = c("variable", "source"))
c5b <- merge(o5[!is.na(mult), .(term, mult0 = mult, sd0 = sd)], hb[, .(term, mult, sd)], by = "term")
o6 <- fread(file.path(FIG0, "source_data_Fig6_observation_process_v2.csv"))
new6 <- rbind(sp_b[, .(level = species, term = "species", b)], pv_b[, .(level = province, term = "province", b)],
              py_b[, .(level = lvl, term = "province_year", b)])
c6 <- merge(o6[, .(level, term, b0 = b)], new6, by = c("level", "term"))
dev <- c(fig5_shares = max(abs(c5a$share - c5a$share0)), fig5_mult = max(abs(c5b$mult - c5b$mult0)),
         fig6_b = max(abs(c6$b - c6$b0)))
msg("核对 / check: rows matched ", nrow(c5a), "/6, ", nrow(c5b), "/5, ", nrow(c6), "/", nrow(o6),
    " | max |diff| = ", paste(names(dev), signif(dev, 3), collapse = "; "))
stopifnot(nrow(c5a) == 6, nrow(c5b) == 5, nrow(c6) == nrow(o6), all(dev < 1e-9))
msg("key numbers: x = ", round(gap_hi, 2), " / ", round(gap_lo, 2), " °C; 1 SD = ", round(CC_SD, 2),
    " °C; effort ×", round(exp(LV_SD), 1), "; HR ", round(dt6$hr[1], 2), " → ", round(tail(dt6$hr, 1), 2),
    "; P = ", signif(P_INT, 2), "; RE mult ", paste(round(hb$mult, 2), collapse = "/"))

# =====================================================================
# 4. 长格式源数据 / long-format source data (every plotted value)
# =====================================================================
S <- function(panel, item, x_var, x, y_var, y, y_lo = NA_real_, y_hi = NA_real_, group = NA_character_)
  data.table(panel, item, group, x_var, x = as.character(x), y_var, y, y_lo, y_hi)
src5 <- rbind(
  S("a", ex$who, "year", ex$year, "15-yr mean anomaly vs 1980-2000 (degC)", ex$anom),
  S("a", c(EX_HI, EX_LO), "year", 2020, "x = province - species range anomaly (degC)", c(gap_hi, gap_lo)),
  S("b", vpart$variable, "component", vpart$source, "share of variance", vpart$share),
  S("c", trimws(as.character(gc1$eff_lab)), "province warmed more than species range (degC)", gc1$cc_deg,
    "annual hazard of a new record (%)", 100 * gc1$haz, 100 * gc1$lo, 100 * gc1$hi,
    group = sprintf("effort_z = %.4f", gc1$ef_z)),
  S("c", c("1 SD accumulated warming (degC)", "1 SD effort (multiplier of annual visits)"), NA, NA,
    "annotation", c(CC_SD, exp(LV_SD))),
  S("d", hb$term, "SD of random intercept", hb$sd, "hazard multiplier per 1 SD", hb$mult,
    group = fifelse(is.na(hb$sd), "fixed", "random")))
src5[, `:=`(item = gsub("\n", " ", item), x = gsub("\n", " ", x))]
tj_source(src5, "TJ_Fig_model_anatomy")
src6 <- rbind(
  S("a", sp_b$species, "migratory group", sp_b$mig_grp, "species hazard multiplier exp(b)", exp(sp_b$b),
    group = as.character(sp_b$mig_grp)),
  S("a", paste("median", sa_med$mig_grp), "migratory group", sa_med$mig_grp, "group median multiplier", sa_med$med),
  S("b", mp$province, "province", mp$province, "province hazard multiplier exp(b)", mp$mult,
    group = fifelse(is.na(mp$mult), "outside analysis scope", "in scope")),
  S("c", py_b$province, "year", py_b$year, "province x year hazard multiplier exp(b)", exp(py_b$b),
    group = "in model"),
  S("c", py_miss$province, "year", py_miss$year, "province x year hazard multiplier exp(b)", NA_real_,
    group = "effort missing (coverage or download gap), not in model (grey cell)"),
  S("d", "effort hazard ratio", "year", dt6$year, "hazard ratio per 1 SD of effort", dt6$hr, dt6$lo, dt6$hi),
  S("d", "effort x time interaction", NA, NA, "P value", P_INT))
src6 <- unique(src6[!(panel == "b" & is.na(item))])
tj_source(src6, "TJ_Fig_observation_process")
msg("DONE")
