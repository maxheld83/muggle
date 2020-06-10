# TODO migrate to rstudio/base https://github.com/subugoe/muggle/issues/2
FROM rocker/rstudio:3.6.3-ubuntu18.04 AS builder

# below two have to be in sync with above
# cannot persist env vars based on running scripts
ENV LIB_PATH="/usr/local/lib/R/site-library"
ENV R_HOME="/usr/local/lib/R"

# install system dependencies (manual)
# TODO these are hacks and should be superseded by https://github.com/subugoe/muggle/issues/25
RUN apt-get update && apt-get install -y \
  # hack-fix for https://github.com/r-hub/sysreqsdb/issues/77
  software-properties-common \
  # TODO hack for missing time zone data base, bug in rocker?
  tzdata
# hack for missing sysdeps for ggalt as per https://github.com/hrbrmstr/ggalt/issues/22
RUN add-apt-repository -y ppa:cran/libgit2 && apt-get install -y \
  libproj-dev

# set RSPM for faster binaries
COPY inst/Rprofile.site $R_HOME/etc/Rprofile.site

# install system dependencies (automatic)
RUN Rscript -e "options(warn = 2); install.packages('remotes')"
RUN Rscript -e "options(warn = 2); remotes::install_github('r-hub/sysreqs', ref='3860f2b512a9c3bd3db6791c2ff467a1158f4048')"
ONBUILD COPY DESCRIPTION .
ONBUILD RUN RHUB_PLATFORM="linux-x86_64-ubuntu-gcc" \
  sysreqs=$(Rscript -e "cat(sysreqs::sysreq_commands('DESCRIPTION'))") && \
  eval "$sysreqs"
