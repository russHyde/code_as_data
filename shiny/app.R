library(shiny)
library(bslib)

# Constants

theme <- bslib::bs_theme(bootswatch = "sandstone")

dirs <- list(
  app_data = file.path("app-data")
)

files <- list(
  cloc = file.path(dirs[["app_data"]], "dev-pkg-cloc.tsv"),
  gitsum = file.path(dirs[["app_data"]], "dev-pkg-gitsum.tsv"),
  repositories = file.path(dirs[["app_data"]], "dev-pkg-repositories.tsv")
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

raw_data <- import_pipeline_results(files)

pkgs <- sort(unique(raw_data[[1]]$package))

# App

ui <- navbarPage(
  "Code as Data",
  tabPanel("Introduction", intro_ui()),
  tabPanel("Cross-package Analysis", crossPackageReportUI("crossPkg", pkg_statistics)),
  tabPanel("Single-package Analysis", singlePackageReportUI("singlePkg", pkgs)),
  tabPanel("Analysed Packages", analysedPackagesUI("pkgs")),
  footer = footer(),
  theme = theme
)

server <- function(input, output, session) {
  crossPackageReportServer("crossPkg", raw_data, labeller = ggplot_labels)
  singlePackageReportServer("singlePkg", raw_data)
  analysedPackagesServer("pkgs", raw_data$repositories)
}

shinyApp(ui, server)
