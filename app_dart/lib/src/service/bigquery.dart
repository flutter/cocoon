// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart';

import 'access_client_provider.dart';

/// The sql query to query the build statistic from the
/// `flutter-dashboard.datasite.luci_prod_build_status`.
///
/// The schema of the `luci_prod_build_status` table:
/// time	            TIMESTAMP
/// date	            DATE
/// sha	              STRING
/// flaky_builds	    STRING
/// succeeded_builds	STRING
/// branch	          STRING
/// device_os       	STRING
/// pool	            STRING
/// repo	            STRING
/// builder_name	    STRING
/// success_count	    INTEGER
/// failure_count	    INTEGER
/// is_flaky	        INTEGER
const String getBuilderStatisticQuery = r'''
select builder_name,
       sum(is_flaky) as flaky_number,
       count(*) as total_number,
       string_agg(case when is_flaky = 1 then flaky_builds end, ', ') as flaky_builds,
       string_agg(succeeded_builds, ', ') as succeeded_builds,
       array_agg(case when is_flaky = 1 then sha end IGNORE NULLS ORDER BY date DESC)[ordinal(1)] as recent_flaky_commit,
       array_agg(case when is_flaky = 1 then flaky_builds end IGNORE NULLS ORDER BY date DESC)[ordinal(1)] as flaky_build_of_recent_flaky_commit,
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

  /// Return the list of current builder statistic.
  ///
  /// See getBuilderStatisticQuery to get the detail information about the table
  /// schema
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
      List<String> flakyBuilds = (row.f[3].v as String)?.split(', ');
      flakyBuilds?.sort();
      flakyBuilds = flakyBuilds?.reversed?.toList();
      List<String> succeededBuilds = (row.f[4].v as String)?.split(', ');
      succeededBuilds?.sort();
      succeededBuilds = succeededBuilds?.reversed?.toList();
      result.add(BuilderStatistic(
          name: builder,
          flakyRate: double.parse(row.f[7].v as String),
          flakyBuilds: flakyBuilds ?? const <String>[],
          succeededBuilds: succeededBuilds ?? const <String>[],
          recentCommit: row.f[5].v as String,
          flakyBuildOfRecentCommit: row.f[6].v as String));
    }
    return result;
  }
}

class BuilderStatistic {
  BuilderStatistic({
    this.name,
    this.flakyRate,
    this.flakyBuilds,
    this.succeededBuilds,
    this.recentCommit,
    this.flakyBuildOfRecentCommit,
  });

  final String name;
  final double flakyRate;
  final List<String> flakyBuilds;
  final List<String> succeededBuilds;
  final String recentCommit;
  final String flakyBuildOfRecentCommit;
}
