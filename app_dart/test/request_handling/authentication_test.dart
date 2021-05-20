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

      test('auth succeeds with authenticated cookie but unauthenticated header', () async {
        httpClient = FakeHttpClient(onIssueRequest: (FakeHttpClientRequest request) {
          if (request.uri.queryParameters['id_token'] == 'bad-header') {
            return verifyTokenResponse
              ..statusCode = HttpStatus.unauthorized
              ..body = 'Invalid token: bad-header';
          }
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

        request.cookies.add(FakeCookie(name: 'X-Flutter-IdToken', value: 'authenticated'));
        request.headers.add('X-Flutter-IdToken', 'bad-header');

        final AuthenticatedContext result = await auth.authenticate(request);
        expect(result.clientContext, same(clientContext));

        // check log to ensure auth was not run on header token
        expect(log.records, hasLength(0));
      });

      test('auth succeeds with authenticated header but unauthenticated cookie', () async {
        httpClient = FakeHttpClient(onIssueRequest: (FakeHttpClientRequest request) {
          if (request.uri.queryParameters['id_token'] == 'bad-cookie') {
            return verifyTokenResponse
              ..statusCode = HttpStatus.unauthorized
              ..body = 'Invalid token: bad-cookie';
          }
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

        request.cookies.add(FakeCookie(name: 'X-Flutter-IdToken', value: 'bad-cookie'));
        request.headers.add('X-Flutter-IdToken', 'authenticated');

        final AuthenticatedContext result = await auth.authenticate(request);
        expect(result.clientContext, same(clientContext));

        // check log for debug statement
        expect(log.records, hasLength(2));
        expect(log.records.first.message, contains('Token verification failed: 401; Invalid token: bad-cookie'));
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
    });
  });
}
