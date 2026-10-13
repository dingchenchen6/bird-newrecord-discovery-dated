# ============================================================
# Scientific question / 科学问题:
# 把「省级新纪录预测能否降尺度到市县」的答案做成两张图:
#   FigC1 分配模型的系数、模型阶梯与样本外技能(能不能做)
#   FigC2 县级落点概率面与外推边界(做出来长什么样、能推到什么时候)
#
# Input / 输入: analysis_v2/tables/tbl_alloc_*.csv,
#               analysis_v2/data/admin/{county,prefecture}_surface_now.csv
# Output / 输出: analysis_v2/figures_admin/FigC1-FigC2 (png/pdf/svg)
# Key assumptions / 关键假设:
#   - 全部数值直接读自分析脚本产出的表。底图为审图号 GS(2019)1822。
# Main packages / 主要包: ggplot2, patchwork, data.table, sf
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(patchwork); library(sf); library(scales)
})
sf_use_s2(FALSE)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_AD <- file.path(V2, "analysis_v2/data/admin")
D_TB <- file.path(V2, "analysis_v2/tables")
D_FG <- file.path(V2, "analysis_v2/figures_admin")
BM   <- file.path(V2, "data/spatial/basemap_GS2019_1822")
dir.create(D_FG, recursive = TRUE, showWarnings = FALSE)
AEA <- "+proj=aea +lat_1=25 +lat_2=47 +lat_0=0 +lon_0=105 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
GREEN <- "#009E73"; BLUE <- "#0072B2"; RED <- "#D55E00"; GREY <- "grey55"

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
save_fig <- function(p, name, w, h) {
  ggsave(file.path(D_FG, paste0(name, ".png")), p, width = w, height = h, dpi = 450, bg = "white")
  ggsave(file.path(D_FG, paste0(name, ".pdf")), p, width = w, height = h, device = grDevices::cairo_pdf)
  ggsave(file.path(D_FG, paste0(name, ".svg")), p, width = w, height = h, device = grDevices::svg)
  cat("wrote ", name, "\n", sep = "")
}

lad <- fread(file.path(D_TB, "tbl_alloc_ladder.csv"))
skl <- fread(file.path(D_TB, "tbl_alloc_skill.csv"))
skp <- fread(file.path(D_TB, "tbl_alloc_skill_province.csv"))

LV <- c(prefecture = "市级(中位 13 个备择)", county = "县级(中位 103 个备择)")

# ---------------- FigC1 ----------------
TERM <- c(log_dist_z = "到该物种分布区距离\n(每 1 SD, log km)",
          in_range   = "质心已在分布区内",
          log_eff_z  = "累计观鸟努力\n(每 1 SD, log)",
          log_area_z = "单元面积\n(每 1 SD, log)",
          bio1_z     = "年均温 (每 1 SD)",
          bio12_z    = "年降水 (每 1 SD)",
          frac_pa_z  = "保护地覆盖 (每 1 SD)",
          elev_z     = "海拔 (每 1 SD)")
m3 <- lad[model == "M3 +环境" & term %in% names(TERM)]
m3[, lbl := factor(TERM[term], levels = rev(TERM))]
m3[, lv := LV[level]]
a1 <- ggplot(m3, aes(OR, lbl, colour = lv)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey60") +
  geom_pointrange(aes(xmin = lo, xmax = hi), position = position_dodge(.5), size = .32) +
  scale_colour_manual(values = c(BLUE, GREEN), name = NULL) +
  scale_x_continuous(trans = "log10", breaks = c(0.03, 0.1, 0.3, 1, 3)) +
  labs(x = "条件优势比 (95% CI,对数轴)", y = NULL,
       title = "a  省内分配模型:什么决定新纪录落在哪个单元",
       subtitle = "离物种已知分布区越近、观鸟越多、面积越大的单元越可能承接") +
  theme_pub() + theme(legend.position = c(.24, .16))

conc <- unique(lad[, .(level, model, concordance)])
conc[, lv := LV[level]]
conc[, model := factor(model, levels = c("M0 面积", "M1 +累计观鸟努力",
                                         "M2 +到分布区距离", "M3 +环境"))]
a2 <- ggplot(conc, aes(model, concordance, colour = lv, group = lv)) +
  geom_line(linewidth = .6) + geom_point(size = 2) +
  geom_text(aes(label = sprintf("%.3f", concordance)), vjust = -1, size = 2.5, show.legend = FALSE) +
  scale_colour_manual(values = c(BLUE, GREEN), name = NULL) +
  scale_y_continuous(limits = c(0.6, 0.82)) +
  labs(x = NULL, y = "一致性指数 (concordance)",
       title = "b  加入分布区距离带来的增量最大",
       subtitle = "环境变量在县级还有增量,在市级已经饱和") +
  theme_pub() + theme(legend.position = c(.72, .18),
                      axis.text.x = element_text(angle = 12, hjust = 1))

skl[, lv := LV[level]]
skl[, method := factor(method, levels = c("M3 分配模型", "基线:仅到分布区距离",
                                          "基线:累计观鸟努力", "基线:单元面积", "基线:随机"))]
a3 <- ggplot(skl, aes(method, rank_pct, fill = method)) +
  geom_col(width = .62) +
  geom_hline(yintercept = 0.5, linetype = 3, colour = "grey40") +
  geom_text(aes(label = sprintf("%.3f", rank_pct)), vjust = -0.4, size = 2.5) +
  facet_wrap(~ lv) +
  scale_fill_manual(values = c(RED, BLUE, GREEN, GREY, "grey80"), guide = "none") +
  scale_y_continuous(limits = c(0, 0.62), expand = expansion(c(0, .04))) +
  labs(x = NULL, y = "被选中单元的预测排名分位(越小越好)",
       title = "c  样本外技能:2002-2018 拟合,2019-2024 预测",
       subtitle = "虚线 0.5 为随机水平;两级都显著优于全部基线") +
  theme_pub() + theme(axis.text.x = element_text(angle = 22, hjust = 1))

hit <- melt(skl[, .(lv, method, top1, top10pct)], id.vars = c("lv", "method"),
            variable.name = "k", value.name = "v")
hit[, k := factor(fifelse(k == "top1", "命中第 1 名", "命中前 10%"),
                  levels = c("命中第 1 名", "命中前 10%"))]
a4 <- ggplot(hit, aes(method, v, fill = k)) +
  geom_col(position = position_dodge(.72), width = .64) +
  facet_wrap(~ lv) +
  scale_fill_manual(values = c(RED, BLUE), name = NULL) +
  scale_y_continuous(labels = percent_format(1)) +
  labs(x = NULL, y = "命中率",
       title = "d  县级 top-1 命中率约为随机期望的 17 倍",
       subtitle = "县级备择数中位 103,随机 top-1 期望约 1%,模型 16.1%;前 10% 命中 45.4%(随机期望 10%)") +
  theme_pub() + theme(axis.text.x = element_text(angle = 22, hjust = 1),
                      legend.position = "top", legend.margin = margin(b = -4))

FigC1 <- (a1 | a2) / (a3 | a4)
save_fig(FigC1, "FigC1_allocation_skill", 10.4, 7.4)

# ---------------- FigC2 ----------------
cs <- fread(file.path(D_AD, "county_surface_now.csv"))
cnty <- st_make_valid(st_transform(st_read(file.path(BM, "县（等积投影）.shp"), quiet = TRUE), AEA))
cnty$unit_id <- as.character(cnty$PAC)
cnty <- cnty[!duplicated(cnty$unit_id), ]
prov_sf <- st_transform(st_read(file.path(BM, "省（等积投影）.shp"), quiet = TRUE), AEA)
mp <- merge(cnty[, "unit_id"], cs[, .(unit_id, share, rank_in_prov, n_unit_prov, province)],
            by = "unit_id", all.x = TRUE)
mp$rel <- mp$share * mp$n_unit_prov          # 相对省内均匀分配的倍数 / relative to uniform

b1 <- ggplot() +
  geom_sf(data = mp, aes(fill = pmin(rel, 12)), colour = NA) +
  geom_sf(data = prov_sf, fill = NA, colour = "grey30", linewidth = .15) +
  scale_fill_viridis_c(option = "magma", direction = -1, na.value = "grey93",
                       name = "相对省内\n均匀分配的倍数", limits = c(0, 12),
                       breaks = c(0, 3, 6, 9, 12), labels = c("0", "3", "6", "9", "≥12")) +
  labs(title = "a  下一条省级新纪录落在各县的相对概率",
       subtitle = "对该省仍在风险集内的候选物种取平均;底图 GS(2019)1822") +
  theme_pub() + theme(axis.line = element_blank(), axis.text = element_blank(),
                      axis.ticks = element_blank(), legend.position = c(.14, .28))

top <- head(cs[order(-share)], 18)
top[, lbl := factor(paste0(unit_nm, "(", prov_cn, ")"), levels = rev(paste0(unit_nm, "(", prov_cn, ")")))]
b2 <- ggplot(top, aes(share, lbl)) +
  geom_col(fill = BLUE, width = .68) +
  geom_text(aes(label = sprintf("%.1f%%  ·  该省 %d 个县", 100 * share, n_unit_prov)),
            hjust = -0.05, size = 2.5) +
  scale_x_continuous(labels = percent_format(1), expand = expansion(c(0, .42))) +
  labs(x = "占该省新纪录的期望份额", y = NULL,
       title = "b  份额最高的 18 个县",
       subtitle = "墨脱、崇明、珲春、勐腊、洋县等均为已知的边界与热点县") +
  theme_pub()

skp[, lv := LV[level]]
b3 <- ggplot(skp[level == "county"], aes(reorder(province, -rank_pct), rank_pct)) +
  geom_hline(yintercept = 0.5, linetype = 3, colour = "grey40") +
  geom_point(aes(size = n_event), colour = BLUE, alpha = .8) +
  scale_size_continuous(range = c(1, 4), name = "事件数") +
  scale_y_continuous(limits = c(0, 0.62)) +
  coord_flip() +
  labs(x = NULL, y = "留一省预测的排名分位",
       title = "c  留一省验证:29 个省中 27 个优于随机",
       subtitle = "把整个省从训练集移除后预测该省;中位分位 0.248。重庆、海南劣于随机(虚线)") +
  theme_pub() + theme(axis.text.y = element_text(size = 6.2),
                      legend.position = c(.82, .22))

sup <- fread(file.path(D_TB, "tbl_v2_future_support.csv"))
sup[, ssp := factor(ssp, levels = c("ssp245", "ssp585"),
                    labels = c("SSP2-4.5", "SSP5-8.5"))]
b4 <- ggplot(sup, aes(factor(horizon), pct, fill = ssp)) +
  geom_col(position = position_dodge(.72), width = .62) +
  geom_text(aes(label = sprintf("%.1f%%", pct)), position = position_dodge(.72),
            vjust = -0.4, size = 2.6) +
  scale_fill_manual(values = c(BLUE, RED), name = NULL) +
  scale_y_continuous(limits = c(0, 58), expand = expansion(c(0, .04))) +
  labs(x = "投影年份", y = "落在拟合协变量范围内的物种-省组合 (%)",
       title = "d  限制外推的是省级那一段,不是县级分配",
       subtitle = "县级分配依赖当前分布与观测格局,可稳定外推;省级风险到 2050 年只剩一成组合可用") +
  theme_pub() + theme(legend.position = c(.84, .86))

FigC2 <- (b1 | b2) / (b3 | b4)
save_fig(FigC2, "FigC2_county_surface", 10.4, 8.0)

cat("\n市县级图件已输出到 ", D_FG, "\n", sep = "")
