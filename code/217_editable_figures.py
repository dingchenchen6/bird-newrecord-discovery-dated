#!/usr/bin/env python3.11
# ============================================================
# 科学问题 / Scientific question:
#   无(打包步骤)。让三刊投稿包里的每张图都能在 PowerPoint 中直接修改。
#   None (packaging step): every figure in the three submission packages
#   should be editable in PowerPoint.
#
# 分析目标 / Objective:
#   把主图与 SI 图转成可编辑 PPTX:原生 DrawingML 形状 + 可编辑文本框,
#   幻灯片尺寸等于图件尺寸,版式与投稿 PDF 一致。
#   Convert main and SI figures into PPTX with native shapes and editable
#   text, one figure per slide, slide size equal to the figure size.
#
# 输入数据 / Input:
#   submission/{J}/figures/*.pdf(投稿用主图);203/204 中登记的 SI 图源
#   submitted main-figure PDFs; SI figure sources registered in 203/204
#
# 主要流程 / Workflow:
#   1. 用 AST 读出 203/204 的图件清单(不执行装配)/ read figure lists via AST
#   2. 源 PDF 按 md5 去重,LibreOffice(impress_pdf_import)批量转 PPTX
#      / deduplicate by md5, convert with LibreOffice's PDF import
#   3. 校正位图:cairo 把色标等位图画得更大再用裁剪框截取,LibreOffice
#      忽略裁剪框,故按 PDF 中的裁剪框裁切图片 / re-apply the PDF clip to rasters
#   4. 矢量 PDF 超过 20 MB(县级多图地图)或没有矢量源(DHARMa 为 PNG)时,
#      改为嵌图 PPTX,并在清单中注明文字不可编辑 / raster fallback, flagged
#   5. 回渲染核验:PPTX→PDF→PNG 与源图比对,输出差异指标与对照图
#      / render back and compare against the source
#
# 预期输出 / Output:
#   submission/{J}/figures/<主图名>.pptx;submission/{J}/figures_SI/FigSn.pptx;
#   第二阶段:顶刊版主图按各刊编号 → submission/{J}/figures_polished/<主图名>.{pdf,png,pptx}
#   stage 2: top-journal redesign, journal-numbered, in submission/{J}/figures_polished/
#   submission/editable_figures_manifest.csv;对照图在 temp/editable_qa/
# Usage: python3.11 code/217_editable_figures.py [--polished-only]
#
# 关键假设 / Key assumptions:
#   源 PDF 为 R cairo 矢量输出;LibreOffice 把 Helvetica 映射为 Arial。
#   Sources are cairo PDFs; Helvetica is mapped to Arial.
#
# 主要包 / Packages: python-pptx, PyMuPDF, Pillow, numpy;LibreOffice 25.x
# 输出路径 / Output directory: analysis_v2/submission/
#
# Usage: python3.11 code/217_editable_figures.py
# ============================================================
from __future__ import annotations

import ast
import csv
import hashlib
import logging
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pymupdf
from PIL import Image
from pptx import Presentation
from pptx.util import Emu

logging.basicConfig(level=logging.INFO, format="[217] %(message)s")
logger = logging.getLogger(__name__)

V2 = Path(__file__).resolve().parent.parent
A2 = V2 / "analysis_v2"
SUB = A2 / "submission"
QA = V2 / "temp" / "editable_qa"
SOFFICE = "/opt/homebrew/bin/soffice"
VECTOR_LIMIT_MB = 20.0          # 超过此体积的矢量图改走嵌图 / larger PDFs use the raster route
EMU_PER_PT = 12700
AUTHOR = "Chenchen Ding"
TJ = A2 / "figures_topjournal"
# 源图 → 顶刊版名 / source figure stem -> top-journal version
TJ_NAME = {
    "Fig1_main_results_v2": "TJ_Fig_main_results",
    "Fig2_dating_correction_v2": "TJ_Fig_dating_correction",
    "Fig3_specification_robustness_v2": "TJ_Fig_specification_robustness",
    "Fig5_model_anatomy_v2": "TJ_Fig_model_anatomy",
    "Fig6_observation_process_v2": "TJ_Fig_observation_process",
    "overall_direction_null": "TJ_Fig_direction_null",
    "FigM4_mech_vs_ml_agreement_v2": "TJ_Fig_mech_vs_ml",
}


@dataclass(frozen=True)
class FigEntry:
    """一张需要可编辑版本的图 / one figure that needs an editable version."""
    journal: str
    label: str          # "Figure 1" / "Fig. S3"
    out: Path           # 目标 PPTX / target PPTX
    base: Path          # 源图路径(无扩展名)/ source path without extension


class _Blank(str):
    """占位串:下标与拼接都返回占位串 / placeholder string tolerant to indexing and concatenation."""

    def __getitem__(self, key):
        return _Blank("")

    def __add__(self, other):
        return _Blank("")

    def __radd__(self, other):
        return _Blank("")


class _Ns(dict):
    """AST 求值用命名空间:未知名字返回占位串函数(清单里有拼接正文的调用)
    / eval namespace: unknown names become functions returning a placeholder (the lists build text)."""

    def __missing__(self, key: str):
        return lambda *a, **k: _Blank("")


def _assigned(src: Path, names: set[str], ns: _Ns) -> dict[str, object]:
    """读取脚本中指定变量的赋值而不执行脚本 / evaluate selected assignments only."""
    tree = ast.parse(src.read_text(encoding="utf-8"))
    out: dict[str, object] = {}
    for node in tree.body:
        if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
            name = node.targets[0].id
            if name in names:
                out[name] = eval(compile(ast.Expression(node.value), str(src), "eval"), {"__builtins__": {}}, ns)
    missing = names - out.keys()
    if missing:
        sys.exit(f"{src.name} 中找不到 / not found: {missing}")
    return out


def figure_entries() -> list[FigEntry]:
    """三刊的主图与 SI 图清单 / main and SI figure lists of the three journals."""
    ns = _Ns(A2=A2, V2=V2)
    g = _assigned(V2 / "code/203_gcb_package.py", {"FIGMAP", "SI_FIGS"}, ns)
    n = _assigned(V2 / "code/204_nee_nc_packages.py", {"F", "CONFIG"}, ns)
    entries: list[FigEntry] = []
    for name, base in g["FIGMAP"]:
        entries.append(FigEntry("GCB", f"Figure {name[6:]}", SUB / "GCB/figures" / f"{name}.pptx",
                                SUB / "GCB/figures" / name))
    for sid, path, _ in g["SI_FIGS"]:
        base = Path(path).with_suffix("")
        if sid == "Fig. S15":   # 203 用目录占位;图注写的是风玫瑰 / legend describes the wind roses
            base = A2 / "figures_direction/combined/order_direction_windrose_facets"
        entries.append(FigEntry("GCB", sid, SUB / "GCB/figures_SI" / f"{sid.replace('. ', '')}.pptx", base))
    for J in ("NEE", "NC"):
        for new, key, _ in n["CONFIG"][J]["main_figs"]:
            entries.append(FigEntry(J, f"Fig. {new[3:]}", SUB / J / "figures" / f"{new}.pptx",
                                    SUB / J / "figures" / new))
        for sid, key, _ in n["CONFIG"][J]["si_figs"]:
            entries.append(FigEntry(J, sid, SUB / J / "figures_SI" / f"{sid.replace('. ', '')}.pptx",
                                    Path(n["F"][key])))
    return entries


def main_figure_sources() -> dict[str, list[tuple[str, Path]]]:
    """各刊主图文件名 → 源图路径(无扩展名)/ journal main-figure names -> source paths."""
    ns = _Ns(A2=A2, V2=V2)
    g = _assigned(V2 / "code/203_gcb_package.py", {"FIGMAP"}, ns)
    n = _assigned(V2 / "code/204_nee_nc_packages.py", {"F", "CONFIG"}, ns)
    out = {"GCB": [(name, Path(base)) for name, base in g["FIGMAP"]]}
    for J in ("NEE", "NC"):
        out[J] = [(new, Path(n["F"][key])) for new, key, _ in n["CONFIG"][J]["main_figs"]]
    return out


def source_of(e: FigEntry) -> tuple[str, Path]:
    """选择转换路线与源文件 / choose route ('vector' | 'raster') and source file."""
    base = e.base
    if base.name.endswith("_si"):        # SI 用的是降采样副本,矢量源去掉后缀 / SI copy is a downsample
        base = base.with_name(base.name[:-3])
    pdf, png = base.with_suffix(".pdf"), base.with_suffix(".png")
    if pdf.exists() and pdf.stat().st_size / 1e6 <= VECTOR_LIMIT_MB:
        return "vector", pdf
    if png.exists():
        return "raster", png
    sys.exit(f"缺少源图 / no source for {e.label} ({e.journal}): {base}")


def md5(p: Path) -> str:
    return hashlib.md5(p.read_bytes()).hexdigest()


def soffice(args: list[str], cwd: Path) -> None:
    r = subprocess.run([SOFFICE, "--headless", *args], cwd=cwd, capture_output=True, text=True, timeout=3600)
    if r.returncode != 0:
        sys.exit(f"soffice 失败 / failed: {r.stderr[-400:]}")


def fix_clipped_rasters(pptx: Path, pdf: Path) -> int:
    """按 PDF 裁剪框裁切位图 / crop pictures to the clip that the PDF applies to them."""
    page = pymupdf.open(pdf)[0]
    images = [pymupdf.Rect(i["bbox"]) for i in page.get_image_info()]
    clips = [pymupdf.Rect(d["scissor"]) for d in page.get_drawings(extended=True) if d.get("type") == "clip"]
    prs = Presentation(str(pptx))
    fixed = 0
    for shp in prs.slides[0].shapes:
        if shp.shape_type != 13:
            continue
        box = pymupdf.Rect(shp.left / EMU_PER_PT, shp.top / EMU_PER_PT,
                           (shp.left + shp.width) / EMU_PER_PT, (shp.top + shp.height) / EMU_PER_PT)
        img = next((r for r in images if all(abs(a - b) < 0.6 for a, b in zip(r, box))), None)
        if img is None:
            continue
        inner = [c for c in clips if img.x0 - 0.6 <= c.x0 and c.x1 <= img.x1 + 0.6
                 and img.y0 - 0.6 <= c.y0 and c.y1 <= img.y1 + 0.6 and c.get_area() < 0.98 * img.get_area()]
        if not inner:
            continue
        c = max(inner, key=lambda r: r.get_area())
        shp.crop_left = (c.x0 - img.x0) / img.width
        shp.crop_right = (img.x1 - c.x1) / img.width
        shp.crop_top = (c.y0 - img.y0) / img.height
        shp.crop_bottom = (img.y1 - c.y1) / img.height
        shp.left, shp.top = Emu(round(c.x0 * EMU_PER_PT)), Emu(round(c.y0 * EMU_PER_PT))
        shp.width, shp.height = Emu(round(c.width * EMU_PER_PT)), Emu(round(c.height * EMU_PER_PT))
        fixed += 1
    prs.save(str(pptx))
    return fixed


def raster_pptx(png: Path, out: Path) -> None:
    """无可用矢量源时:整图嵌入,幻灯片尺寸按矢量源或 450 dpi 推算 / picture-only slide."""
    vec = png.with_suffix(".pdf")
    if vec.exists():
        r = pymupdf.open(vec)[0].rect
        w_in, h_in = r.width / 72, r.height / 72
    else:
        with Image.open(png) as im:
            dpi = (im.info.get("dpi") or (450, 450))[0] or 450
            w_in, h_in = im.width / dpi, im.height / dpi
    prs = Presentation()
    prs.slide_width, prs.slide_height = Emu(round(w_in * 914400)), Emu(round(h_in * 914400))
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    slide.shapes.add_picture(str(png), 0, 0, prs.slide_width, prs.slide_height)
    prs.save(str(out))


def set_props(pptx: Path, title: str) -> None:
    prs = Presentation(str(pptx))
    prs.core_properties.title = title
    prs.core_properties.author = AUTHOR
    prs.core_properties.last_modified_by = AUTHOR
    prs.save(str(pptx))


def anatomy(pptx: Path) -> tuple[int, int, int]:
    """形状、文本框、图片数 / counts of shapes, text boxes and pictures."""
    def walk(shapes) -> tuple[int, int, int]:
        n = t = p = 0
        for s in shapes:
            if s.shape_type == 6:
                a, b, c = walk(s.shapes)
                n, t, p = n + a, t + b, p + c
            else:
                n += 1
                t += int(bool(s.has_text_frame and s.text_frame.text.strip()))
                p += int(s.shape_type == 13)
        return n, t, p
    return walk(Presentation(str(pptx)).slides[0].shapes)


def page_image(path: Path, width: int) -> Image.Image:
    """把 PDF 首页或 PNG 渲染成给定宽度的灰度图 / grey image of fixed width."""
    if path.suffix == ".pdf":
        page = pymupdf.open(path)[0]
        pix = page.get_pixmap(matrix=pymupdf.Matrix(width / page.rect.width, width / page.rect.width), alpha=False)
        img = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
    else:
        img = Image.open(path).convert("RGB")
        img = img.resize((width, round(img.height * width / img.width)))
    return img


def compare(src: Path, rendered_pdf: Path, qa_png: Path) -> tuple[float, float]:
    """回渲染差异:平均绝对差与 >64 像素占比 / mean |diff| and share of pixels differing by >64."""
    a, b = page_image(src, 900), page_image(rendered_pdf, 900)
    b = b.resize(a.size)
    d = np.abs(np.asarray(a.convert("L"), float) - np.asarray(b.convert("L"), float))
    canvas = Image.new("RGB", (a.width * 2 + 24, a.height), "white")
    canvas.paste(a, (0, 0))
    canvas.paste(b, (a.width + 24, 0))
    canvas.save(qa_png)
    return float(d.mean()), float((d > 64).mean() * 100)


def polished_stage() -> list[dict]:
    """顶刊版主图按各刊编号复制并转可编辑 PPTX / journal-numbered polished figures + PPTX."""
    rows: list[dict] = []
    jobs = []
    for J, figs in main_figure_sources().items():
        for name, base in figs:
            tj = TJ / f"{TJ_NAME[base.name]}.pdf"
            if not tj.exists():
                logger.warning("缺顶刊版 / missing polished figure: %s (%s %s)", tj.name, J, name)
                continue
            jobs.append((J, name, tj))
    if not jobs:
        return rows
    with tempfile.TemporaryDirectory() as td:
        work = Path(td)
        (work / "in").mkdir()
        uniq = {tj.stem: tj for _, _, tj in jobs}
        for stem, tj in uniq.items():
            shutil.copy2(tj, work / "in" / f"{stem}.pdf")
        soffice(["--infilter=impress_pdf_import", "--convert-to", "pptx", "--outdir", str(work / "out"),
                 *[f"in/{stem}.pdf" for stem in uniq]], cwd=work)
        for stem, tj in uniq.items():
            fix_clipped_rasters(work / "out" / f"{stem}.pptx", tj)
            set_props(work / "out" / f"{stem}.pptx", stem)
        soffice(["--convert-to", "pdf", "--outdir", str(work / "rt"), *[f"out/{stem}.pptx" for stem in uniq]], cwd=work)
        qa = {stem: compare(tj, work / "rt" / f"{stem}.pdf", QA / f"{stem}.png") for stem, tj in uniq.items()}
        for J, name, tj in jobs:
            d = SUB / J / "figures_polished"
            d.mkdir(parents=True, exist_ok=True)
            for ext in ("pdf", "png"):
                shutil.copy2(tj.with_suffix("." + ext), d / f"{name}.{ext}")
            shutil.copy2(work / "out" / f"{tj.stem}.pptx", d / f"{name}.pptx")
            n_, t_, p_ = anatomy(d / f"{name}.pptx")
            prs = Presentation(str(d / f"{name}.pptx"))
            rows.append({"journal": J, "label": f"{name} (polished)", "pptx": str((d / f"{name}.pptx").relative_to(SUB)),
                         "source": str(tj.relative_to(V2)), "route": "vector",
                         "editable": "native shapes + editable text",
                         "slide_in": f"{prs.slide_width / 914400:.2f} x {prs.slide_height / 914400:.2f}",
                         "shapes": n_, "text_boxes": t_, "pictures": p_,
                         "mean_abs_diff": round(qa[tj.stem][0], 2), "pct_px_diff_gt64": round(qa[tj.stem][1], 2),
                         "size_kb": round((d / f"{name}.pptx").stat().st_size / 1024)})
            logger.info("%-4s %-8s polished  %5d shapes %4d text  diff %.1f / %.1f%%",
                        J, name, n_, t_, *qa[tj.stem])
    return rows


def write_manifest(rows: list[dict]) -> None:
    man = SUB / "editable_figures_manifest.csv"
    old = list(csv.DictReader(man.open(encoding="utf-8"))) if man.exists() else []
    keep_polished = [r for r in old if "(polished)" in r["label"]]
    keep_base = [r for r in old if "(polished)" not in r["label"]]
    new_polished = [r for r in rows if "(polished)" in r["label"]]
    new_base = [r for r in rows if "(polished)" not in r["label"]]
    merged = (new_base or keep_base) + (new_polished or keep_polished)
    with man.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(merged[0]))
        w.writeheader()
        w.writerows(merged)


def main() -> None:
    QA.mkdir(parents=True, exist_ok=True)
    if "--polished-only" in sys.argv:
        rows = polished_stage()
        if rows:
            write_manifest(rows)
        logger.info("完成 / done: %d 个顶刊版图位 / polished slots", len(rows))
        return
    entries = figure_entries()
    QA.mkdir(parents=True, exist_ok=True)
    routes = {e: source_of(e) for e in entries}
    uniq: dict[str, tuple[str, Path]] = {}
    for route, src in routes.values():
        uniq.setdefault(md5(src), (route, src))
    logger.info("%d 个图位,%d 个独立源 / %d slots, %d unique sources", len(entries), len(uniq), len(entries), len(uniq))

    with tempfile.TemporaryDirectory() as td:
        work = Path(td)
        (work / "in").mkdir()
        made: dict[str, Path] = {}
        vec = {k: s for k, (r, s) in uniq.items() if r == "vector"}
        for k, s in vec.items():
            shutil.copy2(s, work / "in" / f"{k[:10]}.pdf")
        soffice(["--infilter=impress_pdf_import", "--convert-to", "pptx", "--outdir", str(work / "out"),
                 *[f"in/{k[:10]}.pdf" for k in vec]], cwd=work)
        for k, s in vec.items():
            p = work / "out" / f"{k[:10]}.pptx"
            if not p.exists():
                sys.exit(f"转换失败 / conversion failed: {s}")
            n_fix = fix_clipped_rasters(p, s)
            if n_fix:
                logger.info("  %s: 校正 %d 个裁剪位图 / %d clipped rasters fixed", s.name, n_fix, n_fix)
            made[k] = p
        for k, (r, s) in uniq.items():
            if r == "raster":
                p = work / "out" / f"{k[:10]}.pptx"
                raster_pptx(s, p)
                made[k] = p
        # 标题用源图名,同一源图在三刊中是同一个文件(git 只存一份)
        # title = source stem, so one source yields byte-identical copies across journals
        for k, p in made.items():
            set_props(p, uniq[k][1].stem)
        # 回渲染并比对,每个独立源只做一次 / render back and compare once per unique source
        soffice(["--convert-to", "pdf", "--outdir", str(work / "rt"), *[f"out/{k[:10]}.pptx" for k in made]], cwd=work)
        qa: dict[str, tuple[float, float]] = {}
        for k, (r, s) in uniq.items():
            qa[k] = compare(s, work / "rt" / f"{k[:10]}.pdf", QA / f"{s.stem}.png")

        rows = []
        for e in entries:
            route, src = routes[e]
            k = md5(src)
            e.out.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(made[k], e.out)
            n, t, pics = anatomy(e.out)
            mean_d, share = qa[k]
            prs = Presentation(str(e.out))
            rows.append({
                "journal": e.journal, "label": e.label, "pptx": str(e.out.relative_to(SUB)),
                "source": str(src.relative_to(V2)), "route": route,
                "editable": "native shapes + editable text" if route == "vector" else "picture only",
                "slide_in": f"{prs.slide_width / 914400:.2f} x {prs.slide_height / 914400:.2f}",
                "shapes": n, "text_boxes": t, "pictures": pics,
                "mean_abs_diff": round(mean_d, 2), "pct_px_diff_gt64": round(share, 2),
                "size_kb": round(e.out.stat().st_size / 1024),
            })
            flag = "" if (mean_d < 12 and share < 8) else "  <-- 请目检 / inspect"
            logger.info("%-4s %-10s %-6s %5d shapes %4d text  diff %.1f / %.1f%%%s",
                        e.journal, e.label, route, n, t, mean_d, share, flag)

    rows += polished_stage()
    write_manifest(rows)
    n_raster = sum(r["route"] == "raster" for r in rows)
    logger.info("完成 / done: %d 个 PPTX(%d 个为嵌图)→ editable_figures_manifest.csv;对照图 %s",
                len(rows), n_raster, QA)


if __name__ == "__main__":
    main()
