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

# build Trial
git clone https://github.com/gedaiu/trial.git
cd trial
dub build :runner
cd ..

# run unit tests
./trial/trial --compiler=$DC

# run a build for unit-threaded
dub --root=test/unit-threaded --compiler=$DC --arch=x86_64

# run a build for vibe-d 0.8
if [[ ${DC=dmd} = dmd ]]; then
  dub -v --root=test/vibe-0.8 --compiler=$DC --arch=x86_64
fi
