// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/service/scheduler/process_check_run_result.dart';
import 'package:test/test.dart';

import '../../src/request_handling/body_decoder_extension.dart';

void main() {
  useTestLoggerPerTest();

  test('.success', () {
    expect(
      const ProcessCheckRunResult.success().toResponse(),
      isA<Response>()
          .having((r) => r.statusCode, 'statusCode', HttpStatus.ok)
          .having((r) => r.body, 'body', same(const Body.empty())),
    );
  });

  test('.userError', () {
    expect(
      const ProcessCheckRunResult.userError('Do better').toResponse(),
      isA<Response>()
          .having((r) => r.statusCode, 'statusCode', HttpStatus.badRequest)
          .having(
            (r) => r.body.readAsJson(),
            'body.readAsJson()',
            completion({'error': 'Do better'}),
          ),
    );
  });

  test('.missingEntity', () {
    expect(
      const ProcessCheckRunResult.missingEntity('No hot dog').toResponse(),
      isA<Response>()
          .having((r) => r.statusCode, 'statusCode', HttpStatus.notFound)
          .having(
            (r) => r.body.readAsJson(),
            'body.readAsJson()',
            completion({'error': 'No hot dog'}),
          ),
    );
  });

  test('.unexpectedError', () {
    expect(
      ProcessCheckRunResult.unexpectedError(
        'Did a really bad thing',
        error: StateError('Bad thing detected'),
        stackTrace: StackTrace.current,
      ).toResponse(),
      isA<Response>()
          .having(
            (r) => r.statusCode,
            'statusCode',
            HttpStatus.internalServerError,
          )
          .having(
            (r) => r.body.readAsJson(),
            'body.readAsJson()',
            completion({'error': 'Did a really bad thing'}),
          ),
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
