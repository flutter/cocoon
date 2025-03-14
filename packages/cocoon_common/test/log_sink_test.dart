// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/cocoon_common.dart';
import 'package:test/test.dart';

void main() {
  test('flush does nothing and completes after a microtask', () {
    final sink = _TestLogSink();
    expect(sink.captured, isEmpty);

    sink.log('Hello World');
    expect(sink.captured, hasLength(1));

    var done = false;
    unawaited(
      sink.flush().then((_) {
        done = true;
      }),
    );
    scheduleMicrotask(
      expectAsync0(() {
        expect(done, isTrue);
      }),
    );
  });

  test('logJson defaults to encoding to a pretty-printed JSON string', () {
    final sink = _TestLogSink();
    sink.logJson({
      'numbers': [1, 2, 3],
    });

    expect(sink.captured, [
      isA<Invocation>().having(
        (i) => i.positionalArguments,
        'positionalArguments',
        [
          ''
              '{\n'
              '  "numbers": [\n'
              '    1,\n'
              '    2,\n'
              '    3\n'
              '  ]\n'
              '}',
        ],
      ),
    ]);
  });
}

final class _TestLogSink with LogSink {
  // Avoids having to use mockito for such a simple test.
  final captured = <Invocation>[];

  @override
  void log(
    String message, {
    Severity severity = Severity.info,
    Object? error,
    StackTrace? trace,
  }) {
    captured.add(Invocation.method(#log, [message], {}));
  }
}
