// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:file/file.dart';
import 'package:glob/glob.dart';

import '../checks.dart';

/// Enforces that `FIXME` is not present in the codebase.
final class DoNotSubmitFixme extends Check {
  const DoNotSubmitFixme();

  @override
  Iterable<Glob> get include => [
    Glob('**/*Dockerfile*'),
    Glob('**/*.dart'),
    Glob('**/*.md'),
    Glob('**/*.sh'),
    Glob('**/*.yaml'),
  ];

  @override
  Future<CheckResult> check(LogSink logger, File file) async {
    final badLines = [
      for (final (line, contents) in file.readAsLinesSync().indexed)
        if (contents.contains('FIXME')) '${line + 1}: $contents',
    ];
    if (badLines.isNotEmpty) {
      logger.error(
        'FIXME present on the following lines:\n'
        '${badLines.join('\n')}',
      );
      return CheckResult.failed;
    }
    return CheckResult.passed;
  }
}
