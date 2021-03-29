# TODO: href links for the packages

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
      df %>%
        dplyr::select(package) %>%
        unique()
    )
  })
}