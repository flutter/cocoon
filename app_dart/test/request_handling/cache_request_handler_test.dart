// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/cache_request_handler.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_request_handler.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('CacheRequestHandler', () {
    late FakeConfig config;
    late RequestHandlerTester tester;

    late CacheService cache;

    const String testHttpPath = '/cache_request_handler_test';

    setUp(() async {
      config = FakeConfig();
      tester = RequestHandlerTester(
        request: FakeHttpRequest(
          path: testHttpPath,
        ),
      );

      cache = CacheService(inMemory: true);
    });

    test('returns response from cache', () async {
      const String responseKey = '$testHttpPath:';
      const String expectedResponse = 'Hello, World!';
      final Body expectedBody = Body.forString(expectedResponse);
      final FakeRequestHandler fallbackHandler = FakeRequestHandler(body: expectedBody, config: FakeConfig());

      final Uint8List? serializedBody = await expectedBody.serialize().first;

      await cache.set(CacheRequestHandler.responseSubcacheName, responseKey, serializedBody);

      final CacheRequestHandler<Body> cacheRequestHandler =
          CacheRequestHandler<Body>(delegate: fallbackHandler, cache: cache, config: config);

      final Body body = await tester.get(cacheRequestHandler);
      final Uint8List response = (await body.serialize().first)!;
      final String strResponse = utf8.decode(response);
      expect(strResponse, expectedResponse);
    });

    test('fallback handler called when cache is empty', () async {
      final FakeRequestHandler fallbackHandler = FakeRequestHandler(
        body: Body.forString('hello!'),
        config: FakeConfig(),
      );

      final CacheRequestHandler<Body> cacheRequestHandler =
          CacheRequestHandler<Body>(delegate: fallbackHandler, cache: cache, config: config);

      expect(fallbackHandler.callCount, 0);
      await tester.get(cacheRequestHandler);
      expect(fallbackHandler.callCount, 1);
    });

    test('flush cache param calls purge', () async {
      tester = RequestHandlerTester(
        request: FakeHttpRequest(
          path: testHttpPath,
          queryParametersValue: <String, String>{
            CacheRequestHandler.flushCacheQueryParam: 'true',
          },
        ),
      );
      final FakeRequestHandler fallbackHandler = FakeRequestHandler(
        body: Body.empty,
        config: FakeConfig(),
      );

      const String responseKey = '$testHttpPath:';
      const String expectedResponse = 'Hello, World!';
      final Body expectedBody = Body.forString(expectedResponse);

      final Uint8List? serializedBody = await expectedBody.serialize().first;

      // set an existing response for the request
      await cache.set(CacheRequestHandler.responseSubcacheName, responseKey, serializedBody);

      final CacheRequestHandler<Body> cacheRequestHandler =
          CacheRequestHandler<Body>(delegate: fallbackHandler, cache: cache, config: config);

      expect(fallbackHandler.callCount, 0);

      final Body body = await tester.get(cacheRequestHandler);
      final Uint8List response = (await body.serialize().first)!;
      final String strResponse = utf8.decode(response);

      // the mock should update the cache to have null -> empty string
      expect(strResponse, '');
      expect(fallbackHandler.callCount, 1);
    });
  });
}
