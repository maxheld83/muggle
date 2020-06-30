
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
#' @family computing environment
#'
#' @export
install_deps2 <- function(dependencies = TRUE) {
  # by default, install_deps does not error out on failed installs, which causes hard to understand downstream problems
  withr::local_options(new = list(warn = 2))
  # just take the first one, should be set correctly in dockerfiles and github actions yaml
  lib_path_pkg_deps <- .libPaths()[1]
  # ignore, for now, everything that comes with muggle
  # exception, out of necessity, is remotes, which has been installed twice.
  withr::local_libpaths(new = .libPaths()[1])
  remotes::install_deps(dependencies = dependencies)

  # create a copy of the library that is readily inside the docker build context
  # this seems hacky, but there appears to be no other way short of using / as build context, which would slow down docker builds
  if (!identical(Sys.getenv("GITHUB_ACTIONS"), "true")) {
    fs::dir_copy(
      path = lib_path_pkg_deps,
      new_path = lib_cache_path,
      overwrite = TRUE
    )
    usethis::ui_done("Copied package dependencies into docker build context path.")
  }
}
