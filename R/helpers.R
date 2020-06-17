#' Browse to URL
#'
#' @details This function is copied from an unexported function in [usethis](https://github.com/r-lib/usethis/blob/23dd62c5e7713ed8ecceae82e6338f795d30ba92/R/helpers.R).
#'
#' @param ... Elements of the URL
#' @param open `[logical(1)]` giving whether the URL should be opened
#' @keywords internal
#' @export
view_url <- function(..., open = interactive()) {
  url <- paste(..., sep = "/")
  if (open) {
    usethis::ui_done("Opening URL {usethis::ui_value(url)}")
    utils::browseURL(url)
  } else {
    usethis::ui_todo("Open URL {usethis::ui_value(url)}")
  }
  invisible(url)
}

#' @inherit usethis::use_package
#' @description [usethis::use_package()] with muggle defaults
#' @family helpers for repeated interactive use
#' @export
use_package2 <- function(package, type = "Imports") {
  usethis::use_package(package = package, type = type, min_version = TRUE)
}

#' @inherit rcmdcheck::rcmdcheck
#' @description [rcmdcheck::rcmdcheck()] with muggle defaults
#' @family helpers for repeated non-interactive use
#' @export
rcmdcheck2 <- function(error_on = "warning") {
  rcmdcheck::rcmdcheck(
    args = c("--no-manual", "--as-cran"),
    check_dir = "check"
  )
}
