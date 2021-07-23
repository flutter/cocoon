// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/service/access_client_provider.dart';
import 'package:cocoon_service/src/service/bigquery.dart';

import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/utilities/mocks.dart';

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
        { "v": "0.5"}
      ]
    }
  ]
}
''';

const String jobNotCompleteResponse = '''
{
  "jobComplete" : false
}
''';

const String expectedProjectId = 'project-id';

void main() {
  test('can handle unsuccessful job query', () async {
    final BigqueryServiceMock service = BigqueryServiceMock(MockAccessClientProvider());
    service.mockJobsResourceApi = MockJobsResourceApi();
    // When queries flaky data from BigQuery.
    when(service.mockJobsResourceApi.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(jobNotCompleteResponse) as Map<dynamic, dynamic>));
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
    final BigqueryServiceMock service = BigqueryServiceMock(MockAccessClientProvider());
    service.mockJobsResourceApi = MockJobsResourceApi();
    // When queries flaky data from BigQuery.
    when(service.mockJobsResourceApi.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(semanticsIntegrationTestResponse) as Map<dynamic, dynamic>));
    });
    final List<BuilderStatistic> statisticList = await service.listBuilderStatistic(expectedProjectId);
    expect(statisticList.length, 1);
    expect(statisticList[0].name, 'Mac_android android_semantics_integration_test');
    expect(statisticList[0].flakyRate, 0.5);
    expect(statisticList[0].succeededBuilds.length, 3);
    expect(statisticList[0].succeededBuilds[0], '203');
    expect(statisticList[0].succeededBuilds[1], '202');
    expect(statisticList[0].succeededBuilds[2], '201');
    expect(statisticList[0].flakyBuilds.length, 3);
    expect(statisticList[0].flakyBuilds[0], '103');
    expect(statisticList[0].flakyBuilds[1], '102');
    expect(statisticList[0].flakyBuilds[2], '101');
    expect(statisticList[0].recentCommit, 'abc');
    expect(statisticList[0].flakyBuildOfRecentCommit, '103');
  });
}

class BigqueryServiceMock extends BigqueryService {
  BigqueryServiceMock(AccessClientProvider accessClientProvider) : super(accessClientProvider);
  MockJobsResourceApi mockJobsResourceApi;
  @override
  Future<JobsResourceApi> defaultJobs() async {
    return mockJobsResourceApi;
  }
}
