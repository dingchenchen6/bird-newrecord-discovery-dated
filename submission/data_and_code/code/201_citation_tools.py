#!/usr/bin/env python3.11
# ============================================================
# 引文工具:编号上标 → 作者-年份制(GCB 需要),以及 A 标签归一化。
# Citation tools: numbered superscripts to author-date (required by GCB),
# and normalisation of the indirect [A1]-[A6] labels.
#
# 为什么单独成一个模块:82 条引文的体例转换是机械但易错的操作,
# 交给语言模型改写会引入随机错误;这里用确定性代码完成,并自带自检。
# Deterministic conversion with a self-check, rather than model rewriting.
# ============================================================

from __future__ import annotations
import re
from pathlib import Path

V2 = Path("/Users/dingchenchen/Documents/New records/bird-new-distribution-records/"
          "tasks/bird_hazard_model_effort_upgrade_v2")
SRC = V2 / "analysis_v2/docs/MANUSCRIPT_v2.md"

# 文稿脚注声明:[A1]–[A6] 对应参考文献 72, 73, 74, 76, 77, 78
A_LABEL = {"A1": 72, "A2": 73, "A3": 74, "A4": 76, "A5": 77, "A6": 78}

NAME = re.compile(r"([A-Z][A-Za-zÀ-ÿ'’\-]+),\s+((?:[A-Z]\.\s*)+(?:[A-Z]\.)?)")


def build_ref_map(text: str) -> dict[int, str]:
    """从参考文献表解析 编号 → 「首作者 et al., 年份」。"""
    block = re.search(r"^## References\s*$(.*?)^## ", text, re.M | re.S).group(1)
    out: dict[int, str] = {}
    for m in re.finditer(r"^(\d+)\.\s+(.+?)(?=\n\d+\.|\n\n|\Z)", block, re.M | re.S):
        n = int(m.group(1))
        body = " ".join(m.group(2).split())
        head = body.split(" *")[0][:300]
        names = NAME.findall(head)
        yr = re.search(r"\((\d{4})\)", body)
        if not names:
            out[n] = f"[ref {n}]"
            continue
        year = yr.group(1) if yr else "in review"
        first = names[0][0]
        if " et al." in head or len(names) >= 3:
            out[n] = f"{first} et al., {year}"
        elif len(names) == 2:
            out[n] = f"{first} & {names[1][0]}, {year}"
        else:
            out[n] = f"{first}, {year}"
    return out


def expand_tokens(inner: str) -> list[int]:
    """把 '1–4'、'16,19–21'、'[A1,A2],55' 展开成有序编号列表。"""
    nums: list[int] = []
    inner = inner.replace("[", "").replace("]", "")
    for tok in inner.split(","):
        tok = tok.strip()
        if not tok:
            continue
        # A 标签区间,如 A3–A5
        m = re.fullmatch(r"A(\d+)\s*[–\-]\s*A(\d+)", tok)
        if m:
            lo, hi = int(m.group(1)), int(m.group(2))
            nums += [A_LABEL[f"A{i}"] for i in range(lo, hi + 1) if f"A{i}" in A_LABEL]
            continue
        if re.fullmatch(r"A\d+", tok):
            nums.append(A_LABEL[tok]); continue
        # 数字区间
        m = re.fullmatch(r"(\d+)\s*[–\-]\s*(\d+)", tok)
        if m:
            nums += list(range(int(m.group(1)), int(m.group(2)) + 1)); continue
        if tok.isdigit():
            nums.append(int(tok))
    seen, ordered = set(), []
    for n in nums:
        if n not in seen:
            seen.add(n); ordered.append(n)
    return ordered


def normalise_a_labels(text: str) -> str:
    """把间接的 [A1] 标签替换成真实编号,使正文只出现数字引文。"""
    def repl(m: re.Match[str]) -> str:
        nums = expand_tokens(m.group(1))
        return "<sup>" + ",".join(str(n) for n in nums) + "</sup>"
    return re.sub(r"<sup>([^<]*A\d[^<]*)</sup>", repl, text)


def to_author_date(text: str, ref_map: dict[int, str]) -> str:
    """编号上标 → 作者-年份括注,GCB 体例。"""
    def repl(m: re.Match[str]) -> str:
        nums = expand_tokens(m.group(1))
        if not nums:
            return m.group(0)
        cites = [ref_map.get(n, f"[ref {n}]") for n in nums]
        return " (" + "; ".join(cites) + ")"
    # 引文上标前常紧跟单词,替换后需要一个空格;先去掉可能的重复空格
    out = re.sub(r"\s*<sup>([\d,\s–\-\[\]A]+)</sup>", repl, text)
    return re.sub(r"\s+\(", " (", out)


def sort_refs_by_author(text: str, ref_map: dict[int, str]) -> str:
    """GCB 参考文献表按首作者字母序重排,去掉编号。"""
    block_m = re.search(r"(^## References\s*$)(.*?)(^## )", text, re.M | re.S)
    block = block_m.group(2)
    entries: list[tuple[str, str]] = []
    for m in re.finditer(r"^(\d+)\.\s+(.+?)(?=\n\d+\.|\n\n|\Z)", block, re.M | re.S):
        n = int(m.group(1))
        body = " ".join(m.group(2).split())
        entries.append((ref_map.get(n, "zzz"), body))
    entries.sort(key=lambda t: t[0].lower())
    new_block = "\n\n" + "\n\n".join(b for _, b in entries) + "\n\n"
    return text[:block_m.start(2)] + new_block + text[block_m.end(2):]


def self_check(text: str, converted: str, ref_map: dict[int, str]) -> list[str]:
    """自检:转换前后引文点位数量应一致,且不应残留上标。"""
    problems: list[str] = []
    n_before = len(re.findall(r"<sup>[\d,\s–\-\[\]A]+</sup>", text))
    n_after = len(re.findall(r"\([A-Z][^)]*\d{4}[^)]*\)", converted))
    if n_after < n_before:
        problems.append(f"引文点位减少:转换前 {n_before},转换后仅识别到 {n_after}")
    leftover = re.findall(r"<sup>[\d,\s–\-\[\]A]+</sup>", converted)
    if leftover:
        problems.append(f"残留未转换的上标 {len(leftover)} 处:{leftover[:5]}")
    missing = [n for n in ref_map if ref_map[n].startswith("[ref")]
    if missing:
        problems.append(f"无法解析作者年份的条目:{missing}")
    return problems


if __name__ == "__main__":
    text = SRC.read_text(encoding="utf-8")
    rm = build_ref_map(text)
    print(f"解析参考文献 {len(rm)} 条")

    norm = normalise_a_labels(text)
    n_a = len(re.findall(r"<sup>[^<]*A\d[^<]*</sup>", text))
    print(f"A 标签引文归一化:{n_a} 处 -> 真实编号")

    conv = to_author_date(norm, rm)
    probs = self_check(norm, conv, rm)
    print("自检:", "通过" if not probs else "发现问题")
    for p in probs:
        print("  -", p)

    print("\n转换样例:")
    for pat in (r"[^\n]*Hortal[^\n]*", ):
        pass
    for m in list(re.finditer(r"<sup>([\d,\s–\-\[\]A]+)</sup>", norm))[:6]:
        nums = expand_tokens(m.group(1))
        print(f"  <sup>{m.group(1)}</sup> -> ({'; '.join(rm[n] for n in nums)})")
