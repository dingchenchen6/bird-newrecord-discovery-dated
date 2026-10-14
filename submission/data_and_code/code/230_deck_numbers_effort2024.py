#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   无(改稿步骤)。2024 年努力修正后, AOC 2026 报告(v3 四版、v4)中的数字与讲稿如何同步?
#   None (editing step): how are the numbers and speaker notes of the AOC 2026 talks (v3 x4, v4)
#   brought in line with the 2024 effort correction?
#
# Objective / 分析目标:
#   对两个构建脚本做精确替换(旧文须恰好出现指定次数), 并把情景图的纵轴改为随数据自适应
#   (新值 89 超出原写死的 70)。零模型数字(1.16、×1.18、0.98)留待 C 路完成后第二轮。
#   Exact replacements in both deck builders (each old string must occur the stated number of times),
#   and data-driven y-axis limits for the scenario charts (the new maximum, 89, exceeds the hard-coded
#   70). Null-model numbers (1.16, x1.18, 0.98) follow in a second pass once lane C has finished.
#
# Input / 输入: ~/.claude/skills/easyslides/projects/bird_talk_aoc2026_{v3_20261011,v4_pku_20261013}/build_*.py
# Main workflow / 主要流程: 读取 → 逐条替换并核对次数 → 幂等(已改则跳过)→ 写回
# Expected output / 预期输出: 两个构建脚本就地修改; 之后由各自 export 脚本重建 PPTX/PDF
# Key assumptions / 关键假设: 新值来自 226b 映射与结果表(见 analysis_v2/effort2024_audit/number_map.csv)
# Main packages / 主要包: 标准库 / standard library
# Output directory / 输出路径: 讲稿项目目录 / talk project directories
#
# Usage: python3.11 code/230_deck_numbers_effort2024.py [--dry-run] [--nulls]
#   --nulls  第二轮: 写入零模型数字(须先确认 tbl_null_models 已重算)/ second pass with null-model numbers
# ============================================================
from __future__ import annotations

import argparse
import csv
import logging
import pathlib

logging.basicConfig(level=logging.INFO, format="[230] %(message)s")
logger = logging.getLogger(__name__)

PROJ = pathlib.Path.home() / ".claude/skills/easyslides/projects"
V3 = PROJ / "bird_talk_aoc2026_v3_20261011/build_talk.py"
V4 = PROJ / "bird_talk_aoc2026_v4_pku_20261013/build_talk_pku.py"
TASK = pathlib.Path(__file__).resolve().parent.parent

NICE = '''

def nice_max(v: float) -> float:
    """纵轴上限: 最大值的 1.12 倍向上取整到 20 / y limit: 1.12 x max, rounded up to a multiple of 20."""
    return float(-(-v * 1.12 // 20) * 20)
'''

# (旧文, 新文, 期望次数) / (old, new, expected count)
V4_EDITS = [
    ("175-fold", "200-fold", 3),
    ('asked=["Why are Yunnan and Guangdong grey in 2024? Their visit counts in the source download fall by more than 90% "\n'
     '            "from 2023 while record counts do not, so the map shows them as incomplete; national totals and the model "\n'
     '            "input are unchanged.",',
     'asked=["Why is Guangdong grey in 2024? Its China Bird Report records cover only 14 days of that year, so we treat "\n'
     '            "that province-year as missing; eBird checklists for 2024, absent from the first download, were added for "\n'
     '            "every province.",', 1),
    ("175,901", "175,640", 3),
    ("7.7-fold", "7.9-fold", 2),
    ('"HR per SD (1.22–1.52)"', '"HR per SD (1.22–1.53)"', 1),
    ('("1.40", "Survey effort", "HR per SD (1.25–1.58)"', '("1.43", "Survey effort", "HR per SD (1.27–1.61)"', 1),
    ('("0.85", "Warming × effort"', '("0.84", "Warming × effort"', 1),
    ('("1.00", "Annual variability"', '("0.99", "Annual variability"', 1),
    ("for warming, and 1.40 for effort", "for warming, and 1.43 for effort", 1),
    ("ΔAIC: warming 28.7, effort 29.5", "ΔAIC: warming 29.9, effort 33.4", 1),
    ("ΔAUC: warming 0.053, effort 0.032", "ΔAUC: warming 0.053, effort 0.033", 1),
    ("Effort 1.25–1.52; warming 1.35–1.37", "Effort 1.25–1.55; warming 1.33–1.39", 1),
    ("around 29 AIC units each", "around 30 AIC units or more each", 1),
    ('("×2.23", "Province × year"', '("×2.22", "Province × year"', 1),
    ("multiplies the hazard by 2.23", "multiplies the hazard by 2.22", 1),
    ("2.18 → 1.07", "2.14 → 1.13", 2),
    ("HR per SD, 2002 → 2024; P = 0.00077", "HR per SD, 2002 → 2024; P = 0.0021", 1),
    ('"P = 0.82", "Return on warming"', '"P = 1.00", "Return on warming"', 1),
    ("Its hazard ratio fell from 2.2 in 2002 to about 1.1 in 2024, and after 2022 it\nis no longer different from one.",
     "Its hazard ratio fell from 2.1 in 2002 to about 1.1 in 2024, and from 2023 it\nis no longer different from one.", 1),
    ("Northern sectors: 40.2% vs 33.0%", "Northern sectors: 40.2% vs 32.8%", 1),
    ("χ² = 25.8, P = 0.001", "χ² = 26.8, P = 0.001", 1),
    ("    top, ymax = y0 + 80, 70.0\n", "    top, ymax = y0 + 80, nice_max(max(v for v, _ in SCEN.values()))\n", 1),
    ("    for t_ in (0, 20, 40, 60):\n        e += [LN(x0 + 64, sy(t_)", "    for t_ in range(0, int(ymax) + 1, 20):\n        e += [LN(x0 + 64, sy(t_)", 1),
    ("SCEN = national(\"tbl_future_scenario_grid.csv\")\n", "SCEN = national(\"tbl_future_scenario_grid.csv\")\n" + NICE, 1),
    ('("Growing effort: more than double", EFFORT)', '("Growing effort: roughly triple", EFFORT)', 1),
    ('"(faded bars: 2% in support)"', '"(faded bars: none in support)"', 1),
    ("changes the expected national count from 23.2 to 23.1 records a year", "changes the expected national count from 26.1 to 25.9 records a year", 1),
    ("If effort keeps\ngrowing, the count more than doubles by 2050.", "If effort keeps\ngrowing, the count roughly triples by 2050.", 1),
    ('asked=["Is 57 to 62 records a year a forecast? No. At 2050 only 2 percent of cells are inside the fitted support; "\n'
     '            "the credible statement is about 23 to 27 records a year in 2030, under any scenario."])',
     'asked=["Is 79 to 89 records a year a forecast? No. At 2050 no cell is inside the fitted support; "\n'
     '            "the credible statement is about 26 to 31 records a year in 2030, under any scenario."])', 1),
    ('("2030: 48%  →  2050: 10%", "B")', '("2030: 46%  →  2050: 6%", "B")', 1),
    ('("2080: 2% (SSP2-4.5)", "B")', '("2080: none (SSP2-4.5)", "B")', 1),
    ("Agree inside the range (ρ = 0.54)", "Agree inside the range (ρ = 0.56)", 1),
    ("drops from 48 percent in 2030, to 10 percent in 2050, and 2 percent by 2080.",
     "drops from 46 percent in 2030 to 6 percent in 2050, and to none by 2080, mostly because effort outgrows its observed range.", 1),
    ('"effort 1.40 per SD:"', '"effort 1.43 per SD:"', 1),
    ('"Warming × effort 0.85:"', '"Warming × effort 0.84:"', 1),
    ('"Province × year ×2.23;"', '"Province × year ×2.22;"', 1),
]

V3_EDITS = [
    ("175,901", "175,640", 1),
    ("175-fold", "200-fold", 1),
    ("175 倍", "200 倍", 2),
    ("7.7-fold", "7.9-fold", 1),
    ("访问量增至 7.7 倍", "访问量增至 7.9 倍", 1),
    ('"HR per SD (1.22–1.52)", "每 SD 风险比（1.22–1.52）"', '"HR per SD (1.22–1.53)", "每 SD 风险比（1.22–1.53）"', 1),
    ('("1.40", L("Survey effort", "调查努力"), L("HR per SD (1.25–1.58)", "每 SD 风险比（1.25–1.58）")',
     '("1.43", L("Survey effort", "调查努力"), L("HR per SD (1.27–1.61)", "每 SD 风险比（1.27–1.61）")', 1),
    ('("0.85", L("Warming × effort"', '("0.84", L("Warming × effort"', 1),
    ('("1.00", L("Annual variability"', '("0.99", L("Annual variability"', 1),
    ("deviation for warming, and 1.40 for effort", "deviation for warming, and 1.43 for effort", 1),
    ("分别是 1.36 和 1.40", "分别是 1.36 和 1.43", 1),
    ('L("ΔAIC: warming 28.7 · effort 29.5", "ΔAIC：增温 28.7 · 努力 29.5")', 'L("ΔAIC: warming 29.9 · effort 33.4", "ΔAIC：增温 29.9 · 努力 33.4")', 1),
    ('L("ΔAUC: warming 0.053 · effort 0.032", "ΔAUC：增温 0.053 · 努力 0.032")', 'L("ΔAUC: warming 0.053 · effort 0.033", "ΔAUC：增温 0.053 · 努力 0.033")', 1),
    ('L("Effort HR 1.25–1.52 · warming 1.35–1.37", "努力 HR 1.25–1.52 · 增温 1.35–1.37")',
     'L("Effort HR 1.25–1.55 · warming 1.33–1.39", "努力 HR 1.25–1.55 · 增温 1.33–1.39")', 1),
    ("around 29 AIC units\neach.", "around 30 AIC units or more\neach.", 1),
    ("各约 29 个 AIC 单位", "各约 30 个 AIC 单位或更多", 1),
    ('("×2.23", L("Province × year"', '("×2.22", L("Province × year"', 1),
    ("multiplies the hazard by 2.23", "multiplies the hazard by 2.22", 1),
    ("一个标准差会让风险乘以 2.23", "一个标准差会让风险乘以 2.22", 1),
    ('L("2002: HR 2.18 (1.63–2.90)", "2002 年：HR 2.18（1.63–2.90）")', 'L("2002: HR 2.14 (1.61–2.85)", "2002 年：HR 2.14（1.61–2.85）")', 1),
    ('L("2024: HR 1.07 (0.88–1.30)", "2024 年：HR 1.07（0.88–1.30）")', 'L("2024: HR 1.13 (0.93–1.37)", "2024 年：HR 1.13（0.93–1.37）")', 1),
    ('L("Effort × time: P = 0.00077", "努力 × 时间：P = 0.00077")', 'L("Effort × time: P = 0.0021", "努力 × 时间：P = 0.0021")', 1),
    ('L("Warming × time: P = 0.82", "增温 × 时间：P = 0.82")', 'L("Warming × time: P = 1.00", "增温 × 时间：P = 1.00")', 1),
    ("Its hazard ratio fell from 2.2 in 2002 to about 1.1 in 2024, and\nafter 2022 it is no longer different from one.",
     "Its hazard ratio fell from 2.1 in 2002 to about 1.1 in 2024, and\nfrom 2023 it is no longer different from one.", 1),
    ("它的风险比从 2002 年的 2.2 降到 2024 年的约 1.1，2022 年之后已与 1 没有差别", "它的风险比从 2002 年的 2.1 降到 2024 年的约 1.1，2023 年起已与 1 没有差别", 1),
    ('L("χ² = 25.8, P = 0.001", "χ² = 25.8，P = 0.001")', 'L("χ² = 26.8, P = 0.001", "χ² = 26.8，P = 0.001")', 1),
    ("    top, ymax = y0 + 40, 70.0\n", "    top, ymax = y0 + 40, nice_max(max(v for v, _ in SCEN.values()))\n", 1),
    ("    for t_ in (0, 20, 40, 60):\n        e += [LN(x0 + 40, sy(t_)", "    for t_ in range(0, int(ymax) + 1, 20):\n        e += [LN(x0 + 40, sy(t_)", 1),
    ("    top, ymax = y0 + 50, 65.0\n",
     "    top, ymax = y0 + 50, nice_max(max(v for (f_, s_, e_, h_), (v, _) in MULTI.items() if s_ == \"ssp245\" and h_ == \"2050\"))\n", 1),
    ("    for t_ in (0, 20, 40, 60):\n        e += [LN(x0 + 60, sy(t_)", "    for t_ in range(0, int(ymax) + 1, 20):\n        e += [LN(x0 + 60, sy(t_)", 1),
    ("MULTI = national(\"tbl_future_multimodel_grid.csv\")\n", "MULTI = national(\"tbl_future_multimodel_grid.csv\")\n" + NICE, 1),
    ('L("Faded bars: only 2% of cells in support", "浅色柱：仅 2% 的单元在拟合范围内")', 'L("Faded bars: no cell in support", "浅色柱：没有单元在拟合范围内")', 1),
    ("changes the expected national count from 23.2 to 23.1 records a year", "changes the expected national count from 26.1 to 25.9 records a year", 1),
    ("If\neffort keeps growing, the count more than doubles by 2050.", "If\neffort keeps growing, the count roughly triples by 2050.", 1),
    ("全国期望纪录数从每年 23.2 条变成\n23.1 条，几乎没变。如果调查努力继续增长，到 2050 年数量会翻一倍多。",
     "全国期望纪录数从每年 26.1 条变成\n25.9 条，几乎没变。如果调查努力继续增长，到 2050 年数量约增至三倍。", 1),
    ('L("Is 57 to 62 records a year a forecast? No. At 2050 only 2 percent of cells are inside the fitted support; the credible statement is about 23 to 27 records a year in 2030, under any scenario.",\n'
     '              "每年 57–62 条是预测吗？不是。到 2050 年只有 2% 的单元在拟合范围内；可信的说法是：2030 年在任一情景下约每年 23–27 条。")',
     'L("Is 79 to 89 records a year a forecast? No. At 2050 no cell is inside the fitted support; the credible statement is about 26 to 31 records a year in 2030, under any scenario.",\n'
     '              "每年 79–89 条是预测吗？不是。到 2050 年已没有单元在拟合范围内；可信的说法是：2030 年在任一情景下约每年 26–31 条。")', 1),
    ("the hazard model rises to 57 records a year", "the hazard model rises to 79 records a year", 1),
    ("升到每年 57 条", "升到每年 79 条", 1),
    ('L("2030: 48% → 2050: 10% → 2080: 2%", "2030：48% → 2050：10% → 2080：2%")', 'L("2030: 46% → 2050: 6% → 2080: none", "2030：46% → 2050：6% → 2080：0")', 1),
    ('L("Agree inside the range (ρ = 0.54)", "范围内一致（ρ = 0.54）")', 'L("Agree inside the range (ρ = 0.56)", "范围内一致（ρ = 0.56）")', 1),
    ("drops from 48 percent in 2030, to 10 percent in 2050, and 2 percent by\n2080.",
     "drops from 46 percent in 2030, to 6 percent in 2050, and to none by\n2080, mostly because effort outgrows its observed range.", 1),
    ("从 2030 年的 48%\n降到 2050 年的 10%，2080 年只剩 2%。", "从 2030 年的 46%\n降到 2050 年的 6%，2080 年降为零，主要因为调查努力超出了观测范围。", 1),
    ('L("Warming 1.36 vs effort 1.40 per SD", "每个标准差：增温 1.36，努力 1.40")', 'L("Warming 1.36 vs effort 1.43 per SD", "每个标准差：增温 1.36，努力 1.43")', 1),
    ('L("Warming × effort = 0.85", "增温 × 努力 = 0.85")', 'L("Warming × effort = 0.84", "增温 × 努力 = 0.84")', 1),
    ('L("Province × year ×2.23 is the largest part;", "省份 × 年份 ×2.23 是最大的成分；")', 'L("Province × year ×2.22 is the largest part;", "省份 × 年份 ×2.22 是最大的成分；")', 1),
    ('L("Returns on effort fell from 2.18 to 1.07", "努力的回报从 2.18 降到 1.07")', 'L("Returns on effort fell from 2.14 to 1.13", "努力的回报从 2.14 降到 1.13")', 1),
    # 首轮漏改(目检发现)/ missed in the first pass, found in visual QA
    ('L("Keep effort growing: more than double", "努力继续增长：翻倍以上")', 'L("Keep effort growing: roughly triple", "努力继续增长：约增至三倍")', 1),
    ('L("Random forest / XGBoost: ρ = 0.62–0.90", "随机森林 / XGBoost：ρ = 0.62–0.90")', 'L("Random forest / XGBoost: ρ = 0.59–0.89", "随机森林 / XGBoost：ρ = 0.59–0.89")', 1),
    ('L("ρ = 0.62–0.90 across units", "单元间 ρ = 0.62–0.90")', 'L("ρ = 0.59–0.89 across units", "单元间 ρ = 0.59–0.89")', 1),
    ("with rank correlations between 0.62 and 0.90.", "with rank correlations between 0.59 and 0.89.", 1),
    ("秩相关在 0.62 到\n0.90 之间。", "秩相关在 0.59 到\n0.89 之间。", 1),
]


def null_edits() -> tuple[list, list]:
    """第二轮: 零模型数字, 由重算后的 tbl_null_models 生成 / second pass from the recomputed null table."""
    rows = list(csv.DictReader((TASK / "analysis_v2/tables/tbl_null_models.csv").open(encoding="utf-8-sig")))
    g = lambda nm, term: float(next(r for r in rows if r["null_model"].startswith(nm) and r["term"] == term)["null_median_HR"])
    mq = {r["item"]: float(r["new"]) for r in csv.DictReader((TASK / "analysis_v2/effort2024_audit/model_quantities.csv").open(encoding="utf-8"))}
    n3, n2 = g("N3", "clim_change_z"), g("N2", "effort_z")
    inc = mq["hr_change"] / n3
    a, r, e = f"{n3:.2f}", f"{inc:.2f}", f"{n2:.2f}"
    v4 = [("A permutation null puts the baseline at 1.16, so the \"\n            \"species-specific increment is about ×1.18 per SD.",
           f"A permutation null puts the baseline at {a}, so the \"\n            \"species-specific increment is about ×{r} per SD.", 1),
          ("Warming null 1.16: increment ×1.18", f"Warming null {a}: increment ×{r}", 1),
          ("Shuffled effort timing: 0.98", f"Shuffled effort timing: {e}", 1),
          ("about 1.18, and effort collapses to 0.98 if we break its timing.", f"about {r}, and effort collapses to {e} if we break its timing.", 1)]
    v3 = [("A permutation null puts the baseline at 1.16, so the species-specific increment is about ×1.18 per SD.",
           f"A permutation null puts the baseline at {a}, so the species-specific increment is about ×{r} per SD.", 1),
          ("置换零模型的基线是 1.16，所以物种特异的增量约为每个标准差 ×1.18。", f"置换零模型的基线是 {a}，所以物种特异的增量约为每个标准差 ×{r}。", 1),
          ('L("Warming null 1.16 → increment ×1.18", "增温零模型 1.16 → 增量 ×1.18")', f'L("Warming null {a} → increment ×{r}", "增温零模型 {a} → 增量 ×{r}")', 1),
          ('L("Shuffle effort timing: falls to 0.98", "打乱努力的时间：降到 0.98")', f'L("Shuffle effort timing: falls to {e}", "打乱努力的时间：降到 {e}")', 1),
          ("warming increment over its null is about 1.18, and effort collapses to 0.98 if we break its timing.",
           f"warming increment over its null is about {r}, and effort collapses to {e} if we break its timing.", 1),
          ("增温相对零模型的增量约 1.18，\n而打乱努力的时间，它会降到 0.98。", f"增温相对零模型的增量约 {r}，\n而打乱努力的时间，它会降到 {e}。", 1)]
    return v3, v4


def apply(path: pathlib.Path, edits: list, dry: bool) -> int:
    text = path.read_text(encoding="utf-8")
    bad = 0
    for old, new, k in edits:
        done = (new in text) if old in new else (new in text and old not in text)
        if done:
            continue
        n = text.count(old)
        if n != k:
            bad += 1
            logger.warning("MISSING %s (found %d, expected %d) | %s", path.name, n, k, old[:80].replace("\n", " "))
            continue
        text = text.replace(old, new)
        logger.info("applied %s ×%d | %s", path.name, k, new[:70].replace("\n", " "))
    if not dry and not bad:
        path.write_text(text, encoding="utf-8")
    elif bad:
        logger.warning("%s 未写回(有 %d 条未匹配)/ not written (%d unmatched)", path.name, bad, bad)
    return bad


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true"); ap.add_argument("--nulls", action="store_true")
    args = ap.parse_args()
    if args.nulls:
        v3, v4 = null_edits()
    else:
        v3, v4 = V3_EDITS, V4_EDITS
    bad = apply(V3, v3, args.dry_run) + apply(V4, v4, args.dry_run)
    logger.info("完成;未匹配 %d 条 / done; unmatched %d", bad, bad)


if __name__ == "__main__":
    main()
