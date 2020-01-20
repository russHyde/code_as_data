###############################################################################

# pkgs require for running the script (not the packages that are analysed here)
general_pkgs <- c("here", "magrittr", "optparse", "yaml")
pkgs <-  c(general_pkgs, "dplyr", "gitsum", "readr", "stringr", "tidyr")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Obtain the file-changes from the git-history for a set of repositories.",
    "The repositories should be stored locally."
  )

  parser <- OptionParser(
    description = description
  ) %>%
    add_option(
      c("--config"), type = "character",
      help = paste(
        "A .yaml file containing the configuration details for the workflow.",
        "The .yaml should contain fields for the keys:",
        "- 'repo_details_file' (package,remote_repo,local_repo);",
        "- 'all_pkg_gitsum_file' (the single output file for this script)"
      )
    )
}

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

source(here("scripts", "utils.R"))

opt <- optparse::parse_args(define_parser())
config <- yaml::read_yaml(opt$config)

main(
  repo_details_file = here(config[["repo_details_file"]]),
  results_file = here(config[["all_pkg_gitsum_file"]])
)

###############################################################################
