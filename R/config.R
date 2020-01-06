###############################################################################

# Config details for the analysis of development tools packages using {dupree}
# - filepaths etc

###############################################################################

config <- list(
  # Store results summaries here:
  results_dir = here("results"),

  # Store results for individual packages in subdirs of this:
  pkg_results_dir = here("results", "packages"),

  repo_dir = normalizePath(
    file.path("~", "temp", "dev-tools-analysis"),
    mustWork = FALSE
  ),

  task_view_url = paste(
    "https://raw.githubusercontent.com/ropensci",
    "PackageDevelopment/master/PackageDevelopment.ctv",
    sep = "/"
  ),

  min_block_sizes = c(100, 40), #, 20, 10)

  # {logging} The github repo for package `logging` does not conform to
  # standard R package structure, and causes dupree to fail.
  #
  # {R.oo} The ./R/ directory of R.oo contains a filename with a comma in it
  # "020.makeObjectFinalizer,private.R". This causes {cloc}::cloc_by_file to
  # fail (because the cloc-results are read in as .csv format)
  drop = c(
    "logging", "R.oo"
  ),

  # which packages should be installed from github?
  # - any dependencies for these packages should already be installed to the
  # conda environment
  remotes = c(
    "hrbrmstr/cloc", "lorenzwalthert/gitsum"
  )
)

config <- append(
  config,
  list(
    # The next three files only store data for the repositories that we are
    # going to analyse here
    repo_details_file = file.path(
      config[["results_dir"]], "dev-pkg-repositories.tsv"
    ),
    cran_details_file = file.path(
      config[["results_dir"]], "dev-pkg-table.tsv"
    ),
    all_pkg_benchmarks_file = file.path(
      config[["results_dir"]], "dev-pkg-benchmarks.tsv"
    ),
    all_pkg_cloc_file = file.path(
      config[["results_dir"]], "dev-pkg-cloc.tsv"
    )
  )
)

###############################################################################
