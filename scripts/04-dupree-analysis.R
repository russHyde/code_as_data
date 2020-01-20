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
      c("--config"), type = "character",
      help = paste(
        "A .yaml file containing the configuration details for the workflow.",
        "The .yaml should contain fields for the keys:",
        "- 'repo_details_file' (package,remote_repo,local_repo);",
        "- 'pkg_results_dir' (the parent of the directory where",
        "package-specific {dupree}-results should be placed);",
        "- 'min_block_sizes' (an array of the different choices for this",
        "dupree_package option)."
      )
    )
}

###############################################################################

run_benchmark_workflow <- function(local_repo, results_file, min_block_sizes) {
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
  results <- bench::press(
    min_block_size = min_block_sizes, {
      bench::mark(
        min_iterations = 5,
        dups = dupree::dupree_package(
          local_repo, min_block_size = min_block_size
        )
      )
    }
  )
  readr::write_rds(results, results_file)
}

run_dupree_workflow <- function(local_repo, results_file, min_block_size) {
  dups <- dupree::dupree_package(local_repo, min_block_size)
  readr::write_tsv(dups, results_file)
}

# --

run_workflow <- function(package, local_repo, results_dir, min_block_sizes) {
  message("Running dupree workflow for: ", package)

  pkg_results_dir <- file.path(results_dir, package)
  if (! dir.exists(pkg_results_dir)) {
    dir.create(pkg_results_dir)
  }

  # -- obtain / save the duplicated code-block results
  #
  # This fails if no top-level ./R/ directory is found
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
    run_benchmark_workflow(local_repo, bench_results_file, min_block_sizes)
  }
}

# --

main <- function(repo_details_file, results_dir, min_block_sizes) {

  stopifnot(is.numeric(min_block_sizes))

  repo_details <- read_repo_details(repo_details_file)

  # For each repo,
  # For each min_block_size in some set
  # - Run dupree
  # - Save the results table to a file
  #     - <results_dir>/<package_name>/dupree_table.b<block_size>.tsv
  # - Measure the time it takes to run & save (package, min_block_size,
  # time_taken) to a file
  #     - <results_dir>/<package_name>/dupree_timings.tsv
  # - Suggest saving the timings in bench::mark results format

  for (i in seq_len(nrow(repo_details))) {
    run_workflow(
      repo_details$package[i],
      normalizePath(repo_details$local_repo[i]),
      results_dir,
      min_block_sizes
    )
  }
}

###############################################################################

source(here("scripts", "utils.R"))

opt <- optparse::parse_args(define_parser())
config <- yaml::read_yaml(opt$config)

main(
  repo_details_file = here(config[["repo_details_file"]]),
  results_dir = here(config[["pkg_results_dir"]]),
  min_block_sizes = config[["min_block_sizes"]]
)

###############################################################################
