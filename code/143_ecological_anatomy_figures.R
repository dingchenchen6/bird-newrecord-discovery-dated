#!/usr/bin/env Rscript
# ============================================================
# Script 143: 模型的生态学解剖 —— 让每个参数的含义可见
# Ecological anatomy of the model: making every parameter's meaning visible
# ============================================================
# 目的 / Objective:
#   主模型的每一个固定效应、交互项与随机项都有明确的生态学或观测过程含义。
#   本脚本把这些含义从文字变成图, 并把效应量换算到【自然单位】(°C、访问次数、
#   风险倍数), 使读者不必在标准差尺度上思考。
#
# Fig5 模型解剖 / Anatomy of the model
#   a  物种参照气候梯度是怎么来的: 省异常 − 物种分布区异常, 用真实物种举例
#   b  它确实是物种特异的: 方差在"省-年之间"与"省-年内部(纯物种差异)"的分配
#   c  自然单位下的偏效应: 风险 vs 相对变暖(°C) 与 风险 vs 访问次数
#   d  层级方差 → 风险倍数, 每一层标注其生态/观测含义
#
# Fig6 观测过程的可视化 / The observation process made visible
#   a  物种随机截距按迁徙类型: 固有可发现性的物种间差异
#   b  省随机截距地图: 地区基线发现环境
#   c  省×年随机截距热图: 观测过程的时空冲击 —— 主模型中最大的方差来源
#   d  努力边际产出随时间递减: 比例风险检验揭示的实质结果
#
# Input / 输入:  analysis_v2/data/{model_v2_thr50.parquet, components_v2_*, fit_R3*.rds}
#                analysis_final/data/panel_full_{grid,species}.csv
# Output / 输出: analysis_v2/figures/Fig{5,6}_*.{png,pdf,svg,pptx} + source data
#
# Main packages / 主要包: data.table, ggplot2, patchwork, glmmTMB, sf, officer, rvg
# 运行 / Run: Rscript --no-init-file code/143_ecological_anatomy_figures.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(ggplot2); library(glmmTMB)
  library(patchwork); library(sf); library(officer); library(rvg)
})
options(warn = 1); sf::sf_use_s2(FALSE)

V2  <- normalizePath(".", mustWork = TRUE)
RB  <- file.path(V2, "analysis_rebuilt"); FN <- file.path(V2, "analysis_final")
OUT <- file.path(V2, "analysis_v2"); FIG <- file.path(OUT, "figures")
SHP <- file.path(V2, "data", "spatial", "basemap_GS2019_1822")
msg <- function(...) cat(sprintf("[143 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

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

# ---------------- 数据 ----------------
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
msg("数据 ", format(nrow(d), big.mark = ","), " 行 | 1 SD 累积变暖 = ", round(CC_SD, 3), " °C")

# =====================================================================
# Fig 5  模型解剖
# =====================================================================
# ---- 5a 梯度的构造, 真实物种举例 ----
gp  <- fread(file.path(FN, "data", "panel_full_grid.csv"))[indicator == "tavg_annual"]
g2p <- fread(file.path(RB, "data", "grid_province_lookup.csv"), encoding = "UTF-8")
gp  <- merge(gp, g2p[, .(grid_cell, province, olap)], by = "grid_cell")
prov <- gp[, .(T_t = stats::weighted.mean(val, olap, na.rm = TRUE),
               T_base = stats::weighted.mean(baseline, olap, na.rm = TRUE)), by = .(province, year)]
spn <- fread(file.path(FN, "data", "panel_full_species.csv"))[indicator == "tavg_annual",
        .(species, year, N_t = val, N_base = baseline)]

EX_PROV <- "Yunnan"; EX_HI <- "Aethopyga christinae"; EX_LO <- "Coracias garrulus"
# 画 15 年滑动均值 —— 这正是 clim_change 用的量, 年际噪声会掩盖概念
# plot the 15-year trailing means, which is exactly what clim_change uses
roll15 <- function(dt) { setorder(dt, year); dt[, anom := frollmean(anom, 15, align = "right")]; dt[!is.na(anom)] }
pv <- roll15(prov[province == EX_PROV, .(year, anom = T_t - T_base, who = paste0(EX_PROV, " (province)"))])
s1 <- roll15(spn[species == EX_HI, .(year, anom = N_t - N_base, who = paste0(EX_HI, " (range)"))])
s2 <- roll15(spn[species == EX_LO, .(year, anom = N_t - N_base, who = paste0(EX_LO, " (range)"))])
ex <- rbindlist(list(pv, s1, s2))
ex[, who := factor(who, levels = c(paste0(EX_PROV, " (province)"),
                                   paste0(EX_HI, " (range)"), paste0(EX_LO, " (range)")))]
gap_hi <- pv[year == 2020]$anom - s1[year == 2020]$anom
gap_lo <- pv[year == 2020]$anom - s2[year == 2020]$anom
p5a <- ggplot(ex, aes(year, anom, colour = who)) +
  geom_hline(yintercept = 0, colour = "grey65", linewidth = 0.3) +
  geom_line(linewidth = 0.75) +
  scale_colour_manual(values = unname(OI[c("grey", "red", "blue")]), name = NULL) +
  annotate("segment", x = 2020, xend = 2020, y = s1[year == 2020]$anom, yend = pv[year == 2020]$anom,
           colour = OI[["red"]], linewidth = 0.7, arrow = arrow(length = unit(3.5, "pt"), ends = "both")) +
  annotate("segment", x = 2022.4, xend = 2022.4, y = s2[year == 2020]$anom, yend = pv[year == 2020]$anom,
           colour = OI[["blue"]], linewidth = 0.7, arrow = arrow(length = unit(3.5, "pt"), ends = "both")) +
  annotate("text", x = 2019.4, y = pv[year == 2020]$anom, hjust = 1, vjust = -0.3, size = 2.4,
           colour = OI[["red"]], label = sprintf("x = %+.2f °C", gap_hi)) +
  annotate("text", x = 2023.2, y = mean(c(s2[year == 2020]$anom, pv[year == 2020]$anom)),
           hjust = 0, size = 2.4, colour = OI[["blue"]], label = sprintf("x = %+.2f °C", gap_lo)) +
  scale_x_continuous(limits = c(1994, 2027), breaks = seq(1995, 2025, 10)) +
  labs(x = NULL, y = "15-yr mean anomaly vs 1980-2000 (°C)",
       title = "The climate variable is referenced to each species' own range",
       subtitle = "Same province, same year, opposite sign for two species") +
  theme_pub() + theme(legend.position = c(0.34, 0.92), legend.text = element_text(size = 6.2),
                      legend.key.height = unit(7, "pt"))

# ---- 5b 方差分解: 物种维度贡献多少 ----
vp <- function(v) {
  tot <- var(d[[v]])
  btw <- var(d[, mean(get(v)), by = .(province, year)]$V1)
  wth <- mean(d[, .(vv = var(get(v)), n = .N), by = .(province, year)][n > 1]$vv)
  data.table(variable = v, source = c("Between province-years\n(regional climate)",
                                      "Within province-year\n(purely among species)"),
             share = c(btw / tot, wth / tot))
}
vpart <- rbindlist(lapply(c("x", "clim_change", "clim_var"), vp))
# 组内方差用的是各省-年组的平均, 与组间方差之和只近似等于总方差, 故归一化到 100%
# NB: the within-group term is a mean across groups, so the two shares sum to
#     approximately (not exactly) 1; rescale so the bars read as a partition.
vpart[, share := share / sum(share), by = variable]
vpart[, variable := factor(variable, levels = c("clim_change", "clim_var", "x"),
      labels = c("Accumulated\nwarming", "Annual\nvariability", "Raw\ngradient x"))]
p5b <- ggplot(vpart, aes(variable, share, fill = source)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = sprintf("%.0f%%", 100 * share)),
            position = position_stack(vjust = 0.5), size = 2.7, colour = "white", fontface = "bold") +
  scale_fill_manual(values = unname(OI[c("grey", "green")]), name = NULL) +
  scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.02))) +
  labs(x = NULL, y = "Share of variance",
       title = "Species identity carries much of the signal",
       subtitle = "A purely regional variable would have no green band") +
  theme_pub() + theme(legend.position = "right", panel.grid.major.y = element_blank(),
                      legend.text = element_text(size = 6.5))

# ---- 5c 自然单位的偏效应 ----
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
p5c <- ggplot(gc1, aes(cc_deg, 100 * haz, colour = eff_lab, fill = eff_lab)) +
  geom_vline(xintercept = 0, linetype = 3, colour = "grey65", linewidth = 0.3) +
  geom_ribbon(aes(ymin = 100 * lo, ymax = 100 * hi), alpha = 0.14, colour = NA) +
  geom_line(linewidth = 0.7) +
  scale_colour_manual(values = unname(OI[c("sky", "blue", "red")]), name = "Survey effort") +
  scale_fill_manual(values = unname(OI[c("sky", "blue", "red")]), guide = "none") +
  labs(x = "Province warmed more than the species' range (°C)",
       y = "Annual hazard of a new record (%)",
       title = "Effect sizes in units a reader can picture",
       subtitle = sprintf("One SD of accumulated warming is %.2f °C; one SD of effort multiplies annual visits by %.1f", CC_SD, exp(LV_SD))) +
  theme_pub() + theme(legend.position = c(0.28, 0.84))

# ---- 5d 层级方差 → 风险倍数 ----
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
hb[, term := factor(term, levels = rev(hb$term))]
p5d <- ggplot(hb, aes(mult, term, fill = is.na(sd))) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
  geom_col(width = 0.55) +
  geom_text(aes(label = sprintf("x%.2f", mult)), hjust = -0.18, size = 2.7, colour = "grey20") +
  scale_fill_manual(values = c(`FALSE` = OI[["blue"]], `TRUE` = OI[["grey"]]), guide = "none") +
  scale_x_continuous(limits = c(0, 2.7)) +
  labs(x = "Hazard multiplier per 1 SD", y = NULL,
       title = "The observation process outweighs either driver",
       subtitle = "One SD of province-by-year shock multiplies the hazard by 2.23, more than warming or effort") +
  theme_pub() + theme(panel.grid.major.y = element_blank())

F5 <- (p5a | p5b) / (p5c | p5d) + plot_annotation(tag_levels = "a")
save_fig(F5, "Fig5_model_anatomy_v2", 11.2, 7.8, src = rbind(vpart, hb, fill = TRUE))

# =====================================================================
# Fig 6  观测过程的可视化
# =====================================================================
re <- ranef(m)$cond
sp_b <- data.table(species = rownames(re$species), b = re$species[[1]])
sp_b <- merge(sp_b, unique(d[, .(species, mig_grp)]), by = "species", all.x = TRUE)
sp_b[, mig_grp := factor(as.character(mig_grp),
     levels = c("Resident", "Partial", "Long-distance", "Unknown"))]
lab_sp <- rbind(sp_b[order(-b)][1:4], sp_b[order(b)][1:3])
p6a <- ggplot(sp_b[!is.na(mig_grp)], aes(mig_grp, exp(b), colour = mig_grp)) +
  geom_hline(yintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
  geom_violin(fill = NA, linewidth = 0.35) +
  geom_jitter(width = 0.18, size = 0.5, alpha = 0.45) +
  stat_summary(fun = median, geom = "point", size = 2.2, shape = 18, colour = "grey15") +
  scale_colour_manual(values = unname(OI[c("green", "orange", "blue", "grey")]), guide = "none") +
  scale_y_continuous(trans = "log2", breaks = c(0.75, 1, 1.5, 2, 2.7)) +
  labs(x = NULL, y = "Species hazard multiplier",
       title = "Intrinsic detectability differs among species",
       subtitle = "Species random intercepts; diamond is the group median") +
  theme_pub() + theme(axis.text.x = element_text(angle = 15, hjust = 1))

pv_b <- data.table(province = rownames(re$province), b = re$province[[1]])
PROV_CN_EN <- c("北京市"="Beijing","天津市"="Tianjin","河北省"="Hebei","山西省"="Shanxi",
 "内蒙古自治区"="Inner Mongolia","辽宁省"="Liaoning","吉林省"="Jilin","黑龙江省"="Heilongjiang",
 "上海市"="Shanghai","江苏省"="Jiangsu","浙江省"="Zhejiang","安徽省"="Anhui","福建省"="Fujian",
 "江西省"="Jiangxi","山东省"="Shandong","河南省"="Henan","湖北省"="Hubei","湖南省"="Hunan",
 "广东省"="Guangdong","广西壮族自治区"="Guangxi","海南省"="Hainan","重庆市"="Chongqing",
 "四川省"="Sichuan","贵州省"="Guizhou","云南省"="Yunnan","西藏自治区"="Tibet","陕西省"="Shaanxi",
 "甘肃省"="Gansu","青海省"="Qinghai","宁夏回族自治区"="Ningxia","新疆维吾尔自治区"="Xinjiang",
 "台湾省"="Taiwan","香港特别行政区"="Hong Kong","澳门特别行政区"="Macau")
p6b <- tryCatch({
  pvsf <- st_make_valid(st_transform(st_read(file.path(SHP, "省（等积投影）.shp"), quiet = TRUE), 4326))
  pvsf$province <- unname(PROV_CN_EN[as.character(pvsf[["省"]])])
  outline <- tryCatch(st_transform(st_read(file.path(SHP, "中国轮廓线.shp"), quiet = TRUE), 4326), error = function(e) NULL)
  nanhai  <- tryCatch(st_transform(st_read(file.path(SHP, "九段线.shp"), quiet = TRUE), 4326), error = function(e) NULL)
  mp <- merge(pvsf[, "province"], pv_b, by = "province", all.x = TRUE)
  ggplot() +
    geom_sf(data = mp, aes(fill = exp(b)), colour = "grey45", linewidth = 0.1) +
    { if (!is.null(outline)) geom_sf(data = outline, fill = NA, colour = "grey15", linewidth = 0.28) } +
    { if (!is.null(nanhai))  geom_sf(data = nanhai,  fill = NA, colour = "grey15", linewidth = 0.38) } +
    scale_fill_distiller(palette = "RdYlBu", direction = -1, na.value = "grey93",
                         trans = "log2", breaks = c(0.75, 1, 1.5, 2), name = "Province\nmultiplier") +
    coord_sf(xlim = c(72, 136), ylim = c(2.5, 54)) +
    labs(title = "Regional baselines after controlling for effort and climate",
         subtitle = "Province random intercepts. Base map GS(2019)1822",
         caption = "Grey: outside the analysis scope (Taiwan, Hong Kong, Macao have no effort coverage)") +
    theme_void(base_size = 9) +
    theme(plot.title = element_text(face = "bold", size = 10, hjust = 0),
          plot.subtitle = element_text(size = 8, colour = "grey30", hjust = 0),
          plot.caption = element_text(size = 6.5, colour = "grey35", hjust = 0),
          legend.key.width = unit(8, "pt"))
}, error = function(e) { msg("  map failed: ", conditionMessage(e)); ggplot() + theme_void() })

# NB: 列名不能叫 key —— 那是 data.table() 的保留参数
py_b <- data.table(lvl = rownames(re$prov_year), b = re$prov_year[[1]])
py_b[, c("province", "year") := tstrsplit(lvl, "\\.", keep = 1:2)]
py_b[, year := as.integer(year)]
ord <- py_b[, .(m = mean(b)), by = province][order(m)]$province
py_b[, province := factor(province, levels = ord)]
p6c <- ggplot(py_b, aes(year, province, fill = exp(b))) +
  geom_tile(colour = "white", linewidth = 0.25) +
  scale_fill_distiller(palette = "RdYlBu", direction = -1, trans = "log2",
                       breaks = c(0.6, 1, 2, 4, 7), name = "Multiplier") +
  scale_x_continuous(breaks = seq(2002, 2024, 4), expand = c(0, 0)) +
  labs(x = NULL, y = NULL,
       title = "Where and when the observation process actually moved",
       subtitle = "Province-by-year random intercepts, the largest variance component (SD 0.804, spanning a 7-fold range)") +
  theme_pub(8) + theme(panel.grid = element_blank(), axis.text.y = element_text(size = 5.6))

mtv <- tryCatch(readRDS(file.path(OUT, "data", "fit_R3_time_varying.rds")), error = function(e) NULL)
p6d <- if (!is.null(mtv)) {
  cf <- fixef(mtv)$cond; Vt <- vcov(mtv)$cond
  yrs <- 2002:2024; yc <- (yrs - mean(d$year)) / stats::sd(d$year)
  nm <- c("effort_z", "effort_z:year_c")
  nm <- nm[nm %in% names(cf)]
  if (length(nm) < 2) nm <- c("effort_z", grep("^effort_z:", names(cf), value = TRUE)[1])
  b_t <- cf[[nm[1]]] + cf[[nm[2]]] * yc
  Vs <- Vt[nm, nm]
  se_t <- sqrt(Vs[1, 1] + yc^2 * Vs[2, 2] + 2 * yc * Vs[1, 2])
  dt <- data.table(year = yrs, hr = exp(b_t), lo = exp(b_t - 1.96 * se_t), hi = exp(b_t + 1.96 * se_t))
  ggplot(dt, aes(year, hr)) +
    geom_hline(yintercept = 1, linetype = 2, colour = "grey55", linewidth = 0.35) +
    geom_ribbon(aes(ymin = lo, ymax = hi), fill = OI[["blue"]], alpha = 0.16) +
    geom_line(colour = OI[["blue"]], linewidth = 0.7) +
    labs(x = NULL, y = "Hazard ratio per 1 SD of effort",
         title = "The return on survey effort is falling",
         subtitle = "Effort x time interaction P = 7.7e-4; easily detectable gaps are being used up") +
    theme_pub()
} else ggplot() + theme_void()

F6 <- (p6a | p6b) / (p6c | p6d) + plot_annotation(tag_levels = "a") +
  plot_layout(heights = c(1, 1.15))
save_fig(F6, "Fig6_observation_process_v2", 11.6, 8.4,
         src = rbind(sp_b[, .(level = species, group = as.character(mig_grp), term = "species", b)],
                     pv_b[, .(level = province, group = NA_character_, term = "province", b)],
                     py_b[, .(level = lvl, group = NA_character_, term = "province_year", b)]))

msg("Fig5 / Fig6 written | DONE")
