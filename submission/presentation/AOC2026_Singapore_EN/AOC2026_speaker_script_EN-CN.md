# AOC 2026 · Speaker script (EN) with Chinese reference

All 20 slides ≈ 12.9 min · core 15 ≈ 10.6 min · optional: P07, P11, P14, P16, P17

## 01 · Title slide

*[about 35 s · 69 words]*

Good morning, everyone. I'm Chenchen Ding, from Peking University. Today I'd like to ask a simple question about new bird records. When a species turns up in a new province, is that the bird moving, or is it us looking harder? Our answer is: both, in roughly equal measure. But that is only true once each record is dated to when it was found, not when it was published.

> 大家早上好。我是来自北京大学的丁晨晨。今天我想就鸟类新纪录提一个简单的问题:当一个物种出现在一个新的省份时,是鸟在移动,还是我们看得更仔细了?我们的答案是:两者都有,而且大致各占一半。但这个结论只有在把每条记录定年到它被发现的时间、而不是发表的时间时才成立。


## 02 · A new record can mean the bird moved — or that someone finally looked

*[about 50 s · 106 words]*

Every record needs two things: a bird, and a birder. So a map of records always mixes where the birds are with where people are looking. In China, both of these changed fast after 2000. The climate warmed, and birdwatching grew from a small hobby into a mass pastime. A model that includes only one of them will give that one the credit for both. Now look at the bottom of the slide. When the original papers explain their own records, sixty-one percent say "range shift", and only seven percent mention survey effort. So our question is simple: can we measure both processes, in one model?

> 每条记录都需要两样东西:一只鸟,和一位观鸟者。所以一张记录分布图,总是把“鸟在哪里”和“人在哪里看”混在一起。2000 年以后,这两件事在中国都变化得很快:气候快速变暖,观鸟也从小众爱好变成了大众活动。只包含其中一个过程的模型,会把两者的功劳都算到它头上。再看幻灯片下方:原始论文在解释自己的记录时,61% 说是“分布区变化”,只有 7% 提到调查努力。所以我们的问题很简单:能否在一个模型里同时度量这两个过程?

- **If asked —** Where do these percentages come from? From the 'inferred discovery reason' field in CBNR, which records the reason given or implied in each source paper.
  - 若被问到——这些百分比从哪里来?来自 CBNR 的“推断发现原因”字段,记录的是每篇原始论文给出或暗示的原因。

## 03 · CBNR: an open dataset of provincial new bird records in China, 2000–2025

*[about 55 s · 112 words]*

Our data come from CBNR, the China Bird New Record dataset, which our team released this year. It compiles provincial new records of birds from the peer-reviewed literature, 2000 to 2025: 1,029 records of 568 species, across 33 provinces. We pulled them out of the papers with a large-language-model pipeline, and then checked every single record by hand. Two things make it useful today. First, it keeps both the discovery date and the publication year. As panel b shows, a record reaches print about two years after it's found. Please keep that in mind. Second, it's open: CC BY licence, on Zenodo. If you'd like to use it, just scan the code.

> 我们的数据来自 CBNR,即中国鸟类新纪录数据集,是我们团队今年发布的。它汇编了 2000–2025 年同行评审文献中的鸟类省级新纪录:1,029 条记录、568 个物种、覆盖 33 个省级单元。我们用大语言模型辅助的流程从论文中提取,然后逐条人工核对。今天它有两点特别有用。第一,它同时保留了发现日期和发表年份——如图 b 所示,一条记录平均在发现约两年后才见刊,请记住这一点。第二,它是开放的:CC BY 许可,放在 Zenodo 上。如果想用,扫一下二维码即可。

- **If asked —** Is CBNR complete? It covers peer-reviewed provincial new records; grey literature and unpublished sightings are not included.
  - 若被问到——CBNR 完整吗?它收录的是同行评审的省级新纪录,不含灰色文献和未发表的观察。
- **If asked —** How accurate is the LLM extraction? The model only drafts; every record was checked by hand, and the audit trail is part of the release.
  - 若被问到——大模型提取准确吗?模型只做初稿,每条记录都经人工核对,审计记录随数据一并发布。

## 04 · One hazard model, four parts that cannot be dropped

*[about 45 s · 92 words]*

We turned the question into a survival-style model. For every species, in every province it could plausibly reach, in every year, we ask: is this the year of its first record? Four parts matter. A complete risk set, so the denominator is real opportunities. Discovery dating, with an offset for records that are not yet published. Warming measured relative to each species' own range, because warming is fairly even across China, so only the difference tells us something about a species. And a province-by-year random effect, which is where survey campaigns live.

> 我们把这个问题写成一个生存分析式的模型。对每个物种、在它可能到达的每个省、在每一年,我们问:这一年是不是它的首次记录之年?有四个部件缺一不可:完整的风险集,让分母是真实的机会;按发现年定年,并用偏移项校正尚未发表的记录;相对于物种自身分布区来度量变暖——因为全国增温相当均匀,只有这个差值才携带物种层面的信息;以及一个省×年随机效应,调查行动的影响就体现在这里。

- **If asked —** Why cloglog? It is the discrete-time form of a proportional-hazards model, so exp(beta) is a hazard ratio that does not depend on the time step. A logit coefficient would.
  - 若被问到——为什么用 cloglog?它是比例风险模型的离散时间形式,exp(β) 是不依赖时间步长的风险比;logit 系数会随步长改变。
- **If asked —** How is 'could reach' defined? Provinces with at least 50 suitable cells in the species' distribution model; results are the same at 100 and 200.
  - 若被问到——“可能到达”如何定义?物种分布模型中适宜格子不少于 50 个的省份;阈值换成 100 或 200 结果不变。

## 05 · Finding 1 · Change the dating, and the conclusion changes

*[about 40 s · 88 words]*

First finding: the date you attach to a record changes the answer. If we date records by publication year, as most studies do, the effort effect is inflated by thirty-seven percent, and a climate-variability effect appears, with P below 0.001. That effect is not really there. Dated to discovery, it disappears, while the warming effect barely moves. Why? Because the publication lag grew over time together with the birding databases. So the publication year is, systematically, a year with more effort. Dating is a modelling decision, not bookkeeping.

> 第一个发现:给记录标注的年份会改变结论。如果像大多数研究那样按发表年定年,调查努力的效应会被高估 37%,还会冒出一个 P 小于 0.001 的“气候年际变异”效应——而它其实并不存在。按发现年定年后,这个效应消失了,而变暖效应几乎不动。为什么?因为发表滞后是随观鸟数据库一起增长的,发表年系统性地落在努力更大的年份。定年是一个建模决策,不是记账细节。

- **If asked —** Where do discovery dates come from? They are reported in the source papers; 1,028 of the 1,029 records have a parseable discovery year.
  - 若被问到——发现日期从哪里来?原始论文中报告;1,029 条中有 1,028 条可解析出发现年。

## 06 · Finding 2 · Warming and effort matter equally — and interact

*[about 40 s · 81 words]*

Second: after correction, warming and effort contribute about equally. A hazard ratio of 1.36 per standard deviation for warming, and 1.40 for effort. They also interact negatively: warming matters most where survey effort is low. One honest caveat. For warming, the right null is not one. Our permutation null sits at 1.16, so the part we can attribute to species-specific warming is about 1.18. Effort is different: if we break its timing, it collapses to 0.98. So its signal is real.

> 第二:校正之后,变暖与调查努力的贡献大致相当——每个标准差,变暖的风险比为 1.36,努力为 1.40。两者还有负交互:在调查努力低的地方,变暖的作用最强。有一点要坦白:对变暖而言,正确的零参照不是 1。置换零分布中位在 1.16,所以可归因于物种特异变暖的部分约为 1.18。努力则不同:打乱其时间对齐,它塌到 0.98——所以它的信号是真的。

- **If asked —** So how big is the warming effect, really? Significant and robust, but the increment from species-specific warming is about 18 percent per SD, not 36.
  - 若被问到——变暖效应到底多大?显著且稳健,但可归因于物种特异变暖的增量约为每个标准差 18%,而非 36%。
- **If asked —** What does 1 SD of warming mean? 0.179 degrees Celsius of species-referenced accumulated warming.
  - 若被问到——1 个标准差的变暖是多少?物种参照的累积变暖 0.179 °C。

## 07 · The balance holds across four criteria and twelve specifications

*[about 25 s · 53 words]  [optional: can be cut]*

This balance is not fragile. Drop either term and the model loses about the same, around 29 AIC units each. On discrimination, climate alone does slightly better than effort alone, and you need both. And across twelve specifications, with different distribution-model thresholds, effort proxies, missing-data rules and climate windows, the numbers stay put.

> 这种平衡并不脆弱。去掉任何一项,模型损失都差不多,各约 29 个 AIC 单位。在判别力上,单独气候略好于单独努力,两者缺一不可。在十二种设定下——不同的分布模型阈值、努力代理、缺失处理规则与气候窗口——数字都基本不变。


## 08 · Finding 3 · Survey campaigns move the record more than either driver

*[about 35 s · 78 words]*

Third: the biggest single component is not a driver at all. It's the province-by-year effect. One standard deviation of it multiplies the hazard by 2.23, more than warming or effort. This is where a provincial bird survey, a big birding event, or a new reserve shows up. Adding this layer lifts conditional AUC from 0.72 to 0.85, but leaves the fixed effects unchanged. If you treat it as noise, you will read the survey history as range change.

> 第三:最大的单一成分根本不是驱动因子,而是省×年效应。它的一个标准差让风险变为 2.23 倍,超过变暖或努力。省级鸟类调查、大型观鸟活动或新建保护区,都会体现在这里。加入这一层后,条件 AUC 从 0.72 升至 0.85,而固定效应不变。如果把它当成噪声,就会把调查史误读为分布变化。

- **If asked —** Could the province-by-year effect also absorb climate anomalies? Yes, partly; that protects the fixed effects at some cost in climatic signal, and we say so in the paper.
  - 若被问到——省×年效应会不会也吸收了气候异常?会,部分吸收;这保护了固定效应,代价是损失一些气候信号,论文中已说明。

## 09 · Finding 4 · Effort is saturating; warming shows no such trend

*[about 45 s · 96 words]*

Fourth: effort is saturating. The effect of effort fell from a hazard ratio of 2.2 in 2002 to about 1.1 in 2024, and after 2022 it is no longer different from one. The easy gaps have been filled. Warming shows no such trend. One way to read this is a stock and a flow: effort mines a finite stock of undiscovered records, while warming keeps adding new candidates. We haven't tested the two trends against each other, so I'd call it consistent, not proven. For monitoring, it means that more effort in eastern hotspots adds little.

> 第四:调查努力正在饱和。努力的效应从 2002 年的风险比 2.2 降到 2024 年的约 1.1,2022 年之后已与 1 无差异——容易填补的空缺已被填完。变暖则没有这样的趋势。一种解读是“存量与流量”:努力在消耗一个有限的、尚未被发现的记录存量,而变暖不断补充新的候选。我们没有正式检验两条时间趋势之间的差异,所以只能说“相符”,还不能说“证明”。对监测而言,这意味着在东部热点继续加大努力收益很小。


## 10 · Finding 5 · The eastward bias is geography; records lean slightly north

*[about 50 s · 102 words]*

Fifth: direction. Measured from each species' range centre, new records look strongly biased to the east and north-east. But most of these species have ranges centred west or south of China, so almost any record inside China lands to the east. If we scatter each record at random among its species' possible provinces, geography alone reproduces the eastward pattern. Only when we also weight provinces by where birders go does a signal remain, and it points north: more records than expected to the north-east and north-west, fewer to the east and south. A modest poleward lean, visible only with the right null.

> 第五:方向。从每个物种分布区的中心量起,新纪录看起来强烈偏向东侧和东北侧。但这些物种大多数的分布区中心位于中国以西或以南,所以中国境内几乎任何一条记录都会落在东侧。如果把每条记录随机放回该物种可能出现的省份,仅凭地理位置就能重现这种偏东格局。只有再按观鸟者的去向给各省加权,才剩下一个信号,而且它指向北:东北和西北的记录多于预期,东和南少于预期。这是一个温和的向极偏移,只有用对了零假设才看得见。

- **If asked —** Why global range centroids? That is what AVONET provides for every species. Any reference point needs a geometric null; ours places records at province level, and a finer, grid-level null is a next step.
  - 若被问到——为什么用全球分布区质心?这是 AVONET 为每个物种都提供的参照点。任何参照点都需要几何零假设;我们的零假设在省级尺度放置记录,更细的网格级零假设是下一步。

## 11 · The results survive null models and resampling

*[about 25 s · 51 words]  [optional: can be cut]*

We also tested all of this against design-preserving null models, which break one link at a time and keep everything else. All four coefficients sit outside their nulls. Bootstraps clustered by province widen the intervals but don't change the conclusions, and no single province, or group of species, drives the result.

> 我们还用设计保持的零模型检验了这一切——每次只破坏一条关联,其余结构不动。四个系数都落在各自的零分布之外。按省聚类的自助法会加宽置信区间,但不改变结论;没有任何单个省份或物种组在支撑结果。


## 12 · Use 1 · Reserves look rich in new records because birders go there

*[about 40 s · 82 words]*

Now, some uses. Nature reserves look like hot spots for new records: twenty-six percent of records fall inside reserves that cover only ten percent of the land. But birders go there too. When we compare each record with places birders actually visited, in the same province and year, the effect shrinks. It disappears if we drop the two largest host reserves, or look at the years before 2013. So, more records inside a reserve is not evidence that the reserve is working.

> 接下来是几个应用。自然保护区看起来是新纪录的热点:26% 的记录落在只占国土 10% 的保护区里。但观鸟者也常去那里。当我们把每条记录与同省同年观鸟者实际去过的地点对照时,效应缩小;去掉两个最大的宿主保护区,或只看 2013 年之前,效应就消失了。所以,保护区里新纪录多,并不能证明保护区管用。

- **If asked —** Which reserves? 1,028 mapped, mostly national, nature reserves established before 2012; about a third of all listed reserves, so we make no gap-analysis or 30-by-30 claims.
  - 若被问到——用了哪些保护区?1,028 个已制图、以国家级为主、2012 年前建立的自然保护区,约占名录三分之一,所以不做保护空缺分析,也不涉及 30×30。

## 13 · Use 2 · Predictions can be pushed down to the county

*[about 35 s · 77 words]*

Second, we can push the predictions down to counties. We split the problem in two: will a province get a new record, and if it does, which county? Tested on 2019 to 2024, the top-ranked county was right sixteen percent of the time, against about one percent by chance. And look at the list: Medog; Pudong, which includes Nanhui; Chongming; Luoshan, home of Dongzhai; Yang County. Birders in China know these names. The model was never told.

> 第二,我们可以把预测降到县级。把问题拆成两步:一个省会不会出现新纪录?如果会,落在哪个县?在 2019–2024 年的检验中,排名第一的县猜中的概率是 16%,随机只有约 1%。再看这份名单:墨脱;浦东——包括南汇;崇明;罗山——董寨就在那里;洋县。中国鸟友都熟悉这些名字,而模型事先并不知道。

- **If asked —** Why do Shanghai and Tianjin districts rank so high? Those provinces have only 16 districts, so each one's share is naturally larger.
  - 若被问到——为什么上海、天津的区县排得靠前?这两个省级单元只有 16 个区,每个区的份额自然更大。
- **If asked —** Is this in the paper? It is an extension module in our open repository, beyond the journal manuscript.
  - 若被问到——这部分在论文里吗?这是开放代码库中的扩展模块,不在期刊稿件内。

## 14 · Province, prefecture and county maps from one consistent model (2024)

*[about 20 s · 46 words]  [optional: can be cut]*

Here is the same model at three scales: province, prefecture and county, for 2024. We also refitted it with random forests and with XGBoost. The maps barely change, with rank correlations between 0.62 and 0.90. Where to look first is robust to the choice of model.

> 这是同一个模型在三个尺度上的结果:省、地级市和县,2024 年。我们还用随机森林和 XGBoost 重新拟合,地图几乎不变,秩相关在 0.62 到 0.90 之间。先去哪里看,这个答案对模型选择是稳健的。


## 15 · Futures: two climate × two effort scenarios (2030 and 2050)

*[about 40 s · 83 words]*

What about the future? We crossed two climate scenarios with two effort scenarios, and the result is striking. Switching from SSP2-4.5 to SSP5-8.5 changes the expected national count from 23.2 to 23.1 records a year. Essentially nothing. Switching effort from frozen to continuing growth more than doubles it. What we will record depends on how we look, more than on how the climate changes. But notice the transparency on the maps: by 2050, most of that increase lies outside the data we fitted.

> 那么未来呢?我们把两种气候情景和两种努力情景交叉组合,结果很醒目。从 SSP2-4.5 换到 SSP5-8.5,全国期望记录数从每年 23.2 条变成 23.1 条——几乎没变;而把努力从冻结换成持续增长,数量翻了一倍多。我们将记录到什么,更多取决于我们怎么看,而不是气候怎么变。但请注意地图上的透明度:到 2050 年,大部分增量都落在拟合数据的范围之外。

- **If asked —** Is 57 to 62 records a year a forecast? No. At 2050 only 2 percent of cells are inside the fitted support. The credible statement is about 23 to 27 records a year in 2030, under any scenario.
  - 若被问到——每年 57–62 条是预测吗?不是。到 2050 年只有 2% 的格子在拟合支撑域内;可信的说法是 2030 年、任一情景下约每年 23–27 条。

## 16 · Same futures, three model families: who responds, who flat-lines

*[about 35 s · 72 words]  [optional: can be cut]*

A warning about machine learning. We ran the same futures with three model families, all calibrated to the same 2024 baseline. Under continuing effort in 2050, our hazard model rises to 57 records a year, the random forest stays flat, and XGBoost actually goes down. They all agree on where records will appear. But outside the data, tree models simply return their edge values, and nobody can check which direction is right.

> 关于机器学习的一个提醒。我们用三类模型跑了同样的未来情景,都校准到同一个 2024 年基线。在 2050 年努力持续增长的情景下,我们的风险模型升到每年 57 条,随机森林纹丝不动,XGBoost 反而下降。三者对“在哪里”意见一致;但在数据范围之外,树模型只返回边界值,没人能检验哪个方向是对的。

- **If asked —** So do you trust the hazard model's 57? No, and I don't claim it: support there is 2 percent.
  - 若被问到——你相信风险模型的 57 吗?不相信,我也没这么说——那里的支撑域只有 2%。

## 17 · Use 3 · Data support, not ambition, sets the forecast horizon

*[about 25 s · 47 words]  [optional: can be cut]*

So our rule is simple: report where the model breaks. Under SSP2-4.5, the share of species-province combinations inside the fitted range drops from 48 percent in 2030, to 10 percent in 2050, and 2 percent by 2080. So 2030 is usable. End-of-century maps are illustrations, not forecasts.

> 所以我们的规则很简单:报告模型在哪里失效。在 SSP2-4.5 下,落在拟合范围内的物种–省组合比例从 2030 年的 48% 降到 2050 年的 10%,2080 年只剩 2%。所以 2030 年可用,世纪末的地图只是示意,不是预测。


## 18 · Four limits that travel with the conclusions

*[about 35 s · 71 words]*

Four limits travel with these results. Our events are published records, not detections, so we explain how records get documented, not how ranges expand. Coordinates are precise to about one kilometre at best. Our reserve map covers about a third of listed reserves. And direction and reserve tests are only as good as their nulls: our direction null works at province level, and no null can remove observer bias inside reserves.

> 有四条局限与这些结论同行。我们的事件是发表的记录而非探测,所以我们解释的是记录如何被记载,而不是分布区如何扩张。坐标精度最高约 1 公里。保护区矢量约覆盖名录的三分之一。方向与保护区的检验都取决于零假设:方向的零假设只在省级尺度上放置记录,而任何零假设都无法扣除保护区内部的观测偏倚。


## 19 · Four take-home messages

*[about 35 s · 70 words]*

Four messages to take home. One: dating is a modelling decision, so use the discovery year. Two: warming and survey effort contribute comparably, and we can separate them. Three: model the observation process explicitly; survey shocks are the largest component. Four: keep applications inside the evidence. So, back to our question: birds or birders? It's not either-or. But the climate signal only becomes interpretable once we model how we look.

> 请带走四句话。第一:定年是建模决策,请用发现年。第二:变暖与调查努力的贡献相当,而且可以分开。第三:要显式地为观测过程建模;调查冲击是最大的成分。第四:应用要守在证据之内。回到我们的问题——是鸟,还是观鸟者?不是二选一。但只有为“我们如何观察”建模之后,气候信号才变得可以解释。


## 20 · Open data, open code — and thank you

*[about 25 s · 50 words]*

Everything is open: the CBNR data on Zenodo, and all of the analysis code on GitHub, where every number in this talk traces back to a table. My thanks to birdwatchers across China, and to every author whose records made this possible. Thank you. I'm happy to take your questions.

> 一切都是开放的:CBNR 数据在 Zenodo 上,全部分析代码在 GitHub 上,这次报告中的每个数字都能追溯到一张结果表。感谢全国的观鸟者,以及所有让这些记录成为可能的作者。谢谢大家,欢迎提问。

