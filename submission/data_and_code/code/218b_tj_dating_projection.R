#!/usr/bin/env Rscript
# ============================================================
# Script 218b: 顶刊版图件 —— 定年校正 与 机制模型 vs 机器学习
# Top-journal redesign: dating correction; mechanistic vs ML agreement
# ============================================================
# Scientific question / 科学问题:
#   (1) 按发表年定年是否制造了虚假的末端激增? 改按发现年定年是否是改变
#       努力效应估计的决定性校正?
#   (2) 机制风险模型与 XGBoost 在观测协变量范围内是否一致? 未来情景离开
#       拟合支撑域后两者是否分歧?
#   (1) Does publication-year dating create a spurious terminal surge, and is
#       re-dating by discovery year the decisive correction?
#   (2) Do the mechanistic hazard model and XGBoost agree inside the observed
#       covariate range and diverge once future scenarios leave it?
#
# Objective / 分析目标:
#   不改变任何绘图数值, 按共享顶刊规范(218 主题)重绘 Fig2_dating_correction_v2
#   (code/139) 与 FigM4_mech_vs_ml_agreement_v2 (code/141)。
#   Redraw the two figures in the shared top-journal style without changing
#   any plotted value.
#
# Input data / 输入数据:
#   analysis_v2/tables/: tbl_publication_lag, tbl_reporting_completeness,
#     tbl_change_decomposition, tbl_dating_comparison,
#     tbl_v2_future_province_projection (141 持久化的省级投影 / persisted by 141)
#   analysis_v2/data/: model_v2_thr50.parquet, components_v2_tavg_annual_W15.parquet,
#     fit_R3.rds, xgb_v2.rds (只读, 不重拟合 / read only, never refitted)
#   analysis_species_specific/tables/tbl_F_cmip6_delta.csv
#
# Main workflow / 主要流程:
#   1. 原样复制 139/141 的数据准备代码 / copy 139/141 data preparation verbatim
#   2. 与原图 source data 和原副标题数字逐值核对 / check against original values
#   3. 按 218 主题重绘各面板 / redraw panels in the 218 style
#   4. 导出整图、单面板、长格式 source data / export figure, panels, source data
#
# Expected output / 预期输出:
#   TJ_Fig_dating_correction.{pdf,png,svg} (183 x 115 mm)
#   TJ_Fig_mech_vs_ml.{pdf,png,svg}        (183 x 125 mm)
#   panels/TJ_Fig_*_{a,b,c}.*; source_data_TJ_Fig_*.csv
#
# Key assumptions / 关键假设:
#   绘图数值与原图一致。FigM4a(省-年平均预测风险)与 FigM4b(协变量分位数)原脚本
#   未持久化, 故以 141 原代码从已保存的模型对象与输入确定性重算: 仅样本内预测与
#   协变量构造, 不重拟合、不重跑未来投影; 并以原 source data 的 Spearman rho 校验。
#   FigM4a/b inputs were never persisted; they are recomputed deterministically
#   with 141's own code (in-sample prediction and covariate construction only;
#   no refit, no re-projection) and checked against the original source data.
#
# Main packages / 主要包: data.table, arrow, ggplot2, patchwork, glmmTMB, xgboost, colorspace
# Output directory / 输出路径: analysis_v2/figures_topjournal/ (+ panels/)
# Run / 运行: Rscript --no-init-file code/218b_tj_dating_projection.R  (cwd = task root)
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(glmmTMB); library(xgboost)
})
options(warn = 1)
source("code/218_theme_topjournal.R")   # TJ 调色板、主题、导出 / palette, theme, export

OUT <- file.path(TJ_V2, "analysis_v2"); TAB <- file.path(OUT, "tables")
SS  <- file.path(TJ_V2, "analysis_species_specific")
msg <- function(...) message(sprintf("[218b %s] ", format(Sys.time(), "%H:%M:%S")), ...)
source(file.path(TJ_V2, "code", "helper_projection_base.R"))   # 基期补齐 / base-year completion
rd  <- function(f) fread(file.path(TAB, f))

# ---- 0. 小工具 / helpers ----
FS    <- pt2mm(6)                                   # 面板内注释 6 pt / in-panel text
MINUS <- function(s) gsub("-", "\u2212", s, fixed = TRUE)   # 排版负号 / typographic minus
TXT_GREY <- colorspace::darken(TJ$neutral, 0.25)    # 灰色系列的文字需略深以保证可读 / legible grey text
# 直接标注防重叠: 迭代推开相距小于 gap 的标签 / push apart labels closer than `gap`
spread <- function(y, gap) {
  o <- order(y); s <- y[o]
  for (k in 1:100) {
    moved <- FALSE
    for (i in seq_along(s)[-1]) if (s[i] - s[i - 1] < gap) {
      sh <- (gap - (s[i] - s[i - 1])) / 2; s[i - 1] <- s[i - 1] - sh; s[i] <- s[i] + sh; moved <- TRUE
    }
    if (!moved) break
  }
  out <- numeric(length(y)); out[o] <- s; out
}

# ==========================================================================
# 图 1 / Figure 1: TJ_Fig_dating_correction (源自 139 的 Fig 2 / from 139 Fig 2)
# ==========================================================================
# ---- 1.1 数据(原样复制 139)/ data, verbatim from 139 ----
lag  <- rd("tbl_publication_lag.csv"); comp <- rd("tbl_reporting_completeness.csv")
dec  <- rd("tbl_change_decomposition.csv"); cmp <- rd("tbl_dating_comparison.csv")
lag_bar <- lag[lag >= 0 & lag <= 12]                       # 139 的筛选 / 139 filter
comp[, lag_x := 2025 - year]                               # 139 的映射 x = 2025 - year

ts <- rbind(cmp[!is.na(new_year), .(year = new_year, dating = "Discovery year (v2)")],
            cmp[!is.na(old_year), .(year = old_year, dating = "Publication year (v1)")])[, .N, by = .(year, dating)]

wf <- melt(dec[, .(step, `Survey effort` = HR_effort, `Accumulated warming` = HR_change,
                   `Annual climate variability` = HR_var, `Warming x effort` = HR_int)], id.vars = "step")
wf[, step := factor(step, levels = dec$step)][, sx := as.integer(step)]
wf[, variable := as.character(variable)]

# ---- 1.2 核对原副标题中的数字 / verify the numbers quoted in the original subtitles ----
# 原图副标题为手写常数; 此处由表重算, 不一致即中止
# The original subtitles were typed constants; recompute and stop on any mismatch
lag_all <- rep(lag$lag, lag$N)
LAG_MED <- median(lag_all); LAG_MEAN <- mean(lag_all); LAG_GE1 <- 100 * mean(lag_all >= 1)
CHG_PCT <- 100 * cmp[!is.na(new_year) & !is.na(old_year), mean(new_year != old_year)]
stopifnot(LAG_MED == 1, sprintf("%.2f", LAG_MEAN) == "2.09", sprintf("%.1f", LAG_GE1) == "81.7",
          sprintf("%.1f", CHG_PCT) == "83.1")
src0 <- fread(file.path(OUT, "figures", "source_data_Fig2_dating_correction_v2.csv"))
stopifnot(isTRUE(all.equal(src0[, .(HR_effort, HR_change, HR_var, HR_int)],
                           dec[, .(HR_effort, HR_change, HR_var, HR_int)], tolerance = 1e-12)))
msg("Fig dating: subtitle numbers and HR table match the original")

# ---- 1.3 面板 a: 发表滞后与报告完整度 / panel a: lag and completeness ----
p_da <- ggplot() +
  geom_col(data = lag_bar, aes(lag, pct), fill = TJ$neutral, width = 0.75) +
  geom_line(data = comp, aes(lag_x, 100 * completeness), colour = TJ$obs, linewidth = 0.5) +
  geom_point(data = comp, aes(lag_x, 100 * completeness), colour = TJ$obs, size = 1.1) +
  annotate("text", x = 6.6, y = 86, label = "Reporting completeness c(t)",
           colour = TJ$obs, size = FS, hjust = 0) +
  # 柱的标签与滞后统计量成组放在最高柱右侧 / bar label and lag statistics grouped beside the tallest bar
  annotate("text", x = 1.65, y = lag_bar[lag == 1, pct], label = "Publication lag",
           colour = TXT_GREY, size = FS, hjust = 0) +
  annotate("text", x = 1.65, y = lag_bar[lag == 1, pct] - 4.5, hjust = 0, vjust = 1, size = FS,
           colour = TJ$subink, lineheight = 1,
           label = sprintf("Median %g yr; mean %.2f yr\n%.1f%% lagged \u2265 1 yr", LAG_MED, LAG_MEAN, LAG_GE1)) +
  scale_x_continuous(breaks = seq(0, 20, 5), expand = expansion(add = 0.7)) +
  scale_y_continuous(breaks = seq(0, 100, 25), limits = c(0, 100), expand = expansion(mult = c(0, 0.04))) +
  labs(x = "Years between discovery and publication", y = "Per cent",
       title = "Records reach print years after discovery") +
  theme_tj()

# ---- 1.4 面板 b: 两种定年的年序列 / panel b: annual series under both datings ----
DAT_COL <- c("Discovery year (v2)" = TJ$ink, "Publication year (v1)" = TJ$neutral)
DAT_LTY <- c("Discovery year (v2)" = "solid", "Publication year (v1)" = "22")
pk_dis <- ts[dating == "Discovery year (v2)"][which.max(N)]          # 2019 峰值 / peak
end_pub <- ts[dating == "Publication year (v1)"][which.max(year)]    # 2024 末端 / end point
p_db <- ggplot(ts, aes(year, N, colour = dating, linetype = dating)) +
  annotate("rect", xmin = 2021.5, xmax = 2024.5, ymin = -Inf, ymax = Inf, fill = TJ$band) +
  annotate("text", x = 2023, y = 1.5, label = "Right-\ncensored", vjust = 0, size = FS,
           colour = TJ$subink, lineheight = 0.9) +
  geom_line(linewidth = 0.5) +
  geom_point(size = 1.1) +
  annotate("text", x = pk_dis$year - 0.45, y = pk_dis$N, label = "Discovery year", hjust = 1,
           size = FS, colour = TJ$ink) +
  annotate("text", x = end_pub$year - 0.45, y = end_pub$N + 3, label = "Publication year", hjust = 1,
           size = FS, colour = TXT_GREY) +
  annotate("text", x = 2001.6, y = 74, hjust = 0, vjust = 1, size = FS, colour = TJ$subink, lineheight = 1,
           label = sprintf("%.1f%% of records\nchange year", CHG_PCT)) +
  scale_colour_manual(values = DAT_COL, guide = "none") +
  scale_linetype_manual(values = DAT_LTY, guide = "none") +
  scale_x_continuous(breaks = seq(2005, 2020, 5), expand = expansion(add = 0.6)) +
  scale_y_continuous(breaks = seq(0, 60, 20), limits = c(0, 75), expand = expansion(mult = c(0, 0.02))) +
  labs(x = "Year", y = "New provincial records",
       title = "Publication-year dating fakes a terminal surge") +
  theme_tj()

# ---- 1.5 面板 c: 规格阶梯上的风险比 / panel c: HR along specification steps ----
STEP_LAB <- c(S0 = "S0\nas published", S1 = "S1\ndiscovery year", S2 = "S2\neffort gaps",
              S3 = "S3\narea weights", S4 = "S4\noffset", S5 = "S5\nprovince \u00d7 year")
TERM_SHOW <- c("Survey effort" = "Survey effort", "Accumulated warming" = "Accumulated warming",
               "Annual climate variability" = "Annual climate variability",
               "Warming x effort" = "Warming \u00d7 effort")
end_lab <- wf[step == "S5"][, y_lab := spread(value, gap = 0.075)]
end_lab[, txt_col := fifelse(TERM_COL[variable] == TJ$neutral, TXT_GREY, unname(TERM_COL[variable]))]
eff01 <- wf[variable == "Survey effort" & step %in% c("S0", "S1")]
p_dc <- ggplot(wf, aes(sx, value, colour = variable)) +
  annotate("rect", xmin = 1, xmax = 2, ymin = -Inf, ymax = Inf, fill = TJ$band) +
  annotate("text", x = 1.5, y = 1.86, label = "Re-dating", size = FS, colour = TJ$subink) +
  # 参考线止于 S5, 不穿过右侧直接标注 / reference line stops at S5, clear of the labels
  annotate("segment", x = 0.75, xend = 6.05, y = 1, yend = 1, linetype = "dashed",
           colour = TJ$neutral, linewidth = 0.25) +
  geom_line(linewidth = 0.5) +
  geom_point(size = 1.4) +
  # 灰色项的文字加深以保证可读 / darker text for the grey term
  geom_text(data = end_lab, aes(x = 6.16, y = y_lab, label = TERM_SHOW[variable]),
            colour = end_lab$txt_col, hjust = 0, size = FS) +
  geom_text(data = eff01, aes(x = sx + c(-0.09, -0.1), y = value + c(0, -0.045),
                              label = sprintf("%.2f", value)), hjust = 1, size = FS) +
  scale_colour_manual(values = TERM_COL, guide = "none") +
  scale_x_continuous(breaks = 1:6, labels = STEP_LAB, limits = c(0.6, 7.45), expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(0.8, 1.8, 0.2), limits = c(0.82, 1.9), expand = c(0, 0)) +
  guides(x = guide_axis(cap = "both")) +
  labs(x = NULL, y = "Hazard ratio per 1 SD", title = "Re-dating is the single decisive correction") +
  theme_tj() + theme(axis.text.x = element_text(lineheight = 1.05))

# ---- 1.6 组装与导出 / assemble and export ----
fig_d <- (p_da | p_db) / p_dc + plot_layout(heights = c(1, 1.02)) + tj_tags()
tj_save(fig_d, "TJ_Fig_dating_correction", 183, 115)
tj_panel(p_da, "TJ_Fig_dating_correction_a", 110, 80)
tj_panel(p_db, "TJ_Fig_dating_correction_b", 110, 80)
tj_panel(p_dc, "TJ_Fig_dating_correction_c", 170, 85)

tj_source(rbindlist(list(
  lag_bar[, .(panel = "a", series = "publication lag (% of records)", x = lag, x_label = as.character(lag), y = pct)],
  comp[, .(panel = "a", series = "reporting completeness c(t) (%)", x = lag_x, x_label = paste0("discovery year ", year),
           y = 100 * completeness)],
  data.table(panel = "a", series = "annotation", x = NA_real_,
             x_label = c("median lag (yr)", "mean lag (yr)", "lagged >= 1 yr (%)"), y = c(LAG_MED, LAG_MEAN, LAG_GE1)),
  ts[order(dating, year), .(panel = "b", series = sub(" \\(v[12]\\)", "", dating), x = year,
                            x_label = as.character(year), y = N)],
  data.table(panel = "b", series = "annotation", x = c(2021.5, 2024.5, NA),
             x_label = c("censored band start", "censored band end", "records changing year (%)"),
             y = c(NA, NA, CHG_PCT)),
  wf[order(variable, sx), .(panel = "c", series = variable, x = sx,
                            x_label = as.character(step), y = value)]
)), "TJ_Fig_dating_correction")
msg("Fig dating written")

# ==========================================================================
# 图 2 / Figure 2: TJ_Fig_mech_vs_ml (源自 141 的 FigM4 / from 141 FigM4)
# ==========================================================================
# ---- 2.1 数据与模型(原样复制 141 第 1–2 节)/ data and models, verbatim from 141 ----
EFF_GROW <- c(ssp245 = 0.30, ssp585 = 0.60)
FEATS <- c("clim_change_z", "clim_var_z", "effort_z")
d <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
d[, c("x", "clim_change", "clim_var") := NULL]
cc <- as.data.table(read_parquet(file.path(OUT, "data", "components_v2_tavg_annual_W15.parquet")))
d <- merge(d, cc[, .(species, province, year, clim_change, clim_var)], by = c("species", "province", "year"))
full <- d[is.finite(clim_change) & is.finite(clim_var)]            # 基期补齐用 / for the base year
d <- full[is.finite(eff_visits_gap_z)]
CC_MU <- mean(d$clim_change); CC_SD <- stats::sd(d$clim_change)
CV_MU <- mean(d$clim_var);    CV_SD <- stats::sd(d$clim_var)
EF_MU <- mean(d$eff_visits_gap_z); EF_SD <- stats::sd(d$eff_visits_gap_z)
d[, `:=`(clim_change_z = (clim_change - CC_MU) / CC_SD,
         clim_var_z    = (clim_var - CV_MU) / CV_SD,
         effort_z      = (eff_visits_gap_z - EF_MU) / EF_SD,
         prov_year     = interaction(province, year, drop = TRUE))]

# 只读取已保存模型, 不重拟合 / saved models are read, never refitted
mech <- readRDS(file.path(OUT, "data", "fit_R3.rds"))
bst  <- readRDS(file.path(OUT, "data", "xgb_v2.rds"))
BETA  <- fixef(mech)$cond
RE    <- ranef(mech)$cond
INT_NM <- grep(":", names(BETA), value = TRUE)[1]
blup <- function(tbl, keys) {
  v <- setNames(tbl[[1]], rownames(tbl))
  out <- unname(v[as.character(keys)]); out[is.na(out)] <- 0; out
}
pred_mech <- function(nd) {
  X <- cbind(1, nd$clim_change_z, nd$effort_z, nd$clim_var_z, nd$clim_change_z * nd$effort_z)
  colnames(X) <- c("(Intercept)", "clim_change_z", "effort_z", "clim_var_z", INT_NM)
  eta <- as.numeric(X[, names(BETA), drop = FALSE] %*% BETA) +
         blup(RE$species, nd$species) + blup(RE$province, nd$province)
  1 - exp(-exp(eta))
}

# 未来协变量(仅构造协变量, 不做模型投影)/ future covariates only, no model projection
cm6 <- fread(file.path(SS, "tables", "tbl_F_cmip6_delta.csv"))
dp <- cm6[unit == "province", .(province = name, ssp, horizon, d_prov = delta)]
ds <- cm6[unit == "species",  .(species  = name, ssp, horizon, d_sp   = delta)]
# 基期: 可用行 + 下载缺口省份(广东 2024, 努力沿用 2023), 后者只用于预测, 不进入标准化常数与支撑域
# base: usable rows + download-gap provinces (Guangdong 2024, effort from 2023); prediction only
gb <- gap_base_rows(full, max(d$year), file.path(OUT, "data", "effort_panel_v2.csv"))
gb[, `:=`(clim_change_z = (clim_change - CC_MU) / CC_SD,
          clim_var_z    = (clim_var - CV_MU) / CV_SD,
          effort_z      = (eff_visits_gap_z - EF_MU) / EF_SD,
          prov_year     = interaction(province, year, drop = TRUE))]
base_yr <- rbind(d[year == max(year)], gb, fill = TRUE)
proj <- rbindlist(lapply(c("ssp245", "ssp585"), function(sp_)
  rbindlist(lapply(c(2030L, 2050L, 2080L), function(hz) {
    b <- copy(base_yr)
    b <- merge(b, dp[ssp == sp_ & horizon == hz, .(province, d_prov)], by = "province", all.x = TRUE)
    b <- merge(b, ds[ssp == sp_ & horizon == hz, .(species, d_sp)],   by = "species",  all.x = TRUE)
    b[is.na(d_prov), d_prov := 0]; b[is.na(d_sp), d_sp := 0]
    b[, clim_change_f := clim_change + (d_prov - d_sp)]          # delta 施加两端 / both ends
    b[, clim_change_z := (clim_change_f - CC_MU) / CC_SD]
    b[, effort_z := effort_z + EFF_GROW[[sp_]] * (hz - max(d$year)) / 10]
    b[, `:=`(ssp = sp_, horizon = hz)]; b
  }))))

# ---- 2.2 面板数据(原样复制 141 第 5 节)/ panel data, verbatim from 141 section 5 ----
# (a) 范围内: 观测行按省-年聚合 / in range: observed rows by province-year
# NB: d[, FEATS, with = FALSE] 与 141 的 d[, ..FEATS] 等价, 仅避免 data.table 警告
d[, p_mech_obs := pred_mech(d)]
d[, p_ml_obs   := as.numeric(predict(bst, as.matrix(d[, FEATS, with = FALSE])))]
inr <- d[, .(mech = mean(p_mech_obs), ml = mean(p_ml_obs)), by = .(province, year)]
r_in <- cor(inr$mech, inr$ml, method = "spearman")

# (b) 外推距离 / covariate ranges, 1st-99th percentile
rng <- rbind(
  data.table(feature = "Accumulated warming", src = "observed 2002-2024",
             lo = quantile(d$clim_change_z, .01), hi = quantile(d$clim_change_z, .99)),
  data.table(feature = "Survey effort", src = "observed 2002-2024",
             lo = quantile(d$effort_z, .01), hi = quantile(d$effort_z, .99)),
  proj[, .(feature = "Accumulated warming", src = paste(toupper(sub("ssp", "SSP", ssp)), horizon),
           lo = quantile(clim_change_z, .01), hi = quantile(clim_change_z, .99)), by = .(ssp, horizon)][, -(1:2)],
  proj[, .(feature = "Survey effort", src = paste(toupper(sub("ssp", "SSP", ssp)), horizon),
           lo = quantile(effort_z, .01), hi = quantile(effort_z, .99)), by = .(ssp, horizon)][, -(1:2)])

# (c) 范围外: 读取 141 持久化的省级投影(全量行, 即原图所用 prov_all)
# out of range: 141's persisted province projection, "all rows" = prov_all used in the original
ag <- rd("tbl_v2_future_province_projection.csv")[scope == "all rows", .(province, ssp, horizon, mech_ratio, ml_ratio)]
ag[, `:=`(ssp_lab = factor(ssp, levels = c("ssp245", "ssp585"), labels = c("SSP2-4.5", "SSP5-8.5")),
          hz_lab  = factor(horizon))]
cors <- ag[, .(rho = cor(mech_ratio, ml_ratio, method = "spearman"),
               agree_dir = mean((mech_ratio > 1) == (ml_ratio > 1)), n = .N), by = .(ssp_lab, hz_lab)]

# ---- 2.3 与原图 source data 核对 / check against the original source data ----
src4 <- fread(file.path(OUT, "figures_future", "source_data_FigM4_mech_vs_ml_agreement_v2.csv"))
chk <- merge(cors[, .(group = paste(ssp_lab, hz_lab), rho, agree_dir)], src4[panel == "b"], by = "group")
stopifnot(nrow(chk) == 6, isTRUE(all.equal(chk$rho.x, chk$rho.y, tolerance = 1e-10)),
          isTRUE(all.equal(chk$agree_dir.x, chk$agree_dir.y, tolerance = 1e-10)),
          isTRUE(all.equal(r_in, src4[panel == "a", rho], tolerance = 1e-10)),
          nrow(ag) == 31 * 6)                      # 31 省 × 6 情景, 基期须覆盖全部省份 / all provinces
msg(sprintf("province x scenario cells with ratio > 1: mechanistic %d, ML %d (of %d)",
            sum(ag$mech_ratio > 1), sum(ag$ml_ratio > 1), nrow(ag)))
msg(sprintf("FigM4: Spearman rho in range = %.4f (n = %d province-years); 6 facet rho/agree values match",
            r_in, nrow(inr)))

# ---- 2.4 面板 a: 观测范围内 / panel a: inside the observed range ----
p_ma <- ggplot(inr, aes(mech, ml)) +
  geom_point(colour = TJ$obs, size = 0.8, alpha = 0.45, stroke = 0.2) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = TJ$ink, linewidth = 0.5) +
  annotate("text", x = min(inr$mech), y = max(inr$ml), hjust = 0, vjust = 1, size = FS, colour = TJ$ink,
           label = sprintf("Spearman \u03c1 = %.2f", r_in)) +
  scale_x_continuous(trans = "log10", breaks = c(0.001, 0.003, 0.01), labels = c("0.001", "0.003", "0.01")) +
  scale_y_continuous(trans = "log10", breaks = c(0.001, 0.003, 0.01, 0.03),
                     labels = c("0.001", "0.003", "0.01", "0.03")) +
  labs(x = "Mechanistic hazard", y = "Machine-learning hazard",
       title = "Within the observed range, predictions co-vary") +
  theme_tj()

# ---- 2.5 面板 b: 协变量范围 / panel b: covariate ranges ----
HZ_COL <- c("Observed" = TJ$obs, "2030" = tint(TJ$warming, 0.5), "2050" = TJ$warming,
            "2080" = colorspace::darken(TJ$warming, 0.35))
rng[, `:=`(grp = fifelse(src == "observed 2002-2024", "Observed",
                         fifelse(grepl("SSP245", src), "SSP2-4.5", "SSP5-8.5")),
           key = fifelse(src == "observed 2002-2024", "Observed", sub(".* ", "", src)))]
rng[, `:=`(grp = factor(grp, levels = c("Observed", "SSP2-4.5", "SSP5-8.5")),
           ylab = factor(fifelse(key == "Observed", "2002\u20132024", key),
                         levels = c("2080", "2050", "2030", "2002\u20132024")))]
obs_lim <- rng[key == "Observed", .(v = c(lo, hi)), by = feature]
p_mb <- ggplot(rng) +
  geom_vline(data = obs_lim, aes(xintercept = v), linetype = "dashed", colour = TJ$neutral, linewidth = 0.25) +
  geom_linerange(aes(y = ylab, xmin = lo, xmax = hi, colour = key), linewidth = 2.1) +
  # 情景分组用右侧条带(置于面板内侧)。NB: strip.placement = "outside" 在 ggplot2 4.0 +
  # patchwork 1.3 下会把相邻面板 a 的 x 轴整体下推约 3 mm, 故不用。
  # Scenario groups as right-hand strips (inside placement). NB: "outside" placement
  # pushes the neighbouring panel's x axis down by ~3 mm under ggplot2 4.0 + patchwork 1.3.
  facet_grid(grp ~ feature, scales = "free", space = "free_y") +
  scale_colour_manual(values = HZ_COL, guide = "none") +
  scale_x_continuous(breaks = scales::breaks_pretty(n = 5), labels = scales::label_number(style_negative = "minus")) +
  labs(x = "Standardised value (1st\u201399th percentile)", y = NULL,
       title = "Future scenarios leave the training range") +
  theme_tj() +
  theme(strip.text.y.right = element_text(angle = 0, hjust = 0, vjust = 0.5, size = 6, face = "bold",
                                          margin = margin(l = 4)),
        panel.spacing.y = unit(3, "pt"), panel.spacing.x = unit(8, "pt"))

# ---- 2.6 面板 c: 省级投影比值 2 x 3 / panel c: province ratios, SSP x horizon ----
cors[, lab := sprintf("\u03c1 = %s\n%.0f%% agree on sign", MINUS(sprintf("%.2f", rho)), 100 * agree_dir)]
LOG2_LAB <- function(x) format(x, drop0trailing = TRUE, trim = TRUE)
p_mc <- ggplot(ag, aes(mech_ratio, ml_ratio)) +
  geom_hline(yintercept = 1, linetype = "dotted", colour = TJ$neutral, linewidth = 0.3) +
  geom_vline(xintercept = 1, linetype = "dotted", colour = TJ$neutral, linewidth = 0.3) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = TJ$neutral, linewidth = 0.25) +
  geom_point(colour = TJ$warming, size = 1.1, alpha = 0.7, stroke = 0.2) +
  geom_text(data = cors, aes(x = 85, y = 5.4, label = lab), hjust = 1, vjust = 1, size = FS,
            colour = TJ$subink, lineheight = 1, inherit.aes = FALSE) +
  # 1:1 线只在左上分面标注一次, 紧贴虚线 / label the 1:1 line once, beside it
  geom_text(data = data.frame(ssp_lab = factor("SSP2-4.5", levels = levels(ag$ssp_lab)),
                              hz_lab = factor("2030", levels = levels(ag$hz_lab))),
            aes(x = 2.9, y = 1.9), label = "1:1", size = FS, colour = TJ$subink, hjust = 0,
            inherit.aes = FALSE) +
  facet_grid(ssp_lab ~ hz_lab) +
  scale_x_continuous(trans = "log2", breaks = c(0.5, 1, 4, 16, 64), labels = LOG2_LAB, limits = c(0.42, 90)) +
  scale_y_continuous(trans = "log2", breaks = c(0.25, 0.5, 1, 2, 4), labels = LOG2_LAB, limits = c(0.16, 5.6)) +
  labs(x = "Mechanistic hazard ratio vs 2024", y = "Machine-learning hazard ratio vs 2024",
       title = "Beyond the training range, projections diverge") +
  theme_tj() +
  theme(strip.text.y.right = element_text(angle = -90, hjust = 0.5, size = 7, face = "bold"),
        panel.spacing.x = unit(10, "pt"), panel.spacing.y = unit(6, "pt"))

# ---- 2.7 组装与导出 / assemble and export ----
fig_m <- (p_ma | p_mb) / p_mc + plot_layout(heights = c(1, 1.45)) + tj_tags()
fig_m[[1]] <- fig_m[[1]] + plot_layout(widths = c(0.9, 1.1))
tj_save(fig_m, "TJ_Fig_mech_vs_ml", 183, 125)
tj_panel(p_ma, "TJ_Fig_mech_vs_ml_a", 100, 85)
tj_panel(p_mb, "TJ_Fig_mech_vs_ml_b", 120, 85)
tj_panel(p_mc, "TJ_Fig_mech_vs_ml_c", 170, 110)

fit_ll <- coef(lm(log10(ml) ~ log10(mech), data = inr))       # 面板 a 拟合线(log10 尺度)/ fit line
tj_source(rbindlist(list(
  inr[order(province, year), .(panel = "a", series = "province-year mean hazard",
                               group = paste(province, year), x = mech, y = ml)],
  data.table(panel = "a", series = c("lm on log10 scale", "lm on log10 scale", "Spearman rho"),
             group = c("intercept", "slope", "observed 2002-2024"), y = c(unname(fit_ll), r_in)),
  rng[, .(panel = "b", series = feature, group = paste(grp, sub(".* ", "", src)), xmin = lo, xmax = hi)],
  ag[order(ssp, horizon, province), .(panel = "c", series = paste(ssp_lab, hz_lab), group = province,
                                      x = mech_ratio, y = ml_ratio)],
  cors[, .(panel = "c", series = paste(ssp_lab, hz_lab), group = "Spearman rho", y = rho)],
  cors[, .(panel = "c", series = paste(ssp_lab, hz_lab), group = "share agreeing on sign", y = agree_dir)]
), fill = TRUE)[, .(panel, series, group, x, y, xmin, xmax)], "TJ_Fig_mech_vs_ml")
msg("FigM4 written | DONE")
