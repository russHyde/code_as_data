library(shiny)

library(dplyr)
library(forcats)
library(ggplot2)
library(magrittr)

# Constants

dirs <- list(
  app_data = file.path("app-data")
)

files <- list(
  cloc = file.path(dirs[["app_data"]], "dev-pkg-cloc.tsv"),
  gitsum = file.path(dirs[["app_data"]], "dev-pkg-gitsum.tsv")
)

# User selects which statistics to plot / present based on the plain-text in
# this vector
pkg_statistics <- c(
  "Lines of Code" = "loc",
  "Number of Commits" = "n_commits",
  "Number of Contributors" = "n_contributors"
)

# Axis labels in plots are taken from this vector, so the axis label is
# "Lines of Code" rather than "loc", for example
ggplot_labels <- setNames(names(pkg_statistics), pkg_statistics)

raw_data <- import_pipeline_results(
  cloc_file = files[["cloc"]],
  gitsum_file = files[["gitsum"]]
)

# App

ui <- navbarPage(
  "Code as Data",
  tabPanel("Introduction", intro_ui()),
  tabPanel("Cross-package Analysis", crossPackageReportUI("crossPkg", pkg_statistics)),
  # TODO: tabPanel("Single-package Analysis"),
  tabPanel("Analysed Packages", analysedPackagesUI("pkgs")),
  footer()
)

server <- function(input, output, session) {
  crossPackageReportServer("crossPkg", raw_data, labeller = ggplot_labels)
  analysedPackagesServer("pkgs", raw_data$cloc)
}

shinyApp(ui, server)
