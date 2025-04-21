// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/github_gold_status.dart';
import 'package:cocoon_service/src/model/firestore/github_gold_status.dart'
    as fs;
import 'package:cocoon_service/src/request_handlers/push_gold_status_to_github.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  const kGoldenFileLabel = 'will affect goldens';

  late FakeConfig config;
  late FakeClientContext clientContext;
  late FakeDashboardAuthentication auth;
  late FakeFirestoreService firestore;
  late ApiRequestHandlerTester tester;
  late PushGoldStatusToGithub handler;

  var checkRuns = <dynamic>[];
  late MockClient mockHttpClient;
  late RepositorySlug slug;

  setUp(() {
    clientContext = FakeClientContext();
    firestore = FakeFirestoreService();
    auth = FakeDashboardAuthentication(clientContext: clientContext);
    config = FakeConfig(firestoreService: firestore);
    tester = ApiRequestHandlerTester(
      context: FakeAuthenticatedContext(clientContext: clientContext),
    );
    mockHttpClient = MockClient(
      (_) async => http.Response('{}', HttpStatus.ok),
    );

    final githubGraphQLClient = FakeGraphQLClient();
    githubGraphQLClient.mutateResultForOptions =
        (MutationOptions options) => createFakeQueryResult();
    githubGraphQLClient.queryResultForOptions = (QueryOptions options) {
      if (options.variables['sRepoName'] == slug.name) {
        return createGithubQueryResult(checkRuns);
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
      goldClient: mockHttpClient,
      ingestionDelay: Duration.zero,
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
      final body = await tester.get<Body>(handler);
      expect(body, same(Body.empty));
    });
  });

  group('in non-development environment', () {
    MockGitHub github;
    MockPullRequestsService pullRequestsService;
    late MockIssuesService issuesService;
    late MockRepositoriesService repositoriesService;
    var prsFromGitHub = <PullRequest>[];

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

      when(
        // ignore: discarded_futures
        repositoriesService.createStatus(any, any, any),
      ).thenAnswer((_) async => RepositoryStatus());
      when(
        // ignore: discarded_futures
        issuesService.createComment(any, any, any),
      ).thenAnswer((_) async => IssueComment());
      when(
        // ignore: discarded_futures
        issuesService.addLabelsToIssue(any, any, any),
      ).thenAnswer((_) async => <IssueLabel>[]);
      config.githubClient = github;
      clientContext.isDevelopmentEnvironment = false;
    });

    GithubGoldStatus newGithubGoldStatus(
      RepositorySlug slug,
      PullRequest pr,
      String statusUpdate,
      String sha,
      String description,
    ) {
      return generateFirestoreGithubGoldStatus(
        1,
        head: sha,
        pr: pr.number,
        status: statusUpdate,
        updates: 0,
        description: description,
        repo: slug.name,
      );
    }

    PullRequest newPullRequest(
      int number,
      String sha,
      String baseRef, {
      bool draft = false,
      DateTime? updated,
    }) {
      return PullRequest()
        ..number = number
        ..head = (PullRequestHead()..sha = sha)
        ..base = (PullRequestHead()..ref = baseRef)
        ..draft = draft
        ..updatedAt = updated ?? DateTime.now();
    }

    group('does not update GitHub or Firestore', () {
      test('if there are no PRs', () async {
        prsFromGitHub = <PullRequest>[];
        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(log, hasNoWarningsOrHigher);
      });

      test(
        'if there are no framework or web engine tests for this PR',
        () async {
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'tool-test1',
              'status': 'completed',
              'conclusion': 'success',
            },
            <String, String>{
              'name': 'linux-host1',
              'status': 'completed',
              'conclusion': 'success',
            },
          ];
          final flutterPr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[flutterPr];

          firestore.putDocument(
            newGithubGoldStatus(slug, flutterPr, '', '', ''),
          );

          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log, hasNoWarningsOrHigher);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(slug, flutterPr.number!, <String>[
              kGoldenFileLabel,
            ]),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              flutterPr.number!,
              argThat(contains(config.flutterGoldCommentID(flutterPr))),
            ),
          );
        },
      );

      test(
        'if there are no framework tests for this PR, exclude web builds',
        () async {
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'web-test1',
              'status': 'completed',
              'conclusion': 'success',
            },
          ];
          final pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];
          firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));
          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log, hasNoWarningsOrHigher);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(slug, pr.number!, <String>[
              kGoldenFileLabel,
            ]),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        },
      );

      test('same commit, checks running, last status running', () async {
        // Same commit
        final pr = newPullRequest(123, 'abc', 'master');
        prsFromGitHub = <PullRequest>[pr];

        firestore.putDocument(
          newGithubGoldStatus(
            slug,
            pr,
            GithubGoldStatus.statusRunning,
            'abc',
            config.flutterGoldPendingValue!,
          ),
        );

        // Checks still running
        checkRuns = <dynamic>[
          <String, String>{
            'name': 'framework',
            'status': 'in_progress',
            'conclusion': 'neutral',
          },
          <String, String>{
            'name': 'web engine',
            'status': 'in_progress',
            'conclusion': 'neutral',
          },
        ];

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus.hasUpdates(0),
          ]),
        );
        expect(log, hasNoWarningsOrHigher);

        // Should not apply labels or make comments
        verifyNever(
          issuesService.addLabelsToIssue(slug, pr.number!, <String>[
            kGoldenFileLabel,
          ]),
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
        final pr = newPullRequest(123, 'abc', 'master');
        prsFromGitHub = <PullRequest>[pr];

        firestore.putDocument(
          newGithubGoldStatus(
            slug,
            pr,
            GithubGoldStatus.statusCompleted,
            'abc',
            config.flutterGoldSuccessValue!,
          ),
        );

        // Checks complete
        checkRuns = <dynamic>[
          <String, String>{
            'name': 'framework',
            'status': 'completed',
            'conclusion': 'success',
          },
          <String, String>{
            'name': 'web engine',
            'status': 'completed',
            'conclusion': 'success',
          },
        ];

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus.hasUpdates(0),
          ]),
        );
        expect(log, hasNoWarningsOrHigher);

        // Should not apply labels or make comments
        verifyNever(
          issuesService.addLabelsToIssue(slug, pr.number!, <String>[
            kGoldenFileLabel,
          ]),
        );

        verifyNever(
          issuesService.createComment(
            slug,
            pr.number!,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ),
        );
      });

      test(
        'same commit, checks complete, last status & gold status is running/awaiting triage, should not comment',
        () async {
          // Same commit
          final pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];

          firestore.putDocument(
            newGithubGoldStatus(
              slug,
              pr,
              GithubGoldStatus.statusRunning,
              'abc',
              config.flutterGoldChangesValue!,
            ),
          );

          // Checks complete
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'framework',
              'status': 'completed',
              'conclusion': 'success',
            },
            <String, String>{
              'name': 'web engine',
              'status': 'completed',
              'conclusion': 'success',
            },
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
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          // Already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = config.flutterGoldCommentID(pr),
            ),
          );

          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(
            firestore,
            existsInStorage(fs.GithubGoldStatus.metadata, [
              isGithubGoldStatus.hasUpdates(0),
            ]),
          );
          expect(log, hasNoWarningsOrHigher);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(slug, pr.number!, <String>[
              kGoldenFileLabel,
            ]),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        },
      );

      test(
        'does nothing for branches not staged to land on main/master',
        () async {
          // New commit
          final pr = newPullRequest(123, 'abc', 'release');
          prsFromGitHub = <PullRequest>[pr];

          firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

          // All checks completed
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'framework',
              'status': 'completed',
              'conclusion': 'success',
            },
          ];

          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(
            firestore,
            existsInStorage(fs.GithubGoldStatus.metadata, [
              isGithubGoldStatus.hasUpdates(0),
            ]),
          );
          expect(log, hasNoWarningsOrHigher);

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(slug, pr.number!, <String>[
              kGoldenFileLabel,
            ]),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        },
      );

      test('does not post for draft PRs, does not query Gold', () async {
        // New commit, draft PR
        final pr = newPullRequest(123, 'abc', 'master', draft: true);
        prsFromGitHub = <PullRequest>[pr];

        firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

        // Checks completed
        checkRuns = <dynamic>[
          <String, String>{
            'name': 'Linux',
            'status': 'completed',
            'conclusion': 'success',
          },
        ];

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus.hasUpdates(0),
          ]),
        );
        expect(log, hasNoWarningsOrHigher);

        // Should not apply labels or make comments
        verifyNever(
          issuesService.addLabelsToIssue(slug, pr.number!, <String>[
            kGoldenFileLabel,
          ]),
        );

        verifyNever(issuesService.createComment(slug, pr.number!, any));
      });

      test(
        'does not post for stale PRs, does not query Gold, stale comment',
        () async {
          // New commit, draft PR
          final pr = newPullRequest(
            123,
            'abc',
            'master',
            updated: DateTime.now().subtract(const Duration(days: 30)),
          );
          prsFromGitHub = <PullRequest>[pr];

          firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'framework',
              'status': 'completed',
              'conclusion': 'success',
            },
          ];

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(
            firestore,
            existsInStorage(fs.GithubGoldStatus.metadata, [
              isGithubGoldStatus.hasUpdates(0),
            ]),
          );
          expect(log, hasNoWarningsOrHigher);

          // Should not apply labels, should comment to update
          verifyNever(
            issuesService.addLabelsToIssue(slug, pr.number!, <String>[
              kGoldenFileLabel,
            ]),
          );

          verify(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldStalePRValue)),
            ),
          ).called(1);
        },
      );

      test('will only comment once on stale PRs', () async {
        // New commit, draft PR
        final pr = newPullRequest(
          123,
          'abc',
          'master',
          updated: DateTime.now().subtract(const Duration(days: 30)),
        );
        prsFromGitHub = <PullRequest>[pr];

        firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

        // Checks completed
        checkRuns = <dynamic>[
          <String, String>{
            'name': 'framework',
            'status': 'completed',
            'conclusion': 'success',
          },
        ];

        // Already commented to update.
        when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = config.flutterGoldStalePRValue,
          ),
        );

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus.hasUpdates(0),
          ]),
        );
        expect(log, hasNoWarningsOrHigher);

        // Should not apply labels or make comments
        verifyNever(
          issuesService.addLabelsToIssue(slug, pr.number!, <String>[
            kGoldenFileLabel,
          ]),
        );

        verifyNever(issuesService.createComment(slug, pr.number!, any));
      });

      test('will not fire off stale warning for non-framework PRs', () async {
        // New commit, draft PR
        final pr = newPullRequest(
          123,
          'abc',
          'master',
          updated: DateTime.now().subtract(const Duration(days: 30)),
        );
        prsFromGitHub = <PullRequest>[pr];

        firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

        // Checks completed
        checkRuns = <dynamic>[
          <String, String>{
            'name': 'tool-test-1',
            'status': 'completed',
            'conclusion': 'success',
          },
        ];

        // Already commented to update.
        when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = 'some other comment',
          ),
        );

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus.hasUpdates(0),
          ]),
        );
        expect(log, hasNoWarningsOrHigher);

        // Should not apply labels or make comments
        verifyNever(
          issuesService.addLabelsToIssue(slug, pr.number!, <String>[
            kGoldenFileLabel,
          ]),
        );

        verifyNever(issuesService.createComment(slug, pr.number!, any));
      });
    });

    group('updates GitHub and/or Firestore', () {
      test('new commit, checks running', () async {
        // New commit
        final flutterPr = newPullRequest(123, 'f-abc', 'master');
        prsFromGitHub = <PullRequest>[flutterPr];

        firestore.putDocument(newGithubGoldStatus(slug, flutterPr, '', '', ''));

        // Checks running
        checkRuns = <dynamic>[
          <String, String>{
            'name': 'framework',
            'status': 'in_progress',
            'conclusion': 'neutral',
          },
          <String, String>{
            'name': 'Linux linux_web_engine',
            'status': 'in_progress',
            'conclusion': 'neutral',
          },
        ];

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(log, hasNoWarningsOrHigher);

        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus.hasUpdates(1),
          ]),
        );

        // Should not apply labels or make comments
        verifyNever(
          issuesService.addLabelsToIssue(slug, flutterPr.number!, <String>[
            kGoldenFileLabel,
          ]),
        );

        verifyNever(
          issuesService.createComment(
            slug,
            flutterPr.number!,
            argThat(contains(config.flutterGoldCommentID(flutterPr))),
          ),
        );
      });

      test('includes misc test shards', () async {
        // New commit
        final pr = newPullRequest(123, 'abc', 'master');
        prsFromGitHub = <PullRequest>[pr];

        firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

        // Checks completed
        checkRuns = <dynamic>[
          <String, String>{
            'name': 'misc',
            'status': 'completed',
            'conclusion': 'success',
          },
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
          goldClient: mockHttpClient,
          ingestionDelay: Duration.zero,
        );

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(log, hasNoWarningsOrHigher);

        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus.hasUpdates(1),
          ]),
        );

        // Should not label or comment
        verifyNever(
          issuesService.addLabelsToIssue(slug, pr.number!, <String>[
            kGoldenFileLabel,
          ]),
        );

        verifyNever(
          issuesService.createComment(
            slug,
            pr.number!,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ),
        );
      });

      Future<void> includesEngineShard(String shard) async {
        // New commit
        final pr = newPullRequest(123, 'abc', 'master');
        prsFromGitHub = <PullRequest>[pr];

        firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

        // Checks completed
        checkRuns = <dynamic>[
          <String, String>{
            'name': shard,
            'status': 'completed',
            'conclusion': 'success',
          },
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
          goldClient: mockHttpClient,
          ingestionDelay: Duration.zero,
        );

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(log, hasNoWarningsOrHigher);

        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus.hasUpdates(1),
          ]),
        );

        // Should not label or comment
        verifyNever(
          issuesService.addLabelsToIssue(slug, pr.number!, <String>[
            kGoldenFileLabel,
          ]),
        );

        verifyNever(
          issuesService.createComment(
            slug,
            pr.number!,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ),
        );
      }

      test('includes linux_android_emulator test shard - monorepo', () async {
        await includesEngineShard('linux_android_emulator');
      });

      test('includes linux_host_engine test shard - monorepo', () async {
        await includesEngineShard('linux_host_engine');
      });

      test('includes linux_web_engine test shard - monorepo', () async {
        await includesEngineShard('linux_web_engine');
      });

      test('includes mac_host_engine test shard - monorepo', () async {
        await includesEngineShard('mac_host_engine');
      });

      test('includes mac_unopt test shard - monorepo', () async {
        await includesEngineShard('mac_unopt');
      });

      test('new commit, checks complete, no changes detected', () async {
        // New commit
        final pr = newPullRequest(123, 'abc', 'master');
        prsFromGitHub = <PullRequest>[pr];

        firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

        // Checks completed
        checkRuns = <dynamic>[
          <String, String>{
            'name': 'framework',
            'status': 'completed',
            'conclusion': 'success',
          },
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
          goldClient: mockHttpClient,
          ingestionDelay: Duration.zero,
        );

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(log, hasNoWarningsOrHigher);

        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus.hasUpdates(1),
          ]),
        );

        // Should not label or comment
        verifyNever(
          issuesService.addLabelsToIssue(slug, pr.number!, <String>[
            kGoldenFileLabel,
          ]),
        );

        verifyNever(
          issuesService.createComment(
            slug,
            pr.number!,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ),
        );
      });

      test(
        'new commit, checks complete, change detected, should comment',
        () async {
          // New commit
          final pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];

          firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'framework',
              'status': 'completed',
              'conclusion': 'success',
            },
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
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log, hasNoWarningsOrHigher);

          expect(
            firestore,
            existsInStorage(fs.GithubGoldStatus.metadata, [
              isGithubGoldStatus.hasUpdates(1),
            ]),
          );

          // Should label and comment
          verify(
            issuesService.addLabelsToIssue(slug, pr.number!, <String>[
              kGoldenFileLabel,
            ]),
          ).called(1);

          verify(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          ).called(1);
        },
      );

      test(
        'new commit, checks complete, change detected, multiple duplicate patchsets, should comment',
        () async {
          // New commit
          final pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];

          firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'framework',
              'status': 'completed',
              'conclusion': 'success',
            },
          ];

          // Change detected by Gold
          mockHttpClient = MockClient((http.Request request) async {
            if (request.url.toString() ==
                'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${pr.number}') {
              return http.Response(
                tryjobDigestsDuplicatePatchsets(pr),
                HttpStatus.ok,
              );
            }
            throw const HttpException('Unexpected http request');
          });
          handler = PushGoldStatusToGithub(
            config: config,
            authenticationProvider: auth,
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log, hasNoWarningsOrHigher);

          expect(
            firestore,
            existsInStorage(fs.GithubGoldStatus.metadata, [
              isGithubGoldStatus.hasUpdates(1),
            ]),
          );

          // Should label and comment
          verify(
            issuesService.addLabelsToIssue(slug, pr.number!, <String>[
              kGoldenFileLabel,
            ]),
          ).called(1);

          verify(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          ).called(1);
        },
      );

      test(
        'same commit, checks complete, last status was waiting & gold status is needing triage, should comment',
        () async {
          // Same commit
          final pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];

          firestore.putDocument(
            newGithubGoldStatus(
              slug,
              pr,
              GithubGoldStatus.statusRunning,
              'abc',
              config.flutterGoldPendingValue!,
            ),
          );

          // Checks complete
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'framework',
              'status': 'completed',
              'conclusion': 'success',
            },
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
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          // Have not already commented for this commit.
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log, hasNoWarningsOrHigher);

          expect(
            firestore,
            existsInStorage(fs.GithubGoldStatus.metadata, [
              isGithubGoldStatus.hasUpdates(1),
            ]),
          );

          // Should apply labels and make comment
          verify(
            issuesService.addLabelsToIssue(slug, pr.number!, <String>[
              kGoldenFileLabel,
            ]),
          ).called(1);

          verify(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          ).called(1);
        },
      );

      test('uses shorter comment after first comment to reduce noise', () async {
        // Same commit
        final pr = newPullRequest(123, 'abc', 'master');
        prsFromGitHub = <PullRequest>[pr];

        firestore.putDocument(
          newGithubGoldStatus(
            slug,
            pr,
            GithubGoldStatus.statusRunning,
            'abc',
            config.flutterGoldPendingValue!,
          ),
        );

        // Checks complete
        checkRuns = <dynamic>[
          <String, String>{
            'name': 'framework',
            'completed': 'in_progress',
            'conclusion': 'success',
          },
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
          goldClient: mockHttpClient,
          ingestionDelay: Duration.zero,
        );

        // Have not already commented for this commit.
        when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = config.flutterGoldInitialAlertValue,
          ),
        );

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(log, hasNoWarningsOrHigher);

        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus.hasUpdates(1),
          ]),
        );

        // Should apply labels and make comment
        verify(
          issuesService.addLabelsToIssue(slug, pr.number!, <String>[
            kGoldenFileLabel,
          ]),
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

      test(
        'same commit, checks complete, new status, should not comment',
        () async {
          // Same commit: abc
          final pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];

          firestore.putDocument(
            newGithubGoldStatus(
              slug,
              pr,
              GithubGoldStatus.statusRunning,
              'abc',
              config.flutterGoldPendingValue!,
            ),
          );

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'framework',
              'status': 'completed',
              'conclusion': 'success',
            },
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
            goldClient: mockHttpClient,
            ingestionDelay: Duration.zero,
          );

          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log, hasNoWarningsOrHigher);

          expect(
            firestore,
            existsInStorage(fs.GithubGoldStatus.metadata, [
              isGithubGoldStatus.hasUpdates(1),
            ]),
          );

          // Should not label or comment
          verifyNever(
            issuesService.addLabelsToIssue(slug, pr.number!, <String>[
              kGoldenFileLabel,
            ]),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        },
      );

      test(
        'will inform contributor of unresolved check for ATF draft status',
        () async {
          // New commit, draft PR
          final pr = newPullRequest(123, 'abc', 'master', draft: true);
          prsFromGitHub = <PullRequest>[pr];

          firestore.putDocument(
            newGithubGoldStatus(
              slug,
              pr,
              GithubGoldStatus.statusRunning,
              'abc',
              config.flutterGoldPendingValue!,
            ),
          );

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'framework',
              'status': 'completed',
              'conclusion': 'success',
            },
          ];
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log, hasNoWarningsOrHigher);
          expect(
            firestore,
            existsInStorage(fs.GithubGoldStatus.metadata, [
              isGithubGoldStatus.hasUpdates(0),
            ]),
          );

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(slug, pr.number!, <String>[
              kGoldenFileLabel,
            ]),
          );

          verify(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldDraftChangeValue)),
            ),
          ).called(1);
        },
      );

      test(
        'will only inform contributor of unresolved check for ATF draft status once',
        () async {
          // New commit, draft PR
          final pr = newPullRequest(123, 'abc', 'master', draft: true);
          prsFromGitHub = <PullRequest>[pr];

          firestore.putDocument(
            newGithubGoldStatus(
              slug,
              pr,
              GithubGoldStatus.statusRunning,
              'abc',
              config.flutterGoldPendingValue!,
            ),
          );

          // Checks completed
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'framework',
              'status': 'completed',
              'conclusion': 'success',
            },
          ];
          when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = config.flutterGoldDraftChangeValue,
            ),
          );

          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log, hasNoWarningsOrHigher);
          expect(
            firestore,
            existsInStorage(fs.GithubGoldStatus.metadata, [
              isGithubGoldStatus.hasUpdates(0),
            ]),
          );

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(slug, pr.number!, <String>[
              kGoldenFileLabel,
            ]),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldDraftChangeValue)),
            ),
          );
        },
      );

      test(
        'delivers pending state for failing checks, does not query Gold',
        () async {
          // New commit
          final pr = newPullRequest(123, 'abc', 'master');
          prsFromGitHub = <PullRequest>[pr];

          firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

          // Checks failed
          checkRuns = <dynamic>[
            <String, String>{
              'name': 'framework',
              'status': 'completed',
              'conclusion': 'failure',
            },
          ];

          final body = await tester.get<Body>(handler);
          expect(body, same(Body.empty));
          expect(log, hasNoWarningsOrHigher);

          expect(
            firestore,
            existsInStorage(fs.GithubGoldStatus.metadata, [
              isGithubGoldStatus.hasUpdates(1),
            ]),
          );

          // Should not apply labels or make comments
          verifyNever(
            issuesService.addLabelsToIssue(slug, pr.number!, <String>[
              kGoldenFileLabel,
            ]),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              pr.number!,
              argThat(contains(config.flutterGoldCommentID(pr))),
            ),
          );
        },
      );
    });

    test(
      'Completed pull request does not skip follow-up prs with early return',
      () async {
        final completedPR = newPullRequest(123, 'abc', 'master');
        final followUpPR = newPullRequest(456, 'def', 'master');
        prsFromGitHub = <PullRequest>[completedPR, followUpPR];

        firestore.putDocument(
          newGithubGoldStatus(
            slug,
            completedPR,
            GithubGoldStatus.statusCompleted,
            'abc',
            config.flutterGoldSuccessValue!,
          ),
        );

        firestore.putDocument(
          newGithubGoldStatus(slug, followUpPR, '', '', ''),
        );

        // Checks completed
        checkRuns = <dynamic>[
          <String, String>{
            'name': 'framework',
            'status': 'completed',
            'conclusion': 'success',
          },
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
          goldClient: mockHttpClient,
          ingestionDelay: Duration.zero,
        );

        when(
          issuesService.listCommentsByIssue(slug, completedPR.number!),
        ).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = 'some other comment',
          ),
        );

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));

        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus
                .hasUpdates(0)
                .hasStatus(GithubGoldStatus.statusCompleted),
            isGithubGoldStatus
                .hasUpdates(1)
                .hasStatus(GithubGoldStatus.statusCompleted),
          ]),
        );

        expect(log, hasNoWarningsOrHigher);
      },
    );

    test(
      'accounts for null status description when parsing for Luci builds',
      () async {
        // Same commit
        final pr = newPullRequest(123, 'abc', 'master');
        prsFromGitHub = <PullRequest>[pr];

        firestore.putDocument(
          newGithubGoldStatus(
            slug,
            pr,
            GithubGoldStatus.statusRunning,
            'abc',
            config.flutterGoldPendingValue!,
          ),
        );

        // null status for luci build
        checkRuns = <dynamic>[
          <String, String?>{
            'name': 'framework',
            'status': null,
            'conclusion': null,
          },
        ];

        final body = await tester.get<Body>(handler);
        expect(body, same(Body.empty));
        expect(log, hasNoWarningsOrHigher);
        expect(
          firestore,
          existsInStorage(fs.GithubGoldStatus.metadata, [
            isGithubGoldStatus.hasUpdates(0),
          ]),
        );

        // Should not apply labels or make comments
        verifyNever(
          issuesService.addLabelsToIssue(slug, pr.number!, <String>[
            kGoldenFileLabel,
          ]),
        );

        verifyNever(
          issuesService.createComment(
            slug,
            pr.number!,
            argThat(contains(config.flutterGoldCommentID(pr))),
          ),
        );
      },
    );

    test('uses the correct Gold endpoint to get status', () async {
      // New commit
      final pr = newPullRequest(123, 'abc', 'master');
      prsFromGitHub = <PullRequest>[pr];

      firestore.putDocument(newGithubGoldStatus(slug, pr, '', '', ''));

      // Checks completed
      checkRuns = <dynamic>[
        <String, String>{
          'name': 'framework',
          'status': 'completed',
          'conclusion': 'success',
        },
        <String, String>{
          'name': 'Linux linux_web_engine',
          'status': 'completed',
          'conclusion': 'success',
        },
      ];

      // Requests sent to Gold.
      final goldRequests = <String>[];
      mockHttpClient = MockClient((http.Request request) async {
        final requestUrl = request.url.toString();
        goldRequests.add(requestUrl);

        final prNumber = int.parse(requestUrl.split('/').last);
        final PullRequest requestedPr;
        if (prNumber == pr.number) {
          requestedPr = pr;
        } else {
          throw HttpException('Unexpected http request for PR#$prNumber');
        }
        return http.Response(tryjobDigests(requestedPr), HttpStatus.ok);
      });
      handler = PushGoldStatusToGithub(
        config: config,
        authenticationProvider: auth,
        goldClient: mockHttpClient,
        ingestionDelay: Duration.zero,
      );

      // Have not already commented for this commit.
      when(issuesService.listCommentsByIssue(slug, pr.number!)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.get<Body>(handler);

      expect(goldRequests, <String>[
        'https://flutter-gold.skia.org/json/v1/changelist_summary/github/${pr.number}',
      ]);
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
                      },
                    ],
                  },
                },
              },
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

/// JSON response template for Skia Gold untriaged tryjob status request.
String tryjobDigestsDuplicatePatchsets(PullRequest pr) {
  return '''
    {
      "changelist_id": "${pr.number!}",
      "patchsets": [
        {
          "new_images": 0,
          "new_untriaged_images": 0,
          "total_untriaged_images": 0,
          "patchset_id": "${pr.head!.sha!}",
          "patchset_order": 1
        },
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
