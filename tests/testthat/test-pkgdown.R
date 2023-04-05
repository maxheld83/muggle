test_that("public url is correctly inferred", {
  local_create_package()
  desc::desc_set_urls(c(
    "https://maxheld83.github.io/muggle",
    "https://github.com/maxheld83/muggle",
    "https://www.google.com"
  ))
  expect_equal(get_url_from_desc(), "https://maxheld83.github.io/muggle")
})
