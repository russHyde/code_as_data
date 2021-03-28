library(dplyr)
library(readr)

import_pipeline_results <- function(cloc_file, gitsum_file) {
  stopifnot(file.exists(cloc_file))
  stopifnot(file.exists(gitsum_file))

  cloc <- readr::read_tsv(cloc_file)

  gitsum <- readr::read_tsv(gitsum_file, col_types = readr::cols()) %>%
    # for consistency with cloc 'filename' column
    dplyr::rename(filename = changed_file)

  list(
    cloc = cloc,
    gitsum = gitsum
  )
}
