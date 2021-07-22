test_that("load and clean works", {
  skip("Cannot be tested without pkg at root")
  obj <- "foo"
  # withr::defer() would warn to remove obj
  # in a successful run
  load_clean_all()
  expect_false(exists("obj"))
})
