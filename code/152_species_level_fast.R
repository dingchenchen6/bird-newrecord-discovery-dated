#!/usr/bin/env Rscript
# ============================================================
# Script 152: 物种水平快速拟合 —— 三种处理系统发育的方式互为对照
# Fast species-level fits: three ways of handling phylogeny, cross-checked
# ============================================================
# 动机 / Why:
#   brms 的贝叶斯系统发育 GLMM 每个模型要十几分钟。本脚本用几分钟给出同一
#   问题的答案, 并且【不依赖单一的系统发育处理方式】。
#
# 为什么不能直接用 glmmTMB 的系统发育协方差 / Why not glmmTMB + phylo covariance:
#   glmmTMB 1.1.14 的 propto() 是给【随机斜率之间】的协方差用的, 期望的是
#   项数 x 项数的矩阵, 不是层级(物种) x 层级的矩阵。实测 propto(1|phylo, A)
#   报 "matrix is not the correct dimensions"。glmmTMB 目前没有等价于
#   brms gr(cov=) 的机制, 故改用下面三条路。
#
# 三种处理 / Three treatments:
#   M1 glmmTMB + 分类阶元嵌套随机效应 (1|order/family/genus)
#      最快; 分类阶元是系统发育的粗粒度代理, 生态学文献中常用。
#   M2 glmmTMB + 系统发育特征向量回归 (PVR)
#      对系统发育距离阵作主坐标分析, 取前 k 个特征向量作固定效应
#      (Diniz-Filho et al. 1998)。在 glmmTMB 框架内显式吸收系统发育结构。
#   M3 phylolm::phyloglm
#      真正用整棵树的系统发育逻辑回归(Ives & Garland 2010, logistic_MPLE),
#      与 brms 的模型设定最接近, 但用惩罚最大似然, 秒级完成。
#
#   若三者(以及后台的 brms)给出一致的系数方向与显著性, 则结论不依赖于
#   系统发育的具体处理方式 —— 这本身就是需要报告的稳健性证据。
#
# Input / 输入:  analysis_v2/data/species_traits_harmonised_v2.csv
#                Clements 2023 dated Aves tree
# Output / 输出: analysis_v2/tables/tbl_v2_species_fast_{effects,compare,fit}.csv
#
# Main packages / 主要包: glmmTMB, phylolm, ape, data.table
# 运行 / Run: Rscript --no-init-file code/152_species_level_fast.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ape); library(glmmTMB); library(phylolm)
})
options(warn = 1); set.seed(42)

OUT  <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
TREE <- "/Users/dingchenchen/Documents/New project/bird_phylogeny_new_records_mctavish_work/data/external/summary_dated_clements_Aves_1.4_Clements2023.nex"
msg  <- function(...) cat(sprintf("[152 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

# ★ 范围变量必须用【全球分布区面积】而不是【中国已分布省数】。
#   中国鸟类性状库发表于 2022 年, 其省份计数已经包含了 2002-2021 年间产生的
#   新纪录 —— 也就是本分析的响应变量本身。实测: 有新纪录物种的中位省数为 14,
#   无新纪录者为 4; 用省数得 OR = 2.06 (P = 3e-16), 用与中国省级记录无关的
#   AVONET 全球分布区面积则为 OR = 1.27 (P = 0.017); 两者同时进入时全球面积
#   被完全吸收(OR 0.96, P = 0.7)。前者是循环的, 后者才是可解释的效应。
CONT <- c(log_mass = "mass_g_final", log_hwi = "hwi_final", log_range = "range_size_av",
          log_clutch = "clutch_final", log_congeners = "n_congeners",
          log_habbreadth = "habitat_breadth", log_dietbreadth = "diet_breadth")
CIRC <- c(log_range_provinces = "provinces_final")   # 仅用于展示循环性, 不作结论
CATS <- c("migration_final", "trophic_niche", "habitat_density", "iucn_group", "endemic_final")
N_PV <- 10L                                   # 系统发育特征向量个数

d <- fread(file.path(OUT, "data", "species_traits_harmonised_v2.csv"))
d <- d[!is.na(tree_label) & nzchar(tree_label)]
d <- d[is.finite(range_size_av)]
msg("物种池 ", nrow(d), " (有系统树标签且有全球分布区面积) | 有新纪录 ", sum(d$new_record_v2))

for (nm in names(CONT)) d[[paste0("z_", nm)]] <- as.numeric(scale(log10(as.numeric(d[[CONT[[nm]]]]) + 1)))
Z <- paste0("z_", names(CONT))
d[, migration_final := factor(migration_final, levels = c("Resident", "Partial migrant", "Migratory"))]
d[, trophic_niche   := factor(trophic_niche,
     levels = c("Invertivore", "Omnivore", "Aquatic predator", "Granivore",
                "Vertivore/Scavenger", "Frugivore/Nectarivore", "Herbivore"))]
d[, habitat_density := factor(habitat_density, levels = c("Dense", "Semi-open", "Open"))]
d[, iucn_group      := factor(iucn_group, levels = c("Least Concern", "Near Threatened", "Threatened"))]
d[, endemic_final   := factor(endemic_final, levels = c("Non-endemic", "Endemic"))]
d[, `:=`(order_f = factor(order_cn), family_f = factor(family_cn),
         genus_f = factor(sub(" .*", "", sp_key)))]

# ---- 系统发育: 子树、特征向量 ----
tr <- read.nexus(TREE)
tr <- drop.tip(tr, setdiff(tr$tip.label, d$tree_label))
d <- d[match(tr$tip.label, tree_label)]
stopifnot(identical(d$tree_label, tr$tip.label))
msg("子树 ", Ntip(tr), " 个 tip | 与数据行一一对应")

pv_file <- file.path(OUT, "data", "_phylo_eigenvectors.rds")
if (file.exists(pv_file)) { pv <- readRDS(pv_file); msg("复用系统发育特征向量") } else {
  msg("主坐标分析(系统发育距离阵 ", Ntip(tr), "^2) ...")
  cp <- cophenetic(tr)
  pc <- cmdscale(cp, k = N_PV, eig = TRUE)
  pv <- list(points = pc$points, explained = 100 * sum(pc$eig[1:N_PV]) / sum(abs(pc$eig)))
  saveRDS(pv, pv_file)
}
PVN <- paste0("pv", seq_len(N_PV))
for (i in seq_len(N_PV)) d[[PVN[i]]] <- as.numeric(scale(pv$points[match(d$tree_label, rownames(pv$points)), i]))
msg("前 ", N_PV, " 个系统发育特征向量解释系统发育距离的 ", round(pv$explained, 1), "%")

for (nm in names(CIRC)) d[[paste0("z_", nm)]] <- as.numeric(scale(log10(as.numeric(d[[CIRC[[nm]]]]) + 1)))
FX <- paste(c(Z, CATS), collapse = " + ")

# ---- M1 分类阶元嵌套 ----
t0 <- Sys.time()
m1 <- glmmTMB(as.formula(paste("new_record_v2 ~", FX, "+ (1|order_f/family_f/genus_f)")),
              data = d, family = binomial())
msg("M1 分类阶元嵌套  AIC=", round(AIC(m1), 1), "  [", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), "s]")

# ---- M2 系统发育特征向量 ----
t0 <- Sys.time()
m2 <- glmmTMB(as.formula(paste("new_record_v2 ~", FX, "+", paste(PVN, collapse = " + "))),
              data = d, family = binomial())
msg("M2 系统发育特征向量 AIC=", round(AIC(m2), 1), "  [", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), "s]")

# ---- M3 phyloglm ----
t0 <- Sys.time()
df <- as.data.frame(d); rownames(df) <- df$tree_label
m3 <- tryCatch(phyloglm(as.formula(paste("new_record_v2 ~", FX)), data = df, phy = tr,
                        method = "logistic_MPLE", btol = 20),
               error = function(e) { msg("  phyloglm 失败: ", conditionMessage(e)); NULL })
if (!is.null(m3)) msg("M3 phyloglm        alpha=", signif(m3$alpha, 3),
                      "  [", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), "s]")

# ---- 汇总系数 ----
grab_tmb <- function(m, tag) {
  s <- summary(m)$coefficients$cond
  data.table(model = tag, term = rownames(s), estimate = s[, 1], se = s[, 2], p_value = s[, 4])
}
grab_phy <- function(m, tag) {
  s <- summary(m)$coefficients
  data.table(model = tag, term = rownames(s), estimate = s[, 1], se = s[, 2],
             p_value = s[, ncol(s)])
}
eff <- rbindlist(list(grab_tmb(m1, "M1 taxonomic nesting"),
                      grab_tmb(m2, "M2 phylogenetic eigenvectors"),
                      if (!is.null(m3)) grab_phy(m3, "M3 phyloglm")), fill = TRUE)
eff <- eff[!grepl("^pv[0-9]+$|Intercept", term)]
eff[, `:=`(odds_ratio = exp(estimate), OR_lo = exp(estimate - 1.96 * se),
           OR_hi = exp(estimate + 1.96 * se), significant = p_value < 0.05)]
fwrite(eff, file.path(OUT, "tables", "tbl_v2_species_fast_effects.csv"))

# 一致性: 三法之间的方向与显著性是否一致
w <- dcast(eff, term ~ model, value.var = "odds_ratio")
ws <- dcast(eff, term ~ model, value.var = "significant")
mods <- setdiff(names(w), "term")
agree <- data.table(term = w$term,
  n_models = rowSums(!is.na(w[, ..mods])),
  same_direction = apply(w[, ..mods], 1, function(r) { r <- r[!is.na(r)]; all(r > 1) || all(r < 1) }),
  n_significant = rowSums(ws[, ..mods] == TRUE, na.rm = TRUE),
  OR_range = apply(w[, ..mods], 1, function(r) sprintf("%.2f-%.2f", min(r, na.rm = TRUE), max(r, na.rm = TRUE))))
setorder(agree, -n_significant)
fwrite(agree, file.path(OUT, "tables", "tbl_v2_species_fast_compare.csv"))
print(agree)

# ---- 循环性演示: 把中国省数加进 M1, 看它如何吞掉全球范围效应 ----
m_circ <- glmmTMB(as.formula(paste("new_record_v2 ~", FX, "+ z_log_range_provinces + (1|order_f/family_f/genus_f)")),
                  data = d, family = binomial())
sc <- summary(m_circ)$coefficients$cond
circ <- data.table(term = c("z_log_range (global range size)", "z_log_range_provinces (Chinese provinces)"),
                   odds_ratio = exp(sc[c("z_log_range", "z_log_range_provinces"), 1]),
                   p_value = sc[c("z_log_range", "z_log_range_provinces"), 4])
fwrite(circ, file.path(OUT, "tables", "tbl_v2_species_range_circularity.csv"))
msg("循环性演示: 全球范围 OR=", round(circ$odds_ratio[1], 3), " (P=", signif(circ$p_value[1], 2),
    ") | 中国省数 OR=", round(circ$odds_ratio[2], 3), " (P=", signif(circ$p_value[2], 2), ")")

fit <- data.table(model = c("M1 taxonomic nesting", "M2 phylogenetic eigenvectors", "M3 phyloglm"),
                  AIC = c(AIC(m1), AIC(m2), if (!is.null(m3)) AIC(m3) else NA_real_),
                  note = c("(1|order/family/genus)",
                           sprintf("%d eigenvectors, %.1f%% of phylogenetic distance", N_PV, pv$explained),
                           if (!is.null(m3)) sprintf("Ives & Garland logistic MPLE, alpha = %.3g", m3$alpha) else "failed"))
fwrite(fit, file.path(OUT, "tables", "tbl_v2_species_fast_fit.csv")); print(fit)

msg("三法一致(方向相同)的项: ", sum(agree$same_direction), " / ", nrow(agree),
    " | 三法均显著: ", sum(agree$n_significant == agree$n_models))
saveRDS(list(m1 = m1, m2 = m2, m3 = m3), file.path(OUT, "models", "species_fast_fits.rds"))
msg("DONE")
