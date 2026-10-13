# ============================================================
# Scientific question / 科学问题:
# 省级新纪录的发生,用随机森林预测能不能比离散时间风险模型更好?
# 更要紧的是:在什么样的验证方案下比较才是公平的,以及两者在
# 拟合范围之外的行为差别有多大。
# Can a random forest outperform the discrete-time hazard model for
# provincial new-record occurrence, under CV schemes that respect the
# species / province / time structure, and how do they differ outside
# the fitted range?
#
# Objective / 分析目标:
#   1. 同一批数据上比较 随机森林 与 冻结主模型(cloglog 离散风险)
#   2. 四套验证方案:随机 / 留物种 / 留省 / 时间前推
#   3. 用适合极不平衡数据的指标:PR-AUC 为主,AUC 与 Brier 为辅,并报告校准
#   4. 外推行为对比:把气候梯度推到拟合范围之外,看两族模型各自怎么走
#
# Input data / 输入数据:
#   analysis_v2/data/model_v2_thr50.parquet   175,901 行,649 事件(事件率 0.369%)
#
# Expected output / 预期输出:
#   analysis_v2/tables/tbl_rf_province_cv.csv        四套验证下的逐折指标
#   analysis_v2/tables/tbl_rf_province_summary.csv   汇总
#   analysis_v2/tables/tbl_rf_importance.csv         置换重要性
#   analysis_v2/data/rf_extrapolation_curve.csv      外推曲线
#
# Key assumptions / 关键假设:
#   - 公平性:随机森林拿到与主模型固定效应完全相同的协变量;
#     另设一个"加结构"版本,把省份、年份、迁徙类型作为特征给它,
#     这是树模型表示随机效应结构的唯一方式。
#   - 主模型的 offset(log 报告完整度)在树模型里只能当作普通特征,
#     无法作为系数固定为 1 的偏移项;这一不对称必须在结果中写明。
#   - 留物种 / 留省验证下,主模型只能做边际预测(固定效应 + offset),
#     因为新物种、新省份没有 BLUP;随机验证下同时报告条件预测。
#   - 事件率 0.369%,因此以 PR-AUC 为主指标,AUC 会被大量真阴性抬高。
#
# Main packages / 主要包: ranger, glmmTMB, PRROC, data.table, arrow
# Output directory / 输出路径: analysis_v2/tables/, analysis_v2/data/
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(glmmTMB); library(ranger); library(PRROC)
})
set.seed(20260804)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_TB <- file.path(V2, "analysis_v2/tables")
D_DT <- file.path(V2, "analysis_v2/data")
msg  <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

# ------------------------------------------------------------
# 0. 数据
# ------------------------------------------------------------
d <- as.data.table(read_parquet(file.path(D_DT, "model_v2_thr50.parquet")))
d <- d[usable_main == TRUE]
zs <- function(x) as.numeric(scale(x))
d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var),
         effort_z = eff_visits_gap_z, yr = year - 2002,
         species_f = factor(species), province_f = factor(province),
         mig_f = factor(mig_grp), ev = factor(event, levels = c(0, 1)))]
msg("建模数据 ", nrow(d), " 行,", sum(d$event), " 事件(", sprintf("%.3f%%", 100 * mean(d$event)), ")")

FE  <- c("clim_change_z", "effort_z", "clim_var_z", "log_completeness")
FE2 <- c(FE, "yr", "province_f", "mig_f")

FORM_H <- event ~ clim_change_z * effort_z + clim_var_z + offset(log_completeness) +
  (1 | species) + (1 | province) + (1 | province:year)

#' 极不平衡下的评价指标 / metrics for a 0.37% positive rate
ev_metrics <- function(y, p) {
  ok <- is.finite(p) & is.finite(y)
  y <- y[ok]; p <- p[ok]
  if (length(unique(y)) < 2) return(list(auc = NA, prauc = NA, brier = NA, cal_slope = NA))
  r  <- PRROC::roc.curve(scores.class0 = p[y == 1], scores.class1 = p[y == 0], curve = FALSE)
  pr <- PRROC::pr.curve(scores.class0 = p[y == 1], scores.class1 = p[y == 0], curve = FALSE)
  eps <- 1e-9
  lg <- qlogis(pmin(pmax(p, eps), 1 - eps))
  cs <- tryCatch(unname(coef(glm(y ~ lg, family = binomial()))[2]), error = function(e) NA_real_)
  list(auc = r$auc, prauc = pr$auc.integral, brier = mean((p - y)^2), cal_slope = cs)
}

#' 主模型的边际预测(固定效应 + offset),用于留物种/留省验证
#' marginal prediction: new species and provinces have no BLUP
pred_hazard_marginal <- function(fit, nd) {
  cf <- fixef(fit)$cond
  eta <- cf[["(Intercept)"]] +
    cf[["clim_change_z"]] * nd$clim_change_z +
    cf[["effort_z"]] * nd$effort_z +
    cf[["clim_var_z"]] * nd$clim_var_z +
    cf[["clim_change_z:effort_z"]] * nd$clim_change_z * nd$effort_z +
    nd$log_completeness
  1 - exp(-exp(eta))
}

# ------------------------------------------------------------
# 1. 四套验证方案
# ------------------------------------------------------------
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
LAB <- c(random = "随机 5 折", leave_species = "留物种 5 折",
         leave_province = "留省 5 折", temporal = "时间前推 2019–2024")

res <- list()
for (sc in SCHEMES) {
  folds <- make_folds(sc)
  for (k in seq_along(folds)) {
    te_i <- folds[[k]]; tr_i <- setdiff(seq_len(nrow(d)), te_i)
    tr <- d[tr_i]; te <- d[te_i]
    if (sum(tr$event) < 20 || sum(te$event) < 3) next
    msg(sprintf("%s 折 %s:训练 %d(%d 事件) / 测试 %d(%d 事件)",
                LAB[[sc]], names(folds)[k], nrow(tr), sum(tr$event), nrow(te), sum(te$event)))

    # --- 离散时间风险模型 ---
    fit <- tryCatch(glmmTMB(FORM_H, data = tr, family = binomial("cloglog")),
                    error = function(e) NULL)
    if (!is.null(fit)) {
      p_marg <- pred_hazard_marginal(fit, te)
      m <- ev_metrics(te$event, p_marg)
      res[[length(res) + 1]] <- data.table(scheme = sc, fold = names(folds)[k],
        model = "离散风险模型(边际)", auc = m$auc, prauc = m$prauc,
        brier = m$brier, cal_slope = m$cal_slope, n_test = nrow(te), n_event = sum(te$event))
      if (sc == "random") {   # 随机验证下才有可用的 BLUP / conditional prediction
        p_cond <- predict(fit, newdata = te, type = "response", allow.new.levels = TRUE)
        m2 <- ev_metrics(te$event, p_cond)
        res[[length(res) + 1]] <- data.table(scheme = sc, fold = names(folds)[k],
          model = "离散风险模型(条件)", auc = m2$auc, prauc = m2$prauc,
          brier = m2$brier, cal_slope = m2$cal_slope, n_test = nrow(te), n_event = sum(te$event))
      }
    }

    # --- 随机森林:同信息 与 加结构 ---
    for (tag in c("同信息", "加结构")) {
      fs <- if (tag == "同信息") FE else FE2
      rf <- ranger(x = tr[, ..fs], y = tr$ev, probability = TRUE,
                   num.trees = 500, min.node.size = 20, num.threads = 0, seed = 1)
      p <- predict(rf, data = te[, ..fs])$predictions[, "1"]
      m <- ev_metrics(te$event, p)
      res[[length(res) + 1]] <- data.table(scheme = sc, fold = names(folds)[k],
        model = paste0("随机森林(", tag, ")"), auc = m$auc, prauc = m$prauc,
        brier = m$brier, cal_slope = m$cal_slope, n_test = nrow(te), n_event = sum(te$event))
    }

    # --- 随机森林:类平衡下采样(稀有事件常规做法)---
    n1 <- sum(tr$event)
    rfb <- ranger(x = tr[, ..FE2], y = tr$ev, probability = TRUE, num.trees = 500,
                  min.node.size = 5, sample.fraction = c(n1, n1) / nrow(tr),
                  replace = TRUE, num.threads = 0, seed = 1)
    pb <- predict(rfb, data = te[, ..FE2])$predictions[, "1"]
    mb <- ev_metrics(te$event, pb)
    res[[length(res) + 1]] <- data.table(scheme = sc, fold = names(folds)[k],
      model = "随机森林(类平衡)", auc = mb$auc, prauc = mb$prauc,
      brier = mb$brier, cal_slope = mb$cal_slope, n_test = nrow(te), n_event = sum(te$event))
  }
}
res <- rbindlist(res)
fwrite(res, file.path(D_TB, "tbl_rf_province_cv.csv"))

smry <- res[, .(n_fold = .N,
                auc = mean(auc, na.rm = TRUE), auc_sd = sd(auc, na.rm = TRUE),
                prauc = mean(prauc, na.rm = TRUE), prauc_sd = sd(prauc, na.rm = TRUE),
                brier = mean(brier, na.rm = TRUE),
                cal_slope = mean(cal_slope, na.rm = TRUE)), by = .(scheme, model)]
smry[, prauc_lift := prauc / (sum(d$event) / nrow(d))]
fwrite(smry, file.path(D_TB, "tbl_rf_province_summary.csv"))
cat("\n================ 省级:随机森林 vs 离散风险模型 ================\n")
for (sc in SCHEMES) {
  cat("\n--", LAB[[sc]], "--\n")
  print(smry[scheme == sc][order(-prauc), .(model, AUC = round(auc, 3),
        `PR-AUC` = round(prauc, 4), `PR 提升倍数` = round(prauc_lift, 1),
        Brier = signif(brier, 3), 校准斜率 = round(cal_slope, 2))])
}

# ------------------------------------------------------------
# 2. 置换重要性
# ------------------------------------------------------------
msg("置换重要性 / permutation importance")
rf_full <- ranger(x = d[, ..FE2], y = d$ev, probability = TRUE, num.trees = 800,
                  min.node.size = 20, importance = "permutation", num.threads = 0, seed = 1)
imp <- data.table(term = names(rf_full$variable.importance),
                  importance = as.numeric(rf_full$variable.importance))
imp[, rel := importance / max(importance)]
setorder(imp, -importance)
fwrite(imp, file.path(D_TB, "tbl_rf_importance.csv"))
cat("\n== 随机森林置换重要性(加结构版)==\n"); print(imp)

# ------------------------------------------------------------
# 3. 外推行为:把气候梯度推到拟合范围之外
# ------------------------------------------------------------
# 树模型在训练范围之外返回边界叶值,预测面饱和;cloglog 在对数风险尺度上
# 线性外推。两种行为都不被数据验证,但必须让读者看到差别有多大。
msg("外推曲线 / extrapolation behaviour")
fit_full <- glmmTMB(FORM_H, data = d, family = binomial("cloglog"))
rng <- range(d$clim_change_z)
grid <- data.table(clim_change_z = seq(-3, 10, by = 0.1))
grid[, `:=`(effort_z = 0, clim_var_z = 0,
            log_completeness = median(d$log_completeness),
            yr = median(d$yr), province_f = d$province_f[1], mig_f = d$mig_f[1])]
grid[, p_hazard := pred_hazard_marginal(fit_full, grid)]
rf_ext <- ranger(x = d[, ..FE2], y = d$ev, probability = TRUE, num.trees = 800,
                 min.node.size = 20, num.threads = 0, seed = 1)
grid[, p_rf := predict(rf_ext, data = grid[, ..FE2])$predictions[, "1"]]
grid[, in_support := clim_change_z >= rng[1] & clim_change_z <= rng[2]]
fwrite(grid, file.path(D_DT, "rf_extrapolation_curve.csv"))
msg(sprintf("拟合范围 %.2f – %.2f SD", rng[1], rng[2]))
cat("\n== 外推行为(effort 固定在均值)==\n")
print(grid[clim_change_z %in% c(-2, 0, 2, 4, 6, 8, 10),
           .(clim_change_z, 支撑域内 = in_support,
             风险模型 = signif(p_hazard, 3), 随机森林 = signif(p_rf, 3),
             比值 = round(p_hazard / pmax(p_rf, 1e-12), 1))])
msg("完成 / done")
