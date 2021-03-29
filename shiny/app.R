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

# Helper functions

barplot_by_package <- function(df, column) {
  # takes the package-summarised dataset and produces a barplot, with packages
  # ordered by a user-selected statistic (lines of code, number of commits etc)
  df %>%
    mutate(package = forcats::fct_reorder(package, {{ column }}, .desc = TRUE)) %>%
    ggplot(aes(x = package, y = {{ column }})) +
    geom_bar(stat = "identity") +
    guides(x = guide_axis(angle = 90))
}

# App

ui <- fluidPage(
  titlePanel("Code as data"),
  dataTableOutput("package_summary_table"),
  plotOutput("pkg_summary_barplot"),
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

  # TODO: allow user to choose whether to make barplot of: loc, n_commits,
  # n_contributors etc
  output$pkg_summary_barplot <- renderPlot(
    data_by_package() %>%
      barplot_by_package(loc)
  )
}

shinyApp(ui, server)
