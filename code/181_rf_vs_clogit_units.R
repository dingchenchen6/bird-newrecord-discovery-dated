# ============================================================
# Scientific question / 科学问题:
# 在市、县两级的「落点分配」任务上,随机森林能不能比条件 logit 预测得更准?
# 分配任务是层内排序问题——给定该省发生了一条新纪录,哪个单元最可能承接。
# On the within-province allocation task, does a random forest rank the
# receiving unit better than the conditional logit?
#
# Objective / 分析目标:
#   1. 同一批备择集上比较 随机森林 与 条件 logit(M3)
#   2. 两套验证:时间前推(2019–2024)与留一省
#   3. 指标与脚本 171 完全一致:被选中单元的预测排名分位、top-1、前 10% 命中
#   4. 报告两族模型排序的一致性,以及各自最看重什么变量
#
# Input data / 输入数据:
#   analysis_v2/data/admin/altset_county.parquet      58,306 行 / 617 事件
#   analysis_v2/data/admin/altset_prefecture.parquet   7,420 行 / 617 事件
#
# Expected output / 预期输出:
#   analysis_v2/tables/tbl_rf_alloc_skill.csv
#   analysis_v2/tables/tbl_rf_alloc_province.csv
#   analysis_v2/tables/tbl_rf_alloc_importance.csv
#
# Key assumptions / 关键假设:
#   - 分配任务只关心层内排序,不关心概率绝对值;因此以排名分位与命中率为准,
#     不报告 Brier 或校准。
#   - 随机森林拿到与条件 logit 完全相同的特征;条件 logit 天然按层估计,
#     随机森林则只能把每个备择当独立样本打分再层内排序——这一结构性劣势
#     是比较的一部分,不做补偿。
#   - 层内正负比约 1:103(县)与 1:13(市),故同时给出默认与类平衡两个版本。
#
# Main packages / 主要包: ranger, survival, data.table, arrow
# Output directory / 输出路径: analysis_v2/tables/
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(survival); library(ranger)
})
set.seed(20260804)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_AD <- file.path(V2, "analysis_v2/data/admin")
D_TB <- file.path(V2, "analysis_v2/tables")
msg  <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

FEAT <- c("log_area_z", "log_eff_z", "log_dist_z", "in_range",
          "elev_z", "bio1_z", "bio12_z", "frac_pa_z")
FORM_CL <- as.formula(paste("chosen ~", paste(FEAT, collapse = " + "), "+ strata(event_id)"))

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

#' 层内排序技能 / within-stratum ranking skill
skill_of <- function(d, score) {
  d <- copy(d); d[, sc := score]
  d[, r := frank(-sc, ties.method = "average"), by = event_id]
  d[, n_alt := .N, by = event_id]
  s <- d[chosen == 1L]
  data.table(n_event = nrow(s), rank_pct = mean(s$r / s$n_alt),
             top1 = mean(s$r == 1), top3 = mean(s$r <= 3),
             top10pct = mean(s$r <= pmax(1, ceiling(0.10 * s$n_alt))))
}

fit_score <- function(tr, te) {
  out <- list()
  # 条件 logit
  cl <- tryCatch(clogit(FORM_CL, data = tr), error = function(e) NULL)
  if (!is.null(cl)) {
    X <- as.matrix(te[, ..FEAT]); b <- coef(cl)[colnames(X)]
    out[["条件 logit (M3)"]] <- as.numeric(X %*% b)
  }
  # 随机森林:默认
  rf <- ranger(x = tr[, ..FEAT], y = tr$ch, probability = TRUE, num.trees = 800,
               min.node.size = 10, num.threads = 0, seed = 1)
  out[["随机森林(默认)"]] <- predict(rf, data = te[, ..FEAT])$predictions[, "1"]
  # 随机森林:类平衡下采样
  n1 <- sum(tr$chosen)
  rfb <- ranger(x = tr[, ..FEAT], y = tr$ch, probability = TRUE, num.trees = 800,
                min.node.size = 3, sample.fraction = c(n1, n1) / nrow(tr),
                replace = TRUE, num.threads = 0, seed = 1)
  out[["随机森林(类平衡)"]] <- predict(rfb, data = te[, ..FEAT])$predictions[, "1"]
  out
}

skl <- list(); byprov <- list(); impl <- list()

for (lv in c("prefecture", "county")) {
  msg("================ ", lv, " ================")
  d <- prep(lv)
  msg(sprintf("备择集 %d 行;事件 %d;备择数中位 %d",
              nrow(d), uniqueN(d$event_id), as.integer(median(d[, .N, by = event_id]$N))))

  # ---- 时间前推 ----
  tr <- d[year <= 2018]; te <- d[year >= 2019]
  msg(sprintf("时间前推:训练事件 %d,测试事件 %d", uniqueN(tr$event_id), uniqueN(te$event_id)))
  sc <- fit_score(tr, te)
  for (nm in names(sc))
    skl[[length(skl) + 1]] <- cbind(level = lv, split = "时间前推 2019–2024",
                                    model = nm, skill_of(te, sc[[nm]]))
  skl[[length(skl) + 1]] <- cbind(level = lv, split = "时间前推 2019–2024",
                                  model = "基线:随机", skill_of(te, runif(nrow(te))))
  # 两族模型排序的一致性 / rank agreement between the two families
  if (all(c("条件 logit (M3)", "随机森林(默认)") %in% names(sc))) {
    a <- frank(-sc[["条件 logit (M3)"]]); b <- frank(-sc[["随机森林(默认)"]])
    msg(sprintf("两族模型层内打分的 Spearman ρ = %.3f", cor(a, b, method = "spearman")))
  }

  # ---- 留一省 ----
  provs <- d[, .N, by = province][N >= 200]$province
  pr <- rbindlist(lapply(provs, function(p) {
    tr2 <- d[province != p]; te2 <- d[province == p]
    if (uniqueN(te2$event_id) < 5) return(NULL)
    s2 <- fit_score(tr2, te2)
    rbindlist(lapply(names(s2), function(nm)
      cbind(level = lv, province = p, model = nm, skill_of(te2, s2[[nm]]))))
  }))
  byprov[[length(byprov) + 1]] <- pr

  # ---- 重要性 ----
  rf_full <- ranger(x = d[, ..FEAT], y = d$ch, probability = TRUE, num.trees = 800,
                    min.node.size = 10, importance = "permutation", num.threads = 0, seed = 1)
  cl_full <- clogit(FORM_CL, data = d)
  impl[[length(impl) + 1]] <- data.table(
    level = lv, term = FEAT,
    rf_importance = as.numeric(rf_full$variable.importance[FEAT]),
    clogit_absbeta = abs(coef(cl_full)[FEAT]))
}

skl <- rbindlist(skl); byprov <- rbindlist(byprov); impl <- rbindlist(impl)
fwrite(skl, file.path(D_TB, "tbl_rf_alloc_skill.csv"))
fwrite(byprov, file.path(D_TB, "tbl_rf_alloc_province.csv"))
impl[, `:=`(rf_rel = rf_importance / max(rf_importance),
            cl_rel = clogit_absbeta / max(clogit_absbeta)), by = level]
fwrite(impl, file.path(D_TB, "tbl_rf_alloc_importance.csv"))

cat("\n================ 分配任务:随机森林 vs 条件 logit ================\n")
print(skl[, .(level, model, n_event, rank_pct = round(rank_pct, 3),
              top1 = round(top1, 3), top3 = round(top3, 3),
              top10pct = round(top10pct, 3))])
cat("\n================ 留一省(按模型汇总)================\n")
print(byprov[, .(n_prov = .N, rank_pct = round(mean(rank_pct), 3),
                 top1 = round(mean(top1), 3),
                 优于随机的省 = sum(rank_pct < 0.5)), by = .(level, model)])
cat("\n================ 变量重要性对照(相对值)================\n")
print(impl[, .(level, term, 随机森林 = round(rf_rel, 3), 条件logit = round(cl_rel, 3))])
msg("完成 / done")
