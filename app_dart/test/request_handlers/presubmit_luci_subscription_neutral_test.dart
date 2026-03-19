// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/commit_ref.dart';
import 'package:cocoon_service/src/model/common/presubmit_completed_check.dart';
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart' as github;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/request_handling/subscription_tester.dart';

void main() {
  useTestLoggerPerTest();

  late PresubmitLuciSubscription handler;
  late FakeConfig config;
  late MockGitHub mockGitHubClient;
  late FakeHttpRequest request;
  late SubscriptionTester tester;
  late MockRepositoriesService mockRepositoriesService;
  late MockGithubChecksService mockGithubChecksService;
  late FakeCiYamlFetcher ciYamlFetcher;
  late MockScheduler mockScheduler;
  late FakeFirestoreService firestore;

  setUp(() async {
    firestore = FakeFirestoreService();

    config = FakeConfig(
      dynamicConfig: DynamicConfig.fromJson({
        'closeMqGuardAfterPresubmit': true,
      }),
    );
    mockGithubChecksService = MockGithubChecksService();
    mockScheduler = MockScheduler();

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
      scheduler: mockScheduler,
      ciYamlFetcher: ciYamlFetcher,
      firestore: firestore,
    );
    request = FakeHttpRequest();

    tester = SubscriptionTester(request: request);

    mockGitHubClient = MockGitHub();
    mockRepositoriesService = MockRepositoriesService();
    when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);
    config.githubClient = mockGitHubClient;
  });

  test(
    'Requests when task failed and is suppressed reports neutral to scheduler',
    () async {
      final userData = PresubmitUserData(
        commit: CommitRef(
          sha: 'abc',
          branch: 'master',
          slug: github.RepositorySlug('flutter', 'flutter'),
        ),
        checkRunId: 1,
        checkSuiteId: 2,
      );

      // Setup Firestore to mark the test as suppressed
      firestore.putDocument(
        SuppressedTest(
            name: 'Linux A',
            repository: 'flutter/flutter',
            issueLink: 'https://github.com/flutter/flutter/issues/123',
            isSuppressed: true,
            createTimestamp: DateTime.now(),
          )
          ..name = firestore.resolveDocumentName(
            SuppressedTest.kCollectionId,
            'suppressed_1',
          ),
      );

      when(
        mockGithubChecksService.updateCheckStatus(
          build: anyNamed('build'),
          checkRunId: anyNamed('checkRunId'),
          luciBuildService: anyNamed('luciBuildService'),
          slug: anyNamed('slug'),
          conclusionOverride: github.CheckRunConclusion.neutral,
          summaryPrepend: anyNamed('summaryPrepend'),
        ),
      ).thenAnswer((_) async => true);

      when(
        mockScheduler.processCheckRunCompleted(any),
      ).thenAnswer((_) async => true);

      tester.message = createPushMessage(
        Int64(1),
        status: bbv2.Status.FAILURE,
        builder: 'Linux A',
        userData: userData,
      );

      await tester.post(handler);

      // Verify that updateCheckStatus was called with neutral override
      verify(
        mockGithubChecksService.updateCheckStatus(
          build: anyNamed('build'),
          checkRunId: 1,
          luciBuildService: anyNamed('luciBuildService'),
          slug: github.RepositorySlug('flutter', 'flutter'),
          conclusionOverride: github.CheckRunConclusion.neutral,
          summaryPrepend: argThat(
            contains(
              '### ⚠️ Test failed but marked as suppressed on dashboard',
            ),
            named: 'summaryPrepend',
          ),
        ),
      ).called(1);

      // Verify that processCheckRunCompleted was called with TaskStatus.neutral
      final captured = verify(
        mockScheduler.processCheckRunCompleted(captureAny),
      ).captured;
      expect(captured, hasLength(1));
      expect(
        captured[0],
        isA<PresubmitCompletedCheck>().having(
          (e) => e.status,
          'status',
          TaskStatus.neutral,
        ),
      );
    },
  );

  test(
    'Requests when task failed and is NOT suppressed reports failure to scheduler',
    () async {
      final userData = PresubmitUserData(
        commit: CommitRef(
          sha: 'abc',
          branch: 'master',
          slug: github.RepositorySlug('flutter', 'flutter'),
        ),
        checkRunId: 1,
        checkSuiteId: 2,
      );

      // Suppression is NOT set up in Firestore

      when(
        mockGithubChecksService.updateCheckStatus(
          build: anyNamed('build'),
          checkRunId: anyNamed('checkRunId'),
          luciBuildService: anyNamed('luciBuildService'),
          slug: anyNamed('slug'),
          conclusionOverride: null,
          summaryPrepend: null,
        ),
      ).thenAnswer((_) async => true);

      when(
        mockScheduler.processCheckRunCompleted(any),
      ).thenAnswer((_) async => true);

      tester.message = createPushMessage(
        Int64(1),
        status: bbv2.Status.FAILURE,
        builder: 'Linux A',
        userData: userData,
      );

      await tester.post(handler);

      // Verify that updateCheckStatus was called without neutral override
      verify(
        mockGithubChecksService.updateCheckStatus(
          build: anyNamed('build'),
          checkRunId: 1,
          luciBuildService: anyNamed('luciBuildService'),
          slug: github.RepositorySlug('flutter', 'flutter'),
          conclusionOverride: null,
          summaryPrepend: null,
        ),
      ).called(1);

      // Verify that processCheckRunCompleted was called with TaskStatus.failed
      final captured = verify(
        mockScheduler.processCheckRunCompleted(captureAny),
      ).captured;
      expect(captured, hasLength(1));
      expect(
        captured[0],
        isA<PresubmitCompletedCheck>().having(
          (e) => e.status,
          'status',
          TaskStatus.failed,
        ),
      );
    },
  );
}
