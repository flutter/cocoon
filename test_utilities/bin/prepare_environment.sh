#!/bin/bash
# Copyright 2019 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# List of commands to be run once per PR before running dart and flutter
# tests.

set -e
pub global activate tuneup
flutter channel beta
flutter upgrade

