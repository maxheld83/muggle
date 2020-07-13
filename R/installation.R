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
