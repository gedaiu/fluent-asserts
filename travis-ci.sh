#!/bin/bash

set -e -x -o pipefail

# test for successful 32-bit build
if [ "$DC" == "dmd" ]; then
	dub build --combined --arch=x86
	dub clean --all-packages
fi

# test for successful release build
dub build --combined -b release --compiler=$DC
dub clean --all-packages

# run unit tests
dub test :core --compiler=$DC
dub test :vibe --compiler=$DC

# run a build for unit-threaded
if ! $($DC --version | grep -q 1.0.0); then
  dub --root=test/unit-threaded --compiler=$DC --arch=x86_64
fi

# run a build for DisableSourceResult
if ! $($DC --version | grep -q 1.0.0); then
  dub --root=test/disabledSourceResult --compiler=$DC --arch=x86_64
fi
