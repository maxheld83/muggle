FROM rstudio/r-base:4.0.2-focal AS builder

# below have to be in sync with above base image
# cannot persist env vars based on running scripts
ENV R_HOME="/opt/R/4.0.2/lib/R"
# TODO remove when migrated to rspm https://github.com/subugoe/muggle/issues/25
ENV RHUB_PLATFORM="linux-x86_64-ubuntu-gcc"

# install random system dependencies (manual)
# TODO these are hacks and should be superseded by https://github.com/subugoe/muggle/issues/25
RUN apt-get update && apt-get install -y \
  # hack-fix for https://github.com/r-hub/sysreqsdb/issues/77
  software-properties-common \
  # TODO hack for missing time zone data base, bug in rocker?
  tzdata
# hack for missing sysdeps for ggalt as per https://github.com/hrbrmstr/ggalt/issues/22
# # RUN add-apt-repository -y ppa:cran/libgit2 && apt-get install -y \
#   libproj-dev

# freeze dependencies
COPY builder_img/Rprofile.site $R_HOME/etc/Rprofile.site

# install remotes into base R library, so it is always available
RUN Rscript -e "options(warn = 2); install.packages('remotes')"
# prepend the site library to be used for muggle deps
ENV R_LIBS_MUGGLE=$R_HOME/site-library
# remember this must *exist*!
RUN mkdir $R_LIBS_MUGGLE
ENV R_LIBS_SITE=$R_LIBS_MUGGLE
WORKDIR /muggle
# copy only description first so as not invalidate cache with all source changes
COPY DESCRIPTION .
SHELL ["Rscript", "-e"]
# install muggle builder system dependencies (automatic)
# these steps are duplicated in muggle::install_*, because muggle isn't available in the dockerfile yet
RUN options(warn = 2); remotes::install_github('r-hub/sysreqs', ref='f068afa96c2f454a54de0b350800dee7564239df')
RUN system(command = sysreqs::sysreq_commands('DESCRIPTION'))
# install muggle builder R dependencies
# NA is so as to ensure that suggests deps such as metaR are not baked into the builder image
RUN options(warn = 2); remotes::install_deps(dependencies = NA)

# install builder software (needed at build time, not at run time)
COPY . .
# install muggle into container
RUN remotes::install_local(upgrade = FALSE)
# TODO remove muggle source later with multistage

WORKDIR /app
# this is for the deps of the target pkg
ENV R_LIBS_APP_GH=.github/library/
ENV R_LIBS_APP_DOCKER=/tempdir/Library/
ENV R_LIBS_APP=$R_LIBS_APP_GH:$R_LIBS_APP_DOCKER
# this must include .github location so it is available on github actions
ENV R_LIBS_USER=$R_LIBS_APP
# this will also create the target folder
ONBUILD COPY .github/library $R_LIBS_APP_DOCKER
# copy DESCRIPTION separetely so as to only invalidate this expensive step when necessary
ONBUILD COPY DESCRIPTION .
ONBUILD RUN muggle::install_sysdeps()
# temporarily disable R_LIBS_SITE, so that necessary pkg get installed again
# this needs to be installed again, is used inside install_deps2()
ONBUILD ENV R_LIBS_SITE=$R_LIBS_APP
ONBUILD RUN install.packages("remotes")
ONBUILD RUN remotes::install_deps(dependencies = TRUE)
# re-enable muggle pkgs
ONBUILD ENV R_LIBS_SITE=$R_LIBS_MUGGLE
ONBUILD COPY . .
ONBUILD RUN devtools::document()
ONBUILD RUN remotes::install_local(upgrade = FALSE)
