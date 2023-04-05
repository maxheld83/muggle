test_that("github packages image url is correct", {
  # outside of muggle container, this does not exist
  # but on ghactions, it should exist
  # TODO should actually test whether it's inside muggle container
  if (!is_github_actions()) {
    withr::local_envvar(.new = c("MUGGLE_PKG_NAME" = "muggle"))
  }
  expect_equal(
    gh_pkgs_image_url(version = "latest", repo_spec = "maxheld83/muggle"),
    "docker.pkg.github.com/maxheld83/muggle/muggle-runtime:latest"
  )
})

test_that("repo spec is correct", {
  skip("Skipping because there is no git repo")
  expect_equal(repo_spec(), "maxheld83/muggle")
})
