#!/usr/bin/env Rscript

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
    "Collapse a set of homogeneous-structured .tsv files into a single .tsv.",
    "The files to collapse can either be specified in a file (--input_files)",
    "or as the trailing arguments to this script."
  )

  parser <- OptionParser(
    usage = "usage: Rscript %prog [options] (file1 file2 file3 ...)",
    description = description
  ) %>%
    add_option(
      c("--input_files"), type = "character",
      help = paste(
        "An (optional) single file, containing the filepaths for all files",
        "that should be collapsed together by this script. If missing there",
        "must be at least one filename trailing the command-line options."
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

define_collapsible_files <- function(opt) {
  # Script can be called:
  # 1) Rscript <script> --input_files <file1> --output <file2>
  # OR
  # Rscript <script> --output <file> [trailing_file_names]
  # For 1) file1 defines the filepaths for those files that are to be collapsed
  # For 2) the unnamed files in trailing position are to be collapsed

  options <- opt$options
  trailing <- opt$args

  raw_files <- if (!is.null(options[["input_files"]])) {
    # the files to collapse are all defined inside a single file
    scan(here::here(options[["input_files"]]), what = "character")
  } else {
    # all files in the unnamed, trailing arguments are to be collapsed
    trailing
  }

  here::here(raw_files)
}

###############################################################################

import_and_collapse <- function(files) {
  stopifnot(length(files) > 0)
  stopifnot(all(file.exists(files)))
  files %>%
    purrr::map_df(readr::read_tsv, col_types = readr::cols())
}

###############################################################################

main <- function(
    opt
) {
  results_file <- here::here(opt$options$output)

  collapsible_files <- define_collapsible_files(opt)

  collapsed_data <- import_and_collapse(collapsible_files)

  readr::write_tsv(collapsed_data, results_file)
}

###############################################################################

# script

###############################################################################

main(
  opt = optparse::parse_args(define_parser(), positional_arguments = TRUE)
)

###############################################################################
