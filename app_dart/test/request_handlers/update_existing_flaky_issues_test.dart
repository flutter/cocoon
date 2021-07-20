// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

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
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/utilities/mocks.dart';

import 'update_existing_flaky_issues_test_data.dart';

const String kThreshold = '0.02';

void main() {
  group('Update flaky', () {
    UpdateExistingFlakyIssue handler;
    ApiRequestHandlerTester tester;
    FakeHttpRequest request;
    FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticationProvider auth;
    MockBigqueryService mockBigqueryService;
    MockGitHub mockGitHubClient;
    MockIssuesService mockIssuesService;

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

      // when gets existing flaky issues.
      when(mockIssuesService.listByRepo(captureAny, state: captureAnyNamed('state'), labels: captureAnyNamed('labels')))
          .thenAnswer((Invocation invocation) {
        return const Stream<Issue>.empty();
      });

      when(mockGitHubClient.issues).thenReturn(mockIssuesService);
      config = FakeConfig(
        githubService: GithubService(mockGitHubClient),
        bigqueryService: mockBigqueryService,
      );
      tester = ApiRequestHandlerTester(request: request);

      handler = UpdateExistingFlakyIssue(
        config,
        auth,
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
          .bind((await tester.get<Body>(handler)).serialize())
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify comment is created correctly.
      List<dynamic> captured = verify(mockIssuesService.createComment(captureAny, captureAny, captureAny)).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), config.flutterSlug.toString());
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
      expect(captured[1], '/repos/${config.flutterSlug.fullName}/issues/$existingIssueNumber/labels');
      expect(captured[2], GitHubJson.encode(<String>['some random label', 'P1']));

      expect(result['Statuses'], 'success');
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
          .bind((await tester.get<Body>(handler)).serialize())
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      // Verify issue is created correctly.
      List<dynamic> captured = verify(mockIssuesService.createComment(captureAny, captureAny, captureAny)).captured;
      expect(captured.length, 3);
      expect(captured[0].toString(), config.flutterSlug.toString());
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
      expect(captured[1], '/repos/${config.flutterSlug.fullName}/issues/$existingIssueNumber/labels');
      expect(captured[2], GitHubJson.encode(<String>['some random label', 'P2']));

      expect(result['Statuses'], 'success');
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
          .bind((await tester.get<Body>(handler)).serialize())
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      verifyNever(mockIssuesService.createComment(captureAny, captureAny, captureAny));

      // Verify labels are the same.
      verifyNever(mockGitHubClient.request(
        captureAny,
        captureAny,
        body: captureAnyNamed('body'),
      ));

      expect(result['Statuses'], 'success');
    });
  });
}
