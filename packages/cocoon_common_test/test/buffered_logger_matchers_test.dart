// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:test/test.dart';

void main() {
  test('bufferedLoggerOf', () {
    final logger = BufferedLogger();
    logger.log(
      'Hello World',
      severity: Severity.warning,
      error: StateError('Error'),
      trace: StackTrace.current,
    );

    expect(
      logger,
      bufferedLoggerOf(contains(logThat(message: contains('Hello')))),
    );
  });

  group('logThat matches', () {
    late final LogRecord record;

    setUpAll(() {
      final logger = BufferedLogger();
      logger.log(
        'message',
        severity: Severity.warning,
        error: StateError('Error'),
        trace: StackTrace.current,
      );
      record = logger.messages.single;
    });

    test('message', () {
      expect(record, logThat(message: equals('message')));
    });

    test('severity', () {
      expect(
        record,
        logThat(message: anything, severity: equals(Severity.warning)),
      );
    });

    test('error', () {
      expect(
        record,
        logThat(
          message: anything,
          error: isA<StateError>().having((e) => e.message, 'message', 'Error'),
        ),
      );
    });

    test('trace', () {
      expect(record, logThat(message: anything, trace: equals(record.trace)));
    });

    test('recordedAt', () {
      expect(
        record,
        logThat(message: anything, recordedAt: equals(record.recordedAt)),
      );
    });
  });
}
