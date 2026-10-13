# Submission checklist

状态图例:✅ 已完成并核验 · ⚠️ 需作者确认 · ⬜ 投稿系统内填写

## 0. 上传即用(2026-09-27)

| | GCB | NEE | NC |
|---|---|---|---|
| 上传清单 | ✅ `GCB/00_UPLOAD_GUIDE.md` | ✅ `NEE/00_UPLOAD_GUIDE.md` | ✅ `NC/00_UPLOAD_GUIDE.md` |
| 上传用稿件 | ✅ `Manuscript_GCB_main_document.docx`(正文 + 表 + 图注;图单独上传) | ✅ `Manuscript_NEE_complete.docx`(正文 + 表 + 图注,5 图嵌入) | ✅ `Manuscript_NC_complete.docx`(7 图嵌入) |
| 上传用 SI | ✅ `pdf/Supporting_Information_GCB.pdf`(34 页) | ✅ `pdf/Supplementary_Information_NEE.pdf`(41 页) | ✅ `pdf/Supplementary_Information_NC.pdf`(34 页) |
| 投稿信 | ✅ docx + pdf | ✅ docx + pdf | ✅ docx + pdf |
| 必需表格 | ✅ 中文摘要 | ✅ Reporting Summary 草稿 | ✅ Reporting Summary 草稿 |
| 审阅用含图全文 PDF | ✅ 44 页 | ✅ 33 页 | ✅ 40 页 |
| 压缩包 `_archives/` | ✅ 13.0 MB | ✅ 15.4 MB | ✅ 16.7 MB |

依据:NEE 初投接受 Word/PDF,稿件文件应含图(nature.com/natecolevol/submission-guidelines,
2026-09-27 核对);NC 初投格式灵活、单图注 ≤350 词(三版图注最长 209 词);Nature 系 SI 须为
**单一合并 PDF,且每张图与图注在同一页**;三份 SI PDF 已逐图核验 0 处跨页。
GCB 按 Wiley 常规结构(参考文献后接表与图注,图件单独上传);Wiley 作者页有人机验证,本轮未能在线复核。

## 0b. 2026-10-13 新增

- ✅ **可编辑图件**:三刊全部主图与 SI 图共 83 个 PPTX(原生形状、文字可改,幻灯片尺寸 = 图件尺寸);
  4 张县级多图地图(矢量 PDF > 50 MB)与 DHARMa 残差图为嵌图版;回渲染差异全部在阈值内(`editable_figures_manifest.csv`)
- ✅ **顶刊设计版主图**:7 张源图 → 三刊 19 个图位(`figures_polished/`),数值与原图逐值核对一致;改用时的图注调整见
  `FIGURES_POLISHED_NOTES.md`
- ✅ **数据与代码**:`data_and_code/`(84 个脚本、建模数据、94 张结果表、19 份按刊编号的主图源数据、renv.lock 与 sessionInfo)
- ✅ **会议报告新版**:`presentation/AOC2026_v3_redesign/`,与已提交摘要一致(定年对比移入备用页;数据页并列 v1.1 与 v2 计数),
  浅色学术、深色主讲、暖色杂志三种风格 + 中文版;19 页主线约 10.8 分钟,另 3 页备用;旧版保留
- ✅ **去 AI 痕迹**:SI 源文档 58 处破折号句式改写(数字与引文逐一核对不变),投稿信与说明文档同步;交付文件经 wm-clean
- ✅ **更正**:GCB Fig. S15 改用各目风玫瑰(此前误用雷达图,与图注不符)

## 1. 文稿 / Manuscript

限额于 2026-09-24 从官方页面核实。

| 项 | GCB | NEE | NC |
|---|---|---|---|
| 题目 | ✅ 15 词 | ✅ 15 词 | ✅ 15 词(上限 15) |
| 字数 / 上限 | ✅ 7,959 / 8,000(**含致谢**) | ✅ 3,404 / 3,500(正文) | ✅ 4,967 / 5,000(正文) |
| 摘要 / 上限 | ✅ 293 / 300 | ✅ 189 / 200 | ✅ 197 / 200 |
| 文献 | ✅ 38(作者-年份) | ✅ 37(按首次出现编号) | ✅ 37(上限 70) |
| 展示项 | 7 图 + 3 表 | ✅ 5 图 + 1 表(上限 6) | ✅ 7 图 + 3 表(上限 10) |
| Running title / 关键词 | ✅ 38 字符 / 9 个 | — | — |
| 研究问题与假设 | ✅ 引言明确问题 + H1–H4 | ✅ | ✅ |
| 数据 / 代码可用性 | ✅ 含 DOI,数据集正式引用 | ✅ | ✅ |
| 冲突/竞争利益 | ⚠️ 待作者确认 | ⚠️ | ⚠️ |
| 生成式 AI 使用披露 | ✅ 致谢中 | ✅ Methods 中 | ✅ Methods 中 |
| 行号、双倍行距、Times New Roman | ✅(题名、标题、行号均为 TNR) | ✅ | ✅ |
| 写作风格扫描(213) | ✅ 破折号 / 否定排比 / 粗体段首 / 套话 均为 0 | ✅ | ✅ |

复核命令:`python3.11 code/207_recount_wordcounts.py`(字数)、`python3.11 code/212_package_qc.py`
(残留项、题目、关键数字、引文完整性与次序、撤回结论、占位符;须 0 失败)。

## 2. 图件 / Figures

- ✅ 全部图件为英文;矢量 PDF + 450 dpi PNG;地图底图 GS(2019)1822,含南海诸岛与九段线。
- ✅ 方位主图改为三联图(观测 vs 几何零假设 vs 几何 + 努力零假设;观测/期望比;分目风玫瑰)。
- ✅ SI 时空格局图(GCB S16 / NEE S18 / NC S15)按 **CBNR v2 的 1,029 条**重绘;
  此前误用预发布工作表(1,056 条),与正文不一致。
- ✅ 正文图最终字号 5.3–6.2 pt(GCB 全页宽 176 mm),过 Nature 系 5 pt 下限。
- ⚠️ GCB 要求最终 ≥ 8 pt;定稿时与编辑部排版协商,或对个别图申请跨页。
- ✅ 文字碰撞/出界逐张检测(`code/208_figure_qc.py`)。

## 3. 支持信息 / Supporting Information

| | GCB | NEE | NC |
|---|---|---|---|
| Notes | ✅ 7 | ✅ 11 | ✅ 8 |
| Tables | ✅ 10(新增 S9–S10 方位零假设) | ✅ 12(新增 S11–S12) | ✅ 10(新增 S9–S10) |
| Figures | ✅ 21 | ✅ 23 | ✅ 20 |
| 交叉引用闭环 | ✅ 残留旧标签 0 | ✅ 0 | ✅ 0 |
| 图与图注同页 | ✅ 21/21 | ✅ 23/23 | ✅ 20/20 |
| 上传文件 | ✅ PDF 5.5 MB(docx 21 MB 为可编辑版) | ✅ PDF 6.1 MB | ✅ PDF 5.1 MB |

SI 行距改为 1.15 倍(正文仍为双倍),以满足「图与图注同页」,页数相应减少。

## 4. 行政文件 / Administrative

- ✅ Cover letter 三份(md + docx + pdf),已与修订后的正文同步:删去「最清楚证据」等已撤回的表述,
  加入观测增长的出处数字与方位几何零假设一句;GCB 七问每题 ≤50 词(42–48 词)
- ✅ Reporting Summary 草稿:已复制进 `NEE/`、`NC/`;须把逐题答案粘贴进官方表格
- ✅ 数据引用:CBNR v2(10.5281/zenodo.20809949)、保护区边界(10.5281/zenodo.14875797)、
  BirdLife BOTW 2024、代码仓库均已正式列入三版文献表
- ✅ GCB 地图声明:含边界的图注均已加入 GCB 要求的边界声明
- ⚠️ **须作者提供**:完整作者名单、单位、ORCID、CRediT(`CRediT_and_authors_TEMPLATE.md`);
  基金与项目编号;GCB 五位推荐审稿人(含机构邮箱);NEE/NC 推荐与回避审稿人(可选);是否有预印本
- ⚠️ **须作者确认**:竞争利益声明;AI 使用披露措辞;CBNR 数据论文状态("in review");
  BirdLife 分布图子版本;方位结论的更正(见第 6 节)
- ⚠️ **GBIF 下载 DOI**:观测努力部分来自 eBird/GBIF,GBIF 要求引用下载 DOI;若经 API 获取,
  可在 GBIF 注册 derived dataset 取得 DOI
- ⬜ 代码 Zenodo DOI:接收后归档,再替换 GitHub 链接

## 5. 会议报告 / Presentation

- ✅ `presentation/AOC2026_Singapore_EN/`:英文 20 页(pptx + pdf)与中英对照讲稿(docx + md);
  第 9、10、18、19 页已与正文同步;20 页全讲约 12.2 分钟,核心 15 页约 10.1 分钟
- ✅ `presentation/鸟类新纪录生成风险_会议报告_20页_v8.{pptx,pdf}`:中文 20 页;修正封面年份口径、
  第 4 页计数(1,029)与时空图、第 9/10/18/19 页结论、证据锚点编号与封底邮箱
- ✅ 两份 deck:SVG 质检 0 错误、20/20 页含备注、无已撤回表述;中文 PDF 以冬青黑体导出(本机无微软雅黑)
- ✅ v7 已移出投稿包(存档于 deck 工程 `exports/archive_from_submission/`)

## 6. 2026-09-24 至 09-27 的实质更正(请作者知悉)

1. **方位**:「新纪录强烈偏向东与东北」是几何假象(方位从 AVONET 全球质心量起);几何零假设下东向
   期望 234.8、观测 237,无扇区显著;按访问量加权后偏离指向北(北侧三扇区 40.2% 对期望 33.0%)。
   三版结果、主图、SI 表、GCB 摘要与两份 PPT 均已更正(脚本 214/154/216)。
2. **SI 时空图计数**:1,056 → 1,029(CBNR v2)。
3. **过度结论**:「努力回报下降而变暖不降是两过程不同的最清楚证据」改为「与之相符」(两条时间趋势未作相互检验)。
4. **版式**:题名、标题与行号统一为 Times New Roman(此前继承 Word 主题字体 Aptos);PDF 页脚不再出现第二个页码。
5. 引言、讨论全面重写,见 `work/REVISION_NOTES_2026-09-24.md`。

## 7. 投稿前最后三件事

1. 确认作者名单、顺序、单位、ORCID,并据此重出题名页与 CRediT。
2. 补齐基金与审稿人信息后运行 `python3.11 code/215_build_final_package.py`,再运行 212 终检。
3. 按目标刊栏宽复查图件缩放后的最小字号(GCB 8 pt)。
