// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/log_chunk.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/request_handlers/get_log.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

void main() {
  group('GetLog', () {
    FakeConfig config;
    FakeDatastoreDB db;
    GetLog handler;

    final List<LogChunk> expectedLogChunks = <LogChunk>[
      LogChunk(createTimestamp: 12345, data: <int>[1, 2, 3, 4, 5, 6])
    ];

    setUp(() {
      config = FakeConfig();
      db = FakeDatastoreDB();
      handler = GetLog(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: () => DatastoreService(db: db),
      );
    });

    test('owner key param required', () async {
      final ApiRequestHandlerTester tester = ApiRequestHandlerTester();

      expect(
          await tester.get(handler),
          throwsA(const TypeMatcher<BadRequestException>().having(
              (BadRequestException e) => e.message,
              'error message',
              contains('Missing required query parameter'))));
    });

    test('bad request if owner key does not exist', () {
      final FakeHttpRequest request = FakeHttpRequest(
          uri: Uri(
        path: '/public/get-log',
        queryParameters: <String, String>{
          GetLog.ownerKeyParam: config.db.emptyKey.id.toString(),
          GetLog.downloadParam: 'true',
        },
      ));
      final ApiRequestHandlerTester tester =
          ApiRequestHandlerTester(request: request);

      expect(
          () => tester.get(handler),
          throwsA(const TypeMatcher<BadRequestException>().having(
              (BadRequestException e) => e.message,
              'error message',
              contains('Invalid owner key. Owner entity does not exist.'))));
    });

    test('successful log request', () async {});

    test('download=true sends content disposition header', () async {
      final FakeHttpRequest request = FakeHttpRequest(
          uri: Uri(
        path: '/public/get-log',
        queryParameters: <String, String>{
          GetLog.ownerKeyParam: 'owner123',
          GetLog.downloadParam: 'true',
        },
      ));
      final ApiRequestHandlerTester tester =
          ApiRequestHandlerTester(request: request);

      db.addOnQuery<LogChunk>(
          (Iterable<LogChunk> logChunks) => expectedLogChunks);

      await tester.get(handler);

      expect(request.response.headers.value('Content-Disposition'), '');
    });

    test('download!=true does not send for download', () async {});
  });
}
