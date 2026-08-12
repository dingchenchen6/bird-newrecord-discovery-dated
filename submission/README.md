# 投稿 Word 文件与期刊适配说明

## 文件

| 文件 | 内容 | 页数 |
|---|---|---|
| `Manuscript_NatureFamily_maintext.docx` | 题名、作者、摘要、Introduction、Results、Discussion、References、Methods | 45 |
| `Manuscript_NatureFamily_tables_and_legends.docx` | Table 1–9(真正的 Word 表格)、全部图注 | 15 |
| `wordcount_vs_journal_limits.csv` | 字数与三家硬约束的逐项比对 |  |

格式：Times New Roman 12 pt、双倍行距、上下左右 1 英寸边距、**连续行号**、页脚居中页码。
引文为编号上标（Nature 系样式）。图件按 Nature 政策单独提交，正文只留图注；
主图 PDF 在 `analysis_v2/figures/`、`figures_pa/`、`figures_admin/`、`figures_rf/`。

生成命令：

```bash
python3.11 code/200_build_submission_docx.py
```

---

## 字数现状与三家的差距

**当前文稿按 Nature 系结构写成，但长度是 GCB 的量级。**

| 项目 | 现状 | NEE | NC | GCB |
|---|---|---|---|---|
| 摘要词数 | **428** | ~150 | ≤150 | ≤250 |
| 正文（Intro+Results+Disc） | **7,751** | ~3,500 | ~5,000（建议） | — |
| 全文含 Methods | **9,191** | — | — | ≤8,000 |
| 参考文献 | 82 | 正文约 50 | 不限 | 不限 |
| 展示项（9 表 + 18 图） | **27** | ≤6 | ≤10 | 从宽 |

三家都需要压缩，程度差别很大：

- **NEE**：正文要砍到 45%，摘要砍到 35%，展示项砍到 22%。这不是编辑加工，是重写。
- **NC**：正文砍到 65%，摘要砍到 35%，展示项砍到 37%。工作量中等。
- **GCB**：全文砍 13%（9,191 → 8,000），摘要砍到 58%，展示项基本不用动。**改动最小。**

但 GCB 需要两处结构性改造，Nature 系不需要：

1. **引文改为作者-年份制**（Wiley/GCB 用 author–date），82 条编号引文需逐条映射
2. **Methods 移到 Introduction 之后**，改为常规 IMRaD 顺序

---

## 建议的压缩路径

Results 占 6,246 词，是压缩的主战场。可搬进 Supplementary 的整段：

| 小节 | 词数量级 | 处置建议 |
|---|---|---|
| 迁徙策略分层 | 中 | 整体移入 SI，正文留两句 |
| 物种尺度与省级尺度 | 大 | 移入 SI，正文留结论句 + 指向 SI 图 |
| 方向偏倚 | 中 | 正文保留一段（它是四条主结论之一） |
| 稳健性（阈值/指标/窗口/基线/努力代理） | 大 | 整体移入 SI，正文压成一句「在 N 种设定下方向不变（SI 表 Sx）」|
| 模型充分性与重抽样 | 中 | 移入 SI，正文留一句 |
| 保护地关联 | 中 | 若投 NEE/NC 建议整体移出，单独成文 |
| 市县降尺度 | — | 尚未写入文稿正文 |

按上表处理后，正文可压到约 3,800–4,200 词——够 NC，接近 NEE 但仍需再砍一轮。

摘要 428 → 150 需要重写，不是删句：Nature 系摘要不带引文、不分小标题，
通常是 1 句背景 + 1 句问题 + 3–4 句结果 + 1 句意义。

---

## 尚未完成的投稿件

以下是投稿必需但目前没有的，按需要补：

- Cover letter
- 作者贡献声明（CRediT）、利益冲突声明、致谢、基金号
- 完整作者名单与单位（当前为 `Chenchen Ding, et al.`，单一单位占位）
- Supplementary Information 文档（把上表移出的内容组织成 SI）
- Extended Data 图件的正式编号与文件（当前 Fig. 1、3、5 编号不连续）
- Data availability 与 Code availability 的正式表述（仓库 README 已有素材）
- 图件按目标期刊的尺寸与分辨率重新导出（NEE/NC 单栏 89 mm、双栏 183 mm）

---

## 已知的小问题

- 行号从第 2 行开始计（第 1 行是空段），Word 中重新编号即可
- `Extended Data Fig.` 编号为 1、3、5，不连续，投稿前需重排
- 表格与图注在单独文件，若目标期刊要求单文件投稿，合并即可
