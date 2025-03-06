#!/usr/bin/env bash
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

# Runner for flutter tests. It expects a single parameter with the full
# path to the flutter project where tests will be run.

set -ex

echo "Running flutter tests from $1"
pushd "$1" > /dev/null

flutter packages get
flutter analyze --no-fatal-infos
dart format --set-exit-if-changed .
flutter test --test-randomize-ordering-seed=random --reporter expanded

popd > /dev/null
