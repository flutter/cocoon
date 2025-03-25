// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/scheduler/process_check_run_result.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late _FakeHttpResponse response;

  setUp(() {
    response = _FakeHttpResponse();
  });

  test('.success', () {
    const ProcessCheckRunResult.success().writeResponse(response);

    expect(response.statusCode, HttpStatus.ok);
    expect(response.reasonPhrase, isEmpty);
  });

  test('.userError', () {
    const ProcessCheckRunResult.userError('Do better').writeResponse(response);

    expect(response.statusCode, HttpStatus.badRequest);
    expect(response.reasonPhrase, 'Do better');
  });

  test('.missingEntity', () {
    const ProcessCheckRunResult.missingEntity(
      'No hot dog',
    ).writeResponse(response);

    expect(response.statusCode, HttpStatus.notFound);
    expect(response.reasonPhrase, 'No hot dog');
  });

  test('.internalError', () {
    ProcessCheckRunResult.internalError(
      'Did a really bad thing',
      error: StateError('Bad thing detected'),
      stackTrace: StackTrace.current,
    ).writeResponse(response);

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(response.reasonPhrase, 'Did a really bad thing');

    expect(
      log,
      bufferedLoggerOf(
        equals([
          logThat(
            message: equals('Did a really bad thing'),
            severity: atLeastError,
            error: isA<StateError>(),
            trace: isNotNull,
          ),
        ]),
      ),
    );
  });
}

final class _FakeHttpResponse extends Fake implements HttpResponse {
  @override
  int statusCode = HttpStatus.ok;

  @override
  String reasonPhrase = '';
}
