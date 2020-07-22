#' Start a boilerplate shiny app
#' @inheritDotParams shiny::runApp
#' @inherit shiny::runApp
#' @keywords internal
#' @export
runOldFaithful <- function(...) {
  shiny::runApp(appDir = system.file("app", package = "muggle"), ...)
}
