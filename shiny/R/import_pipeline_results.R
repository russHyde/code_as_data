library(dplyr)
library(readr)

import_pipeline_results <- function(files) {
  check_file(files, "cloc")
  check_file(files, "gitsum")

  cloc <- read_silently(files[["cloc"]])

  gitsum <- read_silently(files[["gitsum"]]) %>%
    # for consistency with cloc 'filename' column
    dplyr::rename(filename = changed_file)

  list(
    cloc = cloc,
    gitsum = gitsum
  )
}

#' Read a tsv, and keep quiet about it
read_silently <- function(path, ...) {
  readr::read_tsv(path, col_types = readr::cols(), ...)
}

#' Check that files[[label]] is a valid filepath
check_file <- function(files, label) {
  stopifnot(label %in% names(files))
  stopifnot(file.exists(files[[label]]))
}