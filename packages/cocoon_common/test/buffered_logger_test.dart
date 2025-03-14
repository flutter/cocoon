// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:test/test.dart';

void main() {
  test('uses the provided DateTime for recordedAt', () {
    final moment = DateTime.now();
    final logger = BufferedLogger.forTesting(now: () => moment);
    logger.log('Hello World');

    expect(
      logger,
      bufferedLoggerOf(
        equals([
          logThat(message: equals('Hello World'), recordedAt: equals(moment)),
        ]),
      ),
    );
  });

  test('clears the logger', () {
    final logger = BufferedLogger();

    logger.log('Hello World');
    expect(logger, bufferedLoggerOf(hasLength(1)));

    logger.clear();
    expect(logger, bufferedLoggerOf(isEmpty));
  });

  test('stores a JSON message', () {
    final logger = BufferedLogger();

    logger.logJson({
      'numbers': [1, 2, 3],
    });
    expect(
      logger,
      bufferedLoggerOf(
        equals([
          isA<JsonLogRecord>().having((r) => r.message, 'message', {
            'numbers': [1, 2, 3],
          }),
        ]),
      ),
    );
  });
}
