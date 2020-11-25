#' Replacement versions of [pkgdown::build_site()] etc. with muggle defaults
#' 
#' Sets some muggle defaults for pkgdown to minimize code duplication across muggle projects.
#' This includes overrides of `_pkgdown.yml` and `_site.yml`.
#' 
#' @section Additions to pkgdown:
#' These replacement versions of pkgdown functions make the following changes to pkgdown, as applicable:
#' - If there are `vignettes/`, declaring a default vignette rendering function ([local_siteyaml()])
#' - Overriding some values in `_pkgdown.yml` by appending [override_pkgdownyaml()]) to `override`.
#'    Be careful not to provide conflicting overrides.
#' - Sets `run_dont_run = TRUE`, so that examples inside `\dontrun{}` are still run inside of pkgdown.
#'   Examples often need to be skipped on CRAN and other checks, though not when building pkgdown.
#' 
#' @inheritSection pkgdown::build_site YAML config - navbar
#' @inheritParams pkgdown::build_site
#' @inheritDotParams pkgdown::build_site
#' @family pkgdown functions
#' @export
build_site2 <- function(run_dont_run = TRUE, override = list(), ...) {
  if (fs::dir_exists("vignettes")) local_siteyaml()
  pkgdown::build_site(
    run_dont_run = run_dont_run,
    override = c(override, override_pkgdownyaml()),
    ...
  )
}

#' @describeIn build_site2 build all articles
#' @inheritDotParams pkgdown::build_articles
build_articles2 <- function(...) {
  local_siteyaml()
  pkgdown::build_articles(...)
}

#' @describeIn build_site2 build an individual article
#' @inheritDotParams pkgdown::build_articles
build_article2 <- function(...) {
  local_siteyaml()
  pkgdown::build_article(...)
}

#' List of overrides for `_pkgdown.yml` with muggle defaults.
#' 
#' @examples
#' \dontrun{
#' override_pkgdownyaml()
#' }
#' 
#' @family pkgdown functions
#' @export
override_pkgdownyaml <- function() {
  list(
    url = get_url_from_desc()
  )
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

#' Retrieve the public URL from the `DESCRIPTION`
#' 
#' Chooses whichever URL in the `DESCRIPTION` is *not* on github.com.
#' That's assumed to be the public-facing website, such as a pkgdown website on GitHub pages.
#' 
#' @keywords internal
get_url_from_desc <- function() {
  all_urls <- desc::desc_get_urls()
  gh_urls <- sapply(all_urls, is_gh_url)
  public_urls <- all_urls[!gh_urls]
  public_urls[1]
} 

is_gh_url <- function(url) {
  httr::parse_url(url)$hostname == "github.com"
}
