###############################################################################

# pkgs require for running the script
general_pkgs <- c("here", "magrittr", "optparse", "yaml")
pkgs <-  c(general_pkgs, "readr", "purrr")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Merge the git-history results for a set of repositories."
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
        "- 'pkg_results_dir' (the parent directory for the package-specific",
        "analyses)."
      )
    ) %>%
    add_option(
      c("--output", "-o"), type = "character",
      help = paste(
        "The output .tsv file. This will contain the gitsum values across all",
        "repos studied here."
      )
    )
}

###############################################################################

define_gitsum_files <- function(packages, parent_dir) {
  file.path(parent_dir, packages, "gitsum.tsv")
}

import_gitsum_files <- function(files) {
  files %>%
    purrr::map_df(readr::read_tsv, col_types = readr::cols())
}

###############################################################################

main <- function(repo_details_file, pkg_results_dir, results_file) {

  repo_details <- read_repo_details(repo_details_file)
  packages <- repo_details[["package"]]

  gitsum_files <- define_gitsum_files(packages, pkg_results_dir)

  gitsum_data <- import_gitsum_files(gitsum_files)

  readr::write_tsv(gitsum_data, results_file)
}

###############################################################################

# script

###############################################################################

source(here("scripts", "utils.R"))

opt <- optparse::parse_args(define_parser())
config <- yaml::read_yaml(opt$config)

main(
  repo_details_file = here(config[["repo_details_file"]]),
  pkg_results_dir = here(config[["pkg_results_dir"]]),
  results_file = here(opt$output)
)

###############################################################################
