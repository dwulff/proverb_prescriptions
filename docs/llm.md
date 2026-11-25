# LLM annotation procedure

The [historical scripts](../code/llm/historical/) preserve the saved original code (only the private corpus download URL is redacted). **`annotate.py` is a new, adapted runner, not the code that generated the supplied ratings.** See the [preservation audit](llm-audit.md) for verified matches and unresolved historical details.

[`code/llm/prompts.py`](../code/llm/prompts.py) contains the original system prompts, gist and tagging templates, all ten assessment questions, their five response options, and the rating output instructions. Wording was extracted from the private reference repository's `1_get_explanations.py`, `2_get_tags.py`, and `2_get_ratings.py`. No proverb examples or credentials are included.

The workflow represented by the saved scripts is: generate a gist, assign topic tags using the proverb and cleaned gist, then assess each of ten dimensions in a separate request using the proverb and cleaned gist. Ratings did not use the topic tags. Every request specified `google/gemma-3-27b-it` and `max_tokens=500`. Temperature, seed, and other sampling parameters were not specified. The effective sampling defaults are not recorded, so exact regeneration is not guaranteed.

## Inspect or rerun

Python 3, standard library only. From the repository root, preview all twelve request templates with synthetic placeholders, without reading private data or making requests:

```sh
python3 code/llm/annotate.py
```

For an optional rerun, supply `private/proverb_lookup.csv` with columns `proverb_id,proverb` (not distributed). Configure `LLM_API_URL` with an HTTPS chat-completions endpoint and `LLM_AUTHORIZATION` with its full authorization header value (typically `Bearer ...`) in your environment. Then:

```sh
python3 code/llm/annotate.py --run --limit 1
```

This sends proverb text and generated gists to the configured service and makes 12 requests per item. Increase `--limit` explicitly for more items. Empty proverb fields, including reserved ID 49,529, are skipped. The script saves each completed request to `private/llm/annotations.jsonl` and resumes matching requests on subsequent runs. Use a different `--output-name` for an independent rerun. Outputs and the lookup are ignored by Git; they can contain copyrighted text. No public input or figure is overwritten.

Each JSONL record includes `proverb_id`, `stage` (`gist`, `tags`, or a dimension), `endpoint`, the complete `request`, API `response`, and text `answer`. Authorization credentials are not saved. These are new raw annotations, not replacements for the released CSVs.

## Historical limitations and adaptations

The saved original rating script defines `system_msg` but calls `system_prompt`, which is undefined in that standalone script. It also loads a temporary checkpoint and starts at dimension 9 and batch 109. Therefore, that file cannot establish which system prompt actually reached the model in the historical run. The rerun uses the explicitly declared rating system message; the other original system prompts are also available for inspection. It starts all ten dimensions and replaces the hard-coded restart positions with checkpoints.

The original scripts used parallel batches of 200 (gist), 400 (tags), and 300 (ratings) requests. This adaptation sends requests sequentially, defaults to one item, uses environment credentials, reads the private ID lookup instead of a remote corpus link, checks HTTP failures, and records requests and responses. Prompt content and declared model/token settings are preserved.

## From raw answers to released data

The original R analysis extracted the first printable `Answer=` or `Answer:` span, removed square brackets, lowercased it, normalized curly apostrophes, and matched it exactly to the ordered five response options. The option positions became integers 1–5. See [the input codebook](../data/CODEBOOK.md) for the dimension directions and human-rating reverse coding.

Topic extraction used the printable `Answer=` or `Answer:` span, removed `Answer=`, split at semicolons, collapsed whitespace, and lowercased tags. It did not strictly enforce the requested three-tag/two-word limits. The public release additionally replaces eight tags that matched complete corpus entries with withheld-topic aliases. Gist cleanup is retained in `clean_gist()` in the rerun script.

The public analysis continues to use the supplied numeric ratings, parsed tags, and cached topic map. This optional workflow exposes annotation prompts and allows new annotations; it does not rebuild the embedding/map pipeline or automatically apply new annotations to the analysis.
