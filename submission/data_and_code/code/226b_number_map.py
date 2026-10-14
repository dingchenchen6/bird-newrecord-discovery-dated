#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   无(核对步骤)。2024 年努力修正后, 文稿中每一个随之变化的数字由什么改为什么?
#   None (audit step): after the 2024 effort correction, what does every affected number in the
#   manuscripts change from and to?
#
# Objective / 分析目标:
#   每个数字用一个"短片段模板"表示(三刊正文、主稿与 SI 的措辞不同, 片段取各版共有的最短唯一写法),
#   同一模板分别用修正前快照与修正后结果填充: 旧片段必须至少在一份文稿中逐字出现, 才证明取数口径
#   与原文一致; 新片段即替换文本。旧文无法由数据复现(舍入笔误)或措辞须随新结果调整的条目列为
#   manual / computed, 写明理由。
#   Each number is a short phrase fragment shared across versions, filled from the snapshot and from
#   the corrected outputs. The old fragment must occur verbatim in at least one document, validating
#   the definition; the new fragment is the replacement. Entries whose old text is not reproducible
#   from the data (rounding slips) or whose wording must change are listed as manual or computed.
#
# Input data / 输入数据:
#   temp/snapshot_pre_effort2024_20261013/tables/*.csv(旧 / old), analysis_v2/tables/*.csv(新 / new)
#   analysis_v2/effort2024_audit/model_quantities.csv(226a)
#   logs/rerun2024/149.log(省级离散检验 P / province dispersion tests)
#   analysis_v2/figures_future/source_data_FigM4_mech_vs_ml_agreement_v2.csv(141)
#   文稿 / manuscripts: 见 DOCS / see DOCS
#
# Main workflow / 主要流程: 读取 → 填充模板 → 核对旧片段 → 写出映射表与报告
# Expected output / 预期输出: analysis_v2/effort2024_audit/number_map.csv, number_map_report.md
# Key assumptions / 关键假设: 修改时间早于重跑开始(2026-10-13 18:00)的结果表标记为 stale(尚未重算)
# Main packages / 主要包: 标准库 / standard library
# Output directory / 输出路径: analysis_v2/effort2024_audit/
#
# Usage: python3.11 code/226b_number_map.py
# ============================================================
from __future__ import annotations

import csv
import datetime as dt
import logging
import math
import os
import pathlib
import re

logging.basicConfig(level=logging.INFO, format="[226b] %(message)s")
logger = logging.getLogger(__name__)

V2 = pathlib.Path(__file__).resolve().parent.parent
A2 = V2 / "analysis_v2"
SUB = A2 / "submission"
# 旧侧默认为修正前快照; 增量更新时可用环境变量指向另一套结果表, 模型量取 new 列
# the old side defaults to the pre-correction snapshot; for incremental updates an env var can point it
# to another table set, with model quantities taken from the "new" column
OLD_T = pathlib.Path(os.environ.get("NUMBER_MAP_OLD_TABLES", V2 / "temp" / "snapshot_pre_effort2024_20261013" / "tables"))
OLD_MQ = os.environ.get("NUMBER_MAP_OLD_MQ", "old")
NEW_T = A2 / "tables"
AUD = A2 / "effort2024_audit"
RERUN_START = dt.datetime(2026, 10, 13, 18, 0).timestamp()
SUP = str.maketrans("0123456789-", "⁰¹²³⁴⁵⁶⁷⁸⁹⁻")
DOCS = [A2 / "docs/MANUSCRIPT_v2.md",
        *[SUB / j / f"Manuscript_{j}_maintext.md" for j in ("GCB", "NEE", "NC")],
        *[SUB / j / f"cover_letter_{j}.md" for j in ("GCB", "NEE", "NC")],
        SUB / "ReportingSummary_DRAFT_NatureFamily.md",
        SUB / "Manuscript_NatureFamily_maintext.md",
        SUB / "Manuscript_NatureFamily_tables_and_legends.md",
        *sorted((A2 / "docs").glob("*_MODULE.md"))]


# ---------------- 格式 / formatting ----------------
def f(x: float, d: int) -> str:
    """定点小数, 负号用真减号 / fixed decimals with a true minus sign."""
    return f"{x:.{d}f}".replace("-", "−")


def th(x: float) -> str:
    return f"{x:,.0f}"


def sci(p: float) -> str:
    """2.9 × 10⁻⁸ 形式 / scientific notation as used in the text."""
    e = math.floor(math.log10(p))
    m = round(p / 10 ** e, 1)
    if m >= 10:
        m, e = m / 10, e + 1
    return f"{m:.1f} × 10{str(e).translate(SUP)}"


def pfmt(p: float) -> str:
    """正文 P 值: < 0.01 用科学记数, 否则两位小数 / text style for P values."""
    return sci(p) if p < 0.01 else f(p, 2)


# ---------------- 数据读取 / data access ----------------
class Source:
    """一侧(旧或新)的全部取数入口 / every data access for one side (old or new)."""

    def __init__(self, side: str):
        self.side = side
        self.tdir = OLD_T if side == "old" else NEW_T
        mq = list(csv.DictReader((AUD / "model_quantities.csv").open(encoding="utf-8")))
        col = OLD_MQ if side == "old" else "new"
        self.mq = {r["item"]: float(r[col]) for r in mq}
        self.stale: set[str] = set()
        self.touched: set[str] = set()                 # 当前条目读过的表 / tables read by the current entry

    def t(self, name: str) -> list[dict]:
        p = self.tdir / name
        self.touched.add(name)
        if self.side == "new" and p.stat().st_mtime < RERUN_START:
            self.stale.add(name)
        with p.open(encoding="utf-8-sig") as fh:
            return list(csv.DictReader(fh))

    def row(self, name: str, **kw) -> dict:
        # 默认前缀匹配; 值以 "$" 结尾时精确匹配 / prefix match; a trailing "$" asks for an exact match
        ok = lambda r, k, v: str(r[k]) == v[:-1] if v.endswith("$") else str(r[k]).startswith(v)
        rows = [r for r in self.t(name) if all(ok(r, k, v) for k, v in kw.items())]
        if len(rows) != 1:
            raise KeyError(f"{name} {kw}: {len(rows)} rows")
        return rows[0]

    def num(self, name: str, col: str, **kw) -> float:
        return float(self.row(name, **kw)[col])

    # 常用组合 / frequently used quantities
    def null(self, nm: str, term: str, col: str = "null_median_HR") -> float:
        return self.num("tbl_null_models.csv", col, null_model=nm, term=term + "$")

    def boot(self, cluster: str, term: str) -> dict:
        return self.row("tbl_bootstrap_ci.csv", cluster=cluster, term=term + "$")

    def re_(self, s: str, col: str) -> float:
        return self.num("tbl_v2_re_evaluation.csv", col, structure=s)

    def dec(self, step: str, col: str) -> float:
        return self.num("tbl_change_decomposition.csv", col, step=step)

    def dsum(self, scope: str, null: str) -> dict:
        return self.row("tbl_v2_direction_geometric_null_summary.csv", scope=scope, null=null + "$")


# ---------------- 条目 / entries ----------------
ENTRIES: list[tuple[str, str, str, callable]] = []


def E(eid: str, src: str, tpl: str):
    """登记一个片段模板 / register a fragment template; the function returns its fields."""
    def deco(fn):
        ENTRIES.append((eid, src, tpl, fn))
        return fn
    return deco


# ---- A. 摘要与通用 / abstracts and general ----
@E("fold_visits", "effort panel: national visits 2022–24 / 2002–04, rounded to 5", "about {x}-fold")
def _(S):
    return {"x": str(int(round(S.mq["nat_fold_observed"] / 5) * 5))}


@E("cells", "model rows", "{n} species × province × year cells")
def _(S):
    return {"n": th(S.mq["n_rows"])}


@E("abs_warming", "fit_R3 Wald (2 dp)", "(hazard ratio {hr} per SD, 95% CI {lo}–{hi})")
def _(S):
    return {k: f(S.mq[f"{k}_change"], 2) for k in ("hr", "lo", "hi")}


@E("abs_effort", "fit_R3 Wald (2 dp)", "survey effort ({hr}, {lo}–{hi})")
def _(S):
    return {k: f(S.mq[f"{k}_effort"], 2) for k in ("hr", "lo", "hi")}


@E("abs_int", "fit_R3 Wald (2 dp)", "negatively ({hr}, {lo}–{hi})")
def _(S):
    return {k: f(S.mq[f"{k}_int"], 2) for k in ("hr", "lo", "hi")}


@E("abs_short", "fit_R3 (2 dp)", "per standard deviation) and survey effort ({e})")
def _(S):
    return {"e": f(S.mq["hr_effort"], 2)}


@E("abs_py", "fit_R3 province×year multiplier", "(×{m} per standard deviation)")
def _(S):
    return {"m": f(S.mq["mult_prov_year"], 2)}


@E("tv_short", "time-varying model (143 algorithm)", "fell from {a} in 2002 to {b} in 2024")
def _(S):
    return {"a": f(S.mq["tv_hr_2002"], 2), "b": f(S.mq["tv_hr_2024"], 2)}


@E("tv_short2", "time-varying model", "fell from {a} to {b} over two decades")
def _(S):
    return {"a": f(S.mq["tv_hr_2002"], 2), "b": f(S.mq["tv_hr_2024"], 2)}


@E("abs_nulls", "nulls N3 warming, N2 effort", "centred the warming estimate on {n3}, so the species-specific component is about {r}; the effort estimate fell to {n2}")
def _(S):
    n3 = S.null("N3", "clim_change_z")
    return {"n3": f(n3, 3), "r": f(S.mq["hr_change"] / n3, 2), "n2": f(S.null("N2", "effort_z"), 3)}


@E("abs_incr", "fit_R3 / N3 median", "an increment of about {r}")
def _(S):
    return {"r": f(S.mq["hr_change"] / S.null("N3", "clim_change_z"), 2)}


@E("ms_abs_r2", "re_evaluation R1/R3 (2 dp)", "and conditional *R*² from {a} to {b}")
def _(S):
    return {"a": f(S.re_("R1", "R2_conditional"), 2), "b": f(S.re_("R3", "R2_conditional"), 2)}


@E("ms_abs_null", "N3 warming median (2 dp)", "centred on {n} rather than unity")
def _(S):
    return {"n": f(S.null("N3", "clim_change_z"), 2)}


@E("ms_abs_eff", "N2 effort median (2 dp)", "collapses to {n} once")
def _(S):
    return {"n": f(S.null("N2", "effort_z"), 2)}


@E("ms_abs_p", "nulls P (warming N3, effort N2)", "outside their null distributions (*P* = {p})")
def _(S):
    return {"p": f(max(S.null("N3", "clim_change_z", "P_perm"), S.null("N2", "effort_z", "P_perm")), 3)}


# ---- B. 方法 / methods ----
@E("nat_means", "effort panel national means", "mean of {a} in 2002–2004 to {b} in 2022–2024")
def _(S):
    return {"a": th(S.mq["nat_0204_observed"]), "b": th(S.mq["nat_2224_observed"])}


@E("dropped", "nulls / bootstrap n_dropped", "({a} of 199 in N3; {b} of 300 in the species bootstrap")
def _(S):
    return {"a": f(S.null("N3", "clim_change_z", "n_dropped"), 0), "b": f(float(S.boot("species", "clim_change_z")["n_dropped"]), 0)}


@E("dropped_ed5", "nulls / bootstrap n_dropped", "their number is {a} of 199 in the third null, {b} of 300 in the species bootstrap")
def _(S):
    return {"a": f(S.null("N3", "clim_change_z", "n_dropped"), 0), "b": f(float(S.boot("species", "clim_change_z")["n_dropped"]), 0)}


# ---- C. 风险集与定年分解 / risk set and dating decomposition ----
@E("rows4", "model rows", "{n} rows, {e} events, {s} species and {p} provincial units")
def _(S):
    return {"n": th(S.mq["n_rows"]), "e": th(S.mq["n_events"]), "s": th(S.mq["n_species"]), "p": th(S.mq["n_prov"])}


@E("dec_effort", "decomposition S0/S1", "survey-effort hazard ratio from {a} to {b}")
def _(S):
    return {"a": f(S.dec("S0", "HR_effort"), 3), "b": f(S.dec("S1", "HR_effort"), 3)}


@E("dec_pct", "decomposition S0/S1", "publication-year estimate is {p}% larger")
def _(S):
    return {"p": f(100 * (S.dec("S0", "HR_effort") / S.dec("S1", "HR_effort") - 1), 0)}


@E("dec_warming", "decomposition S0/S1", "({a} → {b})")
def _(S):
    return {"a": f(S.dec("S0", "HR_change"), 3), "b": f(S.dec("S1", "HR_change"), 3)}


@E("dec_int2", "decomposition S0/S1 interaction", "({a} → {b}).")
def _(S):
    return {"a": f(S.dec("S0", "HR_int"), 3), "b": f(S.dec("S1", "HR_int"), 3)}


@E("dec_int3", "decomposition S0/S1 interaction", "({a} → {b}),")
def _(S):
    return {"a": f(S.dec("S0", "HR_int"), 3), "b": f(S.dec("S1", "HR_int"), 3)}


@E("dec_s3", "decomposition S3 − S2", "moves it by +{x}")
def _(S):
    return {"x": f(S.dec("S3", "HR_effort") - S.dec("S2", "HR_effort"), 3)}


@E("dec_s4", "decomposition S4 − S3", "restores +{x}")
def _(S):
    return {"x": f(S.dec("S4", "HR_effort") - S.dec("S3", "HR_effort"), 3)}


@E("dec_s5", "decomposition S4 − S5", "removes a further {x}")
def _(S):
    return {"x": f(S.dec("S4", "HR_effort") - S.dec("S5", "HR_effort"), 3)}


@E("dec_s2", "decomposition S2 − S1", "moves effort by {x}")
def _(S):
    return {"x": f(S.dec("S2", "HR_effort") - S.dec("S1", "HR_effort"), 3)}


# ---- D. 主模型、零模型、自然单位、重要性、随机结构 / main model, nulls, units, importance, RE ----
@E("main_warming", "fit_R3 Wald", "by {hr} (95% CI {lo}–{hi}; *P* = {p})")
def _(S):
    return {"hr": f(S.mq["hr_change"], 3), "lo": f(S.mq["lo_change"], 3), "hi": f(S.mq["hi_change"], 3), "p": pfmt(S.mq["p_change"])}


@E("main_effort", "fit_R3 Wald", "multiplies it by {hr} ({lo}–{hi}; *P* = {p})")
def _(S):
    return {"hr": f(S.mq["hr_effort"], 3), "lo": f(S.mq["lo_effort"], 3), "hi": f(S.mq["hi_effort"], 3), "p": pfmt(S.mq["p_effort"])}


@E("main_var", "fit_R3 Wald", "has no effect ({hr}, {lo}–{hi}; *P* = {p})")
def _(S):
    return {"hr": f(S.mq["hr_var"], 3), "lo": f(S.mq["lo_var"], 3), "hi": f(S.mq["hi_var"], 3), "p": pfmt(S.mq["p_var"])}


@E("main_int", "fit_R3 Wald", "negatively ({hr}, {lo}–{hi}; *P* = {p})")
def _(S):
    return {"hr": f(S.mq["hr_int"], 3), "lo": f(S.mq["lo_int"], 3), "hi": f(S.mq["hi_int"], 3), "p": pfmt(S.mq["p_int"])}


@E("null_obs", "fit_R3", "The observed {o} lies outside that null")
def _(S):
    return {"o": f(S.mq["hr_change"], 3)}


@E("null_p_both", "N1/N3 warming P", "(*P* = {p} for both)")
def _(S):
    return {"p": f(max(S.null(n, "clim_change_z", "P_perm") for n in ("N1", "N3")), 3)}


@E("null_p_both2", "N1/N3 warming P", "(*P* = {p} in both cases)")
def _(S):
    return {"p": f(max(S.null(n, "clim_change_z", "P_perm") for n in ("N1", "N3")), 3)}


@E("null_ratio", "fit_R3 / N3 median", "{o}/{n3} ≈ {r}")
def _(S):
    n3 = S.null("N3", "clim_change_z")
    return {"o": f(S.mq["hr_change"], 3), "n3": f(n3, 3), "r": f(S.mq["hr_change"] / n3, 2)}


@E("null_ratio_nee", "fit_R3 / N3 median", "the increment, about {r},")
def _(S):
    return {"r": f(S.mq["hr_change"] / S.null("N3", "clim_change_z"), 2)}


@E("null_eff1", "N2 effort median", "collapses its hazard ratio to {n}")
def _(S):
    return {"n": f(S.null("N2", "effort_z"), 3)}


@E("null_eff2", "N2 effort median", "collapses it to {n}")
def _(S):
    return {"n": f(S.null("N2", "effort_z"), 3)}


@E("boot_prov", "province cluster bootstrap", "to {cl}–{ch} for warming and {el}–{eh} for effort")
def _(S):
    c, e = S.boot("province", "clim_change_z"), S.boot("province", "effort_z")
    return {"cl": f(float(c["boot_lo"]), 2), "ch": f(float(c["boot_hi"]), 2), "el": f(float(e["boot_lo"]), 2), "eh": f(float(e["boot_hi"]), 2)}


@E("boot_int", "province cluster bootstrap (interaction)", "({a}–{b}). ")
def _(S):
    b = S.boot("province", "clim_change_z:effort_z")
    return {"a": f(float(b["boot_lo"]), 2), "b": f(float(b["boot_hi"]), 2)}


@E("boot_int2", "province cluster bootstrap (interaction)", "({a}–{b}).\n")
def _(S):
    b = S.boot("province", "clim_change_z:effort_z")
    return {"a": f(float(b["boot_lo"]), 2), "b": f(float(b["boot_hi"]), 2)}


@E("eff_fold", "effort panel exp(SD log1p visits)", "{x}-fold")
def _(S):
    return {"x": f(S.mq["eff_fold"], 2)}


@E("eff_median", "effort panel median × fold", "from a median of {m} visits per year to about {x}")
def _(S):
    m = S.mq["eff_median"]
    return {"m": f(m, 0) if abs(m - round(m)) < 1e-9 else f(m, 1), "x": f(S.mq["eff_median_x_fold"], 0)}


@E("imp_warming", "E importance", "Dropping accumulated warming costs {a} AIC units and {u} of marginal AUC")
def _(S):
    r = S.row("tbl_v2_E_importance.csv", term="accumulated")
    return {"a": f(float(r["dAIC"]), 1), "u": f(float(r["dAUCm"]), 3)}


@E("imp_effort", "E importance", "dropping survey effort costs {a} AIC units and {u} of marginal AUC")
def _(S):
    r = S.row("tbl_v2_E_importance.csv", term="survey")
    return {"a": f(float(r["dAIC"]), 1), "u": f(float(r["dAUCm"]), 3)}


@E("imp_int", "E importance", "The interaction costs {a} AIC units")
def _(S):
    return {"a": f(S.num("tbl_v2_E_importance.csv", "dAIC", term="climate"), 1)}


@E("ladder0", "D ladder F0", "{x} for the null model")
def _(S):
    return {"x": f(S.num("tbl_v2_D_ladder.csv", "AUC_marginal", model="F0"), 3)}


@E("re_r1r3", "re_evaluation R1/R3", "improves AIC by {d} units, raises conditional *R*² from {r1} to {r3}, raises conditional AUC from {a1} to {a3}, and raises the intraclass correlation from {i1} to {i3}")
def _(S):
    return {"d": f(S.re_("R1", "AIC") - S.re_("R3", "AIC"), 1), "r1": f(S.re_("R1", "R2_conditional"), 3),
            "r3": f(S.re_("R3", "R2_conditional"), 3), "a1": f(S.re_("R1", "AUC_conditional"), 3),
            "a3": f(S.re_("R3", "AUC_conditional"), 3), "i1": f(S.re_("R1", "ICC"), 3), "i3": f(S.re_("R3", "ICC"), 3)}


@E("re_aucm", "re_evaluation marginal AUC range", "all six structures ({a}–{b})")
def _(S):
    v = [float(r["AUC_marginal"]) for r in S.t("tbl_v2_re_evaluation.csv")]
    return {"a": f(min(v), 3), "b": f(max(v), 3)}


@E("re_r4", "re_evaluation R4 dAIC", "accumulated warming (ΔAIC {d}")
def _(S):
    return {"d": f(S.re_("R4", "dAIC"), 1)}


@E("re_r45_r2", "re_evaluation R4/R5/R3", "({r4} and {r5} respectively, against {r3}")
def _(S):
    return {"r4": f(S.re_("R4", "R2_conditional"), 3), "r5": f(S.re_("R5", "R2_conditional"), 3), "r3": f(S.re_("R3", "R2_conditional"), 3)}


@E("re_r45_fx", "re_evaluation R4/R5 HRs", "(effort {e4} and {e5}; warming {c4} and {c5}")
def _(S):
    return {"e4": f(S.re_("R4", "HR_effort"), 3), "e5": f(S.re_("R5", "HR_effort"), 3),
            "c4": f(S.re_("R4", "HR_change"), 3), "c5": f(S.re_("R5", "HR_change"), 3)}


@E("re_minsd", "re_evaluation min_re_sd", "(minimum standard deviation {m})")
def _(S):
    return {"m": f(min(float(r["min_re_sd"]) for r in S.t("tbl_v2_re_evaluation.csv")), 3)}


@E("sd_species", "fit_R3 VarCorr", "*Species (SD {s}).*")
def _(S):
    return {"s": f(S.mq["sd_species"], 3)}


@E("sd_province", "fit_R3 VarCorr", "*Province (SD {s}).*")
def _(S):
    return {"s": f(S.mq["sd_province"], 3)}


@E("sd_provyear", "fit_R3 VarCorr", "*Province by year (SD {s}).*")
def _(S):
    return {"s": f(S.mq["sd_prov_year"], 3)}


@E("py_mult1", "fit_R3 province×year multiplier", "by {m}, more than either fixed effect")
def _(S):
    return {"m": f(S.mq["mult_prov_year"], 2)}


@E("py_mult2", "fit_R3 province×year multiplier", "by {m} (more than either fixed effect)")
def _(S):
    return {"m": f(S.mq["mult_prov_year"], 2)}


@E("py_mult3", "fit_R3 province×year multiplier", "by {m}, more than either driver")
def _(S):
    return {"m": f(S.mq["mult_prov_year"], 2)}


@E("nee_re", "fit_R3 VarCorr", "standard deviations of {s1} for species, {s2} for province and {s3} for province by year, so one standard deviation multiplies the hazard by {m1}, {m2} and {m3} respectively")
def _(S):
    q = S.mq
    return {"s1": f(q["sd_species"], 3), "s2": f(q["sd_province"], 3), "s3": f(q["sd_prov_year"], 3),
            "m1": f(q["mult_species"], 2), "m2": f(q["mult_province"], 2), "m3": f(q["mult_prov_year"], 2)}


@E("latent", "fit_R3 VarCorr", "standard deviation {s} on the latent scale")
def _(S):
    return {"s": f(S.mq["sd_prov_year"], 3)}


@E("offset", "re_ladder R5 offset yes/no", "attenuates the effort coefficient from {a} to {b}")
def _(S):
    by = {r["offset"]: float(r["HR_effort"]) for r in S.t("tbl_v2_re_ladder.csv") if r["model"].startswith("R5")}
    return {"a": f(by["yes"], 3), "b": f(by["no"], 3)}


# 表 5(主稿压缩版生态学依据)/ Table 5, condensed rationale in the master
@E("t5_warming", "fit_R3, CC SD", "HR {c} per {sd} °C of province-minus-range warming")
def _(S):
    return {"c": f(S.mq["hr_change"], 3), "sd": f(S.mq["cc_sd"], 3)}


@E("t5_var", "fit_R3", "HR {v}: weather in the discovery year adds nothing")
def _(S):
    return {"v": f(S.mq["hr_var"], 3)}


@E("t5_effort", "fit_R3, effort fold", "HR {e} per 1 SD; one SD multiplies annual visits by {x}")
def _(S):
    return {"e": f(S.mq["hr_effort"], 3), "x": f(S.mq["eff_fold"], 2)}


@E("t5_int", "fit_R3", "HR {i}: warming matters most")
def _(S):
    return {"i": f(S.mq["hr_int"], 3)}


@E("t5_sp", "fit_R3", "(1\\|species), SD {s}")
def _(S):
    return {"s": f(S.mq["sd_species"], 3)}


@E("t5_pv", "fit_R3", "(1\\|province), SD {s}")
def _(S):
    return {"s": f(S.mq["sd_province"], 3)}


@E("t5_py", "fit_R3", "(1\\|province:year), SD {s}")
def _(S):
    return {"s": f(S.mq["sd_prov_year"], 3)}


@E("t5_pym", "fit_R3", "×{m} per SD, larger than either fixed effect")
def _(S):
    return {"m": f(S.mq["mult_prov_year"], 2)}


# ---- E. 迁徙、物种、省级 / migratory, species, province ----
@E("mig_rate", "model rows − known-strategy rows", "event rate is {u}%")
def _(S):
    rows = [r for r in S.t("tbl_v2_migratory_stratified.csv") if r["grouping"].startswith("three")]
    n = sum(float(r["n"]) for r in rows); e = sum(float(r["events"]) for r in rows)
    return {"u": f(100 * (S.mq["n_events"] - e) / (S.mq["n_rows"] - n), 3)}


@E("mig_partial", "stratified Partial event rate", "({p}% against {lo}–{hi}%)")
def _(S):
    rows = {r["group"]: 100 * float(r["events"]) / float(r["n"]) for r in S.t("tbl_v2_migratory_stratified.csv") if r["grouping"].startswith("three")}
    o = [v for k, v in rows.items() if not k.startswith("Partial")]
    return {"p": f(rows["Partial"], 3), "lo": f(min(o), 2), "hi": f(max(o), 2)}


@E("mig_lr", "migratory ladder LR P", "(*P* = {a}, {b}, {c} and {d}")
def _(S):
    g = lambda m: f(S.num("tbl_v2_migratory_ladder.csv", "LR_P", model=m), 3)
    return {"a": g("M2"), "b": g("M3"), "c": g("M4"), "d": g("M5")}


@E("mig_strat", "migratory stratified (three-level)", "{rc} (95% CI {rl}–{rh}) in residents, {pc} ({pl}–{ph}) in partial migrants and {lc} ({ll}–{lh}) in long-distance migrants")
def _(S):
    out = {}
    for k, grp in (("r", "Resident"), ("p", "Partial"), ("l", "Long")):
        r = S.row("tbl_v2_migratory_stratified.csv", grouping="three", group=grp)
        out[k + "c"] = f(float(r["HR_change"]), 3); out[k + "l"] = f(float(r["lo_change"]), 3); out[k + "h"] = f(float(r["hi_change"]), 3)
    return out


@E("mig_eff_gcb", "migratory stratified effort", "Survey effort does too ({a}, {b} and {c})")
def _(S):
    g = lambda grp: f(float(S.row("tbl_v2_migratory_stratified.csv", grouping="three", group=grp)["HR_effort"]), 3)
    return {"a": g("Resident"), "b": g("Partial"), "c": g("Long")}


@E("mig_eff_ms", "migratory stratified effort", "So does survey effort, at {a}, {b} and {c}")
def _(S):
    g = lambda grp: f(float(S.row("tbl_v2_migratory_stratified.csv", grouping="three", group=grp)["HR_effort"]), 3)
    return {"a": g("Resident"), "b": g("Partial"), "c": g("Long")}


@E("mig_int_long", "interaction by group", "long-distance migrants ({h}, {lo}–{hi}, *P* = {p})")
def _(S):
    r = S.row("tbl_v2_migratory_interaction_by_group.csv", group="Long")
    return {"h": f(float(r["HR_int"]), 3), "lo": f(float(r["lo"]), 3), "hi": f(float(r["hi"]), 3), "p": f"{float(r['P']):.2g}"}


@E("mig_int_res", "interaction by group", "residents ({h}, *P* = {p})")
def _(S):
    r = S.row("tbl_v2_migratory_interaction_by_group.csv", group="Resident")
    return {"h": f(float(r["HR_int"]), 3), "p": f(float(r["P"]), 2)}


@E("mig_int_par", "interaction by group", "partial migrants ({h}, *P* = {p})")
def _(S):
    r = S.row("tbl_v2_migratory_interaction_by_group.csv", group="Partial")
    return {"h": f(float(r["HR_int"]), 3), "p": f(float(r["P"]), 2)}


@E("mig_3way", "migratory ladder M5", "three-way likelihood-ratio test gives *P* = {p}")
def _(S):
    return {"p": f(S.num("tbl_v2_migratory_ladder.csv", "LR_P", model="M5"), 3)}


@E("mig_3way2", "migratory ladder M5", "three-way LR *P* = {p}")
def _(S):
    return {"p": f(S.num("tbl_v2_migratory_ladder.csv", "LR_P", model="M5"), 3)}


@E("prov_nb", "province models + 149 log", "is adequate ({d}, *P* = {p}, θ = {t})")
def _(S):
    r = S.row("tbl_v2_province_models.csv", model="Negative binomial (main)")
    p = 0.20 if S.side == "old" else float(re.search(r"负二项离散: 参数 =\s+[\d.]+\s+\| P =\s+([\d.]+)",
                                                     (V2 / "logs/rerun2024/149.log").read_text(encoding="utf-8")).group(1))
    return {"d": f(float(r["dispersion"]), 2), "p": f(p, 2), "t": f(float(r["theta"]), 2)}


@E("prov_rich", "province coefficients NB main", "(incidence rate ratio {i}, *P* = {p})")
def _(S):
    r = S.row("tbl_v2_province_coefficients.csv", model="NB main", term="z_richness")
    return {"i": f(float(r["IRR"]), 2), "p": f(float(r["p_value"]), 3)}


@E("prov_early", "province coefficients NB offset", "effort ({a}, *P* = {p})")
def _(S):
    r = S.row("tbl_v2_province_coefficients.csv", model="NB offset", term="z_early")
    return {"a": f(float(r["IRR"]), 2), "p": f(float(r["p_value"]), 3)}


@E("prov_gdp", "province coefficients NB offset", "GDP per capita ({b}, *P* = {p})")
def _(S):
    r = S.row("tbl_v2_province_coefficients.csv", model="NB offset", term="z_gdp")
    return {"b": f(float(r["IRR"]), 2), "p": f(float(r["p_value"]), 4)}


@E("prov_area", "province hierarchical partitioning", "{a}% to area")
def _(S):
    return {"a": f(S.num("tbl_v2_province_hp.csv", "pct_of_explained", predictor="z_area"), 1)}


def _dev(S):
    return 20.5 if S.side == "old" else float(re.search(r"全模型解释偏差 =\s+([\d.]+)",
                                                     (V2 / "logs/rerun2024/149.log").read_text(encoding="utf-8")).group(1))


@E("prov_dev1", "149 log", "model explains {d}%")
def _(S):
    return {"d": f(_dev(S), 1)}


@E("prov_dev2", "149 log", "model explaining {d}%")
def _(S):
    return {"d": f(_dev(S), 1)}


# ---- F. 方位 / direction ----
@E("dir_omni", "direction summary geometric_effort", "points north (χ² = {c}, *P* = {p})")
def _(S):
    r = S.dsum("Overall (records)", "geometric_effort")
    return {"c": f(float(r["chisq_vs_null"]), 1), "p": f(float(r["mc_p"]), 3)}


@E("dir_north", "direction summary geometric_effort", "northern sectors hold {o}% of records against {n}% expected")
def _(S):
    r = S.dsum("Overall (records)", "geometric_effort")
    return {"o": f(100 * float(r["obs_north3"]), 1), "n": f(100 * float(r["null_north3"]), 1)}


@E("dir_north2", "direction summary geometric_effort", "{o}% in the three northern sectors against {n}%")
def _(S):
    r = S.dsum("Overall (records)", "geometric_effort")
    return {"o": f(100 * float(r["obs_north3"]), 1), "n": f(100 * float(r["null_north3"]), 1)}


@E("dir_passer", "direction summary Passeriformes geometric_effort", "({o}% against {n}%")
def _(S):
    r = S.dsum("Passeriformes (records)", "geometric_effort")
    return {"o": f(100 * float(r["obs_north3"]), 1), "n": f(100 * float(r["null_north3"]), 1)}


@E("dir_pos", "direction summary *_pos", "(χ² = {a} and {b}")
def _(S):
    return {"a": f(float(S.dsum("Overall (records)", "geometric_pos")["chisq_vs_null"]), 1),
            "b": f(float(S.dsum("Overall (records)", "geometric_effort_pos")["chisq_vs_null"]), 1)}


# ---- G. 比例风险与时变 / proportional hazards and time variation ----
@E("ph_effort", "diagnostics PH effort", "β = {b}, *P* = {p}")
def _(S):
    r = S.row("tbl_v2_diagnostics.csv", test="proportional hazards: effort_z:year_c")
    return {"b": f(float(r["statistic"]), 3), "p": pfmt(float(r["p_value"]))}


@E("tv_model", "diagnostics time-varying model", "(effort {e}, warming {c}, variability {v}), and only the interaction loses significance ({i}, *P* = {p})")
def _(S):
    g = lambda k: S.row("tbl_v2_diagnostics.csv", test=f"time-varying model HR: {k}$")
    i = g("clim_change_z:effort_z")
    return {"e": f(float(g("effort_z")["statistic"]), 3), "c": f(float(g("clim_change_z")["statistic"]), 3),
            "v": f(float(g("clim_var_z")["statistic"]), 3), "i": f(float(i["statistic"]), 3), "p": f(float(i["p_value"]), 2)}


@E("fig6d", "diagnostics PH effort", "Wald *P* = {p}")
def _(S):
    return {"p": pfmt(S.num("tbl_v2_diagnostics.csv", "p_value", test="proportional hazards: effort_z:year_c"))}


# ---- H. 稳健性 / robustness ----
@E("thr_full", "C threshold", "changes the risk set from {n50} to {n200} rows but leaves the coefficients essentially fixed (effort {e1}, {e2}, {e3}; warming {c1}, {c2}, {c3}; interaction {i1}, {i2}, {i3})")
def _(S):
    rows = S.t("tbl_v2_C_threshold.csv")
    out = {"n50": th(float(rows[0]["n"])), "n200": th(float(rows[2]["n"]))}
    for k, col in (("e", "HR_effort"), ("c", "HR_change"), ("i", "HR_int")):
        for j in range(3):
            out[f"{k}{j + 1}"] = f(float(rows[j][col]), 3)
    return out


@E("thr_nee", "C threshold ranges", "to {n200} rows yet leaves the coefficients fixed (effort {ea}–{eb}; warming {ca}–{cb}; interaction {ia}–{ib})")
def _(S):
    rows = S.t("tbl_v2_C_threshold.csv")
    rng = lambda col: (min(float(r[col]) for r in rows), max(float(r[col]) for r in rows))
    e, c, i = rng("HR_effort"), rng("HR_change"), rng("HR_int")
    return {"n200": th(float(rows[2]["n"])), "ea": f(e[0], 3), "eb": f(e[1], 3), "ca": f(c[0], 3), "cb": f(c[1], 3),
            "ia": f(i[0], 3), "ib": f(i[1], 3)}


@E("ind_tmax", "indicator window", "(hazard ratio {hr}, ΔAIC {d} behind the best cell)")
def _(S):
    b = min((r for r in S.t("tbl_v2_indicator_window.csv") if r["indicator"] == "tmax_warm"), key=lambda r: float(r["dAIC"]))
    return {"hr": f(float(b["HR_change"]), 2), "d": f(float(b["dAIC"]), 1)}


@E("ind_cold", "indicator window", "(hazard ratios {lo}–{hi}, all *P* > {p})")
def _(S):
    rows = [r for r in S.t("tbl_v2_indicator_window.csv") if r["indicator"] in ("tmin_cold", "tavg_winter")]
    hr = [float(r["HR_change"]) for r in rows]; p = min(float(r["P_change"]) for r in rows)
    return {"lo": f(min(hr), 2), "hi": f(max(hr), 2), "p": f(math.floor(p * 100) / 100, 2)}


@E("win_w20", "baseline sensitivity W = 20", "to {a}–{b} at twenty")
def _(S):
    v = [float(r["HR_change"]) for r in S.t("tbl_v2_baseline_sensitivity.csv") if r["window"] == "20"]
    return {"a": f(min(v), 2), "b": f(max(v), 2)}


@E("win_d15", "baseline sensitivity dAIC at W = 15", "within {a}–{b} AIC units of")
def _(S):
    v = [float(r["dAIC"]) for r in S.t("tbl_v2_baseline_sensitivity.csv") if r["window"] == "15"]
    return {"a": f(min(v), 1), "b": f(max(v), 1)}


@E("win_flat", "baseline sensitivity effort range", "flat at {a}–{b}")
def _(S):
    v = [float(r["HR_effort"]) for r in S.t("tbl_v2_baseline_sensitivity.csv")]
    return {"a": f(min(v), 2), "b": f(max(v), 2)}


@E("win_int", "baseline sensitivity interaction range", "({a}–{b})")
def _(S):
    v = [float(r["HR_int"]) for r in S.t("tbl_v2_baseline_sensitivity.csv")]
    return {"a": f(min(v), 2), "b": f(max(v), 2)}


def _w15(S):
    return {(r["source"][:3], r["baseline"]): float(r["HR_change"])
            for r in S.t("tbl_v2_baseline_sensitivity.csv") if r["window"] == "15"}


@E("cru70", "baseline sensitivity W = 15", "{a} under CRU 1970–2000")
def _(S):
    return {"a": f(_w15(S)[("CRU", "1970-2000")], 3)}


@E("cru80", "baseline sensitivity W = 15", "{b} under CRU 1980–2000")
def _(S):
    return {"b": f(_w15(S)[("CRU", "1980-2000")], 3)}


@E("cru_main", "fit_R3", "main estimate ({m})")
def _(S):
    return {"m": f(S.mq["hr_change"], 3)}


@E("cru_main2", "fit_R3", "estimate of {m} sits between")
def _(S):
    return {"m": f(S.mq["hr_change"], 3)}


@E("cru_src", "fit_R3 / CRU 1980–2000", "({m} to {b})")
def _(S):
    return {"m": f(S.mq["hr_change"], 3), "b": f(_w15(S)[("CRU", "1980-2000")], 3)}


# ---- I. 诊断与重抽样 / diagnostics and resampling ----
@E("ks", "diagnostics", "Kolmogorov–Smirnov *P* = {k}")
def _(S):
    return {"k": f(S.num("tbl_v2_diagnostics.csv", "p_value", test="KS"), 2)}


@E("disp", "diagnostics", "dispersion is correct (*P* = {d})")
def _(S):
    return {"d": f(S.num("tbl_v2_diagnostics.csv", "p_value", test="dispersion"), 2)}


@E("zi", "diagnostics", "no zero inflation (*P* = {z})")
def _(S):
    return {"z": f(S.num("tbl_v2_diagnostics.csv", "p_value", test="zero"), 2)}


@E("moran", "diagnostics", "Moran's *I* = {i}")
def _(S):
    return {"i": f(S.num("tbl_v2_diagnostics.csv", "statistic", test="Moran"), 3)}


@E("moran_p", "diagnostics", "permutation *P* = {p})")
def _(S):
    return {"p": f(S.num("tbl_v2_diagnostics.csv", "p_value", test="Moran"), 2)}


@E("outliers", "diagnostics", "({n} outliers")
def _(S):
    return {"n": f(S.num("tbl_v2_diagnostics.csv", "statistic", test="outliers"), 0)}


@E("se_prov", "bootstrap se_ratio province", "{a}–{b}-fold and species")
def _(S):
    v = [float(r["se_ratio"]) for r in S.t("tbl_bootstrap_ci.csv") if r["cluster"] == "province"]
    return {"a": f(min(v), 2), "b": f(max(v), 2)}


@E("se_prov2", "bootstrap se_ratio province", "by a factor of {a}–{b}")
def _(S):
    v = [float(r["se_ratio"]) for r in S.t("tbl_bootstrap_ci.csv") if r["cluster"] == "province"]
    return {"a": f(min(v), 2), "b": f(max(v), 2)}


@E("se_sp", "bootstrap se_ratio species", "does not ({a}–{b})")
def _(S):
    v = [float(r["se_ratio"]) for r in S.t("tbl_bootstrap_ci.csv") if r["cluster"] == "species"]
    return {"a": f(min(v), 2), "b": f(max(v), 2)}


@E("param", "parametric bootstrap coverage", "coverage of {a}–{b}%")
def _(S):
    v = [100 * float(r["coverage_95"]) for r in S.t("tbl_parametric_bootstrap.csv")]
    return {"a": f(min(v), 1), "b": f(max(v), 1)}


@E("loo", "influence LOO max |relative change|", "at most {m}%")
def _(S):
    terms = ["clim_change_z", "effort_z", "clim_var_z", "clim_change_z:effort_z"]
    return {"m": f(100 * max(abs(float(r["d_" + t])) for r in S.t("tbl_influence_loo.csv") for t in terms), 1)}


@E("loo_k", "influence LOO count > 3%", "with {k} of 164 combinations exceeding 3%")
def _(S):
    terms = ["clim_change_z", "effort_z", "clim_var_z", "clim_change_z:effort_z"]
    return {"k": str(sum(abs(float(r["d_" + t])) > 0.03 for r in S.t("tbl_influence_loo.csv") for t in terms))}


@E("disc_hr", "fit_R3 (2 dp)", "(hazard ratios {c} and {e})")
def _(S):
    return {"c": f(S.mq["hr_change"], 2), "e": f(S.mq["hr_effort"], 2)}


@E("disc_null", "N3 warming median (2 dp)", "return a hazard ratio of about {n}")
def _(S):
    return {"n": f(S.null("N3", "clim_change_z"), 2)}


@E("disc_null_nee", "N3 warming median", "centre on {n}")
def _(S):
    return {"n": f(S.null("N3", "clim_change_z"), 3)}


@E("disc_tv", "time-varying model", "had fallen to {b} by 2024")
def _(S):
    return {"b": f(S.mq["tv_hr_2024"], 2)}


@E("ed5_null", "N3 warming median (2 dp)", "centred near {n} rather than unity")
def _(S):
    return {"n": f(S.null("N3", "clim_change_z"), 2)}


# ---- J. 情景网格与多模型(187、188)/ scenario grid and model families (187, 188) ----
def _grid(S: Source, name: str = "tbl_future_scenario_grid.csv", fam: str | None = None) -> dict:
    """全国合计与支撑域比例; 努力情景标签中英文均可 / national totals and support, either label language."""
    out: dict = {}
    for r in S.t(name):
        if fam and r.get("fam") != fam:
            continue
        e = "frozen" if ("frozen" in r["eff"] or "停滞" in r["eff"]) else "growing"
        k = (r["ssp"], e, r["horizon"])
        a = out.setdefault(k, [0.0, 0.0, 0.0])
        a[0] += float(r["exp_n"])
        if "n_sp" in r:
            a[1] += float(r["pct_sup"]) * float(r["n_sp"]); a[2] += float(r["n_sp"])
    return out


@E("grid_frozen", "scenario grid (frozen effort)", "{a} versus {b} first records per year in 2030; {c} versus {d} in 2050")
def _(S):
    g = _grid(S)
    return {"a": f(g[("ssp245", "frozen", "2030")][0], 1), "b": f(g[("ssp585", "frozen", "2030")][0], 1),
            "c": f(g[("ssp245", "frozen", "2050")][0], 1), "d": f(g[("ssp585", "frozen", "2050")][0], 1)}


@E("grid_frozen2", "scenario grid (frozen effort)", "({a} versus {b} per year in 2030)")
def _(S):
    g = _grid(S)
    return {"a": f(g[("ssp245", "frozen", "2030")][0], 1), "b": f(g[("ssp585", "frozen", "2030")][0], 1)}


@E("grid_growing", "scenario grid (growing effort, 2050)", "to {lo}–{hi} records per year")
def _(S):
    g = _grid(S); v = [g[(s, "growing", "2050")][0] for s in ("ssp245", "ssp585")]
    return {"lo": f(min(v), 0), "hi": f(max(v), 0)}


@E("grid_nc", "scenario grid", "from {a} to {lo}–{hi}, with")
def _(S):
    g = _grid(S); v = [g[(s, "growing", "2050")][0] for s in ("ssp245", "ssp585")]
    return {"a": f(g[("ssp245", "frozen", "2050")][0], 1), "lo": f(min(v), 0), "hi": f(max(v), 0)}


@E("grid_sup_frozen", "scenario grid support (frozen, 2050)", "{lo}–{hi}% under frozen effort")
def _(S):
    g = _grid(S); v = [100 * g[(s, "frozen", "2050")][1] / g[(s, "frozen", "2050")][2] for s in ("ssp245", "ssp585")]
    return {"lo": f(min(v), 0), "hi": f(max(v), 0)}


@E("mm_mech", "multimodel grid mech, SSP2-4.5 growing 2050", "{m} records per year")
def _(S):
    return {"m": f(_grid(S, "tbl_future_multimodel_grid.csv", "mech")[("ssp245", "growing", "2050")][0], 1)}


@E("mm_rf_xgb", "multimodel grid rf/xgb, SSP2-4.5 growing 2050", "at {r} and XGBoost falls to {x}")
def _(S):
    return {"r": f(_grid(S, "tbl_future_multimodel_grid.csv", "rf")[("ssp245", "growing", "2050")][0], 1),
            "x": f(_grid(S, "tbl_future_multimodel_grid.csv", "xgb")[("ssp245", "growing", "2050")][0], 1)}


# ---------------- 手工条目 / manual entries ----------------
MANUAL = [
    ("window_w5", "1.16–1.21 at five years", "1.16–1.22 at five years",
     "旧文 1.16 为舍入笔误(实为 1.1548→1.15); 新值 1.1616–1.2177 / old text had a rounding slip"),
    ("b_effort_ranges", "between 1.25 and 1.52 and warming hazard ratios between 1.35 and 1.37",
     "between 1.25 and 1.55 and warming hazard ratios between 1.33 and 1.39",
     "用户同意一并更正的旧文错误(旧表实为 1.33–1.38)/ the text error the user agreed to correct"),
    ("b_effort_ranges_nee", "give effort 1.25–1.52 and warming 1.35–1.37", "give effort 1.25–1.55 and warming 1.33–1.39",
     "同上, NEE 措辞 / as above, NEE wording"),
    ("window_within", "is within 0.001 of the former", "differs from the former by 0.001", "新差值 0.0012 / new difference 0.0012"),
    ("ms_int_range", "negative throughout (0.87–1.00", "negative throughout (0.82–0.96",
     "主稿旧值与旧表(0.82–1.00)不一致, 按新表改 / master disagreed with its own table"),
    ("diag_levels", "Two of 23 year levels and two of 31 province levels",
     "None of 23 year levels and three of 31 province levels", "tbl_v2_diagnostics 0/23, 3/31"),
    ("ph_warming", "β = −0.022, *P* = 0.82", "β < 0.001, *P* = 1.00", "tbl_v2_diagnostics β = 0.00023, P = 0.998"),
    ("tv_full", "its hazard ratio falls from 2.18 (95% CI 1.63–2.90) in 2002 to 1.07 (0.88–1.30) in 2024",
     "its hazard ratio falls from 2.14 (95% CI 1.61–2.85) in 2002 to 1.13 (0.93–1.37) in 2024",
     "旧文区间为截断而非四舍五入(旧值 1.638–2.907、0.880–1.310); 新值四舍五入 / old CIs were truncated"),
    ("prov_disp", "(dispersion 5.60, *P* = 2.3 × 10⁻¹⁷)", "(dispersion 5.59, *P* = 2.8 × 10⁻¹⁷)", "149 log"),
    ("dir_sectors",
     "Records fall to the northeast (179 against 153.2 expected) and northwest (31 against 17.9) more often, and to the east (237 against 263.9) and south (20 against 32.1) less often, than the distribution of survey effort predicts (Holm-adjusted *P* = 0.016–0.036)",
     "Records fall to the northeast (179 against 151.8 expected) and northwest (31 against 17.7) more often, and to the east (237 against 264.3) less often, than the distribution of survey effort predicts (Holm-adjusted *P* = 0.016–0.024); the southern deficit (20 against 32.4) is marginal (Holm-adjusted *P* = 0.050)",
     "南向 Holm P 由 0.036 变为 0.050 / south sector no longer below 0.05 after Holm correction"),
    ("dir_sectors_nee",
     "records fall to the northeast and northwest more often, and to the east and south less often, than the distribution of observers predicts (Holm-adjusted *P* = 0.016–0.036)",
     "records fall to the northeast and northwest more often, and to the east less often, than the distribution of observers predicts (Holm-adjusted *P* = 0.016–0.024; the southern deficit is marginal, *P* = 0.050)",
     "NEE 措辞 / NEE wording"),
    ("pace", "(observed pace 1.19)", "(observed pace 1.22)",
     "省均努力指数 2022–2024 均值减 2002–2004 均值, 除以 2 个十年(旧 1.194 → 新 1.217)"),
    ("mig_levels", "689 province-year levels", "688 province-year levels", "fit_mig_3way 的省×年水平数 / levels in the 3-way fit"),
    ("mig_contrast", "long-distance-versus-resident contrast *P* = 0.078", "long-distance-versus-resident contrast *P* = 0.079",
     "fit_mig_3way: 0.0782 → 0.0793"),
    ("ed8_rate", "event rate 0.369%", "event rate 0.370%", "649 / 175,640"),
]


# ---------------- 计算型手工条目(投影)/ computed manual entries (projections) ----------------
def _proj(S: Source) -> dict:
    sup = {(r["ssp"], r["horizon"]): (int(r["in_support"]), int(r["rows"])) for r in S.t("tbl_v2_future_support.csv")}
    pr = [r for r in S.t("tbl_v2_future_province_projection.csv") if r["scope"] == "all rows"]
    ps = [r for r in S.t("tbl_v2_future_province_projection.csv") if r["scope"] == "within covariate support"]
    agree = [((float(r["mech_ratio"]) > 1) == (float(r["ml_ratio"]) > 1)) for r in pr]
    a80 = [((float(r["mech_ratio"]) > 1) == (float(r["ml_ratio"]) > 1)) for r in pr if r["ssp"] == "ssp585" and r["horizon"] == "2080"]
    src = list(csv.DictReader((A2 / "figures_future/source_data_FigM4_mech_vs_ml_agreement_v2.csv").open(encoding="utf-8")))
    rho_in = float(next(r for r in src if r["panel"] == "a")["rho"])
    rho_b = [float(r["rho"]) for r in src if r["panel"] == "b"]
    return {"sup": sup, "ratio_in": (min(float(r["mech_ratio"]) for r in ps), max(float(r["mech_ratio"]) for r in ps)),
            "ratio_all": max(float(r["mech_ratio"]) for r in pr), "agree": 100 * sum(agree) / len(agree),
            "agree80": 100 * sum(a80) / len(a80), "rho_in": rho_in, "rho_b": (min(rho_b), max(rho_b)),
            "mech_up": sum(float(r["mech_ratio"]) > 1 for r in pr), "ml_up": sum(float(r["ml_ratio"]) > 1 for r in pr), "n": len(pr)}


def pct_or_none(k: int, n: int) -> str:
    return "none" if k == 0 else f"{100 * k / n:.1f}%"


def ssp585_clause(s: dict, style: str) -> str:
    """SSP5-8.5 的三期比例; 后两期均为零时合并为 "none thereafter" / merge trailing zeros."""
    a, b, c = (pct_or_none(*s[("ssp585", h)]) for h in ("2030", "2050", "2080"))
    if b == c == "none":
        return (f"under SSP5-8.5, {a} in 2030 and none thereafter" if style == "gcb"
                else f"{a} in 2030 and none thereafter under SSP5-8.5")
    return (f"under SSP5-8.5 the corresponding figures are {a}, {b} and {c}" if style == "gcb"
            else f"{a}, {b} and {c} under SSP5-8.5")


def _ml_prauc(S: Source) -> str:
    rf = {(r["scheme"], r["model"]): float(r["prauc"]) for r in S.t("tbl_rf_province_summary.csv")}
    xg = {(r["scheme"], r["model"]): float(r["prauc"]) for r in S.t("tbl_xgb_province_summary.csv")}
    g = lambda d, sc, m: f(d[(sc, m)], 4)
    return (f"(PR-AUC {g(rf, 'leave_species', '随机森林(类平衡)')} and {g(xg, 'leave_species', 'XGBoost(类平衡)')} versus "
            f"{g(rf, 'leave_species', '离散风险模型(边际)')}) but fall behind it on temporal forward-prediction "
            f"({g(rf, 'temporal', '随机森林(类平衡)')} and {g(xg, 'temporal', 'XGBoost(类平衡)')} versus "
            f"{g(rf, 'temporal', '离散风险模型(边际)')})")


def _grid_wording(news: Source) -> list[tuple[str, str, str, str]]:
    g = _grid(news)
    sup = [100 * g[(s, "growing", "2050")][1] / g[(s, "growing", "2050")][2] for s in ("ssp245", "ssp585")]
    none = max(sup) < 0.05
    fold = g[("ssp245", "growing", "2050")][0] / g[("ssp245", "frozen", "2050")][0]
    fold_w = "roughly triples" if 2.5 <= fold < 3.5 else ("more than doubles" if fold >= 2 else "raises")
    base = float(__import__("re").search(r"全国合计[^:]*:\s*([\d.]+)", (V2 / "logs/rerun2024/188.log").read_text(encoding="utf-8")).group(1))
    rho = [float(r["rho"]) for r in csv.DictReader((NEW_T / "tbl_multiscale_surface_rho.csv").open(encoding="utf-8"))] \
        if (NEW_T / "tbl_multiscale_surface_rho.csv").exists() else None
    out = [
        ("grid_sup_gcb", "with only 2% of species–province cells still inside the fitted support",
         "with no species–province cell left inside the fitted support" if none else
         f"with only {max(sup):.0f}% of species–province cells still inside the fitted support", "scenario grid support"),
        ("grid_sup_ms", "but only 2% of species–province cells then remain inside the fitted covariate support",
         "but no species–province cell then remains inside the fitted covariate support" if none else
         f"but only {max(sup):.0f}% of species–province cells then remain inside the fitted covariate support", "scenario grid support"),
        ("grid_sup_nc", "with only 2% of cells still in support", "with no cells left in support" if none else
         f"with only {max(sup):.0f}% of cells still in support", "scenario grid support"),
        ("grid_nee", "continued effort growth more than doubles it by 2050, almost entirely outside the fitted support",
         f"continued effort growth {fold_w} it by 2050, " + ("entirely outside the fitted support" if none else
                                                         "almost entirely outside the fitted support"), f"fold {fold:.2f}"),
        ("mm_base", "(22.4 records per year)", f"({base:.1f} records per year)", "188 log: calibrated 2024 national total"),
    ]
    if rho:
        out.append(("mm_rho", "0.62–0.90", f"{min(rho):.2f}–{max(rho):.2f}", "tbl_multiscale_surface_rho (185)"))
    # 两种置换的增温零分布中位数; 两位小数相同时写 "about x" / both null medians, merged when equal at 2 dp
    if "tbl_null_models.csv" not in news.stale:
        v = sorted(news.null(n, "clim_change_z") for n in ("N1", "N3"))
        txt = f"about {v[0]:.2f}" if f"{v[0]:.2f}" == f"{v[1]:.2f}" else f"{v[0]:.3f}–{v[1]:.3f}"
        out.append(("null_range", "1.157–1.167, because both permutations", f"{txt}, because both permutations",
                    "N1/N3 warming null medians"))
    return out


def computed(news: Source) -> list[tuple[str, str, str, str]]:
    p = _proj(news); s = p["sup"]
    v = lambda ssp, h: pct_or_none(*s[(ssp, h)])
    out = [
        ("sup_gcb",
         "only 47.8% of species-province cells fall inside the fitted covariate support under SSP2-4.5 in 2030, 10.4% in 2050 and 2.1% in 2080; under SSP5-8.5 the corresponding figures are 34.2%, 2.1% and 1.9%",
         f"only {v('ssp245', '2030')} of species-province cells fall inside the fitted covariate support under SSP2-4.5 in 2030, "
         f"{v('ssp245', '2050')} in 2050 and {v('ssp245', '2080')} in 2080; {ssp585_clause(s, 'gcb')}", "tbl_v2_future_support"),
        ("sup_nee",
         "only 47.8% of species-province cells fall inside the fitted covariate support under SSP2-4.5 in 2030, 10.4% in 2050 and 2.1% in 2080 (34.2%, 2.1% and 1.9% under SSP5-8.5)",
         f"only {v('ssp245', '2030')} of species-province cells fall inside the fitted covariate support under SSP2-4.5 in 2030, "
         f"{v('ssp245', '2050')} in 2050 and {v('ssp245', '2080')} in 2080 ({ssp585_clause(s, 'nee')})", "tbl_v2_future_support"),
        ("ratio_in", "of 0.79 to 2.94", f"of {p['ratio_in'][0]:.2f} to {p['ratio_in'][1]:.2f}", "projection within support"),
        ("ratio_in_nee", "of 0.79–2.94", f"of {p['ratio_in'][0]:.2f}–{p['ratio_in'][1]:.2f}", "projection within support"),
        ("ratio_all", "up to 78", f"up to {p['ratio_all']:.0f}", "projection all rows"),
        ("rho_in", "Spearman ρ = 0.54", f"Spearman ρ = {p['rho_in']:.2f}", "FigM4 source data panel a"),
        ("agree_gcb", "in only 23.7% of cells, falling to 6.5% under SSP5-8.5 in 2080",
         f"in only {p['agree']:.1f}% of cells, " + ("and in none under SSP5-8.5 in 2080" if p["agree80"] == 0
                                                     else f"falling to {p['agree80']:.1f}% under SSP5-8.5 in 2080"),
         "province × scenario cells, pooled"),
        ("agree_nee", "agreeing on direction in only 23.7% of cells", f"agreeing on direction in only {p['agree']:.1f}% of cells", "pooled"),
        ("ms_rho_b", "Outside it they diverge completely: rank correlations across province-scenario cells range from −0.04 to 0.18, and the two agree",
         f"Outside it they diverge: rank correlations across province-scenario cells range from {p['rho_b'][0]:.2f} to {p['rho_b'][1]:.2f}, but the two agree",
         "FigM4 panel b"),
        ("ms_updown", "The mechanistic model projects increases in 176 of 186 cells; the machine-learning model in 42.",
         f"The mechanistic model projects increases in {p['mech_up']} of {p['n']} cells; the machine-learning model in {p['ml_up']}.", "projection"),
        ("disc_support", "late-century scenarios push about 98% of species–province cells outside the fitted support, where the mechanistic and machine-learning models agree on the direction of change in fewer than a quarter of cells",
         "late-century scenarios push all species–province cells outside the fitted support, where the mechanistic and machine-learning models agree on the direction of change in fewer than one cell in ten",
         "2080 support none; agreement pooled"),
        ("disc_support_nee", "By 2080 about 98% of species–province cells lie outside the fitted support, where mechanistic and machine-learning models agree on the direction of change in fewer than a quarter of cells",
         "By 2080 every species–province cell lies outside the fitted support, where mechanistic and machine-learning models agree on the direction of change in fewer than one cell in ten",
         "2080 support none"),
        ("ms_disc1", "fewer than one in fifty species-province cells then resembles anything in the fitted data",
         "virtually no species-province cell then resembles anything in the fitted data", "2080 support none"),
        ("ml_prauc", "(PR-AUC 0.0120 and 0.0118 versus 0.0054) but fall behind it on temporal forward-prediction (0.0067 and 0.0072 versus 0.0098)",
         _ml_prauc(news), "旧文为截断值(0.01205→0.0120)/ the old text truncated"),
        ("ms_disc2", "disagree on the direction of change in three quarters of cells",
         "disagree on the direction of change in more than nine cells in ten", f"agreement {p['agree']:.1f}%"),
    ]
    return out + _grid_wording(news)


def main() -> None:
    texts = {d: d.read_text(encoding="utf-8") for d in DOCS if d.exists()}
    olds, news = Source("old"), Source("new")
    out, bad = [], []
    for eid, src, tpl, fn in ENTRIES:
        news.touched = set()
        try:
            o = tpl.format(**fn(olds)); n = tpl.format(**fn(news))
        except (KeyError, ValueError, IndexError, FileNotFoundError, StopIteration) as e:
            o = n = f"<error: {e}>"
        hits = {d.name: t.count(o) for d, t in texts.items() if t.count(o)}
        if not hits:
            bad.append(eid)
        # 依赖尚未重算的表时暂缓, 以免写入半新半旧的片段 / defer entries that read stale tables
        deferred = "yes" if news.touched & news.stale else "no"
        out.append([eid, "template", o, n, "yes" if o != n else "no", sum(hits.values()),
                    "; ".join(f"{k}:{v}" for k, v in hits.items()), src, deferred])
    for eid, o, n, note in MANUAL + computed(news):
        deferred = "no"
        hits = {d.name: t.count(o) for d, t in texts.items() if t.count(o)}
        if not hits:
            bad.append(eid)
        out.append([eid, "manual", o, n, "yes" if o != n else "no", sum(hits.values()),
                    "; ".join(f"{k}:{v}" for k, v in hits.items()), note, deferred])
    for b in bad:
        logger.warning("旧片段未在任何文稿中找到 / old fragment not found: %s", b)
    with (AUD / "number_map.csv").open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["id", "kind", "old", "new", "changed", "hits", "hits_by_doc", "source", "deferred"])
        w.writerows(out)
    stale = sorted(news.stale)
    lines = ["# 文稿数字新旧映射 / Number map for the manuscripts", "",
             f"条目 {len(out)};变化 {sum(r[4] == 'yes' for r in out)};旧片段未命中 {len(bad)}。"
             f"尚未重算的结果表:{', '.join(stale) if stale else '无 / none'}。", "",
             "| id | 类型 | 变化 | 命中 | 旧 → 新 |", "|---|---|---|---|---|"]
    lines += [f"| {r[0]} | {r[1]} | {r[4]} | {r[6]} | {r[2]} → **{r[3]}** |" for r in out]
    (AUD / "number_map_report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    logger.info("条目 %d;变化 %d;未命中 %d;尚未重算 %s", len(out), sum(r[4] == "yes" for r in out), len(bad), stale or "无")


if __name__ == "__main__":
    main()
