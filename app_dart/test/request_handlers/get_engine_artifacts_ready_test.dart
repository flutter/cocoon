// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handlers/get_engine_artifacts_ready.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/utilities/mocks.mocks.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late MockFirestoreService mockFirestoreService;
  late RequestHandlerTester tester;
  late GetEngineArtifactsReady handler;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    config = FakeConfig()..firestoreService = mockFirestoreService;
    tester = RequestHandlerTester();
    handler = GetEngineArtifactsReady(config: config);
  });

  Future<Map<String, Object?>> decodeHandlerBody() async {
    final body = await tester.get(handler);
    return await utf8.decoder
            .bind(body.serialize() as Stream<List<int>>)
            .transform(json.decoder)
            .single
        as Map<String, Object?>;
  }

  test('returns a 400, "sha" is missing from query string', () async {
    await expectLater(
      tester.get(handler),
      throwsA(
        isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          'Missing query parameter: "sha"',
        ),
      ),
    );
  });

  test('returns a 404, "sha" is missing from database', () async {
    tester.request!.uri = tester.request!.uri.replace(
      queryParameters: {'sha': 'abc123'},
    );

    when(mockFirestoreService.getDocument(any)).thenAnswer((_) async {
      throw g.DetailedApiRequestError(404, 'Document not found');
    });

    await expectLater(tester.get(handler), completes);

    expect(tester.response.statusCode, HttpStatus.notFound);
  });

  test('returns a 500, unhandled exception', () async {
    tester.request!.uri = tester.request!.uri.replace(
      queryParameters: {'sha': 'abc123'},
    );

    when(mockFirestoreService.getDocument(any)).thenAnswer((_) async {
      throw g.DetailedApiRequestError(500, 'Who knows');
    });

    await expectLater(
      tester.get(handler),
      throwsA(isA<g.DetailedApiRequestError>()),
    );
  });

  test('returns "complete"', () async {
    tester.request!.uri = tester.request!.uri.replace(
      queryParameters: {'sha': 'abc123'},
    );

    when(mockFirestoreService.getDocument(any)).thenAnswer((_) async {
      return g.Document(
        fields: {
          'failed_count': g.Value(integerValue: '0'),
          'remaining': g.Value(integerValue: '0'),
        },
      );
    });

    await expectLater(tester.get(handler), completes);
    await expectLater(decodeHandlerBody(), completion({'status': 'complete'}));
  });

  test('returns "pending"', () async {
    tester.request!.uri = tester.request!.uri.replace(
      queryParameters: {'sha': 'abc123'},
    );

    when(mockFirestoreService.getDocument(any)).thenAnswer((_) async {
      return g.Document(
        fields: {
          'failed_count': g.Value(integerValue: '0'),
          'remaining': g.Value(integerValue: '1'),
        },
      );
    });

    await expectLater(tester.get(handler), completes);
    await expectLater(decodeHandlerBody(), completion({'status': 'pending'}));
  });

  test('returns "failed"', () async {
    tester.request!.uri = tester.request!.uri.replace(
      queryParameters: {'sha': 'abc123'},
    );

    when(mockFirestoreService.getDocument(any)).thenAnswer((_) async {
      return g.Document(
        fields: {
          'failed_count': g.Value(integerValue: '1'),
          'remaining': g.Value(integerValue: '1'),
        },
      );
    });

    await expectLater(tester.get(handler), completes);
    await expectLater(decodeHandlerBody(), completion({'status': 'failed'}));
  });
}
