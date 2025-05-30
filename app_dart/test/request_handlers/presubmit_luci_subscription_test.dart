// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/commit_ref.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/luci_build_service/build_tags.dart';
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';
import '../src/service/fake_ci_yaml_fetcher.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/service/fake_luci_build_service.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/build_bucket_messages.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  late PresubmitLuciSubscription handler;
  late FakeConfig config;
  late MockGitHub mockGitHubClient;
  late FakeHttpRequest request;
  late SubscriptionTester tester;
  late MockRepositoriesService mockRepositoriesService;
  late MockGithubChecksService mockGithubChecksService;
  late MockLuciBuildService mockLuciBuildService;
  late FakeCiYamlFetcher ciYamlFetcher;

  setUp(() async {
    final firestore = FakeFirestoreService();

    config = FakeConfig();
    mockLuciBuildService = MockLuciBuildService();
    mockGithubChecksService = MockGithubChecksService();

    ciYamlFetcher = FakeCiYamlFetcher(
      ciYaml: examplePresubmitRescheduleFusionConfig,
    );
    handler = PresubmitLuciSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      luciBuildService: FakeLuciBuildService(
        config: config,
        firestore: firestore,
      ),
      githubChecksService: mockGithubChecksService,
      authProvider: FakeDashboardAuthentication(),
      ciYamlFetcher: ciYamlFetcher,
    );
    request = FakeHttpRequest();

    tester = SubscriptionTester(request: request);

    mockGitHubClient = MockGitHub();
    mockRepositoriesService = MockRepositoriesService();
    when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);
    config.githubClient = mockGitHubClient;
  });

  test('Requests with repo_owner and repo_name update checks', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);

    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => false);

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux Host Engine',
      userData: PresubmitUserData(
        commit: CommitRef(
          sha: 'abc',
          branch: 'master',
          slug: RepositorySlug('flutter', 'cocoon'),
        ),
        checkRunId: 1,
      ),
    );

    await tester.post(handler);
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).called(1);
  });

  test('Requests when task failed but no need to reschedule', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);

    final userData = PresubmitUserData(
      commit: CommitRef(
        sha: 'abc',
        branch: 'master',
        slug: RepositorySlug('flutter', 'flutter'),
      ),
      checkRunId: 1,
    );
    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux A',
      userData: userData,
    );

    final buildsPubSub = createBuild(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux A',
    );

    await tester.post(handler);
    verifyNever(
      mockLuciBuildService.reschedulePresubmitBuild(
        build: buildsPubSub.build,
        builderName: 'Linux Coverage',
        nextAttempt: 0,
        userData: userData,
      ),
    );
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).called(1);
  });

  test('Requests when task failed but need to reschedule', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: true,
      ),
    ).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux presubmit_max_attempts=2',
      userData: PresubmitUserData(
        commit: CommitRef(
          sha: 'abc',
          branch: 'master',
          slug: RepositorySlug('flutter', 'flutter'),
        ),
        checkRunId: 1,
      ),
    );
    await tester.post(handler);

    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: true,
      ),
    ).called(1);
  });

  test('Build rescheduled when in merge queue', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: true,
      ),
    ).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.INFRA_FAILURE,
      builder: 'Linux A',
      userData: PresubmitUserData(
        commit: CommitRef(
          sha: 'abc',
          branch: 'master',
          slug: RepositorySlug('flutter', 'flutter'),
        ),
        checkRunId: 1,
      ),
      // Merge queue should get extra requeues by default, even without presubmit_max_attempts > 1.
      extraTags: [InMergeQueueBuildTag().toStringPair()],
    );

    when(
      mockLuciBuildService.reschedulePresubmitBuild(
        build: anyNamed('build'),
        builderName: anyNamed('builderName'),
        nextAttempt: anyNamed('nextAttempt'),
        userData: anyNamed('userData'),
      ),
    ).thenAnswer(
      (_) async => bbv2.Build(
        id: Int64(8905920700440101120),
        builder: bbv2.BuilderID(
          bucket: 'luci.flutter.prod',
          project: 'flutter',
          builder: 'Linux B',
        ),
      ),
    );

    /// Create a handler using the mock LuciBuildService instead of the fake.
    final luciHandler = PresubmitLuciSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      luciBuildService: mockLuciBuildService,
      githubChecksService: mockGithubChecksService,
      authProvider: FakeDashboardAuthentication(),
      ciYamlFetcher: ciYamlFetcher,
    );

    await tester.post(luciHandler);
    verify(
      mockLuciBuildService.reschedulePresubmitBuild(
        build: anyNamed('build'),
        builderName: 'Linux A',
        nextAttempt: 2,
        userData: anyNamed('userData'),
      ),
    ).called(1);
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
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
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: false,
      ),
    ).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);

    final userData = PresubmitUserData(
      commit: CommitRef(
        sha: 'abc',
        branch: 'master',
        slug: RepositorySlug('flutter', 'flutter'),
      ),
      checkRunId: 1,
    );

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux C',
      userData: userData,
    );

    final buildsPubSub = createBuild(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux C',
    );

    await tester.post(handler);
    verifyNever(
      mockLuciBuildService.reschedulePresubmitBuild(
        build: buildsPubSub.build,
        builderName: 'Linux C',
        userData: userData,
        nextAttempt: 1,
      ),
    );
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: false,
      ),
    ).called(1);
  });

  test('Build not rescheduled if ci.yaml fails validation.', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: false,
      ),
    ).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);

    final userData = PresubmitUserData(
      checkRunId: 1,
      commit: CommitRef(
        sha: 'abc',
        branch: 'master',
        slug: RepositorySlug('flutter', 'flutter'),
      ),
    );
    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux C',
      userData: userData,
    );

    final buildsPubSub = createBuild(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux C',
    );

    await tester.post(handler);
    verifyNever(
      mockLuciBuildService.reschedulePresubmitBuild(
        build: buildsPubSub.build,
        builderName: 'Linux C',
        userData: userData,
        nextAttempt: 1,
      ),
    );
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: false,
      ),
    ).called(1);
  });

  test('Pubsub rejected if branch is not enabled.', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: false,
      ),
    ).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);

    final userData = PresubmitUserData(
      checkRunId: 1,
      commit: CommitRef(
        sha: 'abc',
        branch: 'main',
        slug: RepositorySlug('flutter', 'flutter'),
      ),
    );
    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux C',
      userData: userData,
    );

    await expectLater(
      tester.post(handler),
      throwsA(
        isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          contains('main is not enabled for this .ci.yaml'),
        ),
      ),
    );
  });

  test('Build contains data from build_large_fields', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
        rescheduled: anyNamed('rescheduled'),
      ),
    ).thenAnswer((_) async => true);
    when(mockGithubChecksService.taskFailed(any)).thenAnswer((_) => true);

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux presubmit_max_attempts=2',
      userData: PresubmitUserData(
        checkRunId: 1,
        commit: CommitRef(
          sha: 'abc',
          branch: 'master',
          slug: RepositorySlug('flutter', 'flutter'),
        ),
      ),
    );

    when(
      mockLuciBuildService.reschedulePresubmitBuild(
        build: captureAnyNamed('build'),
        builderName: anyNamed('builderName'),
        nextAttempt: anyNamed('nextAttempt'),
        userData: anyNamed('userData'),
      ),
    ).thenAnswer((_) async {
      return bbv2.Build(
        id: Int64(8905920700440101120),
        builder: bbv2.BuilderID(
          bucket: 'luci.flutter.prod',
          project: 'flutter',
          builder: 'Linux Coverage',
        ),
      );
    });

    /// Create a handler using the mock LuciBuildService instead of the fake.
    final luciHandler = PresubmitLuciSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      luciBuildService: mockLuciBuildService,
      githubChecksService: mockGithubChecksService,
      authProvider: FakeDashboardAuthentication(),
      ciYamlFetcher: ciYamlFetcher,
    );

    await tester.post(luciHandler);

    final build =
        verify(
              mockLuciBuildService.reschedulePresubmitBuild(
                build: captureAnyNamed('build'),
                builderName: anyNamed('builderName'),
                nextAttempt: anyNamed('nextAttempt'),
                userData: anyNamed('userData'),
              ),
            ).captured[0]
            as bbv2.Build;

    // Check that the build.input.properties extracted from build_large_fields
    // contains the git_ref property encoded in the test data.
    expect(build.input.properties.fields, contains('git_ref'));
  });
}
