// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/common/firestore_extensions.dart';
import 'package:cocoon_service/src/model/firestore/ci_staging.dart';
import 'package:cocoon_service/src/request_handlers/get_engine_artifacts_ready.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_firestore_service.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestore;
  late RequestHandlerTester tester;
  late GetEngineArtifactsReady handler;

  setUp(() {
    firestore = FakeFirestoreService();
    tester = RequestHandlerTester();
    handler = GetEngineArtifactsReady(
      config: FakeConfig(),
      firestore: firestore,
    );
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

    await expectLater(tester.get(handler), completes);

    expect(tester.response.statusCode, HttpStatus.notFound);
  });

  test('returns "complete"', () async {
    tester.request!.uri = tester.request!.uri.replace(
      queryParameters: {'sha': 'abc123'},
    );

    firestore.putDocument(
      g.Document(
        fields: {'failed_count': 0.toValue(), 'remaining': 0.toValue()},
        name: firestore.resolveDocumentName(
          CiStaging.metadata.collectionId,
          CiStaging.documentIdFor(
            slug: Config.flutterSlug,
            sha: 'abc123',
            stage: CiStage.fusionEngineBuild,
          ).documentId,
        ),
      ),
    );

    await expectLater(tester.get(handler), completes);
    await expectLater(decodeHandlerBody(), completion({'status': 'complete'}));
  });

  test('returns "pending"', () async {
    tester.request!.uri = tester.request!.uri.replace(
      queryParameters: {'sha': 'abc123'},
    );

    firestore.putDocument(
      g.Document(
        fields: {'failed_count': 0.toValue(), 'remaining': 1.toValue()},
        name: firestore.resolveDocumentName(
          CiStaging.metadata.collectionId,
          CiStaging.documentIdFor(
            slug: Config.flutterSlug,
            sha: 'abc123',
            stage: CiStage.fusionEngineBuild,
          ).documentId,
        ),
      ),
    );

    await expectLater(tester.get(handler), completes);
    await expectLater(decodeHandlerBody(), completion({'status': 'pending'}));
  });

  test('returns "failed"', () async {
    tester.request!.uri = tester.request!.uri.replace(
      queryParameters: {'sha': 'abc123'},
    );

    firestore.putDocument(
      g.Document(
        fields: {'failed_count': 1.toValue(), 'remaining': 1.toValue()},
        name: firestore.resolveDocumentName(
          CiStaging.metadata.collectionId,
          CiStaging.documentIdFor(
            slug: Config.flutterSlug,
            sha: 'abc123',
            stage: CiStage.fusionEngineBuild,
          ).documentId,
        ),
      ),
    );

    await expectLater(tester.get(handler), completes);
    await expectLater(decodeHandlerBody(), completion({'status': 'failed'}));
  });
}
