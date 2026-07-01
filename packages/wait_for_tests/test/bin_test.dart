// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:test/test.dart';

void main() {
  final binPath = Directory('bin').existsSync()
      ? 'bin/wait_for_tests.dart'
      : 'packages/wait_for_tests/bin/wait_for_tests.dart';

  test('prints usage when --help is passed', () async {
    final result = await Process.run('dart', [binPath, '--help']);
    expect(result.exitCode, equals(0));
    expect(result.stdout, contains('Usage: wait-for-tests [options]'));
    expect(result.stdout, contains('--sha'));
    expect(result.stdout, contains('--repo'));
  });

  test(
    'exits with code 1 and prints error when missing required sha and repo',
    () async {
      final result = await Process.run('dart', [binPath]);
      expect(result.exitCode, equals(1));
      expect(
        result.stderr,
        contains('Error: The commit "sha" parameter is required'),
      );
    },
  );

  test(
    'exits with code 1 and prints error when missing required repo',
    () async {
      final result = await Process.run('dart', [
        binPath,
        '--sha',
        'd100ca3882520e04129ff2a5c09372ecec3b3860',
      ]);
      expect(result.exitCode, equals(1));
      expect(
        result.stderr,
        contains('Error: The "repo" parameter is required'),
      );
    },
  );

  test(
    'exits with code 1 and prints error when wait-interval is not an integer',
    () async {
      final result = await Process.run('dart', [
        binPath,
        '--sha',
        'd100ca3882520e04129ff2a5c09372ecec3b3860',
        '--repo',
        'flutter/flutter',
        '--wait-interval',
        'abc',
      ]);
      expect(result.exitCode, equals(1));
      expect(
        result.stderr,
        contains('Error: "wait-interval" must be a valid integer. Got: abc'),
      );
    },
  );

  test(
    'exits with code 1 and prints error when sha is not a full 40-character hex string',
    () async {
      final result = await Process.run('dart', [
        binPath,
        '--sha',
        '3b77a01',
        '--repo',
        'flutter/flutter',
      ]);
      expect(result.exitCode, equals(1));
      expect(
        result.stderr,
        contains(
          'Error: The commit "sha" parameter must be a full 40-character hexadecimal SHA',
        ),
      );
    },
  );

  test(
    'exits with code 1 and prints error when repo is malformed (e.g. trailing slash)',
    () async {
      final result = await Process.run('dart', [
        binPath,
        '--sha',
        'd100ca3882520e04129ff2a5c09372ecec3b3860',
        '--repo',
        'flutter/',
      ]);
      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error: Malformed "repo" parameter'));
    },
  );

  test(
    'exits with code 1 and prints error when repo has too many slashes',
    () async {
      final result = await Process.run('dart', [
        binPath,
        '--sha',
        'd100ca3882520e04129ff2a5c09372ecec3b3860',
        '--repo',
        'flutter/packages/extra',
      ]);
      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error: Malformed "repo" parameter'));
    },
  );
}
