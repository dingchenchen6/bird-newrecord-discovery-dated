# ============================================================
# Scientific question / 科学问题:
# 投稿图件在最终版面上是否存在文字碰撞、出界或字号过小?
# Do the shipped figures carry text collisions, clipping, or
# sub-threshold type at the journal's reproduction width?
#
# Objective / 目标:
# 对图件 PDF 做可复现的机械质检, 取代逐张肉眼检查。
# A reproducible mechanical check on figure PDFs, replacing eyeballing.
#
# Usage / 用法:
#   python3.11 code/208_figure_qc.py analysis_v2/submission/GCB/figures/*.pdf
#   python3.11 code/208_figure_qc.py --width 6.93 <pdf> ...
#
# Key assumptions / 关键假设:
#   - 排除两类假阳性: 同一文本行内因字体切换而拆分的相邻 span;
#     旋转文字(其水平外接框天然相交, 视觉上并不重叠)。
#   - --width 为目标期刊的复现宽度(英寸): GCB 全页 6.93, Nature 系双栏 7.20。
# Main packages / 主要包: PyMuPDF (fitz)
# ============================================================
import fitz, sys, pathlib

def spans(pg):
    out = []
    for bi, b in enumerate(pg.get_text("dict")["blocks"]):
        for li, l in enumerate(b.get("lines", [])):
            if tuple(round(v, 2) for v in l["dir"]) != (1.0, 0.0):
                continue                      # 旋转文字跳过
            for s in l["spans"]:
                if s["text"].strip():
                    out.append(((bi, li), fitz.Rect(s["bbox"]), s["text"].strip()))
    return out

def check(path, edge_pad=1.5, ov_pad=0.5):
    pg = fitz.open(path)[0]; R = pg.rect; sp = spans(pg); bad = []
    for i, (k1, r1, t1) in enumerate(sp):
        over = max(r1.x1 - (R.x1 - edge_pad), (R.x0 + edge_pad) - r1.x0)
        if over > 0:
            bad.append(("贴边", f"{t1[:44]}  (+{over:.1f}pt)", ""))
        for k2, r2, t2 in sp[i + 1:]:
            if k1 == k2: continue             # 同一行内相邻 span 跳过
            oy = min(r1.y1, r2.y1) - max(r1.y0, r2.y0)
            if oy <= 0 or oy / min(r1.height, r2.height) < 0.55: continue
            if min(r1.x1, r2.x1) - max(r1.x0, r2.x0) > ov_pad:
                bad.append(("重叠", t1[:34], t2[:34]))
    return bad

TARGET_IN = 6.93     # GCB 全页宽 176 mm;Nature 系双栏用 7.20
FLOOR_PT = 5.0       # Nature 系最小字号下限


def min_type(path):
    """返回 (画布宽 in, 原始最小字号 pt, 按目标宽换算后的印刷字号 pt)。"""
    pg = fitz.open(path)[0]; wi = pg.rect.width / 72
    sz = [s["size"] for b in pg.get_text("dict")["blocks"]
          for l in b.get("lines", []) for s in l["spans"] if s["text"].strip()]
    if not sz:
        return wi, None, None
    return wi, min(sz), min(sz) * TARGET_IN / wi


args = [a for a in sys.argv[1:] if not a.startswith("--")]
for i, a in enumerate(sys.argv):
    if a == "--width":
        TARGET_IN = float(sys.argv[i + 1])

nbad = 0
for f in args:
    b = check(f); nm = pathlib.Path(f).stem
    wi, raw, eff = min_type(f)
    tiny = eff is not None and eff < FLOOR_PT
    tag = f"  [字号 {eff:.1f} pt @ {TARGET_IN} in]" if eff else ""
    if tiny:
        b = list(b) + [("字号", f"最小 {raw:.1f} pt, 印刷仅 {eff:.1f} pt (< {FLOOR_PT})", "")]
    if not b: print(f"  ✓ {nm}{tag}"); continue
    nbad += 1
    seen = set(); u = [x for x in b if not (x in seen or seen.add(x))]
    print(f"  ✗ {nm}  ({len(u)} 处)")
    for kind, a, c in u[:6]:
        print(f"      [{kind}] {a!r}" + (f"  ×  {c!r}" if c else ""))
print(f"\n合计 {nbad} 个文件有问题 / {len(args)} 个")
