#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Build flutter app to generate flutter repository dashboard.

pushd repo_dashboard > /dev/null
set -e
rm -rf build
flutter pub get
flutter config --enable-web
flutter build web --web-renderer=canvaskit --release
rm -rf ../app_dart/build/web/repository
cp -r build/web/ ../app_dart/build/web/repository
flutter clean
popd > /dev/null
