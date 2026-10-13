#!/usr/bin/env python3.11
# ============================================================
# AI 写作痕迹扫描 / Scan manuscripts for AI-writing patterns
# 依据: Wikipedia "Signs of AI writing" 与 writing-anti-ai 技能的英文模式表。
# 输出每版每节的: 破折号密度、否定排比、AI 高频词、粗体段首句、套话、句长变异。
# Usage: python3.11 code/213_ai_style_scan.py [--detail]
# ============================================================
from __future__ import annotations

import re
import statistics as st
import sys
from pathlib import Path

SUB = Path(__file__).resolve().parent.parent / "analysis_v2" / "submission"
AI_WORDS = r"\b(additionally|moreover|furthermore|crucial(ly)?|pivotal|delve|underscore[sd]?|highlight(s|ed|ing)?|landscape|interplay|intricate|notabl[ey]|showcas\w*|tapestry|testament|vital|robust(ly|ness)?|comprehensive|leverag\w*|align(s|ed)? with|shed(s)? light|pave(s)? the way|in turn|importantly|fundamentally|remarkabl[ey]|strikingly|profound(ly)?)\b"
NEG_PAR = r"\b(not (?:a |an |the )?[\w\-]+(?: [\w\-]+){0,4},? (?:but|rather)|rather than|, not [\w\-]+(?: [\w\-]+){0,3}[.;]|is not (?:merely|just|simply))"
STOCK = r"(Here we |Taken together|In summary|In conclusion|makes the point|The mechanism is transparent|Two qualifications apply|This is substantive|It is (?:straightforward|important|worth))"


def sections(md: str) -> dict[str, str]:
    out, cur = {}, None
    for line in md.split("\n"):
        m = re.match(r"^## (.+)$", line)
        if m:
            cur = m.group(1).strip().lower(); out[cur] = ""; continue
        if cur:
            out[cur] += line + "\n"
    return out


def metrics(t: str) -> dict[str, float]:
    t = re.sub(r"<sup>.*?</sup>|\^[\d,–\-]+\^", "", t)
    words = re.findall(r"[A-Za-z0-9][A-Za-z0-9\-–'’.]*", t)
    n = max(len(words), 1)
    sents = [s for s in re.split(r"(?<=[.!?])\s+(?=[A-Z*])", re.sub(r"\s+", " ", t)) if len(s.split()) > 3]
    lens = [len(s.split()) for s in sents]
    return {"words": n,
            "emdash/1k": 1000 * t.count("—") / n,
            "negpar/1k": 1000 * len(re.findall(NEG_PAR, t, re.I)) / n,
            "aiword/1k": 1000 * len(re.findall(AI_WORDS, t, re.I)) / n,
            "boldlead": len(re.findall(r"^\*\*[^*\n]+\.\*\*", t, re.M)),
            "stock": len(re.findall(STOCK, t)),
            "sent_cv": (st.pstdev(lens) / st.mean(lens)) if len(lens) > 2 else 0.0}


if __name__ == "__main__":
    detail = "--detail" in sys.argv
    print(f"{'版本/章节':<22}{'词数':>6}{'—/千词':>8}{'否定排比':>9}{'AI词':>7}{'粗体段首':>8}{'套话':>6}{'句长CV':>8}")
    for key in ("GCB", "NEE", "NC"):
        sec = sections((SUB / key / f"Manuscript_{key}_maintext.md").read_text(encoding="utf-8"))
        for name in ("abstract", "introduction", "results", "discussion"):
            m = metrics(sec.get(name, ""))
            print(f"{key + ' ' + name:<22}{m['words']:>6}{m['emdash/1k']:>8.1f}{m['negpar/1k']:>9.1f}"
                  f"{m['aiword/1k']:>7.1f}{m['boldlead']:>8}{m['stock']:>6}{m['sent_cv']:>8.2f}")
            if detail:
                for pat, lab in ((AI_WORDS, "AI词"), (STOCK, "套话")):
                    hits = sorted({h if isinstance(h, str) else h[0] for h in re.findall(pat, sec.get(name, ""), re.I)})
                    if hits: print(f"      {lab}: {', '.join(hits)[:150]}")
