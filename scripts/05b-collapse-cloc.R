###############################################################################

# For each package, we count the nummber of lines of R code using the `cloc`
# package and command-line tool

###############################################################################

# pkgs require for running the script (not the packages that are analysed here)
general_pkgs <- c("here", "magrittr", "optparse", "yaml")
pkgs <-  c(general_pkgs, "cloc", "dplyr", "purrr", "readr")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Combine the results from cloc analysis of individual packages into a",
    "single file."
  )

  parser <- OptionParser(
    description = description
  ) %>%
    add_option(
      c("--config"), type = "character",
      help = paste(
        "A .yaml file containing the configuration details for the workflow.",
        "The .yaml should contain fields for the keys:",
        "- 'repo_details_file' (package,remote_repo,local_repo).",
        "- 'pkg_results_dir' (the parent directory for the package-specific",
        "analyses)"
      )
    ) %>%
    add_option(
      c("--output", "-o"), type = "character",
      help = paste(
        "The output .tsv file. This will contain the line-counts across all",
        "packages."
      )
    )
}

###############################################################################

define_cloc_files <- function(packages, parent_dir) {
  file.path(parent_dir, packages, "cloc_by_file.tsv")
}

import_cloc_files <- function(files) {
  files %>%
    purrr::map_df(readr::read_tsv, col_types = readr::cols())
}

###############################################################################

main <- function(repo_details_file, pkg_results_dir, results_file) {
  repo_details <- read_repo_details(repo_details_file)
  packages <- repo_details[["package"]]

  cloc_files <- define_cloc_files(packages, pkg_results_dir)

  cloc_data <- import_cloc_files(cloc_files)

  readr::write_tsv(cloc_data, results_file)
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

# ggplot(cloc, aes(x = reorder(package, loc), y = log2(loc))) + geom_col()
#
# ggplot(
#   filter(tab, loc > 0),
#   aes(x = reorder(package, loc), y = log(loc))
#   ) +
#   geom_boxplot()

###############################################################################
