#!/usr/bin/env Rscript
# ============================================================
# Script 163: 全部气候变化代理的对齐对比表 + 生态学阐释
# Aligned comparison of every climate-change proxy, with its ecological reading
# ============================================================
# 目的 / Objective:
#   把本研究用过的全部气候变化代理放在同一张表里, 逐项给出
#   【气候主效应、调查努力主效应、二者交互】三组参数(HR, 95% CI, P),
#   并附每个代理的生态学依据与含义解释。
#
#   "对齐"的含义 / What "aligned" means here:
#     同一行集(n = 175,901; 649 事件), 同一随机效应结构 R3,
#     同一努力代理(visits, 覆盖缺口口径), 同一 offset(log c_t),
#     同一连接函数(cloglog), 同一累积窗口(W = 15)。
#   因此 AIC 与全部系数在代理之间【直接可比】。
#
# 阐释框架 / The reading these proxies must be interpreted within:
#   一条新记录的产生需要两件事同时发生, 而不是其中之一:
#     (1) 生态过程: 该种确实出现在该省(新到达, 或原本就在但处于低密度);
#     (2) 观测过程: 有人在看、看到了、并把它写成文献。
#   记录风险 = 到达概率 x 发现概率。cloglog 连接是对数的, 所以这个【乘积】
#   在线性预测子上就是【相加】—— 主模型的结构正是这一分解, 而不是把两者
#   当作互相竞争的解释。交互项衡量的是两者偏离纯粹相乘的程度。
#
#   气候项【不是】"越暖越好"。理论上的因果链有两端:
#     源头(push): 物种【原分布区】累积变暖 -> 种群受压 -> 外扩追踪气候
#     目的地(pull): 【目标省】热条件上移 -> 进入该种可占据的条件范围
#   主模型的 x = dT - dN 把两端压进一个系数并强加对称(β_dT = -β_dN)。
#   脚本 164 放开这个约束后发现: 对称被数据拒绝(dAIC 34.9), 驱动来自
#   目的地端(dT HR 1.977), 源头端不但不支持推力, 系数还显著为负(dN 0.852)。
#   因此下表每一行的 rationale 都按"目的地端主导 + 观测过程串联"来写,
#   而不是按"越暖越好"。
#
# 代理来源 / Where each proxy comes from:
#   tavg_annual / tmax_warm / tavg_winter / tmin_cold  -> 脚本 134(四指标)
#   niche_prox / niche_track / heat_exposure / 调节模型 -> 脚本 160
#   dT / dN 两端分解                                    -> 脚本 164(结构不同, AIC 不可比)
#   134 只保存了 HR 与 P, 未保存 CI; 由 Wald 关系反解:
#     se = |log HR| / z(P/2),  CI = exp(log HR +- 1.96 se)
#   已用 160 的两个共有规格交叉验证(见运行时打印的 CHECK 行)。
#
# Input / 输入:
#   analysis_v2/tables/tbl_v2_indicator_window.csv   (134)
#   analysis_v2/tables/tbl_v2_niche_spec_coefs.csv   (160)
#   analysis_v2/tables/tbl_v2_niche_spec_fit.csv     (160)
#   analysis_v2/tables/tbl_v2_push_pull.csv          (164)
# Output / 输出:
#   analysis_v2/tables/tbl_v2_climate_proxy_comparison.csv
#
# Main packages / 主要包: data.table
# 运行 / Run: Rscript --no-init-file code/163_climate_proxy_comparison.R
# ============================================================

suppressPackageStartupMessages(library(data.table))
options(warn = 1)

OUT <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
TAB <- file.path(OUT, "tables")
msg <- function(...) cat(sprintf("[163 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

ci_from_p <- function(HR, P) {
  b <- log(HR)
  z <- stats::qnorm(pmax(P, .Machine$double.xmin) / 2, lower.tail = FALSE)
  se <- abs(b) / z
  list(lo = exp(b - 1.96 * se), hi = exp(b + 1.96 * se))
}

iw <- fread(file.path(TAB, "tbl_v2_indicator_window.csv"))[window == 15L]
ct <- fread(file.path(TAB, "tbl_v2_niche_spec_coefs.csv"))
ft <- fread(file.path(TAB, "tbl_v2_niche_spec_fit.csv"))
pp <- fread(file.path(TAB, "tbl_v2_push_pull.csv"))

for (pair in list(c("tavg_annual", "S0_tavg_annual"), c("tmax_warm", "S1_tmax_warm"))) {
  a <- iw[indicator == pair[1]]; b <- ct[spec == pair[2] & term == "clim_change_z"]
  r <- ci_from_p(a$HR_change, a$P_change)
  msg(sprintf("CHECK %-12s reconstructed [%.4f, %.4f] vs exact [%.4f, %.4f]  max|diff| = %.5f",
      pair[1], r$lo, r$hi, b$HR_lo, b$HR_hi, max(abs(c(r$lo - b$HR_lo, r$hi - b$HR_hi)))))
}

g160 <- function(sp, tm) {
  r <- ct[spec == sp & term == tm]
  if (!nrow(r)) return(as.list(rep(NA_real_, 4)))
  list(HR = r$HR, lo = r$HR_lo, hi = r$HR_hi, P = r$p)
}
g134 <- function(ind, hr_col, p_col) {
  r <- iw[indicator == ind]; ci <- ci_from_p(r[[hr_col]], r[[p_col]])
  list(HR = r[[hr_col]], lo = ci$lo, hi = ci$hi, P = r[[p_col]])
}
g164 <- function(mod, tm) {
  r <- pp[model == mod & term == tm]
  if (!nrow(r)) return(as.list(rep(NA_real_, 4)))
  list(HR = r$HR, lo = r$lo, hi = r$hi, P = r$P)
}

row_of <- function(id, blk, proxy, base, definition, cl, ef, it, AIC, sdpy, why, mean_) {
  data.table(proxy_id = id, block = blk, proxy = proxy, temperature_indicator = base,
             definition = definition,
             HR_climate = cl$HR, lo_climate = cl$lo, hi_climate = cl$hi, P_climate = cl$P,
             HR_effort  = ef$HR, lo_effort  = ef$lo, hi_effort  = ef$hi, P_effort  = ef$P,
             HR_interaction = it$HR, lo_interaction = it$lo, hi_interaction = it$hi,
             P_interaction = it$P, AIC = AIC, sd_prov_year = sdpy,
             ecological_rationale = why, interpretation = mean_)
}

ALIGNED <- "A. Aligned comparison (identical row set, structure, effort proxy, offset, window)"
DIAG    <- "B. Mechanism diagnostic (different random structure; AIC not comparable with block A)"

A <- rbindlist(list(

row_of("P1", ALIGNED, "Thermal displacement, annual mean (MAIN MODEL)", "tavg_annual",
  "x = [T(p,t) - T_base(p)] - [N(s,t) - N_base(s)], 15-yr trailing mean",
  g160("S0_tavg_annual", "clim_change_z"), g160("S0_tavg_annual", "effort_z"),
  g160("S0_tavg_annual", "clim_change_z:effort_z"),
  ft[spec == "S0_tavg_annual"]$AIC, 0.804,
  paste("NOT a 'warmer is better' variable. It measures how far the target province's thermal",
        "conditions have moved relative to the species' OWN historical climate, so a positive",
        "value means the province has moved up relative to what that species was accustomed to.",
        "Its primary virtue is identifiability rather than mechanism: 39% of its variation is",
        "within province-years, i.e. purely between species, which is what allows it to be",
        "separated from the observation process. Absolute provincial warming (dT) has 0% within",
        "province-year variation and is therefore perfectly confounded with the province-year",
        "random intercept - it cannot be estimated in the main structure at all."),
  paste("HR 1.362 per 0.179 degC. Because a record requires both arrival and detection, this is",
        "the ecological factor multiplying the detection factor, not competing with it. The",
        "symmetry the variable imposes (beta_dT = -beta_dN) is rejected by the data (P1a, P1b):",
        "x should be read as an identifiable composite, not as a pure mechanism.")),

row_of("P2", ALIGNED, "Thermal displacement + heat-exposure moderation", "tavg_annual x tmax_warm",
  "P1 plus an interaction with accumulated heat exposure (P4)",
  g160("S4M_exposure_moderates", "clim_change_z"), g160("S4M_exposure_moderates", "effort_z"),
  g160("S4M_exposure_moderates", "clim_change_z:effort_z"),
  ft[spec == "S4M_exposure_moderates"]$AIC, 0.791,
  paste("This is where the 'track the climate to somewhere still suitable' expectation actually",
        "enters the model, and it enters as a BOUND rather than as a direction. Upward movement",
        "of a province's thermal conditions helps only while the province remains inside the",
        "conditions the species is known to occupy; once it has passed the warm end of them,",
        "further warming no longer opens a colonisation window."),
  paste("Climate HR is the warming effect at MEAN exposure. Moderation 0.906 (0.838-0.980,",
        "P = 0.014): warming multiplies the hazard by 1.508 at 1.5 SD below mean exposure and by",
        "1.123 (n.s.) at 1.5 SD above it. Best-fitting specification of the eight, and the only",
        "one that improves on the main model.")),

row_of("P3", ALIGNED, "Thermal displacement, warmest-month maximum", "tmax_warm",
  "Same construction as P1 on warmest-month maximum temperature",
  g134("tmax_warm", "HR_change", "P_change"), g134("tmax_warm", "HR_effort", "P_effort"),
  g134("tmax_warm", "HR_int", "P_int"), iw[indicator == "tmax_warm"]$AIC, 0.837,
  paste("A seasonal extreme constrains breeding heat load and water balance but does not describe",
        "the year-round envelope a range boundary sits in. It is the right variable for locating",
        "a province relative to a thermal limit (P4) and the wrong one for measuring how much a",
        "province has moved."),
  paste("Main effect survives (1.30); the climate x effort interaction vanishes. The interaction",
        "follows the underlying indicator rather than the transformation: present in all four",
        "proxies built on annual mean temperature, absent in both built on this one. Since the",
        "interaction is where the two processes stop being purely multiplicative, its absence",
        "here means this indicator's signal is spatially orthogonal to survey intensity.")),

row_of("P4", ALIGNED, "Heat exposure", "tmax_warm",
  "E = Tmax(p,t) - Tmax_base(s), 15-yr trailing mean; positive = past the warm end",
  g160("S4_heat_exposure", "clim_change_z"), g160("S4_heat_exposure", "effort_z"),
  g160("S4_heat_exposure", "clim_change_z:effort_z"),
  ft[spec == "S4_heat_exposure"]$AIC, 0.827,
  paste("A POSITION, not a rate of change: how far the destination now sits beyond the warm end",
        "of the species' historical envelope. This is the variable that expresses 'too hot to be",
        "suitable' directly."),
  paste("The only proxy with a negative main effect (0.823): the further past the warm end, the",
        "lower the hazard - consistent with unsuitability rather than with attraction. As a",
        "stand-alone climate term it fits poorly (dAIC 22.0) because a position carries no",
        "information about change. Its role is as the moderator in P2.")),

row_of("P5", ALIGNED, "Niche proximity, level", "tavg_annual",
  "-|T(p,t) - N(s,t)|, 15-yr trailing mean; 0 = province matches the range mean",
  g160("S2_niche_prox", "clim_change_z"), g160("S2_niche_prox", "effort_z"),
  g160("S2_niche_prox", "clim_change_z:effort_z"),
  ft[spec == "S2_niche_prox"]$AIC, 0.829,
  paste("Encodes a symmetric optimum: equally penalised for being colder or hotter than the",
        "species' range mean. This is the textbook unimodal niche expectation."),
  paste("No signal (0.943, P = 0.17); a quadratic term is also null (0.965, P = 0.34). Two",
        "reasons, and they matter for interpretation. First the constraint is one-sided, not",
        "symmetric - only the warm end binds (P4). Second, the range MEAN is not the niche",
        "centre: a province warmer than a species' range average may still lie well inside the",
        "range of conditions that species occupies, so |gap| mislabels it as unsuitable.")),

row_of("P6", ALIGNED, "Niche tracking, change", "tavg_annual",
  "-|T(p,t) - N(s,t)| + |T_base(p) - N_base(s)|, 15-yr trailing mean",
  g160("S3_niche_track", "clim_change_z"), g160("S3_niche_track", "effort_z"),
  g160("S3_niche_track", "clim_change_z:effort_z"),
  ft[spec == "S3_niche_track"]$AIC, 0.825,
  paste("The direct operationalisation of climate-niche tracking: does the province's climate",
        "converge on the conditions this species already experiences? Same series, same window",
        "and same construction as P1, differing ONLY in whether the response is assumed monotone",
        "or peaked, which makes the pair a clean test of that assumption."),
  paste("No signal (1.060, P = 0.17), dAIC 23.5, so convergence on the range mean does not",
        "predict where records appear. This does not refute niche tracking as a process; it",
        "shows that at provincial resolution over 23 years, tracking is not detectable as",
        "movement toward a range-mean temperature. Its positive interaction (1.120) reverses",
        "the sign of every other proxy and holds at only two of four windows; not interpreted.")),

row_of("P7", ALIGNED, "Thermal displacement, coldest-month minimum", "tmin_cold",
  "Same construction as P1 on coldest-month minimum temperature",
  g134("tmin_cold", "HR_change", "P_change"), g134("tmin_cold", "HR_effort", "P_effort"),
  g134("tmin_cold", "HR_int", "P_int"), iw[indicator == "tmin_cold"]$AIC, NA_real_,
  paste("Winter cold extremes set the overwintering limit for many resident and partially",
        "migratory birds and are the classic driver of poleward expansion in the",
        "northern-hemisphere literature."),
  paste("No signal here (1.077, P = 0.13). Chinese provincial records are generated across the",
        "whole latitudinal span rather than only at cold margins, so relaxation of a winter",
        "limit does not discriminate event from non-event cells.")),

row_of("P8", ALIGNED, "Thermal displacement, winter mean", "tavg_winter",
  "Same construction as P1 on winter mean temperature",
  g134("tavg_winter", "HR_change", "P_change"), g134("tavg_winter", "HR_effort", "P_effort"),
  g134("tavg_winter", "HR_int", "P_int"), iw[indicator == "tavg_winter"]$AIC, NA_real_,
  paste("A milder version of P7: mean winter conditions rather than the annual cold extreme,",
        "relevant to overwintering survival and passage timing."),
  paste("No signal (1.028, P = 0.58) and the worst fit of the eight. P7 and P8 together show the",
        "result is not a generic 'any warming' effect: it is specific to the year-round thermal",
        "regime, which is the scale at which a range boundary is set.")),

# ---- B. 机制诊断: 把 x 拆回两端 -------------------------------------------
row_of("P1a", DIAG, "Destination warming, dT (pull)", "tavg_annual",
  "dT(p,t) = T(p,t) - T_base(p), 15-yr trailing mean; entered jointly with dN",
  g164("M4", "dT_z"), g164("M4", "effort_z"), g164("M4", "dT_z:effort_z"),
  pp[model == "M4"]$AIC[1], NA_real_,
  paste("The pull end: the destination's own thermal conditions moving upward, making it",
        "occupiable. Not identifiable in the main structure because dT is constant within a",
        "province-year and so is perfectly confounded with the province-year random intercept;",
        "estimated here only after that level is dropped."),
  paste("HR 1.977 (1.656-2.359), by far the strongest climate effect in the study - but read it",
        "with the caveat that dropping the province-year level also lets dT absorb observation",
        "heterogeneity: survey effort falls from 1.404 to 1.145 (P = 0.069) in the same model.",
        "What is safe to conclude is the DIRECTION and the RANKING, not this magnitude.")),

row_of("P1b", DIAG, "Source warming, dN (push)", "tavg_annual",
  "dN(s,t) = N(s,t) - N_base(s), 15-yr trailing mean; entered jointly with dT",
  g164("M4", "dN_z"), g164("M4", "effort_z"), g164("M4", "dN_z:effort_z"),
  pp[model == "M4"]$AIC[1], NA_real_,
  paste("The push end: accumulated warming of the species' OWN range, which under a",
        "climate-tracking model should displace populations outward and raise the chance of",
        "appearing somewhere new."),
  paste("The push hypothesis is not supported. Entered alone in the main structure, source",
        "warming has no effect whatever (1.001, P = 0.99). Entered jointly with dT, its",
        "coefficient is significantly NEGATIVE (0.852, 0.753-0.963, P = 0.011). The symmetry",
        "that x imposes is rejected: freeing the two ends improves AIC by 34.9 under a common",
        "structure, and the two log-hazard-ratios differ by a factor of 4.2 (+0.681 vs -0.161).",
        "Records are generated where the destination has become occupiable, not where the",
        "source has become uncomfortable."))
))

A[, dAIC := ifelse(block == ALIGNED, AIC - AIC[proxy_id == "P1"], NA_real_)]
setcolorder(A, c("proxy_id", "block", "proxy", "temperature_indicator", "definition",
                 "HR_climate", "lo_climate", "hi_climate", "P_climate",
                 "HR_effort", "lo_effort", "hi_effort", "P_effort",
                 "HR_interaction", "lo_interaction", "hi_interaction", "P_interaction",
                 "AIC", "dAIC", "sd_prov_year"))
fwrite(A, file.path(TAB, "tbl_v2_climate_proxy_comparison.csv"))

fmt <- function(h, l, u, p) sprintf("%.3f [%.3f,%.3f] P=%s", h, l, u,
  ifelse(p < 1e-4, sprintf("%.0e", p), sprintf("%.3f", p)))
for (blk in unique(A$block)) {
  cat(sprintf("\n=== %s ===\n", blk))
  for (i in which(A$block == blk)) { r <- A[i]
    cat(sprintf("\n%-4s %s  [AIC %.1f%s]\n", r$proxy_id, r$proxy, r$AIC,
        if (is.na(r$dAIC)) "" else sprintf(", dAIC %+.1f", r$dAIC)))
    cat(sprintf("   climate     %s\n", fmt(r$HR_climate, r$lo_climate, r$hi_climate, r$P_climate)))
    cat(sprintf("   effort      %s\n", fmt(r$HR_effort, r$lo_effort, r$hi_effort, r$P_effort)))
    cat(sprintf("   interaction %s\n", fmt(r$HR_interaction, r$lo_interaction, r$hi_interaction, r$P_interaction)))
  }
}
AL <- A[block == ALIGNED]
cat(sprintf("\n努力主效应全距(A 组 8 个代理) / effort HR range: %.3f - %.3f (spread %.1f%%)\n",
    min(AL$HR_effort), max(AL$HR_effort), 100 * (max(AL$HR_effort) / min(AL$HR_effort) - 1)))
msg("wrote tbl_v2_climate_proxy_comparison.csv | DONE")
