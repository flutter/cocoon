// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';
import '../src/service/fake_buildbucket.dart';
import '../src/service/fake_scheduler_v2.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/push_message.dart';

const String ref = 'deadbeef';

void main() {
  late PresubmitLuciSubscription handler;
  late FakeConfig config;
  late MockGitHub mockGitHubClient;
  late FakeHttpRequest request;
  late SubscriptionTester tester;
  late MockRepositoriesService mockRepositoriesService;
  late MockGithubChecksService mockGithubChecksService;
  late MockLuciBuildServiceV2 mockLuciBuildService;
  late FakeSchedulerV2 scheduler;
  late FakeBuildBucketClient buildBucketClient;

  setUp(() async {
    config = FakeConfig();
    mockLuciBuildService = MockLuciBuildServiceV2();
    buildBucketClient = FakeBuildBucketClient();

    mockGithubChecksService = MockGithubChecksService();
    scheduler = FakeSchedulerV2(
      ciYaml: examplePresubmitRescheduleConfig,
      config: config,
      luciBuildService: mockLuciBuildService,
    );
    handler = PresubmitLuciSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      buildBucketClient: buildBucketClient,
      githubChecksService: mockGithubChecksService,
      authProvider: FakeAuthenticationProvider(),
      scheduler: scheduler,
    );
    request = FakeHttpRequest();

    tester = SubscriptionTester(
      request: request,
    );

    mockGitHubClient = MockGitHub();
    mockRepositoriesService = MockRepositoriesService();
    when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);
    config.githubClient = mockGitHubClient;
  });

  test('Requests without repo_owner and repo_name do not update checks', () async {
    tester.message = pushMessageJsonNoBuildset(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux Host Engine',
    );

    await tester.post(handler);
    verifyNever(mockGithubChecksService.updateCheckStatus(any, any, any));
  });

  test('Requests with repo_owner and repo_name update checks', () async {
    when(mockGithubChecksService.updateCheckStatus(any, any, any)).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => false);
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux Host Engine',
      userData: '{\\"repo_owner\\": \\"flutter\\", \\"repo_name\\": \\"cocoon\\"}',
    );
    await tester.post(handler);
    verify(mockGithubChecksService.updateCheckStatus(any, any, any)).called(1);
  });

  test('Requests when task failed but no need to reschedule', () async {
    when(mockGithubChecksService.updateCheckStatus(any, any, any)).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux A',
      userData: '{\\"repo_owner\\": \\"flutter\\",'
          '\\"commit_branch\\": \\"main\\",'
          '\\"commit_sha\\": \\"abc\\",'
          '\\"repo_name\\": \\"flutter\\"}',
    );
    await tester.post(handler);
    expect(buildBucketClient.scheduleBuildCalls, 0);
    verify(mockGithubChecksService.updateCheckStatus(any, any, any)).called(1);
  });

  test('Requests when task failed but need to reschedule', () async {
    when(mockGithubChecksService.updateCheckStatus(any, any, any, rescheduled: true)).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux B',
      userData: '{\\"repo_owner\\": \\"flutter\\",'
          '\\"commit_branch\\": \\"main\\",'
          '\\"commit_sha\\": \\"abc\\",'
          '\\"repo_name\\": \\"flutter\\"}',
      // Force a reported attempt count of zero, since the default max retry count is 1.
      retries: -1,
    );
    await tester.post(handler);
    expect(buildBucketClient.scheduleBuildCalls, 1);
    verify(mockGithubChecksService.updateCheckStatus(any, any, any, rescheduled: true)).called(1);
  });

  test('Build not rescheduled if not found in ciYaml list.', () async {
    when(mockGithubChecksService.updateCheckStatus(any, any, any, rescheduled: false)).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      // This builder will not be present.
      builderName: 'Linux C',
      userData: '{\\"repo_owner\\": \\"flutter\\",'
          '\\"commit_branch\\": \\"main\\",'
          '\\"commit_sha\\": \\"abc\\",'
          '\\"repo_name\\": \\"flutter\\"}',
    );
    await tester.post(handler);
    expect(buildBucketClient.scheduleBuildCalls, 0);
    verify(mockGithubChecksService.updateCheckStatus(any, any, any, rescheduled: false)).called(1);
  });
}
