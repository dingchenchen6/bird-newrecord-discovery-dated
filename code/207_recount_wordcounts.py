# ============================================================
# Scientific question / 科学问题:
# 三个期刊版本在结构性改写之后, 是否仍在各自的字数硬约束之内?
# After the structural revision, are all three journal versions still
# within their respective hard word limits?
#
# Objective / 目标:
# 只读地重新统计当前 maintext.md 的分节词数并刷新对照表 —— 不重新生成文稿。
# Recount the current manuscripts read-only and refresh the comparison
# table; this script never rewrites the manuscripts themselves.
# (脚本 202 会由源稿重新装配 maintext.md, 会覆盖手工改写, 故不可用于复核。)
#
# Input / 输入:  analysis_v2/submission/{GCB,NEE,NC}/Manuscript_*_maintext.md
# Output / 输出: analysis_v2/submission/three_versions_wordcount.csv
# Key assumptions / 关键假设:
#   - 计数口径与脚本 202 的 wc() 完全一致(剔除上标、表格行与 Markdown 标记)
#   - GCB 受 all-inclusive 约束(Intro+Results+Discussion+Methods)
#     NEE / NC 受正文约束(Intro+Results+Discussion), 摘要与文献均不计入
# Main packages / 主要包: 标准库
# ============================================================
from __future__ import annotations

import csv
import re
from pathlib import Path

SUB = Path(__file__).resolve().parent.parent / "analysis_v2" / "submission"
# 限额均于 2026-09-24 核对官方页面 / limits verified against official pages on 2026-09-24:
#   NEE Article: main text <=3,500, abstract <=200 (nature.com/natecolevol/content)
#   NC Article:  main text <=5,000, abstract <=200, title <=15 words (nature.com/ncomms/submit/article)
#   GCB Research Article: <=8,000 words incl. Intro, M&M, Results, Discussion AND Acknowledgements;
#                         abstract <=300 (Wiley GCB author guidelines)
JOURNAL = {"NEE": ("Nature Ecology & Evolution", 3500, 200),
           "NC": ("Nature Communications", 5000, 200),
           "GCB": ("Global Change Biology", 8000, 300)}
SECTIONS = ("abstract", "introduction", "results", "discussion", "methods", "acknowledgements")


def wc(t: str) -> int:
    """与脚本 202 同口径的词数 / word count identical to script 202."""
    t = re.sub(r"^\*\*Keywords:\*\*.*$", "", t, flags=re.M)   # 关键词行不属于摘要 / keywords are not abstract
    t = re.sub(r"<sup>.*?</sup>", "", t)
    t = re.sub(r"^\|.*\|\s*$", "", t, flags=re.M)
    t = re.sub(r"[*_`#>]", "", t)
    return len(re.findall(r"[A-Za-z0-9][A-Za-z0-9\-–—'’.]*", t))


def split_sections(md: str) -> dict[str, str]:
    """按标题切分正文 / split on headings.

    用状态机而非逐标题匹配: Results 内部还有三级小标题, 逐标题匹配会把
    小标题之后的正文丢掉(实测只数到约四成)。遇到已知的收尾章节即停止累积。
    NB: a state machine, not per-heading matching - Results carries level-3
        subheadings, and per-heading matching silently dropped their bodies.
    """
    STOP = ("references", "author contributions", "competing",
            "data availability", "code availability", "supplementary",
            "extended data", "figure legends", "tables")
    parts: dict[str, str] = {s: "" for s in SECTIONS}
    cur: str | None = None
    for line in md.split("\n"):
        m = re.match(r"^#{1,3}\s+(.+?)\s*$", line)
        if m:
            name = re.sub(r"[*_`]", "", m.group(1)).strip().lower()
            # GCB 用 "Materials and Methods", 需显式别名, 否则 Methods 会被
            # 并进 Introduction(分项失真, 总数仍对)。
            # NB: GCB heads its methods "Materials and Methods".
            if name.startswith(("materials and methods", "methods and materials")):
                name = "methods"
            hit = next((k for k in SECTIONS if name.startswith(k)), None)
            if hit:
                cur = hit; continue
            if any(name.startswith(x) for x in STOP):
                cur = None; continue
            # 其余(小标题)不切换分节, 内容继续计入当前分节
            if cur is not None:
                parts[cur] += line + "\n"
            continue
        if cur is not None:
            parts[cur] += line + "\n"
    return parts


def main() -> None:
    rows = []
    for key, (name, limit, ab_limit) in JOURNAL.items():
        f = SUB / key / f"Manuscript_{key}_maintext.md"
        if not f.exists():
            print(f"[recount] 跳过 {key}: 缺 {f.name}")
            continue
        p = split_sections(f.read_text(encoding="utf-8"))
        c = {s: wc(p.get(s, "")) for s in SECTIONS}
        main_text = c["introduction"] + c["results"] + c["discussion"]
        governing = main_text + c["methods"] + c["acknowledgements"] if key == "GCB" else main_text
        status = "OK" if governing <= limit else f"超 {governing - limit}"
        if c["abstract"] > ab_limit:
            status += f" | 摘要超 {c['abstract'] - ab_limit}"
        rows.append([key, name, c["abstract"], c["introduction"], c["results"],
                     c["discussion"], c["methods"], governing, limit, status])
        print(f"[recount] {key:<4} 摘要 {c['abstract']:>4}/{ab_limit} | 正文 {main_text:>5} | "
              f"约束 {governing}/{limit}  {status}")

    out = SUB / "three_versions_wordcount.csv"
    with out.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["key", "journal", "abstract", "introduction", "results",
                    "discussion", "methods", "governing_count", "limit", "status"])
        w.writerows(rows)
    print(f"[recount] 已刷新 -> {out.name}")


if __name__ == "__main__":
    main()
