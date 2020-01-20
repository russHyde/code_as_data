###############################################################################

# pkgs require for running the script (not the packages that are analysed here)
general_pkgs <- c("here", "magrittr", "optparse", "yaml")
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
      c("--config"), type = "character",
      help = paste(
        "A .yaml file containing the configuration details for the workflow.",
        "The .yaml should contain fields for the keys:",
        "- 'repo_details_file' (package,remote_repo,local_repo);",
        "- 'pkg_results_dir' (the parent of the directory that contains",
        "package-specific {dupree}-results that are to be combined);",
        "- 'all_pkg_benchmarks_file' (the single output file for this script)"
      )
    )
}

###############################################################################

define_pkg_timings_paths <- function(packages, pkg_results_dir) {
  tibble(
    package = packages,
    path = file.path(pkg_results_dir, package, "dupree_timings.rds")
  )
}

###############################################################################

format_benchmark <- function(table) {
  list_cols <- which(purrr::map_lgl(table, is.list))
  table[, list_cols] <- NA
  tibble::as_tibble(table)
}

collapse_benchmarks <- function(tables) {
  # should be a named list of bench::press result tables
  stopifnot(is.list(tables) && !is.null(names(tables)))
  purrr::map_df(tables, format_benchmark, .id = "package")
}

###############################################################################

# --

main <- function(
    repo_details_file, pkg_results_dir, output_file
) {
  repo_details <- read_repo_details(repo_details_file)

  # For each repo, there is a .rds file containing bench::press results
  #
  # Combine these results into a single table

  pkg_timings_paths <- define_pkg_timings_paths(
    repo_details[["package"]], pkg_results_dir
  )

  bench_results <- Map(
    function(pkg, path) read_rds(path),
    pkg_timings_paths[["package"]],
    pkg_timings_paths[["path"]]
  )

  # Combine the benchmark data for each package into a single table
  # - we suppress the `Vectorizing 'bench_time' ...` warnings
  summarised_results <- suppressWarnings(
    collapse_benchmarks(bench_results)
  )

  readr::write_tsv(summarised_results, output_file)
}

###############################################################################

source(here("scripts", "utils.R"))

opt <- optparse::parse_args(define_parser())
config <- yaml::read_yaml(opt$config)

main(
  repo_details_file = here(config[["repo_details_file"]]),
  pkg_results_dir = here(config[["pkg_results_dir"]]),
  output_file = here(config[["all_pkg_benchmarks_file"]])
)

#
# ggplot(df, aes(x = median, y = factor(package, levels =
#   unique(package[order(median)])))) + geom_point(aes(col = min_block_size))

###############################################################################
