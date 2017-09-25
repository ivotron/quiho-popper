#!/bin/bash

# add any tasks that are executed regardless of whether the experiment succeeds

COMMIT_SHORT=`git rev-parse HEAD | head -c7`

# put all generated files in the 'previous' experiments folder
git ls-files \
  --others \
  --exclude-standard \
  --exclude='previous/'
  -z | cpio -pmd0 previous/$COMMIT_SHORT

# TODO: commit all changed files (e.g. notebooks)
