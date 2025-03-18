#!/usr/bin/env bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -ex

dir=$(dirname $0)

pushd $dir/../../dev/code_health_check > /dev/null
dart pub get
dart run bin/check.dart

popd > /dev/null

