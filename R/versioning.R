find_dev_ver_number <- function() {
  script <- system.file("scripts", "find_dev_ver_number.sh", package = "muggle")
  ver <- "0.0.0.9000"
  res <- processx::run(script)
  if (res$stdout == "") {
    cli::cli_alert_warning("
      Could not construct a version number using {.code git describe}.
      Maybe you have not created any {.code git tag}s?
      Using {.code {ver}} instead.
    ")
  } else {
    ver <- res$stdout
  }
  return(ver)
}
