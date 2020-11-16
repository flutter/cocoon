#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Build flutter app to generate flutter repository dashboard.

pushd repository > /dev/null
set -e
rm -rf build
flutter doctor
flutter pub get
flutter config --enable-web
flutter build web --dart-define FLUTTER_WEB_USE_SKIA=true
rm -rf ../app_dart/build/repository
cp -r build ../app_dart/build/repository
flutter clean
popd > /dev/null
