// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/request_handling/pubsub_authentication.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

void main() {
  useTestLoggerPerTest();

  group('PubsubAuthenticationProvider', () {
    late FakeConfig config;
    late FakeClientContext clientContext;
    late FakeHttpRequest request;
    late PubsubAuthenticationProvider auth;
    late MockClient httpClient;

    setUp(() {
      config = FakeConfig();
      clientContext = FakeClientContext();
      request = FakeHttpRequest();
      auth = PubsubAuthenticationProvider(
        config: config,
        clientContextProvider: () => clientContext,
        httpClientProvider: () => httpClient,
      );
    });

    for (var allowedAccount in Config.allowedPubsubServiceAccounts) {
      test('auth succeeds for $allowedAccount', () async {
        httpClient = MockClient(
          (_) async => http.Response(
            _generateTokenResponse(allowedAccount),
            HttpStatus.ok,
            headers: <String, String>{
              HttpHeaders.contentTypeHeader: 'application/json',
            },
          ),
        );
        auth = PubsubAuthenticationProvider(
          config: config,
          clientContextProvider: () => clientContext,
          httpClientProvider: () => httpClient,
        );

        request.headers.add(HttpHeaders.authorizationHeader, 'Bearer token');

        final result = await auth.authenticate(request);
        expect(result.clientContext, same(clientContext));
      });
    }

    test('auth fails with unauthorized service account', () async {
      httpClient = MockClient(
        (_) async => http.Response(
          _generateTokenResponse('unauthorized@gmail.com'),
          HttpStatus.ok,
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        ),
      );
      auth = PubsubAuthenticationProvider(
        config: config,
        clientContextProvider: () => clientContext,
        httpClientProvider: () => httpClient,
      );

      request.headers.add(HttpHeaders.authorizationHeader, 'Bearer token');

      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });

    test('auth fails with invalid token', () async {
      httpClient = MockClient(
        (_) async => http.Response(
          'Invalid token',
          HttpStatus.unauthorized,
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        ),
      );
      auth = PubsubAuthenticationProvider(
        config: config,
        clientContextProvider: () => clientContext,
        httpClientProvider: () => httpClient,
      );

      request.headers.add(HttpHeaders.authorizationHeader, 'Bearer token');

      expect(auth.authenticate(request), throwsA(isA<FormatException>()));
    });

    test('auth fails with expired token', () async {
      httpClient = MockClient(
        (_) async => http.Response(
          _generateTokenResponse(
            Config.allowedPubsubServiceAccounts.first,
            expiresIn: -1,
          ),
          HttpStatus.ok,
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        ),
      );
      auth = PubsubAuthenticationProvider(
        config: config,
        clientContextProvider: () => clientContext,
        httpClientProvider: () => httpClient,
      );

      request.headers.add(HttpHeaders.authorizationHeader, 'Bearer token');

      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });
  });
}

/// Return Google's OAuth response.
String _generateTokenResponse(String email, {int expiresIn = 123}) {
  return '''{
            "issued_to": "456",
            "audience": "https://flutter-dashboard.appspot.com/api/luci-status-handler",
            "user_id": "789",
            "expires_in": $expiresIn,
            "email": "$email",
            "verified_email": true,
            "issuer": "https://accounts.google.com",
            "issued_at": 412321
          }''';
}
