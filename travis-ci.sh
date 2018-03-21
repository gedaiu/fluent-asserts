#!/bin/bash

set -e -x -o pipefail

export DC=dmd

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
dub --root=test/unit-threaded --compiler=$DC --arch=x86_64

# run a build for DisableSourceResult
dub --root=test/disabledSourceResult --compiler=$DC --arch=x86_64

# run a build for DisableMessageResult
dub --root=test/disabledMessageResult --compiler=$DC --arch=x86_64

# run a build for DisableDiffResult
dub --root=test/disabledDiffResult --compiler=$DC --arch=x86_64

dc_version=$("$DC" --version | perl -pe '($_)=/([0-9]+([.][0-9]+)+)/')

# run a build for vibe-d 0.8
if [[ ${DC=dmd} = dmd ]]; then
  if [[ "$dc_version" =~ ^("2.073.2"|"2.077.0"|"2.078.0"|"2.079.0")$ ]]; then
    dub --root=test/vibe-0.7 --compiler=$DC --arch=x86_64
  else
    echo "We don't compile vibe-d 0.8 with dmd" $dc_version
  fi
fi

# run a build for vibe-d 0.7
if [[ ${DC=dmd} = dmd ]]; then
  if [[ ${dc_version} = *"2.073"* ]]; then
    dub --root=test/vibe-0.7 --compiler=$DC --arch=x86_64
  else
    echo "We don't compile vibe-d 0.7 with dmd" $dc_version
  fi
fi