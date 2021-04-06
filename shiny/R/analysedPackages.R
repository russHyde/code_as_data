library(glue)
library(dplyr)

analysedPackagesUI <- function(id) {
  tagList(
    dataTableOutput(NS(id, "analysed_packages"))
  )
}

analysedPackagesServer <- function(id, df) {
  # `df` is one of the fixed raw data tables that contains info for each of the
  # analysed packages
  stopifnot(!is.reactive(df))

  moduleServer(id, function(input, output, session) {
    output$analysed_packages <- renderDataTable(
      format_analysed_packages_table(df),
      escape = FALSE
    )
  })
}

format_analysed_packages_table <- function(df) {
  df %>%
    dplyr::select(package, remote_repo) %>%
    dplyr::mutate(remote_repo = convert_urls_to_html(remote_repo)) %>%
    unique()
}
convert_urls_to_html <- function(urls) {
  glue::glue(
    "<a href='{urls}'>{urls}</a>"
  )
}