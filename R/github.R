#' Get the full docker image url for an image on GitHub Packages
#'
#' Helpful to quickly run an image locally or deploy it.
#' See the [GitHub Packages for Docker documentation](https://docs.github.com/en/packages/using-github-packages-with-your-projects-ecosystem/configuring-docker-for-use-with-github-packages) for details.
#' Forms a URL of the form `docker.pkg.github.com/OWNER/REPOSITORY/IMAGE_NAME:VERSION`
#' Notice how, different from Docker Hub, docker images on GitHub Packages have an `IMAGE_NAME` appended to the familiar `OWNER/REPOSITORY` pattern.
#' These `IMAGE_NAME`s are immutable (cannot be changed nor deleted) and must be unique per GitHub repository.
#'
#' @param image_name,version Image name and version as strings.
#' Defaults to muggle convention.
#'
#' @param repo_spec GitHub repo specification in this form: `owner/repo`.
#' Users should stick to the default; manual entry is only used for testing.
#'
#' @return character string
#'
#' @family GitHub Packages
#'
#' @export
gh_pkgs_image_url <- function(image_name = gh_pkgs_image_name(target = "runtime"),
                              version = gh_pkgs_image_version(),
                              repo_spec = repo_spec()) {
  paste(
    "docker.pkg.github.com",
    repo_spec,
    paste0(image_name, ":", version),
    sep = "/"
  )
}

#' @describeIn gh_pkgs_image_url Get the docker image name conventionally used in muggle projects
#'
#' @param target Build target for multistage muggle builds.
#' By convention, for a package `foo`, {muggle} would build a `foo-buildtime` and `foo-runtime` for the `buildtime` and `runtime` docker multistage build targets, respectively.
#' A `buildtime` target will exist for all {muggle} projects, a `runtime` target only for projects with deployed runtimes such as a shiny app
#'
#' @export
gh_pkgs_image_name <- function(target = c("buildtime", "runtime")) {
  target <- rlang::arg_match(target)
  paste0(utils::packageName(), "-", target)
}

#' @describeIn gh_pkgs_image_url
#' Get the sha of the *latest* `git commit` if on GitHub Actions, or the *head* reference (the branch or tag) otherwise (not recommended for reproducibility).
gh_pkgs_image_version <- function() {
  if (is_github_actions()) {
    return(Sys.getenv("GITHUB_SHA"))
  } else {
    # somewhat hacky backstop, the current head ref
    cli::cli_alert_warning(
      "Using *current* head reference, not the latest {.code git sha}."
    )
    gert::git_info()$shorthand
  }
}

#' Get the GitHub remote associated with a path as a repo_spec (`user/repo`)
#'
#' Wraps [gh::gh_tree_remote()].
#'
#' @keywords internal
#'
#' @family GitHub helpers
#'
#' @export
repo_spec <- function() {
  # something like this already exists in usethis, but seems unexported
  # muggle image *has* git, and on gh actions should also have a repo
  # but this will not work in a local docker container, which has git, but no repo
  do.call(paste, c(gh::gh_tree_remote(), sep = "/"))
}

#' Determine if code is running inside GitHub Actions
#'
#' Looks for the `GITHUB_ACTIONS` environment variable, as [documented](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables)
#'
#' @noRd
is_github_actions <- function() {
  Sys.getenv("GITHUB_ACTIONS") == "true"
}
