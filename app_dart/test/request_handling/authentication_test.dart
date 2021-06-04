// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/model/appengine/allowed_account.dart';
import 'package:cocoon_service/src/model/google/token_info.dart';
import 'package:cocoon_service/src/request_handling/authentication.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';

void main() {
  group('AuthenticationProvider', () {
    FakeConfig config;
    FakeClientContext clientContext;
    FakeLogging log;
    FakeHttpRequest request;
    AuthenticationProvider auth;
    TokenInfo token;

    setUp(() {
      config = FakeConfig();
      token = const TokenInfo(email: 'abc123@gmail.com');
      clientContext = FakeClientContext();
      log = FakeLogging();
      request = FakeHttpRequest();
      auth = AuthenticationProvider(
        config,
        clientContextProvider: () => clientContext,
        httpClientProvider: () => throw AssertionError(),
        loggingProvider: () => log,
      );
    });

    test('throws Unauthenticated with no auth headers', () async {
      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });

    test('succeeds for App Engine cronjobs', () async {
      request.headers.set('X-Appengine-Cron', 'true');
      final AuthenticatedContext result = await auth.authenticate(request);
      expect(result.clientContext, same(clientContext));
    });

    group('when id token is given', () {
      FakeHttpClient httpClient;
      FakeHttpClientResponse verifyTokenResponse;

      setUp(() {
        httpClient = FakeHttpClient();
        verifyTokenResponse = httpClient.request.response;
        auth = AuthenticationProvider(
          config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
          loggingProvider: () => log,
        );
      });

      test('auth succeeds with authenticated header', () async {
        httpClient = FakeHttpClient(onIssueRequest: (FakeHttpClientRequest request) {
          return verifyTokenResponse
            ..statusCode = HttpStatus.ok
            ..body = '{"aud": "client-id", "hd": "google.com"}';
        });
        verifyTokenResponse = httpClient.request.response;
        auth = AuthenticationProvider(
          config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
          loggingProvider: () => log,
        );
        config.oauthClientIdValue = 'client-id';
        request.headers.add('X-Flutter-IdToken', 'authenticated');
        final AuthenticatedContext result = await auth.authenticate(request);
        expect(result.clientContext, same(clientContext));
        expect(result, isNotNull);
      });

      test('fails if token verification fails', () async {
        config.oauthClientIdValue = 'client-id';
        request.headers.add('X-Flutter-IdToken', 'authenticated');
        await expectLater(auth.authenticateToken(token, log: log), throwsA(isA<Unauthenticated>()));
      });

      test('fails if tokenInfo returns invalid JSON', () async {
        verifyTokenResponse.body = 'Not JSON';
        await expectLater(auth.tokenInfo(request, log: log), throwsA(isA<InternalServerError>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, isEmpty);
      });

      test('fails if token verification yields forged token', () async {
        const TokenInfo token = TokenInfo(audience: 'forgery', email: 'abc@abc.com');
        config.oauthClientIdValue = 'expected-client-id';
        await expectLater(auth.authenticateToken(token, log: log), throwsA(isA<Unauthenticated>()));
      });

      test('allows different aud for gcloud tokens with google accounts', () async {
        const TokenInfo token = TokenInfo(audience: 'different', email: 'abc@google.com');
        config.oauthClientIdValue = 'expected-client-id';
        await expectLater(auth.authenticateToken(token, log: log), throwsA(isA<Unauthenticated>()));
      });

      test('succeeds for google.com auth user', () async {
        const TokenInfo token = TokenInfo(audience: 'client-id', hostedDomain: 'google.com', email: 'abc@google.com');
        config.oauthClientIdValue = 'client-id';
        final AuthenticatedContext result = await auth.authenticateToken(token, clientContext: clientContext, log: log);
        expect(result.clientContext, same(clientContext));
      });

      test('fails for non-allowed non-Google auth users', () async {
        const TokenInfo token = TokenInfo(audience: 'client-id', hostedDomain: 'gmail.com', email: 'abc@gmail.com');
        config.oauthClientIdValue = 'client-id';
        await expectLater(auth.authenticateToken(token, log: log), throwsA(isA<Unauthenticated>()));
      });

      test('succeeds for allowed non-Google auth users', () async {
        final AllowedAccount account = AllowedAccount(
          key: config.db.emptyKey.append<int>(AllowedAccount, id: 123),
          email: 'test@gmail.com',
        );
        config.db.values[account.key] = account;
        const TokenInfo token = TokenInfo(audience: 'client-id', email: 'test@gmail.com');
        config.oauthClientIdValue = 'client-id';
        final AuthenticatedContext result = await auth.authenticateToken(token, clientContext: clientContext, log: log);
        expect(result.clientContext, same(clientContext));
      });
    });
  });
}
