FROM rstudio/r-base:4.0.2-focal AS base
# stuff used in all downstream stages (builder and prod)

# below have to be in sync with above base image
# there seems to be no better way; cannot persist env vars based on running scripts
ENV R_HOME="/opt/R/4.0.2/lib/R"
# this freezes r dependencies see https://github.com/subugoe/muggle/issues/60
ENV RSPM="https://packagemanager.rstudio.com/all/__linux__/focal/345"
# TODO remove when migrated to rspm https://github.com/subugoe/muggle/issues/25
ENV RHUB_PLATFORM="linux-x86_64-ubuntu-gcc"
# just FYI; this is were base pkg live, they are always available
ENV R_LIBS_BASE=$R_HOME/library/

# define various paths in "harmless" env vars
# they will be copied to standard env vars expected by r below
# these may not exist yet!
# install all muggle deps as site-library (this is for builder)
ENV R_LIBS_BUILDTIME=$R_HOME/site-library
# this is for runs on gh actions directly, *just* in muggle-buildtime-onbuild, without any of the onbuild instructions firing
# in this situation, the below copying of R_LIBS_RUNTIME_GH to R_LIBS_RUNTIME_DOCKER does not happen
# so .github/library must also be on path
ENV R_LIBS_RUNTIME_GH=.github/library/
# this is for docker build runs on gh actions, this is the copy target of above folder
ENV R_LIBS_RUNTIME_DOCKER=/tempdir/Library/
# this must include .github location so it is available on github actions
# not all of these may exist in all runs, so will be inconsequential
ENV R_LIBS_RUNTIME=$R_LIBS_RUNTIME_DOCKER:$R_LIBS_RUNTIME_GH

# install system dependencies manually
# TODO these are hacks and should be superseded by https://github.com/subugoe/muggle/issues/25
RUN apt-get update && apt-get install -y \
  # hack-fix for https://github.com/r-hub/sysreqsdb/issues/77
  software-properties-common \
  # TODO hack for missing time zone data base, bug in rocker?
  tzdata

# this brings above env var in effect to freeze dependencies
COPY builder_img/Rprofile.site $R_HOME/etc/Rprofile.site
# install some R things needed for all targets
SHELL ["Rscript", "-e"]
RUN options(warn = 2); install.packages('remotes')
RUN options(warn = 2); remotes::install_github('r-hub/sysreqs', ref='f068afa96c2f454a54de0b350800dee7564239df')
SHELL ["sh", "-c"]

FROM base as buildtime
# this is for buildtime dependencies only
# TODO might have to factor out *dev*-time deps (rstudio?) too

# install azure cli
# TODO remove this https://github.com/subugoe/shinycaas/issues/32
RUN ["bash", "-c", "curl -sL https://aka.ms/InstallAzureCLIDeb | bash"]

# this folder has to *exist* to work as a lib
RUN mkdir $R_LIBS_BUILDTIME
# prepend lib search path with muggle, so that stuff gets installed there
ENV R_LIBS_SITE=$R_LIBS_BUILDTIME
# this also creates the dir
WORKDIR /muggle
# copy only description first so as not invalidate cache with all source changes
COPY DESCRIPTION .
SHELL ["Rscript", "-e"]
# install muggle builder system dependencies automatically
# these steps are duplicated in muggle::install_*
# can't be used here because muggle isn't available yet
RUN system(command = sysreqs::sysreq_commands('DESCRIPTION'))
# NA is so as to ensure that suggests deps such as metar are not baked into the builder image
RUN options(warn = 2); remotes::install_deps(dependencies = NA)

# install builder software (needed at build time, not at run time)
COPY . .
# install muggle into container
RUN devtools::document()
RUN remotes::install_local(upgrade = FALSE)

# just using the conventional name
WORKDIR /app
# this is for the deps of the target pkg
ENV R_LIBS_USER=$R_LIBS_RUNTIME
# this will also create the target folder
ONBUILD COPY $R_LIBS_RUNTIME_GH $R_LIBS_RUNTIME_DOCKER
# copy DESCRIPTION separately so as to only invalidate these expensive step when necessary
ONBUILD COPY DESCRIPTION .
ONBUILD RUN muggle::install_sysdeps()
# temporarily disable R_LIBS_SITE, so that necessary pkg get installed again
# tried doing this via withr::with_env but could not get it to work
ONBUILD ENV R_LIBS_SITE=$R_LIBS_RUNTIME
ONBUILD RUN remotes::install_deps(dependencies = TRUE)
# re-enable muggle pkgs
ONBUILD ENV R_LIBS_SITE=$R_LIBS_BUILDTIME
ONBUILD COPY . .
ONBUILD RUN devtools::document()
ONBUILD RUN remotes::install_local(upgrade = FALSE)

FROM base as runtime
ONBUILD SHELL ["Rscript", "-e"]
# sysdeps have to be installed again, because there appears to be no clear way to copy them
ONBUILD COPY DESCRIPTION .
ONBUILD RUN system(command = sysreqs::sysreq_commands('DESCRIPTION'))
ONBUILD COPY --from=buildtime $R_LIBS_RUNTIME_DOCKER $R_LIBS_RUNTIME_DOCKER
ONBUILD ENV R_LIBS_USER=$R_LIBS_RUNTIME
