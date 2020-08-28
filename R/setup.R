#' Create a muggle package
#'
#' @description
#' Set up, or migrate to a muggle project.
#' Wraps the following steps, *if the respective files or configuration do not already exist*:
#'
#' 1. **Package Structure**: Sets up scaffolding via [usethis::create_package()] and asks the user to complete the `DESCRIPTION`.
#' 1. **Editors/IDEs**: Sets up [vscode](http://code.visualstudio.com) ([use_vscode()]) and RStudio as editors.
#' 1. **Git/GitHub**: Initialises a git repo via [usethis::use_git()], creates a repo on GitHub and sets it as an origin remote.
#' 1. **README**: Adds a `README.md` via [usethis::use_readme_md()] and asks the user to complete it.
#' 1. **Testing**: Sets up the project for unit tests via [usethis::use_testthat()] and test coverage via [usethis::use_coverage()].
#' 1. **Documentation**: Sets up markdown support in roxygen via [usethis::use_roxygen_md()], package documentation via [usethis::use_package_doc()] and ddds a pkgdown website via [usethis::use_pkgdown()].
#' 1. **Workflow Automation**: sets up caching at [lib_cache_path] and tba.
#' 1. **Compute Environment**: tba.
#'
#'
#' @details # Warning
#' - Must not be run *inside* a package, but at the root of all packages
#' - If run on an existing project, the project should be under version control, with a clean working tree.
#'   The user should check all changes.
#'
#' @inheritParams usethis::create_package
#' @param license one of the license functions in [usethis]
#' @param license_holder giving the license holder, used as `cph` and `fnd` role in `DESCRIPTION`
#' @inheritParams usethis::use_github
#' @family setup functions
#' @export
create_muggle_package <- function(path,
                                  fields = list(),
                                  license = usethis::use_mit_license,
                                  license_holder = character(),
                                  organisation = NULL,
                                  private = FALSE) {
  # input validation
  checkmate::assert_function(license)
  checkmate::assert_string(license_holder)
  # does not work properly with relative paths
  # at least not with a .git at ~ as on max's machine
  path <- fs::path_abs(path = path)

  # package structure ====
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
  # configure to never save/load Rdata
  usethis::use_blank_slate("project")

  # editors / ide ====
  use_vscode()

  # git/github ====
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

  # testing ====
  # testthat is already in muggle, is also required in user pkg
  # otherwise there is a check error
  usethis::use_testthat()
  usethis::use_coverage()
  remove_dep("covr")

  # documentation ====
  # cleaner to have this in a separate folder
  usethis::use_roxygen_md()
  usethis::use_package_doc(open = FALSE)
  usethis::use_pkgdown(config_file = "pkgdown/_pkgdown.yml")

  # workflow automation ====
  # set up caching of deps from github actions into container
  fs::dir_create(path = lib_cache_path)
  brio::write_lines(
    text = c("See `help('muggle::lib_cache_path')`"),
    path = fs::path(lib_cache_path, "README.md")
  )
  usethis::ui_done(
    "Created {usethis::ui_code(lib_cache_path)} to add cached dependencies to docker build context on GitHub actions."
  )

  # compute environment ====
  # TODO add docker generation

  # final edits ====
  usethis::ui_todo(x = "Edit the {usethis::ui_code('README.md')}.")
  usethis::edit_file("README.md")

  usethis::ui_done(x = "Your package is now set up.")
  usethis::ui_todo(x = "Review and commit all changes.")
}
