# 三家期刊版本

同一份研究，按三家期刊各自的体例与篇幅约束改写成三份独立文稿。

| 目录 | 期刊 | 摘要 | 正文 | 全文 | 约束 | 状态 |
|---|---|---|---|---|---|---|
| `NEE/` | Nature Ecology & Evolution | 148 | 3,604 | 5,044 | 正文 ~3,500–3,600 | 差 4 词，实质达标 |
| `NC/` | Nature Communications | 151 | 4,942 | 6,382 | 正文 ~5,000 | 达标 |
| `GCB/` | Global Change Biology | 246 | 6,387 | 7,864 | 全文 ≤8,000 | 达标 |

每个目录两个 Word 文件：`Manuscript_{刊}_maintext.docx` 与 `Manuscript_{刊}_tables_and_legends.docx`。
排版统一为 Times New Roman 12 pt、双倍行距、1 英寸边距、连续行号、页脚页码、黑色标题。

## 三版的实质差别

**NEE**（正文 3,604 词，砍掉源稿 54%）
Results 十三节压到 2,421 词。迁徙分层压成 45 词的指向句；物种与省级尺度压到约 150 词；
稳健性压到 185 词；模型充分性 135 词。证据全部移入 SI，正文只留结论句与 SI 编号。

**NC**（正文 4,942 词，砍掉源稿 36%）
Results 3,595 词。保留了更多方法学细节与稳健性数值，物种/省级尺度与保护地关联仍大幅移出。

**GCB**（全文 7,864 词，砍掉源稿 14%）
结构改为常规 IMRaD：**Materials and Methods 置于 Introduction 之后**。
Results 保留 4,834 词，接近源稿。摘要扩到 246 词（GCB 允许 250）。

**引文体例**：NEE/NC 用编号上标；GCB 全文 82 条引文已转为**作者-年份制**，
参考文献表按首作者姓氏重排、去掉编号。转换由确定性脚本完成（`code/201_citation_tools.py`），
自带自检：引文点位数不减、无残留上标、每条都能解析出作者年份。
顺带把源稿里 `[A1]`–`[A6]` 的间接编号归一成真实编号（72, 73, 74, 76, 77, 78）。

## 生成流程

```bash
python3.11 code/201_citation_tools.py        # 引文映射与自检
python3.11 code/202_assemble_journal_versions.py
```

输入：`submission/work/revised_{NEE,NC,GCB}.json`（分节 Markdown）与 `plan_*.json`（摘要）。

---

## 改写过程中修掉的问题

三份初稿都经过独立核验，共查出 11 处数字或论据错误，全部已改：

| 问题 | 版本 | 处置 |
|---|---|---|
| 气候基线写成「两个基线 × 两个数据源」（2×2 全因子，实际不存在） | NEE, NC | 改为三条序列，并注明 WorldClim 无法计算 1970–2000 基线 |
| OR 1.57 被归给「仅省-年匹配」模型 | NEE | 补回 1.71 (1.39–2.11)，1.57 为加入海拔/经度/两个生物气候协变量后 |
| 完整度 offset 被称作「individually minor」 | NEE | 恢复 +0.159 的量级（1.289 → 1.448），它是仅次于改期的第二大单步修正 |
| 删掉了唯一一项显著的不利诊断（离群检验） | NEE | 恢复「95 outliers, *P* < 0.001」及其在 0.37% 事件率下属预期的解释 |
| 删掉了 W = 15 的方法学辩护 | NEE | 恢复「lies within 2.2–5.6 AIC units of the optimum in every series」 |
| 交互项范围写成 0.87–1.00 | NC, GCB | 按 `tbl_v2_baseline_sensitivity.csv` 改为 0.82–1.00 |
| 哺乳类方向写成「northward」 | GCB | 改回「northward and eastward」，否则与源稿的对比逻辑相反 |

**零模型基线的限定在三版中均已保留**：气候项置换零分布中位 1.157 而非 1，
可归因于物种特异参照的增量约 1.18；努力项打乱时间对齐后塌到 0.980。

---

## 仍需人工处理

1. **NEE 差 4 词**。NEE 的字数上限是约数（"typically ~3,500 words"），4 词不构成问题；
   若编辑部严格计数，从 Discussion 删一个从句即可。
2. **SI 文档尚未成文**。三版都把大量内容移入 Supplementary，但 SI 本身还没组织成文件。
   各版的 SI 清单在 `work/revised_*.json` 的 `si_manifest` 字段里。
3. **SI 编号未跨版统一**。三版各自编号（NEE 的 Note S3 与 GCB 的 Note S3 内容不同），
   这是版本独立的正常结果，但同一时间只能投一家。
4. **展示项未按版裁剪**。三版目前共用同一份 `tables_and_legends.docx`（9 表 + 18 图注）。
   NEE 需砍到 6 项、NC 砍到 10 项，取舍方案在 `work/plan_*.json` 的 `display_items` 字段。
5. **图件未按刊尺寸重导**。NEE/NC 单栏 89 mm、双栏 183 mm；GCB 另有要求。
6. 投稿件仍缺：cover letter、CRediT 声明、完整作者名单与单位、Data/Code availability 正式表述。

---

## GCB 全包(已完成)

`GCB/` 目录现为**完整投稿包**:

| 文件 | 内容 |
|---|---|
| `Manuscript_GCB_maintext.docx` | 正文(IMRaD,作者-年份引文),40 页 |
| `Manuscript_GCB_tables_and_legends.docx` | Table 1–3 + Figure 1–7 图注(GCB 编号) |
| `Supporting_Information_GCB.docx` | Notes S1–S6、Tables S1–S8、Figs S1–S15(嵌图),33 页 |
| `figures/Figure1–7.(pdf,png)` | 主图按 GCB 编号重命名 |
| `data_code_availability.md` | Data/Code availability 正式表述 |

主图映射:GCB Figure 1←源 Fig.1,2←2,3←3,**4←5(anatomy),5←6(observation process),
6←11(风玫瑰),7←M4(机制 vs ML)**。SI 内文的全部交叉引用已按新编号重映射,零残留。

为 SI 新补一张图:**Fig. S11 重抽样四面板**(置换零分布 / 聚类自助 / 参数自助 / 影响力),
源文件 `figures/FigS5_resampling_v2`,同时可用作 Nature 系的 Extended Data Fig. 5。

投稿前仍需人工:GCB Results 比 agent 自设的 4,800 词子预算超 34 词(全文 7,864/8,000 达标,
不构成硬伤);cover letter 与 CRediT;完整作者名单;图件按 GCB 版式尺寸复查。
NEE 与 NC 的 SI 与展示项裁剪暂缓,待 GCB 投出后按各自方案(`work/plan_*.json`)执行。

---

## NEE 与 NC 全包(已完成)

三家的包现在都是完整投稿套件,各自含:正文 docx、表格与图注 docx(按各版编号)、
Supplementary Information docx(嵌图)、figures/ 重编号主图。

| | NEE | NC | GCB |
|---|---|---|---|
| 正文展示项 | 5 图 + 1 表 | 7 图 + 3 表 | 7 图 + 3 表 |
| SI | 10 Notes + 10 表 + 17 图(43 页) | 7 Notes + 8 表 + 14 图(33 页) | 6 Notes + 8 表 + 15 图(33 页) |
| 引文体例 | 编号上标 | 编号上标 | 作者-年份 |

主图映射:
- **NEE** Fig 1←源1, 2←2, **3←6(观测过程), 4←11(风玫瑰), 5←M4**;Table 1←源 Table 2
- **NC** Fig **1←源2(定年), 2←源1**, 3←5, 4←6, 5←11, 6←3, 7←M4;Tables 1–3←源 1–3

交叉引用采用两阶段替换(源标签→占位符→新标签),NC 的 Fig 1↔2 互换与
NEE 的多处降级(正文→SI)均无串号;三包 SI 残留旧标签均为 0。
NEE 额外收入 Fig. S17(TreeSHAP),因其 Note S9 引用了它而原 manifest 遗漏。

GCB 另有 `cover_letter_GCB.md` 草稿(需补作者名单后使用)。

三包共同的剩余人工项:完整作者名单与单位、CRediT 声明、图件按各刊栏宽的最终版式复查;
NEE 正文仍超约 4 词(其上限为约数)。
