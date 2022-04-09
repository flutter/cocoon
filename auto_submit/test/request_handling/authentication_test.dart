// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/request_handling/authentication.dart';
import 'package:auto_submit/requests/exceptions.dart';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';

import '../src/service/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('AuthenticationProvider', () {
    late Request request;
    late FakeConfig config;
    late FakeClientContext clientContext;
    late AuthenticationProvider auth;

    setUp(() {
      config = FakeConfig();
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
  });
}
