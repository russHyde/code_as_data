# Install any remote dependencies that are required by R, and which are not
# available on conda

###############################################################################

main <- function(remotes) {
  for (package in remotes) {
    devtools::install_github(package, dependencies = FALSE)
  }
}

###############################################################################

library("here")
library("devtools")

source(here("R", "config.R"))

main(
  remotes = config[["remotes"]]
)

###############################################################################
