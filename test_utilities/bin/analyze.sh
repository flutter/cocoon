#!/usr/bin/env bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# General flutter/cocoon repo static analysis.

set -ex

dir=$(dirname $0)

pushd $dir/../../analyze > /dev/null
dart pub get
dart --enable-asserts analyze.dart

popd > /dev/null
