// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/request_handling/authentication.dart' show AuthenticatedContext;
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/request_handling/swarming_authentication.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';

void main() {
  group('SwarmingAuthenticationProvider', () {
    FakeConfig config;
    FakeClientContext clientContext;
    FakeLogging log;
    FakeHttpRequest request;
    SwarmingAuthenticationProvider auth;

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
      FakeHttpClient httpClient;
      FakeHttpClientResponse verifyTokenResponse;

      setUp(() {
        httpClient = FakeHttpClient();
        verifyTokenResponse = httpClient.request.response;
        auth = SwarmingAuthenticationProvider(
          config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
          loggingProvider: () => log,
        );
      });

      test('auth succeeds with expected service account', () async {
        httpClient = FakeHttpClient(
            onIssueRequest: (FakeHttpClientRequest request) => verifyTokenResponse
              ..statusCode = HttpStatus.ok
              ..body = '{"email": "${config.luciProdAccount}"}');

        verifyTokenResponse = httpClient.request.response;
        auth = SwarmingAuthenticationProvider(
          config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
          loggingProvider: () => log,
        );

        request.headers.add(SwarmingAuthenticationProvider.kSwarmingTokenHeader, 'unauthenticated token');

        final AuthenticatedContext result = await auth.authenticate(request);
        expect(result.clientContext, same(clientContext));
      });

      test('auth fails with non-luci service account', () async {
        httpClient = FakeHttpClient(
            onIssueRequest: (FakeHttpClientRequest request) => verifyTokenResponse
              ..statusCode = HttpStatus.ok
              ..body = '{"email": "abc@gmail.com"}');

        verifyTokenResponse = httpClient.request.response;
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
        httpClient = FakeHttpClient(
            onIssueRequest: (FakeHttpClientRequest request) => verifyTokenResponse
              ..statusCode = HttpStatus.unauthorized
              ..body = 'Invalid token');
        verifyTokenResponse = httpClient.request.response;
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
