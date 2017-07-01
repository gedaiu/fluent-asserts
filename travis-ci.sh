#!/bin/bash

set -e -x -o pipefail


# test for successful release build
dub build --combined -b release --compiler=$DC --config=${VIBED_DRIVER=libevent}
dub clean --all-packages

# test for successful 32-bit build
if [ "$DC" == "dmd" ]; then
	dub build --combined --arch=x86 --config=${VIBED_DRIVER=libevent}
	dub clean --all-packages
fi

# test for successful release build
dub build --combined -b release --compiler=$DC
dub clean --all-packages

# run unit tests for 64 bit build
dub test :core --compiler=$DC
dub test :vibe --compiler=$DC

# run a build for unit-threaded
if ! $($DC --version | grep -q 1.0.0); then
  dub --root=test/unit-threaded --compiler=$DC --arch=x86_64
  dub --root=test/unit-threaded --compiler=$DC --arch=x86
fi
