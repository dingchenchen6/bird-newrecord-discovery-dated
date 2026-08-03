#!/usr/bin/env Rscript
# ============================================================
# Script 164: 推力还是拉力 —— 把气候梯度拆回两端
# Push or pull: decomposing the climate gradient back into its two ends
# ============================================================
# Scientific question / 科学问题:
#   主模型的气候变量是一个【差】:
#     x(s,p,t) = [T(p,t) - T_base(p)] - [N(s,t) - N_base(s)] = dT(p,t) - dN(s,t)
#   它把两个方向相反的生态学机制压进了同一个系数:
#     dN 源头增暖 —— 物种【原分布区】变暖, 形成推力(push): 种群被迫外扩,
#                    追踪气候迁往仍然适宜的地方 => 预期正效应, 即 x 的【负】效应
#     dT 目的地增暖 —— 目标省变暖, 使其进入该种可占据的热条件, 形成拉力(pull)
#                    => 预期正效应, 即 x 的【正】效应
#   x 的系数为正(1.362), 但这不足以判定是哪一端在起作用, 因为 x 同时包含两端。
#   本脚本把两端拆开, 直接估计。
#
# 识别性 / Identification (决定本脚本的全部设计):
#   dT(p,t) 在给定省-年是【常数】, 与 (1|province:year) 完全混淆, 在主结构下
#   不可识别。dN(s,t) 在省-年内随物种变化, 可识别。因此:
#     (A) Mundlak 分解: 把 x 拆成省-年【内】与【间】两部分。
#         恒等式: x - mean(x|p,t) = -[dN - mean(dN|p,t)]
#         所以 within 系数就是 dN 效应的【相反数】, 且不受 dT 干扰。
#     (B) 直接放入 dN, 在主结构下估计源头增暖的效应。
#     (C) 去掉 (1|province:year) 后 dT 可识别, 同时放入 dT 与 dN, 直接比较
#         推力与拉力。此结构即 v1 的种+省结构, 非主模型, 仅作机制诊断。
#
# 模型 / Models (效应量均为 HR / 1 SD):
#   M1 x * effort                      主模型(对照)
#   M2 x_within + x_between + effort   Mundlak 分解, 主结构
#   M3 dN * effort                     源头增暖, 主结构
#   M4 dT + dN, 各自 * effort          推力 vs 拉力, 种+省结构(无 prov:year)
#   M5 x * effort                      同 M4 结构下的对照, 使 M4 可比
#
# Input / 输入:
#   analysis_v2/data/model_v2_thr50.parquet             (132)
#   analysis_final/data/panel_full_{grid,species}.csv   (120)
#   analysis_rebuilt/data/grid_province_lookup.csv
# Output / 输出:
#   analysis_v2/tables/tbl_v2_push_pull.csv
#
# Main packages / 主要包: data.table, arrow, glmmTMB
# 运行 / Run: Rscript --no-init-file code/164_push_pull_decomposition.R
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(arrow); library(glmmTMB) })
options(warn = 1)

ROOT <- normalizePath(".", mustWork = TRUE)
OUT  <- file.path(ROOT, "analysis_v2"); RB <- file.path(ROOT, "analysis_rebuilt")
FN   <- file.path(ROOT, "analysis_final"); TAB <- file.path(OUT, "tables")
msg  <- function(...) cat(sprintf("[164 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")
zs   <- function(x) as.numeric(scale(x))
W <- 15L

# ---- 1. 两端的累积增暖 ----------------------------------------------------
gp  <- fread(file.path(FN, "data", "panel_full_grid.csv"))
g2p <- fread(file.path(RB, "data", "grid_province_lookup.csv"), encoding = "UTF-8")
gp  <- merge(gp, g2p[, .(grid_cell, province, olap)], by = "grid_cell")
prov <- gp[, .(T_t = stats::weighted.mean(val, olap, na.rm = TRUE),
               T_base = stats::weighted.mean(baseline, olap, na.rm = TRUE)),
           by = .(province, year, indicator)]
spn <- fread(file.path(FN, "data", "panel_full_species.csv"))
nat <- spn[, .(species, year, indicator, N_t = val, N_base = baseline)]
rm(gp); invisible(gc())

base <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
base[, c("x", "clim_change", "clim_var") := NULL]
base <- base[is.finite(eff_visits_gap_z)]
base[, prov_year := interaction(province, year, drop = TRUE)]
pp <- unique(base[, .(species, province)])

cc <- merge(pp, prov[indicator == "tavg_annual", .(province, year, T_t, T_base)],
            by = "province", allow.cartesian = TRUE)
cc <- merge(cc, nat[indicator == "tavg_annual", .(species, year, N_t, N_base)],
            by = c("species", "year"))
setorder(cc, species, province, year)
cc[, `:=`(dT = T_t - T_base, dN = N_t - N_base)]
cc[, x := dT - dN]
for (v in c("dT", "dN", "x"))
  cc[, (paste0(v, "_W")) := frollmean(get(v), W, align = "right"), by = .(species, province)]
cc[, x_var := x - x_W]
cmp <- cc[year >= 2002L & year <= 2024L,
          .(species, province, year, dT_W, dN_W, x_W, x_var)]

d <- merge(base, cmp, by = c("species", "province", "year"))
d <- d[is.finite(x_W) & is.finite(x_var) & is.finite(dT_W) & is.finite(dN_W)]
msg("建模数据 ", format(nrow(d), big.mark = ","), " 行 / ", sum(d$event), " 事件")

# ---- 2. Mundlak 分解与恒等式验证 ------------------------------------------
d[, `:=`(x_between = mean(x_W), dN_between = mean(dN_W)), by = .(province, year)]
d[, `:=`(x_within = x_W - x_between, dN_within = dN_W - dN_between)]
idc <- cor(d$x_within, d$dN_within)
msg(sprintf("恒等式验证 cor(x_within, -dN_within) = %+.6f  (理论值 +1)", -idc))
msg(sprintf("dT 的省-年内变异占比 = %.4f%%  (理论值 0)",
    100 * var(d$dT_W - ave(d$dT_W, d$province, d$year)) / var(d$dT_W)))

d[, `:=`(effort_z = zs(eff_visits_gap_z), clim_var_z = zs(x_var),
         x_z = zs(x_W), dT_z = zs(dT_W), dN_z = zs(dN_W),
         x_within_z = zs(x_within), x_between_z = zs(x_between))]

RE3 <- "(1|species) + (1|province) + (1|prov_year)"
RE2 <- "(1|species) + (1|province)"

fit <- function(rhs, re, label, note) {
  f <- as.formula(paste("event ~", rhs, "+ offset(log_completeness) +", re))
  t0 <- Sys.time()
  m <- tryCatch(glmmTMB(f, data = d, family = binomial("cloglog")),
                error = function(e) { msg("  FAILED ", label, ": ", conditionMessage(e)); NULL })
  if (is.null(m)) return(NULL)
  cf <- summary(m)$coefficients$cond
  vc <- glmmTMB::VarCorr(m)$cond
  out <- data.table(model = label, structure = if (identical(re, RE3)) "species+province+province:year"
                                               else "species+province",
    term = rownames(cf), estimate = cf[, 1], se = cf[, 2],
    HR = exp(cf[, 1]), lo = exp(cf[, 1] - 1.96 * cf[, 2]), hi = exp(cf[, 1] + 1.96 * cf[, 2]),
    P = cf[, 4], AIC = AIC(m), n = nrow(d), events = sum(d$event), note = note)
  msg(sprintf("  %-4s AIC=%8.1f  [%.0fs]  %s", label, AIC(m),
      as.numeric(difftime(Sys.time(), t0, units = "secs")),
      paste(sprintf("%s=%.3f", rownames(cf)[-1], exp(cf[-1, 1])), collapse = " ")))
  rm(m); invisible(gc())
  out
}

res <- list()
res$M1 <- fit("x_z * effort_z + clim_var_z", RE3, "M1",
  "Main model: the difference dT - dN, symmetry imposed")
res$M2 <- fit("x_within_z + x_between_z + effort_z + clim_var_z", RE3, "M2",
  "Mundlak: within = -dN (species dimension), between = dT net of prov-year shrinkage")
res$M3 <- fit("dN_z * effort_z + clim_var_z", RE3, "M3",
  "Source warming only: warming of the species' own range (push)")
res$M4 <- fit("(dT_z + dN_z) * effort_z + clim_var_z", RE2, "M4",
  "Push vs pull, both ends free; prov:year dropped so that dT is identifiable")
res$M5 <- fit("x_z * effort_z + clim_var_z", RE2, "M5",
  "Control for M4: the constrained difference under the same structure")

tb <- rbindlist(res)
fwrite(tb, file.path(TAB, "tbl_v2_push_pull.csv"))

cat("\n=== 推力 vs 拉力 / push vs pull ===\n")
for (nm in names(res)) {
  r <- res[[nm]]
  if (is.null(r)) next
  cat(sprintf("\n%s [%s]  AIC %.1f\n  %s\n", nm, r$structure[1], r$AIC[1], r$note[1]))
  for (i in which(r$term != "(Intercept)"))
    cat(sprintf("    %-24s HR=%.3f [%.3f, %.3f]  P=%s\n", r$term[i], r$HR[i], r$lo[i], r$hi[i],
        ifelse(r$P[i] < 1e-4, sprintf("%.1e", r$P[i]), sprintf("%.3f", r$P[i]))))
}
msg("wrote tbl_v2_push_pull.csv | DONE")
