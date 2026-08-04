# ============================================================
# Scientific question / 科学问题:
# 把「随机森林 vs 机制模型」的比较做成两张图:
#   FigR1 省级:判别力、校准、外推行为、以及随机森林到底在学什么
#   FigR2 市县级分配:内插时打平,外推到新省份时机制模型胜出
#
# Input / 输入: analysis_v2/tables/tbl_rf_*.csv, analysis_v2/data/rf_extrapolation_curve.csv
# Output / 输出: analysis_v2/figures_rf/FigR1-FigR2 (png/pdf/svg)
# Key assumptions / 关键假设:
#   - 事件率 0.369%,因此判别力以 PR-AUC 为主指标;图中同时给出相对基线的提升倍数。
#   - 校准斜率的理想值为 1;偏离 1 表示概率被压缩或放大。
# Main packages / 主要包: ggplot2, patchwork, data.table
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(patchwork); library(scales)
})

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_TB <- file.path(V2, "analysis_v2/tables")
D_DT <- file.path(V2, "analysis_v2/data")
D_FG <- file.path(V2, "analysis_v2/figures_rf")
dir.create(D_FG, recursive = TRUE, showWarnings = FALSE)
GREEN <- "#009E73"; BLUE <- "#0072B2"; RED <- "#D55E00"; GREY <- "grey55"; PURPLE <- "#8B5FA8"

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

# ================= FigR1 省级 =================
sm <- fread(file.path(D_TB, "tbl_rf_province_summary.csv"))
SCH <- c(random = "随机 5 折", leave_species = "留物种 5 折",
         leave_province = "留省 5 折", temporal = "时间前推\n2019–2024")
sm[, sch := factor(SCH[scheme], levels = SCH)]
MOD <- c("离散风险模型(边际)", "离散风险模型(条件)",
         "随机森林(同信息)", "随机森林(加结构)", "随机森林(类平衡)")
sm[, model := factor(model, levels = MOD)]
COLM <- setNames(c(BLUE, "#4A9BD1", "grey72", GREY, RED), MOD)

a1 <- ggplot(sm, aes(sch, prauc, fill = model)) +
  geom_col(position = position_dodge(.8), width = .72) +
  geom_hline(yintercept = 0.00369, linetype = 3, colour = "grey35") +
  annotate("text", x = 0.62, y = 0.0042, label = "事件率 0.369%", size = 2.4,
           colour = "grey30", hjust = 0) +
  scale_fill_manual(values = COLM, name = NULL) +
  scale_y_continuous(expand = expansion(c(0, .06))) +
  labs(x = NULL, y = "PR-AUC(事件率 0.369% 下的主指标)",
       title = "a  判别力:验证方案一换,排名就翻转",
       subtitle = "内插(随机/留物种)时随机森林领先;外推到新省份或未来年份时机制模型追平甚至反超") +
  theme_pub() + theme(legend.position = "top", legend.margin = margin(b = -4))

a2 <- ggplot(sm, aes(cal_slope, sch, colour = model)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey50") +
  geom_point(position = position_dodge(.6), size = 2, alpha = .9) +
  scale_colour_manual(values = COLM, guide = "none") +
  scale_x_continuous(limits = c(0, 1.15)) +
  labs(x = "校准斜率(理想值 = 1)", y = NULL,
       title = "b  校准:机制模型的概率可以直接用",
       subtitle = "概率森林把风险压扁(斜率 0.03–0.30);类平衡森林斜率接近 1 但概率整体放大约 40 倍") +
  theme_pub()

ex <- fread(file.path(D_DT, "rf_extrapolation_curve.csv"))
exl <- melt(ex[, .(clim_change_z, in_support, `离散风险模型` = p_hazard, `随机森林` = p_rf)],
            id.vars = c("clim_change_z", "in_support"), variable.name = "model", value.name = "p")
sup <- range(ex$clim_change_z[ex$in_support])
a3 <- ggplot(exl, aes(clim_change_z, p, colour = model)) +
  annotate("rect", xmin = sup[1], xmax = sup[2], ymin = -Inf, ymax = Inf,
           fill = "grey85", alpha = .45) +
  annotate("text", x = mean(sup), y = 0.075, label = "拟合范围", size = 2.6, colour = "grey30") +
  geom_line(linewidth = .8) +
  scale_colour_manual(values = c(BLUE, RED), name = NULL) +
  scale_y_continuous(labels = percent_format(0.1)) +
  labs(x = "累积变暖(标准化,SD)", y = "预测年风险",
       title = "c  外推:一个饱和,一个线性上升",
       subtitle = "随机森林在约 2.9 SD 处就已返回边界叶值并恒定在 6.7%;cloglog 在对数风险尺度上继续线性外推") +
  theme_pub() + theme(legend.position = c(.22, .82))

imp <- fread(file.path(D_TB, "tbl_rf_importance.csv"))
TERMCN <- c(yr = "年份", effort_z = "调查努力", clim_change_z = "累积变暖",
            log_completeness = "报告完整度", clim_var_z = "年度气候变异",
            province_f = "省份", mig_f = "迁徙类型")
setorder(imp, importance)
imp[, lbl := factor(TERMCN[term], levels = TERMCN[term])]
imp[, is_obs := term %in% c("yr", "effort_z", "log_completeness", "province_f")]
a4 <- ggplot(imp, aes(rel, lbl, fill = is_obs)) +
  geom_col(width = .66) +
  scale_fill_manual(values = c(`TRUE` = RED, `FALSE` = GREEN),
                    labels = c("生态过程变量", "观测过程变量"), name = NULL) +
  scale_x_continuous(expand = expansion(c(0, .05))) +
  labs(x = "置换重要性(相对最大值)", y = NULL,
       title = "d  随机森林最看重的是年份",
       subtitle = "前四位有三个属于观测过程;树模型学到的主要是「哪些年、哪些省容易出记录」") +
  theme_pub() + theme(legend.position = c(.7, .28))

FigR1 <- (a1 | a2) / (a3 | a4)
save_fig(FigR1, "FigR1_rf_vs_hazard_province", 10.6, 7.4)

# ================= FigR2 市县级分配 =================
sk <- fread(file.path(D_TB, "tbl_rf_alloc_skill.csv"))
bp <- fread(file.path(D_TB, "tbl_rf_alloc_province.csv"))
LV <- c(prefecture = "市级(备择中位 13)", county = "县级(备择中位 103)")
MOD2 <- c("条件 logit (M3)", "随机森林(默认)", "随机森林(类平衡)", "基线:随机")
COL2 <- setNames(c(BLUE, RED, "grey65", "grey85"), MOD2)
sk[, `:=`(lv = factor(LV[level], levels = LV), model = factor(model, levels = MOD2))]

b1 <- ggplot(sk, aes(model, rank_pct, fill = model)) +
  geom_col(width = .64) +
  geom_hline(yintercept = 0.5, linetype = 3, colour = "grey40") +
  geom_text(aes(label = sprintf("%.3f", rank_pct)), vjust = -0.4, size = 2.5) +
  facet_wrap(~ lv) +
  scale_fill_manual(values = COL2, guide = "none") +
  scale_y_continuous(limits = c(0, 0.6), expand = expansion(c(0, .04))) +
  labs(x = NULL, y = "被选中单元的预测排名分位(越小越好)",
       title = "a  时间前推:两族模型打平",
       subtitle = "2002–2018 拟合,2019–2024 预测;随机森林在县级略优") +
  theme_pub() + theme(axis.text.x = element_text(angle = 20, hjust = 1))

bs <- bp[, .(rank_pct = mean(rank_pct), top1 = mean(top1),
             n_better = sum(rank_pct < 0.5), n_prov = .N), by = .(level, model)]
bs[, `:=`(lv = factor(LV[level], levels = LV), model = factor(model, levels = MOD2))]
b2 <- ggplot(bs, aes(model, rank_pct, fill = model)) +
  geom_col(width = .64) +
  geom_hline(yintercept = 0.5, linetype = 3, colour = "grey40") +
  geom_text(aes(label = sprintf("%.3f", rank_pct)), vjust = -0.4, size = 2.5) +
  facet_wrap(~ lv) +
  scale_fill_manual(values = COL2, guide = "none") +
  scale_y_continuous(limits = c(0, 0.6), expand = expansion(c(0, .04))) +
  labs(x = NULL, y = "留一省预测的排名分位",
       title = "b  换成留一省,机制模型明显胜出",
       subtitle = "把整个省移出训练集后预测该省——这才是布点到新地区时的真实处境") +
  theme_pub() + theme(axis.text.x = element_text(angle = 20, hjust = 1))

im <- fread(file.path(D_TB, "tbl_rf_alloc_importance.csv"))
T2 <- c(log_dist_z = "到分布区距离", in_range = "已在分布区内", log_eff_z = "累计观鸟努力",
        log_area_z = "单元面积", elev_z = "海拔", bio1_z = "年均温",
        bio12_z = "年降水", frac_pa_z = "保护地覆盖")
iml <- melt(im[level == "county", .(term, 随机森林 = rf_rel, `条件 logit` = cl_rel)],
            id.vars = "term", variable.name = "model", value.name = "rel")
iml[, lbl := factor(T2[term], levels = rev(T2))]
b3 <- ggplot(iml, aes(rel, lbl, fill = model)) +
  geom_col(position = position_dodge(.72), width = .64) +
  scale_fill_manual(values = c(RED, BLUE), name = NULL) +
  scale_x_continuous(expand = expansion(c(0, .05))) +
  labs(x = "相对重要性(各自归一到最大值)", y = NULL,
       title = "c  两族模型看重的东西不一样(县级)",
       subtitle = "条件 logit 靠物种特异的分布区距离;随机森林靠年均温、面积、海拔这些通用地理描述") +
  theme_pub() + theme(legend.position = c(.74, .22))

FigR2 <- (b1 | b2) / b3 + plot_layout(heights = c(1, 0.9))
save_fig(FigR2, "FigR2_rf_vs_clogit_units", 10.6, 7.2)

cat("\n随机森林比较图件已输出到 ", D_FG, "\n", sep = "")
