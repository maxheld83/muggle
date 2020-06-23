#' Create a muggle project
#'
#' @description
#' Set up, or migrate to a muggle project.
#' Wraps the following steps, *if the respective files or configuration do not already exist*:
#'
#' 1. Sets up package scaffolding via [usethis::create_package()].
#' 1. Initialises a git repo via [usethis::use_git()].
#' 1. Creates a repo on GitHub and sets it as an origin remote.
#' 1. Adds a `README.md` via [usethis::use_readme_md()].
#' 1. Sets up the project for unit tests via [usethis::use_testthat()] and test coverage via [usethis::use_coverage()].
#' 1. Adds a pkgdown website via [usethis::use_pkgdown()].
#' 1. Opens the `DESCRIPTION` and `README.md` for additional edits.
#'
#' @details # warning
#' - Must not be run *inside* a package, but at the root of all packages
#' - If run on an existing project, the project should be under version control, with a clean working tree.
#'   The user should check all changes.
#'
#' @inheritParams usethis::create_package
#' @param license one of the license functions in [usethis]
#' @param license_holder giving the license holder, used as `cph` and `fnd` role in `DESCRIPTION`
#' @inheritParams usethis::use_github
#' @family setup helpers
#' @export
create_muggle <- function(path,
                          fields = list(),
                          license = usethis::use_mit_license,
                          license_holder = character(),
                          organisation = NULL,
                          private = FALSE) {
  # input validation
  checkmate::assert_function(license)
  checkmate::assert_string(license_holder)
  # does not work properly with relative paths, at least not with a .git at ~ as on max's machine
  path <- fs::path_abs(path = path)

  # fix the description and related files ====
  usethis::create_package(
    path = path,
    fields = fields,
    # set rstudio even if api is not available, useful for other users
    rstudio = TRUE
  )
  if (length(license_holder) == 0) {
    rlang::exec(license)
  } else {
    rlang::exec(.fn = license, license_holder)
    desc::desc_add_author(family = license_holder)
    # for some reason this needs to be a separate call
    desc::desc_add_role(role = c("cph", "fnd"), given = license_holder)
  }

  # config
  usethis::use_blank_slate("project")
  use_vscode()

  # set up git ====
  usethis::use_git()
  # imperfect check for whether github remote is set
  if (nrow(gert::git_remote_list()) == 0) {
    # if there was already a git remote as will be the case for existing projects, the whole function would error out here
    usethis::use_github(
      organisation = organisation,
      private = private,
      protocol = "https"
    )
  } else {
    usethis::use_github_links()
  }

  usethis::ui_todo(x = "Edit the {usethis::ui_code('DESCRIPTION')}.")
  usethis::edit_file("DESCRIPTION")

  usethis::use_readme_md()

  # usethis::use_testthat() is actually a bad idea because it would pollute the DESCRIPTION
  usethis::use_testthat()
  remove_dep("testthat")
  usethis::use_coverage()
  remove_dep("covr")

  # cleaner to have this in a separate folder
  usethis::use_pkgdown(config_fil = "pkgdown/_pkgdown.yml")
  # usethis::use_spell_check()

  # usethis::use_package_doc()
  # usethis::use_roxygen_md()

  usethis::ui_todo(x = "Edit the {usethis::ui_code('README.md')}.")
  usethis::edit_file("README.md")
}

#' Set up vscode inside a package
#'
#' 1. adds vscode files to `.Rbuildignore`
#'
#' @family setup helpers
#' @export
use_vscode <- function() {
  usethis::use_build_ignore(
    "[.]code-workspace$",
    escape = FALSE
  )
}

#' Set up codecov
#' @param reposlug `[character(1)]` giving the `username/repo` URL slug of the project.
#' @family setup helpers
#' @export
use_codecov2 <- function(reposlug) {
  usethis::use_coverage(type = "codecov")
  usethis::ui_todo(
    "Add the {usethis::ui_value('Repository Upload Token')} from codecov as a secret called {usethis::ui_value('CODECOV_TOKEN')} on GitHub."
  )
  view_url("https://codecov.io/gh", reposlug, "settings")
  view_url("https://github.com", reposlug, "settings", "secrets")
}
