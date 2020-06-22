# TODO migrate to rstudio/base https://github.com/subugoe/muggle/issues/2
FROM rocker/rstudio:3.6.3-ubuntu18.04 AS builder

# below have to be in sync with above
# cannot persist env vars based on running scripts
ENV R_HOME="/usr/local/lib/R"
# TODO remove when migrated to rspm https://github.com/subugoe/muggle/issues/25
ENV RHUB_PLATFORM="linux-x86_64-ubuntu-gcc"

# set RSPM for faster binaries
COPY builder_img/Rprofile.site $R_HOME/etc/Rprofile.site
# remember this must *exist*!
ENV R_LIBS_SITE=$R_HOME/site-library
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
COPY . /muggle
WORKDIR /muggle

SHELL ["Rscript", "-e"]
# install muggle builder system dependencies (automatic)
# these steps are duplicated in muggle::install_*, because muggle isn't available in the dockerfile yet
RUN options(warn = 2); install.packages('remotes')
RUN options(warn = 2); remotes::install_github('r-hub/sysreqs', ref='f068afa96c2f454a54de0b350800dee7564239df')
RUN system(command = sysreqs::sysreq_commands('DESCRIPTION'))

# install muggle builder R dependencies
RUN options(warn = 2); remotes::install_deps(dependencies = TRUE)

# install muggle into container
RUN remotes::install_local(upgrade = FALSE)

ENV R_LIBS=$R_HOME/library
# install remotes again so that it lingers with user lib for runtime, necessary for install_deps2
RUN options(warn = 2); install.packages('remotes')

# set correct order; user (runtime) lib precedes (build-time) site lib
ENV R_LIBS=$R_HOME/library:$R_LIBS_SITE

# triggers for app software (needed at runtime)
# just overwrite existing description, not needed
ONBUILD COPY DESCRIPTION .
# install runtime sytem dependencies (automatic)
ONBUILD RUN muggle::install_sysdeps()
# TODO still need to cache in R dependencies https://github.com/subugoe/muggle/issues/51
# copy in cache
ONBUILD RUN muggle::install_deps2()
