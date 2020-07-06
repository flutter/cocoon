#!/bin/bash

cd app_flutter
rm -rf build
flutter build web --dart-define FLUTTER_WEB_USE_SKIA=true

