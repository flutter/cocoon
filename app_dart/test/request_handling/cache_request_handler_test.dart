// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/cache_request_handler.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/service/cache_service.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('CacheRequestHandler', () {
    FakeConfig config;
    RequestHandlerTester tester;

    CacheService cache;

    const String testHttpPath = '/cache_request_handler_test';

    setUp(() async {
      config = FakeConfig();
      tester = RequestHandlerTester(
          request: FakeHttpRequest(
        path: testHttpPath,
      ));

      cache = CacheService(inMemory: true);
    });

    test('returns response from cache', () async {
      final RequestHandler<Body> fallbackHandlerMock = MockRequestHandler();

      const String responseKey = '$testHttpPath:';
      const String expectedResponse = 'Hello, World!';
      final Body expectedBody = Body.forString(expectedResponse);

      final Uint8List serializedBody = await expectedBody.serialize().first;

      await cache.set(CacheRequestHandler.responseSubcacheName, responseKey,
          serializedBody);

      final CacheRequestHandler<Body> cacheRequestHandler =
          CacheRequestHandler<Body>(
              delegate: fallbackHandlerMock, cache: cache, config: config);

      final Body body = await tester.get(cacheRequestHandler);
      final Uint8List response = await body.serialize().first;
      final String strResponse = utf8.decode(response);
      expect(strResponse, expectedResponse);
    });

    test('fallback handler called when cache is empty', () async {
      final RequestHandler<Body> fallbackHandlerMock = MockRequestHandler();
      // ignore: invalid_use_of_protected_member
      when(fallbackHandlerMock.get())
          .thenAnswer((_) => Future<Body>.value(Body.forString('hello!')));

      final CacheRequestHandler<Body> cacheRequestHandler =
          CacheRequestHandler<Body>(
              delegate: fallbackHandlerMock, cache: cache, config: config);

      // ignore: invalid_use_of_protected_member
      verifyNever(fallbackHandlerMock.get());

      await tester.get(cacheRequestHandler);

      // ignore: invalid_use_of_protected_member
      verify(fallbackHandlerMock.get()).called(1);
    });

    test('flush cache param calls purge', () async {
      tester = RequestHandlerTester(
          request: FakeHttpRequest(
              path: testHttpPath,
              queryParametersValue: <String, String>{
            CacheRequestHandler.flushCacheQueryParam: 'true',
          }));
      final RequestHandler<Body> fallbackHandlerMock = MockRequestHandler();
      // ignore: invalid_use_of_protected_member
      when(fallbackHandlerMock.get())
          .thenAnswer((Invocation invocation) async => Body.empty);

      const String responseKey = '$testHttpPath:';
      const String expectedResponse = 'Hello, World!';
      final Body expectedBody = Body.forString(expectedResponse);

      final Uint8List serializedBody = await expectedBody.serialize().first;

      // set an existing response for the request
      await cache.set(CacheRequestHandler.responseSubcacheName, responseKey,
          serializedBody);

      final CacheRequestHandler<Body> cacheRequestHandler =
          CacheRequestHandler<Body>(
              delegate: fallbackHandlerMock, cache: cache, config: config);

      // ignore: invalid_use_of_protected_member
      verifyNever(fallbackHandlerMock.get());

      final Body body = await tester.get(cacheRequestHandler);
      final Uint8List response = await body.serialize().first;
      final String strResponse = utf8.decode(response);

      // the mock should update the cache to have null -> empty string
      expect(strResponse, '');

      // ignore: invalid_use_of_protected_member
      verify(fallbackHandlerMock.get()).called(1);
    });
  });
}

// ignore: must_be_immutable
class MockRequestHandler extends Mock implements RequestHandler<Body> {}
