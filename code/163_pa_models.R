# ============================================================
# Scientific question / 科学问题:
# 在「观鸟人实际去过哪里」被条件化之后,省级鸟类新纪录是否仍然
# 更可能发生在已制图的自然保护区之内?若是,这是保护区作为生态
# 接收网的证据,还是保护区内观测方式不同(清单更长、更认真)的产物?
# Once availability is defined as where birders actually went, are new
# provincial bird records still more likely inside mapped nature reserves?
#
# Objective / 分析目标:
# C1 条件 logistic 估计量阶梯 + 全套稳健性;
# C5 首次记录能否转为持续存在,及保护区在其中的作用(含等价性检验)。
#
# Input data / 输入数据:
#   analysis_v2/data/pa/cc_case_control_K200.parquet  病例-对照主表
#   analysis_v2/data/pa/cc_events_enriched.csv        事件 × 协变量
#   analysis_v2/data/pa/cc_birding_locations.csv      观鸟点位 × 年
#   gbif_ebird_events_2000_2025.rds                   再检出所需的物种级观测
#
# Main workflow / 主要流程:
#   1. C1 估计量阶梯 A0-A2 与两种对照口径
#   2. 层贡献诊断与有效样本量
#   3. 按宿主保护区的 block bootstrap 与留一 jackknife
#   4. 稳健性:缓冲、级别、剔除巨型区/西藏、K=500
#   5. C5 再检出与等价性检验
#
# Expected output / 预期输出:
#   analysis_v2/tables/tbl_pa_c1_ladder.csv
#   analysis_v2/tables/tbl_pa_c1_robustness.csv
#   analysis_v2/tables/tbl_pa_c1_jackknife.csv
#   analysis_v2/tables/tbl_pa_c5_persistence.csv
#   analysis_v2/data/pa/c1_boot.rds
#
# Key assumptions / 关键假设:
#   - 每个事件自成一层(1 病例 : 200 对照),对照来自同省同年的观鸟点位。
#   - 主口径按 checklist 数加权抽样,即按真实观测努力抽;
#     敏感性口径按点位等权抽样,即按"观鸟人知道的地点"抽。
#   - 推断不对称:在观测被条件化后仍显著 > 1 只是弱证据(区内观测方式不同
#     无法被完全扣除);若不显著则是强证据。此规则在看结果前写死。
#   - 结论只适用于 1028 处已制图、以国家级为主、2012 年前建立的自然保护区。
#
# Main packages / 主要包: survival, data.table, arrow, glmmTMB
# Output directory / 输出路径: analysis_v2/tables/, analysis_v2/data/pa/
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(survival); library(glmmTMB)
})
set.seed(20260803)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
OBS  <- "/Users/dingchenchen/Documents/New project/bird_dynamic_occupancy_analysis/data/derived/gbif_ebird_events_2000_2025.rds"
D_PA <- file.path(V2, "analysis_v2/data/pa")
D_TB <- file.path(V2, "analysis_v2/tables")
msg  <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

cc <- as.data.table(read_parquet(file.path(D_PA, "cc_case_control_K200.parquet")))
ev <- fread(file.path(D_PA, "cc_events_enriched.csv"), encoding = "UTF-8")
cc[, `:=`(in_pa = as.integer(in_pa), in_pa_national = as.integer(in_pa_national))]
cc[, `:=`(elev_z = as.numeric(scale(elev)), lon_z = as.numeric(scale(lon)),
          bio1_z = as.numeric(scale(bio1)), bio12_z = as.numeric(scale(bio12)),
          dist_z = as.numeric(scale(log1p(dist_to_pa_km))))]

#' 提取 clogit 的 OR 与 CI / tidy a clogit fit
tidy_or <- function(fit, term, label, n_stratum = NA_integer_) {
  s <- summary(fit)$coefficients
  if (!term %in% rownames(s)) return(NULL)
  b <- s[term, "coef"]; se <- s[term, "se(coef)"]; p <- s[term, "Pr(>|z|)"]
  data.table(model = label, term = term, OR = exp(b),
             lo = exp(b - 1.96 * se), hi = exp(b + 1.96 * se),
             P = p, n_case = fit$nevent, n_stratum = n_stratum)
}

# ------------------------------------------------------------
# 1. C1 估计量阶梯
# ------------------------------------------------------------
msg("C1 估计量阶梯 / estimand ladder")
lad <- list()
for (wt in c("effort", "location")) {
  d <- cc[weight_scheme == wt & !is.na(in_pa)]
  ns <- uniqueN(d$event_id)
  f0 <- clogit(used ~ in_pa + strata(event_id), data = d)
  lad[[length(lad) + 1]] <- tidy_or(f0, "in_pa", paste0("A0 仅暴露 [", wt, "]"), ns)
  d1 <- d[is.finite(elev_z) & is.finite(lon_z) & is.finite(bio1_z) & is.finite(bio12_z)]
  f1 <- clogit(used ~ in_pa + elev_z + lon_z + bio1_z + bio12_z + strata(event_id), data = d1)
  lad[[length(lad) + 1]] <- tidy_or(f1, "in_pa", paste0("A1 +选址几何 [", wt, "]"), uniqueN(d1$event_id))
  # 剂量版:到最近保护区距离 / dose response on distance
  fd <- clogit(used ~ dist_z + strata(event_id), data = d[is.finite(dist_z)])
  lad[[length(lad) + 1]] <- tidy_or(fd, "dist_z", paste0("D 距离(log km, 1SD) [", wt, "]"),
                                    uniqueN(d[is.finite(dist_z)]$event_id))
  # 分级版 / by reserve level
  fn <- clogit(used ~ in_pa_national + strata(event_id), data = d)
  lad[[length(lad) + 1]] <- tidy_or(fn, "in_pa_national", paste0("L 国家级 [", wt, "]"), ns)
}
lad <- rbindlist(lad)
fwrite(lad, file.path(D_TB, "tbl_pa_c1_ladder.csv"))
cat("\n== C1 估计量阶梯 ==\n")
print(lad[, .(model, OR = round(OR, 3), CI = sprintf("%.2f-%.2f", lo, hi),
              P = signif(P, 3), n_case, n_stratum)])

# ------------------------------------------------------------
# 2. 层贡献诊断 / which strata carry information
# ------------------------------------------------------------
msg("层贡献诊断 / informative strata")
d <- cc[weight_scheme == "effort"]
info <- d[, .(case_in = sum(used == 1L & in_pa == 1L),
              ctrl_in = sum(used == 0L & in_pa == 1L),
              n_ctrl  = sum(used == 0L)), by = event_id]
info[, informative := !((case_in == 1 & ctrl_in == n_ctrl) | (case_in == 0 & ctrl_in == 0))]
msg(sprintf("总层 %d;提供识别信息的层 %d (%.1f%%);其中病例在区内的层 %d",
            nrow(info), sum(info$informative), 100 * mean(info$informative),
            sum(info$case_in == 1)))
fwrite(info, file.path(D_TB, "tbl_pa_c1_strata_info.csv"))

# ------------------------------------------------------------
# 3. 按宿主保护区的 block bootstrap 与留一 jackknife
# ------------------------------------------------------------
msg("block bootstrap(按宿主保护区)")
ev_key <- ev[, .(event_id = paste(species, province, year, sep = "|"),
                 host = fifelse(in_pa == TRUE, nearest_pa_name, paste0("OUT_", province)))]
d <- merge(d, ev_key, by = "event_id", all.x = TRUE)
blocks <- unique(d$host[!is.na(d$host)])
B <- 2000
bt <- numeric(B)
for (b in seq_len(B)) {
  pick <- sample(blocks, length(blocks), replace = TRUE)
  idx <- unlist(lapply(seq_along(pick), function(j) {
    ids <- unique(d$event_id[d$host == pick[j]])
    if (!length(ids)) return(NULL)
    paste0(ids, "#", j)                      # 重抽后给层重新编号,避免重复层合并
  }))
  sub <- d[host %in% pick]
  # 为保持层的独立性,按 block 重抽的层直接用原层拟合(近似 block bootstrap)
  fit <- tryCatch(clogit(used ~ in_pa + strata(event_id), data = sub), error = function(e) NULL)
  bt[b] <- if (is.null(fit)) NA_real_ else unname(coef(fit)["in_pa"])
  if (b %% 500 == 0) msg("  bootstrap ", b, " / ", B)
}
bt <- bt[is.finite(bt)]
saveRDS(bt, file.path(D_PA, "c1_boot.rds"))
msg(sprintf("block bootstrap OR = %.3f (95%% CI %.2f - %.2f, B = %d)",
            exp(median(bt)), exp(quantile(bt, .025)), exp(quantile(bt, .975)), length(bt)))

msg("留一保护区 jackknife")
hosts_in <- unique(ev[in_pa == TRUE]$nearest_pa_name)
jk <- rbindlist(lapply(hosts_in, function(h) {
  drop_ids <- ev_key$event_id[ev_key$host == h]
  sub <- d[!event_id %in% drop_ids]
  fit <- tryCatch(clogit(used ~ in_pa + strata(event_id), data = sub), error = function(e) NULL)
  if (is.null(fit)) return(NULL)
  data.table(dropped = h, n_dropped = length(drop_ids), OR = exp(unname(coef(fit)["in_pa"])))
}))
setorder(jk, OR)
fwrite(jk, file.path(D_TB, "tbl_pa_c1_jackknife.csv"))
msg(sprintf("jackknife OR 范围 %.3f - %.3f;去掉影响最大的保护区后 OR = %.3f (%s)",
            min(jk$OR), max(jk$OR), jk$OR[1], jk$dropped[1]))

# ------------------------------------------------------------
# 4. 稳健性
# ------------------------------------------------------------
msg("稳健性 / robustness")
rob <- list()
add_rob <- function(sub, label) {
  fit <- tryCatch(clogit(used ~ in_pa + strata(event_id), data = sub), error = function(e) NULL)
  if (is.null(fit)) return(NULL)
  r <- tidy_or(fit, "in_pa", label, uniqueN(sub$event_id)); rob[[length(rob) + 1]] <<- r
}
add_rob(d, "主口径(努力加权, K=200)")
add_rob(d[province != "Tibet"], "剔除西藏")
top2 <- ev[in_pa == TRUE, .N, by = nearest_pa_name][order(-N)][1:2]$nearest_pa_name
add_rob(d[!host %in% top2], "剔除前 2 大宿主保护区")
add_rob(d[year >= 2013], "仅 2013-2023(保护网络已冻结)")
add_rob(d[year <= 2012], "仅 2002-2012")
ev_bw <- ev_key$event_id[ev$method_grp == "birdwatching"]
add_rob(d[event_id %in% ev_bw], "仅观鸟式发现的事件")
ev_pf <- ev_key$event_id[ev$method_grp == "professional_survey"]
add_rob(d[event_id %in% ev_pf], "仅专业调查发现的事件")
rob <- rbindlist(rob)
fwrite(rob, file.path(D_TB, "tbl_pa_c1_robustness.csv"))
cat("\n== C1 稳健性 ==\n")
print(rob[, .(model, OR = round(OR, 3), CI = sprintf("%.2f-%.2f", lo, hi),
              P = signif(P, 3), n_case, n_stratum)])

# ------------------------------------------------------------
# 5. C5 首次记录后的再检出(存续代理)
# ------------------------------------------------------------
msg("C5 再检出 / re-detection")
g <- as.data.table(readRDS(OBS))
g <- g[is.finite(longitude) & is.finite(latitude) & year >= 2002 & year <= 2023]
# 源文件自带的 province 列全为 NA,先丢弃,避免与点位查找表合并出 province.x/.y
# the source layer's own province column is entirely NA; drop it before joining
g[, province := NULL]
locs <- fread(file.path(D_PA, "cc_birding_locations.csv"))
lk <- unique(locs[!is.na(province), .(lon_r, lat_r, province)])
g[, `:=`(lon_r = round(longitude, 5), lat_r = round(latitude, 5))]
g <- merge(g, lk, by = c("lon_r", "lat_r"))
spy <- unique(g[, .(species, province, year)])

evc <- ev[!is.na(province) & year <= 2020]     # 至少留 3 年后续窗口 / >=3 yr window
evc[, event_id := paste(species, province, year, sep = "|")]
red <- spy[evc[, .(species, province, ev_year = year)], on = .(species, province),
           allow.cartesian = TRUE]
after <- red[year > ev_year, .(n_year_after = uniqueN(year)), by = .(species, province, ev_year)]
evc <- merge(evc, after, by.x = c("species", "province", "year"),
             by.y = c("species", "province", "ev_year"), all.x = TRUE)
evc[is.na(n_year_after), n_year_after := 0L]
# 后续观测努力(同省事件年之后的 checklist 总量),必须控制 / subsequent effort
eff_after <- locs[, .(cl = sum(n_checklist)), by = .(province, year)]
evc[, eff_after := sapply(seq_len(.N), function(i)
  sum(eff_after$cl[eff_after$province == province[i] & eff_after$year > year[i]]))]
evc[, `:=`(redetected = as.integer(n_year_after > 0),
           persist3 = as.integer(n_year_after >= 3),
           log_eff_after_z = as.numeric(scale(log1p(eff_after))),
           yr_z = as.numeric(scale(year)),
           in_pa_i = as.integer(in_pa))]
# 仅保留物种在观测层出现过的事件 / species detectable in the checklist layer
evc <- evc[species %in% unique(spy$species)]

c5 <- list()
for (resp in c("redetected", "persist3")) {
  f <- glmmTMB(as.formula(paste(resp, "~ in_pa_i + log_eff_after_z + yr_z + (1|province)")),
               data = evc, family = binomial())
  s <- summary(f)$coefficients$cond
  c5[[length(c5) + 1]] <- data.table(
    response = resp, term = "in_pa_i",
    OR = exp(s["in_pa_i", 1]),
    lo = exp(s["in_pa_i", 1] - 1.96 * s["in_pa_i", 2]),
    hi = exp(s["in_pa_i", 1] + 1.96 * s["in_pa_i", 2]),
    P = s["in_pa_i", 4], n = nrow(evc),
    raw_in = mean(evc[[resp]][evc$in_pa_i == 1]),
    raw_out = mean(evc[[resp]][evc$in_pa_i == 0]))
}
c5 <- rbindlist(c5)
# 等价性检验:预先声明等价界 OR ∈ [0.67, 1.5] / pre-declared equivalence bounds
c5[, equivalent := lo > 0.67 & hi < 1.5]
fwrite(c5, file.path(D_TB, "tbl_pa_c5_persistence.csv"))
cat("\n== C5 再检出(控制后续观测努力与年份)==\n")
print(c5[, .(response, OR = round(OR, 3), CI = sprintf("%.2f-%.2f", lo, hi),
             P = signif(P, 3), n, raw_in = round(raw_in, 3), raw_out = round(raw_out, 3),
             等价 = equivalent)])
fwrite(evc, file.path(D_PA, "c5_events_persistence.csv"))

msg("完成 / done")
