// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/request_handling/swarming_authentication.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

void main() {
  useTestLoggerPerTest();

  group('SwarmingAuthenticationProvider', () {
    late FakeConfig config;
    late FakeClientContext clientContext;
    late FakeHttpRequest request;
    late SwarmingAuthenticationProvider auth;

    setUp(() {
      config = FakeConfig();
      clientContext = FakeClientContext();
      request = FakeHttpRequest();
      auth = SwarmingAuthenticationProvider(
        config: config,
        clientContextProvider: () => clientContext,
      );
    });

    test('fails for App Engine cronjobs', () async {
      request.headers.set('X-Appengine-Cron', 'true');
      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });

    group('when access token is given', () {
      late MockClient httpClient;

      setUp(() {
        auth = SwarmingAuthenticationProvider(
          config: config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
        );
      });

      test('auth succeeds with flutter luci service account', () async {
        httpClient = MockClient(
          (_) async => http.Response(
            '{"email": "${Config.luciProdAccount}"}',
            HttpStatus.ok,
          ),
        );
        auth = SwarmingAuthenticationProvider(
          config: config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
        );

        request.headers.add(
          SwarmingAuthenticationProvider.kSwarmingTokenHeader,
          'token',
        );

        final result = await auth.authenticate(request);
        expect(result.clientContext, same(clientContext));
      });

      test('auth succeeds with frob service account', () async {
        httpClient = MockClient(
          (_) async => http.Response(
            '{"email": "${Config.frobAccount}"}',
            HttpStatus.ok,
          ),
        );
        auth = SwarmingAuthenticationProvider(
          config: config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
        );
        request.headers.add(
          SwarmingAuthenticationProvider.kSwarmingTokenHeader,
          'token',
        );

        final result = await auth.authenticate(request);
        expect(result.clientContext, same(clientContext));
      });

      test('auth fails with non-luci service account', () async {
        httpClient = MockClient(
          (_) async =>
              http.Response('{"email": "abc@gmail.com"}', HttpStatus.ok),
        );
        auth = SwarmingAuthenticationProvider(
          config: config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
        );

        request.headers.add(
          SwarmingAuthenticationProvider.kSwarmingTokenHeader,
          'unauthenticated token',
        );

        expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
      });

      test('auth fails with unauthenticated service account token', () async {
        httpClient = MockClient(
          (_) async => http.Response('Invalid token', HttpStatus.unauthorized),
        );
        auth = SwarmingAuthenticationProvider(
          config: config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
        );

        request.headers.add(
          SwarmingAuthenticationProvider.kSwarmingTokenHeader,
          'unauthenticated token',
        );

        expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
      });
    });
  });
}
