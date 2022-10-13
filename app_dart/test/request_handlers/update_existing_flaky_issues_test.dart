// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/proto/protos.dart' as pb;
import 'package:cocoon_service/src/request_handlers/flaky_handler_utils.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/utilities/mocks.dart';

import 'update_existing_flaky_issues_test_data.dart';

const String kThreshold = '0.02';

void main() {
  group('Update flaky', () {
    late UpdateExistingFlakyIssue handler;
    late ApiRequestHandlerTester tester;
    FakeHttpRequest request;
    late FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticationProvider auth;
    late MockBigqueryService mockBigqueryService;
    late MockGitHub mockGitHubClient;
    late MockIssuesService mockIssuesService;
    MockRepositoriesService mockRepositoriesService;

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
      mockIssuesService = MockIssuesService();
      mockRepositoriesService = MockRepositoriesService();

      // when gets existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return const Stream<Issue>.empty();
      });

      // when gets the content of .ci.yaml
      // when(mockRepositoriesService.getContents(
      //   captureAny,
      //   kCiYamlPath,
      // )).thenAnswer((Invocation invocation) {
      //   return Future<RepositoryContents>.value(
      //       RepositoryContents(file: GitHubFile(content: gitHubEncode(ciYamlContent))));
      // });

      final CiYaml testCiYaml = CiYaml(
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        config: pb.SchedulerConfig(
          enabledBranches: <String>[
            Config.defaultBranch(Config.flutterSlug),
          ],
          targets: <pb.Target>[
            pb.Target(
              name: 'Mac_android android_semantics_integration_test',
              scheduler: pb.SchedulerSystem.luci,
              presubmit: false,
              properties: <String, String>{
                'tags': jsonEncode(['devicelab'])
              },
            ),
            pb.Target(
              name: 'Mac_android ignore_myflakiness',
              scheduler: pb.SchedulerSystem.luci,
              presubmit: false,
              properties: <String, String>{
                'ignore_flakiness': 'true',
                'tags': jsonEncode(['devicelab']),
              }
            ),
            pb.Target(
              name: 'Linux ci_yaml flutter roller',
              scheduler: pb.SchedulerSystem.luci,
              bringup: true,
              timeout: 30,
              runIf: ['.ci.yaml'],
              recipe: 'infra/ci_yaml',
              properties: <String, String> {
                'tags': jsonEncode(["framework", "hostonly", "shard"]),
              },

            ),
            pb.Target(
              name: 'Mac build_tests_1_4',
              scheduler: pb.SchedulerSystem.luci,
              recipe: 'flutter/flutter_drone',
              timeout: 60,
              properties: <String, String> {
                'add_recipes_cq': 'true',
                'shard': 'build_tests',
                'subshard': '1_4',
                'tags': jsonEncode(["framework", "hostonly", "shard"]),
                'dependencies': jsonEncode([
                  {
                    'dependency': 'android_sdk', 'version': 'version:29.0',
                  },
                  {
                    'dependency': 'chrome_and_driver', 'version': 'version:84',
                  },
                  {
                    'dependency': 'xcode', 'version': '13a233',
                  },
                  {
                    'dependency': 'open_jdk', 'version': '11',
                  },
                  {
                    'dependency': 'gems', 'version': 'v3.3.14',
                  },
                  {
                    'dependency': 'goldctl', 'version': 'git_revision:3a77d0b12c697a840ca0c7705208e8622dc94603',
                  },
                ]),
              },
            ),
          ],
        ),
      );

      // when gets the content of TESTOWNERS
      when(mockRepositoriesService.getContents(
        captureAny,
        kTestOwnerPath,
      )).thenAnswer((Invocation invocation) {
        return Future<RepositoryContents>.value(
            RepositoryContents(file: GitHubFile(content: gitHubEncode(testOwnersContent))));
      });

      when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);
      when(mockGitHubClient.issues).thenReturn(mockIssuesService);
      when(mockIssuesService.createComment(any, any, any)).thenAnswer((_) async => IssueComment());
      when(mockIssuesService.edit(any, any, any)).thenAnswer((_) async => Issue());
      config = FakeConfig(
        githubService: GithubService(mockGitHubClient),
        bigqueryService: mockBigqueryService,
        githubOAuthTokenValue: 'token',
      );
      tester = ApiRequestHandlerTester(request: request);

      handler = UpdateExistingFlakyIssue(
        config: config,
        authenticationProvider: auth,
        ciYaml: testCiYaml,
      );
    });

    test('Can add existing issue comment', () async {
      const int existingIssueNumber = 1234;
      final List<IssueLabel> existingLabels = <IssueLabel>[
        IssueLabel(name: 'some random label'),
        IssueLabel(name: 'P2'),
      ];
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId)).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(semanticsIntegrationTestResponse);
      });
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingCiyamlTestResponse);
      });
      // when gets existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[
          Issue(
            assignee: User(login: 'some dude'),
            number: existingIssueNumber,
            state: 'open',
            labels: existingLabels,
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
            createdAt:
                DateTime.now().subtract(const Duration(days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake + 1)),
          )
        ]);
      });
      // when firing github request.
      // This is for replacing labels.
      when(mockGitHubClient.request(
        captureAny,
        captureAny,
        body: captureAnyNamed('body'),
      )).thenAnswer((Invocation invocation) {
        return Future<Response>.value(Response('[]', 200));
      });
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify comment is created correctly.
      List<dynamic> captured = verify(mockIssuesService.createComment(captureAny, captureAny, captureAny)).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], existingIssueNumber);
      expect(captured[2], expectedSemanticsIntegrationTestIssueComment);

      // Verify labels are applied correctly.
      captured = verify(mockGitHubClient.request(
        captureAny,
        captureAny,
        body: captureAnyNamed('body'),
      )).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), 'PUT');
      expect(captured[1], '/repos/${Config.flutterSlug.fullName}/issues/$existingIssueNumber/labels');
      expect(captured[2], GitHubJson.encode(<String>['some random label', 'P1']));

      expect(result['Status'], 'success');
    });

    test('Add only one comment on existing issue when a builder has been marked as unflaky', () async {
      const int existingIssueNumber = 1234;
      final List<IssueLabel> existingLabels = <IssueLabel>[
        IssueLabel(name: 'some random label'),
        IssueLabel(name: 'P2'),
      ];
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId)).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(semanticsIntegrationTestResponse);
      });
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingSameBuilderSemanticsIntegrationTestResponse);
      });
      // when gets existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[
          Issue(
            assignee: User(login: 'some dude'),
            number: existingIssueNumber,
            state: 'open',
            labels: existingLabels,
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
            createdAt:
                DateTime.now().subtract(const Duration(days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake + 1)),
          )
        ]);
      });
      // when firing github request.
      // This is for replacing labels.
      when(mockGitHubClient.request(
        captureAny,
        captureAny,
        body: captureAnyNamed('body'),
      )).thenAnswer((Invocation invocation) {
        return Future<Response>.value(Response('[]', 200));
      });
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify comment is created correctly.
      List<dynamic> captured = verify(mockIssuesService.createComment(captureAny, captureAny, captureAny)).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], existingIssueNumber);
      expect(captured[2], expectedSemanticsIntegrationTestIssueComment);

      // Verify labels are applied correctly.
      captured = verify(mockGitHubClient.request(
        captureAny,
        captureAny,
        body: captureAnyNamed('body'),
      )).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), 'PUT');
      expect(captured[1], '/repos/${Config.flutterSlug.fullName}/issues/$existingIssueNumber/labels');
      expect(captured[2], GitHubJson.encode(<String>['some random label', 'P1']));

      expect(result['Status'], 'success');
    });

    test('Can add bot staging and prod stats for a bringup: true builder', () async {
      const int existingIssueNumber = 1234;
      final List<IssueLabel> existingLabels = <IssueLabel>[
        IssueLabel(name: 'some random label'),
        IssueLabel(name: 'P2'),
      ];
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId)).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(ciyamlTestResponse);
      });
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingCiyamlTestResponse);
      });
      // when gets existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[
          Issue(
            assignee: User(login: 'some dude'),
            number: existingIssueNumber,
            state: 'open',
            labels: existingLabels,
            title: expectedStagingSemanticsIntegrationTestResponseTitle,
            body: expectedStagingSemanticsIntegrationTestResponseBody,
            createdAt:
                DateTime.now().subtract(const Duration(days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake + 1)),
          )
        ]);
      });
      // when firing github request.
      // This is for replacing labels.
      when(mockGitHubClient.request(
        captureAny,
        captureAny,
        body: captureAnyNamed('body'),
      )).thenAnswer((Invocation invocation) {
        return Future<Response>.value(Response('[]', 200));
      });
      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify comment is created correctly.
      List<dynamic> captured = verify(mockIssuesService.createComment(captureAny, captureAny, captureAny)).captured;
      expect(captured.length, 6);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], existingIssueNumber);
      expect(captured[2], expectedCiyamlTestIssueComment);
      expect(captured[3].toString(), Config.flutterSlug.toString());
      expect(captured[4], existingIssueNumber);
      expect(captured[5], expectedStagingCiyamlTestIssueComment);

      // Verify labels are applied correctly.
      captured = verify(mockGitHubClient.request(
        captureAny,
        captureAny,
        body: captureAnyNamed('body'),
      )).captured;
      expect(captured.length, 6);
      expect(captured[0].toString(), 'PUT');
      expect(captured[1], '/repos/${Config.flutterSlug.fullName}/issues/$existingIssueNumber/labels');
      expect(captured[2], GitHubJson.encode(<String>['some random label', 'P1']));

      expect(result['Status'], 'success');
    });

    test('Can assign test owner', () async {
      const int existingIssueNumber = 1234;
      final List<IssueLabel> existingLabels = <IssueLabel>[
        IssueLabel(name: 'some random label'),
        IssueLabel(name: 'P2'),
      ];
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId)).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(semanticsIntegrationTestResponse);
      });
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingCiyamlTestResponse);
      });
      // when gets existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[
          Issue(
            number: existingIssueNumber,
            state: 'open',
            labels: existingLabels,
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
            createdAt:
                DateTime.now().subtract(const Duration(days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake + 1)),
          )
        ]);
      });
      // when firing github request.
      // This is for replacing labels.
      when(mockGitHubClient.request(
        captureAny,
        captureAny,
        body: captureAnyNamed('body'),
      )).thenAnswer((Invocation invocation) {
        return Future<Response>.value(Response('[]', 200));
      });

      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify comment is created correctly.
      final List<dynamic> captured = verify(mockIssuesService.edit(captureAny, captureAny, captureAny)).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], existingIssueNumber);
      final IssueRequest request = captured[2] as IssueRequest;
      expect(request.assignee, 'HansMuller');

      expect(result['Status'], 'success');
    });

    test('Can add existing issue comment case 0.0', () async {
      const int existingIssueNumber = 1234;
      final List<IssueLabel> existingLabels = <IssueLabel>[
        IssueLabel(name: 'some random label'),
        IssueLabel(name: 'P2'),
      ];
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId)).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(semanticsIntegrationTestResponseZeroFlake);
      });
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingCiyamlTestResponse);
      });
      // when gets existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[
          Issue(
            number: existingIssueNumber,
            state: 'open',
            labels: existingLabels,
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
            createdAt:
                DateTime.now().subtract(const Duration(days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake + 1)),
          )
        ]);
      });
      // when firing github request.
      // This is for replacing labels.
      when(mockGitHubClient.request(
        captureAny,
        captureAny,
        body: captureAnyNamed('body'),
      )).thenAnswer((Invocation invocation) {
        return Future<Response>.value(Response('[]', 200));
      });

      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify issue is created correctly.
      List<dynamic> captured = verify(mockIssuesService.createComment(captureAny, captureAny, captureAny)).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], existingIssueNumber);
      expect(captured[2], expectedSemanticsIntegrationTestZeroFlakeIssueComment);

      // Verify labels are the same.
      captured = verify(mockGitHubClient.request(
        captureAny,
        captureAny,
        body: captureAnyNamed('body'),
      )).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), 'PUT');
      expect(captured[1], '/repos/${Config.flutterSlug.fullName}/issues/$existingIssueNumber/labels');
      expect(captured[2], GitHubJson.encode(<String>['some random label', 'P2']));

      expect(result['Status'], 'success');
    });

    test('Does not add comment if the issue is still fresh', () async {
      const int existingIssueNumber = 1234;
      final List<IssueLabel> existingLabels = <IssueLabel>[
        IssueLabel(name: 'some random label'),
        IssueLabel(name: 'P2'),
      ];
      // When queries flaky data from BigQuery.
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId)).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(semanticsIntegrationTestResponseZeroFlake);
      });
      when(mockBigqueryService.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging'))
          .thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingCiyamlTestResponse);
      });
      // when gets existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return Stream<Issue>.fromIterable(<Issue>[
          Issue(
            number: existingIssueNumber,
            state: 'open',
            labels: existingLabels,
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
            createdAt:
                DateTime.now().subtract(const Duration(days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake - 1)),
          )
        ]);
      });

      final Map<String, dynamic> result = await utf8.decoder
          .bind((await tester.get<Body>(handler)).serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      verifyNever(mockIssuesService.createComment(captureAny, captureAny, captureAny));

      // Verify labels are the same.
      verifyNever(mockGitHubClient.request(
        captureAny,
        captureAny,
        body: captureAnyNamed('body'),
      ));

      expect(result['Status'], 'success');
    });
  });
}
