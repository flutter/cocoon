#!/bin/bash
# Copyright 2019 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

pushd $1 > /dev/null

# agent doesn't use build_runner as of this writing.
if grep -lq "build_runner" pubspec.yaml; then
  pub run build_runner build --delete-conflicting-outputs
fi

# See https://github.com/dart-lang/sdk/issues/25551 for why this is necessary.

pub global run tuneup check

popd > /dev/null
