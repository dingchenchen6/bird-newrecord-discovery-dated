#!/usr/bin/env Rscript
# ============================================================
# Script 149: 省级水平分析(仿 Ding et al. 2025 GEB 哺乳动物框架)
# Province-level analysis, following the mammal framework of Ding et al. 2025 GEB
# ============================================================
# 科学问题 / Scientific question:
#   省际新记录数量的差异由什么解释? 这对应 GEB 原文的 Hypothesis 2:
#   新记录数应与当前调查努力和物种丰富度正相关, 与历史调查努力负相关。
#
# 与 GEB 原文的对应 / Correspondence with the mammal paper:
#   同: 计数响应 | 先泊松、检出过度离散后改负二项(log link) | 两个互补模型
#       (主模型: 两期努力均为固定效应; offset 模型: 近期努力取 log offset)
#       | DHARMa 1000 次模拟诊断 | 偏回归 | glmm.hp 层次分割
#   异: 【历史调查努力无法用同一方式度量】——
#       原文用 1949-2000 的野外调查出版物数。鸟类观测数据库在 2000 年之前
#       实测仅有 7 条报告、29/31 省为零, 无法构成有意义的历史努力变量。
#       因此改用数据库自身的早期/近期划分:
#         早期覆盖 2002-2008  <- 承担"历史基线覆盖"的角色
#         近期强度 2009-2024  <- 对应原文的"当前调查努力"
#       科学问题不变(早期已被充分覆盖的省份, 近期的边际发现应更少),
#       但读者必须知道两者的时间尺度与原文不同。
#
# ★ 关键改动 / The key change: 响应用【发现年定年】的 v2 事件计数。
#   努力用本研究统一的 v2 努力面板(访问次数, 覆盖缺口口径), 与风险模型一致,
#   而不是另取一套努力定义。
#
# Input / 输入:
#   analysis_v2/data/{events_discovery_dated.csv, effort_panel_v2.csv}
#   bird_geb_species_province_joint_v2/data_derived/province_model_data_2000_2025.csv
# Output / 输出:
#   analysis_v2/tables/tbl_v2_province_{models,coefficients,partial,hp,diagnostics}.csv
#   analysis_v2/data/province_level_model_data_v2.csv
#
# Main packages / 主要包: MASS, DHARMa, glmm.hp, car, data.table
# 运行 / Run: Rscript --no-init-file code/149_province_level_geb.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(MASS); library(DHARMa)
})
options(warn = 1); set.seed(42)

V2  <- normalizePath(".", mustWork = TRUE)
OUT <- file.path(V2, "analysis_v2")
GEB <- "/Users/dingchenchen/Documents/New project/bird_geb_species_province_joint_v2_20260723"
msg <- function(...) cat(sprintf("[149 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

EARLY <- 2002:2008; RECENT <- 2009:2024

# ---- 1. 响应: v2 发现年定年的省级计数 ----
ev <- fread(file.path(OUT, "data", "events_discovery_dated.csv"))
cnt <- ev[, .(new_record_count = .N), by = province]
msg("v2 事件 ", nrow(ev), " 分布于 ", nrow(cnt), " 个省 | 每省 ",
    min(cnt$new_record_count), "-", max(cnt$new_record_count), " 条")

# ---- 2. 努力: 用本研究统一的 v2 面板 ----
eff <- fread(file.path(OUT, "data", "effort_panel_v2.csv"))
eff <- eff[effort_status_v2 == "observed"]          # 覆盖缺口按缺失处理, 不计入求和
ef <- merge(eff[year %in% EARLY,  .(early_visits  = sum(n_visits, na.rm = TRUE),
                                    early_years   = .N), by = province],
            eff[year %in% RECENT, .(recent_visits = sum(n_visits, na.rm = TRUE),
                                    recent_years  = .N), by = province],
            by = "province", all = TRUE)
ef[is.na(ef)] <- 0L
msg("努力(v2 面板): 早期 ", min(ef$early_years), "-", max(ef$early_years), " 个有效年 | 近期 ",
    min(ef$recent_years), "-", max(ef$recent_years), " 个有效年")

# ---- 3. 其余协变量沿用 GEB 口径的省级表 ----
pv <- fread(file.path(GEB, "data_derived", "province_model_data_2000_2025.csv"))
d <- Reduce(function(a, b) merge(a, b, by = "province", all.x = TRUE),
            list(pv[, .(province, gdp_per_capita, area_km2, habitat_heterogeneity,
                        contemporary_species_richness, candidate_species_richness)],
                 ef, cnt))
d[is.na(new_record_count), new_record_count := 0L]
msg("省级建模集: ", nrow(d), " 省 | 事件合计 ", sum(d$new_record_count))

# log10 变换 + 标准化(与 GEB 一致) / log10 then standardise, as in the mammal paper
TR <- c(z_early_effort = "early_visits", z_recent_effort = "recent_visits",
        z_richness = "contemporary_species_richness", z_gdp = "gdp_per_capita",
        z_area = "area_km2", z_habitat = "habitat_heterogeneity")
for (nm in names(TR)) d[[nm]] <- as.numeric(scale(log10(as.numeric(d[[TR[[nm]]]]) + 1)))
PRED <- names(TR)

vif_tab <- tryCatch({
  v <- car::vif(glm(as.formula(paste("new_record_count ~", paste(PRED, collapse = " + "))),
                    data = d, family = poisson()))
  data.table(variable = names(v), VIF = as.numeric(v))
}, error = function(e) NULL)
if (!is.null(vif_tab)) { print(vif_tab); fwrite(vif_tab, file.path(OUT, "tables", "tbl_v2_province_vif.csv"))
  msg("最大 VIF = ", round(max(vif_tab$VIF), 2), if (max(vif_tab$VIF) > 5) "  <-- 超过 GEB 的 5 门槛" else "") }

# ---- 4. 泊松 -> 过度离散检验 -> 负二项 ----
f_main <- as.formula(paste("new_record_count ~", paste(PRED, collapse = " + ")))
m_pois <- glm(f_main, data = d, family = poisson())
disp <- sum(residuals(m_pois, type = "pearson")^2) / df.residual(m_pois)
p_disp <- pchisq(sum(residuals(m_pois, type = "pearson")^2), df.residual(m_pois), lower.tail = FALSE)
msg("泊松过度离散: 参数 = ", round(disp, 2), " | P = ", signif(p_disp, 3),
    if (disp > 1.5) "  => 泊松不适用, 改负二项" else "")

m_nb <- MASS::glm.nb(f_main, data = d)
disp_nb <- sum(residuals(m_nb, type = "pearson")^2) / df.residual(m_nb)
p_disp_nb <- pchisq(sum(residuals(m_nb, type = "pearson")^2), df.residual(m_nb), lower.tail = FALSE)
msg("负二项离散: 参数 = ", round(disp_nb, 2), " | P = ", signif(p_disp_nb, 3),
    " | theta = ", round(m_nb$theta, 3))

# offset 模型: 近期努力取 log offset, 即"每单位近期努力的发现率"
d[, log_recent_offset := log(recent_visits + 1)]
f_off <- as.formula(paste("new_record_count ~",
                          paste(setdiff(PRED, "z_recent_effort"), collapse = " + "),
                          "+ offset(log_recent_offset)"))
m_off <- MASS::glm.nb(f_off, data = d)

aicc <- function(m) { k <- length(coef(m)) + 1; n <- nobs(m); AIC(m) + 2 * k * (k + 1) / (n - k - 1) }
mods <- data.table(
  model = c("Poisson (main)", "Negative binomial (main)", "Negative binomial (recent effort as offset)"),
  formula = c(deparse1(f_main), deparse1(f_main), deparse1(f_off)),
  df = c(length(coef(m_pois)), length(coef(m_nb)) + 1, length(coef(m_off)) + 1),
  AIC = c(AIC(m_pois), AIC(m_nb), AIC(m_off)),
  AICc = c(aicc(m_pois), aicc(m_nb), aicc(m_off)),
  dispersion = c(disp, disp_nb, sum(residuals(m_off, type = "pearson")^2) / df.residual(m_off)),
  theta = c(NA_real_, m_nb$theta, m_off$theta))
fwrite(mods, file.path(OUT, "tables", "tbl_v2_province_models.csv")); print(mods)

# ---- 5. 系数 ----
co <- function(m, tag) {
  s <- summary(m)$coefficients
  data.table(model = tag, term = rownames(s), estimate = s[, 1], se = s[, 2],
             z = s[, 3], p_value = s[, 4],
             IRR = exp(s[, 1]), IRR_lo = exp(s[, 1] - 1.96 * s[, 2]),
             IRR_hi = exp(s[, 1] + 1.96 * s[, 2]))
}
cf <- rbind(co(m_nb, "NB main"), co(m_off, "NB offset"))
cf[, significant := p_value < 0.05]
fwrite(cf, file.path(OUT, "tables", "tbl_v2_province_coefficients.csv"))
print(cf[term != "(Intercept)", .(model, term, IRR = round(IRR, 3),
        lo = round(IRR_lo, 3), hi = round(IRR_hi, 3), P = signif(p_value, 3), significant)])

# ---- 6. DHARMa 诊断(1000 次模拟, 与 GEB 一致) ----
dg <- list()
for (x in list(list(m_nb, "NB main"), list(m_off, "NB offset"))) {
  sr <- simulateResiduals(x[[1]], n = 1000, seed = 42)
  dg[[x[[2]]]] <- data.table(model = x[[2]],
    KS_p = testUniformity(sr, plot = FALSE)$p.value,
    dispersion_p = testDispersion(sr, plot = FALSE)$p.value,
    outlier_p = testOutliers(sr, plot = FALSE, type = "bootstrap")$p.value)
}
dgt <- rbindlist(dg); fwrite(dgt, file.path(OUT, "tables", "tbl_v2_province_diagnostics.csv")); print(dgt)

# ---- 7. 偏回归: 各预测因子的独立效应 ----
# Carrascal et al. (2009): 用去掉该变量的模型残差与该变量的偏相关衡量独立贡献
partial <- rbindlist(lapply(PRED, function(v) {
  rest <- setdiff(PRED, v)
  m_wo <- MASS::glm.nb(as.formula(paste("new_record_count ~", paste(rest, collapse = " + "))), data = d)
  r_y  <- residuals(m_wo, type = "deviance")
  r_x  <- residuals(lm(as.formula(paste(v, "~", paste(rest, collapse = " + "))), data = d))
  ct <- cor.test(r_x, r_y)
  data.table(predictor = v, partial_r = unname(ct$estimate), p_value = ct$p.value,
             dAIC_when_dropped = AIC(m_wo) - AIC(m_nb))
}))
setorder(partial, -dAIC_when_dropped)
fwrite(partial, file.path(OUT, "tables", "tbl_v2_province_partial.csv"))
print(partial[, .(predictor, partial_r = round(partial_r, 3), P = signif(p_value, 3),
                  dAIC_when_dropped = round(dAIC_when_dropped, 1))])

# ---- 8. 层次分割(Chevan & Sutherland 1991) ----
# glmm.hp 不接受 MASS::glm.nb 对象(报"选择了未定义的列"), 故按原始定义直接实现:
# 对每个预测因子, 在【全部 2^(k-1) 个不含它的子模型】上计算加入它带来的
# 解释偏差增量, 取平均即其【独立贡献 I】; 该因子单独的解释力减去 I 即
# 【共同贡献 J】(与其他因子共享的部分, 可为负)。这与 GEB 用 glmm.hp 得到的
# 量是同一个量, 只是自己算, 便于审计。
# NB: implemented from the definition because glmm.hp rejects glm.nb objects.
dev_of <- function(vars) {
  rhs <- if (length(vars)) paste(vars, collapse = " + ") else "1"
  m <- tryCatch(MASS::glm.nb(as.formula(paste("new_record_count ~", rhs)), data = d),
                error = function(e) NULL)
  if (is.null(m)) return(NA_real_)
  1 - m$deviance / m$null.deviance                       # 伪 R^2 (解释偏差比例)
}
subsets_of <- function(pool) {
  do.call(c, lapply(0:length(pool), function(k) combn(pool, k, simplify = FALSE)))
}
hp <- rbindlist(lapply(PRED, function(v) {
  others <- setdiff(PRED, v)
  incs <- vapply(subsets_of(others), function(s) {
    a <- dev_of(s); b <- dev_of(c(s, v))
    if (is.na(a) || is.na(b)) NA_real_ else b - a
  }, numeric(1))
  indep <- mean(incs, na.rm = TRUE)
  data.table(predictor = v, independent = indep, alone = dev_of(v),
             joint = dev_of(v) - indep)
}))
tot <- dev_of(PRED)
hp[, `:=`(pct_of_explained = round(100 * independent / sum(independent), 1))]
setorder(hp, -independent)
fwrite(hp, file.path(OUT, "tables", "tbl_v2_province_hp.csv"))
msg("全模型解释偏差 = ", round(100 * tot, 1), "% | 独立贡献合计 = ",
    round(100 * sum(hp$independent), 1), "%")
print(hp[, .(predictor, independent = round(independent, 4), alone = round(alone, 4),
             joint = round(joint, 4), pct_of_explained)])

fwrite(d, file.path(OUT, "data", "province_level_model_data_v2.csv"))
msg("wrote province-level tables and model data | DONE")
