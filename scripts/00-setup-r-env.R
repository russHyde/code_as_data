# Install any remote dependencies that are required by R, and which are not
# available on conda

###############################################################################

pkgs <- c("here", "devtools", "yaml")

for (pkg in pkgs) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

###############################################################################

main <- function(remotes) {
  for (package in remotes) {
    devtools::install_github(package, dependencies = FALSE)
  }
}

###############################################################################

config <- yaml::read_yaml(here("conf", "config.yaml"))

main(
  remotes = config[["remotes"]]
)

###############################################################################
