#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

# bq \
#   --project_id=flutter-dashboard \
#   load \
#   --replace=true \
#   --source_format=NEWLINE_DELIMITED_JSON \
#   --autodetect cirrus.Build \
#   ./tmp/build.json


bq \
  --project_id=flutter-dashboard \
  load \
  --replace=true \
  --source_format=NEWLINE_DELIMITED_JSON \
  --autodetect \
  cirrus.Task \
  ./tmp/task.json
