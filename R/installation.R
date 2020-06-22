
#' Install System Dependencies
#'
#' Infers and installs system dependencies from `DESCRIPTION` via the [r-hub/sysreqs](https://github.com/r-hub/sysreqs) project.
#'
#' @family computing environment
#'
#' @export
install_sysdeps <- function() {
  checkmate::assert_file_exists("DESCRIPTION")
  # TODO migrate to rspm db https://github.com/subugoe/muggle/issues/25
  sysdep_cmds <- sysreqs::sysreq_commands("DESCRIPTION")
  # processx does not work here because it requires cmd and args separately
  system(
    command = sysdep_cmds
  )
}

#' @inherit remotes::install_deps
#' @description [remotes::install_deps()] with muggle defaults
install_deps2 <- function() {
  # by default, install_deps does not error out on failed installs, which causes hard to understand downstream problems
  withr::local_options(warn = 2)
  # ignore, for now, everything that comes with muggle
  # exception, out of necessity, is remotes, which has been installed twice.
  withr::local_libpaths(new = .libPaths()[1])
  remotes::install_deps(dependencies = TRUE)
}
