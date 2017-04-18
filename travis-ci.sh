#!/bin/bash

set -e -x -o pipefail

# test for successful release build
# dub build --combined -b release --compiler=$DC
# dub clean --all-packages

# run unit tests
# dub test :core --compiler=$DC
# dub test :vibe --compiler=$DC

# run a build for unit-threaded
if [[ $($DC --version | grep -q 1.0.0) -ne 1 ]]; then
  dub --root=test/unit-threaded --compiler=$DC
fi
