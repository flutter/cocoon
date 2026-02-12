// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/mocks.mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
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

  group('GithubAuthentication', () {
    late GithubAuthentication auth;
    late FakeClientContext clientContext;
    late FakeFirebaseJwtValidator validator;
    late FakeHttpRequest request;
    late FakeConfig config;

    setUp(() {
      request = FakeHttpRequest();
      clientContext = FakeClientContext();
      validator = FakeFirebaseJwtValidator();
      config = FakeConfig();
      auth = GithubAuthentication(
        cache: CacheService(inMemory: true),
        config: config,
        validator: validator,
        clientContextProvider: () => clientContext,
      );
    });

    test(
      'succeeds for firebase jwt with github user that has write permissions',
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
        final result = await auth.authenticate(request.toRequest());
        expect(result.email, email);
      },
    );

    test(
      'fails for firebase jwt with github user that has no write permissions',
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
          final data = <String, dynamic>{'permission': 'read'};
          return http.Response(json.encode(data), HttpStatus.ok);
        });
        final githubService = GithubService(mockGitHub);

        config.githubService = githubService;
        request.headers.set('X-Flutter-IdToken', 'trustmebro');
        expect(
          auth.authenticate(request.toRequest()),
          throwsA(isA<Unauthenticated>()),
        );
      },
    );
  });
}
