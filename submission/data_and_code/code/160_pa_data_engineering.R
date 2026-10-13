# ============================================================
# Scientific question / 科学问题:
# 中国自然保护地网络与"新分布记录生成风险"在空间与时间上如何叠合?
# 保护地内外的新纪录发生率差异,有多少来自栖息地本身,有多少只是
# 因为保护区里观鸟的人更多?
# How does China's nature-reserve network overlap the hazard of
# generating a new provincial bird record, and how much of any
# inside-vs-outside difference is survey effort rather than habitat?
#
# Objective / 分析目标:
# 一次性构建所有保护地关联分析共用的空间底层数据:
#   (1) 保护地图层清洗与时变化(按建区年份)
#   (2) 50 km 网格 × 保护地覆盖度(总体/国家级/地方级;逐年累积)
#   (3) 657 条发现年定年事件点的保护地归属与最近保护地距离
#   (4) 省 × 年保护地覆盖度(供省级模型使用)
#   (5) 网格尺度的保护地连通性指标(最近邻距离、邻域斑块数、八方位密度)
# Build, once, the shared spatial layer that every protected-area
# module downstream consumes.
#
# Input data / 输入数据:
#   china_nature_reserves_utf8.gpkg  1028 个自然保护区(WGS84,含级别/类型/建区年)
#   grid_50km_base.csv               3795 个 50 km 网格中心(WGS84)
#   events_discovery_dated.csv       657 条发现年定年事件(含经纬度)
#   省面.shp                          省级行政边界(审图号 GS(2023)2767)
#
# Main workflow / 主要流程:
#   1. 读取并清洗保护地 / load and clean reserves
#   2. 反算 50 km 网格多边形 / rebuild grid polygons
#   3. 逐年累积并集与网格覆盖度 / cumulative union and cell coverage
#   4. 事件点叠加 / event-point overlay
#   5. 省级覆盖度 / province-level coverage
#   6. 连通性指标 / connectivity metrics
#
# Expected output / 预期输出:
#   analysis_v2/data/pa/pa_clean.gpkg
#   analysis_v2/data/pa/pa_grid50_coverage_year.csv
#   analysis_v2/data/pa/pa_events_overlay.csv
#   analysis_v2/data/pa/pa_province_coverage_year.csv
#   analysis_v2/data/pa/pa_grid50_connectivity.csv
#   analysis_v2/tables/tbl_pa_inventory.csv
#
# Key assumptions / 关键假设:
#   - 网格定义为 Albers 等积投影(lat_1=25, lat_2=47, lat_0=0, lon_0=105,
#     WGS84)下的 50 km 规则格;已用 3795 个中心点的模 50000 余数验证,
#     x 与 y 方向均 100% 对齐。
#   - 建区年份取 `years` 字段前 4 位;无法解析者按 2002 年前已存在处理,
#     因为该名录中位建区年为 1994,且 2002 年后新建仅 185 个。
#   - 保护地之间可能重叠,因此覆盖面积一律用**并集**计算,不做面积相加。
#   - 该名录只含自然保护区,不含国家公园(2021 起)、自然公园与生态保护红线,
#     且建区年份截止 2012。所有下游解释必须限定在"自然保护区"这一口径内。
#
# Main packages / 主要包: sf, data.table, units
# Output directory / 输出路径: analysis_v2/data/pa/
# ============================================================

suppressPackageStartupMessages({
  library(sf); library(data.table); library(units)
})

V2  <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
PA_GPKG <- "/Users/dingchenchen/Documents/New project/china-bird-community-dynamics/data/protected_areas/china_nature_reserves_utf8.gpkg"
PROV_SHP <- "/Users/dingchenchen/Documents/SDMs/GS(2023)2767审图号/省面.shp"

OUT_D <- file.path(V2, "analysis_v2/data/pa")
OUT_T <- file.path(V2, "analysis_v2/tables")
dir.create(OUT_D, recursive = TRUE, showWarnings = FALSE)
dir.create(OUT_T, recursive = TRUE, showWarnings = FALSE)

# 网格与面积计算统一使用的等积投影 / equal-area CRS used throughout
AEA <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
CELL_M <- 50000
YEARS <- 2002:2024

msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

sf_use_s2(FALSE)   # 平面运算,避免球面拓扑在等积投影下的多余开销

# ------------------------------------------------------------
# 1. 保护地图层清洗 / clean the reserve layer
# ------------------------------------------------------------
msg("读取保护地图层 / reading reserves")
pa <- st_read(PA_GPKG, quiet = TRUE)
pa <- st_zm(pa, drop = TRUE, what = "ZM")          # 去掉 Z 维 / drop Z
pa <- st_transform(pa, AEA)
pa <- st_make_valid(pa)
pa <- pa[!st_is_empty(pa), ]

pa_dt <- as.data.table(st_drop_geometry(pa))
# 建区年份 / establishment year
yr_raw <- as.character(pa_dt$years)
est_year <- suppressWarnings(as.integer(substr(yr_raw, 1, 4)))
est_year[!is.finite(est_year) | est_year < 1900 | est_year > 2025] <- NA_integer_
pa$est_year <- est_year

# 级别归并 / collapse level
lv <- as.character(pa_dt$level)
pa$pa_level <- fifelse(lv == "国家级", "national",
                fifelse(lv %in% c("省级"), "provincial",
                fifelse(lv %in% c("县市级", "市级", "县级"), "local", "unknown")))

pa$pa_type <- as.character(pa_dt$type)
pa$pa_name <- as.character(pa_dt$name)
pa$pa_prov <- as.character(pa_dt$province)
pa$area_km2_geom <- as.numeric(set_units(st_area(pa), km^2))

st_write(pa[, c("pa_name", "pa_prov", "pa_level", "pa_type", "est_year", "area_km2_geom")],
         file.path(OUT_D, "pa_clean.gpkg"), layer = "pa_clean",
         delete_dsn = TRUE, quiet = TRUE)

inv <- as.data.table(st_drop_geometry(pa))[, .(
  n = .N,
  area_km2 = round(sum(area_km2_geom), 1),
  est_year_min = min(est_year, na.rm = TRUE),
  est_year_med = as.integer(median(est_year, na.rm = TRUE)),
  est_year_max = max(est_year, na.rm = TRUE),
  n_missing_year = sum(is.na(est_year)),
  n_since_2002 = sum(est_year >= 2002, na.rm = TRUE)
), by = pa_level]
fwrite(inv, file.path(OUT_T, "tbl_pa_inventory.csv"))
msg("保护地清单 / inventory:"); print(inv)

# 重叠程度诊断 / how much do reserves overlap
u_all <- st_union(st_geometry(pa))
area_sum   <- sum(pa$area_km2_geom)
area_union <- as.numeric(set_units(st_area(u_all), km^2))
msg(sprintf("面积相加 %.0f km2 vs 并集 %.0f km2,重叠占 %.2f%%",
            area_sum, area_union, 100 * (1 - area_union / area_sum)))

# ------------------------------------------------------------
# 2. 反算 50 km 网格多边形 / rebuild the 50 km grid polygons
# ------------------------------------------------------------
msg("重建 50 km 网格 / rebuilding grid")
gb <- fread(file.path(V2, "data/raw/grid_50km_base.csv"))
gxy <- sf_project("EPSG:4326", AEA, as.matrix(gb[, .(centroid_lon, centroid_lat)]))
gb[, `:=`(ax = gxy[, 1], ay = gxy[, 2])]

# 校验格心对齐 / verify lattice alignment
off_x <- unique(round(gb$ax %% CELL_M)); off_y <- unique(round(gb$ay %% CELL_M))
stopifnot(length(off_x) == 1L, length(off_y) == 1L)
msg(sprintf("格心对齐校验通过:x 余数 %d,y 余数 %d", off_x, off_y))

mk_cell <- function(cx, cy) {
  h <- CELL_M / 2
  st_polygon(list(cbind(
    c(cx - h, cx + h, cx + h, cx - h, cx - h),
    c(cy - h, cy - h, cy + h, cy + h, cy - h))))
}
grid <- st_sf(
  grid_id  = gb$grid_id,
  province = gb$province,
  cen_lon  = gb$centroid_lon,
  cen_lat  = gb$centroid_lat,
  geometry = st_sfc(Map(mk_cell, gb$ax, gb$ay), crs = AEA)
)
grid$cell_km2 <- as.numeric(set_units(st_area(grid), km^2))
msg(sprintf("网格 %d 格,单格面积 %.1f km2", nrow(grid), grid$cell_km2[1]))

# ------------------------------------------------------------
# 3. 逐年累积保护地并集 × 网格覆盖度 / time-varying cell coverage
# ------------------------------------------------------------
# 覆盖面积一律用并集,避免重叠保护区重复计面积。
# Coverage always uses the union so overlapping reserves are not double counted.
cov_of <- function(sub_geom, tag) {
  if (length(sub_geom) == 0L) {
    return(data.table(grid_id = grid$grid_id, v = 0, metric = tag))
  }
  u <- st_union(sub_geom)
  ix <- st_intersects(grid, u)
  hit <- which(lengths(ix) > 0L)
  out <- data.table(grid_id = grid$grid_id, v = 0, metric = tag)
  if (length(hit)) {
    inter <- st_intersection(st_geometry(grid)[hit], u)
    a <- as.numeric(set_units(st_area(inter), km^2))
    out[hit, v := a]
  }
  out
}

msg("计算静态覆盖度(总体 / 国家级 / 地方级)")
cov_static <- rbindlist(list(
  cov_of(st_geometry(pa),                                        "pa_all"),
  cov_of(st_geometry(pa)[pa$pa_level == "national"],             "pa_national"),
  cov_of(st_geometry(pa)[pa$pa_level %in% c("provincial", "local")], "pa_subnational")
))
cov_static_w <- dcast(cov_static, grid_id ~ metric, value.var = "v")
cov_static_w <- merge(cov_static_w, as.data.table(st_drop_geometry(grid)), by = "grid_id")
cov_static_w[, `:=`(
  frac_pa_all         = pa_all / cell_km2,
  frac_pa_national    = pa_national / cell_km2,
  frac_pa_subnational = pa_subnational / cell_km2
)]
fwrite(cov_static_w, file.path(OUT_D, "pa_grid50_coverage_static.csv"))
msg(sprintf("有任何保护区的格:%d / %d (%.1f%%);格内覆盖度中位数(仅有覆盖的格)%.3f",
            sum(cov_static_w$frac_pa_all > 0), nrow(cov_static_w),
            100 * mean(cov_static_w$frac_pa_all > 0),
            median(cov_static_w$frac_pa_all[cov_static_w$frac_pa_all > 0])))

msg("计算逐年累积覆盖度 / cumulative coverage by year")
# 年份缺失者按 2002 年前已存在处理 / missing year treated as pre-window
pa$est_year_fill <- fifelse(is.na(pa$est_year), 1900L, pa$est_year)
cov_year <- vector("list", length(YEARS))
for (i in seq_along(YEARS)) {
  y <- YEARS[i]
  sel <- pa$est_year_fill <= y
  cy  <- cov_of(st_geometry(pa)[sel], "pa_all")[, .(grid_id, pa_all_km2 = v)]
  cn  <- cov_of(st_geometry(pa)[sel & pa$pa_level == "national"], "pa_nat")[, .(grid_id, pa_nat_km2 = v)]
  d   <- merge(cy, cn, by = "grid_id")
  d[, year := y]
  cov_year[[i]] <- d
  msg(sprintf("  %d: 累积保护区 %d 个", y, sum(sel)))
}
cov_year <- rbindlist(cov_year)
cov_year <- merge(cov_year, as.data.table(st_drop_geometry(grid))[, .(grid_id, province, cell_km2)], by = "grid_id")
cov_year[, `:=`(frac_pa = pa_all_km2 / cell_km2, frac_pa_nat = pa_nat_km2 / cell_km2)]
fwrite(cov_year, file.path(OUT_D, "pa_grid50_coverage_year.csv"))
msg(sprintf("逐年覆盖度表 %d 行", nrow(cov_year)))

# ------------------------------------------------------------
# 4. 事件点叠加 / event-point overlay
# ------------------------------------------------------------
msg("事件点与保护地叠加 / overlaying event points")
ev <- fread(file.path(V2, "analysis_v2/data/events_discovery_dated.csv"), encoding = "UTF-8")
ev_sf <- st_transform(
  st_as_sf(ev, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE), AEA)

# 事件发生当年已存在的保护区 / reserves existing in the event year
in_pa <- rep(FALSE, nrow(ev_sf)); in_pa_nat <- rep(FALSE, nrow(ev_sf))
for (y in sort(unique(ev_sf$year))) {
  idx <- which(ev_sf$year == y)
  sel <- pa$est_year_fill <= y
  if (!any(sel)) next
  h  <- st_intersects(ev_sf[idx, ], st_union(st_geometry(pa)[sel]))
  in_pa[idx] <- lengths(h) > 0L
  seln <- sel & pa$pa_level == "national"
  if (any(seln)) {
    hn <- st_intersects(ev_sf[idx, ], st_union(st_geometry(pa)[seln]))
    in_pa_nat[idx] <- lengths(hn) > 0L
  }
}
ev_sf$in_pa <- in_pa
ev_sf$in_pa_national <- in_pa_nat

# 最近保护区(不分年份,用于距离梯度)/ nearest reserve, any year
nf <- st_nearest_feature(ev_sf, pa)
ev_sf$nearest_pa_name  <- pa$pa_name[nf]
ev_sf$nearest_pa_level <- pa$pa_level[nf]
ev_sf$nearest_pa_type  <- pa$pa_type[nf]
ev_sf$nearest_pa_year  <- pa$est_year[nf]
ev_sf$dist_to_pa_km <- as.numeric(set_units(
  st_distance(ev_sf, pa[nf, ], by_element = TRUE), km))

# 事件点所在 50 km 网格 / assign events to grid cells
gj <- st_join(ev_sf["species"], grid["grid_id"], join = st_intersects)
ev_sf$grid_id <- gj$grid_id

ev_out <- as.data.table(st_drop_geometry(ev_sf))
fwrite(ev_out, file.path(OUT_D, "pa_events_overlay.csv"))
msg(sprintf("事件点:%d 条,落在保护区内 %d 条 (%.1f%%),其中国家级 %d 条 (%.1f%%)",
            nrow(ev_out), sum(ev_out$in_pa), 100 * mean(ev_out$in_pa),
            sum(ev_out$in_pa_national), 100 * mean(ev_out$in_pa_national)))
msg(sprintf("到最近保护区距离:中位 %.1f km,四分位 %.1f - %.1f km",
            median(ev_out$dist_to_pa_km), quantile(ev_out$dist_to_pa_km, .25),
            quantile(ev_out$dist_to_pa_km, .75)))

# ------------------------------------------------------------
# 5. 省 × 年保护地覆盖度 / province-level coverage by year
# ------------------------------------------------------------
msg("省级覆盖度 / province coverage")
prov <- st_make_valid(st_transform(st_read(PROV_SHP, quiet = TRUE), AEA))
# 省名字段自动识别 / auto-detect the province-name field
pn_field <- names(prov)[which(sapply(prov, function(z)
  is.character(z) || is.factor(z)))[1]]
prov$prov_cn <- as.character(prov[[pn_field]])
prov$prov_km2 <- as.numeric(set_units(st_area(prov), km^2))

prov_cov <- vector("list", length(YEARS))
for (i in seq_along(YEARS)) {
  y <- YEARS[i]
  sel <- pa$est_year_fill <= y
  u <- st_union(st_geometry(pa)[sel])
  ix <- st_intersects(prov, u)
  a <- rep(0, nrow(prov))
  hit <- which(lengths(ix) > 0L)
  if (length(hit)) {
    inter <- st_intersection(st_geometry(prov)[hit], u)
    a[hit] <- as.numeric(set_units(st_area(inter), km^2))
  }
  prov_cov[[i]] <- data.table(prov_cn = prov$prov_cn, prov_km2 = prov$prov_km2,
                              pa_km2 = a, year = y)
}
prov_cov <- rbindlist(prov_cov)
prov_cov[, frac_pa := pa_km2 / prov_km2]
fwrite(prov_cov, file.path(OUT_D, "pa_province_coverage_year.csv"))
msg(sprintf("省级覆盖度表 %d 行,2024 年全国均值 %.3f",
            nrow(prov_cov), mean(prov_cov[year == 2024]$frac_pa)))

# ------------------------------------------------------------
# 6. 网格尺度连通性指标 / grid-level connectivity metrics
# ------------------------------------------------------------
# 目的:刻画保护地网络在空间上有多连通,以及沿新纪录偏好方向(东、东北)
# 是否存在"踏脚石"。指标全部基于保护地质心与网格中心的几何关系。
# Purpose: describe how connected the reserve network is, and whether
# stepping stones exist along the direction new records prefer.
msg("连通性指标 / connectivity metrics")
pa_cent <- st_centroid(st_geometry(pa))
pc <- st_coordinates(pa_cent)
pa_dt2 <- data.table(px = pc[, 1], py = pc[, 2],
                     pkm2 = pa$area_km2_geom, plev = pa$pa_level,
                     pyear = pa$est_year_fill)

gc_xy <- st_coordinates(st_centroid(st_geometry(grid)))
gd <- data.table(grid_id = grid$grid_id, gx = gc_xy[, 1], gy = gc_xy[, 2])

RADII <- c(50, 100, 200) * 1000
SECTORS <- c("N", "NE", "E", "SE", "S", "SW", "W", "NW")

conn <- vector("list", nrow(gd))
for (i in seq_len(nrow(gd))) {
  dx <- pa_dt2$px - gd$gx[i]; dy <- pa_dt2$py - gd$gy[i]
  dd <- sqrt(dx^2 + dy^2)
  row <- list(grid_id = gd$grid_id[i], nn_pa_km = min(dd) / 1000)
  for (r in RADII) {
    k <- dd <= r
    row[[sprintf("n_pa_%dkm", r / 1000)]]   <- sum(k)
    row[[sprintf("pa_km2_%dkm", r / 1000)]] <- sum(pa_dt2$pkm2[k])
  }
  # 200 km 邻域内的八方位保护地面积 / directional reserve area within 200 km
  k <- dd <= 200000 & dd > 0
  if (any(k)) {
    br <- (atan2(dx[k], dy[k]) * 180 / pi) %% 360           # 以正北为 0 度顺时针
    sec <- SECTORS[floor(((br + 22.5) %% 360) / 45) + 1]
    ag <- tapply(pa_dt2$pkm2[k], factor(sec, levels = SECTORS), sum)
    ag[is.na(ag)] <- 0
  } else {
    ag <- setNames(rep(0, 8), SECTORS)
  }
  for (s in SECTORS) row[[paste0("pa_km2_200km_", s)]] <- as.numeric(ag[[s]])
  conn[[i]] <- as.data.table(row)
  if (i %% 500 == 0) msg(sprintf("  连通性 %d / %d", i, nrow(gd)))
}
conn <- rbindlist(conn)
conn <- merge(conn, as.data.table(st_drop_geometry(grid))[, .(grid_id, province, cen_lon, cen_lat)],
              by = "grid_id")
fwrite(conn, file.path(OUT_D, "pa_grid50_connectivity.csv"))
msg(sprintf("连通性表 %d 行;到最近保护区距离中位 %.1f km",
            nrow(conn), median(conn$nn_pa_km)))

msg("完成 / done. 输出目录: ", OUT_D)
