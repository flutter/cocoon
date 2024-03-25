// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handlers/reset_try_task.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  // group('ResetTryTask', () {
  //   late ApiRequestHandlerTester tester;
  //   FakeClientContext clientContext;
  //   late ResetTryTask handler;
  //   late FakeConfig config;
  //   FakeScheduler fakeScheduler;
  //   FakeAuthenticatedContext authContext;
  //   MockGitHub mockGithub;
  //   MockPullRequestsService mockPullRequestsService;
  //   late MockGithubChecksUtil mockGithubChecksUtil;

  //   setUp(() {
  //     clientContext = FakeClientContext();
  //     clientContext.isDevelopmentEnvironment = false;
  //     authContext = FakeAuthenticatedContext(clientContext: clientContext);
  //     mockGithub = MockGitHub();
  //     mockPullRequestsService = MockPullRequestsService();
  //     config = FakeConfig(githubClient: mockGithub, githubService: FakeGithubService());
  //     mockGithubChecksUtil = MockGithubChecksUtil();
  //     tester = ApiRequestHandlerTester(context: authContext);
  //     fakeScheduler = FakeScheduler(
  //       config: config,
  //       githubChecksUtil: mockGithubChecksUtil,
  //     );
  //     handler = ResetTryTask(
  //       config: config,
  //       authenticationProvider: FakeAuthenticationProvider(clientContext: clientContext),
  //       scheduler: fakeScheduler,
  //     );
  //     when(mockGithub.pullRequests).thenReturn(mockPullRequestsService);
  //     when(mockPullRequestsService.get(any, 123)).thenAnswer((_) async => generatePullRequest(id: 123));
  //   });

  //   test('Empty repo', () async {
  //     tester.request = FakeHttpRequest(
  //       queryParametersValue: <String, String>{
  //         'pr': '123',
  //       },
  //     );
  //     expect(() => tester.get(handler), throwsA(isA<BadRequestException>()));
  //   });

  //   test('Empty pr', () async {
  //     tester.request = FakeHttpRequest(
  //       queryParametersValue: <String, String>{
  //         'repo': 'flutter',
  //       },
  //     );
  //     expect(() => tester.get(handler), throwsA(isA<BadRequestException>()));
  //   });

  //   test('Trigger builds if all parameters are correct', () async {
  //     when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output'))).thenAnswer((_) async {
  //       return CheckRun.fromJson(const <String, dynamic>{
  //         'id': 1,
  //         'started_at': '2020-05-10T02:49:31Z',
  //         'check_suite': <String, dynamic>{'id': 2},
  //       });
  //     });
  //     tester.request = FakeHttpRequest(
  //       queryParametersValue: <String, String>{
  //         ResetTryTask.kRepoParam: 'flutter',
  //         ResetTryTask.kPullRequestNumberParam: '123',
  //       },
  //     );
  //     expect(await tester.get(handler), Body.empty);
  //   });

  //   test('Parses empty builder correctly', () {
  //     final List<String> builders = handler.getBuilderList('');
  //     expect(builders.isEmpty, true);
  //   });

  //   test('Parses non-empty builder correctly', () {
  //     expect(handler.getBuilderList('a, b, c'), <String>['a', 'b', 'c']);
  //   });
  // });
}
