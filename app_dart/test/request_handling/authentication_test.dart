// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/model/appengine/allowed_account.dart';
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

    setUp(() {
      config = FakeConfig();
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

      test('fails if token verification fails', () async {
        verifyTokenResponse.statusCode = HttpStatus.badRequest;
        verifyTokenResponse.body = 'Invalid token: abc123';
        await expectLater(auth.authenticateIdToken('abc123', clientContext: clientContext, log: log),
            throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, hasLength(1));
        expect(log.records.single.message, contains('Invalid token: abc123'));
      });

      test('fails if token verification returns invalid JSON', () async {
        verifyTokenResponse.body = 'Not JSON';
        await expectLater(auth.authenticateIdToken('abc123', clientContext: clientContext, log: log),
            throwsA(isA<InternalServerError>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, isEmpty);
      });

      test('fails if token verification yields forged token', () async {
        verifyTokenResponse.body = '{"aud": "forgery", "email": "abc@abc.com"}';
        config.oauthClientIdValue = 'expected-client-id';
        await expectLater(auth.authenticateIdToken('abc123', clientContext: clientContext, log: log),
            throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, hasLength(1));
        expect(log.records.single.message, contains('forgery'));
        expect(log.records.single.message, contains('expected-client-id'));
      });

      test('allows different aud for gcloud tokens with google accounts', () async {
        verifyTokenResponse.body = '{"aud": "different", "email": "abc@google.com"}';
        config.oauthClientIdValue = 'expected-client-id';
        await expectLater(auth.authenticateIdToken('abc123', clientContext: clientContext, log: log),
            throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, hasLength(0));
      });

      test('succeeds for google.com auth user', () async {
        verifyTokenResponse.body = '{"aud": "client-id", "hd": "google.com"}';
        config.oauthClientIdValue = 'client-id';
        final AuthenticatedContext result =
            await auth.authenticateIdToken('abc123', clientContext: clientContext, log: log);
        expect(result.clientContext, same(clientContext));
      });

      test('fails for non-allowed non-Google auth users', () async {
        verifyTokenResponse.body = '{"aud": "client-id", "hd": "gmail.com"}';
        config.oauthClientIdValue = 'client-id';
        await expectLater(auth.authenticateIdToken('abc123', clientContext: clientContext, log: log),
            throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
      });

      test('succeeds for allowed non-Google auth users', () async {
        final AllowedAccount account = AllowedAccount(
          key: config.db.emptyKey.append<int>(AllowedAccount, id: 123),
          email: 'test@gmail.com',
        );
        config.db.values[account.key] = account;
        verifyTokenResponse.body = '{"aud": "client-id", "email": "test@gmail.com"}';
        config.oauthClientIdValue = 'client-id';
        final AuthenticatedContext result =
            await auth.authenticateIdToken('abc123', clientContext: clientContext, log: log);
        expect(result.clientContext, same(clientContext));
      });

      test('succeeds for expected service account', () async {
        verifyTokenResponse.body = '{"aud": "client-id", "email": "test@developer.gserviceaccount.com"}';
        config.oauthClientIdValue = 'client-id';
        final AuthenticatedContext result = await auth.authenticateIdToken(
          'abc123',
          clientContext: clientContext,
          log: log,
          expectedAccount: 'test@developer.gserviceaccount.com',
        );
        expect(result.clientContext, same(clientContext));
      });

      test('fails if service account does not match expected account', () async {
        verifyTokenResponse.body = '{"aud": "client-id", "email": "wrong-account@developer.gserviceaccount.com"}';
        config.oauthClientIdValue = 'client-id';
        await expectLater(
            auth.authenticateIdToken(
              'abc123',
              clientContext: clientContext,
              log: log,
              expectedAccount: 'test@developer.gserviceaccount.com',
            ),
            throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
      });
    });
  });
}
