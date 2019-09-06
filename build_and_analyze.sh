#!/bin/bash
# Copyright 2019 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# See https://github.com/dart-lang/sdk/issues/25551 for why this is necessary.

pushd $1 > /dev/null

if [[ grep -q "build_runner" pubspec.yaml ]]; then
  pub run build_runner build --delete-conflicting-outputs
fi

analysis_output="$(dartanalyzer --options analysis_options.yaml . | grep -Ev ".(g|pb).dart")"

line_count=($(echo "$analysis_output" | wc -l))
if [[ $line_count -ne 2 ]]; then
  echo "$analysis_output"
  exit -1
fi

echo "Analysis passed!"

popd > /dev/null
