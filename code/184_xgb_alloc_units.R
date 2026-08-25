# ============================================================
# Scientific question / 科学问题:
# 1. 把 XGBoost 加入市/县级分配任务的模型族对照(与脚本 181 同设计:
#    时间前推 + 留一省,层内排名指标)。
# 2. 为多尺度预测图产出 RF 与 XGBoost 的市/县"当前面":
#    与脚本 172 的机制面同一网格、同一聚合方式(候选物种等权、省内归一),
#    仅把打分函数换成各自的模型族。
# Add XGBoost to the unit-level allocation comparison (same design as 181),
# and score the 172 grid with RF and XGBoost to build their surfaces.
#
# Input / 输入:
#   analysis_v2/data/admin/altset_{prefecture,county}.parquet
#   analysis_v2/data/admin/units_*.csv, effort_unit_year_*.csv,
#   dist_species_unit_*.csv;  analysis_v2/data/model_v2_thr50.parquet
# Output / 输出:
#   analysis_v2/tables/tbl_xgb_alloc_skill.csv(含随机基线,便于并表)
#   analysis_v2/data/admin/{prefecture,county}_surface_{rf,xgb}.csv
#
# Key assumptions / 关键假设:
#   - 打分即排名:分配是层内(每事件的备择集合内)排序任务,
#     二分类概率仅作打分,组内相对次序才是被评价的量。
#   - 面的构造与 172 逐行同构:REF_YEAR 一致、候选集一致、等权聚合一致,
#     三族面的差异只来自打分函数本身。
# Main packages / 主要包: data.table, arrow, ranger, xgboost, survival
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(ranger); library(xgboost); library(survival)
})
set.seed(20260804)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_TB <- file.path(V2, "analysis_v2/tables")
D_AD <- file.path(V2, "analysis_v2/data/admin")
REF_YEAR <- 2024L
msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

FEAT <- c("log_area_z", "log_eff_z", "log_dist_z", "in_range",
          "elev_z", "bio1_z", "bio12_z", "frac_pa_z")

prep <- function(lv) {
  d <- as.data.table(read_parquet(file.path(D_AD, sprintf("altset_%s.parquet", lv))))
  d[, `:=`(log_area = log(area_km2), log_eff = log1p(cum_cl),
           log_dist = log1p(dist_range_km), in_range = as.integer(dist_range_km == 0))]
  for (v in c("log_area", "log_eff", "log_dist", "elev", "bio1", "bio12", "frac_pa"))
    d[[paste0(v, "_z")]] <- as.numeric(scale(d[[v]]))
  d <- d[is.finite(elev_z) & is.finite(bio1_z) & is.finite(bio12_z)]
  d[, ch := factor(chosen, levels = c(0, 1))]
  d
}

skill_of <- function(d, score) {
  d <- copy(d); d[, sc := score]
  d[, r := frank(-sc, ties.method = "average"), by = event_id]
  d[, n_alt := .N, by = event_id]
  s <- d[chosen == 1L]
  data.table(n_event = nrow(s), rank_pct = mean(s$r / s$n_alt),
             top1 = mean(s$r == 1), top3 = mean(s$r <= 3),
             top10pct = mean(s$r <= pmax(1, ceiling(0.10 * s$n_alt))))
}

# 见 183 的说明:3.x 的 xgboost() 丢弃 params,必须用 xgb.train。
xgb_train_fit <- function(X, y) {
  xgb.train(data = xgb.DMatrix(X, label = y), nrounds = 300, verbose = 0,
            params = list(objective = "binary:logistic", eval_metric = "aucpr",
                          eta = 0.05, max_depth = 5, subsample = 0.8,
                          colsample_bytree = 0.8, min_child_weight = 5,
                          scale_pos_weight = sum(y == 0) / sum(y == 1), nthread = 6))
}
xgb_score <- function(tr, te) {
  fit <- xgb_train_fit(as.matrix(tr[, ..FEAT]), tr$chosen)
  predict(fit, xgb.DMatrix(as.matrix(te[, ..FEAT])))
}

# ---------------- 1. XGBoost 分配 CV(与 181 同设计) ----------------
skl <- list()
for (lv in c("prefecture", "county")) {
  msg("================ ", lv, " ================")
  d <- prep(lv)

  tr <- d[year <= 2018]; te <- d[year >= 2019]
  msg(sprintf("时间前推:训练事件 %d,测试事件 %d", uniqueN(tr$event_id), uniqueN(te$event_id)))
  skl[[length(skl) + 1]] <- cbind(level = lv, split = "时间前推 2019–2024",
                                  model = "XGBoost(类平衡)", skill_of(te, xgb_score(tr, te)))

  provs <- d[, .N, by = province][N >= 200]$province
  pr <- rbindlist(lapply(provs, function(p) {
    tr2 <- d[province != p]; te2 <- d[province == p]
    if (uniqueN(te2$event_id) < 5) return(NULL)
    cbind(level = lv, province = p, model = "XGBoost(类平衡)",
          skill_of(te2, xgb_score(tr2, te2)))
  }))
  pr_s <- pr[, .(split = "留一省", n_event = sum(n_event),
                 rank_pct = mean(rank_pct), top1 = mean(top1),
                 top3 = mean(top3), top10pct = mean(top10pct),
                 n_prov = .N, n_better = sum(rank_pct < 0.5)), by = .(level, model)]
  msg(sprintf("留一省:%d 省中 %d 优于随机;平均排名分位 %.3f",
              pr_s$n_prov, pr_s$n_better, pr_s$rank_pct))
  skl[[length(skl) + 1]] <- pr_s
  fwrite(pr, file.path(D_TB, sprintf("tbl_xgb_alloc_province_%s.csv", lv)))
}
fwrite(rbindlist(skl, fill = TRUE), file.path(D_TB, "tbl_xgb_alloc_skill.csv"))

# ---------------- 2. RF / XGBoost 的市县面(172 同网格) ----------------
mv <- as.data.table(read_parquet(file.path(V2, "analysis_v2/data/model_v2_thr50.parquet")))
cand <- unique(mv[year == max(year) & event == 0L, .(species, province)])
msg("候选物种-省对 ", nrow(cand))

for (lv in c("prefecture", "county")) {
  msg("---- ", lv, " 面 / surfaces ----")
  d <- prep(lv)

  # 全数据终拟合(打分函数) / final fits on the full alternative sets
  n1 <- sum(d$chosen)
  rf_fit <- ranger(x = d[, ..FEAT], y = d$ch, probability = TRUE, num.trees = 800,
                   min.node.size = 3, sample.fraction = c(n1, n1) / nrow(d),
                   replace = TRUE, num.threads = 0, seed = 1)
  Xd <- as.matrix(d[, ..FEAT])
  xg_fit <- xgb_train_fit(Xd, d$chosen)

  # 标准化参照:与 172 相同,用 altset 的均值/方差 / same scaling reference as 172
  mu <- list(); sdv <- list()
  raw <- data.table(log_area = log(d$area_km2), log_eff = log1p(d$cum_cl),
                    log_dist = log1p(d$dist_range_km), elev = d$elev,
                    bio1 = d$bio1, bio12 = d$bio12, frac_pa = d$frac_pa)
  for (v in names(raw)) { mu[[v]] <- mean(raw[[v]], na.rm = TRUE); sdv[[v]] <- sd(raw[[v]], na.rm = TRUE) }
  zz <- function(x, v) (x - mu[[v]]) / sdv[[v]]

  ud  <- fread(file.path(D_AD, sprintf("units_%s.csv", lv)))
  eff <- fread(file.path(D_AD, sprintf("effort_unit_year_%s.csv", lv)))
  dst <- fread(file.path(D_AD, sprintf("dist_species_unit_%s.csv", lv)))
  cum <- eff[year <= REF_YEAR, .(cum_cl = sum(n_checklist)), by = unit_id]
  ud <- merge(ud, cum, by = "unit_id", all.x = TRUE)
  ud[is.na(cum_cl), cum_cl := 0L]
  ud <- ud[!is.na(province) & is.finite(bio1) & is.finite(bio12) & is.finite(elev)]
  cd <- cand[species %in% unique(dst$species)]

  for (fam in c("rf", "xgb")) {
    out <- rbindlist(lapply(unique(cd$province), function(p) {
      u <- ud[province == p]
      if (!nrow(u)) return(NULL)
      sp <- cd[province == p]$species
      if (!length(sp)) return(NULL)
      g <- dst[species %in% sp & unit_id %in% u$unit_id]
      if (!nrow(g)) return(NULL)
      g <- merge(g, u[, .(unit_id, area_km2, cum_cl, elev, bio1, bio12, frac_pa)], by = "unit_id")
      Xg <- cbind(log_area_z = zz(log(g$area_km2), "log_area"),
                  log_eff_z  = zz(log1p(g$cum_cl), "log_eff"),
                  log_dist_z = zz(log1p(g$dist_range_km), "log_dist"),
                  in_range   = as.integer(g$dist_range_km == 0),
                  elev_z     = zz(g$elev, "elev"),
                  bio1_z     = zz(g$bio1, "bio1"),
                  bio12_z    = zz(g$bio12, "bio12"),
                  frac_pa_z  = zz(g$frac_pa, "frac_pa"))
      g[, sc := if (fam == "rf") predict(rf_fit, data = as.data.frame(Xg))$predictions[, "1"]
                else predict(xg_fit, xgb.DMatrix(Xg))]
      # 与 172 相同:每物种省内 softmax 归一,再等权聚合
      # per-species within-province normalisation, then equal-weight aggregate
      g[, pr := sc / sum(sc), by = species]
      agg <- g[, .(share = mean(pr), n_species = uniqueN(species)), by = unit_id]
      agg[, `:=`(province = p, share = share / sum(share))]
      agg
    }))
    out <- merge(out, ud[, .(unit_id, unit_nm, prov_cn)], by = "unit_id")
    out[, rank_in_prov := frank(-share), by = province]
    fwrite(out, file.path(D_AD, sprintf("%s_surface_%s.csv", lv, fam)))
    msg(sprintf("  %s-%s 面:%d 单元", lv, fam, nrow(out)))
  }
}
msg("完成 / done")
