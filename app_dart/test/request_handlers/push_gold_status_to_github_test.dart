// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/github_gold_status_update.dart';
import 'package:cocoon_service/src/request_handlers/push_gold_status_to_github.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:github/server.dart';
import 'package:graphql/client.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_graphql_client.dart';

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
    MockHttpClient mockHttpClient;
    RepositorySlug slug;

    setUp(() {
      clientContext = FakeClientContext();
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      cirrusGraphQLClient = FakeGraphQLClient();
      config = FakeConfig(cirrusGraphQLClient: cirrusGraphQLClient);
      db = FakeDatastoreDB();
      log = FakeLogging();
      tester = ApiRequestHandlerTester(context: authContext);
      mockHttpClient = MockHttpClient();
      handler = PushGoldStatusToGithub(
        config,
        auth,
        datastoreProvider: () => DatastoreService(db: db),
        loggingProvider: () => log,
        goldClient: mockHttpClient,
      );

      cirrusGraphQLClient.mutateResultForOptions =
          (MutationOptions options) => QueryResult();

      cirrusGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return createCirrusQueryResult(statuses);
      };

      slug = const RepositorySlug('flutter', 'flutter');
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
      MockIssuesService issuesService;
      MockRepositoriesService repositoriesService;
      List<PullRequest> prsFromGitHub;

      setUp(() {
        github = MockGitHub();
        pullRequestsService = MockPullRequestsService();
        issuesService = MockIssuesService();
        repositoriesService = MockRepositoriesService();
        when(github.pullRequests).thenReturn(pullRequestsService);
        when(github.issues).thenReturn(issuesService);
        when(github.repositories).thenReturn(repositoriesService);
        when(pullRequestsService.list(any)).thenAnswer((Invocation _) {
          return Stream<PullRequest>.fromIterable(prsFromGitHub);
        });
        config.githubClient = github;
        config.goldenBreakingChangeMessageValue = 'goldenBreakingChangeMessage';
        clientContext.isDevelopmentEnvironment = false;
      });

      GithubGoldStatusUpdate newStatusUpdate(
          PullRequest pr, String statusUpdate, String sha, String description) {
        return GithubGoldStatusUpdate(
          key: db.emptyKey.append(GithubGoldStatusUpdate),
          status: statusUpdate,
          pr: pr.number,
          head: sha,
          updates: 0,
          description: description,
          repository: 'flutter/flutter',
        );
      }

      PullRequest newPullRequest(int number, String sha) {
        return PullRequest()
          ..number = number
          ..head = (PullRequestHead()..sha = sha);
      }

      group('does not update GitHub or Datastore', () {
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
          final PullRequest pr = newPullRequest(123, 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          // Should not apply labels or make comments
          verifyNever(issuesService.addLabelsToIssue(
            slug,
            pr.number,
            <String>[
              'will affect goldens',
              'severe: API break',
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.goldenBreakingChangeMessageValue)),
          ));
        });

        test('same commit, checks running, last status running', () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
            pr,
            GithubGoldStatusUpdate.statusRunning,
            'abc',
            'This check is waiting for all other checks to be completed.',
          );
          db.values[status.key] = status;

          // Checks still running
          statuses = <dynamic>[
            <String, String>{'status': 'EXECUTING', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          // Should not apply labels or make comments
          verifyNever(issuesService.addLabelsToIssue(
            slug,
            pr.number,
            <String>[
              'will affect goldens',
              'severe: API break',
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.goldenBreakingChangeMessageValue)),
          ));
        });

        test('same commit, checks complete, last status complete', () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
              pr,
              GithubGoldStatusUpdate.statusCompleted,
              'abc',
              'All golden file tests have passed.');
          db.values[status.key] = status;

          // Checks complete
          statuses = <dynamic>[
            <String, String>{'status': 'COMPLETED', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          // Should not apply labels or make comments
          verifyNever(issuesService.addLabelsToIssue(
            slug,
            pr.number,
            <String>[
              'will affect goldens',
              'severe: API break',
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.goldenBreakingChangeMessageValue)),
          ));
        });

        test(
            'same commit, checks complete, last status & gold status is running/awaiting triage, should not comment',
            () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
              pr,
              GithubGoldStatusUpdate.statusRunning,
              'abc',
              'Image changes have been found for '
                  'this pull request. Visit https://flutter-gold.skia.org/changelists '
                  'to view and triage (e.g. because this is an intentional change).');
          db.values[status.key] = status;

          // Checks complete
          statuses = <dynamic>[
            <String, String>{'status': 'COMPLETED', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];

          // Gold status is running
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse =
              MockHttpClientResponse(utf8.encode(tryjobDigests()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer(
                  (_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer(
              (_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

          // Already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()
                ..body = 'Changes reported for pull request '
                    '#${pr.number} at sha ${pr.head.sha}',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          // Should not apply labels or make comments
          verifyNever(issuesService.addLabelsToIssue(
            slug,
            pr.number,
            <String>[
              'will affect goldens',
              'severe: API break',
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.goldenBreakingChangeMessageValue)),
          ));
        });
      });

      group('updates GitHub and Datastore', () {
        test('new commit, checks running', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks running
          statuses = <dynamic>[
            <String, String>{'status': 'EXECUTING', 'name': 'framework-1'},
            <String, String>{'status': 'EXECUTING', 'name': 'framework-2'}
          ];

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusRunning);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          // Should not apply labels or make comments
          verifyNever(issuesService.addLabelsToIssue(
            slug,
            pr.number,
            <String>[
              'will affect goldens',
              'severe: API break',
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.goldenBreakingChangeMessageValue)),
          ));
        });

        test('new commit, checks complete, no changes detected', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          statuses = <dynamic>[
            <String, String>{'status': 'COMPLETED', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];

          // Change detected by Gold
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse =
              MockHttpClientResponse(utf8.encode(tryjobEmpty()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer(
                  (_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer(
              (_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusCompleted);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          // Should not label or comment
          verifyNever(issuesService.addLabelsToIssue(
            slug,
            pr.number,
            <String>[
              'will affect goldens',
              'severe: API break',
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.goldenBreakingChangeMessageValue)),
          ));
        });

        test('new commit, checks complete, change detected, should comment',
            () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          statuses = <dynamic>[
            <String, String>{'status': 'COMPLETED', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];

          // Change detected by Gold
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse =
              MockHttpClientResponse(utf8.encode(tryjobDigests()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer(
                  (_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer(
              (_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusRunning);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          // Should label and comment
          verify(issuesService.addLabelsToIssue(
            slug,
            pr.number,
            <String>[
              'will affect goldens',
              'severe: API break',
            ],
          )).called(1);

          verify(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.goldenBreakingChangeMessageValue)),
          )).called(1);
        });

        test(
            'same commit, checks complete, last status was waiting & gold status is needing triage, should comment',
            () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
              pr,
              GithubGoldStatusUpdate.statusRunning,
              'abc',
              'This check is waiting for all other checks to be completed.');
          db.values[status.key] = status;

          // Checks complete
          statuses = <dynamic>[
            <String, String>{'status': 'COMPLETED', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];

          // Gold status is running
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse =
              MockHttpClientResponse(utf8.encode(tryjobDigests()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer(
                  (_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer(
              (_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          // Should apply labels and make comment
          verify(issuesService.addLabelsToIssue(
            slug,
            pr.number,
            <String>[
              'will affect goldens',
              'severe: API break',
            ],
          )).called(1);

          verify(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.goldenBreakingChangeMessageValue)),
          )).called(1);
        });

        test('uses shorter comment after first comment to reduce noise',
            () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
              pr,
              GithubGoldStatusUpdate.statusRunning,
              'abc',
              'This check is waiting for all other checks to be completed.');
          db.values[status.key] = status;

          // Checks complete
          statuses = <dynamic>[
            <String, String>{'status': 'COMPLETED', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];

          // Gold status is running
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse =
              MockHttpClientResponse(utf8.encode(tryjobDigests()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer(
                  (_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer(
              (_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()
                ..body =
                    'Golden file changes have been found for this pull request.',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          // Should apply labels and make comment
          verify(issuesService.addLabelsToIssue(
            slug,
            pr.number,
            <String>[
              'will affect goldens',
              'severe: API break',
            ],
          )).called(1);

          verify(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(
                'Golden file changes remain available for triage from new commit,')),
          )).called(1);
        });

        test('same commit, checks complete, new status, should not comment',
            () async {
          // Same commit: abc
          final PullRequest pr = newPullRequest(123, 'abc');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
              pr,
              GithubGoldStatusUpdate.statusRunning,
              'abc',
              'This check is waiting for all other checks to be completed.');
          db.values[status.key] = status;

          // Checks completed
          statuses = <dynamic>[
            <String, String>{'status': 'COMPLETED', 'name': 'framework-1'},
            <String, String>{'status': 'COMPLETED', 'name': 'framework-2'}
          ];

          // New status: completed/triaged/no changes
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse =
              MockHttpClientResponse(utf8.encode(tryjobEmpty()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer(
                  (_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer(
              (_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

          when(issuesService.listCommentsByIssue(slug, pr.number)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusCompleted);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          // Should not label or comment
          verifyNever(issuesService.addLabelsToIssue(
            slug,
            pr.number,
            <String>[
              'will affect goldens',
              'severe: API break',
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.goldenBreakingChangeMessageValue)),
          ));
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

class MockIssuesService extends Mock implements IssuesService {}

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
        .listen(onData,
            onError: onError, onDone: onDone, cancelOnError: cancelOnError);
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
