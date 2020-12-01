#!/bin/bash                                                                      
# Copyright 2020 The Flutter Authors. All rights reserved.                       
# Use of this source code is governed by a BSD-style license that can be         
# found in the LICENSE file.

set -e

command -v cipd > /dev/null || {
  echo "Please install CIPD (available from depot_tools) and add to path first.";
  exit -1;
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
OS="`uname`"

if [[ "{$OS}" == "Linux" || "{$OS}" == "Darwin" ]]; then
  cipd ensure -ensure-file $DIR/ensure_file -root $DIR
else
  # dart2native is not available in stable yet for windows.
  cipd ensure -ensure-file $DIR/ensure_file_windows -root $DIR
fi
pushd $DIR/..

if [[ -d "build" ]]; then
  echo "Please remove the build directory before proceeding"
  exit -1
fi

mkdir -p build
if [[ $OS == "Linux" || $OS == "Darwin" ]]; then
  tool/dart-sdk/bin/pub get
  tool/dart-sdk/bin/dart2native bin/main.dart -o build/device_doctor
else
  tool/dart-sdk/bin/pub.bat get
  tool/dart-sdk/bin/dart2native.bat bin/main.dart -o build/device_doctor.exe
fi
cp -f LICENSE build/
cp -f config.yaml build/

popd
