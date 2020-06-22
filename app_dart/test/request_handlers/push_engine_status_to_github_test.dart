// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/model/appengine/github_build_status_update.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/push_engine_status_to_github.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/luci.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_github_service.dart';

void main() {
  group('PushEngineStatusToGithub', () {
    FakeConfig config;
    FakeDatastoreDB db;
    ApiRequestHandlerTester tester;
    FakeClientContext clientContext;
    FakeAuthenticatedContext authContext;
    MockLuciService mockLuciService;
    PushEngineStatusToGithub handler;
    MockGitHub github;
    MockPullRequestsService pullRequestsService;
    MockIssuesService issuesService;
    MockRepositoriesService repositoriesService;
    List<PullRequest> prsFromGitHub;
    FakeGithubService githubService;

    PullRequest newPullRequest(int number, String sha, String baseRef,
        {bool draft = false}) {
      return PullRequest()
        ..number = 123
        ..head = (PullRequestHead()..sha = 'abc')
        ..base = (PullRequestHead()..ref = baseRef)
        ..draft = draft;
    }

    GithubBuildStatusUpdate newStatusUpdate(
        PullRequest pr, BuildStatus status) {
      return GithubBuildStatusUpdate(
        key: db.emptyKey.append(GithubBuildStatusUpdate, id: pr.number),
        status: status.githubStatus,
        pr: pr.number,
        head: pr.head.sha,
        updates: 0,
      );
    }

    setUp(() {
      clientContext = FakeClientContext();
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      clientContext.isDevelopmentEnvironment = false;
      githubService = FakeGithubService();
      db = FakeDatastoreDB();
      github = MockGitHub();
      pullRequestsService = MockPullRequestsService();
      issuesService = MockIssuesService();
      repositoriesService = MockRepositoriesService();
      config = FakeConfig(
        luciBuildersValue: const <Map<String, String>>[
          <String, String>{
            'name': 'Builder1',
            'repo': 'flutter',
            'taskName': 'foo',
          },
        ],
        githubService: githubService,
        dbValue: db,
        githubClient: github,
      );
      tester = ApiRequestHandlerTester(context: authContext);
      mockLuciService = MockLuciService();
      handler = PushEngineStatusToGithub(
        config,
        FakeAuthenticationProvider(clientContext: clientContext),
        luciServiceProvider: (_) => mockLuciService,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );

      when(github.pullRequests).thenReturn(pullRequestsService);
      when(github.issues).thenReturn(issuesService);
      when(github.repositories).thenReturn(repositoriesService);
      when(pullRequestsService.list(any)).thenAnswer((Invocation _) {
        return Stream<PullRequest>.fromIterable(prsFromGitHub);
      });
      when(repositoriesService.createStatus(any, any, any)).thenAnswer(
        (_) => Future<RepositoryStatus>.value(),
      );
    });

    test('update engine status in datastore when status changes', () async {
      final PullRequest pr = newPullRequest(123, 'abc', 'master');
      prsFromGitHub = <PullRequest>[pr];

      final GithubBuildStatusUpdate status =
          newStatusUpdate(pr, BuildStatus.succeeded);
      config.db.values[status.key] = status;

      final Map<LuciBuilder, List<LuciTask>> luciTasks =
          Map<LuciBuilder, List<LuciTask>>.fromIterable(
        await LuciBuilder.getBuilders(config),
        key: (dynamic builder) => builder as LuciBuilder,
        value: (dynamic builder) => <LuciTask>[
          const LuciTask(
              commitSha: 'abc',
              ref: 'refs/heads/master',
              status: Task.statusFailed,
              buildNumber: 1)
        ],
      );
      when(mockLuciService.getRecentTasks(repo: 'engine'))
          .thenAnswer((Invocation invocation) {
        return Future<Map<LuciBuilder, List<LuciTask>>>.value(luciTasks);
      });

      expect(status.status, 'success');
      await tester.get(handler);
      expect(status.status, 'failure');
      expect(status.updateTimeMillis, isNotNull);
    });
  });
}

// ignore: must_be_immutable
class MockLuciService extends Mock implements LuciService {}

class MockGitHub extends Mock implements GitHub {}

class MockIssuesService extends Mock implements IssuesService {}

class MockPullRequestsService extends Mock implements PullRequestsService {}

class MockRepositoriesService extends Mock implements RepositoriesService {}
