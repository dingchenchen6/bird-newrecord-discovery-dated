## P01

[about 30 s]

Good morning, everyone. I'm Chenchen Ding, from Peking University. Today I'd like to ask a simple question about new bird records. When a species turns up in a new province, is that the bird moving, or is it us looking harder? Our answer is: both, in roughly equal measure, and I'll show you how a single model can tell the two apart.

## P02

[about 45 s]

Let me start with a basic fact. Almost everything we do in biogeography and conservation starts from knowing where species occur. And that knowledge is incomplete, and unevenly so. That's the Wallacean shortfall. Even range maps can mislead: they keep old records and miss real populations in places few people visit. The bias builds up step by step: who goes into the field, what they detect, whether it gets written up, and whether it ever reaches global databases. At each step, a gap in looking can be mistaken for a gap in nature.

## P03

[about 35 s]

China is a good place to study this. Two zoogeographic realms meet here, there are four biodiversity hotspots, several flyways, and about fifteen hundred bird species, some fourteen percent of the world's birds. Monitoring has grown fast, with national networks, citizen science, camera traps and sound recorders. But most new records are still scattered in Chinese-language papers and local reports, and many never reach global databases. There was no standardized dataset of them. So we built one: CBNR.

## P04

[about 45 s]

So what is a new record? It's the first verified occurrence of a species in a province where it wasn't known before. But a record is not a direct observation of movement. It's the last link in a chain: the bird is there, someone looks and finds it, and the find is published. Only the first link is ecology. The other two leave exactly the same trace in the data. So there are two opposite mistakes we can make: read every record as a range shift, or dismiss them all as sampling noise.

If asked: Is this specific to China? No; the chain applies to any dated compilation of first records.

## P05

[about 35 s]

This is why the question is hard in China. On the left, warming: the country turns red, from about 0.2 degrees in 2002 to almost 0.8 by 2024. On the right, survey effort: birding visits rose about 200-fold and spread inland. The amber dots are new records, appearing in the year they were found. Everything rises together, so a trend in new records can't tell us, on its own, which process is behind it.

If asked: Why is Guangdong grey in 2024? Its China Bird Report records cover only 14 days of that year, so we treat that province-year as missing; eBird checklists for 2024, absent from the first download, were added for every province.

If asked: Is this the warming variable in the model? It is the provincial side; the model uses the difference from the same quantity over each species' range.

## P06

[about 30 s]

Here's the gap. When the original papers explain their records, sixty-one percent say range shift, and only seven percent mention survey effort, even though birding grew about 200-fold. Three things haven't been separated: warming and observation grew together; survey pulses are rarely in the model; and warming effects are rarely tested against a benchmark, or projections against the data they came from.

If asked: Where do these percentages come from? From CBNR's 'inferred discovery reason' field, which records the reason given in each source paper; 31% of papers give none.

## P07

[about 50 s]

So we asked four questions. One: does warming raise the rate of new records once observation is modelled, beyond what shared regional climate alone would produce? Two: how large is the observation process itself? We expected province-year survey pulses to be the largest source of variation. Three: do warming and effort interact? We expected a negative interaction, because where effort has long been high, the species that warming favours are already on the list. Four: are the returns stable? We expected the return on effort to decline as the stock of gaps is drawn down, but not the return on warming, which keeps adding new candidates.

If asked: Were these hypotheses pre-specified? H2 to H4 are among the four predictions written down before the robustness analyses; H1 is tested against permutation nulls.

## P08

[about 35 s]

Here's how we built it. We searched Chinese and English literature from 2000 to 2025. A large language model pulled each record into a fixed set of fields, and then every record was standardized and checked by hand: coordinates, taxonomy against the 2026 Chinese catalogue, duplicates, and spatial outliers. The result is 1,076 validated records of 588 species, from 797 papers, and every step is logged so anyone can audit it.

If asked: How reliable is the language-model step? Every extracted record was checked by hand against the source paper; the model only speeds up the reading.

## P09

[about 30 s]

Where are they? New records come from almost every province. The most are in Xizang, with 65, then Hunan and Yunnan, with 63 each. On the right, each dot is a locality: clusters along the south-western mountains, the edge of the Tibetan Plateau, the big river basins and the coast. Almost half are songbirds, and most are documented with field photographs.

## P10

[about 30 s]  [optional: can be cut]

Over time, records rise after about 2010, with the most in the last two years. By order, songbirds lead with 521 records, then shorebirds with 166. The full Sankey diagram linking order, province and year is in the backup slides. Remember this timing: it tracks how hard people looked, which is exactly what the model has to account for.

## P11

[about 30 s]  [optional: can be cut]

On the bird tree, coverage is uneven. Wetland, seabird and soaring orders have the highest share of species with a new record: all the loons, and about seventy percent of storks. Songbirds have the most records but only about a third of their species. Overall the phylogenetic signal is weak, so order-level patterns reflect both ecology and how we look, not just which lineages are moving.

## P12

[about 45 s]

From CBNR to a model takes four steps. We take the records dated to their year of discovery: 657 between 2002 and 2024. We build a risk set of every species, province and year in which a first record could have happened, 175,640 cells. Each cell gets accumulated warming, survey effort, annual climate variability, and an offset for how complete recent reporting is. Then we fit a discrete-time hazard model and test it hard: permutation nulls, twelve alternative specifications, effects that change through time, and projections that report their own data support.

If asked: Why does the model use v2 and not v1.1? v2 is the citable Zenodo release; v1.1 adds 47 records and is not yet on Zenodo.

## P13

[about 40 s]

The question the model asks is simple: for each species, in each province it could reach, in each year, is this the year of its first record? Each pair stays at risk until it's recorded, then leaves. It's a binomial mixed model with a cloglog link, so the coefficients are hazard ratios. Warming is measured against each species' own range; one standard deviation is 0.18 degrees. Effort is birding visits; one standard deviation is about eight-fold. A province-by-year effect absorbs survey campaigns.

If asked: How is 'could reach' defined? Provinces with at least 50 suitable cells in the species' distribution model; results are the same at 100 and 200.

## P14

[about 45 s]

First finding. Warming and survey effort contribute about equally: a hazard ratio of 1.36 per standard deviation for warming, and 1.43 for effort, and the estimates do not move across distribution-model thresholds. And they interact negatively. On the right you can see what that means: where few people are looking, the warming curve is steep; where many people are looking, it flattens out. Annual climate variability has no effect at all. So the answer to question one is yes, and to question three, the interaction is negative, as we expected.

If asked: How big is the warming effect, really? A permutation null puts the baseline at 1.16, so the species-specific increment is about ×1.18 per SD.

If asked: What does 1 SD of warming mean? 0.18 °C of species-referenced accumulated warming.

## P15

[about 35 s]  [optional: can be cut]

This balance is not fragile. Drop either term and the model loses about thirty AIC units. Warming costs more discrimination, effort carries the larger coefficient, and conditional R-squared favours warming; on average the two rank equally. Across twelve specifications, with different distribution-model thresholds, effort proxies and missing-data rules, the numbers stay put. And against design-preserving nulls, both effects stand: the warming increment over its null is about 1.18, and effort collapses to 0.98 if we break its timing.

## P16

[about 40 s]

Second finding. The biggest single component is not a driver at all. It is the province-by-year effect: one standard deviation multiplies the hazard by 2.22, more than warming or effort, and more than species or province. This is where a provincial bird survey, a big birding event or a new reserve shows up. Adding this layer lifts conditional AUC from 0.72 to 0.85, and leaves the fixed effects unchanged. Treat it as noise, and survey history reads as range change.

If asked: Could the province-by-year effect absorb climate anomalies too? Partly; that protects the fixed effects at some cost in climatic signal, and we say so in the paper.

## P17

[about 40 s]

Third finding. Effort is saturating. Its hazard ratio fell from 2.1 in 2002 to about 1.1 in 2024, and from 2023 it is no longer different from one. The easy gaps have been filled. Warming shows no such trend. One way to read this is a stock and a flow: effort mines a finite stock of undocumented occurrences, while warming keeps adding new candidates. We haven't tested the two trends against each other, so I'd call it consistent, not proven.

## P18

[about 35 s]

Which species get new records? Two traits matter. Partial migrants are about twice as likely as residents to gain one, and wide-ranging species are more likely too. Body size, wing shape, clutch size and diet breadth don't matter. On the right, we fitted the model separately for residents, partial migrants and long-distance migrants. Warming and effort raise the hazard in all three, by similar amounts. So migration changes the baseline, but not how the two drivers work.

If asked: Isn't warming weaker for long-distance migrants, who are often vagrants? We expected so, but their point estimate is the highest of the three, though indistinguishable from the others.

If asked: There is a hint that the warming × effort interaction is confined to long-distance migrants (0.75), but the test for a group difference is not significant (P = 0.26).

## P19

[about 35 s]  [optional: can be cut]

Fourth: direction. For each record we take the bearing from the species' range centre to the new location. Of 642 records, 37 percent lie to the east and 28 percent to the north-east. The six largest orders share the lean: songbirds, raptors, ducks, shorebirds, pigeons, rails and cranes. Taken at face value, this looks like an eastward expansion. The next question is whether geography alone could produce it.

## P20

[about 45 s]  [optional: can be cut]

But most of these species have ranges centred west or south of China, so almost any record inside China lands to the east. If we place each record at random among its species' possible provinces, geography alone reproduces the eastward pattern: 235 records expected in the east, 237 observed. Only when we also weight provinces by where birders go does a signal remain, and it points north: 40 percent of records in the northern sectors against 33 percent expected. A modest poleward lean, visible only with the right null.

## P21

[about 55 s]  [optional: can be cut]

A first use. Nature reserves look like hot spots for new records: twenty-six percent of records fall inside reserves that cover ten percent of the land, a two-and-a-half-fold enrichment. Birding effort is not concentrated there, and matching each record to two hundred control locations that birders visited in the same province and year reduces the enrichment to an odds ratio of 1.7, or 1.6 with environmental covariates. But that residual rests on two reserves; without them it is 1.16. It appears only after birding boomed in 2013, and checklists inside reserves record a quarter more species per visit, an observation bias we cannot condition out. So record counts should not be used to judge how well reserves work.

## P22

[about 35 s]

What about the future? We crossed two climate scenarios with two effort scenarios. Switching from SSP2-4.5 to SSP5-8.5 changes the expected national count from 26.1 to 25.9 records a year: essentially nothing. If effort keeps growing, the count roughly triples by 2050. What we will record depends on how we look, more than on how the climate changes. But most of that increase lies outside the data we fitted.

If asked: Is 79 to 89 records a year a forecast? No. At 2050 no cell is inside the fitted support; the credible statement is about 26 to 31 records a year in 2030, under any scenario.

## P23

[about 45 s]  [optional: can be cut]

Where would these records come from? This is 2030 under the middle emission scenario. With effort frozen, the expected records are spread thinly: the top province, Hunan, expects about 1.7 a year, and the top five provinces together hold a quarter of the national total. Let effort keep growing and Hunan rises to about 2, but the number of provinces where most species fall outside the fitted data doubles, from eight to sixteen, mostly in the south and east. The map tells you where to look, and also where not to trust the numbers.

## P24

[about 35 s]  [optional: can be cut]

So our rule is simple: report where the model breaks. Under SSP2-4.5, the share of species-province combinations inside the fitted range drops from 46 percent in 2030 to 6 percent in 2050, and to none by 2080, mostly because effort outgrows its observed range. Machine learning does not rescue it: inside the range the two model families agree, outside it they diverge. So 2030 is usable; end-of-century maps are illustrations, not forecasts.

## P25

[about 25 s]  [optional: can be cut]

Four limits travel with these results. Our events are published records, not detections, so we explain how records get documented, not how ranges expand. Coordinates are precise to about a kilometre at best. Our reserve map covers about a third of listed reserves. And projections leave the data after 2030, so late-century maps are illustrations.

## P26

[about 50 s]

To sum up, four points. One: new records carry a climate signal; warming and survey effort contribute comparably, 1.36 against 1.40 per standard deviation, and one model can separate them. Two: warming matters most where few people are looking. Three: the observation process is the largest single component, and the return on effort is falling. Four: future record counts depend on how we look, and most projected change is extrapolation. For monitoring, send effort to climatically exposed, under-surveyed regions; that is where new records carry the most climate information. Birds or birders? Both. Model how we look, and the records tell us how ranges change.

## P27

[about 25 s]

Everything is open: the CBNR data on Zenodo, and all of the analysis code on GitHub, where every number in this talk traces back to a table. My thanks to my co-authors, to birdwatchers across China, and to every author whose records made this possible. Thank you. I'm happy to take your questions.

## P28

[about 25 s]

If asked about dating. Dated to publication year, as most compilations do, the effort hazard ratio is 1.79 instead of 1.31, inflated by 37 percent, and an annual climate-variability effect appears at 0.85 with P below 0.001. Dated to discovery it vanishes, and warming barely moves. Publication lags discovery by about two years.

## P29

[about 15 s]

If asked about specifications: the signal is strongest for annual mean temperature over 15 to 20 years, and the coefficients are stable across effort proxies and missing-data rules.

## P30

[about 15 s]

If asked how warming is measured: the same province in the same year can warm more or less than a given species' range; that species-specific difference is the climate covariate.

## P31

[about 20 s]

If asked about finer scales: we split the problem into whether a province gets a new record and, if so, which county. Tested on 2019 to 2024, the top-ranked county was right 16 percent of the time, against about 1 percent by chance.

## P32

[about 20 s]

If asked about taxonomic differences: the eastward and north-eastward lean is shared by the larger orders; ducks and geese lean most strongly east, and the small orders are noisy. Read these against the geometric null, not at face value.

## P33

[about 5 s]

The same information as radar profiles, scaled from 0 to 100 percent within each order.

## P34

[about 20 s]

If asked about finer scales: the provincial expectation is split among prefectures by the 2024 allocation model, holding the shares fixed. Municipalities top the list because they are single units; among prefectures, Nyingchi in Xizang and Hanzhong in Shaanxi rank highest.

## P35

[about 15 s]

If asked about the full picture: each ribbon is a set of records, from order, to the province of the record, to the year it was published.

## P36

[about 5 s]

Key references cited on the background slides.