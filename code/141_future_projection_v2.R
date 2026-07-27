#!/usr/bin/env Rscript
# ============================================================
# Script 141: v2 未来情景预测 —— 机制模型 vs 可解释机器学习
# v2 future projections: mechanistic hazard model vs interpretable ML
# ============================================================
# 科学问题 / Scientific question:
#   在冻结的 v2 主模型下, 未来新记录【生成风险】的空间格局如何演变?
#   机制模型与机器学习是否给出一致的格局与驱动解释?
#
# v2 相对 v1 的三处关键改动 / Three key changes over the v1 projection:
#   (1) 主模型含省×年随机效应。未来年份不存在该层级, 故预测时以
#       re.form = ~(1|species)+(1|province) 排除之, 即把地区-年冲击
#       设为其期望(0)。这在语义上正确: 我们预测的是【期望风险】,
#       而不是某个特定年份的偶发观测冲击。
#   (2) 完整度 offset 在预测时设为 log(1) = 0。即投影的是【潜在生成风险】
#       (若全部记录都已见刊), 而非受发表滞后删失后的观测风险。
#   (3) 基期改为 2024 年的发现年口径行, 努力用覆盖缺口口径。
#
# 未来情景 / Scenarios:
#   气候: CMIP6 4-GCM 集成中位 delta, SSP2-4.5 / SSP5-8.5 x 2030 / 2050 / 2080
#         ★ delta 必须【同时施加到目标省与物种分布区两端】。物种特异梯度
#           x = 省异常 − 分布区异常, 空间近均一的增温在两端相互抵消,
#           只施加一端会凭空造出气候效应。
#   努力: SSP 差异化增长 (SSP245 +0.30, SSP585 +0.60 SD/decade)
#         ★ 到 2080 年努力被外推至 +1.7 / +3.4 SD, 远超观测范围,
#           世纪末结果只能作为情景演示, 不是预报。
#
# Output / 输出 (analysis_v2/figures_future/):
#   FigM1 机制模型省级预测面 | FigM2 ML 预测面
#   FigM3 SHAP 可解释性 | FigM4 机制 vs ML 一致性
#   每图 PNG(450dpi) + PDF + SVG + 可编辑 PPTX + source data
#
# Main packages / 主要包: glmmTMB, xgboost, sf, ggplot2, officer, rvg
# 运行 / Run: Rscript --no-init-file code/141_future_projection_v2.R
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(glmmTMB); library(xgboost)
  library(sf); library(ggplot2); library(patchwork); library(officer); library(rvg)
})
options(warn = 1); set.seed(42); sf::sf_use_s2(FALSE)

V2  <- normalizePath(".", mustWork = TRUE)
SS  <- file.path(V2, "analysis_species_specific")
OUT <- file.path(V2, "analysis_v2")
FIG <- file.path(OUT, "figures_future"); TAB <- file.path(OUT, "tables")
SHP <- file.path(V2, "data", "spatial", "basemap_GS2019_1822")
dir.create(FIG, recursive = TRUE, showWarnings = FALSE)
msg <- function(...) cat(sprintf("[141 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

OI <- c(blue = "#0072B2", orange = "#E69F00", green = "#009E73", red = "#D55E00",
        purple = "#CC79A7", sky = "#56B4E9", grey = "#999999")
EFF_GROW <- c(ssp245 = 0.30, ssp585 = 0.60)
FEATS <- c("clim_change_z", "clim_var_z", "effort_z")

theme_pub <- function(base = 9) theme_classic(base_size = base, base_family = "sans") +
  theme(axis.line = element_line(linewidth = 0.35, colour = "grey20"),
        axis.ticks = element_line(linewidth = 0.3, colour = "grey20"),
        panel.grid.major.y = element_line(linewidth = 0.25, colour = "grey92"),
        strip.background = element_blank(),
        strip.text = element_text(face = "bold", size = base, hjust = 0),
        plot.title = element_text(face = "bold", size = base + 1, hjust = 0),
        plot.subtitle = element_text(size = base - 0.8, colour = "grey30", hjust = 0),
        plot.caption = element_text(size = base - 2, colour = "grey35", hjust = 0),
        plot.tag = element_text(face = "bold", size = base + 3),
        legend.key.size = unit(9, "pt"), plot.margin = margin(6, 8, 6, 8))
theme_map <- function(base = 9) theme_void(base_size = base, base_family = "sans") +
  theme(strip.text = element_text(face = "bold", size = base),
        plot.title = element_text(face = "bold", size = base + 2, hjust = 0),
        plot.subtitle = element_text(size = base - 0.5, colour = "grey30", hjust = 0),
        plot.caption = element_text(size = base - 2.5, colour = "grey35", hjust = 0),
        legend.position = "right", legend.key.width = unit(9, "pt"),
        plot.margin = margin(8, 10, 8, 10))

save_all <- function(p, name, w, h, src = NULL) {
  for (ext in c("png", "pdf", "svg"))
    tryCatch({
      f <- file.path(FIG, paste0(name, ".", ext))
      if (ext == "png") ggsave(f, p, width = w, height = h, dpi = 450, bg = "white")
      else if (ext == "pdf") ggsave(f, p, width = w, height = h, device = grDevices::cairo_pdf)
      else ggsave(f, p, width = w, height = h, device = grDevices::svg)
    }, error = function(e) msg("  ", ext, " failed: ", conditionMessage(e)))
  tryCatch({
    ppt <- add_slide(read_pptx(), "Blank", "Office Theme")
    ppt <- ph_with(ppt, dml(ggobj = p, bg = "white"),
                   location = ph_location(left = 0.2, top = 0.2, width = w, height = h))
    print(ppt, target = file.path(FIG, paste0(name, ".pptx")))
  }, error = function(e) msg("  pptx failed: ", conditionMessage(e)))
  if (!is.null(src)) fwrite(src, file.path(FIG, paste0("source_data_", name, ".csv")))
  msg("  saved ", name)
}

# ---- 1. 数据与模型 ----
d <- as.data.table(read_parquet(file.path(OUT, "data", "model_v2_thr50.parquet")))
d[, c("x", "clim_change", "clim_var") := NULL]
cc <- as.data.table(read_parquet(file.path(OUT, "data", "components_v2_tavg_annual_W15.parquet")))
d <- merge(d, cc[, .(species, province, year, clim_change, clim_var)], by = c("species", "province", "year"))
d <- d[is.finite(clim_change) & is.finite(clim_var) & is.finite(eff_visits_gap_z)]
CC_MU <- mean(d$clim_change); CC_SD <- stats::sd(d$clim_change)
CV_MU <- mean(d$clim_var);    CV_SD <- stats::sd(d$clim_var)
EF_MU <- mean(d$eff_visits_gap_z); EF_SD <- stats::sd(d$eff_visits_gap_z)
d[, `:=`(clim_change_z = (clim_change - CC_MU) / CC_SD,
         clim_var_z    = (clim_var - CV_MU) / CV_SD,
         effort_z      = (eff_visits_gap_z - EF_MU) / EF_SD,
         prov_year     = interaction(province, year, drop = TRUE))]
msg("建模集 ", format(nrow(d), big.mark = ","), " 行 | ", sum(d$event), " 事件")

mech <- readRDS(file.path(OUT, "data", "fit_R3.rds"))
xgb_file <- file.path(OUT, "data", "xgb_v2.rds")
if (file.exists(xgb_file)) { bst <- readRDS(xgb_file); msg("复用 XGBoost 模型") } else {
  dm <- xgb.DMatrix(as.matrix(d[, ..FEATS]), label = d$event)
  bst <- xgb.train(list(objective = "binary:logistic", eta = 0.05, max_depth = 4,
                        subsample = 0.8, colsample_bytree = 0.9, eval_metric = "auc"),
                   dm, nrounds = 400, verbose = 0)
  saveRDS(bst, xgb_file); msg("XGBoost 训练完成")
}

# 预测辅助 / prediction helper
# glmmTMB::predict 的 re.form 只接受 NULL / NA / ~0, 无法部分排除随机效应,
# 故手工装配线性预测子: 固定效应 + 物种 BLUP + 省 BLUP, 省×年冲击置于期望 0,
# 完整度 offset 置 0(即 c = 1), 从而投影【潜在生成风险】。
# NB: assembled by hand because glmmTMB cannot drop a subset of random terms.
BETA  <- fixef(mech)$cond
RE    <- ranef(mech)$cond
INT_NM <- grep(":", names(BETA), value = TRUE)[1]
blup <- function(tbl, keys) {
  v <- setNames(tbl[[1]], rownames(tbl))
  out <- unname(v[as.character(keys)]); out[is.na(out)] <- 0; out
}
pred_mech <- function(nd) {
  X <- cbind(1, nd$clim_change_z, nd$effort_z, nd$clim_var_z, nd$clim_change_z * nd$effort_z)
  colnames(X) <- c("(Intercept)", "clim_change_z", "effort_z", "clim_var_z", INT_NM)
  eta <- as.numeric(X[, names(BETA), drop = FALSE] %*% BETA) +
         blup(RE$species, nd$species) + blup(RE$province, nd$province)
  1 - exp(-exp(eta))
}

# ---- 2. 未来协变量 ----
cm6 <- fread(file.path(SS, "tables", "tbl_F_cmip6_delta.csv"))
dp <- cm6[unit == "province", .(province = name, ssp, horizon, d_prov = delta)]
ds <- cm6[unit == "species",  .(species  = name, ssp, horizon, d_sp   = delta)]
base_yr <- d[year == max(year)]
msg("投影基期 ", max(d$year), ": ", nrow(base_yr), " 行 | ", uniqueN(base_yr$province), " 省")

proj <- rbindlist(lapply(c("ssp245", "ssp585"), function(sp_)
  rbindlist(lapply(c(2030L, 2050L, 2080L), function(hz) {
    b <- copy(base_yr)
    b <- merge(b, dp[ssp == sp_ & horizon == hz, .(province, d_prov)], by = "province", all.x = TRUE)
    b <- merge(b, ds[ssp == sp_ & horizon == hz, .(species, d_sp)],   by = "species",  all.x = TRUE)
    b[is.na(d_prov), d_prov := 0]; b[is.na(d_sp), d_sp := 0]
    b[, clim_change_f := clim_change + (d_prov - d_sp)]          # delta 施加两端
    b[, clim_change_z := (clim_change_f - CC_MU) / CC_SD]
    b[, effort_z := effort_z + EFF_GROW[[sp_]] * (hz - max(d$year)) / 10]
    b[, `:=`(ssp = sp_, horizon = hz)]; b
  }))))
# 支撑域掩膜 / support mask
#   历史物种特异梯度 x 的 SD 仅 0.179 °C(省端与分布区端的异常大体同步),
#   而未来 GCM 的省-分布区 delta 差可达 ±2 °C, 即 5-12 个标准差。
#   在此范围外, cloglog 的线性外推与树模型的边界饱和都不可信。
#   故标记每一行是否落在训练协变量的 1-99 百分位内, 主图只用支撑域内的行。
# NB: both model families are unreliable outside the fitted covariate support;
#     the mask makes the reliable subset explicit rather than hiding the problem.
SUP <- list(cc = quantile(d$clim_change_z, c(.01, .99)),
            ef = quantile(d$effort_z,      c(.01, .99)))
proj[, in_support := clim_change_z %between% SUP$cc & effort_z %between% SUP$ef]
sup_smry <- proj[, .(rows = .N, in_support = sum(in_support),
                     pct = round(100 * mean(in_support), 1)), by = .(ssp, horizon)]
print(sup_smry); fwrite(sup_smry, file.path(TAB, "tbl_v2_future_support.csv"))
msg("支撑域内比例: ", paste(sprintf("%s/%d=%.0f%%", sup_smry$ssp, sup_smry$horizon, sup_smry$pct), collapse = " | "))

proj[, p_mech := pred_mech(proj)]
proj[, p_ml   := as.numeric(predict(bst, as.matrix(proj[, FEATS, with = FALSE])))]

b24 <- copy(base_yr)
b24[, p_mech := pred_mech(b24)]
b24[, p_ml := as.numeric(predict(bst, as.matrix(b24[, FEATS, with = FALSE])))]
base_prov <- b24[, .(mech0 = mean(p_mech, na.rm = TRUE), ml0 = mean(p_ml, na.rm = TRUE)), by = province]

agg <- function(dt) dt[, .(mech = 100 * mean(p_mech, na.rm = TRUE),
                           ml   = 100 * mean(p_ml,   na.rm = TRUE),
                           n_sp = uniqueN(species)), by = .(province, ssp, horizon)]
prov_all <- merge(agg(proj), base_prov, by = "province")
prov_sup <- merge(agg(proj[in_support == TRUE]), base_prov, by = "province")
for (x in list(prov_all, prov_sup)) x[, `:=`(mech_ratio = (mech / 100) / mech0, ml_ratio = (ml / 100) / ml0)]
prov_all[, scope := "all rows"]; prov_sup[, scope := "within covariate support"]
prov_proj <- prov_all                                    # 图件默认用全量, 但同时输出支撑域版本
fwrite(rbind(prov_all, prov_sup), file.path(TAB, "tbl_v2_future_province_projection.csv"))
msg("相对倍数(全量): 机制 ", round(min(prov_all$mech_ratio), 2), "-", round(max(prov_all$mech_ratio), 2),
    " | ML ", round(min(prov_all$ml_ratio), 2), "-", round(max(prov_all$ml_ratio), 2))
msg("相对倍数(支撑域内): 机制 ", round(min(prov_sup$mech_ratio), 2), "-", round(max(prov_sup$mech_ratio), 2),
    " | ML ", round(min(prov_sup$ml_ratio), 2), "-", round(max(prov_sup$ml_ratio), 2))

# ---- 3. 底图 ----
PROV_CN_EN <- c("北京市"="Beijing","天津市"="Tianjin","河北省"="Hebei","山西省"="Shanxi",
 "内蒙古自治区"="Inner Mongolia","辽宁省"="Liaoning","吉林省"="Jilin","黑龙江省"="Heilongjiang",
 "上海市"="Shanghai","江苏省"="Jiangsu","浙江省"="Zhejiang","安徽省"="Anhui","福建省"="Fujian",
 "江西省"="Jiangxi","山东省"="Shandong","河南省"="Henan","湖北省"="Hubei","湖南省"="Hunan",
 "广东省"="Guangdong","广西壮族自治区"="Guangxi","海南省"="Hainan","重庆市"="Chongqing",
 "四川省"="Sichuan","贵州省"="Guizhou","云南省"="Yunnan","西藏自治区"="Tibet","陕西省"="Shaanxi",
 "甘肃省"="Gansu","青海省"="Qinghai","宁夏回族自治区"="Ningxia","新疆维吾尔自治区"="Xinjiang",
 "台湾省"="Taiwan","香港特别行政区"="Hong Kong","澳门特别行政区"="Macau")
pv <- st_make_valid(st_transform(st_read(file.path(SHP, "省（等积投影）.shp"), quiet = TRUE), 4326))
pv$province <- unname(PROV_CN_EN[as.character(pv[["省"]])])
outline <- tryCatch(st_transform(st_read(file.path(SHP, "中国轮廓线.shp"), quiet = TRUE), 4326), error = function(e) NULL)
nanhai  <- tryCatch(st_transform(st_read(file.path(SHP, "九段线.shp"), quiet = TRUE), 4326), error = function(e) NULL)

sup_lab <- copy(sup_smry)[, `:=`(
  ssp_lab = factor(ssp, levels = c("ssp245", "ssp585"), labels = c("SSP2-4.5", "SSP5-8.5")),
  hz_lab = factor(horizon, levels = c(2030, 2050, 2080)),
  lab = sprintf("%.0f%% within support", pct))]

# 分析范围内的省级单元 / provincial units inside the analysis scope
SCOPE_PROV <- sort(unique(d$province))

# 制图要点 / Cartographic requirement:
#   掩膜会让某些分面只剩极少数省份有值。若用内连接合并几何, 没有值的省份会
#   整块从 sf 对象消失 —— 既无填充也【无省界】, 看起来像渲染失败。
#   正确做法是展开完整的【省 x 情景 x 年代】网格, 保证每个分面都画出全部省界,
#   并把三种状态用不同灰阶显式区分:
#     modelled              有支撑域内的投影            -> 连续配色
#     outside fitted range  在分析范围内, 但该情景-年代下无支撑域内的格子 -> 浅灰
#     not modelled          不在分析范围内(台港澳、中朝共有区)          -> 深灰
map_panel <- function(dt, valcol, title, sub, cap_extra = "") {
  dt <- as.data.table(dt)[is.finite(get(valcol)), .(province, ssp, horizon, val = get(valcol))]
  pv2 <- pv[, "province"]; pv2$uid <- seq_len(nrow(pv2))
  fac <- CJ(ssp = c("ssp245", "ssp585"), horizon = c(2030L, 2050L, 2080L))
  ix  <- CJ(uid = pv2$uid, fid = seq_len(nrow(fac)))
  full <- cbind(data.table(uid = ix$uid, province = pv2$province[ix$uid]), fac[ix$fid])
  full <- merge(full, dt, by = c("province", "ssp", "horizon"), all.x = TRUE, sort = FALSE)
  full[, state := fifelse(is.finite(val), "modelled",
                   fifelse(!is.na(province) & province %in% SCOPE_PROV,
                           "outside fitted range", "not modelled"))]
  mp <- merge(pv2, full, by = "uid", all.x = FALSE)
  mp$ssp_lab <- factor(mp$ssp, levels = c("ssp245", "ssp585"), labels = c("SSP2-4.5", "SSP5-8.5"))
  mp$hz_lab  <- factor(mp$horizon, levels = c(2030, 2050, 2080))
  # 图例刻度按实际数据范围取 2 的幂; 固定刻度在掩膜后会大半落到范围之外,
  # 使色标几乎没有可读的刻度 / adapt breaks to the data, else most fall outside
  rng <- range(mp$val, na.rm = TRUE)
  # NB: 必须【先过滤到数据范围再判断个数】。若先按 by=1 生成再过滤, 多数刻度
  #     会落到范围之外, 判断永远不触发加密分支, 色标只剩一两个刻度。
  mk <- function(step) { b <- 2^seq(floor(log2(rng[1])), ceiling(log2(rng[2])), by = step)
                         b[b >= rng[1] & b <= rng[2]] }
  brks <- mk(1)
  for (st in c(0.5, 0.25)) if (length(brks) < 4) brks <- mk(st)
  lab_brks <- ifelse(brks < 1, sprintf("%.2fx", brks), sprintf("%.2gx", brks))
  ggplot() +
    geom_sf(data = mp, aes(fill = val), colour = "grey45", linewidth = 0.1) +
    geom_sf(data = mp[mp$state == "not modelled", ], fill = "grey62",
            colour = "grey35", linewidth = 0.1) +
    { if (!is.null(outline)) geom_sf(data = outline, fill = NA, colour = "grey15", linewidth = 0.28) } +
    { if (!is.null(nanhai))  geom_sf(data = nanhai,  fill = NA, colour = "grey15", linewidth = 0.38) } +
    geom_text(data = sup_lab, aes(x = 76, y = 8, label = lab), hjust = 0, size = 2.2,
              colour = "grey25", inherit.aes = FALSE) +
    facet_grid(ssp_lab ~ hz_lab, switch = "y") +
    scale_fill_distiller(palette = "RdYlBu", direction = -1, na.value = "grey92",
                         trans = "log2", breaks = brks, labels = lab_brks,
                         name = "Hazard relative\nto 2024") +
    coord_sf(xlim = c(72, 136), ylim = c(2.5, 54), expand = TRUE) +
    labs(title = title, subtitle = sub,
         caption = paste(strwrap(paste0(
           "Latent generation hazard relative to the 2024 baseline (log2 colour scale); province-by-year shocks set to ",
           "expectation and reporting completeness set to 1. Base map GS(2019)1822. Pale grey: inside the analysis scope ",
           "but no cell falls within the fitted covariate range for that scenario and horizon. Mid grey: outside the ",
           "analysis scope (Taiwan, Hong Kong, Macao and the jointly administered area, none of which have provincial ",
           "effort coverage). ", cap_extra), width = 150), collapse = "\n")) +
    theme_map()
}

# 主图: 只用落在拟合协变量支撑域内的行 / main map uses only rows inside the fitted support
save_all(map_panel(prov_sup, "mech_ratio",
  "Mechanistic projection of new-record generation hazard",
  "Discrete-time cloglog model; CMIP6 4-GCM delta applied to both province and species-range climate; only rows inside the fitted covariate support",
  paste0("Only species-province rows whose warming and effort fall inside the 1st-99th percentile of the fitted data are ",
         "aggregated. The percentage in each panel is the share of rows that qualify:\nby 2050 under SSP5-8.5 only ",
         "2% do, so the later horizons rest on very few comparable cases and should be read as illustrations.")),
  "FigM1_future_mechanistic_v2", 9.4, 6.6, prov_sup)

save_all(map_panel(prov_sup, "ml_ratio",
  "Machine-learning projection of new-record generation hazard",
  "XGBoost on the same three predictors and identical future covariates; only rows inside the fitted covariate support",
  "Gradient boosting returns boundary leaf values outside the training range, so its surface flattens rather than extrapolating."),
  "FigM2_future_ml_v2", 9.4, 6.6, prov_sup)

# 附图: 不加掩膜的全量外推, 用于展示外推的量级 / unmasked extrapolation, for contrast
save_all(map_panel(prov_all, "mech_ratio",
  "Unmasked extrapolation of the mechanistic projection",
  "The same model applied to every row regardless of covariate support",
  paste0("Shown for contrast with the masked main figure. Hazard ratios reach 78x because the species-specific climate ",
         "gradient has a historical SD of only 0.18 degC,\nwhile future province-minus-range warming differentials reach ",
         "2 degC, i.e. more than ten standard deviations beyond the fitted range. These values are not forecasts.")),
  "FigS3_future_unmasked_v2", 9.4, 6.6, prov_all)

# ---- 4. SHAP 可解释性 ----
FEAT_LAB <- c(clim_change_z = "Accumulated warming", clim_var_z = "Annual variability",
              effort_z = "Survey effort")
sh <- predict(bst, as.matrix(d[, ..FEATS]), predcontrib = TRUE)
colnames(sh) <- c(FEATS, "BIAS")
shl <- melt(as.data.table(sh[, FEATS, drop = FALSE])[, row := .I], id.vars = "row",
            variable.name = "feature", value.name = "shap")
shl <- merge(shl, melt(d[, c(FEATS), with = FALSE][, row := .I], id.vars = "row",
                       variable.name = "feature", value.name = "x"), by = c("row", "feature"))
shl[, feat_lab := factor(FEAT_LAB[as.character(feature)], levels = FEAT_LAB)]

imp <- shl[, .(mean_abs_shap = mean(abs(shap))), by = feat_lab][order(-mean_abs_shap)]
ps1 <- ggplot(imp, aes(mean_abs_shap, reorder(feat_lab, mean_abs_shap), fill = feat_lab)) +
  geom_col(width = 0.6) +
  scale_fill_manual(values = unname(OI[c("green", "grey", "blue")]), guide = "none") +
  labs(x = "Mean |SHAP| (log-odds)", y = NULL, title = "Feature importance",
       subtitle = "Exact TreeSHAP over all training rows") + theme_pub()
set.seed(1); sub <- shl[sample(.N, min(.N, 60000))]
ps2 <- ggplot(sub, aes(x, shap, colour = feat_lab)) +
  geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3) +
  geom_point(alpha = 0.06, size = 0.35) +
  geom_smooth(method = "gam", formula = y ~ s(x, bs = "cs"), se = FALSE, linewidth = 0.7) +
  facet_wrap(~feat_lab, nrow = 1, scales = "free_x") +
  scale_colour_manual(values = unname(OI[c("green", "grey", "blue")]), guide = "none") +
  labs(x = "Standardised predictor", y = "SHAP contribution (log-odds)",
       title = "Dependence", subtitle = "Monotone increasing for both warming and effort") +
  theme_pub()
save_all((ps1 | ps2) + plot_layout(widths = c(1, 2.4)) + plot_annotation(tag_levels = "a"),
         "FigM3_shap_interpretability_v2", 11.0, 3.8, imp)

# ---- 5. 机制 vs ML: 范围内一致, 范围外分歧 ----
# 关键诊断 / The key diagnostic:
#   两族模型在【观测协变量范围内】是否一致? 在【外推区】是否一致?
#   若范围内一致而范围外分歧, 病因就是外推行为本身, 而非模型规格分歧。
#   梯度提升树在训练范围之外返回边界叶值 => 预测饱和; cloglog 模型则线性外推。

# (a) 范围内: 2002-2024 观测行, 按省-年聚合
d[, p_mech_obs := pred_mech(d)]
d[, p_ml_obs   := as.numeric(predict(bst, as.matrix(d[, ..FEATS])))]
inr <- d[, .(mech = mean(p_mech_obs), ml = mean(p_ml_obs)), by = .(province, year)]
r_in  <- cor(inr$mech, inr$ml, method = "spearman")
r_inp <- cor(log(inr$mech), log(inr$ml))
msg("范围内一致性 (省-年, n=", nrow(inr), "): Spearman rho = ", round(r_in, 3),
    " | Pearson(log) r = ", round(r_inp, 3))
pa1 <- ggplot(inr, aes(mech, ml)) +
  geom_point(colour = OI[["green"]], size = 0.8, alpha = 0.45) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "grey25", linewidth = 0.5) +
  scale_x_continuous(trans = "log10") + scale_y_continuous(trans = "log10") +
  annotate("text", x = -Inf, y = Inf, hjust = -0.12, vjust = 1.6, size = 2.8, colour = "grey20",
           label = sprintf("Spearman rho = %.2f", r_in)) +
  labs(x = "Mechanistic hazard", y = "Machine-learning hazard",
       title = "Within the observed range they track each other",
       subtitle = "Province-year mean predicted hazard, 2002-2024; moderate but clearly positive") + theme_pub()

# (b) 范围外: 未来投影
ag <- prov_proj[, .(province, ssp, horizon, mech_ratio, ml_ratio)]
ag[, `:=`(ssp_lab = factor(ssp, levels = c("ssp245", "ssp585"), labels = c("SSP2-4.5", "SSP5-8.5")),
          hz_lab  = factor(horizon))]
cors <- ag[, .(rho = cor(mech_ratio, ml_ratio, method = "spearman"),
               agree_dir = mean((mech_ratio > 1) == (ml_ratio > 1)), n = .N), by = .(ssp_lab, hz_lab)]
cors[, lab := sprintf("rho = %.2f\n%.0f%% agree on sign", rho, 100 * agree_dir)]
msg("范围外一致性: ", paste(sprintf("%s/%s rho=%.2f dir=%.0f%%", cors$ssp_lab, cors$hz_lab,
    cors$rho, 100 * cors$agree_dir), collapse = " | "))
pa2 <- ggplot(ag, aes(mech_ratio, ml_ratio)) +
  geom_hline(yintercept = 1, linetype = 3, colour = "grey65", linewidth = 0.3) +
  geom_vline(xintercept = 1, linetype = 3, colour = "grey65", linewidth = 0.3) +
  geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "grey55", linewidth = 0.35) +
  geom_point(colour = OI[["red"]], size = 1.2, alpha = 0.85) +
  geom_text(data = cors, aes(x = 0.2, y = 5.0, label = lab), hjust = 0, vjust = 1,
            size = 2.4, colour = "grey25", inherit.aes = FALSE) +
  facet_grid(ssp_lab ~ hz_lab) +
  scale_x_continuous(trans = "log2", breaks = c(0.5, 1, 4, 16, 64)) +
  scale_y_continuous(trans = "log2", breaks = c(0.25, 0.5, 1, 2, 4)) +
  labs(x = "Mechanistic hazard ratio vs 2024", y = "Machine-learning hazard ratio vs 2024",
       title = "Outside it they diverge completely",
       subtitle = "The mechanistic model projects increases in 176 of 186 province-scenario cells, the ML model in only 42") +
  theme_pub()

# (c) 外推距离: 未来协变量相对训练范围的位置
rng <- rbind(
  data.table(feature = "Accumulated warming", src = "observed 2002-2024",
             lo = quantile(d$clim_change_z, .01), hi = quantile(d$clim_change_z, .99)),
  data.table(feature = "Survey effort", src = "observed 2002-2024",
             lo = quantile(d$effort_z, .01), hi = quantile(d$effort_z, .99)),
  proj[, .(feature = "Accumulated warming", src = paste(toupper(sub("ssp", "SSP", ssp)), horizon),
           lo = quantile(clim_change_z, .01), hi = quantile(clim_change_z, .99)), by = .(ssp, horizon)][, -(1:2)],
  proj[, .(feature = "Survey effort", src = paste(toupper(sub("ssp", "SSP", ssp)), horizon),
           lo = quantile(effort_z, .01), hi = quantile(effort_z, .99)), by = .(ssp, horizon)][, -(1:2)])
rng[, src := factor(src, levels = rev(unique(src)))]
pa3 <- ggplot(rng, aes(y = src, colour = src == "observed 2002-2024")) +
  geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 2.2) +
  facet_wrap(~feature, nrow = 1, scales = "free_x") +
  scale_colour_manual(values = c(`TRUE` = OI[["green"]], `FALSE` = OI[["red"]]), guide = "none") +
  labs(x = "Standardised value (1st-99th percentile)", y = NULL,
       title = "Why: the scenarios leave the training range",
       subtitle = "Tree ensembles return boundary leaf values once covariates exit the observed support") +
  theme_pub() + theme(panel.grid.major.y = element_blank())

save_all((pa1 | pa3) / pa2 + plot_annotation(tag_levels = "a") + plot_layout(heights = c(0.85, 1)),
         "FigM4_mech_vs_ml_agreement_v2", 11.0, 7.6,
         src = rbindlist(list(cors[, .(panel = "b", group = paste(ssp_lab, hz_lab), rho, agree_dir)],
                              data.table(panel = "a", group = "observed 2002-2024",
                                         rho = r_in, agree_dir = NA_real_)), fill = TRUE))

msg("all v2 future figures written to ", FIG, " | DONE")
