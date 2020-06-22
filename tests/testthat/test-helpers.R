test_that("urls are not opened in non-interactive mode", {
  testthat::expect_equal(
    object = view_url("www.github.com", open = FALSE),
    expected = "www.github.com"
  )
})
