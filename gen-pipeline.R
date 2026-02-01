# gen-pipeline.R
# Reproducible pipeline with rixpress:
# - load anime.csv / manga.csv
# - clean + standardize
# - combine
# - summary + correlation analysis
# - create ggplot object (no PNG output)

library(rixpress)
library(dplyr)
library(readr)
library(janitor)
library(lubridate)
library(ggplot2)

pipeline <- list(
  # 1) Load raw data
  rxp_r_file(
    name = anime_raw,
    path = "data/anime.csv",
    read_function = \(x) readr::read_csv(x, show_col_types = FALSE)
  ),
  rxp_r_file(
    name = manga_raw,
    path = "data/manga.csv",
    read_function = \(x) readr::read_csv(x, show_col_types = FALSE)
  ),

  # 2) Clean anime
  rxp_r(
    name = anime_clean,
    expr = {
      anime_raw |>
        janitor::clean_names() |>
        transmute(
          medium = "anime",
          id = anime_id,
          title = title,
          type = type,
          score = as.numeric(score),
          scored_by = as.numeric(scored_by),
          members = as.numeric(members),
          favorites = as.numeric(favorites),
          sfw = as.logical(sfw),
          approved = as.logical(approved),
          start_date = suppressWarnings(lubridate::ymd(start_date)),
          start_year = as.integer(start_year),
          status = status,
          genres = genres,
          themes = themes,
          demographics = demographics
        ) |>
        filter(
          !is.na(score),
          score >= 0, score <= 10,
          !is.na(members),
          members > 0
        )
    }
  ),

  # 3) Clean manga
  rxp_r(
    name = manga_clean,
    expr = {
      manga_raw |>
        janitor::clean_names() |>
        transmute(
          medium = "manga",
          id = manga_id,
          title = title,
          type = type,
          score = as.numeric(score),
          scored_by = as.numeric(scored_by),
          members = as.numeric(members),
          favorites = as.numeric(favorites),
          sfw = as.logical(sfw),
          approved = as.logical(approved),
          start_date = suppressWarnings(lubridate::ymd(start_date)),
          start_year = as.integer(lubridate::year(start_date)),
          status = status,
          genres = genres,
          themes = themes,
          demographics = demographics
        ) |>
        filter(
          !is.na(score),
          score >= 0, score <= 10,
          !is.na(members),
          members > 0
        )
    }
  ),

  # 4) Combine
  rxp_r(
    name = combined,
    expr = bind_rows(anime_clean, manga_clean)
  ),

  # 5) Summary table (quick sanity + useful output)
  rxp_r(
    name = summary_by_medium,
    expr = {
      combined |>
        group_by(medium) |>
        summarise(
          n = n(),
          score_mean = mean(score, na.rm = TRUE),
          score_median = median(score, na.rm = TRUE),
          members_median = median(members, na.rm = TRUE),
          favorites_median = median(favorites, na.rm = TRUE),
          .groups = "drop"
        )
    }
  ),

  # 6) Correlation analysis: score vs popularity (log10 members)
  rxp_r(
    name = corr_score_popularity,
    expr = {
      combined |>
        mutate(members_log10 = log10(members)) |>
        group_by(medium) |>
        summarise(
          n = n(),
          pearson = cor(members_log10, score, use = "complete.obs", method = "pearson"),
          spearman = cor(members_log10, score, use = "complete.obs", method = "spearman"),
          .groups = "drop"
        )
    }
  ),

  # 7) Plot object (not saved to file)
  rxp_r(
    name = plot_score_vs_popularity,
    expr = {
      combined |>
        mutate(members_log10 = log10(members)) |>
        ggplot(aes(x = members_log10, y = score, color = medium)) +
        geom_point(alpha = 0.25, size = 0.8) +
        geom_smooth(se = FALSE, method = "loess", formula = y ~ x) +
        labs(
          title = "Score vs popularity (log10 members)",
          x = "log10(members)",
          y = "score"
        ) +
        theme_minimal()
    }
  )
) |>
  rxp_populate()

