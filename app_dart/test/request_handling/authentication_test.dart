// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/model/appengine/whitelisted_account.dart';
import 'package:cocoon_service/src/request_handling/authentication.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
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

    group('when agent id is specified in header', () {
      Agent agent;

      setUp(() {
        agent = Agent(
          key: config.db.emptyKey.append(Agent, id: 'aid'),
          authToken: ascii.encode(r'$2a$10$4UicEmMSoqzUtWTQAR1s/.qUrmh7oQTyz1MI.f7qt6.jJ6kPipdKq'),
        );
        request.headers.set('Agent-ID', agent.key.id);
      });

      test('throws Unauthenticated if agent lookup fails', () async {
        expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
      });

      group('and in development environment', () {
        setUp(() {
          clientContext.isDevelopmentEnvironment = true;
        });

        test('succeeds if agent lookup succeeds', () async {
          config.db.values[agent.key] = agent;
          final AuthenticatedContext result = await auth.authenticate(request);
          expect(result.agent, same(agent));
          expect(result.clientContext, same(clientContext));
        });
      });

      group('and not in development environment', () {
        setUp(() {
          clientContext.isDevelopmentEnvironment = false;
        });

        test('fails if agent lookup succeeds but auth token is not provided', () async {
          config.db.values[agent.key] = agent;
          expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
        });

        test('fails if agent lookup succeeds but auth token is invalid', () async {
          config.db.values[agent.key] = agent;
          request.headers.set('Agent-Auth-Token', 'invalid_token');
          expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
        });

        test('succeeds if agent lookup succeeds and valid auth token provided', () async {
          config.db.values[agent.key] = agent;
          request.headers.set('Agent-Auth-Token', 'password');
          final AuthenticatedContext result = await auth.authenticate(request);
          expect(result.agent, same(agent));
          expect(result.clientContext, same(clientContext));
        });
      });
    });

    test('succeeds for App Engine cronjobs', () async {
      request.headers.set('X-Appengine-Cron', 'true');
      final AuthenticatedContext result = await auth.authenticate(request);
      expect(result.agent, isNull);
      expect(result.clientContext, same(clientContext));
    });

    group('when X-Flutter-IdToken cookie is specified', () {
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
        request.cookies.add(FakeCookie(name: 'X-Flutter-IdToken', value: 'abc123'));
        verifyTokenResponse.statusCode = HttpStatus.badRequest;
        verifyTokenResponse.body = 'Invalid token: abc123';
        await expectLater(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, hasLength(1));
        expect(log.records.single.level, LogLevel.WARNING);
        expect(log.records.single.message, contains('Invalid token: abc123'));
      });

      test('fails if token verification returns invalid JSON', () async {
        request.cookies.add(FakeCookie(name: 'X-Flutter-IdToken', value: 'abc123'));
        verifyTokenResponse.body = 'Not JSON';
        await expectLater(auth.authenticate(request), throwsA(isA<InternalServerError>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, isEmpty);
      });

      test('fails if token verification yields forged token', () async {
        request.cookies.add(FakeCookie(name: 'X-Flutter-IdToken', value: 'abc123'));
        verifyTokenResponse.body = '{"aud": "forgery"}';
        config.oauthClientIdValue = 'expected-client-id';
        await expectLater(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, hasLength(1));
        expect(log.records.single.level, LogLevel.WARNING);
        expect(log.records.single.message, contains('forgery'));
        expect(log.records.single.message, contains('expected-client-id'));
      });

      test('succeeds for google.com auth user', () async {
        request.cookies.add(FakeCookie(name: 'X-Flutter-IdToken', value: 'abc123'));
        verifyTokenResponse.body = '{"aud": "client-id", "hd": "google.com"}';
        config.oauthClientIdValue = 'client-id';
        final AuthenticatedContext result = await auth.authenticate(request);
        expect(result.agent, isNull);
        expect(result.clientContext, same(clientContext));
      });

      test('fails for non-whitelisted non-Google auth users', () async {
        request.cookies.add(FakeCookie(name: 'X-Flutter-IdToken', value: 'abc123'));
        verifyTokenResponse.body = '{"aud": "client-id", "hd": "gmail.com"}';
        config.oauthClientIdValue = 'client-id';
        await expectLater(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
      });

      test('succeeds for whitelisted non-Google auth users', () async {
        final WhitelistedAccount account = WhitelistedAccount(
          key: config.db.emptyKey.append(WhitelistedAccount, id: 123),
          email: 'test@gmail.com',
        );
        config.db.values[account.key] = account;
        request.cookies.add(FakeCookie(name: 'X-Flutter-IdToken', value: 'abc123'));
        verifyTokenResponse.body = '{"aud": "client-id", "email": "test@gmail.com"}';
        config.oauthClientIdValue = 'client-id';
        final AuthenticatedContext result = await auth.authenticate(request);
        expect(result.agent, isNull);
        expect(result.clientContext, same(clientContext));
      });
    });

    group('when X-Flutter-AccessToken header is specified', () {
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

      test('fails if access token verification fails', () async {
        request.headers.add('X-Flutter-AccessToken', 'failure');
        verifyTokenResponse.statusCode = HttpStatus.badRequest;
        verifyTokenResponse.body = 'Invalid access token: failure';
        await expectLater(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, hasLength(1));
        expect(log.records.single.level, LogLevel.WARNING);
        expect(log.records.single.message, contains('Invalid access token: failure'));
      });

      test('fails if access token verification returns invalid JSON', () async {
        request.headers.add('X-Flutter-AccessToken', 'abc123');
        verifyTokenResponse.body = 'Not JSON';
        await expectLater(auth.authenticate(request), throwsA(isA<InternalServerError>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, isEmpty);
      });

      test('fails if access token verification yields forged token', () async {
        request.headers.add('X-Flutter-AccessToken', 'abc123');
        verifyTokenResponse.body = '{"audience": "forgery"}';
        config.oauthClientIdValue = 'expected-client-id';
        await expectLater(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, hasLength(1));
        expect(log.records.single.level, LogLevel.WARNING);
        expect(log.records.single.message, contains('forgery'));
        expect(log.records.single.message, contains('expected-client-id'));
      });

      test('fails for unverified email', () async {
        request.headers.add('X-Flutter-AccessToken', 'abc123');
        verifyTokenResponse.body = '{"audience": "client-id", "verified_email": "false", "email": "sundar-imposter@google.com"}';
        config.oauthClientIdValue = 'client-id';
        await expectLater(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
        expect(log.records, hasLength(1));
        expect(log.records.single.level, LogLevel.WARNING);
        expect(log.records.single.message, contains('Unverified account'));
      });

      test('succeeds for google.com auth user', () async {
        request.headers.add('X-Flutter-AccessToken', 'abc123');
        verifyTokenResponse.body = '{"audience": "client-id", "verified_email": "true", "email": "sundar@google.com"}';
        config.oauthClientIdValue = 'client-id';
        final AuthenticatedContext result = await auth.authenticate(request);
        expect(result.agent, isNull);
        expect(result.clientContext, same(clientContext));
      });

      test('fails for non-whitelisted non-Google auth users', () async {
        request.headers.add('X-Flutter-AccessToken', 'abc123');
        verifyTokenResponse.body = '{"audience": "client-id", "verified_email": "true",  "email": "sundar@gmail.com"}';
        config.oauthClientIdValue = 'client-id';
        await expectLater(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
        expect(httpClient.requestCount, 1);
      });

      test('succeeds for whitelisted non-Google auth users', () async {
        final WhitelistedAccount account = WhitelistedAccount(
          key: config.db.emptyKey.append(WhitelistedAccount, id: 123),
          email: 'test@gmail.com',
        );
        config.db.values[account.key] = account;
        request.headers.add('X-Flutter-AccessToken', 'abc123');
        verifyTokenResponse.body = '{"audience": "client-id", "verified_email": "true",  "email": "test@gmail.com"}';
        config.oauthClientIdValue = 'client-id';
        final AuthenticatedContext result = await auth.authenticate(request);
        expect(result.agent, isNull);
        expect(result.clientContext, same(clientContext));
      });
    });
  });
}
