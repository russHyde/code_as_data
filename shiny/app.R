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

import_pipeline_results <- function(cloc_file, gitsum_file) {
  stopifnot(file.exists(cloc_file))
  stopifnot(file.exists(gitsum_file))

  cloc <- readr::read_tsv(cloc_file)

  gitsum <- readr::read_tsv(gitsum_file, col_types = readr::cols()) %>%
    # for consistency with cloc 'filename' column
    dplyr::rename(filename = changed_file)

  list(
    cloc = cloc,
    gitsum = gitsum
  )
}

summarise_cloc <- function(df) {
  # collapses the raw cloc dataset (which has one row per file) by package name
  # taking the total of the lines of code
  df %>%
    group_by(package) %>%
    summarise_if(is.numeric, sum)
}

summarise_gitsum <- function(df) {
  df %>%
    group_by(package) %>%
    summarise(
      n_commits = n_distinct(hash),
      n_contributors = n_distinct(author_email)
    )
}

summarise_by_package <- function(cloc_data, gitsum_data) {
  cloc <- summarise_cloc(cloc_data)
  gitsum <- summarise_gitsum(gitsum_data)

  dplyr::left_join(gitsum, cloc)
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

  output$cloc_summary_table <- renderTable(
    data_by_package() %>%
      select(package, loc, blank_lines, comment_lines) %>%
      head(n = 10)
  )

  output$cloc_summary_barplot <- renderPlot(
    data_by_package() %>%
      select(package, loc, blank_lines, comment_lines) %>%
      cloc_barplot()
  )
}

shinyApp(ui, server)
