// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:file/file.dart';
import 'package:glob/glob.dart';

import '../checks.dart';

/// Enforces that trailing spaces are not present in the codebase.
final class NoTrailingWhitespace extends Check {
  const NoTrailingWhitespace();

  @override
  Iterable<Glob> get include => [Glob('**/*')];

  /// Extensions, including the `.`, of binary file formats that are checked in.
  ///
  /// Intentionally non-exhaustive; if we add new extensions to the repository,
  /// the list can be expanded.
  static const _knownBinaryExtensions = {'.png'};

  static final _trailingWhitespace = RegExp(r'\s+$');

  @override
  Future<CheckResult> check(LogSink logger, File file) async {
    final extension = file.fileSystem.path.extension(file.path);
    if (_knownBinaryExtensions.contains(extension)) {
      return CheckResult.passed;
    }

    final problems = <String>[];
    final lines = file.readAsLinesSync();
    for (final (line, contents) in lines.indexed) {
      if (_trailingWhitespace.hasMatch(contents)) {
        problems.add('${line + 1}: trailing whitespace');
      }
    }

    // Ensure the last line is not blank.
    if (lines.isNotEmpty && lines.last.isEmpty) {
      problems.add('${lines.length}: trailing blank line');
    }

    if (problems.isNotEmpty) {
      logger.error(
        'Trailing spaces present on the following lines:\n'
        '${problems.join('\n')}',
      );
      return CheckResult.failed;
    }
    return CheckResult.passed;
  }
}
