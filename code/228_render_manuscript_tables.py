#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   无(改稿步骤)。主稿 MANUSCRIPT_v2.md 的表 1–4、6、8 是手写数字; 2024 年努力修正后如何
#   保证表中每个数都来自结果表?
#   None (editing step): Tables 1–4, 6 and 8 of the master manuscript were typed by hand; after the
#   2024 effort correction, how do we guarantee that every cell comes from the result tables?
#
# Objective / 分析目标:
#   用同一渲染函数分别以修正前快照与修正后结果生成表格 markdown。旧渲染须与主稿现有表格逐字一致
#   (证明取数与格式口径正确), 才用新渲染替换; 不一致时只报告差异, 不写回。
#   Render each table from the pre-correction snapshot and from the corrected results with the same
#   function. The old rendering must match the current manuscript table verbatim (validating source
#   and format) before the new rendering replaces it; otherwise the difference is reported only.
#
# Input data / 输入数据:
#   temp/snapshot_pre_effort2024_20261013/tables/*.csv(旧), analysis_v2/tables/*.csv(新)
#   analysis_v2/effort2024_audit/model_quantities.csv(226a); logs/rerun2024/149.log(省级离散检验 P)
#   analysis_v2/docs/MANUSCRIPT_v2.md
# Main workflow / 主要流程: 渲染旧表 → 与主稿比对 → 渲染新表 → 替换(--apply)
# Expected output / 预期输出: 主稿表格块更新; analysis_v2/effort2024_audit/table_render_report.md
# Key assumptions / 关键假设: 表格块 = 表题行之后、下一个空行之前的连续 "|" 行
# Main packages / 主要包: 标准库 / standard library
# Output directory / 输出路径: analysis_v2/docs/, analysis_v2/effort2024_audit/
#
# Usage: python3.11 code/228_render_manuscript_tables.py [--apply]
# ============================================================
from __future__ import annotations

import argparse
import csv
import logging
import math
import os
import pathlib
import re

logging.basicConfig(level=logging.INFO, format="[228] %(message)s")
logger = logging.getLogger(__name__)

V2 = pathlib.Path(__file__).resolve().parent.parent
OLD_T = pathlib.Path(os.environ.get("TABLE_RENDER_OLD_TABLES", V2 / "temp" / "snapshot_pre_effort2024_20261013" / "tables"))
OLD_MQ = os.environ.get("TABLE_RENDER_OLD_MQ", "old")    # 增量更新时取 new 列 / "new" for incremental updates
NEW_T = V2 / "analysis_v2" / "tables"
AUD = V2 / "analysis_v2" / "effort2024_audit"
MS = V2 / "analysis_v2" / "docs" / "MANUSCRIPT_v2.md"
SUP = str.maketrans("0123456789-", "⁰¹²³⁴⁵⁶⁷⁸⁹⁻")


def f(x: float, d: int) -> str:
    return f"{x:.{d}f}".replace("-", "−")


def th(x: float) -> str:
    return f"{x:,.0f}"


def sci(p: float) -> str:
    e = math.floor(math.log10(p)); m = round(p / 10 ** e, 1)
    if m >= 10:
        m, e = m / 10, e + 1
    return f"{m:.1f} × 10{str(e).translate(SUP)}"


def pfmt(p: float) -> str:
    return sci(p) if p < 0.01 else f(p, 2)


def g2(p: float) -> str:
    """两位有效数字 / two significant figures, e.g. 0.0018, 0.024."""
    return f"{p:.2g}"


class S:
    def __init__(self, side: str):
        self.side = side
        self.tdir = OLD_T if side == "old" else NEW_T
        col = OLD_MQ if side == "old" else "new"
        self.mq = {r["item"]: float(r[col]) for r in csv.DictReader((AUD / "model_quantities.csv").open(encoding="utf-8"))}

    def t(self, name: str) -> list[dict]:
        with (self.tdir / name).open(encoding="utf-8-sig") as fh:
            return list(csv.DictReader(fh))

    def one(self, name: str, **kw) -> dict:
        ok = lambda r, k, v: str(r[k]) == v[:-1] if v.endswith("$") else str(r[k]).startswith(v)
        rows = [r for r in self.t(name) if all(ok(r, k, v) for k, v in kw.items())]
        if len(rows) != 1:
            raise KeyError(f"{name} {kw}: {len(rows)}")
        return rows[0]


# ---------------- 表 1 / Table 1 ----------------
def table1(s: S) -> str:
    lab = {"S0": "previously published", "S1": "+ discovery-year dating", "S2": "+ coverage-gap effort",
           "S3": "+ area-weighted climate", "S4": "+ completeness offset", "S5": "+ province × year effect"}
    out = ["| Step | Change | *n* | Events | HR effort | HR warming | HR variability | HR interaction |",
           "|---|---|---|---|---|---|---|---|"]
    for r in s.t("tbl_change_decomposition.csv"):
        v = [f(float(r[c]), 3) for c in ("HR_effort", "HR_change", "HR_var", "HR_int")]
        if r["step"] == "S5":
            v = [f"**{x}**" for x in v]
        out.append(f"| {r['step']} | {lab[r['step']]} | {th(float(r['n']))} | {r['events']} | " + " | ".join(v) + " |")
    return "\n".join(out)


# ---------------- 表 2 / Table 2 ----------------
def table2_caption_numbers(s: S) -> dict:
    r3 = s.one("tbl_v2_re_evaluation.csv", structure="R3")
    return {"n": th(s.mq["n_rows"]), "aic": f"{float(r3['AIC']):,.1f}"}


def table2(s: S) -> str:
    q = s.mq
    boot = {r["term"]: r for r in s.t("tbl_bootstrap_ci.csv") if r["cluster"] == "province"}
    nul = lambda nm, term: float(s.one("tbl_null_models.csv", null_model=nm, term=term + "$")["null_median_HR"])
    rows = [("Accumulated warming", "change", "clim_change_z", "N3"),
            ("Survey effort", "effort", "effort_z", "N2"),
            ("Annual climate variability", "var", "clim_var_z", "N3"),
            ("Warming × effort", "int", "clim_change_z:effort_z", "N3")]
    out = ["| Term | HR per SD | 95% CI (Wald) | 95% CI (province cluster bootstrap) | Permutation null median | *P* |",
           "|---|---|---|---|---|---|"]
    for lab, k, term, nm in rows:
        b = boot[term]
        out.append(f"| {lab} | {f(q['hr_' + k], 3)} | {f(q['lo_' + k], 3)}–{f(q['hi_' + k], 3)} | "
                   f"{f(float(b['boot_lo']), 2)}–{f(float(b['boot_hi']), 2)} | {f(nul(nm, term), 3)} | {pfmt(q['p_' + k])} |")
    for lab, g in (("σ species", "species"), ("σ province", "province"), ("σ province × year", "prov_year")):
        out.append(f"| {lab} | {f(q['sd_' + g], 3)} | | |")
    return "\n".join(out)


# ---------------- 表 3 / Table 3 ----------------
def table3(s: S) -> str:
    lab = {"R0": "species", "R1": "species + province", "R2": "+ year", "R3": "+ province × year (main)",
           "R4": "+ species warming slope", "R5": "+ province effort slope"}
    out = ["| Structure | ΔAIC | McFadden *R*² | Marginal *R*² | Conditional *R*² | Marginal AUC | Conditional AUC | ICC |",
           "|---|---|---|---|---|---|---|---|"]
    for r in s.t("tbl_v2_re_evaluation.csv"):
        d = float(r["dAIC"])
        v = [f(d, 1) if d >= 10 else f(d, 2), f(float(r["R2_McFadden"]), 4), f(float(r["R2_marginal"]), 3),
             f(float(r["R2_conditional"]), 3), f(float(r["AUC_marginal"]), 3), f(float(r["AUC_conditional"]), 3),
             f(float(r["ICC"]), 3)]
        name = lab[r["structure"]]
        if r["structure"] == "R3":
            name = f"**{name}**"; v = [f"**{x}**" for x in v]
        out.append(f"| {name} | " + " | ".join(v) + " |")
    return "\n".join(out)


# ---------------- 表 4 / Table 4 ----------------
def table4(s: S) -> str:
    d = {r["test"]: r for r in s.t("tbl_v2_diagnostics.csv")}
    g = lambda k: next(v for t, v in d.items() if t.startswith(k))
    ks, disp, zi, outl = g("KS"), g("dispersion"), g("zero"), g("outliers")
    gy, gp, mo = g("grouped by year"), g("grouped by province"), g("Moran")
    phc, phe = g("proportional hazards: clim_change"), g("proportional hazards: effort")
    rate = f(s.mq["event_rate_pct"], 2)
    out = ["| Check | Statistic | *P* | Reading |", "|---|---|---|---|",
           f"| KS uniformity | {f(float(ks['statistic']), 4)} | {f(float(ks['p_value']), 2)} | calibrated |",
           f"| Dispersion | {f(float(disp['statistic']), 3)} | {f(float(disp['p_value']), 2)} | correct |",
           f"| Zero inflation | {f(float(zi['statistic']), 3)} | {f(float(zi['p_value']), 2)} | none |",
           f"| Outliers | {f(float(outl['statistic']), 0)} | < 0.001 | expected at {rate}% event rate |",
           f"| Grouped by year | {f(float(gy['statistic']), 0)} of 23 levels | {g2(float(gy['p_value']))} | at nominal rate |",
           f"| Grouped by province | {f(float(gp['statistic']), 0)} of 31 levels | {g2(float(gp['p_value']))} | at nominal rate |",
           f"| Moran's *I* | {f(float(mo['statistic']), 3)} | {f(float(mo['p_value']), 2)} | no spatial structure |",
           f"| PH: warming × time | {f(float(phc['statistic']), 3)} | {f(float(phc['p_value']), 2)} | assumption holds |",
           f"| PH: effort × time | {f(float(phe['statistic']), 3)} | {pfmt(float(phe['p_value']))} | effort returns decline |"]
    return "\n".join(out)


# ---------------- 表 6 / Table 6 ----------------
def table6(s: S) -> str:
    st = {r["group"]: r for r in s.t("tbl_v2_migratory_stratified.csv") if r["grouping"].startswith("three")}
    it = {r["group"][:4]: r for r in s.t("tbl_v2_migratory_interaction_by_group.csv")}
    lad = {r["model"][:2]: r for r in s.t("tbl_v2_migratory_ladder.csv")}
    out = ["| Group | Events | Warming HR (95% CI) | Effort HR (95% CI) | Warming × effort HR | *P* |",
           "|---|---|---|---|---|---|"]
    for lab, key in (("Resident", "Resident"), ("Partial migrant", "Partial"), ("Long-distance migrant", "Long-distance")):
        r = st[key]; i = it[key[:4]]
        p = float(i["P"])
        out.append(f"| {lab} | {r['events']} | {f(float(r['HR_change']), 3)} ({f(float(r['lo_change']), 3)}–{f(float(r['hi_change']), 3)}) | "
                   f"{f(float(r['HR_effort']), 3)} ({f(float(r['lo_effort']), 3)}–{f(float(r['hi_effort']), 3)}) | "
                   f"{f(float(i['HR_int']), 3)} | {g2(p) if p < 0.01 else f(p, 2)} |")
    out.append(f"| *Moderation tests* | | LR *P* = {f(float(lad['M2']['LR_P']), 3)} | LR *P* = {f(float(lad['M3']['LR_P']), 3)} | "
               f"three-way LR *P* = {f(float(lad['M5']['LR_P']), 3)} | |")
    return "\n".join(out)


# ---------------- 表 8 / Table 8 ----------------
def prov_tests(side: str) -> tuple[float, float]:
    """泊松离散检验与负二项离散检验的 P(仅记录于 149 日志)/ dispersion-test P values (149 log only)."""
    if side == "old":
        return 2.3e-17, 0.20
    log = (V2 / "logs/rerun2024/149.log").read_text(encoding="utf-8")
    p1 = float(re.search(r"泊松过度离散: 参数 =\s+[\d.]+\s+\| P =\s+([\de.+-]+)", log).group(1))
    p2 = float(re.search(r"负二项离散: 参数 =\s+[\d.]+\s+\| P =\s+([\d.]+)", log).group(1))
    return p1, p2


def table8(s: S) -> str:
    m = s.t("tbl_v2_province_models.csv")
    p1, p2 = prov_tests(s.side)
    out = ["| Model | Dispersion | *P* | AICc |", "|---|---|---|---|",
           f"| Poisson | {f(float(m[0]['dispersion']), 2)} | {sci(p1)} | {f(float(m[0]['AICc']), 1)} |",
           f"| Negative binomial | {f(float(m[1]['dispersion']), 2)} | {f(p2, 2)} | {f(float(m[1]['AICc']), 1)} |",
           f"| Negative binomial, recent effort as offset | {f(float(m[2]['dispersion']), 2)} | — | {f(float(m[2]['AICc']), 1)} |"]
    co = {(r["model"], r["term"]): r for r in s.t("tbl_v2_province_coefficients.csv")}

    def cell(model: str, term: str) -> str:
        r = co.get((model, term))
        if r is None:
            return "*offset*"
        irr = f(float(r["IRR"]), 2)
        if r["significant"] == "TRUE":
            p = float(r["p_value"])
            return f"**{irr}** (*P* = {f(p, 4) if p < 0.01 else f(p, 3)})"
        return irr

    rows = [("Regional species richness", "z_richness"), ("Early survey effort (2002–2008)", "z_early_effort"),
            ("Recent survey effort (2009–2024)", "z_recent_effort"), ("GDP per capita", "z_gdp"),
            ("Administrative area", "z_area"), ("Habitat heterogeneity", "z_habitat")]
    out += ["", "| Term | Counts, IRR | Rate per unit of effort, IRR |", "|---|---|---|"]
    out += [f"| {lab} | {cell('NB main', t)} | {cell('NB offset', t)} |" for lab, t in rows]
    return "\n".join(out)


TABLES = {"Table 1.": table1, "Table 2.": table2, "Table 3.": table3, "Table 4.": table4,
          "Table 6.": table6, "Table 8.": table8}


def block(text: str, caption: str) -> tuple[int, int]:
    """表题之后第一段连续表格行(表 8 含两段, 以空行相隔)的起止位置 / span of the table block."""
    i = text.index(f"**{caption}**")
    j = text.index("\n|", i) + 1
    end = j
    lines = text[j:].split("\n")
    k, n = 0, len(lines)
    while k < n:
        if lines[k].startswith("|"):
            k += 1; continue
        if lines[k] == "" and caption == "Table 8." and k + 1 < n and lines[k + 1].startswith("|"):
            k += 1; continue
        break
    end = j + sum(len(x) + 1 for x in lines[:k]) - 1
    return j, end


def main() -> None:
    ap = argparse.ArgumentParser(); ap.add_argument("--apply", action="store_true")
    ap.add_argument("--skip", nargs="*", default=[], help='跳过的表, 如 "Table 2." / tables to skip')
    args = ap.parse_args()
    text = MS.read_text(encoding="utf-8")
    old, new = S("old"), S("new")
    rep = ["# 主稿表格重渲染 / Manuscript table re-rendering", ""]
    ok_all = True
    for cap, fn in TABLES.items():
        if cap in args.skip:
            rep += [f"## {cap} 跳过 / skipped", ""]; continue
        a, b = block(text, cap)
        cur = text[a:b]
        try:
            r_old, r_new = fn(old), fn(new)
        except (KeyError, FileNotFoundError, ValueError) as e:
            rep += [f"## {cap} 渲染失败 / failed: {e}", ""]; ok_all = False; continue
        same = r_old == cur
        if r_new == cur:                                   # 已是新值 / already updated
            rep += [f"## {cap} 已是新渲染 / already up to date", ""]; continue
        ok_all &= same
        rep += [f"## {cap} 旧渲染与主稿一致 / old rendering matches: {same}", ""]
        if not same:
            for x, y in zip(cur.split("\n"), r_old.split("\n")):
                if x != y:
                    rep += [f"- 主稿 / ms: `{x}`", f"- 渲染 / old: `{y}`"]
            rep.append("")
        rep += ["```", r_new, "```", ""]
        if args.apply and same:
            text = text[:a] + r_new + text[b:]
    # 表 2 表题中的 n 与 AIC / n and AIC in the Table 2 caption
    o2, n2 = table2_caption_numbers(old), table2_caption_numbers(new)
    cap_old = f"*n* = {o2['n']}; 649 events; 392 species; 31 provinces; AIC {o2['aic']}."
    cap_new = f"*n* = {n2['n']}; 649 events; 392 species; 31 provinces; AIC {n2['aic']}."
    found = text.count(cap_old)
    rep.append(f"## Table 2 caption: old found {found} → `{cap_new}`")
    if args.apply and found == 1 and "Table 2." not in args.skip:
        text = text.replace(cap_old, cap_new)
    (AUD / "table_render_report.md").write_text("\n".join(rep) + "\n", encoding="utf-8")
    if args.apply:
        MS.write_text(text, encoding="utf-8")
    logger.info("旧渲染全部一致 / all old renderings match: %s;报告 table_render_report.md", ok_all)


if __name__ == "__main__":
    main()
