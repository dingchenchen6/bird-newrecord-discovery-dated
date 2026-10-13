#!/usr/bin/env Rscript
# ============================================================
# tests/smoke_test.R — 验证仓库能复现头条结果
# Verify that the repository reproduces the headline result
# ============================================================
# 依次检查 / Checks, in order:
#   1. 必需与可选 R 包是否安装
#   2. setup_workspace.R 建立的工作布局是否存在
#   3. 自足脚本(133-139)所需的输入是否齐全
#   4. 分发的建模数据是否复现已发表的样本量
#   5. 重新拟合主模型是否复现已发表的系数
#   6. 事件定年与报告完整度的关键数字是否一致
#
# 运行 / Run:  Rscript --no-init-file tests/smoke_test.R
# 约两分钟; 除临时目录外不写任何文件。
# ============================================================

ok <- TRUE
say <- function(status, ...) {
  cat(sprintf("  [%s] ", status), ..., "\n", sep = "")
  if (status == "FAIL") ok <<- FALSE
}

cat("\n=== 1. R packages ===\n")
need <- c("data.table", "arrow", "glmmTMB")
opt  <- c("ggplot2", "patchwork", "sf", "terra", "DHARMa", "performance",
          "xgboost", "pROC", "officer", "rvg", "readxl", "exactextractr", "scales")
for (p in need) {
  have <- requireNamespace(p, quietly = TRUE)
  say(if (have) "PASS" else "FAIL",
      sprintf("%-14s %s", p, if (have) as.character(packageVersion(p)) else "MISSING (required)"))
}
for (p in opt) {
  have <- requireNamespace(p, quietly = TRUE)
  say(if (have) "PASS" else "WARN",
      sprintf("%-14s %s", p, if (have) as.character(packageVersion(p))
              else "missing (needed for figures, diagnostics or projections only)"))
}

cat("\n=== 2. working layout ===\n")
need_dirs <- c("analysis_v2/data", "analysis_v2/tables", "analysis_species_specific/data")
for (d in need_dirs)
  say(if (dir.exists(d)) "PASS" else "FAIL",
      sprintf("%-38s %s", d, if (dir.exists(d)) "present" else "MISSING - run setup_workspace.R"))
if (!all(dir.exists(need_dirs))) {
  cat("\nAborting: run `Rscript --no-init-file setup_workspace.R` first.\n"); quit(status = 1)
}

cat("\n=== 3. inputs for the self-contained pipeline (scripts 133-139) ===\n")
inputs <- c("analysis_v2/data/model_v2_thr50.parquet",
            "analysis_v2/data/components_v2_tavg_annual_W15.parquet",
            "analysis_v2/data/events_discovery_dated.csv",
            "analysis_v2/data/effort_panel_v2.csv",
            "analysis_v2/tables/tbl_change_decomposition.csv",
            "analysis_v2/tables/tbl_v2_re_evaluation.csv",
            "analysis_v2/tables/tbl_v2_E_importance.csv",
            "analysis_v2/tables/tbl_reporting_completeness.csv")
for (f in inputs) say(if (file.exists(f)) "PASS" else "FAIL", basename(f))

suppressPackageStartupMessages({ library(data.table); library(arrow) })
chk <- function(lab, got, want, tol = 0) {
  say(if (abs(got - want) <= tol) "PASS" else "FAIL",
      sprintf("%-30s got %s, expected %s", lab, format(got), format(want)))
}

cat("\n=== 4. shipped data reproduce the published sample sizes ===\n")
b   <- as.data.table(read_parquet("analysis_v2/data/model_v2_thr50.parquet"))
cmp <- as.data.table(read_parquet("analysis_v2/data/components_v2_tavg_annual_W15.parquet"))
b[, c("x", "clim_change", "clim_var") := NULL]
d <- merge(b, cmp[, .(species, province, year, clim_change, clim_var)],
           by = c("species", "province", "year"))
d <- d[is.finite(clim_change) & is.finite(clim_var) & is.finite(eff_visits_gap_z)]
chk("risk-set rows (all)",  nrow(b),             185478)
chk("risk-set events (all)", sum(b$event),       657)
chk("modelling rows",       nrow(d),             175901)
chk("events",               sum(d$event),        649)
chk("species",              uniqueN(d$species),  392)
chk("provincial units",     uniqueN(d$province), 31)

cat("\n=== 5. main model reproduces the published coefficients ===\n")
suppressPackageStartupMessages(library(glmmTMB))
zs <- function(x) as.numeric(scale(x))
d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var),
         effort_z = zs(eff_visits_gap_z), prov_year = interaction(province, year, drop = TRUE))]
cat("  fitting (about 90 s) ...\n")
m <- glmmTMB(event ~ clim_change_z * effort_z + clim_var_z + offset(log_completeness) +
               (1 | species) + (1 | province) + (1 | prov_year),
             data = d, family = binomial("cloglog"))
cf <- fixef(m)$cond
hr <- function(t) exp(cf[[t]])
int_name <- grep(":", names(cf), value = TRUE)[1]
chk2 <- function(lab, got, want, tol) {
  say(if (abs(got - want) <= tol) "PASS" else "FAIL",
      sprintf("%-30s HR = %.3f, expected %.3f (+/- %.3f)", lab, got, want, tol))
}
chk2("accumulated warming",       hr("clim_change_z"), 1.362, 0.02)
chk2("survey effort",             hr("effort_z"),      1.404, 0.02)
chk2("annual climate variability", hr("clim_var_z"),   0.995, 0.02)
chk2("warming x effort",          hr(int_name),        0.849, 0.02)
chk("AIC", round(AIC(m), 1), 8313.2, 1.0)

cat("\n=== 6. dating and reporting completeness ===\n")
ev <- fread("analysis_v2/data/events_discovery_dated.csv")
chk("re-dated events in window", nrow(ev), 657)
# 657 事件中 649 用发现日期, 8 个用 pub_year-1 兜底(发现年不可解析或晚于发表年)
chk("events dated by discovery", sum(ev$date_source == "discovery_date"), 649)
comp <- fread("analysis_v2/tables/tbl_reporting_completeness.csv")
chk("completeness 2002", round(comp[year == 2002]$completeness, 3), 0.997, 0.002)
chk("completeness 2024", round(comp[year == 2024]$completeness, 3), 0.567, 0.002)
eff <- fread("analysis_v2/data/effort_panel_v2.csv")
chk("coverage-gap province-years", sum(eff$effort_status_v2 == "coverage_gap"), 24)
chk("no-coverage province-years",  sum(eff$effort_status_v2 == "no_coverage"),  39)

cat("\n============================================================\n")
# NB: keep `else` on the same line as the closing brace - a top-level `cat(...)`
# followed by a line starting with `else` is a parse error in R.
if (ok) {
  cat("SMOKE TEST PASSED - the shipped data reproduce the published headline model.\n")
} else {
  cat("SMOKE TEST FAILED - see [FAIL] lines above.\n")
}
cat("============================================================\n")
quit(status = if (ok) 0 else 1)
