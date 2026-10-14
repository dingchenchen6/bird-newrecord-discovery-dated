#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   无(改稿步骤)。2024 年努力修正除数字外还需要哪些文字说明?
#   None (editing step): besides the numbers, what wording does the 2024 effort correction require?
#
# Objective / 分析目标:
#   集中记录 226b/227 数字映射之外的全部手工文字修改, 使改稿可追溯、可重复执行:
#   1. 方法: 2024 年 eBird 补入(GBIF 下载 DOI)与广东 2024 年下载缺口; 预测基期的广东补齐;
#   2. 数据可用性: 引用 2024 年 eBird 下载 DOI(GCB 另加参考文献条目);
#   3. 投稿信、Reporting Summary、图件说明与中文摘要中的数字;
#   4. 内部模块文档加注"数字为修正前版本"。
#   Record every manual wording change outside the number map so the revision is traceable and
#   repeatable: methods (2024 eBird supplement with its GBIF DOI, the Guangdong 2024 download gap,
#   the projection base), data availability, letters, reporting summary, notes, Chinese abstract,
#   and a notice on internal module documents.
#
# Input / 输入: 三刊正文、主稿、投稿信、Reporting Summary、中文摘要、内部模块文档、203 的可用性文本
# Main workflow / 主要流程: 每条修改 = (文件, 旧文, 新文); 旧文须恰好出现一次; 已改过则跳过(幂等)
# Expected output / 预期输出: 文稿就地修改; 日志列出每条 applied / already / MISSING
# Key assumptions / 关键假设: 数字映射(227)已先行应用; 零模型与自助法相关数字由 226b/227 第二轮处理
# Main packages / 主要包: 标准库 / standard library
# Output directory / 输出路径: analysis_v2/ 下各文稿 / documents under analysis_v2/
#
# Usage: python3.11 code/229_text_edits_effort2024.py [--dry-run]
# ============================================================
from __future__ import annotations

import argparse
import logging
import pathlib

logging.basicConfig(level=logging.INFO, format="[229] %(message)s")
logger = logging.getLogger(__name__)

V2 = pathlib.Path(__file__).resolve().parent.parent
A2 = V2 / "analysis_v2"
SUB = A2 / "submission"
DOI = "https://doi.org/10.15468/dl.vfeeak"

# 方法新增句 / methods sentences
EBIRD_GCB = (" eBird checklists for 2024, absent from the original download, were added with the same visit definition "
             "(GBIF.org, 2026); Guangdong 2024, with China Bird Report records for only 14 days, was treated as missing.")
EBIRD_NUM = (f" eBird checklists for 2024, absent from the original download, were added from a separate GBIF download "
             f"({DOI}) with the same visit definition; Guangdong in 2024, where China Bird Report records cover only "
             f"14 days, was treated as missing.")
PROJ = " For projection, Guangdong's 2024 effort was carried forward from 2023."
PROJ_ANCHOR = "so the projected quantity is the latent generation hazard."
PROXY_GCB = "through four proxies: visits, distinct observers, birding days and records."
PROXY_NUM = "number of birding days and number of records."
NOTICE = ("> **注(2026-10-13)/ Note.** 本文档记录的是 2024 年调查努力修正之前的分析过程, 文中数字为修正前版本。"
          "修正(补入 2024 年 eBird、广东 2024 年按缺失处理)后的现行数值以 `analysis_v2/tables/` 与三刊正文为准, "
          "新旧对照见 `analysis_v2/effort2024_audit/`。 / Numbers in this document predate the 2024 effort correction; "
          "current values are in `analysis_v2/tables/` and the manuscripts, with the old-to-new map in "
          "`analysis_v2/effort2024_audit/`.\n\n")

EDITS: list[tuple[pathlib.Path, str, str]] = []


def add(path: pathlib.Path, old: str, new: str) -> None:
    EDITS.append((path, old, new))


# ---- GCB 正文 / GCB main text ----
G = SUB / "GCB/Manuscript_GCB_maintext.md"
add(G, PROXY_GCB, PROXY_GCB + EBIRD_GCB)
add(G, "Thirty-nine province-years, all in Hong Kong, Macao and Taiwan, have no coverage in the source database.",
    "Thirty-nine province-years (Hong Kong, Macao and Taiwan) have no coverage.")   # 省字数, 不改原意 / shorter, same meaning
add(G, PROJ_ANCHOR, PROJ_ANCHOR + PROJ)
add(G, "Survey-effort indicators were derived from eBird/GBIF occurrence records and China Bird Report checklists",
    f"Survey-effort indicators were derived from eBird/GBIF occurrence records (2024 records: GBIF.org, 2026, {DOI}) "
    "and China Bird Report checklists")
add(G, "\n\nHarris, I., Osborn, T. J., Jones, P. & Lister, D.",
    f"\n\nGBIF.org. GBIF occurrence download: eBird Observation Dataset, China, 2024 (27 September 2026). {DOI} (2026)."
    "\n\nHarris, I., Osborn, T. J., Jones, P. & Lister, D.")

# ---- NEE、NC 正文与主稿 / NEE, NC main texts and the master ----
for P in (SUB / "NEE/Manuscript_NEE_maintext.md", SUB / "NC/Manuscript_NC_maintext.md", A2 / "docs/MANUSCRIPT_v2.md"):
    add(P, PROXY_NUM, PROXY_NUM + EBIRD_NUM)
    add(P, PROJ_ANCHOR, PROJ_ANCHOR + PROJ)
for P in (SUB / "NEE/Manuscript_NEE_maintext.md", SUB / "NC/Manuscript_NC_maintext.md"):
    add(P, "Survey-effort indicators were derived from eBird/GBIF occurrence records and China Bird Report checklists",
        f"Survey-effort indicators were derived from eBird/GBIF occurrence records (2024 records: {DOI}) "
        "and China Bird Report checklists")
add(A2 / "docs/MANUSCRIPT_v2.md",
    "paths to local copies are configured in `config.R`.",
    f"paths to local copies are configured in `config.R`. eBird records for 2024 were obtained as GBIF occurrence "
    f"download {DOI}.")

# ---- 203 的 GCB 可用性独立副本 / standalone GCB availability text in 203 ----
add(V2 / "code/203_gcb_package.py",
    "licence does not permit redistribution. Survey-effort indicators were derived from\n"
    "eBird/GBIF occurrence records and China Bird Report checklists (http://www.birdreport.cn);",
    "licence does not permit redistribution. Survey-effort indicators were derived from\n"
    f"eBird/GBIF occurrence records (2024 records: GBIF.org, 2026, {DOI}) and China Bird\n"
    "Report checklists (http://www.birdreport.cn);")

# ---- 支撑域为零后的措辞 / wording once no cell remains inside the support (2050, growing effort) ----
add(G, "and its increase lies almost entirely outside the fitted support.",
    "and its increase lies entirely outside the fitted support.")
add(A2 / "docs/MANUSCRIPT_v2.md", "the effort-driven increase lies almost entirely outside the range in which the model can be trusted.",
    "the effort-driven increase lies entirely outside the range in which the model can be trusted.")

# ---- 支撑域丧失的原因: 修正后努力维度先出界 / why support is lost: effort leaves its range first ----
# 2024 年努力已是观测最高水平(20% 基期单元超过拟合努力第 99 百分位), 情景增长后 2050 年仅 11%(SSP2-4.5)
# 与 0%(SSP5-8.5)仍在努力范围内; 仅看气候维度, 2080 年仍有约一半单元在范围内(见 effort2024_audit)。
# The 2024 effort level is already the highest observed; under scenario growth only 11% (SSP2-4.5) and 0%
# (SSP5-8.5) of cells stay within the fitted effort range by 2050, whereas about half stay within the
# climate range even in 2080 (see effort2024_audit).
add(G, "The historical species-specific gradient has a standard deviation of only 0.18 °C, because provincial and "
       "range-wide anomalies largely move together. Future province-minus-range warming differentials reach 2 °C, more "
       "than ten standard deviations beyond the fitted range. Consequently, only",
    "The historical species-specific gradient has a standard deviation of only 0.18 °C, whereas future province-minus-range "
    "differentials reach 2 °C, and effort leaves its fitted range sooner still because its 2024 level is already the "
    "highest observed. Only")
add(G, "for 2030, 2050 and 2080 (Materials and Methods) and asked", "for 2030, 2050 and 2080 and asked")
for P in (G, SUB / "NC/Manuscript_NC_maintext.md"):
    add(P, "Because the species-referenced gradient varied little in the past, late-century scenarios push",
        "Because the species-referenced gradient varied little and effort is projected past its observed peak, "
        "late-century scenarios push")
for P in (SUB / "NC/Manuscript_NC_maintext.md", A2 / "docs/MANUSCRIPT_v2.md", SUB / "Manuscript_NatureFamily_maintext.md"):
    add(P, "more than ten standard deviations beyond the fitted range. Consequently, only",
        "more than ten standard deviations beyond the fitted range, and effort leaves its fitted range sooner still, "
        "because its 2024 level is already the highest observed. Only")
add(SUB / "NEE/Manuscript_NEE_maintext.md", "more than ten standard deviations beyond the fitted range; only",
    "more than ten standard deviations beyond the fitted range, and effort leaves its fitted range sooner still because "
    "its 2024 level is already the highest observed; only")
add(SUB / "NEE/Manuscript_NEE_maintext.md", "By 2080 every species–province cell lies outside the fitted support, where",
    "By 2080 projected effort exceeds anything observed and every species–province cell lies outside the fitted support, where")
add(A2 / "docs/MANUSCRIPT_v2.md", "smaller than the future warming differentials imposed on it.",
    "smaller than the future warming differentials imposed on it, and because projected effort soon exceeds its observed peak.")
add(SUB / "Manuscript_NatureFamily_maintext.md", "smaller than the future warming differentials imposed on it.",
    "smaller than the future warming differentials imposed on it, and because projected effort soon exceeds its observed peak.")

# ---- 投稿信 / cover letters ----
add(SUB / "GCB/cover_letter_GCB.md", "(hazard ratio 1.36 per SD) and effort (1.40)", "(hazard ratio 1.36 per SD) and effort (1.43)")
for j in ("NEE", "NC"):
    add(SUB / f"{j}/cover_letter_{j}.md", "fell from a hazard ratio of 2.18 in 2002 to 1.07 in 2024",
        "fell from a hazard ratio of 2.14 in 2002 to 1.13 in 2024")

# ---- Reporting Summary ----
add(SUB / "ReportingSummary_DRAFT_NatureFamily.md",
    "Cells lacking effort or climate components were excluded (185,478 → 175,901 cells; 657 → 649 events).",
    "Cells lacking effort or climate components were excluded (185,478 → 175,640 cells; 657 → 649 events), including "
    "Guangdong in 2024, whose survey-effort source covers only 14 days of that year.")
# 数据段: 补 2024 年下载 DOI, 占位符收窄到 2002–2023 年记录 / data section: 2024 DOI; narrow the placeholder
add(SUB / "ReportingSummary_DRAFT_NatureFamily.md",
    "Survey-effort indicators were derived from eBird/GBIF occurrence records and China Bird Report checklists "
    "(http://www.birdreport.cn); the raw records remain subject to their providers' terms, and the province-year "
    "effort panel is provided in the project repository. [AUTHORS: add the GBIF download DOI, or register a GBIF "
    "derived dataset and cite its DOI.]",
    f"Survey-effort indicators were derived from eBird/GBIF occurrence records (2024 records: {DOI}) and China Bird "
    "Report checklists (http://www.birdreport.cn); the raw records remain subject to their providers' terms, and the "
    "province-year effort panel is provided in the project repository. [AUTHORS: add the GBIF download DOI for the "
    "2002–2023 records, or register a GBIF derived dataset and cite its DOI.]")

# ---- 独立数字核查后的更正(2026-10-14)/ corrections after the independent number trace ----
# 只改有表或日志为据的事实性错误, 措辞判断留给作者(见 number_trace_audit.md)
# factual slips with a table or log as evidence only; wording judgements are left to the authors
GCB_MT, NEE_MT, NC_MT = (SUB / f"{j}/Manuscript_{j}_maintext.md" for j in ("GCB", "NEE", "NC"))
NF_MT, MASTER = SUB / "Manuscript_NatureFamily_maintext.md", A2 / "docs/MANUSCRIPT_v2.md"
for f in (GCB_MT, NEE_MT, NC_MT, NF_MT, MASTER):      # 三种系统发育处理的 OR 范围 / tbl_v2_species_fast_compare
    add(f, "1.91–2.50", "1.89–2.50")
add(GCB_MT,                                          # 361 种是 1,445 种物种池中的数目 / 361 is of the pool (148.log)
    "database; 1,312 match the dated Clements phylogeny, and 361 of these acquired at least one new provincial record,",
    "database, of which 1,312 match the dated Clements phylogeny and 361 acquired at least one new provincial record,")
for f in (GCB_MT, NF_MT, MASTER):                    # 重跑后为 0/23 年与 3/31 省 / 0 of 23 years, 3 of 31 provinces
    add(f, "close to the nominal rate", "consistent with the nominal rate")
for f in (GCB_MT, NC_MT):                            # 全国访问量在 2003、2008、2011、2020 年下降
    add(f, "observation grew every year", "observation grew almost every year")
add(NEE_MT, "lags discovery. Because observation grew every year,", "lags discovery. Because observation grew almost every year,")
add(NEE_MT, "direction (H1). Because observation grew every year,", "direction (H1). Because observation grew almost every year,")

# ---- 图件说明 / figure notes ----
add(SUB / "FIGURES_POLISHED_NOTES.md",
    "the mechanistic model projects increases in 176 of 186 province–scenario cells, the ML model in 42.",
    "the mechanistic model projects increases in 178 of 186 province–scenario cells, the ML model in 8.")
add(SUB / "FIGURES_POLISHED_NOTES.md",
    "Grey cells are the 24 province-years with an effort coverage gap, which are not in the model.",
    "Grey cells are the 24 province-years with an effort coverage gap and Guangdong 2024 (incomplete effort download), "
    "which are not in the model.")

# ---- 中文摘要(零模型数字留待第二轮)/ Chinese abstract (null-model numbers in the second pass) ----
Z = SUB / "GCB/Translated_Abstract_zh.md"
add(Z, "年观鸟次数增长了约 175 倍", "年观鸟次数增长了约 200 倍")
add(Z, "在 175,901 个“物种 × 省份 × 年份”单元", "在 175,640 个“物种 × 省份 × 年份”单元")
add(Z, "(每个标准差的风险比为 1.36,95% 置信区间 1.22–1.52)与调查努力(1.40,1.25–1.58)的贡献相当,且二者呈负交互(0.85,0.76–0.95)",
    "(每个标准差的风险比为 1.36,95% 置信区间 1.22–1.53)与调查努力(1.43,1.27–1.61)的贡献相当,且二者呈负交互(0.84,0.75–0.94)")
add(Z, "调查努力的回报由 2002 年的 2.18 降至 2024 年的 1.07", "调查努力的回报由 2002 年的 2.14 降至 2024 年的 1.13")

# ---- 内部模块文档加注 / notice on internal module documents ----
for P in sorted((A2 / "docs").glob("*_MODULE.md")) + [A2 / "docs/REPORT_v2_zh.md"]:
    first = P.read_text(encoding="utf-8").split("\n", 1)[0]
    add(P, first + "\n", first + "\n\n" + NOTICE)


def null_edits() -> list[tuple[pathlib.Path, str, str]]:
    """第二轮(C 路之后): 零模型相关的文字, 由重算后的 tbl_null_models 计算; 表未重算则拒绝执行。
    Second pass after lane C: null-model wording computed from the recomputed table; refuses stale tables."""
    import csv
    import datetime as dt
    tab = A2 / "tables/tbl_null_models.csv"
    if tab.stat().st_mtime < dt.datetime(2026, 10, 13, 18, 0).timestamp():
        raise SystemExit("tbl_null_models.csv 尚未重算 / not yet recomputed")
    rows = list(csv.DictReader(tab.open(encoding="utf-8-sig")))
    g = lambda nm, term, col="null_median_HR": float(next(r for r in rows if r["null_model"].startswith(nm)
                                                         and r["term"] == term)[col])
    mq = {r["item"]: float(r["new"]) for r in csv.DictReader((A2 / "effort2024_audit/model_quantities.csv").open(encoding="utf-8"))}
    n3c, n2e = g("N3", "clim_change_z"), g("N2", "effort_z")
    ints = sorted({round(g(n, "clim_change_z:effort_z"), 2) for n in ("N1", "N3")})
    int_txt = f"{ints[0]:.2f}" if len(ints) == 1 else f"{ints[0]:.2f}–{ints[1]:.2f}"
    inc = mq["hr_change"] / n3c
    e = []
    M = A2 / "docs/MANUSCRIPT_v2.md"
    e.append((M, "(*P* = 0.16 and 0.31)", f"(*P* = {g('N1', 'clim_var_z', 'P_perm'):.2f} and {g('N3', 'clim_var_z', 'P_perm'):.2f})"))
    e.append((M, "are centred on 1.16 for accumulated warming and 0.96 for the interaction",
              f"are centred on {n3c:.2f} for accumulated warming and {int_txt} for the interaction"))
    e.append((SUB / "GCB/Translated_Abstract_zh.md",
              "保持数据结构的置换零分布使变暖估计的中心落在 1.157,因此物种特异的部分约为 1.18;打乱调查努力的时间对齐后,其估计降至 0.980",
              f"保持数据结构的置换零分布使变暖估计的中心落在 {n3c:.3f},因此物种特异的部分约为 {inc:.2f};打乱调查努力的时间对齐后,其估计降至 {n2e:.3f}"))
    e.append((SUB / "THREE_VERSIONS.md",
              "气候项置换零分布中位 1.157 而非 1，\n可归因于物种特异参照的增量约 1.18；努力项打乱时间对齐后塌到 0.980。",
              f"气候项置换零分布中位 {n3c:.3f} 而非 1，\n可归因于物种特异参照的增量约 {inc:.2f}；努力项打乱时间对齐后塌到 {n2e:.3f}。"))
    return e


def main() -> None:
    ap = argparse.ArgumentParser(); ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--nulls", action="store_true", help="第二轮: 零模型文字 / second pass: null-model wording")
    args = ap.parse_args()
    edits = null_edits() if args.nulls else EDITS
    cache: dict[pathlib.Path, str] = {}
    missing = 0
    for path, old, new in edits:
        text = cache.setdefault(path, path.read_text(encoding="utf-8"))
        # 幂等: 插入型(新文含旧文)看新文是否已在; 替换型看旧文已不在且新文已在
        # idempotent: insertions are done when the new text is present; replacements when old is gone
        done = (new in text) if old in new else (new in text and old not in text)
        if done:
            logger.info("already  %s | %s", path.name, new[:70].replace("\n", " "))
            continue
        k = text.count(old)
        if k != 1:
            missing += 1
            logger.warning("MISSING  %s (found %d) | %s", path.name, k, old[:70].replace("\n", " "))
            continue
        cache[path] = text.replace(old, new)
        logger.info("applied  %s | %s", path.name, new[:70].replace("\n", " "))
    if not args.dry_run:
        for path, text in cache.items():
            if text != path.read_text(encoding="utf-8"):
                path.write_text(text, encoding="utf-8")
    logger.info("修改 %d 条;未找到 %d 条 / edits %d; missing %d", len(edits), missing, len(edits), missing)


if __name__ == "__main__":
    main()
