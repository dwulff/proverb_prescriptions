# LLM annotation scripts

The original Python scripts are preserved in [`code/llm/`](../code/llm/):

- `1_get_explanations.py`: generate a requested 30-word gist.
- `2_get_tags.py`: assign topic tags using the proverb and cleaned gist.
- `2_get_ratings.py`: assess ten dimensions using the proverb and cleaned gist, with a separate request for each dimension.

The scripts contain the complete prompts, response options, request settings, and batching logic. All specify `google/gemma-3-27b-it` and `max_tokens=500`; other sampling parameters were not explicitly set.

The tagging and rating scripts are unchanged from the saved originals. The gist script differs only in replacing the private corpus download URL with `PRIVATE_CORPUS_URL_REMOVED`. Original paths and resume settings are retained. The rating script declares `system_msg` but calls `system_prompt`; the saved file alone does not resolve that session variable.

These scripts document annotation generation and require the original private inputs and API configuration, plus Python packages `requests` and `pandas`. They are not part of the public analysis run. To reproduce the paper's analyses and figures, use the supplied text-free annotations and the R commands in the [README](../README.md).
