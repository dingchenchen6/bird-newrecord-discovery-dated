## P01

[about 30 s]

Good morning, everyone. I'm Chenchen Ding, from Peking University. Today I'd like to ask a simple question about new bird records. When a species turns up in a new province, is that the bird moving, or is it us looking harder? Our answer is: both, in roughly equal measure, and I'll show you how a single model can tell the two apart.

## P02

[about 50 s]

Every record needs two things: a bird, and a birder. So a map of records always mixes where the birds are with where people are looking. In China, both changed fast after 2000. The climate warmed, and birding visits rose roughly a hundred-and-seventy-five-fold. A model with only one of them will give it the credit for both. At the bottom you can see how the original papers explain their own records: sixty-one percent say range shift, only seven percent mention survey effort. So our question is: how much of the accumulation of new records reflects warming, and how much reflects effort?

If asked: Where do these percentages come from? From CBNR's 'inferred discovery reason' field, which records the reason given or implied in each source paper.

## P03

[about 40 s]

Our data come from CBNR, the China Bird New Record dataset, which our team compiled from the peer-reviewed literature and checked record by record. The current version holds 1,076 records of 588 species, across 33 provincial units, from 2000 to 2025. The analysis I'll show uses the published v2 release of 1,029 records, which gives 649 first records in our modelling window. Each record is dated to the year it was discovered. The data are open, under a CC BY licence; scan the code to get them.

If asked: Why does the model use v2 and not v1.1? v2 is the citable Zenodo release; v1.1 adds 47 records and is not yet on Zenodo.

If asked: Is CBNR complete? It covers peer-reviewed provincial new records; grey literature and unpublished sightings are not included.

## P04

[about 50 s]

We turned the question into a discrete-time hazard model. For every species, in every province it could plausibly reach, in every year, we ask: is this the year of its first record? Four parts matter. A complete risk set, so the denominator is real opportunities. Warming measured relative to each species' own range, because only the difference tells us something about that species. Survey effort, from millions of eBird and GBIF records. And a province-by-year random effect, which is where survey campaigns live. Records are dated to the year they were discovered, with an offset for the most recent years.

If asked: Why cloglog? It is the discrete-time form of a proportional-hazards model, so exp(beta) is a hazard ratio that does not depend on the time step.

If asked: How is 'could reach' defined? Provinces with at least 50 suitable cells in the species' distribution model; results are the same at 100 and 200.

## P05

[about 30 s]

First finding. Warming and survey effort contribute about equally: a hazard ratio of 1.36 per standard deviation for warming, and 1.40 for effort. And they interact negatively. On the right you can see what that means: where few people are looking, the warming curve is steep; where many people are looking, it flattens out. Annual climate variability has no effect at all.

If asked: How big is the warming effect, really? A permutation null puts the baseline at 1.16, so the species-specific increment is about ×1.18 per SD.

If asked: What does 1 SD of warming mean? 0.18 °C of species-referenced accumulated warming.

## P06

[about 30 s]  [optional: can be cut]

This balance is not fragile. Drop either term and the model loses about the same, around 29 AIC units each. Across twelve specifications, with different distribution-model thresholds, effort proxies and missing-data rules, the numbers stay put. And against design-preserving nulls, both effects stand: the warming increment over its null is about 1.18, and effort collapses to 0.98 if we break its timing.

## P07

[about 35 s]

Second finding. The biggest single component is not a driver at all. It is the province-by-year effect: one standard deviation multiplies the hazard by 2.23, more than warming or effort. This is where a provincial bird survey, a big birding event or a new reserve shows up. Adding this layer lifts conditional AUC from 0.72 to 0.85, and leaves the fixed effects unchanged. Treat it as noise, and survey history reads as range change.

If asked: Could the province-by-year effect absorb climate anomalies too? Partly; that protects the fixed effects at some cost in climatic signal, and we say so in the paper.

## P08

[about 40 s]

Third finding. Effort is saturating. Its hazard ratio fell from 2.2 in 2002 to about 1.1 in 2024, and after 2022 it is no longer different from one. The easy gaps have been filled. Warming shows no such trend. One way to read this is a stock and a flow: effort mines a finite stock of undiscovered records, while warming keeps adding new candidates. We haven't tested the two trends against each other, so I'd call it consistent, not proven.

## P09

[about 40 s]  [optional: can be cut]

Fourth: direction. Measured from each species' range centre, new records look strongly biased to the east. But most of these species have ranges centred west or south of China, so almost any record inside China lands to the east. If we place each record at random among its species' possible provinces, geography alone reproduces the eastward pattern. Only when we also weight provinces by where birders go does a signal remain, and it points north. A modest poleward lean, visible only with the right null.

## P10

[about 40 s]

Now, some uses. Nature reserves look like hot spots for new records: twenty-six percent of records fall inside reserves that cover only ten percent of the land. But birders go there too. When we compare each record with places birders actually visited, in the same province and year, the effect shrinks, and it disappears if we drop the two largest host reserves or look before 2013. More records inside a reserve is not evidence that the reserve is working.

## P11

[about 35 s]

Second, we can push the predictions down to counties. We split the problem in two: will a province get a new record, and if it does, which county? Tested on 2019 to 2024, the top-ranked county was right sixteen percent of the time, against about one percent by chance. And look at the names: Medog, Pudong with Nanhui, Chongming, Luoshan with Dongzhai, Yang County. Birders in China know them. The model was never told.

## P12

[about 20 s]  [optional: can be cut]

Here is the same model at three scales: province, prefecture and county. We also refitted it with random forests and with XGBoost. The maps barely change, with rank correlations between 0.62 and 0.90. Where to look first is robust to the choice of model.

## P13

[about 35 s]

What about the future? We crossed two climate scenarios with two effort scenarios. Switching from SSP2-4.5 to SSP5-8.5 changes the expected national count from 23.2 to 23.1 records a year: essentially nothing. If effort keeps growing, the count more than doubles by 2050. What we will record depends on how we look, more than on how the climate changes. But most of that increase lies outside the data we fitted.

If asked: Is 57 to 62 records a year a forecast? No. At 2050 only 2 percent of cells are inside the fitted support; the credible statement is about 23 to 27 records a year in 2030, under any scenario.

## P14

[about 35 s]  [optional: can be cut]

A warning about machine learning. We ran the same futures with three model families, all calibrated to the same 2024 baseline. Under continuing effort in 2050, the hazard model rises to 57 records a year, the random forest stays flat, and XGBoost goes down. They all agree on where records will appear. But outside the data, tree models simply return their edge values, and nobody can check which direction is right.

## P15

[about 25 s]

So our rule is simple: report where the model breaks. Under SSP2-4.5, the share of species-province combinations inside the fitted range drops from 48 percent in 2030, to 10 percent in 2050, and 2 percent by 2080. So 2030 is usable. End-of-century maps are illustrations, not forecasts.

## P16

[about 25 s]

Four limits travel with these results. Our events are published records, not detections, so we explain how records get documented, not how ranges expand. Coordinates are precise to about a kilometre at best. Our reserve map covers about a third of listed reserves. And projections leave the data after 2030, so late-century maps are illustrations.

## P17

[about 40 s]

Four messages to take home. One: new records carry a climate signal, and warming and survey effort contribute comparably. Two: warming matters most where few people are looking. Three: model the observation process; survey pulses are the largest component, and the return on effort is falling. Four: future record counts depend on how we look, and most projected change is extrapolation. So, birds or birders? Both. But we can read the climate signal only once we model how we look.

## P18

[about 30 s]

What does this mean for monitoring? The warming effect is largest where effort is low, and the low-effort provinces lie mostly in the west and the interior. Meanwhile the return on effort in the eastern hotspots has nearly run out. So the monitoring priority is clear: send effort to climatically exposed, under-surveyed regions. That is where new records carry the most climate information.

## P19

[about 25 s]

Everything is open: the CBNR data on Zenodo, and all of the analysis code on GitHub, where every number in this talk traces back to a table. My thanks to birdwatchers across China, and to every author whose records made this possible. Thank you. I'm happy to take your questions.

## P20

[about 30 s]  [optional: can be cut]

If asked about dating. Dated to publication year, as most compilations do, the effort hazard ratio is 1.79 instead of 1.31, inflated by 37 percent, and an annual climate-variability effect appears at 0.85 with P below 0.001. Dated to discovery it vanishes, and warming barely moves. Publication lags discovery by about two years, and the lag grew with the birding databases.

## P21

[about 15 s]  [optional: can be cut]

If asked about specifications: the signal is confined to annual mean temperature over 15 to 20 years, and the coefficients are stable across effort proxies and missing-data rules.

## P22

[about 15 s]  [optional: can be cut]

If asked how warming is measured: the same province in the same year can warm more or less than a given species' range; that species-specific difference is the climate covariate.