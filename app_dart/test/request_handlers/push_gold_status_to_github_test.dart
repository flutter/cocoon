// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/github_gold_status_update.dart';
import 'package:cocoon_service/src/request_handlers/push_gold_status_to_github.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_graphql_client.dart';
import '../src/utilities/mocks.dart';

void main() {
  const String kGoldenFileLabel = 'will affect goldens';

  group('PushGoldStatusToGithub', () {
    FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticatedContext authContext;
    FakeAuthenticationProvider auth;
    FakeDatastoreDB db;
    FakeLogging log;
    ApiRequestHandlerTester tester;
    PushGoldStatusToGithub handler;
    FakeGraphQLClient githubGraphQLClient;
    List<dynamic> checkRuns = <dynamic>[];
    MockHttpClient mockHttpClient;
    RepositorySlug slug;
    RetryOptions retryOptions;

    setUp(() {
      clientContext = FakeClientContext();
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      githubGraphQLClient = FakeGraphQLClient();
      db = FakeDatastoreDB();
      config = FakeConfig(
        dbValue: db,
      );
      log = FakeLogging();
      tester = ApiRequestHandlerTester(context: authContext);
      mockHttpClient = MockHttpClient();
      retryOptions = const RetryOptions(
        delayFactor: Duration(milliseconds: 1),
        maxDelay: Duration(milliseconds: 2),
        maxAttempts: 2,
      );

      githubGraphQLClient.mutateResultForOptions = (MutationOptions options) => QueryResult();
      githubGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return createGithubQueryResult(checkRuns);
      };
      config.githubGraphQLClient = githubGraphQLClient;
      config.flutterGoldPendingValue = 'pending';
      config.flutterGoldChangesValue = 'changes';
      config.flutterGoldSuccessValue = 'success';
      config.flutterGoldAlertConstantValue = 'flutter gold alert';
      config.flutterGoldInitialAlertValue = 'initial';
      config.flutterGoldFollowUpAlertValue = 'follow-up';
      config.flutterGoldDraftChangeValue = 'draft';
      config.flutterGoldStalePRValue = 'stale';

      handler = PushGoldStatusToGithub(
        config,
        auth,
        datastoreProvider: (DatastoreDB db) {
          return DatastoreService(
            config.db,
            5,
            retryOptions: retryOptions,
          );
        },
        loggingProvider: () => log,
        goldClient: mockHttpClient,
      );

      slug = RepositorySlug('flutter', 'flutter');
      checkRuns.clear();
    });

    group('in development environment', () {
      setUp(() {
        clientContext.isDevelopmentEnvironment = true;
      });

      test('Does nothing', () async {
        config.githubClient = ThrowingGitHub();
        db.onCommit = (List<gcloud_db.Model> insert, List<gcloud_db.Key> deletes) => throw AssertionError();
        db.addOnQuery<GithubGoldStatusUpdate>((Iterable<GithubGoldStatusUpdate> results) {
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
        clientContext.isDevelopmentEnvironment = false;
      });

      GithubGoldStatusUpdate newStatusUpdate(PullRequest pr, String statusUpdate, String sha, String description) {
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

      PullRequest newPullRequest(int number, String sha, String baseRef, {bool draft = false, DateTime updated}) {
        return PullRequest()
          ..number = 123
          ..head = (PullRequestHead()..sha = 'abc')
          ..base = (PullRequestHead()..ref = baseRef)
          ..draft = draft
          ..updatedAt = updated ?? DateTime.now();
      }

      group('does not update GitHub or Datastore', () {
        setUp(() {
          db.onCommit = (List<gcloud_db.Model> insert, List<gcloud_db.Key> deletes) => throw AssertionError();
          when(repositoriesService.createStatus(any, any, any)).thenThrow(AssertionError());
        });

        test('if there are no PRs', () async {
          prsFromGitHub = <PullRequest>[];
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
        });

        test('if there are no framework tests for this PR', () async {
          checkRuns = <dynamic>[
            <String, String>{'name': 'tool-test1', 'status': 'completed', 'conclusion': 'success'}
          ];
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ));
        });

        test('same commit, checks running, last status running', () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
            pr,
            GithubGoldStatusUpdate.statusRunning,
            'abc',
            config.flutterGoldPendingValue,
          );
          db.values[status.key] = status;

          // Checks still running
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'in_progress', 'conclusion': 'neutral'}
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ));
        });

        test('same commit, checks complete, last status complete', () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
            pr,
            GithubGoldStatusUpdate.statusCompleted,
            'abc',
            config.flutterGoldSuccessValue,
          );
          db.values[status.key] = status;

          // Checks complete
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'}
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ));
        });

        test('same commit, checks complete, last status & gold status is running/awaiting triage, should not comment',
            () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
            pr,
            GithubGoldStatusUpdate.statusRunning,
            'abc',
            config.flutterGoldChangesValue,
          );
          db.values[status.key] = status;

          // Checks complete
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'}
          ];

          // Gold status is running
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse = MockHttpClientResponse(utf8.encode(tryjobDigests()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/v1/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

          // Already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = config.flutterGoldCommentID(pr),
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ));
        });

        test('does nothing for branches not staged to land on master', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc', 'release');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // All checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'}
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ));
        });

        test('does not post for draft PRs, does not query Gold', () async {
          // New commit, draft PR
          final PullRequest pr = newPullRequest(123, 'abc', 'master', draft: true);
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'}
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            any,
          ));
        });

        test('does not post for draft PRs, does not query Gold', () async {
          // New commit, draft PR
          final PullRequest pr = newPullRequest(123, 'abc', 'master', draft: true);
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'Linux', 'status': 'completed', 'conclusion': 'success'}
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            any,
          ));
        });

        test('does not post for stale PRs, does not query Gold, stale comment', () async {
          // New commit, draft PR
          final PullRequest pr = newPullRequest(123, 'abc', 'master', updated: DateTime.now().subtract(const Duration(days: 30)));
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'Linux', 'status': 'completed', 'conclusion': 'success'}
          ];

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number)).thenAnswer(
              (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
          expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);

          // Should not apply labels, should comment to update
          verifyNever(issuesService.addLabelsToIssue(
            slug,
            pr.number,
            <String>[
              kGoldenFileLabel,
            ],
          ));

          verify(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldStalePRValue)),
          )).called(1);
        });

        test('will only comment once on stale PRs', () async {
          // New commit, draft PR
          final PullRequest pr = newPullRequest(123, 'abc', 'master', updated: DateTime.now().subtract(const Duration(days: 30)));
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'Linux', 'status': 'completed', 'conclusion': 'success'}
          ];

          // Already commented to update.
          when(issuesService.listCommentsByIssue(slug, pr.number)).thenAnswer(
              (_) => Stream<IssueComment>.value(
              IssueComment()..body = config.flutterGoldStalePRValue,
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            any,
          ));
        });
      });

      group('updates GitHub and/or Datastore', () {
        test('new commit, checks running', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks running
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'in_progress', 'conclusion': 'neutral'}
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ));
        });

        test('web tests also indicate golden file tests', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks running
          checkRuns = <dynamic>[
            <String, String>{'name': 'web', 'status': 'in_progress', 'conclusion': 'neutral'}
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ));
        });

        test('new commit, checks complete, no changes detected', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'}
          ];

          // Change detected by Gold
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse = MockHttpClientResponse(utf8.encode(tryjobEmpty()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/v1/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ));
        });

        test('new commit, checks complete, change detected, should comment', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'}
          ];

          // Change detected by Gold
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse = MockHttpClientResponse(utf8.encode(tryjobDigests()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/v1/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

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
              kGoldenFileLabel,
            ],
          )).called(1);

          verify(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          )).called(1);
        });

        test('same commit, checks complete, last status was waiting & gold status is needing triage, should comment',
            () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
              newStatusUpdate(pr, GithubGoldStatusUpdate.statusRunning, 'abc', config.flutterGoldPendingValue);
          db.values[status.key] = status;

          // Checks complete
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'}
          ];

          // Gold status is running
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse = MockHttpClientResponse(utf8.encode(tryjobDigests()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/v1/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

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
              kGoldenFileLabel,
            ],
          )).called(1);

          verify(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          )).called(1);
        });

        test('uses shorter comment after first comment to reduce noise', () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
              newStatusUpdate(pr, GithubGoldStatusUpdate.statusRunning, 'abc', config.flutterGoldPendingValue);
          db.values[status.key] = status;

          // Checks complete
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'completed': 'in_progress', 'conclusion': 'success'}
          ];

          // Gold status is running
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse = MockHttpClientResponse(utf8.encode(tryjobDigests()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/v1/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = config.flutterGoldInitialAlertValue,
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
              kGoldenFileLabel,
            ],
          )).called(1);

          verify(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldFollowUpAlertValue)),
          )).called(1);
          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldInitialAlertValue)),
          ));
          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldAlertConstantValue)),
          ));
        });

        test('same commit, checks complete, new status, should not comment', () async {
          // Same commit: abc
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
              newStatusUpdate(pr, GithubGoldStatusUpdate.statusRunning, 'abc', config.flutterGoldPendingValue);
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'}
          ];

          // New status: completed/triaged/no changes
          final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
          final MockHttpClientResponse mockHttpResponse = MockHttpClientResponse(utf8.encode(tryjobEmpty()));
          when(mockHttpClient.getUrl(Uri.parse(
                  'http://flutter-gold.skia.org/json/v1/changelist/github/${pr.number}/${pr.head.sha}/untriaged')))
              .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close()).thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ));
        });

        test('will inform contributor of unresolved check for ATF draft status', () async {
          // New commit, draft PR
          final PullRequest pr = newPullRequest(123, 'abc', 'master', draft: true);
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
              newStatusUpdate(pr, GithubGoldStatusUpdate.statusRunning, 'abc', config.flutterGoldPendingValue);
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'}
          ];
          when(issuesService.listCommentsByIssue(slug, pr.number)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
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
              kGoldenFileLabel,
            ],
          ));

          verify(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldDraftChangeValue)),
          )).called(1);
        });

        test('will only inform contributor of unresolved check for ATF draft status once', () async {
          // New commit, draft PR
          final PullRequest pr = newPullRequest(123, 'abc', 'master', draft: true);
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
              newStatusUpdate(pr, GithubGoldStatusUpdate.statusRunning, 'abc', config.flutterGoldPendingValue);
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'}
          ];
          when(issuesService.listCommentsByIssue(slug, pr.number)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = config.flutterGoldDraftChangeValue,
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldDraftChangeValue)),
          ));
        });

        test('delivers pending state for failing checks, does not query Gold', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(pr, '', '', '');
          db.values[status.key] = status;

          // Checks failed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'failure'}
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
              kGoldenFileLabel,
            ],
          ));

          verifyNever(issuesService.createComment(
            slug,
            pr.number,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ));
        });
      });

      test('Completed pull request does not skip follow-up prs with early return', () async {
        final PullRequest completedPR = newPullRequest(123, 'abc', 'master');
        final PullRequest followUpPR = newPullRequest(456, 'def', 'master');
        prsFromGitHub = <PullRequest>[
          completedPR,
          followUpPR,
        ];
        final GithubGoldStatusUpdate completedStatus =
            newStatusUpdate(completedPR, GithubGoldStatusUpdate.statusCompleted, 'abc', config.flutterGoldSuccessValue);
        final GithubGoldStatusUpdate followUpStatus = newStatusUpdate(followUpPR, '', '', '');
        db.values[completedStatus.key] = completedStatus;
        db.values[followUpStatus.key] = followUpStatus;

        // Checks completed
        checkRuns = <dynamic>[
          <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'}
        ];

        // New status: completed/triaged/no changes
        final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
        final MockHttpClientResponse mockHttpResponse = MockHttpClientResponse(utf8.encode(tryjobEmpty()));
        when(mockHttpClient.getUrl(Uri.parse(
                'http://flutter-gold.skia.org/json/v1/changelist/github/${completedPR.number}/${completedPR.head.sha}/untriaged')))
            .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
        when(mockHttpClient.getUrl(Uri.parse(
                'http://flutter-gold.skia.org/json/v1/changelist/github/${followUpPR.number}/${followUpPR.head.sha}/untriaged')))
            .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
        when(mockHttpRequest.close()).thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

        when(issuesService.listCommentsByIssue(slug, completedPR.number)).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = 'some other comment',
          ),
        );

        final Body body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(completedStatus.updates, 0);
        expect(followUpStatus.updates, 1);
        expect(completedStatus.status, GithubGoldStatusUpdate.statusCompleted);
        expect(followUpStatus.status, GithubGoldStatusUpdate.statusCompleted);
        expect(log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
        expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
      });

      test('accounts for null status description when parsing for Luci builds', () async {
        // Same commit
        final PullRequest pr = newPullRequest(123, 'abc', 'master');
        prsFromGitHub = <PullRequest>[pr];
        final GithubGoldStatusUpdate status = newStatusUpdate(
          pr,
          GithubGoldStatusUpdate.statusRunning,
          'abc',
          config.flutterGoldPendingValue,
        );
        db.values[status.key] = status;

        // null status for luci build
        checkRuns = <dynamic>[
          <String, String>{
            'name': 'framework',
            'status': null,
            'conclusion': null,
          }
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
            kGoldenFileLabel,
          ],
        ));

        verifyNever(issuesService.createComment(
          slug,
          pr.number,
          argThat(contains(config.flutterGoldCommentID(pr))),
        ));
      });
    });
  });
}

QueryResult createGithubQueryResult(List<dynamic> statuses) {
  assert(statuses != null);
  return QueryResult(
    data: <String, dynamic>{
      'repository': <String, dynamic>{
        'pullRequest': <String, dynamic>{
          'commits': <String, dynamic>{
            'nodes': <dynamic>[
              <String, dynamic>{
                'commit': <String, dynamic>{
                  'checkSuites': <String, dynamic>{
                    'nodes': <dynamic>[
                      <String, dynamic>{
                        'checkRuns': <String, dynamic>{'nodes': statuses}
                      }
                    ]
                  }
                }
              }
            ],
          },
        },
      },
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
