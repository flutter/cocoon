// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_server/logging.dart';
import 'package:cocoon_service/src/model/appengine/allowed_account.dart';
import 'package:cocoon_service/src/model/google/token_info.dart';
import 'package:cocoon_service/src/request_handling/authentication.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

void main() {
  group('AuthenticationProvider', () {
    late FakeConfig config;
    late FakeClientContext clientContext;
    late FakeHttpRequest request;
    late AuthenticationProvider auth;
    late TokenInfo token;

    setUp(() {
      config = FakeConfig();
      token = TokenInfo(email: 'abc123@gmail.com', issued: DateTime.now());
      clientContext = FakeClientContext();
      request = FakeHttpRequest();
      auth = AuthenticationProvider(
        config: config,
        clientContextProvider: () => clientContext,
        httpClientProvider: () => throw AssertionError(),
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
      late MockClient httpClient;

      setUp(() {
        auth = AuthenticationProvider(
          config: config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
        );
      });

      test('auth succeeds with authenticated header', () async {
        httpClient = MockClient((_) async => http.Response('{"aud": "client-id", "hd": "google.com"}', HttpStatus.ok));
        auth = AuthenticationProvider(
          config: config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
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
        await expectLater(
          auth.authenticateToken(
            token,
            clientContext: FakeClientContext(),
          ),
          throwsA(isA<Unauthenticated>()),
        );
      });

      test('fails if tokenInfo returns invalid JSON', () async {
        httpClient = MockClient((_) async => http.Response('Not JSON!', HttpStatus.ok));
        final List<LogRecord> records = <LogRecord>[];
        log.onRecord.listen((LogRecord record) => records.add(record));
        await expectLater(auth.tokenInfo(request), throwsA(isA<InternalServerError>()));
        expect(records, isEmpty);
      });

      test('fails if token verification yields forged token', () async {
        final TokenInfo token = TokenInfo(
          audience: 'forgery',
          email: 'abc@abc.com',
          issued: DateTime.now(),
        );
        config.oauthClientIdValue = 'expected-client-id';
        await expectLater(
          auth.authenticateToken(
            token,
            clientContext: FakeClientContext(),
          ),
          throwsA(isA<Unauthenticated>()),
        );
      });

      test('allows different aud for gcloud tokens with google accounts', () async {
        final TokenInfo token = TokenInfo(
          audience: 'different',
          email: 'abc@google.com',
          issued: DateTime.now(),
        );
        config.oauthClientIdValue = 'expected-client-id';
        await expectLater(
          auth.authenticateToken(
            token,
            clientContext: FakeClientContext(),
          ),
          throwsA(isA<Unauthenticated>()),
        );
      });

      test('succeeds for google.com auth user', () async {
        final TokenInfo token = TokenInfo(
          audience: 'client-id',
          hostedDomain: 'google.com',
          email: 'abc@google.com',
          issued: DateTime.now(),
        );
        config.oauthClientIdValue = 'client-id';
        final AuthenticatedContext result = await auth.authenticateToken(
          token,
          clientContext: clientContext,
        );
        expect(result.clientContext, same(clientContext));
      });

      test('fails for non-allowed non-Google auth users', () async {
        final TokenInfo token =
            TokenInfo(audience: 'client-id', hostedDomain: 'gmail.com', email: 'abc@gmail.com', issued: DateTime.now());
        config.oauthClientIdValue = 'client-id';
        await expectLater(
          auth.authenticateToken(
            token,
            clientContext: FakeClientContext(),
          ),
          throwsA(isA<Unauthenticated>()),
        );
      });

      test('succeeds for allowed non-Google auth users', () async {
        final AllowedAccount account = AllowedAccount(
          key: config.db.emptyKey.append<int>(AllowedAccount, id: 123),
          email: 'test@gmail.com',
        );
        config.db.values[account.key] = account;
        final TokenInfo token = TokenInfo(
          audience: 'client-id',
          email: 'test@gmail.com',
          issued: DateTime.now(),
        );
        config.oauthClientIdValue = 'client-id';
        final AuthenticatedContext result = await auth.authenticateToken(token, clientContext: clientContext);
        expect(result.clientContext, same(clientContext));
      });
    });
  });
}
