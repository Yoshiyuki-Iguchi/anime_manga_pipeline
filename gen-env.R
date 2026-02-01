# gen-env.R
library(rix)

rix(
  date = "2026-01-26",
  r_pkgs = c(
    "readr","dplyr","stringr","janitor",
    "lubridate","ggplot2","scales",
    "rixpress",
    "testthat"
  ),
  ide = "none",
  project_path = ".",
  overwrite = TRUE
)
