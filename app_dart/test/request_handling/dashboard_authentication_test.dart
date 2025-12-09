// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_server_test/mocks.mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/account.dart';
import 'package:cocoon_service/src/model/google/firebase_jwt_claim.dart';
import 'package:cocoon_service/src/model/google/token_info.dart';
import 'package:cocoon_service/src/request_handling/dashboard_authentication.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/request_handling/fake_http.dart';
// import '../src/service/fake_firebase_jwt_validator.dart';
import '../src/service/fake_firebase_jwt_validator.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/utilities/mocks.dart';

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
      final result = await auth.authenticate(request);
      expect(result.clientContext, same(clientContext));
    });

    test('throws for non App Engine cronjobs', () async {
      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });
  });

  group('DashboardFirebaseAuthentication', () {
    late DashboardFirebaseAuthentication auth;
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
      auth = DashboardFirebaseAuthentication(
        cache: CacheService(inMemory: true),
        config: config,
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
      final result = await auth.authenticate(request);
      expect(result.email, 'abc123@google.com');
    });

    test('succeeds for firebase jwt with allowed non-googler', () async {
      firestore.putDocument(Account(email: 'abc123@gmail.com'));
      validator.jwts.add(
        TokenInfo(email: 'abc123@gmail.com', issued: DateTime.now()),
      );
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      final result = await auth.authenticate(request);
      expect(result.email, 'abc123@gmail.com');
    });

    test(
      'succeeds for firebase jwt with github user that have write permissions',
      () async {
        const id = 'awesome-id';
        const user = 'awesome-user';
        const email = 'awesome-email@github.com';
        validator.jwts.add(
          TokenInfo(
            email: email,
            issued: DateTime.now(),
            firebase: const FirebaseJwtClaim(
              identities: {
                'github.com': [id],
              },
            ),
          ),
        );

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
        final result = await auth.authenticate(request);
        expect(result.email, email);
      },
    );

    test('fails for firebase jwt with non-allowed non-googler', () async {
      validator.jwts.add(
        TokenInfo(email: 'abc123@gmail.com', issued: DateTime.now()),
      );
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });

    test('fails for non-firebase jwt', () {
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });
  });
}
