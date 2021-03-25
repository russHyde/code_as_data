library(shiny)

library(dplyr)
library(magrittr)
library(readr)

# Constants

dirs <- list(
  app_data = file.path("app-data")
)

# Helper functions

import_pipeline_results <- function() {
  cloc <- readr::read_tsv(file.path(dirs[["app_data"]], "dev-pkg-cloc.tsv"))

  list(
    cloc = cloc
  )
}

summarise_cloc <- function(df) {
  df %>%
    group_by(package) %>%
    summarise_if(is.numeric, sum)
}

# App

ui <- fluidPage(
  titlePanel("Code as data"),
  tableOutput("cloc_summary_table")
)

server <- function(input, output, session) {
  data <- reactive(import_pipeline_results())
  cloc_table <- reactive(data()[["cloc"]])

  output$cloc_summary_table <- renderTable(
    cloc_table() %>%
      summarise_cloc() %>%
      head(n = 10)
  )
}

shinyApp(ui, server)