#!/bin/bash
# Copyright 2019 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runner for flutter tests. It expects a single parameter with the full
# path to the flutter project where tests will be run.

set -e

echo "Running flutter tests from $1"
pushd $1 > /dev/null

flutter packages get
# Remove the " || true" portion when https://github.com/flutter/flutter/issues/44370
# is fixed.
flutter analyze || true
flutter config --enable-web
flutter build web
flutter test

popd > /dev/null

