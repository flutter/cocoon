// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart';

import 'access_client_provider.dart';

const String getBuilderStatisticQuery = r'''
select builder_name,
       sum(is_flaky) as flaky_number,
       count(*) as total_number,
       string_agg(case when is_flaky = 1 then failed_builds end, ', ') as failed_builds,
       string_agg(succeeded_builds, ', ') as succeeded_builds,
       array_agg(case when is_flaky = 1 then sha end IGNORE NULLS ORDER BY date DESC)[ordinal(1)] as recent_flaky_commit,
       array_agg(case when is_flaky = 1 then failed_builds end IGNORE NULLS ORDER BY date DESC)[ordinal(1)] as failure_of_recent_flaky_commit,
       sum(is_flaky)/count(*) as flaky_ratio
from `flutter-dashboard.datasite.luci_prod_build_status`
where date>=date_sub(current_date(), interval 14 day) and
      date<=current_date() and
      builder_name not like '%Drone' and
      repo='flutter' and
      branch='master' and
      pool = 'luci.flutter.prod' and
      builder_name not like '%Beta%'
group by builder_name;
''';

class BigqueryService {
  const BigqueryService(this.accessClientProvider) : assert(accessClientProvider != null);

  /// AccessClientProvider for OAuth 2.0 authenticated access client
  final AccessClientProvider accessClientProvider;

  /// Return a [TabledataResourceApi] with an authenticated [client]
  Future<TabledataResourceApi> defaultTabledata() async {
    final Client client = await accessClientProvider.createAccessClient(
      scopes: const <String>[BigqueryApi.BigqueryScope],
    );
    return BigqueryApi(client).tabledata;
  }

  /// Return a [JobsResourceApi] with an authenticated [client]
  Future<JobsResourceApi> defaultJobs() async {
    final Client client = await accessClientProvider.createAccessClient(
      scopes: const <String>[BigqueryApi.BigqueryScope],
    );
    return BigqueryApi(client).jobs;
  }

  /// Return the list of current builder statistic;
  Future<List<BuilderStatistic>> listBuilderStatistic(String projectId) async {
    final JobsResourceApi jobsResourceApi = await defaultJobs();
    final QueryRequest query =
        QueryRequest.fromJson(<String, Object>{'query': getBuilderStatisticQuery, 'useLegacySql': false});
    final QueryResponse response = await jobsResourceApi.query(query, projectId);
    if (!response.jobComplete) {
      throw 'job does not complete';
    }
    final List<BuilderStatistic> result = <BuilderStatistic>[];
    for (final TableRow row in response.rows) {
      final String builder = row.f[0].v as String;
      List<String> failedBuilds = (row.f[3].v as String)?.split(', ');
      failedBuilds?.sort();
      failedBuilds = failedBuilds?.reversed?.toList();
      List<String> succeededBuilds = (row.f[4].v as String)?.split(', ');
      succeededBuilds?.sort();
      succeededBuilds = succeededBuilds?.reversed?.toList();
      result.add(BuilderStatistic(
          name: builder,
          flakyRate: double.parse(row.f[7].v as String),
          failedBuilds: failedBuilds ?? const <String>[],
          succeededBuilds: succeededBuilds ?? const <String>[],
          recentCommit: row.f[5].v as String,
          failedBuildOfRecentCommit: row.f[6].v as String));
    }
    return result;
  }
}

class BuilderStatistic {
  BuilderStatistic({
    this.name,
    this.flakyRate,
    this.failedBuilds,
    this.succeededBuilds,
    this.recentCommit,
    this.failedBuildOfRecentCommit,
  });

  final String name;
  final double flakyRate;
  final List<String> failedBuilds;
  final List<String> succeededBuilds;
  final String recentCommit;
  final String failedBuildOfRecentCommit;
}
