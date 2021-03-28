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

# Helper functions

import_pipeline_results <- function() {
  cloc <- readr::read_tsv(file.path(dirs[["app_data"]], "dev-pkg-cloc.tsv"))

  list(
    cloc = cloc
  )
}

summarise_cloc <- function(df) {
  # collapses the raw cloc dataset (which has one row per file) by package name
  # taking the total of the lines of code
  df %>%
    group_by(package) %>%
    summarise_if(is.numeric, sum)
}

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
  tableOutput("cloc_summary_table"),
  plotOutput("cloc_summary_barplot"),
  footer()
)

server <- function(input, output, session) {
  data <- reactive(import_pipeline_results())
  cloc_summary_table <- reactive(summarise_cloc(data()[["cloc"]]))

  output$cloc_summary_table <- renderTable(
    cloc_summary_table() %>%
      head(n = 10)
  )

  output$cloc_summary_barplot <- renderPlot(
    cloc_summary_table() %>%
      cloc_barplot()
  )
}

shinyApp(ui, server)