# ============================================================
# Scientific question / 科学问题:
# 三族模型(机制离散风险 / 随机森林 / XGBoost)在三个行政尺度
# (省 / 市 / 县)上的"当前预测面"是否指向同样的地方?
# 一句话信息:三族在"哪里"上高度一致,分歧不在空间格局,而在外推行为
# (后者见 FigM4 与 FigR1)。
# Do the three model families point at the same places at all three
# administrative scales? The figure's one-sentence message: they agree
# on WHERE; they differ in extrapolation behaviour, not geography.
#
# Panels / 面板分工:
#   FigMS1  3 尺度(行) × 3 族(列) 地图矩阵 + 族间 Spearman ρ(overview+comparison)
#   FigMS2  a 省级 PR-AUC 四方案 × 三族;b 市县分配 rank 技能 × 三族(validation)
#
# Input / 输入:
#   data/admin/pred_prov_2024_all.csv                 (183)
#   data/admin/{prefecture,county}_surface_now.csv    (172, 机制面)
#   data/admin/{prefecture,county}_surface_{rf,xgb}.csv (184)
#   tables/tbl_rf_province_summary.csv, tbl_xgb_province_summary.csv
#   tables/tbl_alloc_skill.csv, tbl_rf_alloc_skill.csv, tbl_xgb_alloc_skill.csv
#   data/spatial/basemap_GS2019_1822/*.shp  (审图号 GS(2019)1822)
# Output / 输出: analysis_v2/figures_multiscale/FigMS1, FigMS2 (png/pdf/svg)
#
# Key assumptions / 关键假设:
#   - 市县面画的是 期望新纪录数 = 省级期望数(各族自己的) × 省内份额(各族自己的),
#     因此每列是一个自洽的"族内两段式",而不是混搭。
#   - 色标在行内共享、跨列可比;取 log10 以覆盖跨 4 个量级的期望数。
#   - 南海诸岛以插图完整呈现,九段线与国界来自审图号底图,未做任何几何修改。
# Main packages / 主要包: sf, ggplot2, patchwork, data.table, scico
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(sf); library(ggplot2); library(patchwork); library(scales)
})
sf_use_s2(FALSE)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_AD <- file.path(V2, "analysis_v2/data/admin")
D_TB <- file.path(V2, "analysis_v2/tables")
D_FG <- file.path(V2, "analysis_v2/figures_multiscale")
BM   <- file.path(V2, "data/spatial/basemap_GS2019_1822")
dir.create(D_FG, recursive = TRUE, showWarnings = FALSE)
AEA <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +datum=WGS84 +units=m"
msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

GREEN <- "#009E73"; BLUE <- "#0072B2"; RED <- "#D55E00"; GREY <- "grey55"
FAM <- c(mech = "离散风险模型", rf = "随机森林", xgb = "XGBoost")

theme_pub <- function(base = 9) {
  theme_classic(base_size = base, base_family = "sans") +
    theme(axis.text = element_text(colour = "grey15"),
          axis.title = element_text(colour = "grey5"),
          strip.background = element_blank(),
          strip.text = element_text(face = "bold", size = base, hjust = 0),
          plot.title = element_text(face = "bold", size = base + 1, hjust = 0),
          plot.subtitle = element_text(size = base - 0.8, colour = "grey30", hjust = 0),
          legend.key.size = unit(3.2, "mm"),
          legend.text = element_text(size = base - 1),
          legend.title = element_text(size = base - 1, face = "bold"))
}
theme_map <- function(base = 9) {
  theme_void(base_size = base, base_family = "sans") +
    theme(plot.title = element_text(face = "bold", size = base + 0.5, hjust = 0),
          plot.subtitle = element_text(size = base - 1, colour = "grey30", hjust = 0),
          legend.key.height = unit(3.0, "mm"), legend.key.width = unit(9, "mm"),
          legend.text = element_text(size = base - 1.5),
          legend.title = element_text(size = base - 1, face = "bold"),
          legend.position = "bottom")
}
save_fig <- function(p, name, w, h) {
  ggsave(file.path(D_FG, paste0(name, ".png")), p, width = w, height = h, dpi = 450, bg = "white")
  ggsave(file.path(D_FG, paste0(name, ".pdf")), p, width = w, height = h, device = grDevices::cairo_pdf)
  ggsave(file.path(D_FG, paste0(name, ".svg")), p, width = w, height = h, device = grDevices::svg)
  cat("wrote ", name, "\n", sep = "")
}

# ---------------- 几何 ----------------
msg("读取底图 / basemap")
prov_sf <- st_make_valid(st_transform(st_read(file.path(BM, "省（等积投影）.shp"), quiet = TRUE), AEA))
pref_sf <- st_make_valid(st_transform(st_read(file.path(BM, "市（等积投影）.shp"), quiet = TRUE), AEA))
cnty_sf <- st_make_valid(st_transform(st_read(file.path(BM, "县（等积投影）.shp"), quiet = TRUE), AEA))
nine    <- st_transform(st_read(file.path(BM, "九段线.shp"), quiet = TRUE), AEA)   # 底图自带 AEA
nation  <- st_make_valid(st_transform(st_read(file.path(BM, "国界.shp"), quiet = TRUE), AEA))
cnty_sf$unit_id <- as.integer(cnty_sf$PAC)
pref_sf$unit_id <- as.integer(pref_sf$市代码)

# EN→CN 省名映射(与建模数据一致) / province name lookup
ucty <- fread(file.path(D_AD, "units_county.csv"))
lk <- unique(ucty[, .(province, prov_cn)])

# ---------------- 数据:三族 × 三尺度 ----------------
prov_pred <- fread(file.path(D_AD, "pred_prov_2024_all.csv"))
prov_pred <- merge(prov_pred, lk, by = "province", all.x = TRUE)

unit_layer <- function(lv, fam) {
  f <- if (fam == "mech") sprintf("%s_surface_now.csv", lv) else sprintf("%s_surface_%s.csv", lv, fam)
  s <- fread(file.path(D_AD, f))[, .(unit_id, province, share)]
  s <- merge(s, prov_pred[, .(province, exp_n = get(fam))], by = "province")
  s[, val := share * exp_n]
  s
}

# ---------------- 南海插图(每格复用同一 grob) ----------------
scs_box <- st_bbox(c(xmin = 106, ymin = 2.5, xmax = 125, ymax = 24), crs = 4326) |>
  st_as_sfc() |> st_transform(AEA)
scs_plot <- ggplot() +
  geom_sf(data = st_intersection(st_geometry(nation), scs_box),
          fill = "grey92", colour = "grey35", linewidth = .18) +
  geom_sf(data = st_intersection(st_geometry(nine), scs_box), colour = "grey25", linewidth = .3) +
  coord_sf(expand = FALSE) +
  theme_void() + theme(panel.border = element_rect(fill = NA, colour = "grey40", linewidth = .3),
                       panel.background = element_rect(fill = "white", colour = NA))
scs_grob <- ggplotGrob(scs_plot)

bb <- st_bbox(prov_sf)
add_scs <- function(p) {
  w <- bb["xmax"] - bb["xmin"]; h <- bb["ymax"] - bb["ymin"]
  p + annotation_custom(scs_grob,
        xmin = bb["xmax"] - 0.16 * w, xmax = bb["xmax"] - 0.005 * w,
        ymin = bb["ymin"] - 0.02 * h, ymax = bb["ymin"] + 0.30 * h)
}

# ---------------- 单格地图 ----------------
map_cell <- function(sfobj, values, title, lims, show_legend, legend_name) {
  m <- merge(sfobj, values, by = "unit_id", all.x = FALSE)
  p <- ggplot() +
    geom_sf(data = prov_sf, fill = "grey96", colour = NA) +
    geom_sf(data = m, aes(fill = pmax(val, lims[1])), colour = NA) +
    geom_sf(data = prov_sf, fill = NA, colour = "white", linewidth = .12) +
    geom_sf(data = nation, fill = NA, colour = "grey35", linewidth = .18) +
    geom_sf(data = nine, colour = "grey25", linewidth = .3) +
    scale_fill_viridis_c(option = "mako", direction = -1, trans = "log10",
                         begin = 0.05, end = 0.95,      # 两端收一点,浅端不与省界白线混淆
                         limits = lims, oob = squish, name = legend_name,
                         labels = function(x) formatC(signif(x, 1), format = "fg")) +
    coord_sf(expand = FALSE) +
    labs(title = title) + theme_map() +
    theme(legend.position = if (show_legend) "bottom" else "none")
  add_scs(p)
}

prov_cell <- function(fam, title, lims, show_legend) {
  m <- merge(prov_sf, prov_pred[, .(prov_cn, val = get(fam))],
             by.x = "省", by.y = "prov_cn", all.x = FALSE)
  p <- ggplot() +
    geom_sf(data = prov_sf, fill = "grey96", colour = NA) +
    geom_sf(data = m, aes(fill = pmax(val, lims[1])), colour = "white", linewidth = .15) +
    geom_sf(data = nation, fill = NA, colour = "grey35", linewidth = .18) +
    geom_sf(data = nine, colour = "grey25", linewidth = .3) +
    scale_fill_viridis_c(option = "mako", direction = -1, trans = "log10",
                         begin = 0.05, end = 0.95,
                         limits = lims, oob = squish,
                         name = "期望新纪录数(2024,种·省求和)",
                         labels = function(x) formatC(signif(x, 1), format = "fg")) +
    coord_sf(expand = FALSE) +
    labs(title = title) + theme_map() +
    theme(legend.position = if (show_legend) "bottom" else "none")
  add_scs(p)
}

# ---------------- FigMS1:3 × 3 矩阵 ----------------
msg("FigMS1")
rows <- list()

# 行 1:省级
lims_p <- range(unlist(prov_pred[, .(mech, rf, xgb)])); lims_p[1] <- max(lims_p[1], 0.05)
rho_p <- c(cor(prov_pred$mech, prov_pred$rf, method = "spearman"),
           cor(prov_pred$mech, prov_pred$xgb, method = "spearman"),
           cor(prov_pred$rf, prov_pred$xgb, method = "spearman"))
r1 <- lapply(seq_along(FAM), function(i) {
  fam <- names(FAM)[i]
  prov_cell(fam, if (i == 1) paste0("a  省级:", FAM[i]) else FAM[i],
            lims_p, show_legend = (i == 2))
})

# 行 2 与行 3:市 / 县
lv_meta <- list(prefecture = list(sf = pref_sf, tag = "b", lab = "市级"),
                county = list(sf = cnty_sf, tag = "c", lab = "县级"))
rho_txt <- sprintf("省级 ρ:机制-RF %.2f · 机制-XGB %.2f · RF-XGB %.2f", rho_p[1], rho_p[2], rho_p[3])
rows_all <- list(r1)
for (lv in names(lv_meta)) {
  meta <- lv_meta[[lv]]
  layers <- lapply(names(FAM), function(f) unit_layer(lv, f))
  names(layers) <- names(FAM)
  allv <- unlist(lapply(layers, `[[`, "val"))
  lims <- quantile(allv[allv > 0], c(0.02, 0.999), na.rm = TRUE)
  wide <- Reduce(function(a, b) merge(a, b, by = "unit_id"),
                 lapply(names(FAM), function(f) setnames(layers[[f]][, .(unit_id, val)], "val", f)))
  rho <- c(cor(wide$mech, wide$rf, method = "spearman"),
           cor(wide$mech, wide$xgb, method = "spearman"),
           cor(wide$rf, wide$xgb, method = "spearman"))
  rho_txt <- paste0(rho_txt, sprintf("\n%s ρ:机制-RF %.2f · 机制-XGB %.2f · RF-XGB %.2f",
                                     meta$lab, rho[1], rho[2], rho[3]))
  rw <- lapply(seq_along(FAM), function(i) {
    fam <- names(FAM)[i]
    map_cell(meta$sf, layers[[fam]],
             if (i == 1) paste0(meta$tag, "  ", meta$lab, ":", FAM[i]) else FAM[i],
             lims, show_legend = (i == 2),
             legend_name = paste0("期望新纪录数(2024,", meta$lab, "落点)"))
  })
  rows_all[[length(rows_all) + 1]] <- rw
}

FigMS1 <- wrap_plots(c(rows_all[[1]], rows_all[[2]], rows_all[[3]]), ncol = 3, nrow = 3) +
  plot_annotation(
    title = "三族模型 × 三个尺度的当前预测面(2024)",
    subtitle = paste0("每列为族内自洽的两段式:省级期望数 × 省内分配份额;色标行内共享(log10)。",
                      "机制面 = 冻结主模型 + 条件 logit;RF / XGBoost 为类平衡变体。\n", rho_txt),
    caption = "底图:审图号 GS(2019)1822;南海诸岛见插图。Basemap GS(2019)1822; South China Sea islands shown in inset.",
    theme = theme(plot.title = element_text(face = "bold", size = 12, hjust = 0),
                  plot.subtitle = element_text(size = 8.6, colour = "grey30", hjust = 0),
                  plot.caption = element_text(size = 7, colour = "grey45", hjust = 0)))
save_fig(FigMS1, "FigMS1_multiscale_model_maps", 12.6, 13.4)

# ---------------- FigMS2:技能对比 ----------------
msg("FigMS2")
s_rf  <- fread(file.path(D_TB, "tbl_rf_province_summary.csv"))
s_xgb <- fread(file.path(D_TB, "tbl_xgb_province_summary.csv"))
# 随机折用条件预测(内插时 BLUP 可用);其余方案新省/新年无 BLUP,用边际。
pick <- rbind(
  s_rf[model == "离散风险模型(条件)" & scheme == "random",
       .(scheme, model = "离散风险模型", prauc, prauc_sd)],
  s_rf[model == "离散风险模型(边际)" & scheme != "random",
       .(scheme, model = "离散风险模型", prauc, prauc_sd)],
  s_rf[model == "随机森林(类平衡)",   .(scheme, model = "随机森林", prauc, prauc_sd)],
  s_xgb[model == "XGBoost(类平衡)",   .(scheme, model = "XGBoost", prauc, prauc_sd)])
SCH <- c(random = "随机 5 折", leave_species = "留物种 5 折",
         leave_province = "留省 5 折", temporal = "时间前推\n2019–2024")
pick[, sch := factor(SCH[scheme], levels = SCH)]
pick[, model := factor(model, levels = c("离散风险模型", "随机森林", "XGBoost"))]
COL3 <- setNames(c(BLUE, RED, "#B45309"), levels(pick$model))

a <- ggplot(pick, aes(sch, prauc, fill = model)) +
  geom_col(position = position_dodge(.78), width = .7) +
  geom_errorbar(aes(ymin = pmax(0, prauc - prauc_sd), ymax = prauc + prauc_sd),
                position = position_dodge(.78), width = .18, linewidth = .3, colour = "grey30") +
  geom_hline(yintercept = 0.00369, linetype = 3, colour = "grey35") +
  annotate("text", x = 4.42, y = 0.0046, label = "事件率 0.369%", size = 2.4, colour = "grey30", hjust = 1) +
  scale_fill_manual(values = COL3, name = NULL) +
  scale_y_continuous(expand = expansion(c(0, .06))) +
  labs(x = NULL, y = "PR-AUC",
       title = "a  省级:内插时树模型领先,外推时机制模型追平或反超",
       subtitle = "机制模型:随机折取条件预测(BLUP 可用),其余方案取边际;RF 与 XGBoost 取类平衡变体;误差线为折间 SD") +
  theme_pub() + theme(legend.position = "top", legend.margin = margin(b = -4))

s_cl <- fread(file.path(D_TB, "tbl_alloc_skill.csv"))
s_ra <- fread(file.path(D_TB, "tbl_rf_alloc_skill.csv"))
s_xa <- fread(file.path(D_TB, "tbl_xgb_alloc_skill.csv"))
rp <- fread(file.path(D_TB, "tbl_rf_alloc_province.csv"))
lp_rf <- rp[model %in% c("条件 logit (M3)", "随机森林(类平衡)"),
            .(split = "留一省", rank_pct = mean(rank_pct)), by = .(level, model)]
# tbl_alloc_skill 的 split 写作"时间外推 2019-2024"(连字符),
# 与 RF/XGB 表的"时间前推 2019–2024"(en-dash)不同——不统一会掉进 NA 面板。
s_cl[, split := fifelse(grepl("^时间", split), "时间前推 2019–2024", split)]
alloc <- rbind(
  s_cl[method == "M3 分配模型", .(level, split, model = "离散风险模型", rank_pct)],
  s_ra[model == "随机森林(类平衡)", .(level, split, model = "随机森林", rank_pct)],
  s_xa[model == "XGBoost(类平衡)" & split == "时间前推 2019–2024",
       .(level, split, model = "XGBoost", rank_pct)],
  lp_rf[model == "条件 logit (M3)", .(level, split, model = "离散风险模型", rank_pct)],
  lp_rf[model == "随机森林(类平衡)", .(level, split, model = "随机森林", rank_pct)],
  s_xa[split == "留一省", .(level, split, model = "XGBoost", rank_pct)])
LV <- c(prefecture = "市级", county = "县级")
alloc[, `:=`(lv = factor(LV[level], levels = LV),
             model = factor(model, levels = names(COL3)),
             split = factor(split, levels = c("时间前推 2019–2024", "留一省")))]

b <- ggplot(alloc, aes(lv, rank_pct, fill = model)) +
  geom_col(position = position_dodge(.78), width = .7) +
  geom_hline(yintercept = 0.5, linetype = 3, colour = "grey40") +
  annotate("text", x = 0.55, y = 0.525, label = "随机 = 0.5", size = 2.4, colour = "grey35", hjust = 0) +
  geom_text(aes(label = sprintf("%.2f", rank_pct)), position = position_dodge(.78),
            vjust = -0.4, size = 2.3, colour = "grey20") +
  facet_wrap(~ split) +
  scale_fill_manual(values = COL3, guide = "none") +
  scale_y_continuous(limits = c(0, 0.62), expand = expansion(c(0, .04))) +
  labs(x = NULL, y = "被选中单元的预测排名分位(越小越好)",
       title = "b  市县分配:时间前推三族打平;换到新省份,机制模型优势最大",
       subtitle = "同一批 2019–2024 事件与同一特征集;留一省 = 把整省移出训练集后预测该省") +
  theme_pub()

FigMS2 <- a / b + plot_layout(heights = c(1, 1.05))
save_fig(FigMS2, "FigMS2_multiscale_model_skill", 8.8, 7.6)
msg("完成 / done")
