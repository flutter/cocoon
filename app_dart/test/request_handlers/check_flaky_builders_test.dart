// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/ci_yaml.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handlers/flaky_handler_utils.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:cocoon_service/src/model/proto/internal/scheduler.pb.dart' as pb;

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/utilities/mocks.dart';

import 'check_flaky_builders_test_data.dart';

const String kThreshold = '0.02';
const String kCurrentMasterSHA = 'b6156fc8d1c6e992fe4ea0b9128f9aef10443bdb';
const String kCurrentUserName = 'Name';
const String kCurrentUserLogin = 'login';
const String kCurrentUserEmail = 'login@email.com';

class MockYaml extends Mock implements CiYaml {}

void main() {
  group('Deflake', () {
    late CheckFlakyBuilders handler;
    late ApiRequestHandlerTester tester;
    FakeHttpRequest request;
    late FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticationProvider auth;
    late MockBigqueryService mockBigqueryService;
    MockGitHub mockGitHubClient;
    late MockRepositoriesService mockRepositoriesService;
    late MockPullRequestsService mockPullRequestsService;
    late MockIssuesService mockIssuesService;
    late MockGitService mockGitService;
    MockUsersService mockUsersService;

    setUp(() {
      request = FakeHttpRequest(
        queryParametersValue: <String, dynamic>{
          FileFlakyIssueAndPR.kThresholdKey: kThreshold,
        },
      );

      clientContext = FakeClientContext();
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      mockBigqueryService = MockBigqueryService();
      mockGitHubClient = MockGitHub();
      mockRepositoriesService = MockRepositoriesService();
      mockIssuesService = MockIssuesService();
      mockPullRequestsService = MockPullRequestsService();
      mockGitService = MockGitService();
      mockUsersService = MockUsersService();
      // when gets the content of .ci.yaml
      when(
        mockRepositoriesService.getContents(
          captureAny,
          kCiYamlPath,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
          RepositoryContents(file: GitHubFile(content: gitHubEncode(ciYamlContent))),
        );
      });
      // when gets the content of TESTOWNERS
      when(
        mockRepositoriesService.getContents(
          captureAny,
          kTestOwnerPath,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
          RepositoryContents(file: GitHubFile(content: gitHubEncode(testOwnersContent))),
        );
      });
      // when gets existing marks flaky prs.
      when(mockPullRequestsService.list(captureAny)).thenAnswer((Invocation invocation) {
        return const Stream<PullRequest>.empty();
      });
      // when gets the current head of master branch
      when(mockGitService.getReference(captureAny, kMasterRefs)).thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(ref: 'refs/$kMasterRefs', object: GitObject('', kCurrentMasterSHA, '')),
        );
      });
      // when gets the current user.
      when(mockUsersService.getCurrentUser()).thenAnswer((Invocation invocation) {
        final CurrentUser result = CurrentUser();
        result.email = kCurrentUserEmail;
        result.name = kCurrentUserName;
        result.login = kCurrentUserLogin;
        return Future<CurrentUser>.value(result);
      });
      // when assigns pull request reviewer.
      when(
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
        bigqueryService: mockBigqueryService,
      );
      tester = ApiRequestHandlerTester(request: request);

      handler = CheckFlakyBuilders(
        config: config,
        authenticationProvider: auth,
      );
    });

    test('Can create pr if the flaky test is no longer flaky with a closed issue', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listRecentBuildRecordsForBuilder(
          kBigQueryProjectId,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderRecord>>.value(semanticsIntegrationTestRecordsAllPassed);
      });
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingSemanticsIntegrationTestResponse);
      });
      // When get issue
      when(mockIssuesService.get(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(Issue(state: 'CLOSED', htmlUrl: existingIssueURL));
      });
      // When creates git tree
      when(mockGitService.createTree(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitTree>.value(GitTree(expectedSemanticsIntegrationTestTreeSha, '', false, <GitTreeEntry>[]));
      });
      // When creates git commit
      when(mockGitService.createCommit(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitCommit>.value(GitCommit(sha: expectedSemanticsIntegrationTestTreeSha));
      });
      // When creates git reference
      when(mockGitService.createReference(captureAny, captureAny, captureAny)).thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(GitReference(ref: invocation.positionalArguments[1] as String?));
      });
      // When creates pr to deflake test
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<PullRequest>.value(PullRequest(number: expectedSemanticsIntegrationTestPRNumber));
      });

      CheckFlakyBuilders.kRecordNumber = semanticsIntegrationTestRecordsAllPassed.length;
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify BigQuery is called correctly.
      List<dynamic> captured = verify(
        mockBigqueryService.listRecentBuildRecordsForBuilder(
          captureAny,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), kBigQueryProjectId);
      expect(captured[1] as String?, expectedSemanticsIntegrationTestBuilderName);
      expect(captured[2] as int?, CheckFlakyBuilders.kRecordNumber);

      // Verify it gets the correct issue.
      captured = verify(mockIssuesService.get(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0], Config.flutterSlug);
      expect(captured[1] as int?, existingIssueNumber);

      // Verify tree is created correctly.
      captured = verify(mockGitService.createTree(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[1], isA<CreateGitTree>());
      final CreateGitTree tree = captured[1] as CreateGitTree;
      expect(tree.baseTree, kCurrentMasterSHA);
      expect(tree.entries!.length, 1);
      expect(tree.entries![0].content, expectedSemanticsIntegrationTestCiYamlContent);
      expect(tree.entries![0].path, kCiYamlPath);
      expect(tree.entries![0].mode, kModifyMode);
      expect(tree.entries![0].type, kModifyType);

      // Verify commit is created correctly.
      captured = verify(mockGitService.createCommit(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[1], isA<CreateGitCommit>());
      final CreateGitCommit commit = captured[1] as CreateGitCommit;
      expect(commit.message, expectedSemanticsIntegrationTestPullRequestTitle);
      expect(commit.author!.name, kCurrentUserName);
      expect(commit.author!.email, kCurrentUserEmail);
      expect(commit.committer!.name, kCurrentUserName);
      expect(commit.committer!.email, kCurrentUserEmail);
      expect(commit.tree, expectedSemanticsIntegrationTestTreeSha);
      expect(commit.parents!.length, 1);
      expect(commit.parents![0], kCurrentMasterSHA);

      // Verify reference is created correctly.
      captured = verify(mockGitService.createReference(captureAny, captureAny, captureAny)).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[2], expectedSemanticsIntegrationTestTreeSha);
      final String? ref = captured[1] as String?;

      // Verify pr is created correctly.
      captured = verify(mockPullRequestsService.create(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], isA<CreatePullRequest>());
      final CreatePullRequest pr = captured[1] as CreatePullRequest;
      expect(pr.title, expectedSemanticsIntegrationTestPullRequestTitle);
      expect(pr.body, expectedSemanticsIntegrationTestPullRequestBody);
      expect(pr.head, '$kCurrentUserLogin:$ref');
      expect(pr.base, 'refs/$kMasterRefs');

      expect(result['Status'], 'success');
    });

    test('Can create pr if the flaky test is no longer flaky without an issue', () async {
      // when gets the content of .ci.yaml
      when(
        mockRepositoriesService.getContents(
          captureAny,
          kCiYamlPath,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
          RepositoryContents(file: GitHubFile(content: gitHubEncode(ciYamlContentNoIssue))),
        );
      });
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listRecentBuildRecordsForBuilder(
          kBigQueryProjectId,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderRecord>>.value(semanticsIntegrationTestRecordsAllPassed);
      });
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingSemanticsIntegrationTestResponse);
      });
      // When creates git tree
      when(mockGitService.createTree(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitTree>.value(GitTree(expectedSemanticsIntegrationTestTreeSha, '', false, <GitTreeEntry>[]));
      });
      // When creates git commit
      when(mockGitService.createCommit(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitCommit>.value(GitCommit(sha: expectedSemanticsIntegrationTestTreeSha));
      });
      // When creates git reference
      when(mockGitService.createReference(captureAny, captureAny, captureAny)).thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(GitReference(ref: invocation.positionalArguments[1] as String?));
      });
      // When creates pr to deflake test
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<PullRequest>.value(PullRequest(number: expectedSemanticsIntegrationTestPRNumber));
      });

      CheckFlakyBuilders.kRecordNumber = semanticsIntegrationTestRecordsAllPassed.length;
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify BigQuery is called correctly.
      List<dynamic> captured = verify(
        mockBigqueryService.listRecentBuildRecordsForBuilder(
          captureAny,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), kBigQueryProjectId);
      expect(captured[1] as String?, expectedSemanticsIntegrationTestBuilderName);
      expect(captured[2] as int?, CheckFlakyBuilders.kRecordNumber);

      // Verify it does not get issue.
      verifyNever(mockIssuesService.get(captureAny, captureAny));

      // Verify tree is created correctly.
      captured = verify(mockGitService.createTree(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[1], isA<CreateGitTree>());
      final CreateGitTree tree = captured[1] as CreateGitTree;
      expect(tree.baseTree, kCurrentMasterSHA);
      expect(tree.entries!.length, 1);
      expect(tree.entries![0].content, expectedSemanticsIntegrationTestCiYamlContent);
      expect(tree.entries![0].path, kCiYamlPath);
      expect(tree.entries![0].mode, kModifyMode);
      expect(tree.entries![0].type, kModifyType);

      // Verify commit is created correctly.
      captured = verify(mockGitService.createCommit(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[1], isA<CreateGitCommit>());
      final CreateGitCommit commit = captured[1] as CreateGitCommit;
      expect(commit.message, expectedSemanticsIntegrationTestPullRequestTitle);
      expect(commit.author!.name, kCurrentUserName);
      expect(commit.author!.email, kCurrentUserEmail);
      expect(commit.committer!.name, kCurrentUserName);
      expect(commit.committer!.email, kCurrentUserEmail);
      expect(commit.tree, expectedSemanticsIntegrationTestTreeSha);
      expect(commit.parents!.length, 1);
      expect(commit.parents![0], kCurrentMasterSHA);

      // Verify reference is created correctly.
      captured = verify(mockGitService.createReference(captureAny, captureAny, captureAny)).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[2], expectedSemanticsIntegrationTestTreeSha);
      final String? ref = captured[1] as String?;

      // Verify pr is created correctly.
      captured = verify(mockPullRequestsService.create(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], isA<CreatePullRequest>());
      final CreatePullRequest pr = captured[1] as CreatePullRequest;
      expect(pr.title, expectedSemanticsIntegrationTestPullRequestTitle);
      expect(pr.body, expectedSemanticsIntegrationTestPullRequestBodyNoIssue);
      expect(pr.head, '$kCurrentUserLogin:$ref');
      expect(pr.base, 'refs/$kMasterRefs');

      expect(result['Status'], 'success');
    });

    test('Do not create PR if the builder is in the ignored list', () async {
      // when gets the content of .ci.yaml
      when(
        mockRepositoriesService.getContents(
          captureAny,
          kCiYamlPath,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
          RepositoryContents(file: GitHubFile(content: gitHubEncode(ciYamlContentFlakyInIgnoreList))),
        );
      });
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingSemanticsIntegrationTestResponse);
      });
      CheckFlakyBuilders.kRecordNumber = semanticsIntegrationTestRecordsAllPassed.length;
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify pr is not called correctly.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny)).captured;

      expect(result['Status'], 'success');
    });

    test('Do not create pr if the issue is still open', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listRecentBuildRecordsForBuilder(
          kBigQueryProjectId,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderRecord>>.value(semanticsIntegrationTestRecordsAllPassed);
      });
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingSemanticsIntegrationTestResponse);
      });
      // When get issue
      when(mockIssuesService.get(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(Issue(state: 'OPEN', htmlUrl: existingIssueURL));
      });
      CheckFlakyBuilders.kRecordNumber = semanticsIntegrationTestRecordsAllPassed.length;
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify it gets the correct issue.
      final List<dynamic> captured = verify(mockIssuesService.get(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0], Config.flutterSlug);
      expect(captured[1] as int?, existingIssueNumber);

      // Verify pr is not created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      expect(result['Status'], 'success');
    });

    test('Do not create pr and do not create issue if the records have flaky runs and there is an open issue',
        () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listRecentBuildRecordsForBuilder(
          kBigQueryProjectId,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderRecord>>.value(semanticsIntegrationTestRecordsFlaky);
      });
      // When get issue
      when(mockIssuesService.get(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(
            state: 'CLOSED',
            htmlUrl: existingIssueURL,
            closedAt: DateTime.now().subtract(const Duration(days: kGracePeriodForClosedFlake - 1)),
          ),
        );
      });
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingSemanticsIntegrationTestResponse);
      });

      CheckFlakyBuilders.kRecordNumber = semanticsIntegrationTestRecordsAllPassed.length + 1;
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify pr is not created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      // Verify issue is created correctly.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      expect(result['Status'], 'success');
    });

    test('Do not create pr and do not create issue if the records have flaky runs and there is a recently closed issue',
        () async {
      // When get issue
      when(mockIssuesService.get(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(
            state: 'OPEN',
            htmlUrl: existingIssueURL,
          ),
        );
      });
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingSemanticsIntegrationTestResponse);
      });

      CheckFlakyBuilders.kRecordNumber = semanticsIntegrationTestRecordsAllPassed.length + 1;
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify pr is not created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      // Verify issue is created correctly.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      expect(result['Status'], 'success');
    });

    test('Do not create pr if the records have failed runs', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listRecentBuildRecordsForBuilder(
          kBigQueryProjectId,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderRecord>>.value(semanticsIntegrationTestRecordsFailed);
      });
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingSemanticsIntegrationTestResponse);
      });
      // When get issue
      when(mockIssuesService.get(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(
            state: 'CLOSED',
            htmlUrl: existingIssueURL,
            closedAt: DateTime.now().subtract(const Duration(days: 50)),
          ),
        );
      });

      CheckFlakyBuilders.kRecordNumber = semanticsIntegrationTestRecordsFailed.length;
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify BigQuery is called correctly.
      List<dynamic> captured = verify(
        mockBigqueryService.listRecentBuildRecordsForBuilder(
          captureAny,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), kBigQueryProjectId);
      expect(captured[1] as String?, expectedSemanticsIntegrationTestBuilderName);
      expect(captured[2] as int?, CheckFlakyBuilders.kRecordNumber);

      // Verify it gets the correct issue.
      captured = verify(mockIssuesService.get(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0], Config.flutterSlug);
      expect(captured[1] as int?, existingIssueNumber);

      // Verify pr is not created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      expect(result['Status'], 'success');
    });

    test('Do not create pr if there is an open one', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listRecentBuildRecordsForBuilder(
          kBigQueryProjectId,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderRecord>>.value(semanticsIntegrationTestRecordsAllPassed);
      });
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingSemanticsIntegrationTestResponse);
      });
      // when gets existing marks flaky prs.
      when(mockPullRequestsService.list(captureAny)).thenAnswer((Invocation invocation) {
        return Stream<PullRequest>.value(PullRequest(body: expectedSemanticsIntegrationTestPullRequestBody));
      });
      // When get issue
      when(mockIssuesService.get(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(Issue(state: 'CLOSED', htmlUrl: existingIssueURL));
      });

      CheckFlakyBuilders.kRecordNumber = semanticsIntegrationTestRecordsAllPassed.length;
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify pr is not created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      expect(result['Status'], 'success');
    });

    test('Do not create pr if not enough records', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listRecentBuildRecordsForBuilder(
          kBigQueryProjectId,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderRecord>>.value(semanticsIntegrationTestRecordsAllPassed);
      });
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingSemanticsIntegrationTestResponse);
      });
      // When get issue
      when(mockIssuesService.get(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(
            state: 'CLOSED',
            htmlUrl: existingIssueURL,
            closedAt: DateTime.now().subtract(const Duration(days: 50)),
          ),
        );
      });

      CheckFlakyBuilders.kRecordNumber = semanticsIntegrationTestRecordsAllPassed.length + 1;
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify BigQuery is called correctly.
      List<dynamic> captured = verify(
        mockBigqueryService.listRecentBuildRecordsForBuilder(
          captureAny,
          builder: captureAnyNamed('builder'),
          limit: captureAnyNamed('limit'),
        ),
      ).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), kBigQueryProjectId);
      expect(captured[1] as String?, expectedSemanticsIntegrationTestBuilderName);
      expect(captured[2] as int?, CheckFlakyBuilders.kRecordNumber);

      // Verify it gets the correct issue.
      captured = verify(mockIssuesService.get(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0], Config.flutterSlug);
      expect(captured[1] as int?, existingIssueNumber);

      // Verify pr is not created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      expect(result['Status'], 'success');
    });

    test('getIgnoreFlakiness handles non-existing builderame', () async {
      final YamlMap? ci = loadYaml(ciYamlContent) as YamlMap?;
      final pb.SchedulerConfig unCheckedSchedulerConfig = pb.SchedulerConfig()..mergeFromProto3Json(ci);
      final CiYaml ciYaml = CiYaml(
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        config: unCheckedSchedulerConfig,
      );
      CheckFlakyBuilders.getIgnoreFlakiness('Non_existing', ciYaml);
    });
  });
}
