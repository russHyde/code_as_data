###############################################################################

# For each package, we count the nummber of lines of R code using the `cloc`
# package and command-line tool

###############################################################################

get_cloc_details <- function(repo_details) {
  Map(
    function(pkg, path) cloc::cloc(path),
    repo_details[["package"]],
    repo_details[["local_repo"]]
  ) %>%
    dplyr::bind_rows()
}

format_cloc <- function(df) {
  df %>%
    dplyr::filter(language == "R") %>%
    dplyr::rename(package = source)
}

###############################################################################

main <- function(repo_details_file, results_file) {
  repo_details <- read_repo_details(repo_details_file)

  cloc_results <- repo_details %>%
    get_cloc_details() %>%
    format_cloc()

  readr::write_tsv(cloc_results, results_file)
}

###############################################################################

# script

###############################################################################

library("here")
source(here("R", "utils.R"))
source(here("R", "config.R"))

# pkgs require for running the script (not the packages that are analysed here)
load_packages(
  c("cloc", "dplyr", "magrittr", "purrr", "readr")
)

main(
  repo_details_file = config[["repo_details_file"]],
  results_file = config[["all_pkg_cloc_file"]]
)

# ggplot(cloc, aes(x = reorder(package, loc), y = log2(loc))) + geom_col()

###############################################################################
