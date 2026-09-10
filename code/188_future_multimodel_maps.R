# ============================================================
# Scientific question / 科学问题:
# 把未来预测的三个维度同时展开:模型族(机制 / 随机森林 / XGBoost)×
# 尺度(省 / 市 / 县)× 情景(SSP2-4.5、SSP5-8.5 × 努力停滞、努力延续 × 2030、2050)。
# 一句话信息:三族对"哪里"仍高度一致,但对"情景"的响应截然不同 ——
# 机制模型随努力情景大幅上升,两个树模型几乎不动,因为未来协变量
# (yr、effort_z)已越出训练范围,树集成返回边界叶值而饱和。
# Expand the future projection along all three axes at once. The families
# agree on WHERE but not on HOW MUCH scenarios matter: the mechanistic model
# responds to the effort scenario while both tree ensembles saturate, because
# the future covariates leave the training support.
#
# Panels / 面板分工:
#   FigMS4  a 省级 3 族(行) × 4 情景(列) @2050 地图矩阵   comparison
#           b 全国期望数 × 8 情景 × 3 族                    summary/mechanism
#   FigMS5  3 尺度(行) × 3 族(列) @焦点情景(2050 SSP2-4.5 努力延续)  multi-scale
#
# Input / 输入:
#   analysis_v2/data/model_v2_thr50.parquet, fit_R3.rds
#   analysis_species_specific/tables/tbl_F_cmip6_delta.csv
#   analysis_v2/data/admin/{prefecture,county}_surface_{now,rf,xgb}.csv
#   data/spatial/basemap_GS2019_1822/*.shp   (审图号 GS(2019)1822)
# Output / 输出:
#   analysis_v2/tables/tbl_future_multimodel_grid.csv
#   analysis_v2/figures_multiscale/FigMS4_future_scenarios_by_model (png/pdf)
#   analysis_v2/figures_multiscale/FigMS5_future_multiscale_by_model (png/pdf)
#
# Key assumptions / 关键假设:
#   - 三族在 2024 基期上各自校准一次(令全国合计与机制模型一致),此后
#     情景响应完全自由 —— 这样"绝对量级可比、情景斜率是各族自己的"。
#     Calibrate each family once at the 2024 baseline, then let scenarios move
#     freely: levels are comparable, scenario slopes are each family's own.
#   - 报告完整度沿用 2024 水平(与脚本 187 同口径),故预测量是"被记录的
#     新纪录数",而非潜在生成风险;这与图例文字一致。
#   - 市县为"份额冻结"假设:省内分配份额取各族自己的 2024 面,
#     只有省级期望数随情景变化 —— 显式声明的简化。
#   - 透明度 = 该省落在训练协变量 1–99 百分位内的物种行比例(三族共用,
#     因为支撑域是数据范围的属性,不是模型的属性)。
# Main packages / 主要包: glmmTMB, ranger, xgboost, sf, ggplot2, patchwork
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(glmmTMB); library(ranger)
  library(xgboost); library(sf); library(ggplot2); library(patchwork); library(scales)
})
sf_use_s2(FALSE)
set.seed(20260910)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
SS   <- file.path(V2, "analysis_species_specific")
D_AD <- file.path(V2, "analysis_v2/data/admin")
D_TB <- file.path(V2, "analysis_v2/tables")
D_FG <- file.path(V2, "analysis_v2/figures_multiscale")
BM   <- file.path(V2, "data/spatial/basemap_GS2019_1822")
AEA  <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +datum=WGS84 +units=m"
msg  <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

EFF_SCEN <- c(`努力停滞` = 0, `努力延续` = 0.6)      # SD / 十年
SSP_LAB  <- c(ssp245 = "SSP2-4.5", ssp585 = "SSP5-8.5")
FAM      <- c(mech = "离散风险模型", rf = "随机森林", xgb = "XGBoost")
BLUE <- "#0072B2"; RED <- "#D55E00"; AMBER <- "#B45309"

# ---------------- 数据与三族终拟合 ----------------
d <- as.data.table(read_parquet(file.path(V2, "analysis_v2/data/model_v2_thr50.parquet")))[usable_main == TRUE]
CC_MU <- mean(d$clim_change); CC_SD <- sd(d$clim_change)
d[, `:=`(clim_change_z = (clim_change - CC_MU) / CC_SD,
         clim_var_z = as.numeric(scale(clim_var)), effort_z = eff_visits_gap_z,
         yr = year - 2002, species_f = factor(species), province_f = factor(province),
         mig_f = factor(mig_grp), ev = factor(event, levels = c(0, 1)))]
msg("数据 ", nrow(d), " 行,", sum(d$event), " 事件;基期 ", max(d$year))

FE  <- c("clim_change_z", "effort_z", "clim_var_z", "log_completeness")
FE2 <- c(FE, "yr", "province_f", "mig_f")
mm  <- function(dd, fs) Matrix::sparse.model.matrix(
  as.formula(paste("~", paste(fs, collapse = " + "), "- 1")), data = dd)

fit_mech <- readRDS(file.path(V2, "analysis_v2/data", "fit_R3.rds"))
fit_rf <- ranger(x = d[, ..FE2], y = d$ev, probability = TRUE, num.trees = 800,
                 min.node.size = 5, sample.fraction = c(sum(d$event), sum(d$event)) / nrow(d),
                 replace = TRUE, num.threads = 0, seed = 1)
Xall <- mm(d, FE2)
fit_xgb <- xgb.train(data = xgb.DMatrix(Xall, label = d$event), nrounds = 300, verbose = 0,
                     params = list(objective = "binary:logistic", eval_metric = "aucpr",
                                   eta = 0.05, max_depth = 5, subsample = 0.8,
                                   colsample_bytree = 0.8, min_child_weight = 5,
                                   scale_pos_weight = sum(d$event == 0) / sum(d$event), nthread = 6))
msg("三族终拟合完成")

SUP  <- list(cc = quantile(d$clim_change_z, c(.01, .99)), ef = quantile(d$effort_z, c(.01, .99)))
base <- d[year == max(d$year)]

#' 对给定协变量表给出三族的原始预测 / raw predictions from all three families
predict_all <- function(b) {
  b <- copy(b)
  b[, prov_year := interaction(province, "F", drop = TRUE)]   # 未来层,取总体均值
  Xb <- mm(b, FE2)
  miss <- setdiff(colnames(Xall), colnames(Xb))
  if (length(miss)) Xb <- cbind(Xb, Matrix::Matrix(0, nrow(Xb), length(miss),
                                dimnames = list(NULL, miss), sparse = TRUE))
  Xb <- Xb[, colnames(Xall), drop = FALSE]
  list(mech = predict(fit_mech, newdata = b, type = "response", allow.new.levels = TRUE),
       rf   = predict(fit_rf, data = b[, ..FE2])$predictions[, "1"],
       xgb  = predict(fit_xgb, xgb.DMatrix(Xb)))
}

# 2024 基期:求各族校准因子(令全国合计与机制模型一致)
p0 <- predict_all(base)
CAL <- sapply(names(FAM), function(f) sum(p0$mech) / sum(p0[[f]]))
msg("校准因子 ", paste(sprintf("%s=%.3f", names(CAL), CAL), collapse = " | "))

# ---------------- 情景网格 × 三族 ----------------
cm6 <- fread(file.path(SS, "tables", "tbl_F_cmip6_delta.csv"))
dp  <- cm6[unit == "province", .(province = name, ssp, horizon, d_prov = delta)]
ds  <- cm6[unit == "species",  .(species  = name, ssp, horizon, d_sp   = delta)]

grid <- CJ(ssp = c("ssp245", "ssp585"), eff = names(EFF_SCEN), hz = c(2030L, 2050L))
proj <- rbindlist(lapply(seq_len(nrow(grid)), function(i) {
  g <- grid[i]; b <- copy(base)
  b <- merge(b, dp[ssp == g$ssp & horizon == g$hz, .(province, d_prov)], by = "province", all.x = TRUE)
  b <- merge(b, ds[ssp == g$ssp & horizon == g$hz, .(species, d_sp)], by = "species", all.x = TRUE)
  b[is.na(d_prov), d_prov := 0]; b[is.na(d_sp), d_sp := 0]
  b[, clim_change_z := (clim_change + (d_prov - d_sp) - CC_MU) / CC_SD]
  b[, effort_z := effort_z + EFF_SCEN[[g$eff]] * (g$hz - max(d$year)) / 10]
  b[, yr := g$hz - 2002L]
  b[, in_support := clim_change_z %between% SUP$cc & effort_z %between% SUP$ef]
  pp <- predict_all(b)
  rbindlist(lapply(names(FAM), function(f)
    data.table(fam = f, ssp = g$ssp, eff = g$eff, horizon = g$hz,
               province = b$province, p = pp[[f]] * CAL[[f]], in_support = b$in_support)))
}))

prov_grid <- proj[, .(exp_n = sum(p), pct_sup = mean(in_support)),
                  by = .(fam, ssp, eff, horizon, province)]
fwrite(prov_grid, file.path(D_TB, "tbl_future_multimodel_grid.csv"))
nat <- proj[, .(total = sum(p), pct_sup = round(100 * mean(in_support))), by = .(fam, ssp, eff, horizon)]
cat("\n== 全国预测新纪录数 / 年 ==\n")
print(dcast(nat, ssp + eff + horizon ~ fam, value.var = "total")[, lapply(.SD, function(x)
  if (is.numeric(x)) round(x, 1) else x)])
cat("\n基期 2024 全国合计(三族校准后一致):", round(sum(p0$mech), 1), "\n")

# ---------------- 几何与作图工具 ----------------
prov_sf <- st_make_valid(st_transform(st_read(file.path(BM, "省（等积投影）.shp"), quiet = TRUE), AEA))
pref_sf <- st_make_valid(st_transform(st_read(file.path(BM, "市（等积投影）.shp"), quiet = TRUE), AEA))
cnty_sf <- st_make_valid(st_transform(st_read(file.path(BM, "县（等积投影）.shp"), quiet = TRUE), AEA))
nine    <- st_transform(st_read(file.path(BM, "九段线.shp"), quiet = TRUE), AEA)
nation  <- st_make_valid(st_transform(st_read(file.path(BM, "国界.shp"), quiet = TRUE), AEA))
cnty_sf$unit_id <- as.integer(cnty_sf$PAC); pref_sf$unit_id <- as.integer(pref_sf$市代码)
lk <- unique(fread(file.path(D_AD, "units_county.csv"))[, .(province, prov_cn)])
prov_grid <- merge(prov_grid, lk, by = "province", all.x = TRUE)

theme_map <- function(base = 9) {
  theme_void(base_size = base, base_family = "sans") +
    theme(plot.title = element_text(face = "bold", size = base + 0.5, hjust = 0),
          plot.subtitle = element_text(size = base - 1.2, colour = "grey30", hjust = 0),
          legend.key.height = unit(3.0, "mm"), legend.key.width = unit(9, "mm"),
          legend.text = element_text(size = base - 1.5),
          legend.title = element_text(size = base - 1, face = "bold"),
          legend.position = "bottom")
}
theme_pub <- function(base = 9) {
  theme_classic(base_size = base, base_family = "sans") +
    theme(axis.text = element_text(colour = "grey15"), axis.title = element_text(colour = "grey5"),
          strip.background = element_blank(),
          strip.text = element_text(face = "bold", size = base, hjust = 0),
          plot.title = element_text(face = "bold", size = base + 1, hjust = 0),
          plot.subtitle = element_text(size = base - 0.8, colour = "grey30", hjust = 0),
          legend.key.size = unit(3.2, "mm"), legend.text = element_text(size = base - 1),
          legend.title = element_text(size = base - 1, face = "bold"))
}
LBL <- function(x) formatC(signif(x, 1), format = "fg")

#' 省级单格 / one provincial panel
cell_prov <- function(f_, sp_, ef_, hz_, title, sub, lims, show_legend) {
  gd <- prov_grid[fam == f_ & ssp == sp_ & eff == ef_ & horizon == hz_]
  m  <- merge(prov_sf, gd[, .(prov_cn, exp_n, pct_sup)], by.x = "省", by.y = "prov_cn", all.x = FALSE)
  ggplot() +
    geom_sf(data = prov_sf, fill = "grey96", colour = NA) +
    geom_sf(data = m, aes(fill = pmax(pmin(exp_n, lims[2]), lims[1]), alpha = pct_sup),
            colour = "white", linewidth = .15) +
    geom_sf(data = nation, fill = NA, colour = "grey35", linewidth = .18) +
    geom_sf(data = nine, colour = "grey25", linewidth = .3) +
    scale_fill_distiller(palette = "RdYlBu", direction = -1, trans = "log10", limits = lims,
                         oob = squish, name = "预测新纪录数 / 年", labels = LBL) +
    scale_alpha_continuous(range = c(0.30, 1), limits = c(0, 1), guide = "none") +
    coord_sf(expand = FALSE) + labs(title = title, subtitle = sub) +
    theme_map() + theme(legend.position = if (show_legend) "bottom" else "none")
}

#' 单元级单格(份额冻结) / one unit-level panel under frozen shares
SHARE_FILE <- c(mech = "now", rf = "rf", xgb = "xgb")
unit_layer <- function(lv, f_, sp_, ef_, hz_) {
  s <- fread(file.path(D_AD, sprintf("%s_surface_%s.csv", lv, SHARE_FILE[[f_]])))[, .(unit_id, province, share)]
  merge(s, prov_grid[fam == f_ & ssp == sp_ & eff == ef_ & horizon == hz_,
                     .(province, exp_n, pct_sup)], by = "province")[, val := share * exp_n][]
}
cell_unit <- function(sfobj, lay, title, lims, show_legend, legend_name) {
  m <- merge(sfobj, lay, by = "unit_id", all.x = FALSE)
  ggplot() +
    geom_sf(data = prov_sf, fill = "grey96", colour = NA) +
    geom_sf(data = m, aes(fill = pmax(pmin(val, lims[2]), lims[1]), alpha = pct_sup), colour = NA) +
    geom_sf(data = prov_sf, fill = NA, colour = "white", linewidth = .1) +
    geom_sf(data = nation, fill = NA, colour = "grey35", linewidth = .18) +
    geom_sf(data = nine, colour = "grey25", linewidth = .3) +
    scale_fill_distiller(palette = "RdYlBu", direction = -1, trans = "log10", limits = lims,
                         oob = squish, name = legend_name, labels = LBL) +
    scale_alpha_continuous(range = c(0.30, 1), limits = c(0, 1), guide = "none") +
    coord_sf(expand = FALSE) + labs(title = title) +
    theme_map() + theme(legend.position = if (show_legend) "bottom" else "none")
}

# ================= FigMS4:3 族 × 4 情景 @2050 =================
msg("FigMS4")
SC <- CJ(ssp = c("ssp245", "ssp585"), eff = names(EFF_SCEN), sorted = FALSE)
lims4 <- quantile(prov_grid[horizon == 2050]$exp_n, c(0.02, 0.99))
cells <- list()
for (fi in seq_along(FAM)) {
  f_ <- names(FAM)[fi]
  for (si in seq_len(nrow(SC))) {
    n0 <- nat[fam == f_ & ssp == SC$ssp[si] & eff == SC$eff[si] & horizon == 2050L]
    # 行首格的标题换行:模型族占一行,情景占下一行,否则会横向压到第二列
    ttl <- if (si == 1) paste0(letters[fi], "  ", FAM[fi], "\n", SSP_LAB[SC$ssp[si]], " · ", SC$eff[si])
           else paste0("\n", SSP_LAB[SC$ssp[si]], " · ", SC$eff[si])
    cells[[length(cells) + 1]] <- cell_prov(
      f_, SC$ssp[si], SC$eff[si], 2050L, ttl,
      sprintf("全国 %.1f 条/年 · 支撑域内 %d%%", n0$total, n0$pct_sup),
      lims4, show_legend = (fi == 3 && si == 2))
  }
}
maps4 <- wrap_plots(cells, nrow = 3, ncol = 4)

nat[, `:=`(famf = factor(FAM[fam], levels = FAM),
           scen = factor(paste0(SSP_LAB[ssp], "\n", eff),
                         levels = paste0(SSP_LAB[SC$ssp], "\n", SC$eff)),
           hzf = factor(paste0(horizon, " 年"), levels = c("2030 年", "2050 年")))]
base_tot <- sum(p0$mech)
d_sum <- ggplot(nat, aes(scen, total, colour = famf, group = famf)) +
  geom_hline(yintercept = base_tot, linetype = 3, colour = "grey40") +
  annotate("text", x = -Inf, y = base_tot * 1.06, label = sprintf("2024 基期 %.1f", base_tot),
           size = 2.5, colour = "grey35", hjust = -0.08) +
  geom_line(linewidth = .6) + geom_point(size = 2.1) +
  facet_wrap(~ hzf) +
  scale_colour_manual(values = setNames(c(BLUE, RED, AMBER), FAM), name = NULL) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(c(0, .10))) +
  labs(x = NULL, y = "全国预测新纪录数 / 年",
       title = "d  情景响应:只有机制模型随努力情景上升;随机森林持平,XGBoost 反向下滑",
       subtitle = "三族已在 2024 基期校准到同一量级(22.4 条/年),此后情景斜率是各族自己的。未来的 yr 与 effort_z 越出训练范围后,\n树集成返回边界叶值:随机森林锁死在基期水平,XGBoost 的边界值甚至给出反向趋势 —— 外推方向不可审查") +
  theme_pub() + theme(legend.position = "top", legend.margin = margin(b = -4))

FigMS4 <- maps4 / d_sum + plot_layout(heights = c(3, 1.15)) +
  plot_annotation(
    title = "未来情景预测(2050):模型族 × 气候情景 × 调查努力情景",
    subtitle = paste0("行=模型族,列=情景;色标全图共享(log10);透明度=该省落在训练协变量支撑域内的比例。",
                      "报告完整度沿用 2024 水平,故预测量为「被记录的新纪录数」。"),
    caption = "底图:审图号 GS(2019)1822(主图全幅含南海诸岛与九段线)。",
    theme = theme(plot.title = element_text(face = "bold", size = 12, hjust = 0),
                  plot.subtitle = element_text(size = 8.6, colour = "grey30", hjust = 0),
                  plot.caption = element_text(size = 7, colour = "grey45", hjust = 0)))
ggsave(file.path(D_FG, "FigMS4_future_scenarios_by_model.png"), FigMS4,
       width = 14.4, height = 13.6, dpi = 400, bg = "white")
ggsave(file.path(D_FG, "FigMS4_future_scenarios_by_model.pdf"), FigMS4,
       width = 14.4, height = 13.6, device = grDevices::cairo_pdf)
cat("wrote FigMS4\n")

# ================= FigMS5:3 尺度 × 3 族 @焦点情景 =================
msg("FigMS5")
FS <- list(ssp = "ssp245", eff = "努力延续", hz = 2050L)
rows5 <- list()
r1 <- lapply(seq_along(FAM), function(fi) {
  n0 <- nat[fam == names(FAM)[fi] & ssp == FS$ssp & eff == FS$eff & horizon == FS$hz]
  cell_prov(names(FAM)[fi], FS$ssp, FS$eff, FS$hz,
            if (fi == 1) paste0("a  省级:", FAM[fi]) else FAM[fi],
            sprintf("全国 %.1f 条/年 · 支撑域内 %d%%", n0$total, n0$pct_sup),
            lims4, show_legend = (fi == 2))
})
rows5[[1]] <- r1
for (li in 1:2) {
  lv  <- c("prefecture", "county")[li]
  meta <- list(tag = c("b", "c")[li], lab = c("市级", "县级")[li], sf = list(pref_sf, cnty_sf)[[li]])
  lays <- lapply(names(FAM), function(f_) unit_layer(lv, f_, FS$ssp, FS$eff, FS$hz))
  names(lays) <- names(FAM)
  allv <- unlist(lapply(lays, `[[`, "val"))
  lims <- quantile(allv[allv > 0], c(0.02, 0.999))
  rows5[[li + 1]] <- lapply(seq_along(FAM), function(fi)
    cell_unit(meta$sf, lays[[fi]],
              if (fi == 1) paste0(meta$tag, "  ", meta$lab, ":", FAM[fi]) else FAM[fi],
              lims, show_legend = (fi == 2),
              legend_name = paste0("预测新纪录数(", meta$lab, ",2050)")))
}
FigMS5 <- wrap_plots(c(rows5[[1]], rows5[[2]], rows5[[3]]), nrow = 3, ncol = 3) +
  plot_annotation(
    title = sprintf("未来情景下的多尺度预测面:%s · %s · %d 年", SSP_LAB[FS$ssp], FS$eff, FS$hz),
    subtitle = paste0("行=尺度,列=模型族;每列为族内自洽的两段式(该族的省级期望 × 该族的省内分配份额),",
                      "市县为份额冻结假设(份额取各族 2024 面)。色标行内共享(log10);透明度=支撑域内比例。"),
    caption = "底图:审图号 GS(2019)1822。",
    theme = theme(plot.title = element_text(face = "bold", size = 12, hjust = 0),
                  plot.subtitle = element_text(size = 8.6, colour = "grey30", hjust = 0),
                  plot.caption = element_text(size = 7, colour = "grey45", hjust = 0)))
ggsave(file.path(D_FG, "FigMS5_future_multiscale_by_model.png"), FigMS5,
       width = 12.6, height = 13.4, dpi = 400, bg = "white")
cat("wrote FigMS5\n")
msg("完成 / done")
