#!/bin/bash
# [wf]: setup infrastructure for test
set -e

if [ -n "$CI" ]; then
  # [wf]: launch a "node" locally
  setup/travis.sh
else
  # [wf]: allocate nodes on CloudLab
  setup/cloudlab.sh
fi
