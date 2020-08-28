#' Set up or update the compute environment
#'
#' Adds or updates a `Dockerfile` and corresponding `main.yaml` GitHub Actions workflow.
#'
#' @family compute environment functions
#' @export
use_onbuild_image <- function() {
  # TODO add dockerignore
  # TODO add dockerfile
  # Rbuildignore dockerfile and dockerignore
  NULL
}

#' Install System Dependencies
#'
#' Infers and installs system dependencies from `DESCRIPTION` via the [r-hub/sysreqs](https://github.com/r-hub/sysreqs) project.
#'
#' @family compute environment functions
#' @keywords internal
#' @export
install_sysdeps <- function() {
  checkmate::assert_file_exists("DESCRIPTION")
  # TODO migrate to rspm db https://github.com/subugoe/muggle/issues/25
  sysdep_cmds <- sysreqs::sysreq_commands("DESCRIPTION")
  if (sysdep_cmds == "") {
    cli::cli_alert_info(
      "No necessary system dependencies could be found. Skipping."
    )
  } else {
    # processx does not work here because it requires cmd and args separately
    system(
      command = sysdep_cmds
    )
    cli::cli_alert_success(
      "System depedencies installed."
    )
  }
}

#' Directory for copying dependencies to docker build context
#'
#' This directory serves to copy the package cache into the docker build context on GitHub actions.
#'
#' @family compute environment functions
#' @keywords internal
#' @export
lib_cache_path <- fs::path(".github", "library")
