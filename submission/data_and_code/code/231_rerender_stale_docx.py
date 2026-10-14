#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   无(打包修补步骤)。2024 年努力修正后, 几份 .docx 没有任何流程步骤从已更新的 .md 重新生成,
#   仍含修正前数字(如 175,901):根目录 Nature 系通用正文、表与图注, Reporting Summary 草稿, GCB 中文摘要。
#   None (packaging repair): after the 2024 effort correction several .docx files were never
#   re-rendered from their updated .md sources and still carried pre-correction numbers.
#
# Objective / 分析目标:
#   1. 表与图注是主稿的纯派生件 → 用 200 的拆分与渲染逻辑从主稿重新生成(.md 与 .docx);
#   2. 通用正文 .md 有独立手改(题名等), 不能从主稿重生成 → 只由现有 .md 重渲染 .docx(200 的版式);
#   3. Reporting Summary 与中文摘要 → 由现有 .md 直接 pandoc 渲染(与原文件同为无版式草稿);
#   4. Reporting Summary 复制到 NEE/NC(与 215 相同);
#   5. 核对: 每份 .md 中出现的数字都必须出现在对应 .docx 中, 且不含修正前的标志性数字。
#   Tables and legends are regenerated from the master; the generic main text keeps its hand-edited
#   .md and only its .docx is re-rendered; the Reporting Summary and Chinese abstract are rendered
#   from their .md; every number in each .md must appear in its .docx.
#
# Input data / 输入数据: analysis_v2/docs/MANUSCRIPT_v2.md;analysis_v2/submission/ 下各 .md
# Main workflow / 主要流程: 重生成表与图注 → 重渲染三份 .docx → 复制 Reporting Summary → 数字核对
# Expected output / 预期输出: 上述 .docx(及表与图注 .md);日志列出每份文件的核对结果
# Key assumptions / 关键假设: 200 的 split_sections/assemble/build 与主稿结构一致;206 随后统一改三线表
# Main packages / 主要包: pandoc(外部), python-docx
# Output directory / 输出路径: analysis_v2/submission/
#
# Usage: python3.11 code/231_rerender_stale_docx.py      # 之后运行 206(三线表)与 215(复制与打包)
# ============================================================
from __future__ import annotations

import importlib.util
import logging
import re
import shutil
import subprocess
import sys
from pathlib import Path
from types import ModuleType

logging.basicConfig(level=logging.INFO, format="[231] %(message)s")
logger = logging.getLogger(__name__)

V2 = Path(__file__).resolve().parent.parent
SUB = V2 / "analysis_v2" / "submission"
PANDOC_FROM = "markdown+raw_html+pipe_tables+tex_math_dollars"
STALE = ("175,901", "86,380", "155,435", "1.157", "0.980", "about 175-fold", "1.35–1.37")   # 修正前标志 / old markers
NUM = re.compile(r"\d+(?:[.,]\d+)+")


def load_200() -> ModuleType:
    """复用 200 的拆分、上标改写与版式函数 / reuse script 200's helpers."""
    spec = importlib.util.spec_from_file_location("m200", V2 / "code/200_build_submission_docx.py")
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def pandoc(md: Path, docx: Path) -> None:
    """md → docx(与 200 相同的输入格式)/ render with the same reader options as 200."""
    r = subprocess.run(["pandoc", str(md), "-o", str(docx), "--from", PANDOC_FROM, "--to", "docx", "--standalone"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"pandoc 失败 / failed ({docx.name}): {r.stderr[:300]}")


def plain(docx: Path) -> str:
    r = subprocess.run(["pandoc", "-t", "plain", "--wrap=none", str(docx)], capture_output=True, text=True, check=True)
    return r.stdout


def verify(md: Path, docx: Path) -> bool:
    """.md 中的数字都须出现在 .docx 中, 且无修正前标志 / numbers of the .md present; no stale markers."""
    md_nums = set(NUM.findall(md.read_text(encoding="utf-8")))
    txt = plain(docx)
    missing = sorted(n for n in md_nums if n not in txt)
    stale = [s for s in STALE if s in txt]
    ok = not missing and not stale
    logger.info("%s %s: 数字 %d 个, 缺失 %d %s;修正前标志 %s", "✓" if ok else "✗", docx.relative_to(SUB),
                len(md_nums), len(missing), missing[:6], stale or "无")
    return ok


def main() -> None:
    m200 = load_200()
    # 1 表与图注: 从主稿重新生成 / tables and legends regenerated from the master
    _, back_md = m200.assemble(m200.split_sections(m200.SRC.read_text(encoding="utf-8")))
    m200.build(back_md, SUB / "Manuscript_NatureFamily_tables_and_legends.docx", "表格与图注 / tables and legends")
    # 2 通用正文: 保留手改的 .md, 只重渲染 .docx / generic main text: keep the .md, re-render the .docx
    mt = SUB / "Manuscript_NatureFamily_maintext.md"
    if "<sup>" in mt.read_text(encoding="utf-8"):
        sys.exit("通用正文含 <sup>, 须先改写为 ^…^ / convert <sup> first")
    pandoc(mt, mt.with_suffix(".docx"))
    m200.style_document(mt.with_suffix(".docx"))
    # 3 Reporting Summary 与中文摘要 / Reporting Summary and Chinese abstract
    for md in (SUB / "ReportingSummary_DRAFT_NatureFamily.md", SUB / "GCB/Translated_Abstract_zh.md"):
        pandoc(md, md.with_suffix(".docx"))
    # 4 Reporting Summary 副本 / copies for NEE and NC (as in 215)
    for j in ("NEE", "NC"):
        for ext in ("md", "docx"):
            shutil.copy2(SUB / f"ReportingSummary_DRAFT_NatureFamily.{ext}", SUB / j / f"ReportingSummary_DRAFT_{j}.{ext}")
    # 5 核对 / verification
    pairs = [(SUB / "Manuscript_NatureFamily_tables_and_legends.md", SUB / "Manuscript_NatureFamily_tables_and_legends.docx"),
             (mt, mt.with_suffix(".docx")),
             (SUB / "ReportingSummary_DRAFT_NatureFamily.md", SUB / "ReportingSummary_DRAFT_NatureFamily.docx"),
             (SUB / "NEE/ReportingSummary_DRAFT_NEE.md", SUB / "NEE/ReportingSummary_DRAFT_NEE.docx"),
             (SUB / "NC/ReportingSummary_DRAFT_NC.md", SUB / "NC/ReportingSummary_DRAFT_NC.docx"),
             (SUB / "GCB/Translated_Abstract_zh.md", SUB / "GCB/Translated_Abstract_zh.docx")]
    bad = [d.name for md, d in pairs if not verify(md, d)]
    if bad:
        sys.exit(f"核对未通过 / verification failed: {bad}")
    logger.info("完成 / done: %d 份 .docx 已与 .md 一致", len(pairs))


if __name__ == "__main__":
    main()
