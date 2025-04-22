// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/github_build_status.dart';
import 'package:cocoon_service/src/request_handlers/push_build_status_to_github.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/config.dart' show Config;
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  late FakeBuildStatusService buildStatusService;
  late FakeFirestoreService firestore;
  late FakeClientContext clientContext;
  late FakeConfig config;
  late ApiRequestHandlerTester tester;
  late FakeAuthenticatedContext authContext;
  late FakeTabledataResource tabledataResourceApi;
  late PushBuildStatusToGithub handler;
  late MockGitHub github;
  late MockPullRequestsService pullRequestsService;
  late MockIssuesService issuesService;
  late MockRepositoriesService repositoriesService;
  late FakeGithubService githubService;

  setUp(() async {
    firestore = FakeFirestoreService();
    clientContext = FakeClientContext();
    authContext = FakeAuthenticatedContext(clientContext: clientContext);
    clientContext.isDevelopmentEnvironment = false;
    buildStatusService = FakeBuildStatusService();
    githubService = FakeGithubService();
    tabledataResourceApi = FakeTabledataResource();
    github = MockGitHub();
    pullRequestsService = MockPullRequestsService();
    issuesService = MockIssuesService();
    repositoriesService = MockRepositoriesService();
    config = FakeConfig(
      bigqueryService: BigqueryService.forTesting(
        tabledataResourceApi,
        MockJobsResource(),
      ),
      githubService: githubService,
      githubClient: github,
    );
    tester = ApiRequestHandlerTester(context: authContext);
    handler = PushBuildStatusToGithub(
      config: config,
      authenticationProvider: FakeDashboardAuthentication(
        clientContext: clientContext,
      ),
      buildStatusService: buildStatusService,
      firestore: firestore,
    );

    when(github.pullRequests).thenReturn(pullRequestsService);
    when(github.issues).thenReturn(issuesService);
    when(github.repositories).thenReturn(repositoriesService);
    when(
      repositoriesService.createStatus(any, any, any),
    ).thenAnswer((_) async => RepositoryStatus());
  });

  test('development environment does nothing', () async {
    clientContext.isDevelopmentEnvironment = true;
    config.githubClient = ThrowingGitHub();
    final body = await tester.get<Body>(handler);
    expect(body, same(Body.empty));
  });

  group('does not update anything', () {
    test('if there are no PRs', () async {
      when(
        pullRequestsService.list(any, base: anyNamed('base')),
      ).thenAnswer((_) => const Stream<PullRequest>.empty());
      buildStatusService.cumulativeStatus = BuildStatus.success();
      final body = await tester.get<Body>(handler);
      final tableDataList = await tabledataResourceApi.list(
        'test',
        'test',
        'test',
      );
      expect(body, same(Body.empty));

      // Test for BigQuery insert
      expect(tableDataList.totalRows, '1');
    });

    test('only if pull request is for the default branch', () async {
      when(pullRequestsService.list(any, base: anyNamed('base'))).thenAnswer(
        (_) => Stream<PullRequest>.value(
          generatePullRequest(id: 1, branch: 'flutter-2.15-candidate.3'),
        ),
      );
      buildStatusService.cumulativeStatus = BuildStatus.success();
      await tester.get<Body>(handler);
      verifyNever(repositoriesService.createStatus(any, any, any));
    });

    test('if status has not changed since last update', () async {
      final pr = generatePullRequest(id: 1, headSha: 'sha1');
      when(
        pullRequestsService.list(any, base: anyNamed('base')),
      ).thenAnswer((_) => Stream<PullRequest>.value(pr));
      buildStatusService.cumulativeStatus = BuildStatus.success();

      firestore.putDocument(
        generateFirestoreGithubBuildStatus(
          1,
          pr: pr.number!,
          head: pr.head!.sha!,
        ),
      );

      final body = await tester.get<Body>(handler);
      expect(body, same(Body.empty));

      expect(
        firestore,
        existsInStorage(GithubBuildStatus.metadata, [
          isGithubBuildStatus.hasUpdates(0),
        ]),
      );
    });

    test('if there is no pr found for a targeted branch', () async {
      final pr = generatePullRequest(
        id: 1,
        headSha: 'sha1',
        branch: 'test_branch',
      );
      when(
        pullRequestsService.list(any, base: anyNamed('base')),
      ).thenAnswer((_) => Stream<PullRequest>.value(pr));
      buildStatusService.cumulativeStatus = BuildStatus.success();

      firestore.putDocument(
        generateFirestoreGithubBuildStatus(
          1,
          pr: pr.number!,
          head: pr.head!.sha!,
          status: GithubBuildStatus.statusFailure,
        ),
      );

      final body = await tester.get<Body>(handler);
      expect(body, same(Body.empty));

      expect(
        firestore,
        existsInStorage(GithubBuildStatus.metadata, [
          isGithubBuildStatus
              .hasUpdates(0)
              .hasStatus(GithubBuildStatus.statusFailure),
        ]),
      );
    });
  });

  test(
    'updates github and Firestore if status has changed since last update',
    () async {
      final pr = generatePullRequest(id: 1, headSha: 'sha1');
      when(
        pullRequestsService.list(any, base: anyNamed('base')),
      ).thenAnswer((_) => Stream<PullRequest>.value(pr));
      buildStatusService.cumulativeStatus = BuildStatus.success();
      firestore.putDocument(
        generateFirestoreGithubBuildStatus(
          1,
          pr: pr.number!,
          head: pr.head!.sha!,
          status: GithubBuildStatus.statusFailure,
        ),
      );

      final body = await tester.get<Body>(handler);

      expect(body, same(Body.empty));

      expect(
        firestore,
        existsInStorage(GithubBuildStatus.metadata, [
          isGithubBuildStatus
              .hasUpdates(1)
              .hasStatus(GithubBuildStatus.statusSuccess),
        ]),
      );
    },
  );

  test('updates github and Firestore if status is neutral', () async {
    final pr = generatePullRequest(
      id: 1,
      headSha: 'sha1',
      labels: [IssueLabel(name: Config.kEmergencyLabel)],
    );
    when(
      pullRequestsService.list(any, base: anyNamed('base')),
    ).thenAnswer((_) => Stream<PullRequest>.value(pr));
    buildStatusService.cumulativeStatus = BuildStatus.failure(const [
      'all bad',
    ]);
    firestore.putDocument(
      generateFirestoreGithubBuildStatus(
        1,
        pr: pr.number!,
        head: pr.head!.sha!,
        status: GithubBuildStatus.statusFailure,
      ),
    );

    final body = await tester.get<Body>(handler);
    expect(body, same(Body.empty));

    expect(
      firestore,
      existsInStorage(GithubBuildStatus.metadata, [
        isGithubBuildStatus
            .hasUpdates(1)
            .hasStatus(GithubBuildStatus.statusNeutral),
      ]),
    );
  });
}
