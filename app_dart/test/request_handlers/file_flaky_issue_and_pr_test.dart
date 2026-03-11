// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/ci_yaml.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/proto/internal/scheduler.pb.dart'
    as pb;
import 'package:cocoon_service/src/request_handlers/flaky_handler_utils.dart';
import 'package:cocoon_service/src/service/big_query.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:cocoon_service/src/service/test_suppression.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../src/request_handling/api_request_handler_tester.dart';
import 'file_flaky_issue_and_pr_test_data.dart';

const String kThreshold = '0.02';
const String kCurrentMasterSHA = 'b6156fc8d1c6e992fe4ea0b9128f9aef10443bdb';
const String kCurrentUserName = 'Name';
const String kCurrentUserLogin = 'login';
const String kCurrentUserEmail = 'login@email.com';

void main() {
  useTestLoggerPerTest();

  group('Check flaky', () {
    late FileFlakyIssueAndPR handler;
    late ApiRequestHandlerTester tester;
    late FakeHttpRequest request;
    late FakeConfig config;
    late FakeClientContext clientContext;
    late FakeDashboardAuthentication auth;
    late MockBigQueryService mockBigQueryService;
    late MockGitHub mockGitHubClient;
    late MockRepositoriesService mockRepositoriesService;
    late MockPullRequestsService mockPullRequestsService;
    late MockIssuesService mockIssuesService;
    late MockGitService mockGitService;
    late MockUsersService mockUsersService;

    late FakeFirestoreService firestore;
    late CacheService cache;
    final fakeNow = DateTime.timestamp();
    late TestSuppression suppression;

    setUp(() {
      request = FakeHttpRequest(
        queryParametersValue: <String, dynamic>{
          FileFlakyIssueAndPR.kThresholdKey: kThreshold,
        },
      );

      clientContext = FakeClientContext();
      auth = FakeDashboardAuthentication(clientContext: clientContext);
      mockBigQueryService = MockBigQueryService();
      mockGitHubClient = MockGitHub();
      mockRepositoriesService = MockRepositoriesService();
      mockIssuesService = MockIssuesService();
      mockPullRequestsService = MockPullRequestsService();
      mockGitService = MockGitService();
      mockUsersService = MockUsersService();

      firestore = FakeFirestoreService();
      cache = CacheService(inMemory: true);
      suppression = TestSuppression(
        firestore: firestore,
        cache: cache,
        now: () => fakeNow,
      );

      // when gets the content of .ci.yaml
      when(
        // ignore: discarded_futures
        mockRepositoriesService.getContents(captureAny, kCiYamlPath),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
          RepositoryContents(
            file: GitHubFile(content: gitHubEncode(ciYamlContent)),
          ),
        );
      });
      // when gets the content of TESTOWNERS
      when(
        // ignore: discarded_futures
        mockRepositoriesService.getContents(captureAny, kTestOwnerPath),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
          RepositoryContents(
            file: GitHubFile(content: gitHubEncode(testOwnersContent)),
          ),
        );
      });
      // ignore: discarded_futures
      when(mockIssuesService.create(any, any)).thenAnswer((_) async => Issue());
      // when gets existing flaky issues.
      when(
        mockIssuesService.listByRepo(
          captureAny,
          state: captureAnyNamed('state'),
          labels: captureAnyNamed('labels'),
        ),
      ).thenAnswer((Invocation invocation) {
        return const Stream<Issue>.empty();
      });
      // when gets existing marks flaky prs.
      when(mockPullRequestsService.list(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return const Stream<PullRequest>.empty();
      });
      // when gets the current head of master branch
      // ignore: discarded_futures
      when(mockGitService.getReference(captureAny, kMasterRefs)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<GitReference>.value(
          GitReference(
            ref: 'refs/$kMasterRefs',
            object: GitObject('', kCurrentMasterSHA, ''),
          ),
        );
      });
      // when gets the current user.
      // ignore: discarded_futures
      when(mockUsersService.getCurrentUser()).thenAnswer((
        Invocation invocation,
      ) {
        final result = CurrentUser();
        result.email = kCurrentUserEmail;
        result.name = kCurrentUserName;
        result.login = kCurrentUserLogin;
        return Future<CurrentUser>.value(result);
      });
      // when assigns pull request reviewer.
      when(
        // ignore: discarded_futures
        mockGitHubClient.postJSON<Map<String, dynamic>, PullRequest>(
          captureAny,
          statusCode: captureAnyNamed('statusCode'),
          fail: captureAnyNamed('fail'),
          headers: captureAnyNamed('headers'),
          params: captureAnyNamed('params'),
          convert: captureAnyNamed('convert'),
          body: captureAnyNamed('body'),
          preview: captureAnyNamed('preview'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<PullRequest>.value(PullRequest());
      });
      when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);
      when(mockGitHubClient.issues).thenReturn(mockIssuesService);
      when(mockGitHubClient.pullRequests).thenReturn(mockPullRequestsService);
      when(mockGitHubClient.git).thenReturn(mockGitService);
      when(mockGitHubClient.users).thenReturn(mockUsersService);
      config = FakeConfig(
        githubService: GithubService(mockGitHubClient),
        githubClient: mockGitHubClient,
      );
      tester = ApiRequestHandlerTester(request: request);

      handler = FileFlakyIssueAndPR(
        config: config,
        authenticationProvider: auth,
        bigQuery: mockBigQueryService,
        testSuppression: suppression,
      );
    });

    test('Can file issue and suppress for devicelab test', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigQueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponse,
        );
      });
      // When creates issue
      when(mockIssuesService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(htmlUrl: expectedSemanticsIntegrationTestNewIssueURL),
        );
      });

      final result =
          await utf8.decoder
                  .bind((await tester.get(handler)).body as Stream<List<int>>)
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;

      // Verify issue is created correctly.
      final captured = verify(
        mockIssuesService.create(captureAny, captureAny),
      ).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], isA<IssueRequest>());
      final issueRequest = captured[1] as IssueRequest;
      expect(issueRequest.title, expectedSemanticsIntegrationTestResponseTitle);
      expect(issueRequest.body, expectedSemanticsIntegrationTestResponseBody);
      expect(
        issueRequest.assignee,
        expectedSemanticsIntegrationTestResponseAssignee,
      );
      expect(
        const ListEquality<String>().equals(
          issueRequest.labels,
          expectedSemanticsIntegrationTestResponseLabels,
        ),
        isTrue,
      );

      // Verify test is suppressed in firestore
      expect(
        firestore,
        existsInStorage(SuppressedTest.metadata, [
          isSuppressedTest
              .hasTestName('Mac_android android_semantics_integration_test')
              .hasRepository('flutter/flutter')
              .hasIsSuppressed(isTrue)
              .hasIssueLink(expectedSemanticsIntegrationTestNewIssueURL)
              .hasUpdates([
                {
                  'user': 'fluttergithubbot',
                  'action': 'SUPPRESS',
                  'note': 'flaky test rate: 0.02',
                  'updateTimestamp': fakeNow,
                },
              ]),
        ]),
      );

      expect(result['Status'], 'success');
    });

    test('File mulitple issues and suppressions', () async {
      // when gets the content of .ci.yaml
      when(
        mockRepositoriesService.getContents(captureAny, kCiYamlPath),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
          RepositoryContents(
            file: GitHubFile(
              content: gitHubEncode(ciYamlContentTwoFlakyTargets),
            ),
          ),
        );
      });
      // When queries flaky data from BigQuery.
      when(
        mockBigQueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponse,
        );
      });
      // When creates issue
      when(mockIssuesService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(htmlUrl: expectedSemanticsIntegrationTestNewIssueURL),
        );
      });

      final result =
          await utf8.decoder
                  .bind((await tester.get(handler)).body as Stream<List<int>>)
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;
      expect(result['Status'], 'success');
      expect(result['NumberOfCreatedIssuesAndPRs'], 2);

      // Verify both tests are suppressed
      expect(
        firestore,
        existsInStorage(SuppressedTest.metadata, [
          isSuppressedTest.hasTestName(
            'Mac_android android_semantics_integration_test',
          ),
          isSuppressedTest.hasTestName('Mac_android ignore_myflakiness'),
        ]),
      );
    });

    test('File issues and suppressions up to issueAndPRLimit', () async {
      // when gets the content of .ci.yaml
      config = FakeConfig(
        githubService: GithubService(mockGitHubClient),
        githubClient: mockGitHubClient,
        issueAndPRLimitValue: 1,
      );
      handler = FileFlakyIssueAndPR(
        config: config,
        authenticationProvider: auth,
        bigQuery: mockBigQueryService,
        testSuppression: suppression,
      );
      when(
        mockRepositoriesService.getContents(captureAny, kCiYamlPath),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
          RepositoryContents(
            file: GitHubFile(
              content: gitHubEncode(ciYamlContentTwoFlakyTargets),
            ),
          ),
        );
      });
      // When queries flaky data from BigQuery.
      when(
        mockBigQueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponse,
        );
      });
      // When creates issue
      when(mockIssuesService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(htmlUrl: expectedSemanticsIntegrationTestNewIssueURL),
        );
      });

      final result =
          await utf8.decoder
                  .bind((await tester.get(handler)).body as Stream<List<int>>)
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;
      expect(result['Status'], 'success');
      expect(result['NumberOfCreatedIssuesAndPRs'], 1);

      // Verify only one test is suppressed
      final suppressed = await SuppressedTest.getSuppressedTests(
        firestore,
        'flutter/flutter',
      );
      expect(suppressed.length, 1);
    });

    test(
      'Can file issue and suppression for framework host-only test',
      () async {
        // When queries flaky data from BigQuery.
        when(
          mockBigQueryService.listBuilderStatistic(kBigQueryProjectId),
        ).thenAnswer((Invocation invocation) {
          return Future<List<BuilderStatistic>>.value(analyzeTestResponse);
        });
        // When creates issue
        when(mockIssuesService.create(captureAny, captureAny)).thenAnswer((_) {
          return Future<Issue>.value(
            Issue(htmlUrl: expectedSemanticsIntegrationTestNewIssueURL),
          );
        });

        final result =
            await utf8.decoder
                    .bind((await tester.get(handler)).body as Stream<List<int>>)
                    .transform(json.decoder)
                    .single
                as Map<String, dynamic>;

        // Verify issue is created correctly.
        final captured = verify(
          mockIssuesService.create(captureAny, captureAny),
        ).captured;
        expect(captured.length, 2);
        expect(captured[0].toString(), Config.flutterSlug.toString());
        expect(captured[1], isA<IssueRequest>());
        final issueRequest = captured[1] as IssueRequest;
        expect(issueRequest.assignee, expectedAnalyzeTestResponseAssignee);
        expect(
          const ListEquality<String>().equals(
            issueRequest.labels,
            expectedAnalyzeTestResponseLabels,
          ),
          isTrue,
        );

        // Verify suppression
        final suppressed = await SuppressedTest.getSuppressedTests(
          firestore,
          'flutter/flutter',
        );
        expect(suppressed.length, 1);
        expect(suppressed[0].testName, 'Linux analyze');
        expect(
          suppressed[0].issueLink,
          expectedSemanticsIntegrationTestNewIssueURL,
        );

        expect(result['Status'], 'success');
      },
    );

    test(
      'Can file issue when limited number of successfuly builds exist',
      () async {
        // When queries flaky data from BigQuery.
        when(
          mockBigQueryService.listBuilderStatistic(kBigQueryProjectId),
        ).thenAnswer((Invocation invocation) {
          return Future<List<BuilderStatistic>>.value(
            limitedNumberOfBuildsResponse,
          );
        });
        // When creates issue
        when(mockIssuesService.create(captureAny, captureAny)).thenAnswer((_) {
          return Future<Issue>.value(
            Issue(htmlUrl: expectedSemanticsIntegrationTestNewIssueURL),
          );
        });

        final result =
            await utf8.decoder
                    .bind((await tester.get(handler)).body as Stream<List<int>>)
                    .transform(json.decoder)
                    .single
                as Map<String, dynamic>;

        // Verify issue is created correctly.
        final captured = verify(
          mockIssuesService.create(captureAny, captureAny),
        ).captured;
        expect(captured.length, 2);
        expect(captured[0].toString(), Config.flutterSlug.toString());
        expect(captured[1], isA<IssueRequest>());
        final issueRequest = captured[1] as IssueRequest;
        expect(issueRequest.body, expectedLimitedNumberOfBuildsResponseBody);

        // Verify suppression
        final suppressed = await SuppressedTest.getSuppressedTests(
          firestore,
          'flutter/flutter',
        );
        expect(suppressed.length, 1);
        expect(
          suppressed[0].issueLink,
          expectedSemanticsIntegrationTestNewIssueURL,
        );

        expect(result['Status'], 'success');
      },
    );

    test('Can file issue but still suppress for shard test', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigQueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(frameworkTestResponse);
      });
      // When creates issue
      when(mockIssuesService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(htmlUrl: expectedSemanticsIntegrationTestNewIssueURL),
        );
      });
      final result =
          await utf8.decoder
                  .bind((await tester.get(handler)).body as Stream<List<int>>)
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;

      // Verify issue is created correctly.
      final captured = verify(
        mockIssuesService.create(captureAny, captureAny),
      ).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], isA<IssueRequest>());
      final issueRequest = captured[1] as IssueRequest;
      expect(issueRequest.assignee, expectedFrameworkTestResponseAssignee);
      expect(
        const ListEquality<String>().equals(
          issueRequest.labels,
          expectedFrameworkTestResponseLabels,
        ),
        isTrue,
      );

      // Verify suppression still happens for shard tests
      final suppressed = await SuppressedTest.getSuppressedTests(
        firestore,
        'flutter/flutter',
      );
      expect(suppressed.length, 1);
      expect(
        suppressed[0].issueLink,
        expectedSemanticsIntegrationTestNewIssueURL,
      );

      expect(result['Status'], 'success');
    });

    test('Do not create issue if there is already one', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigQueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponse,
        );
      });
      // when gets existing flaky issues.
      when(
        mockIssuesService.listByRepo(
          captureAny,
          state: captureAnyNamed('state'),
          labels: captureAnyNamed('labels'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[
          Issue(
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
          ),
        ]);
      });

      final result =
          await utf8.decoder
                  .bind((await tester.get(handler)).body as Stream<List<int>>)
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;
      // Verify no issue is created.
      verifyNever(mockIssuesService.create(captureAny, captureAny));
      // Verify no suppression is created.
      final suppressed = await SuppressedTest.getSuppressedTests(
        firestore,
        'flutter/flutter',
      );
      expect(suppressed.isEmpty, isTrue);

      expect(result['Status'], 'success');
    });

    test('Do not create issue if there is a recently closed one', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigQueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponse,
        );
      });
      // when get existing flaky issues.
      when(
        mockIssuesService.listByRepo(
          captureAny,
          state: captureAnyNamed('state'),
          labels: captureAnyNamed('labels'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[
          Issue(
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
            state: 'closed',
            closedAt: DateTime.now().subtract(
              const Duration(days: kGracePeriodForClosedFlake - 1),
            ),
          ),
        ]);
      });

      final result =
          await utf8.decoder
                  .bind((await tester.get(handler)).body as Stream<List<int>>)
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;
      // Verify no issue is created.
      verifyNever(mockIssuesService.create(captureAny, captureAny));
      // Verify no suppression is created.
      final suppressed = await SuppressedTest.getSuppressedTests(
        firestore,
        'flutter/flutter',
      );
      expect(suppressed.isEmpty, isTrue);

      expect(result['Status'], 'success');
    });

    test(
      'Do create issue if there is a closed one outside the grace period',
      () async {
        // When queries flaky data from BigQuery.
        when(
          mockBigQueryService.listBuilderStatistic(kBigQueryProjectId),
        ).thenAnswer((Invocation invocation) {
          return Future<List<BuilderStatistic>>.value(
            semanticsIntegrationTestResponse,
          );
        });
        // when get existing flaky issues.
        when(
          mockIssuesService.listByRepo(
            captureAny,
            state: captureAnyNamed('state'),
            labels: captureAnyNamed('labels'),
          ),
        ).thenAnswer((Invocation invocation) {
          return Stream<Issue>.fromIterable(<Issue>[
            Issue(
              title: expectedSemanticsIntegrationTestResponseTitle,
              body: expectedSemanticsIntegrationTestResponseBody,
              state: 'closed',
              closedAt: DateTime.now().subtract(
                const Duration(days: kGracePeriodForClosedFlake + 1),
              ),
            ),
          ]);
        });

        final result =
            await utf8.decoder
                    .bind((await tester.get(handler)).body as Stream<List<int>>)
                    .transform(json.decoder)
                    .single
                as Map<String, dynamic>;
        // Verify issue is created correctly.
        final captured = verify(
          mockIssuesService.create(captureAny, captureAny),
        ).captured;
        expect(captured.length, 2);
        expect(captured[0].toString(), Config.flutterSlug.toString());
        expect(captured[1], isA<IssueRequest>());
        final issueRequest = captured[1] as IssueRequest;
        expect(
          issueRequest.title,
          expectedSemanticsIntegrationTestResponseTitle,
        );
        expect(issueRequest.body, expectedSemanticsIntegrationTestResponseBody);
        expect(
          issueRequest.assignee,
          expectedSemanticsIntegrationTestResponseAssignee,
        );
        expect(
          const ListEquality<String>().equals(
            issueRequest.labels,
            expectedSemanticsIntegrationTestResponseLabels,
          ),
          isTrue,
        );

        // Verify suppression
        final suppressed = await SuppressedTest.getSuppressedTests(
          firestore,
          'flutter/flutter',
        );
        expect(suppressed.length, 1);

        expect(result['Status'], 'success');
      },
    );

    test(
      'Do not create an issue or suppression if the test is already suppressed',
      () async {
        // When queries flaky data from BigQuery.
        when(
          mockBigQueryService.listBuilderStatistic(kBigQueryProjectId),
        ).thenAnswer((Invocation invocation) {
          return Future<List<BuilderStatistic>>.value(
            semanticsIntegrationTestResponse,
          );
        });

        // Mark as suppressed in firestore
        final suppressedTest =
            SuppressedTest(
                name: 'Mac_android android_semantics_integration_test',
                repository: 'flutter/flutter',
                issueLink: 'https://github.com/flutter/flutter/issues/123',
                isSuppressed: true,
                createTimestamp: DateTime.now().toUtc(),
              )
              ..name = firestore.resolveDocumentName(
                SuppressedTest.kCollectionId,
                'existing_doc',
              );
        firestore.putDocument(suppressedTest);
        final result =
            await utf8.decoder
                    .bind((await tester.get(handler)).body as Stream<List<int>>)
                    .transform(json.decoder)
                    .single
                as Map<String, dynamic>;
        // Verify no issue is created.
        verifyNever(mockIssuesService.create(captureAny, captureAny));

        expect(result['Status'], 'success');
      },
    );

    test('Do not create issue if there is already an opened one', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigQueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponse,
        );
      });
      // when gets existing flaky issues.
      when(
        mockIssuesService.listByRepo(
          captureAny,
          state: captureAnyNamed('state'),
          labels: captureAnyNamed('labels'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[
          Issue(
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
            state: 'open',
          ),
        ]);
      });

      final result =
          await utf8.decoder
                  .bind((await tester.get(handler)).body as Stream<List<int>>)
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;
      // Verify no issue is created.
      verifyNever(mockIssuesService.create(captureAny, captureAny));

      expect(result['Status'], 'success');
    });

    test('skips when the target doesn not exist', () {
      final ci = loadYaml(ciYamlContent) as YamlMap?;
      final unCheckedSchedulerConfig = pb.SchedulerConfig()
        ..mergeFromProto3Json(ci);
      final ciYaml = CiYamlSet(
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        yamls: {CiType.any: unCheckedSchedulerConfig},
      );
      final builderStatistic = BuilderStatistic(
        name: 'Mac_android test',
        flakyRate: 0.5,
        flakyBuilds: <String>['103', '102', '101'],
        succeededBuilds: <String>['203', '202', '201'],
        recentCommit: 'abc',
        flakyBuildOfRecentCommit: '103',
        flakyNumber: 3,
        totalNumber: 6,
      );
      final targets = unCheckedSchedulerConfig.targets;
      expect(
        handler.shouldSkip(builderStatistic, ciYaml, targets, threshold: 0.02),
        true,
      );
    });

    test('skips if the flakiness_threshold is not met', () {
      final ci = loadYaml(ciYamlContent) as YamlMap?;
      final unCheckedSchedulerConfig = pb.SchedulerConfig()
        ..mergeFromProto3Json(ci);
      final ciYaml = CiYamlSet(
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        yamls: {CiType.any: unCheckedSchedulerConfig},
      );
      final builderStatistic = BuilderStatistic(
        name: 'Mac_android higher_myflakiness',
        flakyRate: 0.05,
        flakyBuilds: <String>['103', '102', '101'],
        succeededBuilds: <String>['203', '202', '201'],
        recentCommit: 'abc',
        flakyBuildOfRecentCommit: '103',
        flakyNumber: 3,
        totalNumber: 6,
      );
      final targets = unCheckedSchedulerConfig.targets;
      expect(
        handler.shouldSkip(builderStatistic, ciYaml, targets, threshold: 0.02),
        true,
        reason: 'test specific flakiness_threshold overrides global threshold',
      );
    });

    test('honors the flakiness_threshold', () {
      final ci = loadYaml(ciYamlContent) as YamlMap?;
      final unCheckedSchedulerConfig = pb.SchedulerConfig()
        ..mergeFromProto3Json(ci);
      final ciYaml = CiYamlSet(
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        yamls: {CiType.any: unCheckedSchedulerConfig},
      );
      final builderStatistic = BuilderStatistic(
        name: 'Mac_android higher_myflakiness',
        flakyRate: 0.11,
        flakyBuilds: <String>['103', '102', '101'],
        succeededBuilds: <String>['203', '202', '201'],
        recentCommit: 'abc',
        flakyBuildOfRecentCommit: '103',
        flakyNumber: 3,
        totalNumber: 6,
      );
      final targets = unCheckedSchedulerConfig.targets;
      expect(
        handler.shouldSkip(builderStatistic, ciYaml, targets, threshold: 0.02),
        false,
        reason: 'falkiness greater than test specified should trigger',
      );
    });
  });

  test('retrieveMetaTagsFromContent can work with different newlines', () async {
    const differentNewline =
        '<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY.\r\n{"name": "Mac_android android_semantics_integration_test"}\r\n-->';
    final metaTags = retrieveMetaTagsFromContent(differentNewline)!;
    expect(metaTags['name'], 'Mac_android android_semantics_integration_test');
  });

  test('getIgnoreFlakiness handles non-existing builderame', () async {
    final ci = loadYaml(ciYamlContent) as YamlMap?;
    final unCheckedSchedulerConfig = pb.SchedulerConfig()
      ..mergeFromProto3Json(ci);
    final ciYaml = CiYamlSet(
      slug: Config.flutterSlug,
      branch: Config.defaultBranch(Config.flutterSlug),
      yamls: {CiType.any: unCheckedSchedulerConfig},
    );
    expect(
      FileFlakyIssueAndPR.getIgnoreFlakiness('Non_existing', ciYaml),
      false,
    );
  });
}
