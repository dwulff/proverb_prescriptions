# Annotation preservation audit — 25 November 2026

Scope: compare this release with the saved files in the sibling `proverb_preference` repository. This checks source and data preservation, not an unavailable historical API session. No API requests were made. The manuscript and GUIDE document mentioned in external feedback are not present in this repository and were not reviewed or edited.

## Three checks

1. **Historical source preservation.** Added all three original annotation scripts under `code/llm/historical/`. Tags and ratings scripts are byte-identical. The gist script differs only in redacting the private corpus download URL. Original/shared SHA-256 hashes and the sole modification are in `historical/provenance.json`. Original batching, request construction, cleanup, file paths, restart offsets, and variable names are retained, including defects.
2. **Prompt and request comparison.** Compared the extracted system prompts, tag template, ten assessment questions, response sets, reasoning/output instructions, and dimension order against executable assignment expressions from the original source. Also compared constructed gist and all ten rating user messages using synthetic placeholders. All matched. Every original request specifies the same model (`google/gemma-3-27b-it`) and `max_tokens=500`. This establishes preserved wording, not that the declared rating system message was actually sent.
3. **Raw-to-public data comparison.** Re-read the original raw annotation CSV and executed its original R rating parser. All 495,280 numeric values match the public 49,528 × 10 rating matrix exactly. Reconstructed tag extraction also matches all 148,491 public tag rows and positions after the eight documented aliases. All 49,528 proverb IDs match the private lookup in order. No public data or figures were modified in this audit.

## Assessment of the external feedback

| Concern | Finding and remaining evidence needed |
| --- | --- |
| Actual rating system prompt | Valid uncertainty. The original script declares `system_msg` but invokes `system_prompt`, undefined in that standalone file. An interactive session could have supplied a value, but there is no saved session evidence establishing which one. Describe the quoted prompt as the one declared in the saved code, not as a verified transmitted prompt. |
| Sampling settings | The saved request dictionaries contain model, messages, and `max_tokens=500`; they do not set temperature, seed, top-p, or other sampling controls. Effective sampling defaults were not recovered. Do not invent these settings. |
| Run date | Original output modification dates are May 17 (gists), May 19 (tags), and June 6, 2025 (ratings). These suggest a period but do not prove generation dates. No matching request logs or session histories were found in the reference folder. |
| Gist step in Methods | The workflow explicitly requests a 30-word gist, cleans the response, and includes it in both tag and rating prompts. This is a requested length, not a verified 30-word output constraint. The manuscript should describe this step; its current wording was not available here. |

## What is deliberately different or not distributed

The adapted runner uses the declared rating system message, sequential execution, environment credentials, a private indexed lookup, and per-request checkpoints. It removes the original hard-coded restart positions. It is not historical execution evidence. The source archive now preserves those original details separately.

Books, proverb text, raw explanations/responses, credentials, and private download access are not distributed. The private reference still contains the original raw annotations. The public lookup is absent by design; a local lookup remains under ignored `private/`. Topic aliases and cached map inputs remain as documented in the input codebook. The embedding/map-generation workflow is not rebuilt by the optional runner.

Exact regeneration of historical LLM outputs is not established. Reproduction of downstream analysis uses the supplied annotations, rather than newly sampled model responses.
