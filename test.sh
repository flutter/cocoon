#!/usr/bin/env bash
# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

if [[ "$1" == "app" ]]; then
  echo "Testing the web is not yet supported"
  exit 0
fi

pushd $1 > /dev/null

pub run test --test-randomize-ordering-seed=random

popd > /dev/null
