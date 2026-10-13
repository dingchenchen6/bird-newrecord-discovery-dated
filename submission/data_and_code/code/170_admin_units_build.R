# ============================================================
# Scientific question / 科学问题:
# 省级新纪录的预测能否降尺度到市、县?响应变量「某物种在某省首次被记录」
# 是行政绑定的,不能直接换尺度;但可以拆成两段:
#   第一段(已冻结的省级风险模型):该省该年是否发生新纪录
#   第二段(本脚本要支持的分配模型):既然发生了,落在省内哪个县
# The response is administratively tied to the province and cannot simply be
# rescaled. It decomposes into a province-level hazard (already frozen) and a
# within-province allocation over counties, which is what this script prepares.
#
# Objective / 分析目标:
# 构建市/县两级的备择集数据:每个事件 × 该省全部县(或市),
# 附上全部在省内有变异的协变量。
#
# Input data / 输入数据:
#   basemap_GS2019_1822/县（等积投影）.shp   2901 个县级单元(含 PAC、省、市)
#   basemap_GS2019_1822/市（等积投影）.shp   371 个市级单元
#   analysis_v2/data/pa/cc_events_enriched.csv     657 条发现年定年事件(含坐标)
#   gbif_ebird_events_2000_2025.rds                真实的细尺度观鸟努力
#   BOTW_clean.gpkg                                466 个物种的 BirdLife 分布区
#   analysis_v2/data/pa/c3_grid_panel.csv          50 km 格级环境(含 CRU 实测增温)
#   analysis_v2/data/pa/pa_clean.gpkg              保护区并集
#
# Main workflow / 主要流程:
#   1. 行政单元与面积 / units and areas
#   2. 事件配单元 / assign events
#   3. 单元 × 年观鸟努力(真实,非省级分摊)/ genuine unit-level effort
#   4. 单元环境:由 50 km 格面积加权聚合 / area-weighted environment
#   5. 单元保护地覆盖 / reserve coverage
#   6. 物种 × 单元 到分布区边缘的距离 / distance to the species' known range
#   7. 输出备择集 / alternative-set table
#
# Expected output / 预期输出:
#   analysis_v2/data/admin/units_county.csv, units_prefecture.csv
#   analysis_v2/data/admin/effort_unit_year_{county,prefecture}.csv
#   analysis_v2/data/admin/dist_species_unit_{county,prefecture}.csv
#   analysis_v2/data/admin/altset_{county,prefecture}.parquet
#
# Key assumptions / 关键假设:
#   - 备择集 = 事件所在省的全部县(市)。跨省分配不在本模型范围内,
#     因为第一段已经决定了省。
#   - 观鸟努力用 GBIF/eBird checklist 计数,不使用 data/derived 下
#     由省级值分摊得到的 n_visits(已核实其省内唯一值恒为 1)。
#   - 分布区距离用 BirdLife 多边形到单元质心的最短距离,单元质心落在
#     分布区内时距离记为 0。分布区为当代分布,不随年份变化。
#   - 县级单元使用审图号底图的 2901 个单元,行政区划以该底图年份为准,
#     不追溯历史区划调整。
#
# Main packages / 主要包: sf, data.table, arrow, units
# Output directory / 输出路径: analysis_v2/data/admin/
# ============================================================

suppressPackageStartupMessages({
  library(sf); library(data.table); library(units); library(arrow)
})
sf_use_s2(FALSE)
set.seed(20260803)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
OBS  <- "/Users/dingchenchen/Documents/New project/bird_dynamic_occupancy_analysis/data/derived/gbif_ebird_events_2000_2025.rds"
BOTW <- "/Users/dingchenchen/Documents/NEW DISTRIBUTION RECORDS/BOTW_clean.gpkg"
BM   <- file.path(V2, "data/spatial/basemap_GS2019_1822")
D_PA <- file.path(V2, "analysis_v2/data/pa")
D_AD <- file.path(V2, "analysis_v2/data/admin")
dir.create(D_AD, recursive = TRUE, showWarnings = FALSE)
AEA <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
CELL_M <- 50000
msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

# 省名对齐:审图号底图用中文省名,项目内用英文 / harmonise province names
PROV_CN2EN <- c(
  "北京市"="Beijing","天津市"="Tianjin","河北省"="Hebei","山西省"="Shanxi",
  "内蒙古自治区"="Inner Mongolia","辽宁省"="Liaoning","吉林省"="Jilin",
  "黑龙江省"="Heilongjiang","上海市"="Shanghai","江苏省"="Jiangsu","浙江省"="Zhejiang",
  "安徽省"="Anhui","福建省"="Fujian","江西省"="Jiangxi","山东省"="Shandong",
  "河南省"="Henan","湖北省"="Hubei","湖南省"="Hunan","广东省"="Guangdong",
  "广西壮族自治区"="Guangxi","海南省"="Hainan","重庆市"="Chongqing","四川省"="Sichuan",
  "贵州省"="Guizhou","云南省"="Yunnan","西藏自治区"="Tibet","陕西省"="Shaanxi",
  "甘肃省"="Gansu","青海省"="Qinghai","宁夏回族自治区"="Ningxia",
  "新疆维吾尔自治区"="Xinjiang")

# ------------------------------------------------------------
# 1. 行政单元
# ------------------------------------------------------------
msg("读取行政单元 / reading administrative units")
cnty <- st_make_valid(st_transform(st_read(file.path(BM, "县（等积投影）.shp"), quiet = TRUE), AEA))
pref <- st_make_valid(st_transform(st_read(file.path(BM, "市（等积投影）.shp"), quiet = TRUE), AEA))

# 底图中有 2 个 PAC 重码(苏州姑苏区/工业园区、台湾一例),按编码融合成单一单元,
# 使 unit_id 成为合法主键 / dissolve the two duplicated PAC codes so unit_id is a key
dup_pac <- as.character(cnty$PAC)[duplicated(as.character(cnty$PAC))]
if (length(dup_pac)) {
  keep <- cnty[!as.character(cnty$PAC) %in% dup_pac, ]
  merged <- do.call(rbind, lapply(unique(dup_pac), function(k) {
    sub <- cnty[as.character(cnty$PAC) == k, ]
    g <- st_union(st_geometry(sub))
    r <- sub[1, ]; st_geometry(r) <- g; r
  }))
  cnty <- rbind(keep, merged)
}
cnty$unit_id  <- as.character(cnty$PAC)
cnty$unit_nm  <- as.character(cnty$NAME)
stopifnot(!anyDuplicated(cnty$unit_id))
cnty$prov_cn  <- as.character(cnty[["省"]])
cnty$pref_cn  <- as.character(cnty[["市"]])
cnty$province <- unname(PROV_CN2EN[cnty$prov_cn])

pref$unit_id  <- as.character(pref[["市代码"]])
pref$unit_nm  <- as.character(pref[["市"]])
pref$prov_cn  <- as.character(pref[["省"]])
pref$province <- unname(PROV_CN2EN[pref$prov_cn])

for (nm in c("cnty", "pref")) {
  x <- get(nm)
  x$area_km2 <- as.numeric(set_units(st_area(x), km^2))
  assign(nm, x)
}
msg(sprintf("县 %d 个(配到省 %d);市 %d 个(配到省 %d)",
            nrow(cnty), sum(!is.na(cnty$province)), nrow(pref), sum(!is.na(pref$province))))

UNITS <- list(county = cnty, prefecture = pref)

# ------------------------------------------------------------
# 2. 事件配单元
# ------------------------------------------------------------
msg("事件配单元 / assigning events")
ev <- fread(file.path(D_PA, "cc_events_enriched.csv"), encoding = "UTF-8")
ev_sf <- st_transform(st_as_sf(ev, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE), AEA)
for (lv in names(UNITS)) {
  u <- UNITS[[lv]]
  j <- st_drop_geometry(st_join(ev_sf["species"], u[, c("unit_id", "province")], join = st_intersects))
  ev[[paste0("unit_", lv)]] <- j$unit_id
  ev[[paste0("provgeo_", lv)]] <- j$province
  msg(sprintf("  %s: 配到 %d / %d 条", lv, sum(!is.na(j$unit_id)), nrow(ev)))
}
# 事件所属省以项目字段为准;单元必须落在该省内才算有效 / unit must be in the same province
for (lv in names(UNITS)) {
  ok <- !is.na(ev[[paste0("unit_", lv)]]) & ev[[paste0("provgeo_", lv)]] == ev$province
  ev[[paste0("valid_", lv)]] <- ok
  msg(sprintf("  %s: 单元与省一致的 %d 条", lv, sum(ok, na.rm = TRUE)))
}
fwrite(ev, file.path(D_AD, "events_with_units.csv"))

# ------------------------------------------------------------
# 3. 单元 × 年观鸟努力(真实)
# ------------------------------------------------------------
msg("单元级观鸟努力 / genuine unit-level effort")
g <- as.data.table(readRDS(OBS))
g <- g[is.finite(longitude) & is.finite(latitude) & year >= 2002 & year <= 2024]
g[, `:=`(lon_r = round(longitude, 5), lat_r = round(latitude, 5))]
cl <- unique(g[, .(serial_id, lon_r, lat_r, year)])
loc <- unique(cl[, .(lon_r, lat_r)])
loc_sf <- st_transform(st_as_sf(loc, coords = c("lon_r", "lat_r"), crs = 4326, remove = FALSE), AEA)
for (lv in names(UNITS)) {
  u <- UNITS[[lv]]
  loc[[paste0("u_", lv)]] <- st_drop_geometry(
    st_join(loc_sf, u["unit_id"], join = st_intersects))$unit_id
}
cl <- merge(cl, loc, by = c("lon_r", "lat_r"))
for (lv in names(UNITS)) {
  k <- paste0("u_", lv)
  eff <- cl[!is.na(get(k)), .(n_checklist = .N, n_loc = uniqueN(paste(lon_r, lat_r))),
            by = c(k, "year")]
  setnames(eff, k, "unit_id")
  fwrite(eff, file.path(D_AD, sprintf("effort_unit_year_%s.csv", lv)))
  msg(sprintf("  %s: %d 个单元-年组合,覆盖 %d 个单元",
              lv, nrow(eff), uniqueN(eff$unit_id)))
}

# ------------------------------------------------------------
# 4. 单元环境:由 50 km 格面积加权聚合
# ------------------------------------------------------------
msg("单元环境(50 km 格面积加权)/ area-weighted environment")
gp <- fread(file.path(D_PA, "c3_grid_panel.csv"))
gb <- fread(file.path(V2, "data/raw/grid_50km_base.csv"))
gxy <- sf_project("EPSG:4326", AEA, as.matrix(gb[, .(centroid_lon, centroid_lat)]))
mk_cell <- function(cx, cy) {
  h <- CELL_M / 2
  st_polygon(list(cbind(c(cx-h, cx+h, cx+h, cx-h, cx-h), c(cy-h, cy-h, cy+h, cy+h, cy-h))))
}
grid_sf <- st_sf(grid_id = gb$grid_id,
                 geometry = st_sfc(Map(mk_cell, gxy[, 1], gxy[, 2]), crs = AEA))
grid_sf <- merge(grid_sf, gp[, .(grid_id, bio1, bio12, elev, warming_rate)], by = "grid_id")

agg_env <- function(u) {
  ix <- st_intersects(u, grid_sf)
  out <- rbindlist(lapply(seq_len(nrow(u)), function(i) {
    j <- ix[[i]]
    if (!length(j)) return(data.table(unit_id = u$unit_id[i], bio1 = NA_real_,
                                      bio12 = NA_real_, elev = NA_real_, warming_rate = NA_real_))
    inter <- suppressWarnings(st_intersection(st_geometry(u)[i], st_geometry(grid_sf)[j]))
    w <- as.numeric(st_area(inter))
    d <- st_drop_geometry(grid_sf)[j, ]
    # st_intersection 可能返回少于 j 的要素,按长度对齐 / align lengths defensively
    n <- min(length(w), nrow(d))
    if (!n) return(data.table(unit_id = u$unit_id[i], bio1 = NA_real_,
                              bio12 = NA_real_, elev = NA_real_, warming_rate = NA_real_))
    w <- w[seq_len(n)]; d <- d[seq_len(n), ]
    wm <- function(v) if (all(is.na(v))) NA_real_ else weighted.mean(v, w, na.rm = TRUE)
    data.table(unit_id = u$unit_id[i], bio1 = wm(d$bio1), bio12 = wm(d$bio12),
               elev = wm(d$elev), warming_rate = wm(d$warming_rate))
  }))
  out
}

pa <- st_read(file.path(D_PA, "pa_clean.gpkg"), quiet = TRUE)
pa_u <- st_union(st_geometry(pa))

for (lv in names(UNITS)) {
  u <- UNITS[[lv]]
  msg("  聚合环境: ", lv, " (", nrow(u), " 个单元)")
  envd <- agg_env(u)
  # 保护地覆盖 / reserve coverage
  ixp <- st_intersects(u, pa_u)
  pa_km2 <- rep(0, nrow(u))
  hit <- which(lengths(ixp) > 0L)
  if (length(hit)) {
    inter <- suppressWarnings(st_intersection(st_geometry(u)[hit], pa_u))
    pa_km2[hit] <- as.numeric(set_units(st_area(inter), km^2))
  }
  ud <- data.table(unit_id = u$unit_id, unit_nm = u$unit_nm, province = u$province,
                   prov_cn = u$prov_cn, area_km2 = u$area_km2, pa_km2 = pa_km2)
  ud[, frac_pa := pa_km2 / area_km2]
  ud <- merge(ud, envd, by = "unit_id", all.x = TRUE)
  cxy <- st_coordinates(st_centroid(st_geometry(u)))
  ud[, `:=`(cx = cxy[match(unit_id, u$unit_id), 1], cy = cxy[match(unit_id, u$unit_id), 2])]
  fwrite(ud, file.path(D_AD, sprintf("units_%s.csv", lv)))
  msg(sprintf("  %s: 环境齐全的单元 %d / %d;保护地覆盖>0 的 %d",
              lv, sum(is.finite(ud$bio1)), nrow(ud), sum(ud$frac_pa > 0)))
}

# ------------------------------------------------------------
# 5. 物种 × 单元 到 BirdLife 分布区的距离
# ------------------------------------------------------------
msg("物种分布区距离 / distance to the species' known range")
bl <- st_read(BOTW, quiet = TRUE)
bl <- st_make_valid(st_transform(bl, AEA))
sp_need <- sort(unique(ev$species))
sp_have <- intersect(sp_need, bl$sci_name)
msg(sprintf("事件物种 %d 个,其中有分布区多边形的 %d 个 (%.1f%%)",
            length(sp_need), length(sp_have), 100 * length(sp_have) / length(sp_need)))

for (lv in names(UNITS)) {
  u <- UNITS[[lv]]
  cen <- st_centroid(st_geometry(u))
  res <- vector("list", length(sp_have))
  for (i in seq_along(sp_have)) {
    s <- sp_have[i]
    poly <- st_union(st_geometry(bl)[bl$sci_name == s])
    d <- as.numeric(set_units(st_distance(cen, poly), km))
    res[[i]] <- data.table(species = s, unit_id = u$unit_id, dist_range_km = d)
    if (i %% 50 == 0) msg(sprintf("  %s 距离 %d / %d", lv, i, length(sp_have)))
  }
  res <- rbindlist(res)
  fwrite(res, file.path(D_AD, sprintf("dist_species_unit_%s.csv", lv)))
  msg(sprintf("  %s: 距离表 %d 行;质心落在分布区内的比例 %.1f%%",
              lv, nrow(res), 100 * mean(res$dist_range_km == 0)))
}

# ------------------------------------------------------------
# 6. 备择集:每个事件 × 该省全部单元
# ------------------------------------------------------------
msg("构建备择集 / building alternative sets")
for (lv in names(UNITS)) {
  ud  <- fread(file.path(D_AD, sprintf("units_%s.csv", lv)))
  eff <- fread(file.path(D_AD, sprintf("effort_unit_year_%s.csv", lv)))
  dst <- fread(file.path(D_AD, sprintf("dist_species_unit_%s.csv", lv)))
  ecol <- paste0("unit_", lv); vcol <- paste0("valid_", lv)
  evu <- ev[get(vcol) == TRUE & !is.na(province)]
  evu[, event_id := paste(species, province, year, sep = "|")]

  alt <- rbindlist(lapply(seq_len(nrow(evu)), function(i) {
    p <- evu$province[i]; y <- evu$year[i]; s <- evu$species[i]
    cand <- ud[province == p]
    if (!nrow(cand)) return(NULL)
    data.table(event_id = evu$event_id[i], species = s, province = p, year = y,
               unit_id = cand$unit_id, unit_nm = cand$unit_nm,
               chosen = as.integer(cand$unit_id == evu[[ecol]][i]),
               area_km2 = cand$area_km2, frac_pa = cand$frac_pa,
               bio1 = cand$bio1, bio12 = cand$bio12, elev = cand$elev,
               warming_rate = cand$warming_rate, cx = cand$cx, cy = cand$cy)
  }))
  # 当年努力与累计努力 / effort in that year and cumulative to that year
  alt <- merge(alt, eff[, .(unit_id, year, n_checklist)], by = c("unit_id", "year"), all.x = TRUE)
  alt[is.na(n_checklist), n_checklist := 0L]
  cum <- eff[, .(unit_id, year, n_checklist)][order(unit_id, year)]
  cum[, cum_cl := cumsum(n_checklist), by = unit_id]
  alt <- merge(alt, cum[, .(unit_id, year, cum_cl)], by = c("unit_id", "year"), all.x = TRUE)
  alt[is.na(cum_cl), cum_cl := 0L]
  alt <- merge(alt, dst, by = c("species", "unit_id"), all.x = TRUE)

  keep <- alt[, .(has_choice = sum(chosen) == 1L), by = event_id][has_choice == TRUE]$event_id
  alt <- alt[event_id %in% keep]
  write_parquet(alt, file.path(D_AD, sprintf("altset_%s.parquet", lv)))
  msg(sprintf("  %s: 备择集 %d 行;事件 %d 个;每事件备择数中位 %d;有分布区距离的行 %.1f%%",
              lv, nrow(alt), uniqueN(alt$event_id),
              as.integer(median(alt[, .N, by = event_id]$N)),
              100 * mean(is.finite(alt$dist_range_km))))
}

msg("完成 / done")
