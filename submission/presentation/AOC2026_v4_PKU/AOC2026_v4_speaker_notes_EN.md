## P01

[about 30 s]

Good morning, everyone. I'm Chenchen Ding, from Peking University. Today I'd like to ask a simple question about new bird records. When a species turns up in a new province, is that the bird moving, or is it us looking harder? Our answer is: both, in roughly equal measure, and I'll show you how a single model can tell the two apart.

## P02

[about 40 s]

A new distribution record is the first documented occurrence of a species in a province where it had not been recorded before. But a record is not an observation of movement. It is the last link in a chain of three events: the bird is there, someone looks and finds it, and the find is published. Only the first link is ecological. The other two leave exactly the same trace in the data, so imperfect detection and uneven sampling can create apparent range changes where none occurred.

If asked: Is this specific to China? No; the chain applies to any dated compilation of first records.

## P03

[about 50 s]

This is why the question is hard in China. On the left, accumulated warming: the fifteen-year mean temperature relative to 1980 to 2000. The country turns red, from about 0.2 degrees in 2002 to almost 0.8 by 2024, most strongly across the north and northwest. On the right, survey effort: birding visits per province, which rose about 200-fold over the same years and spread from the east coast inland. The amber dots are new records, appearing in the year they were discovered: 657 of them. Everything rises together, so a trend in new records cannot, on its own, tell us which process is behind it.

If asked: Why is Guangdong grey in 2024? Its China Bird Report records cover only 14 days of that year, so we treat that province-year as missing; eBird checklists for 2024, absent from the first download, were added for every province.

If asked: Is this the warming variable in the model? It is the provincial side; the model uses the difference from the same quantity over each species' range.

## P04

[about 55 s]

Here is the gap. When the original papers explain their own records, sixty-one percent say range shift, and only seven percent mention survey effort, although birding visits rose about 200-fold. Three things have not been separated. Warming and observation grew together, so a model with only one of them gives it the credit for both. Survey pulses, such as campaigns, festivals and new reserves, and the set of species that could have been recorded where, are rarely part of the model. And a warming effect needs a benchmark: what shared regional climate would produce anyway. Projections, finally, are rarely checked against the range of data the model was fitted to.

If asked: Where do these percentages come from? From CBNR's 'inferred discovery reason' field, which records the reason given in each source paper; 31% of papers give none.

## P05

[about 50 s]

So we asked four questions. One: does warming raise the rate of new records once observation is modelled, beyond what shared regional climate alone would produce? Two: how large is the observation process itself? We expected province-year survey pulses to be the largest source of variation. Three: do warming and effort interact? We expected a negative interaction, because where effort has long been high, the species that warming favours are already on the list. Four: are the returns stable? We expected the return on effort to decline as the stock of gaps is drawn down, but not the return on warming, which keeps adding new candidates.

If asked: Were these hypotheses pre-specified? H2 to H4 are among the four predictions written down before the robustness analyses; H1 is tested against permutation nulls.

## P06

[about 50 s]

The framework has four steps. Records come from CBNR, our compilation of provincial first records from the literature: 1,029 in the published version, each dated to its discovery, 657 of them between 2002 and 2024. We then build a risk set of every species, province and year in which a first record could have happened: 175,640 cells. Each cell carries accumulated warming, survey effort, annual climate variability, and an offset for how complete recent reporting is. Finally, a discrete-time hazard model, tested with permutation nulls, twelve alternative specifications, time-varying effects, and scenario projections that report their own data support.

If asked: Why does the model use v2 and not v1.1? v2 is the citable Zenodo release; v1.1 adds 47 records and is not yet on Zenodo.

## P07

[about 60 s]

For every species, in every province it could reach, in every year, we ask: is this the year of its first record? Each pair stays in the risk set until its first record and then leaves it; pairs that are never recorded stay to the end. The model is a binomial mixed model with a complementary log-log link, the discrete-time form of a proportional-hazards model, so exp of beta is a hazard ratio. Warming is measured relative to each species' own range over fifteen years; one standard deviation is 0.18 degrees. Effort is provincial birding visits; one standard deviation is a 7.9-fold difference. A province-by-year random effect absorbs survey campaigns, and an offset corrects the latest years, which are still being published.

If asked: How is 'could reach' defined? Provinces with at least 50 suitable cells in the species' distribution model; results are the same at 100 and 200.

## P08

[about 40 s]

First finding. Warming and survey effort contribute about equally: a hazard ratio of 1.36 per standard deviation for warming, and 1.43 for effort. And they interact negatively. On the right you can see what that means: where few people are looking, the warming curve is steep; where many people are looking, it flattens out. Annual climate variability has no effect at all. So the answer to question one is yes, and to question three, the interaction is negative, as we expected.

If asked: How big is the warming effect, really? A permutation null puts the baseline at 1.16, so the species-specific increment is about ×1.18 per SD.

If asked: What does 1 SD of warming mean? 0.18 °C of species-referenced accumulated warming.

## P09

[about 30 s]  [optional: can be cut]

This balance is not fragile. Drop either term and the model loses about the same, around 30 AIC units or more each. Across twelve specifications, with different distribution-model thresholds, effort proxies and missing-data rules, the numbers stay put. And against design-preserving nulls, both effects stand: the warming increment over its null is about 1.18, and effort collapses to 0.98 if we break its timing.

## P10

[about 35 s]

Second finding. The biggest single component is not a driver at all. It is the province-by-year effect: one standard deviation multiplies the hazard by 2.22, more than warming or effort. This is where a provincial bird survey, a big birding event or a new reserve shows up. Adding this layer lifts conditional AUC from 0.72 to 0.85, and leaves the fixed effects unchanged. Treat it as noise, and survey history reads as range change.

If asked: Could the province-by-year effect absorb climate anomalies too? Partly; that protects the fixed effects at some cost in climatic signal, and we say so in the paper.

## P11

[about 40 s]

Third finding. Effort is saturating. Its hazard ratio fell from 2.1 in 2002 to about 1.1 in 2024, and from 2023 it is no longer different from one. The easy gaps have been filled. Warming shows no such trend. One way to read this is a stock and a flow: effort mines a finite stock of undocumented occurrences, while warming keeps adding new candidates. We haven't tested the two trends against each other, so I'd call it consistent, not proven.

## P12

[about 40 s]  [optional: can be cut]

Fourth: direction. Measured from each species' range centre, new records look strongly biased to the east. But most of these species have ranges centred west or south of China, so almost any record inside China lands to the east. If we place each record at random among its species' possible provinces, geography alone reproduces the eastward pattern. Only when we also weight provinces by where birders go does a signal remain, and it points north: a modest poleward lean, visible only with the right null.

## P13

[about 55 s]  [optional: can be cut]

A first use. Nature reserves look like hot spots for new records: twenty-six percent of records fall inside reserves that cover ten percent of the land, a two-and-a-half-fold enrichment. Birding effort is not concentrated there, and matching each record to two hundred control locations that birders visited in the same province and year reduces the enrichment to an odds ratio of 1.7, or 1.6 with environmental covariates. But that residual rests on two reserves; without them it is 1.16. It appears only after birding boomed in 2013, and checklists inside reserves record a quarter more species per visit, an observation bias we cannot condition out. So record counts should not be used to judge how well reserves work.

## P14

[about 35 s]

What about the future? We crossed two climate scenarios with two effort scenarios. Switching from SSP2-4.5 to SSP5-8.5 changes the expected national count from 26.1 to 25.9 records a year: essentially nothing. If effort keeps growing, the count roughly triples by 2050. What we will record depends on how we look, more than on how the climate changes. But most of that increase lies outside the data we fitted.

If asked: Is 79 to 89 records a year a forecast? No. At 2050 no cell is inside the fitted support; the credible statement is about 26 to 31 records a year in 2030, under any scenario.

## P15

[about 35 s]  [optional: can be cut]

So our rule is simple: report where the model breaks. Under SSP2-4.5, the share of species-province combinations inside the fitted range drops from 46 percent in 2030 to 6 percent in 2050, and to none by 2080, mostly because effort outgrows its observed range. Machine learning does not rescue it: inside the range the two model families agree, outside it they diverge. So 2030 is usable; end-of-century maps are illustrations, not forecasts.

## P16

[about 25 s]  [optional: can be cut]

Four limits travel with these results. Our events are published records, not detections, so we explain how records get documented, not how ranges expand. Coordinates are precise to about a kilometre at best. Our reserve map covers about a third of listed reserves. And projections leave the data after 2030, so late-century maps are illustrations.

## P17

[about 50 s]

To sum up, four points. One: new records carry a climate signal; warming and survey effort contribute comparably, 1.36 against 1.40 per standard deviation, and one model can separate them. Two: warming matters most where few people are looking. Three: the observation process is the largest single component, and the return on effort is falling. Four: future record counts depend on how we look, and most projected change is extrapolation. For monitoring, send effort to climatically exposed, under-surveyed regions; that is where new records carry the most climate information. Birds or birders? Both. Model how we look, and the records tell us how ranges change.

## P18

[about 25 s]

Everything is open: the CBNR data on Zenodo, and all of the analysis code on GitHub, where every number in this talk traces back to a table. My thanks to my co-authors, to birdwatchers across China, and to every author whose records made this possible. Thank you. I'm happy to take your questions.

## P19

[about 25 s]

If asked about dating. Dated to publication year, as most compilations do, the effort hazard ratio is 1.79 instead of 1.31, inflated by 37 percent, and an annual climate-variability effect appears at 0.85 with P below 0.001. Dated to discovery it vanishes, and warming barely moves. Publication lags discovery by about two years.

## P20

[about 15 s]

If asked about specifications: the signal is strongest for annual mean temperature over 15 to 20 years, and the coefficients are stable across effort proxies and missing-data rules.

## P21

[about 15 s]

If asked how warming is measured: the same province in the same year can warm more or less than a given species' range; that species-specific difference is the climate covariate.

## P22

[about 20 s]

If asked about finer scales: we split the problem into whether a province gets a new record and, if so, which county. Tested on 2019 to 2024, the top-ranked county was right 16 percent of the time, against about 1 percent by chance.