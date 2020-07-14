// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Wrapper function for golden tests in Cocoon.
///
/// Ensures tests are only run on linux for consistency, and golden files are
/// stored in a goldens directory that is separate from the code.
Future<void> expectGoldenMatches(
  dynamic actual,
  String goldenFileKey, {
  String reason,
  dynamic skip, // true or a String
}) {
  if (!Platform.isLinux) {
    // No-op as all golden tests for Cocoon only run on Linux.
    return null;
  }
  final String goldenPath = 'goldens/' + goldenFileKey;
  return expectLater(actual, matchesGoldenFile(goldenPath), reason: reason, skip: skip);
}
