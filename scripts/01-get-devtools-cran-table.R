###############################################################################

# pkgs required for running the script
general_pkgs <- c("here", "magrittr", "optparse", "yaml")
pkgs <- c(general_pkgs, "dplyr", "janitor", "tibble", "readr", "xml2")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Obtain a subset of the CRAN package table that has been restricted to",
    "only those packages mentioned in the package-development CRAN view",
    "hosted by rOpenSci."
  )

  parser <- OptionParser(
    description = description
  ) %>%
    add_option(
      c("--config"), type = "character",
      help = paste(
        "A .yaml file containing the configuration details for the workflow.",
        "The .yaml should contain fields for the keys:",
        "`drop` (which packages that are in both CRAN and the task-view",
        "should be disregarded?)."
      )
    ) %>%
    add_option(
      "--url", type = "character",
      help = paste(
        "A URL that defines a *.ctv file containing a CRAN task-view.",
        "The CRAN-database entry for any package that is mentioned in this",
        "task view will be included in the output file (unless that package)",
        "is present in the `drop` entry of the config."
      )
    ) %>%
    add_option(
      c("--output", "-o"), type = "character",
      help = paste(
        "A .tsv for storing the subset of the CRAN database that relates to",
        "the non-dropped packages present in the task-view .ctv file."
      )
    )
}

###############################################################################

contains_github <- function(x) {
  grepl("github\\.com", x)
}

format_cran_table <- function(x) {
  # NOTE: newlines were observed in some columns of the cran dataframe, these
  # make it difficult to save the dataframe to a .tsv and then reimport it.
  # I suspect this might be due to a bug in `readr::write_tsv`. To get around
  # it, we just convert all whitespace to single-spaces.

  remove_dup_cols <- function(df) df[, !duplicated(colnames(df))]
  collapse_ws <- function(x) gsub("[ \t\r\n]+", " ", x)

  # - Remove any columns that have duplicate names
  # - Convert column names to tidier versions of them (dots / whitespace to
  # underscores, snake_case)
  # - Strip repeated whitespace
  # - Convert all whitespace characters to single-space
  x %>%
    remove_dup_cols() %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate_if(is.character, collapse_ws)
}

import_github_cran_table <- function() {
  # code modified from https://juliasilge.com/blog/mining-cran-description/

  # Download a table containing all the DESCRIPTION fields for the packages on
  # CRAN
  # - then remove duplicated fields
  # - turn it into a tibble
  # - and filter to keep only packages that have a github repo

  # read
  raw_cran <- tools::CRAN_package_db()

  # format & restrict to github repos
  format_cran_table(raw_cran) %>%
    dplyr::filter(contains_github(url) | contains_github(bug_reports))
}

###############################################################################

extract_package_names <- function(xml) {
  # package names are each stored in a <pkg> tag on the task view page
  # and the list of <pkg> tags is stored in a <packagelist> tag

  # extract the package names
  xml %>%
    xml2::xml_find_all("packagelist/pkg") %>%
    xml2::xml_text()
}

import_dev_package_names <- function(url) {
  xml2::read_xml(url) %>%
    extract_package_names()
}

###############################################################################

main <- function(task_view_url, results_file, drop_pkgs = NULL) {
  # We identify packages that
  # - are currently on CRAN
  # - have a github URL
  # - are mentioned on the ROpenSci software development task view
  # - are not in a set of packages for dropping from the pipeline (drop_pkgs)

  stopifnot(dir.exists(dirname(results_file)))

  cran_gh <- import_github_cran_table()
  dev_packages <- import_dev_package_names(task_view_url)

  dev_pkg_table <- dplyr::filter(
    cran_gh,
    package %in% dev_packages & !package %in% drop_pkgs
  )

  readr::write_tsv(dev_pkg_table, results_file)
}

###############################################################################

opt <- optparse::parse_args(define_parser())
config <- yaml::read_yaml(opt$config)

main(
  task_view_url = opt$url,
  results_file = here(opt$output),
  drop_pkgs = config[["drop"]]
)

###############################################################################
