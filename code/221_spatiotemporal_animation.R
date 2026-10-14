#!/usr/bin/env Rscript
# ============================================================
# Scientific question / 科学问题:
#   2002–2024 年中国的增温、观鸟调查努力与鸟类省级新纪录在空间和时间上如何一同变化?
#   两个驱动因子同步增长, 正是新纪录难以归因、需要用一个模型同时分离二者的原因。
#   How did warming, birding effort and provincial new bird records change together across
#   China in 2002–2024? Their joint rise is why records are hard to attribute and why both
#   drivers must be separated within one model.
#
# Objective / 分析目标:
#   生成报告用的时空动图(GIF 嵌入幻灯片, MP4 单独播放)与末帧静态图:
#   左图为格级累积增温, 右图为分省观鸟访问量与逐年新纪录, 下方为全国时间序列。
#   Build the talk's spatiotemporal animation (GIF for the slide, MP4 for standalone use)
#   and a static final frame: cell-level accumulated warming (left), provincial birding
#   visits with new records (right), national time series (bottom).
#
# Input data / 输入数据:
#   WorldClim 2.1 对 CRU TS 4.09 的 10′ 降尺度月均最高/最低温(1980–2024)
#   analysis_v2/data/effort_panel_v2.csv           分省逐年观鸟访问量(eBird/GBIF 与中国观鸟记录中心 China Bird Report)
#   analysis_v2/data/events_discovery_dated.csv    CBNR v2 首次纪录, 按发现年定年(657 条)
#   data/spatial/basemap_GS2019_1822/              标准底图(审图号 GS(2019)1822)
#
# Main workflow / 主要流程:
#   1. 逐年年均温 = 12 个月 (Tmax + Tmin)/2 的均值, 裁到中国范围并缓存
#      annual mean temperature from monthly Tmax/Tmin, cropped to China and cached
#   2. 累积增温 = 15 年滑动均值 − 1980–2000 均值(模型增温协变量的省端口径)
#      accumulated warming = 15-yr trailing mean minus the 1980–2000 mean (province side of the covariate)
#   3. 投影到 Albers 等积投影、按国界掩膜; 全国均值即等积格平均
#      project to Albers equal-area and mask; the national mean is the equal-area cell mean
#   4. 逐年绘帧(地图 + 南海插图 + 时间序列), 再编码为 GIF 与 MP4
#      render one frame per year (maps + SCS inset + series), then encode GIF and MP4
#   5. 写出源数据与图注
#      write source data and the legend
#
# Expected output / 预期输出:
#   analysis_v2/figures_animation/FigAnim_warming_effort_records.{gif,mp4}
#   analysis_v2/figures_animation/FigAnim_warming_effort_records_2024.png(末帧, 供 PDF 与印刷)
#   analysis_v2/figures_animation/source_data_FigAnim_*.csv, LEGEND_FigAnim.md
#
# Key assumptions / 关键假设:
#   每帧都是真实年份的数据, 不做年间插值; 地图色阶在所有帧中固定。
#   2022–2024 年的纪录仍在陆续发表, 柱高偏低, 图中注明(模型用完整度 offset 校正)。
#   台湾、香港、澳门不在努力分析范围内, 与正文图件一致以灰色表示。
#   努力面板已含 2024 年 eBird 修正(脚本 222/131);广东 2024 年为下载缺口(中国观鸟记录中心仅 14 天), 地图上为灰色。
#   Every frame shows a real year (no interpolation); colour scales are fixed across frames.
#   Records for 2022–2024 are still being published (the model corrects this with an offset).
#   Taiwan, Hong Kong and Macao are outside the effort analysis, grey as in the paper's figures.
#   The effort panel includes the 2024 eBird correction (scripts 222 and 131); Guangdong 2024 is a
#   download gap (China Bird Report covers 14 days) and is mapped grey.
#
# Main packages / 主要包: terra, sf, data.table, ggplot2, patchwork, ggtext, rsvg, gifski, ragg
# Output directory / 输出路径: analysis_v2/figures_animation/
# Run / 运行: Rscript --no-init-file code/221_spatiotemporal_animation.R   (cwd = task root)
# ============================================================

# 本机 terra 二进制包未附带 PROJ 数据库, 借用 sf 自带的 proj.db(须在加载 terra 之前设置)
# terra here ships without proj.db; borrow the one bundled with sf (set before terra loads)
if (!nzchar(Sys.getenv("PROJ_DATA")) && nzchar(system.file("proj", package = "sf")))
  Sys.setenv(PROJ_DATA = system.file("proj", package = "sf"))
suppressPackageStartupMessages({
  library(data.table); library(terra); library(sf); library(ggplot2)
  library(patchwork); library(ggtext)
})
options(warn = 1); sf::sf_use_s2(FALSE)
source("code/218_theme_topjournal.R")      # TJ 调色板、底图工具 / palette and basemap helpers

V2    <- normalizePath(".", mustWork = TRUE)
OUT   <- file.path(V2, "analysis_v2", "figures_animation")
CACHE <- file.path(V2, "temp", "anim_cache")
FRM   <- file.path(V2, "temp", "anim_frames")
WC    <- "/Users/dingchenchen/Documents/New project/bird_new_record_full_risk_100pct_20260724/data_external/worldclim_10m/unzipped"
ICONS <- path.expand("~/.claude/skills/easyslides/templates/icons/phosphor-duotone")
for (d in c(OUT, CACHE, file.path(FRM, "gif"), file.path(FRM, "mp4"))) dir.create(d, recursive = TRUE, showWarnings = FALSE)
msg <- function(...) cat(sprintf("[221 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

YEARS <- 2002:2024
BASE  <- 1980:2000
WIN   <- 15L
# 画幅: 2:1, 便于放进幻灯片标题与导航栏下方的区域 / 2:1 canvas to fit under the slide chrome
W_IN <- 12.8; H_IN <- 6.4
RES  <- c(gif = 125, mp4 = 150)              # 1600 x 800 与 1920 x 960 像素 / pixels
PKU_RED <- "#94070A"                          # 年份标签用北大红(界面元素, 非数据编码) / UI accent only
REC_COL <- "#F0A202"                          # 新纪录: 琥珀色, 在蓝色努力底图上醒目 / amber records
NA_COL  <- "#C9C9C6"                          # 无数据或范围外 / no data or outside scope
FS <- 13                                      # 帧内基础字号(pt)/ base font size inside frames

# =====================================================================
# 1. 年均温(1980–2024), 裁到中国范围并缓存 / annual mean temperature, cropped and cached
# =====================================================================
tavg_file <- file.path(CACHE, "wc10m_tavg_china_1980_2024.tif")
if (!file.exists(tavg_file)) {
  msg("由月 Tmax/Tmin 计算年均温 / annual means from monthly Tmax and Tmin")
  ext_cn <- ext(72, 137, 15, 55)
  find_m <- function(var, y) {
    f <- list.files(file.path(WC, paste0("historical_", var)), recursive = TRUE, full.names = TRUE,
                    pattern = sprintf("_%s_%d-\\d{2}\\.tif$", var, y))
    if (length(f) != 12) stop(sprintf("%s %d: 找到 %d 个月 / found %d months", var, y, length(f), length(f)))
    sort(f)
  }
  yrs <- min(BASE):max(YEARS)
  ann <- lapply(yrs, function(y) {
    tx <- crop(rast(find_m("tmax", y)), ext_cn)
    tn <- crop(rast(find_m("tmin", y)), ext_cn)
    r  <- mean((tx + tn) / 2)
    if (y %% 10 == 0) msg("  ", y)
    r
  })
  ann <- rast(ann); names(ann) <- yrs
  writeRaster(ann, tavg_file, overwrite = TRUE, gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"))
}
tavg <- rast(tavg_file)
# 核对: 与已备好的 2002 年年均温一致(同源数据)/ check against the prepared 2002 annual mean
prep02 <- "/Users/dingchenchen/Documents/New project/bird_new_record_full_risk_100pct_20260724/data_external/worldclim_10m/prepared/annual/temp/worldclim_v2.1_cruts4.09_10m_annual_temp_2002.tif"
if (file.exists(prep02)) {
  dd <- global(abs(tavg[["2002"]] - crop(rast(prep02), tavg)), "max", na.rm = TRUE)[1, 1]
  msg("2002 年均温与预处理文件的最大差 / max abs diff vs prepared 2002: ", signif(dd, 3), " °C")
}

# =====================================================================
# 2. 累积增温: 15 年滑动均值 − 1980–2000 均值 / accumulated warming
# =====================================================================
base_mean <- mean(tavg[[as.character(BASE)]])
acc <- rast(lapply(YEARS, function(y) mean(tavg[[as.character((y - WIN + 1):y)]]) - base_mean))
names(acc) <- YEARS

# =====================================================================
# 3. 底图、投影与掩膜 / basemap, projection, mask
# =====================================================================
bm <- tj_basemap()
bm$prov$province[bm$prov$province == "Macau"] <- "Macao"   # 与努力面板拼写一致 / match the effort panel
crs_a <- sf::st_crs(bm$prov)
cn_poly <- sf::st_union(sf::st_make_valid(bm$prov))
acc_a <- project(acc, crs_a$wkt, res = 15000, method = "bilinear")
acc_a <- mask(acc_a, vect(sf::st_sf(geometry = cn_poly)))
nat_warm <- data.table(year = YEARS, warming = global(acc_a, "mean", na.rm = TRUE)[, 1])   # 等积格均值 / equal-area mean
msg("全国累积增温 / national accumulated warming: ",
    sprintf("%.2f (2002) → %.2f (2024) °C", nat_warm$warming[1], nat_warm$warming[length(YEARS)]))
# 分省均值(源数据)/ provincial means for the source data
zon <- terra::extract(acc_a, vect(bm$prov), fun = mean, na.rm = TRUE, ID = TRUE)
prov_warm <- melt(data.table(province = bm$prov$province[zon$ID], zon[, -1]),
                  id.vars = "province", variable.name = "year", value.name = "warming_c")
prov_warm[, year := as.integer(as.character(year))]
prov_warm <- prov_warm[, .(warming_c = mean(warming_c, na.rm = TRUE)), by = .(province, year)]

ras_df <- as.data.frame(acc_a, xy = TRUE, na.rm = FALSE)
ras_df <- as.data.table(ras_df)[, c("x", "y", as.character(YEARS)), with = FALSE]
ras_long <- melt(ras_df, id.vars = c("x", "y"), variable.name = "year", value.name = "val", na.rm = TRUE)
ras_long[, year := as.integer(as.character(year))]
LIM_W <- c(-0.4, 1.6)
msg("增温格值范围 / cell range: ", paste(sprintf("%.2f", range(ras_long$val)), collapse = " to "),
    " | 超出色阶 / outside scale: ", round(100 * mean(ras_long$val < LIM_W[1] | ras_long$val > LIM_W[2]), 2), "%")

# =====================================================================
# 4. 调查努力与新纪录 / survey effort and new records
# =====================================================================
eff <- fread(file.path(V2, "analysis_v2/data/effort_panel_v2.csv"))
eff[, ok := effort_status_v2 == "observed" & in_scope %in% c(TRUE, "TRUE") & mainland %in% c(TRUE, "TRUE")]
# 下载缺口(脚本 131):2024 年 eBird 已补入, 广东 2024 年中国观鸟记录中心仅 14 天, 仍不完整, 地图为灰色
# download gaps (script 131): eBird 2024 is already added; Guangdong 2024 (China Bird Report: 14 days) stays grey
eff[, suspect := effort_status_v2 == "download_gap"]
SUSPECT <- eff[suspect == TRUE, sprintf("%s %d", province, year)]
# 中文图注用中文省名 / Chinese legend uses Chinese province names
PROV_EN_CN <- setNames(sub("(省|市|壮族自治区|回族自治区|维吾尔自治区|自治区|特别行政区)$", "", names(PROV_CN_EN)), PROV_CN_EN)
SUSPECT_ZH <- eff[suspect == TRUE, sprintf("%s %d 年", PROV_EN_CN[province], year)]
msg("下载缺口 / download gaps: ", paste(SUSPECT, collapse = ", "))
eff[, lv := fifelse(ok, log10(pmax(n_visits, 1)), NA_real_)]
nat_eff <- eff[mainland %in% c(TRUE, "TRUE") & ok == TRUE, .(visits = sum(n_visits)), by = year][order(year)]
FOLD <- nat_eff[year %in% 2022:2024, mean(visits)] / nat_eff[year %in% 2002:2004, mean(visits)]
msg("全国访问量 / national visits: ", nat_eff$visits[1], " → ", tail(nat_eff$visits, 1),
    sprintf(" | 2022–24 / 2002–04 = %.1f 倍 / -fold", FOLD))

ev <- fread(file.path(V2, "analysis_v2/data/events_discovery_dated.csv"))
ev <- ev[year %in% YEARS]
ev_sf <- sf::st_transform(sf::st_as_sf(ev, coords = c("longitude", "latitude"), crs = 4326), crs_a)
ev_xy <- cbind(as.data.table(ev)[, .(species, province, year)], sf::st_coordinates(ev_sf))
nat_rec <- ev[, .N, by = year][CJ(year = YEARS), on = "year"][is.na(N), N := 0L][order(year)]
nat_rec[, cum := cumsum(N)]
msg("纪录 / records: ", nrow(ev), " (", min(ev$year), "–", max(ev$year), ")")

# =====================================================================
# 5. 图标: 着色后栅格化供标题使用 / icons recoloured and rasterised for the titles
# =====================================================================
icon_png <- function(name, col) {
  f <- file.path(tempdir(), sprintf("%s_%s.png", name, sub("#", "", col)))
  if (!file.exists(f)) {
    svg <- readLines(file.path(ICONS, paste0(name, ".svg")), warn = FALSE)
    svg <- gsub('fill="currentColor"', sprintf('fill="%s"', col), paste(svg, collapse = ""))
    rsvg::rsvg_png(charToRaw(svg), f, width = 128, height = 128)
  }
  f
}
ic <- function(name, col, px = 20) sprintf("<img src='%s' width='%d'/>", icon_png(name, col), px)
I_THERMO <- ic("thermometer-hot", TJ$warming)
I_BINO   <- ic("binoculars", TJ$effort)
I_BIRD   <- ic("bird", "#B07800")

# =====================================================================
# 6. 帧的组件 / frame components
# =====================================================================
theme_frame <- function(base = FS) {
  theme_void(base_size = base, base_family = "Arial") +
    theme(text = element_text(colour = TJ$ink),
          plot.title = element_markdown(size = base + 2, face = "bold", hjust = 0, margin = margin(b = 2, l = 2)),
          plot.subtitle = element_text(size = base - 1.5, colour = TJ$subink, hjust = 0, margin = margin(b = 2, l = 2)),
          legend.title = element_text(size = base - 2, colour = TJ$ink),
          legend.text = element_text(size = base - 2.5, colour = TJ$subink),
          plot.margin = margin(2, 4, 0, 4))
}

main_bb <- tj_bbox(c(73, 135.5), c(17.6, 53.8), crs_a)
scs_bb  <- tj_bbox(c(106.5, 123.5), c(3.0, 24.5), crs_a)
#' 经纬度 → Albers 坐标(放置手绘图例)/ lon-lat to Albers, for hand-placed legend items
to_a <- function(lon, lat) {
  sf::st_coordinates(sf::st_transform(sf::st_as_sf(data.frame(lon = lon, lat = lat), coords = c("lon", "lat"),
                                                   crs = 4326), crs_a))
}

#' 中国地图 + 南海诸岛插图; 色标放在图框西南角的空白处(南亚), 两图因而等大、标题对齐
#' China map with the South China Sea inset; the colour bar sits in the empty south-west corner
#' (South Asia), so both maps have the same panel size and their titles line up.
china_frame <- function(layers, scales, title, subtitle) {
  base <- c(layers, list(geom_sf(data = bm$outline, colour = TJ$rule, linewidth = 0.3, inherit.aes = FALSE),
                         geom_sf(data = bm$ninedash, colour = TJ$rule, linewidth = 0.35, inherit.aes = FALSE)), scales)
  p_main <- ggplot() + base +
    coord_sf(crs = crs_a, xlim = main_bb$x, ylim = main_bb$y, expand = FALSE, datum = NA, clip = "off") +
    labs(title = title, subtitle = subtitle) + theme_frame() +
    theme(legend.position = "inside", legend.position.inside = c(0.01, 0.035),
          legend.justification.inside = c(0, 0), legend.direction = "horizontal",
          legend.title.position = "top", legend.background = element_blank())
  p_scs <- ggplot() + base +
    coord_sf(crs = crs_a, xlim = scs_bb$x, ylim = scs_bb$y, expand = FALSE, datum = NA) +
    theme_void() +
    theme(legend.position = "none", plot.margin = margin(0, 0, 0, 0),
          panel.border = element_rect(fill = NA, colour = TJ$rule, linewidth = 0.3),
          plot.background = element_rect(fill = "white", colour = NA))
  wrap_elements(full = p_main + inset_element(p_scs, left = 0.85, bottom = 0.0, right = 1.0, top = 0.27,
                                              align_to = "panel", ignore_tag = TRUE))
}

bar_theme <- function(w = 150) theme(legend.key.width = unit(w, "pt"), legend.key.height = unit(8, "pt"),
                                     legend.ticks = element_line(colour = "white", linewidth = 0.4),
                                     legend.ticks.length = unit(c(2, 0), "pt"))

# 增温色阶: 0 为中性色, 正值走向深红, 负值为浅蓝 / neutral at 0, reds for warming
WARM_COLS <- c("#3E6FA3", "#A9C3DE", "#F5F3EF", "#F8D5B5", "#F0A270", "#DC6236", "#B23A1C", "#741A0B")
WARM_VALS <- scales::rescale(c(-0.4, -0.2, 0, 0.2, 0.45, 0.75, 1.05, 1.6), from = LIM_W)
scale_warm <- scale_fill_gradientn(colours = WARM_COLS, values = WARM_VALS, limits = LIM_W, oob = scales::squish,
  breaks = c(-0.4, 0, 0.4, 0.8, 1.2, 1.6), labels = c("−0.4", "0", "0.4", "0.8", "1.2", "1.6"),
  name = "°C warmer than 1980–2000", guide = guide_colourbar(theme = bar_theme(165)))

EFF_COLS <- c("#EEF3F9", "#C6D8EC", "#8FB1D8", "#4F84BE", "#1F5F9E", "#0D3561")
scale_eff <- scale_fill_gradientn(colours = EFF_COLS, limits = c(0, 5), oob = scales::squish, na.value = NA_COL,
  breaks = 0:5, labels = c("1", "10", "100", "1k", "10k", "100k"), name = "Birding visits per year",
  guide = guide_colourbar(theme = bar_theme(165)))

map_warming <- function(yr) {
  d <- ras_long[year == yr]          # 注意: ras_long 有坐标列 y, 参数不能叫 y / ras_long has a column y
  china_frame(
    list(geom_raster(data = d, aes(x = x, y = y, fill = val)),
         geom_sf(data = bm$prov, fill = NA, colour = "white", linewidth = 0.18, inherit.aes = FALSE)),
    list(scale_warm),
    title = paste(I_THERMO, "Accumulated warming"),
    subtitle = sprintf("Mean temperature of %d–%d minus the 1980–2000 mean", yr - WIN + 1, yr))
}

# 新纪录图例手工放在东海(图框东侧空白), 避免与色标争位置
# The records key is hand-placed over the East China Sea, clear of the colour bar
LEG <- {
  p <- to_a(c(126.3, 126.3, 126.3, 126.3), c(36.4, 34.3, 32.5, 30.6))
  list(title = p[1, ], now = p[2, ], before = p[3, ], na = p[4, ])
}
legend_records <- function() {
  dx <- 1.45e5
  list(annotate("text", x = LEG$title[1], y = LEG$title[2], label = "New records", hjust = 0,
                size = (FS - 2) / .pt, family = "Arial", colour = TJ$ink),
       annotate("point", x = LEG$now[1] + 0.3e5, y = LEG$now[2], colour = "white", size = 3.8),
       annotate("point", x = LEG$now[1] + 0.3e5, y = LEG$now[2], colour = REC_COL, size = 2.7),
       annotate("text", x = LEG$now[1] + dx, y = LEG$now[2], label = "this year", hjust = 0,
                size = (FS - 2.5) / .pt, family = "Arial", colour = TJ$subink),
       annotate("point", x = LEG$before[1] + 0.3e5, y = LEG$before[2], colour = "#2B2B2B", size = 0.9),
       annotate("text", x = LEG$before[1] + dx, y = LEG$before[2], label = "earlier years", hjust = 0,
                size = (FS - 2.5) / .pt, family = "Arial", colour = TJ$subink),
       annotate("point", x = LEG$na[1] + 0.3e5, y = LEG$na[2], colour = NA_COL, size = 4, shape = 15),
       annotate("text", x = LEG$na[1] + dx, y = LEG$na[2], label = "no or incomplete data", hjust = 0,
                size = (FS - 2.5) / .pt, family = "Arial", colour = TJ$subink))
}

map_effort <- function(yr) {
  pv <- merge(bm$prov, eff[year == yr, .(province, lv)], by = "province", all.x = TRUE)
  pts <- ev_xy[year <= yr]
  china_frame(
    c(list(geom_sf(data = pv, aes(fill = lv), colour = "white", linewidth = 0.2, inherit.aes = FALSE),
           geom_point(data = pts[year < yr], aes(x = X, y = Y), colour = "#2B2B2B", size = 0.8, alpha = 0.55,
                      stroke = 0),
           geom_point(data = pts[year == yr], aes(x = X, y = Y), colour = "white", size = 3.8, stroke = 0),
           geom_point(data = pts[year == yr], aes(x = X, y = Y), colour = REC_COL, size = 2.7, stroke = 0)),
      legend_records()),
    list(scale_eff),
    title = paste(I_BINO, "Survey effort and", I_BIRD, "new records"),
    subtitle = "Birding visits per province; records dated to their discovery year")
}

# 时间序列: 全程浅色"影线" + 截至当年的实线, 坐标轴在各帧固定 / ghost line plus line to date
theme_series <- function() {
  theme_classic(base_size = FS - 1, base_family = "Arial") +
    theme(text = element_text(colour = TJ$ink),
          plot.title = element_markdown(size = FS - 0.5, face = "bold", hjust = 0, margin = margin(b = 3)),
          plot.title.position = "plot",
          axis.line = element_line(colour = TJ$rule, linewidth = 0.3),
          axis.ticks = element_line(colour = TJ$rule, linewidth = 0.3),
          axis.text = element_text(size = FS - 2, colour = TJ$subink),
          axis.title = element_blank(),
          panel.grid.major.y = element_line(colour = "#EEEEEE", linewidth = 0.3),
          plot.margin = margin(4, 16, 0, 8))
}
# 数值标签: 前几年放在点右侧, 避免压到纵轴刻度 / labels sit right of the point in early years
lab_hjust <- function(yr) if (yr <= 2006) -0.2 else 1.1
X_YEARS <- scale_x_continuous(limits = c(2001.4, 2024.6), breaks = c(2002, 2008, 2014, 2020, 2024), expand = c(0, 0))

series_warming <- function(yr) {
  d <- nat_warm; cur <- d[year == yr]
  ggplot(d, aes(year, warming)) +
    geom_line(colour = tint(TJ$warming, 0.72), linewidth = 0.9) +
    geom_line(data = d[year <= yr], colour = TJ$warming, linewidth = 1.4) +
    geom_point(data = cur, colour = TJ$warming, size = 2.8) +
    geom_text(data = cur, aes(label = sprintf("+%.2f °C", warming)), hjust = lab_hjust(yr), vjust = -0.7,
              size = (FS - 1.5) / .pt, family = "Arial", fontface = "bold", colour = TJ$warming) +
    X_YEARS + scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.5, 1), labels = c("0", "0.5", "1.0 °C")) +
    coord_cartesian(clip = "off") +
    labs(title = paste(ic("thermometer-hot", TJ$warming, 17), "China-wide warming")) +
    theme_series()
}

series_effort <- function(yr) {
  d <- nat_eff; cur <- d[year == yr]
  ggplot(d, aes(year, visits)) +
    geom_line(colour = tint(TJ$effort, 0.72), linewidth = 0.9) +
    geom_line(data = d[year <= yr], colour = TJ$effort, linewidth = 1.4) +
    geom_point(data = cur, colour = TJ$effort, size = 2.8) +
    geom_text(data = cur, aes(label = format(visits, big.mark = ",")), hjust = lab_hjust(yr), vjust = -0.7,
              size = (FS - 1.5) / .pt, family = "Arial", fontface = "bold", colour = TJ$effort) +
    X_YEARS + scale_y_log10(limits = c(150, 3e5), breaks = c(1e3, 1e4, 1e5), labels = c("1k", "10k", "100k")) +
    coord_cartesian(clip = "off") +
    labs(title = paste(ic("binoculars", TJ$effort, 17), sprintf("Birding visits, mainland (×%.0f)", FOLD))) +
    theme_series()
}

series_records <- function(yr) {
  d <- copy(nat_rec)[, grp := fifelse(year < yr, "past", fifelse(year == yr, "now", "future"))]
  cur <- d[year == yr]
  ggplot(d, aes(year, N)) +
    geom_col(aes(fill = grp), width = 0.78) +
    annotate("segment", x = 2021.6, xend = 2024.4, y = 62, yend = 62, colour = TJ$subink, linewidth = 0.3) +
    annotate("text", x = 2023, y = 65, label = "still being\npublished", vjust = 0, lineheight = 0.9,
             size = (FS - 3.5) / .pt, family = "Arial", colour = TJ$subink) +
    geom_text(data = cur, aes(label = sprintf("%d records so far", cum)), x = 2001.9, y = 80, hjust = 0, vjust = 1,
              size = (FS - 1.5) / .pt, family = "Arial", fontface = "bold", colour = "#9A6A00") +
    scale_fill_manual(values = c(past = tint(REC_COL, 0.15), now = "#B87400", future = "#E6E6E3"), guide = "none") +
    X_YEARS + scale_y_continuous(limits = c(0, 80), breaks = c(0, 20, 40, 60), expand = c(0, 0)) +
    coord_cartesian(clip = "off") +
    labs(title = paste(ic("bird", "#B07800", 17), "New records per year")) +
    theme_series()
}

# 年份标签 + 2002–2024 进度轴 / year label with a 2002–2024 progress track
year_box <- function(yr) {
  f <- (yr - min(YEARS)) / (max(YEARS) - min(YEARS))
  x0 <- 0.10; x1 <- 0.88; xp <- x0 + f * (x1 - x0)
  ggplot() + scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    annotate("text", x = 0.49, y = 0.64, label = yr, size = 42 / .pt, family = "Arial",
             fontface = "bold", colour = PKU_RED) +
    annotate("segment", x = x0, xend = x1, y = 0.24, yend = 0.24, colour = "#D9D9D9", linewidth = 1.6,
             lineend = "round") +
    annotate("segment", x = x0, xend = xp, y = 0.24, yend = 0.24, colour = PKU_RED, linewidth = 1.6,
             lineend = "round") +
    annotate("point", x = xp, y = 0.24, colour = PKU_RED, size = 3.2) +
    annotate("text", x = c(x0, x1), y = 0.09, label = c(min(YEARS), max(YEARS)), size = (FS - 3) / .pt,
             family = "Arial", colour = TJ$subink) +
    theme_void() + theme(plot.margin = margin(0, 2, 0, 2))
}

CREDIT <- paste0(
  "Warming: WorldClim 2.1 downscaling of CRU TS 4.09, the provincial side of the model's warming covariate.  ",
  "Effort: birding visits in eBird/GBIF and China Bird Report.  ",
  sprintf("Records: CBNR v2 first records dated to discovery, n = %d.\n", nrow(ev)),
  "Grey: effort coverage gap; outside the analysis (Taiwan, Hong Kong, Macao)",
  if (length(SUSPECT)) sprintf("; or incomplete download (%s)", paste(SUSPECT, collapse = ", ")) else "",
  ".  Base map: GS(2019)1822.")

frame <- function(yr) {
  maps  <- (map_warming(yr) | map_effort(yr))
  strip <- (year_box(yr) | series_warming(yr) | series_effort(yr) | series_records(yr)) +
    plot_layout(widths = c(0.58, 1, 1, 1))
  (maps / strip) + plot_layout(heights = c(4.35, 1.3)) +
    plot_annotation(caption = CREDIT,
                    theme = theme(plot.caption = element_text(size = FS - 4, colour = TJ$subink, hjust = 0,
                                                              lineheight = 1.05, family = "Arial",
                                                              margin = margin(t = 3)),
                                  plot.margin = margin(6, 8, 4, 8),
                                  plot.background = element_rect(fill = "white", colour = NA)))
}

# =====================================================================
# 7. 渲染帧与编码 / render frames and encode
# =====================================================================
render <- function(kind) {
  files <- character(length(YEARS))
  for (i in seq_along(YEARS)) {
    files[i] <- file.path(FRM, kind, sprintf("frame_%d.png", YEARS[i]))
    ragg::agg_png(files[i], width = W_IN, height = H_IN, units = "in", res = RES[[kind]], background = "white")
    print(frame(YEARS[i]))
    invisible(dev.off())
  }
  msg("  ", kind, ": ", length(files), " 帧 / frames")
  files
}
ONLY <- Sys.getenv("ANIM_ONLY")                           # 调试用: 只画指定年份 / debug: one year only
if (nzchar(ONLY)) {
  y <- as.integer(ONLY)
  ragg::agg_png(file.path(FRM, sprintf("test_%d.png", y)), width = W_IN, height = H_IN, units = "in",
                res = RES[["gif"]], background = "white")
  print(frame(y)); invisible(dev.off())
  msg("测试帧 / test frame: ", y); quit(save = "no")
}

f_gif <- render("gif")
f_mp4 <- render("mp4")

# 节奏: 首帧停 1.5 s, 中间每年 0.9 s, 末帧停 4 s / timing: hold first and last frames longer
hold <- c(15L, rep(9L, length(YEARS) - 2L), 40L)
gif_out <- file.path(OUT, "FigAnim_warming_effort_records.gif")
gifski::gifski(rep(f_gif, times = hold), gif_file = gif_out, width = W_IN * RES[["gif"]],
               height = H_IN * RES[["gif"]], delay = 0.1, loop = TRUE, progress = FALSE)
msg("GIF: ", basename(gif_out), sprintf(" (%.1f MB)", file.size(gif_out) / 1e6))

lst <- file.path(FRM, "mp4", "concat.txt")
dur <- hold / 10
writeLines(c(sprintf("file '%s'\nduration %.2f", f_mp4, dur), sprintf("file '%s'", tail(f_mp4, 1))), lst)
mp4_out <- file.path(OUT, "FigAnim_warming_effort_records.mp4")
st <- system2("ffmpeg", c("-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", shQuote(lst),
                          "-vf", shQuote("fps=25,format=yuv420p"), "-c:v", "libx264", "-crf", "18",
                          "-preset", "slow", "-movflags", "+faststart", shQuote(mp4_out)))
if (st != 0) stop("ffmpeg 失败 / ffmpeg failed")
msg("MP4: ", basename(mp4_out), sprintf(" (%.1f MB)", file.size(mp4_out) / 1e6))

# 末帧(高分辨率): PDF 版报告与印刷用 / final frame at high resolution for the PDF deck and print
still <- file.path(OUT, "FigAnim_warming_effort_records_2024.png")
ragg::agg_png(still, width = W_IN, height = H_IN, units = "in", res = 200, background = "white")
print(frame(max(YEARS))); invisible(dev.off())
ggsave(file.path(OUT, "FigAnim_warming_effort_records_2024.pdf"), frame(max(YEARS)),
       width = W_IN, height = H_IN, device = grDevices::cairo_pdf, bg = "white")

# =====================================================================
# 8. 源数据与图注 / source data and legend
# =====================================================================
nat <- Reduce(function(a, b) merge(a, b, by = "year", all = TRUE),
              list(nat_warm, nat_eff, nat_rec[, .(year, records = N, records_cumulative = cum)]))
fwrite(nat[, .(year, accumulated_warming_c = round(warming, 4), birding_visits_mainland = visits,
               new_records = records, new_records_cumulative = records_cumulative)],
       file.path(OUT, "source_data_FigAnim_national.csv"))
pr <- merge(prov_warm, eff[, .(province, year, effort_status = effort_status_v2, n_visits,
                               mapped = fifelse(ok, "visits",
                                                fifelse(suspect, "download gap", "no data or not analysed")))],
            by = c("province", "year"), all = TRUE)
pr <- merge(pr, ev[, .(new_records = .N), by = .(province, year)], by = c("province", "year"), all.x = TRUE)
pr[is.na(new_records), new_records := 0L]
fwrite(pr[year %in% YEARS][order(province, year)][, warming_c := round(warming_c, 4)],
       file.path(OUT, "source_data_FigAnim_province_year.csv"))
fwrite(ev_xy[, .(species, province, discovery_year = year, x_albers_m = round(X), y_albers_m = round(Y))],
       file.path(OUT, "source_data_FigAnim_records.csv"))

lg <- c(
  "# Animated figure: warming, survey effort and new bird records in China, 2002–2024",
  "",
  "**Files.** `FigAnim_warming_effort_records.gif` (1600 × 800 px, for the slide), `.mp4` (1920 × 960 px, H.264),",
  "`_2024.png`/`.pdf` (final frame, for print and the PDF version of the talk). Script: `code/221_spatiotemporal_animation.R`.",
  "",
  "**Legend (English).** Each frame shows one year from 2002 to 2024. Left, accumulated warming: the 15-year trailing mean",
  "of annual mean temperature minus its 1980–2000 mean, at 10 arc-minutes (WorldClim 2.1 downscaling of CRU TS 4.09),",
  "projected to an equal-area grid of 15 km. This is the provincial side of the warming covariate in the hazard model; the",
  "model uses its difference from the same quantity over each species' range. Right, survey effort: birding visits per province",
  "and year in eBird/GBIF and China Bird Report on a log scale; grey provinces have no effort coverage that year or lie outside the effort analysis",
  "(Taiwan, Hong Kong and Macao).",
  if (length(SUSPECT)) paste0("Also grey: ", paste(SUSPECT, collapse = " and "), ", whose China Bird Report records cover only ",
                              "14 days; it is treated as missing in the model. eBird checklists for 2024, absent from the original ",
                              "source download, were added with the same visit definition (scripts 222 and 131).") else "",
  "Points are provincial first records from CBNR v2 dated to their discovery year (amber, this",
  sprintf("year; dark, earlier years; n = %d). Bottom, national series: equal-area mean accumulated warming (%.2f °C in 2002,",
          nrow(ev), nat_warm$warming[1]),
  sprintf("%.2f °C in 2024), total birding visits in mainland provinces (%s in 2002, %s in 2024; %.0f-fold from 2002–2004 to",
          nat_warm$warming[length(YEARS)], format(nat_eff$visits[1], big.mark = ","),
          format(tail(nat_eff$visits, 1), big.mark = ","), FOLD),
  "2022–2024) and new records per discovery year. Counts for 2022–2024 are incomplete because records are still being published;",
  "the hazard model corrects for this with a reporting-completeness offset. Base map: GS(2019)1822.",
  "",
  "**说明(中文).** 每帧为 2002–2024 年中的一年。左图为累积增温(15 年滑动均温减 1980–2000 均值, 即模型增温协变量的省端口径),",
  "右图为分省观鸟访问量(对数色阶; 灰色为当年无努力覆盖或不在努力分析范围内的台湾、香港、澳门)与按发现年定年的新纪录。",
  if (length(SUSPECT)) paste0("另: ", paste(SUSPECT_ZH, collapse = "、"), "的中国观鸟记录中心数据只覆盖 14 天, ",
                              "模型中按缺失处理, 地图为灰色;2024 年 eBird 清单原下载缺失, 已按同一口径补入(脚本 222、131)。") else "",
  "下方为全国时间序列; 2022–2024 年纪录仍在陆续发表, 柱高偏低。每帧均为真实年份数据, 不做年间插值; 各帧色阶固定。",
  "源数据: `source_data_FigAnim_national.csv`、`source_data_FigAnim_province_year.csv`、`source_data_FigAnim_records.csv`。")
writeLines(lg, file.path(OUT, "LEGEND_FigAnim.md"))
msg("DONE")
