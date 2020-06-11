# TODO migrate to rstudio/base https://github.com/subugoe/muggle/issues/2
FROM rocker/rstudio:3.6.3-ubuntu18.04 AS builder

# below have to be in sync with above
# cannot persist env vars based on running scripts
ENV R_HOME="/usr/local/lib/R"
ENV RHUB_PLATFORM="linux-x86_64-ubuntu-gcc"

# set RSPM for faster binaries
# this only needs to persist at build-time
COPY builder_img/Rprofile.site $R_HOME/etc/Rprofile.site
# remember this must *exist*!
ENV R_LIBS_SITE="/usr/local/lib/R/site-library"
# install all builder deps here
ENV R_LIBS=$R_LIBS_SITE

# install random system dependencies (manual)
# TODO these are hacks and should be superseded by https://github.com/subugoe/muggle/issues/25
RUN apt-get update && apt-get install -y \
  # hack-fix for https://github.com/r-hub/sysreqsdb/issues/77
  software-properties-common \
  # TODO hack for missing time zone data base, bug in rocker?
  tzdata
# hack for missing sysdeps for ggalt as per https://github.com/hrbrmstr/ggalt/issues/22
RUN add-apt-repository -y ppa:cran/libgit2 && apt-get install -y \
  libproj-dev

# install builder software (needed at build time, not at run time)
COPY DESCRIPTION .

# install builder system dependencies (automatic)
RUN Rscript -e "options(warn = 2); install.packages('remotes')"
RUN Rscript -e "options(warn = 2); remotes::install_github('r-hub/sysreqs', ref='3860f2b512a9c3bd3db6791c2ff467a1158f4048')"
RUN cat DESCRIPTION
RUN sysreqs=$(Rscript -e "cat(sysreqs::sysreq_commands('DESCRIPTION'))") && \
  eval "$sysreqs"

# install builder R dependencies
RUN Rscript -e "options(warn = 2); remotes::install_deps(dependencies = TRUE)"

# triggers for app software (needed at runtime)
# just overwrite existing description, not needed
ONBUILD COPY DESCRIPTION .
# install runtime sytem dependencies (automatic)
ONBUILD RUN sysreqs=$(Rscript -e "cat(sysreqs::sysreq_commands('DESCRIPTION'))") && \
  eval "$sysreqs"
# TODO still need to cache in R dependencies https://github.com/subugoe/muggle/issues/51
# copy in cache
# if this is run outside of github actions, will just copy empty dir
# COPY .deps/ ${LIB_PATH}
# install runtime R dependencies here, not to site
# R_LIBS_SITE must be unavailable now, so that *all* dependencies for runtime are cleanly installed
ONBUILD ENV R_LIBS=$R_HOME/library
# this requires a reinstall of remotes, which will linger with the runtime deps
ONBUILD RUN Rscript -e "options(warn = 2); install.packages('remotes')"
ONBUILD RUN Rscript -e "options(warn = 2); remotes::install_deps(dependencies = TRUE)"
# enable other images again
ONBUILD ENV R_LIBS=$R_HOME/library:$R_LIBS_SITE
