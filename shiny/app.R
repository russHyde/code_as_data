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

# Helper functions

#' Takes the package-summarised dataset and produces a barplot, with packages
#' ordered by a user-selected statistic (lines of code, number of commits
#' etc)
#' @param df   The data-frame. This should contain columns (package, n_commits,
#' n_contributors, loc, ...)
#' @param column   String. Which of the columns within the dataframe should a
#'   barplot be made for?
#' @param labeller   A named vector. The y-axis label for `column` is obtained
#'   from this vector, so the name of an entry should match the value of column.
#'   If NULL, the y-axis label is the value of `column`.
#'
barplot_by_package <- function(df, column, labeller = NULL) {
  if (is.null(labeller)) {
    labeller <- setNames(column, column)
  }
  df %>%
    mutate(
      package = forcats::fct_reorder(package, .data[[column]], .desc = TRUE)
    ) %>%
    ggplot(aes(x = package, y = .data[[column]])) +
    geom_bar(stat = "identity") +
    guides(x = guide_axis(angle = 90)) +
    labs(x = "Package", y = labeller[[column]])
}

scatter_by_package <- function(df, x, y, labeller = NULL) {
  if (is.null(labeller)) {
    labeller <- setNames(c(x, y), c(x, y))
  }
  df %>%
    ggplot(aes(x = .data[[x]], y = .data[[y]], label = package)) +
    geom_text() +
    scale_x_log10() +
    scale_y_log10() +
    labs(x = labeller[[x]], y = labeller[[y]])
}

# App

ui <- navbarPage(
  "Code as Data",
  tabPanel("Introduction", intro_ui()),
  tabPanel("Cross-package Analysis", cross_pkg_ui(pkg_statistics)),
  # TODO: tabPanel("Single-package Analysis"),
  tabPanel(
    "Analysed Packages", dataTableOutput("analysed_packages")
  ),
  footer()
)

server <- function(input, output, session) {
  # TODO: module for cross-package analysis
  data_by_package <- reactive(
    summarise_by_package(raw_data[["cloc"]], raw_data[["gitsum"]])
  )

  output$pkg_summary_table <- renderDataTable(
    data_by_package(),
    options = list(pageLength = 5)
  )

  output$pkg_summary_barplot <- renderPlot(
    data_by_package() %>%
      barplot_by_package(input$chosen_stat, ggplot_labels)
  )

  output$pkg_loc_vs_commits <- renderPlot(
    data_by_package() %>%
      scatter_by_package("loc", "n_commits", ggplot_labels)
  )

  # TODO: href links for the packages
  output$analysed_packages <- renderDataTable(
    raw_data[["cloc"]] %>%
      dplyr::select(package) %>%
      unique()
  )
}

shinyApp(ui, server)
