// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/helpers.dart';
import 'package:cocoon_server/logging.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('LoggingHandler', () {
    test('Calls the delegate', () async {
      bool called = false;
      final loggingHandler = LoggingHandler((request) async {
        called = true;
        return Response.ok('Delegate called with: ${request.requestedUri}');
      });

      final response = await loggingHandler.handle(Request('get', Uri.parse('http://localhost/foo/bar')));

      expect(called, isTrue);
      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'Delegate called with: http://localhost/foo/bar');
    });

    test('Logs errors from the delegate and rethrows the exception', () async {
      final loggingHandler = LoggingHandler((request) async {
        throw StateError('Some random error');
      });

      final logRecords = <LogRecord>[];
      final logSubscription = log.onRecord.listen((record) {
        logRecords.add(record);
      });

      Object? caughtError;
      try {
        await loggingHandler.handle(Request('get', Uri.parse('http://localhost/foo/bar')));
      } catch (error) {
        caughtError = error;
      }
      await logSubscription.cancel();

      expect(caughtError, isA<StateError>());
      expect(caughtError.toString(), 'Bad state: Some random error');

      expect(logRecords, hasLength(1));
      final logRecord = logRecords.single;
      expect(logRecord.message, 'Uncaught exception in HTTP handler');
      expect(logRecord.error, same(caughtError));
      expect(logRecord.stackTrace, isNotNull);
    });
  });
}
