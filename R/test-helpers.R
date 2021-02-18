local_create_package <- function(dir = fs::file_temp(), env = parent.frame()) {
  old_wd <- getwd()

  usethis::create_package(dir, open = FALSE)
  withr::defer(fs::dir_delete(dir), envir = env)

  setwd(dir)
  withr::defer(setwd(old_wd), envir = env)

  dir
}
