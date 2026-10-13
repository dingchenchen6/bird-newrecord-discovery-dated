# ============================================================
# Scientific question / 科学问题:
# 已发布的 CBNR v2 数据在空间上落在哪里、在时间上如何累积?
# 发现年与发表年之间的滞后在原始数据里是否一眼可见?
# Where do the 1,029 released CBNR records fall, how did they accumulate,
# and is the discovery-to-publication lag visible in the raw data?
#
# Objective / 分析目标:
# 为亚洲鸟类学大会(AOC 2026, 新加坡)报告制作一张投影可读的 CBNR 概览图;
# 图中数字必须与 Zenodo v2 (DOI 10.5281/zenodo.20809949) 完全一致。
# A projection-legible CBNR overview for the AOC 2026 talk whose counts
# match the Zenodo v2 record exactly.
#
# Input data / 输入数据:
#   source_data/CBNR_v2_zenodo20809949/CBNR_EN.csv   (1,029 records)
#   tasks/.../data/spatial/basemap_GS2019_1822/*.shp  (审图号 GS(2019)1822)
#
# Main workflow / 主要流程:
#   1. 读取 v2 发布表,解析发现年与发表年 / parse discovery & publication years
#   2. a: 点图(点色 = 发现年,冷→暖) / points coloured by discovery year
#   3. b: 年度计数(柱 = 发表年;线 = 发现年) / annual counts, two clocks
#
# Expected output / 预期输出:
#   analysis_v2/figures_aoc/FigAOC_cbnr_overview.{png,pdf}
#
# Key assumptions / 关键假设:
#   - 画布按幻灯片上的实际显示尺寸创作(6.3 x 5.6 in ≈ 710 x 540 px @96 ppi),
#     使图内 11–13 pt 文字在 1280x720 幻灯片上约为 15–17 px。
#   - 发现年早于 2000 的少数记录(馆藏标本再鉴定等)在色标上并入 "≤2000"。
#   - 发现年序列末端的回落是右删失(尚未发表),不是真实下降。
#
# Main packages / 主要包: data.table, sf, ggplot2, patchwork
# Output directory / 输出路径: analysis_v2/figures_aoc/
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(sf); library(ggplot2); library(patchwork); library(scales)
})
sf_use_s2(FALSE)

ROOT <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records"
V2   <- file.path(ROOT, "tasks/bird_hazard_model_effort_upgrade_v2")
BM   <- file.path(V2, "data/spatial/basemap_GS2019_1822")
OUT  <- file.path(V2, "analysis_v2/figures_aoc"); dir.create(OUT, showWarnings = FALSE)
AEA  <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +datum=WGS84 +units=m"
AMBER <- "#B45309"; INK <- "#17332D"; GREY_BAR <- "#C9C3B8"

# ---------- 1. 数据 / data ----------
# 年份解析: 取字段中第一个四位年份 / first four-digit year in the field
year_of <- function(x) as.integer(sub(".*?((19|20)[0-9]{2}).*", "\\1",
                                      ifelse(grepl("(19|20)[0-9]{2}", x), x, NA)))
cb <- fread(file.path(ROOT, "source_data/CBNR_v2_zenodo20809949/CBNR_EN.csv"), encoding = "UTF-8")
cb[, disc_year := year_of(Discovery_date)]
cb[, pub_year  := year_of(as.character(Source_publication_year))]
stopifnot(nrow(cb) == 1029L)                      # 与 Zenodo v2 一致 / must match v2
cat(sprintf("records %d | discovery year parsed %d | publication year parsed %d\n",
            nrow(cb), sum(!is.na(cb$disc_year)), sum(!is.na(cb$pub_year))))

prov   <- st_make_valid(st_transform(st_read(file.path(BM, "省（等积投影）.shp"), quiet = TRUE), AEA))
nation <- st_make_valid(st_transform(st_read(file.path(BM, "国界.shp"), quiet = TRUE), AEA))
nine   <- st_transform(st_read(file.path(BM, "九段线.shp"), quiet = TRUE), AEA)
pts    <- st_transform(st_as_sf(cb, coords = c("Longitude", "Latitude"), crs = 4326), AEA)
pts$col_year <- pmax(pts$disc_year, 2000L)       # ≤2000 合并 / clamp early years

# ---------- 2. a 点图 / map ----------
pa <- ggplot() +
  geom_sf(data = prov, fill = "#F1EEE8", colour = "white", linewidth = 0.2) +
  geom_sf(data = nation, fill = NA, colour = "grey45", linewidth = 0.25) +
  geom_sf(data = nine, colour = "grey35", linewidth = 0.35) +
  geom_sf(data = pts[order(pts$col_year), ], aes(colour = col_year),
          size = 1.35, alpha = 0.85, stroke = 0) +
  scale_colour_distiller(palette = "RdYlBu", direction = -1, limits = c(2000, 2025),
                         breaks = c(2000, 2010, 2020), labels = c("≤2000", "2010", "2020"),
                         name = "Discovery year") +
  coord_sf(expand = FALSE) +
  theme_void(base_size = 12, base_family = "Arial") +
  theme(plot.title = element_text(face = "bold", size = 13, colour = INK, margin = margin(b = 4)),
        plot.title.position = "plot",   # 与 b 面板标题左对齐 / left-align with panel b
        # coord_sf 的面板只与地图等宽, 相对坐标图例会落在地图上 -> 放到面板左侧空白
        # NB: the sf panel is only as wide as the map; place the legend outside it.
        legend.position = "left", legend.justification = c(1, 0.35),
        legend.box.margin = margin(0, 18, 0, 0),
        legend.title = element_text(size = 10.5, face = "bold", colour = INK),
        legend.text = element_text(size = 10, colour = INK),
        legend.key.height = unit(4.2, "mm"), legend.key.width = unit(3.4, "mm"),
        plot.margin = margin(2, 2, 2, 2))

# ---------- 3. b 两种时钟的年度计数 / two clocks ----------
yrs  <- 2000:2025
pubN <- cb[pub_year %in% yrs, .N, by = .(year = pub_year)]
disN <- cb[disc_year %in% yrs, .N, by = .(year = disc_year)]
lag  <- cb[!is.na(disc_year) & !is.na(pub_year), pub_year - disc_year]
cat(sprintf("publication lag: mean %.2f yr, median %d, >=1 yr %.1f%%\n",
            mean(lag), as.integer(median(lag)), 100 * mean(lag >= 1)))

pb <- ggplot() +
  geom_col(data = pubN, aes(year, N), fill = GREY_BAR, width = 0.8) +
  geom_line(data = disN, aes(year, N), colour = AMBER, linewidth = 1.0) +
  geom_point(data = disN, aes(year, N), colour = AMBER, size = 1.6) +
  annotate("text", x = 2000.3, y = max(pubN$N) * 0.97, hjust = 0, vjust = 1, size = 3.9,
           colour = "grey35", label = "Bars: year published") +
  annotate("text", x = 2000.3, y = max(pubN$N) * 0.80, hjust = 0, vjust = 1, size = 3.9,
           colour = AMBER, fontface = "bold", label = "Line: year discovered") +
  annotate("text", x = 2025.4, y = max(pubN$N) * 1.17, hjust = 1, vjust = 1, size = 3.7,
           colour = AMBER, label = "recent finds not yet published") +
  annotate("segment", x = 2024.55, xend = 2024.55, y = max(pubN$N) * 1.04,
           yend = disN[year == 2024, N] + 6, colour = AMBER, linewidth = 0.5,
           arrow = arrow(length = unit(1.6, "mm"), type = "closed")) +
  scale_x_continuous(breaks = seq(2000, 2025, 5), expand = expansion(add = 0.6)) +
  scale_y_continuous(expand = expansion(c(0, 0.02)), limits = c(0, max(pubN$N) * 1.18)) +
  labs(x = NULL, y = "Records per year") +
  theme_classic(base_size = 12, base_family = "Arial") +
  theme(plot.title = element_text(face = "bold", size = 13, colour = INK),
        axis.text = element_text(colour = "grey20", size = 10.5),
        axis.title.y = element_text(size = 11, colour = INK),
        axis.line = element_line(linewidth = 0.35), axis.ticks = element_line(linewidth = 0.3),
        plot.margin = margin(6, 8, 2, 4))

# 面板标题用独立文本行: 地图面板定宽比且居中, ggplot 内部标题无法与 b 左对齐
# NB: panel titles as separate text rows - the aspect-locked map panel is centred,
#     so in-plot titles cannot share a left edge with panel b.
ttl <- function(s) wrap_elements(full = grid::textGrob(
  s, x = unit(4, "pt"), hjust = 0,
  gp = grid::gpar(fontfamily = "Arial", fontface = "bold", fontsize = 13, col = INK)))
fig <- ttl("a  1,029 records across 33 provincial units") /
  wrap_elements(full = pa) /
  ttl(sprintf("b  Records reach print %.1f years after discovery", mean(lag))) /
  pb + plot_layout(heights = c(0.10, 1.60, 0.10, 1))
ggsave(file.path(OUT, "FigAOC_cbnr_overview.png"), fig, width = 6.3, height = 5.6, dpi = 300, bg = "white")
ggsave(file.path(OUT, "FigAOC_cbnr_overview.pdf"), fig, width = 6.3, height = 5.6, device = grDevices::cairo_pdf)
cat("wrote FigAOC_cbnr_overview\n")
