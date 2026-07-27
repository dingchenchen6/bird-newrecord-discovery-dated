#!/usr/bin/env Rscript
# ============================================================
# Script 148: 物种水平分析(仿 Ding et al. 2025 GEB 哺乳动物框架)
# Species-level analysis, following the mammal framework of Ding et al. 2025 GEB
# ============================================================
# 科学问题 / Scientific question:
#   在中国鸟类物种池中, 哪些物种更可能产生省级新分布记录? 这是与风险模型
#   互补的一层: 风险模型问"某物种在某省某年的风险", 本分析问"物种本身的
#   属性如何决定它是否会被新记录到", 对应 GEB 原文的 Hypothesis 1。
#
# 与 GEB 原文的对应 / Correspondence with the mammal paper:
#   同: 二元响应(是否有新纪录) | Bayesian 系统发育 GLMM | brms + 系统发育协方差
#       连续变量 log10 变换后标准化 | VIF < 5 | 分类变量另做列联分析
#       R-hat < 1.01, ESS > 1000, pp_check, LOO 比较 | ZINB 计数模型作敏感性
#   异: 性状换成鸟类对应物 ——
#       体重 mass_g               <- 同(体型: 小体型历史上被研究得少)
#       手翼指数 hwi              <- 替代原文的"活动节律"位置, 是鸟类扩散能力的
#                                    标准代理(Sheard et al. 2020); 扩散力强的物种
#                                    更可能出现在分布区之外
#       分布省数 range_provinces  <- 替代原文的 range size(在省级研究中更直接)
#       窝卵数 clutch_size        <- 生活史快慢轴, 原文无对应但对鸟类适用
#       同属物种数 n_congeners    <- 同(分类学复杂度)
#       迁徙类型 migration_class  <- 鸟类特有, 替代原文的活动节律作为分类变量
#       特有性 endemic_status     <- 同
#       食性 diet_group           <- 同(原文的 diet 类别)
#       森林依赖 forest_association <- 替代原文的 habitat breadth
#
# ★ 关键改动 / The key change from the earlier bird adaptation:
#   响应变量改用【发现年定年】的 v2 事件集(2002-2024, 657 事件, 374 物种),
#   而非发表年定年。前期鸟类适配用的是发表年口径, 二元响应有 486 个 1。
#
# Input / 输入:
#   analysis_v2/data/events_discovery_dated.csv
#   bird_geb_species_province_joint_v2/data_derived/species_continuous_model_data.csv
#   bird_geb_species_province_joint_v2/data_derived/event_species_tree_crosswalk.csv
#   Clements 2023 dated Aves tree (nexus)
# Output / 输出:
#   analysis_v2/tables/tbl_v2_species_level_{effects,loo,contingency,vif}.csv
#   analysis_v2/models/brms_species_v2_*.rds
#
# Main packages / 主要包: brms, ape, data.table, car
# 运行 / Run: Rscript --no-init-file code/148_species_level_geb.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ape); library(brms)
})
options(warn = 1); set.seed(42)

V2  <- normalizePath(".", mustWork = TRUE)
OUT <- file.path(V2, "analysis_v2")
MOD <- file.path(OUT, "models"); dir.create(MOD, showWarnings = FALSE, recursive = TRUE)
GEB <- "/Users/dingchenchen/Documents/New project/bird_geb_species_province_joint_v2_20260723"
TREE <- "/Users/dingchenchen/Documents/New project/bird_phylogeny_new_records_mctavish_work/data/external/summary_dated_clements_Aves_1.4_Clements2023.nex"
msg <- function(...) cat(sprintf("[148 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

# 连续性状 / continuous traits (log10 then standardised, as in the mammal paper)
CONT <- c(log_mass       = "mass_g_final",       # 体型: 小体型历史上研究少、更易被漏记
          log_hwi        = "hwi_final",          # 手翼指数: 扩散能力(AVONET)
          log_range      = "provinces_final",    # 分布省数: 已知分布范围
          log_clutch     = "clutch_final",       # 窝卵数: 生活史快慢轴
          log_congeners  = "n_congeners",        # 同属种数: 分类学复杂度
          log_habbreadth = "habitat_breadth",    # 栖息地宽度(BIRDBASE HB: 使用的主要生境数)
          log_dietbreadth = "diet_breadth")      # 食性宽度(BIRDBASE DB: 取食的主要食物类型数)
# 分类性状 / categorical traits
CATS <- c("migration_final", "trophic_niche", "habitat_density", "iucn_group", "endemic_final")

# ---- 1. 物种池(1445 种) 与 v2 响应(均在脚本 151 中建好) ----
d <- fread(file.path(OUT, "data", "species_traits_harmonised_v2.csv"))
msg("物种池 ", nrow(d), " 种(中国鸟类生态学性状数据库) | 有新纪录 ", sum(d$new_record_v2),
    " | 计入事件 ", sum(d$n_new_records_v2))

d[, migration_final := factor(migration_final, levels = c("Resident", "Partial migrant", "Migratory"))]
d[, trophic_niche   := factor(trophic_niche,
     levels = c("Invertivore", "Omnivore", "Aquatic predator", "Granivore",
                "Vertivore/Scavenger", "Frugivore/Nectarivore", "Herbivore"))]
d[, habitat_density := factor(habitat_density, levels = c("Dense", "Semi-open", "Open"))]
d[, iucn_group      := factor(iucn_group, levels = c("Least Concern", "Near Threatened", "Threatened"))]
d[, endemic_final   := factor(endemic_final, levels = c("Non-endemic", "Endemic"))]

IMP_COLS <- intersect(paste0(c(unname(CONT), CATS), "_imputed"), names(d))
d[, any_imputed := Reduce(`|`, lapply(IMP_COLS, function(v) as.logical(d[[v]])))]
msg("主用性状含插补值的物种: ", sum(d$any_imputed), " / ", nrow(d),
    sprintf(" (%.1f%%)", 100 * mean(d$any_imputed)))

# ---- 2. 变量变换: log10 + 标准化(与 GEB 一致) ----
for (nm in names(CONT)) d[[nm]] <- log10(as.numeric(d[[CONT[[nm]]]]) + 1)
for (nm in names(CONT)) d[[paste0("z_", nm)]] <- as.numeric(scale(d[[nm]]))
# 空字符串是"性状数据缺失", 不是一个生态类别。与本研究其他处一致, 改标为
# Unknown 并在结果中标注为不可解释的数据可得性类别, 而不是悄悄当成参照组。
# NB: blank levels are missing trait data, not an ecological class.
for (v in CATS) {
  x <- as.character(d[[v]]); lv0 <- levels(d[[v]])
  x[is.na(x) | !nzchar(x)] <- "Unknown"
  lv <- c(intersect(lv0, unique(x)), if ("Unknown" %in% x) "Unknown")
  d[[v]] <- factor(x, levels = lv)
}

Z <- paste0("z_", names(CONT))
msg("连续变量: ", paste(Z, collapse = ", "))
for (v in CATS) msg("  ", v, ": ", paste(sprintf("%s=%d", levels(d[[v]]), table(d[[v]])), collapse = " | "))

# VIF(与 GEB 一样以 < 5 为保留标准)
vif_tab <- tryCatch({
  m0 <- glm(as.formula(paste("new_record_v2 ~", paste(Z, collapse = " + "))), data = d, family = binomial())
  v <- car::vif(m0); data.table(variable = names(v), VIF = as.numeric(v))
}, error = function(e) { msg("  VIF 失败: ", conditionMessage(e)); NULL })
if (!is.null(vif_tab)) { print(vif_tab); fwrite(vif_tab, file.path(OUT, "tables", "tbl_v2_species_vif.csv")) }

# ---- 3. 系统发育协方差 ----
# 1445 个池中有 1312 个能精确匹配 Clements 2023 树; 其余为该树未收录的名字,
# 系统发育模型只能用这 1312 个。二元响应中被排除的事件物种数一并报告。
tree <- ape::read.nexus(TREE)
d <- d[!is.na(tree_label) & nzchar(tree_label)]
msg("有系统树标签的物种: ", nrow(d), " | 其中有新纪录 ", sum(d$new_record_v2))
keep <- intersect(tree$tip.label, d$tree_label)
tree_sub <- ape::drop.tip(tree, setdiff(tree$tip.label, keep))
A <- ape::vcv.phylo(tree_sub, corr = TRUE)
d <- d[tree_label %in% rownames(A)]
setorder(d, tree_label)
d <- d[match(rownames(A), tree_label)]
d[, phylo_species := factor(tree_label, levels = rownames(A))]
stopifnot(identical(as.character(d$phylo_species), rownames(A)))
msg("系统发育协方差: ", nrow(A), " 个物种 | 建模集 ", nrow(d), " 行 / ", sum(d$new_record_v2), " 个 1")
saveRDS(A, file.path(MOD, "phylo_corr_v2.rds"))

# ---- 4. brms 模型 ----
PHY <- "(1 | gr(phylo_species, cov = A))"
f_joint <- as.formula(paste("new_record_v2 ~", paste(c(Z, CATS), collapse = " + "), "+", PHY))
f_cont  <- as.formula(paste("new_record_v2 ~", paste(Z, collapse = " + "), "+", PHY))
f_cat   <- as.formula(paste("new_record_v2 ~", paste(CATS, collapse = " + "), "+", PHY))

fit_b <- function(f, tag, fam = bernoulli(), ad = 0.98, td = 13) {
  msg("  拟合 ", tag, " ...")
  brm(f, data = d, family = fam, data2 = list(A = A),
      prior = c(prior(normal(0, 2), class = "b"), prior(normal(0, 5), class = "Intercept")),
      chains = 4, cores = 4, iter = 4000, warmup = 1000, seed = 42,
      control = list(adapt_delta = ad, max_treedepth = td),
      file = file.path(MOD, tag), file_refit = "on_change", refresh = 0)
}
m_joint <- fit_b(f_joint, "brms_species_v2_joint")
m_cont  <- fit_b(f_cont,  "brms_species_v2_continuous")
m_cat   <- fit_b(f_cat,   "brms_species_v2_categorical")

# 计数敏感性: 零膨胀负二项 / count sensitivity
f_cnt <- as.formula(paste("n_new_records_v2 ~", paste(c(Z, CATS), collapse = " + "), "+", PHY))
m_cnt <- tryCatch(fit_b(f_cnt, "brms_species_v2_zinb", zero_inflated_negbinomial(), 0.99, 14),
                  error = function(e) { msg("  ZINB 失败: ", conditionMessage(e)); NULL })

# ---- 5. 效应量与诊断 ----
eff_of <- function(m, tag) {
  if (is.null(m)) return(NULL)
  s <- summary(m)$fixed
  dt <- as.data.table(s, keep.rownames = "term")
  setnames(dt, c("Estimate", "Est.Error", "l-95% CI", "u-95% CI", "Rhat", "Bulk_ESS", "Tail_ESS"),
           c("estimate", "se", "lo95", "hi95", "Rhat", "ESS_bulk", "ESS_tail"), skip_absent = TRUE)
  dt[, model := tag]
  dt[, significant := (lo95 > 0 & hi95 > 0) | (lo95 < 0 & hi95 < 0)]
  dt[, odds_ratio := exp(estimate)]
  dt[grepl("Unknown", term), significant := NA]   # 缺失类别不作解释
  dt[, `:=`(OR_lo = exp(lo95), OR_hi = exp(hi95))]
  dt[]
}
eff <- rbindlist(lapply(list(list(m_joint, "joint"), list(m_cont, "continuous_only"),
                             list(m_cat, "categorical_only"), list(m_cnt, "count_zinb")),
                        function(x) eff_of(x[[1]], x[[2]])), fill = TRUE)
fwrite(eff, file.path(OUT, "tables", "tbl_v2_species_level_effects.csv"))
msg("收敛: 最大 Rhat = ", round(max(eff$Rhat, na.rm = TRUE), 4),
    " | 最小 ESS_bulk = ", round(min(eff$ESS_bulk, na.rm = TRUE)))
print(eff[model == "joint" & term != "Intercept",
          .(term, estimate = round(estimate, 3), lo95 = round(lo95, 3), hi95 = round(hi95, 3),
            OR = round(odds_ratio, 3), significant)])

# LOO 比较
loos <- lapply(list(joint = m_joint, continuous_only = m_cont, categorical_only = m_cat),
               function(m) tryCatch(loo(m), error = function(e) NULL))
loos <- loos[!vapply(loos, is.null, logical(1))]
if (length(loos) > 1) {
  lc <- as.data.table(loo_compare(loos), keep.rownames = "model")
  fwrite(lc, file.path(OUT, "tables", "tbl_v2_species_level_loo.csv")); print(lc)
}

# ---- 6. 分类变量的列联分析(GEB 2.2.1 的做法) ----
ct <- rbindlist(lapply(CATS, function(v) {
  tb <- table(d[[v]], d$new_record_v2)
  if (nrow(tb) < 2 || ncol(tb) < 2) return(NULL)
  ex <- suppressWarnings(chisq.test(tb))
  use_fisher <- any(ex$expected < 5)
  p <- if (use_fisher) fisher.test(tb, simulate.p.value = TRUE, B = 10000)$p.value else ex$p.value
  sr <- ex$stdres[, "1"]
  data.table(variable = v, level = rownames(tb), n_without = tb[, "0"], n_with = tb[, "1"],
             pct_with = round(100 * tb[, "1"] / rowSums(tb), 1),
             std_residual = round(as.numeric(sr), 2),
             test = if (use_fisher) "Fisher (Monte Carlo, B=10000)" else "Pearson chi-square",
             statistic = round(unname(ex$statistic), 2), p_value = p)
}), fill = TRUE)
ct[, p_holm := p.adjust(p_value, method = "holm"), by = variable]
ct[, over_represented := std_residual > 1.96 & p_holm < 0.05]
ct[level == "Unknown", `:=`(over_represented = NA, note = "missing trait data, not an ecological class")]
fwrite(ct, file.path(OUT, "tables", "tbl_v2_species_contingency.csv"))
print(ct[, .(variable, level, n_with, pct_with, std_residual, p_holm = signif(p_holm, 3), over_represented)])

fwrite(d[, c("tree_label", "latin", "order_cn", "family_cn", "n_new_records_v2", "new_record_v2",
             names(CONT), Z, CATS, "esi", "any_imputed"), with = FALSE],
       file.path(OUT, "data", "species_level_model_data_v2.csv"))
msg("wrote species-level tables and model data | DONE")
