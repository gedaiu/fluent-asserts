#!/bin/bash

set -e -x -o pipefail

dub --root=test/unit-threaded

dub --root=test/disabledSourceResult
dub --root=test/disabledMessageResult
dub --root=test/disabledDiffResult