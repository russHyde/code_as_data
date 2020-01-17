###############################################################################

# pkgs required for running the script
general_pkgs <- c("here", "magrittr", "optparse", "yaml")
pkgs <- c(general_pkgs, "devtools")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

define_parser <- function() {
  description <- paste(
    "Install any remote dependencies that are required by R, and which are",
    "not available through conda."
  )

  parser <- OptionParser(
    description = description
  ) %>%
    add_option(
      c("--config"), type = "character",
      help = paste(
        "A .yaml file containing the configuration details for the workflow.",
        "Any 'userName/repo' repository in it's `remotes` field will be",
        "installed."
      )
    )
}

###############################################################################

main <- function(remotes) {
  for (package in remotes) {
    devtools::install_github(package, dependencies = FALSE)
  }
}

###############################################################################

opt <- optparse::parse_args(define_parser())
config <- yaml::read_yaml(opt$config)

main(
  remotes = config[["remotes"]]
)

###############################################################################
