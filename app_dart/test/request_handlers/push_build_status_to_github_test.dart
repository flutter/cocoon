// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/github_build_status_update.dart';
import 'package:cocoon_service/src/request_handlers/push_build_status_to_github.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:github/server.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_build_status_provider.dart';

void main() {
  group('PushBuildStatusToGithub', () {
    FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticatedContext authContext;
    FakeAuthenticationProvider auth;
    FakeDatastoreDB db;
    FakeLogging log;
    FakeBuildStatusProvider buildStatusProvider;
    ApiRequestHandlerTester tester;
    PushBuildStatusToGithub handler;
    FakeTabledataResourceApi tabledataResourceApi;

    setUp(() {
      clientContext = FakeClientContext();
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      buildStatusProvider = FakeBuildStatusProvider();
      tabledataResourceApi = FakeTabledataResourceApi();
      config = FakeConfig(tabledataResourceApi: tabledataResourceApi);
      db = FakeDatastoreDB();
      log = FakeLogging();
      tester = ApiRequestHandlerTester(context: authContext);
      handler = PushBuildStatusToGithub(
        config,
        auth,
        datastoreProvider: () => DatastoreService(db: db),
        loggingProvider: () => log,
        buildStatusProvider: buildStatusProvider,
      );
    });

    group('in development environment', () {
      setUp(() {
        clientContext.isDevelopmentEnvironment = true;
      });

      test('Does nothing', () async {
        config.githubClient = ThrowingGitHub();
        db.onCommit =
            (List<gcloud_db.Model> insert, List<gcloud_db.Key> deletes) => throw AssertionError();
        db.addOnQuery<GithubBuildStatusUpdate>(
            (Iterable<GithubBuildStatusUpdate> results) {
          throw AssertionError();
        });
        final Body body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
      });
    });

    group('in non-development environment', () {
      MockGitHub github;
      MockPullRequestsService pullRequestsService;
      MockRepositoriesService repositoriesService;
      List<PullRequest> prsFromGitHub;

      setUp(() {
        github = MockGitHub();
        pullRequestsService = MockPullRequestsService();
        repositoriesService = MockRepositoriesService();
        when(github.pullRequests).thenReturn(pullRequestsService);
        when(github.repositories).thenReturn(repositoriesService);
        when(pullRequestsService.list(any)).thenAnswer((Invocation _) {
          return Stream<PullRequest>.fromIterable(prsFromGitHub);
        });
        config.githubClient = github;
        clientContext.isDevelopmentEnvironment = false;
      });

      GithubBuildStatusUpdate newStatusUpdate(
          PullRequest pr, BuildStatus status) {
        return GithubBuildStatusUpdate(
          key: db.emptyKey.append(GithubBuildStatusUpdate),
          status: status.githubStatus,
          pr: pr.number,
          head: pr.head.sha,
          updates: 0,
        );
      }

      PullRequest newPullRequest({@required int id, @required String sha}) {
        return PullRequest()
          ..number = 123
          ..head = (PullRequestHead()..sha = 'abc');
      }

      group('does not update anything', () {
        setUp(() {
          db.onCommit =
              (List<gcloud_db.Model> insert, List<gcloud_db.Key> deletes) => throw AssertionError();
          when(repositoriesService.createStatus(any, any, any))
              .thenThrow(AssertionError());
        });

        test('if there are no PRs', () async {
          prsFromGitHub = <PullRequest>[];
          buildStatusProvider.cumulativeStatus = BuildStatus.succeeded;
          final Body body = await tester.get<Body>(handler);
          final TableDataList tableDataList = await tabledataResourceApi.list('test', 'test', 'test');
          expect(body, same(Body.empty));
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
          /// Test for [BigQuery] insert
          expect(tableDataList.totalRows, '1');
        });

        test('if status has not changed since last update', () async {
          final PullRequest pr = newPullRequest(id: 123, sha: 'abc');
          prsFromGitHub = <PullRequest>[pr];
          buildStatusProvider.cumulativeStatus = BuildStatus.succeeded;
          final GithubBuildStatusUpdate status =
              newStatusUpdate(pr, BuildStatus.succeeded);
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });
      });

      group('updates GitHub and datastore', () {
        test('if status has changed since last update', () async {
          final PullRequest pr = newPullRequest(id: 123, sha: 'abc');
          prsFromGitHub = <PullRequest>[pr];
          buildStatusProvider.cumulativeStatus = BuildStatus.succeeded;
          final GithubBuildStatusUpdate status =
              newStatusUpdate(pr, BuildStatus.failed);
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, BuildStatus.succeeded.githubStatus);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });
      });
    });
  });
}

class ThrowingGitHub implements GitHub {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw AssertionError();
}

class MockGitHub extends Mock implements GitHub {}

class MockPullRequestsService extends Mock implements PullRequestsService {}

class MockRepositoriesService extends Mock implements RepositoriesService {}
