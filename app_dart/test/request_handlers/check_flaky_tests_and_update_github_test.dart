// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/utilities/mocks.dart';

import 'check_flaky_tests_and_update_github_test_data.dart';

const String kThreshold = '0.02';
const String kCurrentMasterSHA = 'b6156fc8d1c6e992fe4ea0b9128f9aef10443bdb';
const String kCurrentUserName = 'Name';
const String kCurrentUserLogin = 'login';
const String kCurrentUserEmail = 'login@email.com';

void main() {
  group('Check flaky', () {
    CheckForFlakyTestAndUpdateGithub handler;
    ApiRequestHandlerTester tester;
    FakeHttpRequest request;
    FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticationProvider auth;
    MockBigqueryService mockBigqueryService;
    MockGitHub mockGitHubClient;
    MockRepositoriesService mockRepositoriesService;
    MockPullRequestsService mockPullRequestsService;
    MockIssuesService mockIssuesService;
    MockGitService mockGitService;
    MockUsersService mockUsersService;

    setUp(() {
      request = FakeHttpRequest(
        queryParametersValue: <String, dynamic>{
          CheckForFlakyTestAndUpdateGithub.kThresholdKey: kThreshold,
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
      when(mockRepositoriesService.getContents(captureAny, CheckForFlakyTestAndUpdateGithub.kCiYamlPath))
          .thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
            RepositoryContents(file: GitHubFile(content: gitHubEncode(ciYamlContent))));
      });
      // when gets the content of TESTOWNERS
      when(mockRepositoriesService.getContents(captureAny, CheckForFlakyTestAndUpdateGithub.kTestOwnerPath))
          .thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
            RepositoryContents(file: GitHubFile(content: gitHubEncode(testOwnersContent))));
      });
      // when gets existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return const Stream<Issue>.empty();
      });
      // when gets existing marks flaky prs.
      when(mockPullRequestsService.list(captureAny)).thenAnswer((Invocation invocation) {
        return const Stream<PullRequest>.empty();
      });
      // when gets the current head of master branch
      when(mockGitService.getReference(captureAny, CheckForFlakyTestAndUpdateGithub.kMasterRefs))
          .thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(
            ref: 'refs/${CheckForFlakyTestAndUpdateGithub.kMasterRefs}',
            object: GitObject('', kCurrentMasterSHA, '')
          ),
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

      handler = CheckForFlakyTestAndUpdateGithub(
        config,
        auth,
      );
    });

    test('Can file issue and pr', () async {
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(CheckForFlakyTestAndUpdateGithub.kBigQueryProjectId))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(semanticsIntegrationTestResponse);
      });
      // When creates issue
      when(mockIssuesService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(Issue(htmlUrl: expectedSemanticsIntegrationTestNewIssueURL));
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
        return Future<GitReference>.value(GitReference(ref: invocation.positionalArguments[1] as String));
      });
      // When creates pr to mark test flaky
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<PullRequest>.value(PullRequest(number: expectedSemanticsIntegrationTestPRNumber));
      });
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize())
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify issue is created correctly.
      List<dynamic> captured = verify(mockIssuesService.create(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), config.flutterSlug.toString());
      expect(captured[1], isA<IssueRequest>());
      final IssueRequest issueRequest = captured[1] as IssueRequest;
      expect(issueRequest.title, expectedSemanticsIntegrationTestResponseTitle);
      expect(issueRequest.body, expectedSemanticsIntegrationTestResponseBody);
      expect(issueRequest.assignee, expectedSemanticsIntegrationTestResponseAssignee);
      expect(const ListEquality<String>().equals(issueRequest.labels, expectedSemanticsIntegrationTestResponseLabels),
          isTrue);

      // Verify tree is created correctly.
      captured = verify(mockGitService.createTree(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[1], isA<CreateGitTree>());
      final CreateGitTree tree = captured[1] as CreateGitTree;
      expect(tree.baseTree, kCurrentMasterSHA);
      expect(tree.entries.length, 1);
      expect(tree.entries[0].content, expectedSemanticsIntegrationTestCiYamlContent);
      expect(tree.entries[0].path, CheckForFlakyTestAndUpdateGithub.kCiYamlPath);
      expect(tree.entries[0].mode, CheckForFlakyTestAndUpdateGithub.kModifyMode);
      expect(tree.entries[0].type, CheckForFlakyTestAndUpdateGithub.kModifyType);

      // Verify commit is created correctly.
      captured = verify(mockGitService.createCommit(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[1], isA<CreateGitCommit>());
      final CreateGitCommit commit = captured[1] as CreateGitCommit;
      expect(commit.message, expectedSemanticsIntegrationTestPullRequestTitle);
      expect(commit.author.name, kCurrentUserName);
      expect(commit.author.email, kCurrentUserEmail);
      expect(commit.committer.name, kCurrentUserName);
      expect(commit.committer.email, kCurrentUserEmail);
      expect(commit.tree, expectedSemanticsIntegrationTestTreeSha);
      expect(commit.parents.length, 1);
      expect(commit.parents[0], kCurrentMasterSHA);

      // Verify reference is created correctly.
      captured = verify(mockGitService.createReference(captureAny, captureAny, captureAny)).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[2], expectedSemanticsIntegrationTestTreeSha);
      final String ref = captured[1] as String;

      // Verify pr is created correctly.
      captured = verify(mockPullRequestsService.create(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), config.flutterSlug.toString());
      expect(captured[1], isA<CreatePullRequest>());
      final CreatePullRequest pr = captured[1] as CreatePullRequest;
      expect(pr.title, expectedSemanticsIntegrationTestPullRequestTitle);
      expect(pr.body, expectedSemanticsIntegrationTestPullRequestBody);
      expect(pr.head, '$kCurrentUserLogin:$ref');
      expect(pr.base, 'refs/${CheckForFlakyTestAndUpdateGithub.kMasterRefs}');

      expect(result['Statuses'], 'success');
    });

    test('Do not create issue if there is already one', () async {
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(CheckForFlakyTestAndUpdateGithub.kBigQueryProjectId))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(semanticsIntegrationTestResponse);
      });
      // when gets existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[Issue(title: expectedSemanticsIntegrationTestResponseTitle)]);
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
        return Future<GitReference>.value(GitReference(ref: invocation.positionalArguments[1] as String));
      });
      // When creates pr to mark test flaky
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<PullRequest>.value(PullRequest(number: expectedSemanticsIntegrationTestPRNumber));
      });
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize())
          .transform(json.decoder)
          .single as Map<String, dynamic>;
      // Verify no issue is created.
      verifyNever(mockIssuesService.create(captureAny, captureAny));
      expect(result['Statuses'], 'success');
    });

    test('Do not create issue if there is a recently closed one', () async {
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(CheckForFlakyTestAndUpdateGithub.kBigQueryProjectId))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(semanticsIntegrationTestResponse);
      });
      // when get existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[
          Issue(
            title: expectedSemanticsIntegrationTestResponseTitle,
            state: 'closed',
            closedAt: DateTime.now()
                .subtract(const Duration(days: CheckForFlakyTestAndUpdateGithub.kGracePeriodForClosedFlake - 1)),
          )
        ]);
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
        return Future<GitReference>.value(GitReference(ref: invocation.positionalArguments[1] as String));
      });
      // When creates pr to mark test flaky
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<PullRequest>.value(PullRequest(number: expectedSemanticsIntegrationTestPRNumber));
      });
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize())
          .transform(json.decoder)
          .single as Map<String, dynamic>;
      // Verify no issue is created.
      verifyNever(mockIssuesService.create(captureAny, captureAny));
      expect(result['Statuses'], 'success');
    });

    test('Do create issue if there is a closed one outside the grace period', () async {
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(CheckForFlakyTestAndUpdateGithub.kBigQueryProjectId))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(semanticsIntegrationTestResponse);
      });
      // when get existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[
          Issue(
            title: expectedSemanticsIntegrationTestResponseTitle,
            state: 'closed',
            closedAt: DateTime.now()
                .subtract(const Duration(days: CheckForFlakyTestAndUpdateGithub.kGracePeriodForClosedFlake + 1)),
          )
        ]);
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
        return Future<GitReference>.value(GitReference(ref: invocation.positionalArguments[1] as String));
      });
      // When creates pr to mark test flaky
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<PullRequest>.value(PullRequest(number: expectedSemanticsIntegrationTestPRNumber));
      });
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize())
          .transform(json.decoder)
          .single as Map<String, dynamic>;
      // Verify issue is created correctly.
      final List<dynamic> captured = verify(mockIssuesService.create(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), config.flutterSlug.toString());
      expect(captured[1], isA<IssueRequest>());
      final IssueRequest issueRequest = captured[1] as IssueRequest;
      expect(issueRequest.title, expectedSemanticsIntegrationTestResponseTitle);
      expect(issueRequest.body, expectedSemanticsIntegrationTestResponseBody);
      expect(issueRequest.assignee, expectedSemanticsIntegrationTestResponseAssignee);
      expect(const ListEquality<String>().equals(issueRequest.labels, expectedSemanticsIntegrationTestResponseLabels),
          isTrue);

      expect(result['Statuses'], 'success');
    });

    test('Do not create PR if the test is already flaky', () async {
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(CheckForFlakyTestAndUpdateGithub.kBigQueryProjectId))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(semanticsIntegrationTestResponse);
      });
      // when gets the content of .ci.yaml
      when(mockRepositoriesService.getContents(captureAny, CheckForFlakyTestAndUpdateGithub.kCiYamlPath))
          .thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
            RepositoryContents(file: GitHubFile(content: gitHubEncode(ciYamlContentAlreadyFlaky))));
      });

      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize())
          .transform(json.decoder)
          .single as Map<String, dynamic>;
      // Verify no pr is created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      expect(result['Statuses'], 'success');
    });

    test('Do not create PR if there is already an opened one', () async {
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(CheckForFlakyTestAndUpdateGithub.kBigQueryProjectId))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(semanticsIntegrationTestResponse);
      });
      // when gets existing marks flaky prs.
      when(mockPullRequestsService.list(captureAny)).thenAnswer((Invocation invocation) {
        return Stream<PullRequest>.fromIterable(<PullRequest>[
          PullRequest(
            title: expectedSemanticsIntegrationTestPullRequestTitle,
            state: 'open',
          )
        ]);
      });

      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize())
          .transform(json.decoder)
          .single as Map<String, dynamic>;
      // Verify no pr is created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      expect(result['Statuses'], 'success');
    });
  });
}
