# GCB 上传清单 / Upload guide

本目录可直接用于投稿。下表「上传类别」为投稿系统中的文件类型;压缩包 `_archives/GCB_upload_20261014.zip` 内的文件按此顺序编号。

| 编号 | 文件 | 上传类别 | 说明 |
|---|---|---|---|
| 01 | `Manuscript_GCB_main_document.docx` | Main Document | 题名页、摘要、关键词、正文、致谢、声明、参考文献,其后为表与图注(Wiley 常规结构) |
| 02 | `figures/Figure1–7.pdf` | Figure | 矢量 PDF,每图一个文件;450 dpi PNG 为备用 |
| 03 | `pdf/Supporting_Information_GCB.pdf` | Supporting Information | Notes S1–S7、Tables S1–S10、Figs S1–S21;每张图与图注同页。可编辑版 `Supporting_Information_GCB.docx` |
| 04 | `cover_letter_GCB.docx` | Cover Letter | GCB 七问格式;第 7 题推荐审稿人待作者填写 |
| 05 | `Translated_Abstract_zh.docx` | Supplementary Material Not for Review | 中文摘要(GCB 鼓励提供) |
| — | `figures/*.pptx · figures_SI/*.pptx` | 按需 | 全部主图与 SI 图的可编辑 PPTX(原生形状、文字可改;4 张县级多图地图为嵌图版) |
| — | `figures_polished/` | 备选 | 顶刊设计版主图(同一数据, 统一配色与版式), PDF + PNG + 可编辑 PPTX |
| — | `../data_and_code/` | 按编辑部要求 | 数据、代码、各图源数据与运行环境;压缩包 `_archives/data_and_code_日期.zip` |
| — | `pdf/` | 不上传 | 合作者审阅用 PDF:含图全文、SI、投稿信 |

**编辑与重建**:`*.md` 是唯一可编辑源;改动后依次运行 205(渲染)→ 207(词数)→ 212(终检)→ 215(本包)。直接在 docx 中修改的内容须回写 md,否则会在下次重建时丢失。

**投稿前仍须作者补齐**:作者名单与单位、ORCID、CRediT(`../CRediT_and_authors_TEMPLATE.md`)、基金与项目编号、预印本声明、推荐审稿人;详见 `../SUBMISSION_CHECKLIST.md`。
