# ============================================================
# Scientific question / 科学问题:
# 把省级新纪录风险与省内分配模型相乘,得到县级「下一条新纪录最可能落在哪里」
# 的面,并说明这个面能外推到什么时候为止。
# Multiply the frozen province-level hazard by the within-province allocation
# to obtain a county-level surface, and state how far it can be projected.
#
# Objective / 分析目标:
#   1. 对每个省,把仍在风险集内的候选物种的分配概率聚合成县级期望份额
#   2. 与省级未来投影相乘,给出 2030 年 SSP2-4.5 的相对变化面(受支撑域约束)
#   3. 明确报告限制外推的是省级那一段,不是县级这一段
#
# Input data / 输入数据:
#   analysis_v2/data/admin/alloc_fit_{county,prefecture}.rds  分配模型
#   analysis_v2/data/admin/units_{lv}.csv, effort_unit_year_{lv}.csv,
#                          dist_species_unit_{lv}.csv
#   analysis_v2/data/model_v2_thr50.parquet     省级风险集(确定候选物种)
#   analysis_v2/tables/tbl_v2_future_province_projection.csv  省级投影
#   analysis_v2/tables/tbl_v2_future_support.csv              支撑域比例
#
# Expected output / 预期输出:
#   analysis_v2/data/admin/county_surface_now.csv
#   analysis_v2/data/admin/prefecture_surface_now.csv
#   analysis_v2/tables/tbl_county_surface_top50.csv
#
# Key assumptions / 关键假设:
#   - 候选物种 = 截至 2024 年仍在该省风险集内(尚未被记录)的物种。
#   - 分配概率对候选物种取等权平均:省级模型只给出该省当年发生一条新纪录的
#     风险,不区分是哪个物种,因此聚合时不引入物种权重。物种加权版作为敏感性。
#   - 观鸟努力用截至 2023 年的累计 checklist 数(观测层止于 2023)。
#   - 分布区距离为 BirdLife 当代分布,不随情景变化;因此本面刻画的是
#     「在当前分布格局与当前观测格局下」的落点概率。
#   - 2050 年及以后不出面:省级支撑域内组合仅剩 10.4%(SSP2-4.5),
#     限制来自省级那一段,与县级分配无关。
#
# Main packages / 主要包: survival, data.table, arrow
# Output directory / 输出路径: analysis_v2/data/admin/, analysis_v2/tables/
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(survival)
})

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_AD <- file.path(V2, "analysis_v2/data/admin")
D_TB <- file.path(V2, "analysis_v2/tables")
msg  <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

REF_YEAR <- 2023        # 观测层最后一年 / last year of the checklist layer

# 候选物种:截至窗口末仍未在该省被记录 / species still at risk in 2024
mv <- as.data.table(read_parquet(file.path(V2, "analysis_v2/data/model_v2_thr50.parquet")))
cand <- unique(mv[year == max(year) & event == 0L, .(species, province)])
msg("候选物种-省对 ", nrow(cand), ";涉及物种 ", uniqueN(cand$species))

for (lv in c("prefecture", "county")) {
  msg("================ ", lv, " ================")
  ud  <- fread(file.path(D_AD, sprintf("units_%s.csv", lv)))
  eff <- fread(file.path(D_AD, sprintf("effort_unit_year_%s.csv", lv)))
  dst <- fread(file.path(D_AD, sprintf("dist_species_unit_%s.csv", lv)))
  fit <- readRDS(file.path(D_AD, sprintf("alloc_fit_%s.rds", lv)))

  cum <- eff[year <= REF_YEAR, .(cum_cl = sum(n_checklist)), by = unit_id]
  ud <- merge(ud, cum, by = "unit_id", all.x = TRUE)
  ud[is.na(cum_cl), cum_cl := 0L]
  ud <- ud[!is.na(province) & is.finite(bio1) & is.finite(bio12) & is.finite(elev)]

  # 只对同时有分配模型协变量与分布区距离的候选组合打分
  cd <- cand[species %in% unique(dst$species)]
  msg("可打分的候选物种-省对 ", nrow(cd))

  # 逐省聚合:对该省候选物种取等权平均的分配概率
  # aggregate over candidate species, equally weighted
  b <- coef(fit)
  scale_ref <- as.data.table(read_parquet(file.path(D_AD, sprintf("altset_%s.parquet", lv))))
  scale_ref[, `:=`(log_area = log(area_km2), log_eff = log1p(cum_cl),
                   log_dist = log1p(dist_range_km))]
  mu <- list(); sdv <- list()
  for (v in c("log_area", "log_eff", "log_dist", "elev", "bio1", "bio12", "frac_pa")) {
    mu[[v]] <- mean(scale_ref[[v]], na.rm = TRUE); sdv[[v]] <- sd(scale_ref[[v]], na.rm = TRUE)
  }
  zz <- function(x, v) (x - mu[[v]]) / sdv[[v]]

  out <- rbindlist(lapply(unique(cd$province), function(p) {
    u <- ud[province == p]
    if (!nrow(u)) return(NULL)
    sp <- cd[province == p]$species
    if (!length(sp)) return(NULL)
    d <- dst[species %in% sp & unit_id %in% u$unit_id]
    if (!nrow(d)) return(NULL)
    d <- merge(d, u[, .(unit_id, area_km2, cum_cl, elev, bio1, bio12, frac_pa)], by = "unit_id")
    lp <- b["log_area_z"] * zz(log(d$area_km2), "log_area") +
          b["log_eff_z"]  * zz(log1p(d$cum_cl), "log_eff") +
          b["log_dist_z"] * zz(log1p(d$dist_range_km), "log_dist") +
          b["in_range"]   * as.integer(d$dist_range_km == 0) +
          b["elev_z"]     * zz(d$elev, "elev") +
          b["bio1_z"]     * zz(d$bio1, "bio1") +
          b["bio12_z"]    * zz(d$bio12, "bio12") +
          b["frac_pa_z"]  * zz(d$frac_pa, "frac_pa")
    d[, lp := lp]
    d[, pr := exp(lp) / sum(exp(lp)), by = species]     # 每个物种在省内归一
    agg <- d[, .(share = mean(pr), n_species = uniqueN(species)), by = unit_id]
    agg[, `:=`(province = p, share = share / sum(share))]
    agg
  }))
  out <- merge(out, ud[, .(unit_id, unit_nm, prov_cn, area_km2, cum_cl, frac_pa)], by = "unit_id")
  out[, `:=`(rank_in_prov = frank(-share), n_unit_prov = .N), by = province]
  setorder(out, province, -share)
  fwrite(out, file.path(D_AD, sprintf("%s_surface_now.csv", lv)))
  msg(sprintf("%s 面:%d 个单元;份额最高的单元占其省的 %.1f%%(中位)",
              lv, nrow(out), 100 * median(out[rank_in_prov == 1]$share)))

  if (lv == "county") {
    top <- head(out[order(-share)], 50)
    fwrite(top[, .(province, prov_cn, unit_id, unit_nm, share = round(share, 4),
                   rank_in_prov, n_unit_prov, cum_cl, frac_pa = round(frac_pa, 3))],
           file.path(D_TB, "tbl_county_surface_top50.csv"))
    cat("\n== 全国份额最高的 20 个县 ==\n")
    print(head(out[order(-share), .(prov_cn, unit_nm, share = round(share, 4),
                                    rank_in_prov, n_unit_prov, cum_cl)], 20))
  }
}

# ---- 外推边界:限制来自省级那一段 ----
sup <- fread(file.path(D_TB, "tbl_v2_future_support.csv"))
cat("\n== 省级支撑域内比例(决定县级面能外推到什么时候)==\n"); print(sup)
msg("完成 / done")
