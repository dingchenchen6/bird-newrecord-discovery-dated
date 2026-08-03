#!/usr/bin/env Rscript
# ============================================================
# Script 160: 气候代理指标的生态学重设定 —— 热极值、热暴露与生态位追踪
# Ecological re-specification of the climate proxy: thermal extremes,
# thermal exposure, and climatic-niche tracking
# ============================================================
# Scientific question / 科学问题:
#   主模型以【年均温的相对变暖】作为气候变化代理, 其隐含假设是
#   "越暖 => 越有利于新记录生成"(单调假设)。热生态位理论则预测
#   单峰响应: 只有当一地的热条件【向物种生态位中心靠拢】时定殖机会才打开,
#   越过生态位上端后反而形成热暴露压力。
#   若把代理指标换成热极值、生态位邻近度、生态位追踪量或热暴露量,
#   气候主效应与【气候 x 努力】交互效应是否依然成立?
#
# 指标族 / Indicator family (s=物种, p=省, t=年; 基线 1980-2000):
#   记 T(p,t) 省级面积加权气候值, T_b(p) 省基线;
#      N(s,t) 物种分布区均值,       N_b(s) 物种基线;
#      gap(s,p,t) = T(p,t) - N(s,t)  该省热条件相对该种生态位中心的位置
#
#   S0 tavg_annual  x  = [T-T_b] - [N-N_b] = gap(t) - gap_b   (主模型, 单调"越暖越好")
#   S1 tmax_warm    x  同上公式, 但 T/N 取最暖季最高温          (热极值)
#   S2 niche_prox   x  = -|gap(t)|                             (生态位邻近度, 水平量)
#   S3 niche_track  x  = -|gap(t)| + |gap_b|                   (生态位追踪, 单峰版的 S0)
#   S4 heat_exposure x = T_tmax(p,t) - N_tmax_b(s)             (热暴露: 超出该种历史热上端的度数)
#
#   S3 与 S0 的唯一差别是【是否假设单调】: S0 = gap 的有向变化,
#   S3 = |gap| 的变化(取负)。二者同量纲、同构造、同窗口, 因此可直接对比,
#   构成对"越暖越好"假设的干净检验。
#
#   每个指标一律沿用主口径的两分量分解:
#     clim_change = x 在 [t-W+1, t] 的滑动均值   累积信号
#     clim_var    = x(t) - clim_change(t)        年度偏离
#
# 冻结不变的部分 / Held fixed (使系数可比):
#   随机效应 R3 = (1|species) + (1|province) + (1|prov_year)
#   努力代理 eff_visits_gap_z; offset(log_completeness); family binomial(cloglog)
#   固定效应 event ~ clim_change_z * effort_z + clim_var_z
#   行集: 强制取所有规格共同可用的行(AIC 才可比)
#
# 附加模型 / Additional models:
#   S4M 以热暴露水平【调节】变暖效应: clim_change_z(S0) x exposure_level_z
#       检验"变暖只在尚未热超限之处促进新记录"
#   S3Q 生态位邻近度的二次项, 直接检验单峰
#
# Input / 输入:
#   analysis_v2/data/model_v2_thr50.parquet                (132)
#   analysis_final/data/panel_full_{grid,species}.csv      (120)
#   analysis_rebuilt/data/grid_province_lookup.csv         (含 olap 面积权重)
#
# Output / 输出:
#   analysis_v2/tables/tbl_v2_niche_spec_coefs.csv   全部规格的系数(含 95% CI)
#   analysis_v2/tables/tbl_v2_niche_spec_fit.csv     拟合优度与指标描述统计
#   analysis_v2/tables/tbl_v2_niche_gap_structure.csv 生态位位置的分布结构
#
# Main packages / 主要包: data.table, arrow, glmmTMB
# 运行 / Run: Rscript --no-init-file code/160_thermal_niche_specs.R [W]
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)

ROOT <- normalizePath(".", mustWork = TRUE)
OUT  <- file.path(ROOT, "analysis_v2")
RB   <- file.path(ROOT, "analysis_rebuilt")
FN   <- file.path(ROOT, "analysis_final")
msg  <- function(...) cat(sprintf("[160 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

args   <- commandArgs(trailingOnly = TRUE)
W      <- if (length(args)) as.integer(args[1]) else 15L
EFFORT <- "eff_visits_gap_z"
RE_MAIN <- "(1|species) + (1|province) + (1|prov_year)"
YR_FROM <- 2002L; YR_TO <- 2024L
zs <- function(x) as.numeric(scale(x))
msg("累积窗口 W = ", W)

# ---- 1. 省级(面积加权)与物种级气候序列 ------------------------------------
gp  <- fread(file.path(FN, "data", "panel_full_grid.csv"))
g2p <- fread(file.path(RB, "data", "grid_province_lookup.csv"), encoding = "UTF-8")
gp  <- merge(gp, g2p[, .(grid_cell, province, olap)], by = "grid_cell")
prov <- gp[, .(T_t    = stats::weighted.mean(val,      olap, na.rm = TRUE),
               T_base = stats::weighted.mean(baseline, olap, na.rm = TRUE)),
           by = .(province, year, indicator)]
sp   <- fread(file.path(FN, "data", "panel_full_species.csv"))
nat  <- sp[, .(species, year, indicator, N_t = val, N_base = baseline)]
rm(gp); invisible(gc())

base <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
base[, c("x", "clim_change", "clim_var") := NULL]
base <- base[is.finite(get(EFFORT))]
base[, prov_year := interaction(province, year, drop = TRUE)]
pp <- unique(base[, .(species, province)])
msg("候选对 ", nrow(pp), " | 基础行 ", format(nrow(base), big.mark = ","))

# 把某个指标的省-年与种-年序列拼到候选对上 / join both series onto the pairs
pair_series <- function(ind) {
  cc <- merge(pp, prov[indicator == ind, .(province, year, T_t, T_base)],
              by = "province", allow.cartesian = TRUE)
  cc <- merge(cc, nat[indicator == ind, .(species, year, N_t, N_base)],
              by = c("species", "year"))
  setorder(cc, species, province, year)
  cc[]
}

# 由逐年 x 生成两分量 / turn an annual series x into the change/variability pair
components <- function(cc, W) {
  cc[, clim_change := frollmean(x, W, align = "right"), by = .(species, province)]
  cc[, clim_var := x - clim_change]
  cc[year >= YR_FROM & year <= YR_TO,
     .(species, province, year, x, clim_change, clim_var)]
}

msg("构建 5 组气候代理指标 ...")
S_tavg <- pair_series("tavg_annual")
S_tmax <- pair_series("tmax_warm")

# S0 主模型: 有向的相对变暖 / directional relative warming (monotonic assumption)
d0 <- copy(S_tavg)[, x := (T_t - T_base) - (N_t - N_base)]
# S1 热极值: 同构造, 换成最暖季最高温 / same construction on the warm-season maximum
d1 <- copy(S_tmax)[, x := (T_t - T_base) - (N_t - N_base)]
# S2 生态位邻近度(水平): 越接近 0 表示该省热条件越贴近该种生态位中心
d2 <- copy(S_tavg)[, x := -abs(T_t - N_t)]
# S3 生态位追踪: |gap| 的收敛量, S0 的单峰对应版 / unimodal counterpart of S0
d3 <- copy(S_tavg)[, x := -abs(T_t - N_t) + abs(T_base - N_base)]
# S4 热暴露: 省最暖季最高温相对该种历史热上端代理的位置(正 = 超出)
d4 <- copy(S_tmax)[, x := T_t - N_base]

SPECS <- list(
  S0_tavg_annual   = list(d = d0, lab = "S0 relative warming, annual mean (main)"),
  S1_tmax_warm     = list(d = d1, lab = "S1 relative warming, warmest-season max"),
  S2_niche_prox    = list(d = d2, lab = "S2 niche proximity level (-|gap|)"),
  S3_niche_track   = list(d = d3, lab = "S3 niche tracking (change in -|gap|)"),
  S4_heat_exposure = list(d = d4, lab = "S4 heat exposure (Tmax - species Tmax baseline)")
)

CMP <- lapply(SPECS, function(s) components(s$d, W))
for (nm in names(CMP)) setnames(CMP[[nm]], c("x", "clim_change", "clim_var"),
                                paste0(nm, c("_x", "_change", "_var")))

# ---- 2. 统一行集: 所有规格都非缺失才保留 (AIC 可比) -----------------------
d <- copy(base)
for (nm in names(CMP)) d <- merge(d, CMP[[nm]], by = c("species", "province", "year"), all.x = TRUE)
keep <- Reduce(`&`, lapply(names(CMP), function(nm)
  is.finite(d[[paste0(nm, "_change")]]) & is.finite(d[[paste0(nm, "_var")]])))
d <- d[keep]
msg("共同行集 ", format(nrow(d), big.mark = ","), " 行 | ", sum(d$event), " 事件 | ",
    uniqueN(d$species), " 种 | ", uniqueN(d$province), " 省")
d[, effort_z := zs(get(EFFORT))]

# ---- 3. 生态位位置的分布结构(解释 S2-S4 时必须先知道正负比例) -------------
gapinfo <- d[, .(gap_tavg = S0_tavg_annual_x, prox = S2_niche_prox_x, expo = S4_heat_exposure_x)]
gs <- data.table(
  quantity = c("gap = T_prov - N_species (annual mean, degC)",
               "niche proximity -|gap| (degC)",
               "heat exposure Tmax_prov - Tmax_species_base (degC)"),
  mean   = c(NA_real_, mean(gapinfo$prox), mean(gapinfo$expo)),
  q05    = c(NA_real_, quantile(gapinfo$prox, .05), quantile(gapinfo$expo, .05)),
  median = c(NA_real_, median(gapinfo$prox), median(gapinfo$expo)),
  q95    = c(NA_real_, quantile(gapinfo$prox, .95), quantile(gapinfo$expo, .95)),
  pct_positive = c(NA_real_, NA_real_, 100 * mean(gapinfo$expo > 0)))
# gap 本身(未取绝对值)的正负比例: 判断"省比物种生态位中心更热还是更冷"
gap_raw <- merge(unique(d[, .(species, province, year)]),
                 merge(merge(unique(d[, .(species, province)]),
                             prov[indicator == "tavg_annual", .(province, year, T_t)],
                             by = "province", allow.cartesian = TRUE),
                       nat[indicator == "tavg_annual", .(species, year, N_t)],
                       by = c("species", "year")),
                 by = c("species", "province", "year"))
gap_raw[, gap := T_t - N_t]
gs[1, `:=`(mean = mean(gap_raw$gap), q05 = quantile(gap_raw$gap, .05),
           median = median(gap_raw$gap), q95 = quantile(gap_raw$gap, .95),
           pct_positive = 100 * mean(gap_raw$gap > 0))]
gs[, (2:6) := lapply(.SD, round, 3), .SDcols = 2:6]
print(gs)
fwrite(gs, file.path(OUT, "tables", "tbl_v2_niche_gap_structure.csv"))

# ---- 4. 逐规格拟合(结构冻结, 只换气候变量) --------------------------------
tidy_fit <- function(m, spec, lab, extra = NA_character_) {
  cf <- summary(m)$coefficients$cond
  data.table(spec = spec, label = lab, term = rownames(cf),
             estimate = cf[, 1], se = cf[, 2], z = cf[, 3], p = cf[, 4],
             HR = exp(cf[, 1]),
             HR_lo = exp(cf[, 1] - 1.96 * cf[, 2]),
             HR_hi = exp(cf[, 1] + 1.96 * cf[, 2]),
             note = extra)
}

coefs <- list(); fits <- list()
for (nm in names(SPECS)) {
  dd <- copy(d)
  dd[, `:=`(clim_change_z = zs(get(paste0(nm, "_change"))),
            clim_var_z    = zs(get(paste0(nm, "_var"))))]
  f <- as.formula(paste("event ~ clim_change_z * effort_z + clim_var_z +",
                        "offset(log_completeness) +", RE_MAIN))
  t0 <- Sys.time()
  m <- tryCatch(glmmTMB(f, data = dd, family = binomial("cloglog")),
                error = function(e) { msg("  FAILED ", nm, ": ", conditionMessage(e)); NULL })
  if (is.null(m)) next
  coefs[[nm]] <- tidy_fit(m, nm, SPECS[[nm]]$lab)
  vc  <- glmmTMB::VarCorr(m)$cond
  fits[[nm]] <- data.table(
    spec = nm, label = SPECS[[nm]]$lab, window = W, n = nrow(dd), events = sum(dd$event),
    AIC = AIC(m), logLik = as.numeric(logLik(m)),
    sd_change_raw = sd(dd[[paste0(nm, "_change")]]),
    sd_var_raw    = sd(dd[[paste0(nm, "_var")]]),
    cor_change_var = cor(dd[[paste0(nm, "_change")]], dd[[paste0(nm, "_var")]]),
    re_terms = paste(sprintf("%s=%.3f", names(vc), vapply(vc, function(v) sqrt(v[1, 1]), 1)),
                     collapse = "; "))
  msg(sprintf("  %-17s AIC=%8.1f  [%.0fs]", nm, AIC(m),
              as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  saveRDS(m, file.path(OUT, "data", sprintf("fit_niche_%s_W%d.rds", nm, W)))
  rm(m, dd); invisible(gc())
}

# ---- 5. 附加模型 ----------------------------------------------------------
# S4M: 热暴露【水平】调节年均温变暖效应
#      Does warming only help where the province has not yet exceeded the
#      species' historical heat ceiling?
dd <- copy(d)
dd[, `:=`(clim_change_z = zs(S0_tavg_annual_change), clim_var_z = zs(S0_tavg_annual_var),
          exposure_z    = zs(S4_heat_exposure_change))]
f <- as.formula(paste("event ~ clim_change_z * effort_z + clim_change_z * exposure_z +",
                      "clim_var_z + offset(log_completeness) +", RE_MAIN))
t0 <- Sys.time()
m <- tryCatch(glmmTMB(f, data = dd, family = binomial("cloglog")), error = function(e) NULL)
if (!is.null(m)) {
  coefs[["S4M_exposure_moderates"]] <- tidy_fit(
    m, "S4M_exposure_moderates", "S4M warming x heat-exposure moderation")
  vc <- glmmTMB::VarCorr(m)$cond
  fits[["S4M_exposure_moderates"]] <- data.table(
    spec = "S4M_exposure_moderates", label = "S4M warming x heat-exposure moderation",
    window = W, n = nrow(dd), events = sum(dd$event), AIC = AIC(m),
    logLik = as.numeric(logLik(m)), sd_change_raw = NA_real_, sd_var_raw = NA_real_,
    cor_change_var = cor(dd$S0_tavg_annual_change, dd$S4_heat_exposure_change),
    re_terms = paste(sprintf("%s=%.3f", names(vc), vapply(vc, function(v) sqrt(v[1, 1]), 1)),
                     collapse = "; "))
  msg(sprintf("  %-17s AIC=%8.1f  [%.0fs]", "S4M", AIC(m),
              as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  saveRDS(m, file.path(OUT, "data", sprintf("fit_niche_S4M_W%d.rds", W)))
}
rm(m, dd); invisible(gc())

# S3Q: 生态位邻近度的二次项, 直接检验单峰响应
dd <- copy(d)
dd[, `:=`(clim_change_z = zs(S2_niche_prox_change), clim_var_z = zs(S2_niche_prox_var))]
dd[, clim_change_z2 := clim_change_z^2]
f <- as.formula(paste("event ~ clim_change_z * effort_z + clim_change_z2 + clim_var_z +",
                      "offset(log_completeness) +", RE_MAIN))
t0 <- Sys.time()
m <- tryCatch(glmmTMB(f, data = dd, family = binomial("cloglog")), error = function(e) NULL)
if (!is.null(m)) {
  coefs[["S2Q_niche_prox_quad"]] <- tidy_fit(
    m, "S2Q_niche_prox_quad", "S2Q niche proximity with quadratic term")
  vc <- glmmTMB::VarCorr(m)$cond
  fits[["S2Q_niche_prox_quad"]] <- data.table(
    spec = "S2Q_niche_prox_quad", label = "S2Q niche proximity with quadratic term",
    window = W, n = nrow(dd), events = sum(dd$event), AIC = AIC(m),
    logLik = as.numeric(logLik(m)), sd_change_raw = sd(dd$S2_niche_prox_change),
    sd_var_raw = sd(dd$S2_niche_prox_var),
    cor_change_var = cor(dd$S2_niche_prox_change, dd$S2_niche_prox_var),
    re_terms = paste(sprintf("%s=%.3f", names(vc), vapply(vc, function(v) sqrt(v[1, 1]), 1)),
                     collapse = "; "))
  msg(sprintf("  %-17s AIC=%8.1f  [%.0fs]", "S2Q", AIC(m),
              as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  saveRDS(m, file.path(OUT, "data", sprintf("fit_niche_S2Q_W%d.rds", W)))
}
rm(m, dd); invisible(gc())

# ---- 6. 导出 --------------------------------------------------------------
ct <- rbindlist(coefs)
ft <- rbindlist(fits)
ft[, dAIC := AIC - min(AIC[spec %in% names(SPECS)])]
setorder(ft, AIC)
sfx <- if (W == 15L) "" else sprintf("_W%d", W)
fwrite(ct, file.path(OUT, "tables", sprintf("tbl_v2_niche_spec_coefs%s.csv", sfx)))
fwrite(ft, file.path(OUT, "tables", sprintf("tbl_v2_niche_spec_fit%s.csv", sfx)))

cat("\n=== 拟合优度 / model fit ===\n")
print(ft[, .(spec, AIC = round(AIC, 1), dAIC = round(dAIC, 1),
             sd_change = round(sd_change_raw, 3), cor_cv = round(cor_change_var, 3))])
cat("\n=== 主效应与交互效应 / main and interaction effects ===\n")
print(ct[term != "(Intercept)", .(spec, term, HR = round(HR, 3),
         CI = sprintf("[%.3f, %.3f]", HR_lo, HR_hi), p = signif(p, 3))])
msg("wrote tbl_v2_niche_spec_coefs", sfx, ".csv / tbl_v2_niche_spec_fit", sfx, ".csv | DONE")
