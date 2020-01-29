###############################################################################

# pkgs require for running the script
general_pkgs <- c("here", "magrittr", "optparse")
pkgs <-  c(general_pkgs, "dplyr", "gitsum", "readr", "stringr", "tibble")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Obtain the file-changes from the git-history for a repository.",
    "The repository should be stored locally."
  )

  parser <- OptionParser(
    description = description
  ) %>%
    add_option(
      "--local_repo", type = "character",
      help = paste(
        "The path to the repository to analyse.",
        "Only files within the ./R/ subdirectory will be included in the",
        "results."
      )
    ) %>%
    add_option(
      "--package_name", type = "character",
      help = paste(
        "The name of the R package under analysis"
      )
    ) %>%
    add_option(
      c("--output", "-o"), type = "character",
      help = paste(
        "The output .tsv file. This will contain the gitsum values for the",
        "repo studied here."
      )
    )
}

###############################################################################

get_gitsum_results <- function(path, .package) {
  gitsum::init_gitsum(path, over_write = TRUE)

  gitsum::parse_log_detailed(path) %>%
    gitsum::unnest_log() %>%
    gitsum::set_changed_file_to_latest_name() %>%
    dplyr::filter(stringr::str_starts(changed_file, "R/")) %>%
    tibble::add_column(package = .package, .before = 1)
}

###############################################################################

main <- function(local_repo, package, results_file) {
  gitsum_results <- get_gitsum_results(local_repo, package)

  readr::write_tsv(gitsum_results, results_file)
}

###############################################################################

# script

###############################################################################

opt <- optparse::parse_args(define_parser())

main(
  local_repo = opt$local_repo,
  package = opt$package_name,
  results_file = here(opt$output)
)

###############################################################################
