// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/exception/bigquery_exception.dart';
import 'package:auto_submit/model/big_query_pull_request_record.dart';
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
}
