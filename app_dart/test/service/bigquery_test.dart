// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/service/bigquery.dart';

import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:cocoon_server/testing/mocks.dart';

import '../src/service/fake_bigquery_service.dart';

const String semanticsIntegrationTestResponse = '''
{
  "jobComplete" : true,
  "rows": [
    { "f": [
        { "v": "Mac_android android_semantics_integration_test"},
        { "v": "1" },
        { "v": "2" },
        { "v": "101, 102, 103" },
        { "v": "201, 202, 203" },
        { "v": "abc" },
        { "v": "103" },
        { "v": "0.5"},
        {"v": "2023-06-20"},
        {"v": "2023-06-29"}
      ]
    }
  ]
}
''';

const String noRecordsResponse = '''
{
  "jobComplete" : true
}
''';

const String jobNotCompleteResponse = '''
{
  "jobComplete" : false
}
''';

const String expectedProjectId = 'project-id';

void main() {
  late FakeBigqueryService service;
  late MockJobsResource jobsResource;
  setUp(() {
    jobsResource = MockJobsResource();
    service = FakeBigqueryService(jobsResource);
  });

  test('can handle unsuccessful job query', () async {
    // When queries flaky data from BigQuery.
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(jobNotCompleteResponse) as Map<dynamic, dynamic>),
      );
    });
    bool hasError = false;
    try {
      await service.listBuilderStatistic(expectedProjectId);
    } catch (e) {
      expect(e.toString(), 'job does not complete');
      hasError = true;
    }
    expect(hasError, isTrue);
  });

  test('can handle job query', () async {
    // When queries flaky data from BigQuery.
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(semanticsIntegrationTestResponse) as Map<dynamic, dynamic>),
      );
    });
    final List<BuilderStatistic> statisticList = await service.listBuilderStatistic(expectedProjectId);
    expect(statisticList.length, 1);
    expect(statisticList[0].name, 'Mac_android android_semantics_integration_test');
    expect(statisticList[0].flakyRate, 0.5);
    expect(statisticList[0].succeededBuilds!.length, 3);
    expect(statisticList[0].succeededBuilds![0], '203');
    expect(statisticList[0].succeededBuilds![1], '202');
    expect(statisticList[0].succeededBuilds![2], '201');
    expect(statisticList[0].flakyBuilds!.length, 3);
    expect(statisticList[0].flakyBuilds![0], '103');
    expect(statisticList[0].flakyBuilds![1], '102');
    expect(statisticList[0].flakyBuilds![2], '101');
    expect(statisticList[0].recentCommit, 'abc');
    expect(statisticList[0].flakyBuildOfRecentCommit, '103');
    expect(statisticList[0].fromDate, '2023-06-20');
    expect(statisticList[0].toDate, '2023-06-29');
  });

  test('return empty build list when bigquery returns no rows', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(noRecordsResponse) as Map<dynamic, dynamic>),
      );
    });
    final List<BuilderRecord> records =
        await service.listRecentBuildRecordsForBuilder(expectedProjectId, builder: 'test', limit: 10);
    expect(records.length, 0);
  });
}
