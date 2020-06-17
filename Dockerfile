# this is needed only in this pkg; downstream users would just hard-code the tag here
ARG MUGGLE_BUILDER_TAG=latest
FROM subugoe/muggle:${MUGGLE_BUILDER_TAG}
