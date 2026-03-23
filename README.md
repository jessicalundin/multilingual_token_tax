# The Token Tax: Systematic Bias in Multilingual Tokenization

Code and data accompanying the paper:

> Jessica M. Lundin, Ada Zhang, Nihal Karim, Hamza Louzan, Guohao Wei, David Ifeoluwa Adelani, and Cody Carroll. 2026. [The Token Tax: Systematic Bias in Multilingual Tokenization](https://aclanthology.org/2026.africanlp-main.10/). In *Proceedings of the 7th Workshop on African Natural Language Processing (AfricaNLP 2026)*, pages 103–112, Rabat, Morocco. Association for Computational Linguistics.

## Overview

Tokenization inefficiency creates systematic disadvantages for morphologically complex, low-resource languages — inflating compute costs and reducing model accuracy. This repository contains evaluation results and analysis code for 10 large language models (LLMs) benchmarked on [AfriMMLU](https://github.com/masakhane-io/afrimmlu) across 16 African languages and 5 subjects.

Key findings:

- **Token fertility reliably predicts accuracy.** Higher fertility (more tokens per word) consistently predicts lower accuracy across all models and subjects, explaining up to 50% of variance in accuracy. Each additional token per word is associated with accuracy drops of up to 18 percentage points.
- **African languages trail English by ~30 percentage points** on average across models, with the largest gaps in Geography and Economics.
- **Reasoning models narrow but do not close the gap.** DeepSeek R1 and o1 outperform non-reasoning peers across both high- and low-resource languages, improving African language performance by 8–12 points on average.
- **The economic cost scales quadratically.** A 2x increase in token fertility produces a 4x increase in training time and cost — turning linguistic diversity into computational liability.

## Repository Contents

- `accuracy_files/` — Per-model accuracy results on AfriMMLU
- `charts/` — Notebooks and full result CSVs for generating figures
- `R_linear_fit/` — R scripts and figures for fertility–accuracy regression analysis

## Models Evaluated

| Category | Models |
|---|---|
| General LLMs | Llama 3.1 405B, Gemini 1.5 Pro, Claude Sonnet 3.5, DeepSeek V3, GPT-4o, Qwen 2.5 32B |
| Multilingual-focused | Aya 23 35B, Pixtral 12B |
| Reasoning models | DeepSeek R1, OpenAI o1 |

## Citation

```bibtex
@inproceedings{lundin-etal-2026-token,
    title = "The Token Tax: Systematic Bias in Multilingual Tokenization",
    author = "Lundin, Jessica M.  and
      Zhang, Ada  and
      Karim, Nihal  and
      Louzan, Hamza  and
      Wei, Guohao  and
      Adelani, David Ifeoluwa  and
      Carroll, Cody",
    booktitle = "Proceedings of the 7th Workshop on African Natural Language Processing (AfricaNLP 2026)",
    year = "2026",
    address = "Rabat, Morocco",
    publisher = "Association for Computational Linguistics",
    url = "https://aclanthology.org/2026.africanlp-main.10/",
    pages = "103--112",
}
```
