// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/github_build_status_update.dart';
import 'package:cocoon_service/src/request_handlers/push_build_status_to_github.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('PushBuildStatusToGithub', () {
    FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticatedContext authContext;
    FakeAuthenticationProvider auth;
    FakeDatastoreDB db;
    FakeLogging log;
    FakeBuildStatusService buildStatusService;
    ApiRequestHandlerTester tester;
    PushBuildStatusToGithub handler;
    FakeTabledataResourceApi tabledataResourceApi;
    FakeHttpClient branchHttpClient;
    List<int> githubPullRequestsMaster;
    List<int> githubPullRequestsOther;
    MockRepositoriesService repositoriesService;

    List<PullRequest> pullRequestList(String branch) {
      final List<PullRequest> pullRequests = <PullRequest>[];
      for (final int pr in (branch == 'master') ? githubPullRequestsMaster : githubPullRequestsOther) {
        pullRequests.add(PullRequest()
          ..number = pr
          ..head = (PullRequestHead()..sha = pr.toString()));
      }
      return pullRequests;
    }

    setUp(() {
      clientContext = FakeClientContext();
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      buildStatusService = FakeBuildStatusService();
      tabledataResourceApi = FakeTabledataResourceApi();
      branchHttpClient = FakeHttpClient();
      final FakeGithubService githubService = FakeGithubService();
      db = FakeDatastoreDB();
      config = FakeConfig(tabledataResourceApi: tabledataResourceApi, githubService: githubService, dbValue: db);
      log = FakeLogging();
      tester = ApiRequestHandlerTester(context: authContext);
      handler = PushBuildStatusToGithub(
        config,
        auth,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        loggingProvider: () => log,
        buildStatusServiceProvider: (_) => buildStatusService,
        branchHttpClientProvider: () => branchHttpClient,
        gitHubBackoffCalculator: (int attempt) => Duration.zero,
      );

      githubPullRequestsMaster = <int>[];
      githubPullRequestsOther = <int>[];
      githubService.listPullRequestsBranch = (String branch) {
        return pullRequestList(branch);
      };

      repositoriesService = MockRepositoriesService();
      when(githubService.github.repositories).thenReturn(repositoriesService);
    });

    group('in development environment', () {
      setUp(() {
        clientContext.isDevelopmentEnvironment = true;
      });

      test('Does nothing', () async {
        config.githubClient = ThrowingGitHub();
        db.onCommit =
            (List<gcloud_db.Model<dynamic>> insert, List<gcloud_db.Key<dynamic>> deletes) => throw AssertionError();
        db.addOnQuery<GithubBuildStatusUpdate>((Iterable<GithubBuildStatusUpdate> results) {
          throw AssertionError();
        });
        final Body body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
      });
    });

    group('in non-development environment', () {
      setUp(() {
        clientContext.isDevelopmentEnvironment = false;
      });

      GithubBuildStatusUpdate newStatusUpdate(PullRequest pr, BuildStatus status) {
        return GithubBuildStatusUpdate(
          key: db.emptyKey.append(GithubBuildStatusUpdate, id: pr.number),
          status: status.githubStatus,
          pr: pr.number,
          head: pr.head.sha,
          updates: 0,
        );
      }

      PullRequest newPullRequest({@required int id, @required String sha}) {
        return PullRequest()
          ..number = id
          ..head = (PullRequestHead()..sha = sha);
      }

      group('does not update anything', () {
        setUp(() {
          db.onCommit =
              (List<gcloud_db.Model<dynamic>> insert, List<gcloud_db.Key<dynamic>> deletes) => throw AssertionError();
          when(repositoriesService.createStatus(any, any, any)).thenThrow(AssertionError());
        });

        test('if there are no PRs', () async {
          config.flutterBranchesValue = <String>['master'];
          buildStatusService.cumulativeStatus = BuildStatus.success();
          final Body body = await tester.get<Body>(handler);
          final TableDataList tableDataList = await tabledataResourceApi.list('test', 'test', 'test');
          expect(body, same(Body.empty));
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          /// Test for [BigQuery] insert
          expect(tableDataList.totalRows, '1');
        });

        test('if status has not changed since last update', () async {
          githubPullRequestsMaster = <int>[1];
          final PullRequest pr = newPullRequest(id: 1, sha: '1');
          config.flutterBranchesValue = <String>['master'];
          buildStatusService.cumulativeStatus = BuildStatus.success();
          final GithubBuildStatusUpdate status = newStatusUpdate(pr, BuildStatus.success());
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });

        test('if there is no pr found for a targeted branch', () async {
          githubPullRequestsMaster = <int>[1];
          final PullRequest pr = newPullRequest(id: 1, sha: '1');
          config.flutterBranchesValue = <String>['flutter-0.0-candidate.0'];
          buildStatusService.cumulativeStatus = BuildStatus.success();
          final GithubBuildStatusUpdate status =
              newStatusUpdate(pr, BuildStatus.failure(const <String>['failed_task_1']));
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(status.status, BuildStatus.failure().githubStatus);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });
      });

      group('updates GitHub and datastore', () {
        test('if status has changed since last update', () async {
          githubPullRequestsOther = <int>[1];
          final PullRequest pr = newPullRequest(id: 1, sha: '1');
          config.flutterBranchesValue = <String>['flutter-0.0-candidate.0'];
          buildStatusService.cumulativeStatus = BuildStatus.success();
          final GithubBuildStatusUpdate status =
              newStatusUpdate(pr, BuildStatus.failure(const <String>['failed_test_1']));
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.updateTimeMillis, isNotNull);
          expect(status.status, BuildStatus.success().githubStatus);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });

        test('update if statuses have changed since last update - multiple branches', () async {
          githubPullRequestsMaster = <int>[11111];
          githubPullRequestsOther = <int>[22222];
          final PullRequest prMaster = newPullRequest(id: 11111, sha: 'abcd');
          final PullRequest prOther = newPullRequest(id: 22222, sha: 'efgh');
          config.flutterBranchesValue = <String>['flutter-0.0-candidate.0', 'master'];
          buildStatusService.cumulativeStatus = BuildStatus.success();
          final GithubBuildStatusUpdate statusOther =
              newStatusUpdate(prOther, BuildStatus.failure(const <String>['failed_test_1']));
          db.values[statusOther.key] = statusOther;
          final GithubBuildStatusUpdate statusMaster =
              newStatusUpdate(prMaster, BuildStatus.failure(const <String>['failed_test_1']));
          db.values[statusMaster.key] = statusMaster;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(statusMaster.updates, 1);
          expect(statusOther.updates, 1);
          expect(statusMaster.status, BuildStatus.success().githubStatus);
          expect(statusOther.status, BuildStatus.success().githubStatus);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });
      });
    });
  });
}
