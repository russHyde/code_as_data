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

# Module

crossPackageReportUI <- function(id, pkg_statistics) {
  tagList(
    dataTableOutput(NS(id, "pkg_summary_table")),
    sidebarLayout(
      sidebarPanel(
        selectInput(
          NS(id, "chosen_stat"),
          "Choose a statistic to display",
          choices = pkg_statistics
        )
      ),
      mainPanel(
        plotOutput(NS(id, "pkg_summary_barplot"))
      )
    ),
    plotOutput(NS(id, "pkg_loc_vs_commits"))
  )
}

crossPackageReportServer <- function(id, raw_data, labeller) {
  moduleServer(id, function(input, output, session) {
    data_by_package <- reactive(
      summarise_by_package(raw_data[["cloc"]], raw_data[["gitsum"]])
    )

    output$pkg_summary_table <- renderDataTable(
      data_by_package(),
      options = list(pageLength = 5)
    )

    output$pkg_summary_barplot <- renderPlot(
      data_by_package() %>%
        barplot_by_package(input$chosen_stat, labeller)
    )

    output$pkg_loc_vs_commits <- renderPlot(
      data_by_package() %>%
        scatter_by_package("loc", "n_commits", labeller)
    )
  })
}