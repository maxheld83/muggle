#' Set up vscode inside a package
#'
#' 1. adds vscode files to `.Rbuildignore`
#'
#' @family editor functions
#' @export
use_vscode <- function() {
  # TODO create workspace
  usethis::use_build_ignore(
    "[.]code-workspace$",
    escape = FALSE
  )
}
