#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Deploy a new flutter dashboard version to google cloud.

cd app_dart
gcloud app deploy --project flutter-dashboard --version "version-$1" --no-promote --no-stop-previous-version
