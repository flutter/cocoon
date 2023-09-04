// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcs_cleaner/exceptions.dart';
import 'package:process/process.dart';

class Git {
  const Git({
    required this.path,
    required this.pm,
  });

  /// Path of the framework repo.
  final String path;

  /// Current process manager to use.
  final ProcessManager pm;

  /// Generates a map of commits pointing to their associated tag.
  ///
  /// If a commit does not exist in the map, it indicates the commit was never
  /// shipped to users.
  Future<Map<String, String>> tags() async {
    final result = await _run(<String>['show-ref', '--tags']);
    final Map<String, String> commitTags = <String, String>{};
    for (final line in result.split('\n')) {
      final List<String> parts = line.split(' ');
      final sha = parts.first;
      final tag = parts[1];
      // A commit with duplicate tags isn't relevant as it's going to be retained.
      commitTags[sha] = tag;
    }
    return commitTags;
  }

  /// Returns the engine commit associated with [frameworkCommit].
  ///
  /// The framework pins its engine dependencie in `bin/internal/engine.version`.
  Future<String?> lookupEngineCommit(String frameworkCommit) async {
    try {
      final result = await _run(<String>['show', '$frameworkCommit:bin/internal/engine.version']);
      return result;
    } on GitException {
      // Tags circa 2015 will not have bin/internal/engine.version
      return null;
    }
  }

  /// Returns the [DateTime] when a commit was pushed.
  Future<DateTime?> lookupCommitTime(String sha) async {
    try {
      // %cs is committer date in YYYY-MM-DD
      final result = await _run(<String>[
        'show',
        sha,
        '--pretty=%cs',
        '--no-patch',
        '--no-notes',
      ]);
      return DateTime.tryParse(result.trim());
    } on GitException {
      return null;
    }
  }

  /// Runs the given git command in the existing checkout path.
  Future<String> _run(List<String> command) async {
    final result = await pm.run(
      <String>['git', ...command],
      workingDirectory: path,
    );
    if (result.exitCode != 0) {
      throw GitException(
        'git $command failed with exit code ${result.exitCode}\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }

    final stdout = result.stdout as String;
    return stdout.trim();
  }
}
