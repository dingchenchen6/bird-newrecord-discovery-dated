# 顶刊设计版主图说明 / Notes on the polished main figures

各刊目录下的 `figures_polished/` 是主图的另一套设计:同一数据、同一统计量,统一为色觉友好的三色语义调色板
(调查努力 深蓝、累积增温 朱红、观测过程 青绿;交互项 炭灰并直接标注),Nature 版宽 183 mm,
最终尺寸下文字 6–7 pt、面板字母 8 pt。每张图都有 PDF、600 dpi PNG 与可编辑 PPTX;
源数据见 `data_and_code/source_data/`。生成脚本:`code/218a`–`218d`,共用主题 `code/218_theme_topjournal.R`。

投稿件目前仍用原设计(`figures/`)。若改用新设计,只需把 `figures_polished/` 中的文件替换 `figures/` 中的同名文件,
并按下表在图注中补一两句(英文可直接粘贴)。所有数值均由脚本与原图逐值核对一致。

| 源图 | GCB | NEE | NC | 图注需要补充或改动的地方 |
|---|---|---|---|---|
| main results | Fig. 1 | Fig. 1 | Fig. 2 | a: "Lighter tints show the 100- and 200-cell thresholds; numbers at right are the main-model (50-cell) estimates." d: 阶梯标签改为 "Warming" 与 "Warming × effort"(模型不变)。 |
| dating correction | Fig. 2 | Fig. 2 | Fig. 1 | b 的纵轴从 0 起;S0 标为 "as published"。无须改动图注。 |
| specification robustness | Fig. 3 | SI Fig. S2 | Fig. 6 | a,b: "Asterisks, \*P < 0.05, \*\*P < 0.01, \*\*\*P < 0.001; the outlined cell is the main specification." c: 原图注的 "survey effort (triangles) and accumulated warming (circles)" 改为 "accumulated warming (left) and survey effort (right)"。a 的标题由 "confined to" 改为 "strongest for"(Tmax 行同样显著)。 |
| model anatomy | Fig. 4 | SI Fig. S4 | Fig. 3 | 无须改动。 |
| observation process | Fig. 5 | Fig. 3 | Fig. 4 | b: "Grey, outside the analysis scope (Taiwan, Hong Kong and Macao have no effort coverage)." c: "Grey cells are the 24 province-years with an effort coverage gap, which are not in the model." 色阶改为以 1 为中性点;建议把 "a 7-fold range" 写作 "up to 7-fold"(最大乘数 7.03)。 |
| direction null | Fig. 6 | Fig. 4 | Fig. 5 | c 改为六个小玫瑰图,记录数与物种数标在各图标题;方位缩写为 N、NE…;b 的竖条为零假设 95% 蒙特卡洛区间(以比值表示)。999 次抽样的最小 P 为 0.001,可写作 "P ≤ 0.001"。 |
| mechanistic vs ML | Fig. 7 | Fig. 5 | Fig. 7 | 原副标题移入图注:"Within the observed range the two model families co-vary (Spearman ρ = 0.54); tree ensembles return boundary leaf values once covariates leave the observed support; the mechanistic model projects increases in 176 of 186 province–scenario cells, the ML model in 42." |

报告用的放大字号版(约 11 pt)在 `analysis_v2/figures_topjournal_slides/`,不属于投稿件。
