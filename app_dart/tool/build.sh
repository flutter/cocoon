#!/usr/bin/env bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fetches corresponding dart sdk from CIPD for different platforms, builds
# an executable binary of bin/generate_jspb.dart to `build` folder.
#
# This only supports Linux, but can be generalized for Windows and Mac.

set -e

command -v cipd > /dev/null || {
  echo "Please install CIPD (available from depot_tools) and add to path first.";
  exit -1;
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

cipd ensure -ensure-file $DIR/ensure_file -root $DIR

pushd $DIR/..

if [[ -d "build" ]]; then
  echo "Please remove the build directory before proceeding"
  exit -1
fi

mkdir -p build
tool/dart-sdk/bin/dart pub get
tool/dart-sdk/bin/dart compile exe bin/generate_jspb.dart -o build/ci_yaml_jspb

# Definitions related to uploading packages to CIPD
echo "# This file was auto-generated by Cocoon
# For more information, see https://github.com/flutter/cocoon
#
# This file defines information related to CIPD for distribution of generate_jspb.
package: flutter/ci_yaml/generate_jspb/linux-amd64
description: Binary to convert a ci.yaml to a JSON proto, which is readable by flutter.googlesource.com/infra.
data:
  - file: ci_yaml_jspb
" > build/cipd.yaml

popd
