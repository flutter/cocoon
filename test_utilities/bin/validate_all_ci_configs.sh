#!/bin/bash
# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# 

set -euxo pipefail

echo "Running config tests for all repos"
pushd app_dart > /dev/null
flutter clean
dart pub get

dart run test integration_test/

popd > /dev/null
