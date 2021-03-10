// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

const double _kGoldenDiffTolerance = 0.005;

/// Wrapper function for golden tests in Cocoon.
///
/// Ensures tests are only run on linux for consistency, and golden files are
/// stored in a goldens directory that is separate from the code.
Future<void> expectGoldenMatches(
  dynamic actual,
  String goldenFileKey, {
  String reason,
  dynamic skip = false, // true or a String
}) {
  final String goldenPath = path.join('goldens', goldenFileKey);
  goldenFileComparator = CocoonFileComparator(Uri.parse(goldenPath));
  return expectLater(actual, matchesGoldenFile(goldenPath), reason: reason, skip: skip || !Platform.isLinux);
}

class CocoonFileComparator extends LocalFileComparator {
  CocoonFileComparator(Uri testFile) : super(testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (!result.passed && result.diffPercent > _kGoldenDiffTolerance) {
      final String error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return result.passed || result.diffPercent <= _kGoldenDiffTolerance;
  }
}
