// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_common/core_extensions.dart';
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/scheduler/process_check_run_result.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  test('.success', () async {
    final response = const ProcessCheckRunResult.success().toResponse();

    expect(response.statusCode, HttpStatus.ok);
    await expectLater(response.body.collectBytes(), completion(isEmpty));
  });

  test('.userError', () async {
    final response =
        const ProcessCheckRunResult.userError('Do better').toResponse();

    expect(response.statusCode, HttpStatus.badRequest);
    await expectLater(
      response.body.collectBytes(),
      completion(decodedAsJsonMatches({'error': 'Do better'})),
    );
  });

  test('.missingEntity', () async {
    final response =
        const ProcessCheckRunResult.missingEntity('No hot dog').toResponse();

    expect(response.statusCode, HttpStatus.notFound);
    await expectLater(
      response.body.collectBytes(),
      completion(decodedAsJsonMatches({'error': 'No hot dog'})),
    );
  });

  test('.internalError', () async {
    final response =
        ProcessCheckRunResult.unexpectedError(
          'Did a really bad thing',
          error: StateError('Bad thing detected'),
          stackTrace: StackTrace.current,
        ).toResponse();

    expect(response.statusCode, HttpStatus.internalServerError);
    await expectLater(
      response.body.collectBytes(),
      completion(decodedAsJsonMatches({'error': 'Did a really bad thing'})),
    );

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
