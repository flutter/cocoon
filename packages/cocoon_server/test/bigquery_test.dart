// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server/big_query_pull_request_record.dart';
import 'package:cocoon_server/bigquery.dart';
import 'package:cocoon_server_test/bigquery_testing.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  late BigqueryService service;
  late MockJobsResource jobsResource;

  setUp(() {
    jobsResource = MockJobsResource();
    service = BigqueryService.forTesting(jobsResource);
  });

  test('Insert pull request record is successful.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((
      Invocation invocation,
    ) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(
          jsonDecode(insertDeleteUpdateSuccessResponse)
              as Map<dynamic, dynamic>,
        ),
      );
    });

    final pullRequestRecord = PullRequestRecord(
      prCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(123456789),
      prLandedTimestamp: DateTime.fromMillisecondsSinceEpoch(234567890),
      organization: 'flutter',
      repository: 'cocoon',
      author: 'ricardoamador',
      prNumber: 345,
      prCommit: 'ade456',
      prRequestType: 'merge',
    );

    var hasError = false;
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

  test(
    'Insert pull request record handles unsuccessful job complete error.',
    () async {
      when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<QueryResponse>.value(
          QueryResponse.fromJson(
            jsonDecode(errorResponse) as Map<dynamic, dynamic>,
          ),
        );
      });

      var hasError = false;
      final pullRequestRecord = PullRequestRecord(
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
        expect(
          exception.cause,
          'Insert pull request $pullRequestRecord did not complete.',
        );
        hasError = true;
      }
      expect(hasError, isTrue);
    },
  );

  test('Insert pull request fails when multiple rows are returned.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((
      Invocation invocation,
    ) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(
          jsonDecode(selectPullRequestTooManyRowsResponse)
              as Map<dynamic, dynamic>,
        ),
      );
    });

    var hasError = false;
    final pullRequestRecord = PullRequestRecord(
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
      expect(
        exception.cause,
        'There was an error inserting $pullRequestRecord into the table.',
      );
      hasError = true;
    }
    expect(hasError, isTrue);
  });
}
