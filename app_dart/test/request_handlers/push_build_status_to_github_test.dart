// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/firestore/github_build_status.dart';
import 'package:cocoon_service/src/request_handlers/push_build_status_to_github.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart' hide Model;
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:cocoon_server/testing/mocks.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('PushStatusToGithub', () {
    late FakeBuildStatusService buildStatusService;
    late MockFirestoreService mockFirestoreService;
    late FakeClientContext clientContext;
    late FakeConfig config;
    late FakeDatastoreDB db;
    late ApiRequestHandlerTester tester;
    late FakeAuthenticatedContext authContext;
    late FakeTabledataResource tabledataResourceApi;
    late PushBuildStatusToGithub handler;
    late MockGitHub github;
    late MockPullRequestsService pullRequestsService;
    late MockIssuesService issuesService;
    late MockRepositoriesService repositoriesService;
    late FakeGithubService githubService;
    RepositorySlug? slug;
    GithubBuildStatus? githubBuildStatus;

    setUp(() async {
      mockFirestoreService = MockFirestoreService();
      clientContext = FakeClientContext();
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      clientContext.isDevelopmentEnvironment = false;
      buildStatusService = FakeBuildStatusService();
      githubService = FakeGithubService();
      tabledataResourceApi = FakeTabledataResource();
      db = FakeDatastoreDB();
      github = MockGitHub();
      pullRequestsService = MockPullRequestsService();
      issuesService = MockIssuesService();
      repositoriesService = MockRepositoriesService();
      config = FakeConfig(
        tabledataResource: tabledataResourceApi,
        githubService: githubService,
        dbValue: db,
        firestoreService: mockFirestoreService,
        githubClient: github,
      );
      tester = ApiRequestHandlerTester(context: authContext);
      handler = PushBuildStatusToGithub(
        config: config,
        authenticationProvider: FakeAuthenticationProvider(clientContext: clientContext),
        buildStatusServiceProvider: (_, __) => buildStatusService,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );

      slug = RepositorySlug('flutter', 'flutter');
      githubBuildStatus = null;

      when(
        mockFirestoreService.queryLastBuildStatus(slug, 123, 'sha1'),
      ).thenAnswer((Invocation invocation) {
        return Future<GithubBuildStatus>.value(
          githubBuildStatus,
        );
      });

      when(github.pullRequests).thenReturn(pullRequestsService);
      when(github.issues).thenReturn(issuesService);
      when(github.repositories).thenReturn(repositoriesService);
      when(repositoriesService.createStatus(any, any, any)).thenAnswer(
        (_) async => RepositoryStatus(),
      );
    });

    test('development environment does nothing', () async {
      clientContext.isDevelopmentEnvironment = true;
      config.githubClient = ThrowingGitHub();
      final Body body = await tester.get<Body>(handler);
      expect(body, same(Body.empty));
    });

    group('does not update anything', () {
      test('if there are no PRs', () async {
        when(pullRequestsService.list(any, base: anyNamed('base')))
            .thenAnswer((_) => const Stream<PullRequest>.empty());
        buildStatusService.cumulativeStatus = BuildStatus.success();
        final Body body = await tester.get<Body>(handler);
        final TableDataList tableDataList = await tabledataResourceApi.list('test', 'test', 'test');
        expect(body, same(Body.empty));

        // Test for BigQuery insert
        expect(tableDataList.totalRows, '1');
      });

      test('only if pull request is for the default branch', () async {
        when(pullRequestsService.list(any)).thenAnswer(
          (_) => Stream<PullRequest>.value(
            generatePullRequest(
              id: 1,
              branch: 'flutter-2.15-candidate.3',
            ),
          ),
        );
        buildStatusService.cumulativeStatus = BuildStatus.success();
        await tester.get<Body>(handler);
        verifyNever(repositoriesService.createStatus(any, any, any));
      });

      test('if status has not changed since last update', () async {
        final PullRequest pr = generatePullRequest(id: 1, sha: 'sha1');
        when(pullRequestsService.list(any, base: anyNamed('base'))).thenAnswer((_) => Stream<PullRequest>.value(pr));
        buildStatusService.cumulativeStatus = BuildStatus.success();
        githubBuildStatus = generateFirestoreGithubBuildStatus(1);
        final Body body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(githubBuildStatus!.updates, 0);
      });

      test('if there is no pr found for a targeted branch', () async {
        final PullRequest pr = generatePullRequest(id: 1, sha: 'sha1', branch: 'test_branch');
        when(pullRequestsService.list(any, base: anyNamed('base'))).thenAnswer((_) => Stream<PullRequest>.value(pr));
        buildStatusService.cumulativeStatus = BuildStatus.success();
        githubBuildStatus = generateFirestoreGithubBuildStatus(1, status: GithubBuildStatus.statusFailure);
        final Body body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(githubBuildStatus!.updates, 0);
        expect(githubBuildStatus!.status, GithubBuildStatus.statusFailure);
      });
    });

    test('updates github and datastore if status has changed since last update', () async {
      when(
        mockFirestoreService.batchWriteDocuments(
          captureAny,
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      final PullRequest pr = generatePullRequest(id: 1, sha: 'sha1');
      when(pullRequestsService.list(any, base: anyNamed('base'))).thenAnswer((_) => Stream<PullRequest>.value(pr));
      buildStatusService.cumulativeStatus = BuildStatus.success();
      githubBuildStatus = generateFirestoreGithubBuildStatus(1, status: GithubBuildStatus.statusFailure);
      final Body body = await tester.get<Body>(handler);
      expect(body, same(Body.empty));
      expect(githubBuildStatus!.updates, 1);
      expect(githubBuildStatus!.updateTimeMillis, isNotNull);
      expect(githubBuildStatus!.status, BuildStatus.success().githubStatus);

      final List<dynamic> captured = verify(mockFirestoreService.batchWriteDocuments(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      final BatchWriteRequest batchWriteRequest = captured[0] as BatchWriteRequest;
      expect(batchWriteRequest.writes!.length, 1);
      final GithubBuildStatus updatedDocument =
          GithubBuildStatus.fromDocument(githubBuildStatus: batchWriteRequest.writes![0].update!);
      expect(updatedDocument.updates, githubBuildStatus!.updates);
    });
  });
}
