// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:cocoon_service/src/model/appengine/github_gold_status_update.dart';
import 'package:cocoon_service/src/request_handlers/push_gold_status_to_github.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/logging.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_graphql_client.dart';
import '../src/utilities/mocks.dart';

void main() {
  const String kGoldenFileLabel = 'will affect goldens';

  group('PushGoldStatusToGithub', () {
    late FakeConfig config;
    late FakeClientContext clientContext;
    FakeAuthenticatedContext authContext;
    late FakeAuthenticationProvider auth;
    late FakeDatastoreDB db;
    late ApiRequestHandlerTester tester;
    late PushGoldStatusToGithub handler;
    FakeGraphQLClient githubGraphQLClient;
    List<dynamic> checkRuns = <dynamic>[];
    List<dynamic> engineCheckRuns = <dynamic>[];
    late MockClient mockHttpClient;
    late RepositorySlug slug;
    late RepositorySlug engineSlug;
    late RetryOptions retryOptions;

    final List<LogRecord> records = <LogRecord>[];

    setUp(() {
      clientContext = FakeClientContext();
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      githubGraphQLClient = FakeGraphQLClient();
      db = FakeDatastoreDB();
      config = FakeConfig(
        dbValue: db,
      );
      tester = ApiRequestHandlerTester(context: authContext);
      mockHttpClient = MockClient((_) async => http.Response('{}', HttpStatus.ok));
      retryOptions = const RetryOptions(
        delayFactor: Duration(microseconds: 1),
        maxDelay: Duration(microseconds: 2),
        maxAttempts: 2,
      );

      githubGraphQLClient.mutateResultForOptions = (MutationOptions options) => createFakeQueryResult();
      githubGraphQLClient.queryResultForOptions = (QueryOptions options) {
        if (options.variables['sRepoName'] == slug.name) {
          return createGithubQueryResult(checkRuns);
        }
        if (options.variables['sRepoName'] == engineSlug.name) {
          return createGithubQueryResult(engineCheckRuns);
        }
        return createGithubQueryResult(<dynamic>[]);
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
        config: config,
        authenticationProvider: auth,
        datastoreProvider: (DatastoreDB db) {
          return DatastoreService(
            db,
            5,
            retryOptions: retryOptions,
          );
        },
        goldClient: mockHttpClient,
        ingestionDelay: Duration.zero,
      );

      slug = RepositorySlug('flutter', 'flutter');
      engineSlug = RepositorySlug('flutter', 'engine');
      checkRuns.clear();
      engineCheckRuns.clear();
      records.clear();
      log.onRecord.listen((LogRecord record) => records.add(record));
    });

    group('in development environment', () {
      setUp(() {
        clientContext.isDevelopmentEnvironment = true;
      });

      test('Does nothing', () async {
        config.githubClient = ThrowingGitHub();
        db.onCommit =
            (List<gcloud_db.Model<dynamic>> insert, List<gcloud_db.Key<dynamic>> deletes) => throw AssertionError();
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
      late MockIssuesService issuesService;
      late MockRepositoriesService repositoriesService;
      List<PullRequest> prsFromGitHub = <PullRequest>[];
      List<PullRequest> enginePrsFromGitHub = <PullRequest>[];

      setUp(() {
        github = MockGitHub();
        pullRequestsService = MockPullRequestsService();
        issuesService = MockIssuesService();
        repositoriesService = MockRepositoriesService();
        when(github.pullRequests).thenReturn(pullRequestsService);
        when(github.issues).thenReturn(issuesService);
        when(github.repositories).thenReturn(repositoriesService);

        prsFromGitHub.clear();
        when(pullRequestsService.list(slug)).thenAnswer((Invocation _) {
          return Stream<PullRequest>.fromIterable(prsFromGitHub);
        });

        enginePrsFromGitHub.clear();
        when(pullRequestsService.list(engineSlug)).thenAnswer((Invocation _) {
          return Stream<PullRequest>.fromIterable(enginePrsFromGitHub);
        });

        when(repositoriesService.createStatus(any, any, any)).thenAnswer((_) async => RepositoryStatus());
        when(issuesService.createComment(any, any, any)).thenAnswer((_) async => IssueComment());
        when(issuesService.addLabelsToIssue(any, any, any)).thenAnswer((_) async => <IssueLabel>[]);
        config.githubClient = github;
        clientContext.isDevelopmentEnvironment = false;
      });

      GithubGoldStatusUpdate newStatusUpdate(
        RepositorySlug slug,
        PullRequest pr,
        String statusUpdate,
        String sha,
        String description,
      ) {
        return GithubGoldStatusUpdate(
          key: db.emptyKey.append(GithubGoldStatusUpdate, id: pr.number),
          status: statusUpdate,
          pr: pr.number!,
          head: sha,
          updates: 0,
          description: description,
          repository: slug.fullName,
        );
      }

      PullRequest newPullRequest(int number, String sha, String baseRef, {bool draft = false, DateTime? updated}) {
        return PullRequest()
          ..number = number
          ..head = (PullRequestHead()..sha = sha)
          ..base = (PullRequestHead()..ref = baseRef)
          ..draft = draft
          ..updatedAt = updated ?? DateTime.now();
      }

      group('does not update GitHub or Datastore', () {
        setUp(() {
          db.onCommit =
              (List<gcloud_db.Model<dynamic>> insert, List<gcloud_db.Key<dynamic>> deletes) => throw AssertionError();
          when(repositoriesService.createStatus(any, any, any)).thenThrow(AssertionError());
        });

        test('if there are no PRs', () async {
          prsFromGitHub = <PullRequest>[];
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);
        });

        test('if there are no framework or web engine tests for this PR', () async {
          checkRuns = <dynamic>[
            <String, String>{'name': 'tool-test1', 'status': 'completed', 'conclusion': 'success'},
          ];
          final PullRequest flutterPr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[flutterPr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, flutterPr, '', '', '');
          db.values[status.key] = status;

          engineCheckRuns = <dynamic>[
            <String, String>{'name': 'linux-host1', 'status': 'completed', 'conclusion': 'success'},
          ];
          final PullRequest enginePr = newPullRequest(456, 'def', 'main');
          enginePrsFromGitHub = <PullRequest>[enginePr];
          final GithubGoldStatusUpdate engineStatus = newStatusUpdate(engineSlug, enginePr, '', '', '');
          db.values[engineStatus.key] = engineStatus;

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              flutterPr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );
          verifyNever(
            issuesService.addLabelsToIssue(
              engineSlug,
              enginePr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              flutterPr.number!,
              argThat(contains(config.flutterGoldCommentID(flutterPr))),
            ),
          );
          verifyNever(
            issuesService.createComment(
              engineSlug,
              enginePr.number!,
              argThat(contains(config.flutterGoldCommentID(enginePr))),
            ),
          );
        });

        test('if there are no framework tests for this PR, exclude web builds', () async {
          checkRuns = <dynamic>[
            <String, String>{'name': 'web-test1', 'status': 'completed', 'conclusion': 'success'},
          ];
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
          db.values[status.key] = status;
          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        });

        test('same commit, checks running, last status running', () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
            slug,
            pr,
            GithubGoldStatusUpdate.statusRunning,
            'abc',
            config.flutterGoldPendingValue!,
          );
          db.values[status.key] = status;

          // Checks still running
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'in_progress', 'conclusion': 'neutral'},
            <String, String>{'name': 'web engine', 'status': 'in_progress', 'conclusion': 'neutral'},
          ];

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        });

        test('same commit, checks complete, last status complete', () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
            slug,
            pr,
            GithubGoldStatusUpdate.statusCompleted,
            'abc',
            config.flutterGoldSuccessValue!,
          );
          db.values[status.key] = status;

          // Checks complete
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
            <String, String>{'name': 'web engine', 'status': 'completed', 'conclusion': 'success'},
          ];

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        });

        test('same commit, checks complete, last status & gold status is running/awaiting triage, should not comment',
            () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(
            slug,
            pr,
            GithubGoldStatusUpdate.statusRunning,
            'abc',
            config.flutterGoldChangesValue!,
          );
          db.values[status.key] = status;

          final PullRequest enginePr = newPullRequest(456, 'def', 'main');
          enginePrsFromGitHub = <PullRequest>[enginePr];
          final GithubGoldStatusUpdate engineStatus = newStatusUpdate(
            engineSlug,
            enginePr,
            GithubGoldStatusUpdate.statusRunning,
            'def',
            config.flutterGoldChangesValue!,
          );
          db.values[engineStatus.key] = engineStatus;

          // Checks complete
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
          ];
          engineCheckRuns = <dynamic>[
            <String, String>{'name': 'web engine', 'status': 'completed', 'conclusion': 'success'},
          ];

          // Gold status is running
          mockHttpClient = MockClient((http.Request request) async {
            if (request.url.toString() ==
                'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${pr.number}') {
              return http.Response(tryjobDigests(pr), HttpStatus.ok);
            }
            if (request.url.toString() ==
                'https://flutter-engine-gold.skia.org/json/v1/changelist_summary/github/${enginePr.number}') {
              return http.Response(tryjobDigests(enginePr), HttpStatus.ok);
            }
            throw const HttpException('Unexpected http request');
          });
          handler = PushGoldStatusToGithub(
            config: config,
            authenticationProvider: auth,
            datastoreProvider: (DatastoreDB db) {
              return DatastoreService(
                config.db,
                5,
                retryOptions: retryOptions,
              );
            },
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          // Already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = config.flutterGoldCommentID(pr),
            ),
          );
          when(issuesService.listCommentsByIssue(engineSlug, enginePr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = config.flutterGoldCommentID(enginePr),
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );
          verifyNever(
            issuesService.addLabelsToIssue(
              engineSlug,
              enginePr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
          verifyNever(
            issuesService.createComment(
              engineSlug,
              enginePr.number!,
              argThat(contains(config.flutterGoldCommentID(enginePr))),
            ),
          );
        });

        test('does nothing for branches not staged to land on main/master', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc', 'release');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
          db.values[status.key] = status;

          // All checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
          ];

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        });

        test('does not post for draft PRs, does not query Gold', () async {
          // New commit, draft PR
          final PullRequest pr = newPullRequest(123, 'abc', 'master', draft: true);
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
          ];

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              any,
            ),
          );
        });

        test('does not post for draft PRs, does not query Gold', () async {
          // New commit, draft PR
          final PullRequest pr = newPullRequest(123, 'abc', 'master', draft: true);
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'Linux', 'status': 'completed', 'conclusion': 'success'},
          ];

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              any,
            ),
          );
        });

        test('does not post for stale PRs, does not query Gold, stale comment', () async {
          // New commit, draft PR
          final PullRequest pr =
              newPullRequest(123, 'abc', 'master', updated: DateTime.now().subtract(const Duration(days: 30)));
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
          ];

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels, should comment to update
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verify(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldStalePRValue)),
            ),
          ).called(1);
        });

        test('will only comment once on stale PRs', () async {
          // New commit, draft PR
          final PullRequest pr =
              newPullRequest(123, 'abc', 'master', updated: DateTime.now().subtract(const Duration(days: 30)));
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
          ];

          // Already commented to update.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = config.flutterGoldStalePRValue,
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              any,
            ),
          );
        });

        test('will not fire off stale warning for non-framework PRs', () async {
          // New commit, draft PR
          final PullRequest pr =
              newPullRequest(123, 'abc', 'master', updated: DateTime.now().subtract(const Duration(days: 30)));
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'tool-test-1', 'status': 'completed', 'conclusion': 'success'},
          ];

          // Already commented to update.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              any,
            ),
          );
        });
      });

      group('updates GitHub and/or Datastore', () {
        test('new commit, checks running', () async {
          // New commit
          final PullRequest flutterPr = newPullRequest(123, 'f-abc', 'master');
          prsFromGitHub = <PullRequest>[flutterPr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, flutterPr, '', '', '');

          final PullRequest enginePr = newPullRequest(567, 'e-abc', 'main');
          enginePrsFromGitHub = <PullRequest>[enginePr];
          final GithubGoldStatusUpdate engineStatus = newStatusUpdate(engineSlug, enginePr, '', '', '');

          db.values[status.key] = status;
          db.values[engineStatus.key] = engineStatus;

          // Checks running
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'in_progress', 'conclusion': 'neutral'},
          ];
          engineCheckRuns = <dynamic>[
            <String, String>{'name': 'linux_web_engine', 'status': 'in_progress', 'conclusion': 'neutral'},
          ];

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusRunning);
          expect(engineStatus.updates, 1);
          expect(engineStatus.status, GithubGoldStatusUpdate.statusRunning);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              flutterPr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );
          verifyNever(
            issuesService.addLabelsToIssue(
              engineSlug,
              enginePr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              flutterPr.number!,
              argThat(contains(config.flutterGoldCommentID(flutterPr))),
            ),
          );
          verifyNever(
            issuesService.createComment(
              engineSlug,
              enginePr.number!,
              argThat(contains(config.flutterGoldCommentID(enginePr))),
            ),
          );
        });

        test('includes misc test shards', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'misc', 'status': 'completed', 'conclusion': 'success'},
          ];

          // Change detected by Gold
          mockHttpClient = MockClient((http.Request request) async {
            if (request.url.toString() ==
                'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${pr.number}') {
              return http.Response(tryjobEmpty(), HttpStatus.ok);
            }
            throw const HttpException('Unexpected http request');
          });
          handler = PushGoldStatusToGithub(
            config: config,
            authenticationProvider: auth,
            datastoreProvider: (DatastoreDB db) {
              return DatastoreService(
                config.db,
                5,
                retryOptions: retryOptions,
              );
            },
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusCompleted);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not label or comment
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        });

        test('new commit, checks complete, no changes detected', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
          ];

          // Change detected by Gold
          mockHttpClient = MockClient((http.Request request) async {
            if (request.url.toString() ==
                'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${pr.number}') {
              return http.Response(tryjobEmpty(), HttpStatus.ok);
            }
            throw const HttpException('Unexpected http request');
          });
          handler = PushGoldStatusToGithub(
            config: config,
            authenticationProvider: auth,
            datastoreProvider: (DatastoreDB db) {
              return DatastoreService(
                config.db,
                5,
                retryOptions: retryOptions,
              );
            },
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusCompleted);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not label or comment
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        });

        test('new commit, checks complete, change detected, should comment', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
          ];

          // Change detected by Gold
          mockHttpClient = MockClient((http.Request request) async {
            if (request.url.toString() ==
                'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${pr.number}') {
              return http.Response(tryjobDigests(pr), HttpStatus.ok);
            }
            throw const HttpException('Unexpected http request');
          });
          handler = PushGoldStatusToGithub(
            config: config,
            authenticationProvider: auth,
            datastoreProvider: (DatastoreDB db) {
              return DatastoreService(
                config.db,
                5,
                retryOptions: retryOptions,
              );
            },
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusRunning);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should label and comment
          verify(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          ).called(1);

          verify(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          ).called(1);
        });

        test('same commit, checks complete, last status was waiting & gold status is needing triage, should comment',
            () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
              newStatusUpdate(slug, pr, GithubGoldStatusUpdate.statusRunning, 'abc', config.flutterGoldPendingValue!);
          db.values[status.key] = status;

          // Checks complete
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
          ];

          // Gold status is running
          mockHttpClient = MockClient((http.Request request) async {
            if (request.url.toString() ==
                'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${pr.number}') {
              return http.Response(tryjobDigests(pr), HttpStatus.ok);
            }
            throw const HttpException('Unexpected http request');
          });
          handler = PushGoldStatusToGithub(
            config: config,
            authenticationProvider: auth,
            datastoreProvider: (DatastoreDB db) {
              return DatastoreService(
                config.db,
                5,
                retryOptions: retryOptions,
              );
            },
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should apply labels and make comment
          verify(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          ).called(1);

          verify(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          ).called(1);
        });

        test('uses shorter comment after first comment to reduce noise', () async {
          // Same commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
              newStatusUpdate(slug, pr, GithubGoldStatusUpdate.statusRunning, 'abc', config.flutterGoldPendingValue!);
          db.values[status.key] = status;

          // Checks complete
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'completed': 'in_progress', 'conclusion': 'success'},
          ];

          // Gold status is running
          mockHttpClient = MockClient((http.Request request) async {
            if (request.url.toString() ==
                'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${pr.number}') {
              return http.Response(tryjobDigests(pr), HttpStatus.ok);
            }
            throw const HttpException('Unexpected http request');
          });
          handler = PushGoldStatusToGithub(
            config: config,
            authenticationProvider: auth,
            datastoreProvider: (DatastoreDB db) {
              return DatastoreService(
                config.db,
                5,
                retryOptions: retryOptions,
              );
            },
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = config.flutterGoldInitialAlertValue,
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should apply labels and make comment
          verify(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          ).called(1);

          verify(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldFollowUpAlertValue)),
            ),
          ).called(1);
          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldInitialAlertValue)),
            ),
          );
          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldAlertConstantValue)),
            ),
          );
        });

        test('same commit, checks complete, new status, should not comment', () async {
          // Same commit: abc
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
              newStatusUpdate(slug, pr, GithubGoldStatusUpdate.statusRunning, 'abc', config.flutterGoldPendingValue!);
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
          ];

          // New status: completed/triaged/no changes
          mockHttpClient = MockClient((http.Request request) async {
            if (request.url.toString() ==
                'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${pr.number}') {
              return http.Response(tryjobEmpty(), HttpStatus.ok);
            }
            throw const HttpException('Unexpected http request');
          });
          handler = PushGoldStatusToGithub(
            config: config,
            authenticationProvider: auth,
            datastoreProvider: (DatastoreDB db) {
              return DatastoreService(
                config.db,
                5,
                retryOptions: retryOptions,
              );
            },
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusCompleted);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not label or comment
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        });

        test('will inform contributor of unresolved check for ATF draft status', () async {
          // New commit, draft PR
          final PullRequest pr = newPullRequest(123, 'abc', 'master', draft: true);
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
              newStatusUpdate(slug, pr, GithubGoldStatusUpdate.statusRunning, 'abc', config.flutterGoldPendingValue!);
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
          ];
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verify(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldDraftChangeValue)),
            ),
          ).called(1);
        });

        test('will only inform contributor of unresolved check for ATF draft status once', () async {
          // New commit, draft PR
          final PullRequest pr = newPullRequest(123, 'abc', 'master', draft: true);
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status =
              newStatusUpdate(slug, pr, GithubGoldStatusUpdate.statusRunning, 'abc', config.flutterGoldPendingValue!);
          db.values[status.key] = status;

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
          ];
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = config.flutterGoldDraftChangeValue,
            ),
          );

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 0);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldDraftChangeValue)),
            ),
          );
        });

        test('delivers pending state for failing checks, does not query Gold', () async {
          // New commit
          final PullRequest pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
          db.values[status.key] = status;

          // Checks failed
          checkRuns = <dynamic>[
            <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'failure'},
          ];

          final Body body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(status.updates, 1);
          expect(status.status, GithubGoldStatusUpdate.statusRunning);
          expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
          expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              pr.number!,
              <String>[
                kGoldenFileLabel,
              ],
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        });
      });

      test('Completed pull request does not skip follow-up prs with early return', () async {
        final PullRequest completedPR = newPullRequest(123, 'abc', 'master');
        final PullRequest followUpPR = newPullRequest(456, 'def', 'master');
        prsFromGitHub = <PullRequest>[
          completedPR,
          followUpPR,
        ];
        final GithubGoldStatusUpdate completedStatus = newStatusUpdate(
          slug,
          completedPR,
          GithubGoldStatusUpdate.statusCompleted,
          'abc',
          config.flutterGoldSuccessValue!,
        );
        final GithubGoldStatusUpdate followUpStatus = newStatusUpdate(slug, followUpPR, '', '', '');
        db.values[completedStatus.key] = completedStatus;
        db.values[followUpStatus.key] = followUpStatus;

        // Checks completed
        checkRuns = <dynamic>[
          <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
        ];

        // New status: completed/triaged/no changes
        mockHttpClient = MockClient((http.Request request) async {
          if (request.url.toString() ==
              'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${completedPR.number}') {
            return http.Response(tryjobEmpty(), HttpStatus.ok);
          }
          if (request.url.toString() ==
              'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${followUpPR.number}') {
            return http.Response(tryjobEmpty(), HttpStatus.ok);
          }
          throw const HttpException('Unexpected http request');
        });
        handler = PushGoldStatusToGithub(
          config: config,
          authenticationProvider: auth,
          datastoreProvider: (DatastoreDB db) {
            return DatastoreService(
              config.db,
              5,
              retryOptions: retryOptions,
            );
          },
          goldClient: mockHttpClient,
          ingestionDelay: Duration.zero,
        );

        when(issuesService.listCommentsByIssue(slug, completedPR.number!)).thenAnswer(
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
        expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
        expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);
      });

      test('accounts for null status description when parsing for Luci builds', () async {
        // Same commit
        final PullRequest pr = newPullRequest(123, 'abc', 'master');
        prsFromGitHub = <PullRequest>[pr];
        final GithubGoldStatusUpdate status = newStatusUpdate(
          slug,
          pr,
          GithubGoldStatusUpdate.statusRunning,
          'abc',
          config.flutterGoldPendingValue!,
        );
        db.values[status.key] = status;

        // null status for luci build
        checkRuns = <dynamic>[
          <String, String?>{
            'name': 'framework',
            'status': null,
            'conclusion': null,
          }
        ];

        final Body body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(status.updates, 0);
        expect(records.where((LogRecord record) => record.level == Level.WARNING), isEmpty);
        expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);

        // Should not apply labels or make comments
        verifyNever(
          issuesService.addLabelsToIssue(
            slug,
            pr.number!,
            <String>[
              kGoldenFileLabel,
            ],
          ),
        );

        verifyNever(
          issuesService.createComment(
            slug,
            pr.number!,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ),
        );
      });

      test('uses the correct Gold endpoint to get status', () async {
        // New commit
        final PullRequest pr = newPullRequest(123, 'abc', 'master');
        prsFromGitHub = <PullRequest>[pr];
        final GithubGoldStatusUpdate status = newStatusUpdate(slug, pr, '', '', '');
        db.values[status.key] = status;

        final PullRequest enginePr = newPullRequest(456, 'def', 'main');
        enginePrsFromGitHub = <PullRequest>[enginePr];
        final GithubGoldStatusUpdate engineStatus = newStatusUpdate(engineSlug, enginePr, '', '', '');
        db.values[engineStatus.key] = engineStatus;

        // Checks completed
        checkRuns = <dynamic>[
          <String, String>{'name': 'framework', 'status': 'completed', 'conclusion': 'success'},
        ];
        engineCheckRuns = <dynamic>[
          <String, String>{'name': 'linux_web_engine', 'status': 'completed', 'conclusion': 'success'},
        ];

        // Requests sent to Gold.
        final List<String> goldRequests = <String>[];
        mockHttpClient = MockClient((http.Request request) async {
          final String requestUrl = request.url.toString();
          goldRequests.add(requestUrl);

          final int prNumber = int.parse(requestUrl.split('/').last);
          final PullRequest requestedPr;
          if (prNumber == pr.number) {
            requestedPr = pr;
          } else if (prNumber == enginePr.number) {
            requestedPr = enginePr;
          } else {
            throw HttpException('Unexpected http request for PR#$prNumber');
          }
          return http.Response(tryjobDigests(requestedPr), HttpStatus.ok);
        });
        handler = PushGoldStatusToGithub(
          config: config,
          authenticationProvider: auth,
          datastoreProvider: (DatastoreDB db) {
            return DatastoreService(
              config.db,
              5,
              retryOptions: retryOptions,
            );
          },
          goldClient: mockHttpClient,
          ingestionDelay: Duration.zero,
        );

        // Have not already commented for this commit.
        when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = 'some other comment',
          ),
        );
        when(issuesService.listCommentsByIssue(engineSlug, enginePr.number!)).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = 'some other comment',
          ),
        );

        await tester.get<Body>(handler);

        expect(goldRequests, <String>[
          'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${pr.number}',
          'https://flutter-engine-gold.skia.org/json/v1/changelist_summary/github/${enginePr.number}',
        ]);
      });
    });
  });
}

QueryResult createGithubQueryResult(List<dynamic> statuses) {
  return createFakeQueryResult(
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
                        'checkRuns': <String, dynamic>{'nodes': statuses},
                      }
                    ],
                  },
                },
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
      "changelist_id": "123",
      "patchsets": [
        {
          "new_images": 0,
          "new_untriaged_images": 0,
          "total_untriaged_images": 0,
          "patchset_id": "abc",
          "patchset_order": 1
        }
      ],
      "outdated": false
    }
  ''';
}

/// JSON response template for Skia Gold untriaged tryjob status request.
String tryjobDigests(PullRequest pr) {
  return '''
    {
      "changelist_id": "${pr.number!}",
      "patchsets": [
        {
          "new_images": 1,
          "new_untriaged_images": 1,
          "total_untriaged_images": 1,
          "patchset_id": "${pr.head!.sha!}",
          "patchset_order": 1
        }
      ],
      "outdated": false
    }
  ''';
}
