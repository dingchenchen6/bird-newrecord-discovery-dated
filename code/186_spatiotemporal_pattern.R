# ============================================================
# Scientific question / 科学问题:
# 在进入预测之前,先展示原始数据本身的时空格局:
# 1,059 条中国鸟类新分布记录(CBNR 发布版, Zenodo 20809949)在
# 空间上落在哪里、在时间上如何累积、记录的地理位置随时间怎样漂移。
# Before any prediction, show the raw spatio-temporal pattern of the
# released CBNR compilation (Zenodo record 20809949, CC-BY-4.0).
#
# Panels / 面板:
#   a 记录点图(点色 = 年份,冷→暖)     overview
#   b 省级累计记录数 choropleth        space
#   c 年度记录数(发表年柱 + 发现年线)  time
#   d 记录纬度/经度随时间的漂移        space × time
#
# Input / 输入:
#   source_data/bird_new_records_clean.csv     1,059 条(发布口径)
#   analysis_v2/data/events_discovery_dated.csv  657 条(建模窗口,发现年)
#   data/spatial/basemap_GS2019_1822/*.shp
# Output / 输出: analysis_v2/figures_multiscale/FigST1_spatiotemporal_pattern
#
# Key assumptions / 关键假设:
#   - a/b/c 柱按发布口径的报告年份;c 同时叠加建模子集的发现年序列,
#     两者的错位正是正文定年校正(Figure 2)的动机。
#   - 配色:时间用冷→暖(RdYlBu 反转),与预测图的量级色带一致语义。
# Main packages / 主要包: sf, ggplot2, patchwork, data.table
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(sf); library(ggplot2); library(patchwork); library(scales)
})
sf_use_s2(FALSE)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
SRCD <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/source_data"
D_FG <- file.path(V2, "analysis_v2/figures_multiscale")
BM   <- file.path(V2, "data/spatial/basemap_GS2019_1822")
AEA  <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +datum=WGS84 +units=m"
msg  <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

theme_pub <- function(base = 9) {
  theme_classic(base_size = base, base_family = "sans") +
    theme(axis.text = element_text(colour = "grey15"),
          axis.title = element_text(colour = "grey5"),
          strip.background = element_blank(),
          plot.title = element_text(face = "bold", size = base + 1, hjust = 0),
          plot.subtitle = element_text(size = base - 0.8, colour = "grey30", hjust = 0),
          legend.key.size = unit(3.2, "mm"),
          legend.text = element_text(size = base - 1),
          legend.title = element_text(size = base - 1, face = "bold"))
}
theme_map <- function(base = 9) {
  theme_void(base_size = base, base_family = "sans") +
    theme(plot.title = element_text(face = "bold", size = base + 0.5, hjust = 0),
          plot.subtitle = element_text(size = base - 1, colour = "grey30", hjust = 0),
          legend.key.height = unit(3.0, "mm"), legend.key.width = unit(8, "mm"),
          legend.text = element_text(size = base - 1.5),
          legend.title = element_text(size = base - 1, face = "bold"),
          legend.position = "bottom")
}

# ---------------- 数据 ----------------
rec <- fread(file.path(SRCD, "bird_new_records_clean.csv"))
rec <- rec[is.finite(longitude) & is.finite(latitude) & is.finite(year)]
# 剔除明显的坐标异常(如经纬度错位;中国陆域约 lat 15-56, lon 73-136)
n_bad <- rec[!(latitude %between% c(15, 56) & longitude %between% c(73, 136)), .N]
rec <- rec[latitude %between% c(15, 56) & longitude %between% c(73, 136)]
msg("剔除坐标异常 ", n_bad, " 条")
msg("发布版记录 ", nrow(rec), " 条,", uniqueN(rec$species), " 种,",
    uniqueN(rec$province), " 省级单元,年份 ", min(rec$year), "-", max(rec$year))
ev  <- fread(file.path(V2, "analysis_v2/data/events_discovery_dated.csv"))

prov_sf <- st_make_valid(st_transform(st_read(file.path(BM, "省（等积投影）.shp"), quiet = TRUE), AEA))
nine    <- st_transform(st_read(file.path(BM, "九段线.shp"), quiet = TRUE), AEA)
nation  <- st_make_valid(st_transform(st_read(file.path(BM, "国界.shp"), quiet = TRUE), AEA))

pts <- st_transform(st_as_sf(rec, coords = c("longitude", "latitude"), crs = 4326), AEA)

# 省名映射(发布表 province 为英文) / EN→CN lookup
lk <- unique(fread(file.path(V2, "analysis_v2/data/admin/units_county.csv"))[, .(province, prov_cn)])
pc <- rec[, .N, by = province]
pc <- merge(pc, lk, by = "province", all.x = TRUE)

YRS <- range(rec$year)
COL_TIME <- "RdYlBu"

# ---------------- a 记录点图 ----------------
pa <- ggplot() +
  geom_sf(data = prov_sf, fill = "grey96", colour = "white", linewidth = .15) +
  geom_sf(data = nation, fill = NA, colour = "grey40", linewidth = .18) +
  geom_sf(data = nine, colour = "grey30", linewidth = .3) +
  geom_sf(data = pts, aes(colour = year), size = 1.15, alpha = .75, stroke = 0) +
  scale_colour_distiller(palette = COL_TIME, direction = -1, limits = YRS,
                         name = "记录年份", breaks = pretty_breaks(5)) +
  coord_sf(expand = FALSE) +
  labs(title = sprintf("a  %s 条新纪录的空间分布(点色 = 年份)", format(nrow(rec), big.mark = ","))) +
  theme_map() + theme(legend.key.width = unit(11, "mm"))

# ---------------- b 省级累计 ----------------
mb <- merge(prov_sf, pc, by.x = "省", by.y = "prov_cn", all.x = FALSE)
pb <- ggplot() +
  geom_sf(data = prov_sf, fill = "grey96", colour = "white", linewidth = .15) +
  geom_sf(data = mb, aes(fill = N), colour = "white", linewidth = .15) +
  geom_sf(data = nation, fill = NA, colour = "grey40", linewidth = .18) +
  geom_sf(data = nine, colour = "grey30", linewidth = .3) +
  scale_fill_distiller(palette = COL_TIME, direction = -1, trans = "log10",
                       name = "累计新纪录数",
                       breaks = function(l) round(exp(seq(log(l[1]), log(l[2]), length.out = 4)))) +
  coord_sf(expand = FALSE) +
  labs(title = "b  省级累计新纪录数(2000–2025)") +
  theme_map() + theme(legend.key.width = unit(11, "mm"))

# ---------------- c 年度序列 ----------------
yr_pub <- rec[, .N, by = year]
yr_dis <- ev[, .N, by = disc_year]
pc3 <- ggplot() +
  geom_col(data = yr_pub, aes(year, N, fill = year), width = .82) +
  geom_line(data = yr_dis, aes(disc_year, N), colour = "grey15", linewidth = .55) +
  geom_point(data = yr_dis, aes(disc_year, N), colour = "grey15", size = 1.1) +
  scale_fill_distiller(palette = COL_TIME, direction = -1, guide = "none") +
  scale_x_continuous(breaks = seq(2000, 2025, 5)) +
  scale_y_continuous(expand = expansion(c(0, .06))) +
  labs(x = NULL, y = "记录数 / 年",
       title = "c  年度记录数持续上升",
       subtitle = "柱:发布口径(报告年份);黑线:建模子集按发现年 —— 两者的错位即定年校正的动机") +
  theme_pub()

# ---------------- d 位置随时间漂移 ----------------
dl <- melt(rec[, .(year, 纬度 = latitude, 经度 = longitude)],
           id.vars = "year", variable.name = "dim", value.name = "v")
pd <- ggplot(dl, aes(year, v)) +
  geom_point(aes(colour = year), size = .8, alpha = .55, stroke = 0) +
  geom_smooth(method = "loess", se = TRUE, colour = "grey15", linewidth = .6,
              fill = "grey70", alpha = .35, span = .9) +
  facet_wrap(~ dim, scales = "free_y", nrow = 2, strip.position = "left") +
  scale_colour_distiller(palette = COL_TIME, direction = -1, guide = "none") +
  scale_x_continuous(breaks = seq(2000, 2025, 5)) +
  labs(x = NULL, y = NULL, title = "d  记录位置的时间漂移",
       subtitle = "每点一条记录;灰带为 loess ± SE") +
  theme_pub() +
  theme(strip.placement = "outside",
        strip.text = element_text(face = "bold", size = 9))

FigST1 <- (pa | pb) / (pc3 | pd) + plot_layout(heights = c(1.25, 1)) +
  plot_annotation(
    caption = paste0(sprintf("数据:China Bird New Record (CBNR) 数据集,Zenodo 记录 20809949(CC-BY-4.0);剔除坐标异常 %d 条。", n_bad),
                     "底图:审图号 GS(2019)1822。"),
    theme = theme(plot.caption = element_text(size = 7, colour = "grey45", hjust = 0)))
ggsave(file.path(D_FG, "FigST1_spatiotemporal_pattern.png"), FigST1,
       width = 12.2, height = 9.0, dpi = 450, bg = "white")
ggsave(file.path(D_FG, "FigST1_spatiotemporal_pattern.pdf"), FigST1,
       width = 12.2, height = 9.0, device = grDevices::cairo_pdf)
cat("wrote FigST1\n")
