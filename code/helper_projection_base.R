# ============================================================
# helper_projection_base.R: 预测基期补齐 / completing the projection base year
# ============================================================
# 科学问题 / Scientific question:
#   2024 年广东的努力因下载缺口设为缺失(脚本 222、131), 拟合时剔除这 261 行风险集。
#   未来投影与 2024 年预测面都以 2024 为基期; 若直接取建模行, 广东会整体从投影、地图与全国
#   合计中消失。如何在不改变拟合的前提下让基期覆盖全部省份?
#   Guangdong's 2024 effort is a download gap (scripts 222, 131) and its 261 risk-set rows are
#   excluded when fitting. Projections and the 2024 surfaces start from 2024, so taking the
#   fitted rows would drop Guangdong from every projection, map and national total.
#
# 做法 / Approach:
#   基期 = 可用行 + 基期年下载缺口省份的风险集行; 后者各努力指数(eff_*_gap_z)取该省最近一个
#   观测年的值, 与插补口径(脚本 131 的 imp)在序列末端的规则一致。这些行只用于预测,
#   不参与任何拟合, 也不进入标准化常数或支撑域分位数的计算。
#   Base = usable rows + the risk-set rows of download-gap provinces in the base year, whose
#   effort indices take the province's latest observed value (the end-of-series rule of the
#   interpolation treatment in script 131). Prediction only: never used for fitting,
#   standardisation constants or support quantiles.
#
# 输入 / Input: 建模矩阵全部行(按努力过滤之前)与努力面板 analysis_v2/data/effort_panel_v2.csv
# 输出 / Output: data.table, 列与输入相同, 另加 base_filled = TRUE
# 使用者 / Used by: 141, 183, 187(_en), 188(_en), 218b
# ============================================================

#' 基期年下载缺口省份的风险集行, 努力沿用最近观测年
#' Risk-set rows of download-gap provinces in the base year, effort carried forward
#'
#' @param full      建模矩阵全部行(read_parquet 之后、任何努力过滤之前)/ all model-matrix rows
#' @param base_year 基期年 / base year
#' @param panel     努力面板路径 / path to the effort panel
#' @return data.table; 无缺口时为 0 行 / zero rows when there is no gap
gap_base_rows <- function(full, base_year, panel) {
  e  <- data.table::fread(panel)
  gp <- e[year == base_year & effort_status_v2 == "download_gap", unique(province)]
  rows <- data.table::copy(full[year == base_year & province %in% gp])
  if (!nrow(rows)) return(rows)
  src <- e[province %in% gp & effort_status_v2 == "observed" & year < base_year]
  src <- src[order(province, -year)][, .SD[1], by = province]
  stopifnot(setequal(src$province, gp))
  cols <- intersect(grep("^eff_.*_gap_z$", names(full), value = TRUE), names(e))
  for (cl in cols) data.table::set(rows, j = cl, value = src[[cl]][match(rows$province, src$province)])
  rows[, `:=`(usable_main = TRUE, base_filled = TRUE)]
  message(sprintf("[base] %d rows added for %s (effort carried forward from %s)", nrow(rows),
                  paste(gp, collapse = ", "), paste(sprintf("%s %d", src$province, src$year), collapse = ", ")))
  rows
}
