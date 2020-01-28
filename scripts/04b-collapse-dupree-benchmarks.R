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
    "data.frame."
  )

  parser <- OptionParser(
    description = description
  ) %>%
    add_option(
      "--input_files", type = "character",
      help = paste(
        "The set of input files. The file-paths to the data that should be",
        "combined should all be defined in a single one-column file.",
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
    input_files, output_file
) {
  # For each repo, there is a .rds file containing bench::press results
  #
  # Combine these results into a single table

  # Obtain the paths to the dupree-timings .rds files
  pkg_timings_paths <- here::here(scan(input_files, what = "character"))

  bench_results <- Map(import_benchmarks, pkg_timings_paths)

  # Combine the benchmark data for each package into a single table
  # - we suppress the `Vectorizing 'bench_time' ...` warnings
  summarised_results <- suppressWarnings(
    dplyr::bind_rows(bench_results)
  )

  readr::write_tsv(summarised_results, output_file)
}

###############################################################################

opt <- optparse::parse_args(define_parser())

main(
  input_files = here(opt$input_files),
  output_file = here(opt$output)
)

#
# ggplot(df, aes(x = median, y = factor(package, levels =
#   unique(package[order(median)])))) + geom_point(aes(col = min_block_size))

###############################################################################
