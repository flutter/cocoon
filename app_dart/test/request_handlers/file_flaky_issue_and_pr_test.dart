// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_service/ci_yaml.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/proto/internal/scheduler.pb.dart'
    as pb;
import 'package:cocoon_service/src/request_handlers/flaky_handler_utils.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/utilities/mocks.dart';
import 'file_flaky_issue_and_pr_test_data.dart';

const String kThreshold = '0.02';
const String kCurrentMasterSHA = 'b6156fc8d1c6e992fe4ea0b9128f9aef10443bdb';
const String kCurrentUserName = 'Name';
const String kCurrentUserLogin = 'login';
const String kCurrentUserEmail = 'login@email.com';

void main() {
  group('Check flaky', () {
    late FileFlakyIssueAndPR handler;
    late ApiRequestHandlerTester tester;
    late FakeHttpRequest request;
    late FakeConfig config;
    late FakeClientContext clientContext;
    late FakeAuthenticationProvider auth;
    late MockBigqueryService mockBigqueryService;
    late MockGitHub mockGitHubClient;
    late MockRepositoriesService mockRepositoriesService;
    late MockPullRequestsService mockPullRequestsService;
    late MockIssuesService mockIssuesService;
    late MockGitService mockGitService;
    late MockUsersService mockUsersService;

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
        mockRepositoriesService.getContents(captureAny, kTestOwnerPath),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
          RepositoryContents(
            file: GitHubFile(content: gitHubEncode(testOwnersContent)),
          ),
        );
      });
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
        githubClient: mockGitHubClient,
      );
      tester = ApiRequestHandlerTester(request: request);

      handler = FileFlakyIssueAndPR(
        config: config,
        authenticationProvider: auth,
      );
    });

    test('Can file issue and pr for devicelab test', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
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
      // Add issue labels
      when(
        mockIssuesService.addLabelsToIssue(captureAny, captureAny, captureAny),
      ).thenAnswer((_) {
        return Future<List<IssueLabel>>.value(<IssueLabel>[]);
      });
      // When creates git tree
      when(mockGitService.createTree(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitTree>.value(
          GitTree(
            expectedSemanticsIntegrationTestTreeSha,
            '',
            false,
            <GitTreeEntry>[],
          ),
        );
      });
      // When creates git commit
      when(mockGitService.createCommit(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitCommit>.value(
          GitCommit(sha: expectedSemanticsIntegrationTestTreeSha),
        );
      });
      // When creates git reference
      when(
        mockGitService.createReference(captureAny, captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(ref: invocation.positionalArguments[1] as String?),
        );
      });
      // When creates pr to mark test flaky
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((
        _,
      ) {
        return Future<PullRequest>.value(
          PullRequest(number: expectedSemanticsIntegrationTestPRNumber),
        );
      });
      final result =
          await utf8.decoder
                  .bind(
                    (await tester.get<Body>(handler)).serialize()
                        as Stream<List<int>>,
                  )
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;

      // Verify issue is created correctly.
      var captured =
          verify(mockIssuesService.create(captureAny, captureAny)).captured;
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

      // Verify issue label is added correctly.
      captured =
          verify(
            mockIssuesService.addLabelsToIssue(
              captureAny,
              captureAny,
              captureAny,
            ),
          ).captured;
      expect(captured.length, 3);
      expect(captured[2], ['team-framework']);

      // Verify tree is created correctly.
      captured =
          verify(mockGitService.createTree(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[1], isA<CreateGitTree>());
      final tree = captured[1] as CreateGitTree;
      expect(tree.baseTree, kCurrentMasterSHA);
      expect(tree.entries!.length, 1);
      expect(
        tree.entries![0].content,
        expectedSemanticsIntegrationTestCiYamlContent,
      );
      expect(tree.entries![0].path, kCiYamlPath);
      expect(tree.entries![0].mode, kModifyMode);
      expect(tree.entries![0].type, kModifyType);

      // Verify commit is created correctly.
      captured =
          verify(mockGitService.createCommit(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[1], isA<CreateGitCommit>());
      final commit = captured[1] as CreateGitCommit;
      expect(commit.message, expectedSemanticsIntegrationTestPullRequestTitle);
      expect(commit.author!.name, kCurrentUserName);
      expect(commit.author!.email, kCurrentUserEmail);
      expect(commit.committer!.name, kCurrentUserName);
      expect(commit.committer!.email, kCurrentUserEmail);
      expect(commit.tree, expectedSemanticsIntegrationTestTreeSha);
      expect(commit.parents!.length, 1);
      expect(commit.parents![0], kCurrentMasterSHA);

      // Verify reference is created correctly.
      captured =
          verify(
            mockGitService.createReference(captureAny, captureAny, captureAny),
          ).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), '$kCurrentUserLogin/flutter');
      expect(captured[2], expectedSemanticsIntegrationTestTreeSha);
      final ref = captured[1] as String?;

      // Verify pr is created correctly.
      captured =
          verify(
            mockPullRequestsService.create(captureAny, captureAny),
          ).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], isA<CreatePullRequest>());
      final pr = captured[1] as CreatePullRequest;
      expect(pr.title, expectedSemanticsIntegrationTestPullRequestTitle);
      expect(pr.body, expectedSemanticsIntegrationTestPullRequestBody);
      expect(pr.head, '$kCurrentUserLogin:$ref');
      expect(pr.base, 'refs/$kMasterRefs');

      expect(result['Status'], 'success');
    });

    test('File mulitple issues and prs', () async {
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
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
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
      // Add issue labels
      when(
        mockIssuesService.addLabelsToIssue(captureAny, captureAny, captureAny),
      ).thenAnswer((_) {
        return Future<List<IssueLabel>>.value(<IssueLabel>[]);
      });
      // When creates git tree
      when(mockGitService.createTree(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitTree>.value(
          GitTree(
            expectedSemanticsIntegrationTestTreeSha,
            '',
            false,
            <GitTreeEntry>[],
          ),
        );
      });
      // When creates git commit
      when(mockGitService.createCommit(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitCommit>.value(
          GitCommit(sha: expectedSemanticsIntegrationTestTreeSha),
        );
      });
      // When creates git reference
      when(
        mockGitService.createReference(captureAny, captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(ref: invocation.positionalArguments[1] as String?),
        );
      });
      // When creates pr to mark test flaky
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((
        _,
      ) {
        return Future<PullRequest>.value(
          PullRequest(number: expectedSemanticsIntegrationTestPRNumber),
        );
      });
      final result =
          await utf8.decoder
                  .bind(
                    (await tester.get<Body>(handler)).serialize()
                        as Stream<List<int>>,
                  )
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;
      expect(result['Status'], 'success');
      expect(result['NumberOfCreatedIssuesAndPRs'], 2);
    });

    test('File issues and prs up to issueAndPRLimit', () async {
      // when gets the content of .ci.yaml
      config = FakeConfig(
        githubService: GithubService(mockGitHubClient),
        bigqueryService: mockBigqueryService,
        githubClient: mockGitHubClient,
        issueAndPRLimitValue: 1,
      );
      handler = FileFlakyIssueAndPR(
        config: config,
        authenticationProvider: auth,
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
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
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
      // Add issue labels
      when(
        mockIssuesService.addLabelsToIssue(captureAny, captureAny, captureAny),
      ).thenAnswer((_) {
        return Future<List<IssueLabel>>.value(<IssueLabel>[]);
      });
      // When creates git tree
      when(mockGitService.createTree(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitTree>.value(
          GitTree(
            expectedSemanticsIntegrationTestTreeSha,
            '',
            false,
            <GitTreeEntry>[],
          ),
        );
      });
      // When creates git commit
      when(mockGitService.createCommit(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitCommit>.value(
          GitCommit(sha: expectedSemanticsIntegrationTestTreeSha),
        );
      });
      // When creates git reference
      when(
        mockGitService.createReference(captureAny, captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(ref: invocation.positionalArguments[1] as String?),
        );
      });
      // When creates pr to mark test flaky
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((
        _,
      ) {
        return Future<PullRequest>.value(
          PullRequest(number: expectedSemanticsIntegrationTestPRNumber),
        );
      });
      final result =
          await utf8.decoder
                  .bind(
                    (await tester.get<Body>(handler)).serialize()
                        as Stream<List<int>>,
                  )
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;
      expect(result['Status'], 'success');
      expect(result['NumberOfCreatedIssuesAndPRs'], 1);
    });

    test('Can file issue and pr for framework host-only test', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(analyzeTestResponse);
      });
      // When creates issue
      when(mockIssuesService.create(captureAny, captureAny)).thenAnswer((_) {
        return Future<Issue>.value(
          Issue(htmlUrl: expectedSemanticsIntegrationTestNewIssueURL),
        );
      });
      // Add issue labels
      when(
        mockIssuesService.addLabelsToIssue(captureAny, captureAny, captureAny),
      ).thenAnswer((_) {
        return Future<List<IssueLabel>>.value(<IssueLabel>[]);
      });
      // When creates git tree
      when(mockGitService.createTree(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitTree>.value(
          GitTree(
            expectedSemanticsIntegrationTestTreeSha,
            '',
            false,
            <GitTreeEntry>[],
          ),
        );
      });
      // When creates git commit
      when(mockGitService.createCommit(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitCommit>.value(
          GitCommit(sha: expectedSemanticsIntegrationTestTreeSha),
        );
      });
      // When creates git reference
      when(
        mockGitService.createReference(captureAny, captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(ref: invocation.positionalArguments[1] as String?),
        );
      });
      // When creates pr to mark test flaky
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((
        _,
      ) {
        return Future<PullRequest>.value(
          PullRequest(number: expectedSemanticsIntegrationTestPRNumber),
        );
      });
      final result =
          await utf8.decoder
                  .bind(
                    (await tester.get<Body>(handler)).serialize()
                        as Stream<List<int>>,
                  )
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;

      // Verify issue is created correctly.
      var captured =
          verify(mockIssuesService.create(captureAny, captureAny)).captured;
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

      // Verify pr is created correctly.
      captured =
          verify(
            mockPullRequestsService.create(captureAny, captureAny),
          ).captured;
      expect(captured.length, 2);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], isA<CreatePullRequest>());

      expect(result['Status'], 'success');
    });

    test(
      'Can file issue when limited number of successfuly builds exist',
      () async {
        // When queries flaky data from BigQuery.
        when(
          mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
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
        // Add issue labels
        when(
          mockIssuesService.addLabelsToIssue(
            captureAny,
            captureAny,
            captureAny,
          ),
        ).thenAnswer((_) {
          return Future<List<IssueLabel>>.value(<IssueLabel>[]);
        });
        // When creates git tree
        when(mockGitService.createTree(captureAny, captureAny)).thenAnswer((_) {
          return Future<GitTree>.value(
            GitTree(
              expectedSemanticsIntegrationTestTreeSha,
              '',
              false,
              <GitTreeEntry>[],
            ),
          );
        });
        // When creates git commit
        when(mockGitService.createCommit(captureAny, captureAny)).thenAnswer((
          _,
        ) {
          return Future<GitCommit>.value(
            GitCommit(sha: expectedSemanticsIntegrationTestTreeSha),
          );
        });
        // When creates git reference
        when(
          mockGitService.createReference(captureAny, captureAny, captureAny),
        ).thenAnswer((Invocation invocation) {
          return Future<GitReference>.value(
            GitReference(ref: invocation.positionalArguments[1] as String?),
          );
        });
        // When creates pr to mark test flaky
        when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer(
          (_) {
            return Future<PullRequest>.value(
              PullRequest(number: expectedSemanticsIntegrationTestPRNumber),
            );
          },
        );
        final result =
            await utf8.decoder
                    .bind(
                      (await tester.get<Body>(handler)).serialize()
                          as Stream<List<int>>,
                    )
                    .transform(json.decoder)
                    .single
                as Map<String, dynamic>;

        // Verify issue is created correctly.
        final captured =
            verify(mockIssuesService.create(captureAny, captureAny)).captured;
        expect(captured.length, 2);
        expect(captured[0].toString(), Config.flutterSlug.toString());
        expect(captured[1], isA<IssueRequest>());
        final issueRequest = captured[1] as IssueRequest;
        expect(issueRequest.body, expectedLimitedNumberOfBuildsResponseBody);

        expect(result['Status'], 'success');
      },
    );

    test('Can file issue but not pr for shard test', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
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
                  .bind(
                    (await tester.get<Body>(handler)).serialize()
                        as Stream<List<int>>,
                  )
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;

      // Verify issue is created correctly.
      final captured =
          verify(mockIssuesService.create(captureAny, captureAny)).captured;
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
      // Verify no pr is created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      expect(result['Status'], 'success');
    });

    test('Do not create issue if there is already one', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
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
      // When creates git tree
      when(mockGitService.createTree(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitTree>.value(
          GitTree(
            expectedSemanticsIntegrationTestTreeSha,
            '',
            false,
            <GitTreeEntry>[],
          ),
        );
      });
      // When creates git commit
      when(mockGitService.createCommit(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitCommit>.value(
          GitCommit(sha: expectedSemanticsIntegrationTestTreeSha),
        );
      });
      // When creates git reference
      when(
        mockGitService.createReference(captureAny, captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(ref: invocation.positionalArguments[1] as String?),
        );
      });
      // When creates pr to mark test flaky
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((
        _,
      ) {
        return Future<PullRequest>.value(
          PullRequest(number: expectedSemanticsIntegrationTestPRNumber),
        );
      });
      final result =
          await utf8.decoder
                  .bind(
                    (await tester.get<Body>(handler)).serialize()
                        as Stream<List<int>>,
                  )
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;
      // Verify no issue is created.
      verifyNever(mockIssuesService.create(captureAny, captureAny));
      // Verify no pr is created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));
      expect(result['Status'], 'success');
    });

    test('Do not create issue if there is a recently closed one', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
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
      // When creates git tree
      when(mockGitService.createTree(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitTree>.value(
          GitTree(
            expectedSemanticsIntegrationTestTreeSha,
            '',
            false,
            <GitTreeEntry>[],
          ),
        );
      });
      // When creates git commit
      when(mockGitService.createCommit(captureAny, captureAny)).thenAnswer((_) {
        return Future<GitCommit>.value(
          GitCommit(sha: expectedSemanticsIntegrationTestTreeSha),
        );
      });
      // When creates git reference
      when(
        mockGitService.createReference(captureAny, captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(ref: invocation.positionalArguments[1] as String?),
        );
      });
      // When creates pr to mark test flaky
      when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer((
        _,
      ) {
        return Future<PullRequest>.value(
          PullRequest(number: expectedSemanticsIntegrationTestPRNumber),
        );
      });
      final result =
          await utf8.decoder
                  .bind(
                    (await tester.get<Body>(handler)).serialize()
                        as Stream<List<int>>,
                  )
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;
      // Verify no issue is created.
      verifyNever(mockIssuesService.create(captureAny, captureAny));
      // Verify no pr is created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));
      expect(result['Status'], 'success');
    });

    test(
      'Do create issue if there is a closed one outside the grace period',
      () async {
        // When queries flaky data from BigQuery.
        when(
          mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
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
        // When creates git tree
        when(mockGitService.createTree(captureAny, captureAny)).thenAnswer((_) {
          return Future<GitTree>.value(
            GitTree(
              expectedSemanticsIntegrationTestTreeSha,
              '',
              false,
              <GitTreeEntry>[],
            ),
          );
        });
        // Add issue labels
        when(
          mockIssuesService.addLabelsToIssue(
            captureAny,
            captureAny,
            captureAny,
          ),
        ).thenAnswer((_) {
          return Future<List<IssueLabel>>.value(<IssueLabel>[]);
        });
        // When creates git commit
        when(mockGitService.createCommit(captureAny, captureAny)).thenAnswer((
          _,
        ) {
          return Future<GitCommit>.value(
            GitCommit(sha: expectedSemanticsIntegrationTestTreeSha),
          );
        });
        // When creates git reference
        when(
          mockGitService.createReference(captureAny, captureAny, captureAny),
        ).thenAnswer((Invocation invocation) {
          return Future<GitReference>.value(
            GitReference(ref: invocation.positionalArguments[1] as String?),
          );
        });
        // When creates pr to mark test flaky
        when(mockPullRequestsService.create(captureAny, captureAny)).thenAnswer(
          (_) {
            return Future<PullRequest>.value(
              PullRequest(number: expectedSemanticsIntegrationTestPRNumber),
            );
          },
        );
        final result =
            await utf8.decoder
                    .bind(
                      (await tester.get<Body>(handler)).serialize()
                          as Stream<List<int>>,
                    )
                    .transform(json.decoder)
                    .single
                as Map<String, dynamic>;
        // Verify issue is created correctly.
        final captured =
            verify(mockIssuesService.create(captureAny, captureAny)).captured;
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

        expect(result['Status'], 'success');
      },
    );

    test('Do not create an issue or PR if the test is already flaky', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponse,
        );
      });
      // when gets the content of .ci.yaml
      when(
        mockRepositoriesService.getContents(captureAny, kCiYamlPath),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
          RepositoryContents(
            file: GitHubFile(content: gitHubEncode(ciYamlContentAlreadyFlaky)),
          ),
        );
      });

      final result =
          await utf8.decoder
                  .bind(
                    (await tester.get<Body>(handler)).serialize()
                        as Stream<List<int>>,
                  )
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;
      // Verify no issue is created.
      verifyNever(mockIssuesService.create(captureAny, captureAny));
      // Verify no pr is created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      expect(result['Status'], 'success');
    });

    test('Do not create PR if there is already an opened one', () async {
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponse,
        );
      });
      // when gets existing marks flaky prs.
      when(mockPullRequestsService.list(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return Stream<PullRequest>.fromIterable(<PullRequest>[
          PullRequest(
            title: expectedSemanticsIntegrationTestPullRequestTitle,
            body: expectedSemanticsIntegrationTestPullRequestBody,
            state: 'open',
          ),
        ]);
      });

      final result =
          await utf8.decoder
                  .bind(
                    (await tester.get<Body>(handler)).serialize()
                        as Stream<List<int>>,
                  )
                  .transform(json.decoder)
                  .single
              as Map<String, dynamic>;
      // Verify no pr is created.
      verifyNever(mockPullRequestsService.create(captureAny, captureAny));

      expect(result['Status'], 'success');
    });

    test('skips when the target doesn not exist', () {
      final ci = loadYaml(ciYamlContent) as YamlMap?;
      final unCheckedSchedulerConfig =
          pb.SchedulerConfig()..mergeFromProto3Json(ci);
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
      expect(handler.shouldSkip(builderStatistic, ciYaml, targets), true);
    });

    test('skips if the flakiness_threshold is not met', () {
      final ci = loadYaml(ciYamlContent) as YamlMap?;
      final unCheckedSchedulerConfig =
          pb.SchedulerConfig()..mergeFromProto3Json(ci);
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
        handler.shouldSkip(builderStatistic, ciYaml, targets),
        true,
        reason: 'test specific flakiness_threshold overrides global threshold',
      );
    });

    test('honors the flakiness_threshold', () {
      final ci = loadYaml(ciYamlContent) as YamlMap?;
      final unCheckedSchedulerConfig =
          pb.SchedulerConfig()..mergeFromProto3Json(ci);
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
        handler.shouldSkip(builderStatistic, ciYaml, targets),
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
    final unCheckedSchedulerConfig =
        pb.SchedulerConfig()..mergeFromProto3Json(ci);
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
