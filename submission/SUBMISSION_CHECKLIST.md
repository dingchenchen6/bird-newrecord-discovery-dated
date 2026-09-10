# Submission checklist

状态图例:✅ 已完成并核验 · ⚠️ 需作者确认 · ⬜ 投稿系统内填写

## 1. 文稿 / Manuscript

| 项 | GCB | NEE | NC |
|---|---|---|---|
| 正文词数 / 上限 | ✅ 7,999 / 8,000(全含) | ✅ 3,599 / 3,600 | ✅ 4,999 / 5,000 |
| 摘要词数 | ✅ 246 | ✅ 148 | ✅ 151 |
| 章节顺序 | ✅ IMRaD(Methods 在 Intro 后) | ✅ Nature 系 | ✅ Nature 系 |
| 引文体例 | ✅ 作者-年份 | ✅ 编号上标 | ✅ 编号上标 |
| 行号与双倍行距 | ✅ | ✅ | ✅ |
| 文本层中文残留 | ✅ 0 | ✅ 0 | ✅ 0 |

## 2. 图件 / Figures

- ✅ **全部图件为英文**。9 张原为中文的图(FigP1–P3、FigST1、FigMS1–MS5)
  已由 `189_make_english_figures.py` 派生英文版,输出在
  `figures_pa/en/` 与 `figures_multiscale/en/`;中文原版保留供中文报告使用。
- ✅ 中文残留检测:9 张英文 PDF 全部 0 字。
- ✅ 矢量 PDF + 450 dpi PNG 双格式;地图底图为审图号 GS(2019)1822,
  含南海诸岛与九段线,未作任何几何改动。
- ✅ 面板标签统一为小写加粗 `a b c d`;色标语义全稿一致
  (冷→暖 = 低→高;绿=气候、蓝=努力)。
- ⚠️ **投稿前按各刊栏宽复排**:Nature 系单栏 89 mm / 双栏 183 mm;
  GCB 单栏 80 mm / 双栏 166 mm。现有图为工作尺寸(8.8–14.6 in 宽),
  矢量 PDF 可无损缩放,但缩放后需复查最小字号(建议 ≥ 5–7 pt)。

## 3. 支持信息 / Supporting Information

| | GCB | NEE | NC |
|---|---|---|---|
| Notes | ✅ 7 | ✅ 11 | ✅ 8 |
| Tables | ✅ 8 | ✅ 10 | ✅ 8 |
| Figures | ✅ 21 | ✅ 23 | ✅ 20 |
| 交叉引用闭环 | ✅ 残留旧标签 0 | ✅ 0 | ✅ 0 |
| 文件体积 | ✅ 20.8 MB | ⚠️ 22.7 MB | ✅ 19.3 MB |

⚠️ 若目标刊限制单文件 ≤ 20 MB,需把 SI 图拆为独立文件上传
(脚本已用 3000 px 降采样副本,进一步压缩会损失可读性)。

## 4. 行政文件 / Administrative

- ✅ Cover letter 草稿(GCB):`GCB/cover_letter_GCB.md`
- ⚠️ 作者名单与 CRediT:`CRediT_and_authors_TEMPLATE.md` — **必须由通讯作者确认**
- ✅ Data / Code availability:`GCB/data_code_availability.md`
- ⬜ 推荐审稿人、回避名单:投稿系统内填写
- ⬜ 伦理与许可声明:本研究使用已发表记录与公开数据库,无需伦理审批;
  BirdLife 分布区与保护区矢量按各自许可使用,已在 availability 中声明

## 5. 投稿前最后三件事

1. 确认作者名单、顺序、单位、ORCID,并据此重出题名页与 CRediT。
2. 按目标刊栏宽复排图件,复查缩放后的最小字号。
3. 确认 SI 单文件体积符合目标刊上限;必要时拆分上传。
