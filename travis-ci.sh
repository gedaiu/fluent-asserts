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
dub test --compiler=$DC

# run a build for unit-threaded
if ! $($DC --version | grep -q 1.0.0); then
  dub --root=test/unit-threaded --compiler=$DC --arch=x86_64
fi

# run a build for DisableSourceResult
if ! $($DC --version | grep -q 1.0.0); then
  dub --root=test/disabledSourceResult --compiler=$DC --arch=x86_64
fi

# run a build for DisableMessageResult
if ! $($DC --version | grep -q 1.0.0); then
  dub --root=test/disabledMessageResult --compiler=$DC --arch=x86_64
fi

# run a build for DisableDiffResult
if ! $($DC --version | grep -q 2.073); then
  dub --root=test/disabledDiffResult --compiler=$DC --arch=x86_64
fi

# run a build for vibe-d 0.8
if ! $($DC --version | grep -q '2.073\|2.074\|2.075\|2.076\|2.077\|2.078\|2.079'); then
  dub --root=test/vibe-0.7 --compiler=$DC --arch=x86_64
fi

# run a build for vibe-d 0.7
if ! $($DC --version | grep -q 2.073); then
  dub --root=test/vibe-0.7 --compiler=$DC --arch=x86_64
fi
