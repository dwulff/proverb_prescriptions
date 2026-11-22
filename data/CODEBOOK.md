# Input data

All files are UTF-8 CSV, with a header row. `NA` denotes missing data. These are the six inputs required by `code/analysis.R`. No proverb text, text-to-ID crosswalk, generated explanations, model reasoning, survey question text, or personal survey metadata is distributed.

## IDs and provenance

`proverb_id` is a stable integer key shared across files, assigned sequentially in the original analyzed corpus order. IDs 1–49,528 have model ratings. ID 49,529 is reserved for an empty original corpus entry: 77 source records referred to it, but it had no analyzed text or ratings. Those records remain solely to preserve the original source-level prescriptivity denominators. IDs are identifiers, not measurements; do not resample or regenerate them.

The private corpus was extracted from seven proverb collections, with variants and source memberships retained. Model annotations were produced by `google/gemma-3-27b-it`: an approximately 30-word gist, topic tags, and ten five-point ratings based on the proverb and gist. Only parsed numeric answers and short topic tags are retained here. Human ratings cover the original fixed 500-item validation sample, now linked directly by global `proverb_id` rather than survey position.

Eight distinct topic strings exactly matched complete entries in the private corpus (including very short entries). These have been replaced consistently by `withheld_topic_01` through `withheld_topic_08`, including map labels where applicable. They remain distinct categories; the aliases do not affect frequencies, group memberships, or ratings.

## ratings.csv

49,528 rows; one row per analyzed proverb. Primary key: `proverb_id`.

| Column | Meaning |
| --- | --- |
| `proverb_id` | Global integer ID |
| `prescriptivity_num` | Whether the proverb provides guidance on how to act or make decisions |
| `risk_num` | Caution versus risk |
| `time_num` | Long-term versus short-term consequences |
| `social_num` | Other people's versus own interests |
| `autonomy_num` | Compliance versus autonomy |
| `trust_num` | Trust versus suspicion |
| `honesty_num` | Honesty versus deception |
| `equality_num` | Equality versus hierarchy |
| `kindness_num` | Kindness versus malice |
| `cooperation_num` | Cooperation versus competition |

All ratings are integers 1–5, with no missing values. For prescriptivity: 1 = strong no, 2 = no, 3 = indifferent, 4 = yes, 5 = strong yes. For the remaining dimensions: 1 = strongly favors the first pole listed above, 2 = favors the first pole, 3 = indifferent, 4 = favors the second pole, 5 = strongly favors the second pole. Prescriptive items are those with `prescriptivity_num > 3`.

## tags.csv

148,491 rows. Primary key: (`proverb_id`, `tag_position`).

| Column | Meaning |
| --- | --- |
| `proverb_id` | Foreign key to `ratings.csv` |
| `tag_position` | Original tag order within an item, 1–4 |
| `tag` | Parsed, lowercase topic string or withheld-topic alias |

Tags describe both general meaning and concrete imagery. The prompt requested up to three tags of up to two words, but the retained responses include exceptions (four tags or three-word tags). Original multiplicity and ordering are preserved. A proverb can have multiple tags belonging to the same map group.

## sources.csv

56,767 rows. This is a source-membership table, not a one-row-per-proverb table. Duplicate (`proverb_id`, `book`) pairs are intentionally preserved because the original source summaries counted these rows; deduplication changes the analysis.

| Column | Meaning |
| --- | --- |
| `proverb_id` | Global ID; 49,529 is the reserved empty-entry ID described above |
| `book` | Source code below; `NA` for 82 records without source attribution |

| Code | Collection |
| --- | --- |
| `adoap` | A Dictionary of American Proverbs |
| `adop` | A Dictionary of Proverbs (Oxford, 2008) |
| `doaap` | Dictionary of Authentic American Proverbs (2021) |
| `lodop` | Little Oxford Dictionary of Proverbs (2016) |
| `rbowp` | Routledge Book of World Proverbs (2006) |
| `tdomp` | The Dictionary of Modern Proverbs (2012) |
| `tmdop` | The Multicultural Dictionary of Proverbs |

## human_ratings.csv

20,000 rows: 500 items × 2 raters × 2 presentation conditions × 10 dimensions. Primary key: (`proverb_id`, `rater`, `gist`, `dimension`). No missing ratings.

| Column | Meaning |
| --- | --- |
| `proverb_id` | Foreign key to `ratings.csv`; the fixed validation sample |
| `rater` | Anonymous identifier: `Rater_1` or `Rater_2` |
| `gist` | `gist`: proverb accompanied by generated explanation; `no gist`: proverb alone |
| `dimension` | One of the ten rating names above, without `_num` |
| `value` | Integer 1–5 on the same scale as the model ratings |

Human risk, time, social, and autonomy ratings were reverse-coded (`6 - original value`) during preparation to align their direction with the model ratings. Do not reverse-code them again. `gist` is a condition label, not explanation text.

## tag_map.csv

3,362 rows; one cached semantic tag group per row. Primary key: `tag_group_id`.

| Column | Meaning |
| --- | --- |
| `tag_group_id` | Integer group ID, 1–3,362 |
| `labels` | Representative topic label or withheld-topic alias |
| `n` | Cached sum of member-tag occurrence frequencies |
| `lyt_x`, `lyt_y` | Cached two-dimensional map coordinates; arbitrary units |
| `cluster` | Integer visual cluster, 1–20 |

The original map workflow used Qwen/Qwen3-Embedding-0.6B tag embeddings, complete-linkage grouping of similar tags, and PaCMAP coordinates. Visual clusters were obtained by complete-linkage clustering of the two-dimensional coordinates. This release preserves the exact cached groups and coordinates used by the original analysis; it does not recreate embeddings or dimensionality reduction. The map frequencies are cached rather than recomputed after excluding the empty corpus entry.

## tag_groups.csv

15,236 rows; one row per distinct original tag. Primary key: `tag`.

| Column | Meaning |
| --- | --- |
| `tag_group_id` | Foreign key to `tag_map.csv` |
| `tag` | Member tag string or withheld-topic alias, also used in `tags.csv` |

Every observed item tag is covered by this mapping. The map can include cached tags not present among the analyzed items.
