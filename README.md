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

## Project Structure

```
anime_manga_pipeline/
│
├── data/
│   ├── anime.csv
│   └── manga.csv
│   Raw datasets used for analysis.
│
├── gen-pipeline.R
│   Main reproducible pipeline definition.
│   Implements cleaning, merging, analysis, and plotting.
│
├── gen-env.R
│   Script used to generate the pinned Nix environment.
│   Not required to run the pipeline, but documents how the environment was created.
│
├── default.nix
│   Fully pinned environment specification.
│   Guarantees reproducible software dependencies.
│
├── pipeline.nix
│   Auto-generated rixpress pipeline derivations.
│
├── tests/
│   └── testthat/
│       └── test-pipeline.R
│   Automated tests validating data integrity and pipeline correctness.
│
├── .github/
│   └── workflows/
│       └── ci.yml
│   GitHub Actions configuration for continuous integration.
│
└── README.md
    Project documentation and reproduction instructions.
```
___

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
This is for one command.

(Additional Information)
```r
Sys.setenv(RXP_PROJECT_PATH=normalizePath("."))
```

This sets the project root path so the tests can reliably locate the rixpress build cache.

Here is Step-by-step run (alternative):
```bash
git clone https://github.com/Yoshiyuki-Iguchi/anime_manga_pipeline
cd anime_manga_pipeline
nix-build
nix-shell
R
Sys.setenv(RXP_PROJECT_PATH = normalizePath("."))
source("gen-pipeline.R")
rixpress::rxp_make()
testthat::test_dir("tests/testthat")
```

---

## After Running the Pipeline

Once the pipeline command finishes successfully:

```bash
nix-shell --run 'R -q -e "Sys.setenv(RXP_PROJECT_PATH=normalizePath(\".\")); source(\"gen-pipeline.R\"); rixpress::rxp_make(); testthat::test_dir(\"tests/testthat\")"'
```

you can inspect the generated results interactively in R.

Start a new R session inside the nix-shell:

```bash
nix-shell
R
```

Then load the derived objects:

```r
library(rixpress)

summary <- rxp_read("summary_by_medium")
corr <- rxp_read("corr_score_popularity")
plot <- rxp_read("plot_score_vs_popularity")
```

### View summary statistics

```r
summary
```

### View correlation analysis

```r
corr
```

### View visualization

```r
plot
```

All outputs are produced by the reproducible pipeline and stored
in the rixpress cache. No manual preprocessing is required.

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

## Conclusion

The analysis highlights a measurable relationship between popularity
and user ratings in anime and manga datasets.

More importantly, the project demonstrates the practical value of
reproducible pipelines: every step of the workflow is automated,
documented, and testable.

Such reproducibility is essential for reliable data science and
collaborative research.
