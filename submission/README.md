# 投稿包 / Submission package

三个期刊版本由同一套结果派生,共用一份数据、模型与图件源码;差别只在长度、结构与引文体例。
**数值结论三版完全一致。** 每个期刊目录都可直接用于上传:打开其中的 `00_UPLOAD_GUIDE.md`,
按编号逐项上传即可;`_archives/` 中的压缩包是同一套上传文件的打包版本。

## 目录

```
submission/
├── GCB/                 Global Change Biology 版(IMRaD,作者-年份引文)
│   ├── 00_UPLOAD_GUIDE.md             上传清单(文件 → 投稿系统类别)
│   ├── Manuscript_GCB_main_document.docx   上传用主文档:正文 + 表 + 图注
│   ├── figures/                       Figure1–7(矢量 PDF + 450 dpi PNG)
│   ├── pdf/                           含图全文、SI、投稿信的 PDF(SI 上传用 PDF)
│   ├── cover_letter_GCB.docx          GCB 七问格式
│   ├── Translated_Abstract_zh.docx    中文摘要
│   └── *.md / 其余 docx               可编辑源与分件(正文、表与图注、SI)
│   ├── figures_SI/                    全部 SI 图的可编辑 PPTX(FigS1…)
│   ├── figures_polished/              顶刊设计版主图(PDF + PNG + 可编辑 PPTX),见 FIGURES_POLISHED_NOTES.md
├── NEE/  NC/            Nature Ecology & Evolution / Nature Communications 版
│   ├── Manuscript_{J}_complete.docx   上传用单文件稿件:正文 + 表 + 图注,图嵌在图注前
│   ├── pdf/Supplementary_Information_{J}.pdf   上传用 SI(Nature 系要求单一合并 PDF)
│   ├── ReportingSummary_DRAFT_{J}.docx         Reporting Summary 逐题草稿
│   └── cover_letter_{J}.docx, figures/, 可编辑源
├── data_and_code/       数据、代码、各图源数据与运行环境(公开仓库复现核心的冻结快照)
├── presentation/
│   ├── AOC2026_v3_redesign/           2026-10 新版报告:同一叙事三种风格(浅色/深色/暖色)+ 中文版,含讲稿
│   ├── AOC2026_Singapore_EN/          英文会议报告 20 页(pptx + pdf)与中英对照讲稿
│   └── 鸟类新纪录生成风险_会议报告_20页_v8.{pptx,pdf}   中文报告
├── _archives/           {GCB,NEE,NC}_upload_日期.zip、presentation_日期.zip、data_and_code_日期.zip
├── editable_figures_manifest.csv    每个可编辑 PPTX 的来源、形状数与回渲染差异
├── FIGURES_POLISHED_NOTES.md        顶刊版主图:改了什么、改用时图注要补哪句
├── work/                修订说明与中间件(REVISION_NOTES_*.md)
├── SUBMISSION_CHECKLIST.md          逐项投稿核对表
├── FIGURE_MANIFEST.md               图件清单
├── THREE_VERSIONS.md                三版差异说明
├── CRediT_and_authors_TEMPLATE.md   作者与贡献声明模板(待作者填写)
├── ReportingSummary_DRAFT_NatureFamily.*   Reporting Summary 共用源稿
└── three_versions_wordcount.csv     分节词数与硬约束对照
```

根目录下的 `Manuscript_NatureFamily_*` 是**三版共同的历史源稿**(装配脚本 202 的
输入),不是投稿件;`wordcount_vs_journal_limits.csv` 为早期对照,已由
`three_versions_wordcount.csv` 取代。两者保留以便追溯。

> ⚠️ 源稿早于 2026-09-24 的修订:其中「新纪录强烈偏向东与东北」的结论已被几何零假设检验推翻
> (脚本 214;见三版正文「Records lie slightly north of where geometry and effort place them」)。
> 请勿再从源稿摘取正文文字。

## 当前状态(2026-10-13)

| | GCB | NEE | NC |
|---|---|---|---|
| 字数 / 上限 | **7,959 / 8,000**(含致谢) | **3,404 / 3,500** | **4,967 / 5,000** |
| 摘要 / 上限 | **293 / 300** | **189 / 200** | **197 / 200** |
| 参考文献 | 38 | 37 | 37 |
| 正文图 | 7 | 5 | 7 |
| SI(Notes / Tables / Figs) | 7 / 10 / 21 | 11 / 12 / 23 | 8 / 10 / 20 |
| 引文体例 | 作者-年份 | 编号上标 | 编号上标 |
| 上传压缩包 | 13.0 MB | 15.4 MB | 16.7 MB |

各刊限额于 2026-09-24 核对官方页面;Nature 系初投格式与 SI 要求于 2026-09-27 复核。
逐项状态见 `SUBMISSION_CHECKLIST.md`。

## 重新生成

```bash
Rscript --no-init-file code/186_spatiotemporal_pattern_en.R   # SI 时空格局图(CBNR v2, 1,029 条)
Rscript --no-init-file code/214_direction_geometric_null.R    # 方向的几何零假设(须先于 154)
Rscript --no-init-file code/154_directional_windrose_radar.R   # 方向图(主图读取 214 的结果)
Rscript --no-init-file code/216_aoc_direction_null_figure.R    # 报告用方向图
python3.11 code/203_gcb_package.py        # GCB 包(图注与 SI 由 docs/MANUSCRIPT_v2.md 生成)
python3.11 code/204_nee_nc_packages.py    # NEE / NC 包
python3.11 code/205_prune_references.py   # 文献裁剪与重编号;渲染正文(双倍行距)与 SI(1.15 倍)docx
python3.11 code/206_restyle_tables.py     # 全部表格改为三线表
python3.11 code/217_editable_figures.py    # 主图与 SI 图的可编辑 PPTX;顶刊版主图按各刊编号放入 figures_polished/
Rscript --no-init-file code/218a_tj_main_results.R   # 顶刊版主图(218a–218d,共用主题 218_theme_topjournal.R)
python3.11 code/219_data_code_package.py   # data_and_code/ 与压缩包
python3.11 code/215_build_final_package.py  # 完整稿件、投稿信、PDF、Reporting Summary、PPT 同步、上传压缩包
wm-clean <交付文件…>                         # 清除 AI 印记(不处理代码与数据),之后运行 215 --zips-only 与 219 --zip-only
python3.11 code/207_recount_wordcounts.py # 只读复核词数
python3.11 code/212_package_qc.py         # 终检(须 0 失败)
python3.11 code/213_ai_style_scan.py      # 写作风格扫描
python3.11 code/220_sync_public_repo.py   # 同步到公开仓库克隆(只改工作区,提交与推送另行执行)
```

- 所有 R 脚本须 `--no-init-file` 且在任务根目录运行。
- **`code/202_assemble_journal_versions.py` 会覆盖手工改写的正文,不要运行。**
- 会议报告由 deck 工程生成:英文 `~/.claude/skills/easyslides/projects/bird_talk_aoc2026_en_ppt169_20260923/`
  (`build_deck_en.py` → easyslides 导出 → `src/make_script_doc.py`),中文
  `…/bird_talk_v2_ppt169_20260816/`(`build_deck.py` → 导出 → `export_pdf_cjk.py` 生成 PDF;
  本机无微软雅黑,直接转 PDF 会回退到手写体)。215 负责把两份 deck 同步进本目录。

## 图件

- 全部投稿图件为英文;地图底图审图号 GS(2019)1822,含南海诸岛与九段线,未作几何改动。
- 方位主图(GCB 图 6 / NEE 图 4 / NC 图 5)为三联图:观测与两个零假设的方位份额、
  各方位观测/期望比及 95% 蒙特卡洛区间、六个目的风玫瑰。
- 版面字号:正文图在 GCB 全页宽(176 mm)下最小 5.3–6.2 pt,满足 Nature 系 5 pt 下限;
  GCB 要求最终 8 pt,定稿时由编辑部排版确认。
- 排版质检:`python3.11 code/208_figure_qc.py <pdf>...`。

## 仍需作者提供(详见核对表第 4 节)

- 完整作者名单、单位、ORCID 与 CRediT 贡献声明(见 `CRediT_and_authors_TEMPLATE.md`)
- 基金来源与项目编号(三版致谢中的方括号占位;GCB 已预留约 41 词余量)
- GCB 的五位推荐审稿人(姓名 + 机构邮箱);NEE/NC 的推荐与回避审稿人(可选);是否有预印本
- 正文中 S0 "previously published specification" 的正式引文
- GBIF 下载 DOI(或注册 GBIF derived dataset);代码仓库的 Zenodo DOI(接收后)
- 确认:竞争利益声明、AI 使用披露措辞、CBNR 数据论文状态("in review")、方位结论的更正
