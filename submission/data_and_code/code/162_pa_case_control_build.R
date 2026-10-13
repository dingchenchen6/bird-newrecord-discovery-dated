# ============================================================
# Scientific question / 科学问题:
# 省级鸟类新纪录在自然保护区内的富集(26.2%),究竟是保护区作为
# 「生态接收网」的证据,还是保护区作为「观测装置」的产物?
# Is the enrichment of new bird records inside nature reserves evidence
# that reserves receive redistributing species, or an artefact of where
# and how people look?
#
# Objective / 分析目标:
# 构建 used-available 病例-对照数据集:病例 = 新纪录事件点,
# 对照 = 观鸟者实际去过的地点(GBIF/eBird checklist),以省 × 年为层。
# 这样「观鸟者去了哪里」在设计上被条件化掉,而不是作为协变量调整。
# Build a used-available table in which availability is where birders
# actually went, stratified by province and year, so observation geography
# is conditioned out by design rather than adjusted for.
#
# Input data / 输入数据:
#   analysis_v2/data/pa/pa_events_overlay.csv        657 事件 × 保护区叠加
#   gbif_ebird_events_2000_2025.rds                  286 万条观鸟记录
#   analysis_v2/data/pa/pa_clean.gpkg                1028 处已制图自然保护区
#   data/raw/grid_50km_base.csv / grid_50km_climate.csv  格阵与格级环境
#   data/raw/bird_new_records_20260509.xlsx          发现方式等原始字段
#   省面.shp                                          省界(审图号 GS(2023)2767)
#
# Main workflow / 主要流程:
#   1. 省界与格阵 / provinces and lattice
#   2. 观鸟点位 × 年:落区判定、到保护区距离、清单质量
#   3. 事件点:同口径协变量 + 发现方式
#   4. 抽样对照,构建条件 logistic 用的层结构
#   5. 判别性描述统计(辛普森检验、集中度、发现方式、清单质量、缓冲敏感性)
#
# Expected output / 预期输出:
#   analysis_v2/data/pa/cc_case_control_K200.parquet   条件 logistic 主表
#   analysis_v2/data/pa/cc_birding_locations.csv       观鸟点位 × 年全表
#   analysis_v2/data/pa/cc_events_enriched.csv         事件 × 全部协变量
#   analysis_v2/tables/tbl_pa_simpson_by_province.csv  省内分层对比
#   analysis_v2/tables/tbl_pa_discovery_method.csv     发现方式 × 落区
#   analysis_v2/tables/tbl_pa_checklist_quality.csv    区内外清单质量
#   analysis_v2/tables/tbl_pa_concentration.csv        宿主保护区集中度
#   analysis_v2/tables/tbl_pa_buffer_sensitivity.csv   坐标精度缓冲敏感性
#
# Key assumptions / 关键假设:
#   - 只对「1028 处已制图的、以国家级为主的、2012 年前建立的自然保护区」下结论。
#   - 观鸟层止于 2023 年,2024 年的事件没有同年对照,单列处理。
#   - 事件坐标量化至 2 位小数(约 1.1 km),因此落区判定同时给出 0/1.1/3/5 km
#     缓冲下的三分结果(确定内 / 确定外 / 不确定)。
#   - 观鸟点位本身也是被报告的地点,存在自身报告偏倚;它是对照而非真值。
#   - 全部空间运算在等积投影下进行。
#
# Main packages / 主要包: sf, data.table, arrow, readxl, units
# Output directory / 输出路径: analysis_v2/data/pa/, analysis_v2/tables/
# ============================================================

suppressPackageStartupMessages({
  library(sf); library(data.table); library(units); library(arrow)
})
sf_use_s2(FALSE)
set.seed(20260803)

V2  <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
OBS <- "/Users/dingchenchen/Documents/New project/bird_dynamic_occupancy_analysis/data/derived/gbif_ebird_events_2000_2025.rds"
PROV_SHP <- "/Users/dingchenchen/Documents/SDMs/GS(2023)2767审图号/省面.shp"
D_PA <- file.path(V2, "analysis_v2/data/pa")
D_TB <- file.path(V2, "analysis_v2/tables")
AEA <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
CELL_M <- 50000
K_CTRL <- 200

msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

# 禁用清单断言 / assert the disallowed v1 layers are never read here
DISALLOWED <- c("grid_50km_risk_set.csv", "grid_100km_risk_set.csv",
                "events_50km_grid_assigned.csv", "grid_50km_effort.csv")
msg("禁用图层(v1 发表年定年口径 / 省级努力广播): ", paste(DISALLOWED, collapse = ", "))

# ------------------------------------------------------------
# 1. 省界、保护区、格阵
# ------------------------------------------------------------
msg("读取省界与保护区")
prov <- st_make_valid(st_transform(st_read(PROV_SHP, quiet = TRUE), AEA))
# 省名对齐:审图号底图的 Yname 与项目内 province 命名有三处不一致
# harmonise province names between the base map and the project convention
PROV_FIX <- c(Neimenggu = "Inner Mongolia", Xizang = "Tibet", Shangdong = "Shandong")
yn <- as.character(prov$Yname)
prov$province <- ifelse(yn %in% names(PROV_FIX), PROV_FIX[yn], yn)
prov$prov_cn  <- as.character(prov$NAME)

pa <- st_read(file.path(D_PA, "pa_clean.gpkg"), quiet = TRUE)
pa$est_year_fill <- ifelse(is.na(pa$est_year), 1900L, pa$est_year)
pa_geom <- st_geometry(pa)

# 逐年累积并集,供按事件年判定落区 / cumulative unions by year
YEARS <- 2002:2024
u_by_year <- lapply(YEARS, function(y) st_union(pa_geom[pa$est_year_fill <= y]))
names(u_by_year) <- as.character(YEARS)
u_all <- st_union(pa_geom)
u_nat <- st_union(pa_geom[pa$pa_level == "national"])

gb <- fread(file.path(V2, "data/raw/grid_50km_base.csv"))
gxy <- sf_project("EPSG:4326", AEA, as.matrix(gb[, .(centroid_lon, centroid_lat)]))
gb[, `:=`(ax = gxy[, 1], ay = gxy[, 2])]
x0 <- min(gb$ax) - CELL_M / 2; y0 <- min(gb$ay) - CELL_M / 2
gclim <- fread(file.path(V2, "data/raw/grid_50km_climate.csv"))
gb <- merge(gb, gclim[, .(grid_id, bio1, bio12, elev, warming_rate, climate_velocity, climate_exposure)],
            by = "grid_id", all.x = TRUE)

#' 把 Albers 坐标映射到 50 km 格 / map projected coords onto the lattice
assign_grid <- function(ax, ay) {
  ix <- floor((ax - x0) / CELL_M); iy <- floor((ay - y0) / CELL_M)
  key <- paste(ix, iy, sep = "_")
  gb_key <- paste(floor((gb$ax - x0) / CELL_M), floor((gb$ay - y0) / CELL_M), sep = "_")
  gb$grid_id[match(key, gb_key)]
}

# ------------------------------------------------------------
# 2. 观鸟点位 × 年
# ------------------------------------------------------------
msg("读取观鸟层并压到点位 × 年")
g <- as.data.table(readRDS(OBS))
g <- g[is.finite(longitude) & is.finite(latitude) & year >= 2002 & year <= 2024]
g[, `:=`(lon_r = round(longitude, 5), lat_r = round(latitude, 5))]

# 每份 checklist 的质量:物种数与时长 / checklist quality
cl <- unique(g[, .(serial_id, lon_r, lat_r, year, taxon_count_event, duration_min)])
loc_year <- cl[, .(n_checklist = .N,
                   mean_taxa = mean(taxon_count_event, na.rm = TRUE),
                   mean_dur  = mean(duration_min, na.rm = TRUE)),
               by = .(lon_r, lat_r, year)]
loc <- unique(loc_year[, .(lon_r, lat_r)])
msg("唯一观鸟点位 ", nrow(loc), ";点位-年 ", nrow(loc_year))

loc_sf <- st_transform(st_as_sf(loc, coords = c("lon_r", "lat_r"), crs = 4326, remove = FALSE), AEA)
lxy <- st_coordinates(loc_sf)
loc[, `:=`(ax = lxy[, 1], ay = lxy[, 2])]
loc[, province := st_drop_geometry(st_join(loc_sf, prov["province"], join = st_intersects))$province]
loc[, grid_id := assign_grid(ax, ay)]

msg("观鸟点位落区判定与距离")
loc[, in_pa_static := lengths(st_intersects(loc_sf, u_all)) > 0L]
loc[, in_pa_national := lengths(st_intersects(loc_sf, u_nat)) > 0L]
nf <- st_nearest_feature(loc_sf, pa)
loc[, `:=`(dist_to_pa_km = as.numeric(set_units(
             st_distance(loc_sf, pa[nf, ], by_element = TRUE), km)),
           nearest_pa_name = pa$pa_name[nf], nearest_pa_level = pa$pa_level[nf])]
msg(sprintf("观鸟点位区内 %.1f%%;到保护区中位距离 %.1f km",
            100 * mean(loc$in_pa_static), median(loc$dist_to_pa_km)))

loc_year <- merge(loc_year, loc, by = c("lon_r", "lat_r"))
# 按事件年的建区状态重判 / re-evaluate in_pa using reserve status in that year
loc_year[, in_pa := in_pa_static]
for (y in YEARS) {
  idx <- which(loc_year$year == y)
  if (!length(idx)) next
  pts <- st_as_sf(loc_year[idx, .(lon_r, lat_r)], coords = c("lon_r", "lat_r"), crs = 4326)
  loc_year$in_pa[idx] <- lengths(st_intersects(st_transform(pts, AEA), u_by_year[[as.character(y)]])) > 0L
}
fwrite(loc_year, file.path(D_PA, "cc_birding_locations.csv"))

# ------------------------------------------------------------
# 3. 事件端
# ------------------------------------------------------------
msg("事件端协变量")
ev <- fread(file.path(D_PA, "pa_events_overlay.csv"), encoding = "UTF-8")
ev_sf <- st_transform(st_as_sf(ev, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE), AEA)
exy <- st_coordinates(ev_sf)
ev[, `:=`(ax = exy[, 1], ay = exy[, 2])]
ev[, prov_geo := st_drop_geometry(st_join(ev_sf["species"], prov["province"], join = st_intersects))$province]
ev[, grid_id2 := assign_grid(ax, ay)]
ev[, grid_id := fifelse(is.na(grid_id), grid_id2, grid_id)]

# 缓冲敏感性:坐标量化至约 1.1 km / buffer sensitivity for 2-decimal coordinates
for (b in c(0, 1.1, 3, 5)) {
  gm <- if (b == 0) st_geometry(ev_sf) else st_buffer(st_geometry(ev_sf), b * 1000)
  ev[[sprintf("in_pa_b%s", sub("\\.", "_", as.character(b)))]] <-
    lengths(st_intersects(gm, u_all)) > 0L
}

# 发现方式 / discovery method from the source compilation
xl <- suppressWarnings(as.data.table(readxl::read_excel(
  file.path(V2, "data/raw/bird_new_records_20260509.xlsx"), sheet = 1)))
mth <- xl[, .(sp = trimws(as.character(Scientificname)),
              prov_en = trimws(as.character(Province_EN)),
              method = trimws(as.character(Discoverymethod)),
              cause  = trimws(as.character(Discovercause)))]
mth <- mth[!is.na(sp) & sp != ""]
mth <- unique(mth, by = c("sp", "prov_en"))
ev <- merge(ev, mth, by.x = c("species", "province"), by.y = c("sp", "prov_en"), all.x = TRUE)
# 归并为专业调查 vs 观鸟式发现 / professional survey vs birdwatching discovery
prof_kw <- "标本|红外|环志|网捕|救助|采集"
ev[, method_grp := fifelse(is.na(method) | method == "", "unknown",
                    fifelse(grepl(prof_kw, method), "professional_survey", "birdwatching"))]

ev <- merge(ev, gb[, .(grid_id, bio1, bio12, elev, warming_rate, climate_velocity, climate_exposure)],
            by = "grid_id", all.x = TRUE)
fwrite(ev, file.path(D_PA, "cc_events_enriched.csv"))
msg(sprintf("事件 %d 条;配到省 %d;配到格 %d;有发现方式 %d",
            nrow(ev), sum(!is.na(ev$prov_geo)), sum(!is.na(ev$grid_id)),
            sum(ev$method_grp != "unknown")))

# ------------------------------------------------------------
# 4. 抽样对照,构建条件 logistic 主表
# ------------------------------------------------------------
msg("抽样对照 / sampling controls, K = ", K_CTRL)
ly <- loc_year[!is.na(province)]
setkey(ly, province, year)

ev_use <- ev[!is.na(province) & year <= 2023]
ev_use[, event_key := paste(species, province, year, sep = "|")]
cc <- vector("list", nrow(ev_use))
for (i in seq_len(nrow(ev_use))) {
  p <- ev_use$province[i]; y <- ev_use$year[i]
  pool <- ly[.(p, y)]
  if (!nrow(pool) || is.na(pool$lon_r[1])) { cc[[i]] <- NULL; next }
  # 主口径:按 checklist 数加权抽样 = 按真实观测努力抽 / effort-weighted
  idx_w <- sample.int(nrow(pool), K_CTRL, replace = TRUE, prob = pool$n_checklist)
  # 敏感性口径:点位等权抽样 = 按地点抽 / location-equal
  idx_u <- sample.int(nrow(pool), K_CTRL, replace = TRUE)
  mk <- function(idx, wt) data.table(
    event_id = ev_use$event_key[i], stratum = paste(p, y, sep = "|"),
    province = p, year = y, used = 0L, weight_scheme = wt,
    in_pa = pool$in_pa[idx], in_pa_national = pool$in_pa_national[idx],
    dist_to_pa_km = pool$dist_to_pa_km[idx], grid_id = pool$grid_id[idx],
    lon = pool$lon_r[idx], lat = pool$lat_r[idx])
  cc[[i]] <- rbind(mk(idx_w, "effort"), mk(idx_u, "location"))
}
cc <- rbindlist(cc, fill = TRUE)

case_rows <- rbindlist(lapply(c("effort", "location"), function(wt)
  data.table(event_id = ev_use$event_key, stratum = paste(ev_use$province, ev_use$year, sep = "|"),
             province = ev_use$province, year = ev_use$year, used = 1L, weight_scheme = wt,
             in_pa = ev_use$in_pa, in_pa_national = ev_use$in_pa_national,
             dist_to_pa_km = ev_use$dist_to_pa_km, grid_id = ev_use$grid_id,
             lon = ev_use$longitude, lat = ev_use$latitude)))
cc <- rbind(case_rows, cc, fill = TRUE)
cc <- merge(cc, gb[, .(grid_id, bio1, bio12, elev, warming_rate)], by = "grid_id", all.x = TRUE)
cc <- merge(cc, ev_use[, .(event_id = event_key, species, mig = NA_character_,
                           method_grp, host_pa = nearest_pa_name,
                           host_level = nearest_pa_level)],
            by = "event_id", all.x = TRUE)
write_parquet(cc, file.path(D_PA, "cc_case_control_K200.parquet"))
msg(sprintf("病例-对照表 %d 行;有效事件层 %d;每层对照 %d × 2 口径",
            nrow(cc), uniqueN(cc$event_id), K_CTRL))

# ------------------------------------------------------------
# 5. 判别性描述统计
# ------------------------------------------------------------
msg("判别性统计 / discriminating diagnostics")

# 5.1 辛普森检验:全国 vs 省内 / national versus within-province
ev_p <- ev[!is.na(province), .(n_event = .N, ev_in = sum(in_pa)), by = province]
ly_p <- ly[, .(n_cl = sum(n_checklist), cl_in = sum(n_checklist * in_pa),
               n_loc = .N, loc_in = sum(in_pa)), by = province]
simp <- merge(ev_p, ly_p, by = "province", all.x = TRUE)
simp[, `:=`(ev_pct = 100 * ev_in / n_event,
            cl_pct = 100 * cl_in / n_cl,
            loc_pct = 100 * loc_in / n_loc,
            ratio_cl = (ev_in / n_event) / pmax(cl_in / n_cl, 1e-6))]
setorder(simp, -n_event)
fwrite(simp, file.path(D_TB, "tbl_pa_simpson_by_province.csv"))
cat("\n== 省内对比(事件区内% vs checklist 加权区内%)==\n")
print(head(simp[, .(province, n_event, ev_pct = round(ev_pct, 1),
                    cl_pct = round(cl_pct, 1), ratio = round(ratio_cl, 2))], 15))
# 省内加权合并的富集比 / within-province pooled ratio (Mantel-Haenszel style)
mh_num <- sum(simp$ev_in * (1 - simp$cl_in / simp$n_cl), na.rm = TRUE)
mh_den <- sum((simp$n_event - simp$ev_in) * (simp$cl_in / simp$n_cl), na.rm = TRUE)
msg(sprintf("省内合并 MH 优势比(事件 vs checklist 努力)= %.2f", mh_num / mh_den))

# 5.2 发现方式 × 落区 / discovery method
dm <- ev[!is.na(province), .(n = .N, in_pa = sum(in_pa),
                             pct = round(100 * mean(in_pa), 1)), by = method_grp]
fwrite(dm, file.path(D_TB, "tbl_pa_discovery_method.csv"))
cat("\n== 发现方式 × 落区 ==\n"); print(dm)

# 5.3 区内外清单质量 / checklist quality inside vs outside
q <- ly[, .(n_loc = .N, n_cl = sum(n_checklist),
            taxa = round(weighted.mean(mean_taxa, n_checklist, na.rm = TRUE), 2),
            dur  = round(weighted.mean(mean_dur, n_checklist, na.rm = TRUE), 1),
            cl_per_loc = round(sum(n_checklist) / .N, 2)), by = in_pa]
fwrite(q, file.path(D_TB, "tbl_pa_checklist_quality.csv"))
cat("\n== 观鸟清单质量:区内 vs 区外 ==\n"); print(q)

# 5.4 宿主保护区集中度 / concentration among host reserves
host <- ev[in_pa == TRUE, .N, by = nearest_pa_name][order(-N)]
host[, cum_pct := round(100 * cumsum(N) / sum(N), 1)]
fwrite(host, file.path(D_TB, "tbl_pa_concentration.csv"))
cat("\n== 区内事件最集中的 10 个保护区 ==\n"); print(head(host, 10))
msg(sprintf("区内事件落在 %d 个保护区;前 2 处占 %.1f%%;前 10 处占 %.1f%%",
            nrow(host), host$cum_pct[2], host$cum_pct[min(10, nrow(host))]))

# 5.5 缓冲敏感性 / buffer sensitivity
bs <- data.table(buffer_km = c(0, 1.1, 3, 5),
                 n_in = c(sum(ev$in_pa_b0), sum(ev$in_pa_b1_1),
                          sum(ev$in_pa_b3), sum(ev$in_pa_b5)))
bs[, pct := round(100 * n_in / nrow(ev), 1)]
fwrite(bs, file.path(D_TB, "tbl_pa_buffer_sensitivity.csv"))
cat("\n== 坐标精度缓冲敏感性 ==\n"); print(bs)

msg("完成 / done")
