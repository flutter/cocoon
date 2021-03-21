// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handlers/reset_try_task.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('ResetTryTask', () {
    FakeClientContext clientContext;
    ResetTryTask handler;
    FakeConfig config;
    MockLuciBuildService mockLuciBuildService;
    FakeAuthenticatedContext authContext;
    ApiRequestHandlerTester tester;

    setUp(() {
      clientContext = FakeClientContext();
      clientContext.isDevelopmentEnvironment = false;
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      config = FakeConfig();
      tester = ApiRequestHandlerTester(context: authContext);
      mockLuciBuildService = MockLuciBuildService();
      handler = ResetTryTask(
        config,
        FakeAuthenticationProvider(clientContext: clientContext),
        mockLuciBuildService,
      );
    });

    test('Empty repo', () async {
      tester.request = FakeHttpRequest(queryParametersValue: <String, String>{
        'pr': '123',
        'commitSha': 'commitAbc',
      });
      expect(() => tester.get(handler), throwsA(isA<BadRequestException>()));
    });
    test('Empty commitSha', () async {
      tester.request = FakeHttpRequest(queryParametersValue: <String, String>{
        'pr': '123',
        'repo': 'flutter',
      });
      expect(() => tester.get(handler), throwsA(isA<BadRequestException>()));
    });
    test('Empty pr', () async {
      tester.request = FakeHttpRequest(queryParametersValue: <String, String>{
        'commitSha': 'commitAbc',
        'repo': 'flutter',
      });
      expect(() => tester.get(handler), throwsA(isA<BadRequestException>()));
    });

    test('Trigger builds if all parameters are correct', () async {
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
      tester.request = FakeHttpRequest(queryParametersValue: <String, String>{
        'commitSha': 'commitAbc',
        'repo': 'flutter',
        'pr': '123',
      });
      await tester.get(handler);
      expect(
        verify(mockLuciBuildService.scheduleTryBuilds(
          commitSha: captureAnyNamed('commitSha'),
          prNumber: captureAnyNamed('prNumber'),
          slug: captureAnyNamed('slug'),
          checkSuiteEvent: anyNamed('checkSuiteEvent'),
        )).captured,
        <dynamic>['commitAbc', 123, slug],
      );
    });
  });
}
