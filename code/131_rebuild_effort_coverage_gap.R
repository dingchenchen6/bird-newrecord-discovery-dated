#!/usr/bin/env Rscript
# ============================================================
# Script 131: 努力面板重建 —— structural_zero 改判为【覆盖缺口】
# Rebuild the effort panel: structural zeros are coverage gaps, not true zeros
# ============================================================
# 问题 / The problem being fixed:
#   原面板把 24 个省-年标为 `structural_zero`(努力恰为 0), 并赋予固定地板值
#   log_effort_*_z = -2。诊断显示这一判定不成立: 这些格子的**相邻年份**
#   访问数为 1-27 次, 例如
#       Anhui    2002: v=7  | 2003: v=0(stru) | 2004: v=2
#       Xinjiang 2008: v=27 | 2009: v=0(stru) | 2010: v=23
#   观鸟活动不可能整年归零后又恢复。真正的解释是努力数据库在 2002-2010
#   对这些省份覆盖不全 => 属于**缺失**, 而非"零努力"。
#   赋地板值的后果: 这 24 个省-年下的全部风险集行(约 6 千行)被安上了
#   人为的极低努力值, 系统性拉伸了努力分布的下尾。
#
# 三套口径 / Three treatments:
#   gap  (主分析 main)  structural_zero -> NA, 与 no_data 一同剔除
#   zero (敏感性 A)     沿用原地板值口径, 用于量化该判定的影响
#   imp  (敏感性 B)     有界插补: 在同省最近的已观测年之间按 log 尺度线性
#                       内插(边缘缺口用最近一年常数外推)。插补值恒落在
#                       相邻已观测值之间, 故"有界", 不会外推出极端值。
#
# 标准化 / Standardisation:
#   每套口径各自在其分析范围(in_scope 且非缺失)上做 z 标准化, 使系数
#   在该口径内可解释为"每 1 个标准差努力"。
#
# Input / 输入:  analysis_rebuilt/data/effort_province_year_rebuilt.csv
# Output / 输出: analysis_v2/data/effort_panel_v2.csv
#                analysis_v2/tables/tbl_effort_gap_audit.csv
#
# Main packages / 主要包: data.table
# 运行 / Run: Rscript --no-init-file code/131_rebuild_effort_coverage_gap.R
# ============================================================

suppressPackageStartupMessages(library(data.table))
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
msg <- function(...) cat(sprintf("[131 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

e <- fread("analysis_rebuilt/data/effort_province_year_rebuilt.csv")
msg("读入努力面板: ", nrow(e), " 省-年 | ",
    paste(sprintf("%s=%d", names(table(e$effort_status)), table(e$effort_status)), collapse = " | "))

RAW <- c(visits = "n_visits", observers = "n_observers",
         days = "n_birding_days", record = "effort_record")
stopifnot(all(RAW %in% names(e)))

# ---- 1. 重新分类 / reclassify -------------------------------------------
# structural_zero 与 no_data 均为"该省-年无可用努力观测", 只是成因不同。
e[, effort_status_v2 := fifelse(effort_status == "observed", "observed",
                         fifelse(effort_status == "structural_zero",
                                 "coverage_gap", "no_coverage"))]
msg("重新分类: ", paste(sprintf("%s=%d", names(table(e$effort_status_v2)),
                                table(e$effort_status_v2)), collapse = " | "))

# 缺口证据: 相邻已观测年的访问数 / evidence that gaps are not true zeros
gap <- e[effort_status_v2 == "coverage_gap", .(province, year)]
obs <- e[effort_status_v2 == "observed", .(province, year, n_visits)]
audit <- gap[, {
  o <- obs[province == .BY$province]
  prev <- o[year < .BY$year][which.max(year)]
  nxt  <- o[year > .BY$year][which.min(year)]
  .(prev_year   = if (nrow(prev)) as.integer(prev$year)    else NA_integer_,
    prev_visits = if (nrow(prev)) as.numeric(prev$n_visits) else NA_real_,
    next_year   = if (nrow(nxt))  as.integer(nxt$year)      else NA_integer_,
    next_visits = if (nrow(nxt))  as.numeric(nxt$n_visits)  else NA_real_)
}, by = .(province, year)]
fwrite(audit, file.path(OUT, "tables", "tbl_effort_gap_audit.csv"))
msg("缺口相邻年访问数: 中位 prev = ", median(audit$prev_visits, na.rm = TRUE),
    " | 中位 next = ", median(audit$next_visits, na.rm = TRUE),
    " | 相邻两侧均 >0 的缺口 ", audit[prev_visits > 0 & next_visits > 0, .N], "/", nrow(audit))

# ---- 2. 三套原始计数 / three raw-count treatments ------------------------
for (nm in names(RAW)) {
  v  <- as.numeric(e[[RAW[[nm]]]])
  st <- e$effort_status_v2

  # gap: 缺口与无覆盖一律缺失
  e[[paste0("cnt_", nm, "_gap")]]  <- fifelse(st == "observed", v, NA_real_)
  # zero: 缺口按 0 计(原口径), 无覆盖仍缺失
  e[[paste0("cnt_", nm, "_zero")]] <- fifelse(st == "no_coverage", NA_real_,
                                       fifelse(st == "coverage_gap", 0, v))
}

# imp: 同省 log 尺度线性内插 / within-province interpolation on the log scale
interp_one <- function(dt, cnt_col) {
  dt <- copy(dt)[order(year)]
  ok <- dt$effort_status_v2 == "observed" & is.finite(dt[[cnt_col]])
  if (!any(ok)) return(rep(NA_real_, nrow(dt)))
  lx <- log1p(dt[[cnt_col]])
  out <- lx
  need <- dt$effort_status_v2 == "coverage_gap"
  if (any(need)) {
    # approx 带 rule=2 => 边缘缺口取最近一年的常数外推
    out[need] <- stats::approx(x = dt$year[ok], y = lx[ok],
                               xout = dt$year[need], rule = 2)$y
  }
  out[dt$effort_status_v2 == "no_coverage"] <- NA_real_
  expm1(out)
}
for (nm in names(RAW)) {
  col <- RAW[[nm]]
  e[, (paste0("cnt_", nm, "_imp")) := {
    idx <- order(year)
    v <- rep(NA_real_, .N)
    v[idx] <- interp_one(.SD[idx], col)
    v
  }, by = province, .SDcols = c("year", "effort_status_v2", col)]
}
msg("插补完成: 缺口访问数中位 = ",
    round(median(e[effort_status_v2 == "coverage_gap"]$cnt_visits_imp, na.rm = TRUE), 2),
    " (原口径记为 0)")

# ---- 3. log1p + z 标准化(各口径独立, 仅用分析范围) ----------------------
scope <- e$in_scope %in% c(TRUE, 1, "TRUE")
msg("分析范围省-年: ", sum(scope), " / ", nrow(e))
for (trt in c("gap", "zero", "imp")) {
  for (nm in names(RAW)) {
    src <- paste0("cnt_", nm, "_", trt)
    lg  <- log1p(e[[src]])
    use <- scope & is.finite(lg)
    z   <- rep(NA_real_, nrow(e))
    z[use] <- (lg[use] - mean(lg[use])) / stats::sd(lg[use])
    e[[paste0("eff_", nm, "_", trt, "_z")]] <- z
  }
}

# 各口径的可用样本量 / usable province-years per treatment
smry <- rbindlist(lapply(c("gap", "zero", "imp"), function(trt)
  data.table(treatment = trt,
             usable_province_years = sum(scope & is.finite(e[[paste0("eff_visits_", trt, "_z")]])),
             min_z = round(min(e[[paste0("eff_visits_", trt, "_z")]], na.rm = TRUE), 3),
             max_z = round(max(e[[paste0("eff_visits_", trt, "_z")]], na.rm = TRUE), 3))))
print(smry)
fwrite(smry, file.path(OUT, "tables", "tbl_effort_treatment_summary.csv"))

keep <- c("province", "year", "effort_status", "effort_status_v2", "in_scope", "mainland",
          unname(RAW), grep("^cnt_|^eff_.*_z$", names(e), value = TRUE))
fwrite(e[, ..keep], file.path(OUT, "data", "effort_panel_v2.csv"))
msg("wrote effort_panel_v2.csv (", nrow(e), " x ", length(keep), ") | DONE")
