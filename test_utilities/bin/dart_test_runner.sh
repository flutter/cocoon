#!/bin/bash
# Copyright 2019 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runner for dart tests. It expects a single parameter with the full
# path to the start folder where tests will be run.

set -e

# Build and analize
echo "Running tests from $1"
pushd $1 > /dev/null
pub get

echo "############# files that require formatting ###########"
dartfmt -n --set-exit-if-changed .
echo "#######################################################"

# agent doesn't use build_runner as of this writing.
if grep -lq "build_runner" pubspec.yaml; then
  pub run build_runner build --delete-conflicting-outputs
fi

dart --version

# See https://github.com/dart-lang/sdk/issues/25551 for why this is necessary.
pub global run tuneup check
pub run test --test-randomize-ordering-seed=random

popd > /dev/null
