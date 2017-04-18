#!/bin/bash

set -e -x -o pipefail

# test for successful release build
dub build --combined -b release --compiler=$DC
dub clean --all-packages

# run unit tests
dub test :core --compiler=$DC
dub test :vibe --compiler=$DC

# run a build for unit-threaded
echo 'Run unit-threaded build:' $UNIT_THREADED

if [[ $UNIT_THREADED ]]; then
  dub --root=test/unit-threaded --compiler=$DC
fi
