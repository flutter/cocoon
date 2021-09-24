// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/request_handling/authentication.dart' show AuthenticatedContext;
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/request_handling/swarming_authentication.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';

void main() {
  group('SwarmingAuthenticationProvider', () {
    late FakeConfig config;
    late FakeClientContext clientContext;
    late FakeLogging log;
    late FakeHttpRequest request;
    late SwarmingAuthenticationProvider auth;

    setUp(() {
      config = FakeConfig();
      clientContext = FakeClientContext();
      log = FakeLogging();
      request = FakeHttpRequest();
      auth = SwarmingAuthenticationProvider(
        config,
        clientContextProvider: () => clientContext,
        loggingProvider: () => log,
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
          config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
          loggingProvider: () => log,
        );
      });

      test('auth succeeds with flutter luci service account', () async {
        httpClient = MockClient((_) async => http.Response('{"email": "${config.luciProdAccount}"}', HttpStatus.ok));
        auth = SwarmingAuthenticationProvider(
          config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
          loggingProvider: () => log,
        );

        request.headers.add(SwarmingAuthenticationProvider.kSwarmingTokenHeader, 'token');

        final AuthenticatedContext result = await auth.authenticate(request);
        expect(result.clientContext, same(clientContext));
      });

      test('auth succeeds with frob service account', () async {
        httpClient = MockClient((_) async => http.Response('{"email": "${config.frobAccount}"}', HttpStatus.ok));
        auth = SwarmingAuthenticationProvider(
          config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
          loggingProvider: () => log,
        );
        request.headers.add(SwarmingAuthenticationProvider.kSwarmingTokenHeader, 'token');

        final AuthenticatedContext result = await auth.authenticate(request);
        expect(result.clientContext, same(clientContext));
      });

      test('auth fails with non-luci service account', () async {
        httpClient = MockClient((_) async => http.Response('{"email": "abc@gmail.com"}', HttpStatus.ok));
        auth = SwarmingAuthenticationProvider(
          config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
          loggingProvider: () => log,
        );

        request.headers.add(SwarmingAuthenticationProvider.kSwarmingTokenHeader, 'unauthenticated token');

        expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
      });

      test('auth fails with unauthenticated service account token', () async {
        httpClient = MockClient((_) async => http.Response('Invalid token', HttpStatus.unauthorized));
        auth = SwarmingAuthenticationProvider(
          config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
          loggingProvider: () => log,
        );

        request.headers.add(SwarmingAuthenticationProvider.kSwarmingTokenHeader, 'unauthenticated token');

        expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
      });
    });
  });
}
