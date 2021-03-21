// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:cocoon_service/src/datastore/config.dart';
import 'package:cocoon_service/src/request_handlers/flush_cache.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/cache_service.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

void main() {
  group('FlushCache', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    FlushCache handler;
    CacheService cache;

    setUp(() {
      tester = ApiRequestHandlerTester();
      cache = CacheService(inMemory: true);
      config = FakeConfig();
      handler = FlushCache(
        config,
        FakeAuthenticationProvider(),
        cache: cache,
      );
    });

    test('cache is empty when given an existing config key', () async {
      const String cacheKey = 'test';
      await cache.set(
        Config.configCacheName,
        cacheKey,
        Uint8List.fromList('123'.codeUnits),
      );

      tester.request = FakeHttpRequest(queryParametersValue: <String, String>{
        FlushCache.cacheKeyParam: cacheKey,
      });
      await tester.get(handler);

      expect(await cache.getOrCreate(Config.configCacheName, cacheKey), null);
    });

    test('raises error if cache key not passed', () async {
      expect(tester.get(handler), throwsA(isA<BadRequestException>()));
    });

    test('raises error if cache key does not exist', () async {
      tester.request = FakeHttpRequest(queryParametersValue: <String, String>{
        FlushCache.cacheKeyParam: 'abc',
      });
      expect(tester.get(handler), throwsA(isA<NotFoundException>()));
    });
  });
}
