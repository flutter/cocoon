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
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../src/request_handling/api_request_handler_tester.dart';
import 'check_flaky_builders_test_data.dart';

const String kThreshold = '0.02';
const String kCurrentMasterSHA = 'b6156fc8d1c6e992fe4ea0b9128f9aef10443bdb';
const String kCurrentUserName = 'Name';
const String kCurrentUserLogin = 'login';
const String kCurrentUserEmail = 'login@email.com';

void main() {
  useTestLoggerPerTest();

  group('Deflake', () {
    late CheckFlakyBuilders handler;
    late ApiRequestHandlerTester tester;
    late FakeHttpRequest request;
    late FakeConfig config;
    late FakeClientContext clientContext;
    late FakeDashboardAuthentication auth;
    late MockBigQueryService mockBigQueryService;
    late MockGitHub mockGitHubClient;
    late MockRepositoriesService mockRepositoriesService;
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
      when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);
      when(mockGitHubClient.issues).thenReturn(mockIssuesService);
      when(mockGitHubClient.git).thenReturn(mockGitService);
      when(mockGitHubClient.users).thenReturn(mockUsersService);
      config = FakeConfig(githubService: GithubService(mockGitHubClient));
      tester = ApiRequestHandlerTester(request: request);

      handler = CheckFlakyBuilders(
        config: config,
        authenticationProvider: auth,
        bigQuery: mockBigQueryService,
        testSuppression: suppression,
      );
    });

    test(
      'Unsuppress and comment on issue if the test is no longer flaky with a closed issue',
      () async {
        // When queries flaky data from BigQuery.
        when(
          mockBigQueryService.listRecentBuildRecordsForBuilder(
            kBigQueryProjectId,
            builder: captureAnyNamed('builder'),
            limit: captureAnyNamed('limit'),
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<List<BuilderRecord>>.value(
            semanticsIntegrationTestRecordsAllPassed,
          );
        });

        // When get issue
        when(mockIssuesService.get(captureAny, captureAny)).thenAnswer((_) {
          return Future<Issue>.value(
            Issue(
              number: existingIssueNumber,
              state: 'CLOSED',
              htmlUrl: existingIssueURL,
            ),
          );
        });
        // Mock issue edit for closing
        when(
          mockIssuesService.edit(captureAny, captureAny, captureAny),
        ).thenAnswer((_) => Future<Issue>.value(Issue()));
        // Mock comment creation
        when(
          mockIssuesService.createComment(captureAny, captureAny, captureAny),
        ).thenAnswer((_) => Future<IssueComment>.value(IssueComment()));

        // Seed Firestore with a suppressed test
        final suppressedTest =
            SuppressedTest(
                name: 'Mac_android android_semantics_integration_test',
                repository: 'flutter/flutter',
                issueLink: existingIssueURL,
                isSuppressed: true,
                createTimestamp: fakeNow,
              )
              ..name = firestore.resolveDocumentName(
                SuppressedTest.kCollectionId,
                'doc1',
              );
        firestore.putDocument(suppressedTest);

        CheckFlakyBuilders.kRecordNumber =
            semanticsIntegrationTestRecordsAllPassed.length;
        final result =
            await utf8.decoder
                    .bind((await tester.get(handler)).body as Stream<List<int>>)
                    .transform(json.decoder)
                    .single
                as Map<String, dynamic>;

        // Verify BigQuery is called correctly.
        var captured = verify(
          mockBigQueryService.listRecentBuildRecordsForBuilder(
            captureAny,
            builder: captureAnyNamed('builder'),
            limit: captureAnyNamed('limit'),
          ),
        ).captured;
        expect(captured.length, 3);
        expect(captured[0].toString(), kBigQueryProjectId);
        expect(
          captured[1] as String?,
          expectedSemanticsIntegrationTestBuilderName,
        );
        expect(captured[2] as int?, CheckFlakyBuilders.kRecordNumber);

        // Verify it gets the correct issue.
        captured = verify(
          mockIssuesService.get(captureAny, captureAny),
        ).captured;
        expect(captured.length, 2);
        expect(captured[0], Config.flutterSlug);
        expect(captured[1] as int?, existingIssueNumber);

        // Verify comment is created
        captured = verify(
          mockIssuesService.createComment(captureAny, captureAny, captureAny),
        ).captured;
        expect(captured[1] as int?, existingIssueNumber);
        expect(captured[2] as String, contains('passing for'));

        // Verify issue is closed
        captured = verify(
          mockIssuesService.edit(captureAny, captureAny, captureAny),
        ).captured;
        expect(captured[1] as int?, existingIssueNumber);
        final issueRequest = captured[2] as IssueRequest;
        expect(issueRequest.state, 'closed');

        // Verify test is UNSUPPRESSED in firestore
        expect(
          firestore,
          existsInStorage(SuppressedTest.metadata, [
            isSuppressedTest
                .hasTestName('Mac_android android_semantics_integration_test')
                .hasIsSuppressed(isFalse),
          ]),
        );

        expect(result['Status'], 'success');
      },
    );

    test('Do not unsuppress if the builder is in the ignored list', () async {
      // If the list is empty; we can't properly test.
      if (CheckFlakyBuilders.ignoredBuilders.isEmpty) {
        return;
      }
      final ignoredBuilder = CheckFlakyBuilders.ignoredBuilders.first;

      // when gets the content of .ci.yaml
      when(
        mockRepositoriesService.getContents(captureAny, kCiYamlPath),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
          RepositoryContents(
            file: GitHubFile(
              content: gitHubEncode(ciYamlContentFlakyInIgnoreList),
            ),
          ),
        );
      });

      // Seed Firestore with a suppressed test that is ignored
      final suppressedTest =
          SuppressedTest(
              name: ignoredBuilder,
              repository: 'flutter/flutter',
              issueLink: 'https://github.com/flutter/flutter/issues/1',
              isSuppressed: true,
              createTimestamp: fakeNow,
            )
            ..name = firestore.resolveDocumentName(
              SuppressedTest.kCollectionId,
              'ignored_doc',
            );
      firestore.putDocument(suppressedTest);

      CheckFlakyBuilders.kRecordNumber =
          semanticsIntegrationTestRecordsAllPassed.length;
      final result =
          await utf8.decoder
                  .bind((await tester.get(handler)).body as Stream<List<int>>)
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;

      // Verify firestore remains suppressed
      expect(
        firestore,
        existsInStorage(SuppressedTest.metadata, [
          isSuppressedTest.hasTestName(ignoredBuilder).hasIsSuppressed(isTrue),
        ]),
      );

      expect(result['Status'], 'success');
    });

    test('Do not un-suppress if the issue is still open', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigQueryService.listRecentBuildRecordsForBuilder(
          kBigQueryProjectId,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderRecord>>.value(
          semanticsIntegrationTestRecordsAllPassed,
        );
      });

      // Seed Firestore with a suppressed test
      final suppressedTest =
          SuppressedTest(
              name: 'Mac_android android_semantics_integration_test',
              repository: 'flutter/flutter',
              issueLink: existingIssueURL,
              isSuppressed: true,
              createTimestamp: fakeNow,
            )
            ..name = firestore.resolveDocumentName(
              SuppressedTest.kCollectionId,
              'doc1',
            );
      firestore.putDocument(suppressedTest);

      // When get issue
      when(mockIssuesService.get(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(
            number: existingIssueNumber,
            state: 'OPEN',
            htmlUrl: existingIssueURL,
          ),
        );
      });
      CheckFlakyBuilders.kRecordNumber =
          semanticsIntegrationTestRecordsAllPassed.length;
      final result =
          await utf8.decoder
                  .bind((await tester.get(handler)).body as Stream<List<int>>)
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;

      // Verify it gets the correct issue.
      final captured = verify(
        mockIssuesService.get(captureAny, captureAny),
      ).captured;
      expect(captured.length, 2);
      expect(captured[0], Config.flutterSlug);
      expect(captured[1] as int?, existingIssueNumber);

      // Verify comment is not created: that's the job of UpdateExistingFlakyIssue
      // right now.
      verifyNever(
        mockIssuesService.createComment(captureAny, captureAny, captureAny),
      );

      // Verify firestore remains suppressed
      expect(
        firestore,
        existsInStorage(SuppressedTest.metadata, [
          isSuppressedTest
              .hasTestName('Mac_android android_semantics_integration_test')
              .hasIsSuppressed(isTrue),
        ]),
      );

      expect(result['Status'], 'success');
    });

    test('Do not unsuppress if the records have failed runs', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigQueryService.listRecentBuildRecordsForBuilder(
          kBigQueryProjectId,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderRecord>>.value(
          semanticsIntegrationTestRecordsFailed,
        );
      });

      // Seed Firestore with a suppressed test
      final suppressedTest =
          SuppressedTest(
              name: 'Mac_android android_semantics_integration_test',
              repository: 'flutter/flutter',
              issueLink: existingIssueURL,
              isSuppressed: true,
              createTimestamp: fakeNow,
            )
            ..name = firestore.resolveDocumentName(
              SuppressedTest.kCollectionId,
              'doc1',
            );
      firestore.putDocument(suppressedTest);

      // When get issue
      when(mockIssuesService.get(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(
            number: existingIssueNumber,
            state: 'CLOSED',
            htmlUrl: existingIssueURL,
            closedAt: fakeNow.subtract(const Duration(days: 50)),
          ),
        );
      });

      CheckFlakyBuilders.kRecordNumber =
          semanticsIntegrationTestRecordsFailed.length;
      final result =
          await utf8.decoder
                  .bind((await tester.get(handler)).body as Stream<List<int>>)
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;

      // Verify firestore remains suppressed
      expect(
        firestore,
        existsInStorage(SuppressedTest.metadata, [
          isSuppressedTest
              .hasTestName('Mac_android android_semantics_integration_test')
              .hasIsSuppressed(isTrue),
        ]),
      );

      expect(result['Status'], 'success');
    });

    test('Do not unsuppress if not enough records', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigQueryService.listRecentBuildRecordsForBuilder(
          kBigQueryProjectId,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderRecord>>.value(
          semanticsIntegrationTestRecordsAllPassed,
        );
      });

      // Seed Firestore with a suppressed test
      final suppressedTest =
          SuppressedTest(
              name: 'Mac_android android_semantics_integration_test',
              repository: 'flutter/flutter',
              issueLink: existingIssueURL,
              isSuppressed: true,
              createTimestamp: fakeNow,
            )
            ..name = firestore.resolveDocumentName(
              SuppressedTest.kCollectionId,
              'doc1',
            );
      firestore.putDocument(suppressedTest);

      // When get issue
      when(mockIssuesService.get(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(
            number: existingIssueNumber,
            state: 'CLOSED',
            htmlUrl: existingIssueURL,
            closedAt: fakeNow.subtract(const Duration(days: 50)),
          ),
        );
      });

      CheckFlakyBuilders.kRecordNumber =
          semanticsIntegrationTestRecordsAllPassed.length + 1;
      final result =
          await utf8.decoder
                  .bind((await tester.get(handler)).body as Stream<List<int>>)
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;

      // Verify firestore remains suppressed
      expect(
        firestore,
        existsInStorage(SuppressedTest.metadata, [
          isSuppressedTest
              .hasTestName('Mac_android android_semantics_integration_test')
              .hasIsSuppressed(isTrue),
        ]),
      );

      expect(result['Status'], 'success');
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
      CheckFlakyBuilders.getIgnoreFlakiness('Non_existing', ciYaml);
    });
  });
}
