// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;

import 'package:cocoon_service/src/request_handling/cache_response_handler.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handling/body.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('CacheResponseHandler', () {
    RequestHandlerTester tester;

    final FakeConfig config = FakeConfig();

    setUp(() {
      tester = RequestHandlerTester();
    });

    Future<String> _decodeHandlerBody(Body body) {
      return utf8.decoder.bind(body.serialize()).first;
    }

    test('returns response from cache', () {});

    test('fallback handler called when cache is empty', () {
      final RequestHandler<Body> fallbackHandlerMock = MockRequestHandler();

      final CacheResponseHandler cacheResponseHandler = CacheResponseHandler(
          'null-cache', fallbackHandlerMock,
          config: config);

      tester.get(cacheResponseHandler);

      verify(fallbackHandlerMock.get()).called(1);
    });
  });
}

// ignore: must_be_immutable
class MockRequestHandler extends Mock implements RequestHandler<Body> {}
