#!/bin/bash

cd app_flutter
rm -rf build
flutter pub get
flutter config --enable-web
flutter build web --dart-define FLUTTER_WEB_USE_SKIA=true
cd ../app_dart
rm -rf build
cp -r ../app_flutter/build build
