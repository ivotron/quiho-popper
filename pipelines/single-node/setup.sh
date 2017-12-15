#!/bin/bash
set -e

if [ -n "$CI" ]; then
  setup/travis.sh
else
  setup/cloudlab.sh
fi
