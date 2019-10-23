// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;

import 'package:mockito/mockito.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handling/body.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('CacheRequestHandler', () {
    FakeConfig config;
    RequestHandlerTester tester;

    CacheProvider<List<int>> cacheProvider;
    Cache<List<int>> cache;

    CachedRequestHandler requestHandler;

    setUp(() {
      config = FakeConfig(redisResponseSubcacheValue: 'cache_request_handler_test');
      tester = RequestHandlerTester();

      cacheProvider = Cache.inMemoryCacheProvider(16);
      cache = Cache<List<int>>(cacheProvider);
    });

    Future<String> _decodeHandlerBody(Body body) {
      return utf8.decoder.bind(body.serialize()).first;
    }

    test('returns response from cache', () {});

    test('fallback handler called when cache is empty', () async {
      final RequestHandler<Body> fallbackHandlerMock = MockRequestHandler();

      final CachedRequestHandler cacheResponseHandler = CachedRequestHandler(
          'null-key', fallbackHandlerMock,
          cache: cache, config: config);

      await tester.get(cacheResponseHandler);

      verify(fallbackHandlerMock.get()).called(1);
    });
  });
}

// ignore: must_be_immutable
class MockRequestHandler extends Mock implements RequestHandler<Body> {}
