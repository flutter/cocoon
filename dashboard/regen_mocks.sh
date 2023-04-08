#!/bin/bash
# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

dart pub get

echo "(Re)generating mocks."

dart run build_runner build --delete-conflicting-outputs
