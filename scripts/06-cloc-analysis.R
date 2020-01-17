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
    "Count the number of lines of code for each R-source file in a repository.",
    "This only considers files that are in the ./R/ subdirectory of an R",
    "package structure."
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
        "- 'all_pkg_cloc_file' (the single output file for this script)"
      )
    )
}

###############################################################################

get_cloc_details <- function(repo_details) {
  # We only analyse the contents of the ./R/ directory in the repo
  Map(
    function(pkg, path) {
      cloc::cloc_by_file(file.path(path, "R"))
    },
    repo_details[["package"]],
    repo_details[["local_repo"]]
  ) %>%
    dplyr::bind_rows(.id = "package")
}

format_cloc <- function(df) {
  df %>%
    dplyr::filter(language == "R")
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

source(here("scripts", "utils.R"))

opt <- optparse::parse_args(define_parser())
config <- yaml::read_yaml(opt$config)

main(
  repo_details_file = here(config[["repo_details_file"]]),
  results_file = here(config[["all_pkg_cloc_file"]])
)

# ggplot(cloc, aes(x = reorder(package, loc), y = log2(loc))) + geom_col()
#
# ggplot(
#   filter(tab, loc > 0),
#   aes(x = reorder(package, loc), y = log(loc))
#   ) +
#   geom_boxplot()

###############################################################################
