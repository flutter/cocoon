// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:github/github.dart';
import 'package:test/test.dart';

/// Validates the local tree has no outstanding changes.
void expectNoDiff(String path) {
  final gitResult = Process.runSync('git', <String>[
    'diff',
    '--exit-code',
    path,
  ]);
  if (gitResult.exitCode != 0) {
    final gitDiffOutput = Process.runSync('git', <String>['diff', path]);
    fail(
      'The working tree has a diff. Ensure changes are checked in:\n${gitDiffOutput.stdout}',
    );
  }
}

/// Wrapper class to make it easy to add new repos + branches to the validation suite.
class SupportedConfig {
  SupportedConfig(this.slug, [this.branch = 'main']);

  final RepositorySlug slug;
  final String branch;

  @override
  String toString() => '${slug.fullName}/$branch';
}
