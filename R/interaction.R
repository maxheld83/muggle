#' Clean workspace and load all packages
#' @inherit devtools::load_all
#' @family functions for interactive use
#' @export
load_clean_all <- function(...) {
  rm(
    list = ls(envir = parent.frame()),
    envir = parent.frame()
  )
  devtools::load_all(quiet = TRUE)
}
