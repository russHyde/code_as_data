###############################################################################

# For a given package, we count the nummber of lines of R code using the `cloc`
# package and command-line tool

###############################################################################

# pkgs required for running the script
general_pkgs <- c("here", "magrittr", "optparse")
pkgs <-  c(general_pkgs, "cloc", "dplyr", "readr", "tibble")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Count the number of lines of code for each R-source file in a",
    "repository.",
    "This only considers files that are in the ./R/ subdirectory of an R",
    "package structure."
  )

  parser <- OptionParser(
    description = description
  ) %>%
    add_option(
      "--local_repo", type = "character",
      help = paste(
        "The path to the repository to analyse. Only the ./R subdirectory of",
        "this repository will be included."
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
        "The output .tsv file. This will contain the line-counts across the",
        "files in the ./R subdirectory of the package."
      )
    )
}

###############################################################################

get_cloc_details <- function(local_repo) {
  # We only analyse the contents of the ./R/ directory in the repo
  message("Running `cloc_by_file` on ", local_repo)
  cloc::cloc_by_file(
    file.path(local_repo, "R")
  )
}

format_cloc <- function(df, .package) {
  df %>%
    dplyr::filter(language == "R") %>%
    tibble::add_column(package = .package, .before = 1)
}

###############################################################################

main <- function(local_repo, package, results_file) {

  cloc_results <- get_cloc_details(local_repo) %>%
    format_cloc(package)

  readr::write_tsv(cloc_results, results_file)
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
