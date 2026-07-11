// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/commit_ref.dart';
import 'package:cocoon_service/src/service/luci_build_service/build_tags.dart';
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart' as github;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/request_handling/subscription_tester.dart';

void main() {
  useTestLoggerPerTest();

  late PresubmitLuciSubscriptionOrdered handler;
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

    config = FakeConfig();
    mockGithubChecksService = MockGithubChecksService();
    mockScheduler = MockScheduler();

    ciYamlFetcher = FakeCiYamlFetcher(
      ciYaml: examplePresubmitRescheduleFusionConfig,
    );

    handler = PresubmitLuciSubscriptionOrdered(
      cache: CacheService.inMemory(),
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

  test('ordered subscription processes ordered messages directly without forwarding', () async {
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);

    when(
      mockGithubChecksService.conclusionForResult(any),
    ).thenAnswer((_) => github.CheckRunConclusion.empty);
    when(
      mockScheduler.processCheckRunCompleted(any),
    ).thenAnswer((_) async => true);

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux Host Engine',
      userData: PresubmitUserData(
        commit: CommitRef(
          sha: 'abc',
          branch: 'master',
          slug: github.RepositorySlug('flutter', 'cocoon'),
        ),
        checkRunId: 1,
        checkSuiteId: 2,
      ),
      extraTags: [OrderingKeyTag(orderingKey: 'abc123ordering').toStringPair()],
    );

    final response = await tester.post(handler);

    expect(response, Response.emptyOk);
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).called(1);
    verify(mockScheduler.processCheckRunCompleted(any)).called(1);
  });
}
