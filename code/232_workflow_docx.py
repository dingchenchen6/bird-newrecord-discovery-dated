#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   无(文档步骤)。把研究工作流文档由 Markdown 渲染为排版规范的 Word 文件。
#   None (documentation step): render the research-workflow document from Markdown to Word.
#
# Objective / 分析目标:
#   中文宋体正文、黑体标题(北大红)、自动目录、三线表、图宽适配版心、文档属性;
#   内容只来自 RESEARCH_WORKFLOW_zh.md, 不在此处改写任何数字。
#   Chinese body and heading fonts, a table of contents, booktabs tables, page-width figures
#   and document properties; content comes only from the Markdown source.
#
# Input data / 输入数据: analysis_v2/workflow/RESEARCH_WORKFLOW_zh.md, figures/*.png
# Main workflow / 主要流程: 生成参考样式 → pandoc(含目录与公式)→ 三线表与图宽后处理 → 文档属性 → 数字核对
# Expected output / 预期输出: analysis_v2/workflow/RESEARCH_WORKFLOW_zh.docx
# Key assumptions / 关键假设: pandoc 3.x 可用;206 的 booktabs 函数可复用
# Main packages / 主要包: python-docx, pandoc(外部)
# Output directory / 输出路径: analysis_v2/workflow/
#
# Usage: python3.11 code/232_workflow_docx.py
# ============================================================
from __future__ import annotations

import datetime
import importlib.util
import logging
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

logging.basicConfig(level=logging.INFO, format="[232] %(message)s")
logger = logging.getLogger(__name__)

V2 = Path(__file__).resolve().parent.parent
WF = V2 / "analysis_v2" / "workflow"
SRC, OUT = WF / "RESEARCH_WORKFLOW_zh.md", WF / "RESEARCH_WORKFLOW_zh.docx"
PKU = RGBColor(0x8B, 0x00, 0x12)
BODY_ZH, HEAD_ZH, LATIN = "宋体", "黑体", "Times New Roman"


def set_fonts(style, latin: str, east: str, size: float, bold: bool | None = None, color=None) -> None:
    """同时设西文与东亚字体 / set Latin and East Asian faces together."""
    f = style.font
    f.name, f.size = latin, Pt(size)
    if bold is not None:
        f.bold = bold
    if color is not None:
        f.color.rgb = color
    rpr = style.element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = rpr.makeelement(qn("w:rFonts"), {})
        rpr.append(rfonts)
    for k in ("w:ascii", "w:hAnsi", "w:cs"):
        rfonts.set(qn(k), latin)
    rfonts.set(qn("w:eastAsia"), east)
    for k in ("w:asciiTheme", "w:hAnsiTheme", "w:eastAsiaTheme", "w:cstheme"):
        rfonts.attrib.pop(qn(k), None)


def reference_docx(path: Path) -> None:
    """由 pandoc 默认参考文档改写样式 / restyle pandoc's default reference document."""
    raw = subprocess.run(["pandoc", "-o", str(path), "--print-default-data-file", "reference.docx"],
                         capture_output=True)
    if raw.returncode != 0:
        sys.exit(f"pandoc 参考文档失败 / reference doc failed: {raw.stderr[:200]}")
    doc = Document(str(path))
    st = doc.styles
    for name in ("Normal", "Body Text", "First Paragraph", "Compact"):
        if name in [s.name for s in st]:
            set_fonts(st[name], LATIN, BODY_ZH, 10.5)
            pf = st[name].paragraph_format
            pf.line_spacing, pf.space_after = 1.35, Pt(4)
    for name, size in (("Title", 20), ("Subtitle", 13), ("Heading 1", 15), ("Heading 2", 12.5), ("Heading 3", 11)):
        s = st[name]
        set_fonts(s, LATIN, HEAD_ZH, size, bold=True, color=PKU if name != "Subtitle" else RGBColor(0x3F, 0x3F, 0x3F))
        s.paragraph_format.space_before = Pt(14 if name == "Heading 1" else 8)
        s.paragraph_format.space_after = Pt(6)
    for name in ("Author", "Date"):
        set_fonts(st[name], LATIN, BODY_ZH, 10.5, color=RGBColor(0x3F, 0x3F, 0x3F))
    for name in ("Image Caption", "Table Caption"):
        if name in [s.name for s in st]:
            set_fonts(st[name], LATIN, BODY_ZH, 9.5, color=RGBColor(0x6B, 0x6B, 0x6B))
    for sec in doc.sections:
        sec.page_height, sec.page_width = Cm(29.7), Cm(21.0)
        sec.left_margin = sec.right_margin = Cm(2.2)
        sec.top_margin = sec.bottom_margin = Cm(2.3)
    doc.save(str(path))


def load_booktabs():
    spec = importlib.util.spec_from_file_location("m206", V2 / "code/206_restyle_tables.py")
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m.booktabs


def _vlen(s: str) -> int:
    """视觉长度:汉字记 2、其他记 1 / visual length (CJK counts double)."""
    return sum(2 if ord(ch) > 0x2E80 else 1 for ch in s)


def fit_widths(tbl, total: int) -> None:
    """表格满版心, 列宽按内容长度分配(上下限截断)/ full-width table, columns weighted by content."""
    ncol = len(tbl.columns)
    w = []
    for j in range(ncol):
        lens = [_vlen(row.cells[j].text) for row in tbl.rows]
        w.append(min(max(sum(lens) / len(lens), 8), 70))
    tot = sum(w)
    widths = [int(total * x / tot) for x in w]
    pr = tbl._tbl.tblPr
    for old in pr.findall(qn("w:tblW")):
        pr.remove(old)
    tw = pr.makeelement(qn("w:tblW"), {qn("w:w"): "5000", qn("w:type"): "pct"})
    pr.append(tw)
    for old in pr.findall(qn("w:tblLayout")):
        pr.remove(old)
    pr.append(pr.makeelement(qn("w:tblLayout"), {qn("w:type"): "fixed"}))
    grid = tbl._tbl.tblGrid
    for gc, wd in zip(grid.findall(qn("w:gridCol")), widths):
        gc.set(qn("w:w"), str(int(wd / 635)))          # EMU → twip
    for row in tbl.rows:
        for cell, wd in zip(row.cells, widths):
            cell.width = wd


def postprocess(path: Path) -> None:
    doc = Document(str(path))
    booktabs = load_booktabs()
    width = doc.sections[0].page_width - doc.sections[0].left_margin - doc.sections[0].right_margin
    for t in doc.tables:
        booktabs(t)
        fit_widths(t, int(width))
        for row in t.rows:
            for cell in row.cells:
                for p in cell.paragraphs:
                    p.paragraph_format.space_after = Pt(0)
                    p.paragraph_format.line_spacing = 1.15
                    for r in p.runs:
                        r.font.size = Pt(9.5)
    for shp in doc.inline_shapes:                       # 图宽适配版心 / figures fill the text width
        ratio = shp.height / shp.width
        shp.width, shp.height = int(width), int(width * ratio)
    for p in doc.paragraphs:
        if p.style.name in ("Image Caption", "Captioned Figure"):
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    settings = doc.settings.element                    # 打开时更新目录域 / refresh the TOC field on open
    if settings.find(qn("w:updateFields")) is None:
        uf = settings.makeelement(qn("w:updateFields"), {qn("w:val"): "true"})
        settings.append(uf)
    cp = doc.core_properties
    cp.author = cp.last_modified_by = "Chenchen Ding"
    cp.title = "增温还是观测?中国鸟类新纪录生成风险研究工作流"
    cp.subject, cp.comments = "研究工作流 / Research workflow", ""
    cp.created = cp.modified = datetime.datetime.now().replace(microsecond=0)
    doc.save(str(path))


def verify(md: Path, docx: Path) -> None:
    """Markdown 中的每个数字都须出现在 Word 中 / every number in the source appears in the .docx."""
    nums = set(re.findall(r"\d+(?:[.,]\d+)+", md.read_text(encoding="utf-8")))
    txt = subprocess.run(["pandoc", "-t", "plain", "--wrap=none", str(docx)], capture_output=True, text=True).stdout
    missing = sorted(n for n in nums if n not in txt)
    if missing:
        sys.exit(f"数字缺失 / numbers missing in .docx: {missing[:10]}")
    logger.info("核对通过:%d 个数字均在 Word 中 / all %d numbers present", len(nums), len(nums))


def main() -> None:
    with tempfile.TemporaryDirectory() as td:
        ref = Path(td) / "reference.docx"
        reference_docx(ref)
        r = subprocess.run(["pandoc", str(SRC), "-o", str(OUT), "--from", "markdown+pipe_tables+tex_math_dollars",
                            "--to", "docx", "--toc", "--toc-depth=2", "--reference-doc", str(ref),
                            "--resource-path", str(WF), "-M", "toc-title=目录"], capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit(f"pandoc 失败 / failed: {r.stderr[:400]}")
    postprocess(OUT)
    verify(SRC, OUT)
    logger.info("完成 / done -> %s (%.0f KB)", OUT.name, OUT.stat().st_size / 1024)


if __name__ == "__main__":
    main()
