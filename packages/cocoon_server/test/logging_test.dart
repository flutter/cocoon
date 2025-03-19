// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:cocoon_server/src/logging.dart';
import 'package:logging/logging.dart' as pkg_logging;
import 'package:test/test.dart';

void main() {
  late List<pkg_logging.LogRecord> logs;

  setUp(() {
    logs = [];
    pkg_logging.Logger.root.onRecord.listen(logs.add);
  });

  group('log2 maps Severity -> Level', () {
    const expected = {
      Severity.unknown: pkg_logging.Level.FINE,
      Severity.debug: pkg_logging.Level.FINE,
      Severity.info: pkg_logging.Level.INFO,
      Severity.notice: pkg_logging.Level.INFO,
      Severity.warning: pkg_logging.Level.WARNING,
      Severity.error: pkg_logging.Level.SEVERE,
      Severity.critical: pkg_logging.Level.SEVERE,
      Severity.alert: pkg_logging.Level.SEVERE,
      Severity.emergency: pkg_logging.Level.SEVERE,
    };

    for (final MapEntry(key: severity, value: level) in expected.entries) {
      test('$severity -> $level', () {
        log.log('test', severity: Severity.unknown);

        expect(logs, [
          isA<pkg_logging.LogRecord>().having(
            (e) => e.level,
            'level',
            pkg_logging.Level.FINE,
          ),
        ]);
      });
    }
  });

  test('includes message', () {
    log.log('hello world');

    expect(logs, [
      isA<pkg_logging.LogRecord>().having(
        (e) => e.message,
        'message',
        'hello world',
      ),
    ]);
  });

  test('includes error', () {
    final error = StateError('Example error');
    log.log('with error', error: error);

    expect(logs, [
      isA<pkg_logging.LogRecord>().having((e) => e.error, 'error', same(error)),
    ]);
  });

  test('includes stack trace', () {
    final trace = StackTrace.current;
    log.log('with error', trace: trace);

    expect(logs, [
      isA<pkg_logging.LogRecord>().having(
        (e) => e.stackTrace,
        'stackTrace',
        same(trace),
      ),
    ]);
  });
}
