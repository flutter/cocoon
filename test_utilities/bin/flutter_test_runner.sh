#!/bin/bash
# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is used by
# https://github.com/flutter/tests/tree/master/registry/flutter_cocoon.test
# to run the tests of certain packages in this repository as a presubmit
# for the flutter/flutter repository.
# Changes to this file (and any tests in this repository) are only honored
# after the commit hash in the "flutter_cocoon.test" mentioned above has
# been updated.
# Remember to also update the Windows version (flutter_test_runner.bat) when
# changing this file.

# Runner for flutter tests. It expects a single parameter with the full
# path to the flutter project where tests will be run.

set -e

echo "Running flutter tests from $1"
pushd $1 > /dev/null

flutter packages get
flutter analyze
dartfmt --line-length=120 --set-exit-if-changed --dry-run lib/ test/
flutter test --test-randomize-ordering-seed=random

popd > /dev/null

