// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

/// Validates the local tree has no outstanding changes.
void expectNoDiff(String path) {
  final ProcessResult gitResult = Process.runSync('git', <String>['diff', '--exit-code', path]);
  if (gitResult.exitCode != 0) {
    final ProcessResult gitDiffOutput = Process.runSync('git', <String>['diff', path]);
    fail('The working tree has a diff. Ensure changes are checked in:\n${gitDiffOutput.stdout}');
  }
}
