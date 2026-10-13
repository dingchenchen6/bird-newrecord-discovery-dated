#!/usr/bin/env Rscript
# ============================================================
# Script 130: 事件按【发现年】重新定年 + 事件流失桥接表
# Re-date events to discovery year, with a full event-flow bridge
# ============================================================
# 问题 / The problem being fixed:
#   风险集此前用 `pub_year`(论文发表年)作为事件年。核实结果:
#     - 风险集 pub_year 与原始表最早发表年一致率 98.9% (281/284)
#     - 与发现年一致率仅 19.1%
#   而 CBNR 正式发布版中 Discovery_date 100% 非空、发现年 99.9% 可解析,
#   发表滞后中位 1 年、均值 2.09 年, **81.7% 的记录滞后 >= 1 年**。
#   => 气候与调查努力协变量此前对齐到"论文见刊那一年", 而非"鸟被观察到那一年",
#      对绝大多数事件存在 1-6 年的系统性时间错配。
#
# 定年规则 / Dating rule (用户 2026-07-26 指定, 扩展至不可用而非仅缺失):
#   事件年 = 发现年(Discovery_date 解析所得)
#   发现年【不可用】者 = 发表年 - 1 (中位滞后)
#     不可用 = 无法解析(1 条) 或 晚于发表年(9 条, 逻辑矛盾, 占全表 0.88%)
#   发现年 < 2002 的事件移除, 因协变量面板自 2002 起
#
# 报告完整度与右删失 / Reporting completeness and right-censoring:
#   发布版最大发表年为 2025, 因此发现于 Y 年的记录只有滞后 <= 2025-Y 的部分
#   可能已见刊。以合并的发表滞后经验 CDF F() 估计报告完整度
#       c_t = F(2025 - t)
#   该做法的前提是滞后分布随时间平稳, 已检验通过:
#       Spearman(发现年, 滞后) rho = -0.016, P = 0.685
#       Wilcoxon(2002-2010 vs 2011-2018) P = 0.851; 各期 CDF 差异 <= 3 pp
#   在 cloglog 离散时间风险模型中, 观测风险 ~ c_t * h_t, 故
#       log(-log(1-p_obs)) = eta + log(c_t)
#   即 c_t 以 offset(log(c_t)) 精确进入线性预测子(小风险近似)。
#
# 分类与省份对齐 / Taxonomy and province harmonisation:
#   物种名依次尝试 COL China 2026 -> BirdLife v10 -> Clements v2025,
#   取第一个能匹配风险集候选池的名字; 省份 Xizang -> Tibet。
#
# Input / 输入:
#   CBNR_EN.xlsx (正式发布版, 1029 事件)
#   analysis_species_specific/data/model_thr50.parquet (候选池物种与省份)
#
# Output / 输出:
#   analysis_v2/data/events_discovery_dated.csv   重新定年的事件表
#   analysis_v2/tables/tbl_event_flow_bridge.csv  逐步事件流失桥接表
#   analysis_v2/tables/tbl_publication_lag.csv    发表滞后分布
#
# Main packages / 主要包: data.table, readxl, arrow
# 运行 / Run: Rscript --no-init-file code/130_redate_events_discovery.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow)
  if (!requireNamespace("readxl", quietly = TRUE)) stop("readxl required")
})
options(warn = 1)

V2  <- normalizePath(".", mustWork = TRUE)
SS  <- file.path(V2, "analysis_species_specific")
OUT <- file.path(V2, "analysis_v2")
for (d in c("data", "tables", "figures", "logs")) dir.create(file.path(OUT, d), recursive = TRUE, showWarnings = FALSE)
msg <- function(...) cat(sprintf("[130 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

CBNR <- "/Users/dingchenchen/Downloads/China Bird_New_Record (CBNR) /dataset/CBNR_EN.xlsx"
YR_FROM <- 2002L; YR_TO <- 2024L
MEDIAN_LAG <- 1L                     # 发现年缺失时的兜底: 发表年 - 1

flow <- list()
add_flow <- function(step, n_records, n_pairs, note = "")
  flow[[length(flow) + 1L]] <<- data.table(step = step, records = n_records,
                                           species_province_pairs = n_pairs, note = note)

# ---- 1. 读入发布版 ----
d <- as.data.table(readxl::read_excel(CBNR, sheet = "CBNR_EN"))
add_flow("1. CBNR released records", nrow(d), NA_integer_, "official release")
msg("CBNR 发布版: ", nrow(d), " 条")

parse_year <- function(x) {
  y <- regmatches(as.character(x), regexpr("(19|20)[0-9]{2}", as.character(x)))
  out <- rep(NA_integer_, length(x)); hit <- lengths(regmatches(as.character(x),
          gregexpr("(19|20)[0-9]{2}", as.character(x)))) > 0
  out[hit] <- as.integer(y); out
}
d[, disc_year := parse_year(Discovery_date)]
d[, pub_year  := suppressWarnings(as.integer(Source_publication_year))]

# 发表滞后 / publication lag
lagdt <- d[is.finite(disc_year) & is.finite(pub_year), .(lag = pub_year - disc_year)]
lagtab <- lagdt[, .N, by = lag][order(lag)][, pct := round(100 * N / sum(N), 2)]
fwrite(lagtab, file.path(OUT, "tables", "tbl_publication_lag.csv"))
msg("发表滞后: 中位 ", median(lagdt$lag), " | 均值 ", round(mean(lagdt$lag), 2),
    " | >=1 年占 ", round(100 * mean(lagdt$lag >= 1), 1), "%")
stopifnot(median(lagdt$lag) == MEDIAN_LAG)          # 兜底规则用的中位滞后须与数据一致

# 报告完整度 c_t = F(P_max - t), F 为非负滞后的经验 CDF
# Reporting completeness: only records with lag <= P_max - t can have appeared yet.
L    <- sort(lagdt[lag >= 0, lag])
Pmax <- max(d$pub_year, na.rm = TRUE)
Fcdf <- function(k) mean(L <= k)
comp <- data.table(year = YR_FROM:YR_TO)[, `:=`(
  max_observable_lag = Pmax - year,
  completeness       = round(sapply(Pmax - year, Fcdf), 4))]
comp[, log_completeness := log(completeness)]       # 供 cloglog 模型作 offset
fwrite(comp, file.path(OUT, "tables", "tbl_reporting_completeness.csv"))
msg("报告完整度 (P_max=", Pmax, "): 2002-2021 >= ",
    sprintf("%.1f%%", 100 * min(comp[year <= 2021]$completeness)),
    " | 2022 ", sprintf("%.1f%%", 100 * comp[year == 2022]$completeness),
    " | 2023 ", sprintf("%.1f%%", 100 * comp[year == 2023]$completeness),
    " | 2024 ", sprintf("%.1f%%", 100 * comp[year == 2024]$completeness))

# 平稳性检验: offset 用合并 CDF 的前提 / stationarity underpins the pooled CDF
st <- d[is.finite(disc_year) & is.finite(pub_year) & pub_year >= disc_year &
          disc_year %between% c(YR_FROM, 2018), .(disc_year, lag = pub_year - disc_year)]
ct <- suppressWarnings(cor.test(st$disc_year, st$lag, method = "spearman", exact = FALSE))
wt <- suppressWarnings(wilcox.test(lag ~ I(disc_year <= 2010), data = st))
fwrite(data.table(test = c("spearman_discyear_vs_lag", "wilcoxon_2002_2010_vs_2011_2018"),
                  statistic = c(unname(ct$estimate), unname(wt$statistic)),
                  p_value = c(ct$p.value, wt$p.value),
                  n = c(nrow(st), nrow(st))),
       file.path(OUT, "tables", "tbl_lag_stationarity.csv"))
msg("滞后平稳性: Spearman rho = ", round(unname(ct$estimate), 3), " P = ", signif(ct$p.value, 3),
    " | Wilcoxon P = ", signif(wt$p.value, 3), " -> 合并 CDF 成立")

# ---- 2. 定年 ----
# 发现年可用 = 能解析 且 不晚于发表年 / usable = parseable AND not after publication
d[, disc_usable := is.finite(disc_year) & (!is.finite(pub_year) | disc_year <= pub_year)]
msg("发现年不可用: 无法解析 ", sum(!is.finite(d$disc_year)),
    " 条 | 晚于发表年 ", sum(is.finite(d$disc_year) & is.finite(d$pub_year) & d$disc_year > d$pub_year), " 条")
d[, date_source := fifelse(disc_usable, "discovery_date", "publication_minus_median_lag")]
d[, event_year  := fifelse(disc_usable, disc_year, pub_year - MEDIAN_LAG)]
msg("定年来源: ", paste(sprintf("%s=%d", names(table(d$date_source)), table(d$date_source)), collapse = " | "))
add_flow("2. dated by discovery year", nrow(d[is.finite(event_year)]), NA_integer_,
         sprintf("%d from Discovery_date, %d from pub_year-%d (unparseable or later than publication)",
                 sum(d$date_source == "discovery_date"),
                 sum(d$date_source != "discovery_date"), MEDIAN_LAG))

# ---- 3. 分类与省份对齐 ----
cand <- as.data.table(read_parquet(file.path(SS, "data", "model_thr50.parquet")))
cand_sp <- unique(cand$species); cand_pv <- unique(cand$province)

d[, province_std := trimws(New_distribution_province)]
d[province_std == "Xizang", province_std := "Tibet"]

nm_cols <- c("Scientific_name_COL_China_2026", "Scientific_name_BirdLife_v10",
             "Scientific_name_Clements_v2025")
# 注意: 条件必须在 data.table 作用域外算好, 否则 j 中的列会被 i 子集化而错位
# NB: build the mask outside the data.table scope — columns referenced in `j`
# are already subset by `i`, so indexing an external vector with them misaligns.
sp_std <- rep(NA_character_, nrow(d))
for (cl in nm_cols) {
  v <- trimws(as.character(d[[cl]]))
  hit <- is.na(sp_std) & !is.na(v) & v %in% cand_sp
  sp_std[hit] <- v[hit]
}
# 未匹配者保留 COL 名, 便于审计 / keep COL name for auditing
col_nm <- trimws(as.character(d$Scientific_name_COL_China_2026))
sp_std[is.na(sp_std)] <- col_nm[is.na(sp_std)]
d[, species_std := sp_std]
d[, matched_candidate := species_std %in% cand_sp & province_std %in% cand_pv]
msg("匹配候选池: ", sum(d$matched_candidate), " / ", nrow(d),
    " (", round(100 * mean(d$matched_candidate), 1), "%)")
add_flow("3. matched to candidate pool", sum(d$matched_candidate), NA_integer_,
         "species name via COL 2026 / BirdLife v10 / Clements v2025; Xizang -> Tibet")

# ---- 4. 每 (种,省) 取最早发现年 = 首次记录 ----
ev <- d[matched_candidate == TRUE & is.finite(event_year)]
first <- ev[order(event_year)][, .SD[1L], by = .(species_std, province_std)]
add_flow("4. first record per species-province", nrow(first), nrow(first),
         "earliest event_year retained; later reports treated as re-documentation")
msg("首次记录: ", nrow(first), " 个 (种,省) 对")

# ---- 5. 限定分析期 ----
out_early <- first[event_year < YR_FROM]
out_late  <- first[event_year > YR_TO]
keep <- first[event_year >= YR_FROM & event_year <= YR_TO]
msg("移出分析期: 早于 ", YR_FROM, " 共 ", nrow(out_early), " 条 | 晚于 ", YR_TO, " 共 ", nrow(out_late), " 条")
add_flow("5. within 2002-2024 window", nrow(keep), nrow(keep),
         sprintf("removed %d discovered before %d, %d after %d",
                 nrow(out_early), YR_FROM, nrow(out_late), YR_TO))

res <- keep[, .(species = species_std, province = province_std, year = event_year,
                date_source, disc_year, pub_year,
                lag = pub_year - event_year,
                longitude = suppressWarnings(as.numeric(Longitude)),
                latitude  = suppressWarnings(as.numeric(Latitude)))]
setorder(res, species, province)
fwrite(res, file.path(OUT, "data", "events_discovery_dated.csv"))
msg("wrote events_discovery_dated.csv: ", nrow(res), " 事件")

# ---- 6. 与旧口径对比 ----
old <- cand[event == 1L, .(species, province, old_year = year)]
cmp <- merge(res[, .(species, province, new_year = year)], old,
             by = c("species", "province"), all = TRUE)
n_both <- cmp[!is.na(new_year) & !is.na(old_year), .N]
n_shift <- cmp[!is.na(new_year) & !is.na(old_year) & new_year != old_year, .N]
msg("与旧(发表年)口径对比: 共有 ", n_both, " 个事件对 | 年份改变 ", n_shift,
    " (", round(100 * n_shift / max(n_both, 1), 1), "%)")
msg("  仅新口径有: ", cmp[is.na(old_year), .N], " | 仅旧口径有: ", cmp[is.na(new_year), .N])
add_flow("6. comparison with publication-year dating", n_both, n_both,
         sprintf("%d events change year (%.1f%%); %d new-only, %d old-only",
                 n_shift, 100 * n_shift / max(n_both, 1),
                 cmp[is.na(old_year), .N], cmp[is.na(new_year), .N]))

fb <- rbindlist(flow, fill = TRUE)
print(fb)
fwrite(fb, file.path(OUT, "tables", "tbl_event_flow_bridge.csv"))
fwrite(cmp, file.path(OUT, "tables", "tbl_dating_comparison.csv"))
msg("wrote tbl_event_flow_bridge.csv / tbl_dating_comparison.csv | DONE")
