#!/usr/bin/env Rscript
# ============================================================
# Script 138: v2 主模型诊断
# Diagnostics for the frozen v2 main model
# ============================================================
# 目的 / Objective:
#   对冻结的主模型做基于模拟的残差诊断, 并检验离散时间风险模型的关键假设。
#
# 主模型 / Main model:
#   event ~ clim_change_z * effort_z + clim_var_z + offset(log(c_t))
#           + (1|species) + (1|province) + (1|province:year)
#   family = binomial("cloglog");  tavg_annual, W = 15 yr, effort = visits (coverage-gap)
#
# 诊断项 / Diagnostic checks:
#   1. DHARMa 缩放残差: 均匀性(KS)、离散度、离群点、零膨胀
#   2. 残差 vs 各预测变量(检验函数形式)
#   3. 残差按【年】与按【省】分组(检验剩余时空结构)
#   4. 空间自相关: 省质心上的 Moran's I
#   5. 比例风险假设的近似检验: 交互 term x 时间是否显著
#
# 注意 / NB: 稀有事件(事件率 0.37%)下 DHARMa 的离群点检验极易显著,
#   这是二元稀有结局的已知性质, 需与真正的模型失配区分, 故一并报告
#   离群点的方向与数量, 不只报告 P 值。
#
# Input / 输入:  analysis_v2/data/fit_R3.rds, model_v2_thr50.parquet
# Output / 输出: analysis_v2/tables/tbl_v2_diagnostics.csv
#                analysis_v2/figures/FigS1_dharma_v2.{png,pdf,pptx}
#
# Main packages / 主要包: DHARMa, glmmTMB, data.table, ggplot2
# 运行 / Run: Rscript --no-init-file code/138_diagnostics_v2.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(glmmTMB); library(DHARMa)
})
options(warn = 1)
set.seed(42)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
dir.create(file.path(OUT, "figures"), showWarnings = FALSE, recursive = TRUE)
msg <- function(...) cat(sprintf("[138 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

EFFORT <- "eff_visits_gap_z"; IND0 <- "tavg_annual"; W0 <- 15L
zs <- function(x) as.numeric(scale(x))

d <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
d[, c("x", "clim_change", "clim_var") := NULL]
cc <- as.data.table(read_parquet(file.path(OUT, "data", sprintf("components_v2_%s_W%d.parquet", IND0, W0))))
d <- merge(d, cc[, .(species, province, year, clim_change, clim_var)], by = c("species", "province", "year"))
d <- d[is.finite(clim_change) & is.finite(clim_var) & is.finite(get(EFFORT))]
d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var),
         effort_z = zs(get(EFFORT)), prov_year = interaction(province, year, drop = TRUE))]
m <- readRDS(file.path(OUT, "data", "fit_R3.rds"))
msg("主模型载入 | n = ", format(nrow(d), big.mark = ","), " | 事件 ", sum(d$event),
    " | 事件率 ", sprintf("%.3f%%", 100 * mean(d$event)))

# ---- 1. DHARMa 缩放残差 ----
msg("模拟残差 (n_sim = 500) ...")
sr <- simulateResiduals(m, n = 500, seed = 42)
res <- list()
add <- function(test, statistic, p, note = "")
  res[[length(res) + 1L]] <<- data.table(test = test, statistic = statistic, p_value = p, note = note)

ks <- testUniformity(sr, plot = FALSE)
add("KS uniformity", unname(ks$statistic), ks$p.value,
    "scaled residuals vs Uniform(0,1)")
dp <- testDispersion(sr, plot = FALSE)
add("dispersion", unname(dp$statistic), dp$p.value, "simulated vs observed dispersion")
ol <- testOutliers(sr, plot = FALSE, type = "bootstrap")
add("outliers (bootstrap)", unname(ol$statistic), ol$p.value,
    sprintf("%d outliers observed; rare-event binary outcomes inflate this test",
            sum(sr$scaledResiduals %in% c(0, 1))))
zi <- tryCatch({ z <- testZeroInflation(sr, plot = FALSE)
                 add("zero inflation", unname(z$statistic), z$p.value, "ratio observed/simulated zeros"); TRUE },
               error = function(e) { msg("  zero-inflation test skipped: ", conditionMessage(e)); FALSE })

# ---- 2/3. 分组残差: 年、省 ----
# NB: DHARMa::testCategorical 即使 plot=FALSE 也会调用 mtext, 必须有活动图形设备,
#     故在空设备(pdf(NULL))中调用。
rq <- residuals(sr)
# 需要【已初始化的绘图】而不仅是活动设备, 故 pdf(NULL) 之后还要 plot.new()
grDevices::pdf(NULL); plot.new()
gy <- testCategorical(sr, catPred = factor(d$year), plot = FALSE)
plot.new()
gp <- testCategorical(sr, catPred = factor(d$province), plot = FALSE)
grDevices::dev.off()
# testCategorical 返回【每个水平】的 KS 检验, 汇总为超出名义水平的比例
# summarise the per-level KS tests rather than storing one row per level
for (g in list(list("year", gy), list("province", gp))) {
  pv <- g[[2]]$uniformity$p.value
  add(sprintf("grouped by %s (levels with P<0.05)", g[[1]]),
      sum(pv < 0.05, na.rm = TRUE), min(pv, na.rm = TRUE),
      sprintf("%d of %d levels below 0.05 (%.1f%%); nominal rate is 5%%. Statistic = count, p = smallest level P",
              sum(pv < 0.05, na.rm = TRUE), length(pv), 100 * mean(pv < 0.05, na.rm = TRUE)))
}

# ---- 4. 省级空间自相关 ----
# 省质心由事件坐标的均值近似 / province centroids approximated from record coordinates
# NB: 残差必须先写成列。外部向量在 `by=` 的 j 中不会随分组子集化,
#     直接 mean(rq) 会让每个组都拿到全体均值。
d[, resid_q := rq]
sp_res <- d[, .(r = mean(resid_q)), by = province]
ev <- fread(file.path(OUT, "data", "events_discovery_dated.csv"))
ct <- ev[is.finite(longitude) & is.finite(latitude),
         .(lon = mean(longitude), lat = mean(latitude)), by = province]
mg <- merge(sp_res, ct, by = "province")
if (nrow(mg) > 5) {
  dm <- as.matrix(dist(mg[, .(lon, lat)]))
  # 反距离权重; 零距离(质心重合)会产生 Inf, 用最小正距离的一半兜底
  # inverse-distance weights; guard against coincident centroids producing Inf
  pos <- dm[dm > 0]
  dm[dm == 0] <- min(pos) / 2
  w <- 1 / dm; diag(w) <- 0; w <- w / rowSums(w)
  n <- nrow(mg); z <- mg$r - mean(mg$r)
  moran <- function(zz) (n / sum(w)) * sum(w * outer(zz, zz)) / sum(zz^2)
  I <- moran(z); EI <- -1 / (n - 1)
  perm <- replicate(999, moran(sample(z)))
  add("Moran's I (province-mean residuals)", I,
      (1 + sum(abs(perm - EI) >= abs(I - EI))) / 1000,
      sprintf("inverse-distance weights, %d provinces, 999 permutations; E[I] = %.3f", n, EI))
} else {
  add("province-level residual spread", stats::sd(sp_res$r), NA_real_,
      "too few provinces with coordinates for Moran's I")
}

# ---- 5. 比例风险的近似检验 ----
msg("比例风险检验 (term x time) ...")
d[, year_c := as.numeric(scale(year))]
m_ph <- tryCatch(glmmTMB(event ~ clim_change_z * effort_z + clim_var_z +
                           clim_change_z:year_c + effort_z:year_c + offset(log_completeness) +
                           (1|species) + (1|province) + (1|prov_year),
                         data = d, family = binomial("cloglog")),
                 error = function(e) NULL)
if (!is.null(m_ph)) {
  cf <- summary(m_ph)$coefficients$cond
  for (t in c("clim_change_z:year_c", "effort_z:year_c"))
    if (t %in% rownames(cf))
      add(paste("proportional hazards:", t), cf[t, 1], cf[t, 4],
          "non-zero => effect changes over time (PH violated for that term)")
  add("proportional hazards: AIC vs main", AIC(m_ph) - AIC(m), NA_real_,
      "negative favours the time-varying model")
  # PH 松弛后主效应是否改变? / do the focal effects survive relaxing PH?
  for (t in c("effort_z", "clim_change_z", "clim_var_z", grep(":effort_z$", rownames(cf), value = TRUE)[1]))
    if (!is.na(t) && t %in% rownames(cf))
      add(paste("time-varying model HR:", t), exp(cf[t, 1]), cf[t, 4],
          "coefficient in the model that allows effects to change over time")
  saveRDS(m_ph, file.path(OUT, "data", "fit_R3_time_varying.rds"))
}

tb <- rbindlist(res)
fwrite(tb, file.path(OUT, "tables", "tbl_v2_diagnostics.csv"))
print(tb)

# ---- 图 ----
tryCatch({
  grDevices::png(file.path(OUT, "figures", "FigS1_dharma_v2.png"),
                 width = 10, height = 7.5, units = "in", res = 450)
  par(mfrow = c(2, 3), mar = c(4, 4, 3, 1), cex = 0.8)
  plotQQunif(sr, testUniformity = TRUE, testOutliers = FALSE, testDispersion = TRUE)
  plotResiduals(sr, form = d$effort_z,      xlab = "Survey effort (z)",        main = "b  Residuals vs effort")
  plotResiduals(sr, form = d$clim_change_z, xlab = "Accumulated warming (z)",  main = "c  Residuals vs warming")
  plotResiduals(sr, form = d$clim_var_z,    xlab = "Annual variability (z)",   main = "d  Residuals vs variability")
  plotResiduals(sr, form = factor(d$year),  xlab = "Year",                     main = "e  Residuals by year")
  plotResiduals(sr, form = factor(d$province), xlab = "Province",              main = "f  Residuals by province")
  grDevices::dev.off()
  msg("wrote FigS1_dharma_v2.png")
}, error = function(e) msg("  figure failed: ", conditionMessage(e)))

msg("wrote tbl_v2_diagnostics.csv | DONE")
