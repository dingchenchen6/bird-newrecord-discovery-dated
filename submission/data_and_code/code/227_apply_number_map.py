#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   无(改稿步骤)。把 226b 核定的新旧短语映射应用到全部手工维护的文稿, 并找出映射没有覆盖的旧数字。
#   None (editing step): apply the phrase map of script 226b to every hand-maintained manuscript and
#   find old numbers that the map did not reach.
#
# Objective / 分析目标:
#   1. 只替换整段短语(旧短语已在 GCB 原文逐字验证), 不做单个数字的全局替换, 以免误改同值不同义的数字;
#   2. 替换后扫描每份文稿中仍残留的旧数字(取自已变化条目的旧短语), 输出位置与上下文, 交人工逐条处理。
#   1. Replace whole phrases only (each old phrase was verified verbatim in the GCB text), never bare
#      numbers, so that equal values with different meanings are left alone;
#   2. after replacement, scan each document for numbers still carrying old values and list them
#      with context for manual handling.
#
# Input data / 输入数据: analysis_v2/effort2024_audit/number_map.csv(脚本 226b / script 226b)
# Main workflow / 主要流程: 读取映射 → 逐文稿逐短语计数/替换 → 残留旧数字扫描 → 报告
# Expected output / 预期输出: analysis_v2/effort2024_audit/apply_report.md, residual_old_numbers.csv
# Key assumptions / 关键假设: 派生文稿(tables_and_legends、SI)由 203/204 生成, 不在此处修改
# Main packages / 主要包: 标准库 / standard library
# Output directory / 输出路径: analysis_v2/effort2024_audit/
#
# Usage: python3.11 code/227_apply_number_map.py           # 只报告 / dry run
#        python3.11 code/227_apply_number_map.py --apply   # 写回文稿 / write the documents
# ============================================================
from __future__ import annotations

import argparse
import csv
import logging
import pathlib
import re

logging.basicConfig(level=logging.INFO, format="[227] %(message)s")
logger = logging.getLogger(__name__)

V2 = pathlib.Path(__file__).resolve().parent.parent
A2 = V2 / "analysis_v2"
SUB = A2 / "submission"
AUD = A2 / "effort2024_audit"
DOCS = [A2 / "docs/MANUSCRIPT_v2.md",
        *[SUB / j / f"Manuscript_{j}_maintext.md" for j in ("GCB", "NEE", "NC")],
        *[SUB / j / f"cover_letter_{j}.md" for j in ("GCB", "NEE", "NC")],
        SUB / "ReportingSummary_DRAFT_NatureFamily.md",
        SUB / "Manuscript_NatureFamily_maintext.md",
        SUB / "Manuscript_NatureFamily_tables_and_legends.md",
        SUB / "FIGURES_POLISHED_NOTES.md",
        SUB / "GCB/Translated_Abstract_zh.md"]
# 内部模块文档只加"修正前"注记(脚本 229), 不做部分改写 / module docs carry a notice only (229), no partial edits
NUM = re.compile(r"(?<![\d.,])[−-]?\d[\d,]*\.?\d*(?: × 10[⁻⁰¹²³⁴⁵⁶⁷⁸⁹]+)?%?")


def tokens(s: str) -> set[str]:
    """短语中的数字记号(去掉 0/1 位小整数)/ numeric tokens of a phrase, small integers dropped."""
    out = set()
    for m in NUM.finditer(s):
        t = m.group(0).rstrip(".,")
        if re.fullmatch(r"[−-]?\d{1,2}", t):          # 年份片段、序号等太易误配 / too ambiguous
            continue
        out.add(t)
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="写回文稿 / write the documents")
    args = ap.parse_args()
    rows = [r for r in csv.DictReader((AUD / "number_map.csv").open(encoding="utf-8"))
            if r["changed"] == "yes" and r.get("deferred", "no") != "yes"]    # 暂缓条目留待重算后 / deferred
    bad = [r["id"] for r in rows if r["new"].startswith("<error") or r["old"].startswith("<error")]
    if bad:
        raise SystemExit(f"映射含错误条目, 先修 226b / map has error entries: {bad}")
    rows.sort(key=lambda r: -len(r["old"]))                      # 长短语优先 / longest first
    old_tok: dict[str, set[str]] = {}
    for r in rows:
        for t in tokens(r["old"]) - tokens(r["new"]):
            old_tok.setdefault(t, set()).add(r["id"])

    report = ["# 映射应用报告 / Number-map application report", "",
              f"模式 / mode: {'apply' if args.apply else 'dry run'};已变化条目 {len(rows)} 条。", "",
              "| 文稿 | 命中条目 | 替换处 | 残留旧数字 |", "|---|---|---|---|"]
    resid = []
    for doc in DOCS:
        if not doc.exists():
            continue
        text = doc.read_text(encoding="utf-8")
        n_ent = n_rep = 0
        for r in rows:
            k = text.count(r["old"])
            if k:
                n_ent += 1; n_rep += k
                text = text.replace(r["old"], r["new"])
        # 残留扫描 / residual scan
        n_res = 0
        for t, ids in old_tok.items():
            for m in re.finditer(r"(?<![\d.,])" + re.escape(t) + r"(?![\d])(?!\.\d)", text):
                line = text.count("\n", 0, m.start()) + 1
                ctx = text[max(0, m.start() - 90): m.end() + 60].replace("\n", " ")
                resid.append([doc.relative_to(A2), line, t, ";".join(sorted(ids)), ctx])
                n_res += 1
        report.append(f"| {doc.relative_to(A2)} | {n_ent} | {n_rep} | {n_res} |")
        if args.apply and n_rep:
            doc.write_text(text, encoding="utf-8")
    with (AUD / "residual_old_numbers.csv").open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["file", "line", "old_token", "entries", "context"])
        w.writerows(resid)
    (AUD / "apply_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")
    logger.info("\n" + "\n".join(report[4:]))
    logger.info("残留旧数字 %d 处, 见 residual_old_numbers.csv / residual old numbers", len(resid))


if __name__ == "__main__":
    main()
