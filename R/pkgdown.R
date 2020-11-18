#' Replacement version of [pkgdown::build_site()] with muggle defaults
#' 
#' @inherit pkgdown::build_site
#' @inheritDotParams pkgdown::build_site
#' @family pkgdown functions
#' @export
build_site2 <- function(...) {
  local_siteyaml()
  pkgdown::build_site()
}

#' Replacement version of [pkgdown::build_article()] with muggle defaults
#' 
#' @inherit pkgdown::build_article
#' @inheritDotParams pkgdown::build_article
#' @family pkgdown functions
#' @export
build_articles2 <- function(...) {
  local_siteyaml()
  pkgdown::build_articles(...)
}

#' @rdname build_articles2
build_article2 <- function(...) {
  local_siteyaml()
  pkgdown::build_article(...)
}

#' Temporarily create muggle default `vignettes/_site.yml` file
#' 
#' Upgrades vignettes to muggle default.
#' Wraps [local_muggle_file()] to delete file upon use.
#' 
#' @details
#' This `vignettes/_site.yml` declares the default vignette rendering function for muggle vignettes.
#' To enable it, you also must declare in the yaml frontmatter *for each of the vignettes*:
#' 
#' ```yaml
#' pkgdown:
#'  as_is: true
#' ```
#' 
#' For an example of such a vignette with all its features, see `vignette("vignette-muggle")`
#' 
#' @section Features:
#' ## Backported Bookdown Features
#' By default, pkgdown builds vignettes (or rather, articles) using a special format based on [rmarkdown::html_document()].
#' This format does not include the automatic numbering and crossreferencing of figures, tables, equations, and (for cross-references) sections supported by [bookdown](http://bookdown.org).
#' The [`bookdown::html_document2()`](https://bookdown.org/yihui/bookdown/a-single-document.html) render function backports these features for uses outside of bookdown.
#' 
#' ## Raw HTML
#' Pandoc extensions are set to allow correctly indented raw HTML inside vignettes.
#' 
#' @inheritParams local_muggle_file
#' @family pkgdown functions
#' @export
local_siteyaml <- function(.local_envir = parent.frame()) {
  local_muggle_file("vignettes/_site.yml", .local_envir = .local_envir)
}
