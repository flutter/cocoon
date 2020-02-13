// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/github_gold_status_update.dart';
import 'package:cocoon_service/src/request_handlers/push_gold_status_to_github.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:github/server.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_graphql_client.dart';

// TODO(Piinks): Add checks for comments and labels, finish mocks

void main() {
  group('PushGoldStatusToGithub', () {
    FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticatedContext authContext;
    FakeAuthenticationProvider auth;
    FakeDatastoreDB db;
    FakeLogging log;
    ApiRequestHandlerTester tester;
    PushGoldStatusToGithub handler;
    FakeGraphQLClient cirrusGraphQLClient;
    List<dynamic> statuses = <dynamic>[];

    setUp(() {
      clientContext = FakeClientContext();
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      config = FakeConfig(cirrusGraphQLClient: cirrusGraphQLClient);
      db = FakeDatastoreDB();
      log = FakeLogging();
      tester = ApiRequestHandlerTester(context: authContext);
      handler = PushGoldStatusToGithub(
        config,
        auth,
        datastoreProvider: () => DatastoreService(db: db),
        loggingProvider: () => log,
      );

      cirrusGraphQLClient.mutateResultForOptions =
        (MutationOptions options) => QueryResult();

      cirrusGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return createCirrusQueryResult(statuses);
      };
    });

    group('in development environment', () {
      setUp(() {
        clientContext.isDevelopmentEnvironment = true;
      });

      test('Does nothing', () async {
        config.githubClient = ThrowingGitHub();
        db.onCommit =
          (List<gcloud_db.Model> insert, List<gcloud_db.Key> deletes) =>
        throw AssertionError();
        db.addOnQuery<GithubGoldStatusUpdate>(
            (Iterable<GithubGoldStatusUpdate> results) {
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

      GithubGoldStatusUpdate newStatusUpdate(
        PullRequest pr, String statusUpdate, String sha) {
        return GithubGoldStatusUpdate(
          key: db.emptyKey.append(GithubGoldStatusUpdate),
          status: statusUpdate,
          pr: pr.number,
          head: sha,
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
            (List<gcloud_db.Model> insert, List<gcloud_db.Key> deletes) =>
          throw AssertionError();
          when(repositoriesService.createStatus(any, any, any))
            .thenThrow(AssertionError());
        });

        test('if there are no PRs', () async {
          prsFromGitHub = <PullRequest>[];
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });

        test('if there are no framework tests for this PR', () async {
          statuses = <dynamic>[
            <String, String>{'status': 'EXECUTING', 'name': 'tool-test-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'tool-test-2'}
          ];
          final PullRequest pr = newPullRequest(id: 123, sha: 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
            newStatusUpdate(pr, null, null);
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });

        test('same commit, last status running, checks still running', () async {
          statuses = <dynamic>[
            <String, String>{'status': 'EXECUTING', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];
          final PullRequest pr = newPullRequest(id: 123, sha: 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
            newStatusUpdate(pr, GithubGoldStatusUpdate.statusRunning, 'abc');
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });

        test('same commit, last status complete, checks complete', () async {
          statuses = <dynamic>[
            <String, String>{'status': 'COMPLETED', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];
          final PullRequest pr = newPullRequest(id: 123, sha: 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
            newStatusUpdate(pr, GithubGoldStatusUpdate.statusCompleted, 'abc');
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });

        test('same commit, last status same as gold status, checks complete', () async {
          statuses = <dynamic>[
            <String, String>{'status': 'COMPLETED', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];
          // TODO(Piinks): mock gold request
          final PullRequest pr = newPullRequest(id: 123, sha: 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
            newStatusUpdate(pr, GithubGoldStatusUpdate.statusCompleted, 'abc');
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });
      });

      group('updates GitHub and datastore', () {
        test('new commit, checks running', () async {
          statuses = <dynamic>[
            <String, String>{'status': 'EXECUTING', 'name': 'framework-1'},
            <String, String>{'status': 'EXECUTING', 'name': 'framework-2'}
          ];
          final PullRequest pr = newPullRequest(id: 123, sha: 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
            newStatusUpdate(pr, null, null);
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusRunning);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });

        test('new commit, no last status, checks completed', () async {
          statuses = <dynamic>[
            <String, String>{'status': 'COMPLETED', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];
          // TODO(Piinks): mock gold request
          final PullRequest pr = newPullRequest(id: 123, sha: 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
            newStatusUpdate(pr, null, null);
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusRunning);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });

        test('same commit, new status, checks completed', () async {
          statuses = <dynamic>[
            <String, String>{'status': 'COMPLETED', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];
          // TODO(Piinks): mock gold request
          final PullRequest pr = newPullRequest(id: 123, sha: 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
            newStatusUpdate(pr, GithubGoldStatusUpdate.statusRunning, 'abc');
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusCompleted);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });
      });

      test('Generates a comment and applies label on PR with golden changes', () async {

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

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  MockHttpClientResponse(this.response);

  final List<int> response;

  @override
  StreamSubscription<List<int>> listen(
    void onData(List<int> event), {
      Function onError,
      void onDone(),
      bool cancelOnError,
    }) {
    return Stream<List<int>>.fromFuture(Future<List<int>>.value(response))
      .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class MockHttpImageResponse extends Mock implements HttpClientResponse {
  MockHttpImageResponse(this.response);

  final List<List<int>> response;

  @override
  Future<void> forEach(void action(List<int> element)) async {
    response.forEach(action);
  }
}

QueryResult createCirrusQueryResult(List<dynamic> statuses) {
  assert(statuses != null);

  return QueryResult(
    data: <String, dynamic>{
      'searchBuilds': <dynamic>[
        <String, dynamic>{
          'id': '1',
          'latestGroupTasks': <dynamic>[
            <String, dynamic>{
              'id': '1',
              'name': statuses.first['name'],
              'status': statuses.first['status']
            },
            <String, dynamic>{
              'id': '2',
              'name': statuses.last['name'],
              'status': statuses.last['status']
            }
          ],
        }
      ],
    },
  );
}

/// JSON response template for Skia Gold empty tryjob status request.
String tryjobEmpty() {
  return '''
    {
      "digests": null
    }
  ''';
}

/// JSON response template for Skia Gold empty tryjob status request.
String tryjobDigests() {
  return '''
    {
      "digests": [
        "abcd",
        "efgh",
        "ijkl"
      ]
    }
  ''';
}