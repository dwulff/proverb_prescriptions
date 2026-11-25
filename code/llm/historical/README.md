# Historical annotation scripts

These are the saved scripts from the original `proverb_preference/2_code` folder, **not** the adapted rerun implementation. The tags and ratings scripts are byte-identical to those originals. The explanation script differs only in replacing its private corpus download URL with `PRIVATE_CORPUS_URL_REMOVED`. `provenance.json` records SHA-256 hashes and the exact change.

They preserve the original prompts, payloads, batch sizes, input/output paths, gist cleaning, temporary-checkpoint load, restart offsets, and variable-name bug. They are evidence of the saved source, not proof of the exact executed session. They require the old private files, credentials, `requests`, and `pandas`; they are not a working standalone public pipeline. Do not execute them as part of the reproduction instructions.

In particular, `2_get_ratings.py` declares `system_msg` but passes `system_prompt` to the request helper. It resumes at the tenth dimension and batch 110 (zero-based offsets 9 and 109). Neither issue is silently repaired here. The separately adapted [`../annotate.py`](../annotate.py) repairs these execution issues and is **not the code used to generate the historical ratings**.
