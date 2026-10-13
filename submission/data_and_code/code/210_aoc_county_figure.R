# ============================================================
# Scientific question / 科学问题:
# 下一条省级新纪录最可能落在省内哪个县?模型给出的热点是否与鸟友熟知的地点吻合?
# Where within a province is the next new record most likely to land, and do
# the model's hotspots match places birders already know?
#
# Objective / 分析目标:
# 为 AOC 2026 报告制作投影可读的英文县级降尺度图(两面板),替代中文 4 面板 FigC2。
# A projection-legible English two-panel county figure for the AOC talk.
#
# Input data / 输入数据:
#   analysis_v2/data/admin/county_surface_now.csv  (县级份额面, 脚本 172)
#   data/spatial/basemap_GS2019_1822/*.shp         (审图号 GS(2019)1822)
#
# Main workflow / 主要流程:
#   1. 份额 × 省内县数 = 相对省内均匀分配的倍数 / share relative to uniform
#   2. a: 县级相对概率图 / county map
#   3. b: 期望份额前 10 的县(英文名手工转写) / top-10 counties, English names
#
# Expected output / 预期输出: analysis_v2/figures_aoc/FigAOC_county_surface.{png,pdf}
# Key assumptions / 关键假设:
#   - 县名英文采用官方/通行拼写(如 墨脱 = Medog, 阿拉善左旗 = Alxa Left Banner);
#     映射表写死在脚本中并与数据逐条核对, 缺失即报错, 不会静默回退到中文。
#   - 数值与中文版 FigC2 同源(county_surface_now.csv), 仅语言与版式不同。
# Main packages / 主要包: data.table, sf, ggplot2, patchwork
# Output directory / 输出路径: analysis_v2/figures_aoc/
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(sf); library(ggplot2); library(patchwork); library(scales)
})
sf_use_s2(FALSE)

V2  <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
BM  <- file.path(V2, "data/spatial/basemap_GS2019_1822")
OUT <- file.path(V2, "analysis_v2/figures_aoc"); dir.create(OUT, showWarnings = FALSE)
AEA <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +datum=WGS84 +units=m"
INK <- "#17332D"; BLUE <- "#0072B2"

# ---------- 数据 / data ----------
cs <- fread(file.path(V2, "analysis_v2/data/admin/county_surface_now.csv"), encoding = "UTF-8")
cs[, unit_id := as.character(unit_id)]

# 前 10 县的英文名(官方/通行拼写) / English names for the top-10 counties
EN <- c("墨脱县" = "Medog", "浦东新区" = "Pudong", "滨海新区" = "Binhai",
        "阿拉善左旗" = "Alxa Left Banner", "罗山县" = "Luoshan", "沙坡头区" = "Shapotou",
        "崇明区" = "Chongming", "蓟州区" = "Jizhou", "乐东黎族自治县" = "Ledong",
        "洋县" = "Yang County")
top <- head(cs[order(-share)], 10)
miss <- setdiff(top$unit_nm, names(EN))
if (length(miss)) stop("缺英文名 / missing English names: ", paste(miss, collapse = ", "))
top[, lbl := sprintf("%s, %s", EN[unit_nm], province)]
top[, lbl := factor(lbl, levels = rev(lbl))]

cnty <- st_make_valid(st_transform(st_read(file.path(BM, "县（等积投影）.shp"), quiet = TRUE), AEA))
cnty$unit_id <- as.character(cnty$PAC)
cnty <- cnty[!duplicated(cnty$unit_id), ]
prov   <- st_transform(st_read(file.path(BM, "省（等积投影）.shp"), quiet = TRUE), AEA)
nine   <- st_transform(st_read(file.path(BM, "九段线.shp"), quiet = TRUE), AEA)
mp <- merge(cnty[, "unit_id"], cs[, .(unit_id, share, n_unit_prov)], by = "unit_id", all.x = TRUE)
mp$rel <- mp$share * mp$n_unit_prov                 # 相对均匀分配的倍数 / x uniform

# ---------- a 县级相对概率 / county map ----------
pa <- ggplot() +
  geom_sf(data = mp, aes(fill = pmin(rel, 12)), colour = NA) +
  geom_sf(data = prov, fill = NA, colour = "grey30", linewidth = 0.18) +
  geom_sf(data = nine, colour = "grey35", linewidth = 0.35) +
  scale_fill_viridis_c(option = "magma", direction = -1, na.value = "grey93",
                       limits = c(0, 12), breaks = c(0, 4, 8, 12),
                       labels = c("0", "4", "8", "≥12"),
                       name = "Times the\nuniform share") +
  coord_sf(expand = FALSE) +
  theme_void(base_size = 12, base_family = "Arial") +
  theme(legend.position = "left", legend.justification = c(1, 0.35),
        legend.box.margin = margin(0, 18, 0, 0),
        legend.title = element_text(size = 10.5, face = "bold", colour = INK, lineheight = 0.95,
                                    margin = margin(b = 7)),
        legend.text = element_text(size = 10, colour = INK),
        legend.key.height = unit(4.2, "mm"), legend.key.width = unit(3.4, "mm"),
        plot.margin = margin(2, 2, 2, 2))

# ---------- b 前 10 县 / top-10 counties ----------
pb <- ggplot(top, aes(share, lbl)) +
  geom_col(fill = BLUE, width = 0.68) +
  geom_text(aes(label = sprintf("%.0f%%", 100 * share)),
            hjust = -0.08, size = 3.6, colour = "grey20") +
  scale_x_continuous(labels = percent_format(1), expand = expansion(c(0, 0.12))) +
  labs(x = "Expected share of the province's next record", y = NULL) +
  theme_classic(base_size = 12, base_family = "Arial") +
  theme(axis.text.y = element_text(size = 11, colour = INK),
        axis.text.x = element_text(size = 10, colour = "grey20"),
        axis.title.x = element_text(size = 10.5, colour = "grey25"),
        axis.line = element_line(linewidth = 0.35), axis.ticks = element_line(linewidth = 0.3),
        plot.margin = margin(4, 8, 2, 4))

ttl <- function(s) wrap_elements(full = grid::textGrob(
  s, x = unit(4, "pt"), hjust = 0,
  gp = grid::gpar(fontfamily = "Arial", fontface = "bold", fontsize = 13, col = INK)))
fig <- ttl("a  Relative chance of hosting the next provincial record") /
  wrap_elements(full = pa) /
  ttl("b  Top 10 counties by expected share") /
  pb + plot_layout(heights = c(0.10, 1.55, 0.10, 1.15))
ggsave(file.path(OUT, "FigAOC_county_surface.png"), fig, width = 6.3, height = 5.6, dpi = 300, bg = "white")
ggsave(file.path(OUT, "FigAOC_county_surface.pdf"), fig, width = 6.3, height = 5.6, device = grDevices::cairo_pdf)
cat("wrote FigAOC_county_surface\n")
