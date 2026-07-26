#!/usr/bin/env Rscript
# ============================================================
# Script 136: 随机效应结构的多准则评价(不只看 AIC)
# Multi-criterion evaluation of random-effect structures — beyond AIC
# ============================================================
# 科学问题 / Scientific question:
#   随机效应结构的选择应同时满足统计拟合、生态学含义与可解释性。
#   仅凭 AIC 选择会倾向于更复杂的结构, 却可能牺牲参数的生态学可读性,
#   也无法说明模型整体解释了多少变异。
#
# 四类判据 / Four criteria:
#   1. 拟合优度 fit          AIC / BIC / logLik / df
#   2. 整体解释率 explained  McFadden 伪 R^2、Nakagawa 边际与条件 R^2、
#                            AUC(仅固定效应 = 边际判别力; 含随机效应 = 条件判别力)
#   3. 方差结构 variance     各随机项标准差与 ICC, 检查是否塌缩、层级是否有信息
#   4. 生态学含义 ecology    每个随机项对应的生态/观测过程解释(见下表)
#
# 各随机项的生态学含义 / Ecological meaning of each random term:
#   (1|species)     物种固有的被发现倾向: 体型、鸣声辨识度、栖息地可达性、
#                   分类学关注度、种群密度 —— 物种间基线风险的异质性。
#   (1|province)    省份固有的发现环境: 面积、地形复杂度、生境多样性、
#                   观鸟人口基数、区域研究传统 —— 地区间基线风险的异质性。
#   (1|year)        全国性年度冲击: 平台上线、图鉴出版、疫情导致的出行限制、
#                   期刊政策变化 —— 时间上的共同冲击。
#   (1|prov_year)   地区-年特异冲击: 某省某年的观鸟节、保护区新建、
#                   区域调查项目、地方性报告渠道 —— 时空交互的观测过程异质性。
#                   这是把"观测过程"与"生态过程"分离的关键层级。
#   (0+clim_change|species)  物种对累积变暖的响应强度差异(热生态位宽度、
#                   扩散能力、食性专化度)。
#   (0+effort|province)      努力的边际产出在省间不同(已充分调查的省份,
#                   增加努力的新记录产出递减)。
#
# Input / 输入:  analysis_v2/data/fit_R{0..5}.rds  (133 保存的拟合对象)
#                analysis_v2/data/model_v2_thr50.parquet
# Output / 输出: analysis_v2/tables/tbl_v2_re_evaluation.csv
#
# Main packages / 主要包: glmmTMB, performance, pROC, data.table, arrow
# 运行 / Run: Rscript --no-init-file code/136_re_structure_evaluation.R
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
msg <- function(...) cat(sprintf("[136 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

EFFORT <- "eff_visits_gap_z"; IND0 <- "tavg_annual"; W0 <- 15L
zs <- function(x) as.numeric(scale(x))

ECO <- c(
  R0 = "Species-level heterogeneity only: ignores that provinces differ systematically in detectability.",
  R1 = "Species + province: the v1 structure. Separates intrinsic species detectability from regional survey context, but assumes each province's baseline risk is constant through time.",
  R2 = "Adds a national year shock: captures nationwide changes (platform launches, field-guide publication, travel restrictions) shared by all provinces.",
  R3 = "Adds a province-by-year shock: the level at which the observation process actually operates — regional surveys, local reporting channels, protected-area establishment. Key to separating observation from ecology.",
  R4 = "R3 + species-specific slope on accumulated warming: species differ in how strongly warming translates into range expansion (thermal niche breadth, dispersal ability).",
  R5 = "R3 + province-specific slope on effort: the marginal return of additional effort differs among provinces (diminishing returns where coverage is already dense).")

d <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
d[, c("x", "clim_change", "clim_var") := NULL]
cc <- as.data.table(read_parquet(file.path(OUT, "data", sprintf("components_v2_%s_W%d.parquet", IND0, W0))))
d <- merge(d, cc[, .(species, province, year, clim_change, clim_var)], by = c("species", "province", "year"))
d <- d[is.finite(clim_change) & is.finite(clim_var) & is.finite(get(EFFORT))]
d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var),
         effort_z = zs(get(EFFORT)), prov_year = interaction(province, year, drop = TRUE))]
msg("评价数据: ", format(nrow(d), big.mark = ","), " 行 / ", sum(d$event), " 事件")

# 零模型: 仅截距 + offset, 用于 McFadden 伪 R^2
m_null <- glm(event ~ 1 + offset(log_completeness), data = d, family = binomial("cloglog"))
ll0 <- as.numeric(logLik(m_null))
msg("零模型 logLik = ", round(ll0, 2))

auc_of <- function(p, y) {
  if (!requireNamespace("pROC", quietly = TRUE)) return(NA_real_)
  as.numeric(pROC::auc(pROC::roc(y, p, quiet = TRUE, direction = "<")))
}

rows <- list()
for (nm in paste0("R", 0:5)) {
  f <- file.path(OUT, "data", sprintf("fit_%s.rds", nm))
  if (!file.exists(f)) { msg("  缺少 ", nm); next }
  m <- readRDS(f)
  ll <- as.numeric(logLik(m)); k <- attr(logLik(m), "df")

  vc  <- glmmTMB::VarCorr(m)$cond
  sdv <- vapply(vc, function(v) sqrt(v[1, 1]), numeric(1))
  # ICC: 截距类随机项方差 / (截距类随机项方差 + pi^2/6)  [cloglog 的潜变量方差为 pi^2/6]
  var_int <- sum(vapply(vc, function(v) v[1, 1], numeric(1))[!grepl("\\.1$", names(sdv))])
  icc <- var_int / (var_int + pi^2 / 6)

  # 判别力: 边际(仅固定效应) 与 条件(含随机效应)
  p_marg <- as.numeric(predict(m, newdata = d, type = "response", re.form = NA))
  p_cond <- as.numeric(predict(m, type = "response"))
  auc_m <- auc_of(p_marg, d$event); auc_c <- auc_of(p_cond, d$event)

  # Nakagawa R^2 (若可用)
  r2n <- tryCatch({
    if (requireNamespace("performance", quietly = TRUE)) {
      r <- performance::r2_nakagawa(m)
      c(marginal = as.numeric(r$R2_marginal), conditional = as.numeric(r$R2_conditional))
    } else c(marginal = NA_real_, conditional = NA_real_)
  }, error = function(e) c(marginal = NA_real_, conditional = NA_real_))

  cf <- summary(m)$coefficients$cond
  it <- grep(":", rownames(cf), value = TRUE)[1]
  g  <- function(t, kk) if (t %in% rownames(cf)) cf[t, kk] else NA_real_

  rows[[nm]] <- data.table(
    structure = nm, formula_re = as.character(formula(m))[3],
    df = k, AIC = AIC(m), BIC = BIC(m), logLik = ll,
    R2_McFadden = 1 - ll / ll0,
    R2_marginal = unname(r2n["marginal"]), R2_conditional = unname(r2n["conditional"]),
    AUC_marginal = auc_m, AUC_conditional = auc_c,
    ICC = icc, min_re_sd = min(sdv),
    re_sd = paste(sprintf("%s=%.3f", names(sdv), sdv), collapse = "; "),
    HR_effort = exp(g("effort_z", 1)), P_effort = g("effort_z", 4),
    HR_change = exp(g("clim_change_z", 1)), P_change = g("clim_change_z", 4),
    HR_var = exp(g("clim_var_z", 1)), P_var = g("clim_var_z", 4),
    HR_int = exp(g(it, 1)), P_int = g(it, 4),
    ecological_meaning = ECO[[nm]])
  msg(sprintf("  %s  AIC=%8.1f  McFadden=%.4f  R2m=%.4f R2c=%.4f  AUC_m=%.3f AUC_c=%.3f  ICC=%.3f",
      nm, AIC(m), rows[[nm]]$R2_McFadden, rows[[nm]]$R2_marginal, rows[[nm]]$R2_conditional,
      auc_m, auc_c, icc))
  rm(m); invisible(gc())
}
tb <- rbindlist(rows, fill = TRUE)
tb[, dAIC := round(AIC - min(AIC), 2)]
fwrite(tb, file.path(OUT, "tables", "tbl_v2_re_evaluation.csv"))
print(tb[, .(structure, dAIC, R2_McFadden = round(R2_McFadden, 4),
             R2_marginal = round(R2_marginal, 4), R2_conditional = round(R2_conditional, 4),
             AUC_marginal = round(AUC_marginal, 3), AUC_conditional = round(AUC_conditional, 3),
             ICC = round(ICC, 3), HR_effort = round(HR_effort, 3), HR_change = round(HR_change, 3))])
msg("wrote tbl_v2_re_evaluation.csv | DONE")
