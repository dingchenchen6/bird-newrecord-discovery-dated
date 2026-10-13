#!/usr/bin/env Rscript
# ============================================================
# Script 214: 新纪录方位的几何零假设 / Geometric null for the bearing of new records
# ============================================================
# 科学问题 / Scientific question:
#   脚本 154 以"八方位均匀"为零假设, 得出新纪录强烈偏向东与东北
#   (chi2 = 580)。但方位是从物种【全球】分布区质心(AVONET)量到记录点的;
#   许多物种的全球质心位于中国以西或以南, 于是中国境内任何一条记录都天然
#   落在质心的东侧或北侧。均匀零假设因此不成立 —— 需要一个保留这种几何
#   关系的零假设, 才能判断方位偏倚是否超出"记录随机落在候选省份"所能产生的。
#   Script 154 tests bearings against a uniform null. Bearings run from each
#   species' GLOBAL range centroid, so for species centred west or south of
#   China any Chinese record lies east or north of the centroid by geometry
#   alone. The appropriate null keeps that geometry.
#
# 分析目标 / Objective:
#   蒙特卡洛零假设(999 次): 每条记录随机重置到其物种的某个候选省份
#   (风险集 50 格阈值中的物种 x 省份), 位置取该省实际新纪录点的平均经纬度;
#   (a) 候选省份等概率(纯几何); (b) 按 2002-2024 年总访问量加权(几何 + 努力)。
#   逐方位给出观测数、零假设均值与 95% 区间、双侧蒙特卡洛 P 与 Holm 校正;
#   整体给出相对零假设期望的卡方及其蒙特卡洛 P; 并对 154 中五个单独显著的目重复。
#   Monte Carlo nulls reassign each record to a random candidate province of its
#   species (a) uniformly and (b) weighted by 2002-2024 survey visits.
#
# 输入数据 / Input:
#   analysis_v2/data/events_discovery_dated.csv, analysis_v2/data/model_v2_thr50.parquet,
#   analysis_v2/data/effort_panel_v2.csv, AVONET1_BirdLife.csv(质心 / centroids),
#   CBNR v1.1 省界(仅用于没有新纪录的省份的回退位置 / fallback location only)
# 主要流程 / Workflow:
#   1. 复现 154 的观测方位 / reproduce observed bearings exactly as in 154
#   2. 候选省份与省内位置 / candidate provinces and within-province location
#   3. 两个蒙特卡洛零假设 / two Monte Carlo nulls
#   4. 逐方位与整体检验, 总体与分目 / per-sector and omnibus tests, overall and by order
# 预期输出 / Output:
#   analysis_v2/tables/tbl_v2_direction_geometric_null.csv          (逐方位 / per sector)
#   analysis_v2/tables/tbl_v2_direction_geometric_null_summary.csv  (整体 / omnibus)
#   analysis_v2/tables/tbl_v2_direction_null_si_{sectors,omnibus}.csv (SI 精简表 / compact SI tables)
#   下游: 脚本 154 读取逐方位表, 绘制主图的零假设对照面板
#   Downstream: script 154 reads the per-sector table for the main-figure null panels
# 关键假设 / Key assumptions:
#   - 省内位置用该省全部 v2 新纪录点的平均经纬度(记录实际发生处), 无记录者用省面内点;
#     敏感性: 全部改用省面内点 / sensitivity: point-on-surface for every province
#   - 方位算法与 154 完全相同(平面 atan2(经差, 纬差), 正北为 0) / same bearing as 154
# 主要包 / Packages: data.table, arrow, sf
# 运行 / Run (任务根目录 / from task root): Rscript --no-init-file code/214_direction_geometric_null.R
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(sf) })
options(warn = 1)
sf_use_s2(FALSE)
set.seed(20260924)                                   # 可复现 / reproducible
R_MC <- 999L                                         # 蒙特卡洛次数 / Monte Carlo replicates

OUT  <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
AVOF <- "/Users/dingchenchen/Downloads/AVONET/ELEData/TraitData/AVONET1_BirdLife.csv"
PROVF <- "/Users/dingchenchen/Downloads/CBNR_v1.1/20_reference_province_boundaries.shp"
DIRLV <- c("North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest")
ORDERS5 <- c("Passeriformes", "Anseriformes", "Accipitriformes", "Charadriiformes", "Columbiformes")
msg <- function(...) cat(sprintf("[214 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")
norm <- function(x) { x <- trimws(gsub("_", " ", as.character(x))); x <- gsub("\\s+", " ", x)
                      paste0(toupper(substr(x, 1, 1)), tolower(substr(x, 2, nchar(x)))) }
# 与 154 相同的方位划分 / identical sector rule to script 154
sector_of <- function(dx, dy) {
  a <- (atan2(dx, dy) * 180 / pi + 360) %% 360
  factor(DIRLV[floor(((a + 22.5) %% 360) / 45) + 1], levels = DIRLV)
}

# ---- 1. 观测方位 / observed bearings ----
ev <- fread(file.path(OUT, "data", "events_discovery_dated.csv"))[is.finite(longitude) & is.finite(latitude)]
av <- fread(AVOF)
cen <- unique(av[, .(nm = norm(Species1), order_lat = Order1,
                     clat = Centroid.Latitude, clon = Centroid.Longitude)], by = "nm")
ev[, nm := norm(species)]
d <- merge(ev, cen, by = "nm")[is.finite(clat) & is.finite(clon)]
d[, order := tools::toTitleCase(tolower(order_lat))]
d[, sec := sector_of(longitude - clon, latitude - clat)]
msg("观测 / observed: ", nrow(d), " records, ", uniqueN(d$nm), " species")

# ---- 2. 候选省份与省内位置 / candidate provinces and within-province location ----
zh <- c("北京"="Beijing","天津"="Tianjin","河北"="Hebei","山西"="Shanxi","内蒙古"="Inner Mongolia",
        "辽宁"="Liaoning","吉林"="Jilin","黑龙江"="Heilongjiang","上海"="Shanghai","江苏"="Jiangsu",
        "浙江"="Zhejiang","安徽"="Anhui","福建"="Fujian","江西"="Jiangxi","山东"="Shandong","河南"="Henan",
        "湖北"="Hubei","湖南"="Hunan","广东"="Guangdong","广西"="Guangxi","海南"="Hainan","重庆"="Chongqing",
        "四川"="Sichuan","贵州"="Guizhou","云南"="Yunnan","西藏"="Tibet","陕西"="Shaanxi","甘肃"="Gansu",
        "青海"="Qinghai","宁夏"="Ningxia","新疆"="Xinjiang")
pv <- st_read(PROVF, quiet = TRUE)
pv$province <- NA_character_
for (k in names(zh)) pv$province[startsWith(pv$name, k)] <- zh[[k]]
pos <- st_coordinates(st_transform(suppressWarnings(st_point_on_surface(st_make_valid(pv))), 4326))
pos <- data.table(province = pv$province, pos_lon = pos[, 1], pos_lat = pos[, 2])[!is.na(province)]
emp <- ev[, .(emp_lon = mean(longitude), emp_lat = mean(latitude)), by = province]
loc <- merge(pos, emp, by = "province", all.x = TRUE)
loc[, `:=`(lon = fifelse(is.na(emp_lon), pos_lon, emp_lon), lat = fifelse(is.na(emp_lat), pos_lat, emp_lat))]
msg("省份位置 / province locations: ", nrow(loc), " (empirical ", sum(!is.na(loc$emp_lon)), ")")

rs <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet"), col_select = c("species", "province")))
cand <- unique(rs)[, nm := norm(species)][nm %in% d$nm]
vis <- fread(file.path(OUT, "data", "effort_panel_v2.csv"))[in_scope == TRUE & year %in% 2002:2024,
                                                            .(vis = sum(n_visits, na.rm = TRUE)), by = province]
cand <- merge(merge(cand, loc[, .(province, lon, lat, pos_lon, pos_lat)], by = "province"), vis, by = "province")
cand <- merge(cand, unique(d[, .(nm, clon, clat)]), by = "nm")
cand[, `:=`(sec_emp = sector_of(lon - clon, lat - clat), sec_pos = sector_of(pos_lon - clon, pos_lat - clat))]
miss <- setdiff(unique(d$nm), unique(cand$nm))
msg("候选省份 / candidate pairs: ", nrow(cand), " | species without candidates: ", length(miss))

# ---- 3. 蒙特卡洛零假设 / Monte Carlo nulls ----
# 每条记录按其物种的候选省份抽样; 按物种批量抽样以提速
# NB: each record is redrawn among its species' candidate provinces
draw_counts <- function(recs, weight_col, sec_col) {
  out <- matrix(0L, R_MC, 8, dimnames = list(NULL, DIRLV))
  by_sp <- recs[, .N, by = nm]
  for (i in seq_len(nrow(by_sp))) {
    cs <- cand[nm == by_sp$nm[i]]
    w <- if (is.null(weight_col)) rep(1, nrow(cs)) else cs[[weight_col]]
    if (sum(w) <= 0) w <- rep(1, nrow(cs))
    idx <- matrix(sample.int(nrow(cs), R_MC * by_sp$N[i], replace = TRUE, prob = w), nrow = R_MC)
    sec <- as.integer(cs[[sec_col]])[idx]
    dim(sec) <- dim(idx)
    for (k in 1:8) out[, k] <- out[, k] + rowSums(sec == k)
  }
  out
}
mc_p <- function(sim, obs) {                           # 双侧蒙特卡洛 P / two-sided Monte Carlo P
  hi <- (1 + sum(sim >= obs)) / (length(sim) + 1); lo <- (1 + sum(sim <= obs)) / (length(sim) + 1)
  min(1, 2 * min(hi, lo))
}
run_scope <- function(recs, lab) {
  recs <- recs[nm %in% cand$nm]
  obs <- as.integer(table(recs$sec))
  res <- list(); summ <- list()
  for (nl in list(c("geometric", "", "sec_emp"), c("geometric_effort", "vis", "sec_emp"),
                  c("geometric_pos", "", "sec_pos"), c("geometric_effort_pos", "vis", "sec_pos"))) {
    sim <- draw_counts(recs, if (nl[2] == "") NULL else nl[2], nl[3])
    E <- colMeans(sim)
    x2 <- sum((obs - E)^2 / pmax(E, 1e-9)); x2s <- rowSums(sweep(sweep(sim, 2, E)^2, 2, pmax(E, 1e-9), "/"))
    p <- vapply(1:8, function(k) mc_p(sim[, k], obs[k]), numeric(1))
    res[[nl[1]]] <- data.table(scope = lab, null = nl[1], direction = DIRLV, observed = obs,
                               null_mean = E, null_lo = apply(sim, 2, quantile, 0.025),
                               null_hi = apply(sim, 2, quantile, 0.975), ratio = obs / E,
                               mc_p = p, mc_p_holm = p.adjust(p, "holm"))
    half <- function(v, s) sum(v[match(s, DIRLV)]) / sum(v)
    summ[[nl[1]]] <- data.table(scope = lab, null = nl[1], n = sum(obs), chisq_vs_null = x2,
                                mc_p = (1 + sum(x2s >= x2)) / (R_MC + 1),
                                obs_east3 = half(obs, c("Northeast", "East", "Southeast")),
                                null_east3 = half(E, c("Northeast", "East", "Southeast")),
                                obs_west3 = half(obs, c("Southwest", "West", "Northwest")),
                                null_west3 = half(E, c("Southwest", "West", "Northwest")),
                                obs_north3 = half(obs, c("Northwest", "North", "Northeast")),
                                null_north3 = half(E, c("Northwest", "North", "Northeast")),
                                obs_south3 = half(obs, c("Southeast", "South", "Southwest")),
                                null_south3 = half(E, c("Southeast", "South", "Southwest")))
  }
  list(rbindlist(res), rbindlist(summ))
}
scopes <- c(list(run_scope(d, "Overall (records)")),
            lapply(ORDERS5, function(o) run_scope(d[order == o], paste0(o, " (records)"))))
per_sector <- rbindlist(lapply(scopes, `[[`, 1)); omnibus <- rbindlist(lapply(scopes, `[[`, 2))
fwrite(per_sector, file.path(OUT, "tables", "tbl_v2_direction_geometric_null.csv"))
fwrite(omnibus, file.path(OUT, "tables", "tbl_v2_direction_geometric_null_summary.csv"))

# 供 SI 使用的精简表(两个主零假设)/ compact SI tables for the two main nulls
NL <- c(geometric = "Geometry", geometric_effort = "Geometry + effort")
si_sec <- per_sector[scope == "Overall (records)" & null %in% names(NL),
                     .(Null = NL[null], Sector = direction, Observed = observed,
                       Expected = sprintf("%.1f", null_mean),
                       `95% null interval` = sprintf("%.0f–%.0f", null_lo, null_hi),
                       `Obs./exp.` = sprintf("%.2f", ratio),
                       `P (Holm)` = ifelse(mc_p_holm < 0.001, "<0.001", sprintf("%.3f", mc_p_holm)))]
fwrite(si_sec, file.path(OUT, "tables", "tbl_v2_direction_null_si_sectors.csv"))
NL4 <- c(NL, geometric_pos = "Geometry (surface point)", geometric_effort_pos = "Geometry + effort (surface point)")
si_omni <- omnibus[null %in% names(NL4),
                   .(Scope = sub(" \\(records\\)", "", scope), Null = NL4[null], Records = n,
                     `χ² vs null` = sprintf("%.1f", chisq_vs_null),
                     `Monte Carlo P` = sprintf("%.3f", mc_p),
                     `East sectors obs./exp. (%)` = sprintf("%.1f / %.1f", 100 * obs_east3, 100 * null_east3),
                     `North sectors obs./exp. (%)` = sprintf("%.1f / %.1f", 100 * obs_north3, 100 * null_north3))]
fwrite(si_omni, file.path(OUT, "tables", "tbl_v2_direction_null_si_omnibus.csv"))

# ---- 4. 摘要 / summary ----
print(omnibus[, .(scope, null, n, chisq = round(chisq_vs_null, 1), mc_p = signif(mc_p, 3),
                  E_obs = round(100 * obs_east3, 1), E_null = round(100 * null_east3, 1),
                  N_obs = round(100 * obs_north3, 1), N_null = round(100 * null_north3, 1))])
print(per_sector[scope == "Overall (records)" & null %in% c("geometric", "geometric_effort"),
                 .(null, direction, observed, null_mean = round(null_mean, 1),
                   lo = null_lo, hi = null_hi, ratio = round(ratio, 2), p_holm = signif(mc_p_holm, 3))])
msg("DONE")
