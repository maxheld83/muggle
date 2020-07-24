#!/bin/sh
set -e
# does not seem to be supported out of the box, hence hack from
# https://stackoverflow.com/questions/37316954/git-describe-show-only-latest-tag-and-additional-commits
git describe --tags 1.0.0 | sed 's/\(.*\)-.*/\1/'
