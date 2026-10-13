#!/usr/bin/env Rscript
# ============================================================
# Script 162: 替代气候代理敏感性与热暴露机制的图件
# Figures for the climate-proxy sensitivity and the heat-exposure mechanism
# ============================================================
# 目的 / Objective:
#   把脚本 160/161 的结果制成投稿级图件, 每图输出
#   PNG(450 dpi) + 矢量 PDF + SVG + 可编辑 PPTX + source data。
#
# Fig12 气候代理的敏感性 / Climate-proxy sensitivity
#   a  气候主效应 HR vs 累积窗口, 六种代理
#   b  气候 x 努力交互 HR vs 累积窗口 —— 交互只存在于年均温系列
#   c  dAIC vs 窗口(同一行集, 故 AIC 可比)
#   d  省x年方差分量 vs 窗口 —— 独立于 AIC 的第二判据
#
# Fig13 热暴露如何限制变暖效应 / How heat exposure bounds the warming effect
#   a  变暖的边际 HR 随热暴露连续变化, 带 95% 置信带
#   b  生态位位置与热暴露的分布 —— 解释 a 必须先知道正负比例
#   c  四象限原始事件率 vs 乘性预期 —— 不依赖模型的交互证据
#   d  热暴露调节项在三档阈值与四种努力代理下的稳健性(AIC 不可比, 只看系数)
#
# 设计规范 / Design standards (与 139/143/144 一致):
#   Okabe-Ito 色盲友好配色; HR 轴以 1 为参考线; 误差棒为 95% Wald CI;
#   面板字母加粗左上; 直接标注优先于图例。
#
# Input / 输入:
#   analysis_v2/tables/tbl_v2_niche_sensitivity_grid.csv   (161)
#   analysis_v2/tables/tbl_v2_niche_spec_fit.csv           (160)
#   analysis_v2/data/fit_niche_S4M_W15.rds                 (160)
#   analysis_v2/data/model_v2_thr50.parquet                (132)
#   analysis_final/data/panel_full_{grid,species}.csv      (120)
#
# Output / 输出:
#   analysis_v2/figures/Fig12_climate_proxy_sensitivity.{png,pdf,svg,pptx}
#   analysis_v2/figures/Fig13_heat_exposure_mechanism.{png,pdf,svg,pptx}
#   + source_data_*.csv
#
# Main packages / 主要包: data.table, ggplot2, patchwork, glmmTMB, officer, rvg
# 运行 / Run: Rscript --no-init-file code/162_niche_sensitivity_figures.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(ggplot2); library(glmmTMB)
  library(patchwork); library(officer); library(rvg)
})
options(warn = 1)

ROOT <- normalizePath(".", mustWork = TRUE)
OUT  <- file.path(ROOT, "analysis_v2")
RB   <- file.path(ROOT, "analysis_rebuilt"); FN <- file.path(ROOT, "analysis_final")
TAB  <- file.path(OUT, "tables"); FIG <- file.path(OUT, "figures")
dir.create(FIG, showWarnings = FALSE, recursive = TRUE)
msg <- function(...) cat(sprintf("[162 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

OI <- c(blue = "#0072B2", orange = "#E69F00", green = "#009E73", red = "#D55E00",
        purple = "#CC79A7", sky = "#56B4E9", yellow = "#F0E442", grey = "#999999")

theme_pub <- function(base = 9) {
  theme_classic(base_size = base, base_family = "sans") +
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
          legend.title = element_text(size = base - 1, face = "bold"), plot.margin = margin(6, 8, 6, 8))
}

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
  msg("  saved ", name, " (png/pdf/svg/pptx)")
}

zs <- function(x) as.numeric(scale(x))

# ==========================================================================
# Fig 12  气候代理的敏感性
# ==========================================================================
G <- fread(file.path(TAB, "tbl_v2_niche_sensitivity_grid.csv"))
A <- G[block == "A_window"]

SHORT <- c(S0_tavg_annual = "Annual mean (main)",
           S1_tmax_warm   = "Warmest-month max",
           S4M_exposure_moderates = "Annual mean + exposure",
           S4_heat_exposure = "Heat exposure",
           S3_niche_track = "Niche tracking",
           S2_niche_prox  = "Niche proximity")
A[, proxy := factor(SHORT[spec], levels = unname(SHORT))]
COLS <- unname(OI[c("blue", "red", "purple", "orange", "green", "grey")])

band <- function(y, lo, hi, ylab, ttl, sub, ref = 1, legend = "none") {
  ggplot(A, aes(window, get(y), colour = proxy, fill = proxy)) +
    geom_hline(yintercept = ref, linetype = 2, colour = "grey55", linewidth = 0.35) +
    geom_ribbon(aes(ymin = get(lo), ymax = get(hi)), alpha = 0.10, colour = NA) +
    geom_line(linewidth = 0.7) + geom_point(size = 1.5) +
    scale_colour_manual(values = COLS, name = "Climate proxy") +
    scale_fill_manual(values = COLS, guide = "none") +
    scale_x_continuous(breaks = sort(unique(A$window))) +
    labs(x = "Accumulation window W (years)", y = ylab, title = ttl, subtitle = sub) +
    theme_pub() + theme(legend.position = legend)
}

p12a <- band("HR_climate", "lo_climate", "hi_climate", "Hazard ratio per 1 SD",
  "Every proxy carries a signal except the two niche-centre metrics",
  "Niche proximity and niche tracking sit on 1 at every window; heat exposure is negative",
  legend = "bottom")

p12b <- band("HR_int", "lo_int", "hi_int", "Hazard ratio per 1 SD",
  "The interaction follows the underlying indicator, not the transformation",
  paste("Both proxies built on the warmest-month maximum sit on 1 at every window.",
        "\nThose built on annual mean temperature depart from it - downward for the main and",
        "\nmoderated specifications and for niche proximity, upward for niche tracking."))

p12c <- ggplot(A, aes(window, dAIC, colour = proxy)) +
  geom_hline(yintercept = 0, linetype = 2, colour = "grey55", linewidth = 0.35) +
  geom_line(linewidth = 0.7) + geom_point(size = 1.5) +
  scale_colour_manual(values = COLS, guide = "none") +
  scale_x_continuous(breaks = sort(unique(A$window))) +
  labs(x = "Accumulation window W (years)", y = "Delta AIC (common row set)",
       title = "Heat-exposure moderation is the best specification at every window",
       subtitle = "All fits share one row set (n = 175,901), so AIC is comparable throughout") +
  theme_pub()

p12d <- ggplot(A, aes(window, sd_prov_year, colour = proxy)) +
  geom_hline(yintercept = A[spec == "S0_tavg_annual" & window == 15L]$sd_prov_year,
             linetype = 3, colour = "grey45", linewidth = 0.35) +
  geom_line(linewidth = 0.7) + geom_point(size = 1.5) +
  scale_colour_manual(values = COLS, guide = "none") +
  scale_x_continuous(breaks = sort(unique(A$window))) +
  labs(x = "Accumulation window W (years)", y = "SD of the province x year intercept",
       title = "A second criterion, independent of AIC",
       subtitle = paste("Dotted line: the main model at W = 15. Adding heat exposure absorbs province-year variance;",
                        "\nthe warmest-month proxy leaves more of it unexplained.")) +
  theme_pub()

F12 <- (p12a | p12b) / (p12c | p12d) +
  plot_annotation(tag_levels = "a") +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom", legend.direction = "horizontal",
        legend.text = element_text(size = 7), legend.title = element_text(size = 7.4))
save_fig(F12, "Fig12_climate_proxy_sensitivity", 11.2, 7.7, src = A)

# ==========================================================================
# Fig 13  热暴露如何限制变暖效应
# ==========================================================================
# ---- 重建 W=15 的建模数据(与 160 相同的流程) ------------------------------
gp  <- fread(file.path(FN, "data", "panel_full_grid.csv"))
g2p <- fread(file.path(RB, "data", "grid_province_lookup.csv"), encoding = "UTF-8")
gp  <- merge(gp, g2p[, .(grid_cell, province, olap)], by = "grid_cell")
prov <- gp[, .(T_t    = stats::weighted.mean(val,      olap, na.rm = TRUE),
               T_base = stats::weighted.mean(baseline, olap, na.rm = TRUE)),
           by = .(province, year, indicator)]
spn <- fread(file.path(FN, "data", "panel_full_species.csv"))
nat <- spn[, .(species, year, indicator, N_t = val, N_base = baseline)]
rm(gp); invisible(gc())

base <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
base[, c("x", "clim_change", "clim_var") := NULL]
base <- base[is.finite(eff_visits_gap_z)]
pp <- unique(base[, .(species, province)])

series <- function(ind) {
  cc <- merge(pp, prov[indicator == ind, .(province, year, T_t, T_base)],
              by = "province", allow.cartesian = TRUE)
  cc <- merge(cc, nat[indicator == ind, .(species, year, N_t, N_base)], by = c("species", "year"))
  setorder(cc, species, province, year); cc[]
}
comp <- function(cc, W, pre) {
  cc[, ch := frollmean(x, W, align = "right"), by = .(species, province)]
  cc[, vr := x - ch]
  o <- cc[year >= 2002L & year <= 2024L, .(species, province, year, ch, vr, xraw = x)]
  setnames(o, c("ch", "vr", "xraw"), paste0(pre, c("_change", "_var", "_x"))); o
}
S_tavg <- series("tavg_annual"); S_tmax <- series("tmax_warm")
d <- merge(base, comp(copy(S_tavg)[, x := (T_t - T_base) - (N_t - N_base)], 15L, "cl"),
           by = c("species", "province", "year"))
d <- merge(d, comp(copy(S_tmax)[, x := T_t - N_base], 15L, "ex"), by = c("species", "province", "year"))
d <- merge(d, comp(copy(S_tmax)[, x := (T_t - T_base) - (N_t - N_base)], 15L, "tx"),
           by = c("species", "province", "year"))
gapdt <- merge(unique(d[, .(species, province, year)]),
               merge(merge(pp, prov[indicator == "tavg_annual", .(province, year, T_t)],
                           by = "province", allow.cartesian = TRUE),
                     nat[indicator == "tavg_annual", .(species, year, N_t)],
                     by = c("species", "year")), by = c("species", "province", "year"))
gapdt[, gap := T_t - N_t]
d <- merge(d, gapdt[, .(species, province, year, gap)], by = c("species", "province", "year"))
d <- d[is.finite(cl_change) & is.finite(cl_var) & is.finite(ex_change) & is.finite(tx_change)]
d[, `:=`(clim_change_z = zs(cl_change), clim_var_z = zs(cl_var),
         effort_z = zs(eff_visits_gap_z), exposure_z = zs(ex_change))]
msg("Fig13 建模数据 ", format(nrow(d), big.mark = ","), " 行 / ", sum(d$event), " 事件")

# ---- (a) 变暖的边际 HR 随热暴露变化 ---------------------------------------
m <- readRDS(file.path(OUT, "data", "fit_niche_S4M_W15.rds"))
cf <- fixef(m)$cond; V <- vcov(m)$cond
b_ch <- cf[["clim_change_z"]]; b_md <- cf[["clim_change_z:exposure_z"]]
v_cc <- V["clim_change_z", "clim_change_z"]
v_mm <- V["clim_change_z:exposure_z", "clim_change_z:exposure_z"]
v_cm <- V["clim_change_z", "clim_change_z:exposure_z"]
ez_mu <- mean(d$ex_change); ez_sd <- stats::sd(d$ex_change)

gr <- data.table(ez = seq(quantile(d$exposure_z, .02), quantile(d$exposure_z, .98), length.out = 120))
gr[, `:=`(est = b_ch + b_md * ez, se = sqrt(v_cc + ez^2 * v_mm + 2 * ez * v_cm))]
gr[, `:=`(HR = exp(est), lo = exp(est - 1.96 * se), hi = exp(est + 1.96 * se),
          exposure_C = ez * ez_sd + ez_mu)]
rug <- d[sample(.N, min(4000L, .N))][, .(exposure_C = ex_change)]

p13a <- ggplot(gr, aes(exposure_C, HR)) +
  geom_hline(yintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
  geom_vline(xintercept = 0, linetype = 3, colour = OI[["red"]], linewidth = 0.4) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = OI[["blue"]], alpha = 0.15) +
  geom_line(colour = OI[["blue"]], linewidth = 0.8) +
  geom_rug(data = rug, aes(x = exposure_C), inherit.aes = FALSE,
           sides = "b", alpha = 0.08, length = unit(2.5, "pt"), colour = "grey35") +
  annotate("text", x = 0, y = max(gr$hi) * 0.99, label = "species' baseline\nwarm end",
           hjust = -0.08, vjust = 1, size = 2.5, colour = OI[["red"]], lineheight = 0.95) +
  labs(x = "Accumulated heat exposure (°C beyond the species' baseline warm end)",
       y = "Hazard ratio per 1 SD of thermal displacement",
       title = "Warming stops helping once a province passes the thermal envelope",
       subtitle = paste("Marginal effect of warming with 95% CI. Rug: the observed distribution.",
                        "\nInteraction HR 0.906 (0.838-0.980), P = 0.014.")) +
  theme_pub()

# ---- (b) 生态位位置与热暴露的分布 -----------------------------------------
# NB: 两个量都用【逐年】值(而非 W 年滑动均值), 与 tbl_v2_niche_gap_structure.csv
#     及正文引用的结构事实保持同一口径。a 面板必须用累积值, 因为模型里的
#     exposure_z 就是累积量的 z 值; 两者口径不同, 图注中已注明。
dist <- rbind(
  data.table(quantity = "Thermal position\nT(province) - N(species range)", v = d$gap),
  data.table(quantity = "Heat exposure\nTmax(province) - Tmax,base(species)", v = d$ex_x))
dist[, quantity := factor(quantity, levels = unique(quantity))]
lbl <- dist[, .(pct = sprintf("%.1f%% > 0\nmedian %+.2f °C", 100 * mean(v > 0), median(v))),
            by = quantity]

p13b <- ggplot(dist, aes(v, fill = quantity, colour = quantity)) +
  geom_vline(xintercept = 0, linetype = 2, colour = "grey40", linewidth = 0.4) +
  geom_density(alpha = 0.25, linewidth = 0.5, show.legend = FALSE) +
  facet_wrap(~quantity, ncol = 1, scales = "free_y") +
  geom_text(data = lbl, aes(label = pct), x = Inf, y = Inf, hjust = 1.05, vjust = 1.2,
            inherit.aes = FALSE, size = 2.5, lineheight = 0.95, colour = "grey20") +
  scale_fill_manual(values = unname(OI[c("sky", "orange")])) +
  scale_colour_manual(values = unname(OI[c("blue", "red")])) +
  labs(x = "Degrees Celsius", y = "Density",
       title = "Candidate provinces are already on the warm side",
       subtitle = "Which is why a metric built on distance from the niche centre cannot work") +
  theme_pub() + theme(strip.text = element_text(size = 6.6, face = "plain", lineheight = 0.95))

# ---- (c) 四象限原始事件率 vs 乘性预期 -------------------------------------
quad <- function(v, lab) {
  q <- d[, .(rate = 1e4 * mean(event), rows = .N),
         by = .(w = fifelse(get(v) > median(get(v)), "high", "low"),
                e = fifelse(effort_z > median(effort_z), "high", "low"))]
  q[, cell := factor(paste0(fifelse(w == "low", "Low", "High"), " warming\n",
                            fifelse(e == "low", "low effort", "high effort")),
       levels = c("Low warming\nlow effort", "Low warming\nhigh effort",
                  "High warming\nlow effort", "High warming\nhigh effort"))]
  r00 <- q[w == "low"  & e == "low"]$rate; r10 <- q[w == "high" & e == "low"]$rate
  r01 <- q[w == "low"  & e == "high"]$rate
  q[, indicator := lab]
  q[, expected := NA_real_]
  q[w == "high" & e == "high", expected := r10 * r01 / r00]
  q[]
}
qq <- rbind(quad("cl_change", "Annual mean"), quad("tx_change", "Warmest-month max"))
qq[, indicator := factor(indicator, levels = c("Annual mean", "Warmest-month max"))]

shortfall <- qq[!is.na(expected), .(indicator, pct = 100 * (rate - expected) / expected)]
p13c <- ggplot(qq, aes(cell, rate, fill = indicator)) +
  geom_col(position = position_dodge(0.72), width = 0.66, alpha = 0.9) +
  geom_point(aes(y = expected, group = indicator), position = position_dodge(0.72),
             shape = 18, size = 3.2, colour = "grey15", na.rm = TRUE, show.legend = FALSE) +
  scale_fill_manual(values = unname(OI[c("blue", "red")]), name = "Climate indicator") +
  labs(x = NULL, y = "Events per 10,000 risk-set rows",
       title = "The interaction is visible before any model is fitted",
       subtitle = sprintf(paste("Diamonds: the rate expected from the two margins alone.",
                        "\nAnnual mean falls %.0f%% short of it (sub-multiplicative = negative interaction);",
                        "\nthe warmest-month proxy falls only %.0f%% short, that is, essentially multiplicative."),
                        abs(shortfall[indicator == "Annual mean"]$pct),
                        abs(shortfall[indicator == "Warmest-month max"]$pct))) +
  theme_pub() + theme(legend.position = c(0.22, 0.84),
                      axis.text.x = element_text(size = 6.6, lineheight = 0.95))

# ---- (d) 调节项在阈值与努力代理下的稳健性 ---------------------------------
BC <- G[block %in% c("B_threshold", "C_effort") |
        (block == "A_window" & spec == "S4M_exposure_moderates" & window == 15L)]
BC[, setting := fifelse(block == "B_threshold", paste0("SDM threshold ", threshold, " cells"),
                 fifelse(block == "C_effort", paste0("Effort: ", effort),
                         "Main: 50 cells, visits"))]
fd <- rbind(
  BC[, .(setting, term = "Displacement x heat exposure", HR = HR_moderation,
         lo = lo_moderation, hi = hi_moderation, P = P_moderation)],
  BC[, .(setting, term = "Displacement x effort", HR = HR_int, lo = lo_int, hi = hi_int, P = P_int)])
fd[, setting := factor(setting, levels = rev(c("Main: 50 cells, visits",
     "SDM threshold 100 cells", "SDM threshold 200 cells",
     "Effort: observers", "Effort: days", "Effort: record")))]
fd[, sig := P < 0.05]

p13d <- ggplot(fd, aes(HR, setting, colour = term, shape = sig)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
  geom_linerange(aes(xmin = lo, xmax = hi), position = position_dodge(0.6), linewidth = 0.55) +
  geom_point(position = position_dodge(0.6), size = 2) +
  scale_colour_manual(values = unname(OI[c("purple", "blue")]), name = NULL) +
  scale_shape_manual(values = c(`TRUE` = 16, `FALSE` = 21), guide = "none") +
  labs(x = "Hazard ratio per 1 SD (95% CI)", y = NULL,
       title = "Both interactions hold across candidate pools and effort proxies",
       subtitle = paste("Filled points P < 0.05. Sample sizes differ across settings,",
                        "\nso coefficients are compared but AIC is not.")) +
  theme_pub() + theme(legend.position = "bottom", legend.margin = margin(-6, 0, 0, 0),
                      axis.text.y = element_text(size = 6.8))

F13 <- (p13a | p13b) / (p13c | p13d) + plot_annotation(tag_levels = "a")
save_fig(F13, "Fig13_heat_exposure_mechanism", 11.4, 7.6,
         src = rbind(gr[, .(panel = "a", exposure_C, HR, lo, hi)],
                     qq[, .(panel = "c", exposure_C = NA_real_, HR = rate, lo = NA_real_, hi = expected)],
                     fill = TRUE))
fwrite(qq, file.path(FIG, "source_data_Fig13_quadrants.csv"))
fwrite(fd, file.path(FIG, "source_data_Fig13_robustness.csv"))
msg("DONE")
