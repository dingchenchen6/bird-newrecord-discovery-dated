## P01

[about 30 s]

Good morning, everyone. I'm Chenchen Ding, from Peking University. Today I'd like to ask a simple question about new bird records. When a species turns up in a new province, is that the bird moving, or is it us looking harder? Our answer is: both, in roughly equal measure, and I'll show you how a single model can tell the two apart.

## P02

[about 40 s]

Let me start with the big picture. Global change threatens about a million species, and one clear response is that species move: on land, poleward by about seventeen kilometres a decade. To see those moves we need distribution data, and those data are patchy. New records are where a move first shows up. The catch: a record tells us a bird was found, not why it was there. So a gap in looking can pass for a pattern in nature.

If asked: Where is the 16.9 km figure from? Chen et al. 2011 in Science: the median poleward shift across terrestrial taxa, with 11 m per decade upslope.

## P03

[about 25 s]

China is a good place to test this: two realms, four hotspots, several flyways, and about fifteen hundred bird species. Monitoring has grown fast, but most new records still sit in Chinese-language papers that never reach global databases. There was no standard dataset. So we built one: CBNR.

## P04

[about 35 s]

This is what a new record looks like: a short paper, often in Chinese, with a photo as evidence. A koel on the Qinghai plateau, a bunting and a whitethroat in Xizang, a seabird far inland in Yunnan, an openbill in Hunan, and an eared-pheasant on a camera trap in Henan. Notice the dates: most were found a year or two before they were published. We date every record to when it was found.

If asked: Are these typical? They are recent, open-access examples; 79% of CBNR records rest on field photographs like these.

## P05

[about 35 s]

So what is a new record? The first verified sighting of a species in a province where it wasn't known. But it's the last link in a chain: the bird is there, someone looks, and the find gets published. Only the first link is ecology; the other two leave exactly the same trace. So we can make two opposite mistakes: call every record a range shift, or dismiss them all as sampling noise.

If asked: Is this specific to China? No; the chain applies to any dated compilation of first records.

## P06

[about 35 s]

This is why the question is hard in China. On the left, warming: the country turns red, from about 0.2 degrees in 2002 to almost 0.8 by 2024. On the right, survey effort: birding visits rose about 200-fold and spread inland. The amber dots are new records, appearing in the year they were found. Everything rises together, so a trend in new records can't tell us, on its own, which process is behind it.

If asked: Why is Guangdong grey in 2024? Its China Bird Report records cover only 14 days of that year, so we treat that province-year as missing; eBird checklists for 2024, absent from the first download, were added for every province.

If asked: Is this the warming variable in the model? It is the provincial side; the model uses the difference from the same quantity over each species' range.

## P07

[about 35 s]

So where's the gap? The original papers credit sixty-one percent of records to range shifts and only seven percent to survey effort, although birding grew about 200-fold. Three things are missing. Warming and effort are studied apart, and their interaction is almost never tested. We don't know how the response varies, by traits like migration or by direction. And the data are scattered and dated to publication, not discovery.

If asked: Where do these percentages come from? From CBNR's 'inferred discovery reason' field, which records the reason given in each source paper; 31% of papers give none.

## P08

[about 40 s]

So, three questions. One: how do warming and effort work together? We expect both to raise the chance of a first record, warming beyond what shared regional climate gives, with a negative interaction: where people have looked hard for years, the species warming favours are already listed. Two: does this change over time and space? We expect the payoff from effort to shrink, not the payoff from warming, and records to lean poleward. Three: which species? We expect mobile species, like migrants, to gain more records.

If asked: Were these hypotheses pre-specified? The interaction, the survey pulses and the declining return on effort were written down before the robustness analyses; the warming effect is tested against permutation nulls; the trait and direction expectations follow the literature.

## P09

[about 35 s]

Here's how we built it. We searched Chinese and English literature from 2000 to 2025. A large language model pulled each record into a fixed set of fields, and then every record was standardized and checked by hand: coordinates, taxonomy against the 2026 Chinese catalogue, duplicates, and spatial outliers. The result is 1,076 validated records of 588 species, from 797 papers, and every step is logged so anyone can audit it.

If asked: How reliable is the language-model step? Every extracted record was checked by hand against the source paper; the model only speeds up the reading.

## P10

[about 30 s]

Where are they? New records come from almost every province. The most are in Xizang, with 65, then Hunan and Yunnan, with 63 each. On the right, each dot is a locality: clusters along the south-western mountains, the edge of the Tibetan Plateau, the big river basins and the coast. Almost half are songbirds, and most are documented with field photographs.

## P11

[about 30 s]  [optional: can be cut]

Over time, records rise after about 2010, with the most in the last two years. By order, songbirds lead with 521 records, then shorebirds with 166. The full Sankey diagram linking order, province and year is in the backup slides. Remember this timing: it tracks how hard people looked, which is exactly what the model has to account for.

## P12

[about 30 s]  [optional: can be cut]

On the bird tree, coverage is uneven. Wetland, seabird and soaring orders have the highest share of species with a new record: all the loons, and about seventy percent of storks. Songbirds have the most records but only about a third of their species. Overall the phylogenetic signal is weak, so order-level patterns reflect both ecology and how we look, not just which lineages are moving.

## P13

[about 45 s]

From CBNR to a model takes four steps. We take the records dated to their year of discovery: 657 between 2002 and 2024. We build a risk set of every species, province and year in which a first record could have happened, 175,640 cells. Each cell gets accumulated warming, survey effort, annual climate variability, and an offset for how complete recent reporting is. Then we fit a discrete-time hazard model and test it hard: permutation nulls, twelve alternative specifications, effects that change through time, and projections that report their own data support.

If asked: Why does the model use v2 and not v1.1? v2 is the citable Zenodo release; v1.1 adds 47 records and is not yet on Zenodo.

## P14

[about 40 s]

The question the model asks is simple: for each species, in each province it could reach, in each year, is this the year of its first record? Each pair stays at risk until it's recorded, then leaves. It's a binomial mixed model with a cloglog link, so the coefficients are hazard ratios. Warming is measured against each species' own range; one standard deviation is 0.18 degrees. Effort is birding visits; one standard deviation is about eight-fold. A province-by-year effect absorbs survey campaigns.

If asked: How is 'could reach' defined? Provinces with at least 50 suitable cells in the species' distribution model; results are the same at 100 and 200.

## P15

[about 45 s]

First finding. Warming and survey effort contribute about equally: a hazard ratio of 1.36 per standard deviation for warming, and 1.43 for effort, and the estimates do not move across distribution-model thresholds. And they interact negatively. On the right you can see what that means: where few people are looking, the warming curve is steep; where many people are looking, it flattens out. Annual climate variability has no effect at all. So the answer to question one is yes, and to question three, the interaction is negative, as we expected.

If asked: How big is the warming effect, really? A permutation null puts the baseline at 1.16, so the species-specific increment is about ×1.18 per SD.

If asked: What does 1 SD of warming mean? 0.18 °C of species-referenced accumulated warming.

## P16

[about 35 s]  [optional: can be cut]

This balance is not fragile. Drop either term and the model loses about thirty AIC units. Warming costs more discrimination, effort carries the larger coefficient, and conditional R-squared favours warming; on average the two rank equally. Across twelve specifications, with different distribution-model thresholds, effort proxies and missing-data rules, the numbers stay put. And against design-preserving nulls, both effects stand: the warming increment over its null is about 1.18, and effort collapses to 0.98 if we break its timing.

## P17

[about 40 s]

Second finding. The biggest single component is not a driver at all. It is the province-by-year effect: one standard deviation multiplies the hazard by 2.22, more than warming or effort, and more than species or province. This is where a provincial bird survey, a big birding event or a new reserve shows up. Adding this layer lifts conditional AUC from 0.72 to 0.85, and leaves the fixed effects unchanged. Treat it as noise, and survey history reads as range change.

If asked: Could the province-by-year effect absorb climate anomalies too? Partly; that protects the fixed effects at some cost in climatic signal, and we say so in the paper.

## P18

[about 40 s]

Third finding. Effort is saturating. Its hazard ratio fell from 2.1 in 2002 to about 1.1 in 2024, and from 2023 it is no longer different from one. The easy gaps have been filled. Warming shows no such trend. One way to read this is a stock and a flow: effort mines a finite stock of undocumented occurrences, while warming keeps adding new candidates. We haven't tested the two trends against each other, so I'd call it consistent, not proven.

## P19

[about 35 s]

Which species get new records? Two traits matter. Partial migrants are about twice as likely as residents to gain one, and wide-ranging species are more likely too. Body size, wing shape, clutch size and diet breadth don't matter. On the right, we fitted the model separately for residents, partial migrants and long-distance migrants. Warming and effort raise the hazard in all three, by similar amounts. So migration changes the baseline, but not how the two drivers work.

If asked: Isn't warming weaker for long-distance migrants, who are often vagrants? We expected so, but their point estimate is the highest of the three, though indistinguishable from the others.

If asked: There is a hint that the warming × effort interaction is confined to long-distance migrants (0.75), but the test for a group difference is not significant (P = 0.26).

## P20

[about 35 s]  [optional: can be cut]

Fourth: direction. For each record we take the bearing from the species' range centre to the new location. Of 642 records, 37 percent lie to the east and 28 percent to the north-east. The six largest orders share the lean: songbirds, raptors, ducks, shorebirds, pigeons, rails and cranes. Taken at face value, this looks like an eastward expansion. The next question is whether geography alone could produce it.

## P21

[about 35 s]

Fourth, direction. Seen from range centres, records point east. But most of these species have ranges centred west or south of China, so almost any record here lands to the east. Placing records at random among each species' possible provinces gives 235 in the east; we saw 237. Only after adding where birders go does a signal remain, and it points north: 40 percent against 33 expected. A modest poleward lean.

## P22

[about 55 s]  [optional: can be cut]

A first use. Nature reserves look like hot spots for new records: twenty-six percent of records fall inside reserves that cover ten percent of the land, a two-and-a-half-fold enrichment. Birding effort is not concentrated there, and matching each record to two hundred control locations that birders visited in the same province and year reduces the enrichment to an odds ratio of 1.7, or 1.6 with environmental covariates. But that residual rests on two reserves; without them it is 1.16. It appears only after birding boomed in 2013, and checklists inside reserves record a quarter more species per visit, an observation bias we cannot condition out. So record counts should not be used to judge how well reserves work.

## P23

[about 25 s]  [optional: can be cut]

Four limits travel with these results. Our events are published records, not detections, so we explain how records get documented, not how ranges expand. Coordinates are precise to about a kilometre at best. Our reserve map covers about a third of listed reserves. And projections leave the data after 2030, so late-century maps are illustrations.

## P24

[about 45 s]

To sum up. One: warming and survey effort contribute about equally, 1.36 against 1.43 per standard deviation, and one model can tell them apart. Two: warming shows most where few people look. Three: the observation process is the biggest piece, and the payoff from effort is falling. Four: partial migrants gain the most records, and net of geometry, records lean only slightly north. So send effort to under-surveyed regions that are warming fast. Birds or birders? Both. Model how we look, and the records tell us how ranges change.

## P25

[about 25 s]

Everything is open: the CBNR data on Zenodo, and all of the analysis code on GitHub, where every number in this talk traces back to a table. My thanks to my co-authors, to birdwatchers across China, and to every author whose records made this possible. Thank you. I'm happy to take your questions.

## P26

[about 35 s]

If asked about the future. We crossed two climate scenarios with two effort scenarios. Switching from SSP2-4.5 to SSP5-8.5 changes the expected national count from 26.1 to 25.9 records a year: essentially nothing. If effort keeps growing, the count roughly triples by 2050. What we will record depends on how we look, more than on how the climate changes. But most of that increase lies outside the data we fitted.

If asked: Is 79 to 89 records a year a forecast? No. At 2050 no cell is inside the fitted support; the credible statement is about 26 to 31 records a year in 2030, under any scenario.

## P27

[about 45 s]

Where would these records come from? This is 2030 under the middle emission scenario. With effort frozen, the expected records are spread thinly: the top province, Hunan, expects about 1.7 a year, and the top five provinces together hold a quarter of the national total. Let effort keep growing and Hunan rises to about 2, but the number of provinces where most species fall outside the fitted data doubles, from eight to sixteen, mostly in the south and east. The map tells you where to look, and also where not to trust the numbers.

## P28

[about 35 s]

So our rule is simple: report where the model breaks. Under SSP2-4.5, the share of species-province combinations inside the fitted range drops from 46 percent in 2030 to 6 percent in 2050, and to none by 2080, mostly because effort outgrows its observed range. Machine learning does not rescue it: inside the range the two model families agree, outside it they diverge. So 2030 is usable; end-of-century maps are illustrations, not forecasts.

## P29

[about 25 s]

If asked about dating. Dated to publication year, as most compilations do, the effort hazard ratio is 1.79 instead of 1.31, inflated by 37 percent, and an annual climate-variability effect appears at 0.85 with P below 0.001. Dated to discovery it vanishes, and warming barely moves. Publication lags discovery by about two years.

## P30

[about 15 s]

If asked about specifications: the signal is strongest for annual mean temperature over 15 to 20 years, and the coefficients are stable across effort proxies and missing-data rules.

## P31

[about 15 s]

If asked how warming is measured: the same province in the same year can warm more or less than a given species' range; that species-specific difference is the climate covariate.

## P32

[about 20 s]

If asked about finer scales: we split the problem into whether a province gets a new record and, if so, which county. Tested on 2019 to 2024, the top-ranked county was right 16 percent of the time, against about 1 percent by chance.

## P33

[about 20 s]

If asked about taxonomic differences: the eastward and north-eastward lean is shared by the larger orders; ducks and geese lean most strongly east, and the small orders are noisy. Read these against the geometric null, not at face value.

## P34

[about 5 s]

The same information as radar profiles, scaled from 0 to 100 percent within each order.

## P35

[about 20 s]

If asked about finer scales: the provincial expectation is split among prefectures by the 2024 allocation model, holding the shares fixed. Municipalities top the list because they are single units; among prefectures, Nyingchi in Xizang and Hanzhong in Shaanxi rank highest.

## P36

[about 15 s]

If asked about the full picture: each ribbon is a set of records, from order, to the province of the record, to the year it was published.

## P37

[about 5 s]

Key references cited on the background slides.

## P38

[about 5 s]

Short answers are on the slide; spoken answers follow, one per question.

If asked: Q1. Is a single record a range shift, or just a vagrant? Good question, and we're careful here. We never say any single record is a range shift; some are surely vagrants. What we model is the yearly chance that a species gets its first record in a province. And when we fit residents, partial migrants and long-distance migrants separately, warming and effort raise that chance in all three, including residents, where vagrancy isn't really the story.

If asked: Q2. Isn't effort partly a response to records, with birders chasing rarities? That's a fair worry. Our effort measure is all birding checklists in a province in a year, not trips for one species, so a single twitch barely moves it. On top of that, a province-by-year random effect soaks up local pulses. But I'd be honest: we can't rule out every feedback, so we read the effort effect as a strong association, not a causal estimate.

If asked: Q3. How exactly do you measure warming? We don't use raw provincial warming. For each species and province, we take the warming accumulated in that province and compare it with warming over the species' own range. So the same province can be 'warm' for one species and not for another. The signal is strongest for annual mean temperature over fifteen to twenty years, and the estimates are stable across effort proxies and missing-data rules.

If asked: Q4. Why a discrete-time hazard model, not counts or an SDM? Because a new record is an event that happens once. Each species-province pair is 'at risk' every year until it gets its first record, and then it drops out. That lets climate and effort change year by year, it accounts for how long each pair was exposed, and species and province differences go in as random effects. Counts or a distribution model would lose the timing, and timing is the whole point.

If asked: Q5. Why does dating to discovery matter so much? Because papers come out about two years after the bird was found, and effort keeps rising in between. If you date records to publication, as most compilations do, the effort effect is inflated by about a third, and a climate-variability effect shows up that simply isn't there when you use the discovery date. So the date you pick changes the answer.

## P39

[about 5 s]

Short answers are on the slide; spoken answers follow, one per question.

If asked: Q6. How reliable is CBNR, if a language model read the papers? The language model only speeds up the reading. Every single record was checked by hand against its source paper, and then we checked taxonomy against the 2026 Chinese catalogue, coordinates, duplicates and spatial outliers. Every step is logged, and the data are open on Zenodo, so anyone can audit it.

If asked: Q7. What about land-use change and other drivers? It's not in this model, and that's a real limit. Stable differences between provinces are absorbed by the province effect, and year-to-year shocks by the province-by-year effect, so land use can't masquerade as warming very easily. But testing land use directly, and how it interacts with climate, is exactly our next step.

If asked: Q8. Records point east. Isn't that a range expansion? It looks like one, but no. Most of these species have ranges centred west or south of China, so almost any record inside China lands to the east. Placing records at random among each species' possible provinces gives 235 in the east; we saw 237. Only after we add where birders go does a signal remain, and it points north: about 40 percent against 33. A modest poleward lean.

If asked: Q9. What should monitoring programmes do with this? The interaction is the practical part. Warming matters most where few people look, so that's where a new record tells you the most about climate. If I could move survey effort, I'd send it to under-surveyed regions that are warming fast, not to the places that are already well covered.

If asked: Q10. Can you predict where the next records will appear? In the near term, yes. For 2030 we expect about 26 to 31 new records a year nationally, whatever the emission scenario. At county level, when we tested on 2019 to 2024, our top-ranked county was right sixteen percent of the time, against about one percent by chance. But by 2050 the model is outside its data, so the late-century maps are illustrations, not forecasts.