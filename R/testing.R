#' Set up codecov
#' @param reposlug `[character(1)]`
#' giving the `username/repo` URL slug of the project.
#' @family testing functions
#' @export
use_codecov2 <- function(reposlug) {
  usethis::use_coverage(type = "codecov")
  usethis::ui_todo(c(
    "Add the {usethis::ui_value('Repository Upload Token')} from codecov ",
    "as a secret called {usethis::ui_value('CODECOV_TOKEN')} on GitHub."
  ))
  view_url("https://codecov.io/gh", reposlug, "settings")
  view_url("https://github.com", reposlug, "settings", "secrets")
}
