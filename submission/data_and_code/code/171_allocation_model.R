# ============================================================
# Scientific question / 科学问题:
# 既然某省某年发生了一条新纪录,它落在省内哪个市/县?这一段能不能
# 预测得比「随机」「按面积」「按观鸟努力」更好?——只有样本外有增量技能,
# 降尺度到市县才是真的可行,而不是把省级值涂到县上。
# Given that a provincial new record occurs, which prefecture or county does
# it land in? Only genuine out-of-sample skill over area- and effort-only
# baselines makes county-level prediction meaningful.
#
# Objective / 分析目标:
#   1. 拟合省内分配的条件 logit,给出模型阶梯
#   2. 时间外推验证(2002-2018 拟合 → 2019-2024 预测)
#   3. 留一省验证(空间外推)
#   4. 与三条基线比较:随机、按面积、按累计观鸟努力
#
# Input data / 输入数据:
#   analysis_v2/data/admin/altset_county.parquet     58,509 行 / 617 事件
#   analysis_v2/data/admin/altset_prefecture.parquet  7,420 行 / 617 事件
#
# Expected output / 预期输出:
#   analysis_v2/tables/tbl_alloc_ladder.csv        模型阶梯系数
#   analysis_v2/tables/tbl_alloc_skill.csv         样本外技能
#   analysis_v2/tables/tbl_alloc_skill_province.csv 留一省
#   analysis_v2/data/admin/alloc_fit_{lv}.rds
#
# Key assumptions / 关键假设:
#   - 备择集是事件所在省的全部单元;第一段(省级风险)已经决定了省,
#     因此本段不承担跨省分配。
#   - 观鸟努力用事件年之前的**累计** checklist 数,避免用同年信息
#     反推同年事件(同年努力另作敏感性)。
#   - 分布区距离来自 BirdLife 当代分布,不随年份变化;它刻画的是
#     「离这个物种已知分布区有多远」,而不是动态的分布边界。
#   - 技能指标以「被选中单元的预测排名分位」为主:0.5 等于随机,越小越好。
#
# Main packages / 主要包: survival, data.table, arrow
# Output directory / 输出路径: analysis_v2/tables/, analysis_v2/data/admin/
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(survival)
})
set.seed(20260803)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_AD <- file.path(V2, "analysis_v2/data/admin")
D_TB <- file.path(V2, "analysis_v2/tables")
msg  <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

LEVELS <- c("prefecture", "county")

prep <- function(lv) {
  d <- as.data.table(read_parquet(file.path(D_AD, sprintf("altset_%s.parquet", lv))))
  d[, `:=`(log_area = log(area_km2),
           log_eff  = log1p(cum_cl),
           log_eff_now = log1p(n_checklist),
           log_dist = log1p(dist_range_km),
           in_range = as.integer(dist_range_km == 0))]
  for (v in c("log_area", "log_eff", "log_eff_now", "log_dist", "elev", "bio1", "bio12",
              "frac_pa", "warming_rate")) {
    d[[paste0(v, "_z")]] <- as.numeric(scale(d[[v]]))
  }
  d[is.finite(elev_z) & is.finite(bio1_z) & is.finite(bio12_z)]
}

#' 用拟合好的系数给备择集打分并算技能 / score alternatives and compute skill
skill_of <- function(d, score) {
  d <- copy(d); d[, sc := score]
  d[, r := frank(-sc, ties.method = "average"), by = event_id]
  d[, n_alt := .N, by = event_id]
  s <- d[chosen == 1L]
  data.table(n_event = nrow(s),
             rank_pct = mean(s$r / s$n_alt),
             top1     = mean(s$r == 1),
             top3     = mean(s$r <= 3),
             top10pct = mean(s$r <= pmax(1, ceiling(0.10 * s$n_alt))),
             median_rank = median(s$r),
             median_n_alt = median(s$n_alt))
}

FORMS <- list(
  "M0 面积"                 = "chosen ~ log_area_z + strata(event_id)",
  "M1 +累计观鸟努力"        = "chosen ~ log_area_z + log_eff_z + strata(event_id)",
  "M2 +到分布区距离"        = "chosen ~ log_area_z + log_eff_z + log_dist_z + in_range + strata(event_id)",
  "M3 +环境"                = paste("chosen ~ log_area_z + log_eff_z + log_dist_z + in_range +",
                                    "elev_z + bio1_z + bio12_z + frac_pa_z + strata(event_id)")
)

lad <- list(); skl <- list(); skp <- list()

for (lv in LEVELS) {
  msg("================ ", lv, " ================")
  d <- prep(lv)
  msg(sprintf("备择集 %d 行;事件 %d;每事件备择数中位 %d",
              nrow(d), uniqueN(d$event_id), as.integer(median(d[, .N, by = event_id]$N))))

  # ---- 模型阶梯(全样本,仅看系数方向与量级)----
  for (nm in names(FORMS)) {
    f <- clogit(as.formula(FORMS[[nm]]), data = d)
    s <- summary(f)$coefficients
    lad[[length(lad) + 1]] <- data.table(
      level = lv, model = nm, term = rownames(s),
      OR = exp(s[, "coef"]), lo = exp(s[, "coef"] - 1.96 * s[, "se(coef)"]),
      hi = exp(s[, "coef"] + 1.96 * s[, "se(coef)"]), P = s[, "Pr(>|z|)"],
      concordance = summary(f)$concordance[1], AIC = AIC(f))
  }

  # ---- 时间外推验证 ----
  tr <- d[year <= 2018]; te <- d[year >= 2019]
  msg(sprintf("时间外推:训练事件 %d,测试事件 %d",
              uniqueN(tr$event_id), uniqueN(te$event_id)))
  fit_tr <- clogit(as.formula(FORMS[["M3 +环境"]]), data = tr)
  X <- model.matrix(~ log_area_z + log_eff_z + log_dist_z + in_range +
                      elev_z + bio1_z + bio12_z + frac_pa_z, te)[, -1, drop = FALSE]
  b <- coef(fit_tr)[colnames(X)]
  pred <- as.numeric(X %*% b)

  skl[[length(skl) + 1]] <- cbind(level = lv, split = "时间外推 2019-2024",
                                  method = "M3 分配模型", skill_of(te, pred))
  skl[[length(skl) + 1]] <- cbind(level = lv, split = "时间外推 2019-2024",
                                  method = "基线:累计观鸟努力", skill_of(te, te$log_eff_z))
  skl[[length(skl) + 1]] <- cbind(level = lv, split = "时间外推 2019-2024",
                                  method = "基线:单元面积", skill_of(te, te$log_area_z))
  skl[[length(skl) + 1]] <- cbind(level = lv, split = "时间外推 2019-2024",
                                  method = "基线:随机", skill_of(te, runif(nrow(te))))
  # 只用分布区距离 / range distance alone
  skl[[length(skl) + 1]] <- cbind(level = lv, split = "时间外推 2019-2024",
                                  method = "基线:仅到分布区距离", skill_of(te, -te$log_dist_z))

  # ---- 留一省验证 ----
  provs <- d[, .N, by = province][N >= 200]$province
  pr <- rbindlist(lapply(provs, function(p) {
    tr2 <- d[province != p]; te2 <- d[province == p]
    if (uniqueN(te2$event_id) < 5) return(NULL)
    f2 <- tryCatch(clogit(as.formula(FORMS[["M3 +环境"]]), data = tr2), error = function(e) NULL)
    if (is.null(f2)) return(NULL)
    X2 <- model.matrix(~ log_area_z + log_eff_z + log_dist_z + in_range +
                         elev_z + bio1_z + bio12_z + frac_pa_z, te2)[, -1, drop = FALSE]
    b2 <- coef(f2)[colnames(X2)]
    cbind(level = lv, province = p, skill_of(te2, as.numeric(X2 %*% b2)))
  }))
  skp[[length(skp) + 1]] <- pr

  saveRDS(clogit(as.formula(FORMS[["M3 +环境"]]), data = d),
          file.path(D_AD, sprintf("alloc_fit_%s.rds", lv)))
}

lad <- rbindlist(lad); skl <- rbindlist(skl); skp <- rbindlist(skp)
fwrite(lad, file.path(D_TB, "tbl_alloc_ladder.csv"))
fwrite(skl, file.path(D_TB, "tbl_alloc_skill.csv"))
fwrite(skp, file.path(D_TB, "tbl_alloc_skill_province.csv"))

cat("\n================ 模型阶梯(M3 系数)================\n")
print(lad[model == "M3 +环境", .(level, term, OR = round(OR, 3),
                                 CI = sprintf("%.2f-%.2f", lo, hi), P = signif(P, 2))])
cat("\n================ 各阶梯的一致性指数 ================\n")
print(unique(lad[, .(level, model, concordance = round(concordance, 3), AIC = round(AIC, 1))]))
cat("\n================ 样本外技能(时间外推)================\n")
print(skl[, .(level, method, n_event, rank_pct = round(rank_pct, 3),
              top1 = round(top1, 3), top3 = round(top3, 3),
              top10pct = round(top10pct, 3), median_rank, median_n_alt)])
cat("\n================ 留一省(按事件数排序)================\n")
print(skp[order(level, -n_event)][, .(level, province, n_event,
                                      rank_pct = round(rank_pct, 3),
                                      top1 = round(top1, 3), median_n_alt)])
msg("完成 / done")
