// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart' as bb;
import 'package:cocoon_service/src/model/luci/push_message.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';
import '../src/service/fake_buildbucket.dart';
import '../src/service/fake_luci_build_service.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/push_message.dart';

const String ref = 'deadbeef';

void main() {
  late PresubmitLuciSubscription handler;
  late FakeBuildBucketClient buildbucket;
  late FakeConfig config;
  late MockGitHub mockGitHubClient;
  late FakeHttpRequest request;
  late SubscriptionTester tester;
  late MockRepositoriesService mockRepositoriesService;
  late MockGithubChecksService mockGithubChecksService;
  late MockLuciBuildService mockLuciBuildService;
  late FakeScheduler scheduler;

  setUp(() async {
    config = FakeConfig();
    buildbucket = FakeBuildBucketClient();
    mockLuciBuildService = MockLuciBuildService();

    mockGithubChecksService = MockGithubChecksService();
    scheduler = FakeScheduler(
      ciYaml: examplePresubmitRescheduleConfig,
      config: config,
      luciBuildService: mockLuciBuildService,
    );
    handler = PresubmitLuciSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      buildBucketClient: buildbucket,
      luciBuildService: FakeLuciBuildService(config: config),
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
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 1);
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux A',
      userData: '{\\"repo_owner\\": \\"flutter\\",'
          '\\"commit_branch\\": \\"main\\",'
          '\\"commit_sha\\": \\"abc\\",'
          '\\"repo_name\\": \\"flutter\\"}',
    );
    when(
      mockLuciBuildService.rescheduleBuild(
        builderName: 'Linux Coverage',
        buildPushMessage: BuildPushMessage.fromPushMessage(tester.message),
        rescheduleAttempt: 0,
      ),
    ).thenAnswer(
      (_) async => const bb.Build(
        id: '8905920700440101120',
        builderId: bb.BuilderId(bucket: 'luci.flutter.prod', project: 'flutter', builder: 'Linux Coverage'),
      ),
    );
    await tester.post(handler);
    verifyNever(
      mockLuciBuildService.rescheduleBuild(
        builderName: 'Linux Coverage',
        buildPushMessage: BuildPushMessage.fromPushMessage(tester.message),
        rescheduleAttempt: 0,
      ),
    );
    verify(mockGithubChecksService.updateCheckStatus(any, any, any)).called(1);
  });
  test('Requests when task failed but need to reschedule', () async {
    when(mockGithubChecksService.updateCheckStatus(any, any, any, rescheduled: true)).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 0);
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux B',
      userData: '{\\"repo_owner\\": \\"flutter\\",'
          '\\"commit_branch\\": \\"main\\",'
          '\\"commit_sha\\": \\"abc\\",'
          '\\"repo_name\\": \\"flutter\\"}',
    );
    when(
      mockLuciBuildService.rescheduleBuild(
        builderName: 'Linux Coverage',
        buildPushMessage: BuildPushMessage.fromPushMessage(tester.message),
        rescheduleAttempt: 1,
      ),
    ).thenAnswer(
      (_) async => const bb.Build(
        id: '8905920700440101120',
        builderId: bb.BuilderId(bucket: 'luci.flutter.prod', project: 'flutter', builder: 'Linux B'),
      ),
    );
    await tester.post(handler);
    verifyNever(
      mockLuciBuildService.rescheduleBuild(
        builderName: 'Linux B',
        buildPushMessage: BuildPushMessage.fromPushMessage(tester.message),
        rescheduleAttempt: 1,
      ),
    );
    verify(mockGithubChecksService.updateCheckStatus(any, any, any, rescheduled: true)).called(1);
  });

  test('Build not rescheduled if not found in ciYaml list.', () async {
    when(mockGithubChecksService.updateCheckStatus(any, any, any, rescheduled: false)).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 1);
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
    verifyNever(
      mockLuciBuildService.rescheduleBuild(
        builderName: 'Linux C',
        buildPushMessage: BuildPushMessage.fromPushMessage(tester.message),
        rescheduleAttempt: 1,
      ),
    );
    verify(mockGithubChecksService.updateCheckStatus(any, any, any, rescheduled: false)).called(1);
  });
}
