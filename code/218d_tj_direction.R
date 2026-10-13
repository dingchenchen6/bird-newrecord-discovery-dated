#!/usr/bin/env Rscript
# ============================================================
# Script 218d: 顶刊版主图 —— 新纪录方位与几何零假设
#              Top-journal figure: bearings of new records against geometric nulls
# ============================================================
# Scientific question / 科学问题:
#   从物种全球分布区质心量到新纪录的方位强烈偏东。这一偏倚是否只是分布区几何
#   (中国相对质心的位置)的产物? 扣除几何与调查努力之后还剩下什么方向信号?
#   Bearings from species' global range centroids to new records point east.
#   Is the skew a product of range geometry, and what remains once geometry and
#   survey effort are accounted for?
#
# Objective / 分析目标:
#   按 218 顶刊规范重绘脚本 154 的主图 overall_direction_null: (a) 总体方位份额与两个
#   零假设期望; (b) 各方位观测/期望比及蒙特卡洛 95% 区间; (c) 记录最多的六个目,
#   由叠加图改为同一径向刻度的小多图。作图数值与原图逐一相同, 只改版式与编码。
#   Redraw script 154's overall_direction_null in the shared top-journal style;
#   panel c becomes small multiples. Every plotted value equals the original.
#
# Input data / 输入数据:
#   analysis_v2/data/events_discovery_dated.csv                     v2 新纪录 / v2 events
#   AVONET1_BirdLife.csv                                            分布区质心与目 / centroids, orders
#   analysis_v2/tables/tbl_v2_direction_geometric_null.csv          214 逐方位零假设 / per-sector nulls
#   analysis_v2/tables/tbl_v2_direction_geometric_null_summary.csv  214 整体检验 / omnibus tests
#   analysis_v2/tables/tbl_v2_direction_{by_order,overall}.csv      154 输出, 仅作核对 / cross-check only
#   analysis_v2/tables/tbl_v2_direction_null_si_sectors.csv         214 SI 表, 仅作核对 / cross-check only
#
# Main workflow / 主要流程:
#   1. 原样复用 154 的数据准备(方位、扇区、计数、选目), 与 154 的持久化表逐值核对
#   2. 原样复用 154 的零假设整理(读 214 持久化表, 不重跑蒙特卡洛), 与 SI 表核对
#   3. 在笛卡尔坐标中画雷达多边形(顶点位于扇区中心方位), 以便精确控制标注
#   4. 上行 a | b, 下行 c 小多图; 导出全图、单面板与长格式源数据
#
# Expected output / 预期输出:
#   analysis_v2/figures_topjournal/TJ_Fig_direction_null.{pdf,png,svg}          183 mm 宽 / wide
#   analysis_v2/figures_topjournal/panels/TJ_Fig_direction_null_{a,b,c}.{pdf,png,svg}   (c 为 2 x 3 幻灯片版 / c in 2 x 3 for slides)
#   analysis_v2/figures_topjournal/source_data_TJ_Fig_direction_null.csv
#   幻灯片模式 TJ_SLIDE=1 时, 同名文件写到 figures_topjournal_slides/(字号约 11 pt, 画幅 x 1.25)
#   With TJ_SLIDE=1 the same files go to figures_topjournal_slides/ (~11 pt text, canvas x 1.25)
#
# Key assumptions / 关键假设:
#   - 扇区定义、筛选与所选六个目与 154 完全相同; 零假设数值来自 214(999 次, 种子 20260924)
#   - 原图在极坐标中把相邻顶点插值成弧线, 此处改为直线相连; 顶点数值不变
#     154 interpolated arcs between sector vertices; straight chords here, same vertices.
#   - 显著 = 214 的双侧蒙特卡洛 P 经 Holm 校正后 < 0.05 / significant = Holm-adjusted MC P < 0.05
#   - 面板内数字(χ²、蒙特卡洛 P、东/北三扇区份额)直接取自 214 整体表, 与正文和图注一致
#     In-panel numbers (χ², Monte Carlo P, NE–SE and NW–NE shares) come from 214's summary table.
#
# Main packages / 主要包: data.table, ggplot2, patchwork, ggtext, scales; 218 共享主题 / shared theme
# Output directory / 输出路径: analysis_v2/figures_topjournal/
# Run / 运行(任务根目录 / task root): Rscript --no-init-file code/218d_tj_direction.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(patchwork); library(scales); library(ggtext)
})
options(warn = 1)
source("code/218_theme_topjournal.R")              # TJ 调色板、theme_tj、tj_save / shared design system

FIG  <- "TJ_Fig_direction_null"
OUT  <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
AVOF <- "/Users/dingchenchen/Downloads/AVONET/ELEData/TraitData/AVONET1_BirdLife.csv"
msg  <- function(...) cat(sprintf("[218d %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

# ============================================================
# 1. 数据准备 —— 原样复制自 154 第 1–3、5、6 节; 只删去 fwrite(不覆盖 154 的输出)
#    Data preparation copied verbatim from 154 §1–3, §5, §6; only the fwrite calls are dropped.
# ============================================================
DIRLV <- c("North", "Northeast", "East", "Southeast",
           "South", "Southwest", "West", "Northwest")
norm <- function(x) { x <- trimws(gsub("_", " ", as.character(x))); x <- gsub("\\s+", " ", x)
                      paste0(toupper(substr(x, 1, 1)), tolower(substr(x, 2, nchar(x)))) }

ev <- fread(file.path(OUT, "data", "events_discovery_dated.csv"))
ev <- ev[is.finite(longitude) & is.finite(latitude)]
av <- fread(AVOF)
cen <- unique(av[, .(nm = norm(Species1), order_lat = Order1,
                     clat = Centroid.Latitude, clon = Centroid.Longitude)], by = "nm")
ev[, nm := norm(species)]
d <- merge(ev, cen, by = "nm", all.x = TRUE)
d <- d[is.finite(clat) & is.finite(clon)]
d[, order := tools::toTitleCase(tolower(order_lat))]

# 方位: 以分布区质心为原点, 正北 0 度、顺时针; 8 个 45 度扇区 / bearing from centroid, 8 sectors
d[, `:=`(dx = longitude - clon, dy = latitude - clat)]
d[, angle := (atan2(dx, dy) * 180 / pi + 360) %% 360]
d[, direction := factor(fifelse(angle >= 337.5 | angle < 22.5, "North",
                        fifelse(angle < 67.5,  "Northeast",
                        fifelse(angle < 112.5, "East",
                        fifelse(angle < 157.5, "Southeast",
                        fifelse(angle < 202.5, "South",
                        fifelse(angle < 247.5, "Southwest",
                        fifelse(angle < 292.5, "West", "Northwest"))))))), levels = DIRLV)]

full <- CJ(order = unique(d$order), direction = factor(DIRLV, levels = DIRLV), unique = TRUE)
oc <- merge(full, d[, .(n_records = .N, n_species = uniqueN(species)), by = .(order, direction)],
            by = c("order", "direction"), all.x = TRUE)
oc[is.na(n_records), `:=`(n_records = 0L, n_species = 0L)]
tot <- d[, .(tot_records = .N, tot_species = uniqueN(species)), by = order][order(-tot_records)]
oc <- merge(oc, tot, by = "order")
oc[, `:=`(prop_records = n_records / tot_records, prop_species = n_species / tot_species)]
setorder(oc, -tot_records, order, direction)

ov <- d[, .(n_records = .N, n_species = uniqueN(species)), by = direction]
ov <- merge(data.table(direction = factor(DIRLV, levels = DIRLV)), ov, by = "direction", all.x = TRUE)
ov[is.na(n_records), `:=`(n_records = 0L, n_species = 0L)]
ov[, `:=`(prop_records = n_records / sum(n_records), prop_species = n_species / sum(n_species))]

ovl <- head(tot$order, 6)                          # 154 §5: 记录最多的六个目 / six largest orders
ovd <- oc[order %in% ovl][, order := factor(order, levels = ovl)]
ymax <- max(ovd$prop_records) * 1.04               # 154 §6: 六个目共用的径向刻度 / shared radial scale
brk  <- pretty(c(0, ymax), n = 4); brk <- brk[brk > 0]
ymax <- max(brk)

# 核对: 重算结果与 154 的持久化表逐值一致 / check: recomputation equals 154's persisted tables
chk <- fread(file.path(OUT, "tables", "tbl_v2_direction_by_order.csv"))[, direction := factor(direction, levels = DIRLV)]
setorder(chk, -tot_records, order, direction)
stopifnot(isTRUE(all.equal(as.data.frame(chk), as.data.frame(oc), check.attributes = FALSE)))
chk <- fread(file.path(OUT, "tables", "tbl_v2_direction_overall.csv"))[match(DIRLV, direction)]
stopifnot(identical(as.integer(chk$n_records), ov$n_records), isTRUE(all.equal(chk$prop_records, ov$prop_records)))
N_REC <- nrow(d); N_SPP <- uniqueN(d$species)
msg("154 数据准备复现一致 / reproduced: ", N_REC, " records, ", N_SPP, " species; orders: ", paste(ovl, collapse = ", "))

# ============================================================
# 2. 零假设 —— 原样复制自 154 第 6b 节, 读取 214 的持久化表(不重跑蒙特卡洛)
#    Nulls copied verbatim from 154 §6b; reads 214's persisted table, no Monte Carlo rerun.
# ============================================================
NULLF <- file.path(OUT, "tables", "tbl_v2_direction_geometric_null.csv")
gn <- fread(NULLF)[scope == "Overall (records)" & null %in% c("geometric", "geometric_effort")]
NLAB <- c(geometric = "Expected: geometry", geometric_effort = "Expected: geometry + effort")
SERIES <- c("Observed", unname(NLAB))              # 与 154 的 names(NCOL) 同序 / same levels as names(NCOL)
shr <- rbind(gn[null == "geometric", .(direction, series = "Observed", share = observed / sum(observed))],
             gn[, .(direction, series = NLAB[null], share = null_mean / sum(null_mean)), by = null][, null := NULL])
shr[, `:=`(direction = factor(direction, levels = DIRLV), series = factor(series, levels = SERIES))]
rt <- gn[, .(null = NLAB[null], direction = factor(direction, levels = DIRLV), ratio,
             lo = null_lo / null_mean, hi = null_hi / null_mean, sig = mc_p_holm < 0.05)]
rt[, null := factor(null, levels = NLAB)]
# 整体检验(仅用于面板内标注)/ omnibus tests, used only for in-panel annotations
gs <- fread(file.path(OUT, "tables", "tbl_v2_direction_geometric_null_summary.csv"))[
  scope == "Overall (records)" & null %in% names(NLAB)][match(names(NLAB), null)]

# 核对: 214 的观测数 = 154 的计数; 比值与显著性 = 214 的 SI 表 / checks against 154 and the SI table
for (nl in names(NLAB)) stopifnot(identical(gn[null == nl][match(DIRLV, direction)]$observed, ov$n_records))
si <- fread(file.path(OUT, "tables", "tbl_v2_direction_null_si_sectors.csv"), encoding = "UTF-8", colClasses = "character")
si[, null := c(Geometry = NLAB[[1]], `Geometry + effort` = NLAB[[2]])[Null]]
si <- merge(rt[, .(null = as.character(null), Sector = as.character(direction), ratio, sig)], si, by = c("null", "Sector"))
stopifnot(nrow(si) == 16, all(sprintf("%.2f", si$ratio) == si$`Obs./exp.`),
          all((as.numeric(sub("<", "", si$`P (Holm)`)) < 0.05) == si$sig))
stopifnot(isTRUE(all.equal(gs$n, rep(N_REC, 2))))
msg("214 零假设表核对通过 / null tables verified (16 sector-null rows, omnibus n = ", gs$n[1], ")")

# ============================================================
# 3. 编码与极坐标工具 / encoding and polar helpers
#    观测 = 墨色实线; 几何期望 = 中性灰虚线; 几何 + 努力期望 = 努力蓝点线(努力进入该零假设)
#    observed = ink solid; geometry = neutral grey dashed; geometry + effort = effort blue dotted
# ============================================================
DIRAB <- setNames(c("N", "NE", "E", "SE", "S", "SW", "W", "NW"), DIRLV)
BEAR  <- setNames(seq(0, 315, by = 45), DIRLV)     # 扇区中心方位角(度)/ sector-centre bearing (deg)
ENC_COL <- setNames(c(TJ$ink, TJ$neutral, TJ$effort), SERIES)
ENC_LTY <- setNames(c("solid", "42", "13"), SERIES)
ENC_LWD <- setNames(c(0.5, 0.45, 0.55), SERIES)
ENC_END <- setNames(c("butt", "butt", "round"), SERIES)    # 圆端点让点线成为圆点 / round caps make dots
BAR_COL <- setNames(c(tint(TJ$neutral, 0.55), tint(TJ$effort, 0.62)), NLAB)   # 零假设区间色 / null bands
OBS_FILL <- tint(TJ$ink, 0.9)
POLAR_GRID <- "#DCDCDC"                            # 浅色极坐标网格 / light polar grid
TXT <- pt2mm(6)                                    # 6 pt 注释字号 / 6 pt annotation size
# 幻灯片模式(TJ_SLIDE=1): 字号 x TS、画幅 x SLIDE_K; 数据坐标中的标注间距按 REL 缩放, 避免重叠。
# 印刷模式下三者均为 1。/ Slide mode: text x TS, canvas x SLIDE_K; in-panel spacing in data
# units scales by REL so labels never collide. All three equal 1 in print mode.
SLIDE_K <- if (isTRUE(get0("TJ_SLIDE", ifnotfound = FALSE))) 1.25 else 1   # 同 tj_panel / as tj_panel
TS  <- get0("TJ_BASE", ifnotfound = 7) / 7
REL <- TS / SLIDE_K

# 半径 + 方位 → 笛卡尔(正北向上、顺时针)/ radius and bearing to x, y (north up, clockwise)
polar_xy <- function(r, b) list(r * sinpi(b / 180), r * cospi(b / 180))
# 每组首点追加到末尾, 使路径闭合 / repeat each group's first vertex to close the path
close_ring <- function(dt, by) dt[, .SD[c(seq_len(.N), 1L)], by = by]
# 标签朝外对齐: 东侧左对齐、北侧底对齐 / anchor labels outward from the centre
out_hj <- function(b) 0.5 - 0.5 * sinpi(b / 180)
out_vj <- function(b) 0.5 - 0.5 * cospi(b / 180)

rose_grid <- function(rings, spoke) {
  b <- seq(0, 360, length.out = 241)
  ring <- rbindlist(lapply(rings, function(r) data.table(r = r, x = r * sinpi(b / 180), y = r * cospi(b / 180))))
  spk  <- data.table(x = spoke * sinpi(BEAR / 180), y = spoke * cospi(BEAR / 180))
  list(geom_path(data = ring, aes(x, y, group = r), colour = POLAR_GRID, linewidth = 0.2),
       geom_segment(data = spk, aes(x = 0, y = 0, xend = x, yend = y), colour = POLAR_GRID, linewidth = 0.2))
}
compass_lab <- function(r, dirs = DIRLV) {
  b <- BEAR[dirs]
  data.table(lab = DIRAB[dirs], x = r * sinpi(b / 180), y = r * cospi(b / 180), hj = out_hj(b), vj = out_vj(b))
}
ring_lab <- function(rings, b, pad) {
  data.table(lab = percent(rings, accuracy = 1), x = (rings + pad) * sinpi(b / 180),
             y = (rings + pad) * cospi(b / 180), hj = out_hj(b), vj = out_vj(b))
}
label_layer <- function(dt, colour = TJ$subink)
  geom_text(data = dt, aes(x, y, label = lab, hjust = hj, vjust = vj), size = TXT, colour = colour)

# ============================================================
# 4. 面板 a: 总体方位份额 —— 观测与两个零假设期望 / panel a: observed vs expected shares
# ============================================================
RA_RINGS <- seq(0.1, floor(max(shr$share) * 10) / 10, by = 0.1)   # 10–40% 环 / rings
RA_SPOKE <- max(shr$share) * 1.07                                 # 辐条略长于最大份额 / spokes
XA <- c(-0.50, 0.50); YA <- c(-0.50, 0.47 + 0.16 * REL)           # 面板窗口(顶部留给图例)/ window, legend on top
pa_dat <- copy(shr)[order(series, direction)]
pa_dat[, c("x", "y") := polar_xy(share, BEAR[as.character(direction)])]
pa_path <- close_ring(pa_dat, "series")

# 图例(左上, 线型即编码)/ legend, top left: line glyphs carry the encoding
leg_a <- data.table(s = SERIES, lab = c(sprintf("Observed (%d records, %d spp.)", N_REC, N_SPP), NLAB[[1]], NLAB[[2]]))
leg_a[, y := YA[2] - (0.022 + (seq_len(.N) - 1) * 0.046) * REL]
leg_a_layers <- unlist(lapply(seq_len(nrow(leg_a)), function(i) { s <- leg_a$s[i]; list(
  annotate("segment", x = XA[1], xend = XA[1] + 0.10, y = leg_a$y[i], yend = leg_a$y[i], colour = ENC_COL[[s]],
           linetype = ENC_LTY[[s]], linewidth = ENC_LWD[[s]], lineend = ENC_END[[s]]),
  annotate("text", x = XA[1] + 0.125, y = leg_a$y[i], label = leg_a$lab[i], hjust = 0, size = TXT, colour = TJ$ink)) }),
  recursive = FALSE)
# 关键数字: 东侧三扇区份额, 观测 vs 几何期望(214 整体表)/ key number: NE–SE share, observed vs geometry
east_lab <- sprintf("NE\u2013SE share\nObserved %.1f%%\nGeometry %.1f%%", 100 * gs$obs_east3[1], 100 * gs$null_east3[1])

pa <- ggplot() +
  rose_grid(RA_RINGS, RA_SPOKE) +
  geom_polygon(data = pa_dat[series == "Observed"], aes(x, y), fill = OBS_FILL, colour = NA) +
  lapply(rev(SERIES), function(s)                  # 观测线最后画, 位于最上层 / observed drawn on top
    geom_path(data = pa_path[series == s], aes(x, y), colour = ENC_COL[[s]], linetype = ENC_LTY[[s]],
              linewidth = ENC_LWD[[s]], lineend = ENC_END[[s]], linejoin = "round")) +
  label_layer(compass_lab(RA_SPOKE + 0.016)) +
  label_layer(ring_lab(RA_RINGS, 337.5, 0.004)) +
  leg_a_layers +
  annotate("text", x = XA[2], y = YA[1], label = east_lab, hjust = 1, vjust = 0, size = TXT,
           colour = TJ$subink, lineheight = 0.95) +
  coord_fixed(xlim = XA, ylim = YA, expand = FALSE, clip = "off") +
  labs(title = "Geometry alone reproduces the eastward skew", x = NULL, y = NULL) +
  theme_tj_map()

# ============================================================
# 5. 面板 b: 各方位 观测/期望 比 与 零假设 95% 蒙特卡洛区间 / panel b: ratios and null intervals
# ============================================================
DODGE <- setNames(c(-0.16, 0.16), NLAB); BAR_W <- 0.2
pb_dat <- copy(rt)[, `:=`(xpos = as.integer(direction) + DODGE[as.character(null)],
                          col = unname(ENC_COL[as.character(null)]), bar = unname(BAR_COL[as.character(null)]))]
pb_dat[, pt_fill := fifelse(sig, col, "white")]   # 实心 = Holm P < 0.05 / filled = significant

# 图例块(左上): 零假设 + 整体检验数字 + 显著性小键 / legend block: nulls, omnibus numbers, significance key
LY <- 2^(0.915 - (0:2) * 0.11 * REL); LX <- 0.72; GH <- 0.042 * REL   # 行位置(log2 刻度)/ row positions
omni <- sprintf('paste("%s:  χ² = %.1f,  ", italic(P), " = %.3f")', sub("Expected: g", "G", NLAB), gs$chisq_vs_null, gs$mc_p)
leg_b_layers <- c(
  unlist(lapply(1:2, function(i) list(
    annotate("rect", xmin = LX - BAR_W / 2, xmax = LX + BAR_W / 2, ymin = LY[i] * 2^-GH, ymax = LY[i] * 2^GH,
             fill = BAR_COL[[i]]),
    annotate("point", x = LX, y = LY[i], shape = 21, size = 1.7, stroke = 0.5, colour = ENC_COL[[NLAB[i]]], fill = "white"),
    annotate("text", x = LX + 0.22, y = LY[i], label = omni[i], parse = TRUE, hjust = 0, size = TXT, colour = TJ$ink))),
    recursive = FALSE),
  list(annotate("point", x = c(LX, LX + 2.55 * REL), y = LY[3], shape = 21, size = 1.7, stroke = 0.5,
                colour = TJ$subink, fill = c(TJ$subink, "white")),
       annotate("text", x = c(LX + 0.22, LX + 0.22 + 2.55 * REL), y = LY[3], hjust = 0, size = TXT, colour = TJ$ink, parse = TRUE,
                label = c('paste("Holm-adjusted ", italic(P), " < 0.05")', 'paste(italic(P), " ≥ 0.05")'))))

# 关键数字: 北侧三扇区份额, 观测 vs 几何 + 努力期望(214 整体表)/ key number: NW–NE share vs geometry + effort
north_lab <- sprintf("NW\u2013NE share\nObserved %.1f%%\nGeometry + effort %.1f%%",
                     100 * gs$obs_north3[2], 100 * gs$null_north3[2])

pb <- ggplot(pb_dat) +
  geom_hline(yintercept = 1, colour = TJ$subink, linewidth = 0.25) +
  geom_rect(aes(xmin = xpos - BAR_W / 2, xmax = xpos + BAR_W / 2, ymin = lo, ymax = hi, fill = I(bar))) +
  geom_point(aes(xpos, ratio, colour = I(col), fill = I(pt_fill)), shape = 21, size = 1.7, stroke = 0.5) +
  leg_b_layers +
  annotate("text", x = 0.62, y = 0.515, label = north_lab, hjust = 0, vjust = 0, size = TXT,
           colour = TJ$subink, lineheight = 0.95) +
  scale_x_continuous(breaks = 1:8, labels = unname(DIRAB), limits = c(0.5, 8.5), expand = c(0, 0)) +
  scale_y_continuous(transform = "log2", breaks = c(0.5, 0.75, 1, 1.5, 2), labels = c("0.5", "0.75", "1", "1.5", "2"),
                     limits = c(0.5, 2), expand = expansion(mult = 0.01)) +
  labs(title = "Beyond geometry and effort, records lean north", x = NULL, y = "Observed / expected records") +
  theme_tj()

# ============================================================
# 6. 面板 c: 六个目的小多图, 同一径向刻度 / panel c: small multiples on one radial scale
# ============================================================
RC_RINGS <- brk; RC <- ymax                         # 20/40/60%, 与 154 相同 / same rings as 154
lab_c <- tot[match(ovl, order), .(order, lab = sprintf(
  "**%s**<br><span style='font-size:%.1fpt; color:%s'>%d records, %d spp.</span>", order, 6 * TS, TJ$subink,
  tot_records, tot_species))]
cd <- copy(ovd)[order(order, direction)]
cd[, lab := factor(lab_c$lab[match(as.character(order), lab_c$order)], levels = lab_c$lab)]
cd[, c("x", "y") := polar_xy(prop_records, BEAR[as.character(direction)])]
LC <- RC + 0.03 + 0.115 * REL                       # 小多图窗口半宽(含方位标签)/ facet half-width incl. labels

build_c <- function(nrow = 1) {
  rl <- ring_lab(RC_RINGS, 337.5, 0.008)[, lab_f := factor(lab_c$lab[1], levels = lab_c$lab)]
  ggplot() +
    rose_grid(RC_RINGS, RC) +
    geom_polygon(data = cd, aes(x, y, group = lab), fill = OBS_FILL, colour = NA) +
    geom_path(data = close_ring(cd, "lab"), aes(x, y, group = lab), colour = ENC_COL[["Observed"]],
              linewidth = 0.45, linejoin = "round") +
    label_layer(compass_lab(RC + 0.03, c("North", "East", "South", "West"))) +
    geom_text(data = rl, aes(x, y, label = lab, hjust = hj, vjust = vj), size = TXT, colour = TJ$subink) +
    facet_wrap(vars(lab_f), nrow = nrow) +
    coord_fixed(xlim = c(-LC, LC), ylim = c(-LC, LC), expand = FALSE, clip = "off") +
    labs(title = "Raw bearings by order point east to north-east", x = NULL, y = NULL) +
    theme_tj_map() +
    theme(strip.text = element_markdown(size = 6.5 * TS, face = "plain", hjust = 0.5, lineheight = 1.15,
                                        family = "Arial", margin = margin(b = 1)),
          panel.spacing = unit(4, "pt"))
}
cd[, lab_f := lab]                                  # 分面变量 / facet variable

# ============================================================
# 7. 拼版与导出 / assemble and export
# ============================================================
H_TOP <- 80; H_C <- 37
fig <- wrap_plots(A = pa, B = pb, C = build_c(1), design = "AABBB\nCCCCC", heights = c(H_TOP, H_C)) + tj_tags()
# 印刷 183 mm; 幻灯片模式下整图画幅随字号同比放大(TS), 版式与印刷版一致, 不致拥挤
# Print: 183 mm. Slide mode scales the whole canvas by TS so the composite keeps the print layout.
tj_save(fig, FIG, 183 * TS, (H_TOP + H_C) * TS)
tj_panel(pa, paste0(FIG, "_a"), 100, 105)
tj_panel(pb, paste0(FIG, "_b"), 120, 85)
tj_panel(build_c(2), paste0(FIG, "_c"), 120, 100)

# ============================================================
# 8. 长格式源数据: 每个作图数值一行 / long-format source data, one row per plotted value
# ============================================================
cnt <- rbind(gn[null == "geometric", .(series = "Observed", direction, count = observed)],
             gn[, .(series = NLAB[null], direction, count = null_mean)])
src_a <- merge(shr[, .(series = as.character(series), direction = as.character(direction), value = share)],
               cnt, by = c("series", "direction"))[, `:=`(panel = "a", group = "All orders", measure = "share_of_records")]
src_b <- gn[, .(panel = "b", group = "All orders", series = NLAB[null], direction, measure = "observed_to_expected_ratio",
                value = ratio, lower = null_lo / null_mean, upper = null_hi / null_mean, count = observed,
                expected = null_mean, p_value = mc_p, p_holm = mc_p_holm, significant = mc_p_holm < 0.05)]
src_c <- ovd[, .(panel = "c", group = as.character(order), series = "Observed", direction = as.character(direction),
                 measure = "share_of_order_records", value = prop_records, count = n_records,
                 n_records = tot_records, n_species = tot_species)]
src_ann <- rbind(  # 面板内标注数字 / numbers printed inside panels
  gs[, .(panel = "b", group = "All orders", series = NLAB[null], direction = "All", measure = "chisq_vs_null",
         value = chisq_vs_null, p_value = mc_p)],
  data.table(panel = "a", group = "All orders", series = c("Observed", NLAB[[1]]), direction = "NE+E+SE",
             measure = "share_NE_E_SE", value = c(gs$obs_east3[1], gs$null_east3[1]), p_value = NA_real_),
  data.table(panel = "b", group = "All orders", series = c("Observed", NLAB[[2]]), direction = "NW+N+NE",
             measure = "share_NW_N_NE", value = c(gs$obs_north3[2], gs$null_north3[2]), p_value = NA_real_))
src <- rbindlist(list(src_a, src_b, src_c, src_ann), fill = TRUE)
src[panel != "c" & is.na(n_records), `:=`(n_records = N_REC, n_species = N_SPP)]
src[, direction_abbrev := fifelse(direction %in% DIRLV, DIRAB[direction], direction)]
src[, source := fifelse(panel == "c", "154 recomputation (= tbl_v2_direction_by_order.csv)",
                        "214: tbl_v2_direction_geometric_null(_summary).csv")]
setcolorder(src, c("panel", "group", "series", "direction", "direction_abbrev", "measure", "value", "lower", "upper",
                   "count", "expected", "p_value", "p_holm", "significant", "n_records", "n_species", "source"))
src[, `:=`(o1 = match(panel, c("a", "b", "c")), o2 = match(direction, DIRLV))]
setorder(src, o1, group, series, o2, na.last = TRUE)[, c("o1", "o2") := NULL]
tj_source(src, FIG)

# ============================================================
# 9. 核对打印 / verification printout
# ============================================================
msg("面板 a 份额(%) / panel a shares (%):")
print(dcast(shr[, .(series, direction = DIRAB[as.character(direction)], pct = round(100 * share, 1))],
            series ~ direction, value.var = "pct")[, c("series", DIRAB), with = FALSE])
msg("面板 b 比值 [95% 区间] (* = Holm P < 0.05) / panel b ratios:")
print(dcast(rt[, .(null, direction = DIRAB[as.character(direction)],
                   v = sprintf("%.2f%s [%.2f-%.2f]", ratio, fifelse(sig, "*", ""), lo, hi))],
            null ~ direction, value.var = "v")[, c("null", DIRAB), with = FALSE])
msg("面板 c 份额(%) / panel c shares (%):")
print(dcast(ovd[, .(order, direction = DIRAB[as.character(direction)], pct = round(100 * prop_records, 1))],
            order ~ direction, value.var = "pct")[, c("order", DIRAB), with = FALSE])
msg("标注 / annotations: ", paste(sprintf("%s chi2 = %.1f, P = %.3f", NLAB, gs$chisq_vs_null, gs$mc_p), collapse = " | "),
    sprintf(" | NE+E+SE %.1f%% vs %.1f%% | NW+N+NE %.1f%% vs %.1f%%", 100 * gs$obs_east3[1], 100 * gs$null_east3[1],
            100 * gs$obs_north3[2], 100 * gs$null_north3[2]))
msg("源数据行数 / source rows: ", nrow(src), " | DONE")
