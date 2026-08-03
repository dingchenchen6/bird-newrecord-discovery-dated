# ============================================================
# Scientific question / 科学问题:
# 已建成的自然保护区网络,坐落在增温快的地方还是慢的地方?
# 在不新增保护地边界的前提下,应该优先把标准化鸟类监测嫁接到哪些
# 已建保护区里,又有哪些高暴露区域根本不在保护体系内?
# Does the existing reserve network sit where warming is fast or slow, and
# where should monitoring be grafted onto existing reserves first?
#
# Objective / 分析目标:
# 响应变量是保护地覆盖度本身(不含任何观测过程),因此不受观鸟偏倚污染;
# 观测轴改用真实的 GBIF/eBird 观鸟点位密度,而非省级努力广播值。
# 输出「监测嫁接优先级」而非「保护空缺」——图层完整度只有名录的约 30%,
# 不足以支持任何新建保护地的建议。
#
# Input data / 输入数据:
#   analysis_v2/data/pa/pa_grid50_coverage_static.csv   格 × 保护地覆盖度(并集求交)
#   analysis_v2/data/pa/cc_birding_locations.csv        观鸟点位 × 年(真实观测密度)
#   data/raw/grid_50km_climate.csv                      格 × 实测气候与增温速率
#   data/raw/grid_50km_base.csv                         格阵中心
#
# Main workflow / 主要流程:
#   1. 合并格级面板:保护地覆盖 × 实测增温 × 真实观鸟密度
#   2. 增温五分位下的面积加权保护地覆盖率(错配的量级)
#   3. 分数响应回归:含省固定效应与不含两版(省内 vs 省间错配)
#   4. 省 × 海拔带分层置换零模型(排除"保护区在西部高地"这一平凡解释)
#   5. 三象限产品:高增温 × 低观测 × 区内 / 区外
#
# Expected output / 预期输出:
#   analysis_v2/tables/tbl_pa_c3_warming_quintiles.csv
#   analysis_v2/tables/tbl_pa_c3_fracreg.csv
#   analysis_v2/tables/tbl_pa_c3_permutation.csv
#   analysis_v2/tables/tbl_pa_c3_priority_cells.csv
#   analysis_v2/data/pa/c3_grid_panel.csv
#
# Key assumptions / 关键假设:
#   - 只对 1028 处已制图、以国家级为主、2012 年前建立的自然保护区下结论。
#   - 覆盖度用保护区并集求交,不做面积相加(要素间重叠 7.0%)。
#   - 不做任何未来情景投影:已冻结的支撑域结论表明 2050 年仅 10% 的
#     物种-省组合可外推,外推区不具备规划可用性。
#   - 观测轴取 2019-2023 年近期观鸟点位密度,代表当前监测覆盖状态。
#   - 全文不使用"保护空缺"一词,不给出新建保护地建议。
#
# Main packages / 主要包: data.table, sf
# Output directory / 输出路径: analysis_v2/tables/, analysis_v2/data/pa/
# ============================================================

suppressPackageStartupMessages({library(data.table); library(sf)})
set.seed(20260803)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_PA <- file.path(V2, "analysis_v2/data/pa")
D_TB <- file.path(V2, "analysis_v2/tables")
AEA  <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
CELL_M <- 50000
msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

# ------------------------------------------------------------
# 1. 格级面板
# ------------------------------------------------------------
msg("合并格级面板 / assembling the grid panel")
cov <- fread(file.path(D_PA, "pa_grid50_coverage_static.csv"))
clim <- fread(file.path(V2, "data/raw/grid_50km_climate.csv"))
gb <- fread(file.path(V2, "data/raw/grid_50km_base.csv"))
gxy <- sf_project("EPSG:4326", AEA, as.matrix(gb[, .(centroid_lon, centroid_lat)]))
gb[, `:=`(ax = gxy[, 1], ay = gxy[, 2])]
x0 <- min(gb$ax) - CELL_M / 2; y0 <- min(gb$ay) - CELL_M / 2

# 观鸟点位落格 / assign birding locations to cells
locs <- fread(file.path(D_PA, "cc_birding_locations.csv"))
lxy <- sf_project("EPSG:4326", AEA, as.matrix(locs[, .(lon_r, lat_r)]))
gb_key <- paste(floor((gb$ax - x0) / CELL_M), floor((gb$ay - y0) / CELL_M), sep = "_")
lk <- paste(floor((lxy[, 1] - x0) / CELL_M), floor((lxy[, 2] - y0) / CELL_M), sep = "_")
locs[, grid_cell := gb$grid_id[match(lk, gb_key)]]

obs_all <- locs[!is.na(grid_cell), .(n_cl_all = sum(n_checklist), n_loc_all = uniqueN(paste(lon_r, lat_r))),
                by = .(grid_id = grid_cell)]
obs_rec <- locs[!is.na(grid_cell) & year >= 2019,
                .(n_cl_recent = sum(n_checklist), n_loc_recent = uniqueN(paste(lon_r, lat_r))),
                by = .(grid_id = grid_cell)]

# grid_50km_climate.csv 的 warming_rate / climate_velocity / climate_exposure
# 只有 31 个唯一值,是省级值向格广播的结果,不能用于省内比较;
# 改用脚本 165 由 CRU TS 4.09 重算的真正格级增温。
# The warming columns in the grid file are province-level broadcasts; use the
# genuine cell-level warming recomputed from CRU TS 4.09 (script 165).
warm <- fread(file.path(D_PA, "grid50_warming_cru.csv"))
stopifnot(uniqueN(round(warm$warm_trend_dec, 4)) > 100)   # 断言:确为格级
p <- merge(cov[, .(grid_id, province, cell_km2, pa_all, pa_national,
                   frac_pa_all, frac_pa_national)],
           clim[, .(grid_id, bio1, bio12, elev)],
           by = "grid_id")
p <- merge(p, warm[, .(grid_id, warming_rate = warm_trend_dec, warm_delta_c)],
           by = "grid_id")
p <- merge(p, gb[, .(grid_id, centroid_lon, centroid_lat)], by = "grid_id")
p <- merge(p, obs_all, by = "grid_id", all.x = TRUE)
p <- merge(p, obs_rec, by = "grid_id", all.x = TRUE)
for (cl in c("n_cl_all", "n_loc_all", "n_cl_recent", "n_loc_recent"))
  set(p, which(is.na(p[[cl]])), cl, 0L)
p <- p[is.finite(warming_rate) & is.finite(elev)]
msg("面板 ", nrow(p), " 格;有观鸟记录的格 ", sum(p$n_cl_all > 0),
    sprintf(" (%.1f%%)", 100 * mean(p$n_cl_all > 0)))

# ------------------------------------------------------------
# 2. 增温五分位下的保护地覆盖率
# ------------------------------------------------------------
msg("增温五分位 × 保护地覆盖率")
p[, wq := cut(warming_rate, breaks = quantile(warming_rate, seq(0, 1, .2)),
              include.lowest = TRUE, labels = paste0("Q", 1:5))]
wq <- p[, .(n_cell = .N,
            warming_med = round(median(warming_rate), 4),
            elev_med = round(median(elev)),
            pa_cover = round(sum(pa_all) / sum(cell_km2), 4),
            cl_per_cell = round(sum(n_cl_all) / .N, 1),
            pct_cells_no_birding = round(100 * mean(n_cl_all == 0), 1)), by = wq][order(wq)]
fwrite(wq, file.path(D_TB, "tbl_pa_c3_warming_quintiles.csv"))
cat("\n== 增温五分位(Q1 最慢 - Q5 最快)==\n"); print(wq)
msg(sprintf("最快增温五分位覆盖率 %.3f vs 最慢 %.3f,相差 %.1f 倍",
            wq$pa_cover[5], wq$pa_cover[1], wq$pa_cover[1] / max(wq$pa_cover[5], 1e-6)))

# ------------------------------------------------------------
# 3. 分数响应回归:错配发生在省间还是省内
# ------------------------------------------------------------
msg("分数响应回归 / fractional logit")
zs <- function(x) as.numeric(scale(x))
p[, `:=`(w_z = zs(warming_rate), elev_z = zs(elev), bio1_z = zs(bio1),
         bio12_z = zs(bio12), lon_z = zs(centroid_lon), y = frac_pa_all)]
p[y <= 0, y := 1e-6]; p[y >= 1, y := 1 - 1e-6]

fit_frac <- function(form, lab) {
  f <- glm(as.formula(form), data = p, family = quasibinomial("logit"), weights = cell_km2)
  s <- summary(f)$coefficients
  keep <- intersect(rownames(s), c("w_z", "elev_z", "lon_z", "bio1_z", "bio12_z"))
  data.table(model = lab, term = keep, beta = s[keep, 1], se = s[keep, 2],
             P = s[keep, 4],
             lo = s[keep, 1] - 1.96 * s[keep, 2], hi = s[keep, 1] + 1.96 * s[keep, 2])
}
fr <- rbindlist(list(
  fit_frac("y ~ w_z", "M1 仅增温"),
  fit_frac("y ~ w_z + elev_z", "M2 +海拔"),
  fit_frac("y ~ w_z + elev_z + bio1_z + bio12_z + lon_z", "M3 +气候与经度")
))
# M4 省内版:全省固定效应在配额型响应下不稳定(部分省覆盖度近乎恒定),
# 改用省内去均值的增温与覆盖度,估计的是纯粹的省内配置关联。
# Full province fixed effects are unstable here; use within-province demeaning.
p[, w_dm := w_z - mean(w_z), by = province]
p[, y_dm := qlogis(y) - mean(qlogis(y)), by = province]
stopifnot(sd(p$w_dm) > 0)          # 去均值必须真的分了组 / demeaning must actually group
m4 <- lm(y_dm ~ w_dm, data = p, weights = cell_km2)
s4 <- summary(m4)$coefficients
fr <- rbind(fr, data.table(model = "M4 省内去均值", term = "w_z",
                           beta = s4["w_dm", 1], se = s4["w_dm", 2], P = s4["w_dm", 4],
                           lo = s4["w_dm", 1] - 1.96 * s4["w_dm", 2],
                           hi = s4["w_dm", 1] + 1.96 * s4["w_dm", 2]))
fwrite(fr, file.path(D_TB, "tbl_pa_c3_fracreg.csv"))
cat("\n== 保护地覆盖度 ~ 增温速率(面积加权分数 logit)==\n")
print(fr[term == "w_z", .(model, beta = round(beta, 3),
                          CI = sprintf("%.2f-%.2f", lo, hi), P = signif(P, 3))])

# ------------------------------------------------------------
# 4. 省 × 海拔带分层置换零模型
# ------------------------------------------------------------
# 平凡解释:保护区建在西部高地,而高地增温慢。分层置换把这一解释固定住:
# 在同省同海拔带内重排保护地覆盖度,看增温关联是否仍然存在。
# Trivial explanation: reserves sit on western highlands where warming is slow.
# Permuting coverage within province x elevation band holds that fixed.
msg("分层置换零模型 / stratified permutation (999x)")
p[, elev_band := cut(elev, breaks = c(-Inf, 200, 500, 1000, 2000, 3500, Inf),
                     labels = c("b1", "b2", "b3", "b4", "b5", "b6"))]
p[, stratum := paste(province, elev_band, sep = "|")]
obs_stat <- p[, cor(frac_pa_all, warming_rate, method = "spearman")]
# 分层内加权相关的观测值 / observed within-stratum pooled correlation
strat_cor <- function(v) {
  d <- copy(p); d[, fp := v]
  z <- d[, .(r = if (.N >= 10 && sd(fp) > 0 && sd(warming_rate) > 0)
                   suppressWarnings(cor(fp, warming_rate, method = "spearman")) else NA_real_,
             n = .N), by = stratum][is.finite(r)]
  if (!nrow(z)) return(NA_real_)
  weighted.mean(z$r, z$n)
}
obs_within <- strat_cor(p$frac_pa_all)
# 层内重排必须真的发生:用 data.table 分组而非 ave(),后者在此处不分组
# the shuffle must actually happen within strata; ave() silently failed to group here
shuffle_within <- function() {
  d <- p[, .(grid_id, stratum, frac_pa_all)]
  d[, v := sample(frac_pa_all), by = stratum]
  d$v[match(p$grid_id, d$grid_id)]
}
v_test <- shuffle_within()
stopifnot(!identical(v_test, p$frac_pa_all))
perm <- numeric(999)
for (i in seq_len(999)) {
  perm[i] <- strat_cor(shuffle_within())
  if (i %% 200 == 0) msg("  置换 ", i, " / 999")
}
n_perm_ok <- sum(is.finite(perm)); perm <- perm[is.finite(perm)]
pv <- (sum(abs(perm) >= abs(obs_within)) + 1) / (length(perm) + 1)
msg("有效置换 ", n_perm_ok, " / 999")
pt <- data.table(observed_global_rho = obs_stat, observed_within_stratum_rho = obs_within,
                 perm_mean = mean(perm), perm_sd = sd(perm),
                 perm_lo = quantile(perm, .025), perm_hi = quantile(perm, .975),
                 P_perm = pv, n_perm = length(perm))
fwrite(pt, file.path(D_TB, "tbl_pa_c3_permutation.csv"))
cat("\n== 分层置换检验 ==\n"); print(pt)

# ------------------------------------------------------------
# 5. 三象限产品:监测嫁接优先级
# ------------------------------------------------------------
msg("监测嫁接优先级 / monitoring grafting priority")
p[, `:=`(hi_warm = warming_rate >= quantile(warming_rate, 2/3),
         lo_obs  = n_cl_recent <= quantile(n_cl_recent, 1/3),
         in_pa_cell = frac_pa_all > 0.05)]
p[, priority := fifelse(hi_warm & lo_obs & in_pa_cell, "A 嫁接到已建保护区",
                 fifelse(hi_warm & lo_obs & !in_pa_cell, "B 保护体系外,需另投调查",
                 fifelse(hi_warm & !lo_obs, "C 高暴露但已有观测", "D 其他")))]
pri <- p[, .(n_cell = .N, area_km2 = as.numeric(round(sum(cell_km2))),
             warming_med = round(median(warming_rate), 4),
             cl_recent_med = as.numeric(median(n_cl_recent)),
             pa_cover = round(sum(pa_all) / sum(cell_km2), 3)), by = priority][order(priority)]
fwrite(pri, file.path(D_TB, "tbl_pa_c3_priority_quadrants.csv"))
cat("\n== 监测嫁接优先级象限 ==\n"); print(pri)

cellA <- p[priority == "A 嫁接到已建保护区"][order(-warming_rate)]
fwrite(cellA[, .(grid_id, province, centroid_lon, centroid_lat, warming_rate,
                 frac_pa_all, frac_pa_national, n_cl_recent, elev)],
       file.path(D_TB, "tbl_pa_c3_priority_cells.csv"))
cat("\n== A 类格按省分布(前 10 省)==\n")
print(head(cellA[, .(n_cell = .N, area_km2 = round(sum(cell_km2))), by = province][order(-n_cell)], 10))

# 切点敏感性 / sensitivity to cut points
sens <- rbindlist(lapply(list(c(2/3, 1/3), c(3/4, 1/4), c(0.5, 0.5)), function(q) {
  hw <- p$warming_rate >= quantile(p$warming_rate, q[1])
  lo <- p$n_cl_recent <= quantile(p$n_cl_recent, q[2])
  data.table(cut_warm = q[1], cut_obs = q[2],
             nA = sum(hw & lo & p$in_pa_cell), nB = sum(hw & lo & !p$in_pa_cell))
}))
cat("\n== 切点敏感性 ==\n"); print(sens)

fwrite(p, file.path(D_PA, "c3_grid_panel.csv"))
msg("完成 / done")
