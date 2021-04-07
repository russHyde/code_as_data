library(glue)

intro_ui <- function() {
  overview <- withTags(div(
    h2("Overview"),
    p("
      The source code, community and commit history for a range of R packages
      was analysed.
    ")
  ))
  packages <- withTags(div(
    h2("Packages"),
    p(
      "
      The list of packages was obtained from the ",
      a(
        href = "https://github.com/ropensci/PackageDevelopment/",
        "ROpenSci/PackageDevelopment"
      ),
      r"( task view. Those packages were filtered: keeping only those that are
      currently on CRAN and github, and for which the repository has a typical
      `[base]/R/*.R` package structure. The final list of packages can be found
      in the "Analysed Packages" subsection of this app.
      )"
    )
  ))
  analyses <- withTags(div(
    h2("Analyses"),
    p("
      The packages were analysed using gitsum (to count commits and identify
      contributors), dupree (to analyse duplicate code) and cloc (to count the
      lines-of-code in the package). Only files in the `./R/` subdirectory of
      each package were analysed.
    ")
  ))
  withTags(div(
    overview,
    packages,
    analyses
  ))
}

footer <- function() {
  gh <- "https://github.com" # nolint

  gh_links <- list(
    cod = tags$a(href = glue("{gh}/russHyde/code_as_data"), "code_as_data"),
    cloc = tags$a(href = glue("{gh}/hrbrmstr/cloc"), "cloc"),
    gitsum = tags$a(href = glue("{gh}/lorenzwalthert/gitsum"), "gitsum"),
    me = tags$a(href = glue("{gh}/russHyde"), "Russ Hyde"),
    shiny = tags$a(href = glue("{gh}/rstudio/shiny"), "Shiny")
  )

  withTags(
    footer(
      class = "navbar navbar-expand-lg navbar-dark bg-dark",
      span(
        class = "navbar-text",
        style = "float:right",
        p("Made by ", gh_links$me, " using ", gh_links$shiny),
        p("Code at github: ", gh_links$cod),
        p("Analysis packages: ", gh_links$cloc, ", ", gh_links$gitsum)
      )
    )
  )
}
