#!/usr/bin/env bash
# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fetches corresponding dart sdk from CIPD for different platforms, builds
# an executable binary of codesign to `build` folder.
#
# This build script will be triggered on Mac code signing machines.

set -e

command -v cipd > /dev/null || {
  echo "Please install CIPD (available from depot_tools) and add to path first.";
  exit -1;
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
OS="`uname`"

cipd ensure -ensure-file $DIR/ensure_file -root $DIR

pushd $DIR/..

if [[ -d "build" ]]; then
  echo "Please remove the build directory before proceeding"
  exit -1
fi

mkdir -p build
tool/bin/dart pub get
tool/bin/dart compile exe bin/codesign.dart -o build/codesign

cp -f LICENSE build/

popd
