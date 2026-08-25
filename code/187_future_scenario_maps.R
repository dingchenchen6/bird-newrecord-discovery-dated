# ============================================================
# Scientific question / 科学问题:
# 把未来预测按"气候情景 × 调查努力情景"两个独立维度展开:
# SSP2-4.5 / SSP5-8.5 × 努力停滞 / 努力延续 × 2030 / 2050,
# 并在省级(和份额冻结假设下的县级)画出预测新纪录数地图。
# Future prediction maps with climate scenario and survey-effort
# scenario as INDEPENDENT axes (unlike script 141, which tied effort
# growth to the SSP), for 2030 and 2050.
#
# Scenario grid / 情景网格:
#   气候: SSP2-4.5, SSP5-8.5(CMIP6 4-GCM 集成中位 delta,省端与分布区端分别施加)
#   努力: 停滞(冻结在 2024 水平) vs 延续(+0.6 SD / 十年;
#         历史观测增速约 1.2 SD/十年,取 0.6 为保守延续档,与 141 高档一致)
#   期限: 2030, 2050(2080 不入图 —— 支撑域仅 2%,只作情景演示无地图价值)
#
# Input / 输入:
#   analysis_v2/data/model_v2_thr50.parquet, fit_R3.rds
#   analysis_species_specific/tables/tbl_F_cmip6_delta.csv
#   analysis_v2/data/admin/county_surface_now.csv       (县级份额,机制面)
# Output / 输出:
#   analysis_v2/tables/tbl_future_scenario_grid.csv
#   analysis_v2/figures_multiscale/FigMS3_future_scenarios (png/pdf)
#
# Key assumptions / 关键假设:
#   - 未来年的 省×年 随机项不存在,取总体均值(allow.new.levels);
#     物种与省的 BLUP 保留。预测为条件于已知层级的期望。
#   - 支撑域掩膜与 141 相同(训练协变量 1–99 百分位);
#     地图透明度 = 该省落在支撑域内的物种行比例,并标注全国比例。
#   - 县级行采用"份额冻结"假设:省内分配份额取 2024 机制面,
#     只有省级期望数随情景变化 —— 这是显式声明的简化。
# Main packages / 主要包: glmmTMB, sf, ggplot2, patchwork, data.table
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(glmmTMB); library(sf)
  library(ggplot2); library(patchwork); library(scales)
})
sf_use_s2(FALSE)
set.seed(20260825)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
SS   <- file.path(V2, "analysis_species_specific")
D_AD <- file.path(V2, "analysis_v2/data/admin")
D_TB <- file.path(V2, "analysis_v2/tables")
D_FG <- file.path(V2, "analysis_v2/figures_multiscale")
BM   <- file.path(V2, "data/spatial/basemap_GS2019_1822")
AEA  <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +datum=WGS84 +units=m"
msg  <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

EFF_SCEN <- c(`努力停滞` = 0, `努力延续` = 0.6)     # SD / 十年
SSP_LAB  <- c(ssp245 = "SSP2-4.5", ssp585 = "SSP5-8.5")

# ---------------- 数据与模型 ----------------
d <- as.data.table(read_parquet(file.path(V2, "analysis_v2/data/model_v2_thr50.parquet")))
d <- d[usable_main == TRUE]
CC_MU <- mean(d$clim_change); CC_SD <- sd(d$clim_change)
d[, `:=`(clim_change_z = (clim_change - CC_MU) / CC_SD,
         clim_var_z = as.numeric(scale(clim_var)), effort_z = eff_visits_gap_z)]
fit <- readRDS(file.path(V2, "analysis_v2/data", "fit_R3.rds"))
msg("主模型已载入;基期 ", max(d$year))

cm6 <- fread(file.path(SS, "tables", "tbl_F_cmip6_delta.csv"))
dp <- cm6[unit == "province", .(province = name, ssp, horizon, d_prov = delta)]
ds <- cm6[unit == "species",  .(species  = name, ssp, horizon, d_sp   = delta)]

SUP <- list(cc = quantile(d$clim_change_z, c(.01, .99)),
            ef = quantile(d$effort_z, c(.01, .99)))
base <- d[year == max(d$year)]

# ---------------- 情景网格投影 ----------------
grid <- CJ(ssp = c("ssp245", "ssp585"), eff = names(EFF_SCEN), hz = c(2030L, 2050L))
proj <- rbindlist(lapply(seq_len(nrow(grid)), function(i) {
  g <- grid[i]
  b <- copy(base)
  b <- merge(b, dp[ssp == g$ssp & horizon == g$hz, .(province, d_prov)], by = "province", all.x = TRUE)
  b <- merge(b, ds[ssp == g$ssp & horizon == g$hz, .(species, d_sp)], by = "species", all.x = TRUE)
  b[is.na(d_prov), d_prov := 0]; b[is.na(d_sp), d_sp := 0]
  b[, clim_change_z := (clim_change + (d_prov - d_sp) - CC_MU) / CC_SD]
  b[, effort_z := effort_z + EFF_SCEN[[g$eff]] * (g$hz - max(d$year)) / 10]
  b[, in_support := clim_change_z %between% SUP$cc & effort_z %between% SUP$ef]
  # fit_R3 的省×年随机项用预构造列 prov_year;未来年为新层,取总体均值
  b[, prov_year := interaction(province, paste0("F", g$hz), drop = TRUE)]
  p <- predict(fit, newdata = b, type = "response", allow.new.levels = TRUE)
  b[, .(ssp = g$ssp, eff = g$eff, horizon = g$hz, province, species, p = p, in_support)]
}))

prov_grid <- proj[, .(exp_n = sum(p), n_sp = .N, pct_sup = mean(in_support)), by = .(ssp, eff, horizon, province)]
fwrite(prov_grid, file.path(D_TB, "tbl_future_scenario_grid.csv"))
nat <- proj[, .(total = round(sum(p), 1), pct_sup = round(100 * mean(in_support))), by = .(ssp, eff, horizon)]
cat("\n== 全国期望新纪录数 × 情景 ==\n"); print(dcast(nat, ssp + eff ~ horizon, value.var = c("total", "pct_sup")))

# ---------------- 地图 ----------------
theme_map <- function(base = 9) {
  theme_void(base_size = base, base_family = "sans") +
    theme(plot.title = element_text(face = "bold", size = base + 0.5, hjust = 0),
          plot.subtitle = element_text(size = base - 1.2, colour = "grey30", hjust = 0),
          legend.key.height = unit(3.0, "mm"), legend.key.width = unit(9, "mm"),
          legend.text = element_text(size = base - 1.5),
          legend.title = element_text(size = base - 1, face = "bold"),
          legend.position = "bottom")
}
prov_sf <- st_make_valid(st_transform(st_read(file.path(BM, "省（等积投影）.shp"), quiet = TRUE), AEA))
cnty_sf <- st_make_valid(st_transform(st_read(file.path(BM, "县（等积投影）.shp"), quiet = TRUE), AEA))
nine    <- st_transform(st_read(file.path(BM, "九段线.shp"), quiet = TRUE), AEA)
nation  <- st_make_valid(st_transform(st_read(file.path(BM, "国界.shp"), quiet = TRUE), AEA))
cnty_sf$unit_id <- as.integer(cnty_sf$PAC)
lk <- unique(fread(file.path(D_AD, "units_county.csv"))[, .(province, prov_cn)])
prov_grid <- merge(prov_grid, lk, by = "province", all.x = TRUE)

cnty_share <- fread(file.path(D_AD, "county_surface_now.csv"))[, .(unit_id, province, share)]

lims_p <- quantile(prov_grid$exp_n, c(0.02, 0.995))
cell_prov <- function(sp_, ef_, hz_, title, show_legend) {
  gd <- prov_grid[ssp == sp_ & eff == ef_ & horizon == hz_]
  m <- merge(prov_sf, gd[, .(prov_cn, exp_n, pct_sup)], by.x = "省", by.y = "prov_cn", all.x = FALSE)
  n0 <- nat[ssp == sp_ & eff == ef_ & horizon == hz_]
  ggplot() +
    geom_sf(data = prov_sf, fill = "grey96", colour = NA) +
    geom_sf(data = m, aes(fill = pmax(pmin(exp_n, lims_p[2]), lims_p[1]), alpha = pct_sup),
            colour = "white", linewidth = .15) +
    geom_sf(data = nation, fill = NA, colour = "grey35", linewidth = .18) +
    geom_sf(data = nine, colour = "grey25", linewidth = .3) +
    scale_fill_distiller(palette = "RdYlBu", direction = -1, trans = "log10",
                         limits = lims_p, oob = squish, name = "预测新纪录数 / 年",
                         labels = function(x) formatC(signif(x, 1), format = "fg")) +
    scale_alpha_continuous(range = c(0.30, 1), limits = c(0, 1), guide = "none") +
    coord_sf(expand = FALSE) +
    labs(title = title,
         subtitle = sprintf("全国 %.1f 条/年 · 支撑域内 %d%%", n0$total, n0$pct_sup)) +
    theme_map() + theme(legend.position = if (show_legend) "bottom" else "none")
}

cw <- merge(cnty_share, prov_grid[horizon == 2050, .(ssp, eff, province, exp_n, pct_sup)],
            by = "province", allow.cartesian = TRUE)
cw[, val := share * exp_n]
lims_c <- quantile(cw$val[cw$val > 0], c(0.02, 0.999))
cell_cnty <- function(sp_, ef_, title, show_legend) {
  gd <- cw[ssp == sp_ & eff == ef_]
  m <- merge(cnty_sf, gd[, .(unit_id, val, pct_sup)], by = "unit_id", all.x = FALSE)
  ggplot() +
    geom_sf(data = prov_sf, fill = "grey96", colour = NA) +
    geom_sf(data = m, aes(fill = pmax(pmin(val, lims_c[2]), lims_c[1]), alpha = pct_sup), colour = NA) +
    geom_sf(data = prov_sf, fill = NA, colour = "white", linewidth = .1) +
    geom_sf(data = nation, fill = NA, colour = "grey35", linewidth = .18) +
    geom_sf(data = nine, colour = "grey25", linewidth = .3) +
    scale_fill_distiller(palette = "RdYlBu", direction = -1, trans = "log10",
                         limits = lims_c, oob = squish, name = "预测新纪录数(县级,2050)",
                         labels = function(x) formatC(signif(x, 1), format = "fg")) +
    scale_alpha_continuous(range = c(0.30, 1), limits = c(0, 1), guide = "none") +
    coord_sf(expand = FALSE) +
    labs(title = title) +
    theme_map() + theme(legend.position = if (show_legend) "bottom" else "none")
}

COLS <- CJ(ssp = c("ssp245", "ssp585"), eff = names(EFF_SCEN), sorted = FALSE)
row1 <- lapply(seq_len(4), function(i)
  cell_prov(COLS$ssp[i], COLS$eff[i], 2030L,
            paste0(if (i == 1) "a  2030:" else "", SSP_LAB[COLS$ssp[i]], " · ", COLS$eff[i]),
            show_legend = FALSE))
row2 <- lapply(seq_len(4), function(i)
  cell_prov(COLS$ssp[i], COLS$eff[i], 2050L,
            paste0(if (i == 1) "b  2050:" else "", SSP_LAB[COLS$ssp[i]], " · ", COLS$eff[i]),
            show_legend = (i == 2)))
row3 <- lapply(seq_len(4), function(i)
  cell_cnty(COLS$ssp[i], COLS$eff[i],
            paste0(if (i == 1) "c  2050 县级:" else "", SSP_LAB[COLS$ssp[i]], " · ", COLS$eff[i]),
            show_legend = (i == 2)))

FigMS3 <- wrap_plots(c(row1, row2, row3), nrow = 3, ncol = 4) +
  plot_annotation(
    title = "未来情景下的预测新纪录数:气候情景 × 调查努力情景(2030 / 2050)",
    subtitle = paste0("离散风险主模型;气候 delta 取 CMIP6 4-GCM 集成中位,分别施加于省端与物种分布区端;",
                      "努力停滞 = 冻结于 2024,努力延续 = +0.6 SD/十年(历史观测增速约 1.2)。\n",
                      "透明度 = 该省落在训练协变量支撑域(1–99 百分位)内的比例;",
                      "县级行为份额冻结假设(省内分配取 2024 机制面),色标行内共享(log10)。"),
    caption = "底图:审图号 GS(2019)1822(主图全幅含南海诸岛与九段线)。",
    theme = theme(plot.title = element_text(face = "bold", size = 12, hjust = 0),
                  plot.subtitle = element_text(size = 8.4, colour = "grey30", hjust = 0),
                  plot.caption = element_text(size = 7, colour = "grey45", hjust = 0)))
ggsave(file.path(D_FG, "FigMS3_future_scenarios.png"), FigMS3,
       width = 14.6, height = 11.0, dpi = 400, bg = "white")
ggsave(file.path(D_FG, "FigMS3_future_scenarios.pdf"), FigMS3,
       width = 14.6, height = 11.0, device = grDevices::cairo_pdf)
cat("wrote FigMS3\n")
