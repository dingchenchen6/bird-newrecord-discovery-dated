#!/usr/bin/env Rscript
# ============================================================
# Script 145: 气候基线敏感性 1970-2000 vs 1980-2000, 窗口 5/10/15/20
# Baseline sensitivity, 1970-2000 vs 1980-2000, at windows 5/10/15/20
# ============================================================
# 科学问题 / Scientific question:
#   气候基线定义"物种历史上习惯的气候"与"该省历史的气候"。基线越长越稳定,
#   但越早的年份与当代分布边界的关联越弱。1970-2000(31 年)与 1980-2000
#   (21 年)是文献中两种常见选择, 结论不应依赖于二者之一。
#
# 设计上的一个必要控制 / A control the design requires:
#   主分析用 WorldClim 2.1 对 CRU TS 的 10 角分降尺度, 该数据集自 1980 年起,
#   无法给出 1970-2000 基线。故本脚本改用 CRU TS 4.09 原生 0.5 度(1901-2024)
#   重建整条链路, 并同时拟合 CRU 的 1980-2000 与 1970-2000 两个基线。
#   这样"换基线"与"换数据源"被拆成两个独立对比:
#     WorldClim 1980-2000  vs  CRU 1980-2000   => 数据源与分辨率的影响
#     CRU 1980-2000        vs  CRU 1970-2000   => 基线期本身的影响
#   若把两者合成一次比较, 就无法判断差异来自哪一个。
#
# 变量定义 / Variable definitions 与主分析一致:
#   x(s,p,t)    = [T(p,t) − T_base(p)] − [N(s,t) − N_base(s)]
#   clim_change = x 在 [t−W+1, t] 的滑动均值;  clim_var = x − clim_change
#   T(p,t) 为省内网格按"网格∩省"重叠面积加权的均值
#
# 窗口 / Windows: 5, 10, 15, 20 年
#
# Input / 输入:
#   CRU TS 4.09 月均温 NetCDF (1901-2024)
#   china_grid_100km_v2.rds | BOTW_clean.gpkg
#   analysis_v2/data/model_v2_thr50.parquet | analysis_rebuilt/data/grid_province_lookup.csv
# Output / 输出:
#   analysis_v2/data/panel_cru_{grid,species}.csv     (可复用, 提取一次)
#   analysis_v2/tables/tbl_v2_baseline_sensitivity.csv
#
# Main packages / 主要包: terra, sf, exactextractr, glmmTMB, data.table, arrow
# 运行 / Run: Rscript --no-init-file code/145_baseline_1970_sensitivity.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(terra); library(sf); library(glmmTMB)
})
options(warn = 1); sf::sf_use_s2(FALSE)

V2  <- normalizePath(".", mustWork = TRUE)
RB  <- file.path(V2, "analysis_rebuilt"); OUT <- file.path(V2, "analysis_v2")
msg <- function(...) cat(sprintf("[145 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

CRU  <- "/Users/dingchenchen/lucc/0_data/cru_ts4.09.1901.2024.tmp.dat.nc"
GRID <- "/Users/dingchenchen/Documents/New project/bird_dynamic_occupancy_analysis/data/derived_v2/china_grid_100km_v2.rds"
BOTW <- "/Users/dingchenchen/Documents/NEW DISTRIBUTION RECORDS/BOTW_clean.gpkg"

WINS <- c(5L, 10L, 15L, 20L)
BASES <- list(`1970-2000` = c(1970L, 2000L), `1980-2000` = c(1980L, 2000L))
YR_FROM <- 2002L; YR_TO <- 2024L; SERIES_FROM <- 1970L
RE_MAIN <- "(1|species) + (1|province) + (1|prov_year)"
EFFORT <- "eff_visits_gap_z"
zs <- function(v) as.numeric(scale(v))

gf <- file.path(OUT, "data", "panel_cru_grid.csv")
sf_ <- file.path(OUT, "data", "panel_cru_species.csv")

# ---- 1. CRU 年均温提取 (1970-2024) ----
if (!file.exists(gf) || !file.exists(sf_)) {
  msg("提取 CRU TS 年均温 ", SERIES_FROM, "-", YR_TO, " ...")
  cr <- terra::rast(CRU)
  yrs <- as.integer(format(terra::time(cr), "%Y"))
  keep <- which(yrs >= SERIES_FROM & yrs <= YR_TO)
  cr <- cr[[keep]]; yrs <- yrs[keep]
  ann <- terra::tapp(cr, index = yrs, fun = mean, na.rm = TRUE)
  names(ann) <- as.character(sort(unique(yrs)))
  msg("  年均温栅格 ", terra::nlyr(ann), " 层")

  grid <- st_make_valid(st_transform(readRDS(GRID), 4326))
  g2p  <- fread(file.path(RB, "data", "grid_province_lookup.csv"), encoding = "UTF-8")
  grid <- grid[grid$grid_cell %in% g2p$grid_cell, ]
  d0   <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
  rng  <- st_make_valid(st_read(BOTW, quiet = TRUE))
  names(rng)[names(rng) == "sci_name"] <- "species"
  rng  <- rng[rng$species %in% unique(d0$species), ]
  msg("  目标: 网格 ", nrow(grid), " | 分布区 ", nrow(rng))

  ex <- function(obj, idcol, ids) {
    m <- as.data.table(exactextractr::exact_extract(ann, obj, "mean", progress = FALSE))
    setnames(m, sub("^mean\\.", "", names(m)))
    m[[idcol]] <- ids
    lg <- melt(m, id.vars = idcol, variable.name = "year", value.name = "val")
    lg[, year := as.integer(as.character(year))][is.finite(year)]
  }
  gp <- ex(grid, "grid_cell", grid$grid_cell); fwrite(gp, gf)
  sp <- ex(rng, "species", rng$species);       fwrite(sp, sf_)
  msg("  wrote panel_cru_grid.csv (", nrow(gp), ") / panel_cru_species.csv (", nrow(sp), ")")
} else msg("复用已提取的 CRU 面板")

gp  <- fread(gf); sp <- fread(sf_)
g2p <- fread(file.path(RB, "data", "grid_province_lookup.csv"), encoding = "UTF-8")
gp  <- merge(gp, g2p[, .(grid_cell, province, olap)], by = "grid_cell")
prov_t <- gp[, .(T_t = stats::weighted.mean(val, olap, na.rm = TRUE)), by = .(province, year)]
nat_t  <- sp[, .(N_t = mean(val, na.rm = TRUE)), by = .(species, year)]
msg("CRU 省级序列 ", uniqueN(prov_t$province), " 省 | 物种序列 ", uniqueN(nat_t$species), " 种 | ",
    min(prov_t$year), "-", max(prov_t$year))

# ---- 2. 风险集 ----
d0 <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
d0[, c("x", "clim_change", "clim_var") := NULL]
d0 <- d0[is.finite(get(EFFORT))]
d0[, prov_year := interaction(province, year, drop = TRUE)]
pp <- unique(d0[, .(species, province)])

res <- list()
for (bk in names(BASES)) {
  BS <- BASES[[bk]]
  pb <- prov_t[year %between% BS, .(T_base = mean(T_t)), by = province]
  nb <- nat_t[year %between% BS, .(N_base = mean(N_t)), by = species]
  cc <- merge(pp, merge(prov_t, pb, by = "province"), by = "province", allow.cartesian = TRUE)
  cc <- merge(cc, merge(nat_t, nb, by = "species"), by = c("species", "year"))
  cc[, x := (T_t - T_base) - (N_t - N_base)]
  setorder(cc, species, province, year)
  for (W in WINS) {
    cc[, clim_change := frollmean(x, W, align = "right"), by = .(species, province)]
    cc[, clim_var := x - clim_change]
    d <- merge(d0, cc[year %between% c(YR_FROM, YR_TO), .(species, province, year, clim_change, clim_var)],
               by = c("species", "province", "year"))
    d <- d[is.finite(clim_change) & is.finite(clim_var)]
    d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var), effort_z = zs(get(EFFORT)))]
    f <- as.formula(paste("event ~ clim_change_z * effort_z + clim_var_z + offset(log_completeness) +", RE_MAIN))
    t0 <- Sys.time()
    m <- tryCatch(glmmTMB(f, data = d, family = binomial("cloglog")),
                  error = function(e) { msg("  FAILED ", bk, " W", W, ": ", conditionMessage(e)); NULL })
    if (is.null(m)) next
    cf <- summary(m)$coefficients$cond
    it <- grep(":", rownames(cf), value = TRUE)[1]
    g <- function(t, k) if (t %in% rownames(cf)) cf[t, k] else NA_real_
    res[[paste(bk, W)]] <- data.table(
      source = "CRU TS 4.09 (0.5 deg)", baseline = bk, window = W,
      n = nrow(d), events = sum(d$event), AIC = AIC(m),
      sd_change_degC = stats::sd(d$clim_change),
      HR_change = exp(g("clim_change_z", 1)),
      lo_change = exp(g("clim_change_z", 1) - 1.96 * g("clim_change_z", 2)),
      hi_change = exp(g("clim_change_z", 1) + 1.96 * g("clim_change_z", 2)), P_change = g("clim_change_z", 4),
      HR_effort = exp(g("effort_z", 1)),
      lo_effort = exp(g("effort_z", 1) - 1.96 * g("effort_z", 2)),
      hi_effort = exp(g("effort_z", 1) + 1.96 * g("effort_z", 2)), P_effort = g("effort_z", 4),
      HR_var = exp(g("clim_var_z", 1)), P_var = g("clim_var_z", 4),
      HR_int = exp(g(it, 1)), lo_int = exp(g(it, 1) - 1.96 * g(it, 2)),
      hi_int = exp(g(it, 1) + 1.96 * g(it, 2)), P_int = g(it, 4))
    msg(sprintf("  %s W=%2d  n=%s ev=%d AIC=%8.1f  HR_ch=%.3f(%.0e)  HR_eff=%.3f  HR_int=%.3f(%.3f)  SD=%.3f°C [%.0fs]",
        bk, W, format(nrow(d), big.mark = ","), sum(d$event), AIC(m),
        res[[paste(bk, W)]]$HR_change, res[[paste(bk, W)]]$P_change, res[[paste(bk, W)]]$HR_effort,
        res[[paste(bk, W)]]$HR_int, res[[paste(bk, W)]]$P_int, res[[paste(bk, W)]]$sd_change_degC,
        as.numeric(difftime(Sys.time(), t0, units = "secs"))))
    rm(m, d); invisible(gc())
  }
}
cru <- rbindlist(res)

# ---- 3. 并入主数据源(WorldClim, 1980-2000) 的同窗口结果作对照 ----
wc <- fread(file.path(OUT, "tables", "tbl_v2_window_baseline_sensitivity.csv"))[
  baseline == "1980-2000" & window %in% WINS]
wc[, `:=`(source = "WorldClim 2.1 / CRU TS (10 arcmin, main)", baseline = "1980-2000")]
keep <- intersect(names(cru), names(wc))
tb <- rbind(cru[, ..keep], wc[, ..keep])
tb[, dAIC := AIC - min(AIC), by = .(source, baseline)]
setorder(tb, source, baseline, window)
fwrite(tb, file.path(OUT, "tables", "tbl_v2_baseline_sensitivity.csv"))
print(tb[, .(source = substr(source, 1, 22), baseline, window, HR_change = round(HR_change, 3),
             P_change = signif(P_change, 2), HR_effort = round(HR_effort, 3),
             HR_int = round(HR_int, 3), P_int = signif(P_int, 2), dAIC = round(dAIC, 1))])
msg("wrote tbl_v2_baseline_sensitivity.csv | DONE")
