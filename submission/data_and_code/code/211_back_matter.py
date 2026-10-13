#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   投稿稿件是否满足三刊的强制性声明与数据引用要求?
#   Do the three manuscripts meet each journal's mandatory statements and data-citation rules?
#
# Objective / 目标:
#   依据 2026-09-24 核对的官方要求, 为三版正文补齐/重写后置章节并修正数据来源表述:
#   - Nature 系(NEE/NC): Methods 之后依次为 Data availability → Code availability →
#     References → Acknowledgements → Author contributions → Competing interests;
#     生成式 AI 使用在 Methods 中披露(Nature Portfolio AI 政策)。
#   - GCB: Acknowledgements(计入 8,000 词)→ Conflict of interest → Data availability
#     statement → References;running title(<45 字符)与 6–10 个关键词;AI 使用在致谢中披露。
#   - 数据集(CBNR v2、保护区边界、BirdLife 分布图)与代码在参考文献中正式引用。
#   - 修正通讯邮箱(个人主页核实为 chenchen.ding@pku.edu.cn)。
#
# Input / 输入:  analysis_v2/submission/{GCB,NEE,NC}/Manuscript_*_maintext.md
# Output / 输出: 原地改写上述 .md(docx 由脚本 205 重渲染)
# Key assumptions / 关键假设:
#   - 幂等:已存在的目标章节不会重复插入
#   - 作者名单、基金、作者贡献等须作者提供的信息以方括号占位, 并列入核对表
# ============================================================
from __future__ import annotations

import re
from pathlib import Path

SUB = Path(__file__).resolve().parent.parent / "analysis_v2" / "submission"
REPO = "https://github.com/dingchenchen6/bird-newrecord-discovery-dated"

# ---------- 通用替换 / shared fixes ----------
EMAIL_OLD, EMAIL_NEW = "dingchenchen@pku.edu.cn", "chenchen.ding@pku.edu.cn"
EFFORT_OLD = "Provincial annual survey effort was compiled from integrated observation records through four proxies"
EFFORT_NEW = ("Provincial annual survey effort was compiled from deduplicated eBird/GBIF occurrence records "
              "and China Bird Report checklists (http://www.birdreport.cn) through four proxies")
AI_TEXT = ("The authors used Claude (Anthropic) to assist with drafting and editing text, checking numerical "
           "consistency and writing figure code; they reviewed and verified all content and take full "
           "responsibility for it.")

# ---------- Nature 系参考文献(追加后由 205 按首次出现重编号) ----------
NAT_REFS = {
    "CBNR": ("Ding, C. et al. A dataset of provincial-level new distribution records for birds in China from "
             "2000 to 2025 (China Bird New Record dataset, CBNR), version 2. Zenodo "
             "https://doi.org/10.5281/zenodo.20809949 (2026)."),
    "BOTW": ("BirdLife International & Handbook of the Birds of the World. Bird species distribution maps of "
             "the world, version 2024. http://datazone.birdlife.org/species/requestdis (2024)."),
    "NR": ("China Nature Reserve Specimen Resource Sharing Platform. List and vector boundaries of nature "
           "reserves in China. Zenodo https://doi.org/10.5281/zenodo.14875797 (2024)."),
    "CODE": (f"Ding, C. Analysis code for 'Warming and survey effort contribute comparably to new bird "
             f"distribution records when dated to discovery'. GitHub {REPO} (2026)."),
}


def nature_version(key: str) -> None:
    f = SUB / key / f"Manuscript_{key}_maintext.md"
    s = f.read_text(encoding="utf-8")
    if "\n## Data availability\n" in s:
        print(f"[{key}] 已有 Data availability, 跳过"); return
    s = s.replace(EMAIL_OLD, EMAIL_NEW)
    s = s.replace("Correspondence: " + EMAIL_NEW, "Correspondence: Chenchen Ding (" + EMAIL_NEW + ")")
    # Nature 版措辞为 "...observation records and expressed through four proxies"
    eo = "Provincial annual survey effort was compiled from integrated observation records and expressed"
    en = ("Provincial annual survey effort was compiled from deduplicated eBird/GBIF occurrence records and "
          "China Bird Report checklists (http://www.birdreport.cn) and expressed")
    assert eo in s, key; s = s.replace(eo, en, 1)

    # 抽出 References 块(位于 Discussion 与 Methods 之间)
    i = s.index("## References\n"); j = s.index("\n## Methods\n", i)
    refs_block, s = s[i:j].rstrip() + "\n", s[:i] + s[j + 1:]
    n0 = len(re.findall(r"^\d+\.\s", refs_block, re.M))
    num = {k: n0 + 1 + t for t, k in enumerate(NAT_REFS)}
    refs_block += "".join(f"\n{num[k]}. {NAT_REFS[k]}\n" for k in NAT_REFS)

    # Methods: 事件数据引用 CBNR 数据集并说明提取流程;分布区多边形引用 BOTW
    old_ev = "were taken from the released compilation of 1,029 records covering 2000–2025^14^."
    new_ev = (f"were taken from version 2 of the China Bird New Record dataset (CBNR; 1,029 records covering "
              f"2000–2025)^14,{num['CBNR']}^, compiled from peer-reviewed publications with a "
              f"large-language-model-assisted extraction pipeline followed by manual validation of every record^14^.")
    assert old_ev in s, key; s = s.replace(old_ev, new_ev, 1)
    old_rg = "are means over the species' Chinese range polygon."
    assert old_rg in s, key
    s = s.replace(old_rg, f"are means over the species' Chinese range polygon^{num['BOTW']}^.", 1)

    # 删除旧的 Methods 小节 "Data and code availability"(含其后分隔线)
    s = re.sub(r"\n### Data and code availability\n\n.*?(\n---\s*)?$", "\n", s, flags=re.S).rstrip() + "\n"

    s += (f"\n### Use of generative AI\n\n{AI_TEXT}\n"
          f"\n## Data availability\n\n"
          f"The new-record data analysed in this study are version 2 of the China Bird New Record dataset (CBNR), "
          f"openly available under a CC BY 4.0 licence at https://doi.org/10.5281/zenodo.20809949 (ref. {num['CBNR']}). "
          f"Nature-reserve boundaries are openly available at https://doi.org/10.5281/zenodo.14875797 (ref. {num['NR']}). "
          f"Historical monthly climate (WorldClim 2.1 downscaling of CRU TS 4.09) and CMIP6 projections are publicly "
          f"available from WorldClim (https://www.worldclim.org). Species range maps (ref. {num['BOTW']}) are available "
          f"on request from BirdLife International (http://datazone.birdlife.org/species/requestdis); their licence does "
          f"not permit redistribution. Survey-effort indicators were derived from eBird/GBIF occurrence records and China "
          f"Bird Report checklists (http://www.birdreport.cn); the raw records remain subject to their providers' terms, "
          f"and the province-year effort panel used in all analyses is provided in the project repository together with "
          f"the risk set, the derived climate panels and every result table (ref. {num['CODE']}).\n"
          f"\n## Code availability\n\n"
          f"All analysis code (R 4.5.1 with glmmTMB 1.1.14, DHARMa 0.4.7, ranger 0.18.0, xgboost 3.2.1.1, sf 1.0.23 "
          f"and terra 1.8.86) is available at {REPO} (ref. {num['CODE']}) and will be archived with a DOI on Zenodo upon "
          f"acceptance. Numbered scripts reproduce every number, table and figure from the released inputs; a smoke test "
          f"re-derives the four main-model coefficients in about two minutes.\n"
          f"\n{refs_block}"
          f"\n## Acknowledgements\n\nWe thank the birdwatchers who contributed observations to eBird and China Bird Report, "
          f"and the authors of the publications compiled in CBNR. [Funding sources and grant numbers to be added by the authors.]\n"
          f"\n## Author contributions\n\n[To be completed by the authors using CRediT roles; see CRediT_and_authors_TEMPLATE.md.]\n"
          f"\n## Competing interests\n\nThe authors declare no competing interests.\n")
    f.write_text(s, encoding="utf-8")
    print(f"[{key}] 后置章节已重排;新增文献 {n0 + 1}–{n0 + len(NAT_REFS)}")


# ---------- GCB(作者-年份制) ----------
GCB_REFS = [  # (排序键, 条目)
    ("BirdLife", NAT_REFS["BOTW"]),
    ("China Nature", NAT_REFS["NR"]),
    ("Ding, C. Analysis", NAT_REFS["CODE"]),
    ("Ding, C., Zhao", "Ding, C., Zhao, H., Wang, Z., Li, L., Ding, J., Jiang, Z., Zhang, Z. & Wang, Z. A dataset of "
                       "provincial-level new distribution records for birds in China from 2000 to 2025 (China Bird New "
                       "Record dataset, CBNR), version 2. Zenodo https://doi.org/10.5281/zenodo.20809949 (2026)."),
]


def gcb_version() -> None:
    f = SUB / "GCB" / "Manuscript_GCB_maintext.md"
    s = f.read_text(encoding="utf-8")
    if "\n## Data availability statement\n" in s:
        print("[GCB] 已处理, 跳过"); return
    s = s.replace(EMAIL_OLD, EMAIL_NEW)
    s = s.replace("Correspondence: " + EMAIL_NEW, "Correspondence: Chenchen Ding (" + EMAIL_NEW + ")")
    # 题名页要素:running title(<45 字符)
    rt = "Warming and effort in new bird records"
    assert len(rt) < 45
    s = s.replace("\n\nChenchen Ding^1^, et al.\n", f"\n\n**Running title:** {rt}\n\nChenchen Ding^1^, et al.\n", 1)
    # 关键词(6–10)置于摘要之后
    kw = ("biodiversity monitoring; China; citizen science; climate change; discrete-time hazard model; "
          "new distribution records; observation bias; range shift; survey effort")
    assert 6 <= len(kw.split("; ")) <= 10
    i = s.index("## Abstract\n"); j = s.index("\n## Introduction\n", i)
    s = s[:j].rstrip() + f"\n\n**Keywords:** {kw}\n" + s[j:]
    # Methods 数据来源
    assert EFFORT_OLD in s; s = s.replace(EFFORT_OLD, EFFORT_NEW, 1)
    old_ev = "were taken from the released compilation of 1,029 records covering 2000–2025 (Ding et al., in review)."
    new_ev = ("were taken from version 2 of the China Bird New Record dataset (CBNR; 1,029 records covering "
              "2000–2025; Ding et al., 2026), compiled from peer-reviewed publications with a "
              "large-language-model-assisted extraction pipeline followed by manual validation of every record "
              "(Ding et al., in review).")
    assert old_ev in s; s = s.replace(old_ev, new_ev, 1)
    s = s.replace("are means over the species' Chinese range polygon.",
                  "are means over the species' Chinese range polygon (BirdLife International & Handbook of the "
                  "Birds of the World, 2024).", 1)
    # 保护区数据须在 M&M 中引用(GCB 数据引用要求)
    old_pa = "\n### Data and code availability\n"
    pa_sent = ("\n### Protected areas\n\nProtected-area analyses (Supporting Information Note S6) used the 1,028 "
               "mapped nature reserves in China (China Nature Reserve Specimen Resource Sharing Platform, 2024).\n")
    s = re.sub(r"\n### Data and code availability\n\n.*?\n---\n", pa_sent, s, count=1, flags=re.S)
    assert "### Protected areas" in s
    # 后置章节(置于 References 之前)
    ack = ("We thank the birdwatchers who contributed observations to eBird and China Bird Report, and the authors "
           "of the publications compiled in CBNR. [Funding sources and grant numbers to be added by the authors.] "
           + AI_TEXT)
    das = (f"The new-record data analysed in this study are version 2 of the China Bird New Record dataset (CBNR), "
           f"openly available under a CC BY 4.0 licence in Zenodo at https://doi.org/10.5281/zenodo.20809949 "
           f"(Ding et al., 2026). Nature-reserve boundaries are openly available in Zenodo at "
           f"https://doi.org/10.5281/zenodo.14875797 (China Nature Reserve Specimen Resource Sharing Platform, 2024). "
           f"Historical monthly climate (WorldClim 2.1 downscaling of CRU TS 4.09; Fick & Hijmans, 2017; Harris et al., "
           f"2020) and CMIP6 projections are publicly available from WorldClim (https://www.worldclim.org). Species "
           f"range maps (BirdLife International & Handbook of the Birds of the World, 2024) are available on request "
           f"from BirdLife International (http://datazone.birdlife.org/species/requestdis); their licence does not "
           f"permit redistribution. Survey-effort indicators were derived from eBird/GBIF occurrence records and China "
           f"Bird Report checklists (http://www.birdreport.cn); the raw records remain subject to their providers' "
           f"terms, and the province-year effort panel is provided in the project repository. All analysis code "
           f"(R 4.5.1), the risk set, the derived climate and effort panels and every result table are available at "
           f"{REPO} (Ding, 2026) and will be archived in Zenodo with a DOI upon acceptance; the model equations and "
           f"all parameter estimates are given in Materials and Methods and Supporting Information.")
    back = (f"## Acknowledgements\n\n{ack}\n\n## Conflict of interest statement\n\n"
            f"The authors declare no conflicts of interest.\n\n## Data availability statement\n\n{das}\n\n")
    s = s.replace("## References\n", back + "## References\n", 1)
    # 参考文献按字母序插入
    i = s.index("## References\n") + len("## References\n")
    entries = [b.strip() for b in s[i:].split("\n\n") if b.strip()]
    for _, e in GCB_REFS:
        if e not in entries:
            entries.append(e)
    entries.sort(key=lambda e: re.sub(r"[^A-Za-z ,.]", "", e).lower())
    s = s[:i] + "\n" + "\n\n".join(entries) + "\n"
    f.write_text(s, encoding="utf-8")
    print("[GCB] 题名页/关键词/数据来源/后置章节/数据引用已补齐")


# ---------- 其余含错误邮箱的文件 ----------
def fix_email_elsewhere() -> None:
    for rel in ("Manuscript_NatureFamily_maintext.md", "CRediT_and_authors_TEMPLATE.md", "GCB/cover_letter_GCB.md"):
        f = SUB / rel
        s = f.read_text(encoding="utf-8")
        if EMAIL_OLD in s:
            f.write_text(s.replace(EMAIL_OLD, EMAIL_NEW), encoding="utf-8"); print(f"[email] {rel} 已修正")


if __name__ == "__main__":
    for k in ("NEE", "NC"):
        nature_version(k)
    gcb_version()
    fix_email_elsewhere()
