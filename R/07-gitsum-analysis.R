###############################################################################

get_gitsum_results <- function(repo_details) {
   Map(
    function(pkg, path) {
      gitsum::init_gitsum(path, over_write = TRUE)

      gitsum::parse_log_detailed(path) %>%
        gitsum::unnest_log() %>%
        gitsum::set_changed_file_to_latest_name() %>%
        dplyr::filter(stringr::str_starts(changed_file, "R/"))
    },
    repo_details[["package"]],
    repo_details[["local_repo"]]
  )
}

format_gitsum <- function(list_of_dfs) {
  dplyr::bind_rows(list_of_dfs, .id = "package")
}

###############################################################################

main <- function(repo_details_file, results_file) {
  repo_details <- read_repo_details(repo_details_file)

  gitsum_results <- repo_details %>%
    get_gitsum_results() %>%
    format_gitsum()

  readr::write_tsv(gitsum_results, results_file)
}

###############################################################################

# script

###############################################################################

library("here")
source(here("R", "utils.R"))
source(here("R", "config.R"))

# pkgs require for running the script (not the packages that are analysed here)
load_packages(c("dplyr", "gitsum", "magrittr", "readr", "stringr", "tidyr"))

main(
  repo_details_file = config[["repo_details_file"]],
  results_file = config[["all_pkg_gitsum_file"]]
)

###############################################################################
