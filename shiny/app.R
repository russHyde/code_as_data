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

# TODO: fix the y-axis label of the barplot to use the label in this vector
pkg_statistics <- c(
  "Lines of Code" = "loc",
  "Number of Commits" = "n_commits",
  "Number of Contributors" = "n_contributors"
)

# Helper functions

#' Takes the package-summarised dataset and produces a barplot, with packages
#' ordered by a user-selected statistic (lines of code, number of commits
#' etc)
#' @param df   The data-frame. This should contain columns (package, n_commits,
#' n_contributors, loc, ...)
#' @param column   String. Which of the columns within the dataframe should a
#'   barplot be made for?
barplot_by_package <- function(df, column) {
  df %>%
    mutate(
      package = forcats::fct_reorder(package, .data[[column]], .desc = TRUE)
    ) %>%
    ggplot(aes(x = package, y = .data[[column]])) +
    geom_bar(stat = "identity") +
    guides(x = guide_axis(angle = 90))
}

# App

ui <- fluidPage(
  titlePanel("Code as data"),
  dataTableOutput("package_summary_table"),
  fluidRow(
    column(
      3,
      selectInput(
        "chosen_stat",
        "Choose a statistic to display",
        choices = pkg_statistics)
    ),
    column(9, plotOutput("pkg_summary_barplot"))
  ),
  footer()
)

server <- function(input, output, session) {
  data <- reactive(
    import_pipeline_results(
      cloc_file = files[["cloc"]],
      gitsum_file = files[["gitsum"]]
    )
  )

  data_by_package <- reactive(
    summarise_by_package(
      data()[["cloc"]], data()[["gitsum"]]
    )
  )

  output$package_summary_table <- renderDataTable(
    data_by_package(),
    options = list(pageLength = 5)
  )

  output$pkg_summary_barplot <- renderPlot(
    data_by_package() %>%
      barplot_by_package(input$chosen_stat)
  )
}

shinyApp(ui, server)
