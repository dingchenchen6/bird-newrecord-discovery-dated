#!/usr/bin/env Rscript
# ============================================================
# Script 154: 新纪录方向性 —— 雷达图与风玫瑰图(按目)
# Directionality of new records: radar and wind-rose plots by order
# ============================================================
# 科学问题 / Scientific question:
#   新纪录相对于物种已知分布中心, 是否有方向性偏倚? 若有, 偏向哪一侧?
#   这对应 GEB 原文的 Hypothesis 3: 新纪录应集中在分布区的北缘与东缘,
#   反映历史采样缺口与气候驱动的边界推移。
#
# 与既有鸟类方向图脚本的关系 / Relation to the existing bird directional script:
#   沿用 tasks/bird_directional_windrose_radar 的作图风格 —— ggradar 雷达、
#   coord_polar 风玫瑰、按目配色、标题条、PNG/PDF/PPTX 三格式导出。
#   三处改动:
#   (1) 事件改用【发现年定年】的 v2 集合(657 条, 2002-2024), 而非发表年定年;
#   (2) 每个目同时给出【新纪录数】与【物种数】两个样本量, 并直接写进标题条,
#       因为一个物种可在多个省产生多条记录, 两个口径的方向分布可以不同;
#   (3) 补上方向性的统计检验(卡方拟合优度 + 各方位的精确二项检验 + Holm 校正),
#       原脚本只作图不作检验。
#
# 方向的定义 / How direction is defined:
#   angle = atan2(经度差, 纬度差), 以物种分布区质心为原点, 正北为 0 度,
#   顺时针增加; 划为 8 个 45 度扇区。质心取自 AVONET(BirdLife 分布区质心)。
#
# Input / 输入:
#   analysis_v2/data/events_discovery_dated.csv        v2 事件(含经纬度)
#   analysis_v2/data/species_traits_harmonised_v2.csv  目名
#   AVONET1_BirdLife.csv                               分布区质心
# Output / 输出:
#   analysis_v2/figures_direction/{overall,combined,radar_by_order,windrose_by_order}/
#   analysis_v2/tables/tbl_v2_direction_{overall,by_order,tests}.csv
#
# Main packages / 主要包: ggradar, ggplot2, patchwork, data.table, officer, rvg
# 运行 / Run: Rscript --no-init-file code/154_directional_windrose_radar.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(ggradar); library(patchwork)
  library(scales); library(officer); library(rvg)
})
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
FIG <- file.path(OUT, "figures_direction")
DIRS <- file.path(FIG, c("overall", "combined", "radar_by_order", "windrose_by_order"))
for (d in DIRS) dir.create(d, recursive = TRUE, showWarnings = FALSE)
AVOF <- "/Users/dingchenchen/Downloads/AVONET/ELEData/TraitData/AVONET1_BirdLife.csv"
msg <- function(...) cat(sprintf("[154 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

DIRLV <- c("North", "Northeast", "East", "Southeast",
           "South", "Southwest", "West", "Northwest")
REPO6 <- c("#00bfc4", "#be84db", "#f8766d", "#7ad151", "#f1b722", "#619cff")
EXT10 <- c("#F29FB7", "#F4B183", "#C4A46B", "#B7C36B", "#9DCC8A",
           "#78C8A0", "#5FCFCF", "#7FB3FF", "#C3A4FF", "#E2A9E5")
norm <- function(x) { x <- trimws(gsub("_", " ", as.character(x))); x <- gsub("\\s+", " ", x)
                      paste0(toupper(substr(x, 1, 1)), tolower(substr(x, 2, nchar(x)))) }
slug <- function(x) tolower(gsub("^_+|_+$", "", gsub("[^A-Za-z0-9]+", "_", x)))

save_bundle <- function(p, dir, name, w, h) {
  ggsave(file.path(dir, paste0(name, ".png")), p, width = w, height = h, dpi = 450, bg = "white")
  tryCatch(ggsave(file.path(dir, paste0(name, ".pdf")), p, width = w, height = h,
                  device = grDevices::cairo_pdf, bg = "white"),
           error = function(e) msg("  pdf failed: ", conditionMessage(e)))
  tryCatch({ ppt <- add_slide(read_pptx(), "Blank", "Office Theme")
    ppt <- ph_with(ppt, dml(ggobj = p, bg = "white"), location = ph_location_fullsize())
    print(ppt, target = file.path(dir, paste0(name, ".pptx")))
  }, error = function(e) msg("  pptx failed: ", conditionMessage(e)))
}
header_strip <- function(txt, sub = NULL) {
  ggplot() +
    annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1,
             fill = "#D9D9D9", colour = "#6B6B6B", linewidth = 0.5) +
    annotate("text", x = 0.5, y = if (is.null(sub)) 0.5 else 0.66, label = txt,
             family = "sans", fontface = "bold", size = 3.5, colour = "#222222") +
    { if (!is.null(sub)) annotate("text", x = 0.5, y = 0.28, label = sub,
                                  family = "sans", size = 2.5, colour = "#444444") } +
    coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE) + theme_void()
}
with_strip <- function(p, txt, sub = NULL, h = 0.17)
  header_strip(txt, sub) / p + plot_layout(heights = c(h, 1))

radar_core <- function(df, col, alpha_fill = 0.52) {
  ggradar(df, grid.min = 0, grid.mid = 50, grid.max = 100,
          values.radar = c("0%", "50%", "100%"),
          group.line.width = 1.15, group.point.size = 2.15,
          background.circle.colour = "#F7FBFD",
          gridline.mid.colour = "#79CBE3", gridline.max.colour = "#79CBE3",
          gridline.min.colour = "#79CBE3",
          axis.label.size = 2.8, grid.label.size = 2.1, legend.position = "none",
          group.colours = alpha(col, alpha_fill)) +
    theme(plot.background = element_rect(fill = "white", colour = NA),
          panel.background = element_rect(fill = "white", colour = NA),
          plot.margin = margin(3, 3, 3, 3))
}
windrose_core <- function(df, col, show_x = TRUE) {
  ymax <- max(df$count, na.rm = TRUE); if (!is.finite(ymax) || ymax <= 0) ymax <- 1
  ggplot(df, aes(x = direction, y = count, group = 1)) +
    geom_polygon(fill = alpha(col, 0.26), colour = col, linewidth = 0.92) +
    geom_line(colour = col, linewidth = 0.92) +
    geom_point(colour = col, size = 2.0) +
    annotate("segment", x = 1:8, xend = 1:8, y = 0, yend = ymax,
             colour = "#707070", linewidth = 0.32) +
    scale_y_continuous(limits = c(0, ymax), breaks = c(ymax * 0.5, ymax),
                       labels = function(x) paste0(round(100 * x / ymax), "%")) +
    coord_polar(start = -pi / 8) + labs(x = NULL, y = NULL) +
    theme_minimal(base_size = 11) +
    theme(panel.grid.major = element_line(colour = "#79CBE3", linewidth = 0.55, linetype = "22"),
          panel.grid.minor = element_blank(),
          axis.text.y = element_text(size = 7, colour = "#6B6B6B"),
          axis.text.x = if (show_x) element_text(size = 8.5, colour = "#222222") else element_blank(),
          axis.title = element_blank(),
          plot.background = element_rect(fill = "white", colour = NA),
          panel.background = element_rect(fill = "white", colour = NA),
          plot.margin = margin(3, 3, 3, 3))
}

# ---- 1. 事件 + 目 + 分布区质心 ----
ev <- fread(file.path(OUT, "data", "events_discovery_dated.csv"))
ev <- ev[is.finite(longitude) & is.finite(latitude)]
av <- fread(AVOF)
cen <- unique(av[, .(nm = norm(Species1), order_lat = Order1,
                     clat = Centroid.Latitude, clon = Centroid.Longitude)], by = "nm")
ev[, nm := norm(species)]
d <- merge(ev, cen, by = "nm", all.x = TRUE)
msg("v2 事件 ", nrow(ev), " | 匹配到分布区质心 ", sum(is.finite(d$clat)),
    sprintf(" (%.1f%%)", 100 * mean(is.finite(d$clat))))
d <- d[is.finite(clat) & is.finite(clon)]
d[, order := tools::toTitleCase(tolower(order_lat))]

# ---- 2. 方向 ----
d[, `:=`(dx = longitude - clon, dy = latitude - clat)]
d[, angle := (atan2(dx, dy) * 180 / pi + 360) %% 360]
d[, direction := factor(fifelse(angle >= 337.5 | angle < 22.5, "North",
                        fifelse(angle < 67.5,  "Northeast",
                        fifelse(angle < 112.5, "East",
                        fifelse(angle < 157.5, "Southeast",
                        fifelse(angle < 202.5, "South",
                        fifelse(angle < 247.5, "Southwest",
                        fifelse(angle < 292.5, "West", "Northwest"))))))), levels = DIRLV)]
msg("参与方向分析: ", nrow(d), " 条新纪录 / ", uniqueN(d$species), " 物种 / ", uniqueN(d$order), " 目")

# ---- 3. 两个计数口径 ----
full <- CJ(order = unique(d$order), direction = factor(DIRLV, levels = DIRLV), unique = TRUE)
oc <- merge(full, d[, .(n_records = .N, n_species = uniqueN(species)), by = .(order, direction)],
            by = c("order", "direction"), all.x = TRUE)
oc[is.na(n_records), `:=`(n_records = 0L, n_species = 0L)]
tot <- d[, .(tot_records = .N, tot_species = uniqueN(species)), by = order][order(-tot_records)]
oc <- merge(oc, tot, by = "order")
oc[, `:=`(prop_records = n_records / tot_records, prop_species = n_species / tot_species)]
setorder(oc, -tot_records, order, direction)
fwrite(oc, file.path(OUT, "tables", "tbl_v2_direction_by_order.csv"))

ov <- d[, .(n_records = .N, n_species = uniqueN(species)), by = direction]
ov <- merge(data.table(direction = factor(DIRLV, levels = DIRLV)), ov, by = "direction", all.x = TRUE)
ov[is.na(n_records), `:=`(n_records = 0L, n_species = 0L)]
ov[, `:=`(prop_records = n_records / sum(n_records), prop_species = n_species / sum(n_species))]
fwrite(ov, file.path(OUT, "tables", "tbl_v2_direction_overall.csv"))
msg("总体前三方向(记录): ", paste(sprintf("%s %d (%.1f%%)",
    ov[order(-n_records)][1:3]$direction, ov[order(-n_records)][1:3]$n_records,
    100 * ov[order(-n_records)][1:3]$prop_records), collapse = " | "))

# ---- 4. 方向性检验(原脚本缺失的一环) ----
# 卡方拟合优度检验八方位是否均匀; 再对每个方位作单侧精确二项检验(H0: p = 1/8),
# Holm 校正。与 GEB 原文的方向性分析同法。
dir_tests <- function(cnt, lab) {
  n <- sum(cnt); if (n < 8) return(NULL)
  cs <- suppressWarnings(chisq.test(cnt))
  bt <- vapply(seq_along(cnt), function(i)
    binom.test(cnt[i], n, p = 1 / 8, alternative = "greater")$p.value, numeric(1))
  data.table(scope = lab, direction = factor(DIRLV, levels = DIRLV), count = cnt, n = n,
             expected = n / 8, chisq = unname(cs$statistic), df = unname(cs$parameter),
             chisq_p = cs$p.value, binom_p = bt, binom_p_holm = p.adjust(bt, "holm"))
}
tests <- rbindlist(c(list(dir_tests(ov$n_records, "Overall (records)"),
                          dir_tests(ov$n_species, "Overall (species)")),
                     lapply(tot[tot_records >= 8]$order, function(o)
                       dir_tests(oc[order == o][match(DIRLV, direction)]$n_records,
                                 paste0(o, " (records)")))), fill = TRUE)
tests[, over_represented := binom_p_holm < 0.05]
fwrite(tests, file.path(OUT, "tables", "tbl_v2_direction_tests.csv"))
ovt <- tests[scope == "Overall (records)"]
msg("总体方向性: chisq = ", round(ovt$chisq[1], 1), ", df = ", ovt$df[1],
    ", P = ", signif(ovt$chisq_p[1], 3),
    " | 显著过表达的方位: ", paste(ovt[over_represented == TRUE]$direction, collapse = ", "))

# ---- 5. 配色与选目 ----
sel <- head(tot$order, 16)
ovl <- head(tot$order, 6)
pal <- setNames(c(REPO6, EXT10)[seq_along(sel)], sel)

# 标题条: 目名 + 两个样本量 / order name plus both sample sizes
strip_sub <- function(o) {
  t <- tot[order == o]
  sprintf("new records = %d, species = %d", t$tot_records, t$tot_species)
}

# ---- 6. 总体叠加图 ----
ovd <- oc[order %in% ovl][, order := factor(order, levels = ovl)]
rad_in <- dcast(ovd, order ~ direction, value.var = "prop_records", fill = 0)
setnames(rad_in, "order", "group")
rad_in <- rad_in[, c("group", DIRLV), with = FALSE]
for (v in DIRLV) rad_in[[v]] <- 100 * rad_in[[v]]
leg <- sprintf("%s (%d records, %d spp.)", ovl, tot[match(ovl, order)]$tot_records,
               tot[match(ovl, order)]$tot_species)
rad_in[, group := leg]

p_ov_radar <- ggradar(rad_in, grid.min = 0, grid.mid = 50, grid.max = 100,
                      values.radar = c("", "", ""), group.line.width = 1.2,
                      group.point.size = 3.0, background.circle.colour = "white",
                      gridline.mid.colour = "#222222", gridline.max.colour = "#222222",
                      gridline.min.colour = "#222222", axis.label.size = 4.4,
                      grid.label.size = 0, legend.position = "right",
                      group.colours = alpha(unname(pal[ovl]), 0.78)) +
  theme(plot.background = element_rect(fill = "white", colour = NA),
        panel.background = element_rect(fill = "white", colour = NA),
        legend.text = element_text(size = 10.5), axis.text = element_text(size = 13, colour = "#222222"),
        plot.margin = margin(8, 8, 8, 8))

# 叠加图用【比例】而非绝对数: 雀形目 388 条会把其余各目压到圆心, 完全不可读;
# 叠加的意义在于比较形状, 绝对样本量已写在图例中。
# NB: overlay uses proportions - Passeriformes' 388 records would flatten every
#     other order against the centre, and the point of an overlay is shape.
ymax <- max(ovd$prop_records) * 1.08
ovd[, leg := sprintf("%s (%d records, %d spp.)", order, tot_records, tot_species)]
ovd[, leg := factor(leg, levels = leg[match(ovl, order)])]
p_ov_wind <- ggplot(ovd, aes(direction, prop_records, group = leg, colour = leg, fill = leg)) +
  geom_polygon(alpha = 0.22, linewidth = 1.05) +
  geom_line(linewidth = 1.05) + geom_point(size = 3.0) +
  annotate("segment", x = 1:8, xend = 1:8, y = 0, yend = ymax, colour = "#111111", linewidth = 0.65) +
  scale_colour_manual(values = unname(pal[ovl])) + scale_fill_manual(values = unname(pal[ovl])) +
  scale_y_continuous(limits = c(0, ymax), breaks = c(ymax * 0.5, ymax),
                     labels = function(x) percent(x, accuracy = 1)) +
  coord_polar(start = -pi / 8) +
  labs(x = NULL, y = NULL, colour = NULL, fill = NULL,
       caption = "Share of each order's own new records; absolute sample sizes are given in the legend") +
  theme_minimal(base_size = 14) +
  theme(panel.grid.major = element_line(colour = "#111111", linewidth = 0.8, linetype = "22"),
        panel.grid.minor = element_blank(),
        axis.text.y = element_text(size = 9, colour = "#6B6B6B"),
        axis.text.x = element_text(size = 14, colour = "#222222"),
        plot.caption = element_text(size = 9, colour = "grey35", hjust = 0),
        legend.position = "right", legend.text = element_text(size = 10.5),
        plot.background = element_rect(fill = "white", colour = NA),
        panel.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(12, 12, 12, 12))
save_bundle(p_ov_radar, DIRS[1], "overall_direction_radar", 13.0, 8.8)
save_bundle(p_ov_wind,  DIRS[1], "overall_direction_windrose", 13.0, 8.8)

# ---- 7. 4x4 组合图 + 各目单图 ----
mk_radar <- function(o) {
  r <- dcast(oc[order == o], order ~ direction, value.var = "prop_records", fill = 0)
  setnames(r, "order", "group"); r <- r[, c("group", DIRLV), with = FALSE]
  for (v in DIRLV) r[[v]] <- 100 * r[[v]]
  with_strip(radar_core(r, pal[[o]]), o, strip_sub(o))
}
mk_wind <- function(o) {
  w <- oc[order == o][match(DIRLV, direction)][, .(direction, count = n_records)]
  with_strip(windrose_core(w, pal[[o]]), o, strip_sub(o))
}
save_bundle(wrap_plots(lapply(sel, mk_radar), ncol = 4), DIRS[2],
            "order_direction_radar_facets", 14.6, 15.4)
save_bundle(wrap_plots(lapply(sel, mk_wind), ncol = 4), DIRS[2],
            "order_direction_windrose_facets", 14.6, 15.4)
for (o in sel) {
  save_bundle(mk_radar(o), DIRS[3], paste0(slug(o), "_direction_radar"), 4.7, 4.6)
  save_bundle(mk_wind(o),  DIRS[4], paste0(slug(o), "_direction_windrose"), 4.7, 4.8)
}
msg("导出 ", length(sel), " 个目的单图 + 4x4 组合图 + 总体叠加图")
msg("样本量最大的三个目: ", paste(sprintf("%s (%d records, %d spp.)",
    tot[1:3]$order, tot[1:3]$tot_records, tot[1:3]$tot_species), collapse = " | "))
msg("DONE")
