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

#' Remove an unneeded dependency
#' @keywords internal
#' @export
remove_dep <- function(x) {
  desc::desc_del_dep(x)
  usethis::ui_done(
    x = glue::glue(
      "Removing {dep} from DESCRIPTION again, because it is already included in the muggle image.",
      dep = x
    )
  )
}

#' Muggle files
#' 
#' @param muggle_file 
#' File to copy, relative path from built package root.
#' 
#' @keywords internal
#' @export
get_muggle_file <- function(muggle_file) {
  system.file(muggle_file, package = "muggle")
}

#' Temporarily get muggle files
#' 
#' Copies muggle files ([get_muggle_file()]) to the working directory.
#' Files are deleted when `.local_envir` expires.
#' If file already exists, only a warning is thrown.
#' Useful to avoid pasting boilerplate files in muggle packages.
#' 
#' @inheritParams get_muggle_file
#' 
#' @inheritParams withr::local_file
#' 
#' @keywords internal
#' @export
local_muggle_file <- function(muggle_file, .local_envir = parent.frame()) {
  if (fs::file_exists(muggle_file)) {
    cli::cli_alert_warning(c(
      "File {.file {muggle_file}} already exists. ",
      "Using existing file. ",
      "To use muggle defaults, remove the file."
    ))
  } else {
    target <- withr::local_file(.file = muggle_file, .local_envir = .local_envir)
    fs::file_copy(path = get_muggle_file(muggle_file), new_path = target)
  }
}
