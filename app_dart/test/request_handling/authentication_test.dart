// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/model/appengine/whitelisted_account.dart';
import 'package:cocoon_service/src/request_handling/authentication.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

void main() {
  group('AuthenticationProvider', () {
    FakeConfig config;
    FakeClientContext clientContext;
    FakeHttpHeaders headers;
    MockHttpRequest request;
    AuthenticationProvider auth;

    setUp(() {
      config = FakeConfig();
      clientContext = FakeClientContext();
      headers = FakeHttpHeaders();
      request = MockHttpRequest();
      when(request.headers).thenReturn(headers);
      auth = AuthenticationProvider(config, () => clientContext);
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
        headers.set('Agent-ID', agent.key.id);
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
          headers.set('Agent-Auth-Token', 'invalid_token');
          expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
        });

        test('succeeds if agent lookup succeeds and valid auth token provided', () async {
          config.db.values[agent.key] = agent;
          headers.set('Agent-Auth-Token', 'password');
          final AuthenticatedContext result = await auth.authenticate(request);
          expect(result.agent, same(agent));
          expect(result.clientContext, same(clientContext));
        });
      });
    });

    test('succeeds for App Engine cronjobs', () async {
      headers.set('X-Appengine-Cron', 'true');
      final AuthenticatedContext result = await auth.authenticate(request);
      expect(result.agent, isNull);
      expect(result.clientContext, same(clientContext));
    });

    test('succeeds for google.com auth user', () async {
      headers.set('X-AppEngine-User-Email', 'test@google.com');
      final AuthenticatedContext result = await auth.authenticate(request);
      expect(result.agent, isNull);
      expect(result.clientContext, same(clientContext));
    });

    test('fails for non-whitelisted non-Google auth users', () async {
      headers.set('X-AppEngine-User-Email', 'test@gmail.com');
      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });

    test('succeeds for whitelisted non-Google auth users', () async {
      final WhitelistedAccount account = WhitelistedAccount(
        key: config.db.emptyKey.append(WhitelistedAccount, id: 123),
        email: 'test@gmail.com',
      );
      headers.set('X-AppEngine-User-Email', account.email);
      config.db.values[account.key] = account;
      final AuthenticatedContext result = await auth.authenticate(request);
      expect(result.agent, isNull);
      expect(result.clientContext, same(clientContext));
    });
  });
}

class MockHttpRequest extends Mock implements HttpRequest {}
