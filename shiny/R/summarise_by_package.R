library(dplyr)

summarise_cloc <- function(df) {
  # collapses the raw cloc dataset (which has one row per file) by package name
  # taking the total of the lines of code
  df %>%
    dplyr::group_by(package) %>%
    dplyr::summarise_if(is.numeric, sum)
}

summarise_gitsum <- function(df) {
  df %>%
    dplyr::group_by(package) %>%
    dplyr::summarise(
      n_commits = dplyr::n_distinct(hash),
      n_contributors = dplyr::n_distinct(author_email)
    )
}

summarise_by_package <- function(cloc_data, gitsum_data) {
  cloc <- summarise_cloc(cloc_data)
  gitsum <- summarise_gitsum(gitsum_data)

  dplyr::left_join(gitsum, cloc)
}
