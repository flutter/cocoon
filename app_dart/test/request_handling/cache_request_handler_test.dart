// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handling/cache_request_handler.dart';
import 'package:cocoon_service/src/request_handling/http_utils.dart';
import 'package:cocoon_service/src/request_handling/response.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:test/test.dart';

import '../src/request_handling/request_handler_tester.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late RequestHandlerTester tester;

  late CacheService cache;

  const testHttpPath = '/cache_request_handler_test';

  setUp(() async {
    config = FakeConfig();
    tester = RequestHandlerTester(request: FakeHttpRequest(path: testHttpPath));
    cache = CacheService(inMemory: true);
  });

  test('fails retrieving an unexpected cached value', () async {
    const responseKey = '$testHttpPath:';
    const expectedResponse = 'Hello, World!';
    final expectedBody = Response.string(expectedResponse);
    final fallbackHandler = FakeRequestHandler(
      body: expectedBody,
      config: FakeConfig(),
    );

    final serializedBody = await expectedBody.body.first;

    await cache.set(
      CacheRequestHandler.responseSubcacheName,
      responseKey,
      serializedBody,
    );

    final cacheRequestHandler = CacheRequestHandler(
      delegate: fallbackHandler,
      cache: cache,
      config: config,
    );

    await expectLater(tester.get(cacheRequestHandler), throwsStateError);
  });

  test('stores HTTP status and contentType in cache', () async {
    final fallbackHandler = FakeRequestHandler(
      body: Response.string(
        'hello!',
        statusCode: 400,
        contentType: kContentTypeJson,
      ),
      config: FakeConfig(),
    );

    final cacheRequestHandler = CacheRequestHandler(
      delegate: fallbackHandler,
      cache: cache,
      config: config,
    );

    final response = await tester.get(cacheRequestHandler);
    expect(response.statusCode, 400);
    expect(
      response.contentType,
      isA<MediaType>().having((c) => '$c', 'type', kContentTypeJson.toString()),
    );
  });

  test('fallback handler called when cache is empty', () async {
    final fallbackHandler = FakeRequestHandler(
      body: Response.string('hello!'),
      config: FakeConfig(),
    );

    final cacheRequestHandler = CacheRequestHandler(
      delegate: fallbackHandler,
      cache: cache,
      config: config,
    );

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
    final fallbackHandler = FakeRequestHandler(
      body: Response.emptyOk,
      config: FakeConfig(),
    );

    const responseKey = '$testHttpPath:';
    const expectedResponse = 'Hello, World!';
    final expectedBody = Response.string(expectedResponse);

    final serializedBody = await expectedBody.body.first;

    // set an existing response for the request
    await cache.set(
      CacheRequestHandler.responseSubcacheName,
      responseKey,
      serializedBody,
    );

    final cacheRequestHandler = CacheRequestHandler(
      delegate: fallbackHandler,
      cache: cache,
      config: config,
    );

    expect(fallbackHandler.callCount, 0);

    final body = await tester.get(cacheRequestHandler);
    final response = await body.body.first;
    final strResponse = utf8.decode(response);

    // the mock should update the cache to have null -> empty string
    expect(strResponse, '');
    expect(fallbackHandler.callCount, 1);
  });
}
