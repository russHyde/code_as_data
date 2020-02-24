#!/usr/bin/env Rscript

###############################################################################

# pkgs require for running the script (not the packages that are analysed here)
general_pkgs <- c("here", "magrittr", "optparse")
pkgs <- c(general_pkgs, "bench", "dplyr", "purrr", "readr", "tibble")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Combine the results from multiple `bench::press` runs into a single",
    "data.frame.",
    "The files to collapse can either be specified in a file (--input_files)",
    "or as the trailing arguments to this script."
  )

  parser <- OptionParser(
    usage = "usage: Rscript %prog [options] (file1 file2 file3 ...)",
    description = description
  ) %>%
    add_option(
      "--input_files", type = "character",
      help = paste(
        "(optional) The set of input files. The file-paths to the data that",
        "should be combined should all be defined in a single one-column",
        "file.",
        "Each file should be an .rds with data produced by bench::press and",
        "much contain a `package` column."
      )
    ) %>%
    add_option(
      c("--output", "-o"), type = "character",
      help = paste(
        "The output file. A .tsv for storing the dupree-benchmark results",
        "for all the analysed packages."
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

format_benchmarks <- function(table) {
  # Any columns that contain lists are disregarded (for simplicity)
  list_cols <- which(purrr::map_lgl(table, is.list))
  table[, list_cols] <- NA
  tibble::as_tibble(table)
}

import_benchmarks <- function(path) {
  table <- readr::read_rds(path)

  stopifnot("package" %in% colnames(table))

  format_benchmarks(table)
}

###############################################################################

# --

main <- function(
    opt
) {
  # For each repo, there is a .rds file containing bench::press results.
  # Combine these results into a single table

  results_file <- here::here(opt$options$output)

  # Obtain the paths to the dupree-timings .rds files
  collapsible_files <- define_collapsible_files(opt)

  bench_results <- Map(import_benchmarks, collapsible_files)

  # Combine the benchmark data for each package into a single table
  # - we suppress the `Vectorizing 'bench_time' ...` warnings
  summarised_results <- suppressWarnings(
    dplyr::bind_rows(bench_results)
  )

  readr::write_tsv(summarised_results, results_file)
}

###############################################################################

main(
  opt = optparse::parse_args(define_parser(), positional_arguments = TRUE)
)

#
# ggplot(df, aes(x = median, y = factor(package, levels =
#   unique(package[order(median)])))) + geom_point(aes(col = min_block_size))

###############################################################################
