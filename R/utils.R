###############################################################################

load_packages <- function(pkgs) {
  for (pkg in pkgs) {
    suppressPackageStartupMessages(
      library(pkg, character.only = TRUE)
    )
  }
}

read_repo_details <- function(repo_details_file) {
  readr::read_tsv(repo_details_file, col_types = "ccc")
}

###############################################################################
