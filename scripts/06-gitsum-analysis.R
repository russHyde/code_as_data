#!/usr/bin/env Rscript

###############################################################################

# pkgs require for running the script
general_pkgs <- c("here", "magrittr", "optparse")
pkgs <-  c(general_pkgs, "codeAsData")

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

main <- function(local_repo, package, results_file) {
  # This
  # - runs gitsum on a repo,
  # - imports the gitsum results,
  # - cleans them up (so there is only data for R/ files, and a single row per changed file per
  # commit); and
  # - exports the cleaned up data as a .tsv
  codeAsData::run_gitsum_workflow(
    repo_path = local_repo,
    output_path = results_file,
    package = package,
    r_dir_only = TRUE
  )
}

###############################################################################

# script

###############################################################################

opt <- optparse::parse_args(define_parser())

main(
  local_repo = opt$local_repo,
  package = opt$package_name,
  results_file = opt$output
)

###############################################################################
