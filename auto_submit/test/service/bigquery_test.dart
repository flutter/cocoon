// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/exception/bigquery_exception.dart';
import 'package:auto_submit/model/big_query_pull_request_record.dart';
import 'package:auto_submit/model/big_query_revert_request_record.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../src/service/fake_bigquery_service.dart';
import '../utilities/mocks.dart';

const String revertRequestRecordResponse = '''
{
  "jobComplete": true,
  "rows": [
    { "f": [
        { "v": "flutter"},
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "1024" },
        { "v": "123f124" },
        { "v": "123456789" },
        { "v": "123456999" },
        { "v": "ricardoamador" },
        { "v": "2048" },
        { "v": "ce345dc" },
        { "v": "234567890" },
        { "v": "234567999" },
        { "v": "ricardoamador" },
        { "v": "11304" },
        { "v": "1640979000000" },
        { "v": "0" },
        { "v": "" }
      ]
    }
  ]
}
''';

const String pullRequestRecordResponse = '''
{
  "jobComplete": true,
  "rows": [
    { "f": [
        { "v": "123456789"},
        { "v": "234567890" },
        { "v": "flutter" },
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "345" },
        { "v": "ade456" },
        { "v": "merge" }
      ]
    }
  ]
}
''';

const String successResponseNoRowsAffected = '''
{
  "jobComplete": true
}
''';

const String insertDeleteUpdateSuccessResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "1"
}
''';

const String insertDeleteUpdateSuccessTooManyRows = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "2"
}
''';

const String selectPullRequestTooManyRowsResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "2",
  "rows": [
    { "f": [
        { "v": "123456789"},
        { "v": "234567890" },
        { "v": "flutter" },
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "345" },
        { "v": "ade456" },
        { "v": "merge" }
      ]
    },
    { "f": [
        { "v": "123456789"},
        { "v": "234567890" },
        { "v": "flutter" },
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "345" },
        { "v": "ade456" },
        { "v": "merge" }
      ]
    }
  ]
}
''';

const String selectRevertRequestTooManyRowsResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "2",
  "rows": [
    { "f": [
        { "v": "flutter"},
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "1024" },
        { "v": "123f124" },
        { "v": "123456789" },
        { "v": "123456999" },
        { "v": "ricardoamador" },
        { "v": "2048" },
        { "v": "ce345dc" },
        { "v": "234567890" },
        { "v": "234567999" }
      ]
    },
    { "f": [
        { "v": "flutter"},
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "1024" },
        { "v": "123f124" },
        { "v": "123456789" },
        { "v": "123456999" },
        { "v": "ricardoamador" },
        { "v": "2048" },
        { "v": "ce345dc" },
        { "v": "234567890" },
        { "v": "234567999" }
      ]
    }
  ]
}
''';

const String errorResponse = '''
{
  "jobComplete": false
}
''';

const String selectReviewRequestRecordsResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "2",
  "rows": [
    { "f": [
        { "v": "Keyonghan" },
        { "v": "2048" },
        { "v": "234567890" },
        { "v": "0" },
        { "v": "" }
      ]
    },
    { "f": [
        { "v": "caseyhillers" },
        { "v": "2049" },
        { "v": "234567890" },
        { "v": "0" },
        { "v": "" }
      ]
    }
  ]
}
''';

const String expectedProjectId = 'flutter-dashboard';

void main() {
  late FakeBigqueryService service;
  late MockJobsResource jobsResource;

  setUp(() {
    jobsResource = MockJobsResource();
    service = FakeBigqueryService(jobsResource);
  });

  test('Insert pull request record is successful.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(insertDeleteUpdateSuccessResponse) as Map<dynamic, dynamic>),
      );
    });

    final PullRequestRecord pullRequestRecord = PullRequestRecord(
      prCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(123456789),
      prLandedTimestamp: DateTime.fromMillisecondsSinceEpoch(234567890),
      organization: 'flutter',
      repository: 'cocoon',
      author: 'ricardoamador',
      prNumber: 345,
      prCommit: 'ade456',
      prRequestType: 'merge',
    );

    bool hasError = false;
    try {
      await service.insertPullRequestRecord(
        projectId: expectedProjectId,
        pullRequestRecord: pullRequestRecord,
      );
    } on BigQueryException {
      hasError = true;
    }
    expect(hasError, isFalse);
  });

  test('Insert pull request record handles unsuccessful job complete error.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    final PullRequestRecord pullRequestRecord = PullRequestRecord(
      prCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(123456789),
      prLandedTimestamp: DateTime.fromMillisecondsSinceEpoch(234567890),
      organization: 'flutter',
      repository: 'cocoon',
      author: 'ricardoamador',
      prNumber: 345,
      prCommit: 'ade456',
      prRequestType: 'merge',
    );

    try {
      await service.insertPullRequestRecord(
        projectId: expectedProjectId,
        pullRequestRecord: pullRequestRecord,
      );
    } on BigQueryException catch (exception) {
      expect(exception.cause, 'Insert pull request $pullRequestRecord did not complete.');
      hasError = true;
    }
    expect(hasError, isTrue);
  });

  test('Insert pull request fails when multiple rows are returned.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(selectPullRequestTooManyRowsResponse) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    final PullRequestRecord pullRequestRecord = PullRequestRecord(
      prCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(123456789),
      prLandedTimestamp: DateTime.fromMillisecondsSinceEpoch(234567890),
      organization: 'flutter',
      repository: 'cocoon',
      author: 'ricardoamador',
      prNumber: 345,
      prCommit: 'ade456',
      prRequestType: 'merge',
    );

    try {
      await service.insertPullRequestRecord(
        projectId: expectedProjectId,
        pullRequestRecord: pullRequestRecord,
      );
    } on BigQueryException catch (exception) {
      expect(exception.cause, 'There was an error inserting $pullRequestRecord into the table.');
      hasError = true;
    }
    expect(hasError, isTrue);
  });

  test('Select pull request is successful.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(pullRequestRecordResponse) as Map<dynamic, dynamic>),
      );
    });

    final PullRequestRecord pullRequestRecord = await service.selectPullRequestRecordByPrNumber(
      projectId: expectedProjectId,
      prNumber: 345,
      repository: 'cocoon',
    );

    expect(pullRequestRecord, isNotNull);
    expect(pullRequestRecord.prCreatedTimestamp, equals(DateTime.fromMillisecondsSinceEpoch(123456789)));
    expect(pullRequestRecord.prLandedTimestamp, equals(DateTime.fromMillisecondsSinceEpoch(234567890)));
    expect(pullRequestRecord.organization, equals('flutter'));
    expect(pullRequestRecord.repository, equals('cocoon'));
    expect(pullRequestRecord.author, equals('ricardoamador'));
    expect(pullRequestRecord.prNumber, 345);
    expect(pullRequestRecord.prCommit, equals('ade456'));
    expect(pullRequestRecord.prRequestType, equals('merge'));
  });

  test('Select pull request handles unsuccessful job failure.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      await service.selectPullRequestRecordByPrNumber(
        projectId: expectedProjectId,
        prNumber: 345,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(exception.cause, 'Get pull request by pr# 345 in repository cocoon did not complete.');
    }
    expect(hasError, isTrue);
  });

  test('Select pull request handles no rows returned failure.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(successResponseNoRowsAffected) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.selectPullRequestRecordByPrNumber(
        projectId: expectedProjectId,
        prNumber: 345,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(
        exception.cause,
        'Could not find an entry for pull request with pr# 345 in repository cocoon.',
      );
    }
    expect(hasError, isTrue);
  });

  test('Select pull request handles too many rows returned failure.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(selectPullRequestTooManyRowsResponse) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.selectPullRequestRecordByPrNumber(
        projectId: expectedProjectId,
        prNumber: 345,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(
        exception.cause,
        'More than one record was returned for pull request with pr# 345 in repository cocoon.',
      );
    }
    expect(hasError, isTrue);
  });

  test('Delete pull request record handles failure to complete job.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      await service.deletePullRequestRecord(
        projectId: expectedProjectId,
        prNumber: 345,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(
        exception.cause,
        'Delete pull request with pr# 345 in repository cocoon did not complete.',
      );
    }
    expect(hasError, isTrue);
  });

  test('Delete pull request record handles success but no affected rows.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(successResponseNoRowsAffected) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.deletePullRequestRecord(
        projectId: expectedProjectId,
        prNumber: 345,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(
        exception.cause,
        'Could not find pull request with pr# 345 in repository cocoon to delete.',
      );
    }
    expect(hasError, isTrue);
  });

  test('Delete pull request record handles success but wrong number of affected rows.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(insertDeleteUpdateSuccessTooManyRows) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.deletePullRequestRecord(
        projectId: expectedProjectId,
        prNumber: 345,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(
        exception.cause,
        'More than one row was deleted from the database for pull request with pr# 345 in repository cocoon.',
      );
    }
    expect(hasError, isTrue);
  });

  test('Insert revert request record is successful.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(insertDeleteUpdateSuccessResponse) as Map<dynamic, dynamic>),
      );
    });

    final RevertRequestRecord revertRequestRecord = RevertRequestRecord(
      organization: 'flutter',
      repository: 'cocoon',
      author: 'ricardoamador',
      prNumber: 1024,
      prCommit: '123f124',
      prCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(123456789),
      prLandedTimestamp: DateTime.fromMillisecondsSinceEpoch(123456999),
      originalPrAuthor: 'ricardoamador',
      originalPrNumber: 1000,
      originalPrCommit: 'ce345dc',
      originalPrCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(234567890),
      originalPrLandedTimestamp: DateTime.fromMillisecondsSinceEpoch(234567999),
      reviewIssueAssignee: 'ricardoamador',
      reviewIssueNumber: 11304,
      reviewIssueCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(1640979000000),
    );

    bool hasError = false;
    try {
      await service.insertRevertRequestRecord(
        projectId: expectedProjectId,
        revertRequestRecord: revertRequestRecord,
      );
    } on BigQueryException {
      hasError = true;
    }
    expect(hasError, isFalse);
  });

  test('Insert revert request record handles unsuccessful job complete error.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    final RevertRequestRecord revertRequestRecord = RevertRequestRecord(
      organization: 'flutter',
      repository: 'cocoon',
      author: 'ricardoamador',
      prNumber: 1024,
      prCommit: '123f124',
      prCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(123456789),
      prLandedTimestamp: DateTime.fromMillisecondsSinceEpoch(123456999),
      originalPrAuthor: 'ricardoamador',
      originalPrNumber: 1000,
      originalPrCommit: 'ce345dc',
      originalPrCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(234567890),
      originalPrLandedTimestamp: DateTime.fromMillisecondsSinceEpoch(234567999),
      reviewIssueAssignee: 'ricardoamador',
      reviewIssueNumber: 11304,
      reviewIssueCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(1640979000000),
    );

    try {
      await service.insertRevertRequestRecord(
        projectId: expectedProjectId,
        revertRequestRecord: revertRequestRecord,
      );
    } on BigQueryException catch (e) {
      expect(e.cause, 'Insert revert request $revertRequestRecord did not complete.');
      hasError = true;
    }
    expect(hasError, isTrue);
  });

  test('Select revert request is successful.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(revertRequestRecordResponse) as Map<dynamic, dynamic>),
      );
    });

    final RevertRequestRecord revertRequestRecord = await service.selectRevertRequestByRevertPrNumber(
      projectId: expectedProjectId,
      prNumber: 2048,
      repository: 'cocoon',
    );

    expect(revertRequestRecord, isNotNull);
    expect(revertRequestRecord.organization, equals('flutter'));
    expect(revertRequestRecord.repository, equals('cocoon'));
    expect(revertRequestRecord.author, equals('ricardoamador'));
    expect(revertRequestRecord.prNumber, equals(1024));
    expect(revertRequestRecord.prCommit, equals('123f124'));
    expect(revertRequestRecord.prCreatedTimestamp, equals(DateTime.fromMillisecondsSinceEpoch(123456789)));
    expect(revertRequestRecord.prLandedTimestamp, equals(DateTime.fromMillisecondsSinceEpoch(123456999)));
    expect(revertRequestRecord.originalPrAuthor, equals('ricardoamador'));
    expect(revertRequestRecord.originalPrNumber, equals(2048));
    expect(revertRequestRecord.originalPrCommit, equals('ce345dc'));
    expect(revertRequestRecord.originalPrCreatedTimestamp, equals(DateTime.fromMillisecondsSinceEpoch(234567890)));
    expect(revertRequestRecord.originalPrLandedTimestamp, equals(DateTime.fromMillisecondsSinceEpoch(234567999)));
    expect(revertRequestRecord.reviewIssueAssignee, equals('ricardoamador'));
    expect(revertRequestRecord.reviewIssueNumber, equals(11304));
    expect(revertRequestRecord.reviewIssueCreatedTimestamp, equals(DateTime.fromMillisecondsSinceEpoch(1640979000000)));
    expect(revertRequestRecord.reviewIssueLandedTimestamp, equals(DateTime.fromMillisecondsSinceEpoch(0)));
    expect(revertRequestRecord.reviewIssueClosedBy, equals(''));
  });

  test('Select revert request is unsuccessful with job did not complete error.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.selectRevertRequestByRevertPrNumber(
        projectId: expectedProjectId,
        prNumber: 2048,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(exception.cause, 'Get revert request with pr# 2048 in repository cocoon did not complete.');
    }
    expect(hasError, isTrue);
  });

  test('Select revert request is successful but does not return any rows.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(successResponseNoRowsAffected) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.selectRevertRequestByRevertPrNumber(
        projectId: expectedProjectId,
        prNumber: 2048,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(
        exception.cause,
        'Could not find an entry for revert request with pr# 2048 in repository cocoon.',
      );
    }
    expect(hasError, isTrue);
  });

  test('Select is successful but returns more than one row in the request.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(selectRevertRequestTooManyRowsResponse) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.selectRevertRequestByRevertPrNumber(
        projectId: expectedProjectId,
        prNumber: 2048,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(
        exception.cause,
        'More than one record was returned for revert request with pr# 2048 in repository cocoon.',
      );
    }
    expect(hasError, isTrue);
  });

  test('Delete revert request record handles failure to complete job.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.deleteRevertRequestRecord(
        projectId: expectedProjectId,
        prNumber: 2048,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(
        exception.cause,
        'Delete revert request with pr# 2048 in repository cocoon did not complete.',
      );
    }
    expect(hasError, isTrue);
  });

  test('Delete revert request record handles success but no affected rows.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(successResponseNoRowsAffected) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.deleteRevertRequestRecord(
        projectId: expectedProjectId,
        prNumber: 2048,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(
        exception.cause,
        'Could not find revert request with pr# 2048 in repository cocoon to delete.',
      );
    }
    expect(hasError, isTrue);
  });

  test('Delete revert request record handles success but wrong number of affected rows.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(insertDeleteUpdateSuccessTooManyRows) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.deleteRevertRequestRecord(
        projectId: expectedProjectId,
        prNumber: 2048,
        repository: 'cocoon',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(
        exception.cause,
        'More than one row was deleted from the database for revert request with pr# 2048 in repository cocoon.',
      );
    }
    expect(hasError, isTrue);
  });

  test('Select revert request review issues is successful with rows returned.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(selectReviewRequestRecordsResponse) as Map<dynamic, dynamic>),
      );
    });

    final List<RevertRequestRecord> revertRequestRecordReviewsList =
        await service.selectOpenReviewRequestIssueRecordsList(
      projectId: expectedProjectId,
    );

    final RevertRequestRecord keyongRecord = RevertRequestRecord(
      reviewIssueAssignee: 'Keyonghan',
      reviewIssueNumber: 2048,
      reviewIssueCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(234567890),
      reviewIssueLandedTimestamp: DateTime.fromMillisecondsSinceEpoch(0),
      reviewIssueClosedBy: '',
    );

    final RevertRequestRecord caseyRecord = RevertRequestRecord(
      reviewIssueAssignee: 'caseyhillers',
      reviewIssueNumber: 2049,
      reviewIssueCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(234567890),
      reviewIssueLandedTimestamp: DateTime.fromMillisecondsSinceEpoch(0),
      reviewIssueClosedBy: '',
    );

    expect(revertRequestRecordReviewsList.length, 2);
    for (RevertRequestRecord revertRequestRecord in revertRequestRecordReviewsList) {
      if (revertRequestRecord.reviewIssueAssignee == keyongRecord.reviewIssueAssignee) {
        expect(revertRequestRecord.reviewIssueAssignee, keyongRecord.reviewIssueAssignee);
        expect(revertRequestRecord.reviewIssueNumber, keyongRecord.reviewIssueNumber);
        expect(revertRequestRecord.reviewIssueCreatedTimestamp, keyongRecord.reviewIssueCreatedTimestamp);
        expect(revertRequestRecord.reviewIssueLandedTimestamp, keyongRecord.reviewIssueLandedTimestamp);
        expect(revertRequestRecord.reviewIssueClosedBy, keyongRecord.reviewIssueClosedBy);
      } else if (revertRequestRecord.reviewIssueAssignee == caseyRecord.reviewIssueAssignee) {
        expect(revertRequestRecord.reviewIssueAssignee, caseyRecord.reviewIssueAssignee);
        expect(revertRequestRecord.reviewIssueNumber, caseyRecord.reviewIssueNumber);
        expect(revertRequestRecord.reviewIssueCreatedTimestamp, caseyRecord.reviewIssueCreatedTimestamp);
        expect(revertRequestRecord.reviewIssueLandedTimestamp, caseyRecord.reviewIssueLandedTimestamp);
        expect(revertRequestRecord.reviewIssueClosedBy, caseyRecord.reviewIssueClosedBy);
      }
    }
  });

  test('Select revert request review issues is successful with zero rows returned.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(successResponseNoRowsAffected) as Map<dynamic, dynamic>),
      );
    });

    final List<RevertRequestRecord> revertRequestRecordReviewsList =
        await service.selectOpenReviewRequestIssueRecordsList(
      projectId: expectedProjectId,
    );

    assert(revertRequestRecordReviewsList.isEmpty);
  });

  test('Select revert request review issues is not successful with job did not complete.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.selectOpenReviewRequestIssueRecordsList(
        projectId: expectedProjectId,
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(exception.cause, 'Get open review request issues records did not complete.');
    }
    expect(hasError, isTrue);
  });

  test('Update record is successful.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(insertDeleteUpdateSuccessResponse) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.updateReviewRequestIssue(
        projectId: expectedProjectId,
        reviewIssueLandedTimestamp: DateTime.now(),
        reviewIssueNumber: 2048,
        reviewIssueClosedBy: 'ricardoamador',
      );
    } on BigQueryException {
      hasError = true;
    }

    expect(hasError, isFalse);
  });

  test('Update revert request review record is successful but wrong number of rows is updated.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(insertDeleteUpdateSuccessTooManyRows) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.updateReviewRequestIssue(
        projectId: expectedProjectId,
        reviewIssueLandedTimestamp: DateTime.now(),
        reviewIssueNumber: 2048,
        reviewIssueClosedBy: 'ricardoamador',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(
        exception.cause,
        'There was an error updating revert request record review issue landed timestamp with review issue number 2048.',
      );
    }

    expect(hasError, isTrue);
  });

  test('Update revert request review record does not complete successfully.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>),
      );
    });

    bool hasError = false;
    try {
      await service.updateReviewRequestIssue(
        projectId: expectedProjectId,
        reviewIssueLandedTimestamp: DateTime.now(),
        reviewIssueNumber: 2048,
        reviewIssueClosedBy: 'ricardoamador',
      );
    } on BigQueryException catch (exception) {
      hasError = true;
      expect(exception.cause, 'Update of review issue 2048 did not complete.');
    }

    expect(hasError, isTrue);
  });
}
