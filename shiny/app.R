library(shiny)

library(dplyr)
library(forcats)
library(ggplot2)
library(magrittr)
library(readr)

# Constants

dirs <- list(
  app_data = file.path("app-data")
)

files <- list(
  cloc = file.path(dirs[["app_data"]], "dev-pkg-cloc.tsv"),
  gitsum = file.path(dirs[["app_data"]], "dev-pkg-gitsum.tsv")
)

# Helper functions

cloc_barplot <- function(df) {
  # takes the package-summarised cloc dataset and produces a barplot, with
  # packages ordered by the total number of actual lines of code
  df %>%
    mutate(package = fct_reorder(package, loc, .desc = TRUE)) %>%
    ggplot(aes(x = package, y = loc)) +
    geom_bar(stat = "identity") +
    guides(x = guide_axis(angle = 90))
}

# App

ui <- fluidPage(
  titlePanel("Code as data"),
  dataTableOutput("package_summary_table"),
  plotOutput("cloc_summary_barplot"),
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

  output$cloc_summary_barplot <- renderPlot(
    data_by_package() %>%
      select(package, loc, blank_lines, comment_lines) %>%
      cloc_barplot()
  )
}

shinyApp(ui, server)
