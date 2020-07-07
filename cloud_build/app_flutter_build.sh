#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Build flutter app to generate flutter build dashboard.

cd app_flutter
rm -rf build
flutter pub get
flutter config --enable-web
flutter build web --dart-define FLUTTER_WEB_USE_SKIA=true
cd ../app_dart
rm -rf build
cp -r ../app_flutter/build build
