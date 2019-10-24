// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:mockito/mockito.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handling/body.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('CacheRequestHandler', () {
    FakeConfig config;
    RequestHandlerTester tester;

    CacheProvider<List<int>> cacheProvider;
    Cache<List<int>> cache;

    const String testHttpPath = '/cache_request_handler_test';

    setUp(() {
      config =
          FakeConfig(redisResponseSubcacheValue: 'cache_request_handler_test');
      tester = RequestHandlerTester(
          request: FakeHttpRequest(
        path: testHttpPath,
      ));

      cacheProvider = Cache.inMemoryCacheProvider(16);
      cache = Cache<List<int>>(cacheProvider);
    });

    Future<String> _decodeHandlerBody(Body body) {
      return utf8.decoder.bind(body.serialize()).first;
    }

    test('returns response from cache', () async {
      final RequestHandler<Body> fallbackHandlerMock = MockRequestHandler();

      final Cache<List<int>> responseCache =
          cache.withPrefix(await config.redisResponseSubcache);

      const String expectedResponse = 'Hello, World!';
      final Body expectedBody = Body.forString(expectedResponse);

      final List<Uint8List> serializedBody =
          await expectedBody.serialize().toList();

      await responseCache['$testHttpPath:'].set(serializedBody.cast<int>());

      final CachedRequestHandler<Body> cacheRequestHandler =
          CachedRequestHandler<Body>(
              delegate: fallbackHandlerMock, cache: cache, config: config);

      final Body body = await tester.get(cacheRequestHandler);
      final String response = await _decodeHandlerBody(body);

      expect(response, expectedResponse);
    });

    test('fallback handler called when cache is empty', () async {
      final RequestHandler<Body> fallbackHandlerMock = MockRequestHandler();
      // ignore: invalid_use_of_protected_member
      when(fallbackHandlerMock.get())
          .thenAnswer((_) => Future<Body>.value(Body.forString('')));

      final CachedRequestHandler<Body> cacheRequestHandler =
          CachedRequestHandler<Body>(
              delegate: fallbackHandlerMock, cache: cache, config: config);

      // ignore: invalid_use_of_protected_member
      verifyNever(fallbackHandlerMock.get());

      await tester.get(cacheRequestHandler);

      // ignore: invalid_use_of_protected_member
      verify(fallbackHandlerMock.get()).called(1);
    });
  });
}

// ignore: must_be_immutable
class MockRequestHandler extends Mock implements RequestHandler<Body> {}
