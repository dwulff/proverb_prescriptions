# Proverb prescriptions

Reproduce five figures and their numerical results from text-free proverb annotations. Original proverbs, books, model explanations, and survey text are not included; records are linked by `proverb_id`.

From the repository root, using R (tested with 4.6.1):

```sh
Rscript code/setup.R
Rscript code/analysis.R
```

Setup installs the versions in `renv.lock` and requires internet access. Analysis runs offline and writes to `figures/` and `results/`. The generated `results/` folder is excluded from Git.

See [data/CODEBOOK.md](data/CODEBOOK.md) for input schemas, scales, and provenance, and [docs/analysis.md](docs/analysis.md) for outputs and analysis conventions. The analysis starts from the supplied annotations and cached topic map; it does not regenerate them from books or language models.

The original [LLM annotation scripts](code/llm/) include the prompts for gist generation, topic labeling, and ratings. See [docs/llm.md](docs/llm.md) for their scope and model settings.
