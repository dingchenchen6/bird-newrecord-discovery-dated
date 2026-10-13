# ============================================================
# 探针脚本 / probe: 检验 GBIF-eBird 观鸟事件层能否充当
# 「保护区内外对比」的对照集(used-available 设计的 available 端)
# Probe whether the GBIF/eBird checklist layer can serve as the
# availability set for a used-available comparison inside vs outside reserves.
#
# 只做诊断,不产出分析结论 / diagnostics only, no inference
# ============================================================
suppressPackageStartupMessages({library(sf); library(data.table); library(units)})
sf_use_s2(FALSE)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
OBS  <- "/Users/dingchenchen/Documents/New project/bird_dynamic_occupancy_analysis/data/derived/gbif_ebird_events_2000_2025.rds"
PROV_SHP <- "/Users/dingchenchen/Documents/SDMs/GS(2023)2767审图号/省面.shp"
PA_CLEAN <- file.path(V2, "analysis_v2/data/pa/pa_clean.gpkg")
AEA <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

# ---- 1. 观测层:压到唯一点位 × 年 ----
msg("读取观测层 / reading checklist layer")
g <- as.data.table(readRDS(OBS))
g <- g[is.finite(longitude) & is.finite(latitude) & year >= 2002 & year <= 2024]
msg("2002-2024 记录 ", nrow(g), " 条;唯一 checklist ", uniqueN(g$serial_id))

# 每个 (点位, 年) 的 checklist 数 = 该点当年的观测努力
# checklists per (location, year) = effort at that location that year
g[, `:=`(lon_r = round(longitude, 5), lat_r = round(latitude, 5))]
loc_year <- unique(g[, .(serial_id, lon_r, lat_r, year)])[
  , .(n_checklist = .N), by = .(lon_r, lat_r, year)]
loc <- unique(loc_year[, .(lon_r, lat_r)])
msg("唯一点位 ", nrow(loc), ";点位-年组合 ", nrow(loc_year))

# ---- 2. 给点位配省份 ----
msg("点位配省 / assigning provinces")
prov <- st_make_valid(st_transform(st_read(PROV_SHP, quiet = TRUE), AEA))
cn_field <- names(prov)[sapply(prov, is.character)][1]
prov$prov_cn <- as.character(prov[[cn_field]])
loc_sf <- st_transform(st_as_sf(loc, coords = c("lon_r", "lat_r"), crs = 4326, remove = FALSE), AEA)
loc$prov_cn <- st_drop_geometry(st_join(loc_sf, prov["prov_cn"], join = st_intersects))$prov_cn
msg("配到省的点位 ", sum(!is.na(loc$prov_cn)), " / ", nrow(loc),
    sprintf(" (%.1f%%)", 100 * mean(!is.na(loc$prov_cn))))

# ---- 3. 点位是否落在保护区内 ----
msg("点位 × 保护区 / points in reserves")
pa <- st_read(PA_CLEAN, quiet = TRUE)
pa_u <- st_union(st_geometry(pa))
loc$in_pa <- lengths(st_intersects(loc_sf, pa_u)) > 0L
msg(sprintf("观鸟点位落在保护区内:%d / %d = %.1f%%",
            sum(loc$in_pa), nrow(loc), 100 * mean(loc$in_pa)))

# 按 checklist 加权(真实努力权重)/ weighted by actual checklists
ly <- merge(loc_year, as.data.table(loc)[, .(lon_r, lat_r, prov_cn, in_pa)],
            by = c("lon_r", "lat_r"))
msg(sprintf("按 checklist 加权的区内份额:%.1f%%  (总 checklist %d)",
            100 * sum(ly$n_checklist[ly$in_pa]) / sum(ly$n_checklist), sum(ly$n_checklist)))

# ---- 4. 事件端 ----
ev <- fread(file.path(V2, "analysis_v2/data/pa/pa_events_overlay.csv"), encoding = "UTF-8")
ev_sf <- st_transform(st_as_sf(ev, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE), AEA)
ev$prov_cn <- st_drop_geometry(st_join(ev_sf["species"], prov["prov_cn"], join = st_intersects))$prov_cn
msg(sprintf("事件区内份额:%.1f%% (%d/%d)", 100 * mean(ev$in_pa), sum(ev$in_pa), nrow(ev)))

# ---- 5. 关键诊断:同省同年是否有可用对照 ----
msg("对照可得性 / availability of controls by province-year stratum")
ly_prov <- ly[!is.na(prov_cn), .(n_loc = .N, n_cl = sum(n_checklist),
                                 n_loc_pa = sum(in_pa)), by = .(prov_cn, year)]
ev2 <- ev[!is.na(prov_cn)]
have <- merge(ev2[, .(n_event = .N), by = .(prov_cn, year)], ly_prov,
              by = c("prov_cn", "year"), all.x = TRUE)
have[is.na(n_loc), `:=`(n_loc = 0L, n_cl = 0L, n_loc_pa = 0L)]
msg(sprintf("事件所在省-年有对照点位的:%d / %d 事件 (%.1f%%)",
            sum(have$n_event[have$n_loc > 0]), sum(have$n_event),
            100 * sum(have$n_event[have$n_loc > 0]) / sum(have$n_event)))
msg(sprintf("对照点位 >= 20 个的省-年覆盖事件:%d (%.1f%%)",
            sum(have$n_event[have$n_loc >= 20]),
            100 * sum(have$n_event[have$n_loc >= 20]) / sum(have$n_event)))
cat("\n事件数最多的 10 个省-年及其对照量:\n")
print(head(have[order(-n_event)], 10))
cat("\n按年份的对照可得性:\n")
print(have[, .(events = sum(n_event), ctrl_loc = sum(n_loc), ctrl_cl = sum(n_cl)), by = year][order(year)])

# ---- 6. 再检出:能否区分定殖与迷鸟 ----
msg("再检出诊断 / re-detection as a persistence proxy")
gp <- unique(g[, .(species, lon_r, lat_r, year)])
gp <- merge(gp, as.data.table(loc)[, .(lon_r, lat_r, prov_cn)], by = c("lon_r", "lat_r"))
sp_prov_year <- unique(gp[!is.na(prov_cn), .(species, prov_cn, year)])
ev3 <- ev2[species %in% unique(sp_prov_year$species)]
msg("事件物种在观测层出现的:", nrow(ev3), " / ", nrow(ev2))
red <- sp_prov_year[ev3[, .(species, prov_cn, ev_year = year)],
                    on = .(species, prov_cn), allow.cartesian = TRUE]
red_after <- red[year > ev_year, .(n_year_after = uniqueN(year),
                                   first_after = min(year)), by = .(species, prov_cn, ev_year)]
ev3 <- merge(ev3, red_after, by.x = c("species", "prov_cn", "year"),
             by.y = c("species", "prov_cn", "ev_year"), all.x = TRUE)
ev3[is.na(n_year_after), n_year_after := 0L]
msg(sprintf("首次记录后再被检出过的事件:%d / %d = %.1f%%",
            sum(ev3$n_year_after > 0), nrow(ev3), 100 * mean(ev3$n_year_after > 0)))
msg(sprintf("再检出 >= 3 年(视为可能定殖)的:%d = %.1f%%",
            sum(ev3$n_year_after >= 3), 100 * mean(ev3$n_year_after >= 3)))
cat("\n按是否在保护区内的再检出:\n")
print(ev3[, .(n = .N, redetected = sum(n_year_after > 0),
              pct = round(100 * mean(n_year_after > 0), 1),
              persist3 = sum(n_year_after >= 3),
              pct3 = round(100 * mean(n_year_after >= 3), 1)), by = in_pa])

OUT <- file.path(V2, "analysis_v2/data/pa")
fwrite(as.data.table(loc), file.path(OUT, "probe_birding_locations.csv"))
fwrite(ly, file.path(OUT, "probe_birding_loc_year.csv"))
fwrite(ev3, file.path(OUT, "probe_events_redetection.csv"))
msg("探针输出已写出 / probe outputs written")
