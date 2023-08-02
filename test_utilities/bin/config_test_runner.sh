#!/usr/bin/env bash
# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runner for cocoon scheduler config tests. It expects a single parameter with
# the full path to the config file under test.

set -ex

# Build and analyze
echo "Running config tests on $1"
pushd app_dart > /dev/null
flutter clean
pub get

dart bin/validate_scheduler_config.dart "$1"

popd > /dev/null
