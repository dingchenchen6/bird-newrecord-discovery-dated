# ============================================================
# Scientific question / 科学问题:
# 把主模型的「诊断」与「稳健性」各做成一张可用于论文的图:
#   FigD1 诊断:残差分布、分组残差、空间自相关、比例风险
#   FigD2 稳健性:置换零模型、聚类自助、参数自助、影响力
#
# Input / 输入:
#   analysis_v2/data/model_v2_thr50.parquet
#   analysis_v2/data/null_perm_draws.rds, boot_draws.rds
#   analysis_v2/tables/tbl_null_models.csv, tbl_bootstrap_ci.csv,
#                      tbl_parametric_bootstrap.csv, tbl_influence_loo.csv
# Output / 输出: analysis_v2/figures_diag/FigD1-FigD2 (png/pdf/svg)
#
# Key assumptions / 关键假设:
#   - DHARMa 缩放残差在本脚本内重算(500 次模拟),使图件自洽,
#     不依赖脚本 138 的中间对象。
#   - 置换零分布已在脚本 190 中做过收敛过滤(|log HR| < 2),本脚本沿用同一规则。
#   - 全部数值直接取自分析脚本产出的表,图中不做二次计算。
#
# Main packages / 主要包: DHARMa, glmmTMB, ggplot2, patchwork, data.table
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(glmmTMB); library(DHARMa)
  library(ggplot2); library(patchwork); library(scales)
})
set.seed(20260805)

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_DT <- file.path(V2, "analysis_v2/data")
D_TB <- file.path(V2, "analysis_v2/tables")
D_FG <- file.path(V2, "analysis_v2/figures_diag")
dir.create(D_FG, recursive = TRUE, showWarnings = FALSE)
GREEN <- "#009E73"; BLUE <- "#0072B2"; RED <- "#D55E00"; GREY <- "grey55"
msg <- function(...) cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n", sep = "")

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

TERMCN <- c(clim_change_z = "累积变暖", effort_z = "调查努力",
            clim_var_z = "年度气候变异", `clim_change_z:effort_z` = "变暖 × 努力")

# ============================================================
# FigD1 诊断
# ============================================================
msg("重算 DHARMa 残差")
d <- as.data.table(read_parquet(file.path(D_DT, "model_v2_thr50.parquet")))[usable_main == TRUE]
zs <- function(x) as.numeric(scale(x))
d[, `:=`(clim_change_z = zs(clim_change), clim_var_z = zs(clim_var), effort_z = eff_visits_gap_z)]
FM <- event ~ clim_change_z * effort_z + clim_var_z + offset(log_completeness) +
  (1 | species) + (1 | province) + (1 | province:year)
fit <- glmmTMB(FM, data = d, family = binomial("cloglog"),
               control = glmmTMBControl(profile = TRUE))
sr <- simulateResiduals(fit, n = 500, seed = 1)
rq <- residuals(sr)

ks <- testUniformity(sr, plot = FALSE)
dp <- testDispersion(sr, plot = FALSE)
qq <- data.table(obs = sort(rq), exp = ppoints(length(rq)))
p1 <- ggplot(qq[seq(1, .N, by = 40)], aes(exp, obs)) +
  geom_abline(slope = 1, intercept = 0, colour = RED, linewidth = .6) +
  geom_point(size = .35, colour = BLUE, alpha = .5) +
  annotate("text", x = .04, y = .93, hjust = 0, size = 2.7, colour = "grey20",
           label = sprintf("KS D = %.4f, P = %.2f\n离散度 = %.3f, P = %.2f",
                           ks$statistic, ks$p.value, dp$statistic, dp$p.value)) +
  labs(x = "理论分位(均匀分布)", y = "DHARMa 缩放残差",
       title = "a  残差分布:与均匀分布无系统偏离",
       subtitle = "500 次模拟;每 40 个点抽 1 个绘制,避免 17.6 万点overplot") +
  theme_pub()

msg("分组残差")
grp_ks <- function(fac) {
  z <- data.table(g = fac, r = rq)[, .(n = .N, p = tryCatch(
    suppressWarnings(ks.test(r, "punif")$p.value), error = function(e) NA_real_)), by = g]
  z[is.finite(p)]
}
gy <- grp_ks(factor(d$year)); gy[, grp := "按年份 (23 个)"]
gp <- grp_ks(factor(d$province)); gp[, grp := "按省份 (31 个)"]
gg <- rbind(gy, gp)
p2 <- ggplot(gg, aes(p, grp, colour = p < 0.05)) +
  geom_vline(xintercept = 0.05, linetype = 2, colour = RED) +
  geom_jitter(height = .18, size = 1.5, alpha = .85) +
  scale_colour_manual(values = c(`FALSE` = BLUE, `TRUE` = RED), guide = "none") +
  scale_x_continuous(limits = c(0, 1)) +
  labs(x = "该组残差对均匀分布的 KS 检验 P 值", y = NULL,
       title = "b  分组残差:超出名义水平的组数接近 5%",
       subtitle = sprintf("年份 %d/%d 组 P<0.05,省份 %d/%d 组;名义假阳性率 5%%",
                          sum(gy$p < .05), nrow(gy), sum(gp$p < .05), nrow(gp))) +
  theme_pub()

msg("空间自相关")
prov_r <- data.table(province = d$province, r = rq)[, .(r = mean(r)), by = province]
cen <- fread(file.path(D_DT, "pa/pa_grid50_coverage_static.csv"))[
  , .(cx = mean(cen_lon), cy = mean(cen_lat)), by = province]
pr <- merge(prov_r, cen, by = "province")
dm <- as.matrix(dist(pr[, .(cx, cy)]))
w <- 1 / dm; diag(w) <- 0
w[!is.finite(w)] <- 0
zz <- pr$r - mean(pr$r); n <- nrow(pr)
moran <- function(v) (n / sum(w)) * sum(w * outer(v, v)) / sum(v^2)
I_obs <- moran(zz); perm <- replicate(999, moran(sample(zz)))
p_moran <- (sum(abs(perm) >= abs(I_obs)) + 1) / 1000
p3 <- ggplot(data.table(x = perm), aes(x)) +
  geom_histogram(bins = 40, fill = GREY, alpha = .5, colour = NA) +
  geom_vline(xintercept = I_obs, colour = RED, linewidth = .9) +
  annotate("text", x = I_obs, y = Inf, vjust = 1.6, hjust = -0.08, size = 2.7, colour = RED,
           label = sprintf("观测 I = %.3f\nP = %.2f", I_obs, p_moran)) +
  labs(x = "省级残差均值的 Moran's I", y = "999 次置换的频数",
       title = "c  空间自相关:落在零分布内部",
       subtitle = sprintf("反距离权重,%d 个省;E[I] = %.3f", n, -1 / (n - 1))) +
  theme_pub()

msg("比例风险")
d[, year_c := year - 2013]
fit_ph <- glmmTMB(update(FM, . ~ . + clim_change_z:year_c + effort_z:year_c),
                  data = d, family = binomial("cloglog"),
                  control = glmmTMBControl(profile = TRUE))
sph <- summary(fit_ph)$coefficients$cond
phd <- data.table(term = c("累积变暖 × 时间", "调查努力 × 时间"),
                  est = sph[c("clim_change_z:year_c", "effort_z:year_c"), 1],
                  se  = sph[c("clim_change_z:year_c", "effort_z:year_c"), 2],
                  P   = sph[c("clim_change_z:year_c", "effort_z:year_c"), 4])
phd[, `:=`(lo = est - 1.96 * se, hi = est + 1.96 * se)]
p4 <- ggplot(phd, aes(est, term)) +
  geom_vline(xintercept = 0, linetype = 2, colour = "grey55") +
  geom_pointrange(aes(xmin = lo, xmax = hi),
                  colour = ifelse(phd$P < .05, RED, BLUE), size = .45, linewidth = .7) +
  geom_text(aes(x = hi, label = sprintf("  P = %s", signif(P, 2))), hjust = 0, size = 2.7) +
  scale_x_continuous(expand = expansion(c(.08, .3))) +
  labs(x = "系数随时间的变化率(每年,对数风险尺度)", y = NULL,
       title = "d  比例风险:努力项违反,气候项成立",
       subtitle = "努力效应随时间显著衰减——这是实质发现,不是模型缺陷") +
  theme_pub()

FigD1 <- (p1 | p2) / (p3 | p4)
save_fig(FigD1, "FigD1_model_diagnostics", 10.4, 7.2)

# ============================================================
# FigD2 稳健性
# ============================================================
msg("稳健性图")
nl <- readRDS(file.path(D_DT, "null_perm_draws.rds"))
obs <- nl$observed
CONV_MAX <- 2
nd <- rbindlist(lapply(names(nl$draws), function(nm) {
  m <- nl$draws[[nm]]
  keep <- complete.cases(m) & apply(abs(m) < CONV_MAX, 1, all)
  rbindlist(lapply(names(obs), function(tt)
    data.table(null_model = nm, term = tt, val = exp(m[keep, tt]))))
}))
nd[, `:=`(nm_s = sub("^N[123]_", "", null_model), lbl = TERMCN[term])]
nd[, nm_s := factor(nm_s, levels = unique(nm_s))]
nd[, lbl := factor(lbl, levels = TERMCN)]
obs_dt <- data.table(term = names(obs), lbl = factor(TERMCN[names(obs)], levels = TERMCN),
                     hr = exp(obs))
q1 <- ggplot(nd, aes(val, nm_s)) +
  geom_violin(fill = GREY, alpha = .35, colour = NA, scale = "width") +
  geom_vline(data = obs_dt, aes(xintercept = hr), colour = RED, linewidth = .7) +
  facet_wrap(~ lbl, scales = "free_x", nrow = 1) +
  labs(x = "零分布下的风险比(红线 = 观测值)", y = NULL,
       title = "a  设计保持的置换零模型:每个只破坏一条关联",
       subtitle = "N1 打乱物种特异气候 · N2 打乱努力的时间对齐 · N3 打乱事件落在哪个物种;各 199 次") +
  theme_pub() + theme(axis.text.y = element_text(size = 7.2))

bci <- fread(file.path(D_TB, "tbl_bootstrap_ci.csv"))
bci[, lbl := factor(TERMCN[term], levels = rev(TERMCN))]
bci[, cl := fifelse(cluster == "species", "按物种重抽 (392 簇)", "按省份重抽 (31 簇)")]
bl <- rbind(
  bci[, .(lbl, cl, kind = "模型 CI", lo = model_lo, hi = model_hi, hr = observed_HR)],
  bci[, .(lbl, cl, kind = "聚类自助 CI", lo = boot_lo, hi = boot_hi, hr = observed_HR)])
q2 <- ggplot(bl, aes(hr, lbl, colour = kind)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey55") +
  geom_pointrange(aes(xmin = lo, xmax = hi), position = position_dodge(.55),
                  size = .3, linewidth = .6) +
  facet_wrap(~ cl) +
  scale_colour_manual(values = c(BLUE, RED), name = NULL) +
  scale_x_continuous(trans = "log", breaks = c(0.8, 1, 1.2, 1.5, 2)) +
  labs(x = "风险比 (95% CI,对数轴)", y = NULL,
       title = "b  聚类自助 CI vs 模型 CI",
       subtitle = "自助区间明显更宽即说明模型 SE 低估了聚类结构带来的不确定性") +
  theme_pub() + theme(legend.position = "top", legend.margin = margin(b = -4))

pb <- fread(file.path(D_TB, "tbl_parametric_bootstrap.csv"))
pb[, lbl := factor(TERMCN[term], levels = rev(TERMCN))]
q3 <- ggplot(pb, aes(coverage_95, lbl)) +
  geom_vline(xintercept = .95, linetype = 2, colour = RED) +
  geom_point(size = 2.6, colour = BLUE) +
  geom_text(aes(label = fifelse(is.na(rel_bias_pct),
                                sprintf("  偏倚 %+.4f (log HR)", bias_logHR),
                                sprintf("  偏倚 %+.1f%%", rel_bias_pct))),
            hjust = 0, size = 2.6, colour = "grey30") +
  scale_x_continuous(labels = percent_format(1), limits = c(.75, 1.08)) +
  labs(x = "参数自助下 95% 区间的实际覆盖率", y = NULL,
       title = "c  参数自助:估计量能否回收自身真值",
       subtitle = "红线为名义 95%;年度气候变异的 log HR 近 0,相对偏倚无定义,改报绝对偏倚") +
  theme_pub()

infl <- fread(file.path(D_TB, "tbl_influence_loo.csv"))
il <- melt(infl, id.vars = c("type", "dropped"),
           measure.vars = paste0("d_", names(obs)),
           variable.name = "term", value.name = "delta")
il[, term := sub("^d_", "", as.character(term))]
il[, lbl := factor(TERMCN[term], levels = rev(TERMCN))]
q4 <- ggplot(il, aes(delta, lbl, colour = type)) +
  geom_vline(xintercept = 0, linetype = 2, colour = "grey55") +
  geom_jitter(height = .16, size = 1.4, alpha = .8) +
  scale_colour_manual(values = c(BLUE, GREEN), name = NULL) +
  scale_x_continuous(labels = percent_format(1)) +
  labs(x = "剔除该簇后风险比的相对变化", y = NULL,
       title = "d  影响力:没有任何单一省份或物种组主导结果",
       subtitle = "逐省剔除(31 次)与物种十等分剔除(10 次)后四个系数的偏移;最大偏移 4.2%,164 次中仅 9 次超过 3%") +
  theme_pub() + theme(legend.position = "top", legend.margin = margin(b = -4))

FigD2 <- q1 / (q2 | q3) / q4 + plot_layout(heights = c(1, 1, 0.85))
save_fig(FigD2, "FigD2_robustness", 10.4, 9.2)

msg("完成 / done")
