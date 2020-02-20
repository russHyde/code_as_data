#!/usr/bin/env Rscript

###############################################################################

# pkgs required for running the script
general_pkgs <- c("here", "magrittr", "optparse", "yaml")
pkgs <- c(general_pkgs, "bench", "dplyr", "dupree", "git2r", "readr", "tibble")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Runs `dupree::dupree_package` over each repo in a list of packages. The",
    "repos should be available locally."
  )

  parser <- OptionParser(
    description = description
  ) %>%
    add_option(
      "--config", type = "character",
      help = paste(
        "A .yaml file containing the configuration details for the workflow.",
        "The .yaml should contain fields for the keys:",
        "- 'min_block_sizes' (an array of the different choices for this",
        "dupree_package option)."
      )
    ) %>%
    add_option(
      "--local_repo", type = "character",
      help = paste(
        "The filepath for a local-copy of a github repo. dupree_package will",
        "be ran on the package contained therein."
      )
    ) %>%
    add_option(
      "--package_name", type = "character",
      help = paste(
        "The name of the package that is under analysis."
      )
    ) %>%
    add_option(
      "--output_dir", type = "character",
      help = paste(
        "The directory into which the package-specific dupree-results should",
        "be saved."
      )
    )
}

###############################################################################

run_benchmarks <- function(local_repo, min_block_sizes) {
  #  TODO: fix this error in the benchmark calls
  #   - it appears to be due to calling `write_tsv` on a benchmark tibble
  # --
  # Running dupree workflow for: aoos
  # Running with:
  #   min_block_size
  # 1            100
  # 2             40
  # Error in stream_delim_(df, path, ..., bom = bom, quote_escape =
  # quote_escape) :
  # Don't know how to handle vector of type list.
  # Calls: main ... <Anonymous> -> write_delim -> stream_delim ->
  # stream_delim_
  # In addition: There were 50 or more warnings (use warnings() to see the
  # first 50)
  # Execution halted
  # --

  # Time the running of dupree over a package and save the timings to an .RDS
  # file
  bench::press(
    min_block_size = min_block_sizes, {
      bench::mark(
        min_iterations = 5,
        dups = dupree::dupree_package(
          local_repo, min_block_size = min_block_size
        )
      )
    }
  )
}

run_dupree_workflow <- function(local_repo, results_file, min_block_size) {
  dups <- dupree::dupree_package(local_repo, min_block_size)
  readr::write_tsv(dups, results_file)
}

# --

run_workflow <- function(
    local_repo, .package, pkg_results_dir, min_block_sizes
) {
  message("Running dupree workflow for: ", local_repo)

  stopifnot(dir.exists(pkg_results_dir))
  stopifnot(dir.exists(local_repo))
  stopifnot(is.numeric(min_block_sizes))

  # -- obtain / save the duplicated code-block results
  #
  # This fails if no top-level R-package structure is found
  #
  for (bs in min_block_sizes) {
    results_file <- file.path(
      pkg_results_dir, paste0("dupree_table.b", bs, ".tsv")
    )
    if (! file.exists(results_file)) {
      run_dupree_workflow(local_repo, results_file, bs)
    }
  }

  # -- obtain timings for creating the duplicated code-block results
  bench_results_file <- file.path(
    pkg_results_dir, "dupree_timings.rds"
  )
  if (! file.exists(bench_results_file)) {
    benchmarks <- run_benchmarks(
      local_repo = local_repo,
      min_block_sizes = min_block_sizes
    ) %>%
      tibble::add_column(package = .package, .before = 1)

    readr::write_rds(benchmarks, bench_results_file)
  }
}

# --

main <- function(local_repo, package, output_dir, min_block_sizes) {

  # For a given repo,
  # For each min_block_size in some set
  # - Run dupree
  # - Save the results table to a file
  #     - <results_dir>/<package_name>/dupree_table.b<block_size>.tsv
  # - Measure the time it takes to run & save (package, min_block_size,
  # time_taken) to a file
  #     - <results_dir>/<package_name>/dupree_timings.tsv
  # - Save the timings in bench::mark results format

  run_workflow(
    local_repo, package, output_dir, min_block_sizes
  )
}

###############################################################################

opt <- optparse::parse_args(define_parser())

config <- yaml::read_yaml(opt$config)

main(
  local_repo = here(opt$local_repo),
  package = opt$package_name,
  output_dir = opt$output_dir,
  min_block_sizes = config[["min_block_sizes"]]
)

###############################################################################
