# muggle

<!-- badges: start -->
[![Main](https://github.com/maxheld83/muggle/workflows/.github/workflows/main.yaml/badge.svg)](https://github.com/maxheld83/muggle/actions)
[![Codecov test coverage](https://codecov.io/gh/maxheld83/muggle/branch/master/graph/badge.svg)](https://codecov.io/gh/maxheld83/muggle?branch=master)
[![CRAN status](https://www.r-pkg.org/badges/version/muggle)](https://CRAN.R-project.org/package=muggle)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![muggle-buildtime Docker Pulls](https://img.shields.io/docker/pulls/maxheld83/muggle-buildtime-onbuild?label=muggle-buildtime%20docker%20pulls&style=flat)](https://hub.docker.com/repository/docker/maxheld83/muggle-buildtime-onbuild)
[![muggle-runtime Docker Pulls](https://img.shields.io/docker/pulls/maxheld83/muggle-runtime-onbuild?label=muggle-runtime%20docker%20pulls&style=flat)](https://hub.docker.com/repository/docker/maxheld83/muggle-runtime-onbuild)
<!-- badges: end -->

## Overview

> Reproducible DevOps Strictly Without Magic

{muggle} is an R package to implement DevOps best practices for R data products.

Data products are somewhere between one-off scripts and CRAN-bound packages.
One the one hand, they are more complex than simple scripts and take longer to build.
To ensure value for their creators, such data products must be reproducible and better scale to accomodate more users or developers.
On the other hand, data products face fewer requirements than mainstream packages:
They can have more dependencies and they need not run in different computing environments.

{muggle} addresses the needs of such often domain-specific data products by implementing these priorities:

1. **No Magic** (hence the name)
   {muggle} will never infer intent, but users have to state it explicitly.
   For example, dependencies are never inferred from a project source files, but have to be listed in the `DESCRIPTION` file.
   This exposes more technical underpinnings, but makes it easier to reason about a project if things go wrong.
2. **Every R Data Product is an R Package**
   {muggle} organises all data products as an R package.
   For example, a shiny app can be a function in `R/` and a report can be an RMarkdown document in `vignettes/`.
   This adds minimal overhead, but also enforces various best practices and structures projects in a single, familiar way.
3. **One Image Rule them All**
   {muggle} provides one fully versioned and reproducible compute environment as a docker image, including:
   - operating system,
   - R version,
   - system dependencies,
   - and R dependencies snapshotted by date (via [RStudio Package Manager](https://packagemanager.rstudio.com/)).

   Across
   - local development (via [RStudio Server Open Source](https://rstudio.com/products/rstudio/#rstudio-server) or [vscode](https://code.visualstudio.com)),
   - continuous integration / continuous delivery (CI/CD) scripts on [GitHub Actions](https://github.com/features/actions),
   - batch jobs on in high-performance computing clusters,
   - and even [shiny apps](https://shiny.rstudio.com) or [plumber web APIs](https://www.rplumber.io),
   the project will run in the exact same computing environment.
   This reduces flexibility, but minimises the time wasted on "but-it-works-on-my-machine"-problems.
4. **Fast Iterations**
   {muggle} speeds up development iterations as much as possible, using
   - pre-compiled binaries from [RStudio Package Manager](https://packagemanager.rstudio.com/)),
   - docker layer cache,
   - [GitHub Actions cache](https://help.github.com/en/actions/configuring-and-managing-workflows/caching-dependencies-to-speed-up-workflows) for dependencies and
   - [knitr cache](https://yihui.org/knitr/demo/cache/) for vignettes.
   This creates some "GOTCHAS", but encourages agile development by quick turnarounds.
5. **Only Humans `git commit`**.
   {muggle} is designed so that human-edited sources files are under version control.
   Copy-pasted boilerplate and compiled assets are avoided as much as possible (with the exception of `man/` so as to not break `remotes::install_github()`).
   This requires a bit more discipline, but enhances reproducibility and cleans up `git diff`s.
6. **R Packages are for Code, not Data**.
   {muggle} does not ship data with a package, but only wrapper functions which either call databases or git lfs storage.
   Only small or unchanging datasets can be stored inside packages.


## Getting Started

### `make` Targets

All DevOps-steps are stored as `make` targets.
To see all targets, simply run `make`.
