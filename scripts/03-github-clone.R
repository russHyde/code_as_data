###############################################################################

# pkgs required for running the script
general_pkgs <- c("here", "magrittr", "optparse")
pkgs <- c(general_pkgs, "git2r")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Clones an R packages from a (github) remote to a local location.",
    "(Admittedly this is trivial)"
  )

  parser <- OptionParser(
    description = description
  ) %>%
    add_option(
      "--remote_repo", type = "character",
      help = paste(
        "The URL for a github repository that is to be cloned"
      )
    ) %>%
    add_option(
      "--local_repo", type = "character",
      help = paste(
        "The filepath for the directory where the cloned repository should be",
        "placed"
      )
    )
}

###############################################################################

main <- function(
  remote_repo, local_repo
) {
  # Takes a remote URL and a local filepath, then clones the (presumed github
  # URL) from the remote_repo location to the local_repo directory

  if (!dir.exists(local_repo)) {
    git2r::clone(remote_repo, local_repo)
  }
}

###############################################################################

opt <- optparse::parse_args(define_parser())

main(
  remote_repo = opt$remote_repo,
  local_repo = here(opt$local_repo)
)

###############################################################################
