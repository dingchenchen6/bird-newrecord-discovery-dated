#!/usr/bin/env Rscript
# ============================================================
# Scientific question / 科学问题:
#   在“气候情景 × 调查努力情景”下, 各省与各地级市未来每年预期产生多少条鸟类新纪录?哪些预测仍在模型拟合的支撑域内?
#   Under combined climate and survey-effort scenarios, how many new bird records per year are expected
#   in each province and prefecture, and which predictions stay inside the fitted covariate support?
#
# Objective / 分析目标:
#   按 CBNR 数据论文图 2a 的地图规范重画未来预测地图(Albers 等积投影 25°/47°N、105°E;虚线经纬网;
#   细黑省界;十段线;右下带框南海小图;Arial;面板外框), 色带用冷暖对比更强的 ColorBrewer RdYlBu(反向),
#   去掉支撑域打点(支撑域比例写在每幅图上方), 数值不变, 只改呈现:
#   (1) 省级 2 × 4:2030/2050 × {SSP2-4.5, SSP5-8.5} × {努力停滞, 努力延续};
#   (2) 地级市:2030 年 SSP2-4.5、努力延续(份额冻结在 2024 年机制模型分配);
#   印刷版为英文(180 mm 版宽, 400 dpi);演示版有中文(工作流)与英文(AOC 报告)两套, 大字号, 只保留主要面板。
#   Redraw the future maps to the CBNR map standard without changing any value; English print versions
#   and Chinese and English slide versions with large type and only the main panels.
#
# Input data / 输入数据:
#   analysis_v2/tables/tbl_future_scenario_grid.csv(脚本 187:省 × 情景的期望新纪录数与支撑域比例)
#   analysis_v2/data/admin/prefecture_surface_now.csv(2024 年地级市分配份额)、units_county.csv(省名对照)
#   data/spatial/cbnr_basemap/(CBNR 图 2a 所用省界与十段线, GS(2019)1822);
#   data/spatial/basemap_GS2019_1822/市(等积投影).shp(地级市边界)
# Main workflow / 主要流程: 读表与底图 → 支撑域打点 → 单幅地图 + 南海小图 → 拼版 → 印刷版与演示版导出
# Expected output / 预期输出: analysis_v2/figures_refined/{print_en,slide_zh,slide_en}/Fig_future_*.{png,pdf}, source_data/
# Key assumptions / 关键假设:
#   与 187 相同:省 × 年随机项取期望;支撑域为拟合样本 1–99% 分位;地级市采用“份额冻结”(只有省级期望随情景变化)。
#   支撑域比例(落在拟合样本 1–99% 分位内的物种行)标在每幅图上方, 源数据表给出逐省比例;港澳台无努力覆盖, 不作预测(浅灰)。
#   色带取对数刻度;印刷版 2 × 4 共用 0.4–7, 演示版只有 2030 年, 用 0.4–2.1 使颜色铺满色带。
# Main packages / 主要包: sf, ggplot2, cowplot, ggrepel(描边标注 / halo labels), data.table, readxl, ragg
# Output directory / 输出路径: analysis_v2/figures_refined/
#
# Run / 运行: Rscript --no-init-file code/234_future_maps_cbnr_style.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(sf); library(ggplot2); library(cowplot); library(readxl); library(scales); library(ragg)
})
sf_use_s2(FALSE)

V2  <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
CB  <- file.path(V2, "data/spatial/cbnr_basemap")
BM  <- file.path(V2, "data/spatial/basemap_GS2019_1822")
OUT <- file.path(V2, "analysis_v2/figures_refined")
for (d in c("print_en", "slide_zh", "slide_en", "source_data")) dir.create(file.path(OUT, d), recursive = TRUE, showWarnings = FALSE)
AEA <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +datum=WGS84 +units=m +no_defs"
# 冷 → 暖色带:ColorBrewer RdYlBu 反向 11 级(色觉障碍友好)/ cold-to-warm ColorBrewer RdYlBu, reversed, 11 classes
FILL <- c("#313695", "#4575B4", "#74ADD1", "#ABD9E9", "#E0F3F8", "#FFFFBF", "#FEE090", "#FDAE61", "#F46D43", "#D73027", "#A50026")
NA_FILL <- "#EDEDED"

# ---------------- 底图(CBNR 规范)/ base map (CBNR standard) ----------------
china <- st_transform(st_read(file.path(CB, "province_boundaries.shp"), quiet = TRUE), AEA)
ten   <- st_transform(st_read(file.path(CB, "ten_dash_line.shp"), quiet = TRUE), AEA)
pref  <- st_make_valid(st_transform(st_read(file.path(BM, "市（等积投影）.shp"), quiet = TRUE), AEA))
pref$unit_id <- as.integer(pref[["市代码"]])
nm_map <- as.data.table(read_excel(file.path(CB, "province_name_mapping.xls")))[, .(name = NAME, en = Province_EN)]
nm_map[en == "Tibet", en := "Xizang"]
grat <- st_graticule(lon = seq(75, 135, 15), lat = seq(15, 60, 15), crs = st_crs(AEA), datum = st_crs(4326))
bb_c <- st_bbox(china); bb_t <- st_bbox(ten)
xl <- c(bb_c["xmin"] - 0.03 * diff(bb_c[c("xmin", "xmax")]), bb_c["xmax"] + 0.02 * diff(bb_c[c("xmin", "xmax")]))
yl <- c(bb_t["ymin"] - 0.03 * diff(bb_c[c("ymin", "ymax")]), bb_c["ymax"] + 0.03 * diff(bb_c[c("ymin", "ymax")]))
XL <- c(xl[1] + 0.03 * diff(xl), xl[2] - 0.055 * diff(xl))          # 与 CBNR 图 2a 相同的主图范围
YL <- c(yl[1] + 0.17 * diff(yl), yl[2] - 0.03 * diff(yl))           # same main-map extent as CBNR Fig. 2a
XL[2] <- XL[2] + 0.17 * diff(XL)   # 框向东外扩, 给南海小图留出海域(同 CBNR 图 2a 的版面)/ room for the inset, as in CBNR
ins_bb <- st_bbox(st_transform(st_as_sfc(st_bbox(c(xmin = 105, xmax = 125, ymin = 3, ymax = 25), crs = st_crs(4326))), AEA))

# 经纬度标注:经纬线与面板框的交点, 标在框内 / graticule labels where the lines meet the frame, inside it
glab <- function() {
  g <- st_transform(grat, AEA); crs <- st_crs(g)
  bottom <- st_sfc(st_linestring(rbind(c(XL[1], YL[1]), c(XL[2], YL[1]))), crs = crs)
  left   <- st_sfc(st_linestring(rbind(c(XL[1], YL[1]), c(XL[1], YL[2]))), crs = crs)
  mer <- g[g$type == "E" & g$degree %in% c(90, 105, 120), ]
  par <- g[g$type == "N" & g$degree %in% c(30, 45), ]
  pm <- suppressWarnings(st_intersection(mer, bottom)); pp <- suppressWarnings(st_intersection(par, left))
  cm <- st_coordinates(pm); cp <- st_coordinates(pp)
  list(lon = data.table(X = cm[, "X"], Y = cm[, "Y"], lab = paste0(pm$degree, "°E")),
       lat = data.table(X = cp[, "X"], Y = cp[, "Y"], lab = paste0(pp$degree, "°N")))
}
GL <- glab()

# 省名位置:CBNR 图 2a 的逐省定位 / province label positions from CBNR Figure 2a
LABPOS <- data.table(
  name = c("安徽省", "北京市", "重庆市", "福建省", "甘肃省", "广东省", "广西壮族自治区", "贵州省", "海南省", "河北省",
           "黑龙江省", "河南省", "香港特别行政区", "湖北省", "湖南省", "内蒙古自治区", "江苏省", "江西省", "吉林省", "辽宁省",
           "宁夏回族自治区", "青海省", "陕西省", "山东省", "上海市", "山西省", "四川省", "台湾省", "天津市",
           "新疆维吾尔自治区", "西藏自治区", "云南省", "浙江省"),
  lon = c(117.3, 116.2, 107.7, 117.9, 99, 114.2, 107.9, 106.7, 110.2, 115.3, 127.6, 113.8, 115.35, 112.2, 111.4,
          108.4, 119.6, 115.8, 126.7, 123.3, 105.86, 96.2, 108.4, 118.2, 122.1, 112, 102, 121.75, 118.4, 86.1, 88.3,
          101.2, 119.9),
  lat = c(31.6, 40.45, 29.6, 26, 39.2, 23.5, 24.1, 26.75, 18.3, 38.5, 47.34, 33.8, 21.9, 31.05, 27.6, 41.7, 33.3,
          27.6, 43.25, 41.4, 37.19, 35.5, 34.6, 36.2, 31.1, 36.3, 30.3, 23.5, 39.15, 42.2, 31.5, 25.26, 29.2),
  hjust = c(rep(0.5, 24), 0, 0.5, 0.5, 0, 0, 0.5, 0.5, 0.5, 0.5))
xy <- st_coordinates(st_transform(st_as_sf(LABPOS, coords = c("lon", "lat"), crs = 4326), AEA))
LABPOS[, `:=`(x = xy[, 1], y = xy[, 2])]
LABPOS <- merge(LABPOS, nm_map, by = "name", all.x = TRUE)
LABPOS[, zh := sub("(壮族自治区|回族自治区|维吾尔自治区|特别行政区|自治区|省|市)$", "", name)]

# ---------------- 数据 / data ----------------
grid <- fread(file.path(V2, "analysis_v2/tables/tbl_future_scenario_grid.csv"))
lk <- unique(fread(file.path(V2, "analysis_v2/data/admin/units_county.csv"))[, .(province, prov_cn)])
grid <- merge(grid, lk, by = "province")
stopifnot(all(grid$prov_cn %in% china$name), uniqueN(grid$province) == 31)
nat <- grid[, .(total = sum(exp_n), sup = sum(pct_sup * n_sp) / sum(n_sp)), by = .(ssp, eff, horizon)]
share <- fread(file.path(V2, "analysis_v2/data/admin/prefecture_surface_now.csv"))[, .(unit_id, province, unit_nm, share)]
stopifnot(abs(share[, sum(share), by = province]$V1 - 1) < 1e-6)

# ---------------- 单幅地图 / one map ----------------
map_one <- function(fill_sf, lims, s, labels = NULL, pref_mode = FALSE, frame = TRUE, glabels = FALSE) {
  g <- ggplot() +
    geom_sf(data = grat, colour = "#9A9A9A", linewidth = s$lw_grat, linetype = "dashed") +
    geom_sf(data = china, fill = NA_FILL, colour = NA) +
    geom_sf(data = fill_sf, aes(fill = pmin(pmax(val, lims[1]), lims[2])),
            colour = if (pref_mode) "white" else NA, linewidth = s$lw_pref) +
    geom_sf(data = china, fill = NA, colour = "#000000", linewidth = s$lw_prov) +
    geom_sf(data = ten, colour = "#6E6E6E", linewidth = s$lw_ten)
  # 省名加白色描边, 压在深色与省界上仍可读;force = 0 保持 CBNR 定位, 不做避让
  # province names get a white halo so they stay legible on dark fills; force = 0 keeps the CBNR positions
  if (!is.null(labels)) g <- g + ggrepel::geom_text_repel(
    data = labels, aes(x, y, label = lab, hjust = hjust), family = s$fam, size = s$prov_lab / .pt, colour = "#000000",
    bg.colour = "white", bg.r = 0.12, force = 0, force_pull = 0, max.overlaps = Inf, min.segment.length = Inf, seed = 1)
  if (glabels) g <- g +
    geom_text(data = GL$lon, aes(X, Y, label = lab), family = s$fam, size = s$grat_lab / .pt, colour = "#555555",
              vjust = -0.5, hjust = -0.08) +
    geom_text(data = GL$lat, aes(X, Y, label = lab), family = s$fam, size = s$grat_lab / .pt, colour = "#555555",
              angle = 90, vjust = 1.4, hjust = -0.08)
  g + scale_fill_gradientn(colours = FILL, trans = "log10", limits = lims, oob = squish, na.value = NA_FILL, guide = "none") +
    coord_sf(crs = st_crs(AEA), xlim = XL, ylim = YL, expand = FALSE, clip = "on") +
    theme_void(base_family = s$fam) +
    theme(panel.border = if (frame) element_rect(colour = "#000000", fill = NA, linewidth = s$lw_frame) else element_blank(),
          plot.margin = margin(0, 0, 0, 0))
}
inset_one <- function(fill_sf, lims, s, pref_mode = FALSE) {
  ggplot() +
    geom_sf(data = suppressWarnings(st_crop(china, ins_bb)), fill = NA_FILL, colour = NA) +
    geom_sf(data = suppressWarnings(st_crop(fill_sf, ins_bb)), aes(fill = pmin(pmax(val, lims[1]), lims[2])),
            colour = if (pref_mode) "white" else NA, linewidth = s$lw_pref) +
    geom_sf(data = suppressWarnings(st_crop(china, ins_bb)), fill = NA, colour = "#000000", linewidth = s$lw_prov) +
    geom_sf(data = suppressWarnings(st_crop(ten, ins_bb)), colour = "#6E6E6E", linewidth = s$lw_ten * 0.9) +
    scale_fill_gradientn(colours = FILL, trans = "log10", limits = lims, oob = squish, na.value = NA_FILL, guide = "none") +
    coord_sf(crs = st_crs(AEA), xlim = ins_bb[c("xmin", "xmax")], ylim = ins_bb[c("ymin", "ymax")], expand = FALSE) +
    theme_void() + theme(panel.border = element_rect(colour = "#000000", fill = "white", linewidth = s$lw_frame * 0.9),
                         panel.background = element_rect(fill = "white", colour = NA))
}
# 南海小图作为图层嵌在地图坐标系中, 始终贴着框的右下角 / the inset is placed in map coordinates,
# so it always sits in the lower-right corner of the frame whatever the canvas shape
INS_R <- unname(diff(ins_bb[c("xmin", "xmax")]) / diff(ins_bb[c("ymin", "ymax")]))
TW_Y <- st_coordinates(st_transform(st_as_sf(data.frame(lon = 121, lat = 21.6), coords = c("lon", "lat"), crs = 4326), AEA))[2]
with_inset <- function(m, i, h = 0.30) {
  dX <- diff(XL); dY <- diff(YL)
  hh <- min(h * dY, TW_Y - YL[1] - 0.02 * dY)      # 小图顶端低于台湾南端 / keep the inset below Taiwan
  ww <- hh * INS_R
  m + annotation_custom(ggplotGrob(i), xmin = XL[2] - 0.006 * dX - ww, xmax = XL[2] - 0.006 * dX,
                        ymin = YL[1] + 0.008 * dY, ymax = YL[1] + 0.008 * dY + hh)
}

legend_bar <- function(lims, breaks, title, s, width_in) {
  v <- 10^seq(log10(lims[1]), log10(lims[2]), length.out = 200)
  d <- data.table(x0 = seq(0, 1, length.out = 201)[-201], x1 = seq(0, 1, length.out = 201)[-1], v = v)
  pos <- (log10(breaks) - log10(lims[1])) / diff(log10(lims))
  ggplot() + geom_rect(data = d, aes(xmin = x0, xmax = x1, ymin = 0, ymax = 1, fill = v)) +
    scale_fill_gradientn(colours = FILL, trans = "log10", limits = lims, guide = "none") +
    annotate("segment", x = pos, xend = pos, y = 0, yend = -0.25, linewidth = 0.3) +
    annotate("text", x = pos, y = -0.45, label = format(breaks, drop0trailing = TRUE), vjust = 1,
             size = s$leg_txt / .pt, family = s$fam) +
    annotate("text", x = 0, y = 1.35, label = title, hjust = 0, vjust = 0, size = s$leg_title / .pt,
             family = s$fam, fontface = "bold") +
    coord_cartesian(xlim = c(-0.02, 1.02), ylim = c(-1.6, 2.4), expand = FALSE, clip = "off") + theme_void()
}

prov_sf <- function(ss, ee, hh) {
  d <- grid[ssp == ss & eff == ee & horizon == hh, .(name = prov_cn, val = exp_n, pct_sup)]
  merge(china, d, by = "name")
}

S_EN <- list(fam = "Arial", lw_grat = 0.15, lw_prov = 0.12, lw_pref = 0.05, lw_ten = 0.3, lw_frame = 0.4,
             prov_lab = 5.2, grat_lab = 5, leg_txt = 6, leg_title = 6.5, head = 6.8, sub = 5.8)
S_ZH <- list(fam = "Hiragino Sans GB", lw_grat = 0.25, lw_prov = 0.22, lw_pref = 0.08, lw_ten = 0.5, lw_frame = 0.7,
             prov_lab = 8.8, grat_lab = 9, leg_txt = 13, leg_title = 14, head = 16, sub = 13)
SC <- data.table(ssp = c("ssp245", "ssp245", "ssp585", "ssp585"), eff = rep(c("Effort frozen", "Effort continuing"), 2))
SC[, en := sprintf("%s · effort %s", ifelse(ssp == "ssp245", "SSP2-4.5", "SSP5-8.5"),
                   ifelse(eff == "Effort frozen", "frozen", "continuing"))]
P_LIMS <- c(0.4, 7); P_BRK <- c(0.5, 1, 2, 5)       # 印刷版 2 × 4 共用 / shared by the print 2 × 4
S_LIMS <- c(0.4, 2.1); S_BRK <- c(0.5, 1, 2)       # 演示版只有 2030 年 / slides show 2030 only

# ---------------- 图 1 印刷版:省级 2 × 4 / Figure 1 print: provinces, 2 × 4 ----------------
cells <- list(); k <- 0
for (hh in c(2030L, 2050L)) for (j in seq_len(nrow(SC))) {
  k <- k + 1
  ss <- SC$ssp[j]; ee <- SC$eff[j]; n0 <- nat[ssp == ss & eff == ee & horizon == hh]
  m <- with_inset(map_one(prov_sf(ss, ee, hh), P_LIMS, S_EN), inset_one(prov_sf(ss, ee, hh), P_LIMS, S_EN))
  cells[[k]] <- ggdraw() + draw_plot(m, 0, 0, 1, 0.86) +
    draw_label(letters[k], x = 0.01, y = 0.985, hjust = 0, vjust = 1, fontfamily = "Arial", fontface = "bold", size = 8) +
    draw_label(sprintf("%.1f records per year · %d%% in support", n0$total, round(100 * n0$sup)), x = 0.07, y = 0.915,
               hjust = 0, vjust = 0.5, fontfamily = "Arial", size = S_EN$sub, colour = "#333333")
}
head_row <- plot_grid(plotlist = lapply(SC$en, function(t) ggdraw() + draw_label(t, fontfamily = "Arial", fontface = "bold",
                                                                                  size = S_EN$head)), nrow = 1)
row_lab <- function(t) ggdraw() + draw_label(t, angle = 90, fontfamily = "Arial", fontface = "bold", size = 7.5)
body <- plot_grid(row_lab("2030"), plot_grid(plotlist = cells[1:4], nrow = 1), row_lab("2050"),
                  plot_grid(plotlist = cells[5:8], nrow = 1), ncol = 2, rel_widths = c(0.03, 1))
leg <- plot_grid(legend_bar(P_LIMS, P_BRK, "Expected new provincial records per year", S_EN, 2.4),
                 ggdraw() + draw_label("Percentages: share of species rows inside the fitted covariate support\nGrey: no effort coverage (Hong Kong, Macao, Taiwan)",
                                       x = 0, hjust = 0, fontfamily = "Arial", size = S_EN$sub, colour = "#333333", lineheight = 1.1),
                 nrow = 1, rel_widths = c(0.42, 0.58))
F1 <- plot_grid(plot_grid(NULL, head_row, nrow = 1, rel_widths = c(0.03, 1)), body, leg, ncol = 1, rel_heights = c(0.06, 1, 0.13))
ggsave(file.path(OUT, "print_en", "Fig_future_provinces.png"), F1, width = 7.09, height = 3.95, dpi = 400, device = agg_png, bg = "white")
ggsave(file.path(OUT, "print_en", "Fig_future_provinces.pdf"), F1, width = 7.09, height = 3.95, device = cairo_pdf, bg = "white")

# ---------------- 图 2 印刷版:地级市 / Figure 2 print: prefectures ----------------
PREF_SC <- list(ssp = "ssp245", eff = "Effort continuing", hz = 2030L)
pv <- merge(share, grid[ssp == PREF_SC$ssp & eff == PREF_SC$eff & horizon == PREF_SC$hz, .(province, exp_n)], by = "province")
pv[, val := exp_n * share]
pf <- merge(pref[, c("unit_id")], pv[, .(unit_id, val, unit_nm, province)], by = "unit_id")
F_LIMS <- c(0.01, 1); F_BRK <- c(0.01, 0.03, 0.1, 0.3, 1)
lab_en <- LABPOS[!is.na(en) & name != "澳门特别行政区", .(x, y, lab = en, hjust)]
m2 <- with_inset(map_one(pf, F_LIMS, modifyList(S_EN, list(lw_prov = 0.2)), labels = lab_en, pref_mode = TRUE, glabels = TRUE),
                 inset_one(pf, F_LIMS, S_EN, pref_mode = TRUE))
n2 <- nat[ssp == PREF_SC$ssp & eff == PREF_SC$eff & horizon == PREF_SC$hz]
F2 <- ggdraw() + draw_plot(m2, 0, 0, 1, 1) +
  draw_plot(legend_bar(F_LIMS, F_BRK, "Expected new records per year", S_EN, 1.6), x = 0.05, y = 0.08, width = 0.26, height = 0.1) +
  draw_label(sprintf("SSP2-4.5 · effort continuing · 2030\nNational total %.1f records per year; %d%% of rows inside the support",
                     n2$total, round(100 * n2$sup)), x = 0.05, y = 0.96, hjust = 0, vjust = 1, fontfamily = "Arial",
             size = 6.5, lineheight = 1.15)
ggsave(file.path(OUT, "print_en", "Fig_future_prefectures.png"), F2, width = 7.09, height = 5.3, dpi = 400, device = agg_png, bg = "white")
ggsave(file.path(OUT, "print_en", "Fig_future_prefectures.pdf"), F2, width = 7.09, height = 5.3, device = cairo_pdf, bg = "white")

# ---------------- 演示版(中文)/ slide versions (Chinese) ----------------
lab_zh <- LABPOS[name != "澳门特别行政区", .(x, y, lab = zh, hjust)]
# 省级:2030 年 SSP2-4.5 努力停滞 vs 努力延续 / provinces: 2030, SSP2-4.5, effort frozen vs continuing
zcell <- function(ee, title) {
  n0 <- nat[ssp == "ssp245" & eff == ee & horizon == 2030L]
  m <- with_inset(map_one(prov_sf("ssp245", ee, 2030L), S_LIMS, S_ZH, labels = lab_zh),
                  inset_one(prov_sf("ssp245", ee, 2030L), S_LIMS, S_ZH))
  ggdraw() + draw_plot(m, 0, 0, 1, 0.86) +
    draw_label(title, x = 0.01, y = 0.97, hjust = 0, vjust = 1, fontfamily = "Hiragino Sans GB", fontface = "bold", size = S_ZH$head) +
    draw_label(sprintf("全国 %.1f 条/年 · 支撑域内 %d%%", n0$total, round(100 * n0$sup)), x = 0.01, y = 0.905, hjust = 0,
               vjust = 1, fontfamily = "Hiragino Sans GB", size = S_ZH$sub, colour = "#333333")
}
leg_z <- plot_grid(legend_bar(S_LIMS, S_BRK, "预期每年新纪录数(条)", S_ZH, 3),
                   ggdraw() + draw_label(sprintf("百分比:落在拟合支撑域内的物种行比例;浅灰:港澳台无努力数据。\nSSP5-8.5 下两种努力情景全国合计 %.1f 与 %.1f 条/年, 与 SSP2-4.5 几乎相同。",
                                                 nat[ssp == "ssp585" & eff == "Effort frozen" & horizon == 2030L]$total,
                                                 nat[ssp == "ssp585" & eff == "Effort continuing" & horizon == 2030L]$total),
                                         x = 0, hjust = 0, fontfamily = "Hiragino Sans GB", size = S_ZH$sub, colour = "#333333",
                                         lineheight = 1.2),
                   nrow = 1, rel_widths = c(0.36, 0.64))
FZ1 <- plot_grid(plot_grid(zcell("Effort frozen", "SSP2-4.5 · 努力停滞(冻结在 2024 年)"),
                           zcell("Effort continuing", "SSP2-4.5 · 努力延续(每十年 +0.6 SD)"), nrow = 1),
                 leg_z, ncol = 1, rel_heights = c(1, 0.17))
ggsave(file.path(OUT, "slide_zh", "Fig_future_provinces_zh.png"), FZ1, width = 12.2, height = 5.6, dpi = 220, device = agg_png, bg = "white")
ggsave(file.path(OUT, "slide_zh", "Fig_future_provinces_zh.pdf"), FZ1, width = 12.2, height = 5.6, device = cairo_pdf, bg = "white")

# 地级市:地图 + 前 15 名 / prefectures: map plus top 15
mz <- with_inset(map_one(pf, F_LIMS, modifyList(S_ZH, list(lw_prov = 0.35)), labels = lab_zh, pref_mode = TRUE),
                 inset_one(pf, F_LIMS, S_ZH, pref_mode = TRUE))
top <- pv[order(-val)][1:15]
top[, pz := LABPOS$zh[match(lk$prov_cn[match(province, lk$province)], LABPOS$name)]]
top[, lab := ifelse(startsWith(unit_nm, pz), unit_nm, sprintf("%s(%s)", unit_nm, pz))]   # 直辖市不重复省名
top[, lab := factor(lab, levels = rev(lab))]
bar <- ggplot(top, aes(val, lab, fill = val)) + geom_col(width = 0.72) +
  geom_text(aes(label = sprintf("%.2f", val)), hjust = -0.15, family = "Hiragino Sans GB", size = 12 / .pt) +
  scale_fill_gradientn(colours = FILL, trans = "log10", limits = F_LIMS, oob = squish, guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.22))) +
  labs(x = "预期每年新纪录数(条)", y = NULL, title = "前 15 个地级市") +
  theme_minimal(base_family = "Hiragino Sans GB", base_size = 13) +
  theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 15), axis.text.y = element_text(size = 12.5, colour = "#111111"))
FZ2 <- plot_grid(ggdraw() + draw_plot(mz, 0, 0.11, 1, 0.8) +
                   draw_plot(legend_bar(F_LIMS, F_BRK, "预期每年新纪录数(条)", S_ZH, 3), x = 0.03, y = 0, width = 0.5, height = 0.12) +
                   draw_label(sprintf("2030 年 · SSP2-4.5 · 努力延续:全国 %.1f 条/年", n2$total), x = 0.01, y = 0.99, hjust = 0,
                              vjust = 1, fontfamily = "Hiragino Sans GB", fontface = "bold", size = S_ZH$head),
                 bar, nrow = 1, rel_widths = c(1.55, 1))
ggsave(file.path(OUT, "slide_zh", "Fig_future_prefectures_zh.png"), FZ2, width = 12.2, height = 5.8, dpi = 220, device = agg_png, bg = "white")
ggsave(file.path(OUT, "slide_zh", "Fig_future_prefectures_zh.pdf"), FZ2, width = 12.2, height = 5.8, device = cairo_pdf, bg = "white")

# ---------------- 演示版(英文, AOC 报告用)/ slide versions (English, for the AOC talk) ----------------
# 版式与中文演示版相同;英文省名较长, 只标面积够大的省份(直辖市、宁夏、港澳不标)
# same layout as the Chinese slides; English names are long, so the small units are left unlabelled
S_ENS <- modifyList(S_ZH, list(fam = "Arial", prov_lab = 7.6))
lab_ens <- LABPOS[!is.na(en) & !name %in% c("北京市", "天津市", "上海市", "重庆市", "宁夏回族自治区", "香港特别行政区",
                                            "澳门特别行政区"), .(x, y, lab = en, hjust)]
ecell <- function(ee, title) {
  n0 <- nat[ssp == "ssp245" & eff == ee & horizon == 2030L]
  m <- with_inset(map_one(prov_sf("ssp245", ee, 2030L), S_LIMS, S_ENS, labels = lab_ens),
                  inset_one(prov_sf("ssp245", ee, 2030L), S_LIMS, S_ENS))
  ggdraw() + draw_plot(m, 0, 0, 1, 0.86) +
    draw_label(title, x = 0.01, y = 0.97, hjust = 0, vjust = 1, fontfamily = "Arial", fontface = "bold", size = S_ENS$head) +
    draw_label(sprintf("China %.1f records per year · %d%% of rows in support", n0$total, round(100 * n0$sup)), x = 0.01,
               y = 0.905, hjust = 0, vjust = 1, fontfamily = "Arial", size = S_ENS$sub, colour = "#333333")
}
leg_e <- plot_grid(legend_bar(S_LIMS, S_BRK, "Expected new records per year", S_ENS, 3),
                   ggdraw() + draw_label(sprintf("Percentages: share of species rows inside the fitted support. Grey: no effort data.\nUnder SSP5-8.5 the two effort scenarios give %.1f and %.1f records per year: almost the same.",
                                                 nat[ssp == "ssp585" & eff == "Effort frozen" & horizon == 2030L]$total,
                                                 nat[ssp == "ssp585" & eff == "Effort continuing" & horizon == 2030L]$total),
                                         x = 0, hjust = 0, fontfamily = "Arial", size = S_ENS$sub - 1, colour = "#333333",
                                         lineheight = 1.2),
                   nrow = 1, rel_widths = c(0.34, 0.66))
FE1 <- plot_grid(plot_grid(ecell("Effort frozen", "2030 · SSP2-4.5 · effort frozen at 2024"),
                           ecell("Effort continuing", "2030 · SSP2-4.5 · effort growing (+0.6 SD per decade)"), nrow = 1),
                 leg_e, ncol = 1, rel_heights = c(1, 0.17))
ggsave(file.path(OUT, "slide_en", "Fig_future_provinces_en.png"), FE1, width = 12.2, height = 5.6, dpi = 220, device = agg_png, bg = "white")
ggsave(file.path(OUT, "slide_en", "Fig_future_provinces_en.pdf"), FE1, width = 12.2, height = 5.6, device = cairo_pdf, bg = "white")

# 地级市英文名:只为可能进入前 15 的单元提供拼音名;缺名即报错, 不静默显示中文
# English prefecture names for units that can enter the top 15; a missing name stops the script
PREF_EN <- c("上海市" = "Shanghai", "重庆市" = "Chongqing", "北京市" = "Beijing", "天津市" = "Tianjin",
             "林芝市" = "Nyingchi", "汉中市" = "Hanzhong", "百色市" = "Baise", "苏州市" = "Suzhou", "杭州市" = "Hangzhou",
             "崇左市" = "Chongzuo", "遵义市" = "Zunyi", "怀化市" = "Huaihua", "陇南市" = "Longnan", "信阳市" = "Xinyang",
             "山南市" = "Shannan", "上饶市" = "Shangrao")
top_e <- pv[order(-val)][1:15]
miss <- setdiff(top_e$unit_nm, names(PREF_EN))
if (length(miss)) stop("[234] 缺少地级市英文名 / missing English names: ", paste(miss, collapse = ", "))
top_e[, pe := LABPOS$en[match(lk$prov_cn[match(province, lk$province)], LABPOS$name)]]
top_e[, lab := ifelse(PREF_EN[unit_nm] == pe, PREF_EN[unit_nm], sprintf("%s (%s)", PREF_EN[unit_nm], pe))]
top_e[, lab := factor(lab, levels = rev(lab))]
bar_e <- ggplot(top_e, aes(val, lab, fill = val)) + geom_col(width = 0.72) +
  geom_text(aes(label = sprintf("%.2f", val)), hjust = -0.15, family = "Arial", size = 12 / .pt) +
  scale_fill_gradientn(colours = FILL, trans = "log10", limits = F_LIMS, oob = squish, guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.22))) +
  labs(x = "Expected new records per year", y = NULL, title = "Top 15 prefectures") +
  theme_minimal(base_family = "Arial", base_size = 13) +
  theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 15), axis.text.y = element_text(size = 12.5, colour = "#111111"))
me <- with_inset(map_one(pf, F_LIMS, modifyList(S_ENS, list(lw_prov = 0.35)), labels = lab_ens, pref_mode = TRUE),
                 inset_one(pf, F_LIMS, S_ENS, pref_mode = TRUE))
FE2 <- plot_grid(ggdraw() + draw_plot(me, 0, 0.11, 1, 0.8) +
                   draw_plot(legend_bar(F_LIMS, F_BRK, "Expected new records per year", S_ENS, 3), x = 0.03, y = 0, width = 0.5, height = 0.12) +
                   draw_label(sprintf("2030 · SSP2-4.5 · effort growing: China %.1f records per year", n2$total), x = 0.01, y = 0.99,
                              hjust = 0, vjust = 1, fontfamily = "Arial", fontface = "bold", size = S_ENS$head),
                 bar_e, nrow = 1, rel_widths = c(1.5, 1))
ggsave(file.path(OUT, "slide_en", "Fig_future_prefectures_en.png"), FE2, width = 12.2, height = 5.8, dpi = 220, device = agg_png, bg = "white")
ggsave(file.path(OUT, "slide_en", "Fig_future_prefectures_en.pdf"), FE2, width = 12.2, height = 5.8, device = cairo_pdf, bg = "white")

# ---------------- 源数据 / source data ----------------
fwrite(grid[, .(ssp, eff, horizon, province, prov_cn, expected_records_per_year = exp_n, share_rows_in_support = pct_sup)],
       file.path(OUT, "source_data", "source_future_provinces.csv"))
fwrite(pv[, .(unit_id, prefecture = unit_nm, province, province_expected = exp_n, share, expected_records_per_year = val)],
       file.path(OUT, "source_data", "source_future_prefectures_2030_ssp245_effort_continuing.csv"))
cat(sprintf("[234] 完成 / done: 省级 8 幅 + 地级市 %d 个单元;全国合计核对 %s\n", nrow(pv),
            paste(sprintf("%s/%s/%d=%.1f", nat$ssp, substr(nat$eff, 8, 12), nat$horizon, nat$total), collapse = " ")))
