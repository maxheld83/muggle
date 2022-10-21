#' Set up codecov
#' @param reposlug `[character(1)]`
#' giving the `username/repo` URL slug of the project.
#' @family quality control functions
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

#' Set up [super-linter](https://github.com/github/super-linter)
#' @family quality control functions
#' @export
use_superlinter <- function() {
  superlinter_url <- "https://github.com/marketplace/actions/super-linter"
  usethis::ui_todo(c(
    "Please add the {usethis::ui_code{'linter.yaml'} ",
    "as described on {usethis::ui_code{superlinter_url}."
  ))
  view_url(superlinter_url)
}
