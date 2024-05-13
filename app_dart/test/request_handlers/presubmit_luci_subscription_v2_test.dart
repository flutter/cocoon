// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/cocoon_service.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_v2_tester.dart';
import '../src/service/fake_luci_build_service_v2.dart';
import '../src/service/fake_scheduler_v2.dart';
import '../src/utilities/build_bucket_v2_messages.dart';
import '../src/utilities/mocks.dart';

const String ref = 'deadbeef';

void main() {
  late PresubmitLuciSubscriptionV2 handler;
  late FakeConfig config;
  late MockGitHub mockGitHubClient;
  late FakeHttpRequest request;
  late SubscriptionV2Tester tester;
  late MockRepositoriesService mockRepositoriesService;
  late MockGithubChecksServiceV2 mockGithubChecksService;
  late MockLuciBuildServiceV2 mockLuciBuildService;
  late FakeSchedulerV2 scheduler;

  setUp(() async {
    config = FakeConfig();
    mockLuciBuildService = MockLuciBuildServiceV2();

    mockGithubChecksService = MockGithubChecksServiceV2();
    scheduler = FakeSchedulerV2(
      ciYaml: examplePresubmitRescheduleConfig,
      config: config,
      luciBuildService: mockLuciBuildService,
    );

    handler = PresubmitLuciSubscriptionV2(
      cache: CacheService(inMemory: true),
      config: config,
      luciBuildService: FakeLuciBuildServiceV2(config: config),
      githubChecksService: mockGithubChecksService,
      authProvider: FakeAuthenticationProvider(),
      scheduler: scheduler,
    );
    request = FakeHttpRequest();

    tester = SubscriptionV2Tester(
      request: request,
    );

    mockGitHubClient = MockGitHub();
    mockRepositoriesService = MockRepositoriesService();
    when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);
    config.githubClient = mockGitHubClient;
  });

  test('Requests without repo_owner and repo_name do not update checks', () async {
    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux Host Engine',
      addBuildSet: false,
    );

    await tester.post(handler);

    verifyNever(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    );
  });

  test('Requests with repo_owner and repo_name update checks', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);

    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => false);

    const Map<String, dynamic> userDataMap = {
      'repo_owner': 'flutter',
      'repo_name': 'cocoon',
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux Host Engine',
      userData: userDataMap,
    );

    await tester.post(handler);
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).called(1);
  });

  test('Requests when task failed but no need to reschedule', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 1);

    const Map<String, dynamic> userDataMap = {
      'repo_owner': 'flutter',
      'commit_branch': 'main',
      'commit_sha': 'abc',
      'repo_name': 'flutter',
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux A',
      userData: userDataMap,
    );

    final bbv2.BuildsV2PubSub buildsV2PubSub = createBuild(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux A',
    );

    when(
      mockLuciBuildService.rescheduleBuild(
        build: buildsV2PubSub.build,
        builderName: 'Linux Coverage',
        rescheduleAttempt: 0,
        userDataMap: userDataMap,
      ),
    ).thenAnswer(
      (_) async => bbv2.Build(
        id: Int64(8905920700440101120),
        builder: bbv2.BuilderID(bucket: 'luci.flutter.prod', project: 'flutter', builder: 'Linux Coverage'),
      ),
    );

    await tester.post(handler);
    verifyNever(
      mockLuciBuildService.rescheduleBuild(
        build: buildsV2PubSub.build,
        builderName: 'Linux Coverage',
        rescheduleAttempt: 0,
        userDataMap: userDataMap,
      ),
    );
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).called(1);
  });

  test('Requests when task failed but need to reschedule', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: true,
      ),
    ).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 0);

    const Map<String, dynamic> userDataMap = {
      'repo_owner': 'flutter',
      'commit_branch': 'main',
      'commit_sha': 'abc',
      'repo_name': 'flutter',
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux B',
      userData: userDataMap,
    );

    final bbv2.BuildsV2PubSub buildsV2PubSub = createBuild(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux A',
    );

    when(
      mockLuciBuildService.rescheduleBuild(
        build: buildsV2PubSub.build,
        builderName: 'Linux Coverage',
        rescheduleAttempt: 1,
        userDataMap: userDataMap,
      ),
    ).thenAnswer(
      (_) async => bbv2.Build(
        id: Int64(8905920700440101120),
        builder: bbv2.BuilderID(bucket: 'luci.flutter.prod', project: 'flutter', builder: 'Linux B'),
      ),
    );
    await tester.post(handler);
    verifyNever(
      mockLuciBuildService.rescheduleBuild(
        build: buildsV2PubSub.build,
        builderName: 'Linux Coverage',
        rescheduleAttempt: 1,
        userDataMap: userDataMap,
      ),
    );
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: true,
      ),
    ).called(1);
  });

  test('Build not rescheduled if not found in ciYaml list.', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: false,
      ),
    ).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 1);

    const Map<String, dynamic> userDataMap = {
      'repo_owner': 'flutter',
      'commit_branch': 'main',
      'commit_sha': 'abc',
      'repo_name': 'flutter',
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux C',
      userData: userDataMap,
    );

    final bbv2.BuildsV2PubSub buildsV2PubSub = createBuild(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux C',
    );

    await tester.post(handler);
    verifyNever(
      mockLuciBuildService.rescheduleBuild(
        build: buildsV2PubSub.build,
        builderName: 'Linux C',
        userDataMap: userDataMap,
        rescheduleAttempt: 1,
      ),
    );
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: false,
      ),
    ).called(1);
  });

  test('Build not rescheduled if ci.yaml fails validation.', () async {
    scheduler.failCiYamlValidation = true;
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: false,
      ),
    ).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 1);

    final Map<String, dynamic> userDataMap = {
      'repo_owner': 'flutter',
      'commit_branch': Config.defaultBranch(Config.flutterSlug),
      'commit_sha': 'abc',
      'repo_name': 'flutter',
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux C',
      userData: userDataMap,
    );

    final bbv2.BuildsV2PubSub buildsV2PubSub = createBuild(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux C',
    );

    await tester.post(handler);
    verifyNever(
      mockLuciBuildService.rescheduleBuild(
        build: buildsV2PubSub.build,
        builderName: 'Linux C',
        userDataMap: userDataMap,
        rescheduleAttempt: 1,
      ),
    );
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: false,
      ),
    ).called(1);
  });
}
