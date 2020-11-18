test_that("urls are not opened in non-interactive mode", {
  testthat::expect_equal(
    object = view_url("www.github.com", open = FALSE),
    expected = "www.github.com"
  )
})

test_muggle_file <- "vignettes/_site.yml"
test_that("muggle file can be copied", {
  withr::local_dir(tempdir())
  fs::dir_create("vignettes")
  local_muggle_file(test_muggle_file)
  checkmate::expect_file_exists(test_muggle_file)
  # imperfect test, just tests for message, not wheter file is left untouched
  testthat::expect_message(local_muggle_file(test_muggle_file))
  withr::deferred_run()
  testthat::expect_false(fs::file_exists(test_muggle_file))
})
