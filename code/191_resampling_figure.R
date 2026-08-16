# ============================================================
# Scientific question / 科学问题:
# 把零模型、聚类自助、参数自助与影响力四项重抽样结果做成一张四面板图
# (投稿用:GCB SI Fig. S11 / Nature 系 Extended Data Fig. 5)。
# One four-panel figure for the permutation nulls, cluster bootstraps,
# parametric bootstrap and influence analysis.
#
# Input / 输入:
#   analysis_v2/data/null_perm_draws.rds
#   analysis_v2/tables/tbl_bootstrap_ci.csv
#   analysis_v2/tables/tbl_parametric_bootstrap.csv
#   analysis_v2/tables/tbl_influence_loo.csv
# Output / 输出: analysis_v2/figures/FigS5_resampling_v2.(png|pdf|svg)
# Key assumptions / 关键假设:
#   - 与文稿一致:发散拟合按 |log HR| < 2 过滤(文中已声明剔除个数)。
#   - 面板 a 只画三个信息最大的组合:N1/N3 的累积变暖、N2 的努力、N3 的交互。
# Main packages / 主要包: ggplot2, patchwork, data.table
# ============================================================

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(patchwork); library(scales)
})

V2   <- "/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2"
D_TB <- file.path(V2, "analysis_v2/tables")
D_FG <- file.path(V2, "analysis_v2/figures")
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

# ---------- a 置换零分布 ----------
nd <- readRDS(file.path(V2, "analysis_v2/data/null_perm_draws.rds"))
obs <- nd$observed
pick <- list(
  list(null = 1, term = "clim_change_z",          lab = "Accumulated warming\n(null N1: warming shuffled\nwithin province-years)"),
  list(null = 3, term = "clim_change_z",          lab = "Accumulated warming\n(null N3: events shuffled\namong species at risk)"),
  list(null = 2, term = "effort_z",               lab = "Survey effort\n(null N2: effort shuffled\nacross years within province)"),
  list(null = 3, term = "clim_change_z:effort_z", lab = "Warming × effort\n(null N3)")
)
da <- rbindlist(lapply(pick, function(p) {
  m <- nd$draws[[p$null]]
  keep <- complete.cases(m) & apply(abs(m) < 2, 1, all)
  data.table(panel = p$lab, hr = exp(m[keep, p$term]), obs_hr = exp(obs[[p$term]]))
}))
da[, panel := factor(panel, levels = sapply(pick, `[[`, "lab"))]
pa <- ggplot(da, aes(hr)) +
  geom_density(fill = GREY, alpha = .3, colour = NA) +
  scale_x_continuous(expand = expansion(mult = c(0.05, 0.12))) +
  geom_vline(xintercept = 1, linetype = 3, colour = "grey55") +
  geom_vline(aes(xintercept = obs_hr), colour = RED, linewidth = .7) +
  facet_wrap(~ panel, scales = "free", nrow = 1) +
  labs(x = "Hazard ratio under the permutation null", y = "Density",
       title = "a  Design-preserving permutation nulls (199 each)",
       subtitle = "Red: observed. Dotted: unity. The warming nulls centre near 1.16, not unity, because within-stratum shuffles preserve the provincial-annual climate–event covariance") +
  theme_pub() + theme(strip.text = element_text(size = 7.2, face = "plain"))

# ---------- b 聚类自助 ----------
bc <- fread(file.path(D_TB, "tbl_bootstrap_ci.csv"))
TERM <- c(clim_change_z = "Accumulated warming", effort_z = "Survey effort",
          clim_var_z = "Annual variability", `clim_change_z:effort_z` = "Warming × effort")
bc[, lbl := factor(TERM[term], levels = rev(TERM))]
bl <- rbindlist(list(
  bc[cluster == "species", .(lbl, kind = "Wald (model-based)", lo = model_lo, hi = model_hi, mid = observed_HR)],
  bc[cluster == "species", .(lbl, kind = "Species cluster bootstrap", lo = boot_lo, hi = boot_hi, mid = observed_HR)],
  bc[cluster == "province", .(lbl, kind = "Province cluster bootstrap", lo = boot_lo, hi = boot_hi, mid = observed_HR)]
))
bl[, kind := factor(kind, levels = c("Wald (model-based)", "Species cluster bootstrap", "Province cluster bootstrap"))]
pb <- ggplot(bl, aes(mid, lbl, colour = kind)) +
  geom_vline(xintercept = 1, linetype = 3, colour = "grey55") +
  geom_pointrange(aes(xmin = lo, xmax = hi), position = position_dodge(.55), size = .3, fatten = 2.2) +
  scale_colour_manual(values = c(GREY, GREEN, BLUE), name = NULL) +
  scale_x_continuous(trans = "log", breaks = c(0.8, 1, 1.2, 1.4, 1.6, 1.8)) +
  labs(x = "Hazard ratio (95% CI)", y = NULL,
       title = "b  Cluster bootstraps (300 resamples each)",
       subtitle = "Provincial clustering widens the intervals (SE ratio 1.26–1.59); species clustering does not (0.86–1.17)") +
  theme_pub() + theme(legend.position = c(.78, .24))

# ---------- c 参数自助 ----------
pbt <- fread(file.path(D_TB, "tbl_parametric_bootstrap.csv"))
pbt[, lbl := factor(TERM[term], levels = TERM)]
pc <- ggplot(pbt, aes(lbl, coverage_95)) +
  geom_hline(yintercept = 0.95, linetype = 2, colour = "grey50") +
  geom_col(width = .55, fill = BLUE, alpha = .85) +
  geom_text(aes(label = sprintf("bias %+.3f", bias_logHR)), vjust = 1.6, size = 2.5, colour = "white") +
  scale_y_continuous(labels = percent_format(1), limits = c(0, 1.0), expand = expansion(c(0, 0.02))) +
  labs(x = NULL, y = "Actual coverage of the nominal 95% CI",
       title = "c  Parametric bootstrap (150 simulations)",
       subtitle = "Coverage 91.3–95.3%; absolute bias below 0.01 on the log-hazard scale") +
  theme_pub() + theme(axis.text.x = element_text(angle = 15, hjust = 1))

# ---------- d 影响力 ----------
il <- fread(file.path(D_TB, "tbl_influence_loo.csv"))
dl <- melt(il, id.vars = c("type", "dropped"),
           measure.vars = patterns("^d_"), variable.name = "term", value.name = "dlog")
dl[, term := sub("^d_", "", term)]
dl[, lbl := factor(TERM[term], levels = TERM)]
dl[, pct := 100 * (exp(dlog) - 1)]
dl[, grp := fifelse(type == "省", "Leave one province out", "Leave one species decile out")]
pd <- ggplot(dl, aes(lbl, pct)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_hline(yintercept = c(-3, 3), linetype = 3, colour = "grey60") +
  geom_jitter(aes(colour = grp), width = .18, size = .9, alpha = .65) +
  scale_colour_manual(values = c(BLUE, GREEN), name = NULL) +
  labs(x = NULL, y = "Change in hazard ratio when held out (%)",
       title = "d  Influence",
       subtitle = "No single province or species decile carries the result;\nmaximum change 4.2%, 9 of 164 beyond 3% (dotted)") +
  theme_pub() + theme(axis.text.x = element_text(angle = 15, hjust = 1),
                      legend.position = c(.8, .9))

Fig <- pa / (pb | pc | pd) + plot_layout(heights = c(0.95, 1.05))
for (ext in c("png", "pdf", "svg")) {
  f <- file.path(D_FG, paste0("FigS5_resampling_v2.", ext))
  if (ext == "png") ggsave(f, Fig, width = 12.4, height = 7.6, dpi = 450, bg = "white")
  else if (ext == "pdf") ggsave(f, Fig, width = 12.4, height = 7.6, device = grDevices::cairo_pdf)
  else ggsave(f, Fig, width = 12.4, height = 7.6, device = grDevices::svg)
}
cat("wrote FigS5_resampling_v2\n")
