test_that("github packages image url is correct", {
  withr::local_envvar(new = c(
    "MUGGLE_PKG_NAME" = "muggle"
  ))
  expect_equal(
    gh_pkgs_image_url(version = "latest", repo_spec = "subugoe/muggle"),
    "docker.pkg.github.com/subugoe/muggle/muggle-runtime:latest"
  )
})

test_that("repo spec is correct", {
  skip("Skipping because there is no git repo")
  expect_equal(repo_spec(), "subugoe/muggle")
})
