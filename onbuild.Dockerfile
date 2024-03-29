# syntax=docker/dockerfile:1.4

# bump this to bust the cache
ARG BUST_CACHE=1

FROM ubuntu:jammy AS base

SHELL ["/bin/bash", "-c"]
RUN set -o pipefail
ARG DEBIAN_FRONTEND=noninteractive

# default place to mount or copy project source
ARG SOURCE_MOUNT_PATH=/root/source/
ENV SOURCE_MOUNT_PATH=$SOURCE_MOUNT_PATH
RUN mkdir --parents $SOURCE_MOUNT_PATH

FROM base AS python
RUN apt-get update && apt-get install --yes --no-install-recommends \
  python3

FROM base AS helper
RUN apt-get update && apt-get install --yes --no-install-recommends \
  ca-certificates \
  curl \
  gpg

FROM helper AS rstats
ARG TARGETPLATFORM
# install rig
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE="arm64-"; else ARCHITECTURE=""; fi \
  && curl -Ls https://github.com/r-lib/rig/releases/download/latest/rig-linux-"${ARCHITECTURE}"latest.tar.gz | \
  tar xz -C /usr/local
ARG R_VERSION=4.2.3
RUN rig add ${R_VERSION}

FROM rstats AS runner
ONBUILD COPY DESCRIPTION .
ONBUILD RUN Rscript -e 'pak::local_install_deps()'

FROM rstats as rstats1
ENV RSPM_HOST=https://packagemanager.rstudio.com
ENV RSPM_PATH=cran
ENV RSPM_DISTRO_AMD64=__linux__/focal
# TODO add these once available on RSPM
# have to build from source for arm64 for now
ENV RSPM_DISTRO_ARM64=""
# set in .env
ARG RSPM_SNAPSHOT_DATE
ARG RSPM_SNAPSHOT_QUERY
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
    RSPM_SNAPSHOT_URL="${RSPM_HOST}"/"${RSPM_PATH}"/"${RSPM_DISTRO_AMD64}"/"${RSPM_SNAPSHOT_DATE}"+"${RSPM_SNAPSHOT_QUERY}"; \
  else \
    RSPM_SNAPSHOT_URL="${RSPM_HOST}"/"${RSPM_PATH}"/"${RSPM_SNAPSHOT_DATE}"; \
  fi \
  && echo "options(repos = c(CRAN = '${RSPM_SNAPSHOT_URL}'))" >> $R_HOME/etc/Rprofile.site

ARG LANG=en_US.UTF-8
RUN apt-get install locales=2.31-0ubuntu9.9 --yes --no-install-recommends && /usr/sbin/locale-gen --lang ${LANG}

FROM base AS helper
RUN apt-get update && \
  apt-get install --yes --no-install-recommends --allow-downgrades \
  # needed for makefile
  git-all=1:2.34.1-1ubuntu1.8 \
  make=4.3-4.1build1
RUN git config --global --add safe.directory $SOURCE_MOUNT_PATH

FROM helper AS builder
COPY DESCRIPTION .
RUN Rscript -e 'pak:local_install_deps()'

FROM builder AS developer
RUN Rscript -e 'pak:local_install_deps(dependencies = TRUE)'
 
# install gh CLI; helpful for authenticating with GitHub
# instructions from https://github.com/cli/cli/blob/trunk/docs/install_linux.md
RUN apt-get update && apt-get install --yes --no-install-recommends \
  gpg \
  curl
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg;
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | tee /etc/apt/sources.list.d/github-cli.list \
  > /dev/null;
RUN apt-get update && apt-get install --yes --no-install-recommends gh

FROM base AS intermediary
# TODO remove when migrated to rspm https://github.com/maxheld83/muggle/issues/25
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
# TODO these are hacks and should be superseded by https://github.com/maxheld83/muggle/issues/25
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

FROM intermediary as buildtime
# this is for buildtime dependencies only
# TODO might have to factor out *dev*-time deps (rstudio?) too

# install azure cli
# TODO remove this https://github.com/maxheld83/shinycaas/issues/32
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
# does not get picked up by sysreqs https://github.com/maxheld83/muggle/issues/204
RUN shinytest::installDependencies()

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

FROM intermediary as runtime
ONBUILD SHELL ["Rscript", "-e"]
# sysdeps have to be installed again, because there appears to be no clear way to copy them
ONBUILD COPY DESCRIPTION .
ONBUILD RUN system(command = sysreqs::sysreq_commands('DESCRIPTION'))
ONBUILD COPY --from=buildtime $R_LIBS_RUNTIME_DOCKER $R_LIBS_RUNTIME_DOCKER
ONBUILD ENV R_LIBS_USER=$R_LIBS_RUNTIME
