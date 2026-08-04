// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/mocks.mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/account.dart';
import 'package:cocoon_service/src/model/google/firebase_jwt_claim.dart';
import 'package:cocoon_service/src/model/google/token_info.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/request_handling/http_io.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('DashboardCronAuthentication', () {
    late DashboardCronAuthentication auth;
    late FakeClientContext clientContext;
    late FakeHttpRequest request;

    setUp(() {
      request = FakeHttpRequest();
      clientContext = FakeClientContext();
      auth = DashboardCronAuthentication(
        clientContextProvider: () => clientContext,
      );
    });

    test('succeeds for App Engine cronjobs', () async {
      request.headers.set('X-Appengine-Cron', 'true');
      final result = await auth.authenticate(request.toRequest());
      expect(result.clientContext, same(clientContext));
    });

    test('throws for non App Engine cronjobs', () async {
      expect(
        auth.authenticate(request.toRequest()),
        throwsA(isA<Unauthenticated>()),
      );
    });
  });

  group('DashboardFirebaseAuthentication', () {
    late DashboardFirebaseAuthentication auth;
    late FakeFirestoreService firestore;
    late FakeClientContext clientContext;
    late FakeFirebaseJwtValidator validator;
    late FakeHttpRequest request;

    setUp(() {
      firestore = FakeFirestoreService();
      request = FakeHttpRequest();
      clientContext = FakeClientContext();
      validator = FakeFirebaseJwtValidator();
      auth = DashboardFirebaseAuthentication(
        cache: CacheService.inMemory(),
        clientContextProvider: () => clientContext,
        validator: validator,
        firestore: firestore,
      );
    });

    test('succeeds for firebase jwt for googler', () async {
      validator.jwts.add(
        TokenInfo(email: 'abc123@google.com', issued: DateTime.now()),
      );
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      final result = await auth.authenticate(request.toRequest());
      expect(result.email, 'abc123@google.com');
    });

    test('succeeds for firebase jwt with allowed non-googler', () async {
      firestore.putDocument(Account(email: 'abc123@gmail.com'));
      validator.jwts.add(
        TokenInfo(email: 'abc123@gmail.com', issued: DateTime.now()),
      );
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      final result = await auth.authenticate(request.toRequest());
      expect(result.email, 'abc123@gmail.com');
    });

    test('fails for firebase jwt with non-allowed non-googler', () async {
      validator.jwts.add(
        TokenInfo(email: 'abc123@gmail.com', issued: DateTime.now()),
      );
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      expect(
        auth.authenticate(request.toRequest()),
        throwsA(isA<Unauthenticated>()),
      );
    });

    test('fails for non-firebase jwt', () {
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      expect(
        auth.authenticate(request.toRequest()),
        throwsA(isA<Unauthenticated>()),
      );
    });
  });

  group('ChainOfAuthentication', () {
    late ChainOfAuthentication auth;
    late FakeFirestoreService firestore;
    late FakeClientContext clientContext;
    late FakeFirebaseJwtValidator validator;
    late FakeHttpRequest request;
    late FakeConfig config;

    setUp(() {
      firestore = FakeFirestoreService();
      request = FakeHttpRequest();
      clientContext = FakeClientContext();
      validator = FakeFirebaseJwtValidator();
      config = FakeConfig();
      auth = ChainOfAuthentication.forProviders([
        DashboardFirebaseAuthentication(
          cache: CacheService.inMemory(),
          clientContextProvider: () => clientContext,
          validator: validator,
          firestore: firestore,
        ),
        GithubAuthentication(
          cache: CacheService.inMemory(),
          config: config,
          validator: validator,
          clientContextProvider: () => clientContext,
        ),
      ]);
    });

    test('succeeds for github account with write permissions', () async {
      const id = 'awesome-id';
      const user = 'awesome-user';
      const email = 'awesome-email@github.com';
      final token = TokenInfo(
        email: email,
        issued: DateTime.now(),
        firebase: const FirebaseJwtClaim(
          identities: {
            'github.com': [id],
          },
        ),
      );
      // Chained providers decode the token twice.
      validator.jwts.addAll([token, token]);

      final mockGitHub = MockGitHub();
      final mockUsersService = MockUsersService();
      when(mockGitHub.users).thenReturn(mockUsersService);

      when(
        mockUsersService.getUser(id),
      ).thenAnswer((_) async => User(login: user));

      when(
        // ignore: discarded_futures
        mockGitHub.request(
          'GET',
          '/repos/flutter/flutter/collaborators/$user/permission',
          fail: anyNamed('fail'),
        ),
      ).thenAnswer((_) async {
        final data = <String, dynamic>{'permission': 'write'};
        return http.Response(json.encode(data), HttpStatus.ok);
      });
      final githubService = GithubService(mockGitHub);

      config.githubService = githubService;
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      final result = await auth.authenticate(request.toRequest());
      expect(result.email, email);
      expect(result.githubLogin, user);
    });

    test(
      'succeeds for github account with write permissions and with non-allowed non-googler firebase jwt linked account',
      () async {
        const id = 'awesome-id';
        const user = 'awesome-user';
        const email = 'awesome-email@gmail.com';
        final token = TokenInfo(
          email: email,
          issued: DateTime.now(),
          firebase: const FirebaseJwtClaim(
            identities: {
              'github.com': [id],
            },
          ),
        );
        // Chained providers decode the token twice.
        validator.jwts.addAll([token, token]);

        final mockGitHub = MockGitHub();
        final mockUsersService = MockUsersService();
        when(mockGitHub.users).thenReturn(mockUsersService);

        when(
          mockUsersService.getUser(id),
        ).thenAnswer((_) async => User(login: user));

        when(
          // ignore: discarded_futures
          mockGitHub.request(
            'GET',
            '/repos/flutter/flutter/collaborators/$user/permission',
            fail: anyNamed('fail'),
          ),
        ).thenAnswer((_) async {
          final data = <String, dynamic>{'permission': 'write'};
          return http.Response(json.encode(data), HttpStatus.ok);
        });
        final githubService = GithubService(mockGitHub);

        config.githubService = githubService;
        request.headers.set('X-Flutter-IdToken', 'trustmebro');
        final result = await auth.authenticate(request.toRequest());
        expect(result.email, email);
        expect(result.githubLogin, user);
      },
    );
  });
}
