###############################################################################

# pkgs required for running the script
general_pkgs <- c("here", "magrittr", "optparse", "yaml")
pkgs <- c(general_pkgs, "dplyr", "git2r", "purrr", "readr")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Download lots of R packages from a remote to a local location.",
    "For each package mentioned in a file, this downloads the github repo",
    "from a remote to a local location."
  )

  parser <- OptionParser(
    description = description
  ) %>%
    add_option(
      c("--config"), type = "character",
      help = paste(
        "A .yaml file containing the configuration details for the workflow.",
        "The .yaml should contain fields for the keys:",
        "- 'repo_details_file' (package,remote_repo,local_repo)."
      )
    )
}

###############################################################################

clone_repositories <- function(x) {
  # Clone each package from its remote to its local repo (but only if we
  # haven't already cloned it)
  purrr::walk2(
    x$remote_repo, x$local_repo, git2r::clone
  )
}

###############################################################################

main <- function(repo_details_file) {
  # Takes a table of CRAN packages of the form (package-name, remote-repo,
  # local-repo) and clones each package from it's remote location to the
  # specified local location.

  repo_details <- read_repo_details(repo_details_file)

  # Columns of `repo_details`:
  # (package, remote_repo, local_repo)
  stopifnot(
    all(c("package", "remote_repo", "local_repo") %in% colnames(repo_details))
  )

  repo_details %>%
    dplyr::filter(!dir.exists(local_repo)) %>%
    clone_repositories()
}

###############################################################################

source(here("scripts", "utils.R"))

opt <- optparse::parse_args(define_parser())
config <- yaml::read_yaml(opt$config)

main(
  repo_details_file = here(config[["repo_details_file"]])
)

###############################################################################
