#!/usr/bin/env Rscript
# ============================================================
# Scientific question / 科学问题:
#   2024 年分省调查努力为何骤降(云南 1,802 → 5 次访问, 广东 7,082 → 630)?修正后,
#   主模型的努力与增温效应、以及努力回报的时间趋势是否改变?
#   Why does 2024 provincial survey effort collapse (Yunnan 1,802 -> 5 visits, Guangdong
#   7,082 -> 630), and does correcting it change the main model or the trend in the return on effort?
#
# Root cause / 根因(2026-10-13 核查):
#   1. 源表 table_effort_year_province_source.csv 的 eBird/GBIF 部分只到 2023 年:
#      gbif_ebird_events_2000_2025.rds 虽名为 2000–2025, 实际 2,863,487 条止于 2023 年;
#      2024 年各省的"合并"努力因此只剩中国观鸟记录中心一个来源(云南几乎全靠 eBird)。
#   2. 中国观鸟记录中心 2024 年的广东数据只覆盖 14 个观鸟日(2023 年 364 天), 属抓取不全;
#      上海 153 天(2023 年 359 天), 疑似部分缺失。
#   1. The eBird/GBIF events behind the source table end in 2023, so 2024 "combined" effort is
#      China Bird Report only (Yunnan relies almost entirely on eBird).
#   2. China Bird Report covers only 14 birding days in Guangdong in 2024 (364 in 2023);
#      Shanghai 153 days (359), possibly partial.
#
# Objective / 分析目标:
#   用 2026-09 下载的 eBird 2024(GBIF 下载 0009241-260921141020460, doi:10.15468/dl.vfeeak)
#   按源表的同一口径补算 2024 年 eBird/GBIF 部分, 先以 2023 年精确复现作自检;再与中国观鸟
#   记录中心 2024 年合并, 写出修正后的努力面板与审计表。模型与正文不在本脚本中改动。
#   Recompute the missing 2024 eBird/GBIF component with the source table's definitions, after
#   checking that the same code reproduces 2023 exactly; combine with China Bird Report 2024 and
#   write a corrected effort panel and audit tables. Models and manuscripts are not changed here.
#
# Input data / 输入数据:
#   <occupancy>/data/derived/gbif_ebird_events_2000_2025.rds   eBird/GBIF 事件(止于 2023)
#   <occupancy>/data/derived/gbif_ebird_events_2024.rds        eBird 2024 事件(GBIF EOD 下载)
#   <occupancy>/results_v2/table_effort_year_province_source.csv 源表(分来源 × 省 × 年)
#   <occupancy>/data/中国shp/省.shp                            源表所用省界(同一空间连接)
#   analysis_rebuilt/data/effort_province_year_rebuilt.csv     脚本 81 的原始面板(131 的上游)
#
# Main workflow / 主要流程:
#   1. 自检: 同一函数重算 2023 年 eBird/GBIF 分省访问数、观察者数、观鸟日, 须与源表完全一致
#   2. 补算 2024 年 eBird 部分;核对两来源访问数与观察者数可加(2002–2023 合并 = 两源之和)
#   3. 观鸟日取并集:以 2023 年真实并集检验"独立重叠"近似的误差
#   4. 2024 合并努力 = 中国观鸟记录中心 + eBird;中国观鸟记录中心观鸟日不足上一年一半者标为截断
#   5. 写出审计表(含下载缺口判定)与验证表;修正由 131 读入后完成
#   1. self-test on 2023; 2. 2024 eBird component and an additivity check; 3. union of birding days,
#   approximation checked on 2023; 4. combined 2024 effort, truncated China Bird Report flagged;
#   5. audit table (with the download-gap rule) and validation table; script 131 applies the correction
#
# Expected output / 预期输出:
#   analysis_v2/tables/tbl_effort_2024_audit.csv(供 131 读取 / read by script 131), tbl_effort_2024_validation.csv
#
# Key assumptions / 关键假设:
#   访问 = 观察者 × 日期的唯一组合(源表定义);两平台用户名不重合, 2023 年已核实可加。
#   广东 2024 年中国观鸟记录中心部分只覆盖 14 天, 合并值仍明显偏低, 主修正口径将其按覆盖缺口处理。
#   A visit is a unique observer-day (source definition); usernames do not overlap across the two
#   platforms (additivity verified for 2002–2023). Guangdong 2024 stays a coverage gap in the main
#   corrected version because its China Bird Report part covers 14 days.
#
# Main packages / 主要包: data.table, sf
# Output directory / 输出路径: analysis_v2/data/, analysis_v2/tables/
# Run / 运行: Rscript --no-init-file code/222_effort_2024_ebird_fill.R   (cwd = task root)
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(sf) })
options(warn = 1)

V2  <- normalizePath(".", mustWork = TRUE)
OUT <- file.path(V2, "analysis_v2")
OCC <- "/Users/dingchenchen/Documents/New project/bird_dynamic_occupancy_analysis"
msg <- function(...) cat(sprintf("[222 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")
source(file.path(OCC, "code_v2", "utils_spatial.R"))
source(file.path(OCC, "code_v2", "utils_mapping.R"))      # strip_nansha_inset()

# 省名中 → 英, 与 81/131 一致 / Chinese -> English province names, as in scripts 81 and 131
PROV_CN_EN <- c("北京市"="Beijing","天津市"="Tianjin","河北省"="Hebei","山西省"="Shanxi",
  "内蒙古自治区"="Inner Mongolia","辽宁省"="Liaoning","吉林省"="Jilin","黑龙江省"="Heilongjiang",
  "上海市"="Shanghai","江苏省"="Jiangsu","浙江省"="Zhejiang","安徽省"="Anhui","福建省"="Fujian",
  "江西省"="Jiangxi","山东省"="Shandong","河南省"="Henan","湖北省"="Hubei","湖南省"="Hunan",
  "广东省"="Guangdong","广西壮族自治区"="Guangxi","海南省"="Hainan","重庆市"="Chongqing",
  "四川省"="Sichuan","贵州省"="Guizhou","云南省"="Yunnan","西藏自治区"="Tibet","陕西省"="Shaanxi",
  "甘肃省"="Gansu","青海省"="Qinghai","宁夏回族自治区"="Ningxia","新疆维吾尔自治区"="Xinjiang",
  "台湾省"="Taiwan","香港特别行政区"="Hong Kong","澳门特别行政区"="Macao")

# ---------- 源表定义的努力指标(与 02f 逐行一致)/ effort metrics exactly as in script 02f ----------
# 省界须在 s2 开启时修复(同 02f);只在点面连接时关闭 s2。若全程关闭 s2, st_make_valid 会按平面几何
# 修复, 多个沿海与内陆省份的多边形出错, 2023 年自检随即失败(已核实)。
# Repair the polygons with s2 on, as script 02f does, and switch s2 off only for the point join; with s2
# off throughout, st_make_valid repairs in planar geometry and several provinces break (the 2023 self-test fails).
prov_sf <- suppressWarnings(sf::st_read(file.path(OCC, "data", "中国shp", "省.shp"), quiet = TRUE)) |>
  sf::st_make_valid() |> sf::st_transform(4326)
prov_sf <- strip_nansha_inset(prov_sf)

effort_metrics <- function(ev) {
  old <- sf::sf_use_s2(FALSE); on.exit(sf::sf_use_s2(old), add = TRUE)
  pts <- sf::st_as_sf(ev[, .(longitude, latitude)], coords = c("longitude", "latitude"), crs = 4326)
  j <- sf::st_join(pts, prov_sf[, c("省名")], join = sf::st_intersects, left = TRUE)
  stopifnot(nrow(j) == nrow(ev))                     # 边界点不得重复匹配 / no duplicated matches
  ev[, prov_cn := j$省名]
  ev[, `:=`(day_key = sprintf("%04d-%02d-%02d", year, month, day),
            observer_key = tolower(fcoalesce(username, "anon")))]
  ev[, visit_key := paste(observer_key, day_key, sep = "|")]
  ev[!is.na(prov_cn), .(n_records = .N, n_visits = uniqueN(visit_key), n_observers = uniqueN(observer_key),
                        n_birding_days = uniqueN(day_key), days = list(unique(day_key))), by = .(year, prov_cn)]
}

src <- fread(file.path(OCC, "results_v2", "table_effort_year_province_source.csv"), encoding = "UTF-8")

# =====================================================================
# 1. 自检: 2023 年精确复现 / self-test: exact reproduction of 2023
# =====================================================================
g <- as.data.table(readRDS(file.path(OCC, "data", "derived", "gbif_ebird_events_2000_2025.rds")))
yr_cov <- g[, .N, by = year][order(year)]
msg("eBird/GBIF 事件 / events: ", format(nrow(g), big.mark = ","), " 条, 年份 ", min(yr_cov$year), "–", max(yr_cov$year))
m23 <- effort_metrics(g[year == 2023])
rm(g); invisible(gc())
s23 <- src[year == 2023 & source_short == "eBird_GBIF", .(prov_cn = province, t_visits = n_visits,
                                                           t_observers = n_observers, t_days = n_birding_days)]
chk <- merge(m23[, .(prov_cn, n_visits, n_observers, n_birding_days)], s23, by = "prov_cn", all = TRUE)
ok23 <- with(chk, all(n_visits == t_visits & n_observers == t_observers & n_birding_days == t_days, na.rm = FALSE))
msg("2023 自检 / self-test: ", nrow(chk), " 省, 访问/观察者/观鸟日完全一致 = ", ok23)
if (!isTRUE(ok23)) {
  print(chk[!(n_visits %in% t_visits & n_observers %in% t_observers & n_birding_days %in% t_days) |
            is.na(n_visits) | is.na(t_visits)])
  stop("2023 年未能精确复现源表, 停止 / 2023 not reproduced exactly; aborting")
}

# =====================================================================
# 2. 2024 年 eBird 部分 + 两来源可加性 / 2024 eBird component and additivity
# =====================================================================
e24 <- as.data.table(readRDS(file.path(OCC, "data", "derived", "gbif_ebird_events_2024.rds")))
m24 <- effort_metrics(e24)
msg("eBird 2024: ", format(nrow(e24), big.mark = ","), " 条 → ", nrow(m24), " 省, 访问 ",
    format(sum(m24$n_visits), big.mark = ","), "(2023 年 eBird/GBIF 访问 ", format(sum(m23$n_visits), big.mark = ","), ")")
rm(e24); invisible(gc())

w <- dcast(src[year <= 2023], year + province ~ source_short, value.var = c("n_visits", "n_observers"), fill = 0)
add_v <- w[, all(n_visits_Combined == n_visits_China_Birdwatch + n_visits_eBird_GBIF)]
add_o <- w[, all(n_observers_Combined == n_observers_China_Birdwatch + n_observers_eBird_GBIF)]
msg("可加性 / additivity 2002–2023: 访问 ", add_v, ", 观察者 ", add_o)
if (!(add_v && add_o)) stop("两来源不可加, 停止 / sources are not additive; aborting")

# =====================================================================
# 3. 观鸟日并集的近似 / union of birding days, approximation checked on 2023
# =====================================================================
# 只有 eBird 的逐日集合;中国观鸟记录中心只有天数。按独立重叠近似:
#   并集 ≈ d_e + d_c − d_e d_c / N(N = 当年天数), 以 2023 年源表的真实并集检验误差
# eBird day sets are available, China Bird Report only as counts; union ≈ d_e + d_c − d_e d_c / N,
# checked against the true 2023 union in the source table
ndays <- function(y) ifelse((y %% 4 == 0 & y %% 100 != 0) | y %% 400 == 0, 366, 365)
uni <- function(de, dc, y) pmin(ndays(y), round(de + dc - de * dc / ndays(y)))
wd <- dcast(src[year == 2023], province ~ source_short, value.var = "n_birding_days", fill = 0)
wd[, approx := uni(eBird_GBIF, China_Birdwatch, 2023)]
day_err <- wd[, .(mae = mean(abs(approx - Combined)), max_abs = max(abs(approx - Combined)))]
msg("观鸟日并集近似 / union approximation, 2023: MAE ", round(day_err$mae, 1), " 天, 最大 ", day_err$max_abs, " 天")

# =====================================================================
# 4. 2024 年合并努力与截断标记 / combined 2024 effort and truncation flags
# =====================================================================
c24 <- src[year == 2024 & source_short == "China_Birdwatch", .(prov_cn = province, cbr_records = n_records,
           cbr_visits = n_visits, cbr_observers = n_observers, cbr_days = n_birding_days)]
c23 <- src[year == 2023 & source_short == "China_Birdwatch", .(prov_cn = province, cbr_days_2023 = n_birding_days,
           cbr_visits_2023 = n_visits)]
a <- Reduce(function(x, y) merge(x, y, by = "prov_cn", all = TRUE),
            list(c24, c23, m24[, .(prov_cn, eb_records = n_records, eb_visits = n_visits, eb_observers = n_observers,
                                   eb_days = n_birding_days)]))
for (v in c("cbr_records", "cbr_visits", "cbr_observers", "cbr_days", "eb_records", "eb_visits", "eb_observers", "eb_days"))
  set(a, which(is.na(a[[v]])), v, 0L)
a[, `:=`(province = unname(PROV_CN_EN[prov_cn]),
         visits_fix = cbr_visits + eb_visits, observers_fix = cbr_observers + eb_observers,
         days_fix = uni(eb_days, cbr_days, 2024), records_fix = cbr_records + eb_records)]
# 截断: 中国观鸟记录中心 2024 年观鸟日不足 2023 年的一半(且 2023 年 ≥ 100 天)
# truncated: China Bird Report days in 2024 below half of 2023 (with >= 100 days in 2023)
a[, cbr_truncated := !is.na(cbr_days_2023) & cbr_days_2023 >= 100 & cbr_days < 0.5 * cbr_days_2023]
msg("中国观鸟记录中心 2024 截断 / truncated: ", paste(a[cbr_truncated == TRUE,
    sprintf("%s(%d/%d 天)", province, cbr_days, cbr_days_2023)], collapse = ", "))

# =====================================================================
# 5. 审计表与验证表 / audit and validation tables
# =====================================================================
# 只读 81 的原始面板(131 的上游), 不读 131 的输出, 避免循环依赖;131 再读本脚本的审计表完成修正
# Reads the raw panel of script 81 (upstream of 131), never 131's output, to avoid a cycle;
# script 131 then applies the correction from this audit table
r <- fread(file.path(V2, "analysis_rebuilt", "data", "effort_province_year_rebuilt.csv"))
r[province == "Macau", province := "Macao"]
aud <- merge(a[, .(province, cbr_visits_2023, cbr_visits, cbr_days_2023, cbr_days, cbr_truncated, eb_visits,
                   visits_fix, observers_fix, days_fix)],
             r[year == 2023, .(province, visits_2023 = n_visits)], by = "province", all.x = TRUE)
aud <- merge(aud, r[year == 2024, .(province, visits_2024_orig = n_visits, effort_status, in_scope, mainland)],
             by = "province", all.x = TRUE)
# 下载缺口: 中国观鸟记录中心截断, 且补入 eBird 后仍低于上一年(全国其余省份 2024 年增长 1.6–6 倍)
# download gap: China Bird Report truncated and, even with eBird added, below the previous year
aud[, download_gap := cbr_truncated & !is.na(visits_2023) & visits_fix < visits_2023]
aud[, ratio_fix_2023 := round(visits_fix / visits_2023, 2)]
msg("下载缺口 / download gaps 2024: ", paste(aud[download_gap == TRUE, province], collapse = ", "),
    " | 截断但保留 / truncated but kept: ", paste(aud[cbr_truncated & !download_gap, province], collapse = ", "))
fwrite(aud[order(-visits_fix)], file.path(OUT, "tables", "tbl_effort_2024_audit.csv"))

# 全国大陆访问量(描述性)/ national mainland visits (descriptive)
obs <- r[mainland %in% c(TRUE, "TRUE") & effort_status == "observed", .(province, year, visits_orig = n_visits)]
obs <- merge(obs, aud[, .(province, year = 2024L, visits_fix, download_gap)], by = c("province", "year"), all.x = TRUE)
obs[, visits_new := fifelse(year == 2024L & !is.na(visits_fix), visits_fix, visits_orig)]
nat <- obs[, .(visits_orig = sum(visits_orig), visits_fix_all = sum(visits_new),
               visits_fix_panel = sum(visits_new[!(download_gap %in% TRUE)])), by = year][order(year)]
fold <- function(v) mean(v[nat$year %in% 2022:2024]) / mean(v[nat$year %in% 2002:2004])
val <- data.table(
  check = c("eBird/GBIF events: last year", "2023 self-test (visits, observers, days identical)",
            "Additivity of visits and observers, 2002-2023", "Union-of-days approximation, 2023 MAE (days)",
            "Union-of-days approximation, 2023 max abs error (days)",
            "National mainland visits 2024, original", "National mainland visits 2024, corrected (all provinces)",
            "National mainland visits 2024, corrected (panel; download gaps excluded)",
            "Fold change 2002-04 to 2022-24, original", "Fold change 2002-04 to 2022-24, corrected (all provinces)",
            "Fold change 2002-04 to 2022-24, corrected (panel)"),
  value = c(max(yr_cov$year), ok23, add_v && add_o, round(day_err$mae, 2), day_err$max_abs,
            nat[year == 2024, visits_orig], nat[year == 2024, visits_fix_all], nat[year == 2024, visits_fix_panel],
            round(fold(nat$visits_orig), 1), round(fold(nat$visits_fix_all), 1), round(fold(nat$visits_fix_panel), 1)))
fwrite(val, file.path(OUT, "tables", "tbl_effort_2024_validation.csv"))
print(val)
print(aud[order(ratio_fix_2023)][1:6, .(province, visits_2023, visits_2024_orig, cbr_visits, eb_visits, visits_fix,
                                         ratio_fix_2023, cbr_days, download_gap)])
msg("DONE")
