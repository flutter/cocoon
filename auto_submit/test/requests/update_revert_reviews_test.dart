// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/exception/bigquery_exception.dart';
import 'package:auto_submit/model/big_query_revert_request_record.dart';
import 'package:auto_submit/requests/update_revert_reviews.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_bigquery_service.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../utilities/mocks.mocks.dart';

const String expectedProjectId = 'flutter-dashboard';

const String emptyRowsResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "0",
  "rows": []
}
''';

const String updateSuccessResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "1"
}
''';

void main() {
  late FakeGithubService fakeGithubService;
  late FakeBigqueryService fakeBigqueryService;
  late FakeConfig fakeConfig;
  late FakeCronAuthProvider fakeCronAuthProvider;
  late MockJobsResource jobsResource;
  late UpdateRevertReviews updateRevertReviews;

  setUp(() {
    fakeGithubService = FakeGithubService();
    jobsResource = MockJobsResource();
    fakeBigqueryService = FakeBigqueryService(jobsResource);
    fakeCronAuthProvider = FakeCronAuthProvider();
    fakeConfig = FakeConfig(
      githubService: fakeGithubService,
      bigqueryService: fakeBigqueryService,
    );
    updateRevertReviews = UpdateRevertReviews(
      config: fakeConfig,
      cronAuthProvider: fakeCronAuthProvider,
    );
  });

  group('Update issue tests.', () {
    test('Close issue is not updated.', () async {
      User user = User(login: 'ricardoamador');
      Issue issue = Issue(
        user: user,
        state: 'open',
      );

      fakeGithubService.githubIssueMock = issue;

      RevertRequestRecord revertRequestRecord = RevertRequestRecord(
        reviewIssueAssignee: 'keyonghan',
        reviewIssueCreatedTimestamp: DateTime.now(),
        reviewIssueNumber: 1234,
      );

      when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
        return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(updateSuccessResponse) as Map<dynamic, dynamic>),
        );
      });

      bool result = await updateRevertReviews.updateIssue(
        revertRequestRecord: revertRequestRecord,
        bigqueryService: fakeBigqueryService,
        githubService: fakeGithubService,
      );

      expect(result, isFalse);
    });

    test('Closed issue is updated.', () async {
      User user = User(login: 'ricardoamador');
      Issue issue = Issue(
        user: user,
        state: 'closed',
        closedAt: DateTime.now(),
        number: 1234,
        closedBy: user,
      );

      fakeGithubService.githubIssueMock = issue;

      RevertRequestRecord revertRequestRecord = RevertRequestRecord(
        reviewIssueAssignee: 'keyonghan',
        reviewIssueCreatedTimestamp: DateTime.now(),
        reviewIssueNumber: 1234,
      );

      when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
        return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(updateSuccessResponse) as Map<dynamic, dynamic>),
        );
      });

      bool result = await updateRevertReviews.updateIssue(
        revertRequestRecord: revertRequestRecord,
        bigqueryService: fakeBigqueryService,
        githubService: fakeGithubService,
      );

      expect(result, isTrue);
    });

    test('Closed issue is not updated on exception.', () async {
      User user = User(login: 'ricardoamador');
      Issue issue = Issue(
        user: user,
        state: 'closed',
        closedAt: DateTime.now(),
        number: 1234,
        closedBy: user,
      );

      fakeGithubService.githubIssueMock = issue;

      RevertRequestRecord revertRequestRecord = RevertRequestRecord(
        reviewIssueAssignee: 'keyonghan',
        reviewIssueCreatedTimestamp: DateTime.now(),
        reviewIssueNumber: 1234,
      );

      when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
        throw BigQueryException('Update of review issue 1234 did not complete.');
      });

      bool result = await updateRevertReviews.updateIssue(
        revertRequestRecord: revertRequestRecord,
        bigqueryService: fakeBigqueryService,
        githubService: fakeGithubService,
      );

      expect(result, isFalse);
    });
  });

  group('Update closed revert review requests.', () {
    test('All review requests are processed successfully', () async {
      when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
        return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(emptyRowsResponse) as Map<dynamic, dynamic>),
        );
      });

      Response response = await updateRevertReviews.get();
      expect(response.statusCode, 200);
      String body = await response.readAsString(Encoding.getByName("UTF-8"));
      expect(body, equals('No open revert reviews to update.'));
    });

    test('Updateable review requests are process successfully.', () async {});

    test('No review requests to process is successful.', () async {});
  });
}
