# ============================================================
# Scientific question / 科学问题:
# 保护地错配分析需要一个真正的格级增温速率。已有的
# grid_50km_climate.csv 中 warming_rate / climate_velocity /
# climate_exposure 全部只有 31 个唯一值,是省级值向格广播的结果,
# 不能用于任何省内比较。本脚本从 CRU TS 4.09 直接重算格级增温。
# The warming columns in the existing grid files are province-level values
# broadcast to cells (31 unique values). Recompute genuine cell-level warming
# from CRU TS 4.09 so that within-province comparisons are possible.
#
# Objective / 分析目标:
# 为 3795 个 50 km 格计算两种口径的实测增温,并留下可审计的诊断:
#   (1) 1980-2024 年均温线性趋势(°C/十年)
#   (2) 2002-2024 年均温 − 1980-2000 年均温(°C)
#
# Input data / 输入数据:
#   cru_ts4.09.1901.2024.tmp.dat.nc   CRU TS 0.5 度月均温
#   data/raw/grid_50km_base.csv       50 km 格阵中心
#
# Expected output / 预期输出:
#   analysis_v2/data/pa/grid50_warming_cru.csv
#
# Key assumptions / 关键假设:
#   - CRU 为 0.5 度(约 55 km)网格,与 50 km 格分辨率相当,
#     因此格级提取是真实分辨的,不是亚格尺度插值。
#   - 缺值格(海洋或 CRU 无覆盖)保留 NA,不做填充。
#
# Main packages / 主要包: terra, data.table
# Output directory / 输出路径: analysis_v2/data/pa/
# ============================================================

suppressPackageStartupMessages({library(terra); library(data.table)})

V2  <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
CRU <- "/Users/dingchenchen/Documents/New project/bird_dynamic_occupancy_analysis/data/external/cru_ts/cru_ts4.09.1901.2024.tmp.dat.nc"
OUT <- file.path(V2, "analysis_v2/data/pa")
msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

gb <- fread(file.path(V2, "data/raw/grid_50km_base.csv"))
pts <- vect(as.data.frame(gb[, .(centroid_lon, centroid_lat)]),
            geom = c("centroid_lon", "centroid_lat"), crs = "EPSG:4326")

msg("读取 CRU TS 4.09 / reading CRU")
r <- tryCatch(rast(CRU, subds = "tmp"), error = function(e) rast(CRU))
idx <- function(y, m) (y - 1901) * 12 + m

YR <- 1980:2024
msg("逐年提取年均温 / extracting annual means for ", length(YR), " years")
ann <- matrix(NA_real_, nrow = nrow(gb), ncol = length(YR))
for (i in seq_along(YR)) {
  y <- YR[i]
  li <- idx(y, 1):idx(y, 12)
  li <- li[li <= nlyr(r)]
  if (length(li) < 12) next
  ym <- mean(r[[li]], na.rm = TRUE)
  ann[, i] <- terra::extract(ym, pts)[, 2]
  if (y %% 10 == 0) msg("  ", y)
}
colnames(ann) <- as.character(YR)

msg("计算趋势与基线差 / trend and baseline difference")
xx <- YR - mean(YR)
trend <- apply(ann, 1, function(v) {
  ok <- is.finite(v)
  if (sum(ok) < 20) return(NA_real_)
  unname(coef(lm(v[ok] ~ xx[ok]))[2]) * 10          # °C / 十年
})
i_recent <- which(YR >= 2002 & YR <= 2024)
i_base   <- which(YR >= 1980 & YR <= 2000)
delta <- rowMeans(ann[, i_recent, drop = FALSE], na.rm = TRUE) -
         rowMeans(ann[, i_base,   drop = FALSE], na.rm = TRUE)

out <- data.table(grid_id = gb$grid_id, province = gb$province,
                  warm_trend_dec = trend, warm_delta_c = delta,
                  tmean_1980_2000 = rowMeans(ann[, i_base, drop = FALSE], na.rm = TRUE),
                  tmean_2002_2024 = rowMeans(ann[, i_recent, drop = FALSE], na.rm = TRUE))
fwrite(out, file.path(OUT, "grid50_warming_cru.csv"))

# 关键校验:必须存在省内变异,否则与被替换的广播列无异
# critical check: there must be within-province variation
wp <- out[is.finite(warm_trend_dec), .(n = .N, n_uniq = uniqueN(round(warm_trend_dec, 4)),
                                       sd_within = sd(warm_trend_dec)), by = province]
msg(sprintf("有效格 %d / %d;全局唯一趋势值 %d",
            sum(is.finite(out$warm_trend_dec)), nrow(out),
            uniqueN(round(out$warm_trend_dec, 4))))
msg(sprintf("省内标准差中位数 %.4f °C/十年;省内唯一值中位数 %.0f",
            median(wp$sd_within, na.rm = TRUE), median(wp$n_uniq)))
stopifnot(median(wp$n_uniq) > 1)          # 断言:确为格级而非省级广播
cat("\n趋势摘要(°C/十年):\n"); print(summary(out$warm_trend_dec))
cat("\n基线差摘要(°C, 2002-2024 减 1980-2000):\n"); print(summary(out$warm_delta_c))
msg("完成 / done")
