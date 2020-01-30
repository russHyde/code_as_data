###############################################################################

# pkgs require for running the script
general_pkgs <- c("here", "magrittr", "optparse")
pkgs <-  c(general_pkgs, "readr", "purrr")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Collapse a set of homogeneous-structured .tsv files into a single .tsv."
  )

  parser <- OptionParser(
    description = description
  ) %>%
    add_option(
      c("--input_files"), type = "character",
      help = paste(
        "A single file, containing the filepaths for all files that should be",
        "collapsed together by this script."
      )
    ) %>%
    add_option(
      c("--output", "-o"), type = "character",
      help = paste(
        "The output .tsv file. This will contain all data from the input files."
      )
    )
}

###############################################################################

define_files <- function(input_pattern, packages, parent_dir) {
  file.path(parent_dir, packages, input_pattern)
}

import_and_collapse <- function(files) {
  stopifnot(length(files) > 0)
  stopifnot(all(file.exists(files)))
  files %>%
    purrr::map_df(readr::read_tsv, col_types = readr::cols())
}

###############################################################################

main <- function(
    input_files, results_file
) {
  # `input_files` is a file that _contains_ a set of filenames, it is the set
  # of filenames that are to be collapsed here.
  files <- here::here(scan(input_files, what = "character"))

  collapsed_data <- import_and_collapse(files)

  readr::write_tsv(collapsed_data, results_file)
}

###############################################################################

# script

###############################################################################

opt <- optparse::parse_args(define_parser())

main(
  input_files = here(opt$input_files),
  results_file = here(opt$output)
)

###############################################################################
