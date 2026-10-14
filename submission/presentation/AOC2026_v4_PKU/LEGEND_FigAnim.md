# Animated figure: warming, survey effort and new bird records in China, 2002–2024

**Files.** `FigAnim_warming_effort_records.gif` (1600 × 800 px, for the slide), `.mp4` (1920 × 960 px, H.264),
`_2024.png`/`.pdf` (final frame, for print and the PDF version of the talk). Script: `code/221_spatiotemporal_animation.R`.

**Legend (English).** Each frame shows one year from 2002 to 2024. Left, accumulated warming: the 15-year trailing mean
of annual mean temperature minus its 1980–2000 mean, at 10 arc-minutes (WorldClim 2.1 downscaling of CRU TS 4.09),
projected to an equal-area grid of 15 km. This is the provincial side of the warming covariate in the hazard model; the
model uses its difference from the same quantity over each species' range. Right, survey effort: birding visits per province
and year in eBird/GBIF and China Bird Report on a log scale; grey provinces have no effort coverage that year or lie outside the effort analysis
(Taiwan, Hong Kong and Macao).
Also grey: Guangdong 2024, whose China Bird Report records cover only 14 days; it is treated as missing in the model. eBird checklists for 2024, absent from the original source download, were added with the same visit definition (scripts 222 and 131).
Points are provincial first records from CBNR v2 dated to their discovery year (amber, this
year; dark, earlier years; n = 657). Bottom, national series: equal-area mean accumulated warming (0.21 °C in 2002,
0.77 °C in 2024), total birding visits in mainland provinces (707 in 2002, 189,573 in 2024; 201-fold from 2002–2004 to
2022–2024) and new records per discovery year. Counts for 2022–2024 are incomplete because records are still being published;
the hazard model corrects for this with a reporting-completeness offset. Base map: GS(2019)1822.

**说明(中文).** 每帧为 2002–2024 年中的一年。左图为累积增温(15 年滑动均温减 1980–2000 均值, 即模型增温协变量的省端口径),
右图为分省观鸟访问量(对数色阶; 灰色为当年无努力覆盖或不在努力分析范围内的台湾、香港、澳门)与按发现年定年的新纪录。
另: 广东 2024 年的中国观鸟记录中心数据只覆盖 14 天, 模型中按缺失处理, 地图为灰色;2024 年 eBird 清单原下载缺失, 已按同一口径补入(脚本 222、131)。
下方为全国时间序列; 2022–2024 年纪录仍在陆续发表, 柱高偏低。每帧均为真实年份数据, 不做年间插值; 各帧色阶固定。
源数据: `source_data_FigAnim_national.csv`、`source_data_FigAnim_province_year.csv`、`source_data_FigAnim_records.csv`。
