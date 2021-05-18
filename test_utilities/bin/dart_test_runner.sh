#!/bin/bash
# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runner for dart tests. It expects a single parameter with the full
# path to the start folder where tests will be run.

set -ex

# Build and analyze
echo "Running tests from $1"
pushd "$1" > /dev/null
flutter clean
flutter channel stable
dart pub get

echo "############# files that require formatting ###########"
dartfmt --dry-run --line-length=120 --set-exit-if-changed .
echo "#######################################################"

# agent doesn't use build_runner as of this writing.
if grep -lq "build_runner" pubspec.yaml; then
  echo "############# build ###########"
  dart run build_runner build --delete-conflicting-outputs
  echo "###############################"
fi

# See https://github.com/dart-lang/sdk/issues/25551 for why this is necessary.
dart pub global run tuneup check
# Only try tests if test folder exist.
if [ -d 'test' ]; then
  echo "############# tests ###########"
  dart test --test-randomize-ordering-seed=random --reporter expanded
  echo "###############################"
fi

INTEGRATION_TEST_DIR="$PWD/integration_test/"
# Only try tests if integration test folder exist.
if [ -d "$INTEGRATION_TEST_DIR" ]; then
  echo "###### integration tests ######"
  dart test --test-randomize-ordering-seed=random --reporter expanded "$INTEGRATION_TEST_DIR"
  echo "###############################"
fi

popd > /dev/null
