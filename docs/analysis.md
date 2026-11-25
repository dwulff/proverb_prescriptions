# Analysis outputs

`Rscript code/analysis.R` regenerates these CSV tables and five PNG figures. All CSV files have headers; `NA` denotes missing values. Dimension names and rating directions are defined in `data/CODEBOOK.md`.

| File | Row unit and columns |
| --- | --- |
| `human_alignment.csv` | Presentation condition (`gist`) × `dimension`; `cor` is the Pearson correlation between the two individual human raters across items |
| `human_ai_alignment.csv` | `gist` × `dimension`; `cor` compares the mean of the two human raters with model ratings across items |
| `aggregate_alignment.csv` | `gist` × `comparison` (`human-human` or `human-LLM`); `cor` is the Pearson correlation across the nine dimension means, excluding prescriptivity |
| `prescriptivity_overall.csv` | One row (`book = average`); `prescriptivity` is the proportion of analyzed items rated 4 or 5 |
| `prescriptivity_sources.csv` | One row per `book`; `prescriptivity` is the proportion of its source records rated 4 or 5 |
| `prescriptivity_topics.csv` | One row per grouped topic `tag`; `n` counts matching items and `normative` is their prescriptive proportion |
| `polarity_llm.csv` | One row per dimension `name`; `mid` and `polarity` are defined below |
| `polarity_human.csv` | One row per `dimension`; `mid` and `polarity` are defined below |
| `dimension_averages.csv` | One row per dimension `name`; `avg` is the model mean and `se` its standard error across prescriptive items |
| `dimension_sources.csv` | `book` × dimension `name`; `avg` and `se` summarize model ratings of prescriptive source records |
| `dimension_human.csv` | One row per `dimension`; `avg` is the mean of condition-specific human averages for human-selected prescriptive items |
| `dimension_topics.csv` | Raw topic `tag` × dimension `dim`; `avg` is the model mean among matching prescriptive items |
| `sessionInfo.txt` | R, platform, and package versions from the analysis run |

## Figure mapping

- `figures/01_map.png`: cached topic map, colored by cluster and sized by frequency.
- `figures/01b_performance.png`: human-human and human-model alignment, including aggregate alignment.
- `figures/02_normative.png`: prescriptivity by grouped topic, with overall/source reference lines.
- `figures/03_polarity.png`: polarity and extremity for the nine dimensions, comparing model and human summaries.
- `figures/03b_dimensions.png`: dimension means by raw topic, with model, human, and source summaries.

## Conventions preserved from the original analysis

Model-based dimension analyses use items with model prescriptivity > 3. Human-based dimension analyses select items whose prescriptivity averaged over raters and conditions exceeds 3. Thus the human and model subsets need not coincide.

`mid` is the plotted “Extremity”: `1 - mean(value == 3)`. `polarity` is `2 * min(mean(value %in% c(1, 2)), mean(value %in% c(4, 5)))`: twice the smaller proportion of ratings at the two opposing poles. Entirely neutral ratings yield 0; equally frequent opposing poles with no neutral ratings yield 1. This uses the alternative formula commented in the saved original script, confirmed by the author as the formula used for the paper.

The human polarity/extremity calculation pools the two individual raters and their within-condition average, across both conditions. The inclusion of averaged ratings affects the frequency of exact-neutral responses. Polarity uses exact membership in {1, 2} and {4, 5}, so fractional averages are retained in the denominator but count toward neither pole. Human-model alignment compares averaged human ratings with the model, whereas human-human alignment compares individuals.

Source summaries retain source-row multiplicity. The 77 records associated with the reserved empty-entry ID have no model rating and count as non-prescriptive in the original source prescriptivity denominator. They do not enter the overall corpus or prescriptive dimension analyses. Records with missing source codes are excluded from source summaries.

Grouped-topic prescriptivity includes topics with at least 200 occurrences across the four tag-label columns, then counts items matching each topic. Raw-topic dimension summaries include tags with at least 40 occurrences among prescriptive items, and compute a mean only with more than 10 nonmissing item ratings. `se = sd(value)/sqrt(n)` describes row-level variation; it is not adjusted for proverb variants or overlapping sources. Dimension plots label topic means below the 2.5th or above the 97.5th percentile within a dimension.

Random seeds are fixed for label placement. Graphics can still differ across operating systems, fonts, or package versions. Calculations and analysis conventions are preserved; unused exploratory blocks and presentation composites were removed.

The map and grouped-topic prescriptivity figures intentionally share a size
scale between points and labels (ranges 2–5 and 0.8–4, respectively). Do not
introduce a separate size scale: that changes the original visual encoding.
PNG backgrounds are explicitly transparent, matching the reference exports.
