#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   无(核对步骤)。2024 年努力修正后, 哪些结果表的哪些数值变了、变了多少?
#   None (audit step): which values in which result tables changed after the 2024 effort correction?
#
# Objective / 分析目标:
#   逐表对比修正前快照与修正后的结果表, 输出变化清单, 供更新正文数字与追踪核对使用。
#   Compare every result table with the pre-correction snapshot and list the changed values, to drive
#   the manuscript number update and the final number trace.
#
# Input data / 输入数据:
#   temp/snapshot_pre_effort2024_20261013/tables/*.csv(修正前 / before)
#   analysis_v2/tables/*.csv(修正后 / after)
#
# Main workflow / 主要流程:
#   1. 以非数值列为键对齐行(键重复时按行序)/ align rows on the non-numeric columns (row order if keys repeat)
#   2. 数值列逐格比较, 相对差 > 1e-9 记为变化 / compare numeric cells, relative difference > 1e-9 = changed
#   3. 写出 Markdown 报告与长格式 CSV / write a Markdown report and a long-format CSV
#
# Expected output / 预期输出:
#   analysis_v2/effort2024_audit/table_diff_report.md, table_diff_cells.csv
#
# Key assumptions / 关键假设: 表结构(列名)在修正前后相同;新增或删去的表单独列出。
# Main packages / 主要包: pandas 不可用, 只用标准库 csv / standard library only
# Output directory / 输出路径: analysis_v2/effort2024_audit/
#
# Usage: python3.11 code/224_table_diff_effort2024.py
# ============================================================
from __future__ import annotations

import csv
import logging
import math
import pathlib

logging.basicConfig(level=logging.INFO, format="[224] %(message)s")
logger = logging.getLogger(__name__)

V2 = pathlib.Path(__file__).resolve().parent.parent
OLD = V2 / "temp" / "snapshot_pre_effort2024_20261013" / "tables"
NEW = V2 / "analysis_v2" / "tables"
OUT = V2 / "analysis_v2" / "effort2024_audit"
SKIP = {"tbl_effort_2024_audit.csv", "tbl_effort_2024_validation.csv", "tbl_effort_2024_sensitivity.csv",
        "tbl_effort_2024_timevarying.csv"}


def num(x: str) -> float | None:
    try:
        v = float(x)
    except (TypeError, ValueError):
        return None
    return v if math.isfinite(v) else None


def read(p: pathlib.Path) -> tuple[list[str], list[dict]]:
    with p.open(encoding="utf-8-sig") as fh:
        r = csv.DictReader(fh)
        return list(r.fieldnames or []), list(r)


def key_cols(cols: list[str], rows: list[dict]) -> list[str]:
    """非数值列作键 / non-numeric columns form the key."""
    out = []
    for c in cols:
        vals = [r[c] for r in rows if r[c] not in ("", "NA")]
        if vals and not all(num(v) is not None for v in vals):
            out.append(c)
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    cells, summary = [], []
    old_names = {p.name for p in OLD.glob("*.csv")}
    new_names = {p.name for p in NEW.glob("*.csv")}
    for name in sorted((old_names & new_names) - SKIP):
        oc, orows = read(OLD / name)
        nc, nrows = read(NEW / name)
        if oc != nc:
            summary.append((name, "columns changed", len(orows), len(nrows), "", ""))
            continue
        keys = key_cols(oc, orows)
        def kf(r, i):
            return tuple(r[k] for k in keys) if keys else (i,)
        ok_ = [kf(r, i) for i, r in enumerate(orows)]
        nk_ = [kf(r, i) for i, r in enumerate(nrows)]
        if len(set(ok_)) < len(ok_) or len(set(nk_)) < len(nk_):      # 键重复: 按行序 / duplicate keys
            ok_, nk_ = [(i,) for i in range(len(orows))], [(i,) for i in range(len(nrows))]
        omap, nmap = dict(zip(ok_, orows)), dict(zip(nk_, nrows))
        n_changed, maxrel = 0, 0.0
        for k in [k for k in ok_ if k in nmap]:
            o, n = omap[k], nmap[k]
            for c in oc:
                if c in keys:
                    continue
                a, b = num(o[c]), num(n[c])
                if a is None and b is None:
                    if o[c] != n[c]:
                        cells.append((name, " | ".join(map(str, k)), c, o[c], n[c], ""))
                        n_changed += 1
                    continue
                if a is None or b is None:
                    cells.append((name, " | ".join(map(str, k)), c, o[c], n[c], "missing"))
                    n_changed += 1
                    continue
                rel = abs(a - b) / max(abs(a), 1e-12)
                if rel > 1e-9:
                    cells.append((name, " | ".join(map(str, k)), c, o[c], n[c], f"{rel:.3g}"))
                    n_changed += 1
                    maxrel = max(maxrel, rel)
        lost = len([k for k in ok_ if k not in nmap]); added = len([k for k in nk_ if k not in omap])
        summary.append((name, f"{n_changed} cells changed" if n_changed else "unchanged",
                        len(orows), len(nrows), f"{maxrel:.3g}" if n_changed else "", f"rows -{lost} +{added}"
                        if (lost or added) else ""))
    for name in sorted(new_names - old_names - SKIP):
        summary.append((name, "new table", 0, len(read(NEW / name)[1]), "", ""))
    for name in sorted(old_names - new_names):
        summary.append((name, "table removed", len(read(OLD / name)[1]), 0, "", ""))

    with (OUT / "table_diff_cells.csv").open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["table", "row_key", "column", "old", "new", "rel_diff"])
        w.writerows(cells)
    lines = ["# 结果表新旧对比 / Result tables before and after the 2024 effort correction", "",
             f"修正前快照 `{OLD.relative_to(V2)}`;修正后 `{NEW.relative_to(V2)}`。逐格明细见 `table_diff_cells.csv`。", "",
             "| 表 | 状态 | 行(前) | 行(后) | 最大相对差 | 行变化 |", "|---|---|---|---|---|---|"]
    lines += [f"| {a} | {b} | {c} | {d} | {e} | {f} |" for a, b, c, d, e, f in summary]
    (OUT / "table_diff_report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    changed = sum(1 for s in summary if s[1].endswith("changed") and s[1] != "unchanged")
    logger.info("表 %d 张: 有变化 %d、无变化 %d;变化单元格 %d", len(summary), changed,
                sum(1 for s in summary if s[1] == "unchanged"), len(cells))


if __name__ == "__main__":
    main()
