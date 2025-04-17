// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handlers/flaky_handler_utils.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/utilities/mocks.dart';
import 'update_existing_flaky_issues_test_data.dart';

const String kThreshold = '0.02';

void main() {
  useTestLoggerPerTest();

  group('Update flaky', () {
    late UpdateExistingFlakyIssue handler;
    late ApiRequestHandlerTester tester;
    late FakeConfig config;
    late MockBigqueryService mockBigqueryService;
    late MockGitHub mockGitHubClient;
    late MockIssuesService mockIssuesService;

    setUp(() {
      final request = FakeHttpRequest(
        queryParametersValue: <String, dynamic>{
          FileFlakyIssueAndPR.kThresholdKey: kThreshold,
        },
      );

      final clientContext = FakeClientContext();
      final auth = FakeDashboardAuthentication(clientContext: clientContext);
      mockBigqueryService = MockBigqueryService();
      mockGitHubClient = MockGitHub();
      mockIssuesService = MockIssuesService();
      final mockRepositoriesService = MockRepositoriesService();

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

      when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);
      when(mockGitHubClient.issues).thenReturn(mockIssuesService);
      when(
        // ignore: discarded_futures
        mockIssuesService.createComment(any, any, any),
      ).thenAnswer((_) async => IssueComment());
      when(
        // ignore: discarded_futures
        mockIssuesService.edit(any, any, any),
      ).thenAnswer((_) async => Issue());
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
      const existingIssueNumber = 1234;
      final existingLabels = <IssueLabel>[
        IssueLabel(name: 'some random label'),
        IssueLabel(name: 'P2'),
      ];
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponse,
        );
      });
      when(
        mockBigqueryService.listBuilderStatistic(
          kBigQueryProjectId,
          bucket: 'staging',
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingCiyamlTestResponse);
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
            assignee: User(login: 'some dude'),
            number: existingIssueNumber,
            state: 'open',
            labels: existingLabels,
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
            createdAt: DateTime.now().subtract(
              const Duration(
                days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake + 1,
              ),
            ),
          ),
        ]);
      });
      // when firing github request.
      // This is for replacing labels.
      when(
        mockGitHubClient.request(
          captureAny,
          captureAny,
          body: captureAnyNamed('body'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<Response>.value(Response('[]', 200));
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

      // Verify comment is created correctly.
      var captured =
          verify(
            mockIssuesService.createComment(captureAny, captureAny, captureAny),
          ).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], existingIssueNumber);
      expect(captured[2], expectedSemanticsIntegrationTestIssueComment);

      // Verify labels are applied correctly.
      captured =
          verify(
            mockGitHubClient.request(
              captureAny,
              captureAny,
              body: captureAnyNamed('body'),
            ),
          ).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), 'PUT');
      expect(
        captured[1],
        '/repos/${Config.flutterSlug.fullName}/issues/$existingIssueNumber/labels',
      );
      expect(
        captured[2],
        GitHubJson.encode(<String>['some random label', 'P0']),
      );

      expect(result['Status'], 'success');
    });

    test(
      'Add only one comment on existing issue when a builder has been marked as unflaky',
      () async {
        const existingIssueNumber = 1234;
        final existingLabels = <IssueLabel>[
          IssueLabel(name: 'some random label'),
          IssueLabel(name: 'P2'),
        ];
        // When queries flaky data from BigQuery.
        when(
          mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
        ).thenAnswer((Invocation invocation) {
          return Future<List<BuilderStatistic>>.value(
            semanticsIntegrationTestResponse,
          );
        });
        when(
          mockBigqueryService.listBuilderStatistic(
            kBigQueryProjectId,
            bucket: 'staging',
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<List<BuilderStatistic>>.value(
            stagingSameBuilderSemanticsIntegrationTestResponse,
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
              assignee: User(login: 'some dude'),
              number: existingIssueNumber,
              state: 'open',
              labels: existingLabels,
              title: expectedSemanticsIntegrationTestResponseTitle,
              body: expectedSemanticsIntegrationTestResponseBody,
              createdAt: DateTime.now().subtract(
                const Duration(
                  days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake + 1,
                ),
              ),
            ),
          ]);
        });
        // when firing github request.
        // This is for replacing labels.
        when(
          mockGitHubClient.request(
            captureAny,
            captureAny,
            body: captureAnyNamed('body'),
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<Response>.value(Response('[]', 200));
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

        // Verify comment is created correctly.
        var captured =
            verify(
              mockIssuesService.createComment(
                captureAny,
                captureAny,
                captureAny,
              ),
            ).captured;
        expect(captured.length, 3);
        expect(captured[0].toString(), Config.flutterSlug.toString());
        expect(captured[1], existingIssueNumber);
        expect(captured[2], expectedSemanticsIntegrationTestIssueComment);

        // Verify labels are applied correctly.
        captured =
            verify(
              mockGitHubClient.request(
                captureAny,
                captureAny,
                body: captureAnyNamed('body'),
              ),
            ).captured;
        expect(captured.length, 3);
        expect(captured[0].toString(), 'PUT');
        expect(
          captured[1],
          '/repos/${Config.flutterSlug.fullName}/issues/$existingIssueNumber/labels',
        );
        expect(
          captured[2],
          GitHubJson.encode(<String>['some random label', 'P0']),
        );

        expect(result['Status'], 'success');
      },
    );

    test(
      'Can add bot staging and prod stats for a bringup: true builder',
      () async {
        const existingIssueNumber = 1234;
        final existingLabels = <IssueLabel>[
          IssueLabel(name: 'some random label'),
          IssueLabel(name: 'P2'),
        ];
        // When queries flaky data from BigQuery.
        when(
          mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
        ).thenAnswer((Invocation invocation) {
          return Future<List<BuilderStatistic>>.value(ciyamlTestResponse);
        });
        when(
          mockBigqueryService.listBuilderStatistic(
            kBigQueryProjectId,
            bucket: 'staging',
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<List<BuilderStatistic>>.value(
            stagingCiyamlTestResponse,
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
              assignee: User(login: 'some dude'),
              number: existingIssueNumber,
              state: 'open',
              labels: existingLabels,
              title: expectedStagingSemanticsIntegrationTestResponseTitle,
              body: expectedStagingSemanticsIntegrationTestResponseBody,
              createdAt: DateTime.now().subtract(
                const Duration(
                  days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake + 1,
                ),
              ),
            ),
          ]);
        });
        // when firing github request.
        // This is for replacing labels.
        when(
          mockGitHubClient.request(
            captureAny,
            captureAny,
            body: captureAnyNamed('body'),
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<Response>.value(Response('[]', 200));
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

        // Verify comment is created correctly.
        final captured =
            verify(
              mockIssuesService.createComment(
                captureAny,
                captureAny,
                captureAny,
              ),
            ).captured;
        expect(captured.length, 6);
        expect(captured[0].toString(), Config.flutterSlug.toString());
        expect(captured[1], existingIssueNumber);
        expect(captured[2], expectedCiyamlTestIssueComment);
        expect(captured[3].toString(), Config.flutterSlug.toString());
        expect(captured[4], existingIssueNumber);
        expect(captured[5], expectedStagingCiyamlTestIssueComment);

        // Verify no labels are applied for already `bringup: true` target.
        verifyNever(
          mockGitHubClient.request(
            captureAny,
            captureAny,
            body: captureAnyNamed('body'),
          ),
        );

        expect(result['Status'], 'success');
      },
    );

    test('Can assign test owner', () async {
      const existingIssueNumber = 1234;
      final existingLabels = <IssueLabel>[
        IssueLabel(name: 'some random label'),
        IssueLabel(name: 'P2'),
      ];
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponse,
        );
      });
      when(
        mockBigqueryService.listBuilderStatistic(
          kBigQueryProjectId,
          bucket: 'staging',
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingCiyamlTestResponse);
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
            number: existingIssueNumber,
            state: 'open',
            labels: existingLabels,
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
            createdAt: DateTime.now().subtract(
              const Duration(
                days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake + 1,
              ),
            ),
          ),
        ]);
      });
      // when firing github request.
      // This is for replacing labels.
      when(
        mockGitHubClient.request(
          captureAny,
          captureAny,
          body: captureAnyNamed('body'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<Response>.value(Response('[]', 200));
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

      // Verify comment is created correctly.
      final captured =
          verify(
            mockIssuesService.edit(captureAny, captureAny, captureAny),
          ).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], existingIssueNumber);
      final request = captured[2] as IssueRequest;
      expect(request.assignee, 'HansMuller');

      expect(result['Status'], 'success');
    });

    test('Can add existing issue comment case 0.0', () async {
      const existingIssueNumber = 1234;
      final existingLabels = <IssueLabel>[
        IssueLabel(name: 'some random label'),
        IssueLabel(name: 'P2'),
      ];
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponseZeroFlake,
        );
      });
      when(
        mockBigqueryService.listBuilderStatistic(
          kBigQueryProjectId,
          bucket: 'staging',
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingCiyamlTestResponse);
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
            number: existingIssueNumber,
            state: 'open',
            labels: existingLabels,
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
            createdAt: DateTime.now().subtract(
              const Duration(
                days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake + 1,
              ),
            ),
          ),
        ]);
      });
      // when firing github request.
      // This is for replacing labels.
      when(
        mockGitHubClient.request(
          captureAny,
          captureAny,
          body: captureAnyNamed('body'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<Response>.value(Response('[]', 200));
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
          verify(
            mockIssuesService.createComment(captureAny, captureAny, captureAny),
          ).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), Config.flutterSlug.toString());
      expect(captured[1], existingIssueNumber);
      expect(
        captured[2],
        expectedSemanticsIntegrationTestZeroFlakeIssueComment,
      );

      // Verify labels are the same.
      captured =
          verify(
            mockGitHubClient.request(
              captureAny,
              captureAny,
              body: captureAnyNamed('body'),
            ),
          ).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), 'PUT');
      expect(
        captured[1],
        '/repos/${Config.flutterSlug.fullName}/issues/$existingIssueNumber/labels',
      );
      expect(
        captured[2],
        GitHubJson.encode(<String>['some random label', 'P2']),
      );

      expect(result['Status'], 'success');
    });

    test('Does not add comment if the issue is still fresh', () async {
      const existingIssueNumber = 1234;
      final existingLabels = <IssueLabel>[
        IssueLabel(name: 'some random label'),
        IssueLabel(name: 'P2'),
      ];
      // When queries flaky data from BigQuery.
      when(
        mockBigqueryService.listBuilderStatistic(kBigQueryProjectId),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(
          semanticsIntegrationTestResponseZeroFlake,
        );
      });
      when(
        mockBigqueryService.listBuilderStatistic(
          kBigQueryProjectId,
          bucket: 'staging',
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<BuilderStatistic>>.value(stagingCiyamlTestResponse);
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
            number: existingIssueNumber,
            state: 'open',
            labels: existingLabels,
            title: expectedSemanticsIntegrationTestResponseTitle,
            body: expectedSemanticsIntegrationTestResponseBody,
            createdAt: DateTime.now().subtract(
              const Duration(
                days: UpdateExistingFlakyIssue.kFreshPeriodForOpenFlake - 1,
              ),
            ),
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

      verifyNever(
        mockIssuesService.createComment(captureAny, captureAny, captureAny),
      );

      // Verify labels are the same.
      verifyNever(
        mockGitHubClient.request(
          captureAny,
          captureAny,
          body: captureAnyNamed('body'),
        ),
      );

      expect(result['Status'], 'success');
    });
  });
}
