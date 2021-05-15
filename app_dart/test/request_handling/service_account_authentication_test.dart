// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/request_handling/authentication.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/request_handling/service_account_authentication.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';

void main() {
  group('ServiceAccountAuthenticationProvider', () {
    FakeConfig config;
    FakeClientContext clientContext;
    FakeLogging log;
    FakeHttpClient httpClient;
    FakeHttpClientResponse verifyTokenResponse;
    FakeHttpRequest request;
    AuthenticationProvider auth;
    String futureExpiration;

    const String expectedServiceAccount = 'test@developer.gserviceaccount.com';

    setUp(() {
      clientContext = FakeClientContext();
      config = FakeConfig();
      log = FakeLogging();
      request = FakeHttpRequest();
      httpClient = FakeHttpClient();
      verifyTokenResponse = httpClient.request.response;
      auth = ServiceAccountAuthenticationProvider(
        config,
        expectedServiceAccount,
        clientContextProvider: () => clientContext,
        httpClientProvider: () => httpClient,
        loggingProvider: () => log,
      );
      futureExpiration = _datetimeToSecondsSinceEpoch(DateTime.now().add(const Duration(hours: 1))).toString();
    });

    test('succeeds for expected service account', () async {
      request.headers.add(HttpHeaders.authorizationHeader, 'token');
      verifyTokenResponse.body =
          '{"aud": "client-id", "exp": "$futureExpiration", "email": "test@developer.gserviceaccount.com"}';
      config.oauthClientIdValue = 'client-id';
      final AuthenticatedContext result = await auth.authenticate(request);
      expect(result.clientContext, same(clientContext));
    });

    test('fails if service account does not match expected account', () async {
      final String pastExpiration =
          _datetimeToSecondsSinceEpoch(DateTime.now().subtract(const Duration(hours: 1))).toString();
      verifyTokenResponse.body =
          '{"aud": "client-id", "exp": "$pastExpiration", "email": "wrong-account@developer.gserviceaccount.com"}';
      config.oauthClientIdValue = 'client-id';
      await expectLater(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });
  });
}

int _datetimeToSecondsSinceEpoch(DateTime time) {
  return (time.millisecondsSinceEpoch / 1000).round();
}
