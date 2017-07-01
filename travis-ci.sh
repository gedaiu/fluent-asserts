#!/bin/bash

set -e -x -o pipefail

# test for successful release build
dub build --combined -b release --compiler=$DC
dub clean --all-packages

# run unit tests for 64 bit build
dub test :core --compiler=$DC --arch=x86_64
dub test :vibe --compiler=$DC --arch=x86_64

# run unit tests for 32 bit build
dub test :core --compiler=$DC --arch=x86
dub test :vibe --compiler=$DC --arch=x86

# run a build for unit-threaded
if ! $($DC --version | grep -q 1.0.0); then
  dub --root=test/unit-threaded --compiler=$DC --arch=x86_64
  dub --root=test/unit-threaded --compiler=$DC --arch=x86
fi
