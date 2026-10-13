# ============================================================
# Scientific question / 科学问题:
# 把 XGBoost 加入省级预测的模型族对照(机制模型 vs 随机森林 vs XGBoost),
# 使用与脚本 180 完全一致的四套验证方案、指标与随机种子;
# 并为多尺度预测图产出三族模型的 2024 年省级预测面。
# Add XGBoost to the province-level model-family comparison under the
# same four CV schemes as script 180, and export the 2024 provincial
# prediction surface for all three families.
#
# Objective / 分析目标:
# 1. XGBoost 三个变体(同信息 / 加结构 / 类平衡)在 4 方案下的 PR-AUC 等指标
# 2. 三族模型全数据终拟合 → 2024 年每省期望新纪录数(物种风险求和)
#
# Input / 输入:  analysis_v2/data/model_v2_thr50.parquet
# Output / 输出: analysis_v2/tables/tbl_xgb_province_cv.csv / _summary.csv
#               analysis_v2/data/admin/pred_prov_2024_all.csv
#
# Key assumptions / 关键假设:
#   - 折构造与 180 逐行相同(相同 seed 20260804,相同 make_folds),
#     因此三张汇总表可以横向拼接比较。
#   - XGBoost 不做逐折调参:与 RF 的"常规默认"公平对照
#     (eta 0.05, depth 5, 300 轮, 子采样 0.8;类平衡用 scale_pos_weight)。
#   - 2024 年预测取条件预测(含 BLUP):这是描述性的"当前面",
#     不是外推验证;验证见 CV 表。
# Main packages / 主要包: glmmTMB, ranger, xgboost, PRROC, data.table
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(glmmTMB); library(ranger)
  library(xgboost); library(PRROC)
})
set.seed(20260804)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_TB <- file.path(V2, "analysis_v2/tables")
D_DT <- file.path(V2, "analysis_v2/data")
D_AD <- file.path(D_DT, "admin")
msg  <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

# ---------------- 数据(与 180 相同) ----------------
d <- as.data.table(read_parquet(file.path(D_DT, "model_v2_thr50.parquet")))
d <- d[usable_main == TRUE]
zs <- function(x) as.numeric(scale(x))
d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var),
         effort_z = eff_visits_gap_z, yr = year - 2002,
         species_f = factor(species), province_f = factor(province),
         mig_f = factor(mig_grp), ev = factor(event, levels = c(0, 1)))]
msg("数据 ", nrow(d), " 行,", sum(d$event), " 事件")

FE  <- c("clim_change_z", "effort_z", "clim_var_z", "log_completeness")
FE2 <- c(FE, "yr", "province_f", "mig_f")

#' 特征矩阵:因子 one-hot,数值原样 / one-hot encode factors for xgboost
mm <- function(dd, fs) {
  ff <- as.formula(paste("~", paste(fs, collapse = " + "), "- 1"))
  Matrix::sparse.model.matrix(ff, data = dd)
}

ev_metrics <- function(y, p) {
  ok <- is.finite(p) & is.finite(y)
  y <- y[ok]; p <- p[ok]
  if (length(unique(y)) < 2) return(list(auc = NA, prauc = NA, brier = NA, cal_slope = NA))
  r  <- roc.curve(scores.class0 = p[y == 1], scores.class1 = p[y == 0], curve = FALSE)
  pr <- pr.curve(scores.class0 = p[y == 1], scores.class1 = p[y == 0], curve = FALSE)
  cs <- tryCatch(coef(glm(y ~ qlogis(pmin(pmax(p, 1e-8), 1 - 1e-8)),
                          family = binomial()))[2], error = function(e) NA)
  list(auc = r$auc, prauc = pr$auc.integral, brier = mean((p - y)^2), cal_slope = cs)
}

make_folds <- function(scheme, K = 5) {
  if (scheme == "random") {
    split(seq_len(nrow(d)), sample(rep_len(1:K, nrow(d))))
  } else if (scheme == "leave_species") {
    sp <- unique(d$species); g <- setNames(sample(rep_len(1:K, length(sp))), sp)
    split(seq_len(nrow(d)), g[d$species])
  } else if (scheme == "leave_province") {
    pv <- unique(d$province); g <- setNames(sample(rep_len(1:K, length(pv))), pv)
    split(seq_len(nrow(d)), g[d$province])
  } else if (scheme == "temporal") {
    list(`2019-2024` = which(d$year >= 2019))
  }
}
SCHEMES <- c("random", "leave_species", "leave_province", "temporal")

# xgboost 3.x 的 xgboost() 已废弃 params 参数(会被静默丢弃),
# 必须走 xgb.train + xgb.DMatrix 才能保证超参真正生效。
# xgboost() in 3.x silently drops `params`; use xgb.train instead.
xgb_fit <- function(X, y, balanced = FALSE) {
  spw <- if (balanced) sum(y == 0) / sum(y == 1) else 1
  xgb.train(data = xgb.DMatrix(X, label = y), nrounds = 300, verbose = 0,
            params = list(objective = "binary:logistic", eval_metric = "aucpr",
                          eta = 0.05, max_depth = 5, subsample = 0.8,
                          colsample_bytree = 0.8, min_child_weight = 5,
                          scale_pos_weight = spw, nthread = 6))
}

# ---------------- 1. XGBoost 三变体 × 4 方案 ----------------
res <- list()
for (sc in SCHEMES) {
  folds <- make_folds(sc)
  for (k in seq_along(folds)) {
    te_i <- folds[[k]]; tr_i <- setdiff(seq_len(nrow(d)), te_i)
    tr <- d[tr_i]; te <- d[te_i]
    if (sum(tr$event) < 20 || sum(te$event) < 3) next
    msg(sprintf("%s 折 %s", sc, names(folds)[k]))
    for (v in list(list(tag = "同信息", fs = FE, bal = FALSE),
                   list(tag = "加结构", fs = FE2, bal = FALSE),
                   list(tag = "类平衡", fs = FE2, bal = TRUE))) {
      Xtr <- mm(tr, v$fs); Xte <- mm(te, v$fs)
      # 折内省份可能缺层:对齐列 / align columns across folds
      miss <- setdiff(colnames(Xtr), colnames(Xte))
      if (length(miss)) {
        Xte <- cbind(Xte, Matrix::Matrix(0, nrow(Xte), length(miss),
                     dimnames = list(NULL, miss), sparse = TRUE))
      }
      Xte <- Xte[, colnames(Xtr), drop = FALSE]
      fit <- xgb_fit(Xtr, tr$event, v$bal)
      p <- predict(fit, xgb.DMatrix(Xte))
      m <- ev_metrics(te$event, p)
      res[[length(res) + 1]] <- data.table(scheme = sc, fold = names(folds)[k],
        model = paste0("XGBoost(", v$tag, ")"), auc = m$auc, prauc = m$prauc,
        brier = m$brier, cal_slope = m$cal_slope, n_test = nrow(te), n_event = sum(te$event))
    }
  }
}
res <- rbindlist(res)
fwrite(res, file.path(D_TB, "tbl_xgb_province_cv.csv"))
smry <- res[, .(n_fold = .N,
                auc = mean(auc, na.rm = TRUE), auc_sd = sd(auc, na.rm = TRUE),
                prauc = mean(prauc, na.rm = TRUE), prauc_sd = sd(prauc, na.rm = TRUE),
                brier = mean(brier, na.rm = TRUE),
                cal_slope = mean(cal_slope, na.rm = TRUE)), by = .(scheme, model)]
smry[, prauc_lift := prauc / (sum(d$event) / nrow(d))]
fwrite(smry, file.path(D_TB, "tbl_xgb_province_summary.csv"))
cat("\n================ XGBoost 省级四方案 ================\n")
print(smry[, .(scheme, model, AUC = round(auc, 3), `PR-AUC` = round(prauc, 4),
               提升 = round(prauc_lift, 1), 校准 = round(cal_slope, 2))])

# ---------------- 2. 三族终拟合 → 2024 省级预测面 ----------------
msg("终拟合与 2024 预测 / final fits and 2024 provincial surface")
d24 <- d[year == max(year)]

FORM_H <- event ~ clim_change_z * effort_z + clim_var_z + offset(log_completeness) +
  (1 | species) + (1 | province) + (1 | province:year)
fit_h <- glmmTMB(FORM_H, data = d, family = binomial("cloglog"),
                 control = glmmTMBControl(profile = TRUE))
p_mech <- predict(fit_h, newdata = d24, type = "response", allow.new.levels = TRUE)

rf <- ranger(x = d[, ..FE2], y = d$ev, probability = TRUE, num.trees = 800,
             min.node.size = 5,
             sample.fraction = c(sum(d$event), sum(d$event)) / nrow(d),
             replace = TRUE, num.threads = 0, seed = 1)
p_rf_raw <- predict(rf, data = d24[, ..FE2])$predictions[, "1"]

Xall <- mm(d, FE2)
fitx <- xgb_fit(Xall, d$event, balanced = TRUE)
X24 <- mm(d24, FE2)[, colnames(Xall), drop = FALSE]
p_xgb_raw <- predict(fitx, xgb.DMatrix(X24))

# 类平衡模型的概率整体膨胀(先验被改写),按全省合计校准回观测事件率的量级:
# rescale class-balanced scores so provincial sums are comparable across families
cal <- function(p_raw) p_raw * sum(p_mech) / sum(p_raw)
d24[, `:=`(p_mech = p_mech, p_rf = cal(p_rf_raw), p_xgb = cal(p_xgb_raw))]

prov <- d24[, .(n_at_risk = .N,
                mech = sum(p_mech), rf = sum(p_rf), xgb = sum(p_xgb)), by = province]
fwrite(prov, file.path(D_AD, "pred_prov_2024_all.csv"))
cat("\n== 2024 年每省期望新纪录数(三族) ==\n")
print(prov[order(-mech)][1:8, .(province, n_at_risk,
      mech = round(mech, 2), rf = round(rf, 2), xgb = round(xgb, 2))])
cat(sprintf("\n族间 Spearman ρ(省级): mech-rf %.3f | mech-xgb %.3f | rf-xgb %.3f\n",
    cor(prov$mech, prov$rf, method = "spearman"),
    cor(prov$mech, prov$xgb, method = "spearman"),
    cor(prov$rf, prov$xgb, method = "spearman")))
msg("完成 / done")
