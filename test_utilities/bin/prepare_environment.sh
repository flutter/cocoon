#!/bin/bash
# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# List of commands to be run once per PR before running dart and flutter
# tests.

set -ex

dart pub global activate tuneup
flutter channel master
flutter upgrade
