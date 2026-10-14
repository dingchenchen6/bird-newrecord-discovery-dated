#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   无(核对步骤)。2024 年努力修正后, 文稿里哪些数字来自已变化的结果, 应改成什么?
#   None (audit step): which numbers in the manuscripts come from results that changed, and to what?
#
# Objective / 分析目标:
#   以 224 的逐格变化表为源, 为每个变化值生成文中可能出现的写法(不同小数位、千分位、百分数、
#   科学记数), 在各文稿中定位旧写法, 列出位置、上下文、候选新值与来源单元格, 供逐条人工审核。
#   不直接改稿: 同一个旧写法可能来自不同结果, 必须结合上下文判断。
#   From the cell-level changes of script 224, generate the forms a value may take in prose (decimal
#   places, thousands separators, percentages, scientific notation), locate the old forms in each
#   manuscript and list position, context, candidate new value and source cell for manual review.
#   Nothing is edited here: one old string can come from several results, so context decides.
#
# Input data / 输入数据:
#   analysis_v2/effort2024_audit/table_diff_cells.csv(脚本 224)
#   文稿 / manuscripts: docs/MANUSCRIPT_v2.md 与三刊正文、投稿信、Reporting Summary、中文摘要
#
# Main workflow / 主要流程: 生成写法 → 带边界匹配 → 按位置汇总候选 → 写出 CSV
# Expected output / 预期输出: analysis_v2/effort2024_audit/number_candidates.csv
# Key assumptions / 关键假设: 只匹配完整数字(前后不能是数字或小数点);整数只匹配 ≥ 1,000 的千分位写法。
# Main packages / 主要包: 标准库 / standard library
# Output directory / 输出路径: analysis_v2/effort2024_audit/
#
# Usage: python3.11 code/225_number_candidates.py
# ============================================================
from __future__ import annotations

import csv
import logging
import math
import pathlib
import re

logging.basicConfig(level=logging.INFO, format="[225] %(message)s")
logger = logging.getLogger(__name__)

V2 = pathlib.Path(__file__).resolve().parent.parent
A2 = V2 / "analysis_v2"
AUD = A2 / "effort2024_audit"
DOCS = [A2 / "docs/MANUSCRIPT_v2.md"] + [A2 / f"submission/{j}/{n}" for j in ("GCB", "NEE", "NC") for n in
        (f"Manuscript_{j}_maintext.md", f"cover_letter_{j}.md")] + \
       [A2 / "submission/GCB/Translated_Abstract_zh.md", A2 / "submission/ReportingSummary_DRAFT_NatureFamily.md"]
SUP = str.maketrans("0123456789-", "⁰¹²³⁴⁵⁶⁷⁸⁹⁻")


def forms(v: float) -> dict[str, str]:
    """一个数值在文中的常见写法 / common prose forms of a value, keyed by a precision tag."""
    out: dict[str, str] = {}
    if not math.isfinite(v):
        return out
    for d in range(0, 5):
        s = f"{v:.{d}f}"
        if d == 0 and abs(v) >= 1000:
            s = f"{v:,.0f}"
        elif d == 0:
            continue                       # 小整数太易误配 / small integers match too easily
        out[f"d{d}"] = s.replace("-", "−")
    if 0 < abs(v) < 1:
        for d in (0, 1):
            out[f"pct{d}"] = f"{100 * v:.{d}f}%"
    if 0 < abs(v) < 0.001:                 # 科学记数 / scientific notation, e.g. 2.9 × 10⁻⁸
        e = math.floor(math.log10(abs(v)))
        m = v / 10 ** e
        out["sci"] = f"{m:.1f} × 10{str(e).translate(SUP)}"
    return out


def main() -> None:
    cells = list(csv.DictReader((AUD / "table_diff_cells.csv").open(encoding="utf-8")))
    reps: dict[str, list[tuple[str, str]]] = {}
    for c in cells:
        try:
            a, b = float(c["old"]), float(c["new"])
        except ValueError:
            continue
        fa, fb = forms(a), forms(b)
        for tag, s_old in fa.items():
            s_new = fb.get(tag)
            if s_new and s_new != s_old:
                src = f'{c["table"]} [{c["row_key"]}] {c["column"]}'
                reps.setdefault(s_old, []).append((s_new, src))
    logger.info("候选旧写法 %d 个 / candidate old strings", len(reps))
    rows = []
    for doc in DOCS:
        if not doc.exists():
            continue
        text = doc.read_text(encoding="utf-8")
        for s_old, lst in reps.items():
            for m in re.finditer(r"(?<![\d.,])" + re.escape(s_old) + r"(?![\d])(?!\.\d)", text):
                line = text.count("\n", 0, m.start()) + 1
                ctx = text[max(0, m.start() - 80): m.end() + 60].replace("\n", " ")
                news = sorted({n for n, _ in lst})
                rows.append([doc.relative_to(A2), line, m.start(), s_old, " / ".join(news), len(news),
                             "; ".join(sorted({s for _, s in lst}))[:400], ctx])
    rows.sort(key=lambda r: (str(r[0]), r[2]))
    with (AUD / "number_candidates.csv").open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["file", "line", "pos", "old", "candidates_new", "n_candidates", "sources", "context"])
        w.writerows(rows)
    logger.info("文中匹配 %d 处(其中多候选 %d 处)/ matches (ambiguous)", len(rows), sum(1 for r in rows if r[5] > 1))


if __name__ == "__main__":
    main()
