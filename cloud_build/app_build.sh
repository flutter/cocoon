#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Build old angular dart app to generate flutter benchmark dashboard.

pushd app > /dev/null
rm -rf build
flutter pub get
flutter pub run build_runner build --release --output build --delete-conflicting-outputs
cp -rn build/web ../app_dart/build/
flutter clean
popd > /dev/null