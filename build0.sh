#!/bin/bash

cd app
rm -rf build
flutter pub get
flutter pub run build_runner build --release --output build --delete-conflicting-outputs
cp -rn build/web ../app_dart/build/
