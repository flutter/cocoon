// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

//import 'package:cocoon_service/src/model/appengine/allowed_account.dart';
import 'package:auto_submit/model/google/token_info.dart';
import 'package:auto_submit/request_handling/authentication.dart';
import 'package:auto_submit/requests/exceptions.dart';
import 'package:auto_submit/service/log.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';

import '../src/service/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('AuthenticationProvider', () {
    late Request request;
    late FakeConfig config;
    late FakeClientContext clientContext;
    //late FakeHttpRequest request;
    late AuthenticationProvider auth;
    late TokenInfo token;

    setUp(() {
      config = FakeConfig();
      token = TokenInfo(email: 'abc123@gmail.com', issued: DateTime.now());
      clientContext = FakeClientContext();
      //request = FakeHttpRequest();
      auth = AuthenticationProvider(
        config,
        clientContextProvider: () => clientContext,
        httpClientProvider: () => throw AssertionError(),
      );
    });

    test('throws Unauthenticated with no auth headers', () async {
      request = Request('POST', Uri.parse('http://localhost/'));
      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });

    test('succeeds for App Engine cronjobs', () async {
      Map<String, String> header = {'X-Appengine-Cron': 'true'};
      request = Request('POST', Uri.parse('http://localhost/'), headers: header);
      final AuthenticatedContext result = await auth.authenticate(request);
      expect(result.clientContext, same(clientContext));
    });

    group('when id token is given', () {
      late MockClient httpClient;

      setUp(() {
        auth = AuthenticationProvider(
          config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
        );
      });

      test('auth succeeds with authenticated header', () async {
        httpClient = MockClient((_) async => http.Response('{"aud": "client-id", "hd": "google.com"}', HttpStatus.ok));
        auth = AuthenticationProvider(
          config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
        );
        config.oauthClientIdValue = 'client-id';
        Map<String, String> header = {'X-Flutter-IdToken': 'authenticated'};
        request = Request('POST', Uri.parse('http://localhost/'), headers: header);
        final AuthenticatedContext result = await auth.authenticate(request);
        expect(result.clientContext, same(clientContext));
        expect(result, isNotNull);
      });

      test('fails if token verification fails', () async {
        config.oauthClientIdValue = 'client-id';
        Map<String, String> header = {'X-Flutter-IdToken': 'authenticated'};
        request = Request('POST', Uri.parse('http://localhost/'), headers: header);
        await expectLater(
            auth.authenticateToken(
              token,
              clientContext: FakeClientContext(),
            ),
            throwsA(isA<Unauthenticated>()));
      });

      test('fails if tokenInfo returns invalid JSON', () async {
        httpClient = MockClient((_) async => http.Response('Not JSON!', HttpStatus.ok));
        final List<LogRecord> records = <LogRecord>[];
        log.onRecord.listen((LogRecord record) => records.add(record));
        request = Request('POST', Uri.parse('http://localhost/'));
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
            throwsA(isA<Unauthenticated>()));
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
    });
  });
}
