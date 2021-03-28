library(glue)

footer <- function() {
  gh <- "https://github.com"

  gh_links <- list(
    cod = tags$a(href = glue("{gh}/russHyde/code_as_data"), "code_as_data"),
    cloc = tags$a(href = glue("{gh}/hrbrmstr/cloc"), "cloc"),
    me = tags$a(href = glue("{gh}/russHyde"), "Russ Hyde"),
    shiny = tags$a(href = glue("{gh}/rstudio/shiny"), "Shiny")
  )

  withTags(
    nav(
      # TODO: fix theme - the footer background should be dark but isn't
      class = "navbar fixed-bottom navbar-expand-lg navbar-dark bg-dark",
      span(
        class = "navbar-text",
        style = "float:right",
        p("Made by ", gh_links$me, " using ", gh_links$shiny),
        p("Code at github: ", gh_links$cod),
        p("Analysis packages: ", gh_links$cloc)
      )
    )
  )
}
