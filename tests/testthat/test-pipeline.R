# tests/testthat/test-pipeline.R
library(testthat)
library(rixpress)

# Get project root from env var (set before running tests)
PROJECT <- Sys.getenv("RXP_PROJECT_PATH", unset = NA_character_)
if (is.na(PROJECT) || PROJECT == "") {
  stop("RXP_PROJECT_PATH is not set. Run: Sys.setenv(RXP_PROJECT_PATH = normalizePath('.')) before test_dir().")
}

test_that("combined data is not empty", {
  df <- rxp_read("combined", project_path = PROJECT)
  expect_gt(nrow(df), 0)
})

test_that("score is within 0..10 and members are positive", {
  df <- rxp_read("combined", project_path = PROJECT)
  expect_true(all(df$score >= 0 & df$score <= 10))
  expect_true(all(df$members > 0))
})

test_that("medium column contains only anime/manga", {
  df <- rxp_read("combined", project_path = PROJECT)
  expect_true(all(df$medium %in% c("anime", "manga")))
})

test_that("correlation table exists and is sane", {
  corr <- rxp_read("corr_score_popularity", project_path = PROJECT)
  expect_true(all(c("medium","n","pearson","spearman") %in% names(corr)))
  expect_true(all(corr$medium %in% c("anime", "manga")))
  expect_true(all(is.finite(corr$pearson)))
  expect_true(all(is.finite(corr$spearman)))
})
