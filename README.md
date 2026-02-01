# Reproducible Anime & Manga Popularity Pipeline

MADS 0246705627 Yoshiyuki Iguchi 

## Overview

This project implements a fully reproducible analytical pipeline using
**Nix** and **rixpress**. The goal is to clean, combine, and analyze
two datasets containing metadata about anime and manga titles, and to
study the relationship between popularity and user ratings.

The pipeline is designed so that anyone can reproduce the results on a
fresh machine with a single command.

---

## Dataset

The project uses two CSV datasets:

- `data/anime.csv`
- `data/manga.csv`

Both datasets contain metadata such as:

- title and type
- score (user rating)
- number of members (popularity)
- favorites
- genres and demographics

The raw data contains missing values and inconsistent types, which
require cleaning before analysis.

---

## Pipeline

The pipeline is implemented in `gen-pipeline.R` using **rixpress** and
consists of the following steps:

1. Load raw CSV files
2. Clean and standardize variables
   - enforce numeric score ranges (0–10)
   - remove invalid rows
   - normalize dates
3. Combine anime and manga into a single table
4. Compute summary statistics by medium
5. Estimate correlation between popularity and score
6. Produce a ggplot visualization object

All steps are tracked as derivations and executed reproducibly through Nix.

---

## Reproducibility

To reproduce the pipeline from scratch:

```bash
git clone https://github.com/Yoshiyuki-Iguchi/anime_manga_pipeline
cd anime_manga_pipeline
nix-build
nix-shell --run 'R -q -e "Sys.setenv(RXP_PROJECT_PATH=normalizePath(\".\")); source(\"gen-pipeline.R\"); rixpress::rxp_make(); testthat::test_dir(\"tests/testthat\")"'
```
---

## Testing

The project includes automated tests using testthat:

dataset is not empty

score ranges are valid

popularity values are positive

anime/manga labels are consistent

correlation output structure is valid

These tests ensure that the cleaning pipeline behaves as expected.

---

## Viewing the Results

After running the pipeline, all derived objects are stored in the
rixpress cache and can be accessed directly from R.

Start an R session inside the nix-shell:

```bash
R
```

Then load the results:

```r
library(rixpress)

summary <- rxp_read("summary_by_medium")
corr <- rxp_read("corr_score_popularity")
plot <- rxp_read("plot_score_vs_popularity")
```

### Summary statistics

```r
summary
```

Displays descriptive statistics for anime and manga, including
mean score and popularity measures.

### Correlation analysis

```r
corr
```

Shows Pearson and Spearman correlations between popularity
(log-members) and user ratings.

### Visualization

```r
plot
```

Displays a scatter plot of score vs popularity with a smoothing curve.

These objects are generated entirely from the reproducible pipeline —
no manual preprocessing is required.

---
