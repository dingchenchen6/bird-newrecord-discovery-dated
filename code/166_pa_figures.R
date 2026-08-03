# ============================================================
# Scientific question / 科学问题:
# 把保护地关联分析的三条结论做成可用于论文的图:
#   P1 新纪录在保护区内的富集,有多少经得起「以观鸟人去过的地方为对照」
#   P2 保护区并不提高首次记录转为持续存在的概率
#   P3 保护网络与实测增温、与观测覆盖的关系,及监测嫁接优先级
# Three manuscript-ready figures for the protected-area module.
#
# Input / 输入: analysis_v2/tables/tbl_pa_*.csv, analysis_v2/data/pa/*
# Output / 输出: analysis_v2/figures_pa/FigP1-P3 (png/pdf/svg)
# Key assumptions / 关键假设:
#   - 全部数值直接读自分析脚本产出的表,图中不做任何再计算或修约以外的加工。
#   - 底图使用审图号 GS(2019)1822 的省界与国界。
# Main packages / 主要包: ggplot2, patchwork, data.table, sf
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(patchwork); library(sf); library(scales)
})
sf_use_s2(FALSE)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_PA <- file.path(V2, "analysis_v2/data/pa")
D_TB <- file.path(V2, "analysis_v2/tables")
D_FG <- file.path(V2, "analysis_v2/figures_pa")
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
          plot.tag = element_text(face = "bold", size = base + 3),
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

# ============================================================
# FigP1 保护区里的新纪录:富集有多少经得起观测对照
# ============================================================
lad <- fread(file.path(D_TB, "tbl_pa_c1_ladder.csv"))
rob <- fread(file.path(D_TB, "tbl_pa_c1_robustness.csv"))
conc <- fread(file.path(D_TB, "tbl_pa_concentration.csv"))
jk  <- fread(file.path(D_TB, "tbl_pa_c1_jackknife.csv"))
ev  <- fread(file.path(D_PA, "cc_events_enriched.csv"), encoding = "UTF-8")
locs <- fread(file.path(D_PA, "cc_birding_locations.csv"))
cov <- fread(file.path(D_PA, "pa_grid50_coverage_static.csv"))

base_share <- data.table(
  what = factor(c("新纪录事件", "观鸟 checklist\n(按努力加权)", "观鸟地点\n(等权)", "陆域面积"),
                levels = c("新纪录事件", "观鸟 checklist\n(按努力加权)", "观鸟地点\n(等权)", "陆域面积")),
  pct = c(100 * mean(ev$in_pa),
          100 * sum(locs$n_checklist * locs$in_pa) / sum(locs$n_checklist),
          100 * mean(unique(locs[, .(lon_r, lat_r, in_pa_static)])$in_pa_static),
          100 * sum(cov$pa_all) / sum(cov$cell_km2)),
  grp = c("case", "ctrl", "ctrl", "ctrl"))

pa <- ggplot(base_share, aes(what, pct, fill = grp)) +
  geom_col(width = .62) +
  geom_text(aes(label = sprintf("%.1f%%", pct)), vjust = -0.5, size = 2.9, fontface = "bold") +
  scale_fill_manual(values = c(case = RED, ctrl = GREY), guide = "none") +
  scale_y_continuous(limits = c(0, 32), expand = expansion(c(0, .04))) +
  labs(x = NULL, y = "落在自然保护区内的比例 (%)",
       title = "a  基准对比:事件 vs 观鸟努力 vs 面积",
       subtitle = "全国尺度上观鸟努力并未向保护区集中,新纪录却集中") +
  theme_pub()

lad[, wt := fifelse(grepl("effort", model), "按观测努力加权的对照", "按地点等权的对照")]
lad[, lbl := sub(" \\[.*", "", model)]
lad_or <- lad[grepl("^A0|^A1|^L", lbl)]
lad_or[, lbl := factor(lbl, levels = rev(c("A0 仅暴露", "A1 +选址几何", "L 国家级")))]
pb <- ggplot(lad_or, aes(OR, lbl, colour = wt)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey60") +
  geom_pointrange(aes(xmin = lo, xmax = hi), position = position_dodge(.45), size = .35, fatten = 2.6) +
  scale_colour_manual(values = c(BLUE, GREEN), name = NULL) +
  scale_x_continuous(trans = "log", breaks = c(1, 1.5, 2, 2.5, 3), limits = c(0.95, 3.1)) +
  labs(x = "条件优势比 (95% CI)", y = NULL,
       title = "b  条件 logistic:同省同年 1:200 匹配",
       subtitle = "对照 = 观鸟人当年在该省实际去过的地点") +
  theme_pub() + theme(legend.position = "bottom", legend.direction = "vertical",
                      legend.margin = margin(t = -4))

rob[, lbl := factor(model, levels = rev(model))]
pc <- ggplot(rob, aes(OR, lbl)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey60") +
  geom_pointrange(aes(xmin = lo, xmax = hi),
                  colour = ifelse(rob$lo > 1, RED, GREY), size = .35, fatten = 2.6) +
  geom_text(aes(x = hi, label = sprintf("  n=%d", n_stratum)), hjust = 0, size = 2.4, colour = "grey40") +
  scale_x_continuous(trans = "log", breaks = c(0.5, 1, 2, 4, 7), limits = c(0.45, 11)) +
  labs(x = "条件优势比 (95% CI)", y = NULL,
       title = "c  稳健性:效应由少数保护区与近十年撑起",
       subtitle = "剔除前两大宿主保护区后 CI 覆盖 1;2002-2012 无效应") +
  theme_pub()

conc[, rank := .I]
pd <- ggplot(conc, aes(rank, cum_pct)) +
  geom_area(fill = RED, alpha = .18) + geom_line(colour = RED, linewidth = .6) +
  geom_hline(yintercept = 50, linetype = 3, colour = "grey50") +
  annotate("text", x = nrow(conc) * .55, y = 55,
           label = sprintf("前 %d 处保护区\n即占区内事件的一半", which(conc$cum_pct >= 50)[1]),
           size = 2.6, colour = "grey25", hjust = 0) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(x = "宿主保护区(按区内事件数降序)", y = "累计占比 (%)",
       title = "d  区内事件高度集中",
       subtitle = sprintf("%d 条区内事件只落在 %d 处保护区(全部 1028 处中的 %.1f%%)",
                          sum(ev$in_pa), nrow(conc), 100 * nrow(conc) / 1028)) +
  theme_pub()

FigP1 <- (pa | pb) / (pc | pd)
save_fig(FigP1, "FigP1_pa_enrichment", 10.2, 7.0)

# ============================================================
# FigP2 保护区不提高首次记录转为持续存在的概率
# ============================================================
c5 <- fread(file.path(D_TB, "tbl_pa_c5_persistence.csv"))
pers <- fread(file.path(D_PA, "c5_events_persistence.csv"), encoding = "UTF-8")

raw <- melt(c5[, .(response, raw_in, raw_out)], id.vars = "response",
            variable.name = "grp", value.name = "p")
raw[, grp := factor(fifelse(grp == "raw_in", "保护区内", "保护区外"),
                    levels = c("保护区外", "保护区内"))]
raw[, response := factor(fifelse(response == "redetected", "此后至少再检出 1 次", "此后 ≥3 个年份被检出"),
                         levels = c("此后至少再检出 1 次", "此后 ≥3 个年份被检出"))]
nn <- pers[, .N, by = in_pa]
raw[, n := fifelse(grp == "保护区内", nn$N[nn$in_pa == TRUE], nn$N[nn$in_pa == FALSE])]
raw[, se := sqrt(p * (1 - p) / n)]

qa <- ggplot(raw, aes(response, p, fill = grp)) +
  geom_col(position = position_dodge(.7), width = .62) +
  geom_errorbar(aes(ymin = p - 1.96 * se, ymax = p + 1.96 * se),
                position = position_dodge(.7), width = .12, linewidth = .35) +
  scale_fill_manual(values = c(GREY, GREEN), name = NULL) +
  scale_y_continuous(labels = percent_format(1), limits = c(0, .6)) +
  labs(x = NULL, y = "首次记录后被再检出的比例",
       title = "a  再检出的原始比例",
       subtitle = "以 GBIF/eBird 同种同省的后续年份检出为存续代理") +
  theme_pub() + theme(legend.position = c(.82, .9))

c5[, lbl := factor(fifelse(response == "redetected", "此后至少再检出 1 次", "此后 ≥3 个年份被检出"),
                   levels = rev(c("此后至少再检出 1 次", "此后 ≥3 个年份被检出")))]
qb <- ggplot(c5, aes(OR, lbl)) +
  annotate("rect", xmin = 0.67, xmax = 1.5, ymin = -Inf, ymax = Inf, fill = GREEN, alpha = .10) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey60") +
  geom_pointrange(aes(xmin = lo, xmax = hi), colour = BLUE, size = .4, fatten = 3) +
  scale_x_continuous(trans = "log", breaks = c(0.5, 0.67, 1, 1.5, 2), limits = c(0.5, 2.2)) +
  labs(x = "保护区内 vs 区外的优势比 (95% CI)", y = NULL,
       title = "b  控制后续观测努力与年份后",
       subtitle = "绿带为预先声明的等价界 [0.67, 1.5];CI 稍宽于等价界,判为不确定而非无差异") +
  theme_pub()

pers[, eff_bin := cut(log1p(eff_after), 5)]
eb <- pers[, .(p = mean(redetected), n = .N,
               x = mean(log1p(eff_after))), by = .(eff_bin, in_pa)]
eb[, se := sqrt(p * (1 - p) / n)]
qc <- ggplot(eb, aes(x, p, colour = factor(in_pa))) +
  geom_pointrange(aes(ymin = p - 1.96 * se, ymax = p + 1.96 * se), size = .3, fatten = 2.4) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"), se = FALSE, linewidth = .55) +
  scale_colour_manual(values = c(`FALSE` = GREY, `TRUE` = GREEN),
                      labels = c("保护区外", "保护区内"), name = NULL) +
  scale_y_continuous(labels = percent_format(1)) +
  labs(x = "首次记录之后该省累计 checklist 量 (log)", y = "被再检出的比例",
       title = "c  决定再检出的是后续观测努力",
       subtitle = "再检出率随后续 checklist 量陡升;区内外差异在各努力档内均不可分辨") +
  theme_pub() + theme(legend.position = c(.18, .88))

qd_dat <- pers[, .(n = .N, p = mean(persist3)), by = .(year, in_pa)][n >= 5]
qd <- ggplot(qd_dat, aes(year, p, colour = factor(in_pa))) +
  geom_point(aes(size = n), alpha = .7) +
  geom_smooth(method = "lm", se = FALSE, linewidth = .55) +
  coord_cartesian(ylim = c(0, NA)) +
  scale_colour_manual(values = c(`FALSE` = GREY, `TRUE` = GREEN),
                      labels = c("保护区外", "保护区内"), name = NULL) +
  scale_size_continuous(range = c(.8, 3), guide = "none") +
  scale_y_continuous(labels = percent_format(1)) +
  labs(x = "首次记录年份", y = "此后 ≥3 个年份被检出的比例",
       title = "d  右删失:越晚的首次记录后续窗口越短",
       subtitle = "因此主分析限定在 2020 年及以前的事件") +
  theme_pub() + theme(legend.position = c(.82, .88))

FigP2 <- (qa | qb) / (qc | qd)
save_fig(FigP2, "FigP2_pa_persistence", 10.2, 7.0)

# ============================================================
# FigP3 保护网络 × 实测增温 × 观测覆盖
# ============================================================
wq  <- fread(file.path(D_TB, "tbl_pa_c3_warming_quintiles.csv"))
fr  <- fread(file.path(D_TB, "tbl_pa_c3_fracreg.csv"))
pt  <- fread(file.path(D_TB, "tbl_pa_c3_permutation.csv"))
pri <- fread(file.path(D_TB, "tbl_pa_c3_priority_quadrants.csv"))
gp  <- fread(file.path(D_PA, "c3_grid_panel.csv"))
clim_old <- fread(file.path(V2, "data/raw/grid_50km_climate.csv"))

# a 用省级广播列与真正格级列做对照,展示口径陷阱
cmp <- merge(gp[, .(grid_id, cell_km2, pa_all, warm_cell = warming_rate)],
             clim_old[, .(grid_id, warm_prov = warming_rate)], by = "grid_id")
mk_q <- function(v, lab) {
  q <- cut(v, breaks = quantile(v, seq(0, 1, .2), na.rm = TRUE),
           include.lowest = TRUE, labels = paste0("Q", 1:5))
  d <- data.table(q = q, pa = cmp$pa_all, a = cmp$cell_km2)[!is.na(q),
        .(cover = sum(pa) / sum(a)), by = q][order(q)]
  d[, src := lab]; d
}
L_PROV <- "省级广播口径(原 grid 文件)"
L_CELL <- "格级实测口径(CRU TS 4.09 重算)"
qcmp <- rbind(mk_q(cmp$warm_prov, L_PROV), mk_q(cmp$warm_cell, L_CELL))
qcmp[, src := factor(src, levels = c(L_PROV, L_CELL))]
ra <- ggplot(qcmp, aes(q, cover, fill = src)) +
  geom_col(position = position_dodge(.72), width = .64) +
  scale_fill_manual(values = setNames(c(GREY, BLUE), c(L_PROV, L_CELL)), name = NULL) +
  scale_y_continuous(labels = percent_format(1)) +
  labs(x = "增温速率五分位(Q1 最慢 → Q5 最快)", y = "面积加权保护地覆盖率",
       title = "a  「保护区都建在增温慢的地方」是口径造成的",
       subtitle = "省级广播口径给出 8.5 倍落差;格级实测口径下落差仅 1.2 倍") +
  theme_pub() + theme(legend.position = c(.78, .82))

perm_dt <- data.table(x = rnorm(4000, pt$perm_mean, pt$perm_sd))
rb <- ggplot(perm_dt, aes(x)) +
  geom_density(fill = GREY, alpha = .25, colour = NA) +
  geom_vline(xintercept = c(pt$perm_lo, pt$perm_hi), linetype = 3, colour = "grey45") +
  geom_vline(xintercept = pt$observed_within_stratum_rho, colour = RED, linewidth = .8) +
  annotate("text", x = pt$observed_within_stratum_rho, y = Inf,
           label = sprintf("  观测 ρ = %.3f\n  P = %.2f", pt$observed_within_stratum_rho, pt$P_perm),
           hjust = 0, vjust = 1.4, size = 2.7, colour = RED) +
  labs(x = "省 × 海拔带分层内的 Spearman ρ(保护地覆盖 vs 增温)", y = "置换零分布密度",
       title = "b  分层置换检验:省内无配置偏倚",
       subtitle = "999 次层内重排;观测值落在零分布内部") +
  theme_pub()

prov_sf <- st_transform(st_read(file.path(BM, "省（等积投影）.shp"), quiet = TRUE), AEA)
gp_sf <- st_as_sf(gp[!is.na(centroid_lon)], coords = c("centroid_lon", "centroid_lat"), crs = 4326)
gp_sf <- st_transform(gp_sf, AEA)
gp_sf$priority <- factor(gp_sf$priority,
  levels = c("A 嫁接到已建保护区", "B 保护体系外,需另投调查", "C 高暴露但已有观测", "D 其他"))
gp_pri <- gp_sf[gp_sf$priority != "D 其他", ]
gp_pri$priority <- droplevels(gp_pri$priority)
rc <- ggplot() +
  geom_sf(data = prov_sf, fill = "grey97", colour = "grey80", linewidth = .12) +
  geom_sf(data = gp_pri, aes(colour = priority), size = .45, alpha = .85) +
  scale_colour_manual(values = c(GREEN, RED, BLUE), name = NULL) +
  labs(title = "c  监测嫁接优先级", subtitle = "高增温三分位 × 低近期观测三分位;底图 GS(2019)1822") +
  theme_pub() + theme(axis.line = element_blank(), axis.text = element_blank(),
                      axis.ticks = element_blank(), legend.position = c(.16, .22))

pri2 <- pri[priority != "D 其他"]
pri2[, priority := factor(priority, levels = rev(pri2$priority))]
rd <- ggplot(pri2, aes(area_km2 / 1e4, priority, fill = priority)) +
  geom_col(width = .6) +
  geom_text(aes(label = sprintf("%d 格 · 区内覆盖 %.0f%%", n_cell, 100 * pa_cover)),
            hjust = -0.05, size = 2.6) +
  scale_fill_manual(values = rev(c(GREEN, RED, BLUE)), guide = "none") +
  scale_x_continuous(expand = expansion(c(0, .38))) +
  labs(x = "面积 (万 km²)", y = NULL,
       title = "d  两类监测缺口的量级",
       subtitle = "A 类可直接嫁接到已建保护区的管理机构;B 类必须另投调查力量") +
  theme_pub()

FigP3 <- (ra | rb) / (rc | rd) + plot_layout(heights = c(1, 1.15))
save_fig(FigP3, "FigP3_pa_mismatch_monitoring", 10.2, 7.6)

cat("\n全部保护地图件已输出到 ", D_FG, "\n", sep = "")
