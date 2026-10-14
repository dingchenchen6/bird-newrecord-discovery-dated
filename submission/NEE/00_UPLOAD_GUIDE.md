# NEE 上传清单 / Upload guide

本目录可直接用于投稿。下表「上传类别」为投稿系统中的文件类型;压缩包 `_archives/NEE_upload_20261014.zip` 内的文件按此顺序编号。

| 编号 | 文件 | 上传类别 | 说明 |
|---|---|---|---|
| 01 | `Manuscript_NEE_complete.docx` | Manuscript | 单文件:正文、Methods、参考文献、声明,其后为表与图注,图嵌在图注前(NEE 初投接受 Word/PDF) |
| 02 | `pdf/Supplementary_Information_NEE.pdf` | Supplementary Information | Nature 系要求单一合并 PDF,每张图与图注同页;Notes S1–S11、Tables S1–S12、Figs S1–S23。可编辑版 `Supplementary_Information_NEE.docx` |
| 03 | `cover_letter_NEE.docx` | Cover Letter | 推荐/回避审稿人待作者补充 |
| 04 | `ReportingSummary_DRAFT_NEE.docx` | Reporting Summary | 逐题答案草稿,须粘贴进官方 Reporting Summary 表格 |
| 05 | `figures/Fig1–5.pdf` | Figure(接收后/修回时) | 矢量 PDF 与 450 dpi PNG;初投已嵌入完整稿件 |
| — | `figures/*.pptx · figures_SI/*.pptx` | 按需 | 全部主图与 SI 图的可编辑 PPTX(原生形状、文字可改;4 张县级多图地图为嵌图版) |
| — | `figures_polished/` | 备选 | 顶刊设计版主图(同一数据, 统一配色与版式), PDF + PNG + 可编辑 PPTX |
| — | `../data_and_code/` | 按编辑部要求 | 数据、代码、各图源数据与运行环境;压缩包 `_archives/data_and_code_日期.zip` |
| — | `pdf/` | 不上传 | 合作者审阅用 PDF |

**编辑与重建**:`*.md` 是唯一可编辑源;改动后依次运行 205(渲染)→ 207(词数)→ 212(终检)→ 215(本包)。直接在 docx 中修改的内容须回写 md,否则会在下次重建时丢失。

**投稿前仍须作者补齐**:作者名单与单位、ORCID、CRediT(`../CRediT_and_authors_TEMPLATE.md`)、基金与项目编号、预印本声明、推荐审稿人;详见 `../SUBMISSION_CHECKLIST.md`。
