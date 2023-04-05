# this is needed only in this pkg; downstream users would just hard-code the muggle tag here
ARG MUGGLE_BUILDER_TAG=latest
FROM maxheld83/muggle-buildtime-onbuild:${MUGGLE_BUILDER_TAG} as buildtime
FROM maxheld83/muggle-runtime-onbuild:${MUGGLE_BUILDER_TAG} as runtime
CMD shinycaas::az_webapp_shiny_opts(); shiny::runExample("02_text", port = getOption('shiny.port'))
