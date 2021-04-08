library(dplyr)
library(forcats)
library(ggplot2)
library(magrittr)
library(purrr)

singlePackageReportUI <- function(id, pkgs) {
  tagList(
    sidebarLayout(
      sidebarPanel(
        selectInput(NS(id, "chosen_pkg"), "Choose a package", choices = pkgs)
      ),
      mainPanel(
        plotOutput(NS(id, "file_change_plot"))
      )
    )
  )
}

singlePackageReportServer <- function(id, raw_data) {
  moduleServer(id, function(input, output, session) {
    pkg_data <- reactive(
      purrr::map(raw_data, dplyr::filter, package == input$chosen_pkg)
    )

    output$file_change_plot <- renderPlot(
      pkg_data()[["gitsum"]] %>%
        plot_file_commits_by_author()
    )
  })
}

#' Make a barchart of the number of commits that have been made to each file
#' in a package. Separate the contributions of different authors by colour.
#'
#' @param   commits   A dataframe. Must contain columns "author_name" and
#' "filename". Each row in the dataframe represents a single file that was
#' changed in a given commit. So any given commit may have multiple rows (if
#' multiple files were changed), and any given file may have multiple rows (if
#' changed in multiple commits).
#' @param   n_authors   Positive integer. At most this many distinct authors
#' will be represented in the figure. All other authors will be collapsed into
#' "other".
#'
#' @return   A ggplot object

plot_file_commits_by_author <- function(commits, n_authors = 7) {
  commits %>%
    ggplot(
      aes(
        x = forcats::fct_infreq(filename),
        fill = forcats::fct_lump(forcats::fct_infreq(author_name), n = n_authors)
      )
    ) +
    geom_bar() +
    xlab("Filename") +
    ylab("Number of Commits") +
    scale_x_discrete(breaks = NULL) +
    scale_fill_discrete(name = "Author")
}