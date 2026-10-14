#!/usr/bin/env Rscript
# ============================================================
# Script 226a: 正文数字中只能由模型对象或数据面板得到的量(修正前后各算一次)
# Quantities quoted in the manuscripts that come from model objects or data panels,
# computed once before and once after the 2024 effort correction
# ============================================================
# Scientific question / 科学问题:
#   无(核对步骤)。2024 年努力修正后, 正文中来自模型对象(而非结果表)的数字各变为多少?
#   None (audit step): after the correction, what do the numbers that come from model objects
#   rather than result tables become?
#
# Objective / 分析目标:
#   用同一段代码分别读取修正前快照与修正后的数据和模型, 计算主模型 Wald 区间、随机效应
#   标准差与跨度、自然单位换算、方差份额、全国访问量倍数与时变努力效应, 输出长表供 226b
#   与正文逐字比对。旧值必须能在原文中逐字找到, 才证明取数口径正确。
#   The same code reads the pre-correction snapshot and the corrected outputs; 226b checks that
#   every old value is found verbatim in the published text, which validates the definition.
#
# Input data / 输入数据:
#   旧 / old: temp/snapshot_pre_effort2024_20261013/data/{fit_R3,fit_R3_time_varying}.rds,
#             model_v2_thr50.parquet, effort_panel_v2.csv, components_v2_tavg_annual_W15.parquet
#   新 / new: analysis_v2/data/ 下同名文件 / same files under analysis_v2/data/
#
# Main workflow / 主要流程:
#   1. 建模行(与 141/143/218c 逐行一致)/ model rows, verbatim from 141/143/218c
#   2. 主模型与随机效应 / main model and random effects
#   3. 自然单位、方差份额、努力倍数 / natural units, variance shares, effort multipliers
#   4. 时变努力效应(与 143 相同算法)/ time-varying effort effect, as in 143
#
# Expected output / 预期输出: analysis_v2/effort2024_audit/model_quantities.csv(item, old, new)
# Key assumptions / 关键假设: 气候分量文件不依赖努力数据, 新旧相同;Wald 区间 = exp(b ± 1.96 se)
# Main packages / 主要包: data.table, arrow, glmmTMB
# Output directory / 输出路径: analysis_v2/effort2024_audit/
# Run / 运行: Rscript --no-init-file code/226a_model_quantities.R   (cwd = 任务根 / task root)
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)

V2  <- normalizePath(".", mustWork = TRUE)
OUT <- file.path(V2, "analysis_v2", "effort2024_audit")
ROOTS <- c(old = file.path(V2, "temp", "snapshot_pre_effort2024_20261013", "data"),
           new = file.path(V2, "analysis_v2", "data"))
msg <- function(...) cat(sprintf("[226a %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

quantities <- function(DATA) {
  # ---- 1. 建模行 / model rows ----
  d <- as.data.table(read_parquet(file.path(DATA, "model_v2_thr50.parquet")))
  d[, c("x", "clim_change", "clim_var") := NULL]
  cc <- as.data.table(read_parquet(file.path(DATA, "components_v2_tavg_annual_W15.parquet")))
  d <- merge(d, cc, by = c("species", "province", "year"))
  d <- d[is.finite(clim_change) & is.finite(clim_var) & is.finite(eff_visits_gap_z)]
  out <- list(n_rows = nrow(d), n_events = sum(d$event), n_species = uniqueN(d$species),
              n_prov = uniqueN(d$province), event_rate_pct = 100 * mean(d$event))

  # ---- 2. 主模型 Wald 区间与随机效应 / main model and random effects ----
  m  <- readRDS(file.path(DATA, "fit_R3.rds"))
  cf <- summary(m)$coefficients$cond
  terms <- c(change = "clim_change_z", effort = "effort_z", var = "clim_var_z",
             int = grep(":", rownames(cf), value = TRUE)[1])
  for (k in names(terms)) {
    b <- cf[terms[[k]], "Estimate"]; se <- cf[terms[[k]], "Std. Error"]
    out[[paste0("hr_", k)]] <- exp(b)
    out[[paste0("lo_", k)]] <- exp(b - 1.96 * se)
    out[[paste0("hi_", k)]] <- exp(b + 1.96 * se)
    out[[paste0("p_", k)]]  <- cf[terms[[k]], "Pr(>|z|)"]
  }
  vc <- VarCorr(m)$cond
  re <- ranef(m)$cond
  for (g in c("species", "province", "prov_year")) {
    s <- sqrt(vc[[g]][1, 1])
    out[[paste0("sd_", g)]]   <- s
    out[[paste0("mult_", g)]] <- exp(s)
    out[[paste0("span_", g)]] <- exp(diff(range(re[[g]][[1]])))     # exp(max − min)
    out[[paste0("max_", g)]]  <- exp(max(re[[g]][[1]]))
  }

  # ---- 3. 自然单位、方差份额 / natural units, variance shares ----
  cc_sd <- stats::sd(d$clim_change)
  out$cc_sd  <- cc_sd
  out$cc_min <- min(d$clim_change); out$cc_max <- max(d$clim_change)
  out$cc_range_fold <- exp(log(out$hr_change) * (out$cc_max - out$cc_min) / cc_sd)
  vp <- function(v) {
    tot <- var(d[[v]])
    btw <- var(d[, mean(get(v)), by = .(province, year)]$V1)
    wth <- mean(d[, .(vv = var(get(v)), n = .N), by = .(province, year)][n > 1]$vv)
    c(norm = wth / (btw + wth), raw = wth / tot)
  }
  for (v in c("x", "clim_change")) {
    s <- vp(v)
    out[[paste0("within_share_", v)]]     <- s[["norm"]]
    out[[paste0("within_share_raw_", v)]] <- s[["raw"]]
  }

  # ---- 努力: 每 SD 倍数、中位数、全国访问量 / effort multipliers and national visits ----
  e   <- fread(file.path(DATA, "effort_panel_v2.csv"))
  obs <- e[effort_status_v2 == "observed" & in_scope %in% c(TRUE, 1, "TRUE")]
  lv  <- log1p(obs$n_visits)
  out$eff_fold   <- exp(stats::sd(lv))
  out$eff_median <- expm1(stats::quantile(lv, 0.5, names = FALSE))
  out$eff_median_x_fold <- out$eff_median * out$eff_fold
  for (rule in c("observed", "all")) {
    sel <- if (rule == "observed") e[mainland %in% c(TRUE, 1, "TRUE") & effort_status_v2 == "observed"]
           else e[mainland %in% c(TRUE, 1, "TRUE")]
    nat <- sel[, .(v = sum(n_visits, na.rm = TRUE)), by = year]
    a <- nat[year %in% 2002:2004, mean(v)]; b <- nat[year %in% 2022:2024, mean(v)]
    out[[paste0("nat_0204_", rule)]] <- a
    out[[paste0("nat_2224_", rule)]] <- b
    out[[paste0("nat_fold_", rule)]] <- b / a
  }

  # ---- 4. 时变努力效应(143 同算法)/ time-varying effort effect (as in 143) ----
  mtv <- readRDS(file.path(DATA, "fit_R3_time_varying.rds"))
  cft <- fixef(mtv)$cond; Vt <- vcov(mtv)$cond
  yrs <- 2002:2024; yc <- (yrs - mean(d$year)) / stats::sd(d$year)
  nm  <- c("effort_z", grep("^effort_z:", names(cft), value = TRUE)[1])
  b_t <- cft[[nm[1]]] + cft[[nm[2]]] * yc
  se_t <- sqrt(Vt[nm[1], nm[1]] + yc^2 * Vt[nm[2], nm[2]] + 2 * yc * Vt[nm[1], nm[2]])
  lo_t <- exp(b_t - 1.96 * se_t)
  out$tv_hr_2002 <- exp(b_t[1]);  out$tv_lo_2002 <- lo_t[1];  out$tv_hi_2002 <- exp(b_t[1] + 1.96 * se_t[1])
  n <- length(yrs)
  out$tv_hr_2024 <- exp(b_t[n]);  out$tv_lo_2024 <- lo_t[n];  out$tv_hi_2024 <- exp(b_t[n] + 1.96 * se_t[n])
  out$tv_first_ns_year <- yrs[which(lo_t <= 1)[1]]                  # 区间首次含 1 / first year CI covers 1
  out
}

res <- lapply(ROOTS, function(r) { msg("读取 / reading ", sub(V2, ".", r, fixed = TRUE)); quantities(r) })
keys <- names(res$new)
# NB: 列名不能叫 key —— 那是 data.table() 的保留参数 / "key" is a reserved data.table() argument
tab <- data.table(item = keys, old = vapply(keys, function(k) as.numeric(res$old[[k]]), numeric(1)),
                  new = vapply(keys, function(k) as.numeric(res$new[[k]]), numeric(1)))
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
fwrite(tab, file.path(OUT, "model_quantities.csv"))
print(tab[, .(item, old = signif(old, 6), new = signif(new, 6))], nrows = 200)
msg("写出 / wrote model_quantities.csv (", nrow(tab), " keys)")
