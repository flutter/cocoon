#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fetches corresponding dart sdk from CIPD for different platforms, builds
# an executable binary of device_doctor to `build` folder.
#
# This currently supports linux and mac.

set -e

command -v cipd > /dev/null || {
  echo "Please install CIPD (available from depot_tools) and add to path first.";
  exit -1;
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
OS="`uname`"

echo ########### Ensure file ###########
cat $DIR/ensure_file
echo ###################################


cipd ensure -ensure-file $DIR/ensure_file -root $DIR

pushd $DIR/..

if [[ -d "build" ]]; then
  echo "Please remove the build directory before proceeding"
  exit -1
fi

mkdir -p build
pwd
ls tool
tool/bin/dart pub get
tool/bin/dart compile exe bin/main.dart -o build/device_doctor

cp -f LICENSE build/

if [[ $OS == "Darwin" ]]; then
  mkdir -p build/tool
  cp -rf tool/infra-dialog build/tool/
fi

popd
