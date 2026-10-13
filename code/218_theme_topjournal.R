# ============================================================
# Scientific question / 科学问题:
#   无(图件规范)。为全部顶刊版主图提供同一套视觉语言, 使配色、字号、线宽、
#   版宽在所有图中一致, 内容与统计量不变。
#   None (figure standard): one visual language for every top-journal figure,
#   so colour, type size, line weight and width are consistent; content unchanged.
#
# Objective / 分析目标:
#   供 218a–218d 各图脚本 source() 的主题、调色板、导出与底图工具。
#   Shared theme, palette, export and basemap helpers sourced by scripts 218a–218d.
#
# Input data / 输入数据: data/spatial/basemap_GS2019_1822/(审图号 GS(2019)1822 标准底图)
# Main workflow / 主要流程: 调色板 → 主题 → 刻度 → 导出 → 底图与南海插图
# Expected output / 预期输出: analysis_v2/figures_topjournal/(由各图脚本写出)
# Key assumptions / 关键假设:
#   Nature 双栏 183 mm;最终尺寸下正文字 6–7 pt、面板字母 8 pt 粗体、最小 5 pt;
#   线宽 0.25–1 pt;三色语义调色板经色觉缺陷校验(任意两两 ΔE ≥ 12.6)。
#   183 mm double column; 6–7 pt text, 8 pt bold panel letters, 5 pt minimum;
#   0.25–1 pt lines; the three semantic hues pass all-pairs CVD checks.
# Main packages / 主要包: ggplot2, patchwork, sf, ragg, svglite, scales
# Output directory / 输出路径: analysis_v2/figures_topjournal/
# ============================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
  library(scales)
})
# 非交互运行时打开空设备, 避免在任务根目录留下 Rplots.pdf
# open a null device in batch runs so no stray Rplots.pdf is written
if (!interactive()) grDevices::pdf(NULL)

# 约定: 所有 R 脚本在任务根目录以 Rscript --no-init-file 运行
# Convention: every R script runs from the task root with Rscript --no-init-file
TJ_V2  <- getwd()
if (!dir.exists(file.path(TJ_V2, "analysis_v2"))) stop("请在任务根目录运行 / run from the task root")
# 幻灯片模式(环境变量 TJ_SLIDE=1): 同一脚本以约 11 pt 字号、放大 1.25 倍画幅输出报告专用图,
# 写到 figures_topjournal_slides/; 默认印刷模式不受影响
# Slide mode (TJ_SLIDE=1): same scripts, ~11 pt text and 1.25x canvas, written to
# figures_topjournal_slides/; the default print mode is unchanged
TJ_SLIDE <- nzchar(Sys.getenv("TJ_SLIDE"))
TJ_BASE  <- if (TJ_SLIDE) 11 else 7
TJ_DIR <- file.path(TJ_V2, "analysis_v2", if (TJ_SLIDE) "figures_topjournal_slides" else "figures_topjournal")
dir.create(file.path(TJ_DIR, "panels"), recursive = TRUE, showWarnings = FALSE)

# ---------- 调色板 / palette ----------
# 语义固定: 同一变量在所有图中同色; 交互项用炭灰并配直接标注(二级编码)
# Semantic and fixed: one variable, one colour everywhere; the interaction is
# ink-grey with direct labels (secondary encoding).
TJ <- list(
  effort      = "#1F5F9E",   # 调查努力 / survey effort
  warming     = "#D1552C",   # 累积增温 / accumulated warming
  obs         = "#2A9D8F",   # 观测过程、随机效应 / observation process
  interaction = "#3B3B3B",   # 增温 × 努力 / warming x effort
  neutral     = "#9A9A9A",   # 年际变率、零效应参照 / variability, null reference
  ink         = "#1A1A1A",   # 主文字 / primary text
  subink      = "#5A5A5A",   # 次文字 / secondary text
  rule        = "#4A4A4A",   # 坐标轴 / axes
  grid        = "#ECECEC",   # 网格(极少使用)/ gridlines, used sparingly
  band        = "#F4F1EC",   # 强调底色 / highlight band
  na          = "#E9E9E7"    # 缺失与范围外 / missing or out of scope
)
TERM_COL <- c("Survey effort" = TJ$effort, "Accumulated warming" = TJ$warming,
              "Annual climate variability" = TJ$neutral, "Warming x effort" = TJ$interaction)

#' 与白色混合得到浅色 / mix a colour with white
tint <- function(col, amount = 0.5) {
  # 对 col 与 amount 逐元素配对(原写法在 amount 为向量时按矩阵循环, 颜色出错)
  # element-wise over col and amount (the matrix form mis-recycled a vector amount)
  mapply(function(c1, a1) {
    m <- grDevices::col2rgb(c1)[, 1] / 255
    grDevices::rgb(m[1] + (1 - m[1]) * a1, m[2] + (1 - m[2]) * a1, m[3] + (1 - m[3]) * a1)
  }, col, amount, USE.NAMES = FALSE)
}

#' 单色顺序色阶(浅→深)/ single-hue sequential ramp, light to dark
tj_ramp <- function(col, n = 5) {
  grDevices::colorRampPalette(c(tint(col, 0.92), tint(col, 0.55), col, colorspace::darken(col, 0.35)))(n)
}

# 发散色阶: 以 1(对数尺度)为中性灰 / diverging ramp around 1 on a log scale
TJ_DIV <- c("#174A7C", "#5B8DC0", "#B9CDE2", "#F2F1EE", "#EDB79F", "#D1552C", "#8E2F13")

# geom_text 的 size 以 mm 计; 幻灯片模式按字号比例放大 / mm sizes, scaled up in slide mode
pt2mm <- function(pt) pt * (TJ_BASE / 7) / ggplot2::.pt

# ---------- 主题 / theme ----------
theme_tj <- function(base_size = TJ_BASE, base_family = "Arial", grid = c("none", "y", "x", "xy")) {
  grid <- match.arg(grid)
  th <- theme_classic(base_size = base_size, base_family = base_family) +
    theme(
      text              = element_text(colour = TJ$ink, family = base_family),
      axis.line         = element_line(colour = TJ$rule, linewidth = 0.25),
      axis.ticks        = element_line(colour = TJ$rule, linewidth = 0.25),
      axis.ticks.length = unit(2, "pt"),
      axis.text         = element_text(size = base_size - 1, colour = TJ$subink),
      axis.title        = element_text(size = base_size, colour = TJ$ink),
      axis.title.x      = element_text(margin = margin(t = 3)),
      axis.title.y      = element_text(margin = margin(r = 3)),
      legend.title      = element_text(size = base_size - 1, colour = TJ$ink),
      legend.text       = element_text(size = base_size - 1, colour = TJ$subink),
      legend.key.size   = unit(7, "pt"),
      legend.spacing    = unit(2, "pt"),
      legend.margin     = margin(0, 0, 0, 0),
      legend.background = element_blank(),
      legend.key        = element_blank(),
      # 标题左缩进 9 pt, 给面板字母让位 / indent titles so the panel letter sits to their left
      plot.title        = element_text(size = base_size, face = "bold", hjust = 0, margin = margin(b = 4, l = 9)),
      plot.title.position = "plot",
      plot.subtitle     = element_text(size = base_size - 1, colour = TJ$subink, hjust = 0, margin = margin(b = 4, l = 9)),
      plot.caption      = element_text(size = base_size - 1.5, colour = TJ$subink, hjust = 0),
      plot.caption.position = "plot",
      plot.margin       = margin(4, 5, 4, 4),
      plot.tag          = element_text(size = base_size + 1, face = "bold", colour = TJ$ink),
      plot.tag.position = c(0, 1),
      strip.background  = element_blank(),
      strip.text        = element_text(size = base_size, face = "bold", hjust = 0, margin = margin(b = 3)),
      panel.grid        = element_blank(),
      panel.spacing     = unit(6, "pt")
    )
  if (grid %in% c("y", "xy")) th <- th + theme(panel.grid.major.y = element_line(colour = TJ$grid, linewidth = 0.2))
  if (grid %in% c("x", "xy")) th <- th + theme(panel.grid.major.x = element_line(colour = TJ$grid, linewidth = 0.2))
  th
}

# 地图主题: 无坐标轴 / map theme without axes
theme_tj_map <- function(base_size = TJ_BASE) {
  theme_tj(base_size) + theme(axis.line = element_blank(), axis.ticks = element_blank(),
                              axis.text = element_blank(), axis.title = element_blank())
}

# patchwork 面板字母: 小写粗体 8 pt, 左上对齐 / lowercase bold panel letters
tj_tags <- function() plot_annotation(tag_levels = "a", theme = theme(plot.margin = margin(2, 2, 2, 2)))

# 统一几何默认值 / geometry defaults at journal scale
update_geom_defaults("point", list(size = 1.1, colour = TJ$ink))
update_geom_defaults("line",  list(linewidth = 0.5, colour = TJ$ink))
update_geom_defaults("text",  list(size = pt2mm(6), family = "Arial", colour = TJ$ink))

# ---------- 导出 / export ----------
#' 期刊版宽导出 PDF(矢量, 嵌字体)、PNG(600 dpi)、SVG, 并登记尺寸
#' Export PDF (vector, embedded fonts), PNG (600 dpi) and SVG at journal width; log size.
tj_save <- function(p, name, width_mm = 183, height_mm = 120, dir = TJ_DIR) {
  w <- width_mm / 25.4; h <- height_mm / 25.4
  f <- function(ext) file.path(dir, paste0(name, ".", ext))
  ggsave(f("pdf"), p, width = w, height = h, device = grDevices::cairo_pdf, bg = "white")
  ggsave(f("png"), p, width = w, height = h, dpi = 600, device = ragg::agg_png, bg = "white")
  ggsave(f("svg"), p, width = w, height = h, device = svglite::svglite, bg = "white")
  # 地图类 SVG 动辄数十 MB 且不含额外信息: 超过 5 MB 只保留 PDF
  # Map SVGs run to tens of MB with no extra information: keep PDF only above 5 MB
  if (file.size(f("svg")) > 5e6) unlink(f("svg"))
  # 每图一个尺寸登记文件, 多个脚本并行运行时互不覆盖
  # one size record per figure, so scripts running in parallel never clash
  dir.create(file.path(TJ_DIR, "_sizes"), showWarnings = FALSE)
  utils::write.csv(data.frame(name = name, dir = basename(dir), width_mm = width_mm, height_mm = height_mm),
                   file.path(TJ_DIR, "_sizes", paste0(basename(dir), "__", name, ".csv")), row.names = FALSE)
  message(sprintf("  [TJ] %s  %.0f x %.0f mm", name, width_mm, height_mm))
  invisible(f("pdf"))
}

#' 单面板导出(供报告 PPT 使用)/ single panel export for slides
tj_panel <- function(p, name, width_mm = 120, height_mm = 85) {
  k <- if (TJ_SLIDE) 1.25 else 1          # 幻灯片模式放大画幅 / larger canvas for slides
  tj_save(p + theme(plot.tag = element_blank()), name, width_mm * k, height_mm * k, dir = file.path(TJ_DIR, "panels"))
}

#' 源数据 / source data next to the figure
tj_source <- function(df, name) {
  utils::write.csv(df, file.path(TJ_DIR, paste0("source_data_", name, ".csv")), row.names = FALSE)
}

# ---------- 底图 / basemap (GS(2019)1822, 等积投影) ----------
TJ_SHP <- file.path(TJ_V2, "data", "spatial", "basemap_GS2019_1822")
PROV_CN_EN <- c("北京市"="Beijing","天津市"="Tianjin","河北省"="Hebei","山西省"="Shanxi",
  "内蒙古自治区"="Inner Mongolia","辽宁省"="Liaoning","吉林省"="Jilin","黑龙江省"="Heilongjiang",
  "上海市"="Shanghai","江苏省"="Jiangsu","浙江省"="Zhejiang","安徽省"="Anhui","福建省"="Fujian",
  "江西省"="Jiangxi","山东省"="Shandong","河南省"="Henan","湖北省"="Hubei","湖南省"="Hunan",
  "广东省"="Guangdong","广西壮族自治区"="Guangxi","海南省"="Hainan","重庆市"="Chongqing",
  "四川省"="Sichuan","贵州省"="Guizhou","云南省"="Yunnan","西藏自治区"="Tibet","陕西省"="Shaanxi",
  "甘肃省"="Gansu","青海省"="Qinghai","宁夏回族自治区"="Ningxia","新疆维吾尔自治区"="Xinjiang",
  "台湾省"="Taiwan","香港特别行政区"="Hong Kong","澳门特别行政区"="Macau")

#' 读取省界、国界轮廓与九段线(均为 Albers 等积投影)/ provinces, outline, nine-dash line (Albers)
tj_basemap <- function() {
  rd <- function(f) sf::st_read(file.path(TJ_SHP, paste0(f, ".shp")), quiet = TRUE)
  prov <- sf::st_make_valid(rd("省（等积投影）"))
  prov$province <- unname(PROV_CN_EN[as.character(prov[["省"]])])
  list(prov = prov, outline = rd("中国轮廓线"), ninedash = rd("九段线"))
}

#' 经纬度矩形在 Albers 下的外包框 / bbox of a lon-lat rectangle in Albers metres
tj_bbox <- function(lon, lat, crs) {
  g <- expand.grid(x = seq(lon[1], lon[2], length.out = 40), y = seq(lat[1], lat[2], length.out = 40))
  p <- sf::st_transform(sf::st_as_sf(g, coords = c("x", "y"), crs = 4326), crs)
  b <- sf::st_bbox(p)
  list(x = unname(b[c("xmin", "xmax")]), y = unname(b[c("ymin", "ymax")]))
}

#' 中国地图 + 南海诸岛插图(标准地图做法)。layer_fun(bm) 返回要叠加在省界上的图层列表。
#' China map with the South China Sea inset (standard-map practice).
#' `fill_layer`: ggplot layers drawing the data; `scale`: fill scale.
tj_china_map <- function(fill_layer, scale, bm = tj_basemap(), legend = "right", credit = TRUE, title = NULL) {
  crs  <- sf::st_crs(bm$prov)
  main <- tj_bbox(c(73, 135.5), c(17.6, 53.8), crs)
  scs  <- tj_bbox(c(106.5, 123.5), c(3.0, 24.5), crs)
  base <- list(fill_layer,
               geom_sf(data = bm$outline,  colour = TJ$rule, linewidth = 0.18),
               geom_sf(data = bm$ninedash, colour = TJ$rule, linewidth = 0.25),
               scale)
  p_main <- ggplot() + base +
    coord_sf(crs = crs, xlim = main$x, ylim = main$y, expand = FALSE, datum = NA) +
    theme_tj_map() + theme(legend.position = legend)
  if (!is.null(title)) p_main <- p_main + labs(title = title)
  if (credit) p_main <- p_main + labs(caption = "GS(2019)1822") + theme(plot.caption = element_text(hjust = 1))
  p_scs <- ggplot() + base +
    coord_sf(crs = crs, xlim = scs$x, ylim = scs$y, expand = FALSE, datum = NA) +
    theme_tj_map() +
    theme(legend.position = "none", plot.margin = margin(0, 0, 0, 0),
          panel.border = element_rect(fill = NA, colour = TJ$rule, linewidth = 0.25),
          plot.background = element_rect(fill = "white", colour = NA))
  # 包成单一元素: 外层 patchwork 只给整幅地图编一个面板字母, 插图不编号
  # Wrapped as one element so the outer patchwork tags the map once and never the inset
  wrap_elements(full = p_main + inset_element(p_scs, left = 0.80, bottom = 0.0, right = 1.0, top = 0.30,
                                              align_to = "panel", ignore_tag = TRUE))
}

message("[TJ] theme loaded: ", TJ_DIR)
